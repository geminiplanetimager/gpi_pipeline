;+
; NAME: gpi_calibrate_photometric_flux
; PIPELINE PRIMITIVE DESCRIPTION: Calibrate Photometric Flux 
;
;	This primitive applies a spectrophotometric calibrations to the datacube that is determined either from the satellite spots of the supplied cube, the satellite spots of a user-indicated cube, or any user-supplied spectral response function (e.g. derived from an open loop image of a standard star). 
;
; The user may also specify the extraction and sky radii used in performing the aperture photometry.
;
; WARNING: the user-supplied spectral response function is not yet implemented.
;	
;
; INPUTS: 
; 1: datacube that requires calibration (loaded as an Input FITS file)
; AND
; 2a: datacube or to be used to determine the calibration (with or without a accompanying model spectrum of the star)
; OR
; 2b: a 2D spectrum (in ADU per COADD, where the COADD corresponds to input #1). The file format must be three columns, the first being wavelength in microns, the second being the flux in erg/s/cm2/A, the third being the uncertainty
;
; if neither 2a nor 2b or defined, the satellites of the input file are used.
;
; calib_cube_name and calib_model_spectrum require the entire directory+filename unless they are in the output directory
; calib_spectrum requires the full filename
;
; KEYWORDS:
;	/Save	Set to 1 to save the output datacube to a disk file 
;
; GEM/GPI KEYWORDS:FILTER,IFSUNIT
; DRP KEYWORDS: CUNIT,DATAFILE
; OUTPUTS:  
;
; PIPELINE COMMENT: Extract one spectrum from a datacube somewhere in the FOV specified by the user.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="extraction_radius" Type="float" Range="[0,1000]" Default="3." Desc="Aperture radius at middle wavelength (in spaxels i.e. mlens) to extract photometry for each wavelength. "
; PIPELINE ARGUMENT: Name="inner_sky_radius" Type="float" Range="[1,100]" Default="10." Desc="Inner aperture radius at middle wavelength (in spaxels i.e. mlens) to extract sky for each wavelength. "
; PIPELINE ARGUMENT: Name="outer_sky_radius" Type="float" Range="[1,100]" Default="15." Desc="Outer aperture radius at middle wavelength (in spaxels i.e. mlens) to extract sky for each wavelength. "
; PIPELINE ARGUMENT: Name="c_ap_scaling" Type="int" Range="[0,1]" Default="1" Desc="Perform aperture scaling with wavelength?"
; PIPELINE ARGUMENT: Name="calib_cube_name" Type="string" Default="" Desc="Leave blank to use satellites of this cube, or enter a file to use those satellites"
; PIPELINE ARGUMENT: Name="calib_model_spectrum" Type="string" Default="" Desc="Leave blank to use satellites of this cube, or enter a file to use with the spectrum for the satellites"
; PIPELINE ARGUMENT: Name="calib_spectrum" Type="string" Default="" Desc="Leave blank to use satellites of this cube, or enter calibrated spectrum file"
; PIPELINE ARGUMENT: Name="FinalUnits" Type="int" Range="[0,10]" Default="1" Desc="0: ADU per coadd, 1: ADU/s, 2: ph/s/nm/m^2, 3: Jy, 4: 'W/m^2/um, 5: ergs/s/cm^2/A, 6: ergs/s/cm^2/Hz'"

; PIPELINE ORDER: 2.51
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: SpectralScience
; PIPELINE SEQUENCE: 
;
; HISTORY:
;		2014-01-07 PI: Created Module - big overhaul from the original apply_photometric_calibration 	
;
;   JM 2010-03 : created module.
;   2012-10-17 MP: Removed deprecated suffix keyword. FIXME this needs major
;   cleanup!
;   2013-08-07 ds: idl2 compiler compatible 
;- 

function gpi_calibrate_photometric_flux, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history

  @__start_primitive
 suffix='-phot'
 
     
  thisModuleIndex = Backbone->GetCurrentModuleIndex()

	if tag_exist( Modules[thisModuleIndex], "calib_cube_name") then calib_cube_name=string(Modules[thisModuleIndex].calib_cube_name) else calib_cube_name=''
	if tag_exist( Modules[thisModuleIndex], "calib_model_spectrum") then calib_model_spectrum=string(Modules[thisModuleIndex].calib_model_spectrum) else calib_model_spectrum=''
	if tag_exist( Modules[thisModuleIndex], "calib_spectrum") then calib_spectrum=string(Modules[thisModuleIndex].calib_spectrum) else calib_spectrum=''
	if tag_exist( Modules[thisModuleIndex], "extraction_radius") then extraction_radius=float(Modules[thisModuleIndex].extraction_radius) else extraction_radius=3
	if tag_exist( Modules[thisModuleIndex], "inner_sky_radius") then inner_sky_radius=float(Modules[thisModuleIndex].inner_sky_radius) else inner_sky_radius=10
	if tag_exist( Modules[thisModuleIndex], "outer_sky_radius") then outer_sky_radius=float(Modules[thisModuleIndex].outer_sky_radius) else outer_sky_radius=15
	if tag_exist( Modules[thisModuleIndex], "c_ap_scaling") then c_ap_scaling=float(Modules[thisModuleIndex].c_ap_scaling) else c_ap_scaling=1
	if tag_exist( Modules[thisModuleIndex], "FinalUnits") then FinalUnits=long(Modules[thisModuleIndex].FinalUnits) else FinalUnits=5
	if tag_exist( Modules[thisModuleIndex], "gpitv") then gpitv=long(Modules[thisModuleIndex].gpitv) else gpitv=5
	if tag_exist( Modules[thisModuleIndex], "save") then save=long(Modules[thisModuleIndex].save) else save=0




; Warn the user about a stupid issue that results in gpitv not displaying the output if it is not saved.
if gpitv ne 0 and save eq 0 then begin 
return, error('FAILURE ('+functionName+'): A silly bug makes it such that in order to view the file in GPItv it must be saved. Set save equal to 1, or GPItv equal to 0 in order to run this primitive')

endif

band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=cc))
cwv=get_cwv(band)
CommonWavVect=cwv.CommonWavVect
lambda=cwv.lambda

; if nothing is supplied, then we use the cube itself.
if strc(calib_spectrum) eq '' and strc(calib_cube_name) eq '' then begin
	backbone->Log,functionname+":  calib_spectrum nor calib_cube_name specified, using the sat spots in the supplied cube"+string(calib_cube_name)+" to generate calibration"
	calib_cube_struct={image:dataset.currframe[numfile],pri_header:dataset.headersphu[numfile],ext_header:dataset.headersext[numfile]}
endif

; first have to determine if a calibration spectrum is supplied

if calib_spectrum ne '' then begin
	;load in the calibration spectrum, do not do any satellite business
	if file_test(calib_spectrum) eq 1 then begin
		backbone->Log,functionname+"   Loading calibration spectrum "+string(calib_spectrum)
		if keyword_set(calib_cube_name) eq 1 then	backbone->Log,functionname+"This will result in ignoring the provided calibration cube" +string(calib_cube_name)
		backbone->Log,functionname+ ':   WARNING- this has not been thoroughly tested and is extremely dangerous to use. Systematics can be easily introduced!'
		; interpolate to our wavelengths
		readcol,waves,response_curve0,response_curve_err0
		response_curve=interpol(response_curve0,waves,lambda)
		response_curve_err=interpol(response_curve_err0,waves,lambda)
		for l=0, N_ELEMENTS(lambda)-1 do calibrated_cube[*,*,l]*=(1.0/response_curve[l])
		for l=0, N_ELEMENTS(lambda)-1 do calibrated_cube_err[*,*,l]*=(1.0/response_curve[l])
		contained_flux_ratio=1.0  ; assume that no flux correction is necessary
	endif else begin
		backbone->Log,functionname+':   User specified calib_spectrum does not exist; check filename and directory. Aborting sequence'
		return, not_ok
	endelse	 ; file_test for calib_spectrum
endif ; calibration for calib_spectrum


; start by doing photometry of sat spots - if needed
if keyword_set(calib_cube_name) eq 1 or keyword_set(calib_cube_struct) eq 1 then begin

; check to see if it is already declared above - if not - then find it! 
	if keyword_set(calib_cube_struct) eq 0 then begin 
		if file_test(calib_cube_name) eq 1 then begin ; is it in the current directory
			; check to see that the cube name is equal to the filename...
			; if so, write a structure that is equivalent to reading one in.
			logstr = functionname+":  Loading calibration cube "+string(calib_cube_name)
			backbone->Log,logstr
			calib_cube_struct=gpi_load_fits(calib_cube_name)
		endif else begin ; no - is it in the Reduced directory?
			;yes?
			if file_test(Modules[thisModuleIndex].OutputDir+path_sep()+calib_cube_name) eq 1 then begin
				logstr = functionname+':  User specified cube name does not contain a directory, using the output directory to get '+string(calib_cube_name)
				backbone->Log,logstr
				calib_cube_struct=gpi_load_fits(Modules[thisModuleIndex].OutputDir+path_sep()+calib_cube_name)
			endif else begin ; no? - then fail
				logstr = functionname+':  User specified cube name does not exist; check filename and directory. Aborting sequence'
				backbone->Log,logstr
				return, not_ok
			endelse
		endelse
	endif
calib_cube=*calib_cube_struct.image ; ADU/coadd

;grab satspots 
tmp = sxpar(*calib_cube_struct.ext_header,"SATSMASK",count=ct)
if ct eq 0 then return, error('FAILURE ('+functionName+'): SATSMASK undefined.  Use "Measure satellite spot locations" before this one.')
goodcode = hex2bin(tmp,(size(calib_cube,/dim))[2])
good = long(where(goodcode eq 1))
cens = fltarr(2,4,(size(calib_cube,/dim))[2])
for s=0,n_elements(good) - 1 do begin 
   for j = 0,3 do begin 
      tmp = fltarr(2) + !values.f_nan 
;      reads,backbone->get_keyword('SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2),ext_num=1),tmp,format='(F7," ",F7)'
			reads,sxpar(*calib_cube_struct.ext_header,'SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2)),tmp,format='(F7," ",F7)'
      cens[*,j,good[s]] = tmp 
   endfor 
endfor

;;error handle if sat spots haven't been found
tmp =  sxpar(*calib_cube_struct.ext_header,"SATSWARN",count=ct)
if ct eq 0 then return, error('FAILURE ('+functionName+'): SATSWARN undefined.  Use "Measure satellite spot fluxes" with Save=1 on the calibration cube before this one.')

; extract the flux of the satellite spots 
  sat1flux = fltarr(n_elements(cens[0,0,*]))    ;;top left
  sat2flux = fltarr(n_elements(cens[0,0,*]))    ;;bottom left
  sat3flux = fltarr(n_elements(cens[0,0,*]))    ;;top right
  sat4flux = fltarr(n_elements(cens[0,0,*]))    ;;bottom right
  mean_sat_flux = fltarr(n_elements(cens[0,0,*]))
	stddev_sat_flux=  fltarr(n_elements(cens[0,0,*]))

	if c_ap_scaling eq 1 then begin
  aperrad0=extraction_radius/lambda[N_ELEMENTS(lambda)/2]  
	sat_skyrad0 =[inner_sky_radius, outer_sky_radius]/lambda[N_ELEMENTS(lambda)/2]
		endif else begin
	aperrad0=extraction_radius/lambda 
	sat_skyrad0 =[inner_sky_radius, outer_sky_radius]/lambda
	endelse
 	phpadu = 1.0 
  for s=0,n_elements(cens[0,0,*])-1 do begin
	aperrad = aperrad0*lambda[s]
 	sat_skyrad = sat_skyrad0*lambda[s]

     ;;using aperature radius 3 pixels
     aper, calib_cube[*,*,s],cens[0,0,s],cens[1,0,s],flux,eflux,sky,skyerr,phpadu,aperrad,sat_skyrad,[0,0],/flux,/exact,/nan,/silent 
     sat1flux[s]=flux
     aper, calib_cube[*,*,s],cens[0,1,s],cens[1,1,s],flux,eflux,sky,skyerr,phpadu,aperrad,sat_skyrad,[0,0],/flux,/exact,/nan,/silent
     sat2flux[s]=flux
     aper, calib_cube[*,*,s],cens[0,2,s],cens[1,2,s],flux,eflux,sky,skyerr,phpadu,aperrad,sat_skyrad,[0,0],/flux,/exact,/nan,/silent
     sat3flux[s]=flux
     aper, calib_cube[*,*,s],cens[0,3,s],cens[1,3,s],flux,eflux,sky,skyerr,phpadu,aperrad,sat_skyrad,[0,0],/flux,/exact,/nan,/silent
     sat4flux[s]=flux
     ;;calculate a median satellite spectrum
     mean_sat_flux[s]=median([sat1flux[s], sat2flux[s], sat3flux[s], sat4flux[s]],/even) ; counts/slice
		 stddev_sat_flux[s]=robust_sigma([sat1flux[s], sat2flux[s], sat3flux[s], sat4flux[s]]) ; counts/slice
			if stddev_sat_flux[s] eq -1 then stddev_sat_flux[s]=stddev([sat1flux[s], sat2flux[s], sat3flux[s], sat4flux[s]])
		
		; Must approximate a ratio between the flux in the aperture, and the flux outside the aperture.
		; The truth is that we really don't have a good idea of how it changes radially. What we do know is that it is about 
		; 0.6 for a 3 pixel radius and about 1.0 for a 10 pixel radius (at 1.6um)

; this is super dangerous because it depends on the PSF (so the seeing and the correction)
			contained_flux_ratio=0.6
			mean_sat_flux/=contained_flux_ratio
			stddev_sat_flux[s]/=contained_flux_ratio
	  endfor
	norm1=median(sat1flux[5:N_ELEMENTS(lambda)-5]) ; do not use the low throughput regions of the filter bands
	norm2=median(sat2flux[5:N_ELEMENTS(lambda)-5])
	norm3=median(sat3flux[5:N_ELEMENTS(lambda)-5])
	norm4=median(sat4flux[5:N_ELEMENTS(lambda)-5])
	mean_norm=mean([norm1,norm2,norm3,norm4])

	for s=0,n_elements(cens[0,0,*])-1 do begin
  mean_sat_flux[s]=median([sat1flux[s]/norm1, sat2flux[s]/norm2, sat3flux[s]/norm3, sat4flux[s]/norm4],/even)*mean_norm ; counts/slice
	; now look at scaling the values to remove net flux offsets
	 stddev_sat_flux[s]=robust_sigma([sat1flux[s]/norm1, sat2flux[s]/norm2, sat3flux[s]/norm3, sat4flux[s]/norm4]) ; counts/slice
		if stddev_sat_flux[s] eq -1 then stddev_sat_flux[s]=stddev([sat1flux[s]/norm1, sat2flux[s]/norm2, sat3flux[s]/norm3, sat4flux[s]/norm4])

	stddev_sat_flux[s]*=mean_sat_flux[s]
	endfor

if 0 eq 1 then begin
window,19
device,decomposed=0
;loadcolors
ploterror, lambda, mean_sat_flux,stddev_sat_flux, xr=[min(lambda),max(lambda)],/xs,xtitle='wavelength', ytitle='sat spot intensity (ADU)',charsize=1.5,background=255,color=0,thick=2
oplot, lambda,(sat1flux/norm1)*mean_norm, color=255/5*1,linestyle=2,thick=2
oplot, lambda,sat2flux/norm2*mean_norm, color=255/5*2,linestyle=3,thick=2
oplot, lambda,sat3flux/norm3*mean_norm, color=255/5*3,linestyle=4,thick=2
oplot, lambda,sat4flux/norm4*mean_norm, color=255/5*4,linestyle=5,thick=2
pi_legend,['median(even)','UL sat','LL sat','UR sat','LR sat'],color=[0,255/5*1,255/5*2,255/5*3,255/5*4],linestyle=[0,2,3,4,5],textcolor=1,box=0,/top,/right
;stop
endif



; this is meant to determine what you need to multiply by in order to calibrate your spectrum
; calibrated spectrum=spectrum/reference_spectrum * converted_model_reference_spectrum
unitslist = ['ADU per coadd', 'ADU/s','ph/s/nm/m^2', 'Jy', 'W/m^2/um','ergs/s/cm^2/A','ergs/s/cm^2/Hz']


; check if the user supplied a magnitude for the band that can be used instead of the HMAG in the header
;test=sxpar(*(dataset.headersPHU[numfile]),"MAGNITUD",count=ct)
;if ct[0] ne 0 then begin
;	star_mag=test[0]
;	backbone->Log,functionname+":  Using user specified magnitude value instead of "+strc(star_mag)+" instead of the default HMAG keyword"
;endif

; should actually put in the data from the calibration cube!
; aso have to pass a variable with the calib_model_spectrum

converted_model_spectrum = gpi_photometric_calibration_calculation(lambda,*(dataset.headersPHU[numfile]),*(dataset.headersExt[numfile]),units=FinalUnits,ref_model_spectrum=calib_model_spectrum,ref_star_magnitude=star_mag, ref_filter_type=ref_filter_type, ref_SpType=SpType)

if converted_model_spectrum[0] eq -1 then return, error('FAILURE ('+functionName+'): Could not perform photometric calibration, incorrect keywords and/or input to the gpi_photometric_calibration_calculation function ') 

; now correct the spectrum
calibrated_cube=fltarr(281,281,N_ELEMENTS(lambda))
cube=*(dataset.currframe[0]) ; in ADU/coadd normally , but not always!!
conv_fact= 1.0/mean_sat_flux * converted_model_spectrum ; mean sat flux is also in ADU/coadd
for l=0, N_ELEMENTS(lambda)-1 do calibrated_cube[*,*,l]=cube[*,*,l] * conv_fact[l]
calibrated_cube_err=stddev_sat_flux * conv_fact

endif ; if keyword_set(calib_cube_name)

; skip here if a calib_spectrum is supplied but no calib_cube



; now we should write the cube
;*(dataset.currframe[0])=calibrated_cube
unitslist = ['ADU per coadd', 'ADU/s','ph/s/nm/m^2', 'Jy', 'W/m^2/um','ergs/s/cm^2/A','ergs/s/cm^2/Hz']
  	if keyword_set(calib_spectrum) then begin
			backbone->set_keyword,'HISTORY',functionname+ 'WARNING- this has not been thoroughly tested and is extremely dangerous to use. Systematics can be easily introduced!'
			backbone->set_keyword, 'CUNIT', "User_specified", "Data units", ext_num=1
			;update raw IFS units:
			backbone->set_keyword, 'BUNIT', "User_specified", "Data units", ext_num=1
			; put the response curve data into different variable names for ease of header writing
			conv_fact=(1.0/response_curve)
			cal_percent_err=(response_curve_err/response_curve)*100
				
		endif else begin
		backbone->set_keyword,'HISTORY',functionname+ " Converted Datacube to"+unitslist[FinalUnits]
		backbone->set_keyword, 'CUNIT',  unitslist[FinalUnits] ,"Data units", ext_num=1
		;update raw IFS units:
		backbone->set_keyword, 'BUNIT',  unitslist[FinalUnits] ,"Data units", ext_num=1
		backbone->set_keyword,'HISTORY',functionname+ " Used satellites from "+calib_cube_name
		backbone->set_keyword,'HISTORY',functionname+ " Used "+strc(calib_model_spectrum)+"for spectrophoto calib."
		backbone->set_keyword, 'CFILENAM', calib_cube_name,"Specphot calib cube file name", ext_num=0
		backbone->set_keyword, 'C_AP_SC', c_ap_scaling,"Calibrator aper scaling enabled ", ext_num=0
		backbone->set_keyword, 'CEXTR_AP', extraction_radius,"Calib. extr aper at "+strc(lambda[N_ELEMENTS(lambda)/2])+"um", ext_num=0
		backbone->set_keyword, 'CISKY_AP', inner_sky_radius,"Calib. inner sky rad at "+strc(lambda[N_ELEMENTS(lambda)/2])+"um", ext_num=0
		backbone->set_keyword, 'COSKY_AP', outer_sky_radius,"Calib. outer sky rad at "+strc(lambda[N_ELEMENTS(lambda)/2])+"um", ext_num=0
		; put the sat responses into different variable names for ease of header writing
		cal_percent_err=(stddev_sat_flux/mean_sat_flux)*100

		endelse

 	; must write calibration percent error (sat flux and sat error) in the header for proper error handling in spectral extraction
		for l=0, N_ELEMENTS(lambda)-1 do backbone->set_keyword, 'FSCALE'+strc(l), conv_fact[l],"scale to convert counts to "+strc(unitslist[FinalUnits]), ext_num=1
		for l=0, N_ELEMENTS(lambda)-1 do backbone->set_keyword, 'CERR_'+strc(l), cal_percent_err[l],"Cal percent error for slice "+strc(l), ext_num=1

;	write the contained flux ratio to the header
		backbone->set_keyword, 'EFLUXRAT',  contained_flux_ratio ,"flux ratio in photom aper", ext_num=0

*(dataset.currframe[numfile])=calibrated_cube

@__end_primitive 


end
