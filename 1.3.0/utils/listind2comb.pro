function listind2comb,ind
;+
; NAME:
;       listind2comb
;
; PURPOSE:
;       Given the index of a list (i.e, 0, 1, 2...), find the
;       combination in an ordered sequence it corresponds to: 
;       0 ->0,1; 1 -> 0,2; 2 -> 1 2; 3 -> 0 3; etc. 
;
; EXPLANATION:
;       Reverse indexing for combinations of nC2.
;
; Calling SEQUENCE:
;       res = listind2comb(ind)
;
; INPUT/OUTPUT:
;       ind - scalar integer index of combination (0-based)
;       res - 2x1 array of combinatorical values
;
; OPTIONAL OUTPUT:
;       None.
;
; EXAMPLE:
;
;
; DEPENDENCIES:
;	None
;
; NOTES: 
;      
;             
; REVISION HISTORY
;       Written 2012 - ds
;-

counter = 0L
tot = 0L
while ind + 1 - tot gt 0 do begin counter += 1 & tot += counter & end

return,[ind - (tot-counter),counter]
end
