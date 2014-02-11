
;+
; routine for printing coordinates in the form "(X,Y)"
; 04/20/96 M. C. Liu (UCB)
;
; Can either call with two arguments:
; 	printcoo, x, y
; Or with one argument, containing two elements:
;   printcoo, [x,y]
;
;2006-04-10	M. Perrin added _extra so you can pass format strings.
;-

function Printcoo, x, y,brackets=brackets,_extra=_extra


if ((n_params() eq 1) and n_elements(x) eq 2) then begin
	x0 = x[0]
	y0 = x[1]
endif else begin
	checkargnum,n_params(),2,"Error - must call printcoo with two arguments!"
	x0 = x
	y0=y
endelse


if keyword_set(brackets) then return, '['+strc(_extra=_extra,x0)+','+strc(_extra=_extra,y0)+']'
return, '('+strc(_extra=_extra,x0)+','+strc(_extra=_extra,y0)+')'

end

