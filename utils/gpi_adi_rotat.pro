;+
; NAME: gpi_adi_rotat
;
;
; INPUTS:
; common needed:
;
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	 Jerome Maire 2008-10
;   JM: adapted for GPI-pip
function gpi_adi_rotat,im,deg,x0,y0,hdr=hdr,missing=missing

compile_opt defint32, strictarr, logical_predicate

sz=size(im) & dimx=sz[1] & dimy=sz[2]
if n_params() lt 4 then y0=dimy/2
if n_params() lt 3 then x0=dimx/2

imt=rot(im,deg,1.0,x0,y0,missing=missing,cubic=-0.5,/pivot)

;update astrometry if defined
if keyword_set(hdr) && (strcompress(strc(sxpar(hdr, 'CDELT1')),/rem) ne '')  then begin
    extast, hdr, astr
	if (n_elements(astr) gt 0)  then begin
    crpix=astr.crpix
    cd=astr.cd
    theta=deg*!dpi/180.
    ct=cos(theta)
    st=sin(theta)
    rot_mat=[ [ ct, st], [-st, ct] ]

    ;new values
    crpix=transpose(rot_mat)#(crpix-1-[x0,y0])+1+[x0,y0]
    cd=cd#rot_mat
    astr.crpix=crpix
    astr.cd=cd
    ;put in header
    print, 'Updating astrometry after ADI frame rotation.'
    sxaddpar, hdr, 'HISTORY', 'Updating astrometry after ADI frame rotation.'
    putast,hdr,astr
    endif
endif

return,imt
end
