
;+
; NAME: gpi_cosmicrays
; PIPELINE PRIMITIVE DESCRIPTION: Clean Cosmic Rays
; INPUTS: 
;
; KEYWORDS:
;
; OUTPUTS: 
; 	2D image corrected
;
; ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.
;
; PIPELINE COMMENT: Subtract a dark frame. 
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.27
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 2010-01-28: MDP Created Templae.
;
function gpi_cosmicrays, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive


	message,/info, "--- Clean Cosmic Rays is only a PLACEHOLDER ---"
	message,/info, "--- No actual cleaning code written yet.... ---"
	*(dataset.currframe[0]) -= 0

	sxaddhist, functionname+": No Cosmic Ray Cleaning written yet...", *(dataset.headers[numfile])

  
	suffix = "-crclean"	

@__end_primitive
end
