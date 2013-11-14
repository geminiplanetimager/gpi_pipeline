;+
; Temporary Function designed to loop over the lenslets and calculate
; the 2D wavelength solution. Uses function mpfit2dfun and calls 
; ngauss.pro which defines a 2d spread of gaussians defined by the filter
; band combination wl and flux guesses found in a text file.
; NOTE: 
;
;  ***** y is [0] and x is [1] in wavelength calibration files *****
;
;+

FUNCTION gpi_wavecal_wrapper, xdim,ydim,refwlcal,lensletarray,badpixels,wlcalsize,startx,starty,whichpsf

common ngausscommon, numgauss, wl, flux, lambdao, my_psf

nflux=size(flux,/dimensions)

;Pull the values for this lenslet from the reference wavelength calibration
xo=refwlcal[xdim,ydim,1]
yo=refwlcal[xdim,ydim,0]
lambdao=refwlcal[xdim,ydim,2]
w=refwlcal[xdim,ydim,3]
theta=refwlcal[xdim,ydim,4]

;Initialize the starting parameters to be input to mpfit2dfunc
startparmssize=8+nflux
start_params=dblarr(startparmssize)

parinfo = replicate({relstep:0.D, step:0.D, value:0.D, fixed:0, limited:[0,0],limits:[0.D,0.D]}, 8+nflux[0])

for z=0,nflux[0]-1 do begin
    start_params[8+z]=flux[z]
    parinfo[8+z].limited(0)=1
    parinfo[8+z].limits(0)=0.8*flux[z]
    parinfo[8+z].limited(1)=1
    parinfo[8+z].limits(1)=1.2*flux[z]
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

start_params[7]=total(lensletarray);-min(lensletarray)*size(lensletarray,/n_elements)
;print,'flux scaling',start_params[7]

;Provide starting guesses for the gaussian parameters (sigmax,sigmay,rotation)
start_params[4:6] = [1.5, 1.5, 0]


;Compute a weighted error array to be passed to mp2dfitfunct
ERR = sqrt(lensletarray)
wayt = 1D/ERR^2*(1-badpixels)

wnan = where(~finite(wayt), nanct)
if nanct gt 0 then wayt[wnan] = 0

pixelshifttolerance=2.5
oldxpos=start_params[0]
oldypos=start_params[1]

;Place limits on each parameter to be called by mpfit2dfunc.pro
; X position 
parinfo[0].limited(0) = 1
parinfo[0].limits(0) = oldxpos-pixelshifttolerance
parinfo[0].limited(1) = 1
parinfo[0].limits(1) = oldxpos+pixelshifttolerance
; Y position
parinfo[1].limited(0) = 1
parinfo[1].limits(0) = oldypos-pixelshifttolerance
parinfo[1].limited(1) = 1
parinfo[1].limits(1) = oldypos+pixelshifttolerance
; Theta
deltatheta = 0.1 ; radians, so this is about 2 degrees
parinfo[3].limited(0)=1
parinfo[3].limits(0)=theta-deltatheta
parinfo[3].limited(1)=1
parinfo[3].limits(1)=theta+deltatheta
; X sigma
parinfo[4].limited(0)=1
parinfo[4].limits(0)=0.4
parinfo[4].limited(1)=1
parinfo[4].limits(1)=2.0
; Y sigma
parinfo[5].limited(0)=1
parinfo[5].limits(0)=0.4
parinfo[5].limited(1)=1
parinfo[5].limits(1)=2.0
; Flux Scaling
 ;parinfo[7].limited(0)=1
 ;parinfo[7].limits(0)=0.0001*start_params[7]
 ;parinfo[7].limited(1)=1
 ;parinfo[7].limits(1)=start_params[7]


;wprior=refwlcal[xdim,ydim,3]
;wstart=0.999*w
;wend=1.001*w
;winc=(wend-wstart)/3.0

;print, 'Starting guess for lenslet wavecal', start_params


;for k=wstart,wend,winc do begin
k=w

    start_params[2]=k
    deltaw=0.01*w
    ; dispersion
    parinfo[2].relstep=0.1
    parinfo[2].limited(0)=1
    parinfo[2].limits(0)=k-deltaw
    parinfo[2].limited(1)=1
    parinfo[2].limits(1)=k+deltaw

    case whichpsf of
       'nmicrolens': begin
           resultd=mpfit2dfun('nmicrolens',x,y,lensletarray, ERR,weight=wayt, start_params,parinfo=parinfo,bestnorm=bestnorm,/quiet, status=status, errmsg =errmsg)
        end
        'ngauss': begin
           resultd=mpfit2dfun('ngauss',x,y,lensletarray, ERR,weight=wayt, start_params,parinfo=parinfo,bestnorm=bestnorm,/quiet, status=status, errmsg =errmsg)
        end
    endcase

;	print, "Status: ", status

	if status lt 0 then print, "ERROR: ", errmsg
    
 

    ;if float(bestnorm) LE float(max) then begin
    ;    max=bestnorm
        loww=k
        bestres=resultd
    ;endif

;endfor

       
;TO DO: set bestres=0 as a flag for a failed fit, then interpolate the
;correct value in the wavelength solution 2d primitive
if array_equal(start_params[0:1], bestres[0:1]) then begin
   message,/info, "WARNING - SAME START AND END POSITIONS"
  ; bestres=0
endif

return, bestres


END
