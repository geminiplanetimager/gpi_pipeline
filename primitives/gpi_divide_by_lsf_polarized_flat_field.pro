;+
; NAME: gpi_divide_by_lsf_polarized_flat_field
; PIPELINE PRIMITIVE DESCRIPTION: Divide by Low Spatial Freq. Polarized Flat Field
;
;
;
; INPUTS: data-cube
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: HISTORY
; OUTPUTS:  datacube with slices flat-fielded
;
; PIPELINE COMMENT: Divides a 2-slice polarimetry file by a flat field.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="String" CalFileType="polflat" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.3
; PIPELINE CATEGORY: PolarimetricScience, Calibration
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

function gpi_divide_by_lsf_polarized_flat_field, DataSet, Modules, Backbone
  primitive_version= '$Id: gpi_divide_by_polarized_flat_field.pro 3912 2015-05-02 01:13:29Z Max $' ; get version from subversion to store in header history
  no_error_on_missing_calfile=1
  calfiletype='lsf_polflat'
  @__start_primitive
  
  ;Is there actually a good polflat?
  if file_test(string(c_File)) then begin
    polflat = gpi_readfits(c_File)

    if ~ array_equal( (size(*(dataset.currframe[0])))[1:3], (size(polflat))[1:3]) then $
      return, error('FAILURE ('+functionName+'): Supplied flat field and data cube files do not have the same dimensions')

    ; update FITS header history
    backbone->set_keyword,'HISTORY', functionname+": dividing by flat",ext_num=0
    backbone->set_keyword,'HISTORY', functionname+": "+c_File,ext_num=0

    *(dataset.currframe) /= polflat
  endif else begin
    backbone->Log, "***WARNING***: No LSF pol flat found. Therefore not dividing by any flat."
    backbone->set_keyword,'HISTORY',functionname+ "  ***WARNING***: No LSF pol flat found. Therefore not dividing by any flat."
  endelse

  @__end_primitive
end
