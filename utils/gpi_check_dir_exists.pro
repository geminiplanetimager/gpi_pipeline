;+
; NAME: gpi_check_dir_exists
;
;	Check a directory exists and is writeable. If not, optionally create it or else
;	query the user whether it should be created, based on the 
;	prompt_user_for_outputdir_creation pipeline setting
;
; INPUTS: s_OutputDir		string name for output directory
; OUTPUTS:	returns 0 if OK, -1 if NOT_OK
;
; HISTORY:
;	Began 2013-10-08 00:20:32 by Marshall Perrin 
;	2013-11-03 Updated to provide distinct error messages for nonexistent and
;				 read-only cases. 
;-

function gpi_check_dir_exists, s_OutputDir
	OK = 0
	NOT_OK = -1


	if file_test(s_OutputDir,/directory, /write) then return, OK
	

	if ~file_test(s_OutputDir,/directory) then begin
		; directory does not exist at all.
		; Perhaps we should automatically create it:
		if gpi_get_setting('prompt_user_for_outputdir_creation',/bool) then $
            res =  dialog_message('The requested output directory '+s_OutputDir+' does not exist. Should it be created now?', $
            title="Nonexistent Output Directory", /question) else res='Yes'

        if res eq 'Yes' then begin
            file_mkdir, s_OutputDir
        endif else begin
			return, error("FAILURE: Directory "+s_OutputDir+" does not exist.",/alert)
		endelse
	endif


	if ~file_test(s_OutputDir,/directory,/write) then begin
		; directory exists but is not writeable

        res =  dialog_message('The requested output directory '+s_OutputDir+' exists but is not writeable. Please check and adjust file permissions and try again.', $
            title="Output Directory is Read-Only", /error) 

		return, error("FAILURE: Directory "+s_OutputDir+" cannot be written to.",/alert)
	endif



	return, OK

end
