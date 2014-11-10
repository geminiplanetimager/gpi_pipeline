;+
; NAME: gpi_shift_wavecal 
;		Manually adjust a wavecal file by applying some shift. 
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;	Began 013-12-09 01:31:52 by Marshall Perrin 
;-

pro gpi_shift_wavecal, filename, dx, dy

	data = readfits(filename, ext=1, extheader,/silent)
	priheader = headfits(filename,/silent)


	sxaddpar,priheader, 'HISTORY', 'gpi_shift_wavecal: Manually applying shifts to wavecal file.'
	sxaddpar,priheader, 'HISTORY', 'gpi_shift_wavecal:   Shifts = '+printcoo(dx, dy)+" pix dx, dy"
	sxaddpar,priheader, 'HISTORY', 'gpi_shift_wavecal:   Input filename was '
	sxaddpar,priheader, 'HISTORY', 'gpi_shift_wavecal:   '+filename

	data[*,*,0] += dy
	data[*,*,1] += dx

	outfn = strepex(filename, '.fits', '_shifted.fits')

	mwrfits, 0, outfn, priheader,/create
	mwrfits, data, outfn, extheader

	message,/info, 'Attempt at a repaired wavecal written to :'
	message,/info, '   '+outfn



end
