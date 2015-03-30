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
    currdir = gpi_get_setting('gpi_startup_dir',/silent)
    if strc(currdir) eq "ERROR" then currdir = gpi_get_directory('GPI_DATA_ROOT')
    if strc(currdir) ne "ERROR" then cd, gpi_expand_path(currdir)

    o = obj_new('launcher', _extra=_extra)
end
