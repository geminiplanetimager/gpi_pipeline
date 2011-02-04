; Set up environment variables for GPI IFS Software
; HISTORY:
;  2010-07-07 Created J. Maire

function gpi_is_setenv

;;are environment variables defined and valid?
if file_test(getenv('GPI_IFS_DIR'),/dir) && $
  file_test(getenv('GPI_PIPELINE_DIR'),/dir) && $
  file_test(getenv('GPI_PIPELINE_LOG_DIR'),/dir) && $
  file_test(getenv('GPI_DRF_TEMPLATES_DIR'),/dir) && $ 
  file_test(getenv('GPI_QUEUE_DIR'),/dir) && $
  file_test(getenv('GPI_CONFIG_FILE')) && $
  file_test(getenv('GPI_RAW_DATA_DIR'),/dir) && $ 
  file_test(getenv('GPI_DRP_OUTPUT_DIR'),/dir) then return,1 else return,0
  
end   
