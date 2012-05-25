pro statvsr,im,rsum,rmax,nsig=nsig,pixscl=pixscl,pdot=pdot,pmed=pmed,psig=psig,$
            color=color,linestyle=linestyle,xrange=xrange,yrange=yrange,$
            overplot=overplot,xlog=xlog,noplot=noplot,med=imed,isig=isig,$
            asec=asec,silent=silent,xtitle=xtitle,ytitle=ytitle,psym=psym,$
            symsize=symsize,mapsig=mapsig,cens=cens

;Parametres d'entree:
;-------------------
;im: image de la psf a analyser
;rsum: rayon de l'ouverture a prendre pour chaque pixel, par defaut=1
;rmax: rayon maximum a considerer, par defaut=100
;
;Parametres d'entree facultatifs:
;-------------------------------
;nsig: nombre de sigma pour determiner le bruit, plot et retourne
;      nsig*sigma, par defaut=1
;pixscl: "/pixel de l'image, par defaut=1
;/pdot: pour plotter les points de l'intensite de chaque pixel
;/pmed: pour plotter la courbe d'intensite mediane
;/psig: pour plotter la courbe de bruit (nsig*sig)
;color: determine la couleur des courbes, vecteur, les courbes sont
;       plottees dans l'ordre, dot, med, sig
;linestyle: determine le style du trait des courbes, vecteur, les courbes sont
;           plottees dans l'ordre, med, sig
;xrange:
;yrange:
;overplot: pour faire un oplot
;/xlog:
;/noplot: pour ne pas faire de plot
;
;Parametres de sortie:
;--------------------
;med: retourne le vecteur des valeur medianes a chaque rayon
;sig: retourne le vecteur du bruit (nsig*sig) a chaque rayon
;asec: retourne le vecteur des separations de chaque pixel
;mapsig: retourne une image de sig a chaque pixel

s=size(im) & dimx=s[1] & dimy=s[2]
xc = mean(  cens[*,0] )
yc = mean(  cens[*,1] )


if (n_params() lt 2) then rsum=1.
if (n_params() lt 3) then rmax=100
if (not keyword_set(pixscl)) then pixscl=1.
asec=findgen(rmax+1)*pixscl

;indices des pixels a analyser
indices, im, r=rall, center=[xc, yc]
ind=where(rall le rmax+0.70711,npts)
rall=rall[ind]
;ordonne les points
sind=sort(rall) & rall=rall[sind] & ind=ind[sind]

iall=fltarr(npts)

;masque de l'ouverture et indices des pixels du masque (pour le pixel 0,0)
ic=myaper(im,xc,yc,rsum,mask,imask)
if (rsum eq 0.) then begin
    mask=1.
    imask=yc*dimx+xc
endif
imask=imask-xc-yc*dimx

;calcule l'intensite totale dans le masque pour chaque pixel
;important de ne pas mettre /nan dans le total de la ligne suivante
;mettre /nan transforme les nan a zero et ceci biaise la mediane et le
;sttdev ensuite
for n=0l,npts-1 do iall[n]=total(mask*im[imask+ind[n]])

;fait la mediane et sigma sur les points a des intervalles de 1 pixel
rrall=round(rall)
imed=fltarr(rmax+1) & isig=fltarr(rmax+1)

if (not keyword_set(nsig)) then nsig=1.
for r=1,rmax do begin
    i=where(rrall eq r)
    imed[r]=median(iall[i])
    isig[r]=nsig*robust_sigma(iall[i])
;    isig[r]=nsig*stddev(iall[i],/nan)
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

if (keyword_set(noplot)) then return

;fait les graphes
load8colors
op=0 & ic=0 & il=0
if (keyword_set(overplot)) then op=1
if (not keyword_set(color)) then color=[1,2,3]
if (not keyword_set(linestyle)) then linestyle=[0,0]
if (not keyword_set(psym)) then psym=3
if (not keyword_set(symsize)) then symsize=1.
if (not keyword_set(xrange)) then xrange=[0.,rmax*pixscl]

if (keyword_set(pdot)) then begin
    if (op eq 0) then begin
        plot,rall*pixscl,iall,psym=psym,symsize=symsize,/ylog,xlog=xlog,xrange=xrange,yrange=yrange,/xstyle,/ystyle,xtitle=xtitle,ytitle=ytitle,/nodata
        op=1
    endif
    oplot,rall*pixscl,iall,psym=psym,symsize=symsize,color=color[ic]
    ic=ic+1
endif

if (keyword_set(pmed)) then begin
    if (op eq 0) then begin
        plot,asec,imed,/ylog,xlog=xlog,xrange=xrange,yrange=yrange,/xstyle,/ystyle,linestyle=linestyle[il],xtitle=xtitle,ytitle=ytitle,/nodata
        op=1
    endif
    oplot,asec,imed,color=color[ic],linestyle=linestyle[il]
    ic=ic+1
endif

if (keyword_set(psig)) then begin
    if (op eq 0) then begin
        plot,asec,isig,/ylog,xlog=xlog,xrange=xrange,yrange=yrange,xstyle=1,ystyle=8,linestyle=linestyle[il],xtitle=xtitle,ytitle=ytitle, XCHARSIZE = 1.3, YCHARSIZE = 1.3 ,/nodata
        op=1
    endif
  
    oplot,asec,(isig)^(-1.),color=color[ic],linestyle=linestyle[il]
    AXIS, XAXIS=1, YAXIS=1, YLOG=0, YRANGE = (2.5*(!Y.CRANGE)), XSTYLE = 1, YSTYLE = 1, $  
   YTITLE = 'Contrast (3'+greek('sigma')+' limit) '+greek('Delta')+' Magnitude ', YCHARSIZE = 1.3  ; 
 
    ic=ic+1
endif

loadct,0
end
