function intshift,im,dx,dy,missing=missing

;fait un shift d'un nombre entier
;sans wrapping

dim=size(im,/dimensions) & t=size(im,/type)
ims=make_array(dim,type=t,value=missing)

if (dx gt 0) then begin
    xmin=0 & xxmin=dx
    xmax=dim[0]-dx-1 & xxmax=dim[0]-1
endif else begin
    xmin=abs(dx) & xxmin=0
    xmax=dim[0]-1 & xxmax=dim[0]+dx-1
endelse

if (n_elements(dim) eq 2) then begin
    if (dy gt 0) then begin
        ymin=0 & yymin=dy
        ymax=dim[1]-dy-1 & yymax=dim[1]-1
    endif else begin
        ymin=abs(dy) & yymin=0
        ymax=dim[1]-1 & yymax=dim[1]+dy-1
    endelse

    ims[xxmin:xxmax,yymin:yymax]=im[xmin:xmax,ymin:ymax]
endif else begin
    ims[xxmin:xxmax]=im[xmin:xmax]
endelse

return,ims
end
