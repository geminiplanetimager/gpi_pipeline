;+
; NAME: gpi_divide_by_polarized_flat_field
; PIPELINE PRIMITIVE DESCRIPTION: Divide by Polarized Flat Field
;
; INPUTS: data-cube
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: HISTORY
; OUTPUTS:  datacube with slice flat-fielded
;
; PIPELINE COMMENT: Divides a 2-slice polarimetry file by a flat field.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="String" CalFileType="polflat" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 3.5
; PIPELINE NEWTYPE: PolarimetricScience, Calibration
;
;
; HISTORY:
;   2009-07-22: MDP created
;   2009-09-17 JM: added DRF parameters
;   2009-10-09 JM added gpitv display
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2011-07-30 MP: Updated for multi-extension FITS
;   2013-07-12 MP: Rename for consistency
;   2013-12-16 MP: CalibrationFile argument syntax update. 
;-

function gpi_divide_by_polarized_flat_field, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='flat'
@__start_primitive

    polflat = gpi_readfits(c_File)

    ; error check sizes of arrays, etc. 
    if ~ array_equal( (size(*(dataset.currframe[0])))[1:3], (size(polflat))[1:3]) then $
        return, error('FAILURE ('+functionName+'): Supplied flat field and data cube files do not have the same dimensions')

    ; update FITS header history
    backbone->set_keyword,'HISTORY', functionname+": dividing by flat",ext_num=0
    backbone->set_keyword,'HISTORY', functionname+": "+c_File,ext_num=0

    *(dataset.currframe) /= polflat

@__end_primitive
end
