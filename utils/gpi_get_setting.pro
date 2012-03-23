;+
; NAME: gpi_get_setting
; 
;	Look up a setting value from a very simple configuration file, named
;	pipeline_config.txt in the config directory. 
;
;	This is just a tab-delimited name=value mapping. Replace this by 
;	something more sophisticated if needed? 
;
; KEYWORDS:
;   /expand_path		Apply environment variable path expansion to the result
;   				before returning it.
;
; INPUTS:
;	settingname		name of string to look up in that config file
;
; KEYWORD:
; 	/int			Cast result to integer before returning
; 	/bool			Cast result to boolean (byte) before returning
; OUTPUTS:
;	returns the text value stored in that file
;
; HISTORY:
;	Began 012-02-03 17:12:18 by Marshall Perrin 
;-


function gpi_get_setting, settingname, expand_path=expand_path, int=int, bool=bool

	;pipeline_settings_file = file_dirname(GETENV('GPI_DRP_CONFIG_FILE')) + path_sep() + 'pipeline_settings.txt'
	pipeline_settings_file = GETENV('GPI_DRP_CONFIG_DIR') + path_sep() + 'pipeline_settings.txt'

	; FIXME make this more robust to any whitespace as separator
	;readcol, pipeline_settings_file, format='A,A', DELIM = string(9b), comment='#', settingnames, values, count=count, /silent
	readcol, pipeline_settings_file, format='A,A', comment='#', settingnames, values, count=count, /silent
	if count eq 0 then begin
		message,/info,'WARNING: Could not load the pipeline configuration file from '+file_dirname(GETENV('GPI_DRP_CONFIG_DIR')) + path_sep() + 'pipeline_config.txt'
		return, 'ERROR'
	endif

	wm = where(strmatch(settingnames, settingname, /fold_case), ct)
	if ct eq 0 then begin
		message,/info,"-----------------------------------------"
		message,/info, "ERROR: could not find a setting named "+settingname
		message,/info, "Check your file : "+pipeline_settings_file
		message,/info,"-----------------------------------------"
		stop
		return, 'ERROR'
	endif

	result = values[wm[0]]

	if keyword_set(expand_path) then result = gpi_expand_path(result)
	if keyword_set(int) then result=fix(result)
	if keyword_set(bool) then result=byte(result)

	return, result
	

end
