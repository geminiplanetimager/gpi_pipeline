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
; PIPELINE ORDER: 2.515
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;- 

function sat_spots_calib_from_unocc, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


    getmyname, functionname

   ; save starting time
   T = systime(1)

  cubef3D=*(dataset.currframe[0])
;;TOCHECK: unocculted image?
;;TOCHECK: is datacube registered?

lambda=dblarr((size(cubef3D))[3])
lambdamin=CommonWavVect[0] &  lambdamax=CommonWavVect[1]
CommonWavVect[2]=double((size(cubef3D))[3])
for i=0,CommonWavVect(2)-1 do lambda[i]=lambdamin+(lambdamax-lambdamin)/(2.*CommonWavVect[2])+double(i)*(lambdamax-lambdamin)/(CommonWavVect[2])



hdr= *(dataset.headers)[0]




phpadu = 1.0                    ; don't convert counts to electrons
apr = [3.]
skyrad = [10.,12.]
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
  print, 'Use hard-coded value for spot locations in function'+functionname
    cs=0
   if cs eq 1 then spotloc=fltarr(1+4) else spotloc=fltarr(1+2) ;1+ due for PSF center 
        spotloc[0,0]=(size(cubef3D))[1]/2
        spotloc[0,1]=(size(cubef3D))[1]/2  
        print, 'Assume PSF center is [in pix on datacube slice]', spotloc[0,*] 
        
          if filter eq 'J' then begin 
            spotloc[1,0]=106
            spotloc[1,1]=123
            spotloc[2,0]=169
            spotloc[2,1]=154          
          ;x=106 & y=123;spot1 location Jband
          ;x=169 & y=154;spot2 location Jband
          endif
          if filter eq 'H' then begin
            spotloc[1,0]=191
            spotloc[1,1]=164
            spotloc[2,0]=85
            spotloc[2,1]=111           
          ;x=191 & y=164;spot1 location Hband
          ;x=85 & y=111;spot1 location Hband
          endif
          if filter eq 'K1' then begin
            spotloc[1,0]=83
            spotloc[1,1]=110
            spotloc[2,0]=193
            spotloc[2,1]=165
          ;x=193 & y=165;spot2 location K1band 
          ;x=83 & y=110;spot1 location K1band
          endif
          if filter eq 'K2' then begin
            spotloc[1,0]=80
            spotloc[1,1]=109
            spotloc[2,0]=196
            spotloc[2,1]=167         
          ;x=80 & y=109;spot1 location K2band
          ;x=196 & y=167;spot2 location K2band
          endif
          for ii=1,(size(spotloc))[1]-1 do $
          print, 'ASSUME SPOT locations at '+lambdamin+' microms are',spotloc[ii,*]
endelse


;;;; calculate sat locations for all slices of the cube
;;extrapolate sat -spot at a given wavelength

;  pos2=calc_satloc(spotloc2[0,0],spotloc2[0,1],PSFcenter,SPOTWAVE,lambda[floor(CommonWavVect[2]/2)+slic])
;L2m=lambdamin
cubcent2=cubef3D
;wnf1 = where(~FINITE(cubcent2),nancount1)
;if nancount1 gt 0 then cubcent2(wnf1)=0.
;for i=0,CommonWavVect[2]-1 do cubcent2[*,*,i]=fftscale(cubcent[*,*,i],double(L2m)/double(lambda[i]),double(L2m)/double(lambda[i]),1e-7)


;;do the photometry of the spots
intens_sat=fltarr((size(spotloc))[1],CommonWavVect[2])
for spot=1,(size(spotloc))[1]-1 do begin
  for i=0,CommonWavVect[2]-1 do begin
      ;;extrapolate sat -spot at a given wavelength
      pos2=calc_satloc(spotloc[spot,0],spotloc[spot,1],spotloc[0,*],SPOTWAVE,lambda[i])
        x=pos2[0]
        y=pos2[1]
      aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
        skyrad, badpix, /flux, /silent ;, flux=abs(state.magunits-1)
        print, 'slice#',i,' flux sat #'+strc(spot)+'=',flux[0],' sky=',sky[0]
      intens_sat[spot,i]=(flux[0]-sky[0])
  endfor

endfor

;;unocculted STAR location; ok if it is not perfectly centered
inputS=dblarr(CommonWavVect[2])
;star location
sidelen=20
getstarpos=centroid(subarr(cubcent2[*,*,0],sidelen,spotloc[0,*]))
x=spotloc[0,0]-sidelen/2.+getstarpos[0] & y=spotloc[0,1]-sidelen/2.+getstarpos[0]
for i=0,CommonWavVect[2]-1 do begin
    aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
      skyrad, badpix, /flux, /silent 
      print, 'slice=',i,' star flux=',flux[0],' sky=',sky[0]
        inputS[i]=(flux[0]-sky[0])
endfor
print, 'Star/sat ratio 1:',inputS/intens_sat[0,*]
print, 'Star/sat ratio 2:',inputS/intens_sat[1,*]

gridratio=inputS*2./(intens_sat[0,*]+intens_sat[1,*])

print, 'grid_ratios=',gridratio


suffix+='-fluxcal'


  ; Set keywords for outputting files into the Calibrations DB
  sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Grid ratio", "What kind of IFS file is this?"
  sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'



	thisModuleIndex = Backbone->GetCurrentModuleIndex()
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
		  if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, savedata=gridratio ,saveheader=*(dataset.headers[numfile]),display=display)
    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
    endelse


;drpPushCallStack, functionName
return, ok


end
