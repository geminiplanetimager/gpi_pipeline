;+
; NAME: gpiPipeRun
;
; INPUTS:
; 	NONE
;
; KEYWORDS:
; 	queue_dir=		Directory name to use for Queue. If not set, by default 
; 					check for the environment variable "GPI_QUEUE_DIR".
; 					If that's not found either, then fall back to a fixed
; 					hard-coded path.
;   /noDRFGUI		Don't start the DRF GUI
;
;  /noexit			Don't exit IDL after the pipeline is closed
; /testdata    Parser allow the pipeline to process non-Gemini-GPI-IFS data
; /rescanDB   Create a new calibrations DB by reading all files in a given directory
;
; EXAMPLE:
;  IDL> gpipiperun, /noexit, /testdata, /rescanDB, /noguidrf, /parsergui
;
; HISTORY:
; 	Doc Header added 2009-04-20 by Marshall Perrin
;   2009-09-15 gui for drf added - JM 
;   2010-05-13	Removed GUI automatic startup - you can now do this via
;   			the launcher.  - MDP
;-
PRO gpiPipeRun, QUEUE_DIR=queue_dir, config_file=config_file, drfgui=drfgui, noguidrf=noguidrf, foreground=foreground, nodrfgui=nodrfgui, noinit=noinit, $
	parsergui=parsergui, noexit=noexit, testdata=testdata, rescanDB=rescanDB, flushqueue=flushqueue

  ; check for the presence of a valid config, and load default if not.
  config_valid = keyword_set(getenv('GPI_QUEUE_DIR')) and  keyword_set(getenv('GPI_CONFIG_FILE'))
  if ~config_valid then BEGIN
    initgpi_default_paths,err=err
    if err eq 1 then RETURN
  ENDIF
	
  ; note thet keywords set on the command line have top precedence, then
  ; environment variables, then default settings.
  IF ~KEYWORD_SET(QUEUE_DIR) THEN Queue_Dir = GETENV('GPI_QUEUE_DIR')
  IF ~KEYWORD_SET(CONFIG_FILE) THEN CONFIG_FILE= GETENV('GPI_CONFIG_FILE')

	
;;;;	  if keyword_set(foreground) then begin
;;;;			; run the DRF GUI in the foreground IDL session (no spawning)
;;;;			if keyword_set(parsergui) then gpiparsergui, /testdata else $
;;;;		  	gpidrfgui,/no_block
;;;;	  endif else begin
;;;;	
;;;;	    if keyword_set(parsergui) then begin
;;;;	      ; run the DRF GUI in another IDL session spawned in the background
;;;;	    CASE !VERSION.OS_FAMILY OF  
;;;;	      'MacOS': SPAWN, 'idl -e "gpiparsergui, /testdata" &'
;;;;	       'unix': SPAWN, 'idl -e "gpiparsergui, /testdata" &'
;;;;	       'Windows'   :begin
;;;;	       winidlrt= FILE_SEARCH(STRSPLIT(!DLM_PATH, PATH_SEP(/SEARCH_PATH), $
;;;;	       /EXTRACT) + '\idlrt.exe')
;;;;	        SPAWN, winidlrt+' -e "gpiparsergui, /testdata" ',/NOWAIT,/NOSHELL
;;;;	        end
;;;;	    ENDCASE
;;;;	    endif else begin
;;;;	
;;;;		  if ~keyword_set(noguidrf) and ~keyword_set(nodrfgui) then begin
;;;;				; run the DRF GUI in another IDL session spawned in the background
;;;;			CASE !VERSION.OS_FAMILY OF  
;;;;			  'MacOS': SPAWN, 'idl -e "gpidrfgui" &'
;;;;			   'unix': SPAWN, 'idl -e "gpidrfgui" &'
;;;;			   'Windows'   :begin
;;;;			   winidlrt= FILE_SEARCH(STRSPLIT(!DLM_PATH, PATH_SEP(/SEARCH_PATH), $
;;;;			   /EXTRACT) + '\idlrt.exe')
;;;;				  SPAWN, winidlrt+' -e "gpidrfgui" ',/NOWAIT,/NOSHELL
;;;;					end
;;;;			ENDCASE
;;;;		  endif
;;;;		 endelse
;;;;	  endelse
;;;;	


	x = OBJ_NEW('gpiPipelineBackbone', config_file=config_file)
	
	if keyword_set(flushqueue) then x->flushqueue, queue_dir
	if keyword_set(rescanDB) then x->rescan

	
	
	x->Run, Queue_Dir

	OBJ_DESTROY, x
	if ~(keyword_set(noexit)) then exit

END
