;+
; NAME:  __End_primitive
;
; This file is meant to be included at the END of a GPI primitive via
; @__end_primitive
;
; This provides generic options common to essentially all primitives. 
;   save output to disk?
;   display in gpitv? (from disk or memory)
;   pause IDL here for debugging?
;
; HISTORY:
; 	Began 2010-04-08 19:30:34 by Marshall Perrin 
; 	2012-10-10 MP: Remove ability to set save_suffix in DRFs, this is useless
;				   and dangerous.
;-

	save_suffix=suffix
	
	if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
		; if we're saving the file, then we can invoke GPITV using that filename

      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, save_suffix, display=display)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
		; otherwise, any invocations of GPITV must pass the data set as a temp
		; file. 
		; FIXME this doesn't propagate headers
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then begin
          backbone_comm->gpitv, double(*DataSet.currFrame), session=fix(Modules[thisModuleIndex].gpitv), imname='Pipeline result from '+ Modules[thisModuleIndex].name
	  endif
    endelse

   	if tag_exist( Modules[thisModuleIndex], "stopidl") then if keyword_set( Modules[thisModuleIndex].stopidl) then stop

	return, ok


