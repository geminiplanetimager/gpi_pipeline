;+
; NAME: gpi_wavecal_wrapper
; 
; Helper function for 2D model-fitting wavecal algorithm
;
; Function designed to loop over the lenslets and calculate
; the 2D wavelength solution. Uses function mpfit2dfun and calls 
; ngauss.pro which defines a 2d spread of gaussians defined by the filter
; band combination wl and flux guesses found in a text file.
; NOTE: 
;
;  ***** y is [0] and x is [1] in wavelength calibration files *****
;
;
; INPUTS:
;
;
;
; RETURNS:
;    results array as follows
;    res[0]:    X0 position for this lenslet spectrum
;    res[1]:	Y0 position for this lenslet spectrum
;    res[2]:    Dispersion for this lenslet.
;    res[3]:	Spectral tilt theta,     
;    res[4]:    lenslet PSF Gaussian sigma_x
;    res[5]:    lenslet PSF Gaussian sigma_y
;    res[6]:    lenslet PSF Gaussian rotation
;    res[7]:	Constant background offset across the image
;    res[8]:    Total flux in lenslet array in counts
;    res[9:n]:	Relative flux ratios of the individual spectral lines
;
;HISTORY: 
;  2013  by Schuyler Wolff
;
;+

FUNCTION gpi_wavecal_wrapper, xdim,ydim,refwlcal,lensletarray,badpixels,wlcalsize,startx,starty,whichpsf,$
	image_uncert=image_uncert, debug=debug, $
	modelimage=modelimage, modelmask=modelmask, modelbackground=modelbackground

common ngausscommon, numgauss, wl, flux, lambdao, my_psf

nflux=size(flux,/dimensions)

;Pull the values for this lenslet from the reference wavelength calibration
xo=refwlcal[xdim,ydim,1]
yo=refwlcal[xdim,ydim,0]
lambdao=refwlcal[xdim,ydim,2]
w=refwlcal[xdim,ydim,3]
theta=refwlcal[xdim,ydim,4]

;Initialize the starting parameters to be input to mpfit2dfunc
startparmssize=9+nflux
start_params=dblarr(startparmssize)

parinfo = replicate({relstep:0.D, step:0.D, value:0.D, fixed:0, limited:[0,0],limits:[0.D,0.D]}, 9+nflux[0])

for z=0,nflux[0]-1 do begin
    start_params[9+z]=flux[z]
    parinfo[9+z].limited[0]=1
    parinfo[9+z].limits[0]=0.5*flux[z] ; was 20%, now 50% 
    parinfo[9+z].limited[1]=1
    parinfo[9+z].limits[1]=1.5*flux[z]
endfor

start_params[3]=theta


start_params[0]=xo-startx
start_params[1]=yo-starty
sz=size(lensletarray,/dimension)
;print,'test of the wrapper size',sz
xdimension=sz[0]
ydimension=sz[1]
x=indgen(xdimension)
y=indgen(ydimension)

start_params[8]=total(lensletarray);-min(lensletarray)*size(lensletarray,/n_elements)
;print,'flux scaling',start_params[7]

;Initially guess zero rotation for gaussian
start_params[6]=0
if whichpsf EQ 'nmicrolens' then start_params[6].fixed=1

;Provide starting guesses for the gaussian parameters (sigmax,sigmay)
if whichpsf EQ 'ngauss' then begin
if lambdao GT 1.2 then begin
   if xdim LT 211 then start_params[4:5] = [1.5, 1.5]
   if (xdim GE 211) AND (xdim LT 223) then start_params[4:5] = [1.7, 1.7]
   if (xdim GE 223) AND (xdim LT 235) then start_params[4:5] = [1.9, 1.9]
   if (xdim GE 235) AND (xdim LT 245) then start_params[4:5] = [2.1, 2.1]
   if xdim GE 245 then start_params[4:5] = [2.3, 2.3]
endif else begin
   start_params[4:5] = [1.5, 1.5]
endelse
endif



;Compute a weighted error array to be passed to mp2dfitfunct
ERR = sqrt(lensletarray ) ; FIXME this needs to be updated to take into account gain, read noise, etc.
weights = 1D/ERR^2*(1-(badpixels ne 0))

wnan = where(~finite(weights), nanct)
if nanct gt 0 then weights[wnan] = 0

pixelshifttolerance=2.5
oldxpos=start_params[0]
oldypos=start_params[1]

;Place limits on each parameter to be called by mpfit2dfunc.pro
; X position 
parinfo[0].limited[0] = 1
parinfo[0].limits[0] = oldxpos-pixelshifttolerance
parinfo[0].limited[1] = 1
parinfo[0].limits[1] = oldxpos+pixelshifttolerance
; Y position
parinfo[1].limited[0] = 1
parinfo[1].limits[0] = oldypos-pixelshifttolerance
parinfo[1].limited[1] = 1
parinfo[1].limits[1] = oldypos+pixelshifttolerance
;
; dispersion
k=w
start_params[2]=k
deltaw=0.01*w
parinfo[2].relstep=0.1
parinfo[2].limited[0]=1
parinfo[2].limits[0]=k-deltaw
parinfo[2].limited[1]=1
parinfo[2].limits[1]=k+deltaw

; Theta
deltatheta = 0.1 ; radians, so this is about 2 degrees
parinfo[3].limited[0]=1
parinfo[3].limits[0]=theta-deltatheta
parinfo[3].limited[1]=1
parinfo[3].limits[1]=theta+deltatheta

if whichpsf EQ 'ngauss' then begin
if lambdao lt 1.1 then max_fwhm= 4 else max_fwhm=2

; X FWHM
parinfo[4].limited[0]=1
parinfo[4].limits[0]=0.4
parinfo[4].limited[1]=1
parinfo[4].limits[1]=max_fwhm
; Y FWHM
parinfo[5].limited[0]=1
parinfo[5].limits[0]=0.4
parinfo[5].limited[1]=1
parinfo[5].limits[1]=max_fwhm

endif else begin
parinfo[4].fixed=1
parinfo[5].fixed=1
endelse

; Constant background offset must be positive?
parinfo[7].limited[0]=1
parinfo[7].limits[0]=0.0

 

;wprior=refwlcal[xdim,ydim,3]
;wstart=0.999*w
;wend=1.001*w
;winc=(wend-wstart)/3.0

;print, 'Starting guess for lenslet wavecal', start_params


;for k=wstart,wend,winc do begin

    case whichpsf of
       'nmicrolens': begin
           bestres=mpfit2dfun('nmicrolens',x,y,lensletarray, ERR,weight=weights, start_params,parinfo=parinfo,bestnorm=bestnorm,/quiet, status=status, errmsg =errmsg)
        end
        'ngauss': begin
           bestres=mpfit2dfun('ngauss',x,y,lensletarray, ERR,weight=weights, start_params,parinfo=parinfo,bestnorm=bestnorm,/quiet, status=status, errmsg =errmsg)
        end
    endcase

	if status lt 0 then print, "ERROR: ", errmsg
 
	loww=k

	; Return other helpful stuff to the calling routine:
	if arg_present(modelimage) then begin
		; return the 2D model image resulting from the fit,
		case whichpsf of
		  'nmicrolens': modelimage=nmicrolens(x,y,bestres)
		  'ngauss': modelimage=ngauss(x,y,bestres)
		endcase

		; remove the constant background since we have to handle overlaps
		; carefully when combining these. This implementation is easiest given
		; the normalization present in the ngauss function
		modelbackground= min(modelimage)
		modelimage -= modelbackground
	endif
	if arg_present(modelmask) then begin
		; return a 2D mask of which pixels were used in that fit.
		modelmask = weights ne 0
	endif

	if keyword_set(debug) then begin
		atv,[[[lensletarray]],[[modelimage]]],/bl
		stop
	endif
       
;TO DO: set bestres=0 as a flag for a failed fit, then interpolate the
;correct value in the wavelength solution 2d primitive
if array_equal(start_params[0:1], bestres[0:1]) then begin
   message,/info, "WARNING - SAME START AND END POSITIONS"
  ; bestres=0
endif

return, bestres


END
