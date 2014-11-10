;+
; NAME: update_progressbar
;     
;
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;    Jerome Maire 2009-02
;-

pro update_progressbar,Modules,indexModules, nbtotfile, filenum, status, adi=adi

COMMON shareWidID
COMMON PIP

	WIDGET_CONTROL, wChildBase, GET_UVALUE=pState
	; Update progress bar.
	if ~(keyword_set(adi)) then begin
		(*pState).vProgress=200.*double(filenum)/double(nbtotfile)
		(*pState).vProgressf=200.*double(indexModules)/double(N_ELEMENTS(Modules)-1)
	endif else begin 	
		(*pState).vProgress=200.*double(nbtotfile-1)/double(nbtotfile)+	(double(filenum+1)/double(nbtotfile))/double(nbtotfile)
		(*pState).vProgressf=200.*double(filenum)/double(nbtotfile)
	endelse	
	
	idlbridge_img_processing_update, pState
	idlbridge_img_processing_updatef, pState
	idlbridge_img_processing_refresh_name,pState,filename
	idlbridge_img_processing_refresh_suf,pState,suffix
	idlbridge_img_processing_refresh_status,pState,status
	if indexModules lt N_ELEMENTS(Modules)-1 then $
	idlbridge_img_processing_refresh_proc,pState,modules[indexModules+(~(keyword_set(adi)))].name

end
