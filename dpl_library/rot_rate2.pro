;+
; NAME:  rot_rate2.pro
;
;		retourne le taux de rotation du champ en rad/sec pour
;		un objet de declinaison dec, a un angle horaire h
;
; INPUTS:
;		h en heures
;		dec en degres
;
;		pour avoir le temp requis pour rotation d'une fwhm a un rayon donne, specifier:
;		r=r en asec
;		fwhm=fwhm en asec
;
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;originally DLafreniere?CMarois?
;  2007-01 JerMaire changed to function
function rot_rate2,h,dec,lat,r=r,fwhm=fwhm


;latitude
phi=double(lat)*!dtor

;angle au zenith
z=acos( (sin(dec*!dtor)*sin(phi)+cos(dec*!dtor)*cos(phi)*cos(h*15.*!dtor))<1.>(-1.) )

;angle d'azimuth
a=acos( ((cos((90.-dec)*!dtor)-sin(phi)*cos(z)) / (cos(phi)*sin(z)))<1.>(-1.) )

;angle de rotation en rad/sec
w=7.2925e-5*cos(a)*cos(phi)/sin(z)

if ~keyword_set(fwhm) or ~keyword_set(r) then return,w

;angle qu'on doit tourner en asec
theta=(float(fwhm)/r)
;temp requis pour tourner de ce temp la
t=abs(theta/w)
return,t

end
