
;+
; NAME: Simple Destripe
; PIPELINE PRIMITIVE DESCRIPTION: Simple Destripe (hard-coded for I and T)
;
; 	Correct for fluctuations in the bias/dark level using 
; 	area far from where the PSF is right now. 
; 	This is hard-coded for UCSC I&T of GPI, with specific choices
; 	as to what regions of the detector are far from the PSF in the occulted 
; 	case.
;
; 	Won't work well on flats or other such data. 
;
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
; PIPELINE COMMENT: Subtract readout pickup noise using areas far from the PSF core
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display " 
; PIPELINE ARGUMENT: Name="before_and_after" Type="int" Range="[0,1]" Default="0" Desc="Show the before-and-after images for the user to see?"
; PIPELINE ORDER: 1.25
; PIPELINE NEWTYPE: ALL
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 3-
;
; HISTORY:
; 	Originally by Jerome Maire 2008-06
; 	2009-04-20 MDP: Updated to pipeline format, added docs. 
; 				    Some code lifted from OSIRIS subtradark_000.pro
;   2009-09-17 JM: added DRF parameters
;
function destripe_simple, DataSet, Modules, Backbone
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
	means = fltarr(nreadout)


	mask = im
	mask[*] = !values.f_nan
    date = sxpar(*(dataset.headersPHU[0]), 'DATE-OBS', count=count)
    if count eq 0 then begin
        backbone->Log, "DESTRIPE: Could not find DATE-OBS in FITS header, unsure how to proceed."
        return, NOT_OK
    endif

    month=fix(strmid(date,5,2))
    if month le 4 then begin
        ; April 2012 or before: Assume star is off center to the right
        mask[0:300, 360:2047] = 1
        mask[0:150, 250:359] = 1
        mask[850:1050, 0:500] = 1
        label='pre-remediation (April 2012 or before)'
    endif else begin
        ; May 2012 or later (post remediation): Assume star is more well centered

        mask[0:200, 0:2047] = 1
        mask[1847:2047, 0:2047] = 1
        label='post-remediation (May 2012 or later)'
    endelse

    backbone->set_keyword, "HISTORY", "Subtracted ad hoc stripe background estimated from mask for "+label ,ext_num=0

    row_meds = median(im*mask, dim=1)

    ref = rebin(transpose(row_meds), 2048,2048)

    imout = im - ref

	;stop

	before_and_after=0
	if keyword_set(before_and_after) then begin
		atv, [[[im]],[[ref]],[[imout]]],/bl, names=['Input image','Ref Pixel Results', 'Subtracted']
		stop
	endif

	*(dataset.currframe[0]) = imout

suffix = 'destripe'
@__end_primitive
end
