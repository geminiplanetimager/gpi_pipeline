;+
; NAME: readwavcal
; PIPELINE PRIMITIVE DESCRIPTION: Load Wavelength Calibration
;
; 	Reads a wavelength calibration file from disk.
; 	The wavelength calibration is stored using pointers into the common block.
;
; KEYWORDS: DATE-OBS,TIME-OBS,FILTER,DISPERSR
; INPUTS:	CalibrationFile=	Filename of the desired wavelength calibration file to
; 						be read
; OUTPUTS: none
;
; PIPELINE COMMENT: Reads a wavelength calibration file from disk. This primitive is required for any data-cube extraction.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="wavcal" Default="GPI-wavcal.fits" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ORDER: 0.01
; PIPELINE TYPE: ALL-SPEC
;
; HISTORY:
; 	Originally by Jerome Maire 2008-07
; 	Documentation updated - Marshall Perrin, 2009-04
;   2009-09-02 JM: hist added in header
;   2009-09-17 JM: added DRF parameters
;   2010-03-15 JM: added automatic detection
;-

function readwavcal, DataSet, Modules, Backbone

calfiletype = 'wavecal'
@__start_primitive


;common PIP
;COMMON APP_CONSTANTS


    ;getmyname, functionName

   ; save starting time
   ;T = systime(1)

    ;; identify and get the wavecal solution needed:  
    ;thisModuleIndex = Backbone->GetCurrentModuleIndex()
    ;c_File = (Modules[thisModuleIndex].CalibrationFile)
    ;can be automatic detection based on data keywords:
	;if strmatch(c_File, 'AUTOMATIC',/fold) then c_File = (Backbone_comm->Getgpicaldb())->get_best_cal_from_header( 'wavecal', *(dataset.headers)[numfile] )
;    if strmatch(c_File, 'AUTOMATIC',/fold) then begin
;;        dateobs=strcompress(sxpar( *(dataset.headers)[numfile], 'DATE-OBS',  COUNT=cc1),/rem)
;;        timeobs=strcompress(sxpar( *(dataset.headers)[numfile], 'TIME-OBS',  COUNT=cc2),/rem)
;        dateobs2 =  strc(sxpar(*(dataset.headers)[numfile], "DATE-OBS"))+"T"+strc(sxpar(*(dataset.headers)[numfile],"TIME-OBS"))
;        dateobs3 = date_conv(dateobs2, "J")        
;        filt=strcompress(sxpar( *(dataset.headers)[numfile], 'FILTER',  COUNT=cc3),/rem)
;        prism=strcompress(sxpar( *(dataset.headers)[numfile], 'DISPERSR',  COUNT=cc4),/rem)
;        gpicaldb = Backbone_comm->Getgpicaldb()
;        c_File = gpicaldb->get_best_cal( 'wavecal', dateobs3, filt,prism)
;   endif
    ;error handling:
    ;if (file_test( c_File ) EQ 0 ) then $
       ;return, error('ERROR IN CALL ('+strtrim(functionName)+'): Wave Cal File  ' + $
                      ;strtrim(string(c_File),2) + ' not found.' )
	
    ;open the wavecal file:
    pmd_wavcalFrame        = ptr_new(READFITS(c_File, Header, /SILENT))
    wavcal=*pmd_wavcalFrame


;    pmd_wavcalIntFrame     = ptr_new(READFITS(c_File, Header, EXT=1, /SILENT))
;    pmd_wavcalIntAuxFrame  = ptr_new(READFITS(c_File, Header, EXT=2, /SILENT))

    ;update header:
    sxaddhist, functionname+": get wav. calibration file", *(dataset.headers[numfile])
    sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])


@__end_primitive 

end
