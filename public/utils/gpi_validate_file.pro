;+
; NAME:  gpi_validate_file
;
;	Determine if a given file is indeed a valid GPI data file
;	that can be used in the pipeline. 
;
;	Used in the data parser.
;
; INPUTS:
; 	filename	FITS filename
;
; RETURNS:
; 	1 if the file is valid, 
; 	or 3 if it's invalid but strict validation is disabled.
; 	0 if the file is invalid and strict validation is enabled. 
;
; NOTES:
;
;	Could be extended to also handle aborted files and other reasons to ignore
;	something.
;
; HISTORY:
; 	Began 2012-01-31 00:45:08 by Marshall Perrin 
; 			(based on the various validkeyword routines that were 
; 			 spread in redundant copies around various .pro files)
;-

compile_opt defint32, strictarr, logical_predicate

forward_function gpi_validate_file_one_keyword

FUNCTION gpi_validate_file_one_keyword, file_data, keyword, requiredvalue, verbose=verbose, numeric=numeric, _extra=_extra

	val = gpi_get_keyword(*(file_data.pri_header), *(file_data.ext_header), keyword, count=ct)
	if ct eq 0 then begin 
        if keyword_set(verbose) then print, "No match for required keyword "+keyword
        return, 0 
        
    endif else begin
		if keyword_set(numeric) then begin
			matchedvalue = val eq requiredvalue
		endif else begin
			matchedvalue=stregex(val, requiredvalue,/boolean,/fold_case)
		endelse
		if matchedvalue ne 1 then begin
            if keyword_set(verbose) then print, "No match for required keyword value "+requiredvalue+" for keyword "+keyword
            return, 0 
        endif
	endelse
	return, 1 ; valid


end


;-----------------------------------------------------
FUNCTION gpi_validate_file, filename,verbose=verbose
	forward_function gpi_validate_file_one_keyword


	if not file_test(filename) then begin
		message,/info, 'File '+filename+" does not exist."
		return, 0
	endif 

	file_data = gpi_load_fits(filename,/nodata,/fast)

	val1 = gpi_validate_file_one_keyword(file_data, 'TELESCOP','Gemini*',/test, verbose=verbose)
	val2 = gpi_validate_file_one_keyword(file_data, 'INSTRUME','GPI', verbose=verbose)
	val3 = gpi_validate_file_one_keyword(file_data, 'INSTRSUB','IFS', verbose=verbose)
	
	if val1+val2+val3 eq 3 then valid=1 else valid=0

	;if valid eq 1 then return, 1 else begin
	if valid ne 1 then begin
		STRICT_VALIDATION= gpi_get_setting('strict_validation',/bool, default=1,/silent)
		if STRICT_VALIDATION then begin
			message,/info, "File "+filename+" is NOT a valid Gemini GPI IFS file!"
			return, 0
		endif else begin
			message,/info, "File "+filename+" is NOT a valid Gemini GPI IFS file!"
			message,/info, "Loose validation is set, so we're going to ignore that and try to proceed anyway."
			return, 3
		endelse
	endif

	; If we get here, then we know this is at least a GPI file.
	; But was it aborted?
	val4 = gpi_validate_file_one_keyword(file_data, 'ABORTED',1b, verbose=verbose,/numeric) ; note the sxpar returns 0,1 instead of F,T for booleans
	if val4 then begin
		message,/info, "File "+filename+" was ABORTED!"
		return, 0
	endif

	return, 1

end
