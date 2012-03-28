;+
; NAME: apply_photometric_cal_extended
; PIPELINE PRIMITIVE DESCRIPTION: Calibrate Photometric Flux of extented object 
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
; PIPELINE COMMENT: Apply photometric calibration of extented object 
; PIPELINE ARGUMENT: Name="FinalUnits" Type="int" Range="[0,10]" Default="1" Desc="0:Counts, 1:Counts/s, 2:ph/s/nm/m^2, 3:Jy, 4:W/m^2/um, 5:ergs/s/cm^2/A, 6:ergs/s/cm^2/Hz"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="Fluxconv" Default="GPI-fluxconv.fits" Desc="Filename of the desired flux calibration file to be read"
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
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2010-11-16 JM: save conversion factor in Calibration DataBase for eventual future use (with extended object)
;- 

function apply_photometric_cal_extented, DataSet, Modules, Backbone

primitive_version= '$Id: apply_photometric_cal_extented.pro 96 2010-11-16 13:47:13Z maire $' ; get version from subversion to store in header history
calfiletype='Fluxconv' 
@__start_primitive


  	cubef3D=*(dataset.currframe[0])
  	filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
        ;get the common wavelength vector
            ;error handle if extractcube not used before
            if ((size(cubef3D))[0] ne 3) || (strlen(filter) eq 0)  then $
            return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before.')        
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]
       
      
    ;if numext eq 0 then hdr= *(dataset.headers)[numfile] else hdr= *(dataset.headersPHU)[numfile]
       exposuretime=double(backbone->get_keyword( 'ITIME'))

;      fits_info, c_File, /silent, N_ext=n_ext
;    if n_ext eq 0 then  $
;    pmd_fluxcalFrame        = ptr_new(READFITS(c_File, Headerphot, /SILENT)) else $
;      pmd_fluxcalFrame        = ptr_new(mrdfits(c_File, 1, Headerphot, /SILENT)) 
;    ;lambda_gridratio=*pmd_fluxcalFrame
;    lambda_convfac=*pmd_fluxcalFrame
    lambda_convfac = gpi_readfits(c_File,header=Headerphot)
    
    ;;to do: be sure same wavelengths are used and n_elements is ok
    lambdaconvfac=lambda_convfac[*,0]
    convfac=lambda_convfac[*,1]
 ;   fluxratio=*pmd_fluxcalFrame

	;hdr= *(dataset.headers)[0]





;convfac=*pmd_fluxcalFrame  ;fltarr(n_elements(nbphotnormtheosmoothed))
;for i=0,n_elements(nbphotnormtheosmoothed)-1 do $
;convfac[i]=((nbphotnormtheosmoothed[i])/(gaindetector*(gridratio[i])*(fluxsatmedabs[i])))


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
  backbone->set_keyword, 'FSCALE'+strc(i), convfac[i]*(exposuretime), "scale to convert from counts to 'ph/s/nm/m^2", ext_num=1
  backbone->set_keyword, 'CUNIT',  unitslist[unitschoice] ,"Data units", ext_num=0
backbone->set_keyword, 'BUNIT',  unitslist[unitschoice] ,"Data units", ext_num=0
  
	suffix+='-phot'
;  sxaddhist, functionname+": applying photometric calib", *(dataset.headers[numfile])
;  sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])

    backbone->set_keyword,'HISTORY',functionname+": applying photometric calib",ext_num=1
    backbone->set_keyword,'HISTORY',functionname+": "+c_File,ext_num=1


@__end_primitive


end
