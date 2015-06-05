;+
; NAME: gpi_convert_stokes_to_radial
; PIPELINE PRIMITIVE DESCRIPTION: Convert Stokes Cube to Radial
;
; Converts a stokes cube to a radial stokes cube
;

; INPUTS: data-cube
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: HISTORY
; OUTPUTS:  smoothed datacube
;
; PIPELINE COMMENT: Converts a stokes cube to a radial stokes cube
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="offset" Type="float" Range="[-360.,360]" Default="0" Desc="An offset in the theta used to calculate the radial stokes - for testing"
; PIPELINE ORDER: 3.5
; PIPELINE NEWTYPE: PolarimetricScience
;
;
; HISTORY:
;   2014-10-16 MMB created
;
;-

function gpi_convert_stokes_to_radial, DataSet, Modules, Backbone
  primitive_version= '$Id: gpi_smooth_cube.pro 2878 2014-04-29 04:11:51Z mperrin $' ; get version from subversion to store in header history
  @__start_primitive
 suffix = 'rstokesdc'
  
  psfcentx = backbone->get_keyword('PSFCENTX', count=ct1, indexFrame=indexFrame)
  psfcenty = backbone->get_keyword('PSFCENTY', count=ct2, indexFrame=indexFrame)
  
  if ct1+ct2 ne 2 then begin
    return, error("Could not get PSFCENTX and PSFCENTY keywords from header. Cannot determine PSF center.")
  endif
  im=*(dataset.currframe)
  q=im[*,*,1]
  u=im[*,*,2]
  indices, im[*,*,0], x,y,z
  
  phi=atan((y-psfcenty)/(x-psfcentx))+float(Modules[thisModuleIndex].offset)*!dtor 
  
  qr=Q*cos(2*phi)+U*sin(2*phi)
  ur=-Q*sin(2*phi)+U*cos(2*phi)
  
  im[*,*,1]=qr
  im[*,*,2]=ur

  *(dataset.currframe)=im
  
  backbone->set_keyword, "History", functionname+": Converted a stokes cube to a radial stokes cube", ext_num=0
  backbone->set_keyword, 'STKESTYP', 'RADIAL', ext_num=1
  ;suffix='radial'
  
  @__end_primitive
end
