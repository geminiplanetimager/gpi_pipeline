function klip, cubein, refslice=refslice, band=band, locs=locs, $
               annuli=annuli, movmt=movmt, prop=prop, arcsec=arcsec, $
               snr=snr, signal=signal, eqarea=eqarea, $
               statuswindow=statuswindow,nummodules=nummodules
;+
; NAME:
;       klip
; PURPOSE:
;       Subtract noise from a datacube using Karhunen-Loève Image
;       Projection Algorithm 
;
; EXPLANATION:
;      Create a model PSF using a set of optimally compacting basis of
;      a reference set from a datacube, and subtract the model PSF
;      from the original target slice.
;
; Calling SEQUENCE:
;      res=klip(cube,[refslice=refslice,band=band,locs=locs,annuli=annuli,movmt=movmt,prop=prop,arcsec=arcsec,snr=snr,/signal])
;
; INPUT/OUTPUT:
;      cubein - 3D image (must be consistent with cubes produced 
;               by the gpi pipeline)
;      refslice - Index of reference slice (defaults to 0)
;      locs - 2x4x(# of slices) array of Sat spot locations
;      band - Cube spectral band (defaults to H)
;      annuli - Number of annuli KLIP uses (defaults to 10).  0 means
;               use the entire cube, 1 means to generate a single
;               annulus out from the IWA, N generate N annuli from the
;               IWA to the OWA and one outside of that.
;      movmt - Minimum pixel movement for reference slices (defaults
;              to 2)
;      prop - Proportion of eigenvalues used to truncate KL transform
;             vectors (defaults to .99999)
;      arcsec - Radius of interest only if using 1 or no annulus (defaults
;               to .4)
;      /signal - command to calculate the SNR
;      
;      res - Cube with KLIP algorithm applied and reverse speckle
;            aligned 
;      snr- Cube of the SNR of the KLIP algorithm
;      statuswindow - GPI DRP status console object (to update status bar)
;      nummodules - number of modules in current recipe (needs to be
;                   set for status bar update)
;
; OPTIONAL OUTPUT:
;      None
;
; EXAMPLE:
;
;
; DEPENDENCIES:  
;      get_cwv.pro
;      speckle_align.pro
;      gpi_get_constant.pro
;      make_annulus.pro      
;
; NOTES:
;      Based on Soummer et al., 2012
;
; REVISION HISTORY
;      Written 2013. Tyler Barker
;      10.21.2013 - ds - Partial rewrite to improve performance.
;-

;;cube dimensions
lambda_dimen= size(cubein,/dim) 
if n_elements(lambda_dimen) ne 3 then begin
   message,'You must supply a 3D image cube.',/continue
   return,-1
endif

;;need to have satellite spots
if n_elements(size(locs,/dim)) ne 3 then begin
   message,'You must supply the full set of satellite spots.',/continue
   return,-1
endif

;;set defaults 
if n_elements(refslice) eq 0 then refslice = 0
if not keyword_set(band) then band = 'H'
if n_elements(annuli) eq 0 then annuli = 10
annuli = double(annuli) ;ensure that this param is floating point
if n_elements(prop) eq 0 then prop = .99999
if n_elements(movmt) eq 0 then movmt = 2.0

;;get wavelength information, generate wavelengths, and calculate
;;wavelength change per frame
cwv = get_cwv(band,spectralchannels=lambda_dimen[2])
if size(cwv,/type) ne 8 then return,-1
lambda = cwv.lambda

;;get the pixel scale, telescope diam  and define conversion factors
;;and figure out IWA in pixels
pixscl = gpi_get_constant('ifs_lenslet_scale',default=0.0143d0) ;as/lenslet
rad2as = 180d0*3600d0/!dpi ;rad->as
tel_diam = gpi_get_constant('primary_diam',default=7.7701d0) ;m
IWA = 2.8d0 * lambda[refslice]*1d-6/tel_diam*rad2as/pixscl; 2.8 l/D (pix)
OWA = 44d0 * lambda[refslice]*1d-6/tel_diam*rad2as/pixscl; 
waffle = OWA/2*sqrt(2) ;radial location of MEMS waffle

if ceil(waffle) - floor(IWA) lt annuli*2 then begin
   message,'Your requested annuli will be smaller than 2 pixels. Returning.',/continue
   return,-1
endif 

;;figure out starting and ending points of annuli and their centers
case annuli of
   0: rads = [0,lambda_dimen[1]+1]
   1: rads = [floor(IWA),ceil(waffle)]
   else: begin
      if keyword_set(eqarea) then begin
         rads = dblarr(annuli+1)
         rads[0] = floor(IWA)
         rads[n_elements(rads)-1] = ceil(waffle)
         A = !dpi*(rads[n_elements(rads)-1]^2d0 - rads[0]^2d0)
         for j = 1,n_elements(rads)-2 do rads[j] = sqrt(A/!dpi/annuli + rads[j-1]^2d0)
      endif else rads = round(dindgen(annuli+1d0) / (annuli) * (ceil(waffle) - floor(IWA)) + floor(IWA))
   end 
endcase 
if max(rads) lt lambda_dimen[1]/2+1 then rads = [rads,lambda_dimen[1]/2+1]

;;by default arcsec of interest is .4
if annuli lt 1 then begin
   if n_elements(arcsec) eq 0 then arcsec=.4
   radcents = arcsec/pixscl
endif else radcents = (rads[0:n_elements(rads)-2]+rads[1:n_elements(rads)-1])/2d0

;;initialize the final cube.  KLIP has the effect of killing all nans.
;;Store them now so you can estore them in the final signal
signal_final=fltarr(lambda_dimen[0]*lambda_dimen[1],lambda_dimen[2])
badinds = where(~finite(cubein),badindsct)

;;if you're going to be updating the statusbar, you need to
;;know how many total iterations will be done
if keyword_set(statuswindow) then begin
   if ~keyword_set(nummodules) then nummodules = 1
   totiter = (n_elements(rads)-1)*lambda_dimen[2]
endif 

;;figure out where the data actually is in the cube with respect to
;;the center point:
map = where(finite(cubein[*,*,refslice]))
map_2_D = array_indices(cubein[*,*,refslice],map)
c0 = (total(locs[*,*,refslice],2)/4) # (fltarr(n_elements(map))+1.)
coordsp = cv_coord(from_rect=map_2_D - c0,/to_polar)

;;get the number of pixels planet at center of each annulus moves between
;;slices
movmts  = (lambda[0]/lambda - 1d0) # radcents

;;flatten cube for easier indexing
fcube = reform(cubein,lambda_dimen[0]*lambda_dimen[1],lambda_dimen[2]) 

;;klip algorithm (need to do for each slice and annulus)
for radcount = 0,n_elements(rads)-2 do begin
   ;;rad range: rads[radcount]<= R <rads[radcount+1] 
   radinds = where((coordsp[1,*] ge rads[radcount]) and (coordsp[1,*] lt rads[radcount+1]))
   R = fcube[map(radinds),*] ;;ref set

   ;;check that you haven't just grabbed a blank annulus
   if (total(finite(R)) eq 0) then begin 
      if keyword_set(statuswindow) && obj_valid(statuswindow) then $
         statuswindow->set_percent,-1,double(lambda_dimen[2])/totiter*100d/nummodules,/append
      continue
   endif 

   ;;create mean subtracted versions and get rid of NaNs
   mean_R_dim1=dblarr(N_ELEMENTS(R[0,*]))                        
   for zz=0,N_ELEMENTS(R[0,*])-1 do mean_R_dim1[zz]=mean(R[*,zz],/double,/nan)
   R_bar=R-matrix_multiply(replicate(1,n_elements(radinds),1),mean_R_dim1,/btranspose)
   ind=where(R_bar ne R_bar,count)
   if count ne 0 then begin 
      R[ind] = 0
      R_bar[ind] = 0
   endif 

   ;;find covariance of all slices
   covar0 = matrix_multiply(R_bar,R_bar,/atranspose)/(n_elements(radinds)-1) 

   ;;cycle through slices
   for ref_value=0,lambda_dimen[2]-1 do begin

      ;;update progress as needed
      if keyword_set(statuswindow) && obj_valid(statuswindow) then $
         statuswindow->set_percent,-1,1d/totiter*100d/nummodules,/append

      ;;figure out which slices are to be used
      sliceinds = where(abs(movmts[*,radcount] - movmts[ref_value,radcount]) gt movmt, count)
      if count lt 2 then begin 
         sliceinds = where(abs(movmts[*,radcount] - movmts[ref_value,radcount]) gt 1., count)
         if count lt 2 then begin 
            message,'No reference slices available for requested motion. Skipping.',/cont
            continue
         endif 
      endif 

      ;;grab covariance submatrix
      covar = covar0[sliceinds,*]
      covar = covar[*,sliceinds]

      ;;get the eigendecomposition
      residual = 1 ;initialize the residual
      evals = eigenql(covar,eigenvectors=evecs,/double,residual=residual)  

      ;;determines which eigenalues to truncate
      evals_cut = where(total(evals,/cumulative) gt prop*total(evals))
      K = evals_cut[0]
      if K eq -1 then continue

      ;;creates mean subtracted and truncated KL transform vectors
      Z=evecs ## R_bar[*,sliceinds]
      G = diag_matrix(sqrt(1d0/evals/(n_elements(radinds)-1)))

      Z_bar = G ## Z
      Z_bar_trunc=Z_bar[*,0:K] 

      T = R_bar[*,ref_value]
      ;;T = R[*,ref_value]

      ;;Project KL transform vectors and subtract from target
      signal_step_1 = matrix_multiply(T,Z_bar_trunc,/atranspose)
      signal_step_2 = matrix_multiply(signal_step_1,Z_bar_trunc,/btranspose)
      Test = T - transpose(signal_step_2)
      signal_final[map(radinds),ref_value] = Test

   endfor
endfor

;;recreate the data cube
signal_final=reform(signal_final,lambda_dimen[0],lambda_dimen[1],lambda_dimen[2])

;;reverse speckle align
Ima1=speckle_align(signal_final, locs=locs,refslice=refslice ,/reverse) 
signal_final=Ima1

;; calculate the SNR (extremely slow)
if keyword_set(signal) then begin
   ;;sets up the annuli to measure the SNR
   in_annu=make_annulus(3)
   out_annu=make_annulus(7,4)

   ;;prepare the points to find SNR
   snr_map=where(finite(cubein[*,*,0]))      ;map of the good points
   snr_arr=array_indices(cubein[*,*,0],snr_map) ;array of the good points

   snr=fltarr(lambda_dimen[0],lambda_dimen[1],lambda_dimen[2])
   for slice=0,36,1 do begin
      for x=0,n_elements(snr_arr[0,*])-1,1 do begin
         mean_sig=mean(signal_final[snr_arr[0,x]+in_annu,snr_arr[1,x]+in_annu,slice])
         mean_noise=mean(signaL_final[snr_arr[0,x]+out_annu,snr_arr[1,x]+out_annu,slice])
         std_noise=stddev(signaL_final[snr_arr[0,x]+out_annu,snr_arr[1,x]+out_annu,slice])
         snr[snr_arr[0,x],snr_arr[1,x],slice]=(mean_sig-mean_noise)/std_noise
      endfor
   endfor
endif

;;this processing has the effect of killing all nans.  Restore them in
;;the final signal:
if badindsct gt 0 then signal_final[badinds] = !values.f_nan

;;return the final datacube
return, signal_final

end
