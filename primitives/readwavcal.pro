;+
; NAME: readwavcal
; PIPELINE PRIMITIVE DESCRIPTION: Load Wavelength Calibration
;
; 	Reads a wavelength calibration file from disk.
; 	The wavelength calibration is stored using pointers into the common block.
;
; KEYWORDS: 
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: HISTORY
; INPUTS:	CalibrationFile=	Filename of the desired wavelength calibration file to
; 						be read
; OUTPUTS: none
;
; PIPELINE COMMENT: Reads a wavelength calibration file from disk. This primitive is required for any data-cube extraction.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="wavcal" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ORDER: 0.1
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: SpectralScience,Calibration
;
; HISTORY:
; 	Originally by Jerome Maire 2008-07
; 	Documentation updated - Marshall Perrin, 2009-04
;   2009-09-02 JM: hist added in header
;   2009-09-17 JM: added DRF parameters
;   2010-03-15 JM: added automatic detection
;   2010-08-19 JM: fixed bug which created new pointer everytime this primitive was called
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2013-03-28 JM: added manual shifts of the wavecal
;-

function readwavcal, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'wavecal'
@__start_primitive


    ;open the wavecal file:
    wavcal = gpi_readfits(c_File,header=Header)


    ;update header:
    ;sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
	backbone->set_keyword, "HISTORY", functionname+": get wav. calibration file",ext_num=0
	backbone->set_keyword, "HISTORY", functionname+": "+c_File,ext_num=0

	backbone->set_keyword, "DRPWVCLF", c_File, "DRP wavelength calibration file used.", ext_num=0

@__end_primitive 

end
