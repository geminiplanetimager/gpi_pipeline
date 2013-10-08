;+
; NAME: gpi_check_dir_exists
;
;	Check a directory exists. If not, optionally create it or else
;	query the user whether it should be created, based on the 
;	prompt_user_for_outputdir_creation pipeline setting
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;	Began 013-10-08 00:20:32 by Marshall Perrin 
;-

function gpi_check_dir_exists, s_OutputDir
    COMMON APP_CONSTANTS


	if ~file_test(s_OutputDir,/directory, /write) then begin

		if gpi_get_setting('prompt_user_for_outputdir_creation',/bool, default=1) then $
            res =  dialog_message('The requested output directory '+s_OutputDir+' does not exist. Should it be created now?', $
            title="Nonexistent Output Directory", /question) else res='Yes'

        if res eq 'Yes' then begin
            file_mkdir, s_OutputDir
        endif else begin
			return, error("FAILURE: Directory "+s_OutputDir+" does not exist or is not writeable.",/alert)
		endelse
	endif

	return, OK

end
