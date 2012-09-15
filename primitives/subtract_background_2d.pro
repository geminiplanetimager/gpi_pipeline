;+
; NAME: subtract_background_2d
; PIPELINE PRIMITIVE DESCRIPTION: Subtract background from 2D raw image
;
;   Subtract the (possibly fluctuating) background from a 2D raw IFS
;   image, by using the regions in between the spectra. 
;
;   **currently a developmental/testing routine**
;
;   TODO: This algorithm would be more robust if it made use of existing
;   wavelength solution information for masking out which pixels to use,
;   probably. Actually this should be an option the user can select: use
;   the image pixels or use a wavelength solution. Using the image pixels
;   themselves is necessary for the case where you are trying to *create* 
;   a wavelength solution, then once you have that you should probably use it
;   instead. 
;
;   The problem with just using the image pixels is that it depends on the
;   relative brightness of the background noise vs. the spectra, so it can fail
;   if the SNR in the spectra is low or the background noise is especially high.
;
; KEYWORDS:
; 	gpitv=		session number for the GPITV window to display in.
; 				set to '0' for no display, or >=1 for a display.
;
; OUTPUTS:
;
; PIPELINE ARGUMENT: Name="method" Type="string" Range="[threshhold|calfile]" Default="threshhold" Desc='Find background based on image value threshhold cut, or calibration file spectra/spot locations?'
; PIPELINE ARGUMENT: Name="thresh" Type="float" Range="[0,5]" Default="2" Desc="What multiple of the image median should be used as the threshhold for selecting spectra? Suggested values 2 for spectral mode, 4 for polarimetry"
; PIPELINE ARGUMENT: Name="fwhm_x" Type="float" Range="[0,10]" Default="1" Desc="FWHM of the Gaussian for smoothing the background, in the X direction"
; PIPELINE ARGUMENT: Name="fwhm_y" Type="float" Range="[0,10]" Default="7" Desc="FWHM of the Gaussian for smoothing the background, in the Y direction.  Suggested value 7 for spectra, 15 for polarimetry modes"
; PIPELINE ARGUMENT: Name="niter" Type="int" Range="[0,10]" Default="3" Desc="How many times to iterate the convolution fill towards convergence?"
; PIPELINE ARGUMENT: Name="before_and_after" Type="int" Range="[0,1]" Default="0" Desc="Show the before-and-after images for the user to see?"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="1" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
; PIPELINE COMMENT:  Subtract 2D background based on the regions in between the spectra
; PIPELINE ORDER: 1.12 
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE NEWTYPE: SpectralScience,Calibration
;
;
; HISTORY:
; 	Originally by Marshall Perrin, 2011-07-15
;   2011-07-30 MP: Updated for multi-extension FITS
;-
function subtract_background_2d, DataSet, Modules, Backbone
primitive_version= '$Id: displayrawimage.pro 417 2012-02-09 14:13:04Z maire $' ; get version from subversion to store in header history
@__start_primitive

 if tag_exist( Modules[thisModuleIndex], "method") then method=(Modules[thisModuleIndex].method) else method='threshhold'
 if tag_exist( Modules[thisModuleIndex], "thresh") then thresh=float(Modules[thisModuleIndex].thresh) else thresh=2
 if tag_exist( Modules[thisModuleIndex], "fwhm_x") then fwhm_x=float(Modules[thisModuleIndex].fwhm_x) else fwhm_x=1
 if tag_exist( Modules[thisModuleIndex], "fwhm_y") then fwhm_y=float(Modules[thisModuleIndex].fwhm_y) else fwhm_y=7
 if tag_exist( Modules[thisModuleIndex], "niter") then niter=fix(Modules[thisModuleIndex].niter) else niter=3
 if tag_exist( Modules[thisModuleIndex], "before_and_after") then before_and_after=fix(Modules[thisModuleIndex].before_and_after) else before_and_after=0
 mediansize = 7 ;max([fwhm_x, fwhm_y,5])

 ;get the 2D detector image
 image=*(dataset.currframe[0])

 backbone->Log, 'Generating model of 2D image background based on pixels in between spectra'

 ; The first step is to figure out which pixels are from spectra (or pol spots)
 ; and which are not. Perhaps eventually this will be done from a lookup table
 ; or by invoking the wavelength solution, but for now we just do it using a 
 ; cut on the image pixels itself: values > thresh * median value are considered
 ; to be the spectra. 
 sz = size(image)
 mask = bytarr(sz[1],sz[2])

 if strlowcase(method) eq 'threshhold' then begin
	 ; So: divide the image up into a number of chunks and apply the median threshhold
	 ; separately to each chunk. This is done to accomodate any variations in
	 ; average intensity across the FOV which would otherwise prevent a single
	 ; median value for being appropriate for the whole image. 


	; was 4x4, let's try a finer local region because of variation in the background
	; level. 
	chunkx = 8
	chunky = 8
	for ix=0L,chunkx-1 do begin
	for iy=0L,chunky-1 do begin
		dx = sz[1]/chunkx
		dy = sz[2]/chunky
		image_part = image[ix*dx:(ix+1)*dx-1, iy*dy:(iy+1)*dy-1]

		med = median(image_part)
		mask[ix*dx:(ix+1)*dx-1, iy*dy:(iy+1)*dy-1] = $
			image[ix*dx:(ix+1)*dx-1, iy*dy:(iy+1)*dy-1] gt 2*med

	endfor 
	endfor 

	 
	 ; now expand the mask by 1 pixel in all directions to grab things close to
	 ; the edges of the spectra. 1 pixel was chosen based on visual examination of
	 ; how well the final mask works, and is also plausible based on the existence
	 ; of interpixel capacitance that affects adjacent pixels at a ~few percent
	 ; level. 

		kernel = [[0,1,0],[1,1,1],[0,1,0]]  ; This appears to work pretty well based on visual examination of the masked region
		mask = dilate(mask, kernel)

		backbone->Log, "Identified "+strc(total(~mask))+" pixels for use as background pixels"
	endif else begin ;======= use calibration file to determine the regions to use. =====
		;stop
  		;mode=SXPAR( header, 'PRISM', count=c)
		mode = gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', count=c))
		filter= gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=c))
		case strupcase(strc(mode)) of
	  	'PRISM':		begin
			; load mask from spectral calib file
			; The following code is lifted directly from extractcube.
		  ;;get length of spectrum
            sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)
            if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')

			tilt=wavcal[*,*,4]

			for i=0,sdpx-1 do begin  ;through spaxels
				;get the locations on the image where intensities will be extracted:
				x3=xmini-i
				y3=wavcal[*,*,1]+(wavcal[*,*,0]-x3)*tan(tilt[*,*])	
				;extract intensities on a 3x1 box:
				; instead of extracting pixels, mask out those pixels.
				mask[y3,x3] = 1
				mask[y3+1,x3] = 1
				mask[y3-1,x3] = 1
			endfor

	  

	  	end
	  	'WOLLASTON':	begin
		; load mask from polarimetr cal file
		stop

	  	end
	  	'OPEN':	return, error ('FAILURE ('+functionName+'): method=calfile not implemented for prism='+mode)
	  	else: return, error ('FAILURE ('+functionName+'): method=calfile not implemented for prism='+mode)
	  	endcase

	endelse

 ; Now we want to fill in the regions that are masked out. Ideally we would do
 ; this with a convolution, but you can't meaningfully convolve an image full of
 ; NaNs. So let's fill them in with a median first (gets rid of NaNs but does a
 ; mediocre job at image fidelity) and then iteratively repeat convolution to
 ; get it to converge. 
 
 backbone->Log, 'Masking out pixels and replacing with medians.'
 masked_im = image
 masked_im[where(mask)] = !values.f_nan
stop 
 iters = fltarr(sz[1],sz[2], niter)
 ; get rid of any remaining NaNs just to be sure:
 tmp0 = median(masked_im, mediansize) 
 backbone->Log, 'Cleaning up remaining NANs.'
 fixpix, tmp0  ,0,tmp,/nan
 iters[*,*,0] = temporary(tmp)
 for n=1,niter-1 do begin
	 print, "Convolving, iteration "+strc(n)
 	iters[where(~ mask) + n_elements(image)*(n-1)] = image[where(~ mask)]
 	iters[*,*,n] = filter_image(iters[*,*,n-1], fwhm=[fwhm_x,fwhm_y],/all)
 	;(iters[*,*,n])[where(not mask)]= image[where(not mask)]


 
 endfor


 subtracted = image-iters[*,*,niter-1]
 

 ; show comparison in ATV? 
 if keyword_set(before_and_after) then begin
	atv, [[[image]],[[subtracted]],[[masked_im]], [[iters[*,*,niter-1]]]],/bl, $
		names = ['Input image','Post Subtraction', 'Masked to background pixels only', 'Background Model'], /linear,min=0,max=150
 endif 

 ; show comparison in window?
 if keyword_set(before_and_after) then begin
	window,0,xsize=1200,ysize=400
	erase
	mx=1100
	my=1300
	cgimage, bytscl( [image[mx:my,mx:my], masked_im[mx:my,mx:my], iters[mx:my,mx:my, niter-1], subtracted[mx:my,mx:my]],0,150),/keep
	xyouts, 0.05, 0.95, 'Input (subregion)'
	xyouts, 0.3, 0.95, 'Masked'
	xyouts, 0.6, 0.95, 'Model'
	xyouts, 0.8, 0.95, 'Subtracted'
 endif


 *(dataset.currframe[0]) = subtracted
  ;sxaddhist, "Subtracted 2D image background estimated from pixels between spectra", *(dataset.headersPHU[numfile])
  backbone->set_keyword, "HISTORY", "Subtracted 2D image background estimated from pixels between spectra",ext_num=0
  suffix='-bgsub2d'

  logstr = 'After background model sub, stddev of background pixels: '+strc(stddev(subtracted[where(~mask)]))
  ;sxaddhist, logstr, *(dataset.headersPHU[numfile])
  backbone->set_keyword, "HISTORY", logstr,ext_num=0
  backbone->Log, logstr




@__end_primitive
end

