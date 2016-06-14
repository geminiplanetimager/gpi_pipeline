;+
; NAME: gpi_subtract_dark_background
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Dark Background
;
;	 Subtract background from an image using a dark file. 
;
;	 If CalibrationFile=AUTOMATIC, the best available dark is
;	 obtained from the calibration database. 
;    "Best dark" generally means a dark file that has the most similar
;    integration time and is closest in date & time of observation 
;    to the data in question.  
;
;    Specifically, in the Calibration Database code for darks, 
;    the algorithm first looks for dark files which are between
;    0.3 and 3x of the desired integration time. It takes all such
;    darks which are on the closest date of observation to the 
;    science data, and from those finds the one that is closest in
;    integration time to the science data. 
;
;    This dark is read in, rescaled by the appropriate ratio of
;    integration times, and then subtracted from the data. 
;
;
;
;	 Empirically, rescaling darks by too large a factor does not 
;	 result in very high quality subtractions, due to various nonlinear
;	 behaviors such as saturation of hot pixels and the so-called 
;	 'reset anomaly' effect which biases the readout background level.
;	 Hence we impose a limit for scaling the dark integration time 
;	 up or down, semi-arbitrarily chosen to be 3x because it seems to
;	 work reasonably well.  The standard set of darks planned to be 
;	 taken routinely at Gemini should ensure that there are always available
;	 darks within this range. 
;
;	 If you desire different behavior, simply set the CalibrationFile manually
;	 of course.
;    
;
;	 Note: If the RequireExactMatch setting is 1, then only dark files
;		exactly matching in integration time will be used. If there is no
;		such file, the data is returned without any subtraction.
;
; INPUTS: raw 2D image file
;
; OUTPUTS: 2D image corrected for dark current 
;
;
; PIPELINE COMMENT: Subtract a dark frame. 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="string" CalFileType="dark" Default="AUTOMATIC" Desc="Name of dark file to subtract"
; PIPELINE ARGUMENT: Name="RequireExactMatch" Type="int" Range="[0,1]" Default="0" Desc="Must dark calibration file exactly match in integration time, or is scaling from a different exposure time allowed?"
; PIPELINE ARGUMENT: Name="Interpolate" Type="int" Range="[0,1]" Default="0" Desc="Interpolate based on JD between prior and subsequent available darks"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.1
; PIPELINE CATEGORY: ALL
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
;   2013-12-16 MP: CalibrationFile argument syntax update. 
;   2014-03-22 MP: Adding experimental interpolation option.
;   2015-12-09 KBF: Propagate DQ frame
;-
function gpi_subtract_dark_background, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history

thisModuleIndex = Backbone->GetCurrentModuleIndex()
if tag_exist( Modules[thisModuleIndex], "RequireExactMatch") then RequireExactMatch=uint(Modules[thisModuleIndex].RequireExactMatch) else RequireExactMatch=0
if tag_exist( Modules[thisModuleIndex], "Interpolate") then Interpolate=uint(Modules[thisModuleIndex].Interpolate) else Interpolate=0

if keyword_set(RequireExactMatch) then calfiletype = 'dark_exact' else  calfiletype = 'dark' 

no_error_on_missing_calfile = 1 ; don't fail this primitive completely if there is no cal file found.
@__start_primitive
 if (size(*dataset.currframe))[2] ne 2048 then return, error('FAILURE ('+functionName+'): Dimension mismatch - check input image to make sure it is a 2048x2048 array.')  

	if ~keyword_set(interpolate) then begin
		; Regular subtraction of a single file


		if file_test(string(c_File)) then begin
			backbone->set_keyword,'HISTORY',functionname+": dark subtracted using file="
			backbone->set_keyword,'HISTORY',functionname+": "+c_File
			backbone->set_keyword,'DRPDARK',c_File,ext_num=0

			dark = readfits(c_File, darkexthdr, ext=1)
			darkdq = readfits(c_File, darkdqexthdr, ext=2, /silent)
			if darkdq[0] eq -1 then message, /info, 'No data quality extension in calibration frame. Assuming no flagged pixels exist.' 

			darktime = sxpar(darkexthdr, 'ITIME')
			mytime = backbone->get_keyword('ITIME', count=ct1)

			if darktime ne mytime then begin
				if keyword_set(requireExactMatch) then return, error("Dark time does not match science exposure time, but RequireExactMatch was set.")
				
				dark *= mytime/darktime
				backbone->set_keyword,'HISTORY',functionname+": Dark exposure time was "+strc(darktime),ext_num=0
				backbone->set_keyword,'HISTORY',functionname+": Scaled dark by "+strc(mytime/darktime),ext_num=0

			endif else begin
				backbone->set_keyword,'HISTORY',functionname+": Dark exposure time matches exactly, "+strc(darktime),ext_num=0
			endelse
                        
                        *dataset.currframe -= dark
			if darkdq[0] ne -1 then *dataset.currdq = *dataset.currdq OR darkdq
		endif else begin
			backbone->Log, "***WARNING***: No dark file of appropriate time found. Therefore not subtracting any dark."
			backbone->set_keyword,'HISTORY',functionname+ "  ***WARNING***: No dark file of appropriate time found. Therefore not subtracting any dark."
		endelse

	endif else begin

		; Get TWO dark files, one before and one after the science frame.
		; Interpolate between them based on JDs. 
		
		dark_fn_before = (backbone_comm->getgpicaldb())->get_best_cal_from_header( 'dark_before', *(dataset.headersphu)[numfile],*(dataset.headersext)[numfile] ) 
		dark_fn_after  = (backbone_comm->getgpicaldb())->get_best_cal_from_header( 'dark_after', *(dataset.headersphu)[numfile],*(dataset.headersext)[numfile] ) 
		dark_fn_before = gpi_expand_path(string(dark_fn_before))
		dark_fn_after = gpi_expand_path(string(dark_fn_after))
		if ~file_test(dark_fn_before) then return, error(functionname+": could not find prior dark file from calDB, "+strc(dark_fn_before))
		if ~file_test(dark_fn_after) then return, error(functionname+": could not find subsequent dark file from calDB, "+strc(dark_fn_after))
		backbone->set_keyword,'HISTORY',functionname+": dark subtracted using linear combination of prior & following darks."
		backbone->set_keyword,'HISTORY',functionname+": PRIOR - "+dark_fn_before
		backbone->set_keyword,'HISTORY',functionname+": AFTER - "+dark_fn_after
		dark_before = gpi_readfits(dark_fn_before, header=dark_before_exthdr, priheader=dark_before_prihdr)
		dark_after  = gpi_readfits(dark_fn_after,  header=dark_after_exthdr,  priheader=dark_after_prihdr)
		;;should add data quality frame propagation for this option sometime
		message, /info, 'Data quality propagation not currently supported for interpolate mode'
		dark_before_mjd = sxpar(dark_before_prihdr, 'MJD-OBS')
		dark_after_mjd = sxpar(dark_after_prihdr, 'MJD-OBS')
		my_mjd = backbone->get_keyword('MJD-OBS')
		
		dark_before_itime = sxpar(dark_before_exthdr, 'ITIME')
		dark_after_itime = sxpar(dark_after_exthdr, 'ITIME')
		my_itime = backbone->get_keyword('ITIME')

		; Scale darks to same exposure time as science data
		if dark_before_itime ne my_itime then dark_before *= my_itime / dark_before_itime
		if dark_after_itime  ne my_itime then dark_after  *= my_itime / dark_after_itime

		; weights based on linear interpolation between those two JDs.
		deltajd_before = my_mjd-dark_before_mjd
		deltajd_after =  dark_after_mjd-my_mjd

		weight_before = deltajd_after / (deltajd_after + deltajd_before)
		weight_after  = deltajd_before / (deltajd_after + deltajd_before)

		synthetic_dark = dark_before * weight_before + dark_after * weight_after 
		data0 = *dataset.currframe
		*dataset.currframe -= synthetic_dark
		backbone->set_keyword,'HISTORY',functionname+": created synthetic dark and subtracted."
		backbone->set_keyword,'DRPDARK','Interpolated between '+dark_fn_before+" and "+dark_fn_after,ext_num=0

		; testing:
		;atv, [[[data0-synthetic_dark]],[[data0-dark_before]],[[data0-dark_after]]],/bl


	endelse
		  

  	suffix = 'darksub'
@__end_primitive 


end
