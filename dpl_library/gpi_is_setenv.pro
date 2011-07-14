; Verify environment variables for GPI IFS Software
; HISTORY:
;  2010-07-07 Created J. Maire
;  2011-07-13 MDP: Reworked as for loop, added code to print informative error
;  messages rather than just throw up an incomprehensible dialog.

function gpi_is_setenv

vars_to_check = ['GPI_IFS_DIR', 'GPI_PIPELINE_DIR', 'GPI_PIPELINE_LOG_DIR', 'GPI_DRF_TEMPLATES_DIR', $
				'GPI_QUEUE_DIR', 'GPI_CONFIG_FILE', 'GPI_RAW_DATA_DIR', 'GPI_DRP_OUTPUT_DIR']

all_ok = 1
for i=0L,n_elements(vars_to_check)-1 do begin
	var = vars_to_check[i]
	if getenv(var) eq '' then begin
		message,/info, 'ERROR: Environment variable '+var+' is not defined.'
		all_ok = 0
	endif else begin
		if strpos(var,'_DIR') ge 0 then begin
			if not file_test( getenv(var),/dir) then begin
				message,/info, 'ERROR: Environment variable '+var+' does not point to a valid directory.'
				all_ok = 0
			endif 
		endif else begin
			if not file_test( getenv(var),/read) then begin
				message,/info, 'ERROR: Environment variable '+var+' does not point to a valid readable file.'
				all_ok = 0
			endif 
	
		endelse 
	endelse

endfor 


;;are environment variables defined and valid?
;if file_test(getenv('GPI_IFS_DIR'),/dir) && $
  ;file_test(getenv('GPI_PIPELINE_DIR'),/dir) && $
  ;file_test(getenv('GPI_PIPELINE_LOG_DIR'),/dir) && $
  ;file_test(getenv('GPI_DRF_TEMPLATES_DIR'),/dir) && $ 
  ;file_test(getenv('GPI_QUEUE_DIR'),/dir) && $
  ;file_test(getenv('GPI_CONFIG_FILE')) && $
  ;file_test(getenv('GPI_RAW_DATA_DIR'),/dir) && $ 
  ;file_test(getenv('GPI_DRP_OUTPUT_DIR'),/dir) then return,1 else return,0
return, all_ok
  
end   
