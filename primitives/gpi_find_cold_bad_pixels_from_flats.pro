;+
; NAME: gpi_find_cold_bad_pixels_from_flats
; PIPELINE PRIMITIVE DESCRIPTION: Find Cold Bad Pixels from Flats
;
; This primitive finds cold (nonresponsive) pixels from the combination
; of flat fields at multiple wavelengths. This trickier than one might think,
; because it's not possible to illuminate the detector with an actual flat
; field. The best you can do is a flat through the lenslet array but that's
; still not very flat overall, with 37,000 spectra all over the place...
;
; Instead, we can use a clever hack: let's add up flat fields at various
; different wavelengths, and in the end we should get something that's actually 
; at least got some light into all the pixels. But there's a huge ripple pattern
; everwhere. 
;
; We then rely on the symmetry of the lenslet array to compare a given pixel to
; one that should have pretty similar flux levels, and we use that to find the
; cold pixels. 
;
;
; KEYWORDS:
; DRP KEYWORDS: FILETYPE,ISCALIB
; OUTPUTS:
;
; PIPELINE COMMENT: Find cold pixels from a stack of flat images using all different filters
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.01
; PIPELINE NEWTYPE: Calibration

;
; HISTORY:
;  2013-03-08 MP: Implemented in pipeline based on algorithm from Christian
;  2013-12-03 MP: Add check for GCALLAMP=QH on input images 
;-

function shift_nowrap, image, dx, dy, value=value
; utility function to shift and mask out
 if ~(keyword_set(value)) then value=!values.f_nan

	sz = size(image)
	output = shift(image, dx, dy)
	if dx gt 0 then output[0:dx-1,*] = value
	if dy gt 0 then output[*, 0:dy-1] = value
	if dx lt 0 then output[sz[1]+dx:sz[1]-1, *] = value
	if dy lt 0 then output[*, sz[2]+dy:sz[2]-1] = value
	return, output
end



function gpi_find_cold_bad_pixels_from_flats, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
functionname='coldpixels_from_flat' ; brevity is the soul of wit...

	nfiles=dataset.validframecount

    if nfiles lt 5 then return, error('FAILURE ('+functionName+'): Too few files supplied. Must have >=5 files but only got '+strc(nfiles))

	; Load the first file so we can figure out their size, etc. 

	im0 = accumulate_getimage(dataset, 0, hdr,hdrext=hdrext)
	sz = [0, backbone->get_keyword('NAXIS1',ext_num=1), backbone->get_keyword('NAXIS2',ext_num=1)]
	imtab = dblarr(sz[1], sz[2], nfiles)

	filters = strarr(nfiles)
	lamps= strarr(nfiles)

	backbone->Log, "	Reading in n="+strc(nfiles)+' files'

	; read in all the images at once
	for i=0,nfiles-1 do begin
		imtab[*,*,i] =  accumulate_getimage(dataset,i,hdr, hdrext=hdrext) 
		filters[i] = sxpar(hdr, 'IFSFILT') 
		lamps[i] = sxpar(hdr, 'GCALLAMP') 

		if strc(lamps[i]) ne "QH" then return,  error('FAILURE ('+functionName+'): Expected quartz halogen flat lamp images as input, but GCALLAMP != QH.')
	endfor

	for i=0,nfiles-1 do filters[i] = gpi_simplify_keyword_value(filters[i])

	; now combine them.
	backbone->set_keyword, 'HISTORY', functionname+":   Combining n="+strc(nfiles)+' files using method=sum',ext_num=0
	backbone->Log, "	Combining n="+strc(nfiles)+' files using method=sum'
	backbone->set_keyword, 'DRPNFILE', nfiles, "# of files combined to produce this output file"


	; verify we have at least one flat each from Y, J, H, K1, K2
	; compute a median-normalized sum of all the images in each filter
	combinations = dblarr(sz[1], sz[2], 5)
	filter_names = ['Y', "J", 'H', "K1", "K2"]
	for i=0,4L do begin
		wm = where(filters eq filter_names[i], mct)
		if mct eq 0 then begin
			return, error('FAILURE ('+functionName+'): Too few files supplied. We need at least one flat for every filter, and could not find one for '+filter_names[i])
		endif
		backbone->Log, "Found "+strc(mct)+" flat files for filter="+filter_names[i], depth=3
		if mct eq 1 then begin
			combinations[*,*,i] = imtab[*,*, wm]
		endif else begin
			combinations[*,*,i] = total( imtab[*,*, wm],3) / mct
		endelse
		combinations[*,*,i] /= median(combinations[*,*,i])

	endfor
	



	allfilts = total(combinations,3)



	; mask out ref pix
	allfilts[0:3,*] = !values.f_nan
	allfilts[*,0:3] = !values.f_nan
	allfilts[2043:2047,*] = !values.f_nan
	allfilts[*,2043:2047] = !values.f_nan


	; make shifted arrays by (9, 19) pixels, which is very close to the basic
	; periodic repetition step spacing
	shifted = fltarr(sz[1], sz[2], 4)
	shift_factors = [2,1,-1,-2]
	for i=0,3L do shifted[*,*,i] = shift_nowrap(allfilts,9*shift_factors[i], 19*shift_factors[i])

	refpattern = median(shifted, dim=3)

	;wbad = where(imf3 le 0.15, countbad)



	maskcoldpix = (allfilts/refpattern) le 0.15 

	
	; mask out ref pix
	maskcoldpix[0:3,*] = 0
	maskcoldpix[*,0:3] = 0
	maskcoldpix[2043:2047,*] = 0
	maskcoldpix[*,2043:2047] = 0


	atv, [[[allfilts]],[[refpattern]],[[allfilts/refpattern]],[[maskcoldpix]]],/bl
	;stop


    ;backbone->Log, 'Estimated read noise='+sigfig(rdnoise,4)+'cts  from stddev across '+strc(nfiles)+' darks.', depth=3
	;backbone->set_keyword, 'HISTORY', functionname+":   Estimating read noise comparing all files: ",ext_num=0
	;backbone->set_keyword, 'HISTORY', functionname+":      rdnoise = stddev(dark_i-combined_dark) = "+sigfig(rdnoise,4),ext_num=0
	;backbone->set_keyword, 'EST_RDNS', rdnoise, 'Estimated read noise from stddev across '+strc(nfiles)+' darks [counts]' ,ext_num=0

    ncoldpix = total(maskcoldpix)
    backbone->set_keyword, 'DRPNCDPX', ncoldpix, "Number of 'cold' pixels, <15% nominal in flat "
    

	;----- store the output into the backbone datastruct
	*(dataset.currframe)=maskcoldpix
    suffix='-coldpix'

    backbone->set_keyword, "FILETYPE", "Cold Bad Pixel Map", "What kind of IFS file is this?"
    backbone->set_keyword,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.' 



@__end_primitive
end

