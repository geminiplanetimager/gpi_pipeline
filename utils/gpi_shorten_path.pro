;+
; NAME: gpi_shorten_path
;
;		given some pathname, convert it to a path relative to
;		one or more of the GPI directory names.
;
;		Tries all available named directories in a row, then
;		returns whichever path is the shortest.
;
;	See also: gpi_expand_path
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


FUNCTION gpi_shorten_path, path
	compile_opt defint32, strictarr, logical_predicate

	vars = [ 'GPI_DRP_TEMPLATES_DIR','GPI_REDUCED_DATA_DIR', 'GPI_RAW_DATA_DIR',  'GPI_DRP_LOG_DIR', 'GPI_DRP_QUEUE_DIR','GPI_CALIBRATIONS_DIR', 'GPI_DRP_DIR']


	full_path = gpi_expand_path(path)
	;print, full_path

	shortest_path = full_path

	for i=0L,n_elements(vars)-1 do begin
		varpath=gpi_get_directory(vars[i])
		mypath = full_path
		;print, "         |", full_path, "|    |", varpath, "|    ",  strmatch(full_path, "*"+varpath+"*")
		;print, "     "+varpath
		if strmatch(mypath, "*"+varpath+"*") gt 0 then strreplace, mypath, varpath, '${'+vars[i]+'}'

		if strlen(mypath)  lt strlen(shortest_path) then shortest_path = mypath
		;print, "    ",  i, "    ",  vars[i], "    ",  varpath, "    ",  full_path
	endfor 

	return, shortest_path


end
