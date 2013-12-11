;+
; NAME: gpi_pad_wavelength_calibration_edges
; PIPELINE PRIMITIVE DESCRIPTION: Pad Wavelength Calibration Edges
;
; INPUTS: 3D wavcal 
;
;
; PIPELINE COMMENT:  pads the outer edges of the wavecal via extrapolation to cover lenslets whose spectra only partially fall on the detector field of view.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: Save output to disk, 0: Don't save"
; PIPELINE ARGUMENT: Name="gpitvim_dispgrid" Type="int" Range="[0,500]" Default="15" Desc="1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display "
; PIPELINE ORDER: 4.6
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
;
; HISTORY:
;   2013-11-28 MP: Created.
;-

function gpi_pad_wavelength_calibration_edges,  DataSet, Modules, Backbone
primitive_version= '$Id: gpi_combine_wavelength_calibrations.pro 1715 2013-07-17 18:56:52Z mperrin $' ; get version from subversion to store in header history
@__start_primitive


	; Assumption: The current frame must be a wavelength calibration file. No checking done here yet.

	; First we perform the padding to handle lenslets that fall only partially on the detector FOV.
	padded = gpi_wavecal_extrapolate_edges(*dataset.currframe)
	*dataset.currframe = padded
	backbone->set_keyword, 'HISTORY',  functionname+": Extrapolated/padded edges to provide approximate solutions for spectra only partially on the detector." 

	; Now the wavecal is done and ready to be saved.	
	; We handle this a bit differently here than is typically done via __end_primitive,
	; because we want to make use of some nonstandard display hooks to show the wavecal (optionally).
	

@__end_primitive_wavecal

end
