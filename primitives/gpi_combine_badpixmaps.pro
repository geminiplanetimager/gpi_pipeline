;+
; NAME: gpi_combine_badpixmap
; PIPELINE PRIMITIVE DESCRIPTION: Combine bad pixel maps
;
; This routine is used to do an "AND" combination of badpix maps extracted from several bands.
;
; INPUTS: bad pixel maps 
;
; OUTPUTS:
; PIPELINE ORDER: 4.02
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="combmethod" Type="string" Range="OR|AND" Default="OR" Desc="Combination of badpix maps: OR|AND"
; PIPELINE COMMENT: This routine is used to do an AND or OR combination of badpix maps (badpix=1, elsewhere=0) extracted from several bands.
; PIPELINE TYPE: CAL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
;    Jerome Maire 2009-08-10
;   2009-09-17 JM: added DRF parameters
;-


function gpi_combine_badpixmaps,  DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS

primitive_version= '$Id$' ; get version from subversion to store in header history

   getmyname, functionName
   
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
  nfiles=dataset.validframecount


   sz=size(*(dataset.frames[0]))
   
   badpixcomb=bytarr(sz[1],sz[2])

if tag_exist( Modules[thisModuleIndex], "combmethod")&& ( Modules[thisModuleIndex].combmethod eq 'OR' ) then begin
   for n=0,nfiles-1 do badpixcomb= logical_or(badpixcomb,  accumulate_getimage( dataset, n))
endif else begin
   for n=0,nfiles-1 do badpixcomb= logical_and(badpixcomb,  accumulate_getimage( dataset, n))
endelse
;TO DO: put method in Log, 
*(dataset.currframe[0])=badpixcomb

  thisModuleIndex = Backbone->GetCurrentModuleIndex()
suffix+='-comb'

  ; Set keywords for outputting files into the Calibrations DB
  sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Bad Pixel Map", "What kind of IFS file is this?"
  sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'

;TODO header update
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
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
