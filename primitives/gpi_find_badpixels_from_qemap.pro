;+
; NAME: gpi_find_badpixels_from_qe_map
; PIPELINE PRIMITIVE DESCRIPTION: Find Bad pixels from darks or qe map
;
;
;
; KEYWORDS:
; DRP KEYWORDS: FILETYPE,ISCALIB
; OUTPUTS:
;
; PIPELINE COMMENT: Find hot/cold pixels from qe map. Find deviants with [Intensities gt (1 + nbdev) *  mean_value_of the frame] and [Intensities lt (1 - nbdev) *  mean_value_of the frame]. (bad pixel =1, 0 elsewhere)
; PIPELINE ARGUMENT: Name="nbdev" Type="float" Range="[0.,100.]" Default="0.7" Desc="Allowed maximum location fluctuation (in pixel) between adjacent mlens"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-qebadpix" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.3
; PIPELINE TYPE: CAL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   2009-07-20 JM: created
;   2009-09-17 JM: added DRF parameters
;-
function gpi_find_badpixels_from_qemap, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS

primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
   ;getmyname, functionname

   ; save starting time
   T = systime(1)


  thisModuleIndex = Backbone->GetCurrentModuleIndex()
nbdev=float(Modules[thisModuleIndex].nbdev)


badpixmap=bytarr(2048,2048)

 det=*(dataset.currframe[0])
 
meandet = mean(det)

badpixind = where(det le (1.-nbdev)*meandet,cbp)
hotbadpixind = where(det ge (1.+nbdev)*meandet,chbp)

if cbp ne 0 then badpixmap[badpixind]=1
if chbp ne 0 then badpixmap[hotbadpixind]=1


*(dataset.currframe[0])=badpixmap

    thisModuleIndex = Backbone->GetCurrentModuleIndex()
  if tag_exist( Modules[thisModuleIndex], "suffix") then suffix+=Modules[thisModuleIndex].suffix
  sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Bad Pixel Map", "What kind of IFS file is this?"
  sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
  
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
    endelse



return, ok

end

