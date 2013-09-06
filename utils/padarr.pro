;+
; NAME: padarr
;
;	Pad an array; i.e. embed it into a larger array containing mostly 0's
; 
;
; INPUTS:
; 	array	an array
; 	s		size of oversized array
; 	cen		coordinate mapped to center of oversized array
; KEYWORDS:
; 	value=	value for pixels in the oversized array. default is 0.
; OUTPUTS:
;
; HISTORY:
; 	2008-01-24	M. Perrin 	documentation added to existing code
; 	2008-01-31  M. Perrin	added support for 3D cubes
;-

function padarr,array,s,cen,value=value


sz=size(array)

sx=s[0] & sy=sx
if n_elements(s) eq 2 then sy=s[1]
if sz[0] eq 3 then nz = sz[3] else nz = 1 ; is this a 2D image or 3D cube?

if n_params() gt 2 then cenx=cen[0] else cenx=sz[1]/2
if sz[0] ge 2 then begin
    if n_elements(cen) eq 2 then ceny=cen[1] else ceny=sz[2]/2
endif

typ=size(array,/type)
if sz[0] ge 2 then begin
    bigarray=make_array(sx,sy,nz,type=typ)
    if keyword_set(value) then bigarray+=value
    bigarray[sx/2-cenx:sx/2+(sz[1]-cenx)-1,sy/2-ceny:sy/2+(sz[2]-ceny)-1, *]=array
    return,bigarray
endif
if sz[0] eq 1 then begin
    bigarray=make_array(sx,type=typ)
    if keyword_set(value) then bigarray+=value
    bigarray[sx/2-cenx:sx/2+(sz[1]-cenx)-1]=array
    return,bigarray
endif

end
