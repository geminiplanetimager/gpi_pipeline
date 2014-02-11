;+
; NAME: gpi_divide_by_lenslet_flat_field
; PIPELINE PRIMITIVE DESCRIPTION: Divide by Lenslet Flat Field
;
; INPUTS: Spectral or polarization datacube
; OUTPUTS: Each slice of the input datacube is divided by the lenslet flat.
;
;
; PIPELINE COMMENT: Divides a spectral data-cube by a flat field data-cube.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="string" CalFileType="lensletflat" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.2
; PIPELINE CATEGORY: SpectralScience,PolarimetricScience,Calibration
;
; HISTORY:
;   2014-01-02 MP: New primitive
;-

function gpi_divide_by_lenslet_flat_field, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'lensletflat'
@__start_primitive
  
    lensletflat = gpi_readfits(c_File)

    ; error check sizes of arrays, wavelengths are consistent, etc. 
    if ~ array_equal( (size(*(dataset.currframe)))[1:2], (size(lensletflat))[1:2]) then $
        return, error('FAILURE ('+functionName+'): Supplied flat field and data cube files do not have the same dimensions')

    ; update FITS header history
    backbone->set_keyword, "HISTORY", functionname+": dividing by lenslet flat",ext_num=0
    backbone->set_keyword, "HISTORY", functionname+": "+c_File,ext_num=0
    backbone->set_keyword, "DRPLFLAT", c_File, "Lenslet flat field file used."

    ;not absolutely necessary but avoid divide by Nan or zero
    wnan=where(~finite(lensletflat),cc)
    if cc gt 0 then lensletflat[wnan]=1.
    wzero=where((lensletflat eq 0.),cz)
    if cz gt 0 then lensletflat[wzero]=1.


	data0 = *dataset.currframe

	sz = size(*dataset.currframe)

	for i=0L,sz[3]-1 do (*dataset.currframe)[*,*,i] /= lensletflat



	if cc gt 0 then (*dataset.currframe)[wnan]=!VALUES.F_NAN 
	if cz gt 0 then (*dataset.currframe)[wzero]=!VALUES.F_NAN


	;atv, [*dataset.currframe,data0],/bl
	;stop
  
@__end_primitive
end
