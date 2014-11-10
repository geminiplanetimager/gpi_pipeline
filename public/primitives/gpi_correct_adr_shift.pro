;+
; NAME: gpi_correct_adr_shift.pro
; PIPELINE PRIMITIVE DESCRIPTION: Correct for Atmospheric Differential Refraction
;
;  	Uses the location of the satellite spots to calculate a center at each
;	wavelength, fits the x and y drift as a function of wavelenght to a straight
;	line and compensates for it.
;
;
; INPUTS: Spectral Cube
; OUTPUTS: Interpolated Spectral Cube that is shifted for ADR compensation
;
; PIPELINE COMMENT: Interpolates the cube to undo any shifts due to ADR (or leftover ADC).
; PIPELINE ARGUMENT: Name="refslice" Type="int" Range="[0,36]" Default="20" Desc="reference slice to perform relative shifts"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
; PIPELINE ORDER: 2.45
; PIPELINE CATEGORY: Calibration, SpectralScience
;
; HISTORY:
; 	2014-01-31 JW: Created. Accurary is subpixel - hopefully.
;- 

function gpi_correct_adr_shift, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id: gpi_measure_star_position_for_polarimetry.pro 2834 2014-04-25 00:12:51Z Max $' ; get version from subversion to store in header history

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

; the following line sources a block of code common to all primitives
; It loads some common blocks, records the primitive version in the header for
; history, then if calfiletype is not blank it queries the calibration database
; for that file, and does error checking on the returned filename.
@__start_primitive
;suffix='' 		 ; set this to the desired output filename suffix
				 ; This primitive should not change the existing suffix, it
				 ; just updates the headers slightly.


cube = *dataset.currframe
refslice = fix(Modules[thisModuleIndex].refslice)

if ~keyword_set(refslice) then refslice = 20

dims = size(cube, /dim)

;; get centers from headers
numslices = dims[2]
;array to store data
slices = findgen(numslices) - refslice
centerx = findgen(numslices)
centery = findgen(numslices)

;; loop over 37 wavelengths
FOR frame=0, numslices-1 DO BEGIN
	;calcualte the central star position for this slice from the mean of the satellite spots
	psfcentx = fltarr(4)
	psfcenty = fltarr(4)
	for spot=0,3 do begin
		hdrval = backbone->get_keyword('SATS'+strtrim(frame,2)+'_'+strtrim(spot,2), count=ct)
		hdrval = strsplit(hdrval, ' ', /extract)
		;IF (typename(hdrval) eq 'LONG') THEN CONTINUE
		spotx = double(hdrval[0])
		spoty = double(hdrval[1])
		psfcentx[spot] = spotx
		psfcenty[spot] = spoty
	endfor
	
	centerx[frame] = mean(psfcentx)
	centery[frame] = mean(psfcenty)
	
	;locs = find_sat_spots(cube[*,*,frame], leg=leg, highpass=1)
	;centerx[frame] = mean(locs[0,*])
	;centery[frame] = mean(locs[1,*])
ENDFOR
	
;fit a line because I'm lazy to calculate ADR (or residual ADC)
fitx = linfit(slices[3:numslices-1-3], centerx[3:numslices-1-3] - centerx[refslice])
fity = linfit(slices[3:numslices-1-3], centery[3:numslices-1-3] - centery[refslice]) 

;make some array coordinates
xs = indgen(dims[0])
ys = indgen(dims[1])

FOR frame = 0, numslices-1 DO BEGIN
	shiftx = fitx[0] + fitx[1]*(frame-refslice)
	shifty = fity[0] + fity[1]*(frame-refslice)
	print, shiftx, shifty
	shifted_slice = interpolate(cube[*,*,frame], xs + shiftx, ys + shifty, cubic=-0.5, /grid)
	cube[*,*,frame] = shifted_slice
	for j = 0,3 do begin
		hdrval = backbone->get_keyword('SATS'+strtrim(frame,2)+'_'+strtrim(j,2), count=ct)
		hdrval = strsplit(hdrval, ' ', /extract)
		spotx = double(hdrval[0])
		spoty = double(hdrval[1])
		
		backbone->set_keyword,'SATS'+strtrim(frame,2)+'_'+strtrim(j,2),$
		string(strtrim([spotx-shiftx, spoty-shifty],2),format='(F7.3," ",F7.3)'),$
		'Location of sat. spot '+strtrim(j,2)+' of slice '+strtrim(frame,2),$
		ext_num=1
	endfor
ENDFOR

; update FITS header history
;backbone->set_keyword,'HISTORY', functionname+": corrected for any ADC effects", ext_num=0

*dataset.currframe = cube

@__end_primitive

stop
end
