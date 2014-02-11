;+
; NAME: gpi_load_polarimetry_spot_calibration
; PIPELINE PRIMITIVE DESCRIPTION: Load Polarimetry Spot Calibration
;
;   Reads a polarimetry spot calibration file from disk.
;   The spot calibration is stored using pointers into the common block.
;
; INPUTS: Not used directly
; OUTPUTS: none; polarimetry spot cal file is loaded into memory
;
; PIPELINE COMMENT: Reads a pol spot calibration file from disk. This primitive is required for any polarimetry data-cube extraction.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="String" CalFileType="polcal" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ORDER: 0.51
; PIPELINE CATEGORY: PolarimetricScience,Calibration
;
; HISTORY:
;   2013-01-28 MMB: Adapted to pol extraction (based on readwavcal.pro)
;   2013-02-07 MP:  Updated logging and docs a little bit.
;                   Added efficiently not reloading the same file multiple times.
;   2013-06-04 JBR: shifts for flexure code is now moved to
;                   update_shifts_for_flexure.pro and commented out here.
;   2013-07-10 MP:  Documentation update and code cleanup. 
;   2013-07-17 MP:  Rename for consistency
;   2013-12-16 MP:  CalibrationFile argument syntax update. 
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
        polspot_spotpos = readfits(c_File, header,ext=numext-2,/silent)
        Backbone->Log, "Loading polarimetry spot pixel coordinate table",depth=3
        polspot_coords = readfits(c_File, ext=numext-1,/silent)
        Backbone->Log, "Loading polarimetry spot pixel value table",depth=3

        polspot_pixvals = readfits(c_File, ext=numext,/silent)
        
        polcal={spotpos:polspot_spotpos, coords:polspot_coords, pixvals:polspot_pixvals, filename:c_File}
    endif

    backbone->set_keyword, "HISTORY", functionname+": Read calibration file",ext_num=0
    backbone->set_keyword, "HISTORY", functionname+": "+c_File,ext_num=0
    backbone->set_keyword, "DRPPOLCF", c_File, "DRP pol spot calibration file used.", ext_num=0
    
    void=mrdfits(c_file, 0, headerphu, /silent)
    object=sxpar(headerphu, 'OBJECT')
    
    if strcmp(object,'TEL_SIM') then begin ;If using the telescope simulator use some basic options. 
      wc_elev=0
      wc_inport='perfect' ;J
    endif else begin
      ;get elevation amd port for flexure effect correction
      wc_elev = sxpar(  Header, 'ELEVATIO', count=count) 
      if count eq 0 then begin
        void=mrdfits(c_File, 0, headerphu,/silent)
        wc_elev = sxpar(  headerphu, 'ELEVATIO', count=count)
      endif
    
      wc_inport = sxpar(  Header, 'INPORT', count=count) 
      if count eq 0 then begin
        void=mrdfits(c_File, 0, headerphu,/silent)
        wc_inport= sxpar(  headerphu, 'INPORT', count=count)
      endif      
    endelse
    
    wc_date = sxpar(  Header, 'DATE-OBS', count=count) 
    if count eq 0 then begin
      void=mrdfits(c_File, 0, headerphu,/silent)
      wc_date= sxpar(  headerphu, 'DATE-OBS', count=count)
    endif
    
    backbone->set_keyword, "WVELEV", wc_elev, "Wavelength solution elevation", ext_num=0
    backbone->set_keyword, "WVPORT", wc_inport, "Wavelength solution inport", ext_num=0
    backbone->set_keyword, "WVDATE", wc_date, "Wavelength solution obstime", ext_num=0

@__end_primitive 

end
