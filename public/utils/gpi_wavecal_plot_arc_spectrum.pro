;+
; NAME: gpi_wavecal_plot_arc_spectrum 
;
;	Utility function to display GCAL arc lamp theoretical spectra at high res.
;
; INPUTS:	element		either "Xe" or "Ar"
; KEYWORDS:
; OUTPUTS:	makes a plot
;
; HISTORY:
;	Began 013-11-29 23:12:53 by Marshall Perrin 
;-


PRO gpi_wavecal_plot_arc_spectrum, element, scale=scale, xrange=xrange, plotfilters=plotfilters, $
	color=color, _extra=_extra

	if ~(keyword_set(element)) then element='Xe'
	if ~(keyword_set(xrange)) then xrange=[0.9,2.5]
	if ~(keyword_set(scale)) then scale=1.0
	if ~(keyword_set(color)) then color=cgcolor('yellow')
	if n_elements(plotfilters) eq 0 then plotfilters=1

	if element ne "Xe" and element ne 'Ar' then message,'Only valid elements are Xe and Ar for arc lamp spectra'

	bands = ['Y','J','H','K1','K2']


	;;;; Read in Schuyler's lamp spectrum files
	; because IDL <8 cannot tolerate null arrays:
	wavelengths = [0]
	fluxes = [0]
	for i=0,4 do begin
		datafn = gpi_get_directory('DRP_CONFIG')+path_sep()+bands[i]+element+".dat"
		if ~file_test(datafn) then continue
		readcol, datafn,wla,fluxa,skipline=1,format='F,F'

		wavelengths = [wavelengths, wla]
		fluxes = [fluxes, fluxa]
	endfor
	; drop initial zero elements
	fluxes = fluxes[1:*]
	wavelengths = wavelengths[1:*]


	;;;; Read in the updated DST lamp spectrum files 
	readcol, gpi_get_directory('DRP_CONFIG')+path_sep()+"GCAL_"+element+"ArcLamp.txt",format='F,F', wavelengths2, fluxes2

	fluxes /= max(fluxes)
	fluxes2 /= max(fluxes2)


	if keyword_set( plotfilters) then !p.multi = [0,1,2]

	plot, wavelengths, fluxes, psym=1, xrange=xrange, yrange=[0,1.0]/float(scale), /xs,/ys, _extra=_extra,$
		title=element + ' spectrum', ytitle='Flux [arbitrary units]',/nodata
	;for i=0,n_elements(wavelengths)-1 do oplot, [wavelengths[i], wavelengths[i]], [0, fluxes[i]]

	for i=0,n_elements(wavelengths2)-1 do oplot, [wavelengths2[i], wavelengths2[i]], [0, fluxes2[i]],color=color

	if keyword_set( plotfilters) then begin
		colors=['magenta','blue','green','orange','red']
		plot, wavelengths, fluxes, psym=1, xrange=xrange, /xs, _extra=_extra,/nodata,$
			title='GPI IFS Filters', xtitle='Wavelength [microns]', ytitle='Filter Transmission'
		for i=0,4 do begin
			filter = mrdfits(gpi_get_directory('DRP_CONFIG')+path_sep()+"filters/GPI-filter-"+bands[i]+".fits",1)
			oplot, filter.wavelength, filter.transmission, color=cgcolor(colors[i])

		endfor
	endif



end
