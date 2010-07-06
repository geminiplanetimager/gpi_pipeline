;+
; NAME: apply_photometric_cal
; PIPELINE PRIMITIVE DESCRIPTION: Calibrate photometric flux
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
;- 

function apply_photometric_cal, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='Gridratio' ; this is probably the wrong type??
@__start_primitive


  	cubef3D=*(dataset.currframe[0])

	lambda=dblarr((size(cubef3D))[3])
	lambdamin=CommonWavVect[0] &  lambdamax=CommonWavVect[1]
	CommonWavVect[2]=double((size(cubef3D))[3])
	for i=0,CommonWavVect(2)-1 do lambda[i]=lambdamin+(lambdamax-lambdamin)/(2.*CommonWavVect[2])+double(i)*(lambdamax-lambdamin)/(CommonWavVect[2])

;;		;;get fluxcal file
;;		thisModuleIndex = Backbone->GetCurrentModuleIndex()
;;	    c_File = (Modules[thisModuleIndex].CalibrationFile)
;;		if strmatch(c_File, 'AUTOMATIC',/fold) then c_File = (Backbone_comm->Getgpicaldb())->get_best_cal_from_header( 'telluric', *(dataset.headers)[numfile] )
;;	;    if strmatch(c_File, 'AUTOMATIC',/fold) then begin
;;	;        dateobs=strcompress(sxpar( *(dataset.headers)[numfile], 'DATE-OBS',  COUNT=cc1),/rem)
;;	;        timeobs=strcompress(sxpar( *(dataset.headers)[numfile], 'TIME-OBS',  COUNT=cc2),/rem)
;;	;          dateobs2 =  strc(sxpar(*(dataset.headers)[numfile], "DATE-OBS"))+" "+strc(sxpar(*(dataset.headers)[numfile],"TIME-OBS"))
;;	;          dateobs3 = date_conv(dateobs3, "J")
;;	;        
;;	;        filt=strcompress(sxpar( *(dataset.headers)[numfile], 'FILTER',  COUNT=cc3),/rem)
;;	;        prism=strcompress(sxpar( *(dataset.headers)[numfile], 'DISPERSR',  COUNT=cc4),/rem)
;;	;        gpicaldb = Backbone_comm->Getgpicaldb()
;;	;        c_File = gpicaldb->get_best_cal( 'telluric', dateobs3,filt,prism)
;;	;   endif
;;	    if (file_test( c_File ) EQ 0 ) then $
;;	       return, error('ERROR IN CALL ('+strtrim(functionName)+'): Flux Cal File  ' + $
;;	                      strtrim(string(c_File),2) + ' not found.' )


    pmd_fluxcalFrame        = ptr_new(READFITS(c_File, Header, /SILENT))
    gridratio=*pmd_fluxcalFrame

	hdr= *(dataset.headers)[0]

	;cubcent=cubef3D ;[2:278,2:278,*]
	;for i=0,CommonWavVect[2]-1 do  cubcent[*,*,i]=transpose(cubcent[*,*,i])


	L2m=lambdamin
;	cubcent2=cubcent
;	wnf1 = where(~FINITE(cubcent),nancount1)
;	if nancount1 gt 0 then cubcent(wnf1)=0.
;	for i=0,CommonWavVect[2]-1 do cubcent2[0:275,0:275,i]=fftscale(cubcent[0:275,0:275,i],double(L2m)/double(lambda[i]),double(L2m)/double(lambda[i]),1e-7)



intens_sat1=dblarr(CommonWavVect[2])
intens_sat2=dblarr(CommonWavVect[2])
fluxsat=dblarr(CommonWavVect[2],2)
mean_intens_sat=dblarr(CommonWavVect[2])


phpadu = 1.0                    ; don't convert counts to electrons
apr = [3.]
skyrad = [10.,12.]
; Assume that all pixel values are good data
badpix = [-1.,1e6];state.image_min-1, state.image_max+1

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

    ;;extract photometry of SAT 
    fluxsatmedabs=dblarr(CommonWavVect[2])
    cubcent2=cubef3D
    
    ;;do the photometry of the spots
    intens_sat=fltarr((size(spotloc))[1]-1,CommonWavVect[2])
    for spot=1,(size(spotloc))[1]-1 do begin
      for i=0,CommonWavVect[2]-1 do begin
          ;;extrapolate sat -spot at a given wavelength
          pos2=calc_satloc(spotloc[spot,0],spotloc[spot,1],spotloc[0,*],SPOTWAVE,lambda[i])
            x=pos2[0]
            y=pos2[1]
          aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
            skyrad, badpix, /flux, /silent ;, flux=abs(state.magunits-1)
            print, 'slice#',i,' flux sat #'+strc(spot)+'=',flux[0],' sky=',sky[0]
          intens_sat[spot-1,i]=(flux[0]-sky[0])
      endfor
    
    endfor
     
    for i=0,CommonWavVect[2]-1 do fluxsatmedabs[i]=mean(intens_sat[*,i],/nan)

;;;to be changed: handle these locations elsewhere..
;if filter eq 'J' then begin 
;x=106 & y=123;spot1 location Jband
;endif
;if filter eq 'H' then begin 
;x=191 & y=164;spot1 location Hband
;endif
;if filter eq 'K1' then begin 
;x=83 & y=110;spot1 location K1band
;endif
;if filter eq 'K2' then begin 
;x=80 & y=109;spot1 location K2band
;endif
;
;for i=0,CommonWavVect[2]-1 do begin
;    aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
;      skyrad, badpix, /flux, /silent 
;      print, 'slice#',i,' flux sat1=',flux[0],' sky=',sky[0]
;    intens_sat1[i]=(flux[0]-sky[0])
;endfor
;
;if filter eq 'J' then begin 
;x=169 & y=154;spot2 location Jband
;endif
;if filter eq 'H' then begin 
;x=85 & y=111;spot2 location Hband
;endif
;if filter eq 'K1' then begin 
;x=193 & y=165;spot2 location K1band
;endif
;if filter eq 'K2' then begin 
;x=196 & y=167;spot2 location K2band
;endif
;
;for i=0,CommonWavVect[2]-1 do begin
;    aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
;      skyrad, badpix, /flux, /silent 
;      print, 'slice#',i,' flux sat2=',flux[0],' sky=',sky[0]
;        intens_sat2[i]=(flux[0]-sky[0])
;endfor
;
;fluxsat[*,0]=intens_sat1
;fluxsat[*,1]=intens_sat2
for i=0,CommonWavVect[2]-1 do mean_intens_sat[i]=mean(fluxsatmedabs[i,*],/nan)


;;;;;;theoretical intensity:
nbphot_juststar=pip_nbphot_trans(hdr,lambda)

   magni=double(SXPAR( hdr, 'Hmag'))
   spect=strcompress(SXPAR( hdr, 'SPECTYPE'),/rem)
   print, 'star mag=',magni,' spectype=',spect
   Dtel=double(SXPAR( hdr, 'TELDIAM'))
   Obscentral=double(SXPAR( hdr, 'SECDIAM'))
   exposuretime=double(SXPAR( hdr, 'EXPTIME'))
   filter=SXPAR( hdr, 'FILTER')
   nlambda=n_elements(lambda)
   ;endif
   widthL=(lambdamax-lambdamin)
   SURFA=!PI*(Dtel^2.)/4.-!PI*((Obscentral)^2.)/4.

;;check commonwavvect[2]
   nbphotnormtheo=nbphot_juststar*CommonWavVect[2]/(SURFA*widthL*1e3*exposuretime) ;photons to [photons/s/nm/m^2]

;Todo:Need to take in to account Enc.Energy in the aperture 

 exptime=float(SXPAR( hdr, 'EXPTIME',count=cce)) ;BE SURE THAT EXPTIME IS IN SECONDS
 
  gaindetector=1.1 ;from ph to count: IS IT IN THE KEYWORD LIST?
  ifsunits=strcompress(SXPAR( hdr, 'IFSUNITS'),/rem)
  
       ;to ph/s/nm/m^2 syst.
 ;     case ifsunits of
;      'Counts':begin
;        fac=1.
;        end
;      'Counts/s':begin
;        fac=exptime*1.
;        end
;      'Counts/s/coadd':begin
;        fac=(coadds)*exptime*1.
;         end
;      else:  begin ;assume IFSUNITS is always in Counts/s/coadd
;              fac=(coadds)*exptime*1.
;             end 
;      endcase
  
  
  
;FINAL factor that will convert from IFSunits  to [photons/s/nm/m^2]:
;assume IFSUNITS is always in Counts/s/coadd
convfac=(mean(nbphotnormtheo)/(mean(gridratio)*mean(mean_intens_sat)))/(!dpi*(apr[0])^2)  ;convfac: from IFSunits to [photons/s/nm/m^2] per pixel
;(exptime*coadd)*

unitslist = ['Counts', 'Counts/s','ph/s/nm/m^2', 'Jy', 'W/m^2/um','ergs/s/cm^2/A','ergs/s/cm^2/Hz']
 
 ; let's the user define what will be the final units:
      ;from ph/s/nm/m^2 syst. to syst chosen
      unitschoice=fix(Modules[thisModuleIndex].FinalUnits)
      case unitschoice of
      0: begin ;'Counts'
        cubef3D/=(double(convfac)/(exptime))
      end
      1:begin ;'Counts/s'
        cubef3D/=(double(convfac))
        end
      2: begin ;'ph/s/nm/m^2'
        end
      3:  begin ;'Jy'
        ;if ~STRMATCH(state.unitslist(event.index),'') then begin
        for i=0,CommonWavVect[2]-1 do begin
          cubef3D[*,*,i]*=(1e3*(lambda[i])/1.509e7)
        endfor
        ;endif
        end
      4:  begin ;'W/m^2/um'
        ;if ~STRMATCH(state.unitslist(event.index),'') then begin
        for i=0,CommonWavVect[2]-1 do begin
          cubef3D[*,*,i]*=(1.988e-13/(1e3*(lambda[i])))
        endfor
        ;endif
        end
      5:  begin ;'ergs/s/cm^2/A'
        ;if ~STRMATCH(state.unitslist(event.index),'') then begin
        for i=0,CommonWavVect[2]-1 do begin
        cubef3D[*,*,i]*=(1.988e-14/(1e3*(lambda[i])))
        endfor
        ;endif
        end
      6:  begin ;'ergs/s/cm^2/Hz'
        ;if ~STRMATCH(state.unitslist(event.index),'') then begin
        for i=0,CommonWavVect[2]-1 do begin
        cubef3D[*,*,i]*=((1e3*(lambda[i]))/1.509e30)
        endfor
        ;endif
        end
      endcase
    
	*(dataset.currframe[0])=cubef3D

	FXADDPAR, *(dataset.headers)[numfile], 'FSCALE', convfac*(exptime) ;fscale to convert from counts to 'ph/s/nm/m^2'
	FXADDPAR, *(dataset.headers)[numfile], 'CUNIT',  unitslist[unitschoice]  

	suffix+='-phot'
  sxaddhist, functionname+": applying photometric calib", *(dataset.headers[numfile])
  sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
  
@__end_primitive
;;	thisModuleIndex = Backbone->GetCurrentModuleIndex()
;;    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;;		  if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;;    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix ,display=display)
;;    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;;    endif else begin
;;      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;;          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
;;    endelse
;;
;;
;;;drpPushCallStack, functionName
;;return, ok
;;

end
