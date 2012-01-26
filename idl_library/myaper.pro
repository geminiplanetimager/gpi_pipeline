function myaper,im,xc,yc,r,mask,imask,nan=nan

;im: image, 2-d array
;xc, yc: center of aperture
;r: radius of aperture 
;mask: mask corresponding to aperture, centered on round(xc,yc)
;imask: indices of mask pixels, expressed wrt im

if (r lt 0.) then return,-1
if (r eq 0.) then return,im[round(xc),round(yc)]
s=size(im) & dimx=s[1] & dimy=s[2]

;demi-cote de la sous-section a utiliser
re=ceil(r)
ixmin=round(xc)-re & ixmax=round(xc)+re
iymin=round(yc)-re & iymax=round(yc)+re
ixmin=ixmin>0      & iymin=iymin>0
ixmax=ixmax<(dimx-1) & iymax=iymax<(dimy-1)
nx=ixmax-ixmin+1     & ny=iymax-iymin+1
;x et y correspondant a cette sous-section
xm=findgen(nx)#replicate(1.,ny)+ixmin
ym=replicate(1.,nx)#findgen(1.,ny)+iymin
;distances des pixels
distsq=(xm-xc)^2+(ym-yc)^2
;indices de ces pixels dans l'image
imask=ym*dimx+xm

;++construit mask
mask=fltarr(nx,ny)
;indices des pixels interieurs a l'ouverture
ind=where(distsq le (r+0.70711)^2,nin) 
if (nin gt 0) then mask[ind]=1.
;indices des pixels inclus en partie seulement
iedge=where(distsq le (r+0.70711)^2 and distsq ge ((r-0.70711)>0)^2,nedge)
for n=0,nedge-1 do mask[iedge[n]]=pixwt(xc,yc,r,xm[iedge[n]],ym[iedge[n]])
mask=mask>0.<1.
;--construit mask

return,total(im[imask]*mask,nan=nan)
end
