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
;	2012-02-01:		verion 0.8
;					Improved MEF file support, Gemini style keywords, major code
;					reorganization and cleanup. - MP
;	2012-08-08		The large number of improvements in the last few months
;					clearly justify a bump to at least 0.8.1...
;
;-

function gpi_pipeline_version
version = '0.9.0'
return, version
end
