function gpi_photometric_calibration_calculation, lambda, pri_header, ext_header, units=units,ref_star_magnitude=star_mag, ref_filter_type=ref_filter_type, ref_SpType=SpType, ref_model_spectrum=ref_model_spectrum, spectrum=spectrum,ref_spectrum=ref_spectrum,  output_spectrum=output_spectrum, no_satellite_correction=no_satellite_correction,logarr=logarr

;########
; INPUTS

; lambda - wavelength array in microns
; primary header - gpi primary header
; secondary header - gpi secondary header
; units = choice of units 1:'Counts' 2:'Counts/s' 3:'ph/s/nm/m^2' 4: 'Jy' 5: 'W/m^2/um' 6:'ergs/s/cm^2/A' 7:'ergs/s/cm^2/Hz'
; ref_star_magnitude: magnitude of reference star for the filter wavelengths given by lambda
; ref_filter_type: will do the conversion of magnitudes if this is specified. 1: MKO 2: 2Mass
; ref_SpType: spectral type of reference - used to pick the pickles model
; ref_model_spectrum: optional input of the model reference spectrum, if specified then no pickles spectrum is used. Assumes the units are in ergs/s/cm^2/A. If this keyword is set, ref_spType and ref_star_magnitude is ignored
; spectrum : Optional keyword - the spectrum of the companion - if set, then the calibrated spectrum will be returned in the output_spectrum keyword
; ref_spectrum : Optional keyword - the reference spectrum that corresponds to the model spectrum (normally the satellite spot spectrum) - if set, then the calibrated spectrum will be returned in the output_spectrum keyword
; no_satellite_correction: flag that should be set if the ref_spectrum is NOT a satellite spectrum. This will make it such that the correction factor between the satellite flux and the central star flux is not applied
; ########
; OUTPUTS

; output of function is the converted_model_spectrum, so the user does spectrum/reference_spectrum * converted_model_spectrum.
; output_spectrum - the returned calibrated spectrum if the spectrum and ref_spectrum keywords are set

; pipeline data is in ADU/coadd

; goal of this is to do spectrum * model_spectrum/reference_spectrum/

; but this program is more clever, and returns only the model spectrum, so the user does the  spectrum/model_spectrum, unless the ref_spectrum and spectrum keywords are used.

; did the user supply a spectrum?
if keyword_set(ref_model_spectrum) eq 1 then user_supplied_spectrum_flag=1 else user_supplied_spectrum_flag=0
; did the user supply a magnitude
if keyword_set(ref_star_magnitude) eq 1 then begin
		user_supplied_magnitude_flag=1
	;	ref_star_magnitude=float(star_mag)
	endif else user_supplied_magnitude_flag=0

; start a string array of log messages - this is due to some stupid bug where the program will cause bus errors or segmentation faults if message statements are used inside this function. 
logarr='Results of gpi_photometric_calibration_calculation.pro'

; load the keywords out of the header - if needed
; if the user supplies a spectrum then this isnt necessary
if user_supplied_spectrum_flag eq 0 then begin
		; check that the magnitude is defined?
		if keyword_set(ref_SpType) eq 0 or user_supplied_magnitude_flag eq 0 then begin
		
	; check that the spectral type is defined
		ref_spType= gpi_get_keyword( pri_header, ext_header,'SPECTYPE',count=dd)
		if dd eq 0 then return, error('FAILURE (gpi_photometric_calibration_calculation): Reference Spectral type (SPECTYPE) is not defined in the header nor keywords')  

		; is it in the header?
	 	if user_supplied_magnitude_flag eq 0 then ref_star_magnitude=float(gpi_get_keyword( pri_header, ext_header,'HMAG',count=cc))
		if cc eq 0 and user_supplied_magnitude_flag eq 0 then return, error('FAILURE (gpi_photometric_calibration_calculation): H-band magnitude value (HMAG) is not defined in the header nor keywords')  
	endif else begin
logarr=[logarr, "(gpi_photometric_calibration_calculation):  Model of the reference spectrum is defined, ignoring any defined spectral type and magnitude defined in the keywords and/or headers"]
	endelse
endif

; check that an output unit is specified
; this is actually pretty dumb because if you put zero then it flags! 
if keyword_set(units) eq 0 then message,/info, 'WARNING (gpi_photometric_calibration_calculation): FinalUnits either undefined or set to zero. Assuming FinalUnits equals 0'

; ################################
; load in the reference spectrum
; ################################
; first check to see one is specified
if user_supplied_spectrum_flag eq 1 then begin
	if file_test(ref_model_spectrum) eq 1 then return, error ('FAILURE (gpi_photometric_calibration_calculation): The file '+strc(ref_model_spectrum)+', specified by the user is not found')

		logarr=[logarr, '(gpi_photometric_calibration_calculation):  Loading user-specified spectrum '+ref_model_spectrum]
		readcol,ref_model_spectrum,model_wavelengths,model_flux,format=('F,F')
endif

; now try to find a pickles spectrum
if keyword_set(ref_model_spectrum) eq 0 then begin

	; load in the AA_README file with all the info
	readcol, gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'pickles'+path_sep()+'AA_README',pickles_fnames,pickles_sptypes,pickles_temps,skipline=113,numline=79,format=('A,A,F'),/silent
; now find the file associated with the provided spectral type
	for i=0, N_ELEMENTS(pickles_fnames)-1 do begin
		Result = STRMATCH(ref_spType, pickles_sptypes[i], /FOLD_CASE)
		if result ne 0 then begin
			ref_model_spectrum=gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'pickles'+path_sep()+pickles_fnames[i]+'.fits'
		  if file_test(ref_model_spectrum) eq 0 then return, error ('FAILURE (gpi_photometric_calibration_calculation): The file '+strc(ref_model_spectrum)+' is not found in Pickles library. Verify all the pickles models are in the directory '+ gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'pickles')
			; now load the spectrum
			pickles=mrdfits(ref_model_spectrum,1)
			model_wavelengths=pickles.wavelength
			model_flux=pickles.flux ; erg/s/cm2/A - but this is not a zero magnitude - this is whatever the magnitude difference of the star is (so if H-V=2, then its a magnitude 2 star!
			break
		endif
	endfor

	;error handling if something failed
	if i eq N_ELEMENTS(pickles_fnames) then begin
		logarr=[logarr, "(gpi_photometric_calibration_calculation):  No pickles spectrum was found for the given spectral type "+strc(ref_spType)]
		dir=gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'pickles'+path_sep()+'AA_README'
		logarr=[logarr, '(gpi_photometric_calibration_calculation):  Check the AA_README file in '+strc(dir)+' lines 114-193 for the available spectral types']
		return, error('FAILURE (gpi_photometric_calibration_calculation): No pickles spectrum was found for the given spectral type '+strc(ref_spType))
	endif
endif ; if ref_model_spectrum eq 0


; BIN THE SPECTRUM - THIS SHOULD BE DONE AS A FUNCTION OF DETECTOR POSITION and use the mlens psfs!
; pull the filter out of the header
	filter=strc(gpi_simplify_keyword_value(sxpar(pri_header,'IFSFILT')))
	width=lambda[n_elements(lambda)-1]-lambda[0]
	case filter of
 	 'Y':specresolution=35.
 	 'J':specresolution=75;37.
 	 'H':specresolution=45;45.
 	 'K1':specresolution=65;65.
 	 'K2':specresolution=75.
	endcase

	dlam=((min(lambda)+max(lambda))/2.)/specresolution
	fwhmloc = VALUE_LOCATE(model_wavelengths/1e4, [(lambda[0]),(lambda[0]+dlam)])
	fwhm=float(fwhmloc[1]-fwhmloc[0])
	gaus = PSF_GAUSSIAN( Npixel=3.*fwhm, FWHM=fwhm, NDIMEN =1, /NORMAL )
	gpi_model_flux0 = CONVOL( reform(model_flux), gaus , /EDGE_TRUNCATE ) 

	; interpolate to our data
	gpi_model_flux=interpol(gpi_model_flux0,model_wavelengths/1e4,lambda) ; model_wavelengths is still in angstroms

	;plot,model_wavelengths/1e4, gpi_model_flux0
	;oplot, model_wavelengths/1e4,reform(model_flux)
	
; only do a magnitude correction if it is a pickles spectrum
	if user_supplied_spectrum_flag eq 0 then begin
		; determine the magnitude correction between the filters		
	
		; read the header keyword FILTTYPE to determine the proper RSR to grab
		if keyword_set(ref_filter_type) eq 1 then FILTTYPE=ref_filter_type else FILTTYPE=sxpar(pri_header,'FILTTYPE',count=cc)
		if cc eq 0 then begin
			 FILTTYPE='2mass' ; makes it a gpi filter type
			logarr=[logarr, '(gpi_photometric_calibration_calculation):  No FILTTYPE keyword supplied, assuming specified magnitude is a 2mass magnitude']
		endif

		; check for 2mass writing synonyms
		if strc(strlowcase(FILTTYPE)) eq '2mass' or strc(strlowcase(FILTTYPE)) eq '2m' then FILTTYPE='2mass'

		CASE strc(strlowcase(FILTTYPE)) OF
			'2mass': begin 
								; first determine the band, then load in the RSR curve
								directory=gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'filters/2mass_filters/'
								case filter of
									 	 'J': readcol, directory+'2m_J_band_RSR.dat' , filt_wave0, filt_prof0
									 	 'H': readcol, directory+'2m_H_band_RSR.dat', filt_wave0, filt_prof0
									 	 'K1': readcol, directory+'2m_Ks_band_RSR.dat', filt_wave0, filt_prof0
									 	 'K2': readcol, directory+'2m_Ks_band_RSR.dat', filt_wave0, filt_prof0
									else: 	return, error('FAILURE (gpi_photometric_calibration_calculation):  No 2mass filter for the given filter')
								endcase
							end 
			'gpi': begin
							logarr=[logarr, '(gpi_photometric_calibration_calculation):  GPI filter magnitude specified. No delta magnitude correction applied']
							dmag=0.0
						 end
			else: return, error('FAILURE (gpi_photometric_calibration_calculation):  No matching filter type found for '+strc(FILTTYPE)+', options are currently: GPI, 2Mass, 2M or not defined')
		endcase

	; now determine the magnitude offsets (star color and filter)

	; load in the GPI filter profile - SHOULD BE TRANSMISSION PROFILE - ASSUMING FILTER ONLY
			GPI_filt_prof=mrdfits(gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'filters/GPI-filter-'+filter+'.fits',1,/silent)
			; must normalize the gpi_filt
			gpi_filt_prof.transmission/=max(gpi_filt_prof.transmission)
				; interpolate the model to the filter wavelengths.
			model_gpi_flux=interpol(gpi_model_flux0,model_wavelengths/1e4,gpi_filt_prof.wavelength)

		if keyword_set(filt_wave0) eq 1 and keyword_set(filt_prof0) eq 1 then begin
				; interpolate the model to the new filter wavelengths
				model_other_flux=interpol(gpi_model_flux0,model_wavelengths/1e4, filt_wave0)
			
				dmag=-2.5*alog10(int_tabulated(gpi_filt_prof.wavelength,model_gpi_flux*gpi_filt_prof.transmission)/int_tabulated(filt_wave0,model_other_flux*filt_prof0)	); ourmag-2Mmag=dm
			logarr=[logarr, '(gpi_photometric_calibration_calculation):  Applied a magnitude offset of  '+strc(dmag)+' to account for the different relative response curves']
		endif 
		; must determine the star color correction
		; this is necessary because a pickles model of say a k2v star, is normalized to have a zero magnitude only in V-band. So at H-band the counts levels are not for a zero magnitude star (remember that the magnitude given by 2mass etc are for vega).
		; Here we derive that correction by integrating the two spectra over our filter bandpass (this should actually be our spectral response curves)
		; Need a vega spectrum (http://www.stsci.edu/hst/observatory/crds/calspec.html)
		vega=mrdfits(gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'pickles/alpha_lyr_stis_005.fits',1)
		; convolve
		gpi_vega_flux0 = CONVOL( reform(vega.flux), gaus , /EDGE_TRUNCATE ) 
		; interpolate the model to the filter wavelengths.
		model_vega_flux=interpol(gpi_vega_flux0,vega.wavelength/1e4,gpi_filt_prof.wavelength)

		; determine color magnitude correction

		star_color_correction=-2.5*alog10(int_tabulated(gpi_filt_prof.wavelength,model_gpi_flux*gpi_filt_prof.transmission)/int_tabulated(gpi_filt_prof.wavelength,model_vega_flux*gpi_filt_prof.transmission)	); ourmag-2Mmag=dm
		;star_color_correction=0
		logarr=[logarr, '(gpi_photometric_calibration_calculation):  Applied a color correction of '+strc(star_color_correction)+' magnitudes to account for the color differences between Vega and '+strc(ref_spType)]

		; compensate for the magnitude difference due to the filter (dmag)
		; and the star color correction
		gpi_model_flux*=10.0^(-(ref_star_magnitude-star_color_correction+dmag)/2.5)
	endif

; correct for the satellite to star flux ratio if desired
	if keyword_set(no_satellite_correction) eq 0 then begin
		apodizer=sxpar(pri_header,'APODIZER')
		gridfac = gpi_get_gridfac(apodizer)
		gpi_model_flux*=gridfac
	endif


	; model is still in erg/s/cm2/A
	
	; need to convert it to whatever the user desires
	  
unitslist = ['ADU per coadd', 'ADU/s','ph/s/nm/m^2', 'Jy', 'W/m^2/um','ergs/s/cm^2/A','ergs/s/cm^2/Hz']

 ; let's the user define what will be the final units:

; this is just a hack for transmission numbers 
	case filter of
			'Y':  trans_val=0.06
	 	 'J':  trans_val=0.06
	 	 'H': trans_val=0.07
  	 'K1':  trans_val=0.07
	 	 'K2': trans_val=0.07
	endcase

      case units of
      0: begin ;'Counts'
				message,/info,'Converting to ADU per coadd requires a system response function that is not yet properly determined. Continuing, using an approximation based on the filter!'

				; determine conversion
				; this correction requires a transmission function that is not yet available
				; the following just ballparks it
				 h=6.626068d-27                      ; erg * s
			   c=2.99792458d14                     ; um / s
   			 Dtel=gpi_get_constant('primary_diam',default=7.7701d0)
         Obscentral=gpi_get_constant('secondary_diam',default=1.02375d0)
				 SURFA=!PI*(Dtel^2.)/4.-!PI*((Obscentral)^2.)/4.
   	   	gaindetector=double(sxpar(ext_header, 'SYSGAIN'))
				exposuretime=double(sxpar(ext_header, 'ITIME'))
				
				; go from ergs/s/cm^2/A to Counts/s
				conv_fact=(surfa)*(100.0)^2.0 ; from ergs/s/cm^2/A to ergs/s/A with 100cm2/m2 conversion.
				conv_fact*=exposuretime ; from ergs/s/A to ergs/A
				conv_fact*=abs(lambda[1]-lambda[0])*1e4 ;  from ergs/A to ergs
				conv_fact*=(lambda/(h*c)) ; ergs to photons (or electrons)
				conv_fact*=gaindetector ; electons to ADU
				
				; must account for instrument transmission
				; lets just pretend it is the filter profile and 4%
				filt_prof0=mrdfits('/Users/Patrick/work/GPI/gpi_pipeline/pipeline/config/filters/GPI-filter-'+strc(filter)+'.fits',1,/silent)
				; iterpolate to lambda
				filt_prof=interpol(filt_prof0.transmission, filt_prof0.wavelength,lambda)
				transmission=filt_prof*trans_val  
				conv_fact*=(transmission)^2 ; NOT SURE THIS IS CORRECT...

	
				;return, error('FAILURE (gpi_photometric_calibration_calculation): Counts unit type requires a transmission function which is not yet determined')

            end
      1: begin ;'Counts/s'
  				message,/info,'Converting to ADU/s requires a system response function that is not yet properly determined. Continuing, using an approximation based on the filter!'
				 h=6.626068d-27                      ; erg * s
			   c=2.99792458d14                     ; um / s
   			 Dtel=gpi_get_constant('primary_diam',default=7.7701d0)
         Obscentral=gpi_get_constant('secondary_diam',default=1.02375d0)
				 SURFA=!PI*(Dtel^2.)/4.-!PI*((Obscentral)^2.)/4. ; in m2
   	   	gaindetector=double(sxpar(ext_header, 'SYSGAIN'))
				exposuretime=double(sxpar(ext_header, 'ITIME'))
				
				; go from ergs/s/cm^2/A to Counts/s by *multiplying* by conv_fact
				conv_fact=(surfa)*(100.0)^2.0 ; from ergs/s/cm^2/A to ergs/s/A with 100cm2/m2 conversion
				conv_fact*=abs(lambda[1]-lambda[0])*1e4 ;  from ergs/s/A to ergs/s
				conv_fact*=(lambda/(h*c)) ; ergs/s to photons/s (or electrons)	
				conv_fact*=gaindetector ; electons/s to ADU/s
				
				; must account for instrument transmission
				; lets just pretend it is the filter profile and 4%
				filt_prof0=mrdfits('/Users/Patrick/work/GPI/gpi_pipeline/pipeline/config/filters/GPI-filter-'+strc(filter)+'.fits',1,/silent)
				; iterpolate to lambda
				filt_prof=interpol(filt_prof0.transmission, filt_prof0.wavelength,lambda)	
				transmission=filt_prof*trans_val
				conv_fact*=(transmission)^2   ; NOT SURE THIS IS CORRECT...
        end
      2: begin ;'ph/s/nm/m^2'
				 h=6.626068d-27                      ; erg * s
			   c=2.99792458d14                     ; um / s
				conv_fact=(lambda/(h*c)) ; ergs/s/cm2/A to photons/s/cm2/A
				conv_fact*=10.0; photons/s/cm2/A to photons/s/cm2/nm
				conv_fact*=(100.0^2.0) ; photons/s/cm2/nm to photons/s/m2/nm
        end
      3: begin ;'Jy'
        	; 1Jy = 10^-23 erg/s/Hz/cm2
				;c/l=f
       	;c/l^2 dl= df  -- so dl/df= l^2 / c
			  c=2.99792458d14                     ; um / s
				conv_fact=((lambda[*]^2)/c) ; this is in um*s
				conv_fact*=1e4 ; now in A*s
				conv_fact*=(1.0/10.0^(-23.0))				
				 end
      4: begin ;'W/m^2/um'
				conv_fact=fltarr(N_ELEMENTS(lambda))+1
				conv_fact*=10.0^(4) ; from  ergs/s/cm^2/A to ergs/s/cm^2/um
				conv_fact*=(100.0^2.0) ; from ergs/s/cm^2/um to ergs/s/m^2/um
				conv_fact*=1e-7 ; from ergs/s/m^2/um to J/s/m2/um = W/m2/um
         end
      5: begin ;'ergs/s/cm^2/A'
				conv_fact=1.0
        end
      6: begin ;'ergs/s/cm^2/Hz'
				;c/l=f
       	;c/l^2 dl= df  -- so dl/df= l^2 / c
			  c=2.99792458d14                     ; um / s
				conv_fact=((lambda^2)/c) ; this is in um*s
				conv_fact*=1e4 ; now in A*s
				
		    end
      endcase

gpi_model_flux*=conv_fact

if keyword_set(spectrum) and keyword_set(ref_spectrum) then begin
	; output the spectrum if desired
	 output_spectrum=spectrum/ref_spectrum*gpi_model_flux
endif

return, gpi_model_flux

end

