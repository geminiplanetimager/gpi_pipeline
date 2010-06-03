;+
; NAME:  accumulate_getimage
; PIPELINE PRIMITIVE DESCRIPTION: Return one of the images saved by Accumulate_Images
;		
;		Return one of the images saved by Accumulate_Images.pro
;
;		To be used as an accessor routine inside any primitive that 
;		combines multiple files from the accumulator.
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; PIPELINE COMMENT: Return one of the images saved by Accumulate_Images
; HISTORY:
; 	Began 2009-07-22 17:12:00 by Marshall Perrin 
;-


FUNCTION accumulate_getimage, dataset, index, hdr
	common PIP
	common APP_CONSTANTS

	; Option 1: Nothing has been accumulated in position N. 
	; In that case, read in the input file of that filename
	
	case size( *(dataset.frames[index])   ,/TNAME ) of
	'UNDEFINED': begin
		; image was never read in the first place. 
		image = readfits( dataset.inputdir + path_sep() + *(dataset.filenames[index]), hdr,/silent)
		return, image
	end

	; Option 2:  image was stored on disk, so read it in and return it
	"STRING": begin
		image = readfits(  *(dataset.frames[index]), hdr,/silent)
		return, image
	end

	; Option 3: image was kept in memory so just hand that back.
	else :begin
		hdr = *(dataset.headers[index])
		return, *(dataset.frames[index])
	end
	endcase

end
