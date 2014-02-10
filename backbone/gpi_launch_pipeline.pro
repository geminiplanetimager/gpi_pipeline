;+
; NAME: gpi_launch_pipeline
;
; 	Master startup routine for GPI data pipeline.
;
; INPUTS:
; 	NONE
;
; KEYWORDS:
;
;  /noexit			Don't exit IDL after the pipeline is closed
;  /rescanDB   		Create a new calibrations DB by reading all files in a given directory
;  /flushqueue		DELETE any DRFs present in the queue on startup (dangerous,
;  					mostly for debugging purposes)
;  /rescan			Rescan & recreate the calibration files DB on startup
;  /verbose     	Display more output than usual, mostly for debugging
;           		purposes
;  /ignoreconflict	Don't stop running if another instance is already running.
;  					Use this option at your own risk....
;  single=			Process one single DRF (provide the filename as argument)
;  					and then exit the DRP. Useful primarily for testing.
;  /nogui			Do not display the Pipeline Status Console GUI, just run the
;  					backbone algorithms.
;
; EXAMPLE:
;  IDL> gpipiperun, /noexit,  /rescanDB, /noguidrf, /parsergui
;
; HISTORY:
; 	Doc Header added 2009-04-20 by Marshall Perrin
;   2009-09-15 gui for drf added - JM 
;   2010-05-13	Removed GUI automatic startup - you can now do this via
;   			the launcher.  - MDP
;   2012-08-07 Removed ability to set nonstandard queue or config paths here -
;   			this is an unnecessary complication. -MDP
;   2012-12-18 Renamed from gpipiperun - MDP
;-
PRO gpi_launch_pipeline, noinit=noinit, $
	noexit=noexit, rescanDB=rescanDB, flushqueue=flushqueue, verbose=verbose,$
	ignoreconflict=ignoreconflict, single=single, nogui=nogui

        currdir = gpi_expand_path(gpi_get_setting('gpi_startup_dir',/silent))
		if strc(currdir) ne "ERROR" then cd, gpi_expand_path(currdir)


	if ~gpi_validate_paths() then begin
		obj = obj_new('gpi_showpaths') ; will pause here until dialog closed...
        obj_destroy, obj
		return
	endif

	Queue_Dir = gpi_get_directory('GPI_DRP_QUEUE_DIR')


	if gpi_get_setting('prevent_multiple_instances',/bool, default=0) then begin
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

	backbone = OBJ_NEW('gpiPipelineBackbone', verbose=verbose, nogui=nogui)
	
	if keyword_set(flushqueue) then backbone->flushqueue, queue_dir
	if keyword_set(rescanDB) then backbone->rescan

	if keyword_set(single) then begin
		; process one single DRF and then exit
		status = backbone->run_one_recipe(single)
		backbone->Log, "Pipeline was invoked in single-DRF mode. Shutting down now. ",/general
	endif else begin		
		; watch the queue dir and process many DRFs
		backbone->Run_queue, Queue_Dir
	endelse

	OBJ_DESTROY, backbone

	if gpi_get_setting('prevent_multiple_instances',/bool,default=0) then begin
		sem_release, sem_name
		sem_delete, sem_name
	endif 

	if ~(keyword_set(noexit)) then exit

END
