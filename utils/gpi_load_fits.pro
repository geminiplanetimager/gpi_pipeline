;+
; NAME:  gpi_load_fits
;
;	GPI FITS file loading code
;
;	This loads a Gemini MEF-format FITS file with GPI data into memory,
;	returning it as a structure containing pointers to the data and headers. 
;
;   Optionally, for older/non-standards-compliant FITS files, this can 
;   "preprocess" the FITS headers to standardize & update them to the current
;   format. This is done by handing off execution to
;   gpi_load_and_preprocess_fits_file instead. Whether or not this happens is
;   controlled by the pipeline setting variable 'preprocess_fits_files'.
;
;
; INPUTS:
; KEYWORDS:
; 	/nodata		Don't return (or update) the data, just give the headers.
;				This is of course faster, for cases where you just need the
;				headers.
; 	/silent		Don't display any text on screen while working.
; OUTPUTS:
;
; HISTORY:
;	Began 2012-01-30 19:15:23 by Marshall Perrin 
;	2012-12-08 MP: Added support for reading in DQ and Uncert extensions, if
;					present
;
;-
;--------------------------------------------------------------------------------


FUNCTION gpi_load_fits, filename, nodata=nodata, silent=silent, _extra=_extra

	compile_opt defint32, strictarr, logical_predicate


	if gpi_get_setting('preprocess_fits_files',/bool,default=0,/silent) then begin
		return, gpi_load_and_preprocess_fits_file( filename, nodata=nodata, silent=silent, _extra=_extra)
	endif

	; This loads the files into the local variables:
	;	currframe
	;	pri_header
	;	ext_header
	; It then returns an anonymous struct containing pointers to those three
	; items. 

	NOT_OK =  -1

    if ~file_test(filename,/read) then begin
        message,/info, "ERROR: File does not exist: "+filename
        return,NOT_OK
    endif

	; Read in the file, and check whether it is a single image or has
	; extensions.
    fits_info, filename, n_ext = numext, /silent
    if (numext EQ 0) then begin
		; No extension present: Read primary image into the data array
		;  and copy the only header into both the primary and extension headers
		;  (see below where we append the DRF onto the primary header)
		;
		if keyword_set(nodata) then begin
			header = headfits(filename,/silent)
		endif else begin
			currframe = (READFITS(filename , Header, /SILENT))
		endelse

		pri_header=header
		;*(*self.data).HeadersExt[IndexFrame] = header
		;fxaddpar,  *(*self.data).HeadersExt[IndexFrame],'HISTORY', 'Input image has no extensions, so primary header copied to 1st extension'
		mkhdr,ext_header,currframe
		sxaddpar,ext_header,"XTENSION","IMAGE","Image extension",before="SIMPLE"
		sxaddpar,ext_header,"EXTNAME","SCI","Image extension contains science data";,before="SIMPLE"
		sxaddpar,ext_header,"EXTVER",1,"Number assigned to FITS extension";,before="SIMPLE"
		sxdelpar, ext_header, "SIMPLE"
		;add blank wcs keyword in extension (mandatory for all gemini data)
		wcskeytab=["CTYPE1","CD1_1","CD1_2","CD2_1","CD2_2","CDELT1","CDELT2",$
		  "CRPIX1","CRPIX2","CRVAL1","CRVAL2","CRVAL3","CTYPE1","CTYPE2"]
		for iwcs=0,n_elements(wcskeytab)-1 do $
		sxaddpar,ext_header,wcskeytab[iwcs],'','',before="END"
		;*(*self.data).HeadersExt[IndexFrame] = ext_header

    endif else if (numext ge 1) then begin
		; at least one extension is present:  Read the 1st extention image into
		; the data array, and read in the primary and extension headers. 
		;  (see below where we append the DRF onto the primary header)
		if keyword_set(nodata) then begin
			pri_header = headfits(filename, exten=0, /silent)
			ext_header = headfits(filename, exten=1, /silent)
		endif else begin
			currframe        = (mrdfits(filename , 1, ext_Header, /SILENT))
			pri_header = headfits(filename, exten=0, /silent)
		endelse


	endif 
		
    if n_elements( currframe ) eq 1 then if currframe eq -1 then begin
        message,/info, "ERROR: Unable to read file "+filename
        return,NOT_OK 
    endif

	; If user just wants the headers, then we're done and can return that here:
	if keyword_set(nodata) then return, { pri_header: ptr_new(pri_header,/no_copy), ext_header: ptr_new(ext_header,/no_copy)} 
	
	; Save headers and image as a structure:
    mydata = {image: ptr_new(currframe,/no_copy), pri_header: ptr_new(pri_header,/no_copy), ext_header: ptr_new(ext_header,/no_copy)}

	; Now, check for the presence of additional extensions
	for iext=2,numext do begin
		ext2data  = (mrdfits(filename , iext, ext2_Header, /SILENT))
		extname = strc(sxpar(ext2_Header, 'EXTNAME'))
		mydata = create_struct(mydata, extname, ptr_new(ext2data,/no_copy))
	endfor
	


	return, mydata
end


