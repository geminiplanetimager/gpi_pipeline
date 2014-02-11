;+
; NAME:  gpi_badpix_edit
;
;	Utility for manual editing of a GPI bad pixel file
;
;   Example:
;    IDL> gpi_badpix_edit, 'S20140101S0123_badpix.fits', 1024, 650, 1
;    
;    That will mark pixel [1024, 650] as bad. The output will be 
;    saved to S20140101S0123_badpix_edited.fits
;	
;	 In addition to changing the pixel value (which is trivially simple after all)
;	 this routine updates the FITS header history so there's a record of
;	 the manual change. 
;
; INPUTS:	
;	filename	name of a FITS file containing bad pixel mask
;	x,y			integer pixel coordinates
;	val			new value for bad pixel mask at [x,y]
;
; OUTPUTS:
;   A modified bad pixel mask is written to a new filename, 
;   generated as the input filename plus '_edited'
;
; HISTORY:
;	Began 2013-12-11 16:52:01 by Marshall Perrin 
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
