;+
; NAME:  gpi_create_highres_microlens_psf_model
; PIPELINE PRIMITIVE DESCRIPTION: Create High-Resolution Microlens PSF Model
; 
; This primitive is based on the determination of a high resolution PSF for each lenslet. It uses an adapted none iterative algorithm from the paper of Jay Anderson and Ivan R. King 2000.
; 
; INPUTS:  Multiple 2D images with appropriate illumination
; OUTPUTS: High resolution microlens PSF empirical model
;
; PIPELINE COMMENT: Create a few calibrations files based on the determination of a high resolution PSF.
; PIPELINE ARGUMENT: Name="filter_wavelength" Type="string" Range="" Default="" Desc="Narrowband filter wavelength"
; PIPELINE ARGUMENT: Name="bad_pixel_mask" Type="string" Range="" Default="" Desc="Bad pixel mask"
; PIPELINE ARGUMENT: Name="flat_field" Type="int" Range="[0,1]" Default="0" Desc="Is this a flat field"
; PIPELINE ARGUMENT: Name="flat_filename" Type="string" Default="" Desc="Name of flat field"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.01
; PIPELINE CATEGORY: Calibration
;
; HISTORY:
;     Originally by Jean-Baptiste Ruffio 2013-06
;     2014-01-23 MP: Rename and documentation update
;     2014-04-10 PI: overhaul of highres_psf creation
;     2014-04-10 PI: overhaul of flexure handling
;-
function gpi_create_highres_microlens_psf_model, DataSet, Modules, Backbone
  primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive


start_time=systime(1)
;device,decomposed=0
;restore,'/home/LAB/H-band-kernel-testing.sav'
;goto, kernel_testing  


;restore,'flexure_testing.sav'
;goto, transform_section

; restore, 'y-psf-kernel-testing.sav'
; goto, psf_kernel_testing

  ;========  First section: Checking of inputs and initialization of variables depending on observing mode ==========
  ; Note: in the below, comments prefaced by "MP:" are added by Marshall during
  ; his attempt to read through and understand the details of JB's code...


  if tag_exist( Modules[thisModuleIndex], "filter_wavelength") then filter_wavelength=string(Modules[thisModuleIndex].filter_wavelength) else filter_wavelength=''
  if tag_exist( Modules[thisModuleIndex], "bad_pixel_mask") then bad_pixel_mask=string(Modules[thisModuleIndex].bad_pixel_mask) else bad_pixel_mask=0
  if tag_exist( Modules[thisModuleIndex], "flat_field") then flat_field=float(Modules[thisModuleIndex].flat_field) else flat_field=0
  if tag_exist( Modules[thisModuleIndex], "flat_filename") then flat_filename=string(Modules[thisModuleIndex].flat_filename) else flat_filename=""
  
  if filter_wavelength eq '' and flat_field eq 0 then return, error(' No narrowband filter wavelength specified. Please specify a wavelength and re-add to queue')

if keyword_set(bad_pixel_mask) eq 0 then return,error('no bad pixel mask specified')
bad_pixel_mask=mrdfits(bad_pixel_mask,1)
bad_pixel_mask=abs(bad_pixel_mask-1)

  filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
	disperser = gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', indexFrame=nfiles))
	nfiles=dataset.validframecount
 
  if nfiles eq 1 then begin
     image=*(dataset.currframe[0])
     
	 ; MP: I don't understand this part - why has JB hard coded a specific flat
	 ; field here? FIXME
	; PI: This was me doing testing - never had a chance to clean up before you started workingà
	; on it so i had to commit with stuff like this still in it (although not used)
     if keyword_set(flat_filename) eq 1 then begin
        stop
        flat_filename="/home/LAB/gpi/data/Reduced/130703/flat_field_arr_130702S0043.fits"
        flat=mrdfits(flat_filename)
        flat[where((flat) eq 0 or finite(flat) eq 0)]=1.0
        image/=flat
     endif
     sz=size(image) 
     if sz[1] ne 2048 or sz[2] ne 2048 then begin
        backbone->Log, "ERROR: Image is not 2048x2048, don't know how to handle it in microlens PSF measurements."
        return, NOT_OK
     endif
  endif
  
  ;declare variables based on which DISPERSR is selected
  ; MP: And then cut out the postage stamps around each PSF!
  backbone->Log, "Cutting out postage stamps around each lenslet PSF"
  case disperser of
     'PRISM': begin
        width_PSF = 5 ; orig          ; size of stamp?  
        n_per_lenslet = 1                         ; there is only 1 PSF per lenslet in spectral mode                
        sub_pix_res_x = 5		;sub_pixel resolution of the highres ePSF
        sub_pix_res_y = 5		;sub_pixel resolution of the highres ePSF
        cent_mode = "BARYCENTER"
				; if we are working with narrowband filter data, we want the centroid to be at the maximum
        if filter_wavelength ne -1 then cent_mode="MAX"
                                ; Create raw data stamps
 		if filter eq 'K1' then begin
				top_adjustment=-8
				bottom_adjustment=-7
		endif
		if filter eq 'J' then begin
				top_adjustment=0
				bottom_adjustment=-11
		endif
        spaxels = gpi_highres_microlens_psf_extract_microspectra_stamps(disperser, dataset.frames[0:(nfiles-1)],$
				dataset.wavcals[0:(nfiles-1)], width_PSF, top_adjustment=top_adjustment,bottom_adjustment=bottom_adjustment, bad_pixel_mask=bad_pixel_mask, /STAMPS_MODE,/gaussians) 

     end
     'WOLLASTON': begin
        width_PSF = 7                            ; size of stamp?
        n_per_lenslet =2                         ; there are 2 PSFs per lenslet in polarimetry mode.
        sub_pix_res_x = 2                        ; sub_pixel resolution of the highres ePSF
        sub_pix_res_y = 2                        ; sub_pixel resolution of the highres ePSF
        cent_mode = "MAX"
                                ; Create raw data stamps
		;image=*dataset.frames[0]
		;tmp_pol_cal=polcal
		;spaxels = gpi_highres_microlens_psf_extract_microspectra_stamps(disperser, image, polcal, width_PSF,$
		;			bad_pixel_mask=bad_pixel_mask, /STAMPS_MODE,/gaussians)
		spaxels = gpi_highres_microlens_psf_extract_microspectra_stamps(disperser, dataset.frames[0:(nfiles-1)],$
				dataset.polcals[0:(nfiles-1)], width_PSF, bad_pixel_mask=bad_pixel_mask, /STAMPS_MODE);,/gaussians) 


     end
  endcase

; must remove the known bad lenslets
; these are both bad
ptr_free,spaxels.values[183,198],spaxels.values[199,199]
; this is just very weak
ptr_free, spaxels.values[50,167]

  common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary
  common hr_psf_common, c_psf,c_x_vector_psf_min, c_y_vector_psf_min, c_sampling
  diff_image = fltarr(2048,2048)	; MP: difference image, output at end of calculation? PI: Yes
  model_image = fltarr(2048,2048)		; new modeled image - output at end of calculation
  
  n_neighbors = 5               ; number on each side - so 4 gives a 9x9 box - 3 gives a 7x7 box
  ; set up a lenslet jump to improve speed - normally the step would be 2*n_neighbors+1
  ; so this makes it (2*n_neighbors+1)*loop_jump
	loop_jump=1                  ; the multiple of lenslets to jump
 
; determine the cutout size- this is not always the same as width_PSF
; and the y-axis size is determined by the calibration file
  values_tmp = *(spaxels.values[(where(ptr_valid(spaxels.values)))[0]]) ; determine a box size
  nx_pix = (size(values_tmp))[1]	
  ny_pix = (size(values_tmp))[2]

  if (size(spaxels.values))[0] eq 4 then n_diff_elev = (size(spaxels.values))[4] else n_diff_elev = 1
  ; Create data structure for storing high-res PSF:
  ; PSF_template = {values: fltarr(nx_pix*sub_pix_res_x,ny_pix*sub_pix_res_y), $
  ;                xcoords: fltarr(nx_pix*sub_pix_res_x), $
  ;                ycoords: fltarr(ny_pix*sub_pix_res_y), $
  ;                tilt: 0.0,$		; MP: ???
  ;                id: [0,0,0] }		; lenslet indices
  
 ;replace the 281 by variables 
  PSFs = ptrarr(281, 281, n_per_lenslet)
  fitted_spaxels = replicate(spaxels,1)
  fit_error_flag = intarr(281, 281, n_per_lenslet)
  
; start the iterations
; the following (it_flex_max) declares the number of iterations
; over the flexure loop - so the RHS of figure 8 in the Anderson paper
; this should probably be moved into a recipe keyword.
;stop
  it_flex_max = 5				; what is this? -MP  # of iterations for flexure? Not clear what is being iterated over.
;   degree_of_the_polynomial_fit = 2 ; degree of the polynomial surface used for the flexure correction
; can't have multiple iterations if just one file - this should be a recipe failure

  if nfiles eq 1 then begin 
     it_flex_max=1
  endif
; make an ar to look at the stddev as a function of iterations

  if flat_field eq 1 then flat_field_arr=fltarr(2048,2048,nfiles)

debug=1
  if debug eq 1 then begin
	; create a series of arrays to evaluate the fits for each iteration
                                ; want to watch how the weighted
                                ; STDDEV decreases with iterations etc
    stddev_arr=fltarr(281,281,n_per_lenslet,nfiles,it_flex_max)
    intensity_arr=fltarr(281,281,n_per_lenslet,nfiles,it_flex_max)
	weighted_intensity_arr=fltarr(281,281,n_per_lenslet,nfiles,it_flex_max)
    diff_intensity_arr=fltarr(281,281,n_per_lenslet,nfiles,it_flex_max)
    weighted_diff_intensity_arr=fltarr(281,281,n_per_lenslet,nfiles,it_flex_max)
chisq_arr=fltarr(281,281,n_per_lenslet,nfiles,it_flex_max)
  endif

; ########################
; start the flexure loop
; ########################
;

; the following is for pixel phase plotting only - it has no effect on any results
  pp_xind=182 & pp_yind=196
  pp_neighbors=n_neighbors


  imin_test = 0 & imax_test=280		; Iterate over entire field of view.
  jmin_test = 0 & jmax_test=280

; imin_test = 190 & imax_test = 280
; jmin_test = 0 & jmax_test = 210

; imin_test = pp_xind-21 & imax_test = pp_xind+25
; jmin_test = pp_yind-21 & jmax_test = pp_yind+20

; imin_test = 123 & imax_test =179
; jmin_test = 0 & jmax_test = 83


  ; code check range
; imin_test = 81 & imax_test = 89
; jmin_test = 87 & jmax_test = 89
; want 82,88

	; the following is the iteration over the flexure position fixes
	; so the right/outer loop in fig 8

	; want to make sure the reference psfs aren't less then n_neighbours from the border
	; the last lenslets are also often bad or distorted, so move it +1 inside
	tmp= float(ptr_valid(spaxels.masks[*,*,0,0])); shows all lenslets
	kernel=fltarr(2*n_neighbors+1+2+1,2*n_neighbors+1+2+1) ; add 1 extra plus blanks on all sides
	kernel[1:2*n_neighbors+1+1+2-2,1:2*n_neighbors+1+1+2-2]=1
	sample_map=convol(tmp,kernel) ; shows which ones have full sampling

kernel_testing: 
;it_flex_max=2

  for it_flex=0,it_flex_max-1 do begin

;if it_flex eq 2 then stop
; so now create a .save file that we can just load here then continue
; save,/all,filename='/home/LAB/H-band-kernel-testing.sav'

     backbone->Log, 'starting iteration '+strc(it_flex+1)+' of '+strc(it_flex_max)+' for flexure'
 
        for k=0,n_per_lenslet-1 do begin ; MP: loop over # of spots per lenslet - only >1 for polarimetry

           ; now loop over each lenslet
           for i=imin_test,imax_test do begin				
;		statusline, "Creating highres psf: Line "+strc(i)+" of "+strc(imax_test)+ $
;			" and spot "+strc(k+1)+" of "+strc(n_per_lenslet)+" for iteration " + $
;			strc(it_flex+1)+" of "+strc(it_flex_max)
              
		   for j=jmin_test,jmax_test do begin
	  statusline, "Creating highres psf: Line/column "+strc(i)+","+strc(j)+$
				  " of "+strc(imax_test)+" and spot "+strc(k+1)+" of "+ $
					strc(n_per_lenslet)+" for iteration " +strc(it_flex+1)+$
					" of "+strc(it_flex_max)
           							
		; MP: Skip if this is not a valid illuminated lenslet
			; also want to skip if the lenslet is not within the number of neighbours from the border
                if ~finite(spaxels.intensities[i,j,k]) or spaxels.intensities[i,j,k] eq 0.0 or sample_map[i,j] ne total(kernel) then begin
					; can't just continue, or it messes up the spacing the next go around
					; now we need to step in the number of neighbours
					j+=((2*n_neighbors)*loop_jump)
					continue
				endif
	
; ##############################
; Create each highres mlens PSF
; ##############################

;if i lt 99 or i gt 99 then continue
;if j lt 99 or j gt 99 then continue
;
;flag=1

                     ; takes a chunk of the array to work with so you're not
                                ; passing the entire array
                    
                                ;TODO: it doesnt manage the edges
                    imin = max([0,(i-n_neighbors)])
                    imax = min([280,(i+n_neighbors)])
                    jmin = max([0,(j-n_neighbors)])
                    jmax = min([280,(j+n_neighbors)])
                    nspaxels = (imax-imin+1)*(jmax-jmin+1)*n_diff_elev
					iarr=findgen(imax-imin+1)+imin
					jarr=findgen(jmax-jmin+1)+jmin
					; now only want to use the psfs of interest (~6) surrouding a given psf
					coords=[[0,0],[0,1],[1,1],[-1,-1],[1,0],[-1,0]]
					iarr=i+coords[0,*]
					jarr=j+coords[1,*]
                    nspaxels = (N_ELEMENTS(coords[0,*]))*(N_ELEMENTS(coords[1,*]))*n_diff_elev                     
                    ; reforms the arrays to be 1D 
                    ptrs_current_stamps = reform(spaxels.values[[iarr],[jarr],k,*],nspaxels)
                    ptrs_current_xcoords = reform(spaxels.xcoords[[iarr],[jarr],k,*],nspaxels)
                    ptrs_current_ycoords = reform(spaxels.ycoords[[iarr],[jarr],k,*],nspaxels)
                    ptrs_current_masks = reform(spaxels.masks[[iarr],[jarr],k,*],nspaxels)
		    ; find the defined pointers in the range
                    not_null_ptrs = where(ptr_valid(ptrs_current_stamps), n_not_null_ptrs) ; n_not_null_pts
                    current_stamps = fltarr(nx_pix,ny_pix,n_not_null_ptrs)
                    current_x0 = fltarr(n_not_null_ptrs)
                    current_y0 = fltarr(n_not_null_ptrs)
                    current_masks = fltarr(nx_pix,ny_pix,n_not_null_ptrs)
		    ; create small arrays to pass in/out of functions
                    for it_ptr = 0,n_not_null_ptrs-1 do begin
                       current_stamps[*,*,it_ptr] = *ptrs_current_stamps[not_null_ptrs[it_ptr]]
                       current_x0[it_ptr] = (*ptrs_current_xcoords[not_null_ptrs[it_ptr]])[0]
                       current_y0[it_ptr] = (*ptrs_current_ycoords[not_null_ptrs[it_ptr]])[0] 
                       current_masks[*,*,it_ptr] = *ptrs_current_masks[not_null_ptrs[it_ptr]]
                    endfor

                    current_xcen = (spaxels.xcentroids[[iarr],[jarr],k,*])[not_null_ptrs]
                    current_ycen = (spaxels.ycentroids[[iarr],[jarr],k,*])[not_null_ptrs]
                    current_flux = (spaxels.intensities[[iarr],[jarr],k,*])[not_null_ptrs]
                    current_sky = (spaxels.sky_values[[iarr],[jarr],k,*])[not_null_ptrs] 
                    current_tilt=median((spaxels.tilts[[iarr],[jarr],k,*])[not_null_ptrs])

		psf_kernel_testing:
;if i eq 183 and j eq 186 then flag=1 else flag=0

;if i eq 110 and j eq 176 then flag=1 else flag=0 ; K1 band check
;flag=1
;if i eq 184 and j eq 194 and it_flex ge 0 then stop,'arrived at problematic section - create save file'

;if i eq 183 and j eq 186 then flag=1 else flag=0

ptr_current_PSF = gpi_highres_microlens_psf_create_highres_psf($
                                      temporary(current_stamps), $
                                      temporary(current_xcen - current_x0), $
                                      temporary(current_ycen - current_y0), $
                                      temporary(current_flux), $
                                      temporary(current_sky), $
                                      nx_pix,ny_pix,$
                                      sub_pix_res_x,sub_pix_res_y, $
                                      MASK = temporary(current_masks),  $
									  tilt=temporary(current_tilt), $
                                ;XCOORDS = polspot_coords_x, $
                                ;YCOORDS = polspot_coords_y, $
                                      ERROR_FLAG = myerror_flag,flag=flag, filter=filter,$
                                      CENTROID_MODE = cent_mode, $
                                      HOW_WELL_SAMPLED = my_Sampling,$
                                      LENSLET_INDICES = [i,j,k], no_error_checking=1,$
                                      plot_samples=0 )
;if i eq 184 and j eq 194 then stop
	;stop,i,j
			; only store high-res psf in the place for which it was determined 
			PSFs[i,j,k] = (ptr_current_PSF)

			; now we need to step in the number of neighbours
			j+=((2*n_neighbors)*loop_jump)

              endfor       ; end loop over j lenslets (columns?)
		i+=((2*n_neighbors)*loop_jump)
           endfor ; end loop over i lenslsets (rows?)

print,'' ; just puts a space in the status line

; ##############################
; Fit each detector mlens PSF 
; using the highres PSF
; ##############################

	; now fit the PSF to each elevation psf and each neighbour
;		print, "Fitting PSFs: for file "+strc(f)

	valid=ptr_valid(psfs[*,*,k]) ; which psfs are valid?

	  ; now loop over each lenslet
           for i=(imin_test-n_neighbors)>0,(imax_test+n_neighbors)<280 do begin				
	      statusline, "fitting PSF: Fitting line "+strc(i+1)+" of "+strc(imax_test)+" for iteration " +strc(it_flex+1)+" of "+strc(it_flex_max)
       	      for j=(jmin_test-n_neighbors)>0,(jmax_test+n_neighbors)<280 do begin
			
		; check to make sure pointer is valid
		if ptr_valid(spaxels.values[i,j,k]) eq 0 then continue

		; interpolate to grab the psf for this lenslet
		ptr_highres_psf = gpi_highres_microlens_psf_get_local_highres_psf(PSFs[*,*,k],[i,j,k],/preserve_structure,valid=valid)

		; loop over the files/elevations
		for f = 0,nfiles-1 do begin

			first_guess_parameters = [spaxels.xcentroids[i,j,k,f], spaxels.ycentroids[i,j,k,f], spaxels.intensities[i,j,k,f]]
			
			weights='radial'
			; check that all information is valid
			if finite(first_guess_parameters) ne [0] then begin
					; lenslet info is bad for this frame

			ncoadds = gpi_simplify_keyword_value(backbone->get_keyword('COADDS0', indexFrame=f))
;if i eq 183 and j eq 186 then flag=1 else flag=0

			ptr_fitted_PSF = gpi_highres_microlens_psf_fit_detector_psf($
			 *spaxels.values[i,j,k,f] - spaxels.sky_values[i,j,k,f], $
			 FIRST_GUESS = (first_guess_parameters),$
			 mask=*spaxels.masks[i,j,k,f],$
			 ptr_highres_psf,flag=flag,$
			 X0 = (*spaxels.xcoords[i,j,k,f])[0,0], $
			 Y0 = (*spaxels.ycoords[i,j,k,f])[0,0], $
			 FIT_PARAMETERS = best_parameters, $
			 /QUIET, ncoadds=ncoadds, weights=weights,$
			;                              /anti_stuck, $
			 ERROR_FLAG = my_other_error_flag, no_error_checking=1,chisq=chisq) ;
			
                        chisq_arr[i,j,k,f,it_flex]=chisq

;if chisq gt 1e10 then stop,'chisq passed limit'
                        
            fitted_spaxels.values[i,j,k,f] =temporary(ptr_fitted_PSF)
			fitted_spaxels.xcentroids[i,j,k,f] = best_parameters[0]
			fitted_spaxels.ycentroids[i,j,k,f] = best_parameters[1]
			fitted_spaxels.intensities[i,j,k,f] = best_parameters[2]

			endif else begin
			    ptr_free, fitted_spaxels.values[i,j,k,f]
				fitted_spaxels.xcentroids[i,j,k,f] = !values.f_nan
				fitted_spaxels.ycentroids[i,j,k,f] = !values.f_nan
				fitted_spaxels.intensities[i,j,k,f] = !values.f_nan
			endelse

;if it_flex eq 1 and i eq 174 and j eq 184 then stop,'here after fitting'
; gpi_highres_debugging

		endfor      ; loop to fit psfs in elevation
           endfor       ; end loop over j lenslets (columns?)
        endfor ; end loop over i lenslsets (rows?)


        endfor ; end loop over # of spots per lenslet  (1 for spectra, 2 for polarization)
;     stop, 'at end of fitting'

        ; put the fitted values into the originals before re-iterating
;		stop,'just about to modify centroids'
        spaxels.xcentroids = fitted_spaxels.xcentroids
        spaxels.ycentroids = fitted_spaxels.ycentroids
        spaxels.intensities= fitted_spaxels.intensities
   
; ####################################################
; NOW MOVING INTO THE TRANSFORMATION PART OF THE CODE 
; ####################################################


transform_section:
; want to do 1 transform per spot for the moment (this is not ideal but merging both lenslet spots into a single array is difficult book-keeping wise) 

; this is only greater than 0 for polarimetry`
	for k=0,n_per_lenslet-1 do begin 
 
;set the first file as the reference image/elevation.
;All the transformations to go from one elevation to another are computed from that image or to that image.
; ORIGINAL
;  not_null_ptrs = where(finite(spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,*,0]), n_not_null_ptrs) ; select only the lenslets for which we have a calibration.

  valid_ctrd_ptrs = where(finite(spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,k,0]+spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,k,0]) eq 1) ; select only the lenslets for which we have a calibration.

; this part of the code does not use pointers! so there should be no reason to
; mess around with the valid pointer indicies
 
; get the reference centroids coordinates 
; the reference isn't overly important, but it is best to use 
; the instrument position corresponding to the wavecal 
; just for simplicity
     xcen_ref = (spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,k,0])
	 ycen_ref = (spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,k,0])

; arrays to determine mean position in referece array - for entire detector and all elevations
; only really good for showing errors in flexure etc
     xcen_ref_arr=fltarr(N_ELEMENTS(valid_ctrd_ptrs),nfiles)
     ycen_ref_arr=fltarr(N_ELEMENTS(valid_ctrd_ptrs),nfiles)
     xcen_ref_arr2d=fltarr(281,281,nfiles)
     ycen_ref_arr2d=fltarr(281,281,nfiles)

   ; create array to hold the transforms between elevations
;	xtransf_im_to_ref=fltarr(281,281,n_per_lenslet,nfiles)   ; orig
;	ytransf_im_to_ref=fltarr(281,281,n_per_lenslet,nfiles)   ; orig

	xtransf_im_to_ref=fltarr(281,281,nfiles)
	ytransf_im_to_ref=fltarr(281,281,nfiles)

; create median box size for flexure offseting
med_box=[40,30,30,20,10]
    for f = 0,nfiles-1 do begin
 	; xtransform array
	xtrans_tmp=xcen_ref-(spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,k,f])
	ytrans_tmp=ycen_ref-(spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,k,f])
	nan_ind=where(finite(xtrans_tmp+ytrans_tmp) eq 0,ct)	
	; now filter the array
	xtrans_tmp2=filter_image(xtrans_tmp,median=med_box[it_flex<N_ELEMENTS(med_box)],/all) ; this is about 4 cycles per aperture
	ytrans_tmp2=filter_image(ytrans_tmp,median=med_box[it_flex<N_ELEMENTS(med_box)],/all)

	; put the nan's back in the image - the filtering expands the image
	if ct gt 0 then begin
		xtrans_tmp2[nan_ind]=!values.f_nan
		ytrans_tmp2[nan_ind]=!values.f_nan
	endif

	xtransf_im_to_ref[imin_test:imax_test,jmin_test:jmax_test,f]=xtrans_tmp2
	ytransf_im_to_ref[imin_test:imax_test,jmin_test:jmax_test,f]=ytrans_tmp2

	xcen_ref_arr[*,f]=( (spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,k,f])+xtransf_im_to_ref[imin_test:imax_test,jmin_test:jmax_test,f] )[valid_ctrd_ptrs]
	ycen_ref_arr[*,f]=( (spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,k,f])+ytransf_im_to_ref[imin_test:imax_test,jmin_test:jmax_test,f] )[valid_ctrd_ptrs]

	xcen_ref_arr2d[imin_test:imax_test,jmin_test:jmax_test,f]=( (spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,k,f])+xtransf_im_to_ref[imin_test:imax_test,jmin_test:jmax_test,f] )
	ycen_ref_arr2d[imin_test:imax_test,jmin_test:jmax_test,f]=( (spaxels.ycentroids[imin_test:imax_test,jmin_test:jmax_test,k,f])+ytransf_im_to_ref[imin_test:imax_test,jmin_test:jmax_test,f] )

    endfor   ; ends loop over different elevations


; #####################################################################################
; calculate the mean position of each mlens psf in the reference - but use a rejection
; #####################################################################################


mean_xcen_ref=fltarr(N_ELEMENTS(valid_ctrd_ptrs))
mean_ycen_ref=fltarr(N_ELEMENTS(valid_ctrd_ptrs))

for i=0, N_ELEMENTS(valid_ctrd_ptrs)-1 do begin
	meanclip,xcen_ref_arr[i,*], tmp_mean, tmp,clipsig=2.5
	mean_xcen_ref[i]=tmp_mean
endfor

for i=0, N_ELEMENTS(valid_ctrd_ptrs)-1 do begin
	meanclip,ycen_ref_arr[i,*], tmp_mean,tmp, clipsig=2.5
	mean_ycen_ref[i]=tmp_mean
endfor


; #############################
; plot pixel phase if desired
; #############################

; a stupid idl problem that naturally collapses arrays makes this only usable when f gt 1 at the moment
if 0 eq 1 and nfiles gt 1 then begin
		stop,'at pixel phase'
		pixel_phase:
	; pp_logs is just a dump variable at the moment, but can be used to track pp over iterations
	; polynomial fitting
;	pp_logs=gpi_highres_microlens_plot_pixel_phase(spaxels.xcentroids[pp_xind-pp_neighbors:pp_xind+pp_neighbors,pp_yind-pp_neighbors:pp_yind+pp_neighbors,*,*],(spaxels.ycentroids[pp_xind-pp_neighbors:pp_xind+pp_neighbors,pp_yind-pp_neighbors:pp_yind+pp_neighbors,*,*]),pp_neighbors,n_per_lenslet,degree_of_the_polynomial_fit=degree_of_the_polynomial_fit,xtransf_im_to_ref=xtransf_im_to_ref,ytransf_im_to_ref=ytransf_im_to_ref)
	pp_logs=gpi_highres_microlens_plot_pixel_phase(spaxels.xcentroids[pp_xind-pp_neighbors:pp_xind+pp_neighbors,pp_yind-pp_neighbors:pp_yind+pp_neighbors,*,*],(spaxels.ycentroids[pp_xind-pp_neighbors:pp_xind+pp_neighbors,pp_yind-pp_neighbors:pp_yind+pp_neighbors,*,*]),pp_neighbors,n_per_lenslet,xtransf_im_to_ref=xtransf_im_to_ref[pp_xind-pp_neighbors:pp_xind+pp_neighbors,pp_yind-pp_neighbors:pp_yind+pp_neighbors,*],ytransf_im_to_ref=ytransf_im_to_ref[pp_xind-pp_neighbors:pp_xind+pp_neighbors,pp_yind-pp_neighbors:pp_yind+pp_neighbors,*])
;stop,'just finished pixel phase'
endif


; ###################################################################
; transforms the mean positions of each spot back into their images
; replaces each centroid with this mean position
; ###################################################################

; get x, y, z indices of the valid centroid pointers 
     x_id = valid_ctrd_ptrs mod 281
     y_id = valid_ctrd_ptrs / 281
     z_id = valid_ctrd_ptrs / (281L*281L)

; determine indices of arrays to replace
ind_arr = array_indices(spaxels.xcentroids[imin_test:imax_test,jmin_test:jmax_test,k,0],valid_ctrd_ptrs)

;stop,"about to apply flexure correction to centroids"


  if nfiles ne 1 then begin ; skip the flexure correction for the first run
     for f = 0,nfiles-1 do begin ; loop over each flexure position
        
	mean_xcen_ref_in_im=mean_xcen_ref-(xtransf_im_to_ref[imin_test:imax_test,jmin_test:jmax_test,f])[valid_ctrd_ptrs]
	mean_ycen_ref_in_im=mean_ycen_ref-(ytransf_im_to_ref[imin_test:imax_test,jmin_test:jmax_test,f])[valid_ctrd_ptrs]
 
;	for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do mean_xcen_ref_in_im += xtransf_ref_to_im[i,j,f]*mean_xcen_ref^j * mean_ycen_ref^i
;        for i=0,degree_of_the_polynomial_fit do for j= 0,degree_of_the_polynomial_fit do mean_ycen_ref_in_im += ytransf_ref_to_im[i,j,f]*mean_xcen_ref^j * mean_ycen_ref^i


        if (size(ind_arr))[0] gt 2 then begin
           for zx=0L,N_ELEMENTS(ind_arr[0,*])-1 do begin
              spaxels.xcentroids[ind_arr[0,zx]+imin_test,ind_arr[1,zx]+jmin_test,ind_arr[2,zx],f] = mean_xcen_ref_in_im[zx]
              spaxels.ycentroids[ind_arr[0]+imin_test,ind_arr[1]+jmin_test,ind_arr[2],f] = mean_ycen_ref_in_im[zx]
           endfor
        endif else begin
           for zx=0L,N_ELEMENTS(ind_arr[0,*])-1 do begin
              spaxels.xcentroids[ind_arr[0,zx]+imin_test,ind_arr[1,zx]+jmin_test,k,f] = mean_xcen_ref_in_im[zx]
              spaxels.ycentroids[ind_arr[0,zx]+imin_test,ind_arr[1,zx]+jmin_test,k,f] = mean_ycen_ref_in_im[zx]
           endfor
        endelse

     endfor                     ; ends loop over f to apply flexure correction (line 670)
  endif ; if statement to see if there is more than 1 file - 

     ;//////STOP HERE if you want to play with the pixel phase plots or the centroid coordinates in the different images.
     ;stop,'just before end of flexure correction' ; this is where JB_TEST.sav is created
    
	; look at how the flexure samples the pixel phase space
	
	xtmp=xtransf_im_to_ref
	ytmp=ytransf_im_to_ref
	ind=where(xtmp eq 0 and ytmp eq 0,ct)  
	xtmp[ind]=!values.f_nan
	ytmp[ind]=!values.f_nan
	
	plot, median(median(xtmp,dim=2),dim=1) mod 0.5,median(median(ytmp,dim=2),dim=1) mod 0.5,psym=2

	endfor ; this ends the loop over the transformations for each pol spot (k)	
	
	 print, 'at the end of iteration '+string(it_flex) 
endfor ; end of flexure correction loop (over it_flex)

  
     print, 'Run complete in '+strc((systime(1)-start_time)/60.)+' minutes' 

;stop
; #######################
; BUILD THE FLAT FIELD
; ######################
     if flat_field eq 1 then begin
                                ; because we cannot extract arrays
                                ; from arrays of pointers, we have to
                                ; extract them using loops
; probably best to create 1 flat per elevation - which was done in the
;                                                flat_field_arr
; but might have overlap as some pixels will have been used twice
        flat_field_arr2=fltarr(2048,2048,nfiles)
        lowfreq_flat1=fltarr(281,281,nfiles)
        lowfreq_flat2=fltarr(281,281,nfiles)
        for f=0, nfiles-1 do begin
           for k=0,n_per_lenslet-1 do for i=0,281-1 do for j=0,281-1 do begin
                                ; find values are are not masked.
              if ptr_valid(spaxels.masks[i,j,k,f]) eq 0 then continue
              value_to_consider = where(*spaxels.masks[i,j,k,f] eq 1,ct)
              if ct gt 0 then begin
                 flat_field_arr2[ (*spaxels.xcoords[i,j,k,f])[value_to_consider], (*spaxels.ycoords[i,j,k, f])[value_to_consider], replicate(f,N_ELEMENTS(value_to_consider)) ] = ((*spaxels.values[i,j,k,f])[value_to_consider] - (spaxels.sky_values[i,j,k,f]) )/((*fitted_spaxels.values[i,j,k,f]))[value_to_consider]
                 lowfreq_flat1[i,j,k,f]=total((*fitted_spaxels.values[i,j,k,f])[value_to_consider])
                 lowfreq_flat2[i,j,k,f]=total((*spaxels.values[i,j,k,f])[value_to_consider])
              endif      
           endfor
        endfor
; set the values with no flat info to NaN
ind=where(flat_field_arr2 eq 0.000,ct)
if ct gt 0 then flat_field_arr[ind]=!values.f_nan
; so now loop over each pixel and calculate the weighted mean
        final_flat=fltarr(2048,2048)
        weights=fltarr(2048,2048,nfiles)
        for n=0,nfiles-1 do weights[*,*,n]=(*(dataset.frames[n]))
        
        if nfiles eq 1 then $
           final_flat2=flat_field_arr2 $
           else final_flat2=total(weights*flat_field_arr2,3)/total(weights,3) 
           writefits, "flat_field_arr.fits",flat_field_arr

; for lenslet 135,135 
;tvdl, subarr(final_flat2,100,[953,978]),0,2
loadct,0
window,23,retain=2
;tvdl, subarr(final_flat2,100,[1442,1244]),0.9,1.1
;  for lenslet 166,177 
window,24,retain=2
image=*(dataset.currframe[0])
;tvdl, subarr(image,100,[1442,1244]),/log

endif ; end flat field creation

        
; ####################
; create flexure plots
; ####################

     if f gt 1  and 0 eq 1 then begin
; stored in xtransf_im_to_ref
        xx=(fltarr(2048)+1)##findgen(2048)
        xx1d=reform(xx,2048*2048)
        yy=findgen(2048)##(fltarr(2048)+1)
        yy1d=reform(yy,2048*2048)
        
        xflex_trans_arr1d=fltarr(2048*2048,nfiles)
        for f=0,nfiles-1 do $
           for i=0,degree_of_the_polynomial_fit do $
              for j= 0,degree_of_the_polynomial_fit do $
                 xflex_trans_arr1d[*,f] += xtransf_im_to_ref[i,j,f]*xx1d^j * yy1d^i
; now put back into 2-d arrays
        xflex_trans_arr2d=(reform(xflex_trans_arr1d,2048,2048,nfiles))
; we want the difference, so we must subtract the xx array
        for f=0,nfiles-1 do xflex_trans_arr2d[*,*,f]-=xx
        
; now do it in the y-direction
        yflex_trans_arr1d=fltarr(2048*2048,nfiles)
        for f=0,nfiles-1 do $
           for i=0,degree_of_the_polynomial_fit do $
              for j= 0,degree_of_the_polynomial_fit do $
                 yflex_trans_arr1d[*,f] += ytransf_im_to_ref[i,j,f]*xx1d^j * yy1d^i
; now put back into 2-d arrays
        yflex_trans_arr2d=(reform(yflex_trans_arr1d,2048,2048,nfiles))
; we want the difference, so we must subtract the xx array
        for f=0,nfiles-1 do yflex_trans_arr2d[*,*,f]-=yy
        
; evalute performance increase
        window,2,retain=2,title='weighted % residual'
        tmp=(weighted_diff_intensity_arr/weighted_intensity_arr)
        plothist,tmp[*,*,*,*,0],xhist,yhist,/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5
        plothist,tmp[*,*,*,*,0],/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5,yr=[0,max(yhist)*1.5],ys=1
        if nfiles ne 1 then plothist,tmp[*,*,*,*,1],/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5,/noerase,linestyle=2,yr=[0,max(yhist)*1.5],ys=1,color=155
        
        window,1,retain=2,title='non-weighted % residual'
        tmp2=(diff_intensity_arr/intensity_arr)
        
        plothist,tmp2[*,*,*,*,0],xhist,yhist,/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5
        plothist,tmp2[*,*,*,*,0],/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5,yr=[0,max(yhist)*1.5],ys=1
        if nfiles ne 1 then plothist,tmp2[*,*,*,*,1],/nan,bin=0.01,xr=[0,0.15],xs=1,charsize=1.5,/noerase,linestyle=2,yr=[0,max(yhist)*1.5],ys=1,color=155
        
     endif
     
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

stop,'about to make the file'
  
  nrw_filt=strmid(strcompress(string(filter_wavelength),/rem),0,6)
  my_file_name=gpi_get_directory('GPI_REDUCED_DATA_DIR')+'highres-'+nrw_filt+'-psf_structure.fits'
  pri_header=*dataset.headersphu[0]
  sxaddpar,pri_header,'ISCALIB','YES'
  sxaddpar,pri_header,'FILETYPE','High-res Microlens PSFs'
  sxaddpar,pri_header,'NRW_wave','1.00'
 
  mwrfits,to_save_psfs, my_file_name, /create
  ; now add values to the primary header that do not interfere
psf_header=headfits(my_file_name,exten=0)
comment_arr=strarr(N_ELEMENTS(pri_header))
;extract comments from primary header
for h=0,N_ELEMENTS(pri_header)-1 do begin 
   tmp=sxpar(pri_header,strmid(pri_header[h],0,8),comment=comment) 
   comment_arr[h]=comment 
endfor

; put into new header if it doesnt already exist 
for h=0,N_ELEMENTS(pri_header)-1 do begin
   ; check for value in structure psf header
   junk=sxpar(psf_header,strmid(pri_header[h],0,8),count=ct)
; extract value from other header
   value=sxpar(pri_header,strmid(pri_header[h],0,8),count=ct2)
   if ct eq 0 and ct2 ne 0 and strc(strmid(pri_header[h],0,8)) ne 'COMMENT' and strc(strmid(pri_header[h],0,8)) ne 'HISTORY' then sxaddpar,psf_header,strmid(pri_header[h],0,8),value,comment_arr[h]

endfor
; now actually update the header
modfits,my_file_name,0,psf_header,exten_no=0

; now do this for the second extension
psf_ext_header=headfits(my_file_name,exten=1)
ext_header=*dataset.headersext[0]
comment_arr=strarr(N_ELEMENTS(ext_header))
;extract comments from primary header
for h=0,N_ELEMENTS(ext_header)-1 do begin 
   tmp=sxpar(ext_header,strmid(ext_header[h],0,8),comment=comment) 
   comment_arr[h]=comment 
endfor

; put into new ext header if it doesnt already exist 
for h=0,N_ELEMENTS(ext_header)-1 do begin
 ; check for value in structure psf header
   junk=sxpar(psf_ext_header,strmid(ext_header[h],0,8),count=ct)
; extract value from other header
   value=sxpar(ext_header,strmid(ext_header[h],0,8),count=ct2)
if ct eq 0 and ct2 ne 0 and strc(strmid(ext_header[h],0,8)) ne 'COMMENT' and strc(strmid(ext_header[h],0,8)) ne 'HISTORY' then sxaddpar,psf_ext_header,strmid(ext_header[h],0,8),value,comment_arr[h]
endfor
; now actually modify the file
modfits,my_file_name,0,psf_ext_header,exten_no=1

stop
;  psfs_from_file = read_psfs(my_file_name, [281,281,1])
   
  my_file_name = gpi_get_directory('GPI_REDUCED_DATA_DIR')+'highres-'+nrw_filt+'-psf-spaxels.fits'
;  save, spaxels, filename=my_file_name
  
  my_file_name = gpi_get_directory('GPI_REDUCED_DATA_DIR')+'highres-'+nrw_filt+'-fitted_spaxels.fits'
;  save, fitted_spaxels, filename=my_file_name

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
  suffix = '-'+filter+'-'+nrw_filt+'PSFs'
  *(dataset.currframe)=diff_image
  dataset.validframecount=1
  backbone->set_keyword, "FILETYPE", "PSF residuals", /savecomment
  backbone->set_keyword, "ISCALIB", 'NO', 'This is NOT a reduced calibration file of some type.'
  
@__end_primitive
end

