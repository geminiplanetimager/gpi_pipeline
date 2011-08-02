; Set up environment variables for GPI IFS Software
; HISTORY:
;  2010-07-07 Created J. Maire
;  2011-07-29 MP: Validation of directory write permissions fixed up a bit. 

function gpi_is_setenv, first=first


if keyword_set(first) then begin 
 runfromvm = LMGR(/VM)
 if (runfromvm eq 0) && (float(!version.release) lt 6.3) then begin
   void=dialog_message('The DRP can not run with IDL version below v6.3. Please use IDL v6.3 or higher, or run DRP from executables.')
   return,-1
 endif

  ;are environment variables defined and valid?
  if file_test(getenv('GPI_IFS_DIR'),/dir,/write)&& $
  file_test(getenv('GPI_PIPELINE_DIR'),/dir) && $
  file_test(getenv('GPI_PIPELINE_LOG_DIR'),/dir,/write) && $
  file_test(getenv('GPI_DRF_TEMPLATES_DIR'),/dir) && $ 
  file_test(getenv('GPI_QUEUE_DIR'),/dir,/write) && $
  file_test(getenv('GPI_CONFIG_FILE')) && $
  file_test(getenv('GPI_RAW_DATA_DIR'),/dir) && $ 
  file_test(getenv('GPI_DRP_OUTPUT_DIR'),/dir,/write) then return,1 else return,0
  
endif else begin  
	; check all the supplied directories exist.

	drpvartab=['GPI_IFS_DIR','GPI_PIPELINE_DIR','GPI_PIPELINE_LOG_DIR','GPI_DRF_TEMPLATES_DIR',$
            'GPI_QUEUE_DIR','GPI_CONFIG_FILE','GPI_RAW_DATA_DIR','GPI_DRP_OUTPUT_DIR']
	txtmes=''
            
	for ii=0, n_elements(drpvartab)-1 do begin
		if strmatch(drpvartab[ii],'*DIR') then begin
		  if ~file_test(getenv(drpvartab[ii]),/dir) then txtmes+= ' '+drpvartab[ii]
		endif else begin
		  if ~file_test(getenv(drpvartab[ii])) then txtmes+= ' '+drpvartab[ii]
		endelse
	endfor   

    if txtmes ne '' then begin 
        if ~keyword_set(first) then void=dialog_message(txtmes+' does not exist. Please select existent directory.')
        return,0
    endif 
	
	; check that a subset of them are writeable.
	drpvartabwritable=['GPI_IFS_DIR','GPI_PIPELINE_LOG_DIR',$
			'GPI_QUEUE_DIR','GPI_DRP_OUTPUT_DIR']

	txtmeswritable=''
	for ii=0, n_elements(drpvartabwritable)-1 do begin
		if ~file_test(getenv(drpvartabwritable[ii]),/dir,/write) then txtmeswritable+= ' '+drpvartabwritable[ii]
	endfor   
	if txtmeswritable ne '' then begin 
		if ~keyword_set(first) then void=dialog_message('The path in '+txtmeswritable+'  is NOT WRITABLE. Please select a writable directory.')
		return,0
	endif  else begin
	
	
		return,1
	endelse    

endelse  
end   
