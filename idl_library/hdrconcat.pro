;+
; NAME: hdrconcat
; PURPOSE:
; 	Concatenates FITS headers into a 2D string array, doing intelligent
; 	things with axes sizes if needed.
;
; NOTES:
; 	The format for multidimensional FITS headers is that axis 0 is
; 	the various keywords in a header, and axis 1 lets you select
; 	which header you want.
;
; 	It's *nice* if all the keywords line up between headers, but by
; 	no means required and this software does not attempt to enforce
; 	that. 
;
; 	You should use sxpararr to get parameters from a FITS header array.
;
; INPUTS:
; 	hdrarr	either a single fits header or a 2D array of strings
; 			this gets modified to contain hdr.
; 	hdr		a fits header you want to append to hdrarr.
;
; HISTORY:
; 	Began 2002-11-19 20:16:08 by Marshall Perrin 
;-

PRO hdrconcat,hdrarr,hdr
	; handle the case of hdrarr being nonexistent
	if not(keyword_set(hdrarr)) then begin
		hdrarr = hdr
		return
	endif
	
	; actually append two arrays
	sza = size(hdrarr)
	szb = size(hdr)

	if szb[0] gt 1 then message,"HDR must be only a 1D array!"
	if sza[0] eq 1 then n = 2 else n=sza[2]+1
	l = sza[1] > szb[1]

	newhdr = strarr(l,n)
	;newhdr[0:sza[1]-1,0:n-2]=reform(hdrarr,sza[1],n-1)
	newhdr[0:sza[1]-1,0:n-2]=hdrarr
	newhdr[0:szb[1]-1,n-1]=hdr

	hdrarr = temporary(newhdr)

end
