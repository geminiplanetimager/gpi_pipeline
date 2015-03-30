;+
; NAME: gpi_klip_algorithm_angular_differential_imaging
; PIPELINE PRIMITIVE DESCRIPTION: KLIP algorithm Angular Differential Imaging
;
;   This algorithm reduces PSF speckles in a datacube using the
;   KLIP algorithm and Angular Differential Imaging.
;
; ALGORITHM:
;       Star location must have been previously measured using satellite spots.
;       Measure annuli out from the center of the cube and create a
;       reference set for each annuli of each slice. Apply KLIP to the
;       reference set and project the target slice onto the KL
;       transform vector. Subtract the projected image from the
;       original and repeat for all slices 
; 
; INPUTS: Multiple spectral datacubes
; OUTPUTS: A reduced datacube with reduced PSF speckle halo
;
;
; PIPELINE COMMENT: Reduce speckle noise using the KLIP algorithm with ADI data
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="annuli" Type="int" Range="[0,100]" Default="0" Desc="Number of annuli to use"
; PIPELINE ARGUMENT: Name="MinRotation" Type="float" Range="[0.0,360.0]" Default="1" Desc="Minimum rotation between images (degrees)"
; PIPELINE ARGUMENT: Name="prop" Type="float" Range="[0.8,1.0]" Default=".99999" Desc="Proportion of eigenvalues used to truncate KL transform vectors"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="5" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.2
; PIPELINE CATEGORY: SpectralScience
;
; HISTORY:
;        2013-10-21 - ds
;-

function gpi_klip_algorithm_angular_differential_imaging, DataSet, Modules, Backbone
  primitive_version= '$Id$' ; get version from subversion to store in header history
  @__start_primitive

  if numfile ne ((dataset.validframecount)-1) then return, OK

  ;; get some info about the dataset
  nlam = backbone->get_keyword('NAXIS3',indexFrame=0, count=ct)
  dim = [backbone->get_keyword('NAXIS1',indexFrame=0, count=ct1),backbone->get_keyword('NAXIS2',indexFrame=0, count=ct2)]
  if ct+ct1+ct2 ne 3 then return, error('FAILURE ('+functionName+'): Missing NAXIS* keyword(s).')
  nfiles=dataset.validframecount
  band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  if ct eq 0 then return, error('FAILURE ('+functionName+'): Missing IFSFILT keyword.')
  cwv = get_cwv(band,spectralchannels=nlam)
  
  ;;get PA angles and satspots of all images and check that they have
  ;;the same number of slices
  PAs = dblarr(dataset.validframecount)
  locs = dblarr(2,4,nlam,nfiles)
  cens = dblarr(2,nlam,nfiles)
  for j = 0, nfiles - 1 do begin  
     PAs[j] = double(backbone->get_keyword('AVPARANG', indexFrame=j ,count=ct))
     if ct eq 0 then return, error('FAILURE ('+functionName+'): Missing average parallactic angle.')
     
     if (backbone->get_keyword('NAXIS3',indexFrame=j) ne nlam) then $
        return, error('FAILURE ('+functionName+'): All cubes in dataset must have the same number of slices.')

     if ~strcmp(gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct)),band) then $
        return, error('FAILURE ('+functionName+'): All cubes in dataset must be in the same band.')

     tmp = gpi_satspots_from_header(*DataSet.HeadersExt[j])
     if n_elements(tmp) eq 1 then $
        return, error('FAILURE ('+functionName+'): Use "Measure satellite spot locations" before this primitive.') else $
           locs[*,*,*,j] = tmp

     for k = 0,nlam-1 do cens[*,k,j] = [mean(locs[0,*,k,j]),mean(locs[1,*,k,j])]
  endfor
 
  ;;get user inputs
  annuli=long(Modules[thisModuleIndex].annuli)
  minrot=double(Modules[thisModuleIndex].minRotation)
  prop=double(Modules[thisModuleIndex].prop)
  
  ;;get the status console and number of modules
  statuswindow = backbone->getstatusconsole()
  nummodules = double(N_ELEMENTS(Modules))

  ;;get the pixel scale, telescope diam  and define conversion factors
  ;;and figure out IWA in pixels
  pixscl = gpi_get_ifs_lenslet_scale(*DataSet.HeadersExt[numfile]) ;as/lenslet
  rad2as = 180d0*3600d0/!dpi                                       ;rad->as
  tel_diam = gpi_get_constant('primary_diam',default=7.7701d0)     ;m
  IWA = 2.8d0 * (cwv.commonwavvect)[0]*1d-6/tel_diam*rad2as/pixscl ; 2.8 l/D (pix)
  OWA = 44d0 * (cwv.commonwavvect)[0]*1d-6/tel_diam*rad2as/pixscl  ; 
  waffle = OWA/2*sqrt(2)                                           ;radial location of MEMS waffle

  if ceil(waffle) - floor(IWA) lt annuli*2 then $
     return,error('INPUT ERROR ('+functionName+'): Your requested annuli will be smaller than 2 pixels.')

  ;;figure out starting and ending points of annuli and their centers
  case annuli of
     0: rads = [0,max(dim)+1]
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
  if max(rads) lt max(dim)+1 then rads = [rads,max(dim)+1]
  radcents = (rads[0:n_elements(rads)-2]+rads[1:n_elements(rads)-1])/2d0
  
  ;;figure out total number of iterations
  totiter = (n_elements(rads)-1)*nlam*nfiles

  xs = reform(dindgen(dim[0]) # (dblarr(dim[1])+1d0),dim[0]*dim[1])
  ys = reform((dblarr(dim[0])+1d0) # dindgen(dim[1]),dim[0]*dim[1])
  imcent = (dim-1)/2.
  rth = cv_coord(from_rect=transpose([[xs-imcent[0]],[ys-imcent[1]]]),/to_polar)
  rs = rth[1,*]

  ;;allocate output
  final_im = dblarr(dim[0]*dim[1],nlam,nfiles)

  ;; do this by slice
  for l = 0,nlam-1 do begin
     
     R0 = dblarr(dim[0]*dim[1],nfiles)
     ;;get all of the data for the current slice & align image centers
     ;;to center pixel
     for imnum = 0,nfiles-1 do begin
        tmp =  accumulate_getimage(dataset,imnum, slice=l)
        R0[*,imnum] = interpolate(tmp,xs+cens[0,l,imnum]-imcent[0],ys+cens[1,l,imnum]-imcent[1],cubic=-0.5)
     endfor
     
     ;;apply KLIP to each annulus
     for radcount = 0,n_elements(rads)-2 do begin
        ;;rad range: rads[radcount]<= R <rads[radcount+1] 
        radinds = where((rs ge rads[radcount]) and (rs lt rads[radcount+1]))
        R = R0[radinds,*] ;;ref set

        ;;check that you haven't just grabbed a blank annulus
        if (total(finite(R)) eq 0) then begin 
           statuswindow->set_percent,-1,double(nfiles)/totiter*100d/nummodules,/append
           continue
        endif 

        ;;create mean subtracted versions and get rid of NaNs
        mean_R_dim1=dblarr(N_ELEMENTS(R[0,*]))                        
        for zz=0,N_ELEMENTS(R[0,*])-1 do mean_R_dim1[zz]=mean(R[*,zz],/double,/nan)
        R_bar = R-matrix_multiply(replicate(1,n_elements(radinds),1),mean_R_dim1,/btranspose)
        naninds = where(R_bar ne R_bar,countnan)
        if countnan ne 0 then begin 
           R[naninds] = 0
           R_bar[naninds] = 0
           naninds = array_indices(R_bar,naninds)
        endif

        ;;find covariance of all slices
        covar0 = matrix_multiply(R_bar,R_bar,/atranspose)/(n_elements(radinds)-1d0) 

        ;;cycle through images
        for imnum = 0,nfiles-1 do begin

           ;;update progress as needed
           statuswindow->set_percent,-1,1d/totiter*100d/nummodules,/append

           ;;figure out which images are to be used
           fileinds = where(abs(PAs - PAs[imnum]) gt minrot, count)
           if count lt 2 then begin 
              logstr = 'No reference slices available for requested motion. Skipping.'
              message,/info,logstr
              backbone->Log,logstr
              continue
           endif 

           ;;grab covariance submatrix
           covar = covar0[fileinds,*]
           covar = covar[*,fileinds]

           ;;get the eigendecomposition
           residual = 1         ;initialize the residual
           evals = eigenql(covar,eigenvectors=evecs,/double,residual=residual)  

           ;;determines which eigenalues to truncate
           evals_cut = where(total(evals,/cumulative) gt prop*total(evals))
           K = evals_cut[0]
           if K eq -1 then continue

           ;;creates mean subtracted and truncated KL transform vectors
           Z = evecs ## R_bar[*,fileinds]
           G = diag_matrix(sqrt(1d0/evals/(n_elements(radinds)-1)))

           Z_bar = G ## Z
           Z_bar_trunc=Z_bar[*,0:K] 

           T = R_bar[*,imnum]
           ;;T = R[*,ref_value]

           ;;Project KL transform vectors and subtract from target
           signal_step_1 = matrix_multiply(T,Z_bar_trunc,/atranspose)
           signal_step_2 = matrix_multiply(signal_step_1,Z_bar_trunc,/btranspose)
           Test = T - transpose(signal_step_2)
           
           ;;restore,NANs,rotate estimate by -PA and add to output
           if countnan ne 0 then Test[naninds[0,where(naninds[1,*] eq imnum)]] = !values.d_nan

		   final_im[radinds,l,imnum] = Test
           ;final_im[*,*,l] += rot(reform(Test,dim),PAs[imnum],/interp,cubic=-0.5)
        endfor
     endfor
  endfor 
  
  ;final_im = final_im/nfiles
  final_im = reform(final_im, dim[0],dim[1],nlam,nfiles)

  ;;;;*(dataset.currframe[0]) = final_im
  suffix = suffix+'-klip'

for i=0,nfiles-1 do begin

	backbone->Log, "Finished KLIP'd cube: "+strc(i+1)+" of "+strc(nfiles), depth=3
	print, "Saving frame", i
	accumulate_updateimage, dataset, i, newdata = final_im[*,*,*,i]

endfor

  ;backbone->set_keyword,'HISTORY', functionname+": ADI KLIP applied.",ext_num=0;
  ;
  ;;update WCS info
  ;gpi_update_wcs_basic,backbone,parang=0d0,imsize=dim
;
  ;;update satspot locations to new position and rotation
;  flocs = locs[*,*,*,numfile]
;  fcens = cens[*,*,numfile]
;  for j=0,1 do for k=0,nlam-1 do flocs[j,*,k] +=  imcent[j] - fcens[j,k]
;  gpi_rotate_header_satspots,backbone,PAs[numfile],flocs,imcent=imcent
;
;  backbone->set_keyword, "FILETYPE", "Spectral Cube ADI KLIP"
  @__end_primitive
end 

  
  
