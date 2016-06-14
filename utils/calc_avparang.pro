function parang_eq,H
;;helper function for calc_avparang

common calc_avparangle_common,d,phi

paint_ineq = atan(sin(H)*cos(phi),sin(phi)*cos(d) - sin(d)*cos(phi)*cos(H))
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
;-

common calc_avparangle_common,d,phi

;;check inputs
if (n_elements(HAstart) ne 1) || (n_elements(HAend) ne 1) || (n_elements(dec) ne 1) then message,'All inputs must be scalar.'

if ~keyword_set(lat) then lat = gpi_get_constant('observatory_lat',default=-30.24075d0) else $
   if n_elements(lat) ne 1 then message,'Latitude must be scalar.'

;;Sometimes because of how this was done we get an HA larger than
;;24. or smaller than -24.  Correct for this first, then the
;;test4transit code should take care of the rest.

if HAstart le -12. then HAstart = HAstart + 24.
if HAstart gt 24. then HAstart = HAstart - 24.
if HAend le -12. then HAend = HAend + 24.
if HAend gt 24. then HAend = HAend - 24.

;;convert everything radians (converting to degrees first as needed)
h0 =  HAstart * !dpi/180d0
h1 =  HAend * !dpi/180d0
phi = lat * !dpi/180d0
d =   dec * !dpi/180d0

if ~keyword_set(degree) then begin
   h0 *= 15d0
   h1 *= 15d0
endif

;the next step sometimes fails when crossing transit, so first check
;if it crosses transit

test4transit = h1 * h0 ;negative if the two have different signs
if test4transit lt 0 then begin

;We crossed transit, so split the integral in two around 0, this
;bypasses the underflow problem that causes the step to fail

paint1 = qromb('parang_eq',h0,0d0,/double,eps=1e-8)
paint2 = qromb('parang_eq',0d0,h1,/double,eps=1e-8)

;Now, beware of the wrap: if we average -179 and +179 we should get
;180, not 0

if abs(paint1) gt paint2 then paint = paint1 - paint2 else $
paint = paint2 - paint1

;(the equivalent of taking abs(paint1) + abs(paint2), then making it negative
;if most of the average is from the negative side of wrap)

endif else begin

;Not crossing transit, so do what we like
paint = qromb('parang_eq',h0,h1,/double,eps=1e-8)

endelse
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
