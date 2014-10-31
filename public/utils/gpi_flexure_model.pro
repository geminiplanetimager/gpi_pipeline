;+
; NAME: gpi_flexure_model 
;
; INPUTS:
; 	flexuretable	Table of IFS flexure versus elevation
; 	elevation		elevation of the **GPI entrance optical axis**. This
; 					is equal to the telescope elevation if GPI is on the 
; 					bottom port, but will be different if it's on the side
; 					port. 
; KEYWORDS:
; 	wavecal_elevation	Elevation of the reference wavelength calibration. 
; 						See above note for elevation. 
; 	display			IDL window number to display a plot into. Leave blank or
; 					set to -1 for no plot. 
;
; OUTPUTS:
; 	Returns a 2-element array giving [shiftx, shifty] which are the
; 	predicted shift of the science data relative to the wavecal
; 	
;
; HISTORY:
; 	Began 2014-01-29 by MP, based on code by JM in
; 	gpi_update_spot_shifts_for_flexure.pro
;-


function gpi_flexure_model, flexuretable, elevation, wavecal_elevation=wavecal_elevation, $
	display=display

	if ~(keyword_set(wavecal_elevation)) then wavecal_elevation = 90.
	if ~(keyword_set(display)) then display=1

	lookuptable = flexuretable ; for back compatibility


	elevtable=lookuptable[*,0]
	xtable=lookuptable[*,1]
	ytable=lookuptable[*,2]

	elevsortedind=sort(elevtable)
	sortedelev=elevtable[elevsortedind]
	sortedxshift=xtable[elevsortedind]
	sortedyshift=ytable[elevsortedind]
			  
	;;polynomial fit
	shiftpolyx = POLY_FIT( sortedelev, sortedxshift, 2)
	shiftpolyy = POLY_FIT( sortedelev, sortedyshift, 2)

	; evaluate quality of polynomial fit
	fitx = POLY( sortedelev, shiftpolyx)
	fity = POLY( sortedelev, shiftpolyy)
	mean_poly_fit_error = mean(sqrt((sortedxshift-fitx)^2 + (sortedyshift-fity)^2))
	if keyword_set(verbose) then message,/info, "Mean residual from polynomial fit to flexure table: "+sigfig(mean_poly_fit_error,3)+" pixels."


	; Calculate expected position of the current image
	my_shiftx=shiftpolyx[0] + shiftpolyx[1]*elevation + (elevation^2)*shiftpolyx[2]
	my_shifty=shiftpolyy[0] + shiftpolyy[1]*elevation + (elevation^2)*shiftpolyy[2]

	; Calculate expected position of the reference wavelength calibration
    wcshiftx=shiftpolyx[0] + shiftpolyx[1]*wavecal_elevation + (wavecal_elevation^2)*shiftpolyx[2]
    wcshifty=shiftpolyy[0] + shiftpolyy[1]*wavecal_elevation + (wavecal_elevation^2)*shiftpolyy[2]
    
    ;;now calculate the shift of the current image relative to the reference wavecal
    shiftx= my_shiftx - wcshiftx 
    shifty= my_shifty - wcshifty

	if display ne -1 then begin
		if display eq 0 then window,/free else select_window, display
		!p.multi=[0,2,1]
		charsize = 1.2
		elevs = findgen(90)
		plot, sortedelev, sortedxshift, xtitle='Elevation [deg]', ytitle='X shift from Flexure [pixel]', xrange=[-10,100], yrange=[-0.9, 0.1], psym=1, charsize=charsize
		oplot, elevs, poly(elevs, shiftpolyx), /line
		oplot, [wavecal_elevation+1, wavecal_elevation+1], [wcshiftx, my_shiftx], psym=-2, color=fsc_color('yellow'), symsize=2
		oplot, [elevation,elevation],[-1,1], color=fsc_color("blue"), linestyle=2
		oplot, [wavecal_elevation,wavecal_elevation],[-1,1], color=fsc_color("red"), linestyle=2
		xyouts, wavecal_elevation+5, my_shiftx+0.05, 'DX = '+sigfig(shiftx, 3), color=cgColor('yellow')

		plot, sortedelev, sortedyshift, xtitle='Elevation [deg]', ytitle='Y shift from Flexure [pixel]', xrange=[-10,100], yrange=[-0.9, 0.1], psym=1, charsize=charsize
		oplot, elevs, poly(elevs, shiftpolyy), /line
		oplot, [wavecal_elevation+1, wavecal_elevation+1], [wcshifty, my_shifty], psym=-2, color=fsc_color('yellow'), symsize=2
		oplot, [elevation,elevation],[-0.6,1], color=fsc_color("blue"), linestyle=2
  		oplot, [wavecal_elevation,wavecal_elevation],[-0.6,1], color=fsc_color("red"), linestyle=2
		xyouts, wavecal_elevation+5, my_shifty+0.05, 'DY = '+sigfig(shifty, 3), color=cgColor('yellow')

		legend,/bottom,/right, ['Shifts in lookup table','Model','Applied shift','Data Elevation','Wavecal Elevation'], $
			color=[!p.color, !p.color, fsc_color('yellow'), fsc_color('blue'), fsc_color('red')], line=[0,1,1,2,2], psym=[1,0,2,0,0], charsize=charsize
		if obj_valid(backbone) then xyouts, 0.5, 0.96, /normal, "Flexure Shift Model for "+backbone->get_keyword('DATAFILE'), charsize=1.8, alignment=0.5
		!p.multi = 0



		;plot, sortedxshift, sortedyshift, xtitle='X shift [pixel]', ytitle='Y shift [pixel]';;
	endif

	return, [shiftx, shifty]


end
