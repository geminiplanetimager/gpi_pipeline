;+
; NAME: gpi_get_setting
; 
;	Look up a setting value from a very simple configuration file, named
;	pipeline_config.txt in the config directory. 
;
;	This is just a tab-delimited name=value mapping. Replace this by 
;	something more sophisticated if needed? 
;
; INPUTS:
;	settingname		name of string to look up in that config file
; OUTPUTS:
;	returns the text value stored in that file
;
; HISTORY:
;	Began 012-02-03 17:12:18 by Marshall Perrin 
;-


function gpi_get_setting, settingname

	pipeline_settings_file = file_dirname(GETENV('GPI_CONFIG_FILE')) + path_sep() + 'pipeline_settings.txt'

	readcol, pipeline_settings_file, format='A,A', DELIM = string(9b), comment='#', settingnames, values, count=count, /silent
	if count eq 0 then begin
		message,/info,'WARNING: Could not load the pipeline configuration file from '+file_dirname(GETENV('GPI_CONFIG_FILE')) + path_sep() + 'pipeline_config.txt'
		return, 'ERROR'
	endif

	wm = where(strmatch(settingnames, settingname, /fold_case), ct)
	if ct eq 0 then begin
		message,/info, "ERROR: could not find a setting named "+settingname
		return, 'ERROR'
	endif

	return, values[wm[0]]
	

end
