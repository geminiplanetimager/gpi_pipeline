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
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="instpol" Default="GPI-instpol.fits" Desc="Filename of the desired instrumental polarization file to be read" 
; PIPELINE ORDER: 0.1
; PIPELINE TYPE: ALL/POL
;
; HISTORY:
; 	2010-05-22 MDP: started
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2011-07-30 MP: Updated for multi-extension FITS
;-  

function save_output, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='instpol'   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.
@__start_primitive


	loadedcalfiles->load, c_file, calfiletype

    fxaddpar,*(dataset.headersPHU[numfile]),'HISTORY',functionname+": Loaded Instrumental Polarization:"
    fxaddpar,*(dataset.headersPHU[numfile]),'HISTORY',functionname+": "+c_File

@__end_primitive

end
