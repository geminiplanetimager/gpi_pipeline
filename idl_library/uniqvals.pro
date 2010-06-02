;+
; NAME: uniqvals
; PURPOSE: Return all the uniq values in a given array.
;
; NOTES:
; 	this is what the 'uniq' function *ought* to do. The way it works in
; 	IDL is fast and efficient, sure, but kind of klunky to use.
;
; INPUTS:
; 	data	some data you want the uniq values of
; KEYWORDS:
; 	counts	returns the count of occurances for each unique value
; OUTPUTS:
; 	returns the uniq VALUES, not the indices, in the data.
;
; HISTORY:
; 	Began 2002-03-30 23:02:23 by Marshall Perrin 
; -

FUNCTION uniqvals,data,counts=counts, indices=indices, sort=sort

	
	u=data[uniq(data,sort(data))]
	if keyword_set(sort) then u=u[sort(u)]

	if arg_present(counts) then begin
		counts=lonarr(n_elements(u))
		for x=0,n_elements(u)-1 do begin
			w=where(data eq u[x],ct)
			counts[x]=ct
		endfor 
	endif
	if arg_present(indices) then indices=uniq(data,sort(data))

	return,u
end
