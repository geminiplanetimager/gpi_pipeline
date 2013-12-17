;+
; NAME: gpi_get_user_info 
;	Get username and hostname in a cross platform compatible way. 
;
; INPUTS:	None
; KEYWORDS: None
; OUTPUTS:
;		user		username
;		computer	computer hostname
;
; HISTORY:
;	Began 2013-12-17 14:47:05 by Marshall Perrin 
;-

PRO gpi_get_user_info, user, computer
	if !version.os_family eq 'Windows' then begin
		user = getenv('USERNAME')
		computer = getenv('COMPUTERNAME')
	endif else begin
		user = getenv('USER')
		computer = getenv('HOST')
	endelse

end


