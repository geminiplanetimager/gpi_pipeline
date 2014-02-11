;+
; NAME: adr_n
;
; 	atmospheric differential refraction
;
; 	calculates the index of refraction, n, as a function
; 	of wavelength, pressure, temperature, and precipitable water vapor
;
; 	see paper by henry roe, PASP 2002.
;
; 	This function has been tested and confirmed to reproduce the
; 	same answers as in his paper.
; 	
;
; INPUTS:
;	lambda		wavelength in microns
;	pressure	inmillibar
;	temperature	in Kelvin
;	pw			precipitable water vapor in mm
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2003-12-23 06:50:08 by Marshall Perrin 
;-

function adr_n, lambda, pressure=p, Temperature=t, pw=pw

ps = 1013.25	; millibar
Ts = 288.15		; K
if not(keyword_set(p)) then p=ps
if not(keyword_set(T)) then T=Ts
if not(keyword_set(pw)) then pw=0


return, 1+$
	(64.328+ 29498.1/(146-lambda^(-2))+ 255.4/(41-lambda^(-2)))*$
	(p*Ts/(ps*T))*1e-6 $
	-43.49*(1.-(7.956e-3/lambda^2))*pw/ps*1e-6
	

end
