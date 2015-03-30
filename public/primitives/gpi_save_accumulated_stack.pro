;+
; NAME: gpi_save_accumulated_stack
; PIPELINE PRIMITIVE DESCRIPTION: Save Accumulated Stack
;
; Save the current accumulated stack of images to disk.
;
; Note that this uses whatever the currently defined suffix is, though you can
; also override that here.  This is the one and only routine that should be
; used to override a suffix.
;
;  TODO: change output filename too, optionally?
;
; INPUTS: Any
; OUTPUTS:  The input is written to disk as a FITS file
;
; PIPELINE COMMENT: Save output to disk as a FITS file. Note that you can often do this from another module by setting the 'save=1' option; this is a redundant way to specify that.
; PIPELINE ARGUMENT: Name='suffix' Type='string' default='default' Desc="choose the suffix"
; PIPELINE ORDER: 10.0
; PIPELINE CATEGORY: ALL
;
; HISTORY:
;   2014-11-18 Created by MMB
;-

function gpi_save_accumulated_stack, DataSet, Modules, Backbone
  primitive_version= '$Id: gpi_save_output.pro 2511 2014-02-11 05:57:27Z mperrin $' ; get version from subversion to store in header history
    @__start_primitive

  ;Check to make sure a stack was saved
  reduction_level = backbone->get_current_reduction_level()
  if reduction_level eq 1 then return, error("Please use the 'Accumulate Images' primitive before trying to save accumulated images") 
  
  ; check for a suffix keyword, and use it if present, without overriding whatever is in the current
  ; common block suffix variable.
  save_suffix=suffix
  if tag_exist( Modules[thisModuleIndex], "suffix") then if strc(Modules[thisModuleIndex].suffix) ne "" then save_suffix = string(Modules[thisModuleIndex].suffix)
  
  nfiles=dataset.validframecount
  
  for i=0, nfiles-1 do begin
    *dataset.currframe=accumulate_getimage(dataset,i,hdr,hdrext=hdrext)
    b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, save_suffix, display=display, level2=i)
  endfor
 ; stop


end
