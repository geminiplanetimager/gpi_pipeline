
;+
; NAME:  fftrot
; 		Rotate an image, using FFTs
;
; 		See for instance
; 		http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=00784442
;
; INPUTS:
; 	imt		image
; 	thetat	rotation angle, in DEGREES
; KEYWORDS:
; 	maxang
; 	/silent	
; 	/nopad	don't pad array - assume that has already been done elsewhere. 
; 			NOTE: DOES NOT WORK YET!
; OUTPUTS:
;
; HISTORY:
;   Code originally by David Lafreniere. 
; 	2008-03-07 English documentation by Marshall Perrin 
;-


;		From: 	  christian.marois@nrc-cnrc.gc.ca
;		Subject: 	fftrot
;		Date: 	March 4, 2008 11:34:31 AM PST
;		To: 	  macintosh1@llnl.gov, mperrin@ucla.edu, rsoummer@amnh.org, poyneer1@llnl.gov
;	
;	Hello all,
;	
;	here's the FFTROT code (David Lafreniere wrote it during his PhD thesis for a
;	paper we were working on but never published). It is discussed in my PhD
;	thesis.
;	
;	-- 
;	Christian Marois, Research Assistant
;	Herzberg Institute of Astrophysics
;	Phone: (250) 363-0023
;	Fax: (250) 363-0045
;

	
function fftrot,imt,thetat,maxang=maxang,silent=silent, nopad=nopad

;fait une rotation de imt d'un angle thetat dans le sens contraire 
;des aiguilles d'une montre
;
;maxang=angle maximum par sous-rotation, defaut est de 10 degres

im=double(imt) & s=size(im) & dim1=s[1] & dim2=s[2]

;ramene l'angle entre 0 et 360 degree
theta=((double(thetat) mod 360.d)+360.d) mod 360.d
if (not keyword_set(silent)) then message,/info,' Angle requested: '+string(theta,format='(d0)')

;ramene ensuite theta entre -45 et 45
;et fait les rotations exactes necessaires
if (theta gt 315) then theta=theta-360.d
if (theta gt -45 and theta le 45) then rotinit=0
if (theta gt 45 and theta le 135) then rotinit=1
if (theta gt 135 and theta le 225) then rotinit=2
if (theta gt 225 and theta le 315) then rotinit=3
im=rotate(im,rotinit)
case rotinit of
    0:
    1: if (dim1 mod 2 eq 0) then im=shift(im,1,0)
    2: begin
        if (dim1 mod 2 eq 0) then im=shift(im,1,0)
        if (dim2 mod 2 eq 0) then im=shift(im,0,1)
    end
    3: if (dim2 mod 2 eq 0) then im=shift(im,0,1)
endcase
if (not keyword_set(silent)) then message,/info,'Performing initial exact rotation of: '+string( 90.d*rotinit,format='(d0)')
;angle restant a faire
theta=theta-90.d*rotinit

if (theta eq 0.) then return,im
;determine le nombre de sous-rotations a faire
if (not keyword_set(maxang)) then maxang=10.d
nrot=ceil(abs(theta/maxang))

;print,double(theta),size(theta)
;print,(maxang),size(maxang)
;print,(nrot),size(nrot)

if (not keyword_set(silent)) then message,/info,'Followed by '+strtrim(nrot,2)+$
  ' FFT rotation(s) of: '+string(theta/double(nrot),format='(d0)')


;theta total a faire en radians
theta=theta*!dpi/180.d
;calcule les dimensions a utiliser
if keyword_set(nopad) then begin
	dimx=dim1
	dimy=dim2
	im = double(im)
endif else begin
	dimx=(ceil(dim1*cos(abs(theta))+dim2*sin(abs(theta)))+1)/2*2
	dimy=(ceil(dim2*cos(abs(theta))+dim2*sin(abs(theta)))+1)/2*2
	;expand dimension x et y
	imtmp=dblarr(dimx,dimy)
	imtmp[(dimx-dim1)/2:(dimx+dim1)/2-1,(dimy-dim2)/2:(dimy+dim2)/2-1]=im
	im=imtmp
endelse
	;construit array des valeurs de x et de y
x=double(lindgen(dimx,dimy) mod dimx)-dimx/2
y=double(lindgen(dimx,dimy)/dimx)-dimy/2

;theta d'une seule sous-rotation
theta=theta/double(nrot)

;+fait les nrot rotations
;print,nrot,size(nrot)
for n=1,nrot do begin

	;fft des rangees
	im=fft(im,dimension=1,/double,/overwrite)
	;fait une translation en x de y*tan(theta/2)
	delta=-y*tan(theta/2.d)
	im=im*shift(dcomplex( cos(2.d*!dpi*delta*x/dimx),-sin(2.d*!dpi*delta*x/dimx) ),dimx/2,0)
	im=fft(im,1,dimension=1,/double,/overwrite)
	;stop

	;fft des colonnes
	im=fft(im,dimension=2,/double,/overwrite)
	;fait une translation en y de -x*sin(theta)
	delta=x*sin(theta)
	im=im*shift(dcomplex( cos(2.d*!dpi*delta*y/dimy),-sin(2.d*!dpi*delta*y/dimy) ),0,dimy/2)
	im=fft(im,1,dimension=2,/double,/overwrite)
	;stop

	;fft des rangees
	im=fft(im,dimension=1,/double,/overwrite)
	;fait une translation en x de y*tan(theta/2)
	delta=-y*tan(theta/2.d)
	im=im*shift(dcomplex( cos(2.d*!dpi*delta*x/dimx),-sin(2.d*!dpi*delta*x/dimx) ),dimx/2,0)
	im=fft(im,1,dimension=1,/double,/overwrite)
	;stop

endfor ;nrot rotations
;-fin des nrotations

;tronque aux dimensions originales
im=im[(dimx-dim1)/2:(dimx+dim1)/2-1,(dimy-dim2)/2:(dimy+dim2)/2-1]

return,real_part(im)
end

