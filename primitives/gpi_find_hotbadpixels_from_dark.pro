;+
; NAME: gpi_find_hotbadpixels_from_dark
; PIPELINE PRIMITIVE DESCRIPTION: Find hot pixels from dark images
;
;
;
; KEYWORDS:
; DRP KEYWORDS: FILETYPE,ISCALIB
; OUTPUTS:
;
; PIPELINE COMMENT: Find hot pixels with dark images with I gt threshold*mean(image), deliver a badpix map (hot pixel =1, 0 elsewhere)
; PIPELINE ARGUMENT: Name="threshold" Type="float" Range="[0.,100.]" Default="0.7" Desc="deviation from mean intensity, see routine description"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.3
; PIPELINE TYPE: CALIBRATION
; PIPELINE SEQUENCE: 

;
; HISTORY:
;   2009-07-20 JM: created
;   2009-09-17 JM: added DRF parameters
;-
function gpi_find_hotbadpixels_from_dark, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id$' ; get version from subversion to store in header history
   ;functionName = 'gpi_find_hotbadpixels_from_dark'
@__start_primitive
   ; save starting time
   T = systime(1)





badpixmap=bytarr(2048,2048)

 det=*(dataset.currframe[0])
 
 ;  if numext eq 0 then h= *(dataset.headers)[numfile] else h= *(dataset.headersPHU)[numfile]
 ;  header=*(dataset.headers[0])
 ;   units=double(SXPAR( h, 'UNITS'))
    
 thisModuleIndex = Backbone->GetCurrentModuleIndex()
threshold=float(Modules[thisModuleIndex].nbdev)

meandet = mean(det)


hotbadpixind = where(det ge (nbdev)*meandet,chbp)



badpixmap[hotbadpixind]=1

suffix='-darkbadpix'
*(dataset.currframe[0])=badpixmap

  thisModuleIndex = Backbone->GetCurrentModuleIndex()
;  if numext eq 0 then begin
;    sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Bad Pixel Map", "What kind of IFS file is this?"
;    sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
;  endif else begin
    sxaddpar, *(dataset.headersPHU[numfile]), "FILETYPE", "Bad Pixel Map", "What kind of IFS file is this?"
    sxaddpar, *(dataset.headersPHU[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
 ; endelse
 
;    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
;      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;    endif else begin
;      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;         ; gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
;         Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
;    endelse
;return, ok

end

