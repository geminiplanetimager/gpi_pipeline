;+
; NAME: gpi_expand_path
;
; 	Utility function for expanding paths:
; 	 - expands ~ and ~username on Unix/Mac boxes
; 	 - expands environment variables in general.
; 	 - convert path separators to correct one of / or \ for current operating
; 	   system.
;
; 	See also: gpi_shorten_path.pro
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
; 	2011-08-01 MP: Algorithm fix to allow environment variables to be written
; 		as either $THIS, $(THIS), or ${THIS} and it will work in all cases.
;	2012-08-22 MP: Updated to work with new directory names set in ways other
;		than just environment variables (though those work still too)
;-


FUNCTION gpi_expand_path, inputpath, vars_expanded=vars_expanded, recursion=recursion

if N_elements(inputpath) EQ 0 then return,''
if size(inputpath,/TNAME) ne 'STRING' then return,inputpath

; Check for environment variables
;  match any string starting with a $ and optionally enclosed in ()s or {}s
res = stregex(inputpath, '\$(([a-zA-Z_]+)|(\([a-zA-Z_]+\))|(\{[a-zA-Z_]+\}))', length=length)

if res ge 0 then begin
	varname = strmid(inputpath,res+1,length-1)
	;print, varname, length, res
	first_char = strmid(varname,0,1)
	if first_char eq '(' or first_char eq '{' then varname=strmid(varname,1,length-3)
	;print, varname, length
	if ~(keyword_set(vars_expanded)) or ~(keyword_set(recursion)) then vars_expanded = [varname] else vars_expanded =[vars_expanded,varname]
	;print, varname, "|", getenv(varname)
	expanded = strmid(inputpath,0,res)+ gpi_get_directory(varname)+ strmid(inputpath,res+length)
	;print, expanded
	return, gpi_expand_path(expanded, vars_expanded=vars_expanded,/recursion) ; Recursion!
endif

; swap path delimiters as needed
; is it ok for Mac? -JM
; Yes, macs are unix for these purposes. -MP
case !version.os_family of
   'unix': inputpath = strepex(inputpath,'\\','/',/all)
   'Windows': inputpath = strepex(inputpath,'/','\\',/all)
endcase

; clean up any double delimiters
inputpath = strepex(inputpath, path_sep()+path_sep(), path_sep(), /all)

return, expand_tilde(inputpath) ; final step: clean up tildes. 

 

end
