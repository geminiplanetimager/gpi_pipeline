;+
; NAME:  gpi_datestr
;
;	Return a date string as used for organizing data by
;	date, i.e. for the raw or reduced data or the DRFs
;
; INPUTS:
; 	jd=		Specify a given JD to convert to a date string
; KEYWORDS:
; 	/current	Return the date string for the current time
; OUTPUTS:
;
; HISTORY:
; 	Began 2012-02-06 13:16:16 by Marshall Perrin 
;  2012-07-20  Switched to UTC for consistency with file writing, now
;              using exact same code as used in assemble_ifs_path
;  2013-11-12  Implemented Gemini's policy for date increments at 2 pm
;			   Chilean local time. (Savransky, Perrin.)
;-


FUNCTION gpi_datestr, jd=jd, current=current
	compile_opt defint32, strictarr, logical_predicate

	if ~(keyword_set(jd)) and ~(keyword_set(current)) then begin
		message,/info, 'called without specifying either JD or CURRENT; guessing you want the current date? '
		current=1
	endif

	if keyword_set(current) then begin


		if gpi_get_setting('at_gemini',default=0,/silent) then begin
			; Rules for selecting current date and time at the observatory are
			; such that it won't increment in the middle of the night. 
			
			;; get the current date and time of day
			;; the day increments at 1400 local Chilean time, regardless of 
			;; whether it's standard or daylight time
			currtime = systime(/jul)
			tod = double(string(currtime,format = '(C(CHI2.2))'))
			if tod ge 14d0 then currtime += 1d0

			datestr = string(currtime,format = '(C(CYI2.2,CMOI2.2,CDI2.2))') 

		endif else begin
			; Simple UTC date for anywhere else. 
	        datestr = string(systime(/julian,/utc),format = '(C(CYI2.2,CMOI2.2,CDI2.2))')
		endelse


	endif else if keyword_set(jd) then begin
		message, 'Not implemented yet!'

	endif


	return, datestr

end
