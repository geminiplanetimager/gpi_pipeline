;+
; NAME: sat_spots_calib_from_unocc
; PIPELINE PRIMITIVE DESCRIPTION: Measure satellite spot flux ratios
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
; PIPELINE COMMENT: Calculate flux ratio between satellite spots and unocculted star image in a given aperture.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="tests" Type="int" Range="[0,1]" Default="0" Desc="1 only for DRP tests "
; PIPELINE ORDER: 2.515
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   JM 2010-08: routine optimized with simulated test data
;- 

function sat_spots_calib_from_unocc, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id$' ; get version from subversion to store in header history
    getmyname, functionname
@__start_primitive
   ; save starting time
   T = systime(1)

  cubef3D=*(dataset.currframe[0])
;;TOCHECK: unocculted image?
;;TOCHECK: is datacube registered?

        ;get the common wavelength vector
            ;error handle if extractcube not used before
            if ((size(cubef3D))[0] ne 3) || (strlen(filter) eq 0)  then $
            return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before.')        
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]



hdr= *(dataset.headers)[0]



;; set the photometric apertures and parameters
phpadu = 1.0                    ; don't convert counts to electrons
apr = [5.]   ;constant is ok as the same aperture radius is used for sat. and star itself
skyrad = [6.,8.] 
if (filter eq 'J')||(filter eq 'Y') then apr-=2.  ;satellite spots are close to the dark hole in these bands...
if (filter eq 'J')||(filter eq 'Y') then skyrad-=2.
; Assume that all pixel values are good data
badpix = [-1.,1e6]

;;; handle the spot locations
 SPOTWAVE=sxpar( *(dataset.headers[numfile]), 'SPOTWAVE',  COUNT=cc4)
   if cc4 gt 0 then begin
    ;check how many spots locations is in the header (2 or 4)
    void=sxpar( *(dataset.headers[numfile]), 'SPOT4x',  COUNT=cs)
    if cs eq 1 then spotloc=fltarr(1+4,2) else spotloc=fltarr(1+2,2) ;1+ due for PSF center 
          spotloc[0,0]=sxpar( *(dataset.headers[numfile]),"PSFCENTX")
          spotloc[0,1]=sxpar( *(dataset.headers[numfile]),"PSFCENTY")      
        for ii=1,(size(spotloc))[1]-1 do begin
          spotloc[ii,0]=sxpar( *(dataset.headers[numfile]),"SPOT"+strc(ii)+'x')
          spotloc[ii,1]=sxpar( *(dataset.headers[numfile]),"SPOT"+strc(ii)+'y')
        endfor      
   endif else begin
      SPOTWAVE=lambdamin
      print, 'NO SPOT LOCATIONS FOUND: assume PSF is centered'
      print, 'Use hard-coded value for spot locations in function '+functionname
        cs=1
       if cs eq 1 then spotloc=fltarr(1+4,2) else spotloc=fltarr(1+2,2) ;1+ due for PSF center 
            spotloc[0,0]=(size(cubef3D))[1]/2
            spotloc[0,1]=(size(cubef3D))[1]/2  
            print, 'Assume PSF center is [in pix on datacube slice]', spotloc[0,*] 
            ;;; if spot location calibration is NOT available, 
            ;;; enter hereafter the pixel coordinates of satellite images in datacube at the minimum wavelength 
            ;;; in the format: spotloc=[[PSFcenterX,sat1-x,sat2-x,sat3-x,sat4-x],[PSFcenterY,sat1-y,sat2-y,sat3-y,sat4-y]]
            ;;; Note that the spot location calibration can be obtained using the CAL-SPEC DRF templates in the DRF GUI.
            ;;; Note also that the wavelength reference SPOTWAVE for these locations can be different. 
            case strcompress(filter,/REMOVE_ALL) of
              'Y':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
              'J':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
              'H':spotloc=[[140.,140.,140.,140.,140.],[140.,69.,69.,69.,69.]]
              'K1':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
              'K2':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
            endcase
              for ii=1,(size(spotloc))[1]-1 do $
              print, 'ASSUME SPOT locations at ',lambdamin,' microms are',spotloc[ii,*]
    endelse


cubcent2=cubef3D

thisModuleIndex = Backbone->GetCurrentModuleIndex()
tests=fix(Modules[thisModuleIndex].tests) ;we test this routine not with satellites but with two objects of known flux (their locations (vs wavelength) are constant) 


;;do the photometry of the spots
intens_sat=fltarr((size(spotloc))[1]-1,CommonWavVect[2])
sidelen=4
for spot=1,(size(spotloc))[1]-1 do begin
  for i=0,CommonWavVect[2]-1 do begin
      ;;extrapolate sat -spot at a given wavelength
      if tests eq 0 then $
      pos2=calc_satloc(spotloc[spot,0],spotloc[spot,1],spotloc[0,*],SPOTWAVE,lambda[i]) else $
      pos2=[spotloc[spot,0],spotloc[spot,1]]      
      getsatpos=centroid(subarr(cubcent2[*,*,i],sidelen,[pos2[0],pos2[1]]))
      x=spotloc[spot,0]-sidelen/2.+getsatpos[0] & y=spotloc[spot,1]-sidelen/2.+getsatpos[1]
        ;x=pos2[0]
        ;y=pos2[1]
      aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
        skyrad, badpix, /flux, /silent ;, flux=abs(state.magunits-1)
        print, 'slice#',i,' flux sat #'+strc(spot)+'=',flux[0],' at x=',x,' y=',y,' sky=',sky[0]
      intens_sat[spot-1,i]=(flux[0]-sky[0])
  endfor

endfor

;;unocculted STAR location; ok if it is not perfectly centered (as it use a centroid algo to localize center)
inputS=dblarr(CommonWavVect[2])
;star location
sidelen=20
getstarpos=centroid(subarr(cubcent2[*,*,0],sidelen,spotloc[0,*]))
x=spotloc[0,0]-sidelen/2.+getstarpos[0] & y=spotloc[0,1]-sidelen/2.+getstarpos[1]
for i=0,CommonWavVect[2]-1 do begin
    aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
      skyrad, badpix, /flux, /silent 
      print, 'slice=',i,' star flux=',flux[0],' sky=',sky[0],' at x=',x,' y=',y
        inputS[i]=(flux[0]-sky[0])
endfor
nbspot=(size(spotloc))[1]-1

;print, 'Star/sat ratio 1:',inputS/intens_sat[0,*]
;print, 'Star/sat ratio 2:',inputS/intens_sat[1,*]

for i=0,nbspot-1 do $
gridratio=inputS*float(nbspot)/total(intens_sat,1)

print, 'nb spots=',float(nbspot)
print, 'tot intens sat=',total(intens_sat,1)
print, 'grid_ratios=',gridratio
print, 'mean grid ratio=',mean(gridratio[0:n_elements(gridratio)-1], /nan) ;remove edges that can be affected by the interpolation on wavelength?
print, 'median grid ratio=',median(gridratio[0:n_elements(gridratio)-1])
lambda_gridratio=[[lambda],[gridratio]]

suffix+='-fluxcal'


  ; Set keywords for outputting files into the Calibrations DB
  sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Grid ratio", "What kind of IFS file is this?"
  sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'

	thisModuleIndex = Backbone->GetCurrentModuleIndex()
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
		  if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, savedata=lambda_gridratio ,saveheader=*(dataset.headers[numfile]),display=display)
    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
    endelse


;drpPushCallStack, functionName
return, ok


end
