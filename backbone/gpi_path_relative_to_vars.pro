;+
; NAME: gpi_path_relative_to_vars 
;		given some pathname, convert it to a path relative to
;		one or more of the GPI environment variables. 
;
; INPUTS:
; 	path		some path
; KEYWORDS:
; OUTPUTS:
; 	returns an equivalent string for that path, which uses the environment
; 	variables.
;
; HISTORY:
; 	Began 2011-08-01 18:06:55 by Marshall Perrin 
;-


FUNCTION gpi_path_relative_to_vars, path

	vars = ['GPI_DRP_OUTPUT_DIR', 'GPI_RAW_DATA_DIR', 'GPI_DRF_TEMPLATES_DIR', 'GPI_PIPELINE_LOG_DIR', 'GPI_QUEUE_DIR', 'GPI_PIPELINE_DIR','GPI_IFS_DIR']


	full_path = gpi_expand_path(path)
	;print, full_path

	for i=0L,n_elements(vars)-1 do begin
		varpath=gpi_expand_path('$'+vars[i]+'')
		;print, "     "+varpath
		if strmatch(full_path, varpath) gt -1 then strreplace, full_path, varpath, '$('+vars[i]+')'
	endfor 

	return, full_path


end
