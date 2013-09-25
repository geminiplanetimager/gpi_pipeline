; Set up environment variables for GPI IFS Software
; HISTORY:
;  2010-07-07 Created J. Maire
;  2012-08-10 Updated to reflect latest DRP layout - ds

pro setenv_gpi_windows

;----- Required paths (editing required) --------------------
;GPI_DATA_ROOT is a helper path only.  If desired you can set 
;all paths independently.  
;NOTE: If you are pulling all data from the vospace, do NOT 
;put your queue and Reduced directories on the same path as 
;the raw data.  Make these local.
setenv,  "GPI_DATA_ROOT=C:\GPI\data\"         	       ; base dir for all data
setenv,  "GPI_DRP_QUEUE_DIR="+getenv('GPI_DATA_ROOT')+path_sep()+"\queue\"        ; where is the DRP Queue directory?
setenv,  "GPI_RAW_DATA_DIR="+getenv('GPI_DATA_ROOT')+path_sep()+"\Detector\"      ; where is raw data?
setenv,  "GPI_REDUCED_DATA_DIR="+getenv('GPI_DATA_ROOT')+path_sep()+"\Reduced\"   ; where should we put reduced data?

;---- Optional paths (no editing genererally needed) -------
; these variables are optional - you may omit them if your 
; drp setup is standard
setenv,  "GPI_DRP_DIR=C:\GPI\pipeline\"	                    ; pipeline code location
setenv,  "GPI_DRP_CONFIG_DIR="+getenv('GPI_DRP_DIR')+path_sep()+"\config\"            ; default config settings 
setenv,  "GPI_DRP_TEMPLATES_DIR="+getenv('GPI_DRP_DIR')+path_sep()+"\recipe_templates"	  ; pipeline DRF template location

setenv,  "GPI_DRP_CALIBRATIONS_DIR="+getenv('GPI_REDUCED_DATA_DIR')+path_sep()+"\calibrations\"	; pipeline calibration location
setenv,  "GPI_DRP_LOG_DIR="+getenv('GPI_REDUCED_DATA_DIR')+path_sep()+"\logs\"	                ; default log dir

;---- DST install only (optional) -----
setenv,  "GPI_DST_DIR=C:\GPI\dst\"	 


end
