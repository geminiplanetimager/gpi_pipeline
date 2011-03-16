
;------------------------------------------

function pol_combine_for_test, measurements, wpangle, port=port, retardance=retardance
	; This is the guts of the pol_combine routine, pulled out of the DRP and
	; reworked to expect only a single spatial element's worth of data. 

	if ~(keyword_set(port)) then port='side'
	if ~(keyword_set(retardance)) then retardance=0.5

	nfiles= n_elements(wpangle)
	if nfiles lt 4 then return, error('FAILURE ('+functionName+'): At least 4 input polarizations files are required.')


	; Load all files at once. 
	M = fltarr(4, nfiles*2)			; this will be the measurement matrix of coefficients for the Stokes parameters.
	Msumdiff = fltarr(4, nfiles*2)	; a similar measurement matrix, for the sum and single-difference images. 

	;polstack = reform(measurements, n_elements(measurements))  ; make it a 1D array
	polstack = fltarr(n_elements(measurements))


	; right now this routine carries out two parallel sets of computations:
	;  one acting on the observed images, and
	;  one acting on the pairs of sums and difference images. 
	;
	; It's TBD whether this makes any difference or not.


	sumdiffstack = polstack			; a transformed version of polstack, holding the sum and single-difference images
	stokes = fltarr(4); the output Stokes cube!
	stokes2 = stokes

	system_mueller = DST_instr_pol(/mueller, port=port)
  	woll_mueller_vert = mueller_linpol_rot(0) ; swapped by MP on 3:11 2012-12-8
	woll_mueller_horiz= mueller_linpol_rot(90)

	for i=0L,nfiles-1 do begin
		
		wp_mueller = DST_waveplate(angle=wpangle[i], /mueller, retardance=retardance)

		total_mueller_vert = woll_mueller_vert ## wp_mueller ## system_mueller ;## skyrotation_mueller
		total_mueller_horiz = woll_mueller_horiz ## wp_mueller ## system_mueller ;## skyrotation_mueller

		M[*,2*i] = total_mueller_vert[*,0]
		M[*,2*i+1] = total_mueller_horiz[*,0]

		polstack[i*2] = measurements[i,0]
		polstack[i*2+1] = measurements[i,1]
		sumdiffstack[i*2] = polstack[i*2] + polstack[i*2+1]
		sumdiffstack[i*2+1] = polstack[i*2] - polstack[i*2+1]
		Msumdiff[*,2*i] = M[*,2*i]+M[*,2*i+1]
		Msumdiff[*,2*i+1] = M[*,2*i]-M[*,2*i+1]

	endfor 
	
	stack0 =polstack

	svdc, M, w, u, v
	svdc, Msumdiff, wsd, usd, vsd

	; check for singular values and set to zero if they are close to machine
	; precision limit
	print, "    W:  "+aprint(W)
	print, '    WSD:'+aprint(WSD)

	wsingular = where(w lt (machar()).eps*5, nsing)
	if nsing gt 0 then begin
		w[wsingular]=0
		print, "Setting "+strc(nsing)+" singular values to 0 in W vector"
	endif
	wsingular = where(wsd lt (machar()).eps*5, nsing)
	if nsing gt 0 then wsd[wsingular]=0

	; at this point we should have properly computed the system response matrix M.
	; We can now iterate over each position in the FOV and compute the derived
	; Stokes vector at that position.

			; apply the overall solution for pixels which are valid in all
			; frames
			stokes[*] = svsol( u, w, v, reform(polstack[*]))
			stokes2[*] = svsol( usd, wsd, vsd, reform(sumdiffstack[*]))


	print, "Measured Stokes v1 (meas):    "+aprint(stokes)
	print, "Measured Stokes v2 (sumdiff): "+aprint(stokes2)
	;stop

	return, stokes

	; should we do the fit to the two polarized images, or to the sum and diff
	; images?
	; there does not appear to be much difference between the two methods, 
	; which seems logical given that they are a linear combination...
	
end



pro  pol_combine_test, polstate=polstate, port=port, n=n, wpstep=wpstep, retardance=retardance


	;if ~(keyword_set(port)) then port='perfect'
	if ~(keyword_set(port)) then port='side'
	if ~(keyword_set(polstate)) then polstate = [1, 1., 0.0, 0.0]
	if ~(keyword_set(retardance)) then retardance=0.5



	if ~(keyword_set(n)) then n = 4
	if ~(keyword_set(wpstep)) then wpstep = 22.5
	wpangles = findgen(n)*wpstep

	meas = fltarr(n,2)


	M_instrpol = DST_instr_pol(port=port, /mueller)
	M_vert = mueller_linpol_rot(0)
	M_horiz= mueller_linpol_rot(90)


	print, "Input State:      "+ aprint(polstate)
	print, "Port:             "+port
	print, "Waveplate:        "+strc(n)+" steps of "+strc(wpstep)+" deg."
	print, ""

	polstate = reform(polstate, 1,4)
	print, "    Creating input 'measurements':"
	for i=0L,n-1 do begin
		M_wp = dst_waveplate(0, angle=wpangles[i], /mueller, retardance=retardance)
		meas[i,0] = (M_vert  ## M_wp ## M_instrpol ## polstate)[0]
		meas[i,1] = (M_horiz ## M_wp ## M_instrpol ## polstate)[0]
		print, "    Angle="+strc(wpangles[i])+"     meas = "+aprint( reform(meas[i,*]))
		;print, (M_vert  ## M_wp ## M_instrpol)[*,0]
		;print, (M_horiz  ## M_wp ## M_instrpol)[*,0]
	endfor 


	print, "    Running 'pol_combine':"
	ans = pol_combine_for_test( meas, wpangles, port=port, retardance=retardance)


	print, ""
	print, "Input State:       "+ aprint(reform(polstate))
	print, "Output State:      "+ aprint(ans)


	diff = abs(reform(polstate) - ans)
	print, "Equal w/in FP acc.? "+ aprint(diff lt (machar()).eps*5)
	stop


end


