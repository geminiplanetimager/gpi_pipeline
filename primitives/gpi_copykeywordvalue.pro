;+
; NAME: gpi_copykeywordvalue
; PIPELINE PRIMITIVE DESCRIPTION: Copy keyword values to another keyword.
; Useful for test data. Should not often be needed for science data.
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
; PIPELINE ORDER: 0.12
; PIPELINE CATEGORY: Testing
;
; HISTORY:
;    Jerome Maire 2010-03
;    2013-07-11 MP: Documentation cleanup.
;   
;-

function gpi_copykeywordvalue,  DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
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
     

valuesource=backbone->get_keyword(keywordsource, count=cs)

if keywordtarget ne '' then $
valuetarget=backbone->get_keyword(keywordtarget, count=ct) 

        if (ct eq 0) || ((ct ne 0) && (overwrite eq 1)) then begin 
            backbone->set_keyword,keywordtarget, valuesource
            backbone->set_keyword,'HISTORY',functionname+":"+keywordtarget+" keyword value changed.",ext_num=0
        endif
     
  endfor
  
    if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=Modules[thisModuleIndex].suffix
  
@__end_primitive
end
