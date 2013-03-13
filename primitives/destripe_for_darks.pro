;+
; NAME: Destripe for Darks Only
; PIPELINE PRIMITIVE DESCRIPTION: Aggressive destripe assuming there is no signal in the image. (for darks only)
;
; 	Correct for fluctuations in the bias/dark level using a pixel-by-pixel 
; 	median across all channels, taking into account the alternating readout
; 	directions for every other channel. 
;
; 	This provides a very high level of rejection for stripe noise, but of course
; 	it assumes that there's no signal anywhere in your image. So it's only
; 	good for darks. 
;
; SEE ALSO: Destripe science frame
;
; INPUTS: A 2D dark image 
;
; OUTPUTS: 2D image corrected for stripe noise
;
; PIPELINE COMMENT: Subtract readout pickup noise using median across all channels.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display " 
; PIPELINE ARGUMENT: Name="before_and_after" Type="int" Range="[0,1]" Default="0" Desc="Show the before-and-after images for the user to see? (for debugging/testing)"
; PIPELINE ARGUMENT: Name="remove_microphonics" Type="string" Range="[yes|no]" Default="yes" Desc='Attempt to remove microphonics noise via Fourier filtering?'
; PIPELINE ARGUMENT: Name="remove_microphonics_display" Type="string" Range="[yes|no]" Default="no" Desc='Show diagnostic plots if removing microphonics?'
; PIPELINE ORDER: 1.3
; PIPELINE NEWTYPE: ALL
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 3-
;
; HISTORY:
;   2012-10-16 Patrick: fixed syntax error (function name)
;   2012-10-13 MP: Started
;   2013-01-16 MP: Documentation cleanup
;-
function destripe_for_darks, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

 	if tag_exist( Modules[thisModuleIndex], "before_and_after") then before_and_after=fix(Modules[thisModuleIndex].before_and_after) else before_and_after=0
 	if tag_exist( Modules[thisModuleIndex], "remove_microphonics") then remove_microphonics=fix(Modules[thisModuleIndex].remove_microphonics) else remove_microphonics='yes'
 	if tag_exist( Modules[thisModuleIndex], "remove_microphonics_display") then remove_microphonics_display=fix(Modules[thisModuleIndex].remove_microphonics_display) else remove_microphonics_display='no'

	im =  *(dataset.currframe[0])

	sz = size(im)
    if sz[1] ne 2048 or sz[2] ne 2048 then begin
        backbone->Log, "REFPIX: Image is not 2048x2048, don't know how to destripe"
        return, NOT_OK
    endif


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
		backbone->Log, "Fourier filtering to remove microphonics noise."
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

		microphonics_model = real(fft( fftim*fftmask,/inverse))

		;atv, [[[imout]],[[smoothed]],[[imout-microphonics_model]]],/bl
		;stop

		if strlowcase(remove_microphonics_plots) eq 'yes' then begin
			if numfile eq 0 then window,0
			!p.multi=[0,3,1]
			imdisp, imout, /axis, range=[-10,40], title='Destriped', charsize=2
			imdisp, microphonics_model, /axis, range=[-10,40],title="Microphonics model", charsize=2
			imdisp, imout-microphonics_model, /axis, range=[-10,40], title="Destriped and de-microphonicsed", charsize=2
		endif

		imout -= microphonics_model
		backbone->set_keyword, "HISTORY", "Microphonics noise removed via Fourier filtering."

	endif

    


	before_and_after=0
	if keyword_set(before_and_after) then begin
		atv, [[[im]],[[stripes]],[[imout]]],/bl, names=['Input image','Stripe Model', 'Subtracted']
		stop
	endif

	*(dataset.currframe[0]) = imout

suffix = 'destripe'
@__end_primitive
end
