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
;       /double                 Cast result to double before returning
; 	/bool			Cast result to boolean (byte) before returning
;
; 	/rescan			Reload the input files from disk instead of using cached
; 					values
; 	default=		Value to return, for the case when no information is
; 					available in the configuration files.
;	/silent			Don't print any warning messages if setting not found.
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



function gpi_get_setting, settingname, expand_path=expand_path, integer=int, bool=bool, double=double, rescan=rescan,silent=silent, default=default
	compile_opt defint32, strictarr, logical_predicate

	common GPI_SETTINGS, globalsettings, usersettings

	if keyword_set(rescan) then begin ; erase variables to force re-reading config files from disk
		delvarx, globalsettings
		delvarx, usersettings
	endif

	user_settings_file = gpi_expand_path("~")+path_sep()+".gpi_pipeline_settings"
;	if strmatch(!VERSION.OS_FAMILY , 'Windows',/fold) then  user_settings_file = gpi_get_directory("GPI_DRP_CONFIG_DIR")+path_sep()+"gpi_pipeline_settings.txt"
  if strmatch(!VERSION.OS_FAMILY , 'Windows',/fold) and  (n_elements(usersettings) eq 0) then begin
        message,/info, "Your environment variables  that define your paths are not defined correctly"
        return, 'ERROR'
  endif


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
		if ~file_test(global_settings_file) then message,"Global Pipeline Settings File does not exist! Check your pipeline config: "+global_settings_file
		; FIXME make this more robust to any whitespace as separator
		readcol, global_settings_file, format='A,A', comment='#', globalsetting_names, values, count=count, /silent
		if count eq 0 then begin
			if ~(keyword_set(silent)) then message,/info,'WARNING: Could not load the pipeline configuration file from '+global_settings_file
			return, 'ERROR'
		endif
		globalsettings = {parameters:globalsetting_names, values: values}

	endif



	;----- check against local settings

    if size(usersettings,/TNAME) eq 'STRUCT' then begin
        wm = where(strmatch(usersettings.parameters, settingname, /fold_case), ct)
    endif else ct=0

	if ct gt 0 then begin
		result = usersettings.values[wm[0]]
	endif else begin 
		
		;---- secondarily, try the global settings.


		wm = where(strmatch(globalsettings.parameters, settingname, /fold_case), ct)
		if ct eq 0 then begin
			; no match found!
			if n_elements(default) gt 0 then begin
				; If we have a default, use that
				if ~(keyword_set(silent)) then message,/info,'No setting found for '+settingname+"; using default value="+strtrim(default,2)
				return, default
			endif else begin
				; Otherwise alert the user we have no good setting
				if ~(keyword_set(silent)) then begin
					message,/info,"-----------------------------------------"
					message,/info, "ERROR: could not find a setting named "+settingname
					message,/info, "Check your user configuration file : "+user_settings_file
					message,/info, " and global configuration file :     "+global_settings_file
					message,/info,"-----------------------------------------"
				endif
				return, 'ERROR'
			endelse
		endif else begin
			result = globalsettings.values[wm[0]]
		endelse
	endelse


    ; special case: for bool type answers, 0 or 1, cast to integer type automatically.
    ; This is needed because the string '0' is TRUE while the number 0 is FALSE. Lame.
    if ~(keyword_set(int)) and ~(keyword_set(double)) and ~(keyword_set(bool)) and ((result eq '1') or (result eq '0')) then bool = 1

	;---- optional postprocessing
	if keyword_set(expand_path) then result = gpi_expand_path(result)
	if keyword_set(int) then result=fix(result)
        if keyword_set(double) then result=double(result)
	if keyword_set(bool) then result=byte(fix(result))

	return, result
	

end
