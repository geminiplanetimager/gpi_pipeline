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
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.2
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE NEWTYPE: Testing
; PIPELINE SEQUENCE: 
;
; HISTORY:
;     Originally by Jerome Maire 2010-02-12
;     2012-10-15 MP: Don't change suffix of file - this is just a rotation,
;						doesn't really change the type of file.
;
function gpirotateimage, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
 
    rot_dir=uint(Modules[thisModuleIndex].Direction)
    *(dataset.currframe[0]) = rotate(*(dataset.currframe[0]),rot_dir)
	backbone->set_keyword,'HISTORY', functionname+": Rotating image, direction="+strc(rot_dir),ext_num=0


    sxaddhist, functionname+": "+strc(rot_dir), *(dataset.headersPHU[numfile])
  
  

@__end_primitive
end
