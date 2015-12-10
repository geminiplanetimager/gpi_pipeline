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
; PIPELINE CATEGORY: Calibration

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
;   2014-11-04 MP: Avoid trying to run parallelized sigmaclip if in IDL runtime.
;   2015-02-05 KBF: Fix readnoise estimation
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
  dqtab = dblarr(sz[1], sz[2], nfiles)

	itimes = fltarr(nfiles)

	; read in all the images
	for i=0,nfiles-1 do begin
		imtab[*,*,i] =  accumulate_getimage(dataset,i,hdr, hdrext=hdrext, dqframe=dqframe, dqhdr=dqhdr)
		dqtab[*,*,i] = dqframe
		itimes[i] = sxpar(hdrext, 'ITIME')
		; verify all input files have the same exp time?
		if itimes[i] ne itimes[0] then return, error('FAILURE ('+functionName+"): Exposure times are inconsistent. First file was "+strc(itimes[0])+" s, but file "+strc(i)+" is not.")
		if strcompress(sxpar(hdr, 'OBSTYPE'),/remove_all) ne 'DARK' then begin
       return, error('FAILURE ('+functionName+"): This is not a dark or OBSTYPE keyword missing - no master dark will be built")
    endif
	endfor

	

	; now combine them.
	if nfiles gt 1 then begin
		backbone->set_keyword, 'HISTORY', "   Combining n="+strc(nfiles)+' files using method='+method,ext_num=0
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
			can_parallelize = ~ LMGR(/runtime)  ; cannot parallelize if you are in runtime compiled IDL
			combined_im = gpi_sigma_clip_image_stack( imtab, sigma=sigma_cut,parallelize=can_parallelize)
		end
		else: begin
			return, error('FAILURE ('+functionName+"): Invalid combination method '"+method+"' in call to Combine 2D Dark Frames.")
		endelse
		endcase
	endif else begin

		backbone->set_keyword, 'HISTORY', "   Only 1 file supplied, so nothing to combine.",ext_num=0
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
		rdnoise=stddev2[0]/sqrt(float(nfiles))    ;readnoise in master dark frame taking into account number of darks in the cube
		backbone->Log, 'Estimated master dark read noise='+sigfig(rdnoise,4)+'cts  from stddev across '+strc(nfiles)+' darks.', depth=3
		backbone->set_keyword, 'HISTORY', "   Estimating read noise comparing all files: ",ext_num=0
		backbone->set_keyword, 'HISTORY', "     rdnoise = stddev(dark_i-combined_dark)/sqrt(nfiles) = "+sigfig(rdnoise,4),ext_num=0
		backbone->set_keyword, 'EST_RDNS', rdnoise, 'Estimated master dark read noise from stddev across '+strc(nfiles)+' darks [counts]' ,ext_num=0



		;---
		; Let's also attempt to assess the measured mean dark rate and number of hot pixels. 
		; we will define 'hot pixel' as any pixel with >1 e-/sec dark current. This is
		; based on to Teledyne's own definition of >1 e-/sec as a non-operable pixel.

		itime = backbone->get_keyword('ITIME')
		gain = backbone->get_keyword('SYSGAIN') ; gives e-/DN


		combined_center=combined_im[4:2043,4:2043] ; ignore edges

		; use refpix here to subtract off median row
		;refpix = [combined_im[0:3,4:2043], combined_im[2044:*,4:2043]]
		;meanrefpix = mean(refpix,dim=1)
		;combined_center -= rebin(transpose(meanrefpix), 2040, 2040)
		; NO - the above does not work well for the curvature at the bottom from
		; reset anomaly. 
		;
		; Let's just forget the overall dark level (this is negligible) and
		; instead just subtract off row medians
		
		
		rowmedians = median(combined_center, dim=1)
		combined_center -= rebin(transpose(rowmedians), 2040, 2040)

		med_combined = median(combined_center) ; this will probably now be 0.0 given the above.

		nsig=5
		whigh = where(combined_center gt (med_combined+nsig*rdnoise), highct)
		wlow  = where(combined_center lt (med_combined-nsig*rdnoise), lowct)

		if keyword_set(do_plot_dark) then begin
			plothist,combined_center,/ylog, xrange=[-3*rdnoise, 8*rdnoise] 
		endif
		backbone->set_keyword, 'HISTORY', "   "+strc(highct)+" pixels are high, >  5*sigma_readnoise + median(dark)" ,ext_num=0
		backbone->set_keyword, 'HISTORY', "   "+strc(lowct)+" pixels are low,   < -5*sigma_readnoise + median(dark)" ,ext_num=0

		hotcutoff = itime/gain ; = 1 e-/second
		whot = where(combined_center gt hotcutoff+med_combined, hotct)  ; hot pixel threshhold is relative to counts above the median count rate 
																		; so that it is robust against detector bias (which is ~ 15 counts for
																		; short exposures )
		backbone->set_keyword, 'HISTORY', "   Hot pixels (>1 e-/sec) would have >"+sigfig(hotcutoff,5)+" counts",ext_num=0
		backbone->set_keyword, 'HISTORY', "   "+strc(hotct)+" such pixels are present, and " ,ext_num=0
		whot2 = where( (combined_center gt hotcutoff) and (combined_center gt (med_combined+nsig*rdnoise)), hotct2)
		backbone->set_keyword, 'HISTORY', "   "+strc(hotct2)+" of those are > 5 sigma above rdnoise" ,ext_num=0
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
		if goodct eq 0 then return, error("ERROR: In the combined dark, somehow all pixels are flagged as bad.")
		meandark = mean(combined_center[wgood])

		backbone->set_keyword, 'HISTORY', "   Good pixels mean dark rate = "+sigfig(meandark/itime,3)+" counts/sec" ,ext_num=0
		;backbone->set_keyword, 'EST_DKRT', meandark/itime, "Estimated mean count rate for good pixels [counts/sec]"


	endif
    

	; Median data quality frames for image combo... note that there's probably a better way to do this 
  median_dq=median(dqtab, dim=3)
  *(dataset.currdq)=median_dq
  
	;----- store the output into the backbone datastruct
	*(dataset.currframe)=combined_im
	dataset.validframecount=1
  	backbone->set_keyword, "FILETYPE", "Dark File", /savecomment
  	backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
	suffix = '-dark'

@__end_primitive
end
