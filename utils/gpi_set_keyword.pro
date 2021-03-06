;+
; NAME:  gpi_set_keyword
; 	Set a keyword. This will automatically write it to the primary or extension
; 	header as appropriate, based on the keywords list in the GPI-Gemini ICD
;
; INPUTS:
; 	keyword		keyword name
; 	value		value to set for that keyword
; 	pri_header, ext_header		The headers themselves. One of these will be
; 								modified by this function.
; KEYWORDS:
;	ext_num=	This allows you to override the keyword config file if you
;				really know what you're doing. Set ext_num=0 to write to the PHU or
;				ext_num=1 to write to the image extension.
;	/silent		suppress printed output to the screen.
;	/verbose	Opposite of silent.
;				Default is silent if neither are specified.
;
; OUTPUTS:
;   One of the two headers is modified to add the new keyword or update its
;   value.
;
; HISTORY:
; 	Began 2012-01-31 01:08:13 by Marshall Perrin 
; 	2013-04-26 Minor formatting tweak to match TLC outputs
; 	2013-07-12 MP: Documentation
;-


PRO gpi_set_keyword, keyword, value, pri_header, ext_header, comment=comment, ext_num=ext_num, _Extra=_extra, silent=silent, verbose=verbose
	; set a keyword in either the primary or extension header depending on what
	; the keywords table says. 
	;
	compile_opt defint32, strictarr, logical_predicate

	common GPI_KEYWORD_TABLE, keyword_info

	if ~(keyword_set(pri_header)) or ~(keyword_set(ext_header)) then message,"Invalid function call - missing pri_header andor ext_header arguments!"

	if ~ptr_valid(keyword_info) then gpi_load_keyword_table

	if n_elements(silent) eq 0 and ~(keyword_set(verbose)) then silent=1
	if keyword_set(verbose) then silent=0

	if ~(keyword_set(comment)) then comment=' '
	; for aesthetics always enforce a space character at the start of the comment:
	;   (this keeps DRP-produced keywords consistent looking with how TLC writes
	;   keywords.)
	if strmid(comment,0,1) ne ' ' then comment =' '+comment

	wmatch = where( strmatch( (*keyword_info).keyword, keyword, /fold), matchct)


	if n_elements(ext_num) eq 0 then begin 
		; we should use the config file to determine where the keyword goes. 
		if matchct gt 0 then begin
			; if we have a match write to that extension
			ext_num = ( (*keyword_info).extension[wmatch[0]] eq 'extension' ) ? 1 : 0  ; try Pri if either PHU or Both
		endif else begin
			if ~(keyword_set(silent)) then message,/info, 'Keyword '+keyword+' not found in keywords config file; writing to Primary header...'
			ext_num = 0
		endelse
	endif else begin
		; the user has explicitly told us where to put it - check that the value
		; supplied makes sense.
		if ext_num gt 1 or ext_num lt 0 then begin
			if ~(keyword_set(silent)) then message,/info, 'Invalid extension number - can only be 0 or 1. Writing keyword to primary header.'
			ext_num=0
		endif
	endelse


	;if keyword_set(DEBUG) then 
	if ~(keyword_set(silent)) then message,/info, "Writing keyword "+keyword+" to extension "+strc(ext_num)+", value="+strc(value)

	; JM: I do not understand why but fxaddpar do not cut "long" value for "HISTORY" and "COMMENT" keywords
  	if ~strmatch(keyword,'*HISTORY*') then begin 
		if ext_num eq 0 then fxaddpar,  pri_header, keyword, value, comment $
    	else  				 fxaddpar,  ext_header, keyword, value, comment 
	endif else begin
    	if ext_num eq 0 then sxaddparlarge,  pri_header, keyword, value $
    	else           		 sxaddparlarge,  ext_header, keyword, value 
  	endelse

end


