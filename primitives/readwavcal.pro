;+
; NAME: readwavcal
; PIPELINE PRIMITIVE DESCRIPTION: Load Wavelength Calibration
;
; 	Reads a wavelength calibration file from disk.
; 	The wavelength calibration is stored using pointers into the common block.
;
; KEYWORDS: 
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: HISTORY
; INPUTS:	CalibrationFile=	Filename of the desired wavelength calibration file to
; 						be read
; OUTPUTS: none
;
; PIPELINE COMMENT: Reads a wavelength calibration file from disk. This primitive is required for any data-cube extraction.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="wavcal" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ORDER: 0.1
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: SpectralScience,Calibration
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
;-

function readwavcal, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'wavecal'
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
    wavcal = gpi_readfits(c_File,header=Header)


; manual shifts of the wavecal for correcting flexure effects
    directory = gpi_get_directory('calibrations_DIR') 

  if file_test(directory+path_sep()+"shifts.fits") then begin
                shifts=readfits(directory+path_sep()+"shifts.fits")
                shiftx=float(shifts[0])
                shifty=float(shifts[1])
        endif else begin
                shiftx=0.
                shifty=0.
        endelse
        
     wavcal[*,*,0]+=shifty
     wavcal[*,*,1]+=shiftx       
         backbone->set_keyword, "HISTORY", functionname+"Manual wavecal shift dx: "+strc(shiftx,format="(f7.2)"),ext_num=0
       backbone->set_keyword, "HISTORY", functionname+"Manual wavecal shift dy: "+strc(shifty,format="(f7.2)"),ext_num=0
 
;    pmd_wavcalIntFrame     = ptr_new(READFITS(c_File, Header, EXT=1, /SILENT))
;    pmd_wavcalIntAuxFrame  = ptr_new(READFITS(c_File, Header, EXT=2, /SILENT))

    ;update header:
;    sxaddhist, functionname+": get wav. calibration file", *(dataset.headers[numfile])
;    sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
backbone->set_keyword, "HISTORY", functionname+": get wav. calibration file",ext_num=0
backbone->set_keyword, "HISTORY", functionname+": "+c_File,ext_num=0
backbone->set_keyword, "DRPWVCLF", c_File, "DRP wavelength calibration file used.", ext_num=0

@__end_primitive 

end
