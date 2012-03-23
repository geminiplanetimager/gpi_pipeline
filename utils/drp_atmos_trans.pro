;+
; NAME: atmos_trans
;		Computes atmospheric transmission, using a lookup table from Gemini
;
;		Right now the PWV is fixed, and we assume the effect of airmass is just
;		linear (this is not strictly speaking true but isn't a bad approx...)
;
;	The data comes from
;	http://www.gemini.edu/sciops/telescopes-and-sites/observing-condition-constraints/transmission-spectra
;
;
; INPUTS:
; KEYWORDS:
; 	lambda		desired wavelength array. The atmosphere will be returned
; 				converted to this array.
; 	airmass		airmass
; 	hdr			FITS header for history
; OUTPUTS:
;
; HISTORY:
; 	Began  by Jerome
;  2008-04-07  	Documentation added, airmass keyword too (though it is currently
;  				ignored). Algorithm IDL-ized a bit too (perhaps needlessly...)   MDP
;-

function drp_Atmos_Trans, Lamb, airmass=airmass, hdr=hdr


;widthL=(lambda(1)-lambda(0))


fileTransAtmos=getenv('GPI_DRP_DIR')+path_sep()+'dst'+path_sep()+'trans_16_15.dat' ;1.6mm Water vapour column, lambda[um] sampling 5A
ref_airmass = 1.5

;if arg_present(hdr) then sxaddhist, " Atm trans file="+'trans_16_15.dat' , hdr
;if arg_present(hdr) then sxaddhist, "Using atmospheric transmission for 1.6 mm PWV, Airmass=1.5 !", hdr

TransAtmos = READ_ASCII(fileTransAtmos, DATA_START=10)

atmos_wavelen = TransAtmos.field1[0,*] ; in microns
atmos_trans_ = TransAtmos.field1[1,*]

; convert it to the desired wavelength range

output_trans = fltarr(n_elements(lamb))

; Check if the step size agrees or not.
trans_step = atmos_wavelen[1] - atmos_wavelen[0]
lamb_step =lamb[1] - lamb[0]
samestep = (round(lamb_step*1e5) eq round(trans_step *1e5))

if samestep then begin ; don't need to worry about interpolating
	diff = min( abs(atmos_wavelen - lamb[0]), wmin)
	diff = min( abs(atmos_wavelen - lamb[n_elements(lamb)-1]), wmax)

	if n_elements( atmos_trans_[wmin:wmax]) ne n_elements(lamb) then message, "Mismatch in number of elements between atmosphere transmission and wavelength index arrays"
	return, atmos_trans_[wmin:wmax]

endif else begin
	message, /info, "Interpolating transmission onto desired wavelength scale"
	for i=0L, n_elements(lamb)-1 do begin $
		if i lt n_elements(lamb)-1 then lambstep = lamb[i+1]- lamb[i] else lambstep = lamb[i]- lamb[i-1] &$
		wlow  = min(where(atmos_wavelen gt (lamb[i] - lambstep/2) ) ) &$
		whigh = min(where(atmos_wavelen gt (lamb[i] + lambstep/2) ) ) &$
		; compute the mean integrated transmission over that range &$
		;; watch out for the case where both high and low are in the same
		;; wavelength bin (which occurs if the input companion spectrum is
		;; sufficiently high res)
		if whigh eq wlow then  $
		output_trans[i] = atmos_trans_[wlow] else $
		output_trans[i] = int_tabulated(atmos_wavelen[wlow:whigh], atmos_trans_[wlow:whigh],/double) $
			/ int_tabulated(atmos_wavelen[wlow:whigh], fltarr(whigh-wlow+1)+1.0,/double) &$
	endfor

	
;		window, 0
;		plot, atmos_wavelen, atmos_trans_, xrange = lamb[[0,n_elements(lamb-1) ]], xtitle="Wavelength", ytitle="Atmospheric transmission"
;		oplot, lamb, output_trans, psym=10,color=fsc_color('red')

;	stop

	return, {output_trans:output_trans,atmos_wavelen:atmos_wavelen,atmos_trans_:atmos_trans_} ;output_trans
endelse




end
