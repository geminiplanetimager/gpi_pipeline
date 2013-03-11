;+
; NAME:  gpi_modify_wavcal
;
; 	Lets you manually hack on a wavecal file
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2012-01-31 11:24:11 by Marshall Perrin 
;-


PRO  gpi_modify_wavcal, calfile, datafile, deltax=deltax, deltay=deltay, deltalambda=deltalambda, deltatilt=deltatilt

	compile_opt defint32, strictarr, logical_predicate


newcalfile = repstr(calfile,'.fits', '_mod.fits')

caldata = readfits(calfile, ext_header, ext=1)
pri_header = headfits(calfile)
; cal data is 
;  0: x
;  1: y
;  2: lambda0
;  3: w
;  4: tilt


if keyword_set(deltax) then caldata[*,*,0] += deltax
if keyword_set(deltay) then caldata[*,*,1] += deltay
if keyword_set(deltalambda) then caldata[*,*,2] += deltalambda
if keyword_set(deltatilt) then caldata[*,*,3] += deltatilt


sxaddpar, pri_header, "GPI_MODIFY_WAVCAL: Wav cal tweaked by hand!"
if keyword_set(deltax) then sxaddpar, pri_header, 'DELTAX = '+strc(deltax)
if keyword_set(deltaY) then sxaddpar, pri_header, 'DELTAY = '+strc(deltaY)
if keyword_set(deltaLAMBDA) then sxaddpar, pri_header, 'DELTALAMBDA = '+strc(deltaLAMBDA)
if keyword_set(deltaTILT) then sxaddpar, pri_header, 'DELTATILT = '+strc(deltaTILT)

writefits, newcalfile, 0, pri_header
writefits, newcalfile, caldata, ext_header,/append


; Perform the transposition on the science data before display?
scidata_info = gpi_load_fits(datafile)



gpitv, *scidata_info.image, header=*scidata_info.pri_header, dispwavecalgrid = newcalfile


end
