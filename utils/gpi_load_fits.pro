;+
; NAME:  gpi_load_fits
;
;	GPI FITS file loading code
;
;	This is identical to gpi_load_and_preprocess in terms of its output format,
;	but does not preprocess the data in any way. 
;
; INPUTS:
; KEYWORDS:
; 	/nodata		Don't return (or update) the data, just give the headers
; OUTPUTS:
;
; HISTORY:
;	Began 012-01-30 19:15:23 by Marshall Perrin 
;-
;--------------------------------------------------------------------------------


FUNCTION gpi_load_fits, filename, nodata=nodata, silent=silent



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
		currframe = (READFITS(filename , Header, /SILENT))
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
    endif
    if (numext ge 1) then begin
		; at least one extension is present:  Read the 1st extention image into
		; the data array, and read in the primary and extension headers. 
		;  (see below where we append the DRF onto the primary header)
        currframe        = (mrdfits(filename , 1, ext_Header, /SILENT))
		pri_header = headfits(filename, exten=0)
	endif 
		
    if n_elements( currframe ) eq 1 then if currframe eq -1 then begin
        message,/info, "ERROR: Unable to read file "+filename
        return,NOT_OK 
    endif

	if keyword_set(nodata) then return, { pri_header: ptr_new(pri_header), ext_header: ptr_new(ext_header)} else $
    return, {image: ptr_new(currframe), pri_header: ptr_new(pri_header), ext_header: ptr_new(ext_header)}
end


