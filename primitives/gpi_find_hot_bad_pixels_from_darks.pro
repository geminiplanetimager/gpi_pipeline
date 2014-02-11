;+
; NAME: gpi_find_hot_bad_pixels_from_darks
; PIPELINE PRIMITIVE DESCRIPTION: Find Hot Bad Pixels from Darks
;
; This is a variant of combinedarkframes that (instead of combining darks) 
; analyzes them to find hot pixels and then writes out a
; mask showing where the various hot pixels are. 
;
;
; The current algorithm determines pixels that are hot according to the
; criteria:
;	(a) dark count rate must be > 1 e-/second for that pixel
;	(b) that must be measured with >5 sigma confidence above the estimated
;	    read noise of the frames. 
; The first criterion can be adjusted using the hot_bad_thresh argument.
;
; INPUTS: Multiple dark images
; OUTPUTS:	Map of hot bad pixels
;
; PIPELINE COMMENT: Find hot pixels from a stack of dark images (best with deep integration darks)
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="hot_bad_thresh" Type="float" Range="[0,100.]"  Default="1.0" Desc="Threshhold to consider a hot pixel bad, in electrons/second."
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.01
; PIPELINE CATEGORY: Calibration

;
; HISTORY:
;   2009-07-20 JM: created
;   2009-09-17 JM: added DRF parameters
;   2012-01-31 Switched sxaddpar to backbone->set_keyword Dmitry Savransky
;   2012-11-15 MP: Algorithm entirely replaced with one based on combinedarkframes.
;-
function gpi_find_hot_bad_pixels_from_darks, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
functionname='hotpixels_from_dark' ; brevity is the soul of wit...

	if tag_exist( Modules[thisModuleIndex], "hot_bad_thresh") then hot_bad_thresh=float(Modules[thisModuleIndex].hot_bad_thresh) else hot_bad_thresh=1.0

	method='median'

	nfiles=dataset.validframecount

    if nfiles lt 3 then return, error('FAILURE ('+functionName+'): Too few files supplied. Must have >=3 files but only got '+strc(nfiles))

    ;****************************
    ;*
    ;* The following is mostly an exact copy of combinedarkframes
    ;* until the very end, at which point we write out the mask of
    ;* hot pixels instead of the actual dark frame.
    ;*
    ;****************************



	; Load the first file so we can figure out their size, etc. 

	im0 = accumulate_getimage(dataset, 0, hdr,hdrext=hdrext)

	sz = [0, backbone->get_keyword('NAXIS1',ext_num=1), backbone->get_keyword('NAXIS2',ext_num=1)]
	imtab = dblarr(sz[1], sz[2], nfiles)

	itimes = fltarr(nfiles)

	; read in all the images at once
	for i=0,nfiles-1 do begin
		imtab[*,*,i] =  accumulate_getimage(dataset,i,hdr, hdrext=hdrext)
		itimes[i] = sxpar(hdrext, 'ITIME')
	endfor

	; verify all input files have the same exp time
	



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
		'MEANCLIP': begin
			message, 'Method MEANCLIP not implemented yet - bug someone to program it!'
		end
		else: begin
			message,"Invalid combination method '"+method+"' in call to Combine 2D Dark Frames."
			return, NOT_OK
		endelse
		endcase
	endif else begin

		backbone->set_keyword, 'HISTORY', functionname+":   Only 1 file supplied, so nothing to combine.",ext_num=0
		message,/info, "Only one frame supplied - can't really combine it with anything..."

		combined_im = imtab[*,*,0]
	endelse


    ;----- 
    ; Now, let's use the dark frame to assess the read noise in those data. 
    for i=0,nfiles-1 do begin
        imtab[*,*,i] -= combined_im
    endfor
    stddev1 = stddev(imtab) ; that std dev will be biased low if we have median combined
                            ; the frames above, because there will be many pixels that are
                            ; precisely 0.0 in the subtraction (where those were the pixels that
                            ; got selected by the median. Let's mask those out
    wz = where(imtab eq 0, zct)
    if zct gt 0 then imtab[wz] = !values.f_nan

    ; also mask out the ref pixels
    imtab[0:3,*] = !values.f_nan
    imtab[2044:2047,*] = !values.f_nan
    imtab[*,0:3] = !values.f_nan
    imtab[*,2044:2047] = !values.f_nan

    stddev2 = stddev(imtab,/nan) ; this std dev should be less biased
    rdnoise=stddev2[0]
    backbone->Log, 'Estimated read noise='+sigfig(rdnoise,4)+'cts  from stddev across '+strc(nfiles)+' darks.', depth=3
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

    hotcutoff = itime/gain*hot_bad_thresh
    whot = where(combined_center gt hotcutoff, hotct)
	backbone->set_keyword, 'HISTORY', functionname+":   Hot pixels (>"+strc(hot_bad_thresh)+" e-/sec) would have >"+sigfig(hotcutoff,5)+" counts",ext_num=0
	backbone->set_keyword, 'HISTORY', functionname+":   "+strc(hotct)+" such pixels are present." ,ext_num=0
    whot2 = where( (combined_center gt hotcutoff) and (combined_center gt (med_combined+nsig*rdnoise)), hotct2)
	backbone->set_keyword, 'HISTORY', functionname+":   "+strc(hotct2)+" such pixels are present & >5 sigma * rdnoise" ,ext_num=0
    backbone->set_keyword, 'ESTNHTPX', hotct2, "Estimated number of 'hot' pixels, >1 e-/sec "

	backbone->Log, "Hot pixels (>"+strc(hot_bad_thresh)+" e-/sec) would have >"+sigfig(hotcutoff,5)+" counts", depth=3
	backbone->Log, "   "+strc(hotct2)+" such pixels are present & >5 sigma * rdnoise", depth=3


;    wgood = where(abs(combined_center-med_combined) lt nsig*rdnoise, comp=wbad)
    ; For the purposes of this calculation, let's be conservative:
    ; any pixel which is within 3 pix of a known-bad pixel is also suspect. 
    ; This will throw out all the interpixel-capacitance-affected pixels.
    good = abs(combined_center-med_combined) lt nsig*rdnoise
    ;maskbad = bytarr(2040,2048)
    ;maskbad[wbad] = 1
    good = erode(good, bytarr(5,5)+1) 


    wgood = where(good)
    meandark = mean(combined_center[wgood])

	backbone->set_keyword, 'HISTORY', functionname+":   Good pixels mean dark rate = "+sigfig(meandark/itime,3)+" counts/sec" ,ext_num=0
    backbone->set_keyword, 'EST_DKRT', meandark/itime, "Estimated mean count rate for good pixels [counts/sec]"


    ;****************************
    ;*
    ;* Here is where something different from
    ;* combinedarkframes happens:
    ;*
    ;****************************
    maskhotpix =  (combined_im gt hotcutoff) and (combined_im gt (med_combined+nsig*rdnoise))
    nhotpix = total(maskhotpix)
    backbone->set_keyword, 'DRPNHTPX', hotct2, "Number of 'hot' pixels, >1 e-/sec and >5sig*rdnoise "
    

	;----- store the output into the backbone datastruct
	*(dataset.currframe)=maskhotpix
    suffix='-hotpix'

    backbone->set_keyword, "FILETYPE", "Hot Pixel Map", "What kind of IFS file is this?"
    backbone->set_keyword,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.' 

@__end_primitive
end

