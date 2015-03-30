;+
; NAME: gpi_clean_polarization_pairs_via_dd
; PIPELINE PRIMITIVE DESCRIPTION: Clean Polarization Pairs via Double Difference
; 
;	Given a sequence of polarization pair cubes, use a modified double
;	differencing approach to mitigate systematics between the e- and o- ray
;	channels of the cubes. 
;
;	This must be used after Accumulate Images. Unlike most such primitives, it
;	acts on the entire stack of cubes at once without combining them yet. 
;
;	This must be used prior to rotating the cubes if it is to have any hope at
;	all of working well. 
;
;	**Caution** Experimental/Under Development code - algorithms may still be in
;	flux. 
;
; INPUTS:  Multiple polarization pair datacubes
; OUTPUTS: Multiple polarization pair datacubes, hopefully with reduced
;		   systematics
;
;
; PIPELINE ARGUMENT: Name="fix_badpix" Type="int" Range="[0,1]" Default="1" Desc="Also locate statistical outlier bad pixels and repair via interpolation?"
; PIPELINE ARGUMENT: Name="Save_diffbias" Type="int" Range="[0,1]" Default="0" Desc="Save the difference image systematic bias estimate subtracted from each pair?"
; PIPELINE ARGUMENT: Name="gpitv_diffbias" Type="int" Range="[0,500]" Default="10" Desc="Display empirical systematic bias in difference frames in a GPITV session 1-500, or 0 for  no display "
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="debug" Type="int" Range="[0,1]" Default="0" Desc="Stop at breakpoints for debug/test"
;
; PIPELINE ORDER: 4.05
; PIPELINE CATEGORY: PolarimetricScience,Calibration
;
;
; HISTORY:
;	2013-03-20	Started by Marshall, forked from gpi_combine_polarizations_dd.pro
;-

;------------------------------------------




;------------------------------------------

function gpi_clean_polarization_pairs_dd, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive


	if tag_exist( Modules[thisModuleIndex], "Save_diffbias") then save_diffbias=uint(Modules[thisModuleIndex].Save_diffbias) else Save_diffbias=0 
	if tag_exist( Modules[thisModuleIndex], "gpitv_diffbias") then gpitv_diffbias=uint(Modules[thisModuleIndex].gpitv_diffbias) else gpitv_diffbias=0 
	if tag_exist( Modules[thisModuleIndex], "fix_badpix") then fix_badpix=uint(Modules[thisModuleIndex].fix_badpix) else fix_badpix=0 
	if tag_exist( Modules[thisModuleIndex], "debug") then mydebug=uint(Modules[thisModuleIndex].debug) else mydebug=0 

	nfiles=dataset.validframecount

	if backbone->Get_current_reduction_level() ne 2 then return, error(functionname+": can only be called during Level 2 reduction, *after* Accumulate Imagers")

	; Load the first file so we can figure out their size, etc. 
	im0 = accumulate_getimage(dataset, 0, hdr0,hdrext=hdrext)


	; Load all files at once into a stack of all the polarization pairs

	sz = [0, sxpar(hdrext,'NAXIS1'), sxpar(hdrext,'NAXIS2'), sxpar(hdrext,'NAXIS3')]
	polstack =	   fltarr(sz[1], sz[2], sz[3]*nfiles) ; stack of all input polarization pairs
	sumdiffstack = fltarr(sz[1], sz[2], sz[3]*nfiles) ; a transformed version of polstack, holding the sum and single-difference images

	logstr = 'Estimating systematic bias between polarization channels from all pol pairs'
	backbone->set_keyword, "HISTORY", logstr
	backbone->Log, logstr


	for i=0L,nfiles-1 do begin
		polstack[0,0,i*2] = accumulate_getimage(dataset,i,hdr0,hdrext=hdrext)

		; set up summed and differences images from each polarization pair 
		
		sumdiffstack[0,0,i*2] = polstack[*,*,i*2] + polstack[*,*,i*2+1]
		sumdiffstack[0,0,i*2+1] = polstack[*,*,i*2] - polstack[*,*,i*2+1]

	endfor 
	

	;--------- Experimental code here for double differencing as applied to GPI sequences.
	; We can't just use simple double differencing because we have to derotate
	; the images to align north up AFTER the differencing process. And depending
	; on rotation angles the target may rotate too much between one exposure and
	; the next to just simply difference two images without being hurt by the
	; offset between those images.  
	
	; Instead of combining individual pairs of images, we take everything at
	; once, use the combined set of all differences to assess the systematic bias 
	; between the e- and o- channels, and then subtract *that* from the
	; individual differences. 
	; So this is still a double subtraction, but of something slightly
	; different!!


	; First, generate sums and differences of all the individual exposures. 

	sumstack = sumdiffstack[*,*,indgen(nfiles)*2]		; This is all the summed Stokes I images
	diffstack = sumdiffstack[*,*,indgen(nfiles)*2+1]	; This is the difference for each frame

	; Due to systematics in datacube extraction, bad pixels, etc, there are some
	; systematic biases between the e- and o- channels which are consistent
	; between exposures. We measure that here and subtract it off. 
	
	median_diff = median(diffstack,dim=3)				; Median of the differences. Should be mostly systematics
														; i.e. the difference between the e- and o-
														; rays which is due to polarization cube
														; extraction imperfections
	skysub, diffstack, median_diff, subdiffstack		; Subtract this from all the individual differences
									
	; FIXME should we do this on the difference images, or on the sum images?
	; Or the pairs? 
	if keyword_set(fix_badpix) then begin
		clean_diffstack = ns_fixpix(subdiffstack)			; Apply statistical heuristic bad pixel cleanup
		logstr = 'Bad pixel repair attempted via interpolation over statistical outliers'
		backbone->set_keyword, "HISTORY", logstr
		backbone->Log, logstr

	endif else clean_diffstack = subdiffstack

	; Now having cleaned up the differences, combine those back with the sums
	; to produce a cleaned version of the individual e- and o- pairs, which
	; is what we will actually fit. 
	
	clean_polstack = polstack *0
	clean_polstack[*,*,indgen(nfiles)*2] = (sumstack + clean_diffstack)/2
	clean_polstack[*,*,indgen(nfiles)*2+1] = (sumstack - clean_diffstack)/2

	logstr = 'The estimated bias was subtracted from all pairs.'
	backbone->set_keyword, "HISTORY", logstr
	backbone->Log, logstr

	if keyword_set(fix_badpix) then clean_polstack = ns_fixpix(clean_polstack)

	mydebug=0
	if keyword_set(mydebug) then begin
		; OLD VERSION:
		;lpi =  total(abs(subdiffstack),3) / nfiles
		;sum =  total(abs(sumstack),3) / nfiles
		cleansum_diffstack = sumdiffstack
		cleansum_diffstack[*,*,indgen(nfiles)*2+1] = clean_diffstack


		; Now let's reassemble something that looks like the original 
		; differences, but cleaner
		;	sumdiffstack[0,0,i*2] = polstack[*,*,i*2] + polstack[*,*,i*2+1]
		;	sumdiffstack[0,0,i*2+1] = polstack[*,*,i*2] - polstack[*,*,i*2+1]
		;	S = P0+P1
		;	D = P0-P1
		;	P0 = (S+D)/2
		;	P1 = (S-D)/2
		
		polstack0 = polstack		; save copy of pol stack for comparison. 
		polstack[*,*,indgen(nfiles)*2]   = ( cleansum_diffstack[*,*,indgen(nfiles)*2] + cleansum_diffstack[*,*,indgen(nfiles)*2+1] )/2
		polstack[*,*,indgen(nfiles)*2+1] = ( cleansum_diffstack[*,*,indgen(nfiles)*2] - cleansum_diffstack[*,*,indgen(nfiles)*2+1] )/2

		; Can examine here to see the achieved cleanup in the cubes
		atv, [clean_polstack, polstack, polstack0],/bl 
	endif



	sm_clean_diffstack = clean_diffstack *0

	; the runtime version of IDL does not support the execute function that is called in filter_image if the no_ft keyword is not set.
	if LMGR(/runtime) eq 1 then for i=0L,nfiles-1 do sm_clean_diffstack[*,*,i] = filter_image(clean_diffstack[*,*,i],fwhm=3,/all,/no_ft) $
			 else for i=0L,nfiles-1 do sm_clean_diffstack[*,*,i] = filter_image(clean_diffstack[*,*,i],fwhm=3,/all)

	if keyword_set(mydebug) then atv, [diffstack, clean_diffstack, sm_clean_diffstack],/bl

	;for i=0,2*nfiles-1 do polstack[*,*,i] = filter_image(polstack[*,*,i], fwhm=3,/all);;
	if keyword_set(mydebug) then stop


	; Now, stick the modified images back into the accumulator buffer
	for i=0L,nfiles-1 do begin
		accumulate_updateimage, dataset, i, newdata=clean_polstack[*,*,i*2:i*2+1] 
	endfor


  	if keyword_set(save_diffbias) then begin
		backbone->Log, "Saving Polarization Pair Difference Systematic Bias to file."
		priheader = *dataset.headersPHU[numfile]
		extheader = *dataset.headersExt[numfile]
		sxaddpar, priheader, 'FILETYPE', 'Polarization Pair Difference Systematic Bias'

		b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, 'poldiffbias', display=gpitv_diffbias, $
			savedata=median_diff, saveheader=extheader, savePHU=priheader)
	endif

	; *****WARNING**** 
	; Do not use the regular __end_primitive here, this is different enough than
	; most other primitives that output only one file that the __end_primitive won't work.
	return, OK


	; FIXME TODO
	; Add some ability to output/save the debiased data here. This again breaks the
	; paradigm we've had of only writing out one file at a time because it wants to write
	; a whole bunch of stuff. 


    save_suffix = 'podc_debiased'
    b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, save_suffix, display=3)

end

