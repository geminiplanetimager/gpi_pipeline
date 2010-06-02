;+
; NAME: gpi_add_missingkeyword
; PIPELINE PRIMITIVE DESCRIPTION: Add missing keyword.
; Useful for test data,...
;
; OUTPUTS:

; PIPELINE ARGUMENT: Name="keyword" Type="string"  Default="" Desc="Enter keyword name to add."
; PIPELINE ARGUMENT: Name="value" Type="string"  Default="" Desc="Enter value of the keyword to add."
; PIPELINE COMMENT: Add any missing keyword. (use this function several times in the DRF if you need to add more than one keyword)
; PIPELINE ORDER: 1.17
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE SEQUENCE: 
;
; HISTORY:
;    Jerome Maire 2009-09-13
;   2009-09-17 JM: added DRF parameters
;-

function gpi_add_missingkeyword,  DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


   functionName = 'gpi_add_missingkeyword'
 
  thisModuleIndex = Backbone->GetCurrentModuleIndex()  
   if tag_exist( Modules[thisModuleIndex], "keyword") && tag_exist( Modules[thisModuleIndex], "value") then $
   FXADDPAR, *(dataset.headers)[numfile], Modules[thisModuleIndex].keyword, Modules[thisModuleIndex].value
   
   
  thisModuleIndex = Backbone->GetCurrentModuleIndex()

   
   return, ok
;writefits, fname, specpos,h

end
