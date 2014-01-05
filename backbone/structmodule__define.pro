;+
; NAME:  structModule Definition
;
; 	No actual IDL code here, just a structure definition.
; 	Stored in its own file to be globally available. 
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Moved to its own file 2010-04-19 19:27:30 by Marshall Perrin 
;-

pro structModule__define
	compile_opt defint32, strictarr, logical_predicate

    void = {structModule, $
            Name:'', $
            IDLCommand:'', $
            Skip:0, $
            Save:0, $
            OutputDir:'', $			; For historical reasons this is replicated for each module/primitive but in practice will always have the same value for all primitives in a recipe
            CalibrationFile:'',$
			CalFileType: ''}

end
