;+
; NAME: gpi_meas_sat_spots_locations
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
; PIPELINE ARGUMENT: Name="spotsnbr" Type="int" Range="[1,4]" Default="4" Desc="How many spots in a slice of the datacube? "
; PIPELINE ARGUMENT: Name="maxaper" Type="int" Range="[1,4]" Default="2" Desc="Half-side length of the window for maximum detection. "
; PIPELINE ARGUMENT: Name="centroidaper" Type="int" Range="[1,4]" Default="2" Desc="Half-side length of the window for centroid calculation. "
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="spotloc" Default="GPI-spotloc.fits" Desc="Filename of spot locations calibration file to be read for first location guess. Will override following user guess."
; PIPELINE ARGUMENT: Name="x1" Type="int" Range="[0,300]" Default="0" Desc="approximate x-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y1" Type="int" Range="[0,300]" Default="0" Desc="approximate y-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="x2" Type="int" Range="[0,300]" Default="0" Desc="approximate x-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y2" Type="int" Range="[0,300]" Default="0" Desc="approximate y-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="x3" Type="int" Range="[0,300]" Default="0" Desc="approximate x-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y3" Type="int" Range="[0,300]" Default="0" Desc="approximate y-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="x4" Type="int" Range="[0,300]" Default="0" Desc="approximate x-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y4" Type="int" Range="[0,300]" Default="0" Desc="approximate y-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ORDER: 2.44
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;- 

function gpi_meas_sat_spots_locations, DataSet, Modules, Backbone
primitive_version= '$Id: gpi_meas_sat_spots_locations.pro 78 2010-09-03 18:58:45Z maire $' ; get version from subversion to store in header history

;;calefiletype will not be defined if CalibrationFile='', so the user-param x1,y1,x2,... will be considered 
thisModuleIndex = Backbone->GetCurrentModuleIndex()
if (Modules[thisModuleIndex].CalibrationFile) ne '' then calfiletype='spotloc'
@__start_primitive

  cubef3D=*(dataset.currframe[0])

        ;get the common wavelength vector
            ;error handle if extractcube not used before
            if ((size(cubef3D))[0] ne 3) || (strlen(filter) eq 0)  then $
            return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before.')        
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]
       
       
;       filnm=sxpar(*(DataSet.Headers[numfile]),'DATAFILE')
;       slash=strpos(filnm,path_sep(),/reverse_search)
;       c_File = strmid(filnm, slash,strlen(filnm)-5-slash)+'.fits'
;       print, 'Click Ok in the dialog box that appears.'
;       print, 'Use GPItv to locate sat.spots. Select the ''SAT SPOT LOCALIZE'' mouse mode, then click on the spots.'
;       print, 'Look at the widget if spots have been well localized.'
;       print, 'Save our result using the widget and close GPItv after selection.'
;        void=dialog_message(/INF,'Use GPItv to locate sat.spots. Select the ''SAT SPOT LOCALIZE'' mouse mode, then click on the spots. Close GPItv after selection.')
;        spotcalibfile=Modules[thisModuleIndex].OutputDir+path_sep()+'spotloc'+filter+'.fits'
        ;gpitve, cubef3D[*,*,floor(CommonWavVect[2]/2)], nbrsatspot=fix(Modules[thisModuleIndex].spotsnbr), satspotcalibfile=spotcalibfile & gpitv_activate
        ;Backbone_comm->gpitv, cubef3D[*,*,floor(CommonWavVect[2]/2)], nbrsatspot=fix(Modules[thisModuleIndex].spotsnbr), satspotcalibfile=spotcalibfile, ses=20
        
;;re-order sat locations (opposite,..)
nbrspot=fix(Modules[thisModuleIndex].spotsnbr)

approx_loc=fltarr(nbrspot,2)
;; get an approximate location of the spot
if (Modules[thisModuleIndex].CalibrationFile) ne '' then begin
spotloc=readfits(spotcalibfile)
  approx_loc[0,0]=spotloc[1,0]
  approx_loc[0,1]=spotloc[1,1]
  approx_loc[1,0]=spotloc[2,0]
  approx_loc[1,1]=spotloc[2,1]
  approx_loc[2,0]=spotloc[3,0]
  approx_loc[2,1]=spotloc[3,1]
  approx_loc[3,0]=spotloc[4,0]
  approx_loc[3,1]=spotloc[4,1]
endif else begin
  approx_loc[0,0]=fix(Modules[thisModuleIndex].x1)
  approx_loc[0,1]=fix(Modules[thisModuleIndex].y1)
  approx_loc[1,0]=fix(Modules[thisModuleIndex].x2)
  approx_loc[1,1]=fix(Modules[thisModuleIndex].y2)
  approx_loc[2,0]=fix(Modules[thisModuleIndex].x3)
  approx_loc[2,1]=fix(Modules[thisModuleIndex].y3)
  approx_loc[3,0]=fix(Modules[thisModuleIndex].x4)
  approx_loc[3,1]=fix(Modules[thisModuleIndex].y4)
endelse

spotloc=fltarr(nbrspot,2)
maxaper=fix(Modules[thisModuleIndex].maxaper)
centroidaper=fix(Modules[thisModuleIndex].centroidaper)
for ii=0,nbrspot-1 do spotloc[ii,*]=calc_centroid_spots( approx_loc[ii,0],approx_loc[ii,1],cubef3D[*,*,floor(CommonWavVect[2]/2)], maxaper, centroidaper)


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
  sxaddpar, *(dataset.headers[numfile]), "SPOTWAVE", lambda[floor(CommonWavVect[2]/2)], "Wavelength of ref for SPOT locations"
 

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
