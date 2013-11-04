;+
; NAME: gpi_validate_paths
;
; DESCRIPTION: Validate environment variables/paths for GPI IFS Software
;
; KEYWORDS:
;    /get_path_info		don't actually check anything, but return a
;						structure of information about what would 
;						have been checked. Used in setenvir__define
;
;
; HISTORY:
;  2010-07-07 Created J. Maire
;  2011-07-29 MP: Validation of directory write permissions fixed up a bit. 
;  2012-01-26 MP: Modified to use for loops. 
;  2012-08-07 MP: Partial cleanup and simplification. Removed GPI_IFS_DIR as
;  					redundant. GPI_DRP_OUTPUT_DIR
;  					-> GPI_REDUCED_DATA_DIR
;  2012-08-10 DS: Changed dirs marked as optional in setup doc to
;                 actually be optional
;                 MP note: those are optional in the sense of 'user does not
;                 need to set paths explicitly because there are reasonable
;                 defaults'. However, they must all still be valid paths as
;                 returned by gpi_get_directory (which is where those defaults
;                 are in fact set...) so we should include them all here.
; 2012-10-10 MP:  Slight reorganization, more explicit error messages. 
; 2013-11-04 MP:  Auto create some directories if they don't exist, and
;				  remove the obsolete /first option
;  
;
;  FIXME: should try to clean up / reorganize this code? 
;-

function gpi_validate_paths, get_path_info=get_path_info
  compile_opt defint32, strictarr, logical_predicate

  ;;Define a table of the the things we care about for each directory
  env =       {name:'GPI_RAW_DATA_DIR',      writeable:0, isdir:1, autocreate: 0, description:"Directory for raw data input"}
  env = [env, {name:'GPI_REDUCED_DATA_DIR',  writeable:1, isdir:1, autocreate: 0, description:"Directory for reduced data output"}]
  env = [env, {name:'GPI_DRP_QUEUE_DIR',     writeable:1, isdir:1, autocreate: 0, description:"Recipe Queue directory"}]
  env = [env, {name:'GPI_DRP_DIR',           writeable:0, isdir:1, autocreate: 0, description:"Directory for root of GPI DRP"}]
  env = [env, {name:'GPI_DRP_CONFIG_DIR',    writeable:0, isdir:1, autocreate: 0, description:"Directory for DRP config files"}]
  env = [env, {name:'GPI_DRP_TEMPLATES_DIR', writeable:0, isdir:1, autocreate: 0, description:"Directory for recipe templates"}]
  env = [env, {name:'GPI_CALIBRATIONS_DIR',  writeable:1, isdir:1, autocreate: 1, description:"Directory for calibration files"}]
  env = [env, {name:'GPI_DRP_LOG_DIR',       writeable:1, isdir:1, autocreate: 1, description:"Directory for log file output"}]
  env = [env, {name:'GPI_RECIPE_OUTPUT_DIR', writeable:1, isdir:1, autocreate: 1, description:"Directory for recipe file output"}]


  if keyword_set(get_path_info) then return, env

  ;;if this is a first incarnation, check for proper idl version and
  ;;try to fill in as many missing env vars with defaults
  runfromvm = LMGR(/VM)
  if (runfromvm eq 0) && (float(!version.release) lt 7.0) then begin
	void = dialog_message('The GPI DRP can not run with IDL version below v7.0.'+$
						  'Please use IDL v7.0 or higher, or run DRP from executables.')
	return,-1
  endif

  if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)
  retval = 1
  for j = 0,n_elements(env)-1 do begin
     ;;gpi_get_directory always looks for env vars first and takes
     ;;care of default values, so we rely on it completely
     dir = gpi_get_directory(env[j].name,method=method)
     res = file_test(dir, dir = env[j].isdir)
     if res eq 0 then begin
        retval = 0
        message,env[j].name+' value of '+newline+dir+newline+' derived from a(n) '+method+' is not valid: directory does not exist',/info

		; for certain directories, just create them if they don't exist already
		if env[j].autocreate then begin
			if gpi_get_setting('prompt_user_for_outputdir_creation',/bool) then $
				res =  dialog_message('The directory for '+env[j].name+", which is "+dir+', does not exist. Should it be created now?', $
				title="Nonexistent Output Directory", /question) else res='Yes'

			if res eq 'Yes' then begin
				message,/info, "Automatically creating "+dir
				file_mkdir, dir
				res = file_test(dir, dir = env[j].isdir)
				if res then retval=1
			endif 
		endif

     endif

	 if env[j].writeable then begin
	     res = file_test(dir, dir = env[j].isdir, write=1)
		 if res eq 0 then begin
			retval = 0
			message,env[j].name+' value of '+newline+dir+newline+' derived from a(n) '+method+' is not valid: directory must be writeable, but is not.',/info
		endif


	 endif
  endfor

  return, retval
end   
