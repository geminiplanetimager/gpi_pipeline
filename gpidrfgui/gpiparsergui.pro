;+
; NAME:  gpiparsergui
;
; 	Wrapper interface to Parser GUI object
;
; INPUTS:
; 	filenames		filenames to load into the GUI
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2010-04-16 14:23:25 by Marshall Perrin 
;-

pro gpiparsergui, filenames, _extra=_extra ;drfname=drfname,  ;,groupleader,group,proj

	common GPI_PARSER_GUI, parserobj

	if ~obj_valid(parserobj) then parserobj = obj_new('parsergui', _extra=_Extra)
	if obj_valid(parserobj) and keyword_set(filenames) then parserobj->AddFile, filenames

end
