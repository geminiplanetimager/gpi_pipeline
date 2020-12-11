function gpi_get_pa_calibration_by_date,avmjd
;+
; NAME:
;      GPI_GET_PA_CALIBRATION_BY_DATE
;
; PURPOSE:
;      Return the true north correction for a given MJD.
;
; CALLING SEQUENCE:
;      Result = GPI_GET_PA_CALIBRATION_BY_DATE(AVMJD)
;
; INPUTS:
;      avmjd- The MJD at the exposure midpoint
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;     tn_offset - North offset to be added to ifs_rotation
;     tn_error - Uncertainty in north offset
;
; COMMON BLOCKS:
;
; RESTRICTIONS:
;
; EXAMPLE:
;
; NOTES:
;
; MODIFICATION HISTORY:
;   Written 11.12.2020 - R. De Rosa
;
;-

if avmjd < 56908.0d then begin
    tn_offset = 0.23
    tn_error = 0.11
endif else if avmjd < 57326.0d then begin
    tn_offset = 0.17
    tn_error = 0.14
endif else if avmjd < 57636.0d then begin
    tn_offset = 0.21
    tn_error = 0.23
endif else if avmjd < 58039.0d then begin
    tn_offset = 0.32
    tn_error = 0.15
endif else if avmjd < 58362.0d then begin
    tn_offset = 0.28
    tn_error = 0.19
endif else if avmjd < 59215.0d then begin
    tn_offset = 0.45
    tn_error = 0.11
endif else begin
    backbone->log,'GPI_GET_PA_CALIBRATION_BY_DATE: No calibration value available, setting offset to zero!'
    tn_offset = 0.0
    tn_error = 0.0
endelse

return, [tn_offset, tn_error]

end
