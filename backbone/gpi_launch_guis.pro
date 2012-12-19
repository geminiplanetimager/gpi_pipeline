;+
; NAME:  gpi_launch_guis
;
; 	Master startup routine for graphical interfaces for GPI
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2010-04-26 19:12:44 by Marshall Perrin 
; 	2012-12-18: renamed from launch_drp for consistency
;-

PRO gpi_launch_guis, _extra=_extra
	o = obj_new('launcher', _extra=_extra)
end
