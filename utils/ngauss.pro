;+
;
;   Function describing the simultaneous 2D Gaussian fit of an entire 
;   lenslet spectrum. Produces a derivative to be used with mpfitfunc. 
;
;   Input:
;    start_params[0]-xo (x position)
;    start_params[1]-yo (y position)
;    start_params[2]-w (dispersion)
;    start_params[3]-theta (angle of lenslet spectrum)   in radians
;    start_params[4]-sigmax of gaussian
;    start_params[5]-sigmay of gaussian
;    start_params[6]-rotation of gaussian
;    start_params[7]-scaling
;    start_params[8-end]-flux ratios
;    
;+

FUNCTION ngauss,x,y, start_params

common ngausscommon, numgauss, wl, flux, lambdao,my_psf

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

zmod=dblarr(xoffset,yoffset)

for i=0, numgauss-1 do begin
   lambda=wl[i]
   coeff=start_params[8+i]
   xcent=xo+sin(theta)*(lambda-lambdao)/w
   ycent=yo-cos(theta)*(lambda-lambdao)/w
;   zmod=zmod+mpfit2dpeak_gauss()
   zmod=zmod+coeff*psf_gaussian(npixel=[xoffset,yoffset],fwhm=[sigmax,sigmay],centroid=[xcent,ycent],ndimen=2,/double,/normalize)
;print,i
endfor

;normalize this to the science image
zmod=zmod*start_params[7]/total(zmod)


return, zmod

END
