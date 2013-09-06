;+
; NAME: gpi_subtract_dark_background
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Dark Background
;
;    Look up from the calibration database what the best dark file of
;    the correct time is, and subtract it. 
;
;    If no dark file of the correct time is found, then don't do any
;    subtraction at all, just return the input data. 
;
; INPUTS: raw 2D image file
;
; OUTPUTS: 2D image corrected for dark current
;
; ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.
;
; PIPELINE COMMENT: Subtract a dark frame. 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="filename" Default="AUTOMATIC" Desc="Name of dark file to subtract"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.1
; PIPELINE TYPE: ALL
; PIPELINE NEWTYPE: ALL
;
; HISTORY:
; 	Originally by Jerome Maire 2008-06
; 	2009-04-20 MDP: Updated to pipeline format, added docs. 
; 				    Some code lifted from OSIRIS subtradark_000.pro
;   2009-09-02 JM: hist added in header
;   2009-09-17 JM: added DRF parameters
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2012-07-20 MP: added DRPDARK keyword
;   2012-12-13 MP: Remove "Sky" from primitve discription since it's inaccurate
;   2013-07-11 MP: rename 'applydarkcorrection' -> 'subtract_dark_background' for consistency
;
;-
function gpi_subtract_dark_background, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'dark'
no_error_on_missing_calfile = 1 ; don't fail this primitive completely if there is no cal file found.
@__start_primitive


	if file_test(string(c_File)) then begin
		dark = gpi_readfits(c_File)
	  
		*(dataset.currframe[0]) -= dark
		backbone->set_keyword,'HISTORY',functionname+": dark subtracted using file=",ext_num=0
		backbone->set_keyword,'HISTORY',functionname+": "+c_File,ext_num=0
		backbone->set_keyword,'DRPDARK',c_File,ext_num=0
	endif else begin
		backbone->Log, "***WARNING***: No dark file of appropriate time found. Therefore not subtracting any dark."
		backbone->set_keyword,'HISTORY',functionname+ "  ***WARNING***: No dark file of appropriate time found. Therefore not subtracting any dark."
	endelse
	  

  	suffix = 'darksub'
@__end_primitive 


end
