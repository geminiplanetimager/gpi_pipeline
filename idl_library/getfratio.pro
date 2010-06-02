function getfratio,im1,im2,guess,ind,res=bres,med=bmed

if n_elements(guess) eq 0 then f0=1. else f0=guess
allpix=1
if n_elements(ind) gt 3 then allpix=0

diff=allpix ? im1-im2*f0:im1[ind]-im2[ind]*f0	;which means if allpix true, then
;diff=im1-im2*f0 else diff=im1[ind]-im2[ind]*f0

if total(finite(diff)) lt 3 then return,1.
bmed=median(diff,/even)
bres=median(abs(diff-bmed),/even)

for k=1,2 do begin ;loop sur de ratio de flux jusqu'a precision de 10^-k

    step=1./10.^k
    dir=1.
    switched=0

    while (switched lt 2) do begin
        f=f0+dir*step
        diff=allpix ? im1-im2*f:im1[ind]-im2[ind]*f
        med=median(diff,/even)
        res=median(abs(diff-med),/even)

        if (res lt bres) then begin
            f0=f & bres=res & bmed=med
        endif else begin
            dir*=-1. & switched+=1
        endelse
    endwhile
endfor ;k

return,f0
end
