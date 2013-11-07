function gpi_satspots_from_header,h,good=good,fluxes=fluxes,warns=warns
;+
; NAME:
;       gpi_satspots_from_header
;
; PURPOSE:
;       Extract satellite spot locations and fluxes from header
;
; EXPLANATION:
;       Read satellite spot locations from header and repackage into a
;       numerical array
;
; Calling SEQUENCE:
;      res = gpi_satspots_from_header(backbone,nlam,[good=good])
;
; INPUT/OUTPUT:
;      h - Header containing satspot info (typically science im extension)
; 
;      res - 2x4xnlam array of satellite spot locations (pixels).
;
; OPTIONAL OUTPUT:
;      good - slices with valid satspot information
;      fluxes - 4xnlam array of satellite spot fluxes (in units of
;               image)
;      warns - slices with spots varying by more than 25%
;
; EXAMPLE:
;
;
; DEPENDENCIES:  
;      sxpar     
;
; NOTES:
;      Returns -1 if no satspot info is present
;
; REVISION HISTORY
;      10.21.2013 - ds
;-

  ;;figure out the number of slices
  nlam = sxpar(h,'NAXIS3',count=ct)
  if (ct ne 1) || (nlam lt 1) then return, -1

  ;;get the hex mask string
  tmp = sxpar(h,"SATSMASK", count=ct)
  if ct ne 1 then return, -1

  ;;convert mask to binary
  goodcode = hex2bin(tmp,nlam)
  good = long(where(goodcode eq 1))

  ;;allocate and populate locations
  cens = dblarr(2,4,nlam) + !values.d_nan 
  for s=0,n_elements(good) - 1 do begin
     for j = 0,3 do begin 
        tmp = dblarr(2) + !values.d_nan 
        reads,sxpar(h,'SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2)),tmp,format='(F7," ",F7)' 
        cens[*,j,good[s]] = tmp 
     endfor 
  endfor

  ;;now get the flux info, if it's there and was requested
  tmp = sxpar(h,"SATSWARN", count=ct)
  if (ct eq 1) && arg_present(fluxes) then begin
     ;;convert mask to binary
     warns = hex2bin(tmp,nlam)
     
     ;;allocate and populate fluxes
     fluxes = dblarr(4,nlam) + !values.d_nan 
     for s=0,n_elements(good) - 1 do begin
        for j = 0,3 do begin 
           fluxes[j,good[s]] = sxpar(h,'SATF'+strtrim(long(good[s]),2)+'_'+strtrim(j,2))  
        endfor 
     endfor

  endif
  
  return,cens

end
