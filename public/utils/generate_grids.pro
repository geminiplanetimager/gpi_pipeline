pro generate_grids, xgrid, ygrid, n, scale=sfac, $
                    double=doubleflag, whole=wholeflag, $
                    freqshift=fflag
;+
; NAME: generate_grids
;
; PURPOSE: 
;	Generate x and y grids of evenly spaced numbers
;
; INPUTS:
;	n       Size of grid
;       scale   scale grid values by this factor (step size)
;
; KEYWORD:
; 	/double  Create double arrays
;       /whole   Only allow whole number steps
;       /freqshift  Frequency domain grid (shift by n/2)
; OUTPUTS:
;	returns the value stored in the file
;
; HISTORY:
;       Original implementation by Lisa Poyneer.
;-

if keyword_set(fflag) then begin
    xgrid = make_array(n,n,double=doubleflag)
    for j=0, n-1 do xgrid[j,*] = j - (j GT n/2)*n
    if keyword_set(sfac) then xgrid = xgrid*sfac
    ygrid = transpose(xgrid)
    
endif else begin

    xgrid = make_array(n,n,double=doubleflag)
    for j=0, n-1 do xgrid[j,*] = j*1.
    if (n mod 2 ) eq 0 then begin
        if keyword_set(wholeflag) then offset = n/2. else offset = (n-1)/2.
    endif else begin
        if keyword_set(wholeflag) then offset = (n-1)/2. else offset = 0. ;; kind of undefined!
    endelse

    xgrid = xgrid - offset
    if keyword_set(sfac) then xgrid = xgrid*sfac
    ygrid = transpose(xgrid)
endelse

end


