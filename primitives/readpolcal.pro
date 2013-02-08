;+
; NAME: readpolcal
; PIPELINE PRIMITIVE DESCRIPTION: Load Polarimetry Spot Calibration
;
;   Reads a polarimetry spot calibration file from disk.
;   The spot calibration is stored using pointers into the common block.
;
; KEYWORDS: 
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: HISTORY
; INPUTS: CalibrationFile=  Filename of the desired pol spot calibration file to
;             be read
; OUTPUTS: none
;
; PIPELINE COMMENT: Reads a pol spot calibration file from disk. This primitive is required for any polarimetry data-cube extraction.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="polcal" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ORDER: 0.01
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: PolarimetricScience,Calibration
;
; HISTORY:
;   Originally by Jerome Maire 2008-07
;   Documentation updated - Marshall Perrin, 2009-04
;   2009-09-02 JM: hist added in header
;   2009-09-17 JM: added DRF parameters
;   2010-03-15 JM: added automatic detection
;   2010-08-19 JM: fixed bug which created new pointer everytime this primitive was called
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2013-01-28 MMB: Adapted to pol extraction (based on readwavcal.pro)
;   2013-02-07 MP: Updated logging and docs a little bit.
;                  Added efficiently not reloading the same file multiple times.
;-

function readpolcal, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'polcal'
@__start_primitive


    ;open the wavecal file:
    ;rmq: pmd_wavcalFrame not used after...
;    fits_info, c_File, n_ext=n_ext
;    if n_ext eq 0 then begin
;      if ~ptr_valid(pmd_wavcalFrame) then $
;      pmd_wavcalFrame        = ptr_new(READFITS(c_File, Header, /SILENT)) else $
;      *pmd_wavcalFrame = READFITS(c_File, Header, /SILENT)
;    endif else begin
;      if ~ptr_valid(pmd_wavcalFrame) then $
;      pmd_wavcalFrame        = ptr_new(MRDFITS(c_File, 1, Header, /SILENT)) else $
;      *pmd_wavcalFrame = MRDFITS(c_File, 1, Header, /SILENT)      
;    endelse
;    wavcal=*pmd_wavcalFrame
;    ptr_free, pmd_wavcalFrame

    need_to_load=1
    if keyword_set(polcal) then if tag_exist(polcal, 'filename') then if polcal.filename eq c_file then begin
        backbone->Log, "Requested pol cal file is already loaded, no need to load again.", depth=3
        backbone->Log, c_File
        need_to_load=0
    endif



    if need_to_load then begin

        fits_info, c_file, n_ext=numext, /silent
        Backbone->Log, "Loading polarimetry spot peak fit data",depth=3
        polspot_spotpos = readfits(c_File, ext=numext-2,/silent)
        Backbone->Log, "Loading polarimetry spot pixel coordinate table",depth=3
        polspot_coords = readfits(c_File, ext=numext-1,/silent)
        Backbone->Log, "Loading polarimetry spot pixel value table",depth=3

        polspot_pixvals = readfits(c_File, ext=numext,/silent)

        polcal={spotpos:polspot_spotpos, coords:polspot_coords, pixvals:polspot_pixvals, filename:c_File}
    endif
;    pmd_wavcalIntFrame     = ptr_new(READFITS(c_File, Header, EXT=1, /SILENT))
;    pmd_wavcalIntAuxFrame  = ptr_new(READFITS(c_File, Header, EXT=2, /SILENT))

    ;update header:
;    sxaddhist, functionname+": get wav. calibration file", *(dataset.headers[numfile])
;    sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
    backbone->set_keyword, "HISTORY", functionname+": Read calibration file",ext_num=0
    backbone->set_keyword, "HISTORY", functionname+": "+c_File,ext_num=0
    backbone->set_keyword, "DRPPOLCF", c_File, "DRP pol spot calibration file used.", ext_num=0

@__end_primitive 

end
