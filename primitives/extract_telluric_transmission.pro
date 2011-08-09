;+
; NAME: Extract_telluric_transmission
; PIPELINE PRIMITIVE DESCRIPTION: Measure telluric transmission 
;
;
;
; INPUTS: 
;
;
; KEYWORDS:
;	
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: DATAFILE,FILETYPE,ISCALIB,PSFCENTX,PSFCENTY,SPOTix-y,SPOTWAVE,
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Extract Telluric transmission from satelitte spots (method 1) or from PSF signal (method 2) using theoretical star spectrum. Correct or save the transmisssion.
; PIPELINE ARGUMENT: Name="method" Type="int" Range="[1,2]" Default="1" Desc="1: Use satellite flux. 2:Use clean PSF area."
; PIPELINE ARGUMENT: Name="Correct_datacube" Type="int" Range="[0,1]" Default="1" Desc="1: Correct datacube from extracted tell trams., 0: don't correct"
; PIPELINE ARGUMENT: Name="Save_corrected_datacube" Type="int" Range="[0,1]" Default="1" Desc="1: save corrected datacube on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="Save_telluric_transmission" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-telcal" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.5
; PIPELINE TYPE: ALL-SPEC 
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Jerome Maire 2010-03
;- 

function extract_telluric_transmission, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS

primitive_version= '$Id$' ; get version from subversion to store in header history
  @__start_primitive
    ;getmyname, functionname
    
  thisModuleIndex = Backbone->GetCurrentModuleIndex()

  cubef3D=*(dataset.currframe[0])

       ;get the common wavelength vector
       filter = gpi_simplify_keyword_value(backbone->get_keyword('FILTER1', count=ct))
            ;error handle if extractcube not used before
            if ((size(cubef3D))[0] ne 3) || (strlen(filter) eq 0)  then $
            return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before.')        
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]

;hdr= *(dataset.headers)[0]
;if numext eq 0 then hdr= *(dataset.headers)[numfile] else hdr= *(dataset.headersPHU)[numfile]


;stop
if ( Modules[thisModuleIndex].method eq 1 ) then begin
;;; handle the spot locations
;;; handle the spot locations
SPOTWAVE=backbone->get_keyword('SPOTWAVE', count=cc4)  
 ;SPOTWAVE=sxpar( *(dataset.headers)[numfile], 'SPOTWAVE',  COUNT=cc4)
   if cc4 gt 0 then begin
   spotloc=fltarr(5,2) ;1+ due for PSF center 
          spotloc[0,0]=backbone->get_keyword('PSFCENTX');sxpar( *(dataset.headers[numfile]),"PSFCENTX")
          spotloc[0,1]=backbone->get_keyword('PSFCENTY');sxpar( *(dataset.headers[numfile]),"PSFCENTY")      
        for ii=1,(size(spotloc))[1]-1 do begin
          spotloc[ii,0]=backbone->get_keyword("SPOT"+strc(ii)+'x') ;sxpar( *(dataset.headers[numfile]),"SPOT"+strc(ii)+'x')
          spotloc[ii,1]=backbone->get_keyword("SPOT"+strc(ii)+'y') ;sxpar( *(dataset.headers[numfile]),"SPOT"+strc(ii)+'y')
        endfor  
   endif

; SPOTWAVE=sxpar( *(dataset.headers[numfile]), 'SPOTWAVE',  COUNT=cc4)
;   if cc4 gt 0 then begin
;    ;check how many spots locations is in the header (2 or 4)
;    void=sxpar( *(dataset.headers[numfile]), 'SPOT4x',  COUNT=cs)
;    if cs eq 1 then spotloc=fltarr(1+4,2) else spotloc=fltarr(1+2,2) ;1+ due for PSF center 
;          spotloc[0,0]=sxpar( *(dataset.headers[numfile]),"PSFCENTX")
;          spotloc[0,1]=sxpar( *(dataset.headers[numfile]),"PSFCENTY")      
;        for ii=1,(size(spotloc))[1]-1 do begin
;          spotloc[ii,0]=sxpar( *(dataset.headers[numfile]),"SPOT"+strc(ii)+'x')
;          spotloc[ii,1]=sxpar( *(dataset.headers[numfile]),"SPOT"+strc(ii)+'y')
;        endfor      
;   endif else begin
;      SPOTWAVE=lamdamin
;      print, 'NO SPOT LOCATIONS FOUND: assume PSF is centered'
;      print, 'Use hard-coded value for spot locations in function'+functionname
;        cs=0
;       if cs eq 1 then spotloc=fltarr(1+4) else spotloc=fltarr(1+2) ;1+ due for PSF center 
;            spotloc[0,0]=(size(cubef3D))[1]/2
;            spotloc[0,1]=(size(cubef3D))[1]/2  
;            print, 'Assume PSF center is [in pix on datacube slice]', spotloc[0,*] 
;            ;;; if spot location calibration is NOT available, 
;            ;;; enter hereafter the pixel coordinates of satellite images in datacube at the minimum wavelength 
;            ;;; in the format: spotloc=[[PSFcenterX,sat1-x,sat2-x,sat3-x,sat4-x],[PSFcenterY,sat1-y,sat2-y,sat3-y,sat4-y]]
;            ;;; Note that the spot location calibration can be obtained using the CAL-SPEC DRF templates in the DRF GUI.
;            ;;; Note also that the wavelength reference SPOTWAVE for these locations can be different. 
;            case strcompress(filter,/REMOVE_ALL) of
;              'Y':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
;              'J':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
;              'H':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
;              'K1':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
;              'K2':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
;            endcase
;              for ii=1,(size(spotloc))[1]-1 do $
;              print, 'ASSUME SPOT locations at '+lambdamin+' microms are',spotloc[ii,*]
;    endelse


    ;;extract photometry of SAT 
    fluxsatmedabs=dblarr(CommonWavVect[2])
    cubcent2=cubef3D
    
    ;;do the photometry of the spots
    ;;;;set photometric apertures and parameters
    phpadu = 1.0                    ; don't convert counts to electrons
    apr = 1.2*(lambda[n_elements(lambda)/2]*1.e-6/7.7)*(180.*3600./!dpi)/0.014 ;lambda[0]*[7.] ;lambda[0]*[5.] ;lambda[0]*[4.] 
    skyrad = [apr,apr+2.] ;skyrad = lambda[0]*[7.,9.] ;lambda[0]*[5.,7.] ;lambda[0]*[4.,5.]
    if (skyrad[1]-skyrad[0] lt 2.) then skyrad[1]=skyrad[0]+2.
    ; Assume that all pixel values are good data
    badpix = [-1.,1e6];state.image_min-1, state.image_max+1
    hh=3.
    intens_sat=fltarr((size(spotloc))[1]-1,CommonWavVect[2])
    for spot=1,(size(spotloc))[1]-1 do begin
      for i=0,CommonWavVect[2]-1 do begin
          ;;extrapolate sat -spot at a given wavelength
          pos2=calc_satloc(spotloc[spot,0],spotloc[spot,1],spotloc[0,*],SPOTWAVE,lambda[i])
          cent=centroid(cubcent2[pos2[0]-hh:pos2[0]+hh,pos2[1]-hh:pos2[1]+hh,i])
            x=pos2[0]+cent[0]-hh
            y=pos2[1]+cent[1]-hh
          aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, (double(lambda[i])/double(lambdamin))*apr, $
            (double(lambda[i])/double(lambdamin))*skyrad, badpix, /flux, /silent ;, flux=abs(state.magunits-1)
            print, 'slice#',i,' flux sat #'+strc(spot)+'=',flux[0],'at positions ['+strc(x)+','+strc(y)+']',' sky=',sky[0]
          intens_sat[spot-1,i]=(flux[0])
      endfor
    
    endfor
   
    for i=0,CommonWavVect[2]-1 do fluxsatmedabs[i]=mean(intens_sat[*,i],/nan) ;((double(lambda[i])/double(lambdamin))^1.)*mean(intens_sat[*,i],/nan)
    
endif

;;this second method has not been tested!
if ( Modules[thisModuleIndex].method eq 2 ) then begin
      cx=88 & cy=151 & ll=6
      L2m=lambdamin
      carotdc=cubcent2[cx-ll:cx+ll,cy-ll:cy+ll,*]
      fluxsatmedabs=dblarr(CommonWavVect[2])
      for i=0,CommonWavVect[2]-1 do fluxsatmedabs[i]=((double(lambda[i])/double(L2m))^2.)*median(carotdc[*,*,i])/(nbphot[i]*transinstru) ;*Transmfilt[i]
      
endif

;;; get the theorithical spectrum of the star
;;;calculate number of photons at low spectral resolution
;case strcompress(filter,/REMOVE_ALL) of
;  'Y':specresolution=35.
;  'J':specresolution=38.
;  'H':specresolution=45.
;  'K1':specresolution=55.
;  'K2':specresolution=60.
;endcase
;
;lambdamin=lambda[0]
;lambdamax=lambda[n_elements(lambda)-1]
;dlam=((lambdamin+lambdamax)/2.)/specresolution
;nlam=(lambdamax-lambdamin)/dlam
;lambda_nominalres= lambdamin+(lambdamax-lambdamin)*(findgen(floor(nlam))/floor(nlam))+0.5*(lambdamax-lambdamin)/floor(nlam)
;
;nbphotnominal=pip_nbphot_trans(hdr,lambda_nominalres) 
;;;then resample on the common wavelength vector:
;          lambint=lambda_nominalres
;          ;for bandpass normalization
;          bandpassmoy=mean(lambint[1:(size(lambint))[1]-1]-lambint[0:(size(lambint))[1]-2],/DOUBLE)
;          bandpassmoy_interp=mean(lambda[1:(size(lambda))[1]-1]-lambda[0:(size(lambda))[1]-2],/DOUBLE)
;          norma=bandpassmoy_interp/bandpassmoy
;
;          nbphot = norma*INTERPOL( nbphotnominal, lambint, lambda )
;
;        cwv=get_cwv(filter)
;        CommonWavVect=cwv.CommonWavVect        
;        lambdamin=CommonWavVect[0]
;        lambdamax=CommonWavVect[1]
;nlambdapsf=37.
;lambdapsf=fltarr(nlambdapsf)
;  for i=0,n_elements(lambdapsf)-1 do lambdapsf[i]=lambdamin+double(i)*(lambdamax-lambdamin)/nlambdapsf
;nbphot2=pip_nbphot_trans(hdr,lambdapsf) 
nbphot2=pip_nbphot_trans_lowres([*(dataset.headersPHU)[numfile],*(dataset.headersExt)[numfile]],lambda)
        
;spec= decrease_spec_res(lambda, nbphot2,spotloc)
;  stop        
;;; divide the sat. intensity by the star spectrum to obtain the telluric trans, then normalize it:
fluxsatmedabs/=nbphot2 ;nbphot
maxflux=max(fluxsatmedabs,maxind)
;kind of median filtering:
almostmax=median(fluxsatmedabs[(maxind-2>0):((maxind+2)<(n_elements(fluxsatmedabs)-1))])
fluxsatmedabs/=almostmax
;fluxsatmedabs/=max(fluxsatmedabs)

;;this is a comparison of measured/synthetic telluric transmission for DRP tests:
;; comment it for real data, not needed...
testtelluric=1
;if testtelluric eq 1 then test_telluric, lambda, DataSet.OutputFilenames[numfile],fluxsatmedabs
if testtelluric eq 1 then test_telluric, lambda, sxpar(*(DataSet.HeadersPHU[numfile]),'DATAFILE'),fluxsatmedabs

;window, 1
;plot, lambda,fluxsatmedabs
;oplot, lambda, dsttrans, psym=1
;stop

if tag_exist( Modules[thisModuleIndex], "Save_telluric_transmission") && ( Modules[thisModuleIndex].Save_telluric_transmission eq 1 ) then begin
   ; Set keywords for outputting files into the Calibrations DB
    ;backbone->set_keyword, "FILETYPE", "Telluric transmission", "What kind of IFS file is this?", ext_num=0
    ;backbone->set_keyword,"ISCALIB", "YES", 'This is a reduced calibration file of some type.', ext_num=0
    hdrphu=*dataset.headersPHU[numfile]
    hdrext=*dataset.headersExt[numfile]
    sxaddpar, hdrphu, "FILETYPE", "Telluric transmission", "What kind of IFS file is this?"
    sxaddpar, hdrphu,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'  
  suffixtelluric='-tellucal'
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffixtelluric,savedata=fluxsatmedabs,savephu=hdrphu)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')

endif
if tag_exist( Modules[thisModuleIndex], "Correct_datacube")&& ( Modules[thisModuleIndex].Correct_datacube eq 1 ) then begin
;print, 'before corr=',(*(dataset.currframe[0]))[140,140,34]
  for ii=0,CommonWavVect[2]-1 do (*(dataset.currframe[0]))[*,*,ii]/=fluxsatmedabs[ii]
;print, 'after corr=',(*(dataset.currframe[0]))[140,140,34]  
  print, 'Corrected from telluric transmission.'
  
if tag_exist( Modules[thisModuleIndex], "Save_corrected_datacube") && tag_exist( Modules[thisModuleIndex], "suffix") then suffix+=Modules[thisModuleIndex].suffix

    if tag_exist( Modules[thisModuleIndex], "Save_corrected_datacube") && ( Modules[thisModuleIndex].Save_corrected_datacube eq 1 ) then begin
		  if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
          Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
    endelse

endif

return, ok


end
