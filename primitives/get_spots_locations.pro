;+
; NAME: get_spots_locations
; PIPELINE PRIMITIVE DESCRIPTION: Load satellite spot locations  
;
;	
;	
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	/Save	Set to 1 to save the output image to a disk file. 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Get spots locations in calibration file 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="spotloc" Default="GPI-spotloc.fits" Desc="Filename of spot locations calibration file to be read"
; PIPELINE ORDER: 2.45
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;- 

function get_spots_locations, DataSet, Modules, Backbone
;common PIP
;COMMON APP_CONSTANTS

calfiletype='spotloc'
@__start_primitive
;	getmyname, functionname
;
;   	; save starting time
;   	T = systime(1)
;
; 	;;get fluxcal file
;	thisModuleIndex = Backbone->GetCurrentModuleIndex()
;    c_File = (Modules[thisModuleIndex].CalibrationFile)
; 
;        if strmatch(c_File, 'AUTOMATIC',/fold) then begin
;        dateobs=strcompress(sxpar( *(dataset.headers)[numfile], 'DATE-OBS',  COUNT=cc1),/rem)
;        timeobs=strcompress(sxpar( *(dataset.headers)[numfile], 'TIME-OBS',  COUNT=cc2),/rem)
;          dateobs2 =  strc(sxpar(*(dataset.headers)[numfile], "DATE-OBS"))+" "+strc(sxpar(*(dataset.headers)[numfile],"TIME-OBS"))
;          dateobs3 = date_conv(dateobs3, "J")
;        
;        filt=strcompress(sxpar( *(dataset.headers)[numfile], 'FILTER',  COUNT=cc3),/rem)
;        prism=strcompress(sxpar( *(dataset.headers)[numfile], 'DISPERSR',  COUNT=cc4),/rem)
;        gpicaldb = Backbone_comm->Getgpicaldb()
;        c_File = gpicaldb->get_best_cal( 'spotloc', dateobs3, filt,prism)
;   endif
;    
;    ;drpPushCallStack, functionName
;    if (file_test( c_File ) EQ 0 ) then $
;       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Spot locations File  ' + $
;                      strtrim(string(c_File),2) + ' not found.' )
    pmd_fluxcalFrame        = ptr_new(READFITS(c_File, HeaderCalib, /SILENT))

   spotloc =*pmd_fluxcalFrame
   SPOTWAVE=strcompress(sxpar( HeaderCalib, 'SPOTWAVE',  COUNT=cc4),/rem)

	;hdr= *(dataset.headers)[0]
 sxaddpar, *(dataset.headers[numfile]), "SPOTWAVE", SPOTWAVE, "Wavelength of ref for SPOT locations"
 
sxaddpar, *(dataset.headers[numfile]), "PSFCENTX", spotloc[0,0], "x-locations of PSF Center"
sxaddpar, *(dataset.headers[numfile]), "PSFCENTY", spotloc[0,1], "y-locations of PSF Center"
for ii=1,(size(spotloc))[1]-1 do begin
  sxaddpar, *(dataset.headers[numfile]), "SPOT"+strc(ii)+'x', spotloc[ii,0], "x-locations of spot #"+strc(ii)
  sxaddpar, *(dataset.headers[numfile]), "SPOT"+strc(ii)+'y', spotloc[ii,1], "y-locations of spot #"+strc(ii)  
endfor

  sxaddhist, functionname+": Loaded satellite spot locations", *(dataset.headers[numfile])
  sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
;drpPushCallStack, functionName
return, ok


end
