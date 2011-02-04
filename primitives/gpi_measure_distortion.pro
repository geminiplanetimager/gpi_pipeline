;+
; NAME: gpi_measure_distortion
; PIPELINE PRIMITIVE DESCRIPTION: Measure GPI distortion from grid pattern
;
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Measure GPI distortion from grid pattern
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="spotsnbr" Type="int" Range="[1,4]" Default="4" Desc="How many spots in a slice of the datacube? "
; PIPELINE ORDER: 2.44
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;- 

function gpi_measure_distortion, DataSet, Modules, Backbone
primitive_version= '$Id: gpi_measure_distortion.pro 78 2011-01-06 18:58:45Z maire $' ; get version from subversion to store in header history
@__start_primitive

  cubef3D=*(dataset.currframe[0])


*(dataset.currframe[0])=
suffix+='-distor'


  ; Set keywords for outputting files into the Calibrations DB
  sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Distortion Measurement", "What kind of IFS file is this?"
  sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'

@__end_primitive

end
