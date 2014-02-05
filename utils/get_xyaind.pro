; by Jerome Maire
;
function get_xyaind,dimx,dimy,xct,yct,rt,drt

;pour obtenir les indices d'un anneau centre sur xct,yct
;de l'image
;r=rayon inferieur
;dr=largeur de l'anneau

xc=float(xct) & yc=float(yct)
r=float(rt) & dr=float(drt)

;on construit une petite boite et on calcule les distances seulement
;dans cette boite pour que la procedure soit plus rapide
dx=ceil(3*(r+dr))
box=fltarr(dx,dx)
;coordonnees x,y du coin inferieur de la boite
xmin=round(xc)-dx/2 & ymin=round(yc-dx/2)
;coordonnees x,y de la boite
x=indgen(dx)#replicate(1,dx)+xmin
y=replicate(1,dx)#indgen(dx)+ymin
rmax=(r+dr-1+1./sqrt(2))^2
rmin=(r-1./sqrt(2))^2
distarr=(x-xc)^2+(y-yc)^2
;bons indices dans la boite
i=where(distarr lt rmax and distarr gt rmin)
;x,y correspondants
x=x[i]>0<(dimx-1)
y=y[i]>0<(dimy-1)
;bons indices dans l'image de dimension dimx,dimy
i=x+y*dimx
i=i[uniq(i)]


;ancienne procedure, plus lente
;distarr=lindgen(dimx,dimy)
;distarr=sqrt( ((distarr mod dimx)-xc)^2+(distarr/dimx-yc)^2 )
;
;indices=where(distarr ge (rin-sqrt(2.)*0.5) and $
;              distarr le (rin+(dr-1)+sqrt(2.)*0.5))

return,i
end
