;+
; NAME: gpi_update_prev_saved_header 
;
;	Update (replace) the FITS header of the most
;	recently saved file. This is useful for appending additional 
;	metadata to the file you've just saved.  
;
;	This is used in partnership with gpi_get_prev_saved_header
;		
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;	Began 2014-11-08 by Marshall Perrin, following skype discussion with Patrick
;	and Dmitry
;-

pro gpi_update_prev_saved_header, newheader, ext_num=ext

    COMMON APP_CONSTANTS
    COMMON PIP

	if ~(keyword_set(ext)) then ext=0
	last_saved_file = backbone_comm->get_last_saved_file()

	sxaddhist, "Updated FITS header to add more information, after its initial save.", newheader
	modfits, last_saved_file, 0, newheader, exten_no=ext

	backbone_comm->Log, "Updated FITS header of "+last_saved_file+" to add more information, after its initial save.", depth=3

end
