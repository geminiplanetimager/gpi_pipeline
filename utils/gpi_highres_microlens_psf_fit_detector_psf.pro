;+
; NAME: gpi_highres_microlens_psf_fit_detector_psf
; 
; DESCRIPTION: Give the best fit of an image for a given ePSF
; 
;
; - THIS USES LINEAR INTERPOLATION
;
; IMPORTANT: The common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary needs to be declared prior to the call of this function. If not, copy paste it in your code.
; 
; Use MPFIT2DFUN to perform a least square fit using the function gpi_highres_microlens_psf_evaluate_detector_psf with parameters x_centroid, y_centroid and intensity.
; gpi_highres_microlens_psf_evaluate_detector_psf uses the common psf_lookup_table that is defined by the procedure gpi_highres_microlens_psf_initialize_psf_interpolation.
; gpi_highres_microlens_psf_initialize_psf_interpolation interpolates the PSF defined by the inputs (PSF, x_grid_PSF, y_grid_PSF) with a spline curve a store the result in the common.
; Then gpi_highres_microlens_psf_evaluate_detector_psf use the lookup table in the common to evaluate the PSF using a linear interpolation of lookup table.
; At the end you get a linear interpolation of a spline interpolation of your PSF.
; 
; NOTE: right now the keyword first guess is mandatory but should be optional in the future. If the first guesses are not given as input, the function should be able to infer a simple first guess with a barycenter for the centroid and an integration of the stamp for the intensity.
; 
; INPUTS:
; - pixel_array, pixel_array should be a cube of data of dimension nx x ny x nz. nx x ny being the dimension of the image one wants to fit. nz being the number of images one wants to fit using the same ePSF.
; - FIRST_GUESS = first_guess, 3 by nz 2d array with
;   * first_guess[0,*], vector of length nz with the first guess for the x coordinate of the centroids for each image. gcntrd() could be a good start.
;   * first_guess[1,*], vector of length nz with the first guess for the y coordinate of the centroids for each image. gcntrd() could be a good start.
;   * first_guess[2,*], vector of length nz with the first guess for the intensity of each image (stars, spots...). Aper() could be a good start.
;   
; - ptr_obj_psf, a pointer to an object of type psf. See template below
;     PSF_template = {values: fltarr(nx_psf,ny_psf), $          2D array with the ePSF values.
;                    xcoords: fltarr(nx_psf), $             a vector with the x coordinates for the (assumed regular) grid of the psf.
;                    ycoords: fltarr(ny_psf), $             a vector with the y coordinates for the (assumed regular) grid of the psf.
;                    tilt: 0.0,$
;                    id: [0,0,0] }                    a 4 elements vector containing indexes to locate the psf. in the context of the gpi pipeline. id[0] and id[1] are the indexes for the lenslet array. id[2] the spot number in case of polarimetry fata for example.
;                                                       id is used by the function read_psfs() to rebuild a readable array of psf.
; 
; KEYWORDS: 
; - X0 = x0 and Y0 = y0, vector of nz elements or scalar. If set, it indicates the coordinates of the first pixel [0,0] in case the images are stamps extracted from a bigger images. It allows one to keep the absolute centroids coordinates. Otherwise the origin of the axes is taken at the first pixel of the image. If scalar, it is applied for all the images of the cube.
; - ANTI_STUCK, if set, this keyword allows the function to try different initial values for the algorithm if the fit was really bad with the first try.
; - QUIET, quiet...
; 
; OUTPUTS:  
; - Returned value: a pointer to a cube of the same dimension as pixel_array with the fitted PSFs. return null pointer if an error occured (see keyword error_flag).
; 
; - fit_parameters, 3 by nz 2d array with
;   * fit_parameters[0,*] = x_centroids, contains the centroids of the fitted PSFs. It is a vector of nz elements.
;   * fit_parameters[1,*] = y_centroids, same as x_centroids but for the y-coordinates
;   * fit_parameters[2,*] = intensities, contains the intensities of the fitted PSFs (meaning their weights or the total flux). It is be a vector of nz elements.
; 
; - ERROR_FLAG = error_flag
;     -7: keyword FIRST_GUESS not defined.
;     -6: y0 number of elements is neither equal to 1 nor consistent with pixel_array third dimension.
;     -5: x0 number of elements is neither equal to 1 nor consistent with pixel_array third dimension.
;     -4: keyword FIRST_GUESS number of elements is not consistent with pixel_array third dimension.
;     -3: keyword FIRST_GUESS first dimension should have 3 elements.
;     -2: keyword FIRST_GUESS array number of dimensions is not right. Should be a 2d array.
;     -1: pixel_array size is not valid
;     0: Everything looks fine.
;     1: Warning: If anti_stuck set, the fitting did not really work... Maybe because of a bad PSF or simply because the algorithm failed to converge. So we are trying different initial values.
;     2: Warning: If anti_stuck set, even after trying different initial values, it still didn't work well. Maybe a bad PSF?
;     
; HISTORY:
;   Originally by Jean-Baptiste Ruffio 2013-06
;- 
function gpi_highres_microlens_psf_fit_detector_psf, pixel_array, FIRST_GUESS = first_guess, $
                  X0 = x0, Y0 = y0, mask=mask, $
                  ;PSF, x_vector_psf, y_vector_psf, $
                  ptr_obj_psf,$
                  FIT_PARAMETERS = fit_parameters,$
                  ERROR_FLAG = error_flag, QUIET = quiet, ANTI_STUCK = anti_stuck, $
			no_error_checking=no_error_checking, ncoadds=ncoadds,weights=weights,chisq=chisq


error_flag = 0

;////////////////////////////////////
;// Check the validity of the inputs
pixel_array_sz = size(pixel_array)
if pixel_array_sz[0] eq 3 or pixel_array_sz[0] eq 2 then begin
  nx = pixel_array_sz[1]
  ny = pixel_array_sz[2]
  if pixel_array_sz[0] eq 3 then nz = pixel_array_sz[3] else nz = 1


if keyword_set(no_error_checking) eq 0 then begin

  if ~keyword_set(FIRST_GUESS) then begin
      error_flag = -7
      return, ptr_new()
  endif
  
  sz_first_guess = size(first_guess)
  if ~((sz_first_guess[0] eq 2 and nz eq 1) or (sz_first_guess[0] eq 1 and nz eq 1)) then begin
    error_flag = -2
    return, ptr_new()
  endif
  if sz_first_guess[1] ne 3 then begin
    error_flag = -3
    return, ptr_new()
  endif
  if sz_first_guess[2] ne nz and nz ne 1 then begin
    error_flag = -4
    return, ptr_new()
  endif
  endif  ; error checking

  if keyword_set(x0) then begin
    if n_elements(x0) eq 1 then begin
      x0 = fltarr(nz) + x0
    endif else if n_elements(x0) ne nz then begin
      error_flag = -5
      return, ptr_new()
    endif
  endif
  if keyword_set(y0) then begin
    if n_elements(y0) eq 1 then begin
      y0 = fltarr(nz) + y0
    endif else if n_elements(y0) ne nz then begin
      error_flag = -6
      return, ptr_new()
    endif
  endif
  
endif else begin
  error_flag = -1
  return, ptr_new()
endelse

;////////////////////////////////////
  fitted_PSF = fltarr(nx,ny,nz)
  ;the coordinates corresponding to the fitted PSF
  x_grid0 = rebin(findgen(nx),nx,ny)
  y_grid0 = rebin(reform(findgen(ny),1,ny),nx,ny)
  
  ;these are the outputs of the function. centroid and intensity of the best fit.
  fit_parameters = fltarr(3,nz)  
;todo: check the validity of the psf and coordinates vectors

; load in the common block
common hr_psf_common

; put highres psf in common block for fitting
c_psf = (*ptr_obj_psf).values
; put min values in common block for fitting
c_x_vector_psf_min = min((*ptr_obj_psf).xcoords)
c_y_vector_psf_min = min((*ptr_obj_psf).ycoords)
; determine the sampling and put in common block
c_sampling=round(1/( ((*ptr_obj_psf).xcoords)[1]-((*ptr_obj_psf).xcoords)[0] ))

; declare the parinfo for the fitting
  parinfo = replicate({limited:[0,0], limits:[0.0,0]}, 3) ; x,y,f
    parinfo[0].limited = [1,1]
    parinfo[1].limited = [1,1]
    parinfo[2].limited = [1,0]
    parinfo[2].limits  = [0.0]

 ;loop over all the slice of the pixel_array cube. It fit the same PSF to all of them.

  for i_slice = 0L,long(nz-1) do begin
; statusline, "Fit PSF: "+strc(i_slice+1) +" of "+strc(long(nz)) + " slices fitted"
    
    if keyword_set(x0) then x_grid = x_grid0 + x0[i_slice] else x_grid = x_grid0
    if keyword_set(y0) then y_grid = y_grid0 + y0[i_slice] else y_grid = y_grid0
    
 
  ;   WEIGHTS - Array of weights to be used in calculating the
  ;             chi-squared value.  If WEIGHTS is specified then the ERR
  ;             parameter is ignored.  The chi-squared value is computed
  ;             as follows:
  ;
  ;                CHISQ = TOTAL( (Z-MYFUNCT(X,Y,P))^2 * ABS(WEIGHTS) )
  ;
  ;             Here are common values of WEIGHTS:
  ;
  ;                1D/ERR^2 - Normal weighting (ERR is the measurement error)
  ;                1D/Z     - Poisson weighting (counting statistics)
  ;                1D       - Unweighted
    ;TODO: pick a weight but take care to infinite values

; THIS BIT HERE IS ONLY TO MAKE IT SUCH THAT IF NO MASK IS SUPPLIED
; the program will not crash
; Once polarimetry mode is setup in get_spaxels2.pro to do masks as well
; this should be deleted!

	if keyword_set(mask) then my_weights = mask else begin
		; mask must be the same size as the stamp
		sz=size(x_grid)
		my_weights=fltarr(sz[1],sz[2])+1
	endelse



; we want to follow the format of Anderson et al.
; he uses a radial weighting scheme combined with a poisson distribution
; he can do this because he is looking for astrometry not intensity
if weights eq 'radial' then begin 
	; find peak in mask space
	weights0=mask ; just makes the array 

	rad_arr=sqrt((x_grid-first_guess[0])^2+(y_grid-first_guess[1])^2)

	ind1=where(rad_arr gt 2,ct1)
	if ct1 ne 0 then weights0[ind1]=0.0
	ind2=where(rad_arr ge 1.5 and rad_arr lt 2,ct2)
	if ct2 ne 0 then weights0[ind2]=1.0/((rad_arr[ind2])/1.5) ; goes linearly from 1 to zero with radius
	ind3=where(rad_arr lt 1.5 and mask ne 0,ct3)
	if ct3 ne 0 then weights0[ind3]=1.0  ; sets the core to 1
	weights0*=mask

	; now add the poisson error component
	if keyword_set(ncoadds) eq 0 then ncoadds=1
	data_variance=sqrt(mask*pixel_array*3.04*ncoadds)
	; if negative, set it to be consistent with zero 
	ind=where(pixel_array lt 0,ct)
	if ct ne 0 then data_variance[ind]=abs(pixel_array[ind]*3.04*ncoadds)

	; 1/data_variance will give nans
	final_weights=my_weights/data_variance
	ind=where(finite(final_weights) eq 0,ct)
	if ct ne 0 then final_weights[ind]=0

endif
my_weights=weights




;stop

  ;  my_weights = double(pixel_array[*,*,i_slice]
  ;  my_weights = 1D/pixel_array[*,*,i_slice]
  ;  weights_not_finite = where(~finite(my_weights))
  ;  if weights_not_finite[0] ne -1 then my_weights[weights_not_finite] = 0.0
  
; set centroid limits as the edges of the array
    parinfo[0].limits  = [x0[i_slice],x0[i_slice]+nx]
    parinfo[1].limits  = [y0[i_slice],y0[i_slice]+ny]

	; if weighting is being used, then restrict it to 1 pixel from the central guess
if keyword_set(rad_arr) eq 1 then begin
	; center is at
	junk=min(rad_arr,ind,/nan)
	sz=size(rad_arr)

	; must be within 1 pixel of approximation
    parinfo[0].limits  = [x0[i_slice]+(ind mod sz[1])-1,x0[i_slice]+(ind mod sz[1])+1]
	parinfo[1].limits  = [y0[i_slice]+(ind / sz[1])-1,y0[i_slice]+(ind / sz[1])+1]
endif

    ;Fit the result of gpi_highres_microlens_psf_evaluate_detector_psf to the current slice. gpi_highres_microlens_psf_evaluate_detector_psf uses the common psf_lookup_table to get the PSF to fit. Then it shifts and scales it according to the parameters (centroid and intensity).
 parameters = MPFIT2DFUN("gpi_highres_microlens_psf_evaluate_detector_psf", x_grid, y_grid, pixel_array[*,*,i_slice],0, $
                                                      first_guess[*,i_slice], $
                                                      WEIGHTS = final_weights, PARINFO = parinfo, $
                                                      BESTNORM = chisq, /quiet, YFIT = yfit ) 
 
 if 0 eq 1 then begin
	sz=size(mask)*30
	window,2,xsize=sz[1]*3,ysize=sz[2]
	ind=where(mask ne 0)
	dmax=max(pixel_array[ind],/nan)
	dmin=min(pixel_array[ind],/nan)
	loadct,1
	tvdl, pixel_array*mask,dmin,dmax,position=0,/log
	tvdl,yfit*mask,dmin,dmax,position=1,/log
	loadct,0
	diff=pixel_array-yfit
	my_residuals =  abs(diff) / abs(pixel_array)  

	tvdl,my_residuals*mask,0.0,0.2,position=2
	stop
 endif
 
  
 fitted_PSF[*,*,i_slice] = temporary(yfit)  
   ;store the results of the fit
    fit_parameters[*,i_slice] = temporary(parameters)
; improvised red chisq - 
	junk=where(final_weights ne 0, ct)
	chisq0=chisq
; chisq=( total( weights *(pixel_array-fitted_psf)^2) / (total(final_weights)) ) / (dof-3-1)


if chisq lt 0 then stop
  endfor

return, ptr_new(fitted_PSF,/no_copy)
end
