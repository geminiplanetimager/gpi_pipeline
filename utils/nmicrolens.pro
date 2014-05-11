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
;common hr_psf_common, c_psf, c_x_vector_psf_min, c_y_vector_psf_min, c_sampling
;fill the common variables with initialize_psf_interp.
;gpi_highres_microlens_psf_initialize_psf_interpolation, my_psf.values, my_psf.xcoords, my_psf.ycoords
;/////////////////////////

c_psf=my_psf.values
c_x_vector_psf_min = min((my_psf).xcoords)
c_y_vector_psf_min = min((my_psf).ycoords)
c_sampling = round(1.0/( ((my_psf).xcoords)[1]-((my_psf).xcoords)[0] ))
;print, 'psf params', size(c_psf,/dimensions),c_x_vector_psf_min, c_sampling

szx=size(x,/n_elements)
xoffset=szx
szy=size(y,/n_elements)
yoffset=szy

;try something so microlens psf doesn't fail
;szx=5
;szy=20

xo=start_params[0]
yo=start_params[1]
theta=start_params[3]
w=start_params[2]
sigmax=start_params[4]
sigmay=start_params[5]
rotation=start_params[6]
background=start_params[7]

zmod=dblarr(xoffset,yoffset)

x_grid=dblarr(szx,szy)
y_grid=dblarr(szx,szy)

;create the grid in the proper dimensions for the evaluate_psf function
for xsize=0,szx-1 do begin
   y_grid[xsize,*]=indgen(szy)
endfor
for ysize=0,szy-1 do begin
   x_grid[*,ysize]=indgen(szx)
endfor


for peak = 0, numgauss-1 do begin
   lambda=wl[peak]
   coeff=start_params[9+peak]
   xcent=xo+sin(theta)*(lambda-lambdao)/w
   ycent=yo-cos(theta)*(lambda-lambdao)/w

   x_centroid = xcent 
   y_centroid = ycent;-1
   intensity = coeff*100
   ;my_eval_psf = coeff*gpi_highres_microlens_psf_evaluate_detector_psf(x,y,[x_centroid, y_centroid, intensity])
   my_eval_psf = interpolate(c_psf,(x - (x_centroid + c_x_vector_psf_min))*c_sampling,(y - (y_centroid + c_y_vector_psf_min))*c_sampling,/grid,missing=0)
   ;print, my_eval_psf
   ;zmod[where(finite(my_eval_psf))] += my_eval_psf[where(finite(my_eval_psf))]
   zmod += my_eval_psf
   ;print, where(finite(my_eval_psf))
endfor

;normalize this to the science image
zmod=zmod*start_params[8]/total(zmod)

;add a constant background
zmod += background

return, zmod

END
