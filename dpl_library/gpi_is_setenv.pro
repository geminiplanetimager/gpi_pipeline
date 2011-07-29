; Set up environment variables for GPI IFS Software
; HISTORY:
;  2010-07-07 Created J. Maire

function gpi_is_setenv, first=first


txtmes=''
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

drpvartab=['GPI_IFS_DIR','GPI_PIPELINE_DIR','GPI_PIPELINE_LOG_DIR','GPI_DRF_TEMPLATES_DIR',$
            'GPI_QUEUE_DIR','GPI_CONFIG_FILE','GPI_RAW_DATA_DIR','GPI_DRP_OUTPUT_DIR']
            
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
    endif  else begin
        txtmeswritable=''
        drpvartabwritable=['GPI_IFS_DIR','GPI_PIPELINE_LOG_DIR',$
                'GPI_QUEUE_DIR','GPI_DRP_OUTPUT_DIR']
        for ii=0, n_elements(drpvartabwritable)-1 do begin
          if strmatch(drpvartabwritable[ii],'*DIR') then begin
            if ~file_test(getenv(drpvartabwritable[ii]),/dir) then txtmeswritable+= ' '+drpvartabwritable[ii]
          endif else begin
            if ~file_test(getenv(drpvartabwritable[ii])) then txtmeswritable+= ' '+drpvartabwritable[ii]
          endelse
        endfor   
        if txtmes ne '' then begin 
            if ~keyword_set(first) then void=dialog_message(txtmeswritable+' NOT WRITABLE. Please select writable directory.')
            return,0
        endif  else begin
        
        
            return,1
        endelse    
    endelse           

endelse  
end   
