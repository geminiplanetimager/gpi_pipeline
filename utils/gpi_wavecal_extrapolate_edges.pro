;+
; NAME: gpi_wavecal_extrapolate_edges
;
;	Extrapolate approximate solutions for spectra *partially* on the detector,
;	based on the adjacent spectra that are partially on the detector. 
;
;	These solutions aren't going to be perfect, but they will at least give you
;	the ability to extrapolate something rough for those pixels.
;
; INPUTS:
;	wavecal		A GPI spectral wavelength calibration array
; KEYWORDS:
; OUTPUTS:
;	extrapolated	A version of that wavelength calibration, extrapolated out
;					an additional 2 lenslets on all sides. 
;
; HISTORY:
;	Began 013-03-12 15:53:49 by Marshall Perrin 
;-

function gpi_wavecal_extrapolate_edges, wavecal


	mask = finite( wavecal[*,*,0])

	kernel = [[0,1,0],[1,1,1],[0,1,0]]

	mask2 = dilate(dilate(mask, kernel), kernel)


	dwavecaldx = wavecal - shift(wavecal,1,0,0)
	dwavecaldy = wavecal - shift(wavecal,0,1,0)

	sm_dwavecaldx = dwavecaldx
	sm_dwavecaldy = dwavecaldy
	for i=0,4 do sm_dwavecaldx[*,*,i] = smooth(median(dwavecaldx[*,*,i],5),7,/nan)
	for i=0,4 do sm_dwavecaldy[*,*,i] = smooth(median(dwavecaldy[*,*,i],5),7,/nan)

	; extrapolate 1 pixel in X

	;mask3 = mask2-mask
	;mask3[where(mask3 eq 0)] = !values.f_nan

	mask3 = fltarr(281,281)+1.0
	mask3[where(mask)] = !values.f_nan

	sz = size(wavecal)

	; Try extrapolating 2 pixels in all of the +-X and +-Y directions
	extrapolations = fltarr(sz[1],sz[2],sz[3],4)
	extrapolations[0,0,0,0] =  shift(wavecal,-2, 0,0) - 2*sm_dwavecaldx
	extrapolations[0,0,0,1] =  shift(wavecal, 2, 0,0) + 2*sm_dwavecaldx
	extrapolations[0,0,0,2] =  shift(wavecal, 0,-2,0) - 2*sm_dwavecaldy
	extrapolations[0,0,0,3] =  shift(wavecal, 0, 2,0) + 2*sm_dwavecaldy

	; mask out and only keep the extrapolations pixels, not anything that was good
	; originally
	for i=0,3 do for j=0,4 do extrapolations[*,*,j,i] *= mask3

	med_extrap = median(extrapolations, dim=4,/even) 


	extrapolated = wavecal
	wf = where(finite(med_extrap))
	extrapolated[wf] = med_extrap[wf]


	return, extrapolated

end
