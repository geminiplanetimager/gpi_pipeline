
;+
; NAME: gpi_clean_cosmic_rays
; PIPELINE PRIMITIVE DESCRIPTION: Clean Cosmic Rays
;   Placeholder; des not actually do anything yet. 
;   Empirically, cosmic rays do not appear to be a significant noise source
;   for the GPI IFS. It's a substrate-removed H2RG so the level is quite low. 
;   
;
; PIPELINE COMMENT: Placeholder for cosmic ray rejection (if needed; not currently implemented!)
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.23
; PIPELINE NEWTYPE: ALL
;
; HISTORY:
; 2010-01-28 MDP: Created Templae.
; 2011-07-30 MDP: Updated for multi-extension FITS
; 2013-07-16 MDP: Renamed as part of code cleanup.
;-
function gpi_clean_cosmic_rays, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive


	message,/info, "--- Clean Cosmic Rays is only a PLACEHOLDER ---"
	message,/info, "--- No actual cleaning code written yet.... ---"
	*(dataset.currframe[0]) -= 0

	backbone->set_keyword, 'HISTORY', functionname+": No Cosmic Ray Cleaning written yet...",ext_num=0

	;suffix = "-crclean"	

@__end_primitive
end
