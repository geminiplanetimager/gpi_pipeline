;-----------------------------------------------------------------------
; NAME:  error
;
; PURPOSE: Prints a error message to stdou and the logfile, 
;          increases the error_status and returns ERR_UNKNOWN
;
; INPUT :  mess  : error message
;
; STATUS : untested
;
; HISTORY : 27.2.2004, created
;
; AUTHOR : Christof Iserlohe (iserlohe@ph1.uni-koeln.de)
;		   From the Keck OSIRIS data pipeline.
;
;-----------------------------------------------------------------------

FUNCTION error, mess, error_status, alert=alert

   COMMON APP_CONSTANTS, $
        OK, NOT_OK, ERR_UNKNOWN, GOTO_NEXT_FILE,        $        ; Indicates success
        backbone_comm, $         ; Object pointer for main backbone (for access in subroutines & modules) 
        loadedcalfiles, $        ; object holding loaded calibration files (as pointers)
        DEBUG                    ; is DEBUG mode enabled?

	if n_elements(ok) eq 0 then begin
		OK = 0
		NOT_OK = -1
	endif
 
;   mess(0) = '!!!   ' + mess(0)
   m = size(mess,/N_ELEMENTS)
   if keyword_set(alert) then print, "***************************"
   for i=0, m-1 do print, '!!!   ' + mess(i)
   if (n_params() eq 2) then error_status = error_status + 1
	
	; two possible ways we could have been passed the backbone?

	if n_elements(backbone) ne 0 then  backbone->Log, strjoin(mess), DEPTH = 1
    if n_elements(backbone_comm) ne 0 then  backbone_comm->Log, strjoin(mess),DEPTH = 1
   return, NOT_OK

END 
