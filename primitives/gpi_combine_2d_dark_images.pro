;+
; NAME: gpi_combine_2d_dark_images
; PIPELINE PRIMITIVE DESCRIPTION: Combine 2D dark images
;
;  Several dark frames are combined to produce a master dark file, which
;  is saved to the calibration database. This combination can be done using
;  either a mean or median algorithm, or a mean with outlier 
;  rejection (sigma clipping) 
;
;  Also, based on the variance between the various dark frames, the 
;  read noise is estimated, and a list of hot pixels is derived.
;  The read noise and number of significantly hot pixels are written
;  as keywords to the FITS header for use in trending analyses. 
;  CAUTION FIXME: this code does not take into account coadds properly 
;  and thus is underestimating the actual read noise per frame. 
;
;
; INPUTS:  several dark frames
; OUTPUTS: master dark frame, saved as a calibration file
;
; PIPELINE COMMENT: Combine 2D dark images into a master file via mean or median. 
; PIPELINE ARGUMENT: Name="Method" Type="string" Range="MEAN|MEDIAN|SIGMACLIP"  Default="SIGMACLIP" Desc="How to combine images: median, mean, or mean with outlier rejection?[MEAN|MEDIAN|SIGMACLIP]"
; PIPELINE ARGUMENT: Name="Sigma_cut" Type="float" Range="[1,100]" Default="3" Desc="If Method=SIGMACLIP, then data points more than this many standard deviations away from the median value of a given pixel will be discarded. "
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.01
; PIPELINE NEWTYPE: Calibration

; HISTORY:
; 	 Jerome Maire 2008-10
;   2009-09-17 JM: added DRF parameters
;   2009-10-22 MDP: Created from mediancombine_darks, converted to use
;   				accumulator.
;   2010-01-25 MDP: Added support for multiple methods, MEAN method.
;   2010-03-08 JM: ISCALIB flag for Calib DB
;   2011-07-30 MP: Updated for multi-extension FITS
;   2013-07-12 MP: Rename for consistency
;	2013-12-15 MP: Implemented SIGMACLIP, doc header updates. 
;-
function gpi_combine_2d_dark_images, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "method") then method=Modules[thisModuleIndex].method else method='median'
	if tag_exist( Modules[thisModuleIndex], "sigma_cut") then sigma_cut=Modules[thisModuleIndex].sigma_cut else sigma_cut=3.0


	nfiles=dataset.validframecount

	; Load the first file so we can figure out their size, etc. 

	im0 = accumulate_getimage(dataset, 0, hdr,hdrext=hdrext)

	sz = [0, backbone->get_keyword('NAXIS1',ext_num=1), backbone->get_keyword('NAXIS2',ext_num=1)]
	imtab = dblarr(sz[1], sz[2], nfiles)

	itimes = fltarr(nfiles)

	; read in all the images
	for i=0,nfiles-1 do begin
		imtab[*,*,i] =  accumulate_getimage(dataset,i,hdr, hdrext=hdrext)
		itimes[i] = sxpar(hdrext, 'ITIME')
		; verify all input files have the same exp time?
		if itimes[i] ne itimes[0] then return, error('FAILURE ('+functionName+"): Exposure times are inconsistent. First file was "+strc(itimes[0])+" s, but file "+strc(i)+" is not.")
		if strcompress(sxpar(hdr, 'OBSTYPE'),/remove_all) ne 'DARK' then begin
       return, error('FAILURE ('+functionName+"): This is not a dark or OBSTYPE keyword missing - no master dark will be built")
    endif
	endfor

	

	; now combine them.
	if nfiles gt 1 then begin
		backbone->set_keyword, 'HISTORY', functionname+":   Combining n="+strc(nfiles)+' files using method='+method,ext_num=0
		backbone->Log, "	Combining n="+strc(nfiles)+' files using method='+method
		backbone->set_keyword, 'DRPNFILE', nfiles, "# of files combined to produce this output file"
		case STRUPCASE(method) of
		'MEDIAN': begin 
			combined_im=median(imtab,/DOUBLE,DIMENSION=3) 
		end
		'MEAN': begin
			combined_im=total(imtab,/DOUBLE,3) /((size(imtab))[3])
		end
		'SIGMACLIP': begin
			combined_im = gpi_sigma_clip_image_stack( imtab, sigma=sigma_cut,/parallelize)
		end
		else: begin
			return, error('FAILURE ('+functionName+"): Invalid combination method '"+method+"' in call to Combine 2D Dark Frames.")
		endelse
		endcase
	endif else begin

		backbone->set_keyword, 'HISTORY', functionname+":   Only 1 file supplied, so nothing to combine.",ext_num=0
		message,/info, "Only one frame supplied - can't really combine it with anything..."

		combined_im = imtab[*,*,0]
	endelse

	if nfiles gt 1 then begin

		;----- 
		; Now, let's use the dark frame to assess the read noise in those data. 
		for i=0,nfiles-1 do begin
			imtab[*,*,i] -= combined_im
		endfor
		stddev1 = stddev(imtab) ; that std dev will be biased low if we have median combined
								; the frames above, because there will be many pixels that are
								; precisely 0.0 in the subtraction (where those were the pixels that
								; got selected by the median. Let's mask those out:
		wz = where(imtab eq 0, zct)
		if zct gt 0 then imtab[wz] = !values.f_nan

		; also mask out the ref pixels
		imtab[0:3,*] = !values.f_nan
		imtab[2044:2047,*] = !values.f_nan
		imtab[*,0:3] = !values.f_nan
		imtab[*,2044:2047] = !values.f_nan

		stddev2 = stddev(imtab,/nan) ; this std dev should be less biased
		rdnoise=stddev2
		backbone->Log, 'Estimated read noise='+strc(rdnoise)+' cts from stddev across '+strc(nfiles)+' darks.'
		backbone->set_keyword, 'HISTORY', functionname+":   Estimating read noise comparing all files: ",ext_num=0
		backbone->set_keyword, 'HISTORY', functionname+":      rdnoise = stddev(dark_i-combined_dark) = "+sigfig(rdnoise,4),ext_num=0
		backbone->set_keyword, 'EST_RDNS', rdnoise, 'Estimated read noise from stddev across '+strc(nfiles)+' darks [counts]' ,ext_num=0



		;---
		; Let's also attempt to assess the measured mean dark rate and number of hot pixels. 
		; we will define 'hot pixel' as any pixel with >1 e-/sec dark current. This is
		; based on to Teledyne's own definition of >1 e-/sec as a non-operable pixel.

		itime = backbone->get_keyword('ITIME')
		gain = backbone->get_keyword('SYSGAIN') ; gives e-/DN


		combined_center=combined_im[4:2043,4:2043] ; ignore edges
		med_combined = median(combined_center)

		nsig=5
		whigh = where(combined_center gt (med_combined+nsig*rdnoise), highct)
		wlow  = where(combined_center lt (med_combined-nsig*rdnoise), lowct)

		if keyword_set(do_plot_dark) then begin
			plothist,combined_center,/ylog, xrange=[-3*rdnoise, 8*rdnoise] 
		endif
		backbone->set_keyword, 'HISTORY', functionname+":   "+strc(highct)+" pixels are high, 5 sigma above read noise" ,ext_num=0
		backbone->set_keyword, 'HISTORY', functionname+":   "+strc(lowct)+" pixels are low, 5 sigma below read noise" ,ext_num=0

		hotcutoff = itime/gain
		whot = where(combined_center gt hotcutoff, hotct)
		backbone->set_keyword, 'HISTORY', functionname+":   Hot pixels (>1 e-/sec) would have >"+sigfig(hotcutoff,5)+" counts",ext_num=0
		backbone->set_keyword, 'HISTORY', functionname+":   "+strc(hotct)+" such pixels are present." ,ext_num=0
		whot2 = where( (combined_center gt hotcutoff) and (combined_center gt (med_combined+nsig*rdnoise)), hotct2)
		backbone->set_keyword, 'HISTORY', functionname+":   "+strc(hotct2)+" such pixels are present & >5 sigma * rdnoise" ,ext_num=0
		backbone->set_keyword, 'ESTNHTPX', hotct2, "Estimated number of 'hot' pixels, >1 e-/sec "


	;    wgood = where(abs(combined_center-med_combined) lt nsig*rdnoise, comp=wbad)
		; For the purposes of this calculation, let's be conservative:
		; any pixel which is within 3 pix of a known-bad pixel is also suspect. 
		; This will throw out all the interpixel-capacitance-affected pixels.
		good = abs(combined_center-med_combined) lt nsig*rdnoise
		;maskbad = bytarr(2040,2048)
		;maskbad[wbad] = 1
		good = erode(good, bytarr(5,5)+1) 


		wgood = where(good, goodct)
		if goodct eq 0 then begin
			backbone->Log, "ERROR: In the combined dark, somehow all pixels are flagged as bad."
			return, -1
		endif
		meandark = mean(combined_center[wgood])

		backbone->set_keyword, 'HISTORY', functionname+":   Good pixels mean dark rate = "+sigfig(meandark/itime,3)+" counts/sec" ,ext_num=0
		backbone->set_keyword, 'EST_DKRT', meandark/itime, "Estimated mean count rate for good pixels [counts/sec]"


	endif
    

	; TODO: Do something here with the DQ extensions?

	;----- store the output into the backbone datastruct
	*(dataset.currframe)=combined_im
	dataset.validframecount=1
  	backbone->set_keyword, "FILETYPE", "Dark File", /savecomment
  	backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
	suffix = '-dark'

@__end_primitive
end
