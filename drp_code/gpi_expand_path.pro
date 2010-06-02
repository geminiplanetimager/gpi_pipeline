;+
; NAME: gpi_expand_path
;
; 	Utility function for expanding paths:
; 	 - expands ~ and ~username on Unix/Mac boxes
; 	 - expands environment variables in general.
; 	 - convert path separators to correct one of / or \ for current operating
; 	   system.
;
; USAGE:
;    fullpath = gpi_expand_path( "$GPI_DATA_ROOT/dir/filename.fits")
;
; INPUTS:
; 	inputpath	some string
; OUTPUTS:
; 	returns the path with the variables expanded
;
; OUTPUT KEYWORD:
; 	vars_expanded	returns a list of the variables expanded. 
;
;
; NOTE:
; 	There is also a 'recursion' keyword. This is used internally by the function
; 	to expand multiple variables, and should never be set directly by a user.
;
; HISTORY:
; 	Began 2010-01-13 17:01:07 by Marshall Perrin 
; 	2010-01-22: Added vars_expanded, some debugging & testing to verify. MP
;-


FUNCTION gpi_expand_path, inputpath, vars_expanded=vars_expanded, recursion=recursion

if N_elements(inputpath) EQ 0 then return,''
if size(inputpath,/TNAME) ne 'STRING' then return,inputpath

; Check for environment variables
res = stregex(inputpath, '\$([a-zA-Z_]+)', length=length)

if res ge 0 then begin
	varname = strmid(inputpath,res+1,length-1)
	if ~(keyword_set(vars_expanded)) or ~(keyword_set(recursion)) then vars_expanded = [varname] else vars_expanded =[vars_expanded,varname]
	;print, varname, "|", getenv(varname)
	expanded = strmid(inputpath,0,res)+ getenv(varname)+ strmid(inputpath,res+length)
	;print, expanded
	return, gpi_expand_path(expanded, vars_expanded=vars_expanded,/recursion) ; Recursion!
endif

; swap path delimiters as needed
; is it ok for Mac?
case !version.os_family of
'unix': inputpath = strepex(inputpath,'\\','/',/all)
'Windows': inputpath = strepex(inputpath,'/','\\',/all)
endcase

return, expand_tilde(inputpath) ; final step: clean up tildes. 

 

end
