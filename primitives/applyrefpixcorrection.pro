
;+
; NAME: ApplyRefPixCorrection
; PIPELINE PRIMITIVE DESCRIPTION: Apply Reference Pixel Correction
;
; 	Correct for fluctuations in the bias/dark level using the rows of 
; 	reference pixels in the H2RG detectors. 
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
; PIPELINE ORDER: 1.25
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 3-
;
; HISTORY:
; 	Originally by Jerome Maire 2008-06
; 	2009-04-20 MDP: Updated to pipeline format, added docs. 
; 				    Some code lifted from OSIRIS subtradark_000.pro
;   2009-09-17 JM: added DRF parameters
;
function ApplyRefPixCorrection, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

	im =  *(dataset.currframe[0])
	;hdr=*(dataset.headers[numfile])


	sz = size(im)

    if sz[1] ne 2048 or sz[2] ne 2048 then begin
        backbone->Log, "REFPIX: Image is not 2048x2048, don't know how to ref pixel subtract"
        backbone->set_keyword, "HISTORY", "Image is not 2048x2048, don't know how to ref pixel subtract"
        return, NOT_OK
    endif
	nreadout = 32

	chanwidth = sz[1]/nreadout
	means = fltarr(nreadout)

	; For each channel, subtract the mean of the last four reference rows. 
	; TODO: are the last four rows the bottom or top? Check this...
	; TODO: experiment with other approaches to subtraction; this is the 
	;       standard recommended approach used at Teledyne, GSFC, etc. 
	backbone->set_keyword, "HISTORY", " REFPIX-HORIZONTAL: subtracting ref pix means for each readout"
	for ir=0L, nreadout-1 do begin
		refregion = im[ir*chanwidth:((ir+1)*chanwidth-1) < (sz[1]-1), 0:4]
		djs_iterstat, refregion, mean=refmean, sigma=refsig
		means[ir] = refmean
		if debug ge 3 then print, "       For channel "+strc(ir)+", REF BIAS is "+sigfig(refmean,4)+", NOISE SIGMA is "+sigfig(refsig, 4)
		; now do the subtraction!
		im[ir*chanwidth:((ir+1)*chanwidth-1) < (sz[1]-1), *] -= refmean
		backbone->set_keyword, "HISTORY", " REFPIX:  readout "+strc(ir)+" has mean="+strc(refmean),ext_num=0
	endfor 

	;TODO record the relevant numbers in the FITS headers!

	backbone->set_keyword, "HISTORY", " REFPIX-VERTICAL: subtracting ref pix moving median for each row"

    row_meds = median(median([im[0:3, *], im[2044:2047,*]], dim=1),3)

    ref = rebin(transpose(row_meds), 2048,2048)

    im -= ref


	*(dataset.currframe[0]) = im
	;*(dataset.headers[numfile]) = hdr

suffix = 'refpixcorr'
@__end_primitive
end
