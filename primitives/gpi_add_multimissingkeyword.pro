;+
; NAME: gpi_add_multimissingkeyword
; PIPELINE PRIMITIVE DESCRIPTION: Add multi missing keywords.
; Useful for test data,...
;
; OUTPUTS:

; PIPELINE ARGUMENT: Name="keyword1" Type="string"  Default="FILTER" Desc="Enter keyword name to add."
; PIPELINE ARGUMENT: Name="value1" Type=""  Default="H" Desc="Enter value of the keyword to add."
; PIPELINE ARGUMENT: Name="keyword2" Type="string"  Default="OBSTYPE" Desc="Enter keyword name to add."
; PIPELINE ARGUMENT: Name="value2" Type=""  Default="Xenon" Desc="Enter value of the keyword to add."
; PIPELINE COMMENT: Add any missing keyword. (use this function several times in the DRF if you need to add more than one keyword)
; PIPELINE ORDER: 1.18
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE SEQUENCE: 
;
; HISTORY:
;    Jerome Maire 2009-09-13
;   2009-09-17 JM: added DRF parameters
;-

function gpi_add_multimissingkeyword,  DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id$' ; get version from subversion to store in header history
 ;  getmyname, functionname
 @__start_primitive
 
  thisModuleIndex = Backbone->GetCurrentModuleIndex()  
   if tag_exist( Modules[thisModuleIndex], "keyword1") && tag_exist( Modules[thisModuleIndex], "value1") then $
   FXADDPAR, *(dataset.headers)[numfile], Modules[thisModuleIndex].keyword1, Modules[thisModuleIndex].value1
     if tag_exist( Modules[thisModuleIndex], "keyword2") && tag_exist( Modules[thisModuleIndex], "value2") then $
   FXADDPAR, *(dataset.headers)[numfile], Modules[thisModuleIndex].keyword2, Modules[thisModuleIndex].value2
   
   
  thisModuleIndex = Backbone->GetCurrentModuleIndex()

   
   return, ok
;writefits, fname, specpos,h

end
