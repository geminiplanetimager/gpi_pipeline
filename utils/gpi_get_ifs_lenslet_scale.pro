function gpi_get_ifs_lenslet_scale,h,res=res
;+
; NAME:
;     gpi_get_ifs_lenslet_scale
;
; PURPOSE:
;     Return lenslet scale from WCS info in header.  If image never
;     made it through an update_wcs routing (AVPARANG not set) or WCS
;     data is bad then return value from config file. 
;
; CALLING SEQUENCE:
;     ifs_lenslet_scale = gpi_get_ifs_lenslet_scale(h,res)
;
; INPUT/OUTPUT
;     H - Header containing WCS infor (sci extension header)
;     ifs_lenslet_scale - The scale in arcseconds
;
; OPTIONAL INPUT/OUTPUT KEYWORDS:
;     res - Code of result from extast (-1 if no valid WCS info). -2
;           if cube is raw.
;       
; NOTES:
;       
; PROCEDURES CALLED:
;      extast,getrot,gpi_get_constant
;
; REVISION HISTORY
;      Written ds 10.24.2013
;-

avparang = sxpar(h,'AVPARANG',count=ct)

if (ct ne 1) || (avparang eq 0d0) then begin
   res = -2
   return, gpi_get_constant('ifs_lenslet_scale',default = 0.0143d0)
endif 

extast, h, astr, res
if res eq -1 then return, gpi_get_constant('ifs_lenslet_scale',default = 0.0143d0) else begin

   getrot,astr,rot,cdelt,/silent
   return,abs(cdelt[0]*3600d0)

endelse 

end
