;+
; NAME: gpi_load_highres_psfs
; PIPELINE PRIMITIVE DESCRIPTION: Load High-Res PSFs
;
; 	Reads a high-res psf file.
; 	The high-res psf is stored using pointers into the common block.
;
; INPUTS: none
; OUTPUTS: none; mlens psf is loaded into memory
;
; PIPELINE COMMENT: Reads a high-res PSF file from disk. This primitive is required for PSF cube extraction.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type='String' CalFileType="mlenspsf" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ORDER: 0.5
; PIPELINE CATEGORY: PolarimetricScience,SpectralScience,Calibration
;
; HISTORY:
; 	Originally by Zachary Draper 2-28-14
;-

function gpi_load_highres_psfs, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'mlenspsf'
@__start_primitive


    ;open the mlens file. Save into common block variable.
    mlens = gpi_highres_microlens_psf_read_highres_psf_structure(c_File,[281,281,1])

    ;update header:
	backbone->set_keyword, "HISTORY", functionname+": get micro lens calibration file",ext_num=0
	backbone->set_keyword, "HISTORY", functionname+": "+c_File,ext_num=0

	backbone->set_keyword, "DRPMLPSF", c_File, "DRP wavelength calibration file used.", ext_num=0
	
	mlens_file = c_File
    
	;print file name used even when in automatic mode
	backbone->Log, "File used for High-Res PSF: "+c_File

@__end_primitive 

end
