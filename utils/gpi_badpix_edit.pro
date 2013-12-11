;+
; NAME:  
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;	Began 013-12-11 16:52:01 by Marshall Perrin 
;-


PRO gpi_badpix_edit, filename, x, y, val

	data= gpi_load_fits(filename)

	(*data.image)[x[0],y[0]] = fix(val[0])
	logmsg = "   pixel "+printcoo(x[0],y[0])+" set to "+strc(fix(val[0]))
	message,/info, logmsg

	sxaddpar, *data.pri_header, "HISTORY", "GPI_BADPIX_EDIT: User is manually editing bad pixel map"
	sxaddpar, *data.pri_header, "HISTORY", logmsg


	outfn = strepex(filename, '.fits', '_edited.fits')

	mwrfits, 0, outfn, *data.pri_header,/create
	mwrfits, *data.image, outfn, *data.ext_header,/silent

	message,/info, 'Output saved to '+outfn



end
