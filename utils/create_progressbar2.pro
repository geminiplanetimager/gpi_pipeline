
;-----------------------------------------------------------------
; Update a status bar with percentage of processing task completed
; in child process. --WHOLE DATA
PRO idlbridge_img_processing_update, pState
	WIDGET_CONTROL, (*pState).wDrawProgress, get_VALUE=drawbar
	wset, drawbar
	wDrawProgress = (*pState).wDrawProgress
	vProgress = (*pState).vProgress
	(*pState).xpos = 300*(vProgress/100.0)
	ERASE, 255
	POLYFILL, [0,0,5+(*pState).xpos,5+(*pState).xpos], $
	   [0, 19, 19,0], /device, color=80

END
;-----------------------------------------------------------------
; Update a status bar with percentage of processing task completed
; in child process. --current FILE
PRO idlbridge_img_processing_updatef, pState
	WIDGET_CONTROL, (*pState).wDrawProgressf, get_VALUE=drawbar
	wset, drawbar
	wDrawProgressf = (*pState).wDrawProgressf
	vProgressf = (*pState).vProgressf
	(*pState).xposf = 300*(vProgressf/100.0)
	ERASE, 255
	POLYFILL, [0,0,5+(*pState).xposf,5+(*pState).xposf], $
	   [0, 19, 19,0], /device, color=80

END
;-----------------------------------------------------------------
; Refresh process info on statusbar.
PRO idlbridge_img_processing_refresh_name,pState,str

    ; Access common block value and change label.
    ;COMMON shareWidID, wChildBase
	;void = DIALOG_MESSAGE(str)
    ;WIDGET_CONTROL, wChildBase, GET_UVALUE=pState

	WIDGET_CONTROL, (*pState).wLabel, SET_VALUE='Filename processed:'+str

END
;-----------------------------------------------------------------
; Refresh process info on statusbar.
PRO idlbridge_img_processing_refresh_proc,pState,str

    ; Access common block value and change label.
    ;COMMON shareWidID, wChildBase
	;void = DIALOG_MESSAGE(str)
    ;WIDGET_CONTROL, wChildBase, GET_UVALUE=pState

	WIDGET_CONTROL, (*pState).wLabel2, SET_VALUE='Process: '+str

END

;-----------------------------------------------------------------
; Refresh process info on statusbar.
PRO idlbridge_img_processing_refresh_suf,pState,str

    ; Access common block value and change label.
    ;COMMON shareWidID, wChildBase
;void = DIALOG_MESSAGE(str)
    ;WIDGET_CONTROL, wChildBase, GET_UVALUE=pState

	WIDGET_CONTROL, (*pState).wLabel2suf, SET_VALUE=' Saved (suffix): '+str

END

;-----------------------------------------------------------------
; Refresh process info on statusbar.
PRO idlbridge_img_processing_refresh_status,pState,str

    ; Access common block value and change label.
    ;COMMON shareWidID, wChildBase
;void = DIALOG_MESSAGE(str)
    ;WIDGET_CONTROL, wChildBase, GET_UVALUE=pState

  WIDGET_CONTROL, (*pState).wLabelstatus, SET_VALUE=' Completion Status:'+str

END

;-----------------------------------------------------------------
; Remove progress bar display if user aborts or if there is an error.
PRO idlbridge_img_processing_abort_cleanup

    ; Access common block value and cleanup.
    COMMON shareWidID, wChildBase

    WIDGET_CONTROL, wChildBase, GET_UVALUE=pState
	WIDGET_CONTROL,  wChildBase, /DESTROY
	PTR_FREE, pState

END

;--------------------------------------------

pro create_progressbar2

    ; Create a common block to hold the widget ID, wChildBase. This
    ; is used to cleanup if processing is completed, the user aborts
    ; or execution ends due to an error.
    COMMON shareWidID, wChildBase
	DEBUG_FRAMES=1

    ; Make simple widget interface.
	wChildBase = WIDGET_BASE(TITLE='GPI Data Pipeline Status Console', /COLUMN, XOFFSET=680)

	;---- overall config 
	w_config_base = widget_base(wChildBase,/column, frame=DEBUG_FRAMES)
	lab = widget_label(w_config_base, value="Queue Dir:     "+ getenv('GPI_QUEUE_DIR') )




	;---- current status
	w_status_base =  widget_base(wChildBase,/column, frame=DEBUG_FRAMES)
	wLabel = WIDGET_LABEL(w_status_base, VALUE='Filename processed:', $
	   UVALUE='LABEL',/DYNAMIC_RESIZE,/ALIGN_LEFT)
	wLabel2suf = WIDGET_LABEL(w_status_base, VALUE=' Saved (suffix):', $
	   UVALUE='LABELPsuf',XSIZE=600,/ALIGN_LEFT)
	wLabel2 = WIDGET_LABEL(w_status_base, VALUE=' Processing:', $
	   UVALUE='LABELP',XSIZE=600,/ALIGN_LEFT)
	wLabelstatus = WIDGET_LABEL(w_status_base, VALUE=' Completion Status:', $
	   UVALUE='LABEL3',/DYNAMIC_RESIZE)
	wDrawProgress = WIDGET_DRAW(w_status_base, xsize=600, ysize=20, $
	   uvalue="PROGRESS")
	wLabel4 = WIDGET_LABEL(w_status_base, VALUE=' Current Image Completion Status:', $
	   UVALUE='LABEL4')
	wDrawProgressf = WIDGET_DRAW(w_status_base, xsize=600, ysize=20, $
	   uvalue="PROGRESSF")

	;---- current status
	w_log_base = widget_base(wChildBase,/column, frame=DEBUG_FRAMES,/base_align_left)
	lab = widget_label(w_log_base, value="Pipeline Log Message History:")
	text = widget_text(w_log_base, ysize=5, xsize=100)



    ; Set initial color table for draw widget.
    DEVICE, DECOMPOSED=0
    LOADCT, 39

	State2 = {wChildBase:wChildBase, wDrawProgress:wDrawProgress, $
	   wDrawProgressf:wDrawProgressf,vProgress:0,vProgressf:0, xpos:0,xposf:0, $
	   wLabel:wLabel,wLabel2:wLabel2,wLabel2suf:wLabel2suf,wLabelstatus:wLabelstatus}
	pState = PTR_NEW(State2)
	WIDGET_CONTROL, wChildBase, SET_UVALUE=pState
	WIDGET_CONTROL, wChildBase, /REALIZE
	;WIDGET_CONTROL, /HOURGLASS

  if (not(xregistered('procstatus', /noshow))) then begin
    xmanager, 'procstatus', wChildBase,/NO_BLOCK
  endif
    ; Update progress bar.
    (*pState).vProgress=3
	(*pState).vProgressf=3
	idlbridge_img_processing_update, pState
	idlbridge_img_processing_updatef, pState



end


