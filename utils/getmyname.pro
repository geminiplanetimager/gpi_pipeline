;+
; FUNCTION: getmyname
;
; PURPOSE:
;		Returns the name and file path to the source code of the calling
;		procedure
;	NOTES:
;		In other words, if you're executing FOO from /some/path/foo.pro
;		then 
;			getmyname, name,path
;		sets name="FOO" and path="/some/path/foo.pro"
;		
; INPUTS:
; KEYWORDS:
; 	dir		outputs directory not including file name
; OUTPUTS:
; 	name	name of calling procedure
; 	path	path to file containing calling procedure
;
; HISTORY:
;   By Marshall Perrin, circa 2005 ish?
;
;-

PRO getmyname,name,path,dir=dir

help,call=call                                                                  
caller=call[1]  ; the thing which called this procedure

if caller eq "$MAIN$" then begin
	name="$MAIN$"
	path=""
	return
endif

; a typical line returned by help,call looks like:
;TMP </frosty/mperrin/idl/tmp.pro(   6)>

sp=strpos(caller," ")
paren=strpos(caller,"(")

name=strmid(caller,0,sp)
path=strmid(caller,sp+2,paren-sp-2)

progname = strlowcase(name)+".pro"
nameloc = strpos(caller,progname)



parts = strsplit(path, '/')
dir = strmid(path,0,parts[n_elements(parts)-1]-1)


end
