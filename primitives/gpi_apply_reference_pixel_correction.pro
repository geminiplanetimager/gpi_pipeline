
;+
; NAME: gpi_apply_reference_pixel_correction 
; PIPELINE PRIMITIVE DESCRIPTION: Apply Reference Pixel Correction
;
; 	Correct for fluctuations in the bias/dark level using the rows of 
; 	reference pixels in the H2RG detectors.
;
;   Note that *vertical* reference pixel subtraction to fix offsets between
;   the 32 readout channels is done in real time during the readout process by
;   the IFS Detector Server software. The Detector Server does not currently
;   apply any horizontal reference pixel subtraction, so we need to do that in
;   the pipeline. See the HRPSTYPE and VRPSTYPE FITS keywords in the SCI
;   extension headers. 
;
;	Also note that if you use one of the specialized Destriping primitives,
;	you do not also need to use this one as well. 
;
;
;   Algorithm choices include: 
;    1) simple_channels		in this case, just use the median of each
;    					    vertical channel to remove offsets between 
;    					    the channels. (deprecated, now done by the IFS
;    					    detector server in real time during readout)
;    2) simple_horizontal	take the median of the 8 ref pix for each row,
;    						and subtract that from each row. 
;    3) smoothed_horizontal	Like the above, but smoothed by N pixels vertically
;							for better S/N. N is adjustable using the smoothing_size
;							parameter. Empirically values < 20 or 30 seem to be
;							not enough smoothing, so the read noise fluctuations
;							give spurious biases to the ref pix model. 
;    3) interpolated		In this case, use James Larkin's interpolation
;    						algorithm to remove linear variation with time 
;    						in the horizontal direction. This gives the highest
;    						spatial frequency correction but is more affected
;    						by read noise.
;
; 	See discussion in section 3.1 of Rauscher et al. 2008 Prof SPIE 7021 p 63.
;
;   
;
; INPUTS: 2D image file
;
; OUTPUTS: 2D image corrected for background using reference pixels
;
; ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.
;
; PIPELINE COMMENT: Subtract channel bias levels and bias drift stripes using H2RG reference pixels.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display " 
; PIPELINE ARGUMENT: Name="smoothing_size" Type="int" Range="[0,500]" Default="31" Desc="Smoothing kernel size for smoothed_horizontal method.  " 
; PIPELINE ARGUMENT: Name="before_and_after" Type="int" Range="[0,1]" Default="0" Desc="Show the before-and-after images for the user to see?"
; PIPELINE ARGUMENT: Name="Method" Type="enum" Range="SIMPLE_CHANNELS|SIMPLE_HORIZONTAL|SMOOTHED_HORIZONTAL|INTERPOLATED"  Default="INTERPOLATED" Desc="Algorithm for reference pixel subtraction."
; PIPELINE ORDER: 1.25
; PIPELINE CATEGORY: ALL
;
; HISTORY:
; 	Originally by Jerome Maire 2008-06
; 	2009-04-20 MDP: Updated to pipeline format, added docs. 
; 				    Some code lifted from OSIRIS subtradark_000.pro
;   2009-09-17 JM: added DRF parameters
;   2012-07-27 MP: Added Method parameter, James Larkin's improved algorithm
;   2012-10-14 MP: debugging and code cleanup.
;   2013-07-17 MP: Rename for consistency
;   2013-12-03 MP: Some docs updates and added SMOOTHED_HORIZONTAL algorithm and smoothing_size parameter
;-
function gpi_apply_reference_pixel_correction, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

 	if tag_exist( Modules[thisModuleIndex], "before_and_after") then before_and_after=fix(Modules[thisModuleIndex].before_and_after) else before_and_after=0
 	if tag_exist( Modules[thisModuleIndex], "smoothing_size") then smoothing_size=fix(Modules[thisModuleIndex].smoothing_size) else smoothing_size=31

	im =  *dataset.currframe

	sz = size(im)


    if sz[1] ne 2048 or sz[2] ne 2048 then begin
        backbone->Log, "REFPIX: Image is not 2048x2048, don't know how to ref pixel subtract"
        backbone->set_keyword, "HISTORY", "Image is not 2048x2048, don't know how to ref pixel subtract"
        return, NOT_OK
    endif

	nreadout = 32
	chanwidth = sz[1]/nreadout


	if tag_exist( Modules[thisModuleIndex],'method') then method=strupcase(Modules[thisModuleIndex].method) else method='SIMPLE_CHANNELS'


	case method of
	'SIMPLE_CHANNELS': begin
		; A very simple approach: 
		; For each channel, subtract the outlier-rejected mean of the last four reference rows. 
		;
		; TODO: experiment with other approaches to subtraction; this is the 
		;       standard recommended approach supposedly used at Teledyne 
		;
		; TODO: are the last four rows the bottom or top? Check this...
		means = fltarr(nreadout)


		backbone->set_keyword, "HISTORY", " REFPIX-HORIZONTAL: subtracting ref pix means for each readout"
		backbone->set_keyword, "DRPHREF", "Simple", 'Horizontal reference pixel subtraction method'
		for ir=0L, nreadout-1 do begin
			refregion = im[ir*chanwidth:((ir+1)*chanwidth-1) < (sz[1]-1), 0:4]
			djs_iterstat, refregion, mean=refmean, sigma=refsig
			means[ir] = refmean
			if debug ge 3 then print, "       For channel "+strc(ir)+", REF BIAS is "+sigfig(refmean,4)+", NOISE SIGMA is "+sigfig(refsig, 4)
			; now do the subtraction!
			im[ir*chanwidth:((ir+1)*chanwidth-1) < (sz[1]-1), *] -= refmean
			backbone->set_keyword, "HISTORY", " REFPIX:  readout "+strc(ir)+" has mean="+strc(refmean),ext_num=0
		endfor 
	end
	'SIMPLE_HORIZONTAL': begin
		; a simple subtraction of horizontal reference pixels
		backbone->set_keyword, "HISTORY", " REFPIX-HORIZONTAL: subtracting ref pixels from row medians"
		backbone->set_keyword, "DRPHREF", "Simple", 'Horizontal reference pixel subtraction method'
		href=fltarr(8,2048)	; For each row, the median horizontal reference
		mref=fltarr(2048)

		; Determine the median of the horizontal ref pixels for each row
		href[0:3,*]=im[0:3,*]
		href[4:7,*]=im[2044:2047,*]
		mref[*]=median(href,dimension=1)

		model = rebin(transpose(mref),2048,2048)
		im -= model
		
	end
	'SMOOTHED_HORIZONTAL': begin
		backbone->set_keyword, "HISTORY", " REFPIX-HORIZONTAL: subtracting ref pixels from smoothed row medians"
		backbone->set_keyword, "HISTORY", " REFPIX-HORIZONTAL:    Smoothing size = "+strc(smoothing_size)
		backbone->set_keyword, "DRPHREF", "Smoothed", 'Horizontal reference pixel subtraction method'
		; The first part here is an exact copy of simple_horizontal
		href=fltarr(8,2048)	; For each row, the median horizontal reference
		mref=fltarr(2048)
		href[0:3,*]=im[0:3,*]
		href[4:7,*]=im[2044:2047,*]
		mref[*]=median(href,dimension=1)

		; now we just smooth by a few pixels vertically
		mref = smooth(mref, 9, /edge_truncate)

		model = rebin(transpose(mref),2048,2048)
		im -= model
		
	end
	'INTERPOLATED': begin
		; James Larkin's improved algorithm here, lifted from his fix_row.pro
		; routine
		backbone->set_keyword, "HISTORY", " REFPIX-HORIZONTAL: subtracting ref pixels interpolated via Larkin's algorithm"
		backbone->set_keyword, "DRPHREF", "Larkin interpolation", 'Horizontal reference pixel subtraction method'
		
		;--------------------------------------------------------------	
		; This code is designed to use the horizontal reference pixels in a
		; Hawaii-2RG infrared detector to remove some horizontal striping.
		; At each pixel in the array, the routine interpolates between the
		; reference pixels before and after to the location of the pixel
		; to try and improve on temperoral fluctuations in the bias voltages.
		; The only parameter is the 2048x2048 pixel array itself.
		;
		; Written by James Larkin, July 5, 2012
		;--------------------------------------------------------------	

		refh=fltarr(8)		; Temporary array of the 8 ref pixels on a row
		href=fltarr(8,2048)	; For each row, the median horizontal reference
		href_lin=fltarr(64,2048); Interpolations between the reference pixels.
		mref=fltarr(2048)
		dref=fltarr(2048)	

		; Determine the median of the horizontal ref pixels for each row
		href[0:3,*]=im[0:3,*]
		href[4:7,*]=im[2044:2047,*]
		mref[*]=median(href,dimension=1)
		
		; Calculate difference between one row and the next for interpolation
		dref[0:2046]=mref[1:2047]-mref[0:2046]

		; Calculate linear trends across the 64 pixels of an output between 
		; hrefs (note there are 12 extra pixels in the clocking pattern so divide by 76)
		ramp=findgen(64)/76.0
		for k=0,2046 do begin
			href_lin[*,k]=mref[k]+ramp*dref[k]
		end

		; Even rows need the reverse time series to subtract
		href_r=reverse(href_lin,1)

		; For all 32 outputs, subtract their interpolated hrefs
		for j=0,15 do begin
			;tmp[64*2*j:64*2*j+63,*]=tmp[64*2*j:64*2*j+63,*]-href_lin
			  im[64*2*j:64*2*j+63,*]-=href_lin
			  im[64*2*j+64:64*2*j+127,*]-=href_r
		end

	end
	else:begin
		backbone->Log, "REFPIX: unknown 'method' parameter value '"+method+"'"
		return, NOT_OK
	end
	endcase


; This part of the code is now redundant and can be dropped.
;	;TODO record the relevant numbers in the FITS headers!
;
;	backbone->set_keyword, "HISTORY", " REFPIX-VERTICAL: subtracting ref pix moving median for each row"
;
;    row_meds = median(median([im[0:3, *], im[2044:2047,*]], dim=1),3)
;
;    ref = rebin(transpose(row_meds), 2048,2048)
;
;    imout = im - ref
;

	;before_and_after=1
	if keyword_set(before_and_after) then begin
		diff = *dataset.currframe - im
		atv, [[[*dataset.currframe]], [[diff]],[[im]]],/bl, names=['Input image','Ref Pixel Model', 'Subtracted' ]

		;;atv, [[[*dataset.currframe]], [[im]],[[ref]],[[imout]]],/bl, names=['Input image','Ref Pixel Results', 'Subtracted', 'output']
		stop
	endif

	*dataset.currframe = im

suffix = 'refpixcorr'
@__end_primitive
end
