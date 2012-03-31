;+
; NAME: gpi_copykeywordvalue
; PIPELINE PRIMITIVE DESCRIPTION: Copy keyword value to an other keyword.
; Useful for test data,...
;
; OUTPUTS:
; PIPELINE ARGUMENT: Name="overwrite" Type="int"  Default="0" Desc="0:do not overwrite already existent keyword; 1:overwrite"
; PIPELINE ARGUMENT: Name="keyw_source_1" Type="string"  Default="OBJECT" Desc="Enter keyword name to copy its value to keyw_target_1."
; PIPELINE ARGUMENT: Name="keyw_target_1" Type="string"  Default="GCALLAMP" Desc="Enter keyword name that will receive value of keyw_source_1."
; PIPELINE ARGUMENT: Name="keyw_source_2" Type="string"  Default="OBJECT" Desc="Enter keyword name to copy its value to keyw_target_2."
; PIPELINE ARGUMENT: Name="keyw_target_2" Type="string"  Default="GCALSHUT" Desc="Enter keyword name that will receive value of keyw_source_2."
; PIPELINE ARGUMENT: Name="keyw_source_3" Type="string"  Default="OBJECT" Desc="Enter keyword name to copy its value to keyw_target_2."
; PIPELINE ARGUMENT: Name="keyw_target_3" Type="string"  Default="OBSTYPE" Desc="Enter keyword name that will receive value of keyw_source_2."
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-keyw" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE COMMENT: Copy keyword values to other keywords. 
; PIPELINE ORDER: 1.15
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE SEQUENCE: 
;
; HISTORY:
;    Jerome Maire 2010-03
;   
;-

function gpi_copykeywordvalue,  DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id$' ; get version from subversion to store in header history
    ;getmyname, functionname
    @__start_primitive
 
 overwrite=0  
   thisModuleIndex = Backbone->GetCurrentModuleIndex()  
 if tag_exist( Modules[thisModuleIndex], "overwrite") then overwrite=Modules[thisModuleIndex].overwrite
 

 tag = tag_names(Modules[thisModuleIndex])
 nkeyw = n_elements(where(strmatch(tag,'keyw_*', /fold)))
 for i=0,nkeyw/2-1 do begin
     keyw_source="keyw_source_"+strc(i+1)
     keyw_target="keyw_target_"+strc(i+1)

     indkeysource=where(strmatch(tag, keyw_source, /fold))
     keywordsource=Modules[thisModuleIndex].(indkeysource)
     indkeytarget=where(strmatch(tag, keyw_target, /fold))
     keywordtarget=Modules[thisModuleIndex].(indkeytarget)
     

;if numext eq 0 then hdr= *(dataset.headers)[numfile] else hdr= *(dataset.headersPHU)[numfile]
valuesource=backbone->get_keyword(keywordsource, count=cs); sxpar( hdr,keywordsource, count=cs)

;;if necessary, change/format hereafter the value of the keywordsource:
 
  ;;these change for UdeM test data:
;    if strmatch(keywordtarget,'OBSTYPE',/fold) then begin
;        if strmatch(valuesource, '*off*',/fold)  then valuesource='dark'
;        if strmatch(valuesource, '*xenon*',/fold) || strmatch(valuesource, '*argon*',/fold) then valuesource='wavecal'
;        if strmatch(valuesource, '*white*',/fold)  then valuesource='flat'
;    endif
;    if strmatch(keywordtarget,'OBJECT',/fold) then begin
;         valuesource='xenon on -2286'
;    endif

;  ;;these change to correct a badly calculated PA angle:
;  if i eq 0 then begin
;  valuesourceHA=double(sxpar( hdr,'HA', count=cs))
;  valuesource=gpiparangle(valuesourceHA,valuesource,ten_string('-30:14:26.7'))
;  print, 'new PA=',valuesource
;  endif

;;; end of the change
if keywordtarget ne '' then $
valuetarget=backbone->get_keyword(keywordtarget, count=ct) ;sxpar( hdr,keywordtarget, count=ct)

        if (ct eq 0) || ((ct ne 0) && (overwrite eq 1)) then begin 
            backbone->set_keyword,keywordtarget, valuesource
            backbone->set_keyword,'HISTORY',functionname+":"+keywordtarget+" keyword value changed.",ext_num=0
           ;FXADDPAR, hdr, keywordtarget, valuesource
        endif
     
  endfor
  
    if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=Modules[thisModuleIndex].suffix
  
;    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
;      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;    endif else begin
;      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
;          Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
;    endelse
;
;   
;   return, ok
;writefits, fname, specpos,h

      ; if numext eq 0 then *(dataset.headers)[numfile]=hdr else *(dataset.headersPHU)[numfile] =hdr
@__end_primitive
end
