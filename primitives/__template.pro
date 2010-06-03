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
; PIPELINE ARGUMENT: Name='suffix' type='string' default='default' Desc="choose the suffix"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 10.0
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 
;
; HISTORY:
;-  

function save_output, DataSet, Modules, Backbone

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.
@__start_primitive


	; put your code here


@__end_primitive

end
