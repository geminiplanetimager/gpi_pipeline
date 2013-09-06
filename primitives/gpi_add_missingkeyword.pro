;+
; NAME: gpi_add_missingkeyword
; PIPELINE PRIMITIVE DESCRIPTION: Add missing keyword
; Useful for test data,...
;
; OUTPUTS: The FITS file is modified in memory to add the specified keyword and
; value. The file on disk is NOT changed. 
;
; PIPELINE ARGUMENT: Name="keyword" Type="string"  Default="" Desc="Enter keyword name to add."
; PIPELINE ARGUMENT: Name="value" Default="" Desc="Enter value of the keyword to add."
; PIPELINE COMMENT: Add any missing keyword. (use this function several times in the DRF if you need to add more than one keyword)
; PIPELINE ORDER: 0.1
; PIPELINE NEWTYPE: Calibration,Testing
;
; HISTORY:
;    Jerome Maire 2009-09-13
;   2009-09-17 JM: added DRF parameters
;   2013-07-11 MP: Documentation cleanup.
;-

function gpi_add_missingkeyword,  DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
 
  if tag_exist( Modules[thisModuleIndex], "keyword") && tag_exist( Modules[thisModuleIndex], "value") then begin
    
    backbone->set_keyword, Modules[thisModuleIndex].keyword, Modules[thisModuleIndex].value
    backbone->Log, 'Added keyword "'+Modules[thisModuleIndex].keyword+'", value="'+Modules[thisModuleIndex].value+'".'
  endif else begin
    backbone->Log, 'WARNING: Add missing keyword was called, but there were no arguments describing a keyword to add. Doing nothing.'
  endelse
   
   
@__end_primitive


end
