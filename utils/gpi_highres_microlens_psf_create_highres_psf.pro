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
function gpi_highres_microlens_psf_create_highres_psf, psf_ptr_arr, pixel_array, fitted_pixel_array,$
					lenslet_indice_array,$
					 x_centroids, y_centroids, intensities, sky_values, $
                  PSF_nx_pix,PSF_ny_pix, PSF_samples_per_xpix, PSF_samples_per_ypix, $
                  MASK = mask,  tilt=tilt,XCOORDS = xcoords, YCOORDS = ycoords, filter=filter, $
                  ERROR_FLAG = error_flag,flag=flag, $
                  SPLINE_PSF = spline_psf, X_SPLINE_PSF = x_spline_psf, Y_SPLINE_PSF = y_spline_psf, $
                  CENTROID_MODE = centroid_mode, $
                  PLOT_SAMPLES = plot_samples,$
                  HOW_WELL_SAMPLED = how_well_sampled,$
                  LENSLET_INDICES = lenslet_indices, no_error_checking=no_error_checking
                  

error_flag = 0
quadrant_mode=0
;------------------------------------
;  Check the validity of the inputs in both case (vector of coordinates or stamps).
;  In case of stamps, the stamps are reformed in vectors of coordinates. This way, only one type of array is considered in the next section
pixel_array_sz = size(pixel_array)
; create a fitted_pixel_array
;fitted_pixel_array=fltarr(pixel_array_sz[1],pixel_array_sz[2],pixel_array_sz[3])

;calculate the width of the extraction slice
width=max(total(mask,1))
; check to see if this is the first run through
if keyword_set(xcoords) and keyword_set(ycoords) and ~keyword_set(mask) and pixel_array_sz[0] eq 2 then begin
	xcoords_sz = size(xcoords)
	ycoords_sz = size(ycoords)
	x_centroids_sz = size(x_centroids)
	y_centroids_sz = size(y_centroids)
	intensities_sz = size(intensities)
	sky_values_sz = size(sky_values)
  endif

if keyword_set(no_error_checking) eq 0 then begin
			
	if ~keyword_set(centroid_mode) then begin
  		centroid_mode = "MAX"
	endif else if ~(centroid_mode eq "MAX" or centroid_mode eq "BARYCENTER" or centroid_mode eq "EDGE" ) then begin
	;     "MAX", take the max value
	;     "BARYCENTER", take the barycenter
	;     "EDGE", when the centroid is on an edge, both pixels on each side are equal.
	  error_flag = -6
	  return, ptr_new()
	endif


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
endif ; if keyword_set(no_error_checking) 

; ################################################
; create the grids for the highres psf derivations
; ################################################

; want a coordinate system with 0,0 at the centroid
PSF_nx_samples = (PSF_nx_pix+2)*PSF_samples_per_xpix ; 7 pixels box * 5 samples per pixel
PSF_ny_samples = (PSF_ny_pix+2)*PSF_samples_per_ypix ; 22 pixel box * 5 samples per pixel
PSF_x_step = 1.0/float(PSF_samples_per_xpix) ; step size of sampling
PSF_y_step = 1.0/float(PSF_samples_per_ypix)

; so we want a grid where the centroid is centered at 0,0 - but we still need a 0,0 point
; set up the sampling in y
; creates symmetrical grid the length of the box with zero at center
PSF_y_sampling = (findgen(PSF_ny_samples) - floor(PSF_ny_samples/2))* PSF_y_step 
; offset the grid to make the centroid at 0,0
yoffset=( (median(y_centroids)+psf_y_sampling[0])/psf_y_step) ; gives offset in pixels!
; apply offset to grid - but the size of a stepsize
psf_y_sampling-=((round(yoffset)*psf_y_step)+1.0)
;stupid rounding error fix - cannot figure out why this occurs - it is from the rounding
psf_y_sampling=round(temporary(psf_y_sampling)/psf_y_step)*psf_y_step

; set up the sampling in x
; creates symmetrical grid the length of the box with zero at center
PSF_x_sampling = (findgen(PSF_nx_samples) - float(floor(PSF_nx_samples/2)))* PSF_x_step 
; offset the grid to make the centroid at 0,0
xoffset=( (median(x_centroids)+psf_x_sampling[0])/psf_x_step) ; gives offset in pixels!
psf_x_sampling-=(float(round(xoffset))*psf_x_step)+1d0 ; apply offset to grid - but the size of a stepsize
;stupid rounding error fix - cannot figure out why this occurs - it is from the rounding
psf_x_sampling=round(temporary(psf_x_sampling)/psf_x_step)*psf_y_step

; verify there is a zero,zero point
; this is just a bug catching line - can one day be commented out?
; if you hit this, that means that the calculated centroid is outside the stamp
; if this happens, the spaxel should be ignored. 

testy=where(psf_y_sampling eq 0,ct1)
testx=where(psf_x_sampling eq 0,ct2)
if ct1 ne 1 or ct2 ne 1 then begin
print,' (get_psf2) - WARNING! No 0,0 point in psf_y_sampling or psf_x_sampling!'
print, ' either a bad flexure offset or bad wavecal positioning'
print, 'you should never actually arrive here :('
stop
; if this flags, then the entire run is useless.
endif
;create coordinate grids
x_grid_PSF = rebin(PSF_x_sampling,PSF_nx_samples,PSF_ny_samples)
y_grid_PSF = rebin(reform(PSF_y_sampling,1,PSF_ny_samples),PSF_nx_samples,PSF_ny_samples)
; cent index of the center
cent_ind=where(x_grid_psf eq 0 and y_grid_psf eq 0)
sz=size(x_grid_psf)
cent_indx=cent_ind mod sz[1]
cent_indy=cent_ind / sz[1]


loop_iterations=2
;how many samples needed per data point?
;samples_needed=N_ELEMENTS(pixel_array[0,0,*])/(PSF_nx_samples*PSF_ny_samples)*1/3.0

;create PSF array
; want to load in the beginning PSF if present
if ptr_valid(psf_ptr_arr[lenslet_indices[0],lenslet_indices[1],lenslet_indices[2]]) then begin
		psf=(*psf_ptr_arr[lenslet_indices[0],lenslet_indices[1],lenslet_indices[2]]).values
		psf/=total(psf,/nan)
		endif else PSF = fltarr(PSF_nx_samples, PSF_ny_samples) ;+ !values.f_nan

; only for debugging
psf_before_loop=psf

;need to declare the next common before calling gpi_highres_microlens_psf_fit_detector_psf()
common hr_psf_common

nx_pix = pixel_array_sz[1]
ny_pix = pixel_array_sz[2]
n_PSF_samples = pixel_array_sz[3]
	
mask_sz = size(mask)
x_centroids_sz = size(x_centroids)
y_centroids_sz = size(y_centroids)
intensities_sz = size(intensities)
sky_values_sz = size(sky_values)

image_x_sampling = findgen(nx_pix)
image_y_sampling = findgen(ny_pix)

;create PSF grid
x_grid=rebin(image_x_sampling,nx_pix,ny_pix)
y_grid=rebin(reform(image_y_sampling,1,ny_pix),nx_pix,ny_pix)

xshift=0 & yshift=0
orig_pixel_array=pixel_array
orig_fitted_pixel_array=fitted_pixel_array

normalized_pixel_array=fltarr(nx_pix,ny_pix,N_ELEMENTS(intensities))
normalized_fitted_pixel_array=fltarr(nx_pix,ny_pix,N_ELEMENTS(intensities))

for q=0, pixel_array_sz[3]-1 do normalized_pixel_array[*,*,q]=pixel_array[*,*,q]/intensities[q]
for q=0, pixel_array_sz[3]-1 do normalized_fitted_pixel_array[*,*,q]=fitted_pixel_array[*,*,q]/intensities[q]


pixel_array=normalized_pixel_array
fitted_pixel_array=normalized_fitted_pixel_array
for l=0, loop_iterations-1 do begin

   ; need to create residuals for EVERY psf - OR DO I?
if 1 eq 1 then begin
	for p=0, pixel_array_sz[3]-1 do begin
			; must normalize by their intensities
		
		; check to see if 
		if ptr_valid(psf_ptr_arr[lenslet_indices[0],lenslet_indices[1],lenslet_indices[2]]) eq 1 then begin

			valid=ptr_valid(psf_ptr_arr) ; which psfs are valid?
			ptr_current_PSF = gpi_highres_microlens_psf_get_local_highres_psf(psf_ptr_arr,[lenslet_indice_array[0,p],lenslet_indice_array[1,p],lenslet_indice_array[2,p]],/preserve_structure, valid=valid)

			; put min values in common block for fitting
			c_x_vector_psf_min = min((*ptr_current_psf).xcoords)
			c_y_vector_psf_min = min((*ptr_current_psf).ycoords)
			; determine the sampling and put in common block
			c_sampling=round(1/( ((*ptr_current_psf).xcoords)[1]-((*ptr_current_psf).xcoords)[0] ))
			; load the high-res psf into the common block			
			c_psf = (*ptr_current_psf).values ; integral of this is 1

			properties=[x_centroids[p], y_centroids[p],1.0]


			tmp_det_psf0=gpi_highres_microlens_psf_evaluate_detector_psf(x_grid, y_grid, properties)
			normalized_fitted_pixel_array[*,*,p]=tmp_det_psf0
			;flag=0
			if 0 eq 1 then begin
					window,7
				tvdl, (pixel_array*mask)[*,*,p],min((pixel_array*mask)[*,*,p]),max((pixel_array*mask)[*,*,p]),/log,position=0		
				tvdl, tmp_det_psf0,min((pixel_array*mask)[*,*,p]),max((pixel_array*mask)[*,*,p]),/log,position=1			
					stop
			endif
		endif else begin
			; so in this case in which no highres psf exists yet - so the fitted_pixel_array[*,*,p]=0 - but they're already zeros
		endelse ; 
			
	endfor ; loop to create residuals 
 endif

	all_pix_values = normalized_pixel_array    
	all_fitted_pix_values = normalized_fitted_pixel_array
		
	; the following rebins the arrays to have a 1d array per image
	; this is faster to work with.
	; there were originally three different ways to do this, but this was 
	; determined to be the quickest. 

	all_pix_values = reform(pixel_array,nx_pix*ny_pix,n_PSF_samples)	
	all_fitted_pix_values = reform(fitted_pixel_array,nx_pix*ny_pix,n_PSF_samples)	
	xcoords = rebin(reform(rebin(image_x_sampling,nx_pix,ny_pix),nx_pix*ny_pix),nx_pix*ny_pix,n_PSF_samples)
	ycoords = rebin(reform(rebin(reform(image_y_sampling,1,ny_pix),nx_pix,ny_pix),nx_pix*ny_pix),nx_pix*ny_pix,n_PSF_samples)
	; it also sets all the pixels (indices) that are just masked or have bad pixels to !NaN
	not_relevant = where((reform(mask,nx_pix*ny_pix,n_PSF_samples)) eq 0,ct)
	if ct ne 0 then begin
	  all_pix_values[not_relevant] = !values.f_nan
	  all_fitted_pix_values[not_relevant] = !values.f_nan
	  xcoords[not_relevant] = !values.f_nan
	  ycoords[not_relevant] = !values.f_nan
	endif
;------------------------------------
;   Build the PSF with all the data
;------------------------------------
; note that each ePSF is normalized by it's INTEGRATED intensity
; so the total is equal to 1 (in the highres case)
; the psfs PIXELS are being divided by thier measured INTEGRATED intensity

all_x_coords = float(xcoords)
all_y_coords = float(ycoords)
for i=0L,long(n_PSF_samples-1) do begin
  all_x_coords[*,i] = xcoords[*,i]-x_centroids[i]-xshift[0]
  all_y_coords[*,i] = ycoords[*,i]-y_centroids[i]-yshift[0]
;  all_pix_values[*,i] = (all_pix_values[*,i] - sky_values[i])/intensities[i]
;  all_fitted_pix_values[*,i]= (all_fitted_pix_values[*,i])/intensities[i] ; sky already subtracted
endfor

all_x_coords = reform(all_x_coords, n_elements(all_x_coords))
all_y_coords = reform(all_y_coords, n_elements(all_y_coords))
all_pix_values = reform(all_pix_values, n_elements(all_pix_values)) 
all_fitted_pix_values = reform(all_fitted_pix_values, n_elements(all_fitted_pix_values)) 


; declare array will just keep track of how many samplings are used in the determination of each psf point
how_well_sampled = fltarr(PSF_nx_samples, PSF_ny_samples)

; this finds the psf coordinates in the desired region???
where_coords_NOT_too_big = where(all_x_coords lt (PSF_x_sampling[PSF_nx_samples-1] + PSF_x_step/2.)  $
                             AND all_y_coords lt (PSF_y_sampling[PSF_ny_samples-1] + PSF_y_step/2.)  ,ct)
       
if ct eq 0 then stop, 'line 219'

;if where_coords_NOT_too_big[0] ne -1 then begin
  all_x_coords = all_x_coords[where_coords_NOT_too_big]
  all_y_coords = all_y_coords[where_coords_NOT_too_big]
  all_pix_values = all_pix_values[where_coords_NOT_too_big]
  all_fitted_pix_values = all_fitted_pix_values[where_coords_NOT_too_big]
 
  
  if keyword_set(PLOT_SAMPLES) or keyword_set(flag) then begin
	  select_window, 10,retain=2,xsize=650,ysize=600;
	    plot,all_x_coords,all_y_coords ,psym=3,$
         TITLE = "PSF sampling (green = psf grid, white = samples)", $
        XTITLE = "x axis (in pixel)", $
         YTITLE = "y axis (in pixel)", $
       yr=[-1,1],/ys, $
         xr=[-1,1],/xs
;
;         yr=[min(y_grid_psf)-2,max(y_grid_psf)+2],/ys, $
;         xr=[min(x_grid_psf)-2,max(x_grid_psf)+2],/xs
   oplot, reform(x_grid_PSF, n_elements(x_grid_PSF)),$
	reform(y_grid_PSF, n_elements(y_grid_PSF)),psym=1,color=cgcolor('green')

;	pi_spie_plot_pixel_sampling, pixel_array, all_x_coords, all_y_coords , x_grid_PSF, y_grid_PSF,mask=mask

;stop
endif



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

;n=3
; norm is about the FWHM of a psf
;norm=3.0
;r/=norm
;r=distarr(n,n)
;signs= [ [-1.0, 1.0, -1.0], $
;         [ 1.0, 1.0,  1.0], $
;         [-1.0, 1.0, -1.0]]

n=5
r=distarr(n,n)
signs= [ [  1.0, -1.0, -1.0, -1.0,  1.0], $
         [ -1.0, -1.0,  1.0, -1.0, -1.0], $
	 [  -1.0,  1.0,  1.0,  1.0,  -1.0], $
        [ -1.0, -1.0,  1.0, -1.0, -1.0], $
	 [  1.0, -1.0, -1.0, -1.0,  1.0]]

; how about using a square box kernel - rotated by ~24.5 degrees
if 1 eq 1 then begin
;kernel0=1.0/((abs(r/12.0)+1.0)^15)*signs 
angle=-24.5+tilt/!dtor
r=sqrt(1./9)
x=(x_grid_psf*cos(angle*!dtor)-y_grid_psf*sin(angle*!dtor))
y=(x_grid_psf*sin(angle*!dtor)+y_grid_psf*cos(angle*!dtor))

Int = (sinc(x/r))^2 * (sinc(y/r))^2
kernel=(Int[cent_indx-2:cent_indx+2,cent_indy-2:cent_indy+2]*rot(signs,-angle,cubic=-0.5))

kernel=(Int[cent_indx-2:cent_indx+2,cent_indy-2:cent_indy+2]*rot(signs,-angle,cubic=-0.5))[n/2-1:n/2+1,n/2-1:n/2+1]

;kernel=Int[cent_indx-1:cent_indx+1,cent_indy-1:cent_indy+1]*signs

;tvdl,I,/log,position=0
;print, kernel

;tvdl,data,/log,position=1
;kernel=kernel
endif


; kernel depends on the filter!
; The r-array is to be normalized by the ~FWHM of the psf
	case filter of
 	 'Y':kernel=1.0/((abs(r/13.0)+1.0)^15)*signs ; updated 140415 - PI
 	 'J':kernel=1.0/((abs(r/13.0)+1.0)^15)*signs  ; MUST UPDATE
	 ;'H':kernel=1.0/((abs(r/15.0)+1.0)^15)*signs ; MUST UPDATE - better - creates a doughnut
	 'H':kernel=kernel
 	 ; 'H':kernel=1.0/((abs(r/12.0)+1.0)^15)*abs(signs) ; MUST UPDATE - about a 1% error - still creates doughnut
	 ;'H': kernel=I[cent_indx-2:cent_indx+2,cent_indy-2:cent_indy+2]*abs(signs)
	 ;'H': kernel=I[cent_indx-1:cent_indx+1,cent_indy-1:cent_indy+1]*(signs)
 	 ;'H':kernel=1.0/((abs(r/10.0)+1.0)^6.5)*signs ; fit from psf - not good - not sharp enough
	 ; 	 'K1':kernel=1.0/((abs(r/10.0)+1.0)^6)*signs  ; updated 140501 - not amazing - asymmetric?
	 'K1':kernel=1.0/((abs(r/10.0)+1.0)^15)*signs  ; no idea why this works better... 
 	 'K2':kernel=1.0/((abs(r/10.0)+1.0)^6)*signs  ; same as K1
	endcase


; these are the shifts of the psf samplings so that the high-res psf
; is properly centered. We start with zero, but this will be changed 
; in the fitting loop below 
;xshift=0.0 & yshift=0.0
time0=systime(1)  ; this is just for timing 
; we do the centering/smoothing 10 times - this is rather arbitrary
; 10 gives the best result - this is when the x and y shifts 
; converge to a certain value
;loop_iterations=3
;how many samples needed per data point?
;samples_needed=N_ELEMENTS(pixel_array[0,0,*])/(PSF_nx_samples*PSF_ny_samples)*1/3.0
;for l=0, loop_iterations-1 do begin
    
	; this finds all the samplings for a given psf coordinate
    ; takes very little time
	; shifts are only singular values but if they get turned into 1 d arrays
	; then the value_locate function no longer works :-( not sure why
   val_loc_x_coords = value_locate(PSF_x_sampling, all_x_coords);-xshift[0]) 
   val_loc_y_coords = value_locate(PSF_y_sampling, all_y_coords);-yshift[0])

dPSF=fltarr(psf_nx_samples,psf_ny_samples)
dPSF_sig=fltarr(psf_nx_samples,psf_ny_samples)



                                ; loop over x samples
   for i = 0,PSF_nx_samples-1 do begin
    ; the indices_for_current_point variable is determined in the following 
	; manner simply for speed reasons. this isnt the most logical way to do it!
      
    ; this is the original method - it is VERY slow
    ; indices_for_current_point = where((val_loc_x_coords ge i and $
	;	val_loc_x_coords le i+1) and (val_loc_y_coords ge j and $
	;	val_loc_y_coords le j+1) )
    	possible_Lind= where((val_loc_x_coords eq i),ctL)
		possible_Rind= where((val_loc_x_coords eq i+1),ctR)
      
		if ctL*ctR eq 0 then begin
        	error_flag += 1
        	PSF[i,*] = !values.f_nan
			dPSF[i,*] = !values.f_nan
        	continue
		endif
		tmp_val_loc_y_coordsL=val_loc_y_coords[possible_Lind]
		tmp_val_loc_y_coordsR=val_loc_y_coords[possible_Rind]

  
		; loop over y-samples
    	for j = 0,PSF_ny_samples-1 do begin
  
 ; check to see that the sample isn't too far away from the centroid
		 ; no value should exist that is more than half the width of the cutout 
		 ; plus 1 pixel from the center - if so, that a centroid is way off!
		; if i eq 20 and j eq 70 then stop
			tilt_offset=atan(tilt)*y_grid_psf[i,j];*psf_x_step ; offset from 0,0
			if abs(tilt_offset+x_grid_psf[i,j]) ge (width/2.0 +0.25) $
				then begin
				;stop
				error_flag += 1
            	PSF[i,j] = !values.f_nan
				dPSF[i,j] = !values.f_nan
				continue
			endif

        ; tmp=where((tmp_val_loc_y_coords eq j or tmp_val_loc_y_coords eq j+1),ct)
			; indices for downleft downright
			tmpDL=where((tmp_val_loc_y_coordsL eq j),ctDL)
			tmpDR=where((tmp_val_loc_y_coordsR eq j),ctDR)
			; indicies for upleft upright
			tmpUL=where((tmp_val_loc_y_coordsL eq j+1),ctUL)
			tmpUR=where((tmp_val_loc_y_coordsR eq j+1),ctUR)

;         	if ctUL*ctDL*ctUR*ctDR eq 0 then begin
	if ((ctDL<1)+(ctDR<1)+(ctUL<1)+(ctUR<1)) eq 0 then begin
;			stop,'stopped'
;	if ((ctDL<1)+(ctDR<1)+(ctUL<1)+(ctUR<1)) lt (4quadrant_mode)>1 then stop,'stopped2'


            	error_flag += 1
            	PSF[i,j] = !values.f_nan
				dPSF[i,j] = !values.f_nan
            	continue
         	endif
        	;indices_for_current_point=temporary(possible_ind[temporary(tmp)])
        	indices_for_DL_points=temporary(possible_Lind[temporary(tmpDL)])
	 		indices_for_DR_points=temporary(possible_Rind[temporary(tmpDR)])
        	indices_for_UL_points=temporary(possible_Lind[temporary(tmpUL)])
	 		indices_for_UR_points=temporary(possible_Rind[temporary(tmpUR)])
        	if indices_for_DL_points[0] ne -1 and $
				indices_for_DR_points[0] ne -1 and $
				indices_for_UL_points[0] ne -1 and $
				indices_for_UR_points[0] ne -1 then begin
					matching_DL_values = all_pix_values[indices_for_DL_points]-all_fitted_pix_values[indices_for_DL_points]
					matching_DR_values = all_pix_values[indices_for_DR_points]-all_fitted_pix_values[indices_for_DR_points]
					matching_UL_values = all_pix_values[indices_for_UL_points]-all_fitted_pix_values[indices_for_UL_points]
					matching_UR_values = all_pix_values[indices_for_UR_points]-all_fitted_pix_values[indices_for_UR_points]
            
					; make sure no nan's are present
					good_DL=where(finite(matching_DL_values) eq 1, ct_DL, complement=bad)
					good_DR=where(finite(matching_DR_values) eq 1, ct_DR, complement=bad)
					good_UL=where(finite(matching_UL_values) eq 1, ct_UL, complement=bad)
					good_UR=where(finite(matching_UR_values) eq 1, ct_UR, complement=bad)
					; make sure each quadrant has at least 2 points
					; this is necessary to do quadrant mode but NOT the full mode
					if ((ct_DL<1)+(ct_DR<1)+(ct_UL<1)+(ct_UR<1)) lt (4*quadrant_mode)>1 then begin
               			error_flag += 1
               			PSF[i,j] = !values.f_nan
						dPSF[i,j] = !values.f_nan
						continue
		           	endif

              ; what is actually quite important is that the sampling
              ; is equally on all sides of the center
              ; if you have 10 points all on one side then your
              ; 'average' is very biased.       
              ; calculate residual.
              ; note that sometimes funny things happen where with the new shifts new samplings
	      ; of the psf are possible that previously were not, so new pieces of the psf array 
              ; appear and disappear. this is why this stupid little median hack is here. 
		; It only really affects the edges
					if finite(psf[i,j]) eq 0 then begin
            	    	;resid= matching_values - median(psf[(i-1)>0:(i+1)<(PSF_nx_samples-1),(j-1)>0:(j+1)<(PSF_ny_samples-1)]) 
						resid_DL=matching_DL_values[good_DL]
						resid_DR=matching_DR_values[good_DR]
						resid_UL=matching_UL_values[good_UL]
						resid_UR=matching_UR_values[good_UR]
					endif else begin
						resid_DL=matching_DL_values[good_DL];- PSF[i,j]
						resid_DR=matching_DR_values[good_DR];- PSF[i,j]
						resid_UL=matching_UL_values[good_UL];- PSF[i,j]
						resid_UR=matching_UR_values[good_UR];- PSF[i,j]
                	;resid= matching_values[good] - PSF[i,j]
					endelse
            	    ; find rejected mean for the psf datapoint
            	   ;delvarx,subs
					subsDL=[] & subsDR=[] & subsUL=[] & subsUR=[] & subs=[]
					badind=where(finite([resid_DL,resid_DR,resid_UL,resid_UR]) eq 0,ct)
					if ct ne 0 then begin
                		stop,'badind flag - this should never happen'
                 		continue
               		endif 
if quadrant_mode eq 1 then begin
		; want the mean of each quadrant
		meanclip, resid_DL, curr_mean_DL, curr_sigma, clipsig=2.0, subs=subsDL, maxiter=3,converge=0 ;,/verbose   
		meanclip, resid_DR, curr_mean_DR, curr_sigma, clipsig=2.0, subs=subsDR, maxiter=3,converge=0 ;,/verbose  
		meanclip, resid_UL, curr_mean_UL, curr_sigma, clipsig=2.0, subs=subsUL, maxiter=3,converge=0 ;,/verbose  
		meanclip, resid_UR, curr_mean_UR, curr_sigma, clipsig=2.0, subs=subsUR, maxiter=3,converge=0 ;,/verbose  
		PSF[i,j] += mean([curr_mean_DL,curr_mean_DR,curr_mean_UL,curr_mean_UR])
	endif else begin
					meanclip, [resid_DL,resid_DR,resid_UL,resid_UR], $
					curr_mean, curr_sigma,clipsig=2.0, subs=subs, maxiter=3,converge=0 	
					dPSF[i,j] = curr_mean
					dPSF_sig[i,j] = curr_sigma


				;	PSF[i,j] += curr_mean
    endelse
				 ;curr_sigma = robust_sigma(matching_values) ; WAY SLOWER
                                ; median is very slow too!
                                ; adjust the high-res psf accordingly
			;	if curr_mean lt curr_sigma and keyword_set(flag) then stop   
	                                ; just a record of how well sampled this point is
               how_well_sampled[i,j] = N_ELEMENTS(temporary(subsDL)) + N_ELEMENTS(temporary(subsDR)) $
					+ N_ELEMENTS(temporary(subsUL)) + N_ELEMENTS(temporary(subsUR)) 
 
         endif else begin       ; there no samplings for this PSF dta point for at least 1 quadrant
            error_flag += 1
            PSF[i,j] = !values.f_nan
			dPSF[i,j] = !values.f_nan
            continue		
         endelse
      endfor                    ; end loop over y samples to determine the point on the PSF
   endfor                       ; end loop over x samples to determine the point on the PSF
   
   psf_before=psf
   psf=psf_before_loop+dpsf   ; does this work in the first iteration? YES!
;    psf=psf_before+dpsf

  ; is the entire psf junk?

 
                                ; now we smooth by a kernel
;	window,1,xsize=200,ysize=500,retain=200
;	tvdl,psf
	
	psf0=psf
	; so psf holds the pre-smoothed psf
	; psf2 is the smoothed psfi
;	psf2 = CONVOL( psf, kernel,/nan )
psf2=psf
        ; must replace the nans that were in the array with nans
        ; otherwise a weird smoothing happens which is bad
	ind = where(finite(psf) eq 0) ; just original nans
	; make it such that the nans are the same
	psf2[ind]=!values.f_nan

	; also the edges that do not have all of the indices in the convolution
	; should not be touched.
	; we would actually like to invoke a smoothing kernel, i'm just not sure how...
	; for the moment we'll just replace them with the originals
	; find the nans
	mask1=finite(psf0)
	mask2= CONVOL( float(mask1), kernel,/nan )
	corrupt_ind=where(mask2 ne total(kernel) and mask2 ne 0,complement=gind)
	
	bad_ind=where(mask2 ne total(kernel)) ; flagged for use with edge interpolation

	; normalize so that the psf is the same total as the convolved psf
	psf2*=total(psf[gind],/nan)/total(psf2[gind],/nan)
	
	; the smoothing might have shifted the CofM of the epsf, to compensate
	; we shift all the samplings to match the original

	; how we centroid depends on the method
	; for flats, we will want to use the CofM - since it is a goofy shape and the peak is not well defined
	; for the polarimetry mode and the narrowband psfs, we want to use the peak.

	 case centroid_mode of
		"MAX": begin
	; must find the peak which we know is near 0,0
; can't just use max because sometimes an edge can go crazy due
; to a lenslet having a bad centroid 
	
			; this attempts to find the max of the entire
			; image after removing bad pixels
			;tmp=psf2
			;tmp[corrupt_ind]=!values.f_nan
            ;useless = max(tmp,max_subscript,/NAN)
			;x_centroid = x_grid_PSF[max_subscript]
			;y_centroid = y_grid_PSF[max_subscript]
			;stop, x_centroid, y_centroid
			; this uses a small image section
			; peak shouldn't miss by more than 1.0 pixels
			stamp=psf2[cent_indx-1.0*psf_samples_per_xpix:cent_indx+1.0*psf_samples_per_xpix,$
				cent_indy-1.0*psf_samples_per_ypix:cent_indy+1.0*psf_samples_per_ypix]
			dpsf_stamp=dpsf[cent_indx-1.0*psf_samples_per_xpix:cent_indx+1.0*psf_samples_per_xpix,$
				cent_indy-1.0*psf_samples_per_ypix:cent_indy+1.0*psf_samples_per_ypix]

			tmp=max(psf2[cent_indx-1.0*psf_samples_per_xpix:cent_indx+1.0*psf_samples_per_xpix,$
				cent_indy-1.0*psf_samples_per_ypix:cent_indy+1.0*psf_samples_per_ypix],max_subscript,/nan)
			x_centroid = (x_grid_PSF[cent_indx-1.0*psf_samples_per_xpix:cent_indx+1.0*psf_samples_per_xpix,$
				cent_indy-1.0*psf_samples_per_ypix:cent_indy+1.0*psf_samples_per_ypix])[max_subscript]
			y_centroid = (y_grid_PSF[cent_indx-1.0*psf_samples_per_xpix:cent_indx+1.0*psf_samples_per_xpix,$
				cent_indy-1.0*psf_samples_per_ypix:cent_indy+1.0*psf_samples_per_ypix])[max_subscript]



			;stop, x_centroid, y_centroid
			; need it at 0,0 so shift negative
			if abs(xshift) gt 2 or abs(yshift) gt 2 then stop, 'shifting error-interger pix'
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
				;xind=(max_subscript mod PSF_nx_samples)
				;yind=(max_subscript / PSF_nx_samples)
				; it should always be at 0,0 here
				xind=cent_indx[0]
				yind=cent_indy[0]
			
				;so eqn 9 might have an error in the negative sign in the denominator... 
				; if it doesnt, then you always get 0.5,0.5 - which is wrong
				dx=0.5*(psf2[xind+1,yind]-psf2[xind-1,yind]) / ( (psf2[xind+1,yind]-psf2[xind,yind]) - (psf2[xind,yind]-psf2[xind-1,yind]))
				dy=0.5*(psf2[xind,yind+1]-psf2[xind,yind-1]) / ( (psf2[xind,yind+1]-psf2[xind,yind]) - (psf2[xind,yind]-psf2[xind,yind-1]) ) 

			; stamp is rotated -24.5ish degrees relative to the x-axis - we want to derotate it
			; so this means rotating it 24.5 degrees counter-clockwise?
				stamp2=10^(rot(alog10(stamp),-angle,cubic=-0.5)	) ; want to go clockwise - angle is negative -24.5, so must be positive here
				ssz=size(stamp2)
				xind=ssz[1]/2 & yind=ssz[2]/2
				dx=0.5*(stamp2[xind+1,yind]-stamp2[xind-1,yind]) / ( (stamp2[xind+1,yind]-stamp2[xind,yind]) - (stamp2[xind,yind]-stamp2[xind-1,yind]))
				dy=0.5*(stamp2[xind,yind+1]-stamp2[xind,yind-1]) / ( (stamp2[xind,yind+1]-stamp2[xind,yind]) - (stamp2[xind,yind]-stamp2[xind,yind-1]) )
				
				dx*=cos(angle*!dtor)
				dy*=sin(abs(angle)*!dtor) ; draw this angle...

				; in poorly sampled cases, sometimes the pixel adjacent to xind,yind is not finite! 
				; in this case, we simply cannot do a minor adjustment, we must assume that it is properly 
				; centered on the pixel already
				if finite(dx) eq 0 then dx=0
				if finite(dy) eq 0 then dy=0

				print, 'dx,dy to shifts' ,dx*psf_x_step,dy*psf_y_step
				xshift-=(dx*psf_x_step)
				yshift-=(dy*psf_y_step)
				
				;flag=0  ; this is a manual flag for debugging
				if xshift gt 2 or yshift gt 2 then stop, 'shifting error-subpix'
				; we want this loop to break if the offsets are really small
				; so we'll designate 'small' as 1/10th of the sampling step size
				if abs((dx)) lt (PSF_x_step/10.) and $
					abs((dy)) lt (PSF_y_step/10.) and $
					keyword_set(flag) eq 0 then l=loop_iterations-1
			endif ; end small shift adjustment
			; ### end of max
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

	; if on the last iteration - replace the corrupt indices
	if l eq loop_iterations-1 then begin
		c_xind= corrupt_ind mod sz[1]
		c_yind= corrupt_ind / sz[1]
		psf20=psf2
		psf20[corrupt_ind]=!values.f_nan
		radius0=sqrt(x_grid_psf^2+y_grid_psf^2)
		for b=0,N_ELEMENTS(c_xind)-1 do begin
			; find the nearest 5x5 gridpoints
			radius=sqrt((x_grid_psf-x_grid_psf[c_xind[b],c_yind[b]])^2+$
			(y_grid_psf-y_grid_psf[c_xind[b],c_yind[b]])^2)
			radius[bad_ind]=1e5 ; set to big number
			tmp=sort(radius)
			; do radial fit from the center of the psf
			;dist=radius0[tmp[0:25]]
			;vals=psf20[tmp[0:25]]
			;result=ladfit(dist,alog10(vals)); returns y-int, slope
		    ;psf2[c_xind[b],c_yind[b]]=10^(result[1]*radius0[c_xind[b],c_yind[b]]+result[0])
			;print,10^(result[1]*radius0[c_xind[b],c_yind[b]]+result[0])

			; do a planefit
			coef=planefit(x_grid_psf[tmp[0:25]],y_grid_psf[tmp[0:25]],$
						alog10(psf2[tmp[0:25]]),0);,yfit)
			
			psf2[c_xind[b],c_yind[b]]=10^(coef[0]+coef[1]* $					
					x_grid_psf[c_xind[b],c_yind[b]]+$
					coef[2]*y_grid_psf[c_xind[b],c_yind[b]])

			;print, psf2[c_xind[b],c_yind[b]]

			endfor

	endif

	if 0 eq 1 or keyword_set(flag) eq 1 then begin

	data=psf0
	fit=psf2

	my_residuals =  (data - fit) / (data)  

	szt=size(data)*4
	window,2,xsize=szt[1]*3,ysize=szt[2],retain=2
	ind=where(fit ne 0 and finite(fit) eq 1)
	dmax=max(data[ind],/nan)
	dmin=min(data[ind],/nan)
	loadct,1
	tvdl, data,dmin,dmax,position=0,/log,/silent
	tvdl,fit,dmin,dmax,position=1,/log,/silent
	loadct,0
	tvdl,my_residuals,-0.05,0.05,position=2,/silent
	stop,'stopped for psf analysis for loop iteration '+strc(l),' xshift='+strc(xshift),' yshift='+strc(yshift)
	endif

;	if l eq loop_iterations-2 then stop,'about to break psf smoothing loop'

                                ; now put the nans to zeros to prevent propagation
                                ; if there is not enough points
                                ; they'll just get set to nan again
                                ; if there are enough points then
         ; theyll become part of the highres psf
        ind=where(finite(psf2) eq 0,ct)
        if ct ne 0 then psf2[ind]=0
	; now make the new psf the smoothed psf
	psf=temporary(psf2) 

; psfs should be normalized to 1 by definition
; this should probably be done around the psf alone... but i'll leave that for another day
psf/=total(psf,/nan)

; psf is still offcenter here... 
;psf_ptr_arr[lenslet_indices[0],lenslet_indices[1],lenslet_indices[2]]=ptr_new({values: psf, $
;           xcoords: PSF_x_sampling, $
;           ycoords: PSF_y_sampling, $
;           tilt: tilt,$
;           id: lenslet_indices })


endfor ; iterative loop




;print, time0-systime(1)
;stop, 'finished iterative loop'
;window,5
;loadct,0
;tvdl, psf,/log
;stop


obj_PSF = {values: psf, $
           xcoords: PSF_x_sampling, $
           ycoords: PSF_y_sampling, $
           tilt: tilt,$
           id: lenslet_indices }
                  
return, ptr_new(obj_PSF,/no_copy)

end
