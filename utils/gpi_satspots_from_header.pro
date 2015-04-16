function gpi_satspots_from_header,h,good=good,fluxes=fluxes,warns=warns,psfcens=psfcens
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
;      res = gpi_satspots_from_header(h,[good=good,fluxes=fluxes,warns=warns,psfcens=psfcens])
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
;      psfcens - 2xnlam array of PSF centers
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
;      10.11.2014 - ds - added psfcens output
;-

  compile_opt defint32, strictarr, logical_predicate

  ;;figure out the number of slices
  nlam = sxpar(h,'NAXIS3',count=ct)
  if (ct ne 1) || (nlam lt 1) then return, -1

  prism = sxpar(h,'DISPERSR')
  ;if strmatch(dispersr, '*PRISM*') then begin
  if nlam gt 2 then begin 
	;--- SPECTRAL MODE---

	  ;;get the hex mask string
	  tmp = sxpar(h,"SATSMASK", count=ct)
	  if ct ne 1 then return, -1

	  ;;convert mask to binary
	  goodcode = hex2bin(tmp,nlam)
	  good = long(where(goodcode eq 1))

	  ;;allocate and populate locations
	  cens = dblarr(2,4,nlam) + !values.d_nan 
	  if arg_present(psfcens) then psfcens = dblarr(2,nlam) + !values.d_nan
	  for s=0,n_elements(good) - 1 do begin
		 for j = 0,3 do begin 
			tmp = dblarr(2) + !values.d_nan 
			reads,sxpar(h,'SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2)),tmp,format='(F7," ",F7)' 
			cens[*,j,good[s]] = tmp 
		 endfor 
		 if arg_present(psfcens) then begin
			tmp = dblarr(2) + !values.d_nan 
			reads,sxpar(h,'PSFC_'+strtrim(long(good[s]),2)),tmp,format='(F7," ",F7)' 
			psfcens[*,good[s]] = tmp
		 endif 
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
  endif else if nlam eq 2 then begin
	;--- POLARIMETRY MODE---
	; in this case jsut read in the PSFCENTX and PSFCENTY from the Radon
	; transform and infer everything else from that.

	  cens = dblarr(2,4,2) + !values.d_nan  ; dummy, not really used
	  psfcens = dblarr(2,2) + !values.d_nan
	  tmp = sxpar(h, 'PSFCENTX', count=ct)
	  if ct ne 1 then return, -1
	  psfcens[0,*] = tmp
	  tmp = sxpar(h, 'PSFCENTY', count=ct)
	  if ct ne 1 then return, -1
	  psfcens[1,*] = tmp

	  cens[0,*,*] = psfcens[0]
	  cens[1,*,*] = psfcens[1]

	  ; don't do anything with fluxes or warnings but hand back placeholders to
	  ; support gpitv expecting them
	  if arg_present(fluxes) then fluxes = dblarr(4,2) + !values.d_nan 
	  if arg_present(warns) then warns = dblarr(4,2) ; assume all good
	  if arg_present(good) then good = [0,1] ; ditto

  endif else begin
	; UNKNOWN PRISM
	return, 01
  endelse
	  
  return,cens

end
