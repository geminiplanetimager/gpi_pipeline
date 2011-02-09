;+
; NAME: gpi_add_geminigpikeywords
; PIPELINE PRIMITIVE DESCRIPTION: Add Gemini and GPI keywords.
; Useful for test data,...
;
; OUTPUTS:
; PIPELINE ARGUMENT: Name="overwrite" Type="int"  Default="0" Desc="0:do not overwrite already existent keyword; 1:overwrite"
; PIPELINE ARGUMENT: Name="keyword1" Type="string"  Default="FILTER" Desc="Enter keyword name to add."
; PIPELINE ARGUMENT: Name="value1" Type="string"  Default="H" Desc="Enter value of the keyword to add."
; PIPELINE ARGUMENT: Name="keyword2" Type="string"  Default="OBSTYPE" Desc="Enter keyword name to add."
; PIPELINE ARGUMENT: Name="value2" Type="string"  Default="wavecal" Desc="Enter value of the keyword to add."
; PIPELINE ARGUMENT: Name="keyword3" Type="string"  Default="GCALLAMP" Desc="Enter keyword name to add."
; PIPELINE ARGUMENT: Name="value3" Type="string"  Default="Xenon" Desc="Enter value of the keyword to add."
; PIPELINE ARGUMENT: Name="keyword4" Type="string"  Default="PRISM" Desc="Enter keyword name to add."
; PIPELINE ARGUMENT: Name="value4" Type="string"  Default="Spectral" Desc="Enter value of the keyword to add."
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-keyw" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE COMMENT: Add GPI and Gemini missing keywords. 
; PIPELINE ORDER: 1.16
; PIPELINE TYPE: CAL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
;    Jerome Maire 2010-02
;   
;-

function gpi_add_geminigpikeywords,  DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id$' ; get version from subversion to store in header history
   ; getmyname, functionname
   @__start_primitive
 
 overwrite=0.  
   thisModuleIndex = Backbone->GetCurrentModuleIndex()  
 if tag_exist( Modules[thisModuleIndex], "overwrite") then overwrite=float(Modules[thisModuleIndex].overwrite)
 

 tag = tag_names(Modules[thisModuleIndex])
 nkeyw = n_elements(where(strmatch(tag,'keywo*', /fold)))
 for i=0,nkeyw-1 do begin
     keyw="keyword"+strc(i+1)
     val="value"+strc(i+1)
     indkey=where(strmatch(tag, keyw, /fold))
     keyword=Modules[thisModuleIndex].(indkey)
     indval=where(strmatch(tag, val, /fold))
     value=Modules[thisModuleIndex].(indval)
     

void=sxpar( *(dataset.headers)[numfile],keyword, count=cc)
     if ( cc ne 0)  then begin
        if overwrite eq 1. then begin 
           if tag_exist( Modules[thisModuleIndex], keyw) && tag_exist( Modules[thisModuleIndex], val) then $
           FXADDPAR, *(dataset.headers)[numfile], keyword, value
        endif
     endif else begin
            if tag_exist( Modules[thisModuleIndex], keyw) && tag_exist( Modules[thisModuleIndex], val) then $
           FXADDPAR, *(dataset.headers)[numfile], keyword, value
     endelse 
     
  endfor
  
    if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=Modules[thisModuleIndex].suffix
  
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
    endelse

   
   return, ok
;writefits, fname, specpos,h

end
