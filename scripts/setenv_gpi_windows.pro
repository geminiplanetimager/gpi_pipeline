; Set up environment variables for GPI IFS Software
; HISTORY:
;  2010-07-07 Created J. Maire

pro setenv_gpi_windows


;----- Most users will only need to change this next line -----
setenv, 'GPI_IFS_DIR=E:\testsvn3'


;----- Most users will not need to change anything below here -----

; where is the software?
setenv, 'GPI_DRP_DIR='+getenv('GPI_IFS_DIR')+path_sep()+'pipeline'+path_sep()  ; pipeline software
setenv, 'GPI_DRP_LOG_DIR='+getenv('GPI_IFS_DIR')+path_sep()+'logs'+path_sep()    ; default log dir
setenv, 'GPI_DRP_TEMPLATES_DIR='+getenv('GPI_DRP_DIR')+path_sep()+'drf_templates'+path_sep() ; template Data Reduction Files
setenv, 'GPI_DRP_QUEUE_DIR='+getenv('GPI_DRP_DIR')+path_sep()+'queue'+path_sep()   ; DRF Queue directory
setenv, 'GPI_DRP_CONFIG_FILE='+getenv('GPI_DRP_DIR')+path_sep()+'config'+path_sep()+'gpi_pipeline_primitives.xml'

; where is the data?
setenv, 'GPI_RAW_DATA_DIR='+getenv('GPI_IFS_DIR')+path_sep()+'data'+path_sep()+'raw'+path_sep()
setenv, 'GPI_DRP_OUTPUT_DIR='+getenv('GPI_IFS_DIR')+path_sep()+'data'+path_sep()+'reduced'+path_sep()

end
