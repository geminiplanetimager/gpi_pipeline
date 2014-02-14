function find_pol_center, img0, x0, y0, xrad, yrad, maskrad=maskrad, highpass=highpass, statuswindow=statuswindow
;+
; NAME:
;        find_pol_center
; PURPOSE:
;        Find the occulted star poistion in GPI Polarimetry mode
;
; EXPLAINATION
;        Performs a radon transform for all points within the
;        specified box to determine whether the satellite spots
;        all converge to that point. This produces a 'cost function'
;        map that is then interpolated to find the center to 
;        subpixel accurary.
;
; CALLING SEQUENCE:
;        center = find_pol_center(img, 148, 147, 5, 5, [maskrad=maskrad, /highpass])
; 
; INPUT/OUTPUT:
;        img0 - 2D or 3D image
;        x0,y0 - inital guess for the center of the occulted star
;        xrad,yrad - x and y search radius that defines the rectangular
;                    box to search in. The algorithm runs slowly so
;                    avoid big search boxes
;        center - 2 element array [x,y] of the calculated star position
;
; OPTIONAL INPUT:
;        maskrad - the radius of the mask of the center of the psf
;                   (default is 50 pixels)
;        highpass - set to run a highpass filter before locating spots
;        statuswindow - pointer to status window to update gui progressbar
; DEPENDENCIES:
; filter_image.pro
;
; REVISION HISTORY
;        Wrttien 01/28/2014. Based on work by Laurent -jasonwang
;-

;make copy of image, I think
img = img0

;collapse polarization dimension if not already
if (size(img))[0] eq 3 then img = total(img, 3)

;remove NANs
badind = where(~FINITE(img),cc)
if cc ne 0 then img[badind] = 0

;filter image to remove background
if keyword_set(highpass) then img -= filter_image(img,median=9)

;mask out the center psf because it is too bright
if not keyword_set(maskrad) then maskrad = 50
dims = size(img,/dim)
x = (LINDGEN(dims[0],dims[1]) MOD dims[0])
y = (LINDGEN(dims[0],dims[1]) / dims[0])
centralmask = where( (x-x0)^2 + (y-y0)^2  le maskrad^2)
img[centralmask] = 0

;locate center of image and compare with guess x0,y0
imgxcen = dims[1] / 2
imgycen = dims[0] / 2

xoffset = imgxcen - x0
yoffset = imgycen - y0

;create search box and output of search (searchspace)
xsearchlen = 2*xrad+1
ysearchlen = 2*yrad+1
xrange = indgen(xsearchlen) - xrad
yrange = indgen(ysearchlen) - yrad
searchspace = dindgen(xsearchlen, ysearchlen) * 0

;try all points in the search box to see how well sat spots align
for i=0,xsearchlen-1 do begin
	for j=0,ysearchlen-1 do begin
		;shift so that the search point is in the center of the image
		shifted = shift(img, xoffset-xrange[i], yoffset-yrange[j])

		;radon transform
		;we only care about radon xform slice for rho=0 (i.e. the center)
		;so we'll make the drho stepsize huge
		sino = radon(shifted, rho=rho, ntheta=720, drho=dims[0])

		;look at only how the radon xform looks in the center
		rho0 = where(rho eq 0)

		;we expect pairs of sat spots to be 90 degrees apart so 
		;fold the sinogram in the angular coordinate so that points
		;90 degrees apart will add together
		;don't know if this actually works...
		;sinodim = size(sino,/dim)
		;sino = sino[0:sinodim[0]/2-1,*] + sino[sinodim[0]/2:*,*]

		;add up the signal
		signal = total(sino[*,rho0]^2)

		;write the signal to our output map
		searchspace[i,j] = signal

		;update status window if GUI display
		if keyword_set(statuswindow) then $
			statuswindow->set_percent, -1, 100.0/(xsearchlen*ysearchlen+1.),/append
	endfor
endfor

;how much precision do you want the interpolatoin to try
precision = 1000.

;interpolate map to get subpixel accuracy 
xfine = (findgen(xsearchlen*precision) / precision)
yfine = (findgen(ysearchlen*precision) / precision)

finersearch = interpolate(searchspace, xfine, yfine, cubic=-0.5, /grid)

;find maximum value in interpolation -> this is our occulted star position
maxval = max(finersearch, index)
index = array_indices(finersearch, index)

;convert back to pixel coordiantes
xcent = float(index[0])/precision - xrad + x0
ycent = float(index[1])/precision - yrad + y0

if keyword_set(statuswindow) then $
	statuswindow->set_percent, -1, 100.0

return, [xcent,ycent]
end
