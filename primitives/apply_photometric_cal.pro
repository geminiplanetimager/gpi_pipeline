;+
; NAME: apply_photometric_cal
; PIPELINE PRIMITIVE DESCRIPTION: Calibrate Photometric Flux
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
; PIPELINE COMMENT: Apply photometric calibration using satellite flux 
; PIPELINE ARGUMENT: Name="FinalUnits" Type="int" Range="[0,10]" Default="1" Desc="0:Counts, 1:Counts/s, 2:ph/s/nm/m^2, 3:Jy, 4:W/m^2/um, 5:ergs/s/cm^2/A, 6:ergs/s/cm^2/Hz"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="fluxcal" Default="GPI-fluxcal.fits" Desc="Filename of the desired flux calibration file to be read"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.51
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   JM 2010-03 : added sat locations & choice of final units
;   JM 2010-08 : routine optimized with simulated test data
;- 

function apply_photometric_cal, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='Gridratio' 
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


    pmd_fluxcalFrame        = ptr_new(READFITS(c_File, Headerphot, /SILENT))
    lambda_gridratio=*pmd_fluxcalFrame

	hdr= *(dataset.headers)[0]



;;extract photometry of SAT 
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
      SPOTWAVE=lamdamin
      print, 'NO SPOT LOCATIONS FOUND: assume PSF is centered'
      print, 'Use hard-coded value for spot locations in function'+functionname
        cs=0
       if cs eq 1 then spotloc=fltarr(1+4) else spotloc=fltarr(1+2) ;1+ due for PSF center 
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
              'H':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
              'K1':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
              'K2':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
            endcase
              for ii=1,(size(spotloc))[1]-1 do $
              print, 'ASSUME SPOT locations at '+lambdamin+' microms are',spotloc[ii,*]
    endelse

    ;;extract photometry of SAT 
    ;;set photometric apertures and parameters:
    phpadu = 1.0                    ; don't convert counts to electrons
    apr = lambda[0]*[3.] 
    ; Assume that all pixel values are good data
    badpix = [-1.,1e6];state.image_min-1, state.image_max+1
    
    fluxsatmedabs=dblarr(CommonWavVect[2])
    cubcent2=cubef3D
    ;;do the photometry of the spots
    intens_sat=fltarr((size(spotloc))[1]-1,CommonWavVect[2]) 
    for spot=1,(size(spotloc))[1]-1 do begin
      skyrad = lambda[0]*[3.,4.]  
      if (skyrad[1]-skyrad[0] lt 2.) then skyrad[1]=skyrad[0]+2.
      intens_sat2=fltarr(1,CommonWavVect[2])+!VALUES.F_NAN
       while (total(~finite(intens_sat2)) ne 0) && (skyrad[1]-skyrad[0] lt 20.) do begin
        for i=0,CommonWavVect[2]-1 do begin
            ;;extrapolate sat -spot at a given wavelength
            pos2=calc_satloc(spotloc[spot,0],spotloc[spot,1],spotloc[0,*],SPOTWAVE,lambda[i])
              x=pos2[0]
              y=pos2[1]
            aper, abs(cubcent2[*,*,i]), [x], [y], flux, errap, sky, skyerr, phpadu, (lambda[i]/lambda[0])*apr, $
              (lambda[i]/lambda[0])*skyrad, badpix, /flux, /silent 
              print, 'slice#',i,' flux sat #'+strc(spot)+'=',flux[0],' sky=',sky[0]
            intens_sat2[0,i]=(flux[0])
        endfor
        skyrad[1]+=1.
       endwhile
       intens_sat[spot-1,*]=intens_sat2[0,*]
    endfor
     ;;keep only mean values over the 4 spots
    for i=0,CommonWavVect[2]-1 do fluxsatmedabs[i]=mean(intens_sat[*,i],/nan)
;Todo?:Need to take in to account Enc.Energy in the aperture 


;;;;;;theoretical flux:
nlambdapsf=37.
lambdapsf=fltarr(nlambdapsf)
    cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect        
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]
  ;for i=0,n_elements(lambdapsf)-1 do lambdapsf[i]=lambda[0]+(lambda[nlambdapsf-1]-lambda[0])/(2.*nlambdapsf)+double(i)*(lambda[nlambdapsf-1]-lambda[0])/nlambdapsf
 for i=0,n_elements(lambdapsf)-1 do lambdapsf[i]=lambdamin+double(i)*(lambdamax-lambdamin)/nlambdapsf

;nbphot_juststar=pip_nbphot_trans(hdr,lambdapsf)
nbphot_juststar=pip_nbphot_trans_lowres(hdr,lambda)

   magni=double(SXPAR( hdr, 'Hmag'))
   spect=strcompress(SXPAR( hdr, 'SPECTYPE'),/rem)
   Dtel=double(SXPAR( hdr, 'TELDIAM'))
   Obscentral=double(SXPAR( hdr, 'SECDIAM'))
   exposuretime=double(SXPAR( hdr, 'EXPTIME')) ;TODO use ITIME instead
   ;BE SURE THAT EXPTIME IS IN SECONDS
   filter=SXPAR( hdr, 'FILTER')
   nlambda=n_elements(lambda)
   widthL=(lambdamax-lambdamin)
   SURFA=!PI*(Dtel^2.)/4.-!PI*((Obscentral)^2.)/4.
   gaindetector=1. ;1.1 ;from ph to count: IS IT IN THE KEYWORD LIST?
   ifsunits=strcompress(SXPAR( hdr, 'IFSUNITS'),/rem)

;; normalize by commonwavvect[2] because widthL is the width of the entire band here
   nbphotnormtheo=nbphot_juststar*float(n_elements(lambdapsf))/(SURFA*widthL*1e3*exposuretime) ;photons to [photons/s/nm/m^2]
nbphotnormtheosmoothed=nbphotnormtheo
;;smooth to the resolution of the spectrograph:
;case strcompress(filter,/REMOVE_ALL) of
;  'Y':specresolution=30.
;  'J':specresolution=39.
;  'H':specresolution=45.
;  'K1':specresolution=55.
;  'K2':specresolution=60.
;endcase
;  lambda=dblarr(CommonWavVect[2])
;  lambdamin=CommonWavVect[0] &  lambdamax=CommonWavVect[1]
;  for i=0,CommonWavVect[2]-1 do lambda[i]=lambdamin+(lambdamax-lambdamin)/(2.*CommonWavVect[2])+double(i)*(lambdamax-lambdamin)/(CommonWavVect[2])
;lambdamin=lambda[0]
;lambdamax=lambda[n_elements(lambda)-1]
;dlam=((lambdamin+lambdamax)/2.)/specresolution
;nlam=(lambdamax-lambdamin)/dlam
;lambdalow= lambdamin+(lambdamax-lambdamin)*(findgen(floor(nlam))/floor(nlam))
;smooth to the resolution of the spectrograph:
;verylowspec=changeres(nbphotnormtheo, lambda,lambdalow)
;then resample on the common wavelength vector:
;nbphotnormtheosmoothed=changeres(verylowspec, lambdalow,lambda)

;nbphot2=pip_nbphot_trans(hdr,lambda)           
;nbphotnormtheosmoothed= decrease_spec_res(lambda, nbphotnormtheo,spotloc)
;;prepare the satellite flux ratio using a linear fit to reduce noise in the measurement
lambdagrid=lambda_gridratio[*,0]
rawgridratio=lambda_gridratio[*,1]
gridratiocoeff=linfit(lambdagrid,rawgridratio)
gridratio= gridratiocoeff[0]+gridratiocoeff[1]*lambdagrid[*]
;or use it directly with the following line:
;gridratio=lambda_gridratio[*,1]

;;here is the flux conversion factor!
convfac=fltarr(n_elements(nbphotnormtheosmoothed))
for i=0,n_elements(nbphotnormtheosmoothed)-1 do $
convfac[i]=((nbphotnormtheosmoothed[i])/(gaindetector*(gridratio[i])*(fluxsatmedabs[i])))


;http://www.gemini.edu/sciops/instruments/?q=sciops/instruments&q=node/10257  
;assume IFSUNITS is always in Counts/s/coadd
;convert datacube from IFSunits  to [photons/s/nm/m^2]
        for i=0,CommonWavVect[2]-1 do begin
          cubef3D[*,*,i]*=double(convfac[i])
        endfor

unitslist = ['Counts', 'Counts/s','ph/s/nm/m^2', 'Jy', 'W/m^2/um','ergs/s/cm^2/A','ergs/s/cm^2/Hz']
 
 ; let's the user define what will be the final units:
      ;from ph/s/nm/m^2 syst. to syst chosen
      unitschoice=fix(Modules[thisModuleIndex].FinalUnits)
      case unitschoice of
      0: begin ;'Counts'
        for i=0,CommonWavVect[2]-1 do cubef3D[*,*,i]/=(float(convfac[i])/float(exposuretime))
      end
      1:begin ;'Counts/s'
        for i=0,CommonWavVect[2]-1 do cubef3D[*,*,i]/=(float(convfac[i]))
        end
      2: begin ;'ph/s/nm/m^2'
        end
      3:  begin ;'Jy'
        for i=0,CommonWavVect[2]-1 do begin
          cubef3D[*,*,i]*=(1e3*(lambda[i])/1.509e7)
        endfor
        end
      4:  begin ;'W/m^2/um'
        for i=0,CommonWavVect[2]-1 do begin
          cubef3D[*,*,i]*=(1.988e-13/(1e3*(lambda[i])))
        endfor
        end
      5:  begin ;'ergs/s/cm^2/A'
        for i=0,CommonWavVect[2]-1 do begin
        cubef3D[*,*,i]*=(1.988e-14/(1e3*(lambda[i])))
        endfor
        end
      6:  begin ;'ergs/s/cm^2/Hz'
        for i=0,CommonWavVect[2]-1 do begin
        cubef3D[*,*,i]*=((1e3*(lambda[i]))/1.509e30)
        endfor
        end
      endcase
   
	*(dataset.currframe[0])=cubef3D
for i=0,n_elements(convfac)-1 do $
	FXADDPAR, *(dataset.headers)[numfile], 'FSCALE'+strc(i), convfac[i]*(exposuretime) ;fscale to convert from counts to 'ph/s/nm/m^2'
	FXADDPAR, *(dataset.headers)[numfile], 'CUNIT',  unitslist[unitschoice]  

	suffix+='-phot'
  sxaddhist, functionname+": applying photometric calib", *(dataset.headers[numfile])
  sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
  
@__end_primitive


end
