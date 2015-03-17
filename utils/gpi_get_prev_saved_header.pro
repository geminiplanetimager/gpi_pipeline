;+
; NAME: gpi_get_prev_saved_header 
;
;	Get (read) the FITS header of the most
;	recently saved file. This is useful for appending additional 
;	metadata to the file you've just saved.  
;
;	This is used in partnership with gpi_update_prev_saved_header
;
; INPUTS:
; KEYWORDS:
;
; OUTPUTS:
;	status		Indicates whether this worked or not. 
;
; HISTORY:
;	Began 2014-11-08 by Marshall Perrin, following skype discussion with Patrick
;	and Dmitry
;-

function gpi_get_prev_saved_header, newheader, ext_num=ext, status=status

    COMMON APP_CONSTANTS
    COMMON PIP

	status=NOT_OK

	if ~(keyword_set(ext)) then ext=0
	last_saved_file = backbone_comm->get_last_saved_file()

	if (strc(last_saved_file) eq '') or ~file_test(last_saved_file) then begin
		status=NOT_OK
		return, ""
	endif

	oldheader = headfits(last_saved_file, ext=ext)

	status=OK
	return, oldheader


end

