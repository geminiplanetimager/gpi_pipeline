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
;	Began 2013-03-12 15:53:49 by Marshall Perrin 
;	2013-04-05 MP: documentation update
;-

function gpi_wavecal_extrapolate_edges, wavecal

	mask = finite( wavecal[*,*,0])

	kernel = [[0,1,0],[1,1,1],[0,1,0]]

	; this is never used...
	;mask2 = dilate(dilate(mask, kernel), kernel)


	; Compute spatial derivatives of wavecal positions for x and y directions
	dwavecaldx = wavecal - shift(wavecal,1,0,0)
	dwavecaldy = wavecal - shift(wavecal,0,1,0)

	; Smooth them, first median smooth to discard outliers then more
	; smoothing to get nice even gradiants
	sm_dwavecaldx = dwavecaldx
	sm_dwavecaldy = dwavecaldy
; original - susceptible to edge effects as median will not filter the edges
;	for i=0,4 do sm_dwavecaldx[*,*,i] = smooth(median(dwavecaldx[*,*,i],5),7,/nan)
;	for i=0,4 do sm_dwavecaldy[*,*,i] = smooth(median(dwavecaldy[*,*,i],5),7,/nan)

	; new edge handling version
	for i=0,4 do sm_dwavecaldx[*,*,i] = filter_image(dwavecaldx[*,*,i],median=7,smooth=5,/all)*mask
	for i=0,4 do sm_dwavecaldy[*,*,i] = filter_image(dwavecaldy[*,*,i],median=7,smooth=5,/all)*mask

	mask3 = fltarr(281,281)+1.0
	mask3[where(mask)] = !values.f_nan

	sz = size(wavecal)

	; Try extrapolating 2 lenslets in all of the +-X and +-Y directions
	; This is simple linear extrapolation of lenslet positions based on 
	; the derivatives computed above. 
	;
	; This results in a 4D array where the 4th axis is the direction of
	; interpolation.
	extrapolations = fltarr(sz[1],sz[2],sz[3],4)
	extrapolations[0,0,0,0] =  shift(wavecal,-2, 0,0) - 2*sm_dwavecaldx
	extrapolations[0,0,0,1] =  shift(wavecal, 2, 0,0) + 2*sm_dwavecaldx
	extrapolations[0,0,0,2] =  shift(wavecal, 0,-2,0) - 2*sm_dwavecaldy
	extrapolations[0,0,0,3] =  shift(wavecal, 0, 2,0) + 2*sm_dwavecaldy

	; mask out and only keep the extrapolated lenslets, not anything that was good
	; originally
	for i=0,3 do for j=0,4 do extrapolations[*,*,j,i] *= mask3

	; Median across the 4th axis, ignoring the NaN pixels that make up most of
	; tha arrays, to produce a single wavecal that includes the
	; valid extrapolated pixels from all 4 extrapolation directions
	med_extrap = median(extrapolations, dim=4,/even) 


	; Create a copy of the original wavecal and 
	; fill in the appropriate lenslets with the extrapolation
	extrapolated = wavecal*1.0 ; copy
	wf = where(finite(med_extrap))
	extrapolated[wf] = med_extrap[wf]


	return, extrapolated

end
