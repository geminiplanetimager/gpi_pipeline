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
; OUTPUTS:
;
; HISTORY:
; 	Began 2012-07-19 00:28:24 by Marshall Perrin 
;-


function gpi_get_directory, dirname,expand_path=expand_path

	if dirname eq "" then begin
		if	 ~(keyword_set( dirname)) then dirname='.' 
	endif

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
	case strupcase(varrname) of
		'GPI_DRP_DIR': begin
			stop ; look up DRP dir from path to this routine
		end
		'GPI_DRP_TEMPLATES_DIR': 	result = gpi_get_directory("GPI_DRP_DIR")+path_sep()+"drf_templates"
		'GPI_DRP_CONFIG_DIR': 		result = gpi_get_directory("GPI_DRP_DIR")+path_sep()+"config"
		'GPI_DRP_LOG_DIR': 			result = gpi_get_directory("GPI_REDUCED_DATA_DIR")+path_sep()+"logs"
		'GPI_DRF_OUTPUT_DIR': 		result = gpi_get_directory("GPI_REDUCED_DATA_DIR")+path_sep()+"drfs"
		'GPI_CALIBRATIONS_DIR': 	result = gpi_get_directory("GPI_REDUCED_DATA_DIR")+path_sep()+"calibrations"
		else: begin
			message, 'could not find default value for '+dirname+'; that is an unknown directory name.',/info
			result = "Not a known directory"
		endelse
	endcase

	if keyword_set(expand_path) then result=gpi_expand_path(result)
	return, result
end
