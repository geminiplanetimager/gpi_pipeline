;+
; NAME: gpi_get_setting
; 
;	Look up a setting value for GPI, either from the user's own configuration
;	file or from the system pipeline configuration. 	
;
;	The user setting file is entirely optional. If it doesn't exist, then
;	settings are just read from the system configuration. 
;	The user setting file is ~/.gpi_drp_config on Linux or Mac, TBD on Windows.
;	The system configuration is 
;
;	The contents of either file is just a tab-delimited name=value mapping. Replace this by 
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
;
; 	/rescal			Reload the input files from disk instead of using cached
; 					values
; OUTPUTS:
;	returns the text value stored in that file
;
; HISTORY:
;	Began 2012-02-03 17:12:18 by Marshall Perrin 
;	2012-06-29		Reworked to have user and system configurations, with the
;					former taking precedence over the latter
;-
;function gpi_get_setting_helper, result, expand_path=expand_path, int=int, bool=bool
;	if keyword_set(expand_path) then result = gpi_expand_path(result)
;	if keyword_set(int) then result=fix(result)
;	if keyword_set(bool) then result=byte(result)
;
;	return, result
;end
;	



function gpi_get_setting, settingname, expand_path=expand_path, integer=int, bool=bool, rescan=rescan,silent=silent

	common GPI_SETTINGS, globalsettings, usersettings

	if keyword_set(rescan) then begin ; erase variables to force re-reading config files from disk
		delvarx, globalsettings
		delvarx, usersettings
	endif

	user_settings_file = gpi_expand_path("~")+path_sep()+".gpi_drp_config"
	global_settings_file = gpi_get_directory("GPI_DRP_CONFIG_DIR")+path_sep()+"pipeline_settings.txt"

	;-------- First, load the user settings, if present
	if n_elements(usersettings) eq 0  and file_test(user_settings_file) then begin
		if ~(keyword_set(silent)) then message,/info,"Reading in user settings file: "+user_settings_file
		; FIXME make this more robust to any whitespace as separator
		catch, read_error
		if read_error eq 0 then begin
			readcol, user_settings_file, format='A,A', comment='#', usersetting_names, values, count=count, /silent
			if count eq 0 then begin
				usersetting_names=['None']
				values=['None']
			endif
		endif else begin
			usersetting_names=['None']
			values=['None']
		endelse

		catch,/cancel
		usersettings = {parameters: usersetting_names, values: values}
	endif
	;-------- load global settings
	if n_elements(globalsettings) eq 0 then begin
		if ~(keyword_set(silent)) then message,/info,"Reading in global settings file: "+global_settings_file
		; FIXME make this more robust to any whitespace as separator
		readcol, global_settings_file, format='A,A', comment='#', globalsetting_names, values, count=count, /silent
		if count eq 0 then begin
			if ~(keyword_set(silent)) then message,/info,'WARNING: Could not load the pipeline configuration file from '+global_settings_file
			return, 'ERROR'
		endif
		globalsettings = {parameters:globalsetting_names, values: values}

	endif



	;----- check against local settings

	wm = where(strmatch(usersettings.parameters, settingname, /fold_case), ct)
	if ct gt 0 then begin
		result = usersettings.values[wm[0]]
	endif else begin 
		
		;---- secondarily, try the global settings.


		wm = where(strmatch(globalsettings.parameters, settingname, /fold_case), ct)
		if ct eq 0 then begin
			if ~(keyword_set(silent)) then begin
				message,/info,"-----------------------------------------"
				message,/info, "ERROR: could not find a setting named "+settingname
				message,/info, "Check your user configuration file : "+user_settings_file
				message,/info, " and global configuration file :     "+global_settings_file
				message,/info,"-----------------------------------------"
			endif
			return, 'ERROR'
		endif else begin
			result = globalsettings.values[wm[0]]
		endelse
	endelse


	;---- optional postprocessing
	if keyword_set(expand_path) then result = gpi_expand_path(result)
	if keyword_set(int) then result=fix(result)
	if keyword_set(bool) then result=byte(result)

	return, result
	

end
