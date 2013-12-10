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
;    start_params[4]-FWHM x of gaussian
;    start_params[5]-FWHM y of gaussian
;    start_params[6]-rotation of gaussian
;    start_params[7]-scaling
;    start_params[8-end]-flux ratios
;    
; HISTORY:
;    Created by Schuyler Wolff
;    2013-12-04 Marshall Perrin: modifications to support rotated Gaussians. 
;				added one_2d_gaussian function and helper functions, and some
;				other mostly minor changes.
;-
;-----------------------------------
; Helper functions lifted from mpfit2dpeak:
;

; Compute the "u" value = (x/a)^2 + (y/b)^2 with optional rotation
function mpfit2dpeak_u, x, y, p, tilt=tilt, symmetric=sym
  widx  = abs(p[2]) > 1e-20 & widy  = abs(p[3]) > 1e-20
  if keyword_set(sym) then widy = widx
  xp    = x-p[4]            & yp    = y-p[5]
  theta = p[6]
  if keyword_set(tilt) AND theta NE 0 then begin
      c  = cos(theta) & s  = sin(theta)
      return, ( (xp * (c/widx) - yp * (s/widx))^2 + $
                (xp * (s/widy) + yp * (c/widy))^2 )
  endif else begin
      return, (xp/widx)^2 + (yp/widy)^2
  endelse

end

; Gaussian Function
function mpfit2dpeak_gauss, x, y, p, tilt=tilt, symmetric=sym, _extra=extra
  sz = size(x)
  if sz[sz[0]+1] EQ 5 then smax = 26D else smax = 13.

  u = mpfit2dpeak_u(x, y, p, tilt=keyword_set(tilt), symmetric=keyword_set(sym))
  mask = u LT (smax^2)  ;; Prevents floating underflow
  return, p[0] + p[1] * mask * exp(-0.5 * u * mask)
end

;-----------------------------------
; A drop-in replacement for psf_gaussian (mostly syntax compatible) which allows rotation
function one_2d_gaussian, xvals, yvals, fwhm=fwhm, centroid=centroid, ndimen=ndimen, double=double, normalize=normalize,rotation=rotation
   ;replaces: psf_gaussian(npixel=[xoffset,yoffset],fwhm=[sigmax,sigmay],centroid=[xcent,ycent],ndimen=2,/double,/normalize
   if ~(keyword_set(rotation)) then rotation=0

    if keyword_set(double) then idltype = 5 else idltype = 4
	p = [0, 1, fwhm/(2*sqrt(2*alog(2))), centroid, rotation] ; convert from fwhm to sigmas...

	ans = mpfit2dpeak_gauss(xvals, yvals, p, tilt=keyword_set(rotation))
	if keyword_set(normalize) then ans/=total(ans)
	return, ans

end



;-----------------------------------
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
fwhmx=start_params[4]
fwhmy=start_params[5]
rotation=start_params[6]
;background=start_params[7]

zmod=dblarr(xoffset,yoffset)

xvals = make_array(szx,szy,/index,/integer) mod szx
yvals = make_array(szx,szy,/index,/integer) / szx


for i=0, numgauss-1 do begin
   lambda=wl[i]
   coeff=start_params[8+i]
   xcent=xo+sin(theta)*(lambda-lambdao)/w
   ycent=yo-cos(theta)*(lambda-lambdao)/w
;   zmod=zmod+mpfit2dpeak_gauss()
   ;gauss1 = coeff*psf_gaussian(npixel=[xoffset,yoffset],fwhm=[fwhmx,fwhmy],centroid=[xcent,ycent],ndimen=2,/double,/normalize)
   zmod += coeff*one_2d_gaussian(xvals, yvals, fwhm=[fwhmx,fwhmy],centroid=[xcent,ycent],ndimen=2,/double,/normalize,rotation=rotation)
   ;zmod+= gauss1
   
;print,i
endfor

;normalize this to the science image
zmod=zmod*start_params[7]/total(zmod)


return, zmod

END
