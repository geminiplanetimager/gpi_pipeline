
;+
; NAME: ApplyDarkCorrection
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Dark/Sky Background
;
;
; INPUTS: 
;
; KEYWORDS:
; 	CalibrationFile=	Name of dark file to subtract.
;
; OUTPUTS: 
; 	2D image corrected
;
; ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.
;
; PIPELINE COMMENT: Subtract a dark frame. 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="dark" Default="GPI-dark.fits"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-darksub" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.26
; PIPELINE TYPE: ALL
;
; HISTORY:
; 	Originally by Jerome Maire 2008-06
; 	2009-04-20 MDP: Updated to pipeline format, added docs. 
; 				    Some code lifted from OSIRIS subtradark_000.pro
;   2009-09-02 JM: hist added in header
;   2009-09-17 JM: added DRF parameters
;
function ApplyDarkCorrection, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'dark'
@__start_primitive
;;		common APP_CONSTANTS
;;		common PIP
;;	
;;	 	;thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
;;	
;;	  getmyname, functionname
;;	  thisModuleIndex = Backbone->GetCurrentModuleIndex()
;;	    c_File = Modules[thisModuleIndex].CalibrationFile
;;	
;;		if strmatch(c_File, 'AUTOMATIC',/fold) then c_File = (Backbone_comm->Getgpicaldb())->get_best_cal_from_header( 'dark', *(dataset.headers)[numfile] )
;;	;          dateobs2 =  strc(sxpar(*(dataset.headers)[numfile], "DATE-OBS"))+"T"+strc(sxpar(*(dataset.headers)[numfile],"TIME-OBS"))
;;	;          dateobs3 = date_conv(dateobs2, "J")
;;	;          itime=sxpar(*(dataset.headers)[numfile], "ITIME", count=ci)
;;	;          if ci eq 0 then itime=sxpar(*(dataset.headers)[numfile], "INTIME", count=ci)
;;	;  ;dateobs=strcompress(sxpar( *(dataset.headers)[numfile], 'DATE-OBS',  COUNT=cc),/rem)
;;	;        gpicaldb = Backbone_comm->Getgpicaldb()
;;	;        c_File = gpicaldb->get_best_cal( 'dark', dateobs3,itime=itime)
;;	;endif
;;	    if ( NOT file_test ( c_File ) ) then $
;;	       return, error ('ERROR IN CALL ('+strtrim(functionName)+'): Master dark ' + $
;;	                      strtrim(string(c_File),2) + ' not found.' )
;;	

	dark=readfits(c_File)
	*(dataset.currframe[0]) -= dark

  sxaddhist, functionname+": dark subtracted", *(dataset.headers[numfile])
  sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])

thisModuleIndex = Backbone->GetCurrentModuleIndex()
  if tag_exist( Modules[thisModuleIndex], "Save") && tag_exist( Modules[thisModuleIndex], "suffix") then suffix+=Modules[thisModuleIndex].suffix
  

  suffix = 'darksub'
@__end_primitive 

;;	    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;;	      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;;	      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, 'darksubtracted', display=display)
;;	      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;;	    endif else begin
;;	      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;;	          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
;;	    endelse
;;	
;;		return, ok
end
