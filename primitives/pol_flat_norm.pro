;+
; NAME: pol_flat_norm
; PIPELINE PRIMITIVE DESCRIPTION: Normalize polarimetry flats
;
; INPUTS: data-cube
;
; KEYWORDS:
;	/Save	set to 1 to save the output image to a disk file. 
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS:NAXES,NAXISi,FILETYPE,ISCALIB
; OUTPUTS:  datacube with slice at the same wavelength
;
; PIPELINE COMMENT: Normalize a polarimetry-mode flat field to unity.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 3.1992
; PIPELINE TYPE: ALL/POL
; PIPELINE SEQUENCE: 31-
;
; HISTORY:
; 	2009-06-20: JM created
; 	2009-07-22: MDP added doc header keywords
;   2009-09-17 JM: added DRF parameters
;   2009-10-09 JM added gpitv display
;   2011-07-30 MP: Updated for multi-extension FITS
;-

function pol_flat_norm, DataSet, Modules, Backbone
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




suffix='polflat'
@__end_primitive
end
