;+
; NAME:  gpi_sanity_check_wavecal
;	Utility function to do some basic quality tests on a wavecal.
;
;	Passing these checks is probably a necessary but far from
;	sufficient condition for a wavecal to be of good quality.
;
;	Currently implemented checks include:
;		- basic file dimensionality
;		- comparison of X- and Y-shifts between adjacent lenslets
;		  to check for entire rows that "jump" out of position, which
;		  is a common problem for the original barycenter wavecal algorithm
;
; INPUTS: 
;	filename  name of a wavecal file
;	
; KEYWORDS:
;	/silent		don't print any info to the screen
;	/noplots	don't make any diagnostic plots
; OUTPUTS: 
;	1 if sanity checks pass OK, 0 if failed
;
; HISTORY:
;	Began 013-10-02 21:43:05 by Marshall Perrin 
;-


function gpi_sanity_check_wavecal, filename, silent=silent, $
	noplots=noplots

	if ~file_test(filename) then begin
		if ~(keyword_set(silent)) then message,/info, 'File '+filename+" does not exist."
		return, 0
	endif
	prihdr = headfits(filename,ext=0,/silent)
 	data = readfits(filename, ext=1, exthdr,/silent)


	sz = size(data)
	if sz[0] ne 3 then begin
		if ~(keyword_set(silent)) then message,/info, filename+" is invalid. Not a 3D datacube."
		return, 0
	endif

	loadct,0,/silent
	; Check histogram of X delta values

	xdiff = data[*,*,0] - shift(data[*,*,0],1)
	ydiff = data[*,*,1] - shift(data[*,*,1],1)
	wg = where(finite(xdiff) and finite(ydiff))
	pct_wide_x = total( abs(xdiff[wg]-mean(xdiff[wg]) ) gt 2 ) / n_elements(wg)
	pct_wide_y = total( abs(ydiff[wg]-mean(ydiff[wg]) ) gt 2 ) / n_elements(wg)

	if ~(keyword_set(noplots)) then begin
		!p.multi=[0,1,2]
		plothist, xdiff[wg],bin=0.01,/ylog,title='Adjacent lenslet X diffs',$
			xtitle=sigfig(pct_wide_x*100,3)+"% outside mean +-2"
		ver, mean(xdiff[wg]),/line



		plothist, ydiff[wg],bin=0.01,/ylog,title='Adjacent lenslet Y diffs',$
			xtitle=sigfig(pct_wide_y*100,3)+"% outside mean +-2"
		ver, mean(ydiff[wg]),/line
	endif

	if pct_wide_x*100 gt 0.1 and pct_wide_y*100 gt 0.1 then begin
		if ~(keyword_set(silent)) then message,/info, filename+" looks invalid. Too many X and Y offsets between adjacent lenslets are outside expected values."
		return, 0
	endif

	;stop

	if ~(keyword_set(silent)) then message,/info, filename+" passes basic check." 

	return, 1


end
