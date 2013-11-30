;+
; NAME:  gpi_readfits
;
;	Utility function for loading possibly-multi-extension FITS files
;	for GPI:
;		1) if the file has no extensions, just read the primary HDU
;		2) if the file does have image extensions, read the first one. 
;
;	See also: gpi_load_fits which does a more thorough job of loading everything
;
; INPUTS: filename
; KEYWORDS:	
; 	header		for returning the header
; OUTPUTS:	data
;
;
; HISTORY:
; 	Began 2011-07-29 18:37:06 by Marshall Perrin 
;-

FUNCTION gpi_readfits, filename, header=header

	compile_opt defint32, strictarr, logical_predicate
	fits_info, filename, n_ext = numexten, /silent

	return, mrdfits(filename, numexten gt 0, header,/silent)

  	;if numexten eq 0 then data= readfits(filename, header) else data = mrdfits(filename,1, header)
	;return, data

end

