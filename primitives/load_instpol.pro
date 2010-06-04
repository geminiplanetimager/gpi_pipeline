;+
; NAME: 
; PIPELINE PRIMITIVE DESCRIPTION:  Load Instrumental Polarization Calibration
;
; KEYWORDS:
;
; OUTPUTS:  
;
; PIPELINE COMMENT: 
; PIPELINE ARGUMENT: Name='suffix' type='string' default='default' Desc="choose the suffix"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="instpol" Default="GPI-instpol.fits" Desc="Filename of the desired instrumental polarization file to be read" ;
; PIPELINE ORDER: 0.1
; PIPELINE TYPE: ALL/POL
;
; HISTORY:
; 	2010-05-22 MDP: started
;-  

function save_output, DataSet, Modules, Backbone

calfiletype='instpol'   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.
@__start_primitive



	loadedcalfiles->load, c_file, calfiletype

 	sxaddhist, functionname+": Loaded Instrumental Polarization:", *(dataset.headers[numfile])
 	sxaddhist, functionname+": "+Modules[thisModuleIndex].CalibrationFile, *(dataset.headers[numfile])


@__end_primitive

end
