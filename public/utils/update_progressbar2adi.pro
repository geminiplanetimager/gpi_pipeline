;+
; NAME: update_progressbar2ADI
;     
;
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;    Jerome Maire 2009-02
;

pro update_progressbar2adi,Modules,indexModules, nbtotfile, filenum, status

COMMON shareWidID
COMMON PIP

nmodules=N_elements(Modules)
WIDGET_CONTROL, wChildBase, GET_UVALUE=pState
 ; Update progress bar.
 	(*pState).vProgress=200*double(nbtotfile-1)/double(nbtotfile)+ (double(filenum+1)/double(nbtotfile))/double(nbtotfile)
 	(*pState).vProgressf=200*double(filenum)/double(nbtotfile)
	idlbridge_img_processing_update, pState
	idlbridge_img_processing_updatef, pState
	idlbridge_img_processing_refresh_name,pState,filename
	idlbridge_img_processing_refresh_suf,pState,suffix
	idlbridge_img_processing_refresh_status,pState,status
	;if indexModules lt N_ELEMENTS(Modules)-1 then $
	idlbridge_img_processing_refresh_proc,pState,modules[indexModules].name

end
