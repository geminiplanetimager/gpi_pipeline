;+
; NAME: aprint
;
; PURPOSE:
; 	print something out formatted as an IDL array (i.e. in IDL source code syntax)
; NOTES:
;
; 	This is useful if you want to take some variable and embed
; 	it as a constant into an IDL routine.
;
; 	CAUTION: Does not work properly on multidimensional arrays yet.
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2005-07-22 10:12:01 by Marshall Perrin 
;-

function aprint,thing,nocompress=nocompress,_extra=_extra

	if size(thing,/type) eq 7 then begin
		; it's a string, so use quotes.
		delimiter='", "' 
		delim2 = '"'
	endif else if size(thing,/type) eq 1 then begin
		; it's a byte, which strjoin fails on for some reason.
		; so cast to int and then retry this recursively.
		return, aprint(fix(thing), nocompress=nocompress,_extra=_extra)
	endif else begin
		delimiter=', '
		delim2 = ''
	endelse

	; handle multidimensional arrays via recursion
	if (size(thing))[0] gt 1 then begin
		nd = (size(thing))[0]
		; recursion over the last dimension requires some pretty hairy juggling.
		; 
		; first, we need to find out the dimensions
		dims = size(thing,/dimensions)
		nz = dims[nd-1]
		leading_dims = dims[0:nd-2]
		; now, we need to swap the last dimension to be first
		thing2 = transpose(thing,[nd-1,indgen(nd-1)])
		; and squash it into a 2d array
		thing2 = reform(thing2,[nz,n_elements(thing2)/nz])
		retval = "[ "
		for i = 0,nz-1 do begin
			if i gt 0 then retval += ", " ;+string(10)
			; extract one slice of the 2d array and reflate it to the correct
			; dimensions
			thing3 = reform(thing2[i,*],leading_dims)
			retval += aprint(thing3)
		endfor
		retval += " ]"
		return,retval
	endif
			
	
		
	if keyword_set(nocompress) then return,"[ "+delim2+strjoin(thing,delimiter)+delim2+" ]"
	return,"[ "+delim2+strc(thing,/join,delim=delimiter,_extra=_extra)+delim2+" ]"


end
