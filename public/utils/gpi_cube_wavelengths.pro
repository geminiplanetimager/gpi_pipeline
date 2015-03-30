;+
; NAME: gpi_cube_wavelengths
;
; 	Return the wavelengths for each slice of a datacube, based on the FITS
; 	header keywords. 
;
; 	Simple convenience function.
;
; INPUTS:
; 	extheader	an extension header from a GPI datacube (with the WCS keywords
; 	 			in place)
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2013-04-25 21:39:10 by Marshall Perrin 
;-


FUNCTION gpi_cube_wavelengths, extheader


	; In accordance with Gemini standard, preferentially look to CD3_3 for the
	; wavelength axis step size, but fall back to CDELT3 for compatibility with 
	; earlier GPI data products.  - MP 2012-12-09
    cd3 = sxpar(extheader, "CD3_3", count=cw1) ;wav increm
    if cw1 eq 0 then cd3 = sxpar(extheader, "CDELT3", count=cw1) ;wav increm

	; for pixel coordinates, recall these must be in the FITS convention where
	; pixel indices start at 1, not 0. 
    crpix3 = sxpar(extheader,"CRPIX3", count=cw2) ;pix coord. of ref. point

	if crpix3 eq 0 then begin
		message, 'wavelength reference pixel CRPIX3 is 0, outside of the actual datacube',/info
		message, 'Assuming this is an older non-FITS-WCS compliant header and guessing that ',/info
		message, 'CRPIX=1 for the first spectral slice is what was actually meant.',/info
		crpix3=1
	endif

    crval3 = sxpar(extheader, "CRVAL3", count=cw3) ;wav value at ref point
    nax3   = sxpar(extheader, "NAXIS3", count=cw4) ;size of axis
    
    if (cw1+cw2+cw3+cw4) ne 4 then begin
        self->message, msgtype = 'error', 'At least one FITS keyword of CTYPE3, CD3_3/CDELT3, CRPIX3, CRVAL3, NAXIS3 appears to be missing. Wavelength solution may not be properly calculated.'
		return, !values.f_nan
	endif

    
	wavelengths = (findgen(nax3) - (CRPIX3-1)) * cd3 + CRVAL3
	return, wavelengths

end
