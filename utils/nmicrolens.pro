;+
;
;   Function describing the simultaneous 2D microlens psf fit of an entire 
;   lenslet spectrum. Produces a derivative to be used with mpfitfunc. 
;
;   Input:
;    start_params[0]-xo (x position)
;    start_params[1]-yo (y position)
;    start_params[2]-w (dispersion)
;    start_params[3]-theta (angle of lenslet spectrum)   in radians
;    start_params[4]-FWHM of gaussian
;    start_params[5]-FWHM of gaussian
;    start_params[6]-rotation of gaussian
;    start_params[7]-consant background offset
;    start_params[8]-scaling
;    start_params[9-end]-flux ratios
;    
;+

FUNCTION nmicrolens,x,y, start_params

common ngausscommon, numgauss, wl, flux, lambdao,my_psf

;/////////////////////////
;Code you need to add before using gpi_highres_microlens_psf_evaluate_detector_psf
;declare the common variable used by gpi_highres_microlens_psf_evaluate_detector_psf()
common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary
common hr_psf_common, c_psf, c_x_vector_psf_min, c_y_vector_psf_min, c_sampling
;fill the common variables with initialize_psf_interp.
;gpi_highres_microlens_psf_initialize_psf_interpolation, my_psf.values, my_psf.xcoords, my_psf.ycoords
;/////////////////////////


szx=size(x,/n_elements)
xoffset=szx
szy=size(y,/n_elements)
yoffset=szy

xo=start_params[0]
yo=start_params[1]
theta=start_params[3]
w=start_params[2]
sigmax=start_params[4]
sigmay=start_params[5]
rotation=start_params[6]
background=start_params[7]

zmod=dblarr(xoffset,yoffset)

x_grid=dblarr(szx,szx)
y_grid=dblarr(szx,szy)

;create the grid in the proper dimensions for the evaluate_psf function
for xsize=0,szx-1 do begin
   x_grid[*,xsize]=x
   y_grid[xsize,*]=y
endfor


for peak = 0, numgauss-1 do begin
   lambda=wl[peak]
   coeff=start_params[9+peak]
   xcent=xo+sin(theta)*(lambda-lambdao)/w
   ycent=yo-cos(theta)*(lambda-lambdao)/w

   x_centroid = xcent 
   y_centroid = ycent-1
   intensity = coeff
   my_eval_psf = gpi_highres_microlens_psf_evaluate_detector_psf(x_grid,y_grid,[x_centroid, y_centroid, intensity])
   zmod += my_eval_psf

endfor

;normalize this to the science image
zmod=zmod*start_params[8]/total(zmod)

;add a constant background
zmod += background

return, zmod

END
