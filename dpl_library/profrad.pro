pro profrad,imt,res,med4q=med4q,p2d=p2d,p1d=p1d,rayon=rayon

;Calcule un profil radial median.
;Par defaut, calcule un profil radial 1d qui consiste en la mediane
;des valeurs de tous les pixels situes dans un interval de distance du
;centre de l'image. Cet interval de distance est determine par
;res. Utilise ensuite un spline cubique pour extrapoler le profil a la
;distance de chacun des pixels pour construire le profil 2D.
;
;res: resolution (en pixels) du profil radial 1d, optionnel, la valeur
;     par defaut est 1.
;p2d: profil 2d
;p1d: profil 1d
;rayon: rayon correspondant a p1d
;/med4q: calcule le profil 2d en prenant la mediane sur les 4 quadrants

s=size(imt) & dimx=s[1] & dimy=s[2]
im=double(imt)

;calcul de profil 1d
if (arg_present(p1d) or (not keyword_set(med4q) and arg_present(p2d))) then begin
    if (n_params() eq 1) then res=1.
    distarr=shift(dist(dimx,dimy),dimx/2,dimy/2)
    if res ne 0 then rdistarr=round(distarr/res)*res else rdistarr=distarr
    rayon=rdistarr[0:dimx/2,0:dimy/2]
    sind=sort(rayon) & rayon=rayon[uniq(rayon,sind)]
    p1d=dblarr(n_elements(rayon))

    for r=0,n_elements(rayon)-1 do $
      p1d[r]=median(im[where(rdistarr eq rayon[r])],/even)
endif

;calcul du profil 2d
if (not keyword_set(med4q) and arg_present(p2d)) then begin
    ;interpole le profil sur l'image au complet d'un coup
    ;p2d=dblarr(dimx,dimy)
    ;sind=sort(distarr)
    ;p2d[sind]=spline(rayon,p1d,distarr[sind])

    ;fait un seul quadrant et copie sur les 3 autres quadrants
    ;cette methode est 3X plus rapide pour l'interpolation
    distarr=distarr[0:dimx/2,0:dimy/2]
    sind=sort(distarr)
    q1=dblarr(dimx/2+1,dimy/2+1)
    q1[sind]=spline(rayon,p1d,distarr[sind])

    if (dimx mod 2 eq 0) then i1x=1 else i1x=0
    if (dimy mod 2 eq 0) then i1y=1 else i1y=0
    ;pas besoin de prendres de transposes ici car les profils sont
    ;symmetriques aux transpose
    p2d=dblarr(dimx,dimy)
    p2d[0:dimx/2,0:dimy/2]=q1
    p2d[0:dimx/2,dimy/2:dimy-1]=reverse(q1[*,i1y:dimy/2],2)
    p2d[dimx/2:dimx-1,dimy/2:dimy-1]=$
      reverse(reverse(q1[i1x:dimx/2,i1y:dimy/2],2),1)
    p2d[dimx/2:dimx-1,0:dimy/2]=reverse(q1[i1x:dimx/2,*],1)
endif

if (keyword_set(med4q) and arg_present(p2d)) then begin
    ;place les 4 quadrants dans un cube, fait la mediane, et replace cette
    ;mediane dans les quadrants
    ;(equivalent a faire un cube avec 4 rotation et prendre la mediane)
    q=dblarr(dimx/2+1,dimy/2+1,4)
    if (dimx mod 2 eq 0) then i1x=1 else i1x=0
    if (dimy mod 2 eq 0) then i1y=1 else i1y=0
    q[*,*,0]=im[0:dimx/2,0:dimy/2]
    q[*,i1y:dimy/2,1]=reverse(im[0:dimx/2,dimy/2:dimy-1],2)
    q[*,*,1]=transpose(q[*,*,1])
    q[i1x:dimx/2,i1y:dimy/2,2]=reverse(reverse(im[dimx/2:dimx-1,dimy/2:dimy-1],2),1)
    q[i1x:dimx/2,*,3]=reverse(im[dimx/2:dimx-1,0:dimy/2],1)
    q[*,*,3]=transpose(q[*,*,3])
    q=median(q,dimension=3,/even)
;    q=min(q,dimension=3)
    qt=transpose(q)
    p2d=dblarr(dimx,dimy)
    p2d[0:dimx/2,0:dimy/2]=q
    p2d[0:dimx/2,dimy/2:dimy-1]=reverse(qt[*,i1y:dimy/2],2)
    p2d[dimx/2:dimx-1,dimy/2:dimy-1]=$
      reverse(reverse(q[i1x:dimx/2,i1y:dimy/2],2),1)
    p2d[dimx/2:dimx-1,0:dimy/2]=reverse(qt[i1x:dimx/2,*],1)

endif

end
