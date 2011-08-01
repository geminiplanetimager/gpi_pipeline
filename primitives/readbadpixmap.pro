;+
; NAME: readbadpixmap
; PIPELINE PRIMITIVE DESCRIPTION: Load bad pixel map
;
;     Reads a wbad-pixel map file from disk.
;     The bad-pixel map is stored using pointers into the common block.
;
; KEYWORDS:
;     CalibrationFile=    Filename of the desired bad-pixel map file to
;                         be read
; GEM/GPI KEYWORDS:
; DRP KEYWORDS:HISTORY
; OUTPUTS: none
;
; PIPELINE COMMENT: Reads a bad-pixel map file from disk. 
; PIPELINE ARGUMENT: Name="CalibrationFile" type="badpix" default="GPI-badpix.fits" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ORDER: 0.02
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Originally by Jerome Maire 2009-07
;   2009-09-02 JM: hist added in header     
;   2009-09-17 JM: added DRF parameters
;   2010-10-19 JM: split HISTORY keyword if necessary
;-

function readbadpixmap, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='badpix'
@__start_primitive

    pmd_badpixmapFrame        = ptr_new(READFITS(c_File, Header, /SILENT))
    badpixmap=*pmd_badpixmapFrame

; sxaddhist, functionname+": Loaded bad pixel map", *(dataset.headers[numfile])
; sxaddhist, functionname+": "+Modules[thisModuleIndex].CalibrationFile, *(dataset.headers[numfile])
    fxaddpar,*(dataset.headers[numfile]),'HISTORY',functionname+": Loaded bad pixel map"
    fxaddpar,*(dataset.headers[numfile]),'HISTORY',functionname+": "+c_File


return, ok
end
