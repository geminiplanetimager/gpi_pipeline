;+
; NAME:  
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2012-01-31 01:08:37 by Marshall Perrin 
;-

FUNCTION gpi_get_keyword, pri_header, ext_header, keyword, count=count, comment=comment, ext_num=ext_num, silent=silent
	; get a keyword, either from primary or extension HDU
	;	
	; KEYWORDS:
	;	ext_num		This allows you to override the keyword config file if you
	;				really know what you're doing. Set ext_num=0 to read from the PHU or
	;				ext_num=1 to read from the image extension.
	;	silent		suppress printed output to the screen.
	;
	
	common GPI_KEYWORD_TABLE, keyword_info

	if ~ptr_valid(keyword_info) then gpi_load_keyword_table


	; which header to try first?
	if n_elements(ext_num) eq 0 then begin 
		; we should use the config file to determine where the keyword goes. 
		wmatch = where( strmatch( (*keyword_info).keyword, keyword, /fold), matchct)
		if matchct gt 0 then begin
			; if we have a match try that extension
			ext_num = ( (*keyword_info).extension[wmatch[0]] eq 'extension' ) ? 1 : 0  ; try Pri if either PHU or Both
		endif else begin
			; if we have no match, then try PHU first and if that fails try the
			; extension
			if ~(keyword_set(silent)) then message,/info, 'Keyword '+keyword+' not found in keywords config file; trying Primary header...'
			ext_num=0
			;value = sxpar(  *(*self.data).headersPHU[indexFrame], keyword, count=count) 
			;if count eq 0 then value =  sxpar(  *(*self.data).headersExt[indexFrame], keyword, count=count, comment=comment)
			;return, value
		endelse
	endif else begin
		; the user has explicitly told us where to get it - check that the value
		; supplied makes sense.
		if ext_num gt 1 or ext_num lt 0 then begin
			if ~(keyword_set(silent)) then message,/info, 'Invalid extension number - can only be 0 or 1. Checking for keyword in primary header.'
			ext_num=0
		endif
	endelse



	; try the preferred header
	if ext_num eq 0 then value= sxpar(  pri_header, keyword, count=count, comment=comment)  $
	else  				 value= sxpar(  ext_header, keyword, count=count, comment=comment)  

	;if that failed, try the other header
	if count eq 0 then begin
		if ~(keyword_set(silent)) then message,/info,'Keyword '+keyword+' not found in preferred header; trying the other HDU'
		if ext_num eq 0 then value= sxpar(  ext_header, keyword, count=count, comment=comment)  $
		else  				 value= sxpar(  pri_header, keyword, count=count, comment=comment)  
	endif
	
	; remove extra leading or trailing blanks (because the sxpar/sxaddpar
	; produce these for short strings)
	if size(value,/TNAME) eq 'STRING' then value = strtrim(value,2)
	return, value
	
end


