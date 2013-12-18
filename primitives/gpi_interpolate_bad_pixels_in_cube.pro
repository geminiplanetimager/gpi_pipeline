;+
; NAME: gpi_interpolate_bad_pixels_in_cube
; PIPELINE PRIMITIVE DESCRIPTION: Interpolate bad pixels in cube
;
;	Searches for statistical outlier bad pixels in a cube and replace them
;	by interpolating between their neighbors. 
;
;	Heuristic and not guaranteed or tested in any way; this is more a 
;	convenience function than a rigorous statistcally justified repair tool
;
; INPUTS: Cube in either spectral or polarization mode
; OUTPUTS: Cube with bad pixels potentially cleaned up. 
;
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="1" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="before_and_after" Type="int" Range="[0,1]" Default="0" Desc="Show the before-and-after images for the user to see? (for debugging/testing)"
;
; PIPELINE COMMENT:  Repair bad pixels by interpolating between their neighbors. 
; PIPELINE ORDER: 2.5
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE NEWTYPE: SpectralScience, PolarimetricScience, Calibration
;
;
; HISTORY:
;	2013-12-14 MP: Created as a convenience function cleanup tool. Almost
;	certainly not the best algorithm - just something quick and good enough for
;	now? 
;-
function gpi_interpolate_bad_pixels_in_cube, DataSet, Modules, Backbone
primitive_version= '$Id: gpi_interpolate_bad_pixels_in_2d_frame.pro 2194 2013-12-03 03:49:09Z mperrin $' ; get version from subversion to store in header history
@__start_primitive


 	if tag_exist( Modules[thisModuleIndex], "before_and_after") then before_and_after=fix(Modules[thisModuleIndex].before_and_after) else before_and_after=0
    if keyword_set(before_and_after) then cube0= *dataset.currframe ; save copy for later display if desired



    backbone->set_keyword,'HISTORY',functionname+": Heuristically locating and interpolating"
    backbone->set_keyword,'HISTORY',functionname+": bad pixels in the data cube."
	*dataset.currframe = ns_fixpix(*dataset.currframe)

	if keyword_set(before_and_after) then begin
		atv, [ cube0, *dataset.currframe ],/bl; , names=['Input image','Output Image', 'Bad Pix Mask']
		stop
	endif

	; update the DQ extension if it is present

	if ptr_valid( dataset.currDQ) then begin
		; we should still leave those pixels flagged to indicate
		; that they were repaired. This is used in some subsequent steps of
		; processing (for instance the 2D wavecal)
		; Bit 5 set = 'flagged as bad'
		; Bit 0 set = 'is OK to use'  therefore 32 means flagged and corrected
		; The following bitwise incantation sets bit 5 and clears bit one
		(*(dataset.currDQ))[wbad] =  ((*(dataset.currDQ))[wbad] OR 32) and (128+64+32+16+8+4+2)
		backbone->set_keyword,'HISTORY',functionname+": Updated DQ extension to indicate bad pixels were repaired.", ext_num=0
	endif



  suffix='-bpfix'


@__end_primitive
end

