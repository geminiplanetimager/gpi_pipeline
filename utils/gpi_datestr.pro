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
;-


FUNCTION gpi_datestr, jd=jd, current=current

	if ~(keyword_set(jd)) and ~(keyword_set(current)) then begin
		message,/info, 'called without specifying either JD or CURRENT; guessing you want the current date? '
		current=1
	endif

	if keyword_set(current) then begin
	    ; FIXME be more careful here about UTC vs local time?
        caldat,systime(/julian),month,day,year, hour,minute,second
        datestr = string(year mod 100,month,day,format='(i2.2,i2.2,i2.2)')
	endif else if keyword_set(jd) then begin
		message, 'Not implemented yet!'

	endif


	return, datestr

end
