function klip, cubein, refslice=refslice, band=band, locs=locs, $
               annuli=annuli, movmt=movmt, prop=prop, arcsec=arcsec, $
               snr=snr, signal=signal
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
;      annuli - Number of annuli KLIP uses (defaults to 10)
;      movmt - Minimum pixel movement for reference slices (defaults
;              to 2)
;      prop - Proportion of eigenvalues used to truncate KL transform
;             vectors (defaults to .99999)
;      arcsec - Radius of interest only if using 1 annulus (defaults
;               to .4)
;      /signal - command to calculate the SNR
;      
;      res - Cube with KLIP algorithm applied and reverse speckle
;            aligned 
;      snr- Cube of the SNR of the KLIP algorithm
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
;      gpi_get_setting.pro
;      make_annulus.pro      
;
; NOTES:
;
;
; REVISION HISTORY
;      Written 2013. Tyler Barker
;-

;;cube dimensions
lambda_dimen= size(cubein,/dim) 
if n_elements(lambda_dimen) ne 3 then begin
   message,'You must supply a 3D image cube.',/continue
   return,-1
endif

;;by defulat use 0th slice as reference and assume H band
if n_elements(refslice) eq 0 then refslice = 0

;;get wavelength information, generate wavelengths, and calculate
;;wavelength change per frame
if not keyword_set(band) then band = 'H'
cwv = get_cwv(band,spectralchannels=lambda_dimen[2])
lambda = cwv.lambda
wav_per_frame=(lambda[lambda_dimen[2]-1]-lambda[0])/lambda_dimen[2]

;;need to have satellite spots
if n_elements(size(locs,/dim)) ne 3 then begin
   message,'You must supply the full set of satellite spots.',/continue
   return,-1
endif

;;by defulat use 10 annuli
if n_elements(annuli) eq 0 then annuli=10
annuli=float(annuli)

;;by default use a proportion of .99999
if n_elements(prop) eq 0 then prop=.99999

;;by default use 2.0 minimum pixel movement
if n_elements(movmt) eq 0 then movmt=2.0

;;get the pixel scale for arcsec conversion
pixscl = gpi_get_setting('ifs_lenslet_scale') 
if ~strcmp(pixscl,'ERROR',/fold_case) then pixscl = double(pixscl) else $
     pixscl = 0.0143d ;in units arcsec/pixel

;;by default arcsec interest is .4
if annuli eq 1 then begin
   if n_elements(arcsec) eq 0 then arcsec=.4
   arcsec=arcsec/pixscl
endif

;;initialize the final cube 
signal_final=fltarr(lambda_dimen[1]^2,lambda_dimen[2])

;;sets up the annuli to measure the SNR
in_annu=make_annulus(3)
out_annu=make_annulus(7,4)

;;prepare the points to find SNR
snr_map=where(finite(cubein[*,*,0])) ;map of the good points
snr_arr=array_indices(cubein[*,*,0],snr_map) ;array of the good points

;;klip algorithm (need to do for each slice)
for ref_value=0,lambda_dimen[2]-1,1 do begin
   ;;gets the inner working angle in pixels
   mult_const=6.48e5/(7.7*!dpi)
   in_ang0=(2.8e-6*lambda[ref_value])
   in_ang1=in_ang0*mult_const/pixscl
   start_rad=float(floor(in_ang1))

   ;;sets up the annulus coordinates
   map=where(cubein[*,*,ref_value])
   map_2_D=array_indices(cubein[*,*,ref_value],map)
   c0 = (total(locs[*,*,0],2)/4) # (fltarr(n_elements(map))+1.)
   coordsp = cv_coord(from_rect=map_2_D - c0,/to_polar)

   ;;runs klip for each annulus
   for rad=start_rad,lambda_dimen[1]/2+20.0,lambda_dimen[1]/(2*annuli) do begin
      ;;calculates the reference set
      range=ceil(((movmt/rad+1)*lambda[0]-lambda[0])/wav_per_frame);calc # of frames
      if rad lt 25.0 then range=ceil(((movmt/(25.0)+1)*lambda[0]-lambda[0])/wav_per_frame)
      if annuli eq 1.0 then range=ceil(((movmt/arcsec+1)*lambda[0]-lambda[0])/wav_per_frame)
      if range gt (lambda_dimen[2]/2-1) then range=lambda_dimen[2]/2-1
      choice=findgen(lambda_dimen[2])      ;sets up array to figure out which slices to use
      exclude=findgen(2*range-1)-range+ref_value+1   ;use -1 to include the end range values
      exclude[where(exclude gt (lambda_dimen[2]-1), /null)]=ref_value
      exclude[where(exclude lt 0, /null)]=ref_value
      remove, exclude, choice   ;this takes the range around ref_value out of the choices
      
      ;;set the annular rings to a certain width
      inds=where((coordsp[1,*] gt rad-(lambda_dimen[1]/(4*annuli)+1)) and (coordsp[1,*] lt rad+(lambda_dimen[1]/(4*annuli)+1)))

      ;;set up the target slice and reference slices
      R=reform(cubein[*,*,choice],lambda_dimen[1]^2,size(choice, dimension=1),1) 
      R=R[inds,*]
      T=reform(cubein[*,*,ref_value],lambda_dimen[1]^2,1)   
      T=T[inds]  

      ;;gets the size of the reference slice
      dimen=size(R,/dimensions) 
      col=dimen[0]             
      row=dimen[1]              

      ;;create mean subtracted versions and get rid of NaNs
      R_bar=R-matrix_multiply(replicate(1,col,1),mean(R,dimension=1,/double,/nan),/btranspose)
      R_bar[where(R_bar ne R_bar)]=0 
      T_bar=T-mean(T,dimension=1,/double,/nan)##replicate(1,col,1) 
      T_bar[where(T_bar ne T_bar)]=0 
      
      ;;calculate the covariance and eigenspace
      covar=matrix_multiply(R_bar,R_bar,/atranspose)/(col-1) 
      residual=1 ;initialize the residual
      evals=eigenql(covar,eigenvectors=evecs,/double,residual=residual)  

      ;;determines which eigenalues to truncate
      evals_cut=where(total(evals,/cumulative) gt prop*total(evals))
      K=evals_cut(0)

      ;;creates mean subtracted and truncated KL transform vectors
      Z=evecs##R_bar
      G=sqrt(invert(diag_matrix(evals)))/sqrt(col-1)
      Z_bar=G##Z
      Z_bar_trunc=Z_bar(*,0:K) 

      ;;Project KL transform vectors and subtract from target
      signal_step_1=matrix_multiply(T_bar,Z_bar_trunc,/atranspose)
      signal_step_2=matrix_multiply(signal_step_1,Z_bar_trunc,/btranspose)
      signal_final[inds,ref_value]=T_bar-transpose(signal_step_2)
   endfor
endfor

;;recreate the data cube
signal_final=reform(signal_final,lambda_dimen[0],lambda_dimen[1],lambda_dimen[2])

;;reverse speckle align
Ima1=speckle_align(signal_final, locs=locs,refslice=refslice ,/reverse) 
signal_final=Ima1

;; calculate the SNR (extremely slow)
if keyword_set(signal) then begin
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

;;return the final datacube
return, signal_final

end
