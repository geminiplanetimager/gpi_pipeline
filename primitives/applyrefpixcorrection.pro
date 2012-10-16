
;+
; NAME: ApplyRefPixCorrection
; PIPELINE PRIMITIVE DESCRIPTION: Apply Reference Pixel Correction
;
; 	Correct for fluctuations in the bias/dark level using the rows of 
; 	reference pixels in the H2RG detectors. 
;   Algorithm choices include: 
;    1) simple_channels		in this case, just use the median of each
;    					    vertical channel to remove offsets between 
;    					    the channels
;    2) simple_horizontal	take the median of the 8 ref pix for each row,
;    						and subtract that from each row. 
;    3) interpolating		in this case, use James Larkin's interpolation
;    						algorithm to remove linear variation with time 
;    						in the horizontal direction
;
; 	See discussion in section 3.1 of Rauscher et al. 2008 Prof SPIE 7021 p 63.
;
; INPUTS: 
;
; KEYWORDS:
;
; OUTPUTS: 
; 	2D image corrected
;
; ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.
;
; PIPELINE COMMENT: Subtract channel bias levels using H2RG reference pixels.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display " 
; PIPELINE ARGUMENT: Name="before_and_after" Type="int" Range="[0,1]" Default="0" Desc="Show the before-and-after images for the user to see?"
; PIPELINE ARGUMENT: Name="Method" Type="enum" Range="SIMPLE_CHANNELS|INTERPOLATED"  Default="INTERPOLATED" Desc="Algorithm for reference pixel subtraction."
; PIPELINE ORDER: 1.25
; PIPELINE TYPE: ALL
; PIPELINE NEWTYPE: ALL
; PIPELINE SEQUENCE: 3-
;
; HISTORY:
; 	Originally by Jerome Maire 2008-06
; 	2009-04-20 MDP: Updated to pipeline format, added docs. 
; 				    Some code lifted from OSIRIS subtradark_000.pro
;   2009-09-17 JM: added DRF parameters
;   2012-07-27 MP: Added Method parameter, James Larkin's improved algorithm
;   2012-10-14 MP: debugging and code cleanup.
;
function ApplyRefPixCorrection, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

 	if tag_exist( Modules[thisModuleIndex], "before_and_after") then before_and_after=fix(Modules[thisModuleIndex].before_and_after) else before_and_after=0

	im =  *(dataset.currframe[0])

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



	;TODO record the relevant numbers in the FITS headers!

	backbone->set_keyword, "HISTORY", " REFPIX-VERTICAL: subtracting ref pix moving median for each row"

    row_meds = median(median([im[0:3, *], im[2044:2047,*]], dim=1),3)

    ref = rebin(transpose(row_meds), 2048,2048)

    imout = im - ref


	;before_and_after=1
	if keyword_set(before_and_after) then begin
		atv, [[[*(dataset.currframe[0])]], [[im]],[[ref]],[[imout]]],/bl, names=['Input image','Ref Pixel Results', 'Subtracted', 'output']
		stop
	endif

	*(dataset.currframe[0]) = imout
	;*(dataset.headers[numfile]) = hdr

suffix = 'refpixcorr'
@__end_primitive
end
