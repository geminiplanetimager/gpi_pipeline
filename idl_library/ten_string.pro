;+
; NAME: ten_string
; PURPOSE:
; 	Does the same thing as the goddard IDL astro library's "ten" procedure
; 	(converts sexagesimal coords into decimal) but works on string arguments
; 	of the form "DD:MM:SS" or "DD MM SS".
;
; INPUTS:
; 	sixty_string	a sexagesimal string, possibly with sign.
; KEYWORDS:
; OUTPUTS:	
;   tenv			a decimal value representing degrees or hours
;
; HISTORY:
; 	Began 2002-08-14 21:01:48 by Marshall Perrin 
; 	2004-07-25	sixty_string may now be an array of strings.
;-

function ten_string,sixty_string

	tenvs = dblarr(n_elements(sixty_string) )
	
	for i=0l,n_elements(sixty_string)-1 do begin
		str = sixty_string[i]

		negloc = strpos("-",str) 
		if (negloc gt -1) then begin
			str = strmid(str,negloc+1)
			negativeflag=1
		endif else negativeflag = 0	

		parts = strsplit(str,"[: ]",/extract,/regex)
		if n_elements(parts) lt 3 then message,"This isn't a valid sexagesimal string: "+str
		tenv = ten(parts[0],parts[1],parts[2])
		if (negativeflag) then tenv = -1*tenv 
		tenvs[i]=tenv
	endfor

	if n_elements(tenvs) eq 1 then tenvs=tenvs[0]
	return,tenvs
end
