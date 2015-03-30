;+
; NAME: gpi_save_output
; PIPELINE PRIMITIVE DESCRIPTION: Save Output
;
;	Save the current file to disk. Note that you can often do this
;	from another primitive by setting the 'save=1' option; this is an
;	optional, redundant way to specify that. 
;
;	Note that this uses whatever the currently defined suffix is, though you can
;	also override that here.  This is the one and only routine that should be
;	used to override a suffix. 
;
;  TODO: change output filename too, optionally? 
;
; INPUTS: Any 
; OUTPUTS:  The input is written to disk as a FITS file
;
; PIPELINE COMMENT: Save output to disk as a FITS file. Note that you can often do this from another module by setting the 'save=1' option; this is a redundant way to specify that. 
; PIPELINE ARGUMENT: Name='suffix' Type='string' default='default' Desc="choose the suffix"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 10.0
; PIPELINE CATEGORY: ALL
;
; HISTORY:
;	2009-07-21 Created by MDP. 
;   2009-09-17 JM: added DRF parameters
;   2013-07-17 MP: Rename for consistency
;-  

function gpi_save_output, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

	; check for a suffix keyword, and use it if present, without overriding whatever is in the current
	; common block suffix variable. 
	save_suffix=suffix
	if tag_exist( Modules[thisModuleIndex], "suffix") then if strc(Modules[thisModuleIndex].suffix) ne "" then save_suffix = string(Modules[thisModuleIndex].suffix)

    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, save_suffix, display=display)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
          Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
    endelse


return, ok


end
