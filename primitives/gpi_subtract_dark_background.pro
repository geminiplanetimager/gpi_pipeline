;+
; NAME: gpi_subtract_dark_background
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Dark Background
;
;    Look up from the calibration database what the best dark file of
;    the correct time is, and subtract it. 
;
;    If no dark file of the correct time is found:
;		If the RequireExactMatch setting is 1, then 
; 		don't do any subtraction at all, just return the input data. 
;		Otherwise, find an available dark calibration that is
;		within a factor of 3 in exposure time, scale that, then
;		subtract it.
;
; INPUTS: raw 2D image file
;
; OUTPUTS: 2D image corrected for dark current
;
; ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.
;
; PIPELINE COMMENT: Subtract a dark frame. 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="filename" Default="AUTOMATIC" Desc="Name of dark file to subtract"
; PIPELINE ARGUMENT: Name="RequireExactMatch" Type="int" Range="[0,1]" Default="0" Desc="Must dark calibration file exactly match in integration time, or is scaling from a different exposure time allowed?"
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
;	2013-10-03 MP: Add RequireExactMatch option, enable scaling for non-matching exptimes
;
;-
function gpi_subtract_dark_background, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history

thisModuleIndex = Backbone->GetCurrentModuleIndex()
if tag_exist( Modules[thisModuleIndex], "RequireExactMatch") then RequireExactMatch=uint(Modules[thisModuleIndex].RequireExactMatch) else RequireExactMatch=0

if keyword_set(RequireExactMatch) then calfiletype = 'dark_exact' else  calfiletype = 'dark' 

no_error_on_missing_calfile = 1 ; don't fail this primitive completely if there is no cal file found.
@__start_primitive


	if file_test(string(c_File)) then begin
		backbone->set_keyword,'HISTORY',functionname+": dark subtracted using file=",ext_num=0
		backbone->set_keyword,'HISTORY',functionname+": "+c_File,ext_num=0
		backbone->set_keyword,'DRPDARK',c_File,ext_num=0

		dark = readfits(c_File, darkexthdr, ext=1)
		;darkhdr = headfits(c_File, ext=0)


		darktime = sxpar(darkexthdr, 'ITIME')
		mytime = backbone->get_keyword('ITIME', count=ct1)

		if darktime ne mytime then begin
			if keyword_set(requireExactMatch) then return, error("Dark time does not match science exposure time, but RequireExactMatch was set.")
			
			dark *= mytime/darktime
			backbone->set_keyword,'HISTORY',functionname+": Dark exposure time was "+strc(darktime),ext_num=0
			backbone->set_keyword,'HISTORY',functionname+": Scaled dark by "+strc(mytime/darktime),ext_num=0

		endif

	  
		*(dataset.currframe[0]) -= dark
	endif else begin
		backbone->Log, "***WARNING***: No dark file of appropriate time found. Therefore not subtracting any dark."
		backbone->set_keyword,'HISTORY',functionname+ "  ***WARNING***: No dark file of appropriate time found. Therefore not subtracting any dark."
	endelse
	  

  	suffix = 'darksub'
@__end_primitive 


end
