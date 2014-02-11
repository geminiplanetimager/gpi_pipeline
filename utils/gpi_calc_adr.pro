;+
; NAME: gpi_calc_adr 
;
;    Calculate post facto the atmospheric differential
;    refraction for a given GPI image. For more general
;    calculations see gpi_plot_adr.
;
; INPUTS:   filename	FITS filename of a GPI image
; KEYWORDS:
; 	display			IDL window number to display a plot into. Leave blank or
; 					set to -1 for no plot. 
;
; OUTPUTS:
;
; HISTORY:
;	Began 014-01-30 13:14:10 by Marshall Perrin 
;-


function gpi_calc_adr, filename, verbose=verbose,display=display


	if ~(keyword_set(display)) then display=-1

	data = gpi_load_fits(filename)

	filt = gpi_simplify_keyword_value(gpi_get_keyword(*data.pri_header, *data.ext_header, 'IFSFILT'))
	filt_info = get_cwv(filt)
	wl_min = min(filt_info.lambda)
	wl_max = max(filt_info.lambda)
	wl_mid = (wl_min + wl_max) / 2.0
	wl_AOWFS = 0.8

	elevation = gpi_get_keyword(*data.pri_header, *data.ext_header, 'ELEVATIO')
	pressure= gpi_get_keyword(*data.pri_header, *data.ext_header, 'PRESSUR2') / 100  ; PRESSUR2 is in Pascals, so divide by 100 to get mBar
	temperature = gpi_get_keyword(*data.pri_header, *data.ext_header, 'TAMBIENT') + 273.15 ; TAMBIENT is in C so add to get K

	dateobs = gpi_get_keyword(*data.pri_header, *data.ext_header, 'DATE-OBS') 
	timeobs = gpi_get_keyword(*data.pri_header, *data.ext_header, 'UTSTART') 


	n_aowfs  = adr_n(wl_AOWFS, pr=pressure,T=temperature)
	n_min  =   adr_n(wl_min,   pr=pressure,T=temperature)
	n_mid  =   adr_n(wl_mid,   pr=pressure,T=temperature)
	n_max  =   adr_n(wl_max,   pr=pressure,T=temperature)

	; this formula is from Henry Roe's paper
	;		DR = 206265* ( (n_vis^2-1)/(2*n_vis^2) - (n_ir^2 -1)/(2*n_ir^2 ))*tan(z*!dtor)
	; this formula is from James' web page. (according to notes from 2003 - not
	; sure in 2014 what that meant... - MP)
	;		DR2 = 206265*(-(n_ir-1)*tan(z*!dtor) + (n_vis-1)*tan(z*!dtor))
	; These appear to agree to better than 0.1 mas at ZD=60 so there is
	; negligible difference between them.
	
	zd = 90.-elevation
	adr_ir_vis = 206265*(-(n_mid-1)*tan(zd*!dtor) + (n_aowfs-1)*tan(zd*!dtor))
	adr_ir_min_max = 206265*(-(n_max-1)*tan(zd*!dtor) + (n_min-1)*tan(zd*!dtor))

	ifs_scale = gpi_get_constant('ifs_lenslet_scale',/silent)
	adr_ir_min_max_pix = adr_ir_min_max / ifs_scale

	if keyword_set(verbose) then begin
		message,/info, "For file "+file_basename(filename)+" taken at "+dateobs+" "+timeobs+" UTC"
		message,/info, "  Pressure = "+sigfig(pressure,5)+" mBar, Temperature = "+sigfig(temperature,4)+" K"
		message,/info, "  Elevation = "+sigfig(elevation, 4)+" degrees"
		message,/info, "  ADR across "+strc(filt)+" band = "+sigfig(adr_ir_min_max, 3)+" arcsec = "+sigfig(adr_ir_min_max_pix,3)+" lenslets"
		message,/info, "  ADR from "+strc(filt)+" band to AOWFS = "+sigfig(adr_ir_vis, 3)+" arcsec"
	endif


	if display ne -1 then begin
		if display eq 0 then window,/free else select_window, display
	
		zdrange = findgen(60)
		adrange_ir_vis = 206265*(-(n_mid-1)*tan(zdrange*!dtor) + (n_aowfs-1)*tan(zdrange*!dtor))
		adrange_ir_min_max = 206265*(-(n_max-1)*tan(zdrange*!dtor) + (n_min-1)*tan(zdrange*!dtor))

		charsize = !p.charsize
		xm = !x.margin
		!x.margin=[8, 8]
		!p.charsize=1.5
		plot,zdrange, adrange_ir_vis, title="Atmospheric Differential Refraction",$
			ytitle="Delta zenith distance [arcsec]",xtitle="Zenith distance [degrees]",$
			ystyle=8
		AXIS, YAXIS=1, YRANGE=!y.crange/ifs_Scale, ytitle='IFS lenslets',/ystyle
		
		oplot,zdrange, adrange_ir_vis ,color=cgColor('red')
		xyouts,20,0.37,"ADR for "+sigfig(wl_aowfs,3)+"-"+sigfig(wl_mid,3)+' microns',color=cgColor('red')

		oplot,zdrange, adrange_ir_min_max ,color=cgColor('yellow')
		xyouts,20,0.08,"ADR for "+sigfig(wl_min,3)+"-"+sigfig(wl_max,3)+' microns',color=cgColor('yellow')
	

		spotradius = 0.246/2 * (wl_mid/1.6)
		oplot,[0,90],[spotradius,spotradius],lines=1
		xyouts,5,spotradius*1.05,"GPI "+filt+" Occulter radius"
	
		res = 206265*wl_mid*1e-6/7.7
		oplot,[0,90],[res,res],lines=2
		xyouts,5,res*1.1,"Diffraction Limit at "+filt+" band"

		oplot, [zd, zd], !y.crange,color=cgcolor('cyan')
		xyouts, zd-1, 0.05, file_basename(filename), orient=90, color=cgColor('cyan')
		wshow

		!x.margin=xm	; be a good neighbor and restore plot settings after this plot
		!p.charsize=charsize
	
	endif

	;stop
	return, adr_ir_min_max

end
