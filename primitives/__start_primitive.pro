;+
; NAME:  __start_primitive
;
; This code is meant to be included at the START of a GPI primitive using 
; @__start_primitive
;
; it is **not** a full routine on its own!
;
; HISTORY:
; 	Began 2010-04-08 19:25:24 by Marshall Perrin 
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2011-07-30 MP: Updated for multi-extension FITS
;-



; some common initialization of useful stuff:
	common PIP
	COMMON APP_CONSTANTS

	getmyname, functionname
	thisModuleIndex = Backbone->GetCurrentModuleIndex()

; record this primitive name AND its version in the header for traceability.
	if ~(keyword_set(primitive_version)) then primitive_version="unknown"
  backbone->set_keyword,'HISTORY', "Running "+functionname+"; version "+primitive_version, ext_num=0


; if appropriate, attempt to locate and verify a calibration file.
	if keyword_set(calfiletype) then begin

		c_file = (modules[thismoduleindex].calibrationfile)

		if strmatch(c_file, 'automatic',/fold) then begin
		    c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( calfiletype, *(dataset.headersphu)[numfile],*(dataset.headersext)[numfile] ) 

			if size(c_file,/tname) eq 'int' then if c_file eq not_ok then begin
				if ~(keyword_set(no_error_on_missing_calfile)) then $
				return, error('error in call ('+strtrim(functionname)+'): calibration file could not be found in calibrations database.')
			endif else begin
				fxaddpar,*(dataset.headersphu[numfile]),'history',functionname+": automatically resolved calibration file of type '"+calfiletype+"'."
				fxaddpar,*(dataset.headersphu[numfile]),'history',functionname+":   "+c_file 
			endelse
		endif
		c_file = gpi_expand_path(c_file)  


		; in either case, does the requested file actually exist?
		if ( not file_test ( c_file ) ) then $
			if ~(keyword_set(no_error_on_missing_calfile)) then $
		   return, error ('error in call ('+strtrim(functionname)+'): calibration file  ' + $
						  strtrim(string(c_file),2) + ' not found.' )

	endif




