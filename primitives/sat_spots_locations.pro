;+
; NAME: sat_spots_locations
; PIPELINE PRIMITIVE DESCRIPTION: Measure satellite spot locations
;
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Calculate locations of sat.spots in datacubes
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="spotsnbr" Type="int" Range="[1,4]" Default="2" Desc="How many spots in a slice of the datacube? "
; PIPELINE ORDER: 2.44
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;- 

function sat_spots_locations, DataSet, Modules, Backbone
@__start_primitive

  cubef3D=*(dataset.currframe[0])

lambda=dblarr((size(cubef3D))[3])
lambdamin=CommonWavVect[0] &  lambdamax=CommonWavVect[1]
CommonWavVect[2]=double((size(cubef3D))[3])
for i=0,CommonWavVect(2)-1 do lambda[i]=lambdamin+(lambdamax-lambdamin)/(2.*CommonWavVect[2])+double(i)*(lambdamax-lambdamin)/(CommonWavVect[2])
       
       filnm=sxpar(*(DataSet.Headers[numfile]),'DATAFILE')
       slash=strpos(filnm,path_sep(),/reverse_search)
       c_File = strmid(filnm, slash,strlen(filnm)-5-slash)+'.fits'
void=dialog_message(/INF,'Use GPItv to locate sat.spots. Select the ''SAT SPOT LOCALIZE'' mouse mode, then click on the spots. Close GPItv after selection.')
spotcalibfile=Modules[thisModuleIndex].OutputDir+path_sep()+'spotloc.fits'
gpitv, cubef3D[*,*,floor(CommonWavVect[2]/2)], nbrsatspot=fix(Modules[thisModuleIndex].spotsnbr), satspotcalibfile=spotcalibfile & gpitv_activate
;;todo:add header in this calibration file (important:wavelength used)

;;re-order sat locations (opposite,..)
nbrspot=fix(Modules[thisModuleIndex].spotsnbr)
spotloc=readfits(spotcalibfile)
spotloc2=fltarr(nbrspot,2)
  ;;replace spots in the tab
if nbrspot eq 2 then begin
    spotloc2=spotloc[sort(spotloc[*,1]),*]    
endif
if nbrspot eq 4 then begin
    void=sort(spotloc[*,1])
    spotloc2[0,*]=  spotloc[ void[0],*] 
    spotloc2[1,*]=  spotloc[ void[3],*] 
    spotloc2[2,*]=  spotloc[ void[1],*]
    spotloc2[3,*]=  spotloc[ void[2],*]
endif
print, 'spotloc2=',spotloc2

;; calculate center of the PSF
if nbrspot eq 2 then begin
    PSFcenter=[0.5*(spotloc2[0,0]+spotloc2[1,0]), 0.5*(spotloc2[0,1]+spotloc2[1,1]) ] 
    print, 'PSF center=',PSFcenter    
endif
if nbrspot eq 4 then begin
    PSFcenter1=[0.5*(spotloc2[0,0]+spotloc2[1,0]), 0.5*(spotloc2[0,1]+spotloc2[1,1]) ] 
    print, 'PSF center 1=',PSFcenter1
    PSFcenter2=[0.5*(spotloc2[2,0]+spotloc2[3,0]), 0.5*(spotloc2[2,1]+spotloc2[3,1]) ]
    print, 'PSF center 2=',PSFcenter2
    PSFcenter=[0.5*(PSFcenter1[0]+PSFcenter2[0]), 0.5*(PSFcenter1[1]+PSFcenter2[1]) ]
    print, 'mean PSF center=',PSFcenter  
endif
;;extrapolate sat -spot at a given wavelength
;slic=10
;  pos2=calc_satloc(spotloc2[0,0],spotloc2[0,1],PSFcenter,lambda[floor(CommonWavVect[2]/2)],lambda[floor(CommonWavVect[2]/2)+slic])
;print, lambda[floor(CommonWavVect[2]/2)],spotloc2[0,0],spotloc2[0,1]
;print, lambda[floor(CommonWavVect[2]/2)+slic],pos2[0],pos2[1]

*(dataset.currframe[0])=[transpose(PSFcenter),spotloc2]
  sxaddpar, *(dataset.headers[numfile]), "SPOTWAVE", lambda(floor(CommonWavVect[2]/2)), "Wavelength of ref for SPOT locations"
 

suffix+='-spotloc'

  ; Set keywords for outputting files into the Calibrations DB
  sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Spot Location Measurement", "What kind of IFS file is this?"
  sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'

;TODO header update

@__end_primitive
;;	  thisModuleIndex = Backbone->GetCurrentModuleIndex()
;;	    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;;	      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;;	      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
;;	      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;;	    endif 
;;	
;;	
;;	;;
;;	return, ok
;;	
;;	
end
