;+
; NAME: 
; PIPELINE PRIMITIVE DESCRIPTION: 
;
;
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;
; OUTPUTS:  
;
; PIPELINE COMMENT: 
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 10.0
; PIPELINE TYPE: ALL
; PIPELINE NEWTYPE: ALL
; PIPELINE NEWTYPE: SpectralScience
; PIPELINE NEWTYPE: PolarimetricScience
; PIPELINE NEWTYPE: SpectralScience,PolarimetricScience
; PIPELINE NEWTYPE: Calibration
; PIPELINE NEWTYPE: Testing
; PIPELINE NEWTYPE: SpectralScience,Calibration
; PIPELINE SEQUENCE: 
;
; HISTORY:
;-  

function save_output, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.
suffix='' ; output filename suffix
@__start_primitive


	; put your code here


@__end_primitive

end
