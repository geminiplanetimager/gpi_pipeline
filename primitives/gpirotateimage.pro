;+
; NAME: gpirotateimage
; PIPELINE PRIMITIVE DESCRIPTION: Rotate 2d image (90,180,270deg)
;
;
; INPUTS: 
;
; KEYWORDS:
;
; OUTPUTS: 
;     2D image rotated
;
; ALGORITHM TODO: do it for 3d datacube
;
; PIPELINE COMMENT: Rotate a 2d image (90,180,270deg)
; PIPELINE ARGUMENT: Name="Direction" Type="int" Range="[0,3]" Default="1" Desc="Rotation Counterclockwise:0=None,1=90deg,2=180deg,3=270deg"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-rot" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.2
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE SEQUENCE: 
;
; HISTORY:
;     Originally by Jerome Maire 2010-02-12
;
function gpirotateimage, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
 
    rot_dir=uint(Modules[thisModuleIndex].Direction)
    *(dataset.currframe[0]) = rotate(*(dataset.currframe[0]),rot_dir)

    sxaddhist, functionname+": "+strc(rot_dir), *(dataset.headersPHU[numfile])
  

    if tag_exist( Modules[thisModuleIndex], "Save") && tag_exist( Modules[thisModuleIndex], "suffix") then suffix+=Modules[thisModuleIndex].suffix
  

@__end_primitive
;;    	
;;    	    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;;    	      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;;    	      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
;;    	      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;;    	    endif else begin
;;    	      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;;    	          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
;;    	    endelse
;;    	
;;    		return, ok
end
