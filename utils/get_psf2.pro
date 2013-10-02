;+
; NAME: get_PSF2
; 
; DESCRIPTION: Compute a high resolution PSF from a set of low sampled PSFs.
; 
; The output PSF will be given on the grid which size is defined by PSF_nx_pix, PSF_ny_pix, PSF_samples_per_xpix and PSF_samples_per_ypix.
; The x and y coordinates can be obtained in the output structure (.xcoords and.ycoords).
; The x = 0.0 and y = 0.0  is the centroid of the PSF defined so that when the centroid is on an edge between to pixels, the value of the two pixel be equal.
;
; INPUTS:
; The PSF can be computed using PSF samples in 2D (using the keyword MASK) or in 1D (using the keyword XCOORDS and YCOORDS). In the 2D case the input PSF samples are many small images, most likely stamps extracted from an image around each of the PSF spots. In the 1D case, it means you already have the coordinates of the points.
; 
; IF MASK is defined, then
;     XCOORDS and YCOORDS must not be defined
;   - MASK, mask should be a cube of same dimension as pixel_array. mask indicates if the corresponding pixel in pixel_array should be considered (=1) are ignored (=0).
;   - pixel_array, pixel_array should be a cube of data of dimension nx x ny x nz. nx x ny being the dimension of the image including the sampled PSF. nz being the number of samples of the same PSF.
;   - x_centroids, give the centroids of the PSFs. It should be a vector of nz elements. The origin is taken at the center of the pixel of coordinates [0,0].
;   - y_centroids, same as x_centroids but for the y-coordinates
;   - intensities, give the intensities of the PSFs (meaning their weights or the total flux). It should be a vector of nz elements.
;   - sky_values, give the sky values for each slice, ie what to subtract. It should be a vector of nz elements.
; 
; THEN IF XCOORDS AND YCOORDS are defined
;     MASK must not be defined
;   - XCOORDS, xcoords should be an array of dimension nx x ny containing the x-coordinates of the pixels of the PSF samples. nx being the number values for each PSF sample. ny being the number of samples of the same PSF. f_nan values are considered as missing data and can be used to fill the array if there is not enough points for one PSF.
;   - YCOORDS, same as xcoords but for the y-coordinates
;   - pixel_array, 
;   - x_centroids, give the centroids of the PSFs. It should be a vector of ny elements. The coordinates should be consistent with xcoords and ycoords.
;   - y_centroids, same as x_centroids but for the y-coordinates 
;   - intensities, give the intensities of the PSFs (meaning their weights or the total flux). It should be a vector of ny elements.
;   - sky_values, give the sky values for each slice, ie what to subtract. It should be a vector of ny elements.
; 
; In Both cases:
; - PSF_nx_pix, The width of the returned PSF in number of pixel along the x_axis. Should be greater than 3.
; - PSF_ny_pix, The width of the returned PSF in number of pixel along the y_axis. Should be greater than 3.
; - PSF_samples_per_xpix, The number of intervals in which a pixel should be cut along the x_axis.
; - PSF_samples_per_ypix, The number of intervals in which a pixel should be cut along the y_axis.
;
;
; KEYWORDS: 
; - CENTROID_MODE, indicate the method to use to compute the centroid of the PSF.
;     "MAX", take the max value
;     "BARYCENTER", take the barycenter
;     "EDGE", when the centroid is on an edge, both pixels on each side are equal. 
;        If the spline interpolation cannot be performed (for MAX and EDGE), a simple barycenter is used to get the centroid. (see error_flag = -8)
; - PLOT_SAMPLES, plot (in window 0) the point samples in the high resolution PSF grid. It triggers a stop in the function.
; - HOW_WELL_SAMPLED, return an array of same size as the PSF with the number of samples used for inferring each point.
; 
;
; OUTPUTS:  
; - Returned value: A pointer to the structure of the computed PSF (null pointer if an error occured, see error_flag):
;   obj_PSF = {values: psf, $                 contains the values of the psf to the points defined by xcoords and ycoords. It is an array of dimension PSF_nx_samples x PSF_ny_samples, with:
;                                                 PSF_nx_samples = PSF_nx_pix*PSF_samples_per_xpix + 1
;                                                 PSF_ny_samples = PSF_ny_pix*PSF_samples_per_ypix + 1
;             xcoords: PSF_x_sampling, $      is a vector with the values along the x-axis where the returned PSF is sampled.
;             ycoords: PSF_y_sampling, $      is a vector with the values along the y-axis where the returned PSF is sampled.
;             tilt: 0.0,$
;             id: lenslet_indices }                   a 4 elements vector containing indices to locate the psf. in the context of the gpi pipeline. id[0] and id[1] are the indices for the lenslet array. id[2] the spot number in case of polarimetry data for example. 
;                                             id is used by the function read_psfs() to rebuild a readable array of psf.
;                                             
; - ERROR_FLAG = error_flag
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
;- 
function get_PSF2, pixel_array, x_centroids, y_centroids, intensities, sky_values, $
                  PSF_nx_pix,PSF_ny_pix, PSF_samples_per_xpix, PSF_samples_per_ypix, $
                  MASK = mask,  XCOORDS = xcoords, YCOORDS = ycoords, $
                  ERROR_FLAG = error_flag, $
                  SPLINE_PSF = spline_psf, X_SPLINE_PSF = x_spline_psf, Y_SPLINE_PSF = y_spline_psf, $
                  CENTROID_MODE = centroid_mode, $
                  PLOT_SAMPLES = plot_samples,$
                  HOW_WELL_SAMPLED = how_well_sampled,$
                  LENSLET_INDICES = lenslet_indices, no_error_checking=no_error_checking
                  

error_flag = 0

;////////////////////////////////////
;// Check the validity of the inputs in both case (vector of coordinates or stamps).
;// In case of stamps, the stamps are reformed in vectors of coordinates. This way, only one type of array are considered in the next section
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
  
  ;should try to remove this loop (done see below)
;time0=systime(1)
;  xcoords = fltarr(nx_pix*ny_pix,n_PSF_samples)
;  ycoords = fltarr(nx_pix*ny_pix,n_PSF_samples)
;  all_pix_values = fltarr(nx_pix*ny_pix,n_PSF_samples)
;
;  for i=0,nx_pix-1 do begin
;    for j=0,ny_pix-1 do begin
;      xcoords[j*nx_pix+i,*] = image_x_sampling[i]
;      ycoords[j*nx_pix+i,*] = image_y_sampling[j]
;      all_pix_values[j*nx_pix+i,*] = pixel_array[i,j,*]
;      not_relevant = where(mask[i,j,*] eq 0)
;      if not_relevant[0] ne -1 then begin
;        xcoords[j*nx_pix+i,not_relevant] = !values.f_nan
;        ycoords[j*nx_pix+i,not_relevant] = !values.f_nan
;        all_pix_values[j*nx_pix+i,not_relevant] = !values.f_nan
;      endif
;    endfor
;  endfor
;  time1=systime(1)
;print, time1-time0
;all_pix_values1=temporary(all_pix_values)
;xcoords1=temporary(xcoords)
;ycoords1=temporary(ycoords)
;delvarx, all_pix_values, xcoords, ycoords
;
;time2=systime(1)
;  ;reform the stamps
;  all_pix_values = reform(pixel_array,nx_pix*ny_pix,n_PSF_samples)
;  xcoords = (reform(image_x_sampling#(fltarr(ny_pix)+1.0),nx_pix*ny_pix))#(fltarr(n_PSF_samples)+1.0)
;  ycoords = (reform((fltarr(nx_pix)+1.0)#image_y_sampling,nx_pix*ny_pix))#(fltarr(n_PSF_samples)+1.0)
;  not_relevant = where((reform(mask,nx_pix*ny_pix,n_PSF_samples)) eq 0)
;  if not_relevant[0] ne -1 then begin
;    all_pix_values[not_relevant] = !values.f_nan
;    xcoords[not_relevant] = !values.f_nan
;    ycoords[not_relevant] = !values.f_nan
;  endif
; time3=systime(1)
;print, time3-time2
;all_pix_values2=temporary(all_pix_values)
;xcoords2=temporary(xcoords)
;ycoords2=temporary(ycoords)
;delvarx, all_pix_values, xcoords, ycoords
;
; this one is the quickest
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
;////////////////////////////////////

;////////////////////////////////////
;// Build the PSF with all the data
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

PSF_nx_samples = PSF_nx_pix*PSF_samples_per_xpix + 1
PSF_ny_samples = PSF_ny_pix*PSF_samples_per_ypix + 1
PSF_x_step = 1.0/float(PSF_samples_per_xpix)
PSF_y_step = 1.0/float(PSF_samples_per_ypix)
PSF_x_sampling = (findgen(PSF_nx_samples) - floor(PSF_nx_samples/2))* PSF_x_step - (mean(x_centroids,/nan)/(nx_pix-1) - 0.5)*PSF_nx_samples*PSF_x_step
PSF_y_sampling = (findgen(PSF_ny_samples) - floor(PSF_ny_samples/2))* PSF_y_step - (mean(y_centroids,/nan)/(ny_pix-1) - 0.5)*PSF_ny_samples*PSF_y_step

x_grid_PSF = rebin(PSF_x_sampling,PSF_nx_samples,PSF_ny_samples)
y_grid_PSF = rebin(reform(PSF_y_sampling,1,PSF_ny_samples),PSF_nx_samples,PSF_ny_samples)

PSF = fltarr(PSF_nx_samples, PSF_ny_samples) ;+ !values.f_nan
how_well_sampled = fltarr(PSF_nx_samples, PSF_ny_samples)
tilt = !values.f_nan
  
where_coords_NOT_too_big = where(all_x_coords lt (PSF_x_sampling[PSF_nx_samples-1] + PSF_x_step/2.)  $
                             AND all_y_coords lt (PSF_y_sampling[PSF_ny_samples-1] + PSF_y_step/2.)  )
       
if where_coords_NOT_too_big[0] ne -1 then begin
  all_x_coords = all_x_coords[where_coords_NOT_too_big]
  all_y_coords = all_y_coords[where_coords_NOT_too_big]
  all_pix_values = all_pix_values[where_coords_NOT_too_big]
  
  
  if keyword_set(PLOT_SAMPLES) then begin
    window, 0
    plot,all_x_coords,all_y_coords ,psym=3,$
                  TITLE = "PSF sampling (green = psf grid, white = samples)", $
                  XTITLE = "x axis (in pixel)", $
                  YTITLE = "y axis (in pixel)", yr=[-1,1],xr=[-1,1]
    oplot, reform(x_grid_PSF, n_elements(x_grid_PSF)),reform(y_grid_PSF, n_elements(y_grid_PSF)),psym=1,color=155
    ;stop
  endif
  
 ;for i=0,88 do for j = 0,32 do cou[j,i] = n_elements(where(val_loc_x_coords eq j and val_loc_y_coords eq i))

; this is the slowest part by far - takes 98% of the time to run this function
; this builds the high-res PSF

	; now we loop 5 times
kernel= [ [ 0.041632, -0.080816, -0.078368, -0.081816,  0.041632], $
					[-0.080816, -0.019592,  0.200816, -0.019592, -0.080816], $
					[ 0.078368,  0.200816,  0.441632,  0.200816,  0.078368], $
					[-0.080816, -0.019592,  0.200816, -0.019592, -0.080816], $
					[ 0.041632, -0.080816, -0.078368, -0.081816,  0.041632]  ]
kernel/=total(kernel) 
xshift=0.0 & yshift=0.0

;loadct,0

; JB code - but this only grabs the points in a half psf_x_step box - we want the full box
;val_loc_x_coords = value_locate(PSF_x_sampling-xshift, all_x_coords + PSF_x_step/2.) 
;val_loc_y_coords = value_locate(PSF_y_sampling+yshift, all_y_coords + PSF_y_step/2.)

time0=systime(1)
	for l=0, 10 do begin
; this finds all the samplings for a given psf coordinate
; takes very little time
val_loc_x_coords = value_locate(PSF_x_sampling-xshift, all_x_coords) 
val_loc_y_coords = value_locate(PSF_y_sampling-yshift, all_y_coords)
	  for i = 0,PSF_nx_samples-1 do begin
			; the indices_for_current_point variable is determined in the following manner simply for speed reasons.
			possible_ind= where((val_loc_x_coords eq i or val_loc_x_coords eq i+1))
			if possible_ind[0] eq -1 then begin
				error_flag += 1
        PSF[i,*] = !values.f_nan
				continue
			endif
			tmp_val_loc_y_coords=val_loc_y_coords[possible_ind]

  	  for j = 0,PSF_ny_samples-1 do begin

				tmp=where((tmp_val_loc_y_coords eq j or tmp_val_loc_y_coords eq j+1))
					if tmp[0] eq -1 then begin
						error_flag += 1
        		PSF[i,j] = !values.f_nan
						continue
					endif
				indices_for_current_point=temporary(possible_ind[temporary(tmp)])


				; the next line is the slowest - this is the original method
				;indices_for_current_point = where((val_loc_x_coords ge i and val_loc_x_coords le i+1) and (val_loc_y_coords ge j and val_loc_y_coords le j+1) )

			  if indices_for_current_point[0] ne -1 then begin
        matching_values = all_pix_values[indices_for_current_point]
					; make sure no nan's are present
					bad=where(finite(matching_values) eq 0, complement=good)
					if good[0] eq -1 then begin
						 error_flag += 1
             PSF[i,j] = !values.f_nan
						continue
					endif
    	    if n_elements(matching_values[good]) ge 3 then begin
      				; calculate residual.
							resid= matching_values - PSF[i,j]
						;stop,[i,j]
							meanclip, resid, curr_mean, curr_sigma, clipsig=2.5, subs=subs;,/verbose   
					;curr_sigma = robust_sigma(matching_values) ; WAY SLOWER
            	PSF[i,j] += curr_mean ; median is too slow
            	how_well_sampled[i,j] = N_ELEMENTS(temporary(subs))
          endif else begin
            error_flag += 1
            PSF[i,j] = !values.f_nan
						continue
          			endelse
        endif else begin
            error_flag += 1
            PSF[i,j] = !values.f_nan
        		continue		
				endelse
      endfor
  	endfor
; now we smooth by a kernel
;window,1,xsize=200,ysize=500
;tvdl,psf

psf2 = CONVOL( psf, kernel , /EDGE_TRUNCATE, /NAN, /NORMALIZE )
ind=where(finite(psf) eq 0)
if ind[0] ne -1 then psf2[ind]=0.0;!values.f_nan
; normalize so that the psf is the same total
psf2*=total(psf,/nan)/total(psf2,/nan)

;window, 2, xsize=200, ysize=500
;tvdl,psf2;,min(psf,/nan),max(psf,/nan)

; this might have shifted the CofM of the epsf, to compensate
; we shift all the samplings to match the original
if l eq 0 then begin
x_centroid0 = total(psf*x_grid_PSF,/nan)/total(psf,/nan);
y_centroid0 = total(psf*y_grid_PSF,/nan)/total(psf,/nan);
endif

new_x_centroid = total(psf2*x_grid_PSF,/nan)/total(psf2,/nan);
new_y_centroid = total(psf2*y_grid_PSF,/nan)/total(psf2,/nan);

; the psf must be centered at 0,0 - but we dont have a real psf
; so we just have to maintain the same centroid as the first pass
xshift = (new_x_centroid-x_centroid0);*psf_x_step 
yshift = (new_y_centroid-y_centroid0);*psf_y_step
; force x to be zero for a moment
;if l eq 9 then print,l,xshift,yshift
if finite(xshift+yshift) eq 0 then stop, 'shifts are not a number ?!? - get_psf2 line 360'
;stop,l,xshift,yshift
psf=temporary(psf2) 

	endfor ; iterative loop
;print, time0-systime(1)

  ;////////////////////////////////////
;stop, 'finished iterative loop'
  ;////////////////////////////////////
  ;// Needs to recenter the PSF.
  ;// This is to verify the property explained in the paper ###### paragraph #. Sorry I don't have the paper right now...
  ;// It says that the centroid of a PSF is defined by the fact that if it is on an edge, both pixels on each side should have the same value.
  
  ;This is simple to say but actually harder to implement properly
  ;;DO NOT TRY TO UNDERSTAND WHAT IT DOES LINE BY LINE. I should make a drawing of that to explain what's going on.
  
  if centroid_mode eq "MAX" or centroid_mode eq "EDGE" then begin
    if n_elements(where(finite(PSF) eq 1)) ge 7 then begin
      ;this is the constant you changed to improve the precision of the centroid. But you have to remember that it is the centroid of the spline-interpolated PSF.
      resolution = 2
      
      ;begin: build an even higher resolution PSF
      psf_sz = size(psf)
      nx = psf_sz[1]
      ny = psf_sz[2]
      
      new_nx = nx+(nx-1)*(resolution-1)
      new_ny = ny+(ny-1)*(resolution-1)
      
      x_grid_PSF = rebin(PSF_x_sampling,nx,ny)
      y_grid_PSF = rebin(reform(PSF_y_sampling,1,ny),nx,ny)
      
      ;remove the nans from the PSF
      reformed_x_grid_psf = reform(x_grid_PSF, n_elements(x_grid_PSF))
      reformed_y_grid_psf = reform(y_grid_PSF, n_elements(y_grid_PSF))
      reformed_psf = reform(PSF, n_elements(PSF))
      
      where_valid_values = where(finite(reformed_psf))
      if where_valid_values[0] ne -1 then begin
        reformed_x_grid_psf = reformed_x_grid_psf[where_valid_values]
        reformed_y_grid_psf = reformed_y_grid_psf[where_valid_values]
        reformed_psf = reformed_psf[where_valid_values]
      endif
      
         higher_res_psf = GRID_TPS(reformed_x_grid_psf,$
                            reformed_y_grid_psf,$
                            reformed_psf,$
                            COEFFICIENTS = useless,$
                            NGRID = [new_nx,new_ny],$
                            START = [x_grid_PSF[0,0], y_grid_PSF[0,0]],$
                            DELTA = [(x_grid_PSF[1,0]-x_grid_PSF[0,0])/resolution,(y_grid_PSF[0,1]-y_grid_PSF[0,0])/resolution])
      
      new_x_PSF = findgen( new_nx )*(x_grid_PSF[1,0]-x_grid_PSF[0,0])/resolution + x_grid_PSF[0,0]
      new_y_PSF = findgen( new_ny )*(y_grid_PSF[0,1]-y_grid_PSF[0,0])/resolution + y_grid_PSF[0,0]
      
      higher_res_x_grid_PSF = rebin(new_x_PSF, new_nx, new_ny)
      higher_res_y_grid_PSF = rebin(reform(new_y_PSF,1,new_ny), new_nx, new_ny)
      ;end: build an even higher resolution PSF
      
      
    endif else begin
      centroid_mode = "BARYCENTER"
      error_flag = -8
    endelse
  endif
  
  ;     "MAX", take the max value
  ;     "BARYCENTER", take the barycenter
  ;     "EDGE", when the centroid is on an edge, both pixels on each side are equal.
  ;begin: find the coordinates of the maxima along both axis
  case centroid_mode of
    "MAX": begin
      useless = max(higher_res_psf,max_subscript,/NAN)
      x_centroid = higher_res_x_grid_PSF[max_subscript]
      y_centroid = higher_res_y_grid_PSF[max_subscript]
    end
    "BARYCENTER": begin
      x_centroid = total(psf*x_grid_PSF,/nan)/total(psf,/nan);
      y_centroid = total(psf*y_grid_PSF,/nan)/total(psf,/nan);
    end
    "EDGE": begin ;is there a better way to do that, faster I mean?
      useless = max(higher_res_psf,max_subscript,/NAN)
      max_x_subscript = max_subscript mod new_nx
      max_y_subscript = floor(max_subscript/new_nx)
      
      useless = max(higher_res_psf, max_subscript_along_x, DIMENSION = 1, /NAN)
      useless = max(higher_res_psf, max_subscript_along_y, DIMENSION = 2, /NAN)
      
      x_coord_of_max_along_x = max_subscript_along_x mod new_nx
      y_coord_of_max_along_x = floor(max_subscript_along_x/new_nx)
      x_coord_of_max_along_y = max_subscript_along_y mod new_nx
      y_coord_of_max_along_y = floor(max_subscript_along_y/new_nx)
      ;end: find the coordinates of the maxima along both axis
      
      ;// In the following, for each column or raw vectors, we are looking for the point that would correspond to the edge of the two pixels with equal value.
      ; We are only looking around the maximum that we previously found. This is to ensure unicity of that point for most cases.
      
      ;Basically, we are looking where we have two points with the same value and spaced by 1 pixel.
      
      ;// First, along the rows
      ;translate from one pix along the x direction and subtract. Where the result is 0 will tell you where there are two equal points at a distance of one pixel. (But as it is never zero we just take the min)
      index_x_right_of_max = lindgen(PSF_samples_per_xpix*resolution+1)
      index_x_right_of_max = rebin(index_x_right_of_max,PSF_samples_per_xpix*resolution+1,new_ny)
      index_x_right_of_max += rebin(reform(x_coord_of_max_along_x,1,new_ny),PSF_samples_per_xpix*resolution+1,new_ny)
      
      index_x_left_of_max = index_x_right_of_max - (PSF_samples_per_xpix*resolution)
      
      index_y = rebin(reform(lindgen(new_ny),1,new_ny),PSF_samples_per_xpix*resolution+1,new_ny)
      
      abs_translate_and_subtract_along_x = abs(higher_res_psf[index_x_right_of_max,index_y]-higher_res_psf[index_x_left_of_max,index_y])
      
      useless = min(abs_translate_and_subtract_along_x, center_index_along_x, DIMENSION = 1, /nan)
      ;center_x_ind_along_x = center_index_along_x mod (PSF_samples_per_xpix*resolution+1)
      ;center_y_ind_along_x = floor(center_index_along_x/(PSF_samples_per_xpix*resolution+1))
      
      ;// Then, along the columns
      index_y_top_of_max = lindgen(PSF_samples_per_ypix*resolution+1)
      index_y_top_of_max = rebin(reform(index_y_top_of_max,1,PSF_samples_per_ypix*resolution+1),new_nx,PSF_samples_per_ypix*resolution+1)
      index_y_top_of_max += rebin(y_coord_of_max_along_y,new_nx,PSF_samples_per_ypix*resolution+1)
      
      index_y_bottom_of_max = index_y_top_of_max - (PSF_samples_per_ypix*resolution)
      
      index_x = rebin(lindgen(new_nx),new_nx,PSF_samples_per_ypix*resolution+1)
      
      abs_translate_and_subtract_along_y = abs(higher_res_psf[index_x,index_y_top_of_max]-higher_res_psf[index_x,index_y_bottom_of_max])
      
      useless = min(abs_translate_and_subtract_along_y, center_index_along_y, DIMENSION = 2, /nan)
      ;center_x_ind_along_y = center_index_along_y mod new_nx
      ;center_y_ind_along_y = floor(center_index_along_y/new_nx)
      
      ;uncomment this to see what we just did. The intersection of the two curve is the upper right corner of the central pixel of a psf centered on the centroid. So you just need to get the position of this intersection and translate it of dx=-0.5pix and dy=-0.5pix
     ; cpy_psf = higher_res_psf
      ;;cpy_psf[index_x_right_of_max[center_x_ind_along_x,center_y_ind_along_x],index_y[center_x_ind_along_x,center_y_ind_along_x]] = 1.0
      ;;cpy_psf[index_x[center_x_ind_along_y,center_y_ind_along_y],index_y_top_of_max[center_x_ind_along_y,center_y_ind_along_y]] = 1.0
     ; cpy_psf[index_x_right_of_max[center_index_along_x],index_y[center_index_along_x]] = 1.0
     ; cpy_psf[index_x[center_index_along_y],index_y_top_of_max[center_index_along_y]] = 1.0
     ; window, 1
      ;shade_surf, cpy_psf
     ; writefits, "/Users/jruffio/Desktop/cpy_psf.fits",cpy_psf
      
      ;// take the intersection point
      ;The intersection point of the two lines formed previously (save cpy_psf in a fits file after uncommenting the few lines above to see what we did)
      ;The intersection point is the upper-right corner of the center pixel of a centered PSF. So we want to get its coordinates and then shift it toward the bottom-left the get the real center
      
      
      ;remove the borders because it creates problem and there is no chance for the centroid to be there.
  ;    id_x_centers_along_x = float(index_x_right_of_max[center_index_along_x])
  ;    id_y_centers_along_y = float(index_y_top_of_max[center_index_along_y])
  ;    id_x_centers_along_x[0:PSF_samples_per_ypix*resolution] = !values.f_nan
  ;    id_x_centers_along_x[(new_ny - PSF_samples_per_ypix*resolution):(new_ny-1)] = !values.f_nan
  ;    id_y_centers_along_y[0:PSF_samples_per_xpix*resolution] = !values.f_nan
  ;    id_y_centers_along_y[(new_nx - PSF_samples_per_xpix*resolution):(new_nx-1)] = !values.f_nan
      
      ;only keep what's around the max because it creates problem and there is no chance for the centroid to be outhere.
      id_x_centers_along_x = float(index_x_right_of_max[center_index_along_x])
      id_y_centers_along_y = float(index_y_top_of_max[center_index_along_y])
      id_x_centers_along_x[0:max([0,(max_y_subscript - PSF_samples_per_ypix*resolution)])] = !values.f_nan
      id_x_centers_along_x[min([(new_ny-1),(max_y_subscript + PSF_samples_per_ypix*resolution)]):(new_ny-1)] = !values.f_nan
      id_y_centers_along_y[0:max([0,(max_x_subscript - PSF_samples_per_xpix*resolution)])] = !values.f_nan
      id_y_centers_along_y[min([(new_nx-1),(max_x_subscript + PSF_samples_per_xpix*resolution)]):(new_nx-1)] = !values.f_nan
      
      
      ;build an array with the L1 (Manhattan) distance between all the combinations of point to find the two closest one. If the two closest on are a unique pixel, then there is an intersection and it is the one we are looking for. Otherwise we just take the middle of the two closest points.
      n_elem_hori = n_elements(index_x[center_index_along_y])
      n_elem_vert = n_elements(id_x_centers_along_x)
      x_j = rebin(reform(id_x_centers_along_x,1,n_elem_vert),n_elem_hori,n_elem_vert)
      y_j = rebin(reform(index_y[center_index_along_x],1,n_elem_vert),n_elem_hori,n_elem_vert)
      x_i = rebin(index_x[center_index_along_y],n_elem_hori,n_elem_vert)
      y_i = rebin(id_y_centers_along_y,n_elem_hori,n_elem_vert)
      
      delta_x_ij = x_i - x_j
      delta_y_ij = y_i - y_j
      
      L1_dist_ij = abs(delta_x_ij) + abs(delta_y_ij)
      min_dist = min(L1_dist_ij, closest_points_id, /nan)
      
      hori_id = closest_points_id mod n_elem_hori
      vert_id = floor(closest_points_id / n_elem_hori)
      bingo_x = 0.5*((index_x[center_index_along_y])[hori_id]+(id_x_centers_along_x)[vert_id])
      bingo_y = 0.5*((index_y[center_index_along_x])[vert_id]+(id_y_centers_along_y)[hori_id])
      x_centroid = higher_res_x_grid_PSF[bingo_x,bingo_y]-0.5
      y_centroid = higher_res_y_grid_PSF[bingo_x,bingo_y]-0.5
      
      ;writefits, "/Users/jruffio/Desktop/L1_dist_ij.fits",L1_dist_ij
      
      ;The following is a bit dirty.. I know.. but it should work in most cases. We should manage the case where there is a shift of one or two pix and that should be fine. Ask Jean-Baptiste to know what is the problem.
      ;mask = intarr(new_nx, new_ny)
      ;mask[id_x_centers_along_x,index_y[center_index_along_x]] += 1
      ;mask[index_x[center_index_along_y],id_y_centers_along_y] += 1
      ;writefits, "/Users/jruffio/Desktop/mask.fits",mask
      ;
      ;bingo = where(mask eq 2.0)
      ;if bingo[0] ne -1 then begin
      ;  x_centroid = higher_res_x_grid_PSF[bingo]-0.5
      ;  y_centroid = higher_res_y_grid_PSF[bingo]-0.5
      ;endif else begin
      ;  mask_tmp = ([intarr(1,new_ny),mask]+[mask,intarr(1,new_ny)])[1:(new_nx-1),1:(new_ny-1)]+([[intarr(new_nx,1)],[mask]]+[[mask],[intarr(new_nx,1)]])[1:(new_nx-1),1:(new_ny-1)]
      ;  bingo = where(mask_tmp gt 3)
      ;  x_centroid = higher_res_x_grid_PSF[bingo[0]]-0.5
      ;  y_centroid = higher_res_y_grid_PSF[bingo[0]]-0.5
      ;endelse
      ;writefits, "/Users/jruffio/Desktop/mask_tmp.fits",mask_tmp
      ;stop
    end
  endcase
  
  
  ;Finally... We shift the coordinates...
  PSF_x_sampling -= x_centroid
  PSF_y_sampling -= y_centroid
  
  if (centroid_mode eq "MAX" or centroid_mode eq "EDGE") and (n_elements(where(finite(PSF) eq 1)) ge 7) then begin
      ;For the keywords:
      spline_psf = higher_res_psf
      x_spline_psf = new_x_PSF - x_centroid
      y_spline_psf = new_y_PSF - y_centroid
  endif else begin
      ;For the keywords:
      spline_psf = !values.f_nan
      x_spline_psf = !values.f_nan
      y_spline_psf = !values.f_nan
  endelse
  ;////////////////////////////////////
endif else begin
  error_flag = -7
endelse

obj_PSF = {values: psf, $
           xcoords: PSF_x_sampling, $
           ycoords: PSF_y_sampling, $
           tilt: 0.0,$
           id: lenslet_indices }
                  
return, ptr_new(obj_PSF,/no_copy)

end
