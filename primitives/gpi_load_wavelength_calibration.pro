;+
; NAME: gpi_load_wavelength_calibration
; PIPELINE PRIMITIVE DESCRIPTION: Load Wavelength Calibration
;
; 	Reads a wavelength calibration file from disk.
; 	The wavelength calibration is stored using pointers into the common block.
;
; INPUTS: none
; OUTPUTS: none; wavecal is loaded into memory
;
; PIPELINE COMMENT: Reads a wavelength calibration file from disk. This primitive is required for any data-cube extraction.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type='String' CalFileType="wavecal" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ORDER: 0.5
; PIPELINE CATEGORY: SpectralScience,Calibration
;
; HISTORY:
; 	Originally by Jerome Maire 2008-07
; 	Documentation updated - Marshall Perrin, 2009-04
;   2009-09-02 JM: hist added in header
;   2009-09-17 JM: added DRF parameters
;   2010-03-15 JM: added automatic detection
;   2010-08-19 JM: fixed bug which created new pointer everytime this primitive was called
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2013-03-28 JM: added manual shifts of the wavecal
;   2013-04		   manual shifts code moved to new update_shifts_for_flexure
;   2013-07-10 MP: Documentation update and code cleanup
;   2013-07-16 MP: Rename file for consistency
;   2013-12-02 JM: get ELEVATIO and INPORT for later flexure correction
;   2013-12-16 MP: CalibrationFile argument syntax update. 
;-

function gpi_load_wavelength_calibration, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'wavecal'
@__start_primitive


    ;open the wavecal file. Save into common block variable.
    wavcal = gpi_readfits(c_File,header=Header)


    ;update header:
	backbone->set_keyword, "HISTORY", functionname+": get wav. calibration file",ext_num=0
	backbone->set_keyword, "HISTORY", functionname+": "+c_File,ext_num=0

	backbone->set_keyword, "DRPWVCLF", c_File, "DRP wavelength calibration file used.", ext_num=0
	
	;get elevation amd port for flexure effect correction
	  wc_elev = sxpar(  Header, 'ELEVATIO', count=count) 
	  if count eq 0 then begin
	      void=mrdfits(c_File, 0, headerphu,/silent)
	      wc_elev = sxpar(  headerphu, 'ELEVATIO', count=count)
	  endif
    backbone->set_keyword, "WVELEV", wc_elev, "Wavelength solution elevation", ext_num=0
    
        wc_inport = sxpar(  Header, 'INPORT', count=count) 
    if count eq 0 then begin
        void=mrdfits(c_File, 0, headerphu,/silent)
        wc_inport= sxpar(  headerphu, 'INPORT', count=count)
    endif
    backbone->set_keyword, "WVPORT", wc_inport, "Wavelength solution inport", ext_num=0
    
        wc_date = sxpar(  Header, 'DATE-OBS', count=count) 
    if count eq 0 then begin
        void=mrdfits(c_File, 0, headerphu,/silent)
        wc_date= sxpar(  headerphu, 'DATE-OBS', count=count)
    endif
    backbone->set_keyword, "WVDATE", wc_date, "Wavelength solution obstime", ext_num=0
    
@__end_primitive 

end
