;+
; NAME: gpi_check_data_quality
; PIPELINE PRIMITIVE DESCRIPTION: Check Data Quality 
;
;   This routine looks at various FITS header keywords to
;   assess whether the data should be considered usable or not. 
;
;   The keywords checked include GPIHEALT, AVGRNOT, RMSERR.
;   You can set the acceptable minimum data quality with the r0 and rmserr
;   parameters to this primitive. 
;
;   If a file of unacceptable quality is detected, the action taken will 
;   be determined by the "action" parameter:
;     0. Alert the user with a message printed to screen 
;        but allow reduction to continue
;     1. Halt the reduction and fail the receipe. 
;
;  TODO: implement pop-up window for alerts rather than just 
;        printing a message on screen
;
; INPUTS: 2D image file
; OUTPUTS: No change in data; reduction either continues or is terminated.
;
; GEM/GPI KEYWORDS:AVRGNOT,GPIHEALT,RMSERR
;
; PIPELINE COMMENT: Check quality of data based on header keywords. For bad data, can fail the reduction or simply alert the user.
; PIPELINE ARGUMENT: Name="Action" Type="int" Range="[0,10]" Default="1" Desc="0:Simple alert and continue reduction, 1:Reduction fails"
; PIPELINE ARGUMENT: Name="r0" Type="float" Range="[0,2]" Default="0.08" Desc="critical r0 [m] at lambda=0.5microns"
; PIPELINE ARGUMENT: Name="rmserr" Type="float" Range="[0,1000]" Default="10." Desc="Critical rms wavefront error in microns. "
; PIPELINE ORDER: 0.9
; PIPELINE NEWTYPE: ALL
;
; HISTORY:
;   JM 2010-10 : created
;   MP 2013-01 : Docs updated
;   2013-07-16 MP: Documentation cleanup. Rename 'control_data_quality' -> 'check_data_quality'
;
;
;- 

function gpi_check_data_quality, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
 
@__start_primitive

  if tag_exist( Modules[thisModuleIndex], "r0") then criticalr0=float(Modules[thisModuleIndex].r0) else criticalr0=0.08
  if tag_exist( Modules[thisModuleIndex], "rmserr") then criticalrmserr=float(Modules[thisModuleIndex].rmserr) else criticalrmserr=10.

    badquality=0
    drpmessage='ALERT '
    
  	;hdr= *(dataset.headers)[0]
  	;;control GPI health
  	health=strcompress(string(backbone->get_keyword('GPIHEALT',count=cc)), /rem)
  	if strmatch(health,'WARNING',/fold) || strmatch(health,'BAD',/fold) || strmatch(health,'0',/fold) then begin
  	    badquality=1
  	    drpmessage+='GPI-health='+health
  	endif
  	;;RAWGEMQA keyword tested?
  	
  	;;control r0
  	r0=strcompress(backbone->get_keyword('AVRGNOT',count=cc), /rem) ;r0 [m] at 500nm
  	if cc eq 0 then r0=strcompress(string(backbone->get_keyword('R0_TOT',count=cc)), /rem)
  	 if  (float(r0) lt criticalr0) then begin
  	    badquality=1
        drpmessage+=' r0[m]='+r0  	 
  	 endif
  	 
  	 ;;control rms error
  	rmserr=strcompress(backbone->get_keyword('RMSERR',count=cc), /rem) 
  	  if cc eq 0 then begin
  	      drpmessagerms='No RMSERR keyword found.'
  	      print, 'BAD QUALITY DATA: '+drpmessagerms
         backbone->Log, strjoin(drpmessagerms),  DEPTH = 1
  	  endif
  	    if  (float(rmserr) gt criticalrmserr) && (cc eq 1) then begin
          badquality=1
          drpmessage+=' rms waveront error [microns]='+rmserr     
        endif

if badquality  then begin
  action=uint(Modules[thisModuleIndex].Action)
  case action of
    0:begin
        print, 'BAD QUALITY DATA: '+drpmessage
         backbone->Log, strjoin(drpmessage),  DEPTH = 1
       ;sxaddparlarge,*(dataset.headers[numfile]),'HISTORY',functionname+"ALERT BAD QUALITY DATA"+drpmessage
       backbone->set_keyword, 'HISTORY', functionname+"ALERT BAD QUALITY DATA"+drpmessage,ext_num=0
      end
    1: begin
      return, error('REDUCTION FAILED ('+strtrim(functionName)+'):'+drpmessage)
    end
  
  endcase
endif


  return, ok

end
