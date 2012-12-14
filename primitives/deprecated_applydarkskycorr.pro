;  *** Back compatibility patch for renaming of  "Subtract Dark/Sky Background"
;  to "Subtract Sky Background". This  primitive just ensures that the old name
;  is still considered valid, we can re-run old recipes using it. No actual code
;  here, it just passes any calls along to the actual algorithm in
;  ApplyDarkCorrection.pro
;

;+
; NAME: ApplyDarkCorrection
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Dark/Sky Background
;
;
; INPUTS: 
;
; KEYWORDS:
;
; OUTPUTS: 
;
; PIPELINE COMMENT: Subtract a dark frame. 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="dark" Default="AUTOMATIC"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.26
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE NEWTYPE: ALL
;
; HISTORY:
;   2012-12-13 MP: Created as a back-compatibility workaround for a renaming.
;-

function deprecated_applydarkskycorr, DataSet, Modules, Backbone

	return, ApplyDarkCorrection( DataSet, Modules, Backbone)

end


