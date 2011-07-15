;+
; NAME: subtract_background_2d
; PIPELINE PRIMITIVE DESCRIPTION: Subtract background from 2D raw image
;
;   Subtract the (possibly fluctuating) background from a 2D raw IFS
;   image, by using the regions in between the spectra. 
;
;   **currently a developmental/testing routine**
;
;   T
;
; KEYWORDS:
; 	gpitv=		session number for the GPITV window to display in.
; 				set to '0' for no display, or >=1 for a display.
;
; OUTPUTS:
;
; PIPELINE ARGUMENT: Name="thresh" Type="float" Range="[0,5]" Default="2" Desc="What multiple of the image median should be used as the threshhold for selecting spectra?"
; PIPELINE ARGUMENT: Name="fwhm_x" Type="float" Range="[0,10]" Default="1" Desc="FWHM of the Gaussian for smoothing the background, in the X direction"
; PIPELINE ARGUMENT: Name="fwhm_y" Type="float" Range="[0,10]" Default="7" Desc="FWHM of the Gaussian for smoothing the background, in the Y direction"
; PIPELINE ARGUMENT: Name="niter" Type="int" Range="[0,10]" Default="3" Desc="How many times to iterate the convolution fill towards convergence?"
; PIPELINE ARGUMENT: Name="before_and_after" Type="int" Range="[0,1]" Default="0" Desc="Show the before-and-after images for the user to see?"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="1" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
; PIPELINE COMMENT:  Subtract 2D background based on the regions in between the spectra
; PIPELINE ORDER: 1.12 
; PIPELINE TYPE: ALL HIDDEN
;
;
; HISTORY:
; 	Originally by Marshall Perrin, 2011-07-15
;-
function subtract_background_2d, DataSet, Modules, Backbone
primitive_version= '$Id: displayrawimage.pro 417 2011-07-14 14:13:04Z perrin $' ; get version from subversion to store in header history
@__start_primitive

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
 

 ; So: divide the image up into a number of chunks and apply the median threshhold
 ; separately to each chunk. This is done to accomodate any variations in
 ; average intensity across the FOV which would otherwise prevent a single
 ; median value for being appropriate for the whole image. 

sz = size(image)
mask = bytarr(sz[1],sz[2])


chunkx = 4
chunky = 4
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

 ; Now we want to fill in the regions that are masked out. Ideally we would do
 ; this with a convolution, but you can't meaningfully convolve an image full of
 ; NaNs. So let's fill them in with a median first (gets rid of NaNs but does a
 ; mediocre job at image fidelity) and then iteratively repeat convolution to
 ; get it to converge. 
 
 masked_im = image
 masked_im[where(mask)] = !values.f_nan
 
 iters = fltarr(sz[1],sz[2], niter)
 iters[*,*,0] = fixnans(median(masked_im, mediansize))
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
 if keyword_set(before_and_after)
	window,0,xsize=1200,ysize=400
	erase
	mx=1100
	my=1300
	tvimage, bytscl( [image[mx:my,mx:my], masked_im[mx:my,mx:my], iters[mx:my,mx:my, niter-1], subtracted[mx:my,mx:my]],0,150),/keep
	xyouts, 0.05, 0.95, 'Input (subregion)'
	xyouts, 0.3, 0.95, 'Masked'
	xyouts, 0.6, 0.95, 'Model'
	xyouts, 0.8, 0.95, 'Subtracted'
 endif


 *(dataset.currframe[0]) = subtracted
  sxaddhist, "Subtracted 2D image background estimated from pixels between spectra", *(dataset.headers[numfile])
  suffix='-bgsub2d'

  logstr = 'After background model sub, stddev of background pixels: '+strc(stddev(subtracted[where(~mask)]))
  sxaddhist, logstr, *(dataset.headers[numfile])
  backbone->Log, logstr




@__end_primitive
end

