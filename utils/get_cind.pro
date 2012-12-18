function get_cind,dimx,dimy,r

compile_opt defint32, strictarr, logical_predicate
;pour obtenir les indices d'un cercle centre sur le centre
;de l'image
;r=rayon

xc=dimx/2 & yc=dimy/2
;on construit les distances seulement dans une petite boite 
;pour que la procedure soit plus rapide
dx=ceil(3*(r>1))
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
i=i[sort(i)]
i=i[uniq(i)]

;ancienne procedure, plus lente
;r=float(r)
;distarr=shift(dist(dimx,dimy),dimx/2,dimy/2)
;indices=where(distarr le (r+sqrt(2.)*0.5))

return,i
end
