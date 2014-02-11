;+
; NAME: gpi_highres_microlens_psf_evaluate_detector_psf
; 
; DESCRIPTION: Evaluate the PSF stored in the common variables of psf_lookup_table at the points specified by the grid defined by x an y and following the parameters p.
; If the points specified by x and y are outside the definition range of the PSF, the given value is 0.0.
; 
; IMPORTANT 1: The common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary needs to be declared prior to the call of this function. If not, copy paste it in your code.
; com_* in the name stand for common.
; 
; IMPORTANT 2: gpi_highres_microlens_psf_initialize_psf_interpolation has to be called before if you want to use evaluate_psf.
; 
; INPUTS:
; - x, 2d array with the x coordinates. all the vector x[*,i] should be equal.
; - y, 2d array with the y coordinates. all the vector y[i,*] should be equal.
; - p, vector of 3 elements with the parameters of the psf from which you want the values. p[0] x coord of the centroid. p[1] y coord of the centroid. p[2] is the intensity.
;
; OUTPUTS:  
; - p[2]*psf(x-p[0],y-p[1])
;     
; HISTORY:
;   Originally by Jean-Baptiste Ruffio 2013-06
;-
function gpi_highres_microlens_psf_evaluate_detector_psf, x, y, p
;common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary
common psf_lookup_table

x_cen = p[0]
y_cen = p[1]
f = p[2]

diff_x_grid = x - x_cen
diff_y_grid = y - y_cen

return, f * TRIGRID( com_x_grid_PSF, com_y_grid_PSF, com_psf, com_triangles , XOUT = diff_x_grid[*,0], YOUT = diff_y_grid[0,*], MISSING = 0.0 )

end
