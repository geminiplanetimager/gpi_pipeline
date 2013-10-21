; Set up environment variables for GPI IFS Software
; HISTORY:
;  2010-07-07 Created J. Maire
;  2012-08-10 Updated to reflect latest DRP layout - ds
;  2013-10-21  Added descriptions for ease of install - PI

pro setenv_gpi_windows

;----- Required paths (editing required) --------------------
;GPI_DATA_ROOT is a helper path/variable only.  If desired you can set 
;all paths independently. For example, << setenv,  "GPI_DRP_QUEUE_DIR=C:\GPI\data\queue\" >>

; instances of C:\GPI\ should be replaced with the users directory structure of choice

; the user is **REQUIRED** to set the GPI_DATA_ROOT directory, then create the queue, Detector, and Reduced subdirectories (although the user can rename them to their chosing)
setenv,  "GPI_DATA_ROOT=C:\GPI\data\"         	       														; base dir for all data ** CHANGE REQUIRED**
setenv,  "GPI_DRP_QUEUE_DIR="+getenv('GPI_DATA_ROOT')+path_sep()+"\queue\"        ; where is the DRP Queue directory?
setenv,  "GPI_RAW_DATA_DIR="+getenv('GPI_DATA_ROOT')+path_sep()+"\Detector\"      ; where is raw data?
setenv,  "GPI_REDUCED_DATA_DIR="+getenv('GPI_DATA_ROOT')+path_sep()+"\Reduced\"   ; where should we put reduced data?

;---- Optional paths (no editing genererally needed) -------
; these variables are optional - you may omit them if your 
; drp setup is standard
setenv,  "GPI_DRP_DIR=C:\GPI\pipeline\"	       ; ** CHANGE REQUIRED**  pipeline code location (contains subdirectories backbone, config, gpitv etc.)
setenv,  "GPI_DRP_CONFIG_DIR="+getenv('GPI_DRP_DIR')+path_sep()+"\config\"            ; default config settings (no change required)
setenv,  "GPI_DRP_TEMPLATES_DIR="+getenv('GPI_DRP_DIR')+path_sep()+"\recipe_templates"	  ; pipeline DRF template location (no change required)

;  the user is **REQUIRED** to create the calibrations and logs subdirectories
setenv,  "GPI_DRP_CALIBRATIONS_DIR="+getenv('GPI_REDUCED_DATA_DIR')+path_sep()+"\calibrations\"	; pipeline calibration location
setenv,  "GPI_DRP_LOG_DIR="+getenv('GPI_REDUCED_DATA_DIR')+path_sep()+"\logs\"	                ; default log dir

;---- DST install only (optional) -----
setenv,  "GPI_DST_DIR=C:\GPI\dst\"	 


end
