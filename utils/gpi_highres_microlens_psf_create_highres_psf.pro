;+
; NAME: gpi_highres_microlens_psf_create_highres_psf
; 
; DESCRIPTION: Compute a high resolution PSF from a set of regularly sampled PSFs.
; 
;   The output PSF will be given on the grid which size is defined by PSF_nx_pix, PSF_ny_pix, PSF_samples_per_xpix and PSF_samples_per_ypix.
;   The x and y coordinates can be obtained in the output structure (.xcoords and.ycoords).
;   The x = 0.0 and y = 0.0  is the centroid of the PSF defined so that when the centroid is on an edge between to pixels, the value of the two pixel be equal.
;
; INPUTS:
;
;    The PSF can be computed using PSF samples in 2D (using the keyword MASK) or in
;    1D (using the keyword XCOORDS and YCOORDS). In the 2D case the input PSF
;    samples are many small images, most likely stamps extracted from an image
;    around each of the PSF spots. In the 1D case, it means you already have the
;    coordinates of the points.
;
; 
;    if MASK is defined, then
;        XCOORDS and YCOORDS must not be defined
;      - MASK, mask should be a cube of same dimension as pixel_array. mask indicates if the corresponding pixel in pixel_array should be considered (=1) are ignored (=0).
;      - pixel_array, pixel_array should be a cube of data of dimension nx x ny x nz. nx x ny being the dimension of the image including the sampled PSF. nz being the number of samples of the same PSF.
;      - x_centroids, give the centroids of the PSFs. It should be a vector of nz elements. The origin is taken at the center of the pixel of coordinates [0,0].
;      - y_centroids, same as x_centroids but for the y-coordinates
;      - intensities, give the intensities of the PSFs (meaning their weights or the total flux). It should be a vector of nz elements.
;      - sky_values, give the sky values for each slice, ie what to subtract. It should be a vector of nz elements.
;    
;    Or if XCOORDS AND YCOORDS are defined
;        MASK must not be defined
;      - XCOORDS, xcoords should be an array of dimension nx x ny containing the x-coordinates of the pixels of the PSF samples. nx being the number values for each PSF sample. ny being the number of samples of the same PSF. f_nan values are considered as missing data and can be used to fill the array if there is not enough points for one PSF.
;      - YCOORDS, same as xcoords but for the y-coordinates
;      - pixel_array, 
;      - x_centroids, give the centroids of the PSFs. It should be a vector of ny elements. The coordinates should be consistent with xcoords and ycoords.
;      - y_centroids, same as x_centroids but for the y-coordinates 
;      - intensities, give the intensities of the PSFs (meaning their weights or the total flux). It should be a vector of ny elements.
;      - sky_values, give the sky values for each slice, ie what to subtract. It should be a vector of ny elements.
;    
;    In both cases:
;    - PSF_nx_pix, The width of the returned PSF in number of pixel along the x_axis. Should be greater than 3.
;    - PSF_ny_pix, The width of the returned PSF in number of pixel along the y_axis. Should be greater than 3.
;    - PSF_samples_per_xpix, The number of intervals in which a pixel should be cut along the x_axis.
;    - PSF_samples_per_ypix, The number of intervals in which a pixel should be cut along the y_axis.
;
;
; KEYWORDS: 
;  CENTROID_MODE		indicate the method to use to compute the centroid of the PSF.
;                          "MAX", take the max value
;                          "BARYCENTER", take the barycenter
;                          "EDGE", when the centroid is on an edge, both pixels
;                                  on each side are equal.  (Deprecated, do not use)
;                             If the spline interpolation cannot be performed (for MAX and EDGE), a simple barycenter is used to get the centroid. (see error_flag = -8)
;  PLOT_SAMPLES			 plot (in window 0) the point samples in the high resolution PSF grid. It triggers a stop in the function.
;  HOW_WELL_SAMPLED		 return an array of same size as the PSF with the number of samples used for inferring each point.
; 
;
; OUTPUTS:  
;   Returned value: A pointer to the structure of the computed PSF (null pointer if an error occured, see error_flag):
;   obj_PSF = {values: psf, $                 contains the values of the psf to the points defined by xcoords and ycoords. It is an array of dimension PSF_nx_samples x PSF_ny_samples, with:
;                                                 PSF_nx_samples = PSF_nx_pix*PSF_samples_per_xpix + 1
;                                                 PSF_ny_samples = PSF_ny_pix*PSF_samples_per_ypix + 1
;             xcoords: PSF_x_sampling, $      is a vector with the values along the x-axis where the returned PSF is sampled.
;             ycoords: PSF_y_sampling, $      is a vector with the values along the y-axis where the returned PSF is sampled.
;             tilt: 0.0,$
;             id: lenslet_indices }                   a 4 elements vector containing indices to locate the psf. in the context of the gpi pipeline. id[0] and id[1] are the indices for the lenslet array. id[2] the spot number in case of polarimetry data for example. 
;                                             id is used by the function read_psfs() to rebuild a readable array of psf.
;                                             
;   ERROR_FLAG = error_flag
;     -8: There are not enough finite point in the PSF so we can't compute the spline interpolation. The new centroid is therefore computed with a simple barycenter of the finite values. 
;     -7: no valid samples to build the PSF.
;     -6: CENTROID_MODE unknown.
;     -5: In the case of MASK, the dimension of a single slice in mask is not consistent with the slices of pixel_array.
;     -4: The number of PSF samples is not the same for all the inputs.
;     -3: In the case XCOORDS AND YCOORDS, it means that the number of elements of the first dimension of either pixel_array, xcoords or ycoords is not good.
;     -2: There is at least one input with a number of dimensions either not consistent with the others.
;     -1: The inputs don't match with any mode (MASK or XCOORDS AND YCOORDS). Verify that you don't define MASK if you define the others and vice versa. Check if pixel_array has the right number of dimensions regarding the chosen mode.
;     0: Everything looks fine.
;     >1: Give the number of points where the PSF couldn't be evaluated. Either because there were no points around this corrdinate in the input data or because all the values don't respect the the 3 sigma variation constraint.
;
; HISTORY:
;   Originally by Jean-Baptiste Ruffio 2013-06
;   2014-01 - Pol mode code updates, slightly improved documentation, code cleanup. MP
;- 
function gpi_highres_microlens_psf_create_highres_psf, pixel_array, x_centroids, y_centroids, intensities, sky_values, $
                  PSF_nx_pix,PSF_ny_pix, PSF_samples_per_xpix, PSF_samples_per_ypix, $
                  MASK = mask,  XCOORDS = xcoords, YCOORDS = ycoords, filter=filter $
                  ERROR_FLAG = error_flag, $
                  SPLINE_PSF = spline_psf, X_SPLINE_PSF = x_spline_psf, Y_SPLINE_PSF = y_spline_psf, $
                  CENTROID_MODE = centroid_mode, $
                  PLOT_SAMPLES = plot_samples,$
                  HOW_WELL_SAMPLED = how_well_sampled,$
                  LENSLET_INDICES = lenslet_indices, no_error_checking=no_error_checking
                  

error_flag = 0

;------------------------------------
;  Check the validity of the inputs in both case (vector of coordinates or stamps).
;  In case of stamps, the stamps are reformed in vectors of coordinates. This way, only one type of array is considered in the next section
pixel_array_sz = size(pixel_array)

; check to see if this is the first run through
if keyword_set(xcoords) and keyword_set(ycoords) and ~keyword_set(mask) and pixel_array_sz[0] eq 2 then begin
	xcoords_sz = size(xcoords)
	ycoords_sz = size(ycoords)
	x_centroids_sz = size(x_centroids)
	y_centroids_sz = size(y_centroids)
	intensities_sz = size(intensities)
	sky_values_sz = size(sky_values)
  
	if keyword_set(no_error_checking) eq 0 then begin
		;check that all the arrays have the expecting number of dimensions
		if ~(xcoords_sz[0] eq 2 and ycoords_sz[0] eq 2 and x_centroids_sz[0] eq 1 and y_centroids_sz[0] eq 1 and intensities_sz[0] eq 1 and sky_values_sz[0] eq 1) then begin
			error_flag = -2
			return, ptr_new()
		endif
		;check that pixel_array, xcoords and ycoords have a consistent first dimension
		if ~(xcoords_sz[1] eq pixel_array_sz[1] and ycoords_sz[1] eq pixel_array_sz[1]) then begin
			error_flag = -3
			return, ptr_new()
		endif
		;check that all the arrays ( pixel_array, x_centroids, y_centroids, intensities, sky_values, xcoords and ycoords) have the same number of PSF samples.
		if ~(xcoords_sz[2] eq pixel_array_sz[2] and ycoords_sz[2] eq pixel_array_sz[2] and x_centroids_sz[1] eq pixel_array_sz[2] and y_centroids_sz[1] eq pixel_array_sz[2] and intensities_sz[1] eq pixel_array_sz[2] and sky_values_sz[1] eq pixel_array_sz[2]) then begin
			error_flag = -4
			return, ptr_new()
		endif
	endif

	all_pix_values = pixel_array
	n_PSF_samples = pixel_array_sz[2]
endif else if ~keyword_set(xcoords) and ~keyword_set(ycoords) and keyword_set(mask) and pixel_array_sz[0] eq 3 then begin
	nx_pix = pixel_array_sz[1]
	ny_pix = pixel_array_sz[2]
	n_PSF_samples = pixel_array_sz[3]
	
	mask_sz = size(mask)
	x_centroids_sz = size(x_centroids)
	y_centroids_sz = size(y_centroids)
	intensities_sz = size(intensities)
	sky_values_sz = size(sky_values)

	if keyword_set(no_error_checking) eq 0 then begin
	  ;check that all the arrays have the expecting number of dimensions
	  if ~(mask_sz[0] eq 3 and x_centroids_sz[0] eq 1 and y_centroids_sz[0] eq 1 and intensities_sz[0] eq 1 and sky_values_sz[0] eq 1) then begin
	    error_flag = -2
	    return, ptr_new()
	  endif
	  ;check that the dimension of the image stamps are consistent in mask and pixel_array
	  if ~(mask_sz[1] eq nx_pix and mask_sz[2] eq ny_pix) then begin
	    error_flag = -5
	    return, ptr_new()
	  endif
	  ;check that all the arrays ( pixel_array, x_centroids, y_centroids, intensities and mask) have the same number of PSF samples.
	  if ~(mask_sz[3] eq n_PSF_samples and x_centroids_sz[1] eq n_PSF_samples and y_centroids_sz[1] eq n_PSF_samples and intensities_sz[1] eq n_PSF_samples and sky_values_sz[1] eq n_PSF_samples) then begin
	    error_flag = -4
	    return, ptr_new()
	  endif
	endif

	image_x_sampling = findgen(nx_pix)
	image_y_sampling = findgen(ny_pix)
	
	; I think this makes it such that we only consider the relevant psfs 
	; there were originally three different ways to do this, but this was determined to be the quickest. 

	all_pix_values = reform(pixel_array,nx_pix*ny_pix,n_PSF_samples)	
	xcoords = rebin(reform(rebin(image_x_sampling,nx_pix,ny_pix),nx_pix*ny_pix),nx_pix*ny_pix,n_PSF_samples)
	ycoords = rebin(reform(rebin(reform(image_y_sampling,1,ny_pix),nx_pix,ny_pix),nx_pix*ny_pix),nx_pix*ny_pix,n_PSF_samples)
	not_relevant = where((reform(mask,nx_pix*ny_pix,n_PSF_samples)) eq 0)
	if not_relevant[0] ne -1 then begin
	  all_pix_values[not_relevant] = !values.f_nan
	  xcoords[not_relevant] = !values.f_nan
	  ycoords[not_relevant] = !values.f_nan
	endif


endif else begin
	error_flag = -1
	return, ptr_new()
endelse

if ~keyword_set(centroid_mode) then begin
  centroid_mode = "MAX"
endif else if ~(centroid_mode eq "MAX" or centroid_mode eq "BARYCENTER" or centroid_mode eq "EDGE" ) then begin
;     "MAX", take the max value
;     "BARYCENTER", take the barycenter
;     "EDGE", when the centroid is on an edge, both pixels on each side are equal.
  error_flag = -6
  return, ptr_new()
endif

;------------------------------------
;   Build the PSF with all the data
;
all_x_coords = float(xcoords)
all_y_coords = float(ycoords)
for i=0L,long(n_PSF_samples-1) do begin
  all_x_coords[*,i] = xcoords[*,i]-x_centroids[i]
  all_y_coords[*,i] = ycoords[*,i]-y_centroids[i]
  all_pix_values[*,i] = (all_pix_values[*,i] - sky_values[i])/intensities[i]
endfor

all_x_coords = reform(all_x_coords, n_elements(all_x_coords))
all_y_coords = reform(all_y_coords, n_elements(all_y_coords))
all_pix_values = reform(all_pix_values, n_elements(all_pix_values)) 

; want a coordinate system with 0,0 at the centroid
PSF_nx_samples = PSF_nx_pix*PSF_samples_per_xpix + 1 ; 7 pixels box * 5 samples per pixel
PSF_ny_samples = PSF_ny_pix*PSF_samples_per_ypix + 1 ; 22 pixel box * 5 samples per pixel
PSF_x_step = 1.0/float(PSF_samples_per_xpix) ; step size of sampling
PSF_y_step = 1.0/float(PSF_samples_per_ypix)
; want the mean centered at 0,0 ?
;PSF_x_sampling = (findgen(PSF_nx_samples) - floor(PSF_nx_samples/2))* PSF_x_step - (mean(x_centroids,/nan)/(nx_pix-1) - 0.5)*PSF_nx_samples*PSF_x_step ; original - but doesnt have a 0,0 pt
;PSF_y_sampling = (findgen(PSF_ny_samples) - floor(PSF_ny_samples/2))* PSF_y_step - (mean(y_centroids,/nan)/(ny_pix-1) - 0.5)*PSF_ny_samples*PSF_y_step ; original - but doesnt have a 0,0 pt

; so we want a grid where the centroid is centered at 0,0 - but we still need a 0,0 point
; set up the sampling in y
; creates symmetrical grid the length of the box with zero at center
PSF_y_sampling = (findgen(PSF_ny_samples) - floor(PSF_ny_samples/2))* PSF_y_step 
; offset the grid to make the centroid at 0,0
yoffset=round( (median(y_centroids)+psf_y_sampling[0])/psf_y_step) ; gives offset in pixels!
psf_y_sampling+=(yoffset*psf_y_step) ; apply offset to grid - but the size of a stepsize

; set up the sampling in x
; creates symmetrical grid the length of the box with zero at center
PSF_x_sampling = (findgen(PSF_nx_samples) - floor(PSF_nx_samples/2))* PSF_x_step 
; offset the grid to make the centroid at 0,0
xoffset=round( (median(x_centroids)+psf_x_sampling[0])/psf_x_step) ; gives offset in pixels!
psf_x_sampling+=(xoffset*psf_x_step) ; apply offset to grid - but the size of a stepsize


; verify there is a zero,zero point
; this is just a bug catching line - can one day be commented out?
; if you hit this, that means that the calculated centroid is outside the stamp
; if this happens, the spaxel should be ignored. 

testy=where(psf_y_sampling eq 0)
testx=where(psf_x_sampling eq 0)
if testy[0] eq -1 or testx[0] eq -1 then begin
print,' (get_psf2) - WARNING! No 0,0 point in psf_y_sampling or psf_x_sampling!'
print, ' either a bad flexure offset or bad wavecal positioning'
print, 'you should never actually arrive here :('
stop
; if this flags, then the entire run is useless.

endif
;create coordinate grids
x_grid_PSF = rebin(PSF_x_sampling,PSF_nx_samples,PSF_ny_samples)
y_grid_PSF = rebin(reform(PSF_y_sampling,1,PSF_ny_samples),PSF_nx_samples,PSF_ny_samples)
;create PSF array
PSF = fltarr(PSF_nx_samples, PSF_ny_samples) ;+ !values.f_nan
; declare array will just keep track of how many samplings are used in the determination of each psf point
how_well_sampled = fltarr(PSF_nx_samples, PSF_ny_samples)

tilt = !values.f_nan
; this finds the psf coordinates in the desired region???
where_coords_NOT_too_big = where(all_x_coords lt (PSF_x_sampling[PSF_nx_samples-1] + PSF_x_step/2.)  $
                             AND all_y_coords lt (PSF_y_sampling[PSF_ny_samples-1] + PSF_y_step/2.)  )
       
if where_coords_NOT_too_big[0] eq -1 then stop, 'line 219'

;if where_coords_NOT_too_big[0] ne -1 then begin
  all_x_coords = all_x_coords[where_coords_NOT_too_big]
  all_y_coords = all_y_coords[where_coords_NOT_too_big]
  all_pix_values = all_pix_values[where_coords_NOT_too_big]
  
  
  ;if keyword_set(PLOT_SAMPLES) then begin
;    select_window, 10,retain=2,xsize=550,ysize=500
;    plot,all_x_coords,all_y_coords ,psym=3,$
;                  TITLE = "PSF sampling (green = psf grid, white = samples)", $
;                  XTITLE = "x axis (in pixel)", $
;                  YTITLE = "y axis (in pixel)", yr=[-1,1],xr=[-1,1]
;    oplot, reform(x_grid_PSF, n_elements(x_grid_PSF)),reform(y_grid_PSF, n_elements(y_grid_PSF)),psym=1,color=cgcolor('green')
  ;  ;stop
  ;endif



; ################################################ 
; NOW DERIVE THE HIGH-RES PSF and center it at 0,0
; ################################################ 

; this is the slowest part by far - 98% of the time to run this function
; this builds the high-res PSF

  ;  ; this is the kernel to do the smoothing
  ;  ; it is a quartic kernel - this was found to be the best for the
  ;  ; WFPC2 data, not necessarily ideal for GPI 
; anderson kernel
;  kernel= [ [ 0.041632, -0.080816, -0.078368, -0.081816,  0.041632], $
;            [-0.080816, -0.019592,  0.200816, -0.019592, -0.080816], $
;            [-0.078368,  0.200816,  0.441632,  0.200816, -0.078368], $
;            [-0.080816, -0.019592,  0.200816, -0.019592, -0.080816], $
;            [ 0.041632, -0.080816, -0.078368, -0.081816,  0.041632]  ]

  
; after looking at different kernels, the moffat kernel was determined
; to be the best (using only 1 psf)

  
;tmp=[1,4,6,4,1] ; gaussian - ; just blurs ver a large region
;tmp=[1,2,1] ; gaussian - ; blurs over a small region
;kernel= (tmp)##reform((transpose(tmp))) 
;kernel/=total(kernel) ; normalize the kernel

n=3
r=distarr(n,n)
; norm is about the FWHM of a psf
;norm=3.0
;r/=norm

signs= [ [-1.0, 1.0, -1.0], $
         [ 1.0, 1.0,  1.0], $
         [-1.0, 1.0, -1.0]]

; kernel depends on the filter!
; The r-array is to be normalized by the FWHM of the 
	case filter of
 	 'Y':kernel=1.0/((abs(r/)+1.0)^9)*signs
 	 'J':specresolution=75;37.
 	 'H':specresolution=45;45.
 	 'K1':specresolution=65;65.
 	 'K2':specresolution=75.
	endcase

'Y':



; these are the shifts of the psf samplings so that the high-res psf
; is properly centered. We start with zero, but this will be changed 
; in the fitting loop below 
xshift=0.0 & yshift=0.0

time0=systime(1)  ; this is just for timing 

; we do the centering/smoothing 10 times - this is rather arbitrary
; 10 gives the best result - this is when the x and y shifts 
; converge to a certain value
loop_iterations=10
for l=0, loop_iterations-1 do begin
                                ; this finds all the samplings for a given psf coordinate
                                ; takes very little time
   val_loc_x_coords = value_locate(PSF_x_sampling, all_x_coords-xshift) 
   val_loc_y_coords = value_locate(PSF_y_sampling, all_y_coords-yshift)
                                ; loop over x samples
   for i = 0,PSF_nx_samples-1 do begin
                                ; the indices_for_current_point variable is determined in the following manner simply for speed reasons.
                                ; this is not the most logical way to do it!
      
                                ; this is the original method - it is VERY slow
                                ;indices_for_current_point = where((val_loc_x_coords ge i and val_loc_x_coords le i+1) and (val_loc_y_coords ge j and val_loc_y_coords le j+1) )
      
      possible_ind= where((val_loc_x_coords eq i or val_loc_x_coords eq i+1))
      if possible_ind[0] eq -1 then begin
         error_flag += 1
         PSF[i,*] = !values.f_nan
         continue
      endif
      tmp_val_loc_y_coords=val_loc_y_coords[possible_ind]
                                ; loop over y-samples
      for j = 0,PSF_ny_samples-1 do begin
         
         tmp=where((tmp_val_loc_y_coords eq j or tmp_val_loc_y_coords eq j+1))
         if tmp[0] eq -1 then begin
            error_flag += 1
            PSF[i,j] = !values.f_nan
            continue
         endif
         indices_for_current_point=temporary(possible_ind[temporary(tmp)])
         
         if indices_for_current_point[0] ne -1 then begin
            matching_values = all_pix_values[indices_for_current_point]
                                ; make sure no nan's are present
            bad=where(finite(matching_values) eq 0, complement=good)
            if good[0] eq -1 then begin
               error_flag += 1
               PSF[i,j] = !values.f_nan
               continue
            endif
                                ; make sure there are at least 13 samplings per psf datapoint 
                                ; I think the 13 is rather random...
                                ; what is actually quite important is that the sampling
                                ; is equally on all sides of the center
                                ; if you have 10 points all on one side then your
                                ; 'average' is very biased.       
            if n_elements(matching_values[good]) ge 13 then begin
                                ; calculate residual.
                                ; note that sometimes funny things happen where with the new shifts new samplings of the psf are possible that previously were not, so new pieces of the psf array appear and disappear. this is why this stupid little median hack is here. It only really affects the edges
               if finite(total(matching_values[good])) eq 0 or finite(psf[i,j]) eq 0 then begin
                  resid= matching_values - median(psf[(i-1)>0:(i+1)<(PSF_nx_samples-1),(j-1)>0:(j+1)<(PSF_ny_samples-1)]) 
               endif else begin
                  resid= matching_values - PSF[i,j]
               endelse
                                ;stop,[i,j]
                                ; find rejected mean for the psf datapoint
               delvarx,subs
               badind=where(finite(resid) eq 0)
               if badind[0] ne -1 then begin
                                ;	print,'badind flag'
                  continue
               endif 
               meanclip, resid, curr_mean, curr_sigma, clipsig=2.5, subs=subs ;,/verbose   
                                ;curr_sigma = robust_sigma(matching_values) ; WAY SLOWER
                                ; median is very slow too!
                                ; adjust the high-res psf accordingly
               PSF[i,j] += curr_mean 
                                ; just a record of how well sampled this point is
               how_well_sampled[i,j] = N_ELEMENTS(temporary(subs)) 
            endif else begin    ; there are not at least 13 samplings for this PSF datapoint
               error_flag += 1
               PSF[i,j] = !values.f_nan
               continue
            endelse
         endif else begin       ; there no samplings for this PSF dta point
            error_flag += 1
            PSF[i,j] = !values.f_nan
            continue		
         endelse
      endfor                    ; end loop over y samples to determine the point on the PSF
   endfor                       ; end loop over x samples to determine the point on the PSF
   
   
                                ; now we smooth by a kernel
;	window,1,xsize=200,ysize=500,retain=200
;	tvdl,psf
	
	psf0=psf
	; so psf holds the pre-smoothed psf
	; psf2 is the smoothed psf
	psf2 = CONVOL( psf, kernel,/nan )
        ; must replace the nans that were in the array with nans
        ; otherwise a weird smoothing happens which is bad
	ind = where(finite(psf) eq 0,complement=gind) ; just original nans
	ind2=where(finite(psf2) eq 0); values surrounding edge of original
	; make it such that the nans are the same
	psf2[ind]=!values.f_nan
	; however, the edges are pretty bad - must come up with a solution
	; for this but for the moment we'll just replace them with the
	; originals
	; because the convolution kernel is so incorrect this is actually rather minimal
	psf2[ind2]=psf[ind2]

	; normalize so that the psf is the same total as the convolved psf
	psf2*=total(psf[gind],/nan)/total(psf2[gind],/nan)

;	window, 2, xsize=200, ysize=500,retain=2
;	tvdl,psf2;,min(psf,/nan),max(psf,/nan)
;stop
	; the smoothing might have shifted the CofM of the epsf, to compensate
	; we shift all the samplings to match the original

	; how we centroid depends on the method
	; for flats, we will want to use the CofM - since it is a goofy shape and the peak is not well defined
	; for the polarimetry mode and the narrowband psfs, we want to use the peak.

	 case centroid_mode of
		"MAX": begin
			useless = max(psf2,max_subscript,/NAN)
			x_centroid = x_grid_PSF[max_subscript]
			y_centroid = y_grid_PSF[max_subscript]
			; need it at 0,0 so shift negative
			xshift+= x_centroid
			yshift+= y_centroid
			; so if we are centered on the 0,0 pixel, we make fine adjustments
			; to center the peak at the center of the center pixel
			; this is eqn 9 of the anderson paper
			; the following prints out the pixels surrounding the peak, the 
			; current peak position, and the current shifts
			;print, psf2[xind-1:xind+1,yind-1:yind+1]
			;print,'peak at',x_grid_psf[xind,yind],y_grid_psf[xind,yind]
			;print,'xshift,yshift' ,xshift,yshift

			if x_centroid eq 0 and y_centroid eq 0 then begin
				; get the indicies of the peak		
				xind=(max_subscript mod PSF_nx_samples)
				yind=(max_subscript / PSF_nx_samples)
			
				;so eqn 9 might have an error in the negative sign in the denominator... 
				; if it doesnt, then you always get 0.5,0.5 - which is wrong
				dx=0.5*(psf2[xind+1,yind]-psf2[xind-1,yind]) / ( (psf2[xind+1,yind]-psf2[xind,yind]) - (psf2[xind,yind]-psf2[xind-1,yind]))
				dy=0.5*(psf2[xind,yind+1]-psf2[xind,yind-1]) / ( (psf2[xind,yind+1]-psf2[xind,yind]) - (psf2[xind,yind]-psf2[xind,yind-1]) )
				
				; in poorly sampled cases, sometimes the pixel adjacent to xind,yind is not finite! 
				; in this case, we simply cannot do a minor adjustment, we must assume that it is properly 
				; centered on the pixel already
				if finite(dx) eq 0 then dx=0
				if finite(dy) eq 0 then dy=0
				
				;print, 'dx,dy' ,dx,dy
				xshift-=(dx*psf_x_step)
				yshift-=(dy*psf_y_step)
				; we want this loop to break if the offsets are really small
				; so we'll designate 'small' as 1/10th of the sampling step size
				if abs((dx*psf_x_step)) lt (PSF_x_step/10.) and abs((dy*psf_y_step)) lt (PSF_y_step/10.) then l=loop_iterations-1
			endif
		end ; end the peak centroid case
		"BARYCENTER": begin
			; the psf should be centered at 0,0 - but we dont have a real psf
			; so we just have to maintain the same centroid as the first pass
			; the centroid is undefined for the first pass  
			if l eq 0 then begin
				x_centroid0 = total(psf*x_grid_PSF,/nan)/total(psf,/nan);
				y_centroid0 = total(psf*y_grid_PSF,/nan)/total(psf,/nan);
			endif
			; this is the centroid of the new psf
			new_x_centroid = total(psf2*x_grid_PSF,/nan)/total(psf2,/nan);
			new_y_centroid = total(psf2*y_grid_PSF,/nan)/total(psf2,/nan);

			; the psf should be centered at 0,0 - but we dont have a real psf
			; so we just have to maintain the same centroid as the first pass
			xshift = (new_x_centroid-x_centroid0)
			yshift = (new_y_centroid-y_centroid0)

		end
		"EDGE": begin ;is there a better way to do that, faster I mean?
				; this was a clever algorithm developed by JB to find a peak, 
				; unfortunately it was just far too slow
				return, error('EDGE NO LONGER SUPPORTED, choose barycenter or MAX')
		end
	 endcase

	; Just make sure nothing goofy happened
	if finite(xshift+yshift) eq 0 then stop, 'shifts are not a number ?!? - get_psf2 line 360'

	; display the smoothed psf
	;loadct,1
	;print,l,xshift,yshift,sqrt((xshift)^2+(yshift)^2)
	;if l eq 0 then window,3,retain=2
;	 tvdl, abs(psf2-psf)/psf,0.001,0.5,box=28
;	wait,1
;	stop
;	if l eq loop_iterations-2 then stop,'about to break psf smoothing loop'

                                ; now put the nans to zeros to prevent propagation
                                ; if there is not enough points
                                ; they'll just get set to nan again
                                ; if there are enough points then
         ; theyll become part of the highres psf
        ind=where(finite(psf2) eq 0)
        if ind[0] ne -1 then psf2[where(finite(psf2) eq 0)]=0
	; now make the new psf the smoothed psf
	psf=temporary(psf2) 

endfor ; iterative loop

;print, time0-systime(1)
;stop, 'finished iterative loop'



obj_PSF = {values: psf, $
           xcoords: PSF_x_sampling, $
           ycoords: PSF_y_sampling, $
           tilt: 0.0,$
           id: lenslet_indices }
                  
return, ptr_new(obj_PSF,/no_copy)

end
