function avgaper,im,rsum,mask=mask

;Retourne une image dans laquelle chaque pixel consiste en la moyenne de
;im sur une ouverture centree sur ce pixel.
;
;Parametres d'entree:
;-------------------
;im: image
;rsum: rayon de l'ouverture a prendre sommer le flux, par defaut=1.
;mask=mask: masque a utiplutot qu'une ouverture circulaire de rsum
;           pixels de rayon
;

s=size(im) & dimx=s[1] & dimy=s[2]

if (not keyword_set(mask)) then begin
    if (rsum eq 0) then return,im
    mask=mkpupil(dimx>dimy,rsum)
    if (dimx ne dimy) then begin
        s=size(mask) & dmask=s[1]
        mask=mask[dmask/2-dimx/2:dmask/2-dimx/2+dimx-1,dmask/2-dimy/2:dmask/2-dimy/2+dimy-1]
    endif
endif

maskft=fft(shift(mask/total(mask)*dimx*dimy,-dimx/2,-dimy/2),-1,/double)
return,double( shift( fft( fft(shift(im, -dimx/2,-dimy/2),-1,/double)*maskft, 1,/double ), dimx/2,dimy/2 ) )
end
