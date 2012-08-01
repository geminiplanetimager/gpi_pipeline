im1 = readfits('~/Documents/IFSNoiseTest/S20120726S0166-spdc.fits',/ext)  ;;17 dB
im_psfs1 = get_sat_fluxes(im1,band='H',good=good1,cens=cens1,warns=warns1)

im2 = readfits('~/Documents/IFSNoiseTest/S20120726S0016-spdc.fits',/ext)  ;;16 dB
im_psfs2 = get_sat_fluxes(im2,band='H',good=good2,cens=cens2,warns=warns2)

cwv = get_cwv('H')
lambda = cwv.lambda

window,1,xsize=800,ysize=600
cols = [fsc_color('red'),fsc_color('blue'),fsc_color('green'),fsc_color('navy')]
plot,/nodata,[1.5,1.8],[min([im_psfs1,im_psfs2]),max([im_psfs1,im_psfs2])],Background=cgcolor('white'), Color=cgcolor('black')
for j=0,3 do begin oplot,lambda,im_psfs1[j,*],psym=1,color=cols[j] & oplot,lambda,im_psfs2[j,*],psym=2,color=cols[j] & endfor


;;;;;;;;;;;;;;;;;;;;;;;;;;
copsf = im0
sz = size(im0,/dim)

gridfac = 1e-4
ic_psfi = fltarr(sz[2])+(1./gridfac)
for j=0,sz[2]-1 do ic_psfi[j] *= mean(ic_psfs[*,j])

;;mask psf center
pixscl = gpi_get_setting('ifs_lenslet_scale')
immask = 1.-mkpupil(sz[0],0.12/pixscl)
im = avgaper(immask,1.)
tmp = where(abs(im-1) gt 1e-13, ct)
if ct ne 0 then im[tmp] = 0

;;mask satellites
for k = 0,sz[2]-1 do begin &$
   tmp = copsf[*,*,k]/(ic_psfi[k]*im)  &$
   for isat=0,3 do begin  &$
      dis = distarr(sz[0],sz[1],cens[0,isat,k],cens[1,isat,k])  &$
      imask=where(dis lt 0.1/pixscl)  &$
      tmp[imask] = !values.f_nan  &$
   endfor  &$
   copsf[*,*,k] = tmp  &$
endfor

if (n_params() lt 2) then rsum=1.
if (n_params() lt 3) then rmax=100
if (not keyword_set(pixscl)) then pixscl=1.
if (not keyword_set(nsig)) then nsig=1.

;;loop through slices
for k=0,sz[2]-1 do begin 
   im = copsf[*,*,k]
   xc = mean( cens[0,*,k] )
   yc = mean( cens[1,*,k] )

   indices, im, r=rall, center=[xc, yc]
   ind = where(rall le rmax + 1d/sqrt(2d), npts)
   rall = rall[ind]
   sind=sort(rall) & rall=rall[sind] & ind=ind[sind]
   iall=fltarr(npts)

   ;;masque de l'ouverture et indices des pixels du masque (pour le pixel 0,0)
   ic0=myaper(im,xc,yc,rsum,mask,imask)
   if (rsum eq 0.) then begin mask=1. & imask=yc*sz[0]+xc & endif
   imask=imask-xc-yc*sz[0]

   ;;calcule l'intensite totale dans le masque pour chaque pixel
   for n=0l,npts-1 do iall[n]=total(mask*im[imask+ind[n]],/nan)

   ;;fait la mediane et sigma sur les points a des intervalles de 1 pixel
   rrall=round(rall)
   imed=fltarr(rmax+1) & isig=fltarr(rmax+1)
   asec=findgen(rmax+1)*pixscl
   
   for r=1,rmax do begin
      i=where(rrall eq r)
      imed[r]=median(iall[i])
      isig[r]=nsig*robust_sigma(iall[i])
   endfor
   if (arg_present(mapsig)) then begin
      mapsig=fltarr(dimx,dimy)+!values.f_nan
      distarr=round(shift(dist(dimx,dimy),dimx/2,dimy/2))
      for r=1,rmax do begin
         i=where(distarr eq r)
         mapsig[i]=isig[r]
      endfor
   endif

   imed[0]=iall[0] & isig[0]=iall[0]
   asec=asec[2:rmax] & imed=imed[2:rmax] & isig=isig[2:rmax]
   

      if (keyword_set(psig)) then begin
         if (op eq 0) then begin
            plot,asec,isig,ylog=(*self.state).contr_yaxis_type,xlog=xlog,xrange=xrange,yrange=yrange,/xstyle,/ystyle,$
                 linestyle=linestyle[il],xtitle=xtitle,ytitle=ytitle,/nodata, charsize=(*self.state).contr_font_size, $
                 title=title
            op=1
         endif
         oplot,asec,isig,color=color[ic]+k*100,linestyle=linestyle[il]
         ;ic=ic+1
      endif
endfor
