rootdir = '~/Documents/ifs/Reduced/'
im1 = readfits(rootdir+'120726/S20120726S0166-spdc.fits',/ext)  ;;17 dB
st = systime(1) & sats1 = get_sat_fluxes(im1,band='H',good=good1,cens=cens1,warns=warns1) & print,systime(1) - st
st = systime(1) & sats2 = get_sat_fluxes(im1,band='H',good=good2,cens=cens2,warns=warns2,/refinefits) & print,systime(1) - st

st = systime(1) & sats3 = get_sat_fluxes(im1,band='H',good=good3,cens=cens3,warns=warns3,/gaussfit) & print,systime(1) - st
st = systime(1) & sats4 = get_sat_fluxes(im1,band='H',good=good4,cens=cens4,warns=warns4,/gaussfit,/refinefits) & print,systime(1) - st

im2 = readfits(rootdir+'120726/S20120726S0016-spdc.fits',/ext)  ;;16 dB
im_psfs2 = get_sat_fluxes(im2,band='H',good=good2,cens=cens2,warns=warns2)

cwv = get_cwv('H')
lambda = cwv.lambda

plot_sat_vals,lambda,sats1

fnames = file_search(rootdir+'120720','*.fits')
sats = fltarr(4,37,n_elements(fnames))
for j=0,n_elements(fnames)-1 do begin &$
   im = readfits(fnames[j],/ext) &$
   sats[*,*,j] = get_sat_fluxes(im,band='H') &$
endfor

plot_sat_vals,lambda,sats
write_png,'~/Downloads/sat_vals_300s.png',tvread()

imdat = '120726'
imstart = 122
imcounter = 0
sats2 = fltarr(4,37,10)
for j = 0,9 do begin &$
   fname = rootdir+imdat+'/S20'+imdat+'S'+string(imstart+imcounter,format='(I04)')+'-spdc.fits' &$
   print,fname &$
   im = readfits(fname,/ext) &$
   sats2[*,*,j] = get_sat_fluxes(im,band='H') &$
   imcounter += 1 &$
endfor

plot_sat_vals,lambda,sats2
write_png,'~/Downloads/sat_vals_15s_spher.png',tvread()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rootdir = '~/Documents/ifs/Reduced/'
im1 = readfits(rootdir+'120726/S20120726S0166-spdc.fits',/ext)  ;;17 dB
sats1 = get_sat_fluxes(im1,band='H',good=good1,cens=cens1,warns=warns1)
radial_profile,im1[*,*,0],cens1[*,*,0],imed=imed1,isig=isig1,imn=imn1,asec=asec1

im2 = readfits(rootdir+'120726/S20120726S0161-spdc.fits',/ext)  ;;16 dB
sats2 = get_sat_fluxes(im2,band='H',good=good2,cens=cens2,warns=warns2)
radial_profile,im2[*,*,0],cens2[*,*,0],imed=imed2,isig=isig2,imn=imn2,asec=asec2

im3 = readfits(rootdir+'120720/S20120720S0130-spdc.fits',/ext)  ;;16 dB
sats3 = get_sat_fluxes(im3,band='H',good=good3,cens=cens3,warns=warns3)
radial_profile,im3[*,*,0],cens3[*,*,0],imed=imed3,isig=isig3,imn=imn3,asec=asec3


window,1,xsize=800,ysize=600,retain=2 
plot,/nodata,[min(asec1),max(asec1)],[min([imed1,imed1,imed3]),max([imed1,imed2,imed3])],$
     charsize=1.5, Background=cgcolor('white'), Color=cgcolor('black'),$
     xtitle='Angular separation [Arcsec]',ytitle='Average Flux'
oplot,asec1,imed1,color=fsc_color('red')
oplot,asec2,imed2,color=fsc_color('blue')
oplot,asec3,imed3,color=fsc_color('green')



;;;;;;;;;;;;;;;;;;;;;;;;;;

im2 = readfits(rootdir+'120726/S20120726S0161-spdc.fits',/ext)  ;;16 dB
sats2 = get_sat_fluxes(im2,band='H',good=good2,cens=cens2,warns=warns2)
radial_profile,im2[*,*,0],cens2[*,*,0],imed=imed2,isig=isig2,imn=imn2,asec=asec2
radial_profile,im2[*,*,0],cens2[*,*,0],imed=imed2b,isig=isig2b,imn=imn2b,asec=asec2b
