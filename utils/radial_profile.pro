pro radial_profile,im0,cens,imed=imed,isig=isig,imn=imn,asec=asec,rmax=rmax,rsum=rsum

  if not keyword_set(rmax) then rmax = 100
  if not keyword_set(rsum) then rsum = 1

  sz = size(im0,/dim)
  cent = fltarr(2)
  if sz[0] mod 2 then cent[0] = (sz[0]-1)/2. else cent[0] = sz[0]/2. - 1
  if sz[1] mod 2 then cent[1] = (sz[1]-1)/2. else cent[1] = sz[1]/2. - 1
  true_cent = [mean(cens[0,*]),mean(cens[1,*])]

  pixscl = gpi_get_setting('ifs_lenslet_scale')
  tmp = make_annulus(sz[0],0.12/pixscl)
  coremask = fltarr(sz[0],sz[1])+!values.f_nan
  coremask[cent[0]+tmp[*,0],cent[1]+tmp[*,1]] = 1.
  coremask = shift(coremask,round(true_cent - cent))

  ;;mask satellites and center
  im = im0*coremask
  for isat=0,3 do begin &$
     dis = distarr(sz[0],sz[1],cens[0,isat],cens[1,isat])  &$
     imask=where(dis lt 0.12/pixscl)  &$
     im[imask] = !values.f_nan  &$
  endfor 
  
  indices, im, r=rall, center = true_cent
  ind = where(rall le rmax + 1d/sqrt(2d), npts)
  rall = rall[ind]
  sind=sort(rall) & rall=rall[sind] & ind=ind[sind]
  iall=fltarr(npts)
  
  ;;masque de l'ouverture et indices des pixels du masque (pour
  ;;le pixel 0,0)
  ic0 = myaper(im,true_cent[0],true_cent[1],rsum,mask,imask)
  if (rsum eq 0.) then begin mask = 1. & imask = yc*sz[0]+true_cent[0] & endif
  imask = imask - true_cent[0] - true_cent[0]*sz[0]

  ;;calcule l'intensite totale dans le masque pour chaque pixel
  for n=0l,npts-1 do iall[n]=total(mask*im[imask+ind[n]],/nan)
  
  ;;fait la mediane et sigma sur les points a des intervalles de 1 pixel
  rrall=round(rall)
  imed=fltarr(rmax+1) & isig=fltarr(rmax+1) & imn = fltarr(rmax+1)
  asec=findgen(rmax+1)*pixscl

  for r=1,rmax do begin
     i=where(rrall eq r)
     imed[r]=median(iall[i])
     imn[r] = mean(iall[i])
     isig[r]=robust_sigma(iall[i])
  endfor

  asec=asec[2:rmax] & imed=imed[2:rmax] & isig=isig[2:rmax] & imn = imn[2:rmax]

end
