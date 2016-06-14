;+
; NAME: gpi_normalize_polarimetry_flat_field
; PIPELINE PRIMITIVE DESCRIPTION: Normalize polarimetry flat field
;
; INPUTS: polarimetry data-cube with flat lamp
; OUTPUTS:  Normalized polarimetry mode flat field
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS:NAXES,NAXISi,FILETYPE,ISCALIB
;
; PIPELINE COMMENT: Normalize a polarimetry-mode flat field to unity.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="type" Type="string" Range="[basic|lsf]" Default="basic" Desc="Basic flats or Low Spatial Frequency?"
; PIPELINE ORDER: 3.1992
; PIPELINE CATEGORY: Calibration
;
; HISTORY:
; 	2009-06-20: JM created
; 	2009-07-22: MDP added doc header keywords
;   2009-09-17 JM: added DRF parameters
;   2009-10-09 JM added gpitv display
;   2011-07-30 MP: Updated for multi-extension FITS
;-

function gpi_normalize_polarimetry_flat_field, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

  ;cube=*(dataset.currframe[0])

	;sz = size(cube)
  sz = size(*(dataset.currframe))

  for pol=0,1 do begin
	  ;wg = where(finite(cube[*,*,pol]), fct)
	  (*(dataset.currframe))[*,*,pol] /= median( (*(dataset.currframe))[*,*,pol] )
  endfor


	;*(dataset.currframe[0])=cube

	; FIXME
	;;TO DO: complete header
	backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
    backbone->set_keyword, "FILETYPE", "Flat Field", "What kind of IFS file is this?"
    backbone->set_keyword, "NAXIS", sz[0]
    backbone->set_keyword, "NAXIS1", sz[1]
    backbone->set_keyword, "NAXIS2", sz[2]
    backbone->set_keyword, "NAXIS3", sz[3]


  if tag_exist( Modules[thisModuleIndex], "type") then type=strupcase(Modules[thisModuleIndex].type) else type='BASIC'

  case type of
    'BASIC': begin
      suffix='polflat'
      backbone->set_keyword, "FILETYPE", "Flat Field", "What kind of IFS file is this?"
      end
    'LSF': begin
      suffix='lsf_polflat'
      backbone->set_keyword, "FILETYPE", "Low Spatial Frequency Polarimetry flat field", "What kind of IFS file is this?"
      end
   endcase

@__end_primitive
end
