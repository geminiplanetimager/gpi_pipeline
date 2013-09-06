;+
; NAME: calibrate with PSF
; PIPELINE PRIMITIVE DESCRIPTION: calibrate with PSF
; 
; This primitive is based on the determination of a high resolution PSF for each lenslet. It uses an adapted none iterative algorithm from the paper of Jay Anderson and Ivan R. King 2000.
; 
; INPUTS:  Whatever of the same type
; OUTPUTS: Some stuffs...
;
; PIPELINE COMMENT: Create a few calibrations files based on the determination of a high resolution PSF.
; PIPELINE ARGUMENT: Name="filter_wavelength" Type="float" Range="[0.8,2.5]" Default="-1.0" Desc="Narrowband filter wavelength"
; PIPELINE ARGUMENT: Name="flat_field" Type="int" Range="[0,1]" Default="-1.0" Desc="Is this a flat field"
; PIPELINE ARGUMENT: Name="flat_filename" Type="string" Default="" Desc="Name of flat field"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.01
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 22-
;
; HISTORY:
;     Originally by Jean-Baptiste Ruffio 2013-06
;-
function calibrate_with_PSF, DataSet, Modules, Backbone
  primitive_version= '$Id: create_2d_LF_flat_psffit.pro 1558 2013-05-31 18:42:08Z jruffio $' ; get version from subversion to store in header history
@__start_primitive
  
  if tag_exist( Modules[thisModuleIndex], "filter_wavelength") then filter_wavelength=float(Modules[thisModuleIndex].filter_wavelength) else filter_wavelength=-1
  if tag_exist( Modules[thisModuleIndex], "flat_field") then flat_field=float(Modules[thisModuleIndex].flat_field) else flat_field=0
  if tag_exist( Modules[thisModuleIndex], "flat_filename") then flat_filename=string(Modules[thisModuleIndex].flat_filename) else flat_filename=""
  
  if filter_wavelength eq -1 and flat_field eq 0 then return, error(' No narrowband filter wavelength specified. Please specify a wavelength and re-add to queue')
  
                                ;Check that all the images 
                                ;  - have the same type (spectra PRISM or polarization WOLLASTON). It should be more precise in the future, for instance taking into account the lamp (Ar/Xe/narrow band etc...) to let the algo decide on his own what to do.
                                ;  - have the elevation (not anymore). In the future, this should not be a restriction. All images of the same elevation should be merged before and they should all arrive here and processed all together.
                                ;  - The images don't need to be all flats in facts depending on what you'd like to do. But if you wish to get only the PSF, the intensity doesn't matter has you normalize the PSFs.
  nfiles = 0
                                ;define the common wavelength vector with the IFSFILT keyword:
  my_first_filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
;  my_first_elevation = backbone->get_keyword('ELEVATIO', indexFrame=nfiles)
  my_first_mode =  gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', indexFrame=nfiles))
  while (size(*dataset.headersphu[nfiles+1]))[0] ne 0 do begin ;hard to understand but it checks if there is indeed a header behind the pointer
     nfiles+=1
;    my_elevation = backbone->get_keyword('ELEVATIO', indexFrame=nfiles)
     my_mode =  gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', indexFrame=nfiles))
                                ; the above line returns zero if no keyword is found. This is
                                ; acceptable since all data taken without this keyword has an
                                ; elevation of zero!
;    if my_elevation ne my_first_elevation then return, error('Image '+strc(nfiles+1)+' has different elevation (ELEVATIO keyword) than first image in sequence. Cannot continue!')
     if my_mode ne my_first_mode then return, error('Image '+strc(nfiles+1)+' is not '+my_first_mode+' (DISPERSR keyword) like the first image. Cannot continue!')
     if my_mode ne my_first_mode then return, error('Image '+strc(nfiles+1)+' is not '+my_first_mode+' (DISPERSR keyword) like the first image. Cannot continue!')
  endwhile
  nfiles+=1                     ; because it was previously used as an index and index starts at 0
  
  if nfiles eq 1 then begin
     image=*(dataset.currframe[0])
     
     if keyword_set(flat_filename) eq 1 then begin
        stop
        flat_filename="/home/LAB/gpi/data/Reduced/130703/flat_field_arr_130702S0043.fits"
        flat=mrdfits(flat_filename)
        flat[where((flat) eq 0 or finite(flat) eq 0)]=1.0
        image/=flat
     endif
     
     
     sz=size(image) 
     if sz[1] ne 2048 or sz[2] ne 2048 then begin
        backbone->Log, "REFPIX: Image is not 2048x2048, don't know how to manage it."
        return, NOT_OK
     endif
  endif
  
                                ;set the common variable (in PIP)  
  filter = my_first_filter
;stop
;declare variables....
  case my_first_mode of
     'PRISM': begin
        width_PSF = 4
        kmax = 0
                                ;sub_pixel resolution of the PSF
        sub_pix_res_x = 4
        sub_pix_res_y = 4
        cent_mode = "BARYCENTER"
                                ; raw data stamps
        if nfiles ge 2 then $
           spaxels = get_spaxels(my_first_mode, dataset.frames[0:(nfiles-1)], dataset.wavcals[0:(nfiles-1)], width_PSF, /STAMPS_MODE) $
        else $
           spaxels = get_spaxels(my_first_mode, image, wavcal, width_PSF, /STAMPS_MODE)
     end
     'WOLLASTON': begin
        width_PSF = 7
        kmax = 1
                                ;sub_pixel resolution of the PSF
        sub_pix_res_x = 4
        sub_pix_res_y = 4
        cent_mode = "EDGE"
                                ; raw data stamps
        spaxels = get_spaxels(my_first_mode, image, polcal, width_PSF, /STAMPS_MODE)
;  return: {values: ptr_values,$
;          xcoords: ptr_xcoords,$
;          ycoords: ptr_ycoords,$
;          xcentroids: xcentroids,$
;          ycentroids: ycentroids,$
;          intensities: intensities,$
;          sky_values: sky_values,$
;          masks: ptr_masks}
     end
  endcase
;  stop
;  stop
  
  common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary
                                ;diff_image = readfits("/Users/jruffio/Desktop/diff_image6.fits")
  diff_image = fltarr(2048,2048)
  new_image = fltarr(2048,2048)
  
  n_neighbors = 2               ; number on each side - so 4 gives a 9x9 box
  n_neighbors_flex = 2          ; for the flexure shift determination
  n_neighbors_flex = 4 ; for the flexure shift determination
  values_tmp = *(spaxels.values[(where(ptr_valid(spaxels.values)))[0]])
  nx_pix = (size(values_tmp))[1]
  ny_pix = (size(values_tmp))[2]
  if (size(spaxels.values))[0] eq 4 then n_diff_elev = (size(spaxels.values))[4] else n_diff_elev = 1
  PSF_template = {values: fltarr(nx_pix*sub_pix_res_x+1,ny_pix*sub_pix_res_y+1), $
                  xcoords: fltarr(nx_pix*sub_pix_res_x+1), $
                  ycoords: fltarr(ny_pix*sub_pix_res_y+1), $
                  tilt: 0.0,$
                  id: [0,0,0] }
  
                                ;replace the 281 by variables 
                                ;these replicates are very slow
;  PSFs = replicate(PSF_template, 281, 281, kmax+1)
  PSFs = ptrarr(281, 281, kmax+1)
  fitted_spaxels = replicate(spaxels,1)
  fit_error_flag = intarr(281, 281, kmax+1)
  
  time0=systime(1) 
; start the iterations
  it_max=1
  it_flex_max = 2
  
; make an array to look at the stddev as a function of iterations

  if flat_field eq 1 then flat_field_arr=fltarr(2048,2048,nfiles)
  
debug=1
  if debug eq 1 then begin
 ; create a series of arrays to evaluate the fits for each iteration
                                ; want to watch how the weighted
                                ; STDDEV decreases with iterations etc
     stddev_arr=fltarr(281,281,kmax+1,nfiles,it_max,it_flex_max)
     intensity_arr=fltarr(281,281,kmax+1,nfiles,it_max,it_flex_max)
     diff_intensity_arr=fltarr(281,281,kmax+1,nfiles,it_max,it_flex_max)
     
; can also use this (eventually) to build the proper flat fields.

     ; need a S/N for each pixel for that...
  endif

  imin_test = 0 & imax_test=280
  jmin_test = 0 & jmax_test=280
  imin_test = 140 & imax_test = 160
  jmin_test = 140 & jmax_test = 160
  ; code check range
;  imin_test = 148 & imax_test = 152
;  jmin_test = 148 & jmax_test = 152
  for it_flex=0,it_flex_max-1 do begin
     print, 'starting iteration '+strc(it_flex+1)+' of '+strc(it_flex_max)+' for flexure'
                                ; make an array to look at the stddev as a function of iterations
     
     for it = 0, it_max-1 do begin
                                ;  stop do begin
        for k=0,kmax do begin
                                ;    for i=0,281-1 do begin
                                ;      for j=0,281-1 do begin
           for i=imin_test,imax_test do begin
              statusline, "Get and fit PSF: Fitting line "+strc(i+1)+" of 281 and spot "+strc(k+1)+" of "+strc(kmax+1)+" for iteration " +strc(it+1)+" of "+strc(it_max)
              for j=jmin_test,jmax_test do begin
                 ; see if there are any intensities and not all nans
                 if spaxels.intensities[i,j,k] ne 0.0 then begin
                    
                                ; takes a chunk of the array to
                                ; work with so you're not
                                ; passing the entire array
                    
                                ;TODO: it doesnt manage the edges
                    imin = max([0,(i-n_neighbors)])
                    imax = min([280,(i+n_neighbors)])
                    jmin = max([0,(j-n_neighbors)])
                    jmax = min([280,(j+n_neighbors)])
                    nspaxels = (imax-imin+1)*(jmax-jmin+1)*n_diff_elev
                                ;            stop
                                ; just reforms the array to be smaller
                    ptrs_current_stamps = reform(spaxels.values[imin:imax,jmin:jmax,k,*],nspaxels)
                    ptrs_current_xcoords = reform(spaxels.xcoords[imin:imax,jmin:jmax,k,*],nspaxels)
                    ptrs_current_ycoords = reform(spaxels.ycoords[imin:imax,jmin:jmax,k,*],nspaxels)
                    ptrs_current_masks = reform(spaxels.masks[imin:imax,jmin:jmax,k,*],nspaxels)
                    
                    not_null_ptrs = where(ptr_valid(ptrs_current_stamps), n_not_null_ptrs)
                    current_stamps = fltarr(nx_pix,ny_pix,n_not_null_ptrs)
                    current_x0 = fltarr(n_not_null_ptrs)
                    current_y0 = fltarr(n_not_null_ptrs)
                    current_masks = fltarr(nx_pix,ny_pix,n_not_null_ptrs)
                    for it_ptr = 0,n_not_null_ptrs-1 do begin
                       current_stamps[*,*,it_ptr] = *ptrs_current_stamps[not_null_ptrs[it_ptr]]
                       current_x0[it_ptr] = (*ptrs_current_xcoords[not_null_ptrs[it_ptr]])[0]
                       current_y0[it_ptr] = (*ptrs_current_ycoords[not_null_ptrs[it_ptr]])[0]
                       current_masks[*,*,it_ptr] = *ptrs_current_masks[not_null_ptrs[it_ptr]]
                    endfor
                    
                    current_xcen = (spaxels.xcentroids[imin:imax,jmin:jmax,k,*])[not_null_ptrs]
                    current_ycen = (spaxels.ycentroids[imin:imax,jmin:jmax,k,*])[not_null_ptrs]
                    current_flux = (spaxels.intensities[imin:imax,jmin:jmax,k,*])[not_null_ptrs]
                    current_sky =  (spaxels.sky_values[imin:imax,jmin:jmax,k,*])[not_null_ptrs]
                    
                                ;0.000568
                                ;            stop
                                ;stop
                    tmp0 = systime(1)
                    ptr_current_PSF = get_PSF( current_stamps, $
                                               current_xcen - current_x0, $
                                               current_ycen - current_y0, $
                                               current_flux, $
                                               current_sky, $
                                               nx_pix,ny_pix,$
                                               sub_pix_res_x,sub_pix_res_y, $
                                               MASK = current_masks,  $
                                ;XCOORDS = polspot_coords_x, $
                                ;YCOORDS = polspot_coords_y, $
                                               ERROR_FLAG = myerror_flag, $
                                               CENTROID_MODE = cent_mode, $
                                               HOW_WELL_SAMPLED = my_Sampling,$
                                               LENSLET_INDICES = [i,j,k]) ;,$
                                ;/plot_samples )
                    ; now fit the PSF to each elevation psf
                    for it_elev = 0,nfiles-1 do begin
                       first_guess_parameters = [spaxels.xcentroids[i,j,k,it_elev], spaxels.ycentroids[i,j,k,it_elev], spaxels.intensities[i,j,k,it_elev]]
                       ptr_fitted_PSF = fit_PSF( *spaxels.values[i,j,k,it_elev] - spaxels.sky_values[i,j,k,it_elev], $
                                                 FIRST_GUESS = first_guess_parameters, $
                                                 ptr_current_PSF,$
                                                 X0 = (*spaxels.xcoords[i,j,k,it_elev])[0,0], Y0 = (*spaxels.ycoords[i,j,k,it_elev])[0,0], $
                                                 FIT_PARAMETERS = best_parameters, $
                                                 /QUIET, $
                                ;                              /anti_stuck, $
                                                 ERROR_FLAG = my_other_error_flag) ;
                       
                       PSFs[i,j,k] = ptr_current_PSF
                       fitted_spaxels.values[i,j,k,it_elev] = ptr_fitted_PSF
                       fitted_spaxels.xcentroids[i,j,k,it_elev] = best_parameters[0]
                       fitted_spaxels.ycentroids[i,j,k,it_elev] = best_parameters[1]
                       fitted_spaxels.intensities[i,j,k,it_elev] = best_parameters[2]
;                fit_error_flag[i,j,k] = my_other_error_flag                       

; #########################################                       
; FROM HERE TO THE ENDFOR IS JUST DEBUGGING
; #########################################
; 
;
;                       value_to_consider = where(*spaxels.masks[i,j,k,it_elev] eq 1)
;                       if value_to_consider[0] ne -1 then begin
;                          diff_image[ (*spaxels.xcoords[i,j,k,it_elev])[value_to_consider], (*spaxels.ycoords[i,j,k,it_elev])[value_to_consider] ] = (*spaxels.values[i,j,k,it_elev])[value_to_consider] - (spaxels.sky_values[i,j,k,it_elev])[value_to_consider]-((*ptr_fitted_PSF)*(*spaxels.masks[i,j,k,it_elev]))[value_to_consider]
;                                ; what is new image?
;                          new_image[ (*spaxels.xcoords[i,j,k,it_elev])[value_to_consider], (*spaxels.ycoords[i,j,k,it_elev])[value_to_consider] ] += ((*ptr_fitted_PSF)*(*spaxels.masks[i,j,k,it_elev]))[value_to_consider]
;                       
;                                ; calculate the stddev
;;                            stddev_arr=fltarr(281,281,kmax+1,nfiles,it_max,it_flex_max)
;
;                             ; interested in the weighted stddev
;                             ; weight by intensity
;                          mask0=(*spaxels.masks[i,j,k,it_elev])
;                          mask0[where(mask0 eq 0)]=!values.f_nan
;                          mask=(*spaxels.masks[i,j,k,it_elev])[value_to_consider]
;                          sz=size(mask0)
;
;;                          weights0=reform((*spaxels.values[i,j,k,it_elev]) - (spaxels.sky_values[i,j,k,it_elev]),sz[1],sz[2])*mask0
;;                          weights=((*spaxels.values[i,j,k,it_elev])[value_to_consider] - (spaxels.sky_values[i,j,k,it_elev])[value_to_consider])*mask
;                          gain=float(backbone->get_keyword('sysgain'))
;                          weights0=sqrt((*ptr_fitted_PSF)*gain)/gain
;                          weights=sqrt((*ptr_fitted_PSF)[value_to_consider]*gain)/gain
;
;                          intensity0=reform((*spaxels.values[i,j,k,it_elev]) - (spaxels.sky_values[i,j,k,it_elev]),sz[1],sz[2])*mask0
;                          intensity=((*spaxels.values[i,j,k,it_elev])[value_to_consider] - (spaxels.sky_values[i,j,k,it_elev])[value_to_consider])*mask
;
;                          diff0=mask0*(reform((*spaxels.values[i,j,k,it_elev]) - (spaxels.sky_values[i,j,k,it_elev]),sz[1],sz[2])-(*ptr_fitted_PSF))
;                          diff=(*spaxels.values[i,j,k,it_elev])[value_to_consider] - (spaxels.sky_values[i,j,k,it_elev])[value_to_consider]-((*ptr_fitted_PSF)*(*spaxels.masks[i,j,k,it_elev]))[value_to_consider]
;                          model=(*ptr_fitted_PSF)*mask
;                          w_mean=total(diff*weights,/nan)/total(weights,/nan)/total(mask,/nan)
;                          intensity_arr[i,j,k,it_elev,it,it_flex]=total(intensity*weights,/nan)/total(weights,/nan)
;                          stddev_arr[i,j,k,it_elev,it,it_flex]= total(weights*(diff-w_mean)^2.0,/nan)/total(weights,/nan)
;                          diff_intensity_arr[i,j,k,it_elev,it,it_flex]=total(weights*diff,/nan)/total(weights)
;;if i eq 150 and j eq 150 and it eq it_max-1 and it_elev eq nfiles-1 and it_flex eq it_flex_max-1 then stop
;
;                             if i eq 150 and j eq 150 and it_elev eq 0 and it_flex eq it_flex_max-1 then begin
;                                loadct,0
;                                window,1,retain=2,xsize=300,ysize=300,title='orig- '+strc(i)+', '+strc(j)
;                                sz=(*spaxels.values[150,150])
;                                mask=(*spaxels.masks[i,j,k,it_elev])
;                                orig=mask*(*spaxels.values[i,j,k,it_elev])
;                                tvdl,orig,min(orig,/nan),max(orig,/nan)
;                                
;                                window,3,retain=3,xsize=300,ysize=300,title='model- '+strc(i)+', '+strc(j)
;                                fit=((*ptr_fitted_PSF)*(*spaxels.masks[i,j,k,it_elev]))
;                                tvdl,fit,min(orig,/nan),max(orig,/nan)
;                                window,2,retain=2,xsize=300,ysize=300,title='percentage residuals- '+strc(i)+', '+strc(j)
;                                sky=mask*(spaxels.sky_values[i,j,k,it_elev])
;                                tvdl,mask*(orig-sky-fit)/fit,-0.1,0.1
;;                                stop
;                             endif ; display if
;                          endif    ; check for no dead values
                    endfor ; loop to fit psfs
                 endif     ; check to see if there are any intensities in the slice
              endfor ; end loop over j lenslets (columns?)
           endfor ; end loop over i lenslsets (rows?)
        endfor ; end loop over spots (1 for spectra, 2 for polarization)
        
        print, 'Iteration complete in '+strc((systime(1)-time0)/60.)+' minutes'
                                ; put the fitted values into the originals before re-iterating
        spaxels.xcentroids = fitted_spaxels.xcentroids
        spaxels.ycentroids = fitted_spaxels.ycentroids
        spaxels.intensities= fitted_spaxels.intensities
        
     endfor ; end loop over flexure iterations
     
                                ; if we are on the last interation for
                                ; the flexure - do we want to end
                                ;               here? I don't
                                ;               think so because we
                                ;               want the centroids to
                                ;               be at their best
                                ;               positions and the
                                ;               flexures to be updated

     ;set the first file as the reference image/elevation.
     ;All the transformations to go from one elevation to another are computed from that image or to that image.
     not_null_ptrs = where(finite(spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,0]), n_not_null_ptrs) ; select only the lenslets for which we have a calibration.
     ;The previous index vector will be used for all the images so it should be valid for all of them.
     ;This should be fine if the all the images were computed using the same wavelnegth solution wich could be shifted using the lookup table.
     xcen_ref = (spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,0])[not_null_ptrs] ;get the centroids coordinates (it's the only thing we need for this step)
     ycen_ref = (spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,*,0])[not_null_ptrs]
;     xcen_ref_rel = xcen_ref - spaxels.xcentroids[140,140,0,0]
;     ycen_ref_rel = ycen_ref - spaxels.ycentroids[140,140,0,0]
     
                                ;declare the variables
;     shift_x = fltarr(nfiles)
;     shift_y = fltarr(nfiles)
;     tip = fltarr(nfiles)
;     tilt = fltarr(nfiles)
;     shift_x[0] = 0.0
;     shift_y[0] = 0.0
;     tip[0] = 1.0
;     tilt[0] = 1.0
     
     
;     xtransf_ref_to_im = fltarr(3,nfiles)
;     xtransf_im_to_ref = fltarr(3,nfiles)
;     ytransf_ref_to_im = fltarr(3,nfiles)
;     ytransf_im_to_ref = fltarr(3,nfiles)

     degree_of_the_polynomial_fit = 2 ; degree of the polynomial surface used for the flexure correction
     ;declare the arrays which will contain the coefficients of the polynomial surface for every single image (ie elevation)
     ;The third dimension indicated which file to consider
     xtransf_ref_to_im = fltarr(degree_of_the_polynomial_fit+1,degree_of_the_polynomial_fit+1,nfiles) ;How to get the x coordinates of the centroids of the reference image into the current image (cf 3rd dimension index to select the image). 
     xtransf_im_to_ref = fltarr(degree_of_the_polynomial_fit+1,degree_of_the_polynomial_fit+1,nfiles) ;How to get the x coordinates of the centroids of the current image into the reference one. 
     ytransf_ref_to_im = fltarr(degree_of_the_polynomial_fit+1,degree_of_the_polynomial_fit+1,nfiles) ;How to get the y coordinates of the centroids of the reference image into the current image (cf 3rd dimension index to select the image). 
     ytransf_im_to_ref = fltarr(degree_of_the_polynomial_fit+1,degree_of_the_polynomial_fit+1,nfiles) ;How to get the y coordinates of the centroids of the current image into the reference one. 
     ;JB: Inverting the transformation analytically is dangerous because some of the coefficients are really close to zero so you may divide stuff by really small numbers.
     ; It tended to increase the noise. That's why we compute the two transformations im->ref and ref->im independentaly without using an inverse.
     
     
     ; The transformation of the reference image into the reference one should be identity
     xtransf_ref_to_im[1,0,0] = 1
     xtransf_im_to_ref[1,0,0] = 1
     ytransf_ref_to_im[0,1,0] = 1
     ytransf_im_to_ref[0,1,0] = 1
     
     ;declare the two variables defining the mean. They will be set in the next loop by adding the contribution of each elevation to the mean
     mean_xcen_ref = xcen_ref/nfiles
     mean_ycen_ref = ycen_ref/nfiles
     
     
     ;loop over the other images with different elevations
     ;We first compute the flexure transformation and then add the contribution of the current image to the mean position of the centroids.
     ;at the end of this loop we have all the transformation im->ref and ref>im for all the elevations and the mean position of the centroid in the reference image.
     for it_elev = 1,nfiles-1 do begin
     
     ;Different methods were tried to compute the flexure correction. THey are commented.
     ;The current one use a 2d polynomial surface. Contrary to the linear interpolation (shift + tip/tilt), it takes into account the distortion in x depending on y (and y on x).
     
;//////////////////////////independant axes lin fit with origin in the middle of the detector
;        not_null_ptrs = where(finite(spaxels.xcentroids[*,*,k,0]), n_not_null_ptrs)
;        xcen_ref = (spaxels.xcentroids[*,*,k,0])[not_null_ptrs]
;        ycen_ref = (spaxels.ycentroids[*,*,k,0])[not_null_ptrs]
;        xcen = (spaxels.xcentroids[*,*,k,it_elev])[not_null_ptrs]
;        ycen = (spaxels.ycentroids[*,*,k,it_elev])[not_null_ptrs]
;          
;          window,0
;          plot, xcen_ref, (xcen_ref - xcen) , psym = 3
;          window,1
;          plot,  (ycen_ref - ycen),ycen_ref, psym = 3
;          
;          coef_linfit = linfit(xcen_ref, xcen)
;          tip = coef_linfit[1]
;          shift_x = coef_linfit[0]/tip
;          
;          coef_linfit = linfit(ycen_ref, ycen)
;          tilt = coef_linfit[1]
;          shift_y = coef_linfit[0]/tilt
;          
;          new_xcen = (xcen - shift_x)/tip
;          new_ycen = (ycen - shift_y)/tilt
;          window,3
;          plot, xcen_ref, (xcen_ref - new_xcen), psym = 3
;          window,4
;          plot,  (ycen_ref - new_ycen),ycen_ref, psym = 3
        
        
;//////////////////////////independant axes lin fit
;        xcen = (spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,it_elev])[not_null_ptrs]
;        ycen = (spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,*,it_elev])[not_null_ptrs]
;        xcen_rel = xcen - spaxels.xcentroids[140,140,0,0]
;        ycen_rel = ycen - spaxels.ycentroids[140,140,0,0]
;        
;        coef_linfit = linfit(xcen_ref_rel, xcen_rel)
;        tip[it_elev] = coef_linfit[1]
;        shift_x[it_elev] = coef_linfit[0]/tip[it_elev]
;        
;        coef_linfit = linfit(ycen_ref_rel, ycen_rel)
;        tilt[it_elev] = coef_linfit[1]
;        shift_y[it_elev] = coef_linfit[0]/tilt[it_elev]
;        
;        new_xcen_rel = (xcen_rel/tip[it_elev] - shift_x[it_elev])
;        new_ycen_rel = (ycen_rel/tilt[it_elev] - shift_y[it_elev])
;        new_xcen = spaxels.xcentroids[140,140,0,0] + new_xcen_rel
;        new_ycen = spaxels.ycentroids[140,140,0,0] + new_ycen_rel
;        
;        mean_xcen_ref = mean_xcen_ref+new_xcen/nfiles
;        mean_ycen_ref = mean_ycen_ref+new_ycen/nfiles
;        
;          window,0
;          plot, xcen_ref_rel, (xcen_ref_rel - xcen_rel) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;          window,1
;          plot,  (ycen_ref_rel - ycen_rel),ycen_ref_rel, psym = 3;, xrange = [0.2-0.6,0.2+0.6]
;          ;legend, ['ref','current elev'], psym = [1,3]
;          window,3
;          plot, xcen_ref_rel, (xcen_ref_rel - new_xcen_rel), psym = 3;, yrange = [-0.6,0.6]
;          window,4
;          plot,  (ycen_ref_rel - new_ycen_rel),ycen_ref_rel, psym = 3;, xrange = [-0.6,0.6]
;          window,7 
;          tvdl, (spaxels.xcentroids[*,*,0,0] - spaxels.xcentroids[*,*,0,4] + shift_x[it_elev])>(-0.1)<0.1
;          window,8
;          tvdl, (spaxels.ycentroids[*,*,0,0] - spaxels.ycentroids[*,*,0,4] + shift_y[it_elev])>(-0.1)<0.1


;//////////////////////////independant axes poly fit
;        xcen = (spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,it_elev])[not_null_ptrs]
;        coef_polyfit = poly_fit(xcen_ref, xcen,2,yfit = myfit1)
;        xcen_ref_in_im = poly(xcen_ref,coef_polyfit)
;;        delta = coef_polyfit[1]^2-4*coef_polyfit[2]*(coef_polyfit[0]-xcen)
;;        if coef_polyfit[2] gt 0.0 then new_xcen = (-coef_polyfit[1]+sqrt(delta))/(2*coef_polyfit[2]) else new_xcen = (-coef_polyfit[1]-sqrt(delta))/(2*coef_polyfit[2])
;        xtransf_ref_to_im[*,it_elev] = coef_polyfit
;        coef_polyfit = poly_fit(xcen,xcen_ref,2,yfit = myfit2)
;        xcen_in_ref = poly(xcen,coef_polyfit)
;        xtransf_im_to_ref[*,it_elev] = coef_polyfit
;     
;        ;in reference space
;        window,0
;        plot, xcen_ref, (xcen - xcen_ref) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, xcen_ref, (myfit1 - xcen_ref), psym = 7, color = 150
;        window,1
;        plot, xcen_ref, (xcen_ref - xcen_in_ref) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;        ;in current image space
;        window,0
;        plot, xcen_ref, (xcen - xcen_ref) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, xcen_ref, (myfit2 - xcen_ref), psym = 7, color = 150
;        window,1
;        plot, xcen_ref_in_im, (xcen_ref_in_im - xcen) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;        ycen = (spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,*,it_elev])[not_null_ptrs]
;        coef_polyfit = poly_fit(ycen_ref, ycen,2,yfit = myfit3)
;        ycen_ref_in_im = poly(ycen_ref,coef_polyfit)
;;        delta = coef_polyfit[1]^2-4*coef_polyfit[2]*(coef_polyfit[0]-ycen)
;;        if coef_polyfit[2] gt 0.0 then new_ycen = (-coef_polyfit[1]+sqrt(delta))/(2*coef_polyfit[2]) else new_ycen = (-coef_polyfit[1]-sqrt(delta))/(2*coef_polyfit[2])
;        ytransf_ref_to_im[*,it_elev] = coef_polyfit
;        coef_polyfit = poly_fit(ycen,ycen_ref,2,yfit = myfit4)
;        ycen_in_ref = poly(ycen,coef_polyfit)
;        ytransf_im_to_ref[*,it_elev] = coef_polyfit
;        
;        mean_xcen_ref = mean_xcen_ref+xcen_in_ref/nfiles
;        mean_ycen_ref = mean_ycen_ref+ycen_in_ref/nfiles
;        
;        ;in reference space
;        window,0
;        plot, (ycen - ycen_ref), ycen_ref , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, (myfit3 - ycen_ref), ycen_ref, psym = 7, color = 150
;        window,1
;        plot, (ycen_ref - ycen_in_ref), xcen_ref , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;        ;in current image space
;        window,0
;        plot, (ycen - ycen_ref), ycen_ref , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, (myfit4 - ycen_ref), ycen_ref, psym = 7, color = 150
;        window,1
;        plot, (ycen_ref_in_im - ycen), ycen_ref_in_im , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;          window,7 
;          tvdl, (spaxels.xcentroids[*,*,0,0] - spaxels.xcentroids[*,*,0,3])
;          window,8
;          tvdl, (spaxels.ycentroids[*,*,0,0] - spaxels.ycentroids[*,*,0,3])
        
;//////////////////////////independant axes surface fit
        ;Get the centroids of the current image (ie elevation)
        xcen = (spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,it_elev])[not_null_ptrs]
        ycen = (spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,*,it_elev])[not_null_ptrs]
        
        ;First block computes the transformation from the reference to the current image for the x coordinates
        data_sfit = [transpose(xcen_ref), transpose(ycen_ref),transpose(xcen)] ;Prepare the input for the sfit fitting function. xcen is function of xcen_ref and ycen_ref.
        xcen_sfit = SFIT( data_sfit, degree_of_the_polynomial_fit, /IRREGULAR, KX=coef_sfit ) ;Fitting function with a polynamial surface of degree "degree_of_the_polynomial_fit".
        xtransf_ref_to_im[*,*,it_elev] = coef_sfit ;Store the resulting coefficients into our own variable
        xcen_ref_in_im = fltarr(n_elements(xcen_ref)) ;declare the new list of x coordinates for the centroids of the reference image transformed for the current image elevation.
        ;Loop to compute xcen_ref_in_im using the previous coefficients. It only computes a 2d polynom.
        ;JB: If someone now a real function to do that, feel free to change.
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do xcen_ref_in_im += xtransf_ref_to_im[i,j,it_elev]*xcen_ref^j * ycen_ref^i
        
        ;Second block, x coordinates, from the image to the reference. (See first block for complete description)
        data_sfit = [transpose(xcen), transpose(ycen),transpose(xcen_ref)]
        xcen_ref_sfit = SFIT( data_sfit, degree_of_the_polynomial_fit, /IRREGULAR, KX=coef_sfit )
        xtransf_im_to_ref[*,*,it_elev] = coef_sfit
        xcen_in_ref = fltarr(n_elements(xcen_ref))
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do xcen_in_ref += xtransf_im_to_ref[i,j,it_elev]*xcen^j * ycen^i
        
        ;Third block, y coordinates, ref to im. (See first block for complete description)
        data_sfit = [transpose(xcen_ref), transpose(ycen_ref),transpose(ycen)]
        ycen_sfit = SFIT( data_sfit, degree_of_the_polynomial_fit, /IRREGULAR, KX=coef_sfit )
        ytransf_ref_to_im[*,*,it_elev] = coef_sfit
        ycen_ref_in_im = fltarr(n_elements(xcen_ref))
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do ycen_ref_in_im += ytransf_ref_to_im[i,j,it_elev]*xcen_ref^j * ycen_ref^i
        
        ;Fourth block, y coordinates, im to ref. (See first block for complete description)
        data_sfit = [transpose(xcen), transpose(ycen),transpose(ycen_ref)]
        ycen_ref_sfit = SFIT( data_sfit, degree_of_the_polynomial_fit, /IRREGULAR, KX=coef_sfit )
        ytransf_im_to_ref[*,*,it_elev] = coef_sfit
        ycen_in_ref = fltarr(n_elements(xcen_ref))
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do ycen_in_ref += ytransf_im_to_ref[i,j,it_elev]*xcen^j * ycen^i

        mean_xcen_ref = mean_xcen_ref+xcen_in_ref/nfiles
        mean_ycen_ref = mean_ycen_ref+ycen_in_ref/nfiles

;       ;The next few lines are there to be copy pasted in the console after a stop to test flexure correction with wavelength solution.
;        a = readfits("/Users/jruffio/Shared_with_JB/S20130329S0046-H--wavecal.fits",exten_no=1)
;        b = readfits("/Users/jruffio/Shared_with_JB/S20130329S0048-H--wavecal.fits",exten_no=1)
;        xa = a[*,*,1]
;        ya = a[*,*,0]
;        xb = b[*,*,1]
;        yb = b[*,*,0]
;          window,8
;          tvdl, (xb - xa)
;          window,9
;          tvdl, (yb - ya)
;     not_null_ptrs = where(finite(xa) and finite(xb), n_not_null_ptrs)
;     xcen_ref = (xa)[not_null_ptrs]
;     ycen_ref = (ya)[not_null_ptrs]
;     xcen = (xb)[not_null_ptrs]
;     ycen = (yb)[not_null_ptrs]



;////////////PLOTS PLOTS PLOTS PLOTS///////////////////
;          ;Plot in lenslet space the difference between the current image and the reference.
;          window,8
;          tvdl, (spaxels.xcentroids[*,*,0,0] - spaxels.xcentroids[*,*,0,it_elev])
;          window,9
;          tvdl, (spaxels.ycentroids[*,*,0,0] - spaxels.ycentroids[*,*,0,it_elev])
;        
;        ;The plots show the residuals in a 1d plot using different axes.
;        ;in reference space
;            ;x shift
;        window,0
;        plot, xcen_ref, (xcen - xcen_ref) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, xcen_ref, (xcen_sfit - xcen_ref), psym = 3, color = 150
;        window,1
;        plot, xcen_ref, (xcen_in_ref - xcen_ref) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;        window,2
;        plot, ycen_ref, (xcen - xcen_ref) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, ycen_ref, (xcen_sfit - xcen_ref), psym = 7, color = 150
;        window,3
;        plot, ycen_ref, (xcen_in_ref - xcen_ref) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;            ;y shift
;        window,4
;        plot, (ycen - ycen_ref), ycen_ref, psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, (ycen_sfit - ycen_ref), ycen_ref, psym = 3, color = 150
;        window,5
;        plot, (ycen_in_ref - ycen_ref), ycen_ref , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;        window,6
;        plot, (ycen - ycen_ref), xcen_ref , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, (ycen_sfit - ycen_ref), xcen_ref, psym = 7, color = 150
;        window,7
;        plot, (ycen_in_ref - ycen_ref), xcen_ref , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;        ;in image space
;            ;x shift
;        window,0
;        plot, xcen, (xcen_ref - xcen) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, xcen, (xcen_ref_sfit - xcen), psym = 3, color = 150
;        window,1
;        plot, xcen, (xcen_ref_in_im - xcen) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;        window,2
;        plot, ycen, (xcen_ref - xcen) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, ycen, (xcen_ref_sfit - xcen), psym = 7, color = 150
;        window,3
;        plot, ycen, (xcen_ref_in_im - xcen) , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;            ;y shift
;        window,4
;        plot, (ycen_ref - ycen), ycen, psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, (ycen_ref_sfit - ycen), ycen, psym = 3, color = 150
;        window,5
;        plot, (ycen_ref_in_im - ycen), ycen , psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        
;        window,6
;        plot, (ycen_ref - ycen), xcen_ref, psym = 3;, yrange = [0.8-0.6,0.8+0.6]
;        oplot, (ycen_ref_sfit - ycen), xcen, psym = 7, color = 150
;        window,7
;        plot, (ycen_ref_in_im - ycen), xcen, psym = 3;, yrange = [0.8-0.6,0.8+0.6]
        

; Test  using rotation matrix to go from an image to another
;  loadct, 3
;          X0 = [[new_xcen_rel],[new_ycen_rel]]
;          th =  -0.0005 / (180.*3.14)
;          res_rot = [[cos(th), -sin(th)],[sin(th),cos(th)]]#transpose(X0)
;          new_xcen_rel_rot = reform(res_rot[0,*],1,n_elements(res_rot[0,*]))
;          new_ycen_rel_rot = reform(res_rot[1,*],1,n_elements(res_rot[0,*]))
;          window,5
;          plot, xcen_ref_rel, (xcen_ref_rel - new_xcen_rel_rot), psym = 3, yrange = [-0.5,0.5]
;          window,6
;          plot,  (ycen_ref_rel - new_ycen_rel_rot),ycen_ref, psym = 3, xrange = [-0.5,0.5]  
     endfor
     
     
;  res_fit = CURVEFIT( xcen_ref - floor(xcen_ref), xcen_ref-mean_xcen_ref, xcen_ref*0.0 + 1.0, [0.01], FUNCTION_NAME="jb_sin" , /noderivative)


;  ;plot the pixel phase error of the reference and of the last computed image in the loop.
;  window, 10 ;pixel phase of the reference in the reference
;  plot, mean_xcen_ref - floor(mean_xcen_ref) ,xcen_ref-mean_xcen_ref, psym = 3
;  window, 11 ;pixel phase of the image in the reference
;  plot, mean_xcen_ref - floor(mean_xcen_ref) ,xcen_in_ref-mean_xcen_ref, psym = 3
;  window, 12 ;pixel phase of the image in the image (it means we have to get the mean in the image space first)
;  mean_xcen_ref_in_im = fltarr(n_elements(xcen_ref))
;  for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do mean_xcen_ref_in_im += xtransf_ref_to_im[i,j,it_elev]*xcen_ref^j * ycen_ref^i
;  plot, mean_xcen_ref_in_im - floor(mean_xcen_ref_in_im) ,xcen-mean_xcen_ref_in_im, psym = 3

    ;THE RESULT OF THE NEXT LOOP HAS NOT BEEN CHECK YET.
     x_id = not_null_ptrs mod 281
     y_id = not_null_ptrs / 281
     z_id = not_null_ptrs / (281L*281L)
     for it_elev = 0,nfiles-1 do begin
;        spaxels.xcentroids[x_id,y_id,z_id,lonarr(n_elements(x_id))+it_elev] = tip[it_elev]*(mean_xcen_ref + shift_x[it_elev])
;        spaxels.ycentroids[x_id,y_id,z_id,lonarr(n_elements(x_id))+it_elev] = tip[it_elev]*(mean_ycen_ref + shift_x[it_elev])
        
;        spaxels.xcentroids[x_id,y_id,z_id,lonarr(n_elements(x_id))+it_elev] = poly(mean_xcen_ref,xtransf_ref_to_im[*,it_elev])
;        spaxels.ycentroids[x_id,y_id,z_id,lonarr(n_elements(x_id))+it_elev] = poly(mean_ycen_ref,ytransf_ref_to_im[*,it_elev])
        
        mean_xcen_ref_in_im = fltarr(n_elements(xcen_ref))
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do mean_xcen_ref_in_im += xtransf_ref_to_im[i,j,it_elev]*xcen_ref^j * ycen_ref^i
        mean_ycen_ref_in_im = fltarr(n_elements(xcen_ref))
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do mean_ycen_ref_in_im += ytransf_ref_to_im[i,j,it_elev]*xcen_ref^j * ycen_ref^i
        spaxels.xcentroids[x_id,y_id,z_id,lonarr(n_elements(x_id))+it_elev] = mean_xcen_ref_in_im
        spaxels.ycentroids[x_id,y_id,z_id,lonarr(n_elements(x_id))+it_elev] = mean_ycen_ref_in_im
     endfor
     
     ;//////STOP HERE if you want to play with the pixel phase plots or the centroid coordinates in the different images.
     stop
     
  endfor

  
     print, 'Run complete in '+strc((systime(1)-time0)/60.)+' minutes'
     
     writefits, "diff_image.fits",diff_intensity_arr
     writefits, "intensity_arr.fits",intensity_arr
     writefits, "stddev_arr.fits",stddev_arr

; #######################
; BUILD THE FLAT FIELD
; ######################
                          ; calculate flat field - only on last iteration
     if flat_field eq 1 then begin
                                ; because we cannot extract arrays
                                ; from arrays of pointers, we have to
                                ; extract them using loops
; probably best to create 1 flat per elevation - which was done in the
;                                                flat_field_arr
; but might have overlap as some pixels will have been used twice
        flat_field_arr2=fltarr(2048,2048,nfiles)
        for it_elev=0, nfiles-1 do begin
           for k=0,kmax do for i=0,281-1 do for j=0,281-1 do begin
                                ; find values are are not masked.
              if ptr_valid(spaxels.masks[i,j,k,it_elev]) eq 0 then continue
              value_to_consider = where(*spaxels.masks[i,j,k,it_elev] eq 1)
              if value_to_consider[0] ne -1 then begin
                 flat_field_arr2[ (*spaxels.xcoords[i,j,k,it_elev])[value_to_consider], (*spaxels.ycoords[i,j,k, it_elev])[value_to_consider], replicate(it_elev,N_ELEMENTS(value_to_consider)) ] = ((*spaxels.values[i,j,k,it_elev])[value_to_consider] - (spaxels.sky_values[i,j,k,it_elev]) )/((*fitted_spaxels.values[i,j,k,it_elev]))[value_to_consider]
              endif      
           endfor
        endfor
; so now loop over each pixel and calculate the weighted mean
        final_flat=fltarr(2048,2048)
        weights=fltarr(2048,2048,nfiles)
        for n=0,nfiles-1 do weights[*,*,n]=(*(dataset.frames[n]))
        
        final_flat2=total(weights*flat_field_arr2,3)/total(weights,3)
           writefits, "flat_field_arr.fits",flat_field_arr
        endif

        
        
  stop
;  writefits, "/home/LAB/Desktop/diff_image7.fits",diff_image
;  writefits, "/home/LAB/Desktop/new_image.fits",new_image
;  writefits, "/users/jruffio/Desktop/diff_image7.fits",diff_image
;  writefits, "/users/jruffio/Desktop/new_image.fits",new_image
                                ;evaluate_psf(spaxels.xcoords[*,*,i,j,k], spaxels.ycoords[*,*,i,j,k], [current_x_centroid,current_y_centroid,current_intensity])
;  fiterr = fltarr(5,5,2)
;  fiterr = fltarr(5,5,1)
;  for k = 0,1 do for i=171,175 do for j=171,175 do fiterr[i-171,j-171,k] = total(spaxels.values[*,*,i,j,k])
;  for k = 0,1 do for i=171,175 do for j=171,175 do fiterr[i-171,j-171,k] = total(abs(spaxels.values[*,*,i,j,k] - fitted_values[*,*,i,j,k]))/total(spaxels.values[*,*,i,j,k])
;  for k = 0,0 do for i=171,175 do for j=171,175 do fiterr[i-171,j-171,k] = total(abs(spaxels.values[*,*,i,j,k] - fitted_values[*,*,i,j,k]))/total(spaxels.values[*,*,i,j,k])
;  spaxels.values[*,*,171,171,0]
;  fitted_values[*,*,171,171,0]
;  stddev((*spaxels.values[171,171,0]-*fitted_spaxels.values[171,171,0])[where((*spaxels.masks[171,171,0]) eq 1)])
;fit_error_flag[171:175,171:175,0]
;fitted_spaxels.xcentroids[171:175,171:175,0]
;spaxels.masks[*,*,175,175,0]
;  stop

  valid_psfs = where(ptr_valid(PSFs), n_valid_psfs)
  
  to_save_psfs = replicate(*PSFs[valid_psfs[0]],n_valid_psfs)
  
  for i=0,n_valid_psfs-1 do begin
     to_save_psfs[i] = *PSFs[valid_psfs[i]]
  endfor
  
  backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
  gpicaldb = Backbone_comm->Getgpicaldb()
  s_OutputDir = gpicaldb->get_calibdir()
                                ; ensure we have a directory separator, if it's not there already
  if strmid(s_OutputDir, strlen(s_OutputDir)-1,1) ne path_sep() then s_OutputDir+= path_sep()
  filenm = dataset.filenames[numfile]
                                ; Generate output filename
                                ; remove extension if need be
  base_filename = file_basename(filenm)
  extloc = strpos(base_filename,'.', /reverse_search)
  
  nrw_filt=strmid(strcompress(string(filter_wavelength),/rem),0,5)
  my_file_name = s_OutputDir + strmid(filenm,0,extloc)+ '-'+filter+'-'+nrw_filt+'um-PSFs'+'.fits'
  mwrfits,to_save_psfs, my_file_name,*(dataset.headersExt[numfile]), /create
  
;  psfs_from_file = read_psfs(my_file_name, [281,281,1])
 
  
  my_file_name = s_OutputDir + strmid(filenm,0,extloc)+ '-'+filter+'-'+'Spaxels'+'.fits'
  save, spaxels, filename=my_file_name
  
  my_file_name = s_OutputDir + strmid(filenm,0,extloc)+ '-'+filter+'-'+'Fitted_s paxels'+'.fits'
  save, fitted_spaxels, filename=my_file_name

 ; cant save these files as fits since they're not pointers 
;  mwrfits,spaxels, my_file_name,*(dataset.headersExt[numfile])
;  
;  mwrfits,fitted_spaxels, my_file_name,*(dataset.headersExt[numfile])
;  stop
  ;how to read the fits with the psfs
;  rawarray =mrdfits(my_file_name,1)
;  PSFs = reform(rawarray, 281,281,2or1)
;  one_psf = PSFs[171,171,0].values
;  tvdl, one_psf
  
                                ;----- store the output into the backbone datastruct
  suffix = '-'+filter+'-'+'PSF_residuals'
  *(dataset.currframe)=diff_image
  dataset.validframecount=1
  backbone->set_keyword, "FILETYPE", "PSF residuals", /savecomment
  backbone->set_keyword, "ISCALIB", 'NO', 'This is NOT a reduced calibration file of some type.'
  
@__end_primitive
end


;//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;//////////////////////////////LOCAL DISTORTION = PROBABLY USELESS ////////////////////////////////////////////////////////////
;  ;loop over the lenslets
;  for k=0,kmax do begin
;    for i=171,175 do begin
;    statusline, "Correct centroids with flexure: Fitting line "+strc(i+1)+" of 281 and spot "+strc(k+1)+" of "+strc(kmax+1)+" for iteration flex" +strc(it_flex+1)+" of "+strc(it_max+1)
;      for j=171,175 do begin
;        if spaxels.intensities[i,j,k] ne 0.0 then begin
;        imin = max([0,(i-n_neighbors_flex)])
;        imax = min([280,(i+n_neighbors_flex)])
;        jmin = max([0,(j-n_neighbors_flex)])
;        jmax = min([280,(j+n_neighbors_flex)])
;        nspaxels = (imax-imin+1)*(jmax-jmin+1)
;        
;        not_null_ptrs = where(finite(spaxels.xcentroids[imin:imax,jmin:jmax,k,0]), n_not_null_ptrs)
;        xcen_ref = (spaxels.xcentroids[imin:imax,jmin:jmax,k,0])[not_null_ptrs]
;        ycen_ref = (spaxels.ycentroids[imin:imax,jmin:jmax,k,0])[not_null_ptrs]
;        
;        ;loop over the other images with different elevations
;        for it_elev = 1,nfiles-1 do begin
;          xcen = (spaxels.xcentroids[imin:imax,jmin:jmax,k,it_elev])[not_null_ptrs]
;          ycen = (spaxels.ycentroids[imin:imax,jmin:jmax,k,it_elev])[not_null_ptrs]
;          
;          ;loadct, 3
;          window,0
;          plot, xcen_ref - spaxels.xcentroids[i,j,k,0], ycen_ref - spaxels.ycentroids[i,j,k,0], psym = 1
;          oplot, xcen - spaxels.xcentroids[i,j,k,it_elev], ycen - spaxels.ycentroids[i,j,k,it_elev], psym = 3;, color = 150
;          oplot, xcen_ref - spaxels.xcentroids[i,j,k,0], (xcen_ref - xcen) * 100, psym = 3
;          oplot,  (ycen_ref - ycen) * 100,ycen_ref - spaxels.ycentroids[i,j,k,0], psym = 3
;          ;legend, ['ref','current elev'], psym = [1,3]
;          
;          xcen_ref_rel = xcen_ref - spaxels.xcentroids[i,j,k,0]
;          xcen_rel = xcen - spaxels.xcentroids[i,j,k,0]
;          ycen_ref_rel = ycen_ref - spaxels.ycentroids[i,j,k,0]
;          ycen_rel = ycen - spaxels.ycentroids[i,j,k,0]
;          
;          coef_linfit = linfit(xcen_ref_rel, xcen_rel)
;          tip = coef_linfit[1]
;          shift_x = coef_linfit[0]/tip
;          
;          coef_linfit = linfit(ycen_ref_rel, ycen_rel)
;          tilt = coef_linfit[1]
;          shift_y = coef_linfit[0]/tilt
;          
;;          new_xcen = spaxels.xcentroids[i,j,k,0] + (xcen - spaxels.xcentroids[i,j,k,0] - shift_x)/tip
;;          new_ycen = spaxels.ycentroids[i,j,k,0] + (ycen - spaxels.ycentroids[i,j,k,0] - shift_y)/tilt
;;          window,1
;;          plot, xcen_ref - spaxels.xcentroids[i,j,k,0], ycen_ref - spaxels.ycentroids[i,j,k,0], psym = 1
;;          oplot, new_xcen - spaxels.xcentroids[i,j,k,it_elev], new_ycen - spaxels.ycentroids[i,j,k,it_elev], psym = 3;, color = 150
;;          oplot, xcen_ref - spaxels.xcentroids[i,j,k,0], (xcen_ref - new_xcen) * 100, psym = 3
;;          oplot,  (ycen_ref - new_ycen) * 100,ycen_ref - spaxels.ycentroids[i,j,k,0], psym = 3
;          
;        endfor
;  
;        endif
;      endfor
;    endfor
;  endfor
;//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
