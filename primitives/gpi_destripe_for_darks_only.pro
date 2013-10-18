;+
; NAME: gpi_destripe_for_darks_only
; PIPELINE PRIMITIVE DESCRIPTION: Destripe for Darks Only
;
; 	Correct for fluctuations in the background bias level
; 	(i.e. horizontal stripes in	the raw data) using a pixel-by-pixel 
; 	median across all channels, taking into account the alternating readout
; 	directions for every other channel. 
;
; 	This provides a very high level of rejection for stripe noise, but of course
; 	it assumes that there's no signal anywhere in your image. So it's only
; 	good for darks. 
;
;
;   A second noise source that can be removed by this routine is the 
;   so-called microphonics noise induced by high frequency vibrational modes of
;   the H2RG. This noise has a characteristic frequenct both temporally and 
;   spatially, which lends itself to removal via Fourier filtering. After
;   destriping, the image is Fourier transformed, masked to select only the
;   Fourier frequencies of interest, and transformed back to yield a model for
;   the microphonics striping that can be subtracted from the data. Empirically
;   this correction works quite well. Set the "remove_microphonics" option to
;   enable this, and set "display" to show on screen a
;   diagnostic plot that lets you see the stripe & microphonics removal in
;   action.
;
; SEE ALSO: Destripe science frame
;
; INPUTS: A 2D dark image 
;
; OUTPUTS: 2D image corrected for stripe noise
;
; PIPELINE COMMENT: Subtract readout pickup noise using median across all channels. This is an aggressive destriping algorithm suitable only for use on images that have no light. Also includes microphonics noise removal.
; PIPELINE ARGUMENT: Name="remove_microphonics" Type="string" Range="[yes|no]" Default="yes" Desc='Attempt to remove microphonics noise via Fourier filtering?'
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[-1,100]" Default="-1" Desc="-1 = No display; 0 = New (unused) window else = Window number to display diagonostics in."
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display " 
; PIPELINE ORDER: 1.3
; PIPELINE NEWTYPE: Calibration
; PIPELINE TYPE: CAL-SPEC

; HISTORY:
;   2012-10-16 Patrick: fixed syntax error (function name)
;   2012-10-13 MP: Started
;   2013-01-16 MP: Documentation cleanup
;   2012-03-13 MP: Added Fourier filtering to remove microphonics noise
;   2013-04-25 MP: Improved documentation, display for microphonics removal.
;-
function gpi_destripe_for_darks_only, DataSet, Modules, Backbone
compile_opt defint32, strictarr, logical_predicate
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

 	if tag_exist( Modules[thisModuleIndex], "remove_microphonics") then remove_microphonics=Modules[thisModuleIndex].remove_microphonics else remove_microphonics='yes'
 	if tag_exist( Modules[thisModuleIndex], "display") then display=fix(Modules[thisModuleIndex].display) else display=-1

	im =  *(dataset.currframe[0])

	if display ne -1 then im0 = im ; save a copy of input image for later display
	sz = size(im)
    if sz[1] ne 2048 or sz[2] ne 2048 then begin
        backbone->Log, "REFPIX: Image is not 2048x2048, don't know how to destripe"
        return, NOT_OK
    endif


	backbone->Log, "Removing horizontal stripes based on median across channels.",depth=2
	; Chop the image into the 32 readout channels. 
	; Flip every other channel to account for the readout direction
	; alternating for the H2RG
	parts = transpose(reform(im, 64,32, 2048),[0,2,1])
 	for i=0,15 do parts[*,*,2*i+1] = reverse(parts[*,*,2*i+1]) 

	; Generate a median image from all 32 readout channels
	; TODO: outlier-rejected mean here? 
 	medpart = median(parts,dim=3)

	; Generate a model stripe image from that median, replicated for 
	; each of the 32 channels with appropriate flipping
	model = rebin(medpart, 64,2048,32)
 	for i=0,15 do model[*,*,2*i+1] = reverse(model[*,*,2*i+1]) 
	stripes = reform(transpose(model, [0,2,1]), 2048, 2048)	


    imout = im - stripes
	backbone->set_keyword, "HISTORY", "Destriped, using aggressive algorithm assuming no signal in image"
	backbone->set_keyword, "HISTORY", "This had better be a dark frame or else it's probably messed up now."

	if strlowcase(remove_microphonics) eq 'yes' then begin
		backbone->Log, "Fourier filtering to remove microphonics noise.",depth=2
		; first we want to mask out all the hot/cold pixels so they don't bias
		; the FFT below
		smoothed = median(imout,5)
		diffim = imout - smoothed
		sig = robust_sigma(diffim)
		wgood = where(abs(diffim) lt 3*sig)
		smoothed[wgood] = imout[wgood]

		; Now we use a FFT filter to generate a model of the microphonics noise

		fftim = fft(smoothed)
		fftmask = bytarr(2048,2048)
		fftmask[1004:1046, 1190:1210]  = 1  ; a box around the 3 peaks from the microphonics blobs,
											; as seen in an FFT array if 'flopped'
											; to be centered on the 0-freq component
		;fftmask[1004:1046, 1368:1378] = 1
		fftmask += reverse(fftmask, 2)
		fftmask = shift(fftmask,-1024,-1024) ; flop to line up with fftim

		microphonics_model = real_part(fft( fftim*fftmask,/inverse))

		; For some reason presumably explicable in Fourier space, the resulting
		; microphonics model often appears to have extra striping in the top rows
		; of the image. This leads to some *induced* extra striping there
		; when subtracted. Let's force the top rows to zero to avoid this. 
		microphonics_model[*, 1975:*] = 0

		if display ne -1 then im_destriped = imout ; save for use in display

		imout -= microphonics_model
		backbone->set_keyword, "HISTORY", "Microphonics noise removed via Fourier filtering."

	endif


	if display ne -1 then begin
		if display eq 0 then window,/free else select_window,display
		loadct, 0
		erase

		if strlowcase(remove_microphonics) eq 'yes' then begin
			; display for destriping and microphonics removal
			!p.multi=[0,4,1]
			mean_offset = mean(im0) - mean(imout)
			imdisp, im0 - mean_offset, /axis, range=[-10,30], title='Input Data', charsize=2
			imdisp, im_destriped, /axis, range=[-10,30], title='Destriped', charsize=2
			imdisp, microphonics_model, /axis, range=[-10,30],title="Microphonics model", charsize=2
			imdisp, imout, /axis, range=[-10,30], title="Destriped and de-microphonicsed", charsize=2
			xyouts, 0.5, 0.95, /normal, "Stripe & Microphonics Noise Removal for "+backbone->get_keyword('DATAFILE'), charsize=2, alignment=0.5
		endif else begin
			; display for just destriping
	 		if numfile eq 0 then window,0
			!p.multi=[0,3,1]
			mean_offset = mean(im0) - mean(imout)
			imdisp, im0-mean_offset, /axis, range=[-10,30], title='Input Data', charsize=2
			imdisp, stripes-mean_offset, /axis, range=[-10,30], title='Stripes Model', charsize=2
			imdisp, imout, /axis, range=[-10,30], title='Destriped Data', charsize=2
			xyouts, 0.5, 0.95, /normal, "Stripe Noise Removal for "+backbone->get_keyword('DATAFILE'), charsize=2, alignment=0.5
		endelse
	endif
   

	*(dataset.currframe[0]) = imout

suffix = 'destripe'
@__end_primitive
end
