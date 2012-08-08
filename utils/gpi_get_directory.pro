;+
; NAME: gpi_get_directory
;
;
; 	Return a directory name for some GPI task, based either on default paths
; 	or configuration file settings, or environment variables (in increasing order of
; 	precedence)
;
; EXAMPLES:
;
;    path = gpi_get_directory('DRP_LOG')
;    path = gpi_get_directory('GPI_DRP_LOG_DIR')
;
;    the above are both equivalent.
;
; INPUTS:
; KEYWORDS:
; 	expand_path		return full path, with ~s and environment variables expanded
; 					out. This is true by default, but you can set it to 0 if you 
; 					want to disable this feature for some reason.
; OUTPUTS:
;
; HISTORY:
; 	Began 2012-07-19 00:28:24 by Marshall Perrin 
;-


function gpi_get_directory, dirname,expand_path=expand_path

	if dirname eq "" then begin
		if	 ~(keyword_set( dirname)) then dirname='.' 
	endif

	if n_elements(expand_path) eq 0 then expand_path=1

	; First, convert the directory name requested to a canonical variable name,
	; which will always start with GPI_ and end with _DIR
	dirname=strupcase(dirname)
	varname = strupcase(dirname)
	if ~(strmid(varname,0,4) eq 'GPI_') then varname="GPI_"+varname
	if ~(strmid(varname, strlen(varname)-4,4) eq '_DIR') then varname=varname+"_DIR"

	; Highest precedence: environment variables. This will override anything
	; else.
	result = getenv(varname)
	if result ne "" then begin
		if keyword_set(expand_path) then result=gpi_expand_path(result)
		return, result
	endif


	; Second precedence: A setting from a configuration file
	; As always, will first look in user's config file and then in global.
	result = gpi_get_setting(varname)
	if result ne 'ERROR' then begin
		if keyword_set(expand_path) then result=gpi_expand_path(result)
		return, result
	endif
	
	
	; Third precedence: Default paths. 
	; Yes, this will typically recursively call this routine, but for a
	; different variable name.
	case strupcase(varname) of
		'GPI_DRP_DIR': begin
			; find where this current file is
			FindPro, 'gpi_get_directory', dirlist=dirlist
			dirlist = dirlist[0] ; scalarize
			result = file_dirname(dirlist) ; parent directory will be pipeline root.
		end
		'GPI_DRP_TEMPLATES_DIR': 	result = gpi_get_directory("GPI_DRP_DIR")+path_sep()+"drf_templates"
		'GPI_DRP_CONFIG_DIR': 		result = gpi_get_directory("GPI_DRP_DIR")+path_sep()+"config"
		'GPI_DRP_LOG_DIR': 			result = gpi_get_directory("GPI_REDUCED_DATA_DIR")+path_sep()+"logs"
		'GPI_DRF_OUTPUT_DIR': 		result = gpi_get_directory("GPI_REDUCED_DATA_DIR")+path_sep()+"drfs"
		'GPI_CALIBRATIONS_DIR': 	result = gpi_get_directory("GPI_REDUCED_DATA_DIR")+path_sep()+"calibrations"
		'GPI_DST_DIR': 				result = file_basename(gpi_get_directory("GPI_DRP_DIR"))+path_sep()+"dst" ; optional, may not be present...
		else: begin
			message, 'could not find default value for '+dirname+'; that is an unknown directory name.',/info
			result = "Not a known directory"
		endelse
	endcase

	if keyword_set(expand_path) then result=gpi_expand_path(result)
	return, result
end
