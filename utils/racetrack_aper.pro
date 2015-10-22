function racetrack_aper, img, imgspare,xpos, ypos, rotang, aper_radii, halflength,spot, uttimeobs, targetname,ncoadd, sysgain

;if not keyword_set(spot_halflen) then spot_halflen = 5.7 

;;this is not actually the half length of the radon spot, 
;;it is the length from the center of the spot to the furthest spot peak 
;;(i.e. peak of the spot in spectral mode in the shortest or longest wavelength of the band). This is only currently true in H band

;///////////////////
rotang *= -1

where_nan=where(~FINITE(img))
img[where_nan]=0
spot_halflen=halflength
dims = size(img,/dim)


xcoord = indgen(dims[0], dims[1], /long) mod dims[0]
ycoord = indgen(dims[0], dims[1], /long) / dims[0] ;integer division

xppos = cos(rotang)*xpos - sin(rotang)*ypos
yppos = sin(rotang)*xpos + cos(rotang)*ypos
xpcoord = cos(rotang)*xcoord - sin(rotang)*ycoord
ypcoord = sin(rotang)*xcoord + cos(rotang)*ycoord


aperrad = aper_radii[0]
inskyrad = aper_radii[1]
outskyrad = aper_radii[2]

FDF=dindgen(7) ; output with flux, deltaflux, median sky, mode sky


source_mid = (ypcoord gt yppos-aperrad) and (ypcoord lt yppos+aperrad) and (xpcoord gt xppos - spot_halflen) and (xpcoord lt xppos + spot_halflen)
source_bot = ((xpcoord lt xppos - spot_halflen) and ((ypcoord-yppos)^2 + (xpcoord-(xppos-spot_halflen))^2 lt aperrad^2))
source_top = ((xpcoord gt xppos + spot_halflen) and ((ypcoord-yppos)^2) + (xpcoord-(xppos+spot_halflen))^2 lt aperrad^2)

source = where( source_mid or source_bot or source_top, countsource )
;source = where( ((ypcoord gt yppos-5) and (ypcoord lt yppos+5) and (xpcoord gt xppos - 5.7) and (xpcoord lt xppos + 5.7)) or ((xpcoord lt xppos - 5.7) and ((ypcoord-yppos)^2 + (xpcoord-(xppos-5.7))^2 lt 5^2)) or ((xpcoord gt xppos + 5.7) and ((ypcoord-yppos)^2) + (xpcoord-(xppos+5.7))^2 lt 5^2), countsource )

insky_mid = ((ypcoord lt yppos - inskyrad) or (ypcoord gt yppos + inskyrad)) 
insky_bot =  ((xpcoord lt xppos - spot_halflen) and ((ypcoord-yppos)^2 + (xpcoord-(xppos-spot_halflen))^2 gt inskyrad^2))
insky_top =  ((xpcoord gt xppos + spot_halflen) and ((ypcoord-yppos)^2) + (xpcoord-(xppos+spot_halflen))^2 gt inskyrad^2)

outsky_mid = ((ypcoord gt yppos - outskyrad) and (ypcoord lt yppos + outskyrad) and (xpcoord gt xppos - spot_halflen) and (xpcoord lt xppos + spot_halflen)) 
outsky_bot =  ((xpcoord lt xppos - spot_halflen) and ((ypcoord-yppos)^2 + (xpcoord-(xppos-spot_halflen))^2 lt outskyrad^2)) 
outsky_top =  ((xpcoord gt xppos + spot_halflen) and ((ypcoord-yppos)^2) + (xpcoord-(xppos+spot_halflen))^2 lt outskyrad^2)

sky=  where( (insky_mid or insky_bot or insky_top) and (outsky_mid or outsky_bot or outsky_top) , countsky)
;print, 'Pixels in Aperture: ', n_elements(source)
;print, 'Calling MMM:'
mmm, img[sky], skymode, READNOISE=5
;READNOISE 2 at 88 CDS Reads, 

flux = (total(img[source]) - median(img[sky])*countsource ) ;FLUX per coadd.

;print, '';
;print,'Sky Values at Satellite Spots'
;print, 'Mean and Median Sky Values: ', mean(img[sky]), median(img[sky])
;print, 'Pixels used: ', countsky

deltaF = sqrt( (1./sysgain)*( (total(img[source])-countsource*median(img[sky])) )/(ncoadd) +(countsource + (countsource^2/countsky))*stddev(img[sky])^2 )

FDF[0]=flux                ;satspot flux
FDF[1]=deltaF              ;satspot delta flux
FDF[2]=median(img[sky])    ;sky median
FDF[3]=stddev(img[sky])    ;sky stddev 
FDF[4]=skymode             ; sky mode 
FDF[5]=n_elements(source)  ; #pixels in source
FDF[6]=n_elements(sky)     ; # pixels in sky  
;/// Printing

print, 'SAT SPOT FLUX (ADU coadd-1):  ', FDF[0] , ' DELTA FLUX (ADU coadd-1):  ', FDF[1]
print, 'SKY MEDIAN, STDDEV and MODE:  ', FDF[2], ' ', FDF[3], ' ', FDF[4]

imgspare[source]=100000
;IM=image(img[*,*,0])
img[where_nan]=!values.f_nan
imgspare[sky]=!values.f_nan
return, FDF


end



