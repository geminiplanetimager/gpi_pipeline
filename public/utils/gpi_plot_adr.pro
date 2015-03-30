;+
; NAME: gpi_plot_adr
;
; 	Plot atmospheric differential refraction as relevant to GPI. 
;
; 	This plots some general theoretical ADR curves as a function of
; 	elevation. See gpi_calc_adr for a calculation for a specific
; 	GPI observation.
;
; 	see paper by Henry Roe (PASP 114: 450-461, 2002 April)
;
; INPUTS:
; KEYWORDS:
;	pressure		atmos pressure in mbar
;	temperature		temperature in degrees C
; OUTPUTS:
;
; HISTORY:
; 	Began 2003-12-23 06:55:49 by Marshall Perrin 
; 	2013-11-13 modified for GPI. Ten years later!
;-

PRO gpi_plot_adr,l_vis=l_vis, pressure = pressure, temperature=temperature

	!p.charsize=2

	if not(keyword_set(l_vis)) then l_vis = 0.8d ; microns
	;l_vis = 1.0d
	l_ir = 1.6d

	if keyword_set(pressure) then p_pachon = pressure else $
		p_pachon	= 731	; millibars atmospheric pressure at Cerro Pachon, measured on first night
	if keyword_set(temperature) then t_pachon = temperature+273 else $
	T_pachon	= 282	; temp in K at Pachon at night, measured on first night

	n_vis  = adr_n(l_vis,pr=p_pachon,T=t_pachon)
	n_vis2 = adr_n(0.95d,pr=p_pachon,T=t_pachon)
	n_ir   = adr_n(l_ir,pr=p_pachon,T=t_pachon)
	n_ir15   = adr_n(1.5d,pr=p_pachon,T=t_pachon)
	n_ir16   = adr_n(1.6d,pr=p_pachon,T=t_pachon)
	n_ir17   = adr_n(1.7d,pr=p_pachon,T=t_pachon)
	n_ir18   = adr_n(1.8d,pr=p_pachon,T=t_pachon)

	z = findgen(100) /100*60 

	; this formula is from Henry Roe's paper
	DR = 206265* ($
		(n_vis^2-1)/(2*n_vis^2) - $
		(n_ir^2 -1)/(2*n_ir^2 )$
	    )*tan(z*!dtor)

	; this formula is from James' web page.
	DR2 = 206265*(-(n_ir-1)*tan(z*!dtor) + (n_vis-1)*tan(z*!dtor))
	
	DR3 = 206265*(n_vis2-n_ir)*tan(z*!dtor)


	DR4 = 206265*(-(n_ir18-1)*tan(z*!dtor) + (n_ir15-1)*tan(z*!dtor))
	DR5 = 206265*(-(n_ir17-1)*tan(z*!dtor) + (n_ir16-1)*tan(z*!dtor))

	!x.margin=[8, 8]

	plot,z,DR2,title="Atmospheric Differential Refraction",$
		ytitle="Delta zenith distance, vis-ir (arcsec)",xtitle="Zenith distance (degrees)",$
		ystyle=8
	

	;oplot,z,DR,color=getcolor('yellow')
	oplot,z,DR3,color=getcolor('red')
	oplot,z,DR4,color=getcolor('yellow')
	oplot,z,DR5,color=getcolor('cyan')

	;legend,/top,/left,['0.80-1.60 microns','0.95-1.60 microns'],colors=[!p.color,getcolor('red')],$
		;psym=[-3,-3]


	xyouts,43,0.39,'0.80-1.60 microns'
	xyouts,43,0.23,'0.95-1.60 microns',color=getcolor('red')
	xyouts,43,0.07,'1.50-1.80 microns',color=getcolor('yellow')
	xyouts,43,0.015,'1.60-1.70 microns',color=getcolor('cyan')

	spotradius = 0.246/2
	oplot,[0,90],[spotradius,spotradius],lines=1
	xyouts,5,spotradius*1.05,"GPI H Occulter radius"
	

	res = 206265*l_ir*1e-6/7.7
	oplot,[0,90],[res,res],lines=2
	xyouts,5,res*1.1,"Diffraction Limit at 1.6 microns"

	wl = where (DR3 lt res)
	ml = max(wl)
	;print,"Maximum zenith angle less with ADR < DL: ",z[ml]

	AXIS, YAXIS=1, YRANGE=!y.crange/0.0145, ytitle='IFS lenslets',/ystyle

end
