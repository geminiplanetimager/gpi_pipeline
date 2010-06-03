;+
;
; NAME:
;	COMDIM2
;
; PURPOSE:
;	Collapse degenerate dimensions of an array.
;
; CATEGORY:
;	GEN
;
; CALLING SEQUENCE:
;	Result = COMDIM(Array)
;
; INPUTS:
;       Array:	Array to be collapsed.
;
; OUTPUTS:
;       Result:	Reformed array.
;
; RESTRICTIONS:
;       Use Version 2 function Reform to make Version 1 code compatible.
;
; MODIFICATION HISTORY:
;       Mod. 05/06/96 by RCJ. Added formal documentation.
;       Mod. 16-Sep-01, Zarro (EITI/GSFC) - collapse single element array to
;       scalar, e.g, a[1] -> a
;-
;
function comdim2,a
if n_elements(a) eq 0 then return,-1
sz=size(a)
if sz(0) eq 0 then return,a
temp_array=reform(a) 
sz=size(temp_array)
if (sz(0) eq 1) and (sz(1) eq 1) then temp_array=temp_array(0)
return,temp_array
end
