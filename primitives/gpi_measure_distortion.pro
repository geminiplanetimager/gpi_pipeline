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
; PIPELINE ORDER: 2.44
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;       Switched sxaddpar to backbone->set_keyword 01.31.2012 Dmitry Savransky
;- 

function gpi_measure_distortion, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

  cubef3D=*(dataset.currframe[0])

;;;PUT YOUR CODE HERE for distortion measurement
;;the following code is a hard-coded measurement of the distortion made by Quinn
;; based on Dec.10th 2012 piholes data
      a = DBLARR(21)
      a[0] = 0.012829132      
      a[1] = 0.99785766   
      a[2] = -0.0025138799  
      a[3] = -2.9363537e-06   
      a[4] = 4.0838655e-06
      a[5] = 8.6704596e-07   
      a[6] = 2.0875084e-09  
      a[7] = -7.3038816e-08  
      a[8] = -4.4049383e-08   
      a[9] = 2.5314827e-08
      a[10] = -4.8459488e-10   
      a[11] = 5.3338987e-10  
      a[12] = -3.7203296e-10   
      a[13] = 8.1742126e-10  
      a[14] = -5.7992610e-10
      a[15] = -1.9259339e-12   
      a[16] = 1.3236841e-11   
      a[17] = 1.1932603e-11  
      a[18] = -8.3725183e-13  
      a[19] = -1.2386457e-11
      a[20] = -1.3324329e-12
     
      
      b = DBLARR(21)
      b[0] = 0.041555827   
      b[1] = -0.0024815303       
      b[2] = 1.0019879  
      b[3] = -1.2697275e-05  
      b[4] = -1.0826337e-05
      b[5] = -6.3283901e-06  
      b[6] = -1.3677509e-09  
      b[7] = -1.9630077e-08   
      b[8] = 3.8928093e-08   
      b[9] = 4.9045834e-08
      b[10] = -5.8777483e-11   
      b[11] = 2.3945722e-10  
      b[12] = -4.5031869e-11   
      b[13] = 6.4241092e-10   
      b[14] = 3.4429371e-11
      b[15] = 7.4537407e-13   
      b[16] = 1.5959833e-11  
      b[17] = -1.1553926e-11  
      b[18] = -2.3062054e-11   
      b[19] = 2.5627773e-12
      b[20] = -9.4071676e-13
      
      *(dataset.currframe[0])=[[a],[b]]
;;;

;*(dataset.currframe[0])=
suffix+='-distor'


  ; Set keywords for outputting files into the Calibrations DB

backbone->set_keyword, "FILETYPE", "Distortion Measurement", "What kind of IFS file is this?"
backbone->set_keyword,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'

@__end_primitive

end
