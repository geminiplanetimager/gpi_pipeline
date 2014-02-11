;+
; NAME: gpi_flag_quicklook
; PIPELINE PRIMITIVE DESCRIPTION: Flag Quicklook
;	
;	Writes a QUIKLOOK=True keyword to the current header. 
;	Also updates some FITS history text to indicate the quicklook status.
;
; INPUT: Any FITS file
; OUTPUTS: The FITS file header in memory gets added a keyword QUIKLOOK=True
;
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: Save output to disk, 0: Don't save"
; PIPELINE COMMENT: Flag a given reduction output as 'quicklook' quality rather than science grade.
; PIPELINE ORDER: 0.1
; PIPELINE CATEGORY: ALL
;
; HISTORY:
;    Marshall Perrin 2013-10-29  Started based on gpi_add_missingkeyword
;-

function gpi_flag_quicklook,  DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
 
    
    backbone->set_keyword, "QUIKLOOK", 'T', 'This is a quick-look reduction; not science quality!'
    backbone->set_keyword, "HISTORY", "        **************************************************"
    backbone->set_keyword, "HISTORY", "        *  This file is a 'quicklook'-quality reduction  *"
    backbone->set_keyword, "HISTORY", "        *    NOT guaranteed publication quality data!    *"
    backbone->set_keyword, "HISTORY", "        * Use caution and your best scientific judgement *"
    backbone->set_keyword, "HISTORY", "        **************************************************"

    backbone->Log, 'Flagged as Quicklook quality data', depth=3
   
@__end_primitive


end
