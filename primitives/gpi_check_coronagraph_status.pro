;+
; NAME: gpi_check_coronagraph_status
; PIPELINE PRIMITIVE DESCRIPTION:Check for closed-loop coronagraphic image
;
;	This primitive checks that the input file is in fact a coronagraphic image.
;	It is intended to be used in quicklook recipes that may encounter all sorts
;	of different data. 
;
;	Any following primitives will only be executed if the
;	image is in fact coronagraphic data. This is useful so the quicklook 
;	recipe can include satellite spots or contrast measurement primitives, 
;	which would generally cause the recipe to fail if they receive any
;	unocculted data. With this primitive added in the recipe before those
;	steps, they will just be skipped without producing any error messages. 
;
; INPUT: Any GPI FITS file
; OUTPUT: No change in that file; subsequent recipe processing steps are only executed if coronagraphic data is found. 
;
; PIPELINE COMMENT:  Check whether file represents a closed-loop  coronagraphic image.
; PIPELINE ARGUMENT: Name="err_on_false" Type="int"  Range="[0,1]" Default="0" Desc=" If false, 0: continue to next image; 1: Throw error"
; PIPELINE ORDER: 2.41
; PIPELINE CATEGORY: Calibration,SpectralScience,PolarimetricScience
;
; HISTORY:
;   2013-08-02 ds - initial version
;   2013-11-12 MP - add check for PUPVIEWR inserted
;- 

function gpi_check_coronagraph_status, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

err_on_false = fix(Modules[thisModuleIndex].err_on_false)
if err_on_false eq 1 then retval = NOT_OK else retval = GOTO_NEXT_FILE

;;we are only okay with the five well behaved apodizers
apodizer = backbone->get_keyword('APODIZER', count=ct)
if ct eq 0 then return, retval
val = strupcase(apodizer)
if (strpos(val,'_Y_') eq -1) &&  (strpos(val,'_J_') eq -1) &&  (strpos(val,'_H_') eq -1) && $
   (strpos(val,'_HL_') eq -1) && (strpos(val,'_K1_') eq -1) &&  (strpos(val,'_K2_') eq -1) then return,retval


;;we are only okay with one of the coronagraph science masks
fpm = backbone->get_keyword('OCCULTER', count=ct)
if ct eq 0 then return, retval
val = strupcase(fpm)
if (strpos(val,'_Y_') eq -1) &&  (strpos(val,'_J_') eq -1) &&  (strpos(val,'_H_') eq -1) && $
   (strpos(val,'_K1_') eq -1) &&  (strpos(val,'_K2_') eq -1) then return,retval

;;we are only okay with a real lyot stop
lyot = backbone->get_keyword('LYOTMASK', count=ct)
if ct eq 0 then return, retval
if strpos(lyot,'080') eq -1 then return,retval

aoon = backbone->get_keyword('AOON', count=ct)
if ct eq 0 then return, retval
if ~strcmp(strupcase(aoon),'TRUE') then return,retval

; are we looking at the back side of the pupil viewer fold?
pupviewer = backbone->get_keyword('PUPVIEWR',count=ct)
if ct eq 0 then return, retval
if fix(pupviewer) eq 1 then return, retval


return, OK

end
