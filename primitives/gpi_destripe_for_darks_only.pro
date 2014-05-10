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
; PIPELINE ORDER: 1.35
; PIPELINE CATEGORY: Calibration

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

  im =  *(dataset.currframe)

  if display ne -1 then im0 = im ; save a copy of input image for later display
  sz = size(im)
  if sz[1] ne 2048 or sz[2] ne 2048 then begin
	 return, error('FAILURE ('+functionName+"): Image is not 2048x2048, don't know how to destripe")
  endif


  ;---- Part one: Measure stripes as medians across pixels read out simultaneously across
  ;     the 32 readout channels. This allows for an excellent removal of readout
  ;     noise, under the assumption that there isn't any actual signal in the
  ;     image at all. 
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


  ;---- Part two: From the model of the striping that we dervied above, remove the
  ;     overall median, so as to leave unchanged the total bias of the dark
  ;     frame. This ensures that when it is subtracted from a science image, the
  ;     resulting background count level should end up near zero.
  ;
  ;     When doing this, pay special attention to the bottom of the detector
  ;     where there is a roll-off to negative counts of the background, particularly 
  ;     at short exposures. THis is due to the 'reset anomaly' effect in H2RGs,
  ;     where the first read of any UTR series is biased downwards for the first
  ;     tens of milliseconds as the array recovers from having done the reset. 
  ;     Empirically this shows up in the lowest 100 rows or so, so we fit a
  ;     simple polynomial model there so that the destriping doesn't remove this
  ;     effect from the dark background. This allows the darks to better
  ;     subtract off this curvature. 
  ;
  ;     Note that all of this care here is less important in cases where we are
  ;     going to destripe the science data itself, since that destriping will
  ;     just remove the bias level to zero and take out the curvature at the
  ;     bottom from reset anomaly. But we want to treat this carefully to handle 
  ;     cases where we are not destriping the science frames. 


  ; Empirically we want to smooth out the stripes pattern overall to leave the 
  ; medians relatively untouched, but allow higher frequency curvature near the
  ; bottom of the detector due to the reset anomaly curvature observed there
  ; particularly at short exposures
  stripes2 = stripes

  rowmeds = (median(stripes,dim=1))[4:2043]		; concentrate on the photosensitive pixels only

  res = poly_fit(findgen(200),rowmeds[0:199],3)	; Fit a polynomial to the curved part

  backgndlevel = fltarr(2040)
  backgndlevel[0:100] = poly(findgen(101), res)	; And subtract it
  backgndlevel[101:*] = median(stripes[101:*])	; Remove a flat median from everything else. 
  ; enforce continuity between the curved and flat parts
  step = backgndlevel[100]-backgndlevel[101]
  backgndlevel[0:100]-=step

  ;stripes2[*,4:2043] -= rebin(transpose(backgndlevel), 2048, 2040)

  ; Now let's convert this back to a 2D array
  backgndlevel2 = fltarr(2048)					; Make a padded version 
  backgndlevel2[4:2043] = backgndlevel	
  backgndlevel2[0:3] = mean(backgndlevel[0:3])	; extrapolate to fill in plausible values for the ref pixels (this is mostly cosmetic)
  backgndlevel2[2044:2047] = mean(backgndlevel[2036:2039])
  stripes2 -= rebin(transpose(backgndlevel2), 2048, 2048)

  stripes=stripes2

  ;---- Part three: Subtract the stripes model and save history

  imout = im - stripes
  backbone->set_keyword, "HISTORY", "   Destriped, using aggressive algorithm assuming no signal in image"
  backbone->set_keyword, "HISTORY", "   This had better be a dark frame or else it's probably messed up now."

  ;---- Part four: Remove microphonics (optional)
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


	;	 ; The following is the older, original version
	;	 ; using all 2048x^2 pixels - But it works ***slightly*** better
	;	 ; to use just the photosensitive 2040^2 as in the following code
	;
	;     fftim = fft(smoothed)
	;     fftmask = bytarr(2048,2048)
	;     fftmask[1004:1046, 1190:1210]  = 1 ; a box around the 3 peaks from the microphonics blobs,
	;     fftmask += reverse(fftmask, 2)
	;     fftmask = shift(fftmask,-1020,-1020) ; flop to line up with fftim
	;     microphonics_model1 = real_part(fft( fftim*fftmask,/inverse))
	;     microphonics_model1[*, 1975:*] = 0
	;     clean1 = imout - microphonics_model1



								; Only do this on the photosensitive pixels; the
								; effect of microphonics is different on the ref
								; pix.
     fftim = fft(smoothed[4:2043, 4:2043])
     fftmask = bytarr(2040,2040)
     fftmask[1000:1042, 1186:1206]  = 1 ; a box around the 3 peaks from the microphonics blobs,
										; as seen in an FFT array if 'flopped'
										; to be centered on the 0-freq component
     fftmask += reverse(fftmask, 2)
     fftmask = shift(fftmask,-1020,-1020) ; flop to line up with fftim

     microphonics_model = real_part(fft( fftim*fftmask,/inverse))

                                ; For some reason presumably explicable in Fourier space, the resulting
                                ; microphonics model often appears to have extra striping in the top rows
                                ; of the image. This leads to some *induced* extra striping there
                                ; when subtracted. Let's force the top rows to zero to avoid this. 
     microphonics_model[*, 1975:*] = 0

     if display ne -1 then im_destriped = imout ; save for use in display

     clean2 = imout
	 clean2[4:2043,4:2043] -= microphonics_model
	 imout = clean2
     backbone->set_keyword, "HISTORY", "   Microphonics noise removed via Fourier filtering."

  endif

  ;---- Part 5: Display (optional of course)
  if display ne -1 then begin
     if display eq 0 then window,/free else select_window,display
     loadct, 0
     erase

	 immedian = median(im0)
	 disprange = [immedian-10,immedian+30]
     if strlowcase(remove_microphonics) eq 'yes' then begin
                                ; display for destriping and microphonics removal
        !p.multi=[0,5,1]
        ;mean_offset = mean(im0) - mean(imout)
        imdisp, im0 , /axis, range=disprange, title='Input Data', charsize=2
        imdisp, stripes, /axis, range=[-10,30], title='Stripes Model', charsize=2
        imdisp, im_destriped, /axis, range=disprange, title='Destriped', charsize=2
        imdisp, microphonics_model, /axis, range=[-10,30],title="Microphonics model", charsize=2
        imdisp, imout, /axis, range=disprange, title="Destriped and de-microphonicsed", charsize=2
        xyouts, 0.5, 0.95, /normal, "Stripe & Microphonics Noise Removal for "+strc( dataset.filenames[numfile]), charsize=2, alignment=0.5
     endif else begin
                                ; display for just destriping
        if numfile eq 0 then window,0
        !p.multi=[0,3,1]
        ;mean_offset = mean(im0) - mean(imout)
        imdisp, im0, /axis, range=disprange, title='Input Data', charsize=2
        imdisp, stripes, /axis, range=[-10,30], title='Stripes Model', charsize=2
        imdisp, imout, /axis, range=disprange, title='Destriped Data', charsize=2
        xyouts, 0.5, 0.95, /normal, "Stripe & Microphonics Noise Removal for "+strc( dataset.filenames[numfile]), charsize=2, alignment=0.5
     endelse
     !P.MULTI = 0
  endif
  

  ;---- and now we're done.
  *(dataset.currframe) = imout

  suffix = 'destripe'
@__end_primitive
end
