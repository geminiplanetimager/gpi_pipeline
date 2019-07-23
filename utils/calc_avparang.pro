function parang_eq,H
;;helper function for calc_avparang

common calc_avparangle_common,d,phi,wrap_flag
paint_ineq = atan(sin(H)*cos(phi),sin(phi)*cos(d) - sin(d)*cos(phi)*cos(H))

;; to remove discontinuity from -179 to 179
;; may lead to average parang being > 180, so parang is wrapped at the end of the function
if wrap_flag && (H < 0.0d) then paint_ineq += 2.0d*!dpi
return, paint_ineq


end

function calc_avparang,HAstart,HAend,dec,lat=lat,degree=degree
;+
; NAME:
;      CALC_AVPARANGLE
;
; PURPOSE:
;      Return the average parallactic angle of a source over the
;      course of an observation.
;
; CALLING SEQUENCE:
;      Result = CALC_AVPARANGLE(HA, DEC, LATITUDE [,/DEGREE])
;
; INPUTS:
;      HAstart,HAend - The starting and ending hour angle of the
;                      source in decimal hours, unless /DEGREE keyword
;                      is set, in which case input is assumed to be in
;                      decimal degrees.
;      DEC - the declination of the source in decimal degrees
;
;      LATITUDE - The geodetic latitude of the telescope in decimal degrees
;
; KEYWORD PARAMETERS:
;      /DEGREE - If set, then the HA values have been input in degrees
;                rather than hours.
;
; OUTPUTS:
;     res - Average parallactic angle in decimal degrees.
;
; COMMON BLOCKS:
;      calc_avparangle_common
;
; RESTRICTIONS:
;
; EXAMPLE:
;
; NOTES:
;
; MODIFICATION HISTORY:
;	Written 08.14.2013 - ds
;   2019-07-16 - Fixed integration for exposures through transit.
;                Was previoulsy integrating curve as 
;                int_h0^0 abs(p) dt + int_0^h1 p dt, rather than
;                int_h0^0 p+2pi  dt + int_0^h1 p dt.
;-

common calc_avparangle_common,d,phi,wrap_flag

;;check inputs
if (n_elements(HAstart) ne 1) || (n_elements(HAend) ne 1) || (n_elements(dec) ne 1) then message,'All inputs must be scalar.'

if ~keyword_set(lat) then lat = gpi_get_constant('observatory_lat',default=-30.24075d0) else $
   if n_elements(lat) ne 1 then message,'Latitude must be scalar.'

;;Sometimes because of how this was done we get an HA larger than
;;24. or smaller than -24.  Correct for this first, then the
;;test4transit code should take care of the rest.

if HAstart le -12.d then HAstart = HAstart + 24.d
if HAstart gt 24.d then HAstart = HAstart - 24.d
if HAend le -12.d then HAend = HAend + 24.d
if HAend gt 24.d then HAend = HAend - 24.d

;;convert everything radians (converting to degrees first as needed)
h0 =  HAstart * !dpi/180d0
h1 =  HAend * !dpi/180d0
phi = lat * !dpi/180d0
d =   dec * !dpi/180d0

if ~keyword_set(degree) then begin
   h0 *= 15d0
   h1 *= 15d0
endif

;h1*h0 < 0 if HA goes from -ve to +ve
;if we cross meridian and are in the north there is a discontinuity in parang
wrap_flag = 0
if ((h1 * h0) lt 0) && (d gt phi) then wrap_flag = 1

;; Wrap treated inside parang_eq
paint = qromb('parang_eq',h0,h1,/double,eps=1e-8)

;This is accurate to 0.0001 degrees.  Our target astrometric accuracy
;is 1 mas, which at the edge of the field (1.4") is 0.04
;degrees.

final_parang = paint/(h1-h0) * 180d0/!dpi

;Because of the wrap it's possible that parang is no longer
;between -180 and 180

above180 = where(final_parang gt 180d0)
if above180(0) ne -1 then final_parang(above180) = final_parang(above180) $
  -360d0
belowneg180 = where(final_parang le -180d0)
if belowneg180(0) ne -1 then final_parang(belowneg180) = $
  final_parang(belowneg180) +360d0

return,final_parang

end
