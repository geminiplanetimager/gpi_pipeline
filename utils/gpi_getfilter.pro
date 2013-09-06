;+
; NAME:  gpi_getfilter
;
; 	Return a filter transmission profile, looked up from
; 	files in the pipeline config subdirectory with the transmission curves
; INPUTS: 	
;	lambda		wavelength array
; KEYWORDS:
; 	filter		Name of filter
; 	/display	Make a plot to show the filter on screen
; OUTPUTS:
;
; HISTORY:
; 	Began 2009-04-01 17:09:30 by Marshall Perrin (as dst_applyfilter)
; 	sometime??  split off into pipeline_getfilter
; 	2012-01-30: Updated file paths, updated docs. -MP
; 	2013-07-17 MP: Rename to gpi_getfilter for consistency
;
;-

function gpi_getfilter,   lambda, filter=filtername, display=display

	if ~(keyword_set(filtername)) then filtername="H"

	filter_file =  gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'filters'+path_sep()+"GPI-filter-"+strc(filtername)+".fits"

	if ~file_test(filter_file) then message, "Could not find filter file! error:"+filter_file
	filtstruct = mrdfits(filter_file,1)


	
	; the global wavelength solution is in "lambda"

	wavelen_deltas = [(shift(lambda,-1) - lambda)]

	nl = n_elements(lambda)
	wavelen_midpoints = [lambda[0] - 0.5*wavelen_deltas[0], (lambda + wavelen_deltas/2)[0:nl-2], lambda[nl-1]+wavelen_deltas[nl-2]*0.5 ]


	net_transmission = fltarr(n_elements(lambda))
	for i=0L, n_elements(net_transmission)-1 do begin
		wm = where(filtstruct.wavelength gt wavelen_midpoints[i] and filtstruct.wavelength lt wavelen_midpoints[i+1], ct)
		if ct eq 0 then begin
			message, "no transmission data in filter for that wavelength?" 
		endif
		net_transmission[i] = mean(filtstruct.transmission[wm])
	endfor 

	if keyword_set(display) then begin 
		window,22
		plot, filtstruct.wavelength, filtstruct.transmission, $
			xtitle="Wavelength [micron]", ytitle="Transmission fraction", title="Filter Transmission for "+filtername
		oplot,  lambda, net_transmission, color=cgcolor('red'), psym=10
	endif


	return, net_Transmission
		

end
