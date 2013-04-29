;Very simplistic SSDI algorithm for testing and QL application
;C. Marois April 5th, 2013.

;Input parameters
;I1: image1
;I2: image2
;L1M: wavelength of image 1
;L2M: wavelength of image 2
;knumin: normalization factor between image 1 and 2 (-1 to have the soft search for the best one)

;Output parameters
;vscaleopt and knum are output parameters

function gpi_ssdi,I1,I2,L1m,L2m,vscaleopt,knumin,knum

;Image magnification with ROT
locs =  find_sat_spots(I1)

;Search for optimal image magnification
vres=fltarr(200)
vscale=make_array(200,/index)
vscale=1+0.1*(vscale-100.)/100

knum=1.
if knumin ne -1 then knum=double(knumin)

for icm=0,199 do begin
 I1s=rot(I1,0,vscale[icm]*double(L2m)/double(L1m),mean(locs[0,*]),mean(locs[1,*]),/pivot,cubic=-0.5)
 diffsdi=I1s-knum[0]*I2
 vres[icm]=median([stddev(diffsdi[locs[0,0]-10:locs[0,0]+10,locs[1,0]-10:locs[1,0]+10]),$
 stddev(diffsdi[locs[0,1]-10:locs[0,1]+10,locs[1,1]-10:locs[1,1]+10]),$
 stddev(diffsdi[locs[0,2]-10:locs[0,2]+10,locs[1,2]-10:locs[1,2]+10]),$
 stddev(diffsdi[locs[0,3]-10:locs[0,3]+10,locs[1,3]-10:locs[1,3]+10])])
endfor
vmin=min(vres)
jmin=where(vres eq vmin)
vscaleopt=vscale[jmin]
;-----

;Final magnification for SSDI subtraction - do magnification at average spot location
 I1s=rot(I1,0,vscaleopt[0]*double(L2m)/double(L1m),mean(locs[0,*]),mean(locs[1,*]),/pivot,cubic=-0.5)

;Smooth out pixel-to-pixel noise (usually limiting factor in SSDI subtraction)
smoothfact=1

;Image smoothing
I1s=smooth(I1s,2,/nan)
I2=smooth(I2,2,/nan)
;Factor 1.2855 is to account for smoothing in the contrast calculation
smoothfact=1.28555

if knumin eq -1 then begin
 vres=fltarr(100)
 vint=make_array(100,/index)
 vint=1.+(0.2*vint/100.-0.1)
 for icm = 0 , 99 do begin
  diffsdi=I1s-vint[icm]*I2
  vres[icm]=median([stddev(diffsdi[locs[0,0]-10:locs[0,0]+10,locs[1,0]-10:locs[1,0]+10]),$
  stddev(diffsdi[locs[0,1]-10:locs[0,1]+10,locs[1,1]-10:locs[1,1]+10]),$
  stddev(diffsdi[locs[0,2]-10:locs[0,2]+10,locs[1,2]-10:locs[1,2]+10]),$
  stddev(diffsdi[locs[0,3]-10:locs[0,3]+10,locs[1,3]-10:locs[1,3]+10])])
 endfor
 vmin=min(vres)
 jmin=where(vres eq vmin)
 knum[0]=vscale[jmin]
endif

return,smoothfact*(I1s-knum[0]*I2)

end