;+
; NAME: sxpararr
; PURPOSE:
; 	Like sxparr, but for an array of fits headers.
;
; NOTES:
; 	This isn't necessarily the fastest way to do this, but it
; 	works fine for me.
;
; INPUTS:
; 	hdrs	an array of fits headers. (i.e. a 2D string array)
; 	name	string name of the parameter to return.
; KEYWORDS:
; OUTPUTS:
; 	valid	(optional) an array specifying where the keyword was
; 			found (valid=1) or not (valid=0)
;
; HISTORY:
; 	Began 2002-11-19 20:34:57 by Marshall Perrin 
; 	2005-06-01   Added error handling for the case where the first
; 				 header lacks the keyword in question.
;    2010-02-10 inform and continue if keyword is absent; JM
;-

FUNCTION sxpararr,hdrs,name,valid=valid,silent=silent
	sz = size(hdrs)
	if sz[0] ne 2 then begin
		if ~(keyword_set(silent)) then begin
		message,"HDRS ought to be a 2D string array!",/info
		message,/info,"Returning single sxpar instead."
		endif
		return, sxpar(hdrs,name)
	endif
	nh = sz[2]

	; find the first instance where the header array contains the
	; keyword. Use this to determine the type of array to use to 
	; hold the result.
	i = 0
	repeat begin
		param = sxpar(hdrs[*,i],name,count=count)
		i++
	end until (count gt 0 or i eq nh)
	if ~(keyword_set(silent)) then if count eq 0 then message,'Keyword \"'+name+'\" not found in header!',/continue
	type = size(param,/TYPE)

	; create an array to hold the result.
	output = make_array(sz[2],type=type)
	if arg_present(valid) then valid=bytarr(sz[2])
		
	; loop through, checking for the keyword for each header.
	for i=0,sz[2]-1 do begin
		output[i] = (sxpar(hdrs[*,i],name,count=count))[0]
		if arg_present(valid) then valid[i]=count gt 0
	endfor 

	return,output

end
