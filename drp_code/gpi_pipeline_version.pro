;+
; NAME:  gpi_pipeline_version
;
; OUTPUTS: Return the current pipeline version number
;
; HISTORY:
; 	Began 2010-05-22 11:56:33 by Marshall Perrin 
;
;	0.6:
;	0.65: 		most of 2010 development? not really updated.
;
;	2011-08-01:		version 0.70
;			 		multi-extension FITS format adopted for consistency with Gemini.
;
;-

function gpi_pipeline_version
version = '0.71'
return, version
end
