;+
; NAME: gpiPipeRun
;
; INPUTS:
; 	NONE
;
; KEYWORDS:
; 	queue_dir=		Directory name to use for Queue. If not set, by default 
; 					check for the environment variable "GPI_DRP_QUEUE_DIR".
; 					If that's not found either, then fall back to a fixed
; 					hard-coded path.
;
;  /noexit			Don't exit IDL after the pipeline is closed
;  /rescanDB   Create a new calibrations DB by reading all files in a given directory
;  /flushqueue		DELETE any DRFs present in the queue on startup (dangerous,
;  					mostly for debugging purposes)
;  /rescan			Rescan & recreate the calibration files DB on startup
;  /verbose     Display more output than usual, mostly for debugging
;           purposes
;  /ignoreconflict	Don't stop running if another instance is already running.
;  					Use this option at your own risk....
;
; EXAMPLE:
;  IDL> gpipiperun, /noexit,  /rescanDB, /noguidrf, /parsergui
;
; HISTORY:
; 	Doc Header added 2009-04-20 by Marshall Perrin
;   2009-09-15 gui for drf added - JM 
;   2010-05-13	Removed GUI automatic startup - you can now do this via
;   			the launcher.  - MDP
;-
PRO gpiPipeRun, QUEUE_DIR=queue_dir, config_file=config_file, noinit=noinit, $
	noexit=noexit, rescanDB=rescanDB, flushqueue=flushqueue, verbose=verbose,$
	ignoreconflict=ignoreconflict


issetenvok=gpi_is_setenv(/first)
if issetenvok eq 0 then begin
        obj=obj_new('setenvir')
        if obj->act() eq 1 then issetenvok=-1
        obj_destroy, obj
  while (issetenvok ne -1) && (gpi_is_setenv() eq 0)  do begin
        obj=obj_new('setenvir')
        if obj->act() eq 1 then issetenvok=-1
        obj_destroy, obj
  endwhile
endif else if issetenvok eq -1 then return
  if issetenvok eq -1 then return
  ; check for the presence of a valid config, and load default if not.
  config_valid = keyword_set(getenv('GPI_DRP_QUEUE_DIR')) and  keyword_set(getenv('GPI_DRP_CONFIG_DIR'))
  if ~config_valid then BEGIN
    initgpi_default_paths,err=err
    if err eq 1 then RETURN
  ENDIF
	
  ; note thet keywords set on the command line have top precedence, then
  ; environment variables, then default settings.
  IF ~KEYWORD_SET(QUEUE_DIR) THEN Queue_Dir = GETENV('GPI_DRP_QUEUE_DIR')
  IF ~KEYWORD_SET(CONFIG_FILE) THEN CONFIG_FILE= GETENV('GPI_DRP_CONFIG_DIR')+path_sep()+"gpi_pipeline_primitives.xml"



  if gpi_get_setting('prevent_multiple_instances',/bool) then begin
	  ; Use a semaphore lock to prevent multiple instances of the pipeline
	  ; from running at once. 
	  ;
	  ; FIXME - does not work properly, need to be debugged
	  sem_name = idl_validname(queue_dir,/convert_all)
	  sem = sem_create(sem_name)

		message,/info, "Trying to lock semaphore "+sem_name
		status = sem_lock(sem_name)
	  
		if (status eq 0) then begin
		  message,/info, "Semaphore lock failed!"
		  if ~keyword_set(ignoreconflict) then begin
			res = dialog_message(/cancel,["Another instance of the GPI Data Pipeline appears to already be running looking at","the queue directory "+queue_dir+". You probably should not run ","two copies of the pipeline at once, as this has not been tested to work. Continue anyway?"], $
				title="WARNING: Pipeline already running!")
			if res eq 'Cancel' then begin
				message,/info, "Pipeline invocation cancelled by user due to duplicate session warning."
				return
			endif
		  endif
		endif
	endif


	x = OBJ_NEW('gpiPipelineBackbone', config_file=config_file, verbose=verbose)
	
	if keyword_set(flushqueue) then x->flushqueue, queue_dir
	if keyword_set(rescanDB) then x->rescan

	
	
	x->Run, Queue_Dir

	OBJ_DESTROY, x

	if gpi_get_setting('prevent_multiple_instances',/bool) then begin
		sem_release, sem_name
		sem_delete, sem_name
	endif 

	if ~(keyword_set(noexit)) then exit

END
