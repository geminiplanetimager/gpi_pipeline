; This is error catching code for event handlers in gpitv
; 
; This is not a standalone function and is not intended to be called directly,
; rather it is a common code block for inclusion in many places in gpitv via
; "@gpitv_err" in gpitv__define.pro

if gpi_get_setting('enable_gpitv_debug',default=0,/silent) then begin
   theError = 0        ; don't use catch when debugging, stop on errors
endif else begin
   catch, theError
endelse
IF theError NE 0 THEN BEGIN
    Help, /Last_Message, Output=theErrorMessage
    FOR j=0,N_Elements(theErrorMessage)-1 DO BEGIN
        print,theErrorMessage[j]
    ENDFOR
    RETURN
ENDIF
