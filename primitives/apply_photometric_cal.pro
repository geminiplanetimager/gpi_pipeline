;+
; NAME: apply_photometric_cal
; PIPELINE PRIMITIVE DESCRIPTION: Calibrate Photometric Flux
;
; INPUTS: data-cube
;
; GEM/GPI KEYWORDS:EXPTIME,FILTER,IFSFILT,HMAG,IFSUNITS,SECDIAM,SPECTYPE,TELDIAM
; DRP KEYWORDS: CUNIT,FILETYPE,FSCALE,HISTORY,ISCALIB,PSFCENTX,PSFCENTY,SPOT1x,SPOT1y,SPOT2x,SPOT2y,SPOT3x,SPOT3y,SPOT4x,SPOT4y,SPOTWAVE
; OUTPUTS:  
;
; PIPELINE COMMENT: Apply photometric calibration using satellite flux 
; PIPELINE ARGUMENT: Name="FinalUnits" Type="int" Range="[0,10]" Default="1" Desc="0:Counts, 1:Counts/s, 2:ph/s/nm/m^2, 3:Jy, 4:W/m^2/um, 5:ergs/s/cm^2/A, 6:ergs/s/cm^2/Hz"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.51
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: SpectralScience
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   JM 2010-03 : added sat locations & choice of final units
;   JM 2010-08 : routine optimized with simulated test data
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2011-07-30 MP: Updated for multi-extension FITS
;    2013-11-13 JM: major updates for better sat spot flux measurement
;- 

function apply_photometric_cal, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history

@__start_primitive



  	cube=*(dataset.currframe[0])

       filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  	
        ;get the common wavelength vector
            ;error handle if extractcube not used before
    if ((size(cube))[0] ne 3) || (strlen(filter) eq 0)  then $
        return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before.')        
    cwv=get_cwv(filter)
    CommonWavVect=cwv.CommonWavVect
    lambda=cwv.lambda
    lambdamin=CommonWavVect[0]
    lambdamax=CommonWavVect[1]


;;grab satspots 

tmp = backbone->get_keyword("SATSMASK", ext_num=1, count=ct)
if ct eq 0 then $
   return, error('FAILURE ('+functionName+'): SATSMASK undefined.  Use "Measure satellite spot locations" before this one.')

goodcode = hex2bin(tmp,(size(cube,/dim))[2])
good = long(where(goodcode eq 1))
cens = fltarr(2,4,(size(cube,/dim))[2])
for s=0,n_elements(good) - 1 do begin 
   for j = 0,3 do begin 
      tmp = fltarr(2) + !values.f_nan 
      reads,backbone->get_keyword('SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2),ext_num=1),tmp,format='(F7," ",F7)' 
      cens[*,j,good[s]] = tmp 
   endfor 
endfor

;;error handle if sat spots haven't been found
tmp = backbone->get_keyword("SATSWARN", ext_num=1, count=ct)
if ct eq 0 then $
   return, error('FAILURE ('+functionName+'): SATSWARN undefined.  Use "Measure satellite spot fluxes" before this one.')

;;grab sat fluxes
warns = hex2bin(tmp,(size(cube,/dim))[2])
satflux = fltarr(4,(size(cube,/dim))[2])
for s=0,n_elements(good) - 1 do begin
   for j = 0,3 do begin 
      satflux[j,good[s]] = backbone->get_keyword('SATF'+strtrim(long(good[s]),2)+'_'+strtrim(j,2),ext_num=1) 
   endfor 
endfor

;;get grid fac
apodizer = backbone->get_keyword('APODIZER', count=ct)
if strcmp(apodizer,'UNKNOWN',/fold_case) then begin
   val = backbone->get_keyword('OCCULTER', count=ct)
   if ct ne 0 then begin
      res = stregex(val,'FPM_([A-Za-z])',/extract,/subexpr)
      if res[1] ne '' then apodizer = res[1]
   endif
endif 
gridfac = gpi_get_gridfac(apodizer)
if ~finite(gridfac) then return, error('FAILURE ('+functionName+'): Could not match apodizer.')

    ;nbphot_juststar=pip_nbphot_trans(hdr,lambdapsf)
    nbphot_juststar=pip_nbphot_trans_lowres([*(dataset.headersPHU)[numfile],*(dataset.headersExt)[numfile]],lambda)

   magni=double(backbone->get_keyword( 'HMAG'))
   spect=strcompress(backbone->get_keyword( 'SPECTYPE'),/rem)
        Dtel=gpi_get_constant('primary_diam',default=7.7701d0)
    Obscentral=gpi_get_constant('secondary_diam',default=1.02375d0)
   exposuretime=double(backbone->get_keyword( 'ITIME')) ;TODO use ITIME instead
   ;BE SURE THAT TIME keyword IS IN SECONDS
   ;filter=backbone->get_keyword( 'FILTER')
   nlambda=n_elements(lambda)
   widthL=(lambdamax-lambdamin)
   SURFA=!PI*(Dtel^2.)/4.-!PI*((Obscentral)^2.)/4.
   gaindetector=1. ;1.1 ;from ph to count: IS IT IN THE KEYWORD LIST?
   ifsunits=strcompress(backbone->get_keyword( 'BUNIT'),/rem)

;; normalize by n_elements(lambdapsf) because widthL is the width of the entire band here
   nbphotnormtheo=nbphot_juststar*float(n_elements(lambda))/(SURFA*widthL*1.e3*exposuretime) ;photons to [photons/s/nm/m^2]

gridratio=replicate(gridfac,n_elements(lambda))

;;here is the flux conversion factor!
convfac=fltarr(n_elements(nbphotnormtheo))
for i=0,n_elements(nbphotnormtheo)-1 do $
convfac[i]=((nbphotnormtheo[i]*(gridratio[i]))/(gaindetector*( mean(satflux[*,i])))) ;TODO implement good[s]? for satflux

;http://www.gemini.edu/sciops/instruments/?q=sciops/instruments&q=node/10257  
;assume IFSUNITS is always in Counts/s/coadd
;convert datacube from IFSunits  to [photons/s/nm/m^2]
cubef3D=cube; JM:todo:use only one variable for the cube
        for i=0,CommonWavVect[2]-1 do   cubef3D[*,*,i]*=double(convfac[i])
        

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
	backbone->set_keyword, 'FSCALE'+strc(i), convfac[i]*(exposuretime), "scale to convert from counts to 'ph/s/nm/m^2", ext_num=1
	backbone->set_keyword, 'CUNIT',  unitslist[unitschoice] ,"Data units", ext_num=0
	;update raw IFS units:
	backbone->set_keyword, 'BUNIT',  unitslist[unitschoice] ,"Data units", ext_num=0
		;FXADDPAR, *(dataset.headersExt)[numfile], 'FSCALE'+strc(i), convfac[i]*(exposuretime) ;fscale to convert from counts to 'ph/s/nm/m^2'
	;FXADDPAR, *(dataset.headersExt)[numfile], 'CUNIT',  unitslist[unitschoice]  

	suffix+='-phot'
;  sxaddhist, functionname+": applying photometric calib", *(dataset.headers[numfile])
;  sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
;  fsxaddpar,*(dataset.headersPHU[numfile]),'HISTORY',functionname+": applying photometric calib"
;  fxaddpar,*(dataset.headersPHU[numfile]),'HISTORY',functionname+": "+c_File

@__end_primitive


end
