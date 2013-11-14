;+
; NAME: gpi_add_dispersr_if_missing
; PIPELINE PRIMITIVE DESCRIPTION: Add DISPERSR keyword if missing - workaround for 1st light run
; Useful for test data,...
;
; OUTPUTS: The FITS file is modified in memory to add the specified keyword and
; value. The file on disk is NOT changed. 
;
; PIPELINE ARGUMENT: Name="value" Default="DISP_PRISM_G6262" Desc="Enter value of the keyword to add."
; PIPELINE COMMENT: Add missing DISPERSR keyword
; PIPELINE ORDER: 0.1
; PIPELINE NEWTYPE: Calibration,Testing
;
; HISTORY:
;    Jerome Maire 2009-09-13
;   2009-09-17 JM: added DRF parameters
;   2013-07-11 MP: Documentation cleanup.
;-

function gpi_add_missingkeyword,  DataSet, Modules, Backbone

primitive_version= '$Id: gpi_add_missingkeyword.pro 2026 2013-10-29 22:44:50Z mperrin $' ; get version from subversion to store in header history
@__start_primitive

	val = backbone->get_keyword("DISPERSR", count=ct)
	if ct gt 0 then return, OK ; nothing needs to be done. 


    
    backbone->set_keyword, "DISPERSR", Modules[thisModuleIndex].value
    backbone->Log, 'Added missing DISPERSR keyword value="'+Modules[thisModuleIndex].value+'".', depth=3
   
   
@__end_primitive


end
