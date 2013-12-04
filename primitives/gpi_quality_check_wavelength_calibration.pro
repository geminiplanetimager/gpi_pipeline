;+
; NAME: gpi_quality_check_wavelength_calibration
; PIPELINE PRIMITIVE DESCRIPTION: Quality Check Wavelength Calibration
;
; INPUTS: 3D wavcal 
;

; PIPELINE COMMENT: Performs a basic quality check on a wavecal based on the statistical distribution of measured inter-lenslet spacings. 
; PIPELINE ARGUMENT: Name="error_action" Type="string" Range="[Fail|Ask_user]" Default="Ask_user" Desc="If the quality check fails, should the recipe immediately fail or should I alert the user and ask what they want to do?"
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[-1,100]" Default="-1" Desc="-1 = No display; 0 = New (unused) window; else = Window number to display diagnostic plot."
; PIPELINE ORDER: 4.5
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
;
; HISTORY:
;   2013-11-28 MP: Created.
;-

function gpi_quality_check_wavelength_calibration,  DataSet, Modules, Backbone
primitive_version= '$Id: gpi_combine_wavelength_calibrations.pro 1715 2013-07-17 18:56:52Z mperrin $' ; get version from subversion to store in header history
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "display") then display=fix(Modules[thisModuleIndex].display) else display=-1
	if tag_exist( Modules[thisModuleIndex], "error_action") then error_action=strupcase(strc(Modules[thisModuleIndex].error_action)) else error_action='FAIL'


	; Assumption: The current frame must be a wavelength calibration file

    if display ne -1 then begin
        if display eq 0 then window,/free else select_window, display
		noplots=0
	endif else noplots=1

	check_ok = gpi_sanity_check_wavecal(*dataset.currframe, noplots=noplots)

	if keyword_set(check_ok) then begin
		  backbone->set_keyword, 'HISTORY',  functionname+": Wavelength calibration passed basic statistical quality check" 

	endif else begin
		backbone->set_keyword, 'HISTORY',  functionname+": **WARNING** " 
		backbone->set_keyword, 'HISTORY',  functionname+": **WARNING** Wavelength calibration FAILED basic statistical quality check." 
		backbone->set_keyword, 'HISTORY',  functionname+": **WARNING** This file is probably no good and should not be used." 
		backbone->set_keyword, 'HISTORY',  functionname+": **WARNING** " 

		if error_action eq 'ASK_USER' then begin

			; dialog box here to ask the user what we should do.
			res =  dialog_message(['The wavelength calibration file just produced has failed its basic statistical quality check.',$
								   'This calibration is probably not usable. The most likely cause of this is inadequate S/N in',$
								   'the supplied arc lamp data. Do you want to keep this probably-bad calibration anyway? ',$
								   '',$
								   '       Select No to discard this file, Yes to save it anyway.'], $
                           title="Wavecal Quality Check Failed", /question,/center) 
			if strupcase(res) eq 'NO' then return, NOT_OK
 
		endif else begin
			; otherwise we just declare this whole reduction a failure
			return, NOT_OK
		endelse

	endelse


@__end_primitive

end
