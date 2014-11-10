;+
; NAME: gpi_load_instrumental_polarization_calibration
; PIPELINE PRIMITIVE DESCRIPTION:  Load Instrumental Polarization Calibration
;
;
; INPUT: not used
; OUTPUTS:  Instrumental polarization calibration is loaded into memory
;
; PIPELINE COMMENT: Load a calibration file for the instrumental polarization.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type='String' CalFileType="instpol" Default="AUTOMATIC" Desc="Filename of the desired instrumental polarization file to be read" 
; PIPELINE ORDER: 0.52
; PIPELINE CATEGORY: PolarimetricScience,Calibration
;
; HISTORY:
; 	2010-05-22 MDP: started
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2011-07-30 MP: Updated for multi-extension FITS
;   2013-07-16 MP: Renamed for consistency
;   2013-12-16 MP: CalibrationFile argument syntax update. 
;-  

function gpi_load_instrumental_polarization_calibration, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='instpol'   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.
@__start_primitive


	loadedcalfiles->load, c_file, calfiletype

    backbone->set_keyword,'HISTORY',functionname+": Loaded Instrumental Polarization:",ext_num=0
    backbone->set_keyword,'HISTORY',functionname+": "+c_File,ext_num=0

@__end_primitive

end
