;+
; NAME: displayrawimage
; PIPELINE PRIMITIVE DESCRIPTION: Display raw data with GPItv
;
; 		Display in GPITV the current raw image, before any processing
;
;
; KEYWORDS:
; 	gpitv=		session number for the GPITV window to display in.
; 				set to '0' for no display, or >=1 for a display.
;
; INPUTS: A raw 2D file.
; OUTPUTS: No change to data
;
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="1" Desc="1-500: choose gpitv session for displaying output, 0 for no display "
; PIPELINE COMMENT: Display, with GPItv, raw data to be processed  
; PIPELINE ORDER: 0.01
; PIPELINE NEWTYPE: ALL, HIDDEN
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
 
 sesnum=fix(Modules[thisModuleIndex].gpitv)
 Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)

return, ok

end

