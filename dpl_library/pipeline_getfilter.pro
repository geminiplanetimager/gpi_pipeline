;+
; NAME:  dst_applyfilter
;
; 	Apply a filter transmission profile to a datacube.
;
; INPUTS: 	
; 	Files from the detector_data subdirectory with the transmission curves
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2009-04-01 17:09:30 by Marshall Perrin 
;-

function pipeline_getfilter,   lambda, filter=filtername

	;common DST_input
	if ~(keyword_set(filtername)) then filtername="H"

	filter_file = '.'+path_sep()+'pipeline'+path_sep()+"dpl_library"+path_sep()+'filters'+path_sep()+"GPI-filter-"+strc(filtername)+".fits"


	if ~file_test(filter_file) then message, "Could not find filter file! error:"+filter_file
	filtstruct = mrdfits(filter_file,1)


	
	; the global wavelength solution is in "lambda"

	wavelen_deltas = [(shift(lambda,-1) - lambda)]

	nl = n_elements(lambda)
	wavelen_midpoints = [lambda[0] - 0.5*wavelen_deltas[0], (lambda + wavelen_deltas/2)[0:nl-2], lambda[nl-1]+wavelen_deltas[nl-2]*0.5 ]


	net_transmission = fltarr(n_elements(lambda))
	for i=0L, n_elements(net_transmission)-1 do begin
		wm = where(filtstruct.wavelength gt wavelen_midpoints[i] and filtstruct.wavelength lt wavelen_midpoints[i+1], ct)
		;print, ct
		if ct eq 0 then begin
			message, "no transmission data in filter for that wavelength?" 
		endif
		net_transmission[i] = mean(filtstruct.transmission[wm])
	endfor 

	;print, "Filter transmission profile"

	if 1 eq 0 then begin 
	window,22
		plot, filtstruct.wavelength, filtstruct.transmission, $
			xtitle="Wavelength [micron]", ytitle="Transmission fraction", title="Filter Transmission for "+filtername
		oplot,  lambda, net_transmission, color=fsc_color('red'), psym=10
	endif


	return, net_Transmission
		

end
