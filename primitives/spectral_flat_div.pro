;+
; NAME: spectral_flat_div
; PIPELINE PRIMITIVE DESCRIPTION: Divide by Spectral Flat Field
;
; INPUTS: data-cube
;
; KEYWORDS:
;	/Save	set to 1 to save the output image to a disk file. 
;
; DRP KEYWORDS: HISTORY
; OUTPUTS:  datacube with slice at the same wavelength
;
; PIPELINE COMMENT: Divides a spectral data-cube by a flat field data-cube.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="specflat" Default="GPI-specflat.fits" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-rawspdc" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.2
; PIPELINE TYPE: ALL/SPEC
; PIPELINE SEQUENCE: 3-
;
; HISTORY:
; 	2009-08-27: JM created
;   2009-09-17 JM: added DRF parameters
;   2009-10-09 JM added gpitv display
;   2010-10-19 JM: split HISTORY keyword if necessary
;-

function spectral_flat_div, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'flat'
@__start_primitive

	specflat = readfits(c_File)

	; error check sizes of arrays, etc. 
	if not array_equal( (size(*(dataset.currframe[0])))[1:3], (size(specflat))[1:3]) then $
		return, error('FAILURE ('+functionName+'): Supplied flat field and data cube files do not have the same dimensions')

	; update FITS header history
;	sxaddhist, functionname+": dividing by flat", *(dataset.headers[numfile])
;	sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
  sxaddparlarge,*(dataset.headers[numfile]),'HISTORY',functionname+": dividing by flat"
  sxaddparlarge,*(dataset.headers[numfile]),'HISTORY',functionname+": "+c_File

	*(dataset.currframe[0]) /= specflat

;  if tag_exist( Modules[thisModuleIndex], "Save") && tag_exist( Modules[thisModuleIndex], "suffix") then suffix+=Modules[thisModuleIndex].suffix
  
@__end_primitive
end
