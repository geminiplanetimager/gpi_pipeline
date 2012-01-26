;;		From: 	  christian.marois@nrc-cnrc.gc.ca
;;		Subject: 	Re: idl code
;;		Date: 	February 29, 2008 9:02:20 AM PST
;;		To: 	  mperrin@ucla.edu
;;	
;;	Hello Marshall,
;;	
;;	the software is not released yet (it is something I wrote on the side during my PhD thesis), so everything is in French etc, but I think it will be good enough for what you want to do. I'll do an official GPI version in the next few weeks.
;;	
;;	You simple call the software via im2=fftscale(im1,scalex,scaley,precision)
;;	
;;	where scalex and scaley are the scale parameters in X and Y. You 
;;	currently needs to use the same scale in both axis since I haven't 
;;	modified the soft to do a none equal spatial scale. The precision 
;;	keyword is the scale precision that you want (Delta scale/scale, 
;;	typically ~10^-7). You have the option to modify the pixel MTF, 
;;	but that is not really useful for simulated data. The soft does a 
;;	2 iterations image & Fourier planes zero padding to find the best 
;;	possible combination of zero padding to do the image spatial scale. 
;;	The worse case scenario is to do a ~1x scale. What you want to do in 
;;	these cases is to do a combination of 2 scales to avoid a ~1x scale 
;;	(like if you want to do a 1.01x scale, you do a 1.1x scale followed by 
;;	a (1.01/1.1)x scale).
;;	
;;	Good luck and let me know if it works,
;;	
;;	-- 
;;	Christian Marois, Research Assistant
;;	Herzberg Institute of Astrophysics
;;	Phone: (250) 363-0023
;;	Fax: (250) 363-0045


;+
; NAME: FFTSCALE
;   Change l'echelle spatiale d'une image par FFT. Determination des echelles des images et scale des images C. Marois
;
; INPUTS:
; 	imin		an image
; 	scxin		scale in X
; 	scyin		scale in Y  **MUST EQUAL SCXIN RIGHT NOW**
; 	rapprec		Fractional precision, typically 1e-7
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	By Christian Marois
; 	2008-03-07  Documentation in English added by Marshall Perrin
;-

function fftscale,imin,scxin,scyin,rapprec,mtfpixcor=mtfpixcor,$
	silent=silent,scxout=scxout,scyout=scyout,dimout=dimout

scx=double(scxin)
scy=double(scyin)

im=double(imin)
s=size(im)
dimx=s[1]
dimy=s[2]
meilprec=1E10
found=0

if scx eq scy then begin
	if scx ge 1.d then begin
		for i=0,1023 do begin
			padinit=dimx+i
			for j=0,scx*padinit-1 do begin
				padfft=padinit+j
				scx1=double(padfft)/double(padinit)
				for k=0,(scx-scx1)*dimx do begin
					padinit2=dimx+k
					padfft2=round((scx/scx1)*padinit2)
					scx2=double(padfft2)/double(padinit2) 

					prec=abs(scx1*scx2/scx-1.d)
					scf=scx1*scx2

					if abs(prec) lt meilprec and scx ge 1.d and scx1 ge 1.d and scx2 ge 1.d then begin
						padinitF=padinit
						padfftF=padfft
						padinit2F=padinit2
						padfft2F=padfft2
						if keyword_set(scxout) then scxout=scf
						if keyword_set(scyout) then scyout=scf
						meilprec=abs(prec)
						scfF=scf
						if abs(prec) lt rapprec then found=1
						if abs(prec) lt rapprec then break
					endif

				endfor
				if abs(prec) lt rapprec then break
			endfor
			if abs(prec) lt rapprec then break
		endfor
	endif

	if scx lt 1.d then begin
		for i=0,1023 do begin
			padinit=dimx+i
			for j=0,padinit-scx*padinit-1 do begin
				padfft=padinit-j
				scx1=double(padfft)/double(padinit)
				for k=0,1023 do begin
					padinit2=dimx+k
					padfft2=round((scx/scx1)*padinit2)
					scx2=double(padfft2)/double(padinit2)

					prec=abs(scx1*scx2/scx-1.d)
					scf=scx1*scx2

					if abs(prec) lt meilprec and scx lt 1.d and padfft2 lt 1023 then begin
						padinitF=padinit
						padfftF=padfft
						padinit2F=padinit2
						padfft2F=padfft2
						scfF=scf
					if keyword_set(scxout) then scxout=scf
					if keyword_set(scyout) then scyout=scf
					meilprec=abs(prec)
					if abs(prec) lt rapprec then found=1
					if abs(prec) lt rapprec then break
					endif
				endfor
				if abs(prec) lt rapprec then break
			endfor
			if abs(prec) lt rapprec then break
		endfor
	endif

	if found eq 0 then begin
	if not keyword_set(silent) then print,'Pas de scale trouve... Conservation du meilleur scale'
endif

padinit=padinitF
padinit2=padinit2F
padfft=padfftF
padfft2=padfft2F
scf=scfF

if not keyword_set(silent) then begin
	print,'Dim init = ',dimx,' Dim init + pad = ',padinit
	print,'Dim FFT init = ',padinit,' Dim FFT init + pad = ',padfft

	print,'Dim init 2 = ',dimx,' Dim init + pad = ',padinit2
	print,'Dim FFT init 2 = ',padinit2,' Dim FFT init + pad = ',padfft2

	print,'Scale demande = ',scx,' Scale obtenu = ',scf
	print,'Precision = ',meilprec
endif


;stop

;ITERATION 1
if padinit ne padfft then begin
	padim=dblarr(padinit,padinit)
	padim[floor(padinit/2)-floor(dimx/2):floor(padinit/2)+floor(dimx/2)-1,floor(padinit/2)-floor(dimy/2):floor(padinit/2)+floor(dimy/2)-1]=im
	padim=shift(padim,-floor(padinit/2),-floor(padinit/2)) 

	imfft=fft(padim,1,/double)
	imfftr=shift(real_part(imfft),floor(padinit/2),floor(padinit/2))
	imffti=shift(imaginary(imfft),floor(padinit/2),floor(padinit/2))

	padfftr=dblarr(padfft,padfft)
	padffti=dblarr(padfft,padfft)

	if padfft ge padinit then begin
		imimp=padinit mod 2

		padfftr[floor(padfft/2)-floor(padinit/2):floor(padfft/2)+floor(padinit/2)-1+imimp,floor(padfft/2)-floor(padinit/2):floor(padfft/2)+floor(padinit/2)-1+imimp]=imfftr

		padffti[floor(padfft/2)-floor(padinit/2):floor(padfft/2)+floor(padinit/2)-1+imimp,floor(padfft/2)-floor(padinit/2):floor(padfft/2)+floor(padinit/2)-1+imimp]=imffti
	endif

	if padfft lt padinit then begin
		imimp=padfft mod 2

		padfftr=imfftr[floor(padinit/2)-floor(padfft/2):floor(padinit/2)+floor(padfft/2)-1+imimp,floor(padinit/2)-floor(padfft/2):floor(padinit/2)+floor(padfft/2)-1+imimp]

		padffti=imffti[floor(padinit/2)-floor(padfft/2):floor(padinit/2)+floor(padfft/2)-1+imimp,floor(padinit/2)-floor(padfft/2):floor(padinit/2)+floor(padfft/2)-1+imimp]
	endif

	padfftim=dcomplex(shift(padfftr,-floor(padfft/2),-floor(padfft/2)),shift(padffti,-floor(padfft/2),-floor(padfft/2)))

	psf=fft(padfftim,-1,/double)

	rpsf=shift(real_part(psf),floor(padfft/2),floor(padfft/2))

	if padfft ge dimx then begin
		imimp=dimx mod 2
		im=rpsf(floor(padfft/2)-floor(dimx/2):floor(padfft/2)+floor(dimx/2)-1+imimp,floor(padfft/2)-floor(dimx/2):floor(padfft/2)+floor(dimx/2)-1+imimp)
	endif

	if padfft lt dimx then begin
		im=dblarr(dimx,dimy)
		imimp=padfft mod 2
		im[floor(dimx/2)-floor(padfft/2):floor(dimx/2)+floor(padfft/2)-1+imimp,floor(dimx/2)-floor(padfft/2):floor(dimx/2)+floor(padfft/2)-1+imimp]=rpsf
	endif

; imimp=dimx mod 2
	                         ;
;
; im=rpsf(floor(padfft/2)-floor(dimx/2):floor(padfft/2)+floor(dimx/2)-1+imimp,floor(padfft/2)-floor(dimx/2):floor(padfft/2)+floor(dimx/2)-1+imimp) 
endif


;ITERATION 2
if padinit2 ne padfft2 then begin
	padim=dblarr(padinit2,padinit2)


	padim[floor(padinit2/2)-floor(dimx/2):floor(padinit2/2)+floor(dimx/2)-1,floor(padinit2/2)-floor(dimy/2):floor(padinit2/2)+floor(dimy/2)-1]=im
	padim=shift(padim,-floor(padinit2/2),-floor(padinit2/2))

	imfft=fft(padim,1,/double)
	imfftr=shift(real_part(imfft),floor(padinit2/2),floor(padinit2/2))
	imffti=shift(imaginary(imfft),floor(padinit2/2),floor(padinit2/2))

	padfftr=dblarr(padfft2,padfft2)
	padffti=dblarr(padfft2,padfft2)

	if padfft2 ge padinit2 then begin
	imimp=padinit2 mod 2

	padfftr[floor(padfft2/2)-floor(padinit2/2):floor(padfft2/2)+floor(padinit2/2)-1+imimp,floor(padfft2/2)-floor(padinit2/2):floor(padfft2/2)+floor(padinit2/2)-1+imimp]=imfftr

	padffti[floor(padfft2/2)-floor(padinit2/2):floor(padfft2/2)+floor(padinit2/2)-1+imimp,floor(padfft2/2)-floor(padinit2/2):floor(padfft2/2)+floor(padinit2/2)-1+imimp]=imffti
	endif

	if padfft2 lt padinit2 then begin
	imimp=padfft2 mod 2

	padfftr=imfftr[floor(padinit2/2)-floor(padfft2/2):floor(padinit2/2)+floor(padfft2/2)-1+imimp,floor(padinit2/2)-floor(padfft2/2):floor(padinit2/2)+floor(padfft2/2)-1+imimp]

	padffti=imffti[floor(padinit2/2)-floor(padfft2/2):floor(padinit2/2)+floor(padfft2/2)-1+imimp,floor(padinit2/2)-floor(padfft2/2):floor(padinit2/2)+floor(padfft2/2)-1+imimp]
endif

	if keyword_set(mtfpixcor) then begin
	if not keyword_set(silent) then print,"Correction pour la difference des mtfs des pixels..."
	scalefact=double(double(scx))
	pixmtf1=double(mtfpix(3.6,1.6,padfft2,0.018,xc=0.,yc=0.,scfact=scalefact))
	pixmtf2=double(mtfpix(3.6,1.6,padfft2,0.018,xc=0.,yc=0.))
	padfftim=dcomplex(shift(padfftr*pixmtf2/pixmtf1,-floor(padfft2/2),-floor(padfft2/2)),shift(padffti*pixmtf2/pixmtf1,-floor(padfft2/2),-floor(padfft2/2)))
	endif

	if not keyword_set(mtfpixcor) then padfftim=dcomplex(shift(padfftr,-floor(padfft2/2),-floor(padfft2/2)),shift(padffti,-floor(padfft2/2),-floor(padfft2/2)))

	psf=fft(padfftim,-1,/double) 

	rpsf=shift(real_part(psf),floor(padfft2/2),floor(padfft2/2))

	fpsf=dblarr(dimx,dimy)

	if keyword_set(dimout) then dimx=dimout
	if padfft2 ge dimx then begin
	imimp=dimx mod 2
	fpsf=rpsf(floor(padfft2/2)-floor(dimx/2):floor(padfft2/2)+floor(dimx/2)-1+imimp,floor(padfft2/2)-floor(dimx/2):floor(padfft2/2)+floor(dimx/2)-1+imimp)
	endif

	if padfft2 lt dimx then begin
	imimp=padfft2 mod 2
	fpsf[floor(dimx/2)-floor(padfft2/2):floor(dimx/2)+floor(padfft2/2)-1+imimp,floor(dimx/2)-floor(padfft2/2):floor(dimx/2)+floor(padfft2/2)-1+imimp]=rpsf
	endif

endif

if padinit2 eq padfft2 then fpsf=im


return,fpsf

endif


end





