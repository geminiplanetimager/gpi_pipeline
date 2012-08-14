;; CVS header information for IDL files
;; $Revision: 1.1.1.1 $
;; $Author: LAB $
;; $Date: 2011/10/19 16:28:55 $

;; this is a helper since I am always making these stupid 
;; x and y-indices grids!!!!!


pro generate_grids, xgrid, ygrid, n, scale=sfac, $
                    double=doubleflag, whole=wholeflag, $
                    freqshift=fflag

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


