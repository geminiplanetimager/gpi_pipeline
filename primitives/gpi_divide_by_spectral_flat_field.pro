;+
; NAME: gpi_divide_by_spectral_flat_field
; PIPELINE PRIMITIVE DESCRIPTION: Divide by Spectral Flat Field
;
; INPUTS: data-cube
;
;
; PIPELINE COMMENT: Divides a spectral data-cube by a flat field data-cube.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="specflat" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.2
; PIPELINE NEWTYPE: SpectralScience,Calibration
;
; HISTORY:
;     2009-08-27: JM created
;   2009-09-17 JM: added DRF parameters
;   2009-10-09 JM added gpitv display
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2011-07 JM: added check for NAN & zero
;   2012-10-11 MP: Added min/max wavelength checks
;   2012-10-17 MP: Removed deprecated suffix= keyword
;   2013-07-17 MP: Rename for consistency
;-

function gpi_divide_by_spectral_flat_field, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'flat'
@__start_primitive
  
    specflat = gpi_readfits(c_File)

    ; error check sizes of arrays, wavelengths are consistent, etc. 
    if ~ array_equal( (size(*(dataset.currframe[0])))[1:3], (size(specflat))[1:3]) then $
        return, error('FAILURE ('+functionName+'): Supplied flat field and data cube files do not have the same dimensions')

	minwavelength = backbone->get_keyword('DRP_WMIN', count=mincount)
	maxwavelength = backbone->get_keyword('DRP_WMAX', count=maxcount)
	if mincount gt 0 and maxcount gt 0 then begin
		cwv = get_cwv(filter)
		lstep = cwv.lambda[1] - cwv.lambda[0]
		if ((abs(min(cwv) - minwavelength) gt 0.05*lstep ) or $ 
		    (abs(max(cwv) - maxwavelength) gt 0.05*lstep )) then $
        	return, error('FAILURE ('+functionName+'): Supplied flat field and data cube files do not have the same min/max wavelength settings')
	endif



    ; update FITS header history
    backbone->set_keyword, "HISTORY", functionname+": dividing by flat",ext_num=0
    backbone->set_keyword, "HISTORY", functionname+": "+c_File,ext_num=0
    backbone->set_keyword, "DRPFLAT", c_File,ext_num=0

    ;not absolutely necessary but avoid divide by Nan or zero
    bordnan=where(~finite(specflat),cc)
    if cc gt 0 then specflat[bordnan]=1.
    bordzero=where((specflat eq 0.),cz)
    if cz gt 0 then specflat[bordzero]=1.

	*(dataset.currframe[0]) /= specflat

	if cc gt 0 then (*(dataset.currframe[0]))[bordnan]=!VALUES.F_NAN 
	if cz gt 0 then specflat[bordzero]=!VALUES.F_NAN

  
@__end_primitive
end
