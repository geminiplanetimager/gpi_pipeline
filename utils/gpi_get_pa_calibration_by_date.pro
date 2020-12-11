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

if avmjd lt 56908.0d then begin
    tn_offset = 0.23d
    tn_error = 0.11d
endif else if avmjd lt 57326.0d then begin
    tn_offset = 0.17d
    tn_error = 0.14d
endif else if avmjd lt 57636.0d then begin
    tn_offset = 0.21d
    tn_error = 0.23d
endif else if avmjd lt 58039.0d then begin
    tn_offset = 0.32d
    tn_error = 0.15d
endif else if avmjd lt 58362.0d then begin
    tn_offset = 0.28d
    tn_error = 0.19d
endif else if avmjd lt 59215.0d then begin
    tn_offset = 0.45d
    tn_error = 0.11d
endif else begin
    backbone->log,'GPI_GET_PA_CALIBRATION_BY_DATE: No calibration value available, setting offset to zero!'
    tn_offset = 0.0d
    tn_error = 0.0d
endelse

return, [tn_offset, tn_error]

end
