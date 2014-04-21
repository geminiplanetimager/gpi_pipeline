;+
; NAME: gpi_highres_microlens_psf_extract_microspectra_stamps
; 
; DESCRIPTION: Extract for both spectral or pol mode the spots or the spectra corresponding to each lenslet and store them in a struct.
; 
; INPUTS:
; - my_type, equal to either "PRISM" or "WOLLASTON" to indicate the type of data to be processed.
; - image, the 2d 2048x2048 detector image
; - calibration, should be either wavcal or polcal
; - width, give the size of the stamps to extract from the image. See size of the outputs below to see in each case its influence.
; 
; KEYWORDS: 
; - STAMPS_MODE, if set, the output are 2d arrays, ie small images taken from the bigger one. if not set, the lists of values for pixels are 1d vectors.
;   
; OUTPUTS:
; - it returns a struct with the following data:
;          {values: values,$             The values of the pixels for each "stamp". This an an array of pointers. Each pointer pointings to a stamp.
;          xcoords: xcoords,$            The corresponding x coordinates. This an an array of pointers.
;          ycoords: ycoords,$            The corresponding y coordinates. This an an array of pointers.
;          xcentroids: xcentroids,$      The x coordinate of the centroids
;          ycentroids: ycentroids,$      The y coordinate of the centroids
;          intensities: intensities,$    The intensity of the spot on the "stamp"
;          sky_values: sky_values,$      The sky value around the spot
;          masks: masks,$                If stamp_mode has been activited, it gives the mask to indicate which value are interesting. This an an array of pointers.
;          tilts: tilts}                 In the case of spectra it give the tilt of it.
; 
; SIZE of the OUTPUTS:
;    if Not STAMPS_MODE
;        values = fltarr(sdpx*width (spectra) or width*width (pol),nlens,nlens,1,1) ; the one before last dimension should be npol, and the last dimension is used for different flexures. But not implemented yet.
;        xcoords = fltarr(sdpx*width (spectra) or width*width (pol),nlens,nlens,1,1) 
;        ycoords = fltarr(sdpx*width (spectra) or width*width (pol),nlens,nlens,1,1) 
;        
;    if /STAMPS_MODE
;      if spectra
;          nx = floor( max(abs(sdpx*tan(wavcal[*,*,4])),/NAN) ) + width
;          ny = sdpx
;        values = fltarr(nx,ny,nlens,nlens,1,1) ;the one before last dimension should be npol, and the last dimension is used for different flexures. But not implemented yet.
;        xcoords = fltarr(nx,ny,nlens,nlens,1,1)
;        ycoords = fltarr(nx,ny,nlens,nlens,1,1)
;        masks = fltarr(nx,ny,nlens,nlens,1,1) ;this is set only if stamps_mode is activated
;       
;      if polarization
;        values = fltarr(width,width,nlens,nlens,1,1) ;the one before last dimension should be npol, and the last dimension is used for different flexures. But not implemented yet.
;        xcoords = fltarr(width,width,nlens,nlens,1,1)
;        ycoords = fltarr(width,width,nlens,nlens,1,1) 
;        masks = = fltarr(width,width,nlens,nlens,1,1) ;this is set only if stamps_mode is activated 
;      
;    xcentroids = fltarr(nlens,nlens,1,1)
;    ycentroids = fltarr(nlens,nlens,1,1)
;    intensities = fltarr(nlens,nlens,1,1)
;    tilts = fltarr(nlens,nlens,1,1)
;    sky_values = fltarr(nlens,nlens,1,1)
;        
; HISTORY:
;   Originally by Jean-Baptiste Ruffio 2013-06
;- 
function gpi_highres_microlens_psf_extract_microspectra_stamps, my_type, image, calibration, width, STAMPS_MODE = stamps_mode,bad_pixel_mask=bad_pixel_mask;, CENTROID_MODE = centroid_mode
                  
  common PIP
  COMMON APP_CONSTANTS

;check that ptr_images is indeed an array of pointers. Otherwise it assumes it is a single 2d array.
if (size(image))[0] eq 2 then begin
  ptr_images = ptr_new(image)
  ptr_calibrations = ptr_new(calibration)
endif else begin
  ptr_images = image
  ptr_calibrations = calibration
endelse


;if ~keyword_set(centroid_mode) then begin
;  centroid_mode = "CALIB"
;endif else if ~(centroid_mode eq "CALIB" or centroid_mode eq "BARYCENTER" or centroid_mode eq "GCN" ) then begin
;;     "MAX", take the max value
;;     "BARYCENTER", take the barycenter
;;     "EDGE", when the centroid is on an edge, both pixels on each side are equal.
;  return, !values.F_NAN
;endif

case my_type of
  'PRISM': begin      
      nlens=(size(*ptr_calibrations[0]))[1]       ;pixel sidelength of final datacube (spatial dimensions) 
      dim=(size(*ptr_images[0]))[1]            ;detector sidelength in pixels
      n_diff_elev = n_elements(ptr_images)           ;number of different elevation = number of slices in the cube.
      ;error handle if readwavcal or not used before
      if (nlens eq 0) || (dim eq 0)  then return, error('FAILURE Failed to load wavelength calibration data prior to calling this primitive.') 
      ;error handle if IFSFILT keyword not found
      if (filter eq '') then return, error('FAILURE invalid filter.')

      if (width mod 2) eq 1 then width_odd = 1 else if (width mod 2) eq 0 then width_odd = 0 else return, error('width is not valid number')

      wavcal = *(ptr_calibrations[0])
      sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect) ; get the length of the spectrum (sdpx)
      ptr_values = ptrarr(nlens,nlens,1,n_diff_elev)
      ptr_xcoords = ptrarr(nlens,nlens,1,n_diff_elev)
      ptr_ycoords = ptrarr(nlens,nlens,1,n_diff_elev)
      ptr_masks = ptrarr(nlens,nlens,1,n_diff_elev)
      
      values = fltarr(sdpx*width,nlens,nlens,1) + !values.f_nan; the one before last dimension should be npol, and the last dimension is used for different flexures. But not implemented yet.
      xcoords = fltarr(sdpx*width,nlens,nlens,1) + !values.f_nan
      ycoords = fltarr(sdpx*width,nlens,nlens,1) + !values.f_nan
      xcentroids = fltarr(nlens,nlens,1,n_diff_elev) + !values.f_nan
      ycentroids = fltarr(nlens,nlens,1,n_diff_elev) + !values.f_nan
      intensities = fltarr(nlens,nlens,1,n_diff_elev) + !values.f_nan
      tilts = fltarr(nlens,nlens,1,n_diff_elev) + !values.f_nan
      sky_values = fltarr(nlens,nlens,1,n_diff_elev) ;will stay zero because I don't know if how we could get the sky value with the spetra (they are too close)
      masks = !values.f_nan ;this is set only if stamps_mode is activated

      nx = floor( max(abs(sdpx*tan(wavcal[*,*,4])),/NAN) ) + width
      ny = sdpx
        
      values_stamps = fltarr(nx,ny,nlens,nlens,1) + !values.f_nan ; the one before last dimension should be npol, and the last dimension is used for different flexures. But not implemented yet.
      masks_stamps = bytarr(nx,ny,nlens,nlens,1) + !values.f_nan
      xcoords_stamps = fltarr(nx,ny,nlens,nlens,1) + !values.f_nan
      ycoords_stamps = fltarr(nx,ny,nlens,nlens,1) + !values.f_nan

;/////////////////////////////////////////////////////////////////////////
;/////// Iteration over the different elevations
      for it_elev = 0,n_diff_elev-1 do begin
				image = *(ptr_images[it_elev])*bad_pixel_mask

		  ;get length of spectrum
      ;maybe sdpx should be variable. the length of the spectra is not constant over the detector
      ;TODO: filter is a variable of the common PIP I think but sometimes it is not defined. I don't know where the definition occurs. Should check that.
      ;PROBLEM with sdpx, too small sometimes!!

			; need an spdx that is large enough for the entire field and that stays constant
			; using the first spdx for the reference.
			
				wavcal = *(ptr_calibrations[it_elev])
				wavcal0 = *(ptr_calibrations[0])

       sdpx0 = calc_sdpx(wavcal0, filter, xmini, CommonWavVect)
			 sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)

      if (sdpx < 0) then return, error('FAILURE Wavelength solution is bogus! All values are NaN.')
      
      
      ;Get the coordinates of the pixels
      xcoords_cal = fltarr(sdpx0,nlens,nlens)
      ycoords_cal = fltarr(sdpx0,nlens,nlens)
      for i=0,sdpx0-1 do begin
        ycoords_cal[i,*,*] = reform(xmini - i ,1,nlens,nlens)
        xcoords_cal[i,*,*] = reform(wavcal[*,*,1]+(wavcal[*,*,0]-ycoords_cal[i,*,*])*tan(wavcal[*,*,4]),1,nlens,nlens)
;stop
      endfor
      if width_odd then begin ; width is odd
        xcoords[0:sdpx0-1,*,*] = xcoords_cal
        ycoords[0:sdpx0-1,*,*] = ycoords_cal
        for w=1,floor(width/2) do begin
          ycoords[(2*w-1)*sdpx0:(2*w)*sdpx0-1,*,*] = ycoords_cal
          ycoords[(2*w)*sdpx0:(2*w+1)*sdpx0-1,*,*] = ycoords_cal
          xcoords[(2*w-1)*sdpx0:(2*w)*sdpx0-1,*,*] = round(xcoords_cal + w)
          xcoords[(2*w)*sdpx0:(2*w+1)*sdpx0-1,*,*] = round(xcoords_cal - w)
        endfor
      endif else begin;width is even
        for w=1,floor(width/2) do begin
          ycoords[(2*w-2)*sdpx0:(2*w-1)*sdpx0-1,*,*] = ycoords_cal
          ycoords[(2*w-1)*sdpx0:(2*w)*sdpx0-1,*,*] = ycoords_cal
          xcoords[(2*w-2)*sdpx0:(2*w-1)*sdpx0-1,*,*] = round(xcoords_cal + w - 0.5)
          xcoords[(2*w-1)*sdpx0:(2*w)*sdpx0-1,*,*] = round(xcoords_cal - w + 0.5)
        endfor
      endelse
      coords_not_good = where( ~finite(xcoords) or ~finite(ycoords) or (ycoords LE 4.0) OR (ycoords GE 2043.0) OR (xcoords LE 4.0) OR (xcoords GE 2043.0), COMPLEMENT = where_good)
      xcoords[coords_not_good] = !values.f_nan
      ycoords[coords_not_good] = !values.f_nan
      
      ;get the values
      values = image[xcoords,ycoords]
      values[coords_not_good] = !values.f_nan
      
      ;get the intensities
;      tmp_values = values
;      tmp_values[where(~finite(values))] = 0.0
;      intensities = total(tmp_values,1)
      intensities[*,*,0,it_elev] = total(values,1,/nan)
      
      ;get the centroids
;      ycentroids = wavcal[*,*,0]
;      xcentroids = wavcal[*,*,1]
      tilts[*,*,0,it_elev] = wavcal[*,*,4]
      
      ;I don't like it, it should converge even with the centroid above. if you want to know what I mean ask JB.
      ;The few line below are the only way to have a correct fit for spectra right now.
      xcoords_nonans = xcoords
      ycoords_nonans = ycoords
      values_nonans = values
      xcoords_nonans[where(~finite(xcoords_nonans))] = 0.0
      ycoords_nonans[where(~finite(ycoords_nonans))] = 0.0
      values_nonans[where(~finite(values_nonans))] = 0.0
      
      xcentroids[*,*,0,it_elev] = total(values_nonans*xcoords_nonans,1)/total(values_nonans,1)
      ycentroids[*,*,0,it_elev] = total(values_nonans*ycoords_nonans,1)/total(values_nonans,1)
      

      
      if keyword_set(stamps_mode) eq 1 then begin
        mask_image = bytarr(dim,dim)
        ;writefits, "/Users/jruffio/Desktop/mask_image.fits",mask_image
        xcoords_image = rebin(findgen(dim),dim,dim)
        ycoords_image = rebin(reform(findgen(dim),1,dim),dim,dim)
        
       
        for i=0,nlens-1 do begin
          for j=0,nlens-1 do begin
		; check to see if the spaxel is defined
		if finite(wavcal[i,j,4]) eq 0 then continue
		; depends on the tilt - so if the tilt gt 0
        	    if wavcal[i,j,4] ge 0.0 then begin
	              mask_image[xcoords[where(finite(xcoords[*,i,j])),i,j],ycoords[where(finite(ycoords[*,i,j])),i,j]] = 1
	              xlim = round(wavcal[i,j,1]+(wavcal[i,j,0]-xmini[i,j])*tan(wavcal[i,j,4]) - float((width-1))/2.)
	              ylim = xmini[i,j]-ny+1
	              
	              xmin = max([0,xlim])
	              xmax = min([2047,(xlim+nx-1)])
	              ymin = max([0,ylim])
	              ymax = min([2047,(ylim+ny-1)])
       	       
		      values_stamps[0:xmax-xmin,0:ymax-ymin,i,j] = image[xmin:xmax,ymin:ymax]
			masks_stamps[0:xmax-xmin,0:ymax-ymin,i,j] = mask_image[xmin:xmax,ymin:ymax]*(bad_pixel_mask)[xmin:xmax,ymin:ymax]
       	       xcoords_stamps[0:xmax-xmin,0:ymax-ymin,i,j] = xcoords_image[xmin:xmax,ymin:ymax]
       	       ycoords_stamps[0:xmax-xmin,0:ymax-ymin,i,j] = ycoords_image[xmin:xmax,ymin:ymax]
              
              mask_image[xcoords[where(finite(xcoords[*,i,j])),i,j],ycoords[where(finite(ycoords[*,i,j])),i,j]] = 0
							 ;endif else if wavcal[i,j,4] lt 0.0 then begin
		endif else begin 
							; so this is when wavcal[i,j,4] lt 0.0
              mask_image[xcoords[where(finite(xcoords[*,i,j])),i,j],ycoords[where(finite(ycoords[*,i,j])),i,j]] = 1
        
              xlim = round(wavcal[i,j,1]+(wavcal[i,j,0]-xmini[i,j])*tan(wavcal[i,j,4]) + float((width-1))/2.)
              ylim = xmini[i,j]-ny+1
              
              xmin = max([0,(xlim-nx+1)])
              xmax = min([2047,xlim])
              ymin = max([0,ylim])
              ymax = min([2047,(ylim+ny-1)])
              
              values_stamps[0:xmax-xmin,0:ymax-ymin,i,j] = image[xmin:xmax,ymin:ymax]
              masks_stamps[0:xmax-xmin,0:ymax-ymin,i,j] = mask_image[xmin:xmax,ymin:ymax]*(bad_pixel_mask)[xmin:xmax,ymin:ymax]
              xcoords_stamps[0:xmax-xmin,0:ymax-ymin,i,j] = xcoords_image[xmin:xmax,ymin:ymax]
              ycoords_stamps[0:xmax-xmin,0:ymax-ymin,i,j] = ycoords_image[xmin:xmax,ymin:ymax]
                           
              mask_image[xcoords[where(finite(xcoords[*,i,j])),i,j],ycoords[where(finite(ycoords[*,i,j])),i,j]] = 0
            endelse
		; now calculate the centroids - this just does a center of mass calculation
		tmpx=xcentroids[i,j,0,it_elev]
		tmpy=ycentroids[i,j,0,it_elev]
		xcentroids[i,j,0,it_elev]= total(values_stamps[0:xmax-xmin,0:ymax-ymin,i,j]*$
						xcoords_stamps[0:xmax-xmin,0:ymax-ymin,i,j]*$ 
						masks_stamps[0:xmax-xmin,0:ymax-ymin,i,j])/$ 
						total(values_stamps[0:xmax-xmin,0:ymax-ymin,i,j]*$
						      masks_stamps[0:xmax-xmin,0:ymax-ymin,i,j])
		ycentroids[i,j,0,it_elev]= total(values_stamps[0:xmax-xmin,0:ymax-ymin,i,j]*$
						ycoords_stamps[0:xmax-xmin,0:ymax-ymin,i,j]*$
						masks_stamps[0:xmax-xmin,0:ymax-ymin,i,j])/$ 
						total(values_stamps[0:xmax-xmin,0:ymax-ymin,i,j]*$
						masks_stamps[0:xmax-xmin,0:ymax-ymin,i,j])
			; the following just flags if the offset is too large?
			if tmpx-xcentroids[i,j,0,it_elev] ge 1.1*tmpx then stop ; PI: Have never seen this flag
			if tmpy-ycentroids[i,j,0,it_elev] ge 1.1*tmpy then stop ; PI: Have never seen this flag
          endfor
        endfor
      endif

      if keyword_set(stamps_mode) eq 1 then begin
        for i=0,nlens-1 do begin
          for j=0,nlens-1 do begin
            spaxel_valid = (where(finite(values_stamps[*,*,i,j])))[0] ne -1
            if spaxel_valid eq 1 then begin
              ptr_values[i,j,0,it_elev] = ptr_new(values_stamps[*,*,i,j])
              ptr_xcoords[i,j,0,it_elev] = ptr_new(xcoords_stamps[*,*,i,j])
              ptr_ycoords[i,j,0,it_elev] = ptr_new(ycoords_stamps[*,*,i,j])
              ptr_masks[i,j,0,it_elev] = ptr_new(masks_stamps[*,*,i,j])
            endif
          endfor
        endfor
      endif else begin
        for i=0,nlens-1 do begin
          for j=0,nlens-1 do begin
            spaxel_valid = (where(finite(values[*,i,j])))[0] ne -1
            if spaxel_valid eq 1 then begin
              ptr_values[i,j,0,it_elev] = ptr_new(values[*,i,j])
              ptr_xcoords[i,j,0,it_elev] = ptr_new(xcoords[*,i,j])
              ptr_ycoords[i,j,0,it_elev] = ptr_new(ycoords[*,i,j])
            endif
          endfor
        endfor
      endelse

      endfor
;/////// End of the iteration for the different elevations
;/////////////////////////////////////////////////////////////////////////

      ;just to be sure we delete the useless variables
      delvarx, values,xcoords,ycoords,masks
  end ; PRISM case
  'WOLLASTON': begin
      ;load the pol solution
      polspot_coords = polcal.coords
      polspot_position = polcal.spotpos
      if ((size(polspot_coords))[0] eq 0) then begin
        return, error('FAILURE Failed to load polarimetry calibration data prior to calling this primitive.') 
      endif
      nlens=(size(polspot_coords))[3]
	  dim = (size(image))[1]

	  n_diff_elev = 1 ; multiple elevations not yet implemented...
; Actually, I think you can just uncomment the following and it should work - but this is untested
;		  n_diff_elev = n_elements(ptr_images)           ;number of different elevation = number of slices in the cube.

      ptr_values = ptrarr(nlens,nlens,2,n_diff_elev)
      ptr_xcoords = ptrarr(nlens,nlens,2,n_diff_elev)
      ptr_ycoords = ptrarr(nlens,nlens,2,n_diff_elev)
      ptr_masks = ptrarr(nlens,nlens,2,n_diff_elev)
      
      values = fltarr(width,width,nlens,nlens,2,1) + !values.f_nan; the one before last dimension should be npol, and the last dimension is used for different flexures. But not implemented yet.
      xcoords = fltarr(width,width,nlens,nlens,2,1) + !values.f_nan
      ycoords = fltarr(width,width,nlens,nlens,2,1) + !values.f_nan
      xcentroids = fltarr(nlens,nlens,2,1) + !values.f_nan
      ycentroids = fltarr(nlens,nlens,2,1) + !values.f_nan
      intensities = fltarr(nlens,nlens,2,1) + !values.f_nan
      sky_values = fltarr(nlens,nlens,2,1) + !values.f_nan
      masks =  bytarr(width,width,nlens,nlens,2,1)
      tilts = fltarr(nlens,nlens,2,1)
      
      xcoords_image = rebin(findgen(dim),dim,dim)
      ycoords_image = rebin(reform(findgen(dim),1,dim),dim,dim)
      
        ;///////////////////////////////////
        ;loop over all the spots
        half_width = float(width-1)/2.
        for npol=0,1 do begin
          for i=0,nlens-1 do begin
            for j=0,nlens-1 do begin
              xcen_cal = polspot_position[0,i,j,npol]
              ycen_cal = polspot_position[1,i,j,npol]
              xcen_cal_pix = round(polspot_position[0,i,j,npol])
              ycen_cal_pix = round(polspot_position[1,i,j,npol])
              
              ;I think it could be (width-2.)/2. for the condition below and not half_width = (width-1.)/2. but anyway...
              spot_valid = finite(xcen_cal_pix) AND $
                            finite(ycen_cal_pix) AND $
                            xcen_cal_pix gt float(half_width) + 4. AND $
                            ycen_cal_pix gt float(half_width) + 4. AND $
                            xcen_cal_pix lt 2047.-float(half_width) - 4. AND $
                            ycen_cal_pix lt 2047.-float(half_width) - 4.
              
              if spot_valid then begin
                
				; Cut out the individual stamps and their coordinates and store
				; them.
                values[*,*,i,j,npol] = image[round(xcen_cal_pix-half_width):round(xcen_cal_pix+half_width),round(ycen_cal_pix-half_width):round(ycen_cal_pix+half_width)]
                xcoords[*,*,i,j,npol] = xcoords_image[round(xcen_cal_pix-half_width):round(xcen_cal_pix+half_width),round(ycen_cal_pix-half_width):round(ycen_cal_pix+half_width)]
                ycoords[*,*,i,j,npol] = ycoords_image[round(xcen_cal_pix-half_width):round(xcen_cal_pix+half_width),round(ycen_cal_pix-half_width):round(ycen_cal_pix+half_width)]

				; The following is wrong - it's assuming we can use circular
				; masks of fixed radius to capture the regions where there is
				; light for each lenslet PSF, and that is simply not the case. 
				; Let's use the entire lenslet PSF for each. - MP
                ;tmp_mask = bytarr(width,width)
                ;tmp_mask[where( sqrt((xcoords[*,*,i,j,npol]-xcen_cal)^2+(ycoords[*,*,i,j,npol]-ycen_cal)^2) le float(width)/2. )] = 1
                masks[*,*,i,j,npol] =  1; temporary(tmp_mask)
                
                if ~keyword_set(stamps_mode) then begin
                  values[where(masks ne 1)] = !values.f_nan
                  xcoords[where(masks ne 1)] = !values.f_nan
                  ycoords[where(masks ne 1)] = !values.f_nan
                  
                  values = reform(values,width*width,nlens,nlens,2,1)
                  xcoords = reform(xcoords,width*width,nlens,nlens,2,1)
                  ycoords = reform(ycoords,width*width,nlens,nlens,2,1)
                  masks = !values.f_nan
                endif
                
                
                ;!!!!!!!!!!!!!!!!TO CHANGE TO MAX AFTER DEBUGGING
                ;width_spot = mean(polspot_position[3:4,i,j,npol],/nan)
				; MP: The above line here does not work in some cases, where the
				; fitting done in the pol spot calibration for some reason was
				; off for this lenslet. It seems more robust to use a median
				; from a small local region:
				width_spot = median(polspot_position[3:4,i-2:i+2,j-2:j+2,npol])
                
                ;get the coordinates of the pixels close to the current one
                all_x_coords_neighboors = reform(polspot_coords[0,*,max([0,(i-1)]):min([(nlens-1),(i+1)]),max([0,(j-1)]):min([(nlens-1),(j+1)]),*])
                all_y_coords_neighboors = reform(polspot_coords[1,*,max([0,(i-1)]):min([(nlens-1),(i+1)]),max([0,(j-1)]):min([(nlens-1),(j+1)]),*])
                
                
                ;remove from that list the coordinate corresponding to the current pixel
                all_x_coords_neighboors[*,i-max([0,(i-1)]),j-max([0,(j-1)]),npol] = !values.f_nan
                all_y_coords_neighboors[*,i-max([0,(i-1)]),j-max([0,(j-1)]),npol] = !values.f_nan
                
                ;take only the valid coordinates
                valid_neighbors = where( finite(all_x_coords_neighboors) AND $
                                         finite(all_y_coords_neighboors) AND $
                                         all_x_coords_neighboors gt 3 AND $
                                         all_y_coords_neighboors gt 3 AND $
                                         all_x_coords_neighboors lt 2044 AND $
                                         all_y_coords_neighboors lt 2044)
                
                ;we want to save them before to be able to restore them after the aperture photometry (because we will temporarly erase this pixels from the image)
                save_neighbors_flux = image[all_x_coords_neighboors[valid_neighbors],all_y_coords_neighboors[valid_neighbors]]
                
                ;temporarly mask the neighbors for the sky computation in function aper
                image[all_x_coords_neighboors[valid_neighbors],all_y_coords_neighboors[valid_neighbors]] = !values.f_nan
                
                
      ;          ;We have some problems with nans that are in the aperture and prevent aper to compute the spot flux so we will set them a value that will not change a lot the sky.
      ;          ;So all Nans that are closer than 3.*width_spot to the current spot are set to a value very close to the sky
      ;          ;This pixels will be restored right after
                nans_too_close = where(abs(all_x_coords_neighboors[valid_neighbors[*]] - xcen_cal) lt 3.*width_spot AND $
									   abs(all_y_coords_neighboors[valid_neighbors[*]] - ycen_cal) lt 3.*width_spot AND $
									   ~finite(image[all_x_coords_neighboors[valid_neighbors[*]],all_y_coords_neighboors[valid_neighbors[*]]]) )

                if nans_too_close[0] ne -1 then begin
                  image[all_x_coords_neighboors[valid_neighbors[nans_too_close]],$
                        all_y_coords_neighboors[valid_neighbors[nans_too_close]]] = median(image[max([0,(xcen_cal-5*width_spot)]):min([2047,(xcen_cal+5*width_spot)]),$
                                                                                                max([0,(ycen_cal-5*width_spot)]):min([2047,(ycen_cal+5*width_spot)]) ])
                endif
                
                ;/////////////////////////
                ;APERTURE PHOTOMETRY!!!!!
                ;Note: Aperture photometry with a radius of 2.35482*width_spot = FWHM = 2*sqrt(2*Ln(2))*sigma
                ;Note: Sky computation in the interval of radii [2.35482*width_spot,5*width_spot], We masked the spot in the aera so it should be fine.
                APER, image, xcen_cal, ycen_cal, flux, errap, sky, skyerr, 1.0, 2.35482*width_spot, [2.35482*width_spot,5*width_spot], /FLUX, /NAN, /SILENT
      ;          APER, image, xcen_cal, ycen_cal, flux, errap, sky, skyerr, 1.0, 1.5*width_spot, [3.0*width_spot,5*width_spot], /FLUX, /NAN, /SILENT
                intensities[i,j,npol] = flux
                sky_values[i,j,npol] = sky
				if sky eq 0 then stop
                ;/////////////////////////
                
                ;/////////////////////////
                ;CENTROIDS!!!!!
;                gcntrd,image,xcen_cal,ycen_cal,xcen,ycen,2.35482*width_spot
;                xcentroids[i,j,npol] = xcen
;                ycentroids[i,j,npol] = ycen
                xcentroids[i,j,npol] = xcen_cal
                ycentroids[i,j,npol] = ycen_cal
                ;/////////////////////////
                
                ;restore the masked pixels
                image[all_x_coords_neighboors[valid_neighbors],all_y_coords_neighboors[valid_neighbors]] = save_neighbors_flux

				; Convert everything into pointer arrays for compatibility with what the
				; spectral mode code is now doing... I don't know why JB wrote it this way
				; but I will stick with it. -MP

				it_elev=0 ; multiple elevations not yet implemented
				ptr_values[i,j,npol,it_elev] = ptr_new(values[*,*,i,j, npol])
				ptr_xcoords[i,j,npol,it_elev] = ptr_new(xcoords[*,*,i,j, npol])
				ptr_ycoords[i,j,npol,it_elev] = ptr_new(ycoords[*,*,i,j, npol])
				ptr_masks[i,j,npol,it_elev] = ptr_new(masks[*,*,i,j, npol])
                
              endif
              
            endfor
          endfor
        endfor
      ;///////////////////////////////////
      
	if keyword_set(stop) then begin
		; allow for interative examination:
		values2 = reform(values, 7,7,281L*281*2)
		medians = meds(values2)
		wf= where(finite(medians))
		atv, values2[*,*,wf],/bl  
		stop    
	end

  end

endcase



return,  {values: ptr_values,$
          xcoords: ptr_xcoords,$
          ycoords: ptr_ycoords,$
          xcentroids: xcentroids,$
          ycentroids: ycentroids,$
          intensities: intensities,$
          sky_values: sky_values,$
          masks: ptr_masks,$
          tilts: tilts}
end
