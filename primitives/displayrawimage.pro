;+
; NAME: displayrawimage
; PIPELINE PRIMITIVE DESCRIPTION: Display raw data with GPItv
;
; 		display in GPITV the raw image to be processed
;
;
; KEYWORDS:
; 	gpitv=		session number for the GPITV window to display in.
; 				set to '0' for no display, or >=1 for a display.
;
; OUTPUTS:
;
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="1" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE COMMENT: Display, with GPItv, raw data to be processed  
; PIPELINE ORDER: 1.1 
; PIPELINE TYPE: ALL HIDDEN
;
;
; HISTORY:
; 	Originally by Jerome Maire 2007-11
;   2008-04-02 JM: spatial summation window centered on pixel and interpolation on the zem. comm. wav. vector
;	  2008-06-06 JM: adapted to pipeline inputs
;	  2009-04-15 MDP: Documentation updated
;   2009-09-17 JM: added DRF parameters
;-
function displayrawimage, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
;;	common PIP
;;	COMMON APP_CONSTANTS
;;	
;;	
;;	   functionName = 'displayrawimage'
;;	
 det=*(dataset.frames[numfile])
 ;thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
;;		thisModuleIndex = Backbone->GetCurrentModuleIndex()
 
 sesnum=fix(Modules[thisModuleIndex].gpitv)
 Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
 ;if (sesnum ne 0) then gpitvms, det, ses=sesnum


;drpPushCallStack, functionName
return, ok

end

