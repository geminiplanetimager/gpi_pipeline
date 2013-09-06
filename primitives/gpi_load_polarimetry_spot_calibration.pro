;+
; NAME: gpi_load_polarimetry_spot_calibration
; PIPELINE PRIMITIVE DESCRIPTION: Load Polarimetry Spot Calibration
;
;   Reads a polarimetry spot calibration file from disk.
;   The spot calibration is stored using pointers into the common block.
;
; OUTPUTS: none
;
; PIPELINE COMMENT: Reads a pol spot calibration file from disk. This primitive is required for any polarimetry data-cube extraction.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="polcal" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ORDER: 0.51
; PIPELINE NEWTYPE: PolarimetricScience,Calibration
;
; HISTORY:
;   2013-01-28 MMB: Adapted to pol extraction (based on readwavcal.pro)
;   2013-02-07 MP:  Updated logging and docs a little bit.
;                   Added efficiently not reloading the same file multiple times.
;   2013-06-04 JBR: shifts for flexure code is now moved to
;                   update_shifts_for_flexure.pro and commented out here.
;   2013-07-10 MP:  Documentation update and code cleanup. 
;   2013-07-17 MP:  Rename for consistency
;-

function gpi_load_polarimetry_spot_calibration, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'polcal'
@__start_primitive

  need_to_load=1
	; Check common block for already loaded calibration information
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

    backbone->set_keyword, "HISTORY", functionname+": Read calibration file",ext_num=0
    backbone->set_keyword, "HISTORY", functionname+": "+c_File,ext_num=0
    backbone->set_keyword, "DRPPOLCF", c_File, "DRP pol spot calibration file used.", ext_num=0

@__end_primitive 

end
