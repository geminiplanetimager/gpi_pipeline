;+
; NAME: gpi_expand_path
;
; 	Utility function for expanding paths:
; 	 - expands ~ and ~username on Unix/Mac boxes
; 	 - expands environment variables in general.
;
; USAGE:
;    fullpath = gpi_expand_path( "$GPI_DATA_ROOT/dir/filename.fits")
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2010-01-13 17:01:07 by Marshall Perrin 
;-


FUNCTION gpi_expand_path, inputpath

if N_elements(inputpath) EQ 0 then return,''
if size(inputpath,/TNAME) ne 'STRING' then return,inputpath

; Check for environment variables
res = stregex(inputpath, '\$([a-zA-Z_]+)', length=length)

if res ge 0 then begin
	varname = strmid(inputpath,res+1,length-1)
	;print, varname, "|", getenv(varname)
	expanded = strmid(inputpath,0,res)+ getenv(varname)+ strmid(inputpath,res+length)
	;print, expanded
	return, gpi_expand_path(expanded) ; Recursion!
endif

return, expand_tilde(inputpath) ; final step: clean up tildes. 

 

end
