;+
; NAME: gpi_create_lenslet_flat_field
; PIPELINE PRIMITIVE DESCRIPTION: Create Lenslet Flat Field
;
;	Creates a simple derived flat field for non-uniform transmission in the
;	lenslets.
;
;	WARNING: experimental code, probably not yet ready for prime time.
;
; INPUTS: Flat lamp data
; OUTPUTS: 2D lenslet flat field file
;
; PIPELINE COMMENT: Create a 2D flat field for wavelength-independent lenslet throughput variations.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 3.1992
; PIPELINE CATEGORY: Calibration
;
; HISTORY:
;    2014-01-02 MP: Created 
;-

function gpi_create_lenslet_flat_field, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive


  sz = size(*(dataset.currframe))


  backbone->Log, "Creating lenslet flat field -- experimental code, may not work right! --"
  ; Median combine and throw out the extreme channels
  ;
  backbone->Log, "WARNING - hard coded for K1 band channels right now!"
  ;
  flat2 = median( (*dataset.currframe)[*,*,4:16], dim=3)

  flat2 /= median(flat2)

  ; hack to remove the curvy W but also kills all other low freq variations
  smoothed = median(flat2, 7) 
  flat3 = flat2 - (smoothed - median(smoothed))

  atv, [[[flat2]],[[flat3]]],/bl



	backbone->set_keyword, "HISTORY", 'Created 2D lenslet flat from filtered, collapsed image cube'


  *dataset.currframe  =  flat3



  stop
	;*(dataset.currframe[0])=cube

	; FIXME
	sz = size(flat3)
	;;TO DO: complete header
	backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
    backbone->set_keyword, "FILETYPE", "Lenslet Flat Field", "What kind of IFS file is this?"
    backbone->set_keyword, "NAXIS",  2
    backbone->set_keyword, "NAXIS1", sz[1]
	backbone->set_keyword, "NAXIS2", sz[2]
    backbone->del_keyword, "NAXIS3"




suffix='lensletflat'
@__end_primitive
end
