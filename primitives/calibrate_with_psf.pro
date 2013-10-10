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
        sub_pix_res_x = 5
        sub_pix_res_y = 5
        cent_mode = "BARYCENTER"
                                ; raw data stamps
        if nfiles ge 2 then begin
					time0=systime(1,/seconds)
           spaxels = get_spaxels(my_first_mode, dataset.frames[0:(nfiles-1)], dataset.wavcals[0:(nfiles-1)], width_PSF, /STAMPS_MODE) 
  				time_cut=systime(1,/seconds)-time0
			 endif else $
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
  
  n_neighbors = 3               ; number on each side - so 4 gives a 9x9 box - 3 gives a 7x7 box
;  n_neighbors_flex = 3          ; for the flexure shift determination - not currently used

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
  if nfiles eq 1 then it_flex_max=1
; make an array to look at the stddev as a function of iterations

  if flat_field eq 1 then flat_field_arr=fltarr(2048,2048,nfiles)
  
debug=1
  if debug eq 1 then begin
 ; create a series of arrays to evaluate the fits for each iteration
                                ; want to watch how the weighted
                                ; STDDEV decreases with iterations etc
     stddev_arr=fltarr(281,281,kmax+1,nfiles,it_max,it_flex_max)
     intensity_arr=fltarr(281,281,kmax+1,nfiles,it_max,it_flex_max)
		 weighted_intensity_arr=fltarr(281,281,kmax+1,nfiles,it_max,it_flex_max)
     diff_intensity_arr=fltarr(281,281,kmax+1,nfiles,it_max,it_flex_max)
     weighted_diff_intensity_arr=fltarr(281,281,kmax+1,nfiles,it_max,it_flex_max)
  endif

; ########################
; start the flexure loop
; ########################

  imin_test = 0 & imax_test=280
  jmin_test = 0 & jmax_test=280
; imin_test = 145 & imax_test = 155
; jmin_test = 145 & jmax_test = 155
 imin_test = 166-20 & imax_test = 177+20
 jmin_test = 166-20 & jmax_test = 177+20
  ; code check range
; imin_test = 148 & imax_test = 152
; jmin_test = 148 & jmax_test = 152

  xind=166 & yind=177
  pp_neighbors=8


time1=systime(1,/seconds)
  for it_flex=0,it_flex_max-1 do begin
     print, 'starting iteration '+strc(it_flex+1)+' of '+strc(it_flex_max)+' for flexure'
                                ; make an array to look at the stddev as a function of iterations
     
     for it = 0, it_max-1 do begin
		time_it0=systime(1,/seconds)
                                ;  stop do begin
        for k=0,kmax do begin ; loop over spots/lenslet - only non-zero for polarimetry

           ; now loop over each lenslet
           for i=imin_test,imax_test do begin				
              ;statusline, "Get and fit PSF: Fitting line "+strc(i+1)+" of 281 and spot "+strc(k+1)+" of "+strc(kmax+1)+" for iteration " +strc(it+1)+" of "+strc(it_max)
						
              for j=jmin_test,jmax_test do begin
								
                 ; see if there are any intensities and not all nans
                 if spaxels.intensities[i,j,k] eq 0.0 then continue
				
									time_ij0=systime(1,/seconds)

                     ; takes a chunk of the array to work with so you're not
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
                   
										time_ij1 = systime(1,/seconds)

                    not_null_ptrs = where(ptr_valid(ptrs_current_stamps), n_not_null_ptrs)
                    current_stamps = fltarr(nx_pix,ny_pix,n_not_null_ptrs)
                    current_x0 = fltarr(n_not_null_ptrs)
                    current_y0 = fltarr(n_not_null_ptrs)
                    current_masks = fltarr(nx_pix,ny_pix,n_not_null_ptrs)

										time_ij2 = systime(1,/seconds)

                    for it_ptr = 0,n_not_null_ptrs-1 do begin
                       current_stamps[*,*,it_ptr] = *ptrs_current_stamps[not_null_ptrs[it_ptr]]
                       current_x0[it_ptr] = (*ptrs_current_xcoords[not_null_ptrs[it_ptr]])[0]
                       current_y0[it_ptr] = (*ptrs_current_ycoords[not_null_ptrs[it_ptr]])[0]
                       current_masks[*,*,it_ptr] = *ptrs_current_masks[not_null_ptrs[it_ptr]]
                    endfor
                    time_ij3 = systime(1,/seconds)

                    current_xcen = (spaxels.xcentroids[imin:imax,jmin:jmax,k,*])[not_null_ptrs]
                    current_ycen = (spaxels.ycentroids[imin:imax,jmin:jmax,k,*])[not_null_ptrs]
                    current_flux = (spaxels.intensities[imin:imax,jmin:jmax,k,*])[not_null_ptrs]
                    current_sky =  (spaxels.sky_values[imin:imax,jmin:jmax,k,*])[not_null_ptrs]
                    
                               
  	                time_ij4 = systime(1,/seconds)
										print, "Get and fit PSF: Fitting [line,column] ["+strc(i+1)+','+strc(j+1)+"] of 281 and spot "+strc(k+1)+" of "+strc(kmax+1)
	
                    ptr_current_PSF = get_PSF2( temporary(current_stamps), $
                                               temporary(current_xcen - current_x0), $
                                               temporary(current_ycen - current_y0), $
                                               temporary(current_flux), $
                                               temporary(current_sky), $
                                               nx_pix,ny_pix,$
                                               sub_pix_res_x,sub_pix_res_y, $
                                               MASK = temporary(current_masks),  $
                                ;XCOORDS = polspot_coords_x, $
                                ;YCOORDS = polspot_coords_y, $
                                               ERROR_FLAG = myerror_flag, $
                                               CENTROID_MODE = cent_mode, $
                                               HOW_WELL_SAMPLED = my_Sampling,$
                                               LENSLET_INDICES = [i,j,k], no_error_checking=1,$
                                /plot_samples )
time_ij5 = systime(1,/seconds)

                    ; now fit the PSF to each elevation psf and each neighbour
for it_elev = 0,nfiles-1 do begin
   for pi=imin, imax do begin
      for pj=jmin, jmax do begin
         
         time_it_elev0 = systime(1,/seconds)
											
		; check to make sure pointer is valid
					if ptr_valid(spaxels.values[pi,pj,k,it_elev]) eq 0 then continue
      	    first_guess_parameters = [spaxels.xcentroids[pi,pj,k,it_elev], spaxels.ycentroids[pi,pj,k,it_elev], spaxels.intensities[pi,pj,k,it_elev]]

;stop,pi,pj,'just before fitting'
            ptr_fitted_PSF = fit_PSF( *spaxels.values[pi,pj,k,it_elev] - spaxels.sky_values[pi,pj,k,it_elev], $
                                     FIRST_GUESS = (first_guess_parameters),$
																		 mask=*spaxels.masks[pi,pj,k,it_elev],$
                                     ptr_current_PSF,$
                                     X0 = (*spaxels.xcoords[pi,pj,k,it_elev])[0,0], $
																		 Y0 = (*spaxels.ycoords[pi,pj,k,it_elev])[0,0], $
                                     FIT_PARAMETERS = best_parameters, $
                                     /QUIET, $
                                ;                              /anti_stuck, $
                                     ERROR_FLAG = my_other_error_flag, no_error_checking=1) ;
                
                time_it_elev1 = systime(1,/seconds)
                
                                ; only store high-res psf in the place for which it was determined 
                if pi eq i and pj eq j then PSFs[i,j,k] = (ptr_current_PSF)
                fitted_spaxels.values[pi,pj,k,it_elev] =temporary(ptr_fitted_PSF)
                fitted_spaxels.xcentroids[pi,pj,k,it_elev] = best_parameters[0]
                fitted_spaxels.ycentroids[pi,pj,k,it_elev] = best_parameters[1]
                fitted_spaxels.intensities[pi,pj,k,it_elev] = best_parameters[2]
             endfor                                                            ; end loop over pj
   endfor                                                                      ; end loop over pi
time_it_elev2 = systime(1,/seconds)
;
;; #########################################                       
;; FROM HERE TO THE ENDFOR IS JUST DEBUGGING
;; #########################################
;
;
                      value_to_consider = where(*spaxels.masks[i,j,k,it_elev] eq 1)
                      if value_to_consider[0] ne -1 then begin
                         diff_image[ (*spaxels.xcoords[i,j,k,it_elev])[value_to_consider], (*spaxels.ycoords[i,j,k,it_elev])[value_to_consider] ] = (*spaxels.values[i,j,k,it_elev])[value_to_consider] - (spaxels.sky_values[i,j,k,it_elev])[value_to_consider]-((*fitted_spaxels.values[i,j,k,it_elev])*(*spaxels.masks[i,j,k,it_elev]))[value_to_consider]
;                               ; what is new image?
                         new_image[ (*spaxels.xcoords[i,j,k,it_elev])[value_to_consider], (*spaxels.ycoords[i,j,k,it_elev])[value_to_consider] ] += ((*fitted_spaxels.values[i,j,k,it_elev])*(*spaxels.masks[i,j,k,it_elev]))[value_to_consider]
                     
                              ; calculate the stddev
                          stddev_arr=fltarr(281,281,kmax+1,nfiles,it_max,it_flex_max)

                           ; interested in the weighted stddev
                           ; weight by intensity
                        mask0=(*spaxels.masks[i,j,k,it_elev])
                        mask0[where(mask0 eq 0)]=!values.f_nan
                        mask=(*spaxels.masks[i,j,k,it_elev])[value_to_consider]
                        sz=size(mask0)

                        weights0=reform((*spaxels.values[i,j,k,it_elev]) - (spaxels.sky_values[i,j,k,it_elev]),sz[1],sz[2])*mask0
                        weights=((*spaxels.values[i,j,k,it_elev])[value_to_consider] - (spaxels.sky_values[i,j,k,it_elev])[value_to_consider])*mask
                        gain=float(backbone->get_keyword('sysgain'))
                        weights0=sqrt((*fitted_spaxels.values[i,j,k,it_elev])*gain)/gain
                        weights=sqrt((*fitted_spaxels.values[i,j,k,it_elev])[value_to_consider]*gain)/gain

                        intensity0=reform((*spaxels.values[i,j,k,it_elev]) - (spaxels.sky_values[i,j,k,it_elev]),sz[1],sz[2])*mask0
                        intensity=((*spaxels.values[i,j,k,it_elev])[value_to_consider] - (spaxels.sky_values[i,j,k,it_elev])[value_to_consider])*mask

                        diff0=mask0*(reform((*spaxels.values[i,j,k,it_elev]) - (spaxels.sky_values[i,j,k,it_elev]),sz[1],sz[2])-(*fitted_spaxels.values[i,j,k,it_elev]))
                        diff=(*spaxels.values[i,j,k,it_elev])[value_to_consider] - (spaxels.sky_values[i,j,k,it_elev])[value_to_consider]-((*fitted_spaxels.values[i,j,k,it_elev])*(*spaxels.masks[i,j,k,it_elev]))[value_to_consider]
                        model=(*fitted_spaxels.values[i,j,k,it_elev])*mask
                        w_mean=total(abs(diff)*weights,/nan)/total(weights,/nan)/total(mask,/nan)
                        weighted_intensity_arr[i,j,k,it_elev,it,it_flex]=total(intensity*weights,/nan)/total(weights,/nan)
												intensity_arr[i,j,k,it_elev,it,it_flex]=total(intensity,/nan)
                        stddev_arr[i,j,k,it_elev,it,it_flex]= total(weights*(diff-w_mean)^2.0,/nan)/total(weights,/nan)
                        weighted_diff_intensity_arr[i,j,k,it_elev,it,it_flex]=total(abs(weights*diff),/nan)/total(weights)
												diff_intensity_arr[i,j,k,it_elev,it,it_flex]=total(abs(diff),/nan)

                            if i eq 125 and j eq 125 and it_elev eq 0 then begin;and it_flex eq it_flex_max-1 then begin
                               ;loadct,0
                               ;window,1,retain=2,xsize=300,ysize=300,title='orig & fit- '+strc(i)+', '+strc(j)
                               sz=(*spaxels.values[150,150])
                               mask=(*spaxels.masks[i,j,k,it_elev])
                               orig=mask*(*spaxels.values[i,j,k,it_elev])
                               ;tvdl,orig,min(orig,/nan),max(orig,/nan)
                            
                               window,3,retain=3,xsize=300,ysize=300,title='orig & model- '+strc(i)+', '+strc(j)
                               fit=((*fitted_spaxels.values[i,j,k,it_elev])*(*spaxels.masks[i,j,k,it_elev]))
                               tvdl,[orig,fit],min(orig,/nan),max(orig,/nan)
                               window,2,retain=2,xsize=300,ysize=300,title='percentage residuals- '+strc(i)+', '+strc(j)
                               sky=mask*(spaxels.sky_values[i,j,k,it_elev])
                               mask[where(mask eq 0)]=!values.f_nan
																tvdl,mask*(orig-sky-fit)/fit,-0.1,0.1
                               
																print, 'mean and weighted mean',  total(abs(mask*diff),/nan)/total(orig*mask,/nan), w_mean
																
															 ;stop
                            endif ; display if
                      endif     ; check for no dead values
;        
;; ####################            
;; END OF DEBUG
;; ####################
;
time_it_elev3 = systime(1,/seconds)

                    endfor      ; loop to fit psfs in elevation

					time_ij6 = systime(1,/seconds)
					;print, (time_ij1-time_ij0)/(time_ij6-time_ij0)
					;print, (time_ij2-time_ij1)/(time_ij6-time_ij0)
					;print, (time_ij3-time_ij2)/(time_ij6-time_ij0)
					;print, (time_ij4-time_ij3)/(time_ij6-time_ij0)

					;print, 'time to cut arrays', time_cut

					print, '% of time to do get_psf', (time_ij5-time_ij4)/(time_ij6-time_ij0)
					print, '% of time to do fit_psf', (time_ij6-time_ij5)/(time_ij6-time_ij0)
					print, 'total time=',time_ij6-time_ij0


					; now we need to step in the number of neighbours
					j+=(2*n_neighbors)


              endfor       ; end loop over j lenslets (columns?)
						i+=(2*n_neighbors)
           endfor ; end loop over i lenslsets (rows?)
        endfor ; end loop over spots (1 for spectra, 2 for polarization)
        
        print, 'Iteration complete in '+strc((systime(1)-time0)/60.)+' minutes'
                                ; put the fitted values into the originals before re-iterating
;stop,'just about to modify centroids'
        spaxels.xcentroids = fitted_spaxels.xcentroids
        spaxels.ycentroids = fitted_spaxels.ycentroids
        spaxels.intensities= fitted_spaxels.intensities
        
     endfor                     ; end loop over internal iterations
     
     ;set the first file as the reference image/elevation.
     ;All the transformations to go from one elevation to another are computed from that image or to that image.
     not_null_ptrs = where(finite(spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,0]), n_not_null_ptrs) ; select only the lenslets for which we have a calibration.
     ;The previous index vector will be used for all the images so it should be valid for all of them.
     ;This should be fine if the all the images were computed using the same wavelnegth solution which could be shifted using the lookup table.

;get the reference centroids coordinates (it's the only thing we need for this step)
     xcen_ref = (spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,0])[not_null_ptrs] 
     ycen_ref = (spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,*,0])[not_null_ptrs]
     
     degree_of_the_polynomial_fit = 1 ; degree of the polynomial surface used for the flexure correction
     ;declare the arrays which will contain the coefficients of the polynomial surface for every single image (ie elevation)
     ;The third dimension indicated which file to consider
     xtransf_ref_to_im = fltarr(degree_of_the_polynomial_fit+1,degree_of_the_polynomial_fit+1,nfiles) ;How to get the x coordinates of the centroids of the reference image into the current image (cf 3rd dimension index to select the image). 
     xtransf_im_to_ref = fltarr(degree_of_the_polynomial_fit+1,degree_of_the_polynomial_fit+1,nfiles) ;How to get the x coordinates of the centroids of the current image into the reference one. 
     ytransf_ref_to_im = fltarr(degree_of_the_polynomial_fit+1,degree_of_the_polynomial_fit+1,nfiles) ;How to get the y coordinates of the centroids of the reference image into the current image (cf 3rd dimension index to select the image). 
     ytransf_im_to_ref = fltarr(degree_of_the_polynomial_fit+1,degree_of_the_polynomial_fit+1,nfiles) ;How to get the y coordinates of the centroids of the current image into the reference one. 
     ;JB: Inverting the transformation analytically is dangerous because some of the coefficients are really close to zero so you may divide stuff by really small numbers.
     ; It tended to increase the noise. That's why we compute the two transformations im->ref and ref->im independentaly without using an inverse.
     
     ;loop over the other images with different elevations
     ; note that we only compute the
     ; it_elev=0 position for pixel phase reasons

  ;We first compute the flexure transformation and then add the contribution of the current image to the mean position of the centroids.
     ;at the end of this loop we have all the transformation im->ref and ref>im for all the elevations and the mean position of the centroid in the reference image.
     ;The current transformation method uses 2d polynomial surface. Contrary to the linear interpolation (shift + tip/tilt), it takes into account the distortion in x depending on y (and y on x).

; mean position in referece arrays - for entire detector
; only really good for showing errors in flexure etc
     xcen_ref_arr=fltarr(N_ELEMENTS(xcen_ref),nfiles)
     ycen_ref_arr=fltarr(N_ELEMENTS(ycen_ref),nfiles)

     pp_xcen_ref_arr=fltarr((2*pp_neighbors+1.0)^2, nfiles)
     pp_ycen_ref_arr=fltarr((2*pp_neighbors+1.0)^2, nfiles)

     for it_elev = 0,nfiles-1 do begin
 
     ; The transformation of the reference image into the reference one should be identity
   ;  xtransf_ref_to_im[1,0,0] = 1
   ;  xtransf_im_to_ref[1,0,0] = 1
   ;  ytransf_ref_to_im[0,1,0] = 1
   ;  ytransf_im_to_ref[0,1,0] = 1
  
    ;Get the centroids of the current image (ie elevation)
        xcen = (spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,it_elev])[not_null_ptrs]
        ycen = (spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,*,it_elev])[not_null_ptrs]
        
        ;Computes the transformation from the reference to the current image for the x coordinates
        ;Prepare the input for the sfit fitting function. xcen is function of xcen_ref and ycen_ref.
        data_sfit = [transpose(xcen_ref), transpose(ycen_ref),transpose(xcen)] 
        ;Fitting function with a polynamial surface of degree "degree_of_the_polynomial_fit".
        xcen_sfit = SFIT( data_sfit, degree_of_the_polynomial_fit, /IRREGULAR, KX=coef_sfit)
        ;Store the resulting coefficients 
        xtransf_ref_to_im[*,*,it_elev] = coef_sfit 
        ;declare the new list of the reference xcentroids in the image
        ; from the current image (at a given elevation)
        xcen_ref_in_im = fltarr(n_elements(xcen_ref)) 
        ;Loop to compute xcen_ref_in_im using the previous coefficients. 
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do xcen_ref_in_im += xtransf_ref_to_im[i,j,it_elev]*xcen_ref^j * ycen_ref^i
        
        ;Now, x coordinates, from the image to the reference. 
        data_sfit = [transpose(xcen), transpose(ycen),transpose(xcen_ref)]
        xcen_ref_sfit = SFIT( data_sfit, degree_of_the_polynomial_fit, /IRREGULAR, KX=coef_sfit )
        xtransf_im_to_ref[*,*,it_elev] = coef_sfit
        xcen_in_ref = fltarr(n_elements(xcen_ref))
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do xcen_in_ref += xtransf_im_to_ref[i,j,it_elev]*xcen^j * ycen^i
        
        ;Now, y coordinates, ref to im. 
        data_sfit = [transpose(xcen_ref), transpose(ycen_ref),transpose(ycen)]
        ycen_sfit = SFIT( data_sfit, degree_of_the_polynomial_fit, /IRREGULAR, KX=coef_sfit )
        ytransf_ref_to_im[*,*,it_elev] = coef_sfit
        ycen_ref_in_im = fltarr(n_elements(xcen_ref))
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do ycen_ref_in_im += ytransf_ref_to_im[i,j,it_elev]*xcen_ref^j * ycen_ref^i
        
        ;Now, y coordinates, im to ref. 
        data_sfit = [transpose(xcen), transpose(ycen),transpose(ycen_ref)]
        ycen_ref_sfit = SFIT( data_sfit, degree_of_the_polynomial_fit, /IRREGULAR, KX=coef_sfit )
        ytransf_im_to_ref[*,*,it_elev] = coef_sfit
        ycen_in_ref = fltarr(n_elements(xcen_ref))
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do ycen_in_ref += ytransf_im_to_ref[i,j,it_elev]*xcen^j * ycen^i

; we want the mean position in the reference
; already have the first component of the mean computed
; now add the component to the mean
        xcen_ref_arr[*,it_elev] = xcen_in_ref
        ycen_ref_arr[*,it_elev] = ycen_in_ref

; plot pixel phase
; only want the values from the neighbours
        if 1 eq 1 then begin
           pp_xcen = reform((spaxels.xcentroids[xind-pp_neighbors:xind+pp_neighbors,yind-pp_neighbors:yind+pp_neighbors,*,it_elev]),(2*pp_neighbors+1.0)^2)
           pp_ycen = reform((spaxels.ycentroids[xind-pp_neighbors:xind+pp_neighbors,yind-pp_neighbors:yind+pp_neighbors,*,it_elev]),(2*pp_neighbors+1.0)^2)
           ; bring into reference
           ; first x
           pp_xcen_in_ref = fltarr(n_elements(pp_xcen))
           for i=0,degree_of_the_polynomial_fit do $
              for j= 0,degree_of_the_polynomial_fit do $
                 pp_xcen_in_ref += xtransf_im_to_ref[i,j,it_elev]*pp_xcen^j * pp_ycen^i
           ;now y
           pp_ycen_in_ref = fltarr(n_elements(pp_ycen))
           for i=0,degree_of_the_polynomial_fit do $
              for j= 0,degree_of_the_polynomial_fit do $
                 pp_ycen_in_ref += ytransf_im_to_ref[i,j,it_elev]*pp_xcen^j * pp_ycen^i
        
           ; now we want to create/calculate a mean
           if it_elev eq 0 then begin
              pp_xcen_ref_arr[*,it_elev]=pp_xcen_in_ref
              pp_ycen_ref_arr[*,it_elev]=pp_ycen_in_ref
              ; now create centroid arrays
              pp_xcens_arr=pp_xcen_in_ref
              pp_ycens_arr=pp_ycen_in_ref
           endif else begin
              pp_xcen_ref_arr[*,it_elev] = pp_xcen_in_ref
              pp_ycen_ref_arr[*,it_elev] = pp_ycen_in_ref
              pp_xcens_arr=[pp_xcens_arr,[pp_xcen_in_ref]]
              pp_ycens_arr=[pp_ycens_arr,[pp_ycen_in_ref]]
           endelse
        ;  window, 11 ;pixel phase of the image in the reference
;  plot, mean_xcen_ref - floor(mean_xcen_ref) ,xcen_in_ref-mean_xcen_ref, psym = 3

        endif
    endfor   ; ends loop over different elevations

;  pp_xcens_arr - these are the centroids in the reference image.

; must calculate the means for pp_mean_xcen_ref
pp_mean_xcen_ref=fltarr((2*pp_neighbors+1.0)^2)
pp_mean_ycen_ref=fltarr((2*pp_neighbors+1.0)^2)

;for i=0, (2*pp_neighbors+1.0)^2-1 do pp_mean_xcen_ref[i]=mean(pp_xcen_ref_arr[i,where(abs(pp_xcen_ref_arr[i,*]-median(pp_xcen_ref_arr[i,*],/even)) lt 2.5*robust_sigma(pp_xcen_ref_arr[i,*]))])
;for i=0, (2*pp_neighbors+1.0)^2-1 do pp_mean_ycen_ref[i]=mean(pp_ycen_ref_arr[i,where(abs(pp_ycen_ref_arr[i,*]-median(pp_ycen_ref_arr[i,*],/even)) lt 2.5*robust_sigma(pp_ycen_ref_arr[i,*]))])

for i=0, (2*pp_neighbors+1.0)^2-1 do begin
	meanclip,pp_xcen_ref_arr[i,*],tmp_mean,tmp2, clipsig=2.5
	pp_mean_xcen_ref[i]=tmp_mean
;=mean(pp_xcen_ref_arr[i,where(abs(pp_xcen_ref_arr[i,*]-median(pp_xcen_ref_arr[i,*],/even)) lt 2.5*stddev(pp_xcen_ref_arr[i,*]))])
endfor

for i=0, (2*pp_neighbors+1.0)^2-1 do begin
	meanclip,pp_ycen_ref_arr[i,*], tmp_mean, tmp, clipsig=2.5
	pp_mean_ycen_ref[i]=tmp_mean
;pp_mean_ycen_ref[i]=mean(pp_ycen_ref_arr[i,where(abs(pp_ycen_ref_arr[i,*]-median(pp_ycen_ref_arr[i,*],/even)) lt 2.5*stddev(pp_ycen_ref_arr[i,*]))])
endfor

xresid=fltarr((2*pp_neighbors+1.0)^2*nfiles)
xpp=fltarr((2*pp_neighbors+1.0)^2*nfiles)
incre=(2*pp_neighbors+1.0)^2
for i=1,nfiles-1 do xresid[incre*i:incre*(i+1)-1]=pp_xcens_arr[incre*i:incre*(i+1)-1]-pp_mean_xcen_ref
;for i=0,nfiles-1 do xpp[incre*i:incre*(i+1)-1]=pp_mean_xcen_ref-floor(pp_mean_xcen_ref+0.5)  
xpp2=pp_xcens_arr-floor(pp_xcens_arr+0.5)  
;window,1,retain=2,xsize=600,ysize=400
;plot, xpp, xresid, psym = 3,xr=[-0.5,0.5],yr=[-0.12,0.12],/xs,/ys
window,2,retain=2,xsize=600,ysize=400
plot, xpp2, xresid, psym = 3,xr=[-0.5,0.5],yr=[-0.2,0.2],/xs,/ys,xtitle='X-pixel phase',ytitle='residuals (x-xbar)'

yresid=fltarr((2*pp_neighbors+1.0)^2*nfiles)
ypp=fltarr((2*pp_neighbors+1.0)^2*nfiles)
incre=(2*pp_neighbors+1.0)^2
for i=1,nfiles-1 do yresid[incre*i:incre*(i+1)-1]=pp_ycens_arr[incre*i:incre*(i+1)-1]-pp_mean_ycen_ref
;for i=0,nfiles-1 do ypp[incre*i:incre*(i+1)-1]=pp_mean_ycen_ref-floor(pp_mean_ycen_ref+0.5)  
ypp2=pp_ycens_arr-floor(pp_ycens_arr+0.5)  
;window,3,retain=2,xsize=600,ysize=400
;plot, ypp, yresid, psym = 3,xr=[-0.5,0.5],yr=[-0.12,0.12],/xs,/ys
window,4,retain=2,xsize=600,ysize=400
plot, ypp2, yresid, psym = 3,xr=[-0.5,0.5],yr=[-0.2,0.2],/xs,/ys,xtitle='Y-pixel phase',ytitle='residuals (y-ybar)'


;stop,"about to apply flexure correction to centroids"

; calculate the mean position of each mlens psf - but use a rejection
; must calculate the means for pp_mean_xcen_ref
mean_xcen_ref=fltarr(N_ELEMENTS(xcen_ref))
mean_ycen_ref=fltarr(N_ELEMENTS(ycen_ref))

;for i=0, N_ELEMENTS(xcen_ref)-1 do mean_xcen_ref[i]=mean(xcen_ref_arr[i,where(abs(xcen_ref_arr[i,*]-median(xcen_ref_arr[i,*])) lt 2.5*robust_sigma(xcen_ref_arr[i,*]))])
;for i=0, N_ELEMENTS(ycen_ref)-1 do mean_ycen_ref[i]=mean(ycen_ref_arr[i,where(abs(ycen_ref_arr[i,*]-median(ycen_ref_arr[i,*])) lt 2.5*robust_sigma(ycen_ref_arr[i,*]))])

for i=0, N_ELEMENTS(xcen_ref)-1 do begin
	meanclip,xcen_ref_arr[i,*], tmp_mean, tmp,clipsig=2.5
	mean_xcen_ref[i]=tmp_mean
endfor

for i=0, N_ELEMENTS(ycen_ref)-1 do begin
	meanclip,ycen_ref_arr[i,*], tmp_mean,tmp, clipsig=2.5
	mean_ycen_ref[i]=tmp_mean
endfor

; transforms the mean positions of each spot back into their images
; replaces each centroid with this mean position
    ;THE RESULT OF THE NEXT LOOP HAS NOT BEEN CHECK YET.
     x_id = not_null_ptrs mod 281
     y_id = not_null_ptrs / 281
     z_id = not_null_ptrs / (281L*281L)
; determine indices of arrays to replace
		 ind_arr = array_indices(spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,0],not_null_ptrs)

;xcen_ref = (spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,0])[not_null_ptrs] 

     if nfiles ne 1 then begin
     for it_elev = 0,nfiles-1 do begin
tmpx=(spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,it_elev])[not_null_ptrs] 
tmpy=(spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,*,it_elev])[not_null_ptrs] 

        mean_xcen_ref_in_im = fltarr(n_elements(xcen_ref))
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do mean_xcen_ref_in_im += xtransf_ref_to_im[i,j,it_elev]*mean_xcen_ref^j * mean_ycen_ref^i

        mean_ycen_ref_in_im = fltarr(n_elements(ycen_ref))
        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do mean_ycen_ref_in_im += ytransf_ref_to_im[i,j,it_elev]*mean_xcen_ref^j * mean_ycen_ref^i

       	if (size(ind_arr))[0] gt 2 then begin
					for zx=0L,N_ELEMENTS(ind_arr[0,*])-1 do begin
						spaxels.xcentroids[ind_arr[0,zx]+imin_test,ind_arr[1,zx]+jmin_test,ind_arr[2,zx],it_elev] = mean_xcen_ref_in_im[zx]
	      		spaxels.ycentroids[ind_arr[0]+imin_test,ind_arr[1]+jmin_test,ind_arr[2],it_elev] = mean_ycen_ref_in_im[zx]
					endfor
	 				endif else begin
						for zx=0L,N_ELEMENTS(ind_arr[0,*])-1 do begin
							spaxels.xcentroids[ind_arr[0,zx]+imin_test,ind_arr[1,zx]+jmin_test,*,it_elev] = mean_xcen_ref_in_im[zx]
	      			spaxels.ycentroids[ind_arr[0,zx]+imin_test,ind_arr[1,zx]+jmin_test,*,it_elev] = mean_ycen_ref_in_im[zx]
						endfor
					endelse
;stop,'in application of flexure correction'
;				spaxels.xcentroids[x_id,y_id,z_id,lonarr(n_elements(x_id))+it_elev] = mean_xcen_ref_in_im
;        spaxels.ycentroids[x_id,y_id,z_id,lonarr(n_elements(x_id))+it_elev] = mean_ycen_ref_in_im

        
     endfor                     ; ends loop over it_elev to apply flexure correction (line 670)
endif
     ;//////STOP HERE if you want to play with the pixel phase plots or the centroid coordinates in the different images.
     ;stop,'just before end of flexure correction' ; this is where JB_TEST.sav is created
     
  endfor ; end of flexure correction loop (over it_flex)

  
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
; set the values with no flat info to NaN
ind=where(flat_field_arr2 eq 0.000)
if ind[0] ne -1 then flat_field_arr[ind]=!values.f_nan
; so now loop over each pixel and calculate the weighted mean
        final_flat=fltarr(2048,2048)
        weights=fltarr(2048,2048,nfiles)
        for n=0,nfiles-1 do weights[*,*,n]=(*(dataset.frames[n]))
        
        final_flat2=total(weights*flat_field_arr2,3)/total(weights,3)
           writefits, "flat_field_arr.fits",flat_field_arr

; for lenslet 135,135 
;tvdl, subarr(final_flat2,100,[953,978]),0,2
;  for lenslet 166,177 
window,23,retain=2
tvdl, subarr(final_flat2,100,[1442,1244]),0.9,1.1
window,24,retain=2
image=*(dataset.currframe[0])
tvdl, subarr(image,100,[1442,1244]),/log

endif
        
; ####################
; create flexure plots
; ####################
; stored in xtransf_im_to_ref
xx=(fltarr(2048)+1)##findgen(2048)
xx1d=reform(xx,2048*2048)
yy=findgen(2048)##(fltarr(2048)+1)
yy1d=reform(yy,2048*2048)

xflex_trans_arr1d=fltarr(2048*2048,nfiles)
for it_elev=0,nfiles-1 do $
	for i=0,degree_of_the_polynomial_fit do $
		for j= 0,degree_of_the_polynomial_fit do $
			xflex_trans_arr1d[*,it_elev] += xtransf_im_to_ref[i,j,it_elev]*xx1d^j * yy1d^i
; now put back into 2-d arrays
xflex_trans_arr2d=(reform(xflex_trans_arr1d,2048,2048,nfiles))
; we want the difference, so we must subtract the xx array
for it_elev=0,nfiles-1 do xflex_trans_arr2d[*,*,it_elev]-=xx

; now do it in the y-direction
yflex_trans_arr1d=fltarr(2048*2048,nfiles)
for it_elev=0,nfiles-1 do $
	for i=0,degree_of_the_polynomial_fit do $
		for j= 0,degree_of_the_polynomial_fit do $
			yflex_trans_arr1d[*,it_elev] += ytransf_im_to_ref[i,j,it_elev]*xx1d^j * yy1d^i
; now put back into 2-d arrays
yflex_trans_arr2d=(reform(yflex_trans_arr1d,2048,2048,nfiles))
; we want the difference, so we must subtract the xx array
for it_elev=0,nfiles-1 do yflex_trans_arr2d[*,*,it_elev]-=yy

; evalute performance increase
window,2,retain=2,title='weighted % residual'
tmp=(weighted_diff_intensity_arr/weighted_intensity_arr)
plothist,tmp[*,*,*,*,*,0],xhist,yhist,/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5
plothist,tmp[*,*,*,*,*,0],/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5,yr=[0,max(yhist)*1.5],ys=1
plothist,tmp[*,*,*,*,*,1],/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5,/noerase,linestyle=2,yr=[0,max(yhist)*1.5],ys=1,color=155

window,1,retain=2,title='non-weighted % residual'
tmp2=(diff_intensity_arr/intensity_arr)

plothist,tmp2[*,*,*,*,*,0],xhist,yhist,/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5
plothist,tmp2[*,*,*,*,*,0],/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5,yr=[0,max(yhist)*1.5],ys=1
plothist,tmp2[*,*,*,*,*,1],/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5,/noerase,linestyle=2,yr=[0,max(yhist)*1.5],ys=1,color=155



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
  
                                ;---- store the output into the backbone datastruct
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
