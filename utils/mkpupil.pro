function mkpupil,dim,rpup,cobs=cobs
;+
; NAME:
;      mkpupil
; PURPOSE:
;     create a pupil mask
;
; EXPLANATION:
;       
;
; Calling SEQUENCE:
;      
;
; INPUT/OUTPUT:
;

; OPTIONAL OUTPUT:
;       
;
; EXAMPLE:
;
;
; DEPENDENCIES:
;
;
; NOTES: 
;      
;             
; REVISION HISTORY
;       Written  before 2008, Mathilde beaulieu/Jean-Francois Lavigne/David Lafreniere/Jerome Maire. 
;-

xc=dim/2 & yc=dim/2
rpup=float(rpup)

;+Cree une pupille avec ou sans obscuration centrale
; qui consiste en seulement des 0 ou des 1
pup=dblarr(dim,dim)
distarr=shift(dist(dim),dim/2,dim/2)
if (not keyword_set(cobs)) then ind=where(distarr le (rpup+sqrt(2.)*0.5),count) $
  else ind=where(distarr le (rpup+sqrt(2.)*0.5) and distarr ge (rpup*cobs-sqrt(2.)*0.5),count)
if count ne 0 then pup[ind]=1.d

;+Ajuste le bords exterieur de la pupille pour qu'ils aient
; une valeur correspondant a la fraction du pixel couverte
; par la pupille
;
;indices de tous les pixels sur le bords exterieur de la pupille
bordsext=where(distarr le (rpup+sqrt(2.)*0.5) and distarr ge (rpup-sqrt(2.)*0.5))
;x,y de ces pixels par rapport au centre de la pupille
xbordsext=(bordsext mod dim)-xc & ybordsext=(bordsext/dim)-yc
;on garde seulement les valeur positives, symmetrie dans les 4 quadrants
indpos=where(xbordsext ge 0 and ybordsext ge 0,count)
if count ne 0 then begin
    xbordsext=xbordsext[indpos] & ybordsext=ybordsext[indpos]
endif

for n=0l,count-1 do begin
    x=xbordsext[n] & y=ybordsext[n]
    aire=pixwt(xc,yc,rpup,xc+x,yc+y) > 0.d0 <1.d0
    if aire lt 0.d then stop
    pup[xc+x,yc+y]=aire & pup[xc+x,yc-y]=aire
    pup[xc-x,yc+y]=aire & pup[xc-x,yc-y]=aire
endfor
;-Ajustement des bords exterieurs

;+Ajuste le bords interieur (cobs!=0) de la pupille pour qu'ils aient
; une valeur correspondant a la fraction du pixel couverte
; par la pupille
if (keyword_set(cobs)) then begin
    rint=cobs*rpup
    ;indices de tous les pixels sur le bords interieur de la pupille
    bordsint=where(distarr le (rint+sqrt(2.)*0.5) and distarr ge (rint-sqrt(2.)*0.5))
    ;x,y de ces pixels par rapport au centre de la pupille
    xbordsint=(bordsint mod dim)-xc & ybordsint=(bordsint/dim)-yc
    ;on garde seulement les valeur positive, symmetrie dans les 4 quadrants
    indpos=where(xbordsint ge 0 and ybordsint ge 0)
    xbordsint=xbordsint[indpos] & ybordsint=ybordsint[indpos]

    for n=0l,n_elements(xbordsint)-1 do begin
        x=xbordsint[n] & y=ybordsint[n]
        aire=(1.d0-pixwt(xc,yc,rint,xc+x,yc+y)) > 0.d0 <1.d0 
        pup[dim/2+x,dim/2+y]=aire & pup[dim/2+x,dim/2-y]=aire
        pup[dim/2-x,dim/2+y]=aire & pup[dim/2-x,dim/2-y]=aire
    endfor
endif
;-Ajustement des bords interieurs

return,pup
end
