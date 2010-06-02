;+
; NAME:  __End_primitive
;
; This file is meant to be included at the END of a GPI primitive via
; @__end_primitive
;
; HISTORY:
; 	Began 2010-04-08 19:30:34 by Marshall Perrin 
;-

; Normally, the save suffix is either determined by 
;   a) the suffix variable in the common block, as carried over from previous
;   modules
;   b) being set explicitly in this module. 
;
; But the user can (optionally) override by setting the suffix= keyword in the
; DRF.

; So check for a suffix keyword, and use it *if present*, without overriding whatever is in the current
; common block suffix variable. 
	save_suffix=suffix
	if tag_exist( Modules[thisModuleIndex], "suffix") then if strc(Modules[thisModuleIndex].suffix) ne "" then save_suffix = string(Modules[thisModuleIndex].suffix)


	; Options: save (and possibly display from disk) the file, or display from memory, and/or pause IDL here
   if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, save_suffix, display=display)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then begin
          backbone_comm->gpitv, double(*DataSet.currFrame), session=fix(Modules[thisModuleIndex].gpitv)

	  endif
    endelse

   	if tag_exist( Modules[thisModuleIndex], "stopidl") then if keyword_set( Modules[thisModuleIndex].stopidl) then stop

	return, ok


