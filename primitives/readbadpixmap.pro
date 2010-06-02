;+
; NAME: readbadpixmap
; PIPELINE PRIMITIVE DESCRIPTION: Load bad pixel map
;
; 	Reads a wbad-pixel map file from disk.
; 	The bad-pixel map is stored using pointers into the common block.
;
; KEYWORDS:
; 	CalibrationFile=	Filename of the desired bad-pixel map file to
; 						be read
; OUTPUTS: none
;
; PIPELINE COMMENT: Reads a bad-pixel map file from disk. 
; PIPELINE ARGUMENT: Name="CalibrationFile" type="badpix" default="GPI-badpix.fits" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ORDER: 0.02
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-07
;   2009-09-02 JM: hist added in header 	
;   2009-09-17 JM: added DRF parameters
;-

function readbadpixmap, DataSet, Modules, Backbone

calfiletype='badpix'
@__start_primitive

;;	common PIP
;;	COMMON APP_CONSTANTS
;;	
;;	
;;	 getmyname, functionname
;;	
;;	   ; save starting time
;;	   T = systime(1)
;;	
;;	   ;drpLog, 'Received data set: ' + DataSet.Name, /DRF, DEPTH = 1
;;	
;;	    ; get the badpix map
;;	    ;thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
;;		thisModuleIndex = Backbone->GetCurrentModuleIndex()
;;	    ;c_File = drpXlateFileName(Modules[thisModuleIndex].CalibrationFile)
;;	    c_File = (Modules[thisModuleIndex].CalibrationFile)
;;	    
;;		if strmatch(c_File, 'AUTOMATIC',/fold) then c_File = (Backbone_comm->Getgpicaldb())->get_best_cal_from_header( 'badpix', *(dataset.headers)[numfile] )
;;	;        if strmatch(c_File, 'AUTOMATIC',/fold) then begin
;;	;        dateobs=strcompress(sxpar( *(dataset.headers)[numfile], 'DATE-OBS',  COUNT=cc1),/rem)
;;	;        timeobs=strcompress(sxpar( *(dataset.headers)[numfile], 'TIME-OBS',  COUNT=cc2),/rem)
;;	;          dateobs2 =  strc(sxpar(*(dataset.headers)[numfile], "DATE-OBS"))+" "+strc(sxpar(*(dataset.headers)[numfile],"TIME-OBS"))
;;	;          dateobs3 = date_conv(dateobs3, "J")
;;	;        
;;	;;        filt=strcompress(sxpar( *(dataset.headers)[numfile], 'FILTER1',  COUNT=cc3),/rem)
;;	;;        prism=strcompress(sxpar( *(dataset.headers)[numfile], 'DISPERSR',  COUNT=cc4),/rem)
;;	;        gpicaldb = Backbone_comm->Getgpicaldb()
;;	;        c_File = gpicaldb->get_best_cal( 'badpix', dateobs3)
;;	;   endif
;;	    
;;	    
;;	    if ( NOT file_test ( c_File ) ) then $
;;	       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Bad pixel map File  ' + $
;;	                      strtrim(string(c_File),2) + ' not found.' )
;;		

    pmd_badpixmapFrame        = ptr_new(READFITS(c_File, Header, /SILENT))
    badpixmap=*pmd_badpixmapFrame


 sxaddhist, functionname+": get bad pixel map", *(dataset.headers[numfile])
 sxaddhist, functionname+": "+Modules[thisModuleIndex].CalibrationFile, *(dataset.headers[numfile])



return, ok
end
