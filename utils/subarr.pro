function subarr,array,s,cen,zeroout=zeroout,nanout=nanout, verbose=verbose

;extract a subarray of array
;s: side of subarray
;cen: center of subarray
;
; HISTORY
; 2008-09-17	J. Maire	Added Nanout keyword

sz=size(array)

sx=s[0] & sy=sx
if n_elements(s) eq 2 then sy=s[1]

if n_params() gt 2 then cenx=round(cen[0]) else cenx=sz[1]/2

ok=1
x1=cenx-sx/2 & x2=cenx-sx/2+sx-1
if x1 lt 0 or x2 gt sz[1]-1 then ok=0
if sz[0] eq 1 then begin
    if ok eq 1 then return,array[x1:x2]

    ;to set out of bound pixels to zero
    if keyword_set(zeroout) || keyword_set(nanout) then begin
        x=lindgen(x2-x1+1)+x1
        tmp=array[x]
        i=where(x lt 0 or x ge sz[1])
        if keyword_set(zeroout) then tmp[i]=0
        if keyword_set(nanout) then  tmp[i]=!VALUES.F_NAN
        return,tmp
    endif

    x=(lindgen(x2-x1+1)+x1)>0
    return,array[x]
endif

if sz[0] eq 2 then begin
    if n_params() gt 2 then ceny=round(cen[1]) else ceny=sz[2]/2
    y1=ceny-sy/2 & y2=ceny-sy/2+sy-1
    if y1 lt 0 or y2 gt sz[2]-1 then ok=0
	if keyword_set(verbose) then message,/info, "extracting subarray ["+strc(x1)+":"+strc(x2)+", "+strc(y1)+":"+strc(y2)+"]"
    if ok eq 1 then return,array[x1:x2,y1:y2]

    ;to set out of bound pixels to zero
    if keyword_set(zeroout) || keyword_set(nanout) then begin
        x=(lindgen(x2-x1+1)+x1)#replicate(1,y2-y1+1)
        y=replicate(1,x2-x1+1)#(lindgen(y2-y1+1)+y1)
        tmp=array[x+y*sz[1]]
        i=where(x lt 0 or x ge sz[1] or y lt 0 or y ge sz[2])
        if keyword_set(zeroout) then tmp[i]=0
        if keyword_set(nanout) then tmp[i]=!VALUES.F_NAN
        return,tmp
    endif
    x=((lindgen(x2-x1+1)+x1)#replicate(1,y2-y1+1))>0<(sz[1]-1)
    y=(replicate(1,x2-x1+1)#(lindgen(y2-y1+1)+y1))>0<(sz[2]-1)
    return,array[x+y*sz[1]]
endif

if sz[0] eq 3 then begin
    if n_params() gt 2 then ceny=round(cen[1]) else ceny=sz[2]/2
    y1=ceny-sy/2 & y2=ceny-sy/2+sy-1
    if y1 lt 0 or y2 gt sz[2]-1 then ok=0
    if ok eq 1 then return,array[x1:x2,y1:y2, *]
endif
if sz[0] eq 4 then begin
    if n_params() gt 2 then ceny=round(cen[1]) else ceny=sz[2]/2
    y1=ceny-sy/2 & y2=ceny-sy/2+sy-1
    if y1 lt 0 or y2 gt sz[2]-1 then ok=0
    if ok eq 1 then return,array[x1:x2,y1:y2, *, *]
endif



end
