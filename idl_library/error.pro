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
;
;-----------------------------------------------------------------------

FUNCTION error, mess, error_status, alert=alert

   COMMON APP_CONSTANTS

;   mess(0) = '!!!   ' + mess(0)
   m = size(mess,/N_ELEMENTS)
   if keyword_set(alert) then print, "***************************"
   for i=0, m-1 do print, '!!!   ' + mess(i)
   if (n_params() eq 2) then error_status = error_status + 1
	  ; stop
	  if n_elements(backbone) ne 0 then $
   backbone->Log, strjoin(mess), /DRF, DEPTH = 1, /GENERAL
    if n_elements(backbone_comm) ne 0 then $
   backbone_comm->Log, strjoin(mess), /DRF, DEPTH = 1, /GENERAL
   return, NOT_OK

END 
