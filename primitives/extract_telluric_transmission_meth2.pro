;+
; NAME: Extract_telluric_transmission_meth2
; PIPELINE PRIMITIVE DESCRIPTION: Extract telluric transmission from datacube
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
; PIPELINE COMMENT: Extract Telluric Spectrum from star spec estimated from datacube
; PIPELINE ARGUMENT: Name="Correct_datacube" Type="int" Range="[0,1]" Default="1" Desc="1: Correct datacube from extracted tell trams., 0: don't correct"
; PIPELINE ARGUMENT: Name="Save_corrected_datacube" Type="int" Range="[0,1]" Default="1" Desc="1: save corrected datacube on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="Save_telluric_transmission" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-telcal" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="Xspot1" Type="int" Range="[0,2048]" Default="97" Desc="Initial approximate x-position [pixel] of sat. spot 1"
; PIPELINE ARGUMENT: Name="Yspot1" Type="int" Range="[0,2048]" Default="117" Desc="Initial approximate y-position [pixel] of sat. spot 1"
; PIPELINE ARGUMENT: Name="Xspot2" Type="int" Range="[0,2048]" Default="179" Desc="Initial approximate x-position [pixel] of sat. spot 2"
; PIPELINE ARGUMENT: Name="Yspot2" Type="int" Range="[0,2048]" Default="159" Desc="Initial approximate y-position [pixel] of sat. spot 2"
; PIPELINE ORDER: 2.52
; PIPELINE TYPE: ALL-SPEC HIDDEN
; PIPELINE NEWTYPE: SpectralScience
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Jerome Maire 2009-12
;- 

function extract_telluric_transmission_meth2, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS

primitive_version= '$Id$' ; get version from subversion to store in header history

    getmyname, functionname
  thisModuleIndex = Backbone->GetCurrentModuleIndex()

  cubef3D=*(dataset.currframe[0])

;;TOCHECK: is datacube registered?

lambda=dblarr((size(cubef3D))[3])
lambdamin=CommonWavVect[0] &  lambdamax=CommonWavVect[1]
CommonWavVect[2]=double((size(cubef3D))[3])
for i=0,CommonWavVect(2)-1 do lambda[i]=lambdamin+(lambdamax-lambdamin)/(2.*CommonWavVect[2])+double(i)*(lambdamax-lambdamin)/(CommonWavVect[2])

hdr= *(dataset.headers)[0]

;;To change: this following 2 lines will have to change: need to handle properly registration..
cubcent=cubef3D[2:278,2:278,*]
for i=0,CommonWavVect[2]-1 do  cubcent[*,*,i]=transpose(cubcent[*,*,i])


L2m=lambdamin
cubcent2=cubcent
wnf1 = where(~FINITE(cubcent),nancount1)
if nancount1 gt 0 then cubcent(wnf1)=0.
for i=0,CommonWavVect[2]-1 do cubcent2[0:275,0:275,i]=fftscale(cubcent[0:275,0:275,i],double(L2m)/double(lambda[i]),double(L2m)/double(lambda[i]),1e-7)


phpadu = 1.0                    ; don't convert counts to electrons
apr = [3.]
skyrad = [8.,12.]
; Assume that all pixel values are good data
badpix = [-1.,1e6];state.image_min-1, state.image_max+1

;;extract photometry of SAT 
cx=88 & cy=151 & ll=6

carotdc=cubcent2[cx-ll:cx+ll,cy-ll:cy+ll,*]

fluxsatmedabs=dblarr(CommonWavVect[2])
for i=0,CommonWavVect[2]-1 do fluxsatmedabs[i]=((double(lambda[i])/double(L2m))^2)*median(carotdc[*,*,i])/(nbphot[i]*transinstru) ;*Transmfilt[i]



;;;se placer a la res spectrale limite de l instrument pour spectre theorique:
WavVect=CommonWavVect
WavVect[2]=10
lambda_nominalres=fltarr(WavVect[2])
for i=0,WavVect[2]-1 do lambda_nominalres[i]=lambdamin+(lambdamax-lambdamin)/(2.*WavVect[2])+double(i)*(lambdamax-lambdamin)/(WavVect[2])

nbphotnominal=PIP_nbphot_trans(hdr,lambda_nominalres) 
;se replacer a la resolution spectrale  effective de travail:
          lambint=lambda_nominalres
          ;for bandpass normalization
          bandpassmoy=mean(lambint[1:(size(lambint))[1]-1]-lambint[0:(size(lambint))[1]-2],/DOUBLE)
          bandpassmoy_interp=mean(lambda[1:(size(lambda))[1]-1]-lambda[0:(size(lambda))[1]-2],/DOUBLE)
          norma=bandpassmoy_interp/bandpassmoy

          nbphot = norma*INTERPOL( nbphotnominal, lambint, lambda )

fluxsatmedabs/=nbphot
fluxsatmedabs/=max(fluxsatmedabs)



if tag_exist( Modules[thisModuleIndex], "Save_telluric_transmission") && ( Modules[thisModuleIndex].Save_telluric_transmission eq 1 ) then begin
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
