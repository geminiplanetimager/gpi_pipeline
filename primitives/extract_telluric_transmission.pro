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

    getmyname, functionname
  thisModuleIndex = Backbone->GetCurrentModuleIndex()

  cubef3D=*(dataset.currframe[0])

lambda=dblarr((size(cubef3D))[3])
lambdamin=CommonWavVect[0] &  lambdamax=CommonWavVect[1]
CommonWavVect[2]=double((size(cubef3D))[3])
for i=0,CommonWavVect(2)-1 do lambda[i]=lambdamin+(lambdamax-lambdamin)/(2.*CommonWavVect[2])+double(i)*(lambdamax-lambdamin)/(CommonWavVect[2])

hdr= *(dataset.headers)[0]

;;To change: this following 2 lines will have to change: need to handle properly registration..
;cubcent=cubef3D[2:278,2:278,*]
;for i=0,CommonWavVect[2]-1 do  cubcent[*,*,i]=transpose(cubcent[*,*,i])


;L2m=lambdamin
;cubcent2=cubcent
;wnf1 = where(~FINITE(cubcent),nancount1)
;if nancount1 gt 0 then cubcent(wnf1)=0.
;for i=0,CommonWavVect[2]-1 do cubcent2[0:275,0:275,i]=fftscale(cubcent[0:275,0:275,i],double(L2m)/double(lambda[i]),double(L2m)/double(lambda[i]),1e-7)


phpadu = 1.0                    ; don't convert counts to electrons
apr = [3.]
skyrad = [8.,12.]
; Assume that all pixel values are good data
badpix = [-1.,1e6];state.image_min-1, state.image_max+1


if ( Modules[thisModuleIndex].method eq 1 ) then begin
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
            print, 'slice#',i,' flux sat #'+strc(spot)+'=',flux[0],'at positions ['+strc(x)+','+strc(y)+']',' sky=',sky[0]
          intens_sat[spot-1,i]=(flux[0]-sky[0])
      endfor
    
    endfor
     
    for i=0,CommonWavVect[2]-1 do fluxsatmedabs[i]=((double(lambda[i])/double(lambdamin))^1.)*mean(intens_sat[*,i],/nan)
    
endif

if ( Modules[thisModuleIndex].method eq 2 ) then begin
      cx=88 & cy=151 & ll=6
      L2m=lambdamin
      carotdc=cubcent2[cx-ll:cx+ll,cy-ll:cy+ll,*]

      fluxsatmedabs=dblarr(CommonWavVect[2])
      for i=0,CommonWavVect[2]-1 do fluxsatmedabs[i]=((double(lambda[i])/double(L2m))^2.)*median(carotdc[*,*,i])/(nbphot[i]*transinstru) ;*Transmfilt[i]
      
endif

;;;se placer a la res spectrale limite de l instrument pour spectre theorique:
WavVect=CommonWavVect
WavVect[2]=10
lambda_nominalres=fltarr(WavVect[2])
for i=0,WavVect[2]-1 do lambda_nominalres[i]=lambdamin+(lambdamax-lambdamin)/(2.*WavVect[2])+double(i)*(lambdamax-lambdamin)/(WavVect[2])

nbphotnominal=pip_nbphot_trans(hdr,lambda_nominalres) 
;se replacer a la resolution spectrale  effective de travail:
          lambint=lambda_nominalres
          ;for bandpass normalization
          bandpassmoy=mean(lambint[1:(size(lambint))[1]-1]-lambint[0:(size(lambint))[1]-2],/DOUBLE)
          bandpassmoy_interp=mean(lambda[1:(size(lambda))[1]-1]-lambda[0:(size(lambda))[1]-2],/DOUBLE)
          norma=bandpassmoy_interp/bandpassmoy

          nbphot = norma*INTERPOL( nbphotnominal, lambint, lambda )

fluxsatmedabs/=nbphot
fluxsatmedabs/=max(fluxsatmedabs)

window, 0
plot, fluxsatmedabs
stop

if tag_exist( Modules[thisModuleIndex], "Save_telluric_transmission") && ( Modules[thisModuleIndex].Save_telluric_transmission eq 1 ) then begin
   ; Set keywords for outputting files into the Calibrations DB
  sxaddpar, hdr, "FILETYPE", "Telluric transmission", "What kind of IFS file is this?"
  sxaddpar, hdr,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'  
  suffixtelluric='-tellucal'
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffixtelluric,savedata=fluxsatmedabs,saveheader=hdr)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')

endif
if tag_exist( Modules[thisModuleIndex], "Correct_datacube")&& ( Modules[thisModuleIndex].Correct_datacube eq 1 ) then begin
  for ii=0,CommonWavVect[2]-1 do (*(dataset.currframe[0]))[*,*,ii]/=fluxsatmedabs[ii]


if tag_exist( Modules[thisModuleIndex], "Save_corrected_datacube") && tag_exist( Modules[thisModuleIndex], "suffix") then suffix+=Modules[thisModuleIndex].suffix

    if tag_exist( Modules[thisModuleIndex], "Save_corrected_datacube") && ( Modules[thisModuleIndex].Save_corrected_datacube eq 1 ) then begin
		  if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
    endelse

endif

return, ok


end
