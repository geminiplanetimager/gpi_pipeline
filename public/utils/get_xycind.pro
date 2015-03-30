function get_xycind,dimx,dimy,xct,yct,r
; Also by Jerome Maire? 

xc=float(xct) & yc=float(yct)

;on construit une petite boite et on calcule les distances seulement
;dans cette boite pour que la procedure soit plus rapide
dx=ceil(3*r)
box=fltarr(dx,dx)
;coordonnees x,y du coin inferieur de la boite
xmin=round(xc)-dx/2 & ymin=round(yc-dx/2)
;coordonnees x,y de la boite
x=indgen(dx)#replicate(1,dx)+xmin
y=replicate(1,dx)#indgen(dx)+ymin
rmax=(r+1./sqrt(2))^2
;bons indices dans la boite
i=where((x-xc)^2+(y-yc)^2 lt rmax)
;x,y correspondants
x=x[i]>0<(dimx-1)
y=y[i]>0<(dimy-1)
;bons indices dans l'image de dimension dimx,dimy
i=x+y*dimx
i=i[uniq(i)]

return,i
end
