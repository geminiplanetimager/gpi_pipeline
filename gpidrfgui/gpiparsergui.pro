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
;   2011-01-17: JM, new keywords for controlling the parser using automaticproc__define
;-

function gpiparsergui, filenames, _extra=_extra, cleanlist=cleanlist, mode=mode ;drfname=drfname,  ;,groupleader,group,proj

	common GPI_PARSER_GUI, parserobj

	if ~obj_valid(parserobj) then parserobj = obj_new('parsergui', _extra=_Extra)
	if obj_valid(parserobj) and keyword_set(cleanlist) then parserobj->cleanfilelist
	if obj_valid(parserobj) and keyword_set(filenames) and ~keyword_set(mode) then parserobj->AddFile, filenames
  if obj_valid(parserobj) and keyword_set(filenames) and keyword_set(mode) then begin
      case mode of 
      1:begin
        parserobj->cleanfilelist
        parserobj->AddFile, filenames
        end
      2:begin
        parserobj->AddFile, filenames, mode=2
      end
      3:parserobj->AddFile, filenames
      else:parserobj->AddFile, filenames
      endcase
  endif    
  return, parserobj
end
