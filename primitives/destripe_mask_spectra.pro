;+
; NAME: mask_spectra
; PIPELINE PRIMITIVE DESCRIPTION: Destripe by Masking Spectra
;
;		This routine generates a mask image for a 2D image, showing which
;		pixels will be used for extracting a cube, and then uses it to
;		generate a model of the readout noise stripes measured in that
;		background region, and subtracts that model from the image to
;		remove the correlated noise stripes. 
;
;		NOT TESTED PROBABLY DOES NOT WORK YET USE AT YOUR OWN RISK!
;
;		You probably want to still use applyrefpix prior to calling this?
;		TBD via experimentation...
;
; KEYWORDS: 
; GEM/GPI KEYWORDS:IFSFILT
; OUTPUTS:
;
; PIPELINE COMMENT: Mask out the areas used for spectra, and use the residual in between areas to destripe. 
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: SpectralScience
;
; HISTORY:
;   2012-10-11 MP: Created, based on extractcube
;+
function destripe_mask_spectra, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive


  	sz  = size(*(dataset.currframe[0]))
    if sz[1] ne 2048 or sz[2] ne 2048 then begin
        backbone->Log, "REFPIX: Image is not 2048x2048, don't know how to destripe"
        return, NOT_OK
    endif


	mode=gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', count=c))



  	case strupcase(strc(mode)) of
	'PRISM': begin

		  ;====== Generate the mask of where the spectra are ======
		  ;get the 2D detector image size
			sz  = size(*(dataset.currframe[0]))
					
		  ;define the common wavelength vector with the IFSFILT keyword:
		  filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
		  
		  ;error handle if IFSFILT keyword not found
		  if (filter eq '') then $
			 return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 

		  ;get length of spectrum
		  sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)
		  if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')
		  
		  ;get tilts of the spectra included in the wavelength solution:
		  tilt=wavcal[*,*,4]


		  mask = bytarr(sz[1], sz[2])

		  for i=0,sdpx-1 do begin       
			 ;get the locations on the image where intensities will be extracted:
			 x3=xmini-i
			 y3=wavcal[*,*,1]+(wavcal[*,*,0]-x3)*tan(tilt[*,*])	
		  
			 ; mask out area assuming a 3x1 moving box
			 mask[y3,x3] = 1
			 mask[y3+1,x3] = 1
			 mask[y3-1,x3] = 1
			 
		  endfor
		end
	'WOLLASTON': begin
		message,'Not yet implemented'
		stop

		end
	'OPEN': begin
		message,'Not yet implemented'
		stop
		end
	endcase


  ;====== Also mask out the reference pixels ======
  ; we don't use them here to measure the on-detector background stripes,
  ; because they will likely have an offset with respect to the mean counts of
  ; the image, and thus will bias the median. So, you should probably also use
  ; applyrefpix first if you're going to use this. 
  mask[0:3,*] = 1
  mask[2044:2047, *] = 1
  mask[*,0:3] = 1
  mask[*,2044:2047] = 1


  ;====== Generate a copy of the data with that area masked out ======

  masked_data = *(dataset.currframe[0])

  masked_data(where(mask)) = !values.f_nan

  ; what to do about areas in the wings of the channels?
  ; maybe have some max threshhold in terms of allowable counts
  ; say 5 sigma based on measured readnoise in the ref pix area?
  ; or perhaps we can subtract off some very wide area median?


  atv, [[[*(dataset.currframe[0])]],[[masked_data]]],/bl
  stop

  ; now we want to compute the median across all channels,
  ; taking into account the flipped readout pattern of every other channel

  parts = transpose(reform(masked_data, 64,32, 2048),[0,2,1])
  for i=0,15 do parts[*,*,2*i+1] = reverse(parts[*,*,2*i+1]) 
  medpart = median(parts,dim=3)

 ; fix any remaining nans in the median array
 ; by interpolating across them I guess?
 ; linear interpolation across each row of the array? 
 ;
  stop

  ; generate a new 2D image based on the derived model

	model = rebin(medpart, 64,2048,32)
 	for i=0,15 do model[*,*,2*i+1] = reverse(model[*,*,2*i+1]) 
	model = reform(transpose(model, [0,2,1]), 2048, 2048)

	; subtract to apply the correction
  	corrected= *(dataset.currframe[0]) - model
  	atv, [[[*(dataset.currframe[0])]],[[model]],[[corrected]]],/bl

  	stop
	before_and_after=0
	if keyword_set(before_and_after) then begin
		atv, [[[im]],[[stripes]],[[imout]]],/bl, names=['Input image','Stripe Model', 'Subtracted']
		stop
	endif


 	*(dataset.currframe[0]) = corrected

suffix = 'destripe'
@__end_primitive

end

