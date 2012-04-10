;+
; NAME: initgpi_default_paths
;
; 	The GPI pipeline requires a bunch of environment variables to work properly. 
; 	If they are not set already, then attempt to set them to reasonable default
; 	values. These are of course not guaranteed to work! Probably you want to set
; 	them already in a shell configuration file somewhere before starting the
; 	pipeline.
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2010-01-19 19:06:19 by Marshall Perrin 
;-


; Set default for one environment variable path. 
; First check if it's already defined, and
; **ONLY** redefine it if it is not already defined
pro initgpi_default_onepath, varname, defaultvalue, _extra=_extra
	; if environment variable is defined and exists, then don't change it
	if getenv(varname) then begin
		if file_test(getenv(varname), _extra=_extra) then return
		message,/info, "Env Var "+strc(strupcase(varname))+" is defined as "+getenv(varname)
		message,/info, "but that path does not exist!"
	endif
	; validate new value
	if ~file_test(defaultvalue, _extra=_extra) then begin
		message, /info, "New value for Env Var "+strc(strupcase(varname))+" would be " 
		message, /info, defaultvalue
		message,/info, "But that path does not exist!!"
		FindPro, 'initgpi_default_paths', dirlist=dirlist
		dirlist=dirlist[0]
		print, 'ERROR when initializing the pipeline: '
		print, 'Please check setenv values in the function '+dirlist+path_sep()+'initgpi_default_paths.pro'
		print, 'Some directories may not exist on your system. Change paths, create directories, and check permissions as needed.'
		stop
	endif
	message, "Setting path environment variable to DEFAULT PATH:", /info
	message,/info, strc(varname+"="+ defaultvalue)
	setenv, strc(varname+"="+ defaultvalue)

end

;---------------

pro initgpi_default_paths, err=err
;message, "Setting path environment variables to DEFAULT PATHS", /info
err=0
CASE !VERSION.OS_FAMILY OF  
	'Windows': begin
		GPI_DRP_DIR='E:\testsvn3\pipeline' 
		GPI_RAW_DATA_DIR='E:\GPIdatabase\Gemini\'
		GPI_DRP_OUTPUT_DIR='E:\GPIdatabase\GPIreduced\'
	end
	'unix': begin
		default_GPI_IFS_DIR = expand_path('~/GPI/')
		initgpi_default_onepath, 'GPI_IFS_DIR', default_GPI_IFS_DIR, /directory
		GPI_DRP_DIR=gpi_expand_path("$GPI_IFS_DIR/pipeline/")
		GPI_RAW_DATA_DIR=gpi_expand_path("$GPI_IFS_DIR/data/raw/")
		GPI_DRP_OUTPUT_DIR=gpi_expand_path("$GPI_IFS_DIR/data/reduced/")
	end
endcase




initgpi_default_onepath, 'GPI_DRP_DIR', GPI_DRP_DIR, /directory
initgpi_default_onepath, 'GPI_RAW_DATA_DIR', GPI_RAW_DATA_DIR, /directory, /write
initgpi_default_onepath, 'GPI_DRP_OUTPUT_DIR', GPI_DRP_OUTPUT_DIR, /directory, /write



GPI_DRP_QUEUE_DIR= 		GPI_DRP_DIR+path_sep()+'drf_queue'+path_sep()
GPI_DRP_CONFIG_DIR=		GPI_DRP_DIR+path_sep()+'config'+path_sep();+'gpi_pipeline_primitives.xml'
GPI_DRP_TEMPLATES_DIR=	GPI_DRP_DIR+path_sep()+'drf_templates'+path_sep()
GPI_DRP_LOG_DIR =		GPI_DRP_DIR+path_sep()+"log"+path_sep()

initgpi_default_onepath, 'GPI_DRP_QUEUE_DIR', GPI_QUEUE_DIR, /directory, /write
initgpi_default_onepath, 'GPI_DRP_TEMPLATES_DIR', GPI_DRF_TEMPLATES_DIR, /directory, /write
initgpi_default_onepath, 'GPI_DRP_LOG_DIR', GPI_DRP_LOG_DIR, /directory, /write
initgpi_default_onepath, 'GPI_DRP_CONFIG_DIR', GPI_DRP_CONFIG_FILE, /directory, /write

;if file_test(GPI_QUEUE_DIR,/directory, /write) && $
;   file_test(GPI_CONFIG_FILE) && $
;   file_test(GPI_DRF_TEMPLATES_DIR, /directory, /write) && $
;   file_test(GPI_RAW_DATA_DIR, /directory, /write) && $
;   file_test(GPI_DRP_DIR,/directory, /write) && $
;   file_test(GPI_DRP_OUTPUT_DIR,/directory, /write)  then begin
;      setenv,'GPI_QUEUE_DIR='+GPI_QUEUE_DIR
;      setenv,'GPI_CONFIG_FILE='+GPI_CONFIG_FILE
;      setenv,'GPI_DRF_TEMPLATES_DIR='+GPI_DRF_TEMPLATES_DIR
;      setenv,'GPI_RAW_DATA_DIR='+GPI_RAW_DATA_DIR
;      setenv,'GPI_DRP_DIR='+GPI_DRP_DIR
;      setenv,'GPI_DRP_LOG_DIR='+GPI_DRP_LOG_DIR
;      setenv,'GPI_DRP_DRF_DIR='+GPI_DRP_LOG_DIR
;      setenv,'GPI_DRP_OUTPUT_DIR='+GPI_DRP_OUTPUT_DIR
;endif else begin
;	FindPro, 'initgpi_default_paths', dirlist=dirlist
;	print, 'ERROR when initializing the pipeline: '
;	print, 'Please check setenv values in the function '+dirlist+path_sep()+'initgpi_default_paths.pro'
;	print, 'Some directories may not exist on your system. Change paths, create directories, and check permissions as needed.'
;	err=1
;endelse
end
