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
;-


FUNCTION gpi_datestr, jd=jd, current=current
	compile_opt defint32, strictarr, logical_predicate

	if ~(keyword_set(jd)) and ~(keyword_set(current)) then begin
		message,/info, 'called without specifying either JD or CURRENT; guessing you want the current date? '
		current=1
	endif

	if keyword_set(current) then begin
	    ; FIXME be more careful here about UTC vs local time?
        ;caldat,systime(/julian,/utc),month,day,year, hour,minute,second
        ;datestr = string(year mod 100,month,day,format='(i2.2,i2.2,i2.2)')
        datestr = string(systime(/julian,/utc),format = '(C(CYI2.2,CMOI2.2,CDI2.2))')

	endif else if keyword_set(jd) then begin
		message, 'Not implemented yet!'

	endif


	return, datestr

end
