;+
; NAME:  gpi_open_help
;
; INPUTS:
;	path		Path name for HTML file to open, relative to
;				documentation root
; KEYWORDS:
;	/dev		open the development version
;	/gpilib		open gpilib help instead of pipeline help
; OUTPUTS:
;
; HISTORY:
;	Began 2013-08-05 12:09:03 by Marshall Perrin 
;-


PRO gpi_open_help, path, dev=dev, gpilib=gpilib

; assemble html help URL:
if keyword_set(gpilib) then begin
	gpi_help_root = 'http://docs.planetimager.org/gpilib'
endif else begin
	gpi_help_root = 'http://docs.planetimager.org/pipeline'
endelse

if keyword_set(dev) then gpi_help_root += '_dev'

;if ~strmatch(path, '*.html') then path +=".html"

URL = gpi_help_root + "/" + path


mg_open_url, URL

end
