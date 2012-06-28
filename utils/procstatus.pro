;+
; NAME: procstatus
; 		Progress bar
;
;
;
; HISTORY:
; 	Originally by Jerome Maire 2008-07
;
;-----------------------------------------------------------------
; Update a status bar with percentage of processing task completed
; in child process.
PRO idlbridge_img_processing_update, pState

	wDrawProgress = (*pState).wDrawProgress
	vProgress = (*pState).vProgress
	(*pState).xpos = 300*(vProgress/100.0)
	ERASE, 255
	POLYFILL, [0,0,5+(*pState).xpos,5+(*pState).xpos], $
	   [0, 19, 19,0], /device, color=80

END

;-----------------------------------------------------------------
; Refresh process info on statusbar.
PRO idlbridge_img_processing_abort_refresh,pState,str

    ; Access common block value and change label.
    ;COMMON shareWidID, wChildBase
;void = DIALOG_MESSAGE(str)
    ;WIDGET_CONTROL, wChildBase, GET_UVALUE=pState

	WIDGET_CONTROL, (*pState).wLabel2, SET_VALUE='Process: '+str

END

;-----------------------------------------------------------------
; Refresh process info on statusbar.
PRO idlbridge_img_processing_abort_refreshsuf,pState,str

    ; Access common block value and change label.
    ;COMMON shareWidID, wChildBase
;void = DIALOG_MESSAGE(str)
    ;WIDGET_CONTROL, wChildBase, GET_UVALUE=pState

	WIDGET_CONTROL, (*pState).wLabel2suf, SET_VALUE=' Saved (suffix): '+str

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

;------------------------------
pro procstatus,filenm
    ; Create a common block to hold the widget ID, wChildBase. This
    ; is used to cleanup if processing is completed, the user aborts
    ; or execution ends due to an error.
      COMMON shareWidID
if (not(xregistered('procstatus', /noshow))) then begin


    ; Make simple widget interface.
	wChildBase = WIDGET_BASE(TITLE='Process Progress', /COLUMN, $
	   XOFFSET=680)
	wLabel = WIDGET_LABEL(wChildBase, VALUE='Filename processed:'+filenm, $
	   UVALUE='LABEL',XSIZE=600,/ALIGN_LEFT)
	   	wLabel2suf = WIDGET_LABEL(wChildBase, VALUE=' Saved (suffix):', $
	   UVALUE='LABELPsuf',XSIZE=600,/ALIGN_LEFT)
	wLabel2 = WIDGET_LABEL(wChildBase, VALUE=' Processing:', $
	   UVALUE='LABELP',XSIZE=600,/ALIGN_LEFT)

	 wLabel3 = WIDGET_LABEL(wChildBase, VALUE=' Completion Status:', $
	   UVALUE='LABEL3')
	wDrawProgress = WIDGET_DRAW(wChildBase, xsize=600, ysize=20, $
	   uvalue="PROGRESS")

    ; Set initial color table for draw widget.
    DEVICE, DECOMPOSED=0
    LOADCT, 39

	State2 = {wChildBase:wChildBase, wDrawProgress:wDrawProgress, $
	   vProgress:0, xpos:0, wLabel:wLabel,wLabel2:wLabel2,wLabel2suf:wLabel2suf}
	pState = PTR_NEW(State2)
endif else begin
	WIDGET_CONTROL,(*pState).wLabel, SET_VALUE='Filename processed:'+filenm
endelse


	WIDGET_CONTROL, wChildBase, SET_UVALUE=pState
	WIDGET_CONTROL, wChildBase, /REALIZE
	;WIDGET_CONTROL, /HOURGLASS

	if (not(xregistered('procstatus', /noshow))) then begin
    xmanager, 'procstatus', wChildBase,/NO_BLOCK
	endif
;return, pState
END