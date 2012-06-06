
;+
; NAME: Simple Destripe
; PIPELINE PRIMITIVE DESCRIPTION: Simple Destripe (hard-coded for I and T)
;
; 	Correct for fluctuations in the bias/dark level using 
; 	area far from where the PSF is right now. 
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
; PIPELINE COMMENT: Subtract channel bias levels using H2RG reference pixels.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display " 
; PIPELINE ARGUMENT: Name="before_and_after" Type="int" Range="[0,1]" Default="0" Desc="Show the before-and-after images for the user to see?"
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
function destripe_simple, DataSet, Modules, Backbone
primitive_version= '$Id: applyrefpixcorrection.pro 677 2012-03-31 20:47:13Z Dmitry $' ; get version from subversion to store in header history
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
	mask[0:300, 360:2047] = 1
	mask[0:150, 250:359] = 1
	mask[850:1050, 0:500] = 1


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
	;*(dataset.headers[numfile]) = hdr

suffix = 'refpixcorr'
@__end_primitive
end
