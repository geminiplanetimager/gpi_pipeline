;+
; NAME: gpi_highres_microlens_psf_initialize_psf_interpolation
; 
; DESCRIPTION: Setup the common psf_lookup_table for later use.
; 
; IMPORTANT: The common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary needs to be declared prior to the call of this function. If not, copy paste it in your code.
; com_* in the name stand for common.
; 
; This procedure has to be called before if you want to use gpi_highres_microlens_psf_evaluate_detector_psf.pro.
; It also give the triangles and boundaries (from triangulate) that you need if you want to perform a linear interpolation using TRIGRID.
; 
; INPUTS:
; - psf, a 2d array with the PSF values for the coordinates defined by x_grid_PSF and y_grid_PSF.
; - x_vector_PSF, vector with the x coordinates of the psf's grid
; - y_vector_PSF, vector with the y coordinates of the psf's grid
; - resolution, 
; OUTPUTS:  
; - No returned value. But it changes the value of the variables of the common psf_lookup_table.
; 
; KEYWORDS:
; - SPLINE, trigger the spline interpolation before the call to triangulate (tri_grid interpolation latter on). It interpolates using GRID_TPS and then samples it as indicate by resolution. The spline interpolation has been removed by default for the moment because it is very slow and appears not to do better.
; - RESOLUTION, 2 by default. This factor indicates the resolution of the spline samples. If you have a PSF with nx*ny points, you will get a spline-psf with [nx+(nx-1)*(resolution-1)]x[ny+(ny-1)*(resolution-1)].
;     
; HISTORY:
;   Originally by Jean-Baptiste Ruffio 2013-06
;-
pro gpi_highres_microlens_psf_initialize_psf_interpolation, psf, x_vector_PSF, y_vector_PSF, RESOLUTION = resolution, SPLINE = spline
;  common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary
  common psf_lookup_table
  
  sz_psf = size(psf)
  nx_psf = sz_psf[1]
  ny_psf = sz_psf[2]
  x_grid_PSF = rebin(x_vector_psf,nx_psf,ny_psf)
  y_grid_PSF = rebin(reform(y_vector_psf,1,ny_psf),nx_psf,ny_psf)
  
  if keyword_set(SPLINE) then begin
    if ~keyword_set(RESOLUTION) then resolution = 2
  
    ;TODO: check the PSF validity
    psf_sz = size(psf)
    nx = psf_sz[1]
    ny = psf_sz[2]
    
    new_nx = nx+(nx-1)*(resolution-1)
    new_ny = ny+(ny-1)*(resolution-1)
    
    ;remove the nans from the PSF because grid_tps doesn't like them.
    reformed_x_grid_psf = reform(x_grid_PSF, n_elements(x_grid_PSF))
    reformed_y_grid_psf = reform(y_grid_PSF, n_elements(y_grid_PSF))
    reformed_psf = reform(PSF, n_elements(PSF))
    
    where_valid_values = where(finite(reformed_psf))
    if where_valid_values[0] ne -1 then begin
      reformed_x_grid_psf = reformed_x_grid_psf[where_valid_values]
      reformed_y_grid_psf = reformed_y_grid_psf[where_valid_values]
      reformed_psf = reformed_psf[where_valid_values]
    endif
    
    ;com_* is standing for common because it is a common variable
    com_psf = GRID_TPS(reformed_x_grid_psf,$
                          reformed_y_grid_psf,$
                          reformed_psf,$
                          COEFFICIENTS = useless,$
                          NGRID = [new_nx,new_ny],$
                          START = [x_grid_PSF[0,0], y_grid_PSF[0,0]],$
                          DELTA = [(x_grid_PSF[1,0]-x_grid_PSF[0,0])/resolution,(y_grid_PSF[0,1]-y_grid_PSF[0,0])/resolution])
    
    new_x_PSF = findgen( new_nx )*(x_grid_PSF[1,0]-x_grid_PSF[0,0])/resolution + x_grid_PSF[0,0]
    new_y_PSF = findgen( new_ny )*(y_grid_PSF[0,1]-y_grid_PSF[0,0])/resolution + y_grid_PSF[0,0]
    
    com_x_grid_PSF = rebin(new_x_PSF, new_nx, new_ny)
    com_y_grid_PSF = rebin(reform(new_y_PSF,1,new_ny), new_nx, new_ny)
  endif else begin
    com_psf=psf
    com_x_grid_PSF = x_grid_PSF
    com_y_grid_PSF = y_grid_PSF
  endelse

  if n_elements(where(finite(com_psf))) ge 3 then begin
     ind=where(finite(com_psf) eq 1)
     com_psf=temporary(com_psf[ind])
     com_x_grid_PSF =  com_x_grid_PSF[ind]
     com_y_grid_PSF=com_y_grid_PSF[ind]
    triangulate, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary,tolerance=10^(-6.0)*max(com_x_grid_PSF*com_y_grid_PSF)
  endif
end
