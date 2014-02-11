;+
; NAME: gpi_insert_planet_into_cube
; PIPELINE PRIMITIVE DESCRIPTION: Insert Planet into datacube
;
;
; This primitive allows users to input artificial planets, based on the solar
; metalicity, hybrid cloud model, hot/cold formation scenario models of Spiegel
; and Burrows (2012) into reduced datacubes. The planet PSF is represented by an
; average of the four satellite spots. The models span the ages of 1 to 1000
; Myr, and masses of 1-15 Jupiter masses. If a user specifies parameters that do
; not represent an exact model the nearest model in age, then mass, is used.
; Currently, the intensity of the planets is determined assuming an instrument
; throughput of 18.6%, combined with a 7.9 meter primary mirror with a 1m
; secondary. The user also has the option to scale the image to represent a star
; of a user-defined magnitude. This provides the ability to simulate multiple
; observing scenarios.
;
; The stellar and planet properties are written to the headers. Should the user
; wish to not include the planet information, it can be bypassed by
; de-activating the write_header_info keyword.
;
; At the moment there is no way to determine only the star parameters and not
; insert a planet. To do this, the user should just put the planet distance to a
; large number and separation to a small number.
;
; INPUTS: A fully reduced datacube prior to any speckle manipulation. A planet's distance, separation, position angle, mass, age, and formation scenario (hot/cold start). 
;
; OUTPUTS: The datacube with an inserted planet.
;
; PIPELINE COMMENT: This primitive inserts planets into reduced datacubes. It can be run multiple times to insert multiple planets. 
;
; PIPELINE ARGUMENT: Name="Age" Type="int" Range="[1,1000]"  Default="10" Desc="Age of planet in Myr"
; PIPELINE ARGUMENT: Name="Mass" Type="int" Range="[1,15]"  Default="10" Desc="Mass of planet in Jupiter masses"
; PIPELINE ARGUMENT: Name="model_type" Type="string" Range="[hot,cold]"  Default="hot" Desc="Hot or Cold Start formation scenario"
; PIPELINE ARGUMENT: Name="position_angle" Type="float" Range="[0,360]"  Default="45.0" Desc="Position angle of the planet in degrees East of North"
; PIPELINE ARGUMENT: Name="Separation" Type="float" Range="[0,1800]"  Default="500" Desc="Separation in milli-arcseconds"
; PIPELINE ARGUMENT: Name="Star_Mag" Type="float" Range="[-1,8]"  Default="-1" Desc="Stellar Magnitude in H band, -1 estimates stellar magnitude from satellite spots"
; PIPELINE ARGUMENT: Name="distance" Type="float" Range="[0,1000]"  Default="10.0" Desc="distance to system in parsecs"
; PIPELINE ARGUMENT: Name="write_header_info" Type="int" Range="[0,1]" Default="1" Desc="1: Write planet info to headers 0: don't write planet info to headers"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; 
; PIPELINE ORDER: 5.0
; PIPELINE CATEGORY: SpectralScience
;
; HISTORY:
;    2013-07-30 PI: Created Primitive
;-  

function gpi_insert_planet_into_cube, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate
primitive_version= '$Id$' ; get version from subversion to store in header history

@__start_primitive
suffix='wplnt' 		 ; set this to the desired output filename suffix
 	if tag_exist( Modules[thisModuleIndex], "age") then age=long(Modules[thisModuleIndex].age) else age=10
	if tag_exist( Modules[thisModuleIndex], "mass") then mass=long(Modules[thisModuleIndex].mass) else mass=10
	if tag_exist( Modules[thisModuleIndex], "model_type") then model_type=string(Modules[thisModuleIndex].model_type) else model_type='hot'

	if tag_exist( Modules[thisModuleIndex], "position_angle") then position_angle=float(Modules[thisModuleIndex].position_angle) else position_angle=90.0
	if tag_exist( Modules[thisModuleIndex], "separation") then separation=float(Modules[thisModuleIndex].separation) else separation=500.0
	if tag_exist( Modules[thisModuleIndex], "distance") then distance=float(Modules[thisModuleIndex].distance) else distance=10.0
	if tag_exist( Modules[thisModuleIndex], "star_mag") then star_mag=float(Modules[thisModuleIndex].star_mag) else star_mag=-1.0	
	if tag_exist( Modules[thisModuleIndex], "write_header_info") then write_header_info=long(Modules[thisModuleIndex].write_header_info) else write_header_info=1.0	

	; #############################
	; get magnitude of central star
	; #############################

	;;apodizer - which apodizer is selected is used to look up the
	; satellite spot flux ratios
	val = (backbone->get_keyword('APODIZER')) 
	if strc(string(val)) eq '0' or val eq 'CLEAR' or val eq 'CLEAR_GP' then return, error('FAILURE ('+functionName+'): Apodizer not properly defined, or apodizer set to CLEAR or CLEAR_GP which will not have satellite spots, therefore no planet can be properly input into the cube')

	gridfac=gpi_get_gridfac(val) ; satellite spot ratios

	; pull the psf from a satellite spot - will be used as planet later
	
	; grab the satellite spot locations from the headers
	;;error handle if sat spots haven't been found
	tmp = backbone->get_keyword("SATSMASK", ext_num=1, count=ct)
	if ct eq 0 then $
   		return, error('FAILURE ('+functionName+'): SATSMASK undefined.  You must run the "Measure satellite spot locations" primitive prior to this one.')

	;grab frame
	cube=*dataset.currframe 
	image_size=size(cube)

	;;grab satspots 
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


	;;set aperture
	app =  17 ;set aperture size
	generate_grids, fx, fy, app, /whole

	;;grab all valid satspots
	planet_psf = fltarr(app,app,image_size[3])
	for j = 0, image_size[3]-1 do begin
	  for i = 0,3 do begin
	     planet_psf[*,*,j] += interpolate(cube[*,*,good[j]],fx+cens[0,i,good[j]],fy+cens[1,i,good[j]],cubic=-0.5)
  		psfbkg = mean([transpose(planet_psf[0,1:app-1,j]),planet_psf[1:app-1,app-1,j],transpose(planet_psf[app-1,0:app-2,j]),planet_psf[1:app-2,0,j]])
		planet_psf[*,*,j]-=psfbkg
		planet_psf[*,*,j]=(temporary(planet_psf[*,*,j])>0)
	endfor
	endfor

	; divide by 4 to maintain flux level - this isn't actually necessary...
	planet_psf/=4.0

	; modified gpitv code to get stellar magnitude
	sat1flux = fltarr(image_size[3]) ;;top left
 	sat2flux = fltarr(image_size[3]) ;;bottom left
 	sat3flux = fltarr(image_size[3])  ;;top right
	sat4flux = fltarr(image_size[3]) ;;bottom right
	mean_sat_flux = fltarr(image_size[3])

	for s=0,image_size[3]-1 do begin
		aper, cube[*,*,s],cens[0,0,s],cens[1,0,s],flux,eflux,sky,skyerr,1.,3.,[10.,20.],[-10.,2*max(planet_psf,/nan)],/flux,/exact,/nan,/silent ;;using aperature radius 3 pixels
	     	sat1flux[s]=flux
				aper, cube[*,*,s],cens[0,1,s],cens[1,1,s],flux,eflux,sky,skyerr,1.,3.,[10.,20.],[-10.,2*max(planet_psf,/nan)],/flux,/exact,/nan,/silent
     		sat2flux[s]=flux
  			aper, cube[*,*,s],cens[0,2,s],cens[1,2,s],flux,eflux,sky,skyerr,1.,3.,[10.,20.],[-10.,2*max(planet_psf,/nan)],/flux,/exact,/nan,/silent
     		sat3flux[s]=flux
	     	aper, cube[*,*,s],cens[0,3,s],cens[1,3,s],flux,eflux,sky,skyerr,1.,3.,[10.,20.],[-10.,2*max(planet_psf,/nan)],/flux,/exact,/nan,/silent
     		sat4flux[s]=flux
		mean_sat_flux[s]=mean([sat1flux[s], sat2flux[s], sat3flux[s], sat4flux[s]]) ; counts
	endfor

	; now get magnitude of central star
	
	filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT'))
	; vega zero points and filter central wavelenghts stored in gpi_constants config file
	filt_cen_wave=gpi_get_constant('cen_wave_'+filter) ; in um
	zero_vega=gpi_get_constant('zero_pt_flux_'+filter) ; in erg/cm2/s/um

	; get the wavelengths of the cube and interpolate
	cwv=get_cwv(filter) 
	lambda=cwv.lambda
	
	; planets are in erg/cm2/s/um for the resolution of our instrument
	; must convert to photons/sec
	h=6.626068d-27; erg / s
	c=2.99792458d14 ; um / s
	zero_vega*=(lambda/(h*c)) ; ph/cm2/s/um

	; diameter of Gemini South is 7.9m - with a 1m dia secondary
  primary_diam = gpi_get_constant('primary_diam',default=7.7701d0)*100d
  secondary_diam = gpi_get_constant('secondary_diam',default=1.02375d0)*100d
  area=(!pi*(primary_diam/2.0)^2.0 - !pi*(secondary_diam/2.0)^2.0 ) 
	zero_vega*=area; ph/s/um

	; get instrument transmission (and resolution)
	; corrections for lyot, PPM, and filter transmission

	lyot_mask=(backbone_comm->get_keyword('LYOTMASK'))
	pupil_mask=gpi_simplify_keyword_value(backbone_comm->get_keyword('APODIZER'))
	transmission=calc_transmission(filter, pupil_mask, lyot_mask, /without_filter, resolution=resolution)

	if transmission[0] eq -1 then begin
		return, error('FAILURE ('+functionName+'): Failed to calculate transmission, planet not inserted')
  endif


  ; no filter transmission included!	
	zero_vega*=transmission ; ph/s/um

	; multiply by the integration time
	zero_vega*=(backbone->get_keyword('ITIME')) ; ph/um
	; convert to counts using the detector gain [elec/ADU]
	zero_vega/=(backbone->get_keyword('sysgain')) ; ADU/um
	; each slice is how big in wavelength space
	; answer returned from calc_transmission
	dlambda=(lambda[1]-lambda[0])
	zero_vega*=(lambda/dlambda); photons/slice
	
	; load filters for integration	
	filt_prof0=mrdfits( gpi_get_directory('GPI_DRP_CONFIG')+'/filters/GPI-filter-'+filter+'.fits',1,/silent)
	filt_prof=interpol(filt_prof0.transmission,filt_prof0.wavelength,lambda)

	; must not integrate over wavelength since it is per slice 
	; no filter profile correction necessary - already in 
	star_mag0=-2.5*alog10(total(mean_sat_flux/0.57/gridfac)$
												/total(zero_vega*filt_prof))
	
	backbone->Log,"Stellar magnitude estimated to be: "+strc(string(star_mag0))
	backbone->set_keyword,'HISTORY',functionname+ "Central star "+filter+" magnitude measured to be "+string(star_mag0)
	backbone->set_keyword,'StarMAG',star_mag0, "Measured Central star "+filter+" magnitude"

	; check to see if user wants to scale to a different stellar magnitude
	if star_mag ne -1 then begin
	backbone->Log,"Changing stellar magnitude from "+strc(string(star_mag0))+" to "+strc(string(star_mag))

	; scale cube to the desired magnitude
	cube*=10.0^((-1.0/2.5)*(star_mag-star_mag0))
	backbone->set_keyword,'HISTORY',functionname+ "Central star "+filter+" magnitude changed to "+strc(string(star_mag))
	backbone->set_keyword,'StarMAG0',star_mag, "Initial Central star "+filter+" magnitude"
	endif else star_mag=star_mag0 


	; ################################################
	; now we want to load the proper planet spectrum
	; ################################################

	; put age in proper format
	tmp=(strcompress(string(round(age)),/rem))
	CASE strlen(tmp) OF
		1: age_str='000'+tmp 
		2: age_str='00'+tmp 
		3: age_str='0'+tmp
		4: age_str=tmp 
		else: return, error('FAILURE ('+functionName+'): age is too old. Currently the pipeline supports ages between 1 and 1000 Myr')
	endcase
	; put mass in proper format
	tmp=(strcompress(string(round(mass)),/rem))
	CASE strlen(tmp) OF
		1: mass_str='00'+tmp 
		2: mass_str='0'+tmp 
		3: mass_str=tmp
		else: return, error('FAILURE ('+functionName+'): mass is too high. Currently the pipeline supports masses between 1 and 15 Jupiter masses')
	endcase
	;ensure model type is defined (hot or cold)
	if strc(strlowcase(model_type)) ne 'cold' and strc(strlowcase(model_type)) ne 'hot' then return, error('FAILURE ('+functionName+'): Model type is incorrectly defined. User must define a "hot" or "cold" start model formation scenario.')
 
	model_file_name=gpi_get_directory('DRP_CONFIG')+'/planet_models/gpi_spec_hy1s_mass_'+mass_str+'_age_'+age_str+'.fits'

	; check to see if the model exists, if not, find the closest
	if file_test(model_file_name) eq 0 then begin
		backbone->Log,'ATTENTION: The desired model (mass and age) does not exist, finding the closest model'
		; extract ages and masses from model strings
		; get files
		filetypes = gpi_get_directory('DRP_CONFIG')+'/planet_models/*.{fits}'
		searchpattern = filetypes
		current_files =FILE_SEARCH(searchpattern,/FOLD_CASE, count=file_count)
		if file_count eq 0 then return, error('FAILURE ('+functionName+'): No gpi models found. Please download the models from the GPI data archive.')
		; extract the masses and ages from headers
		mass_arr=intarr(file_count)
		age_arr=intarr(file_count)
			for f=0, file_count-1 do begin
				model_hdr=headfits(current_files[f])
				mass_arr[f]= sxpar(model_hdr,'M_MASS')
				age_arr[f]= sxpar(model_hdr,'M_AGE')
			endfor
			; now find the best model
			; first find by age, then by mass
			tmp=min(abs(age-age_arr),age_match)
			; find all
			good_ind=where(age_arr eq age_arr[age_match])
			tmp2=min(abs(mass-mass_arr[good_ind]),age_mass_match)
			
			file_ind=where(mass_arr[good_ind[age_mass_match]] eq mass_arr and age_arr[age_match] eq age_arr)
			if file_ind[0] eq -1 then return, error('FAILURE ('+functionName+'): No gpi models found. Please specify ages and masses with in the allow ranges)')
			;set the mass and age keywords
			mass=long(mass_arr[good_ind[age_mass_match]]) 
			age=long(age_arr[age_match]) 
			model_file_name=current_files[file_ind]
;			print, current_files[file_ind]
			
	endif 
	message,/info,'Reading in model gpi_spec_hy1s_mass_'+mass_str+'_age_'+age_str+'.fits'
	;read in the file
	model_hdr=headfits(model_file_name)

	struct=mrdfits(model_file_name,1)
	model_wave=struct.wavelength_in_microns
	
	; The user/developer should note that the inputted planet must
	; be binned to the resolution of GPI and be in erg/cm2/s/um

	if strc(strlowcase(model_type)) eq 'cold' then $
		model_spec0=struct.GPI_cold_spec_in_erg_cm2_s_um $
		else model_spec0=struct.GPI_hot_spec_in_erg_cm2_s_um

	; get the wavelengths of the cube and interpolate
	cwv=get_cwv(filter) 
	lambda=cwv.lambda

	; only take part the part of the model of interest
	model_spec=interpol(model_spec0,model_wave, lambda)

	; requires zero pt flux of vega - but in units of erg/cm2/s/um
	zero_vega=gpi_get_constant('zero_pt_flux_'+filter)

	; calculate absolute magnitude - for header
	planet_absolute_mag=-2.5*alog10(int_tabulated(lambda, filt_prof*model_spec,/double)$
	/int_tabulated(lambda,zero_vega*filt_prof))


	; ################################################
	; now scale for distance
	; ################################################

	model_spec0=model_spec
	model_spec*=(10.0/distance)^2.0 ; planet models normalized to 10pc
	; calculate apparent magnitude for header
	planet_apparent_mag= planet_absolute_mag + 5.0 * (alog10(distance) - 1.0)

	; multiply planet spectrum by filter profile
	; this isnt right... there is a filter profile in the throughput
	model_spec*=filt_prof

	; planets are in erg/cm2/s/um for the resolution of our instrument
	; must convert to photons/sec
	model_spec*=(lambda/(h*c)) ; ph/cm2/s/um

	; diameter of Gemini South is 7.9m - with a 1m dia secondary
  primary_diam = gpi_get_constant('primary_diam',default=7.7701d0)*100d
  secondary_diam = gpi_get_constant('secondary_diam',default=1.02375d0)*100d
  area=(!pi*(primary_diam/2.0)^2.0 - !pi*(secondary_diam/2.0)^2.0 ) 
	model_spec*=area; ph/s/um

	; get instrument transmission (and resolution)
	; corrections for lyot, PPM, and filter transmission
	transmission=calc_transmission(filter, pupil_mask, lyot_mask, /without_filter, resolution=resolution)

	if transmission[0] eq -1 then begin
	return, error('FAILURE ('+functionName+'): Failed to calculate transmission, planet not inserted')
  endif

  ; no filter transmission included in transmission - but was accounted for above!	
	model_spec*=transmission ; ph/s/um

	; multiply by the integration time
	model_spec*=(backbone->get_keyword('ITIME')) ; ph/um
	; convert to counts using the detector gain [elec/ADU]
	model_spec/=(backbone->get_keyword('sysgain')) ; ADU/um
	; each slice is how big in wavelength space
	; resolution was calculated above
	model_spec*=(lambda/resolution)
	
	; now scale the PSF to be the brightness of the desired spectrum
	planet_psf0=planet_psf
	for w=0, image_size[3]-1 do begin
		ratio=model_spec[w]/total(planet_psf[*,*,w])
		planet_psf[*,*,w]=ratio[0]*reform(planet_psf[*,*,w])
	; not sure why i cant just do a X ne X then stop.... so confusing!
		if (total(planet_psf[*,*,w]) - float(model_spec[w])) gt 0.001*model_spec[w] then stop,'error in gpi_insert_plnet_into_cube.pro, line 221ish'
	endfor

	; ################################################
	; now insert planet into the cube
	; ################################################

	; must get the orientation of the planet correct (and the PSF) 	
        ; easiest way to do this is by translating the image in a cube full of zeros
	pixscl = gpi_get_ifs_lenslet_scale(*DataSet.HeadersExt[numfile])*1000d0 ; mas/pixel
	; assume no rotation for a moment
	getrot, *dataset.headersext[numfile], rot, cdelt, /silent
	position_angle2=position_angle+90+rot+gpi_get_constant('ifs_rotation_angle', default=-24.5)
	pos_x=(separation/pixscl) * cos(position_angle2*!dtor)
	; negative due to orientation of North
	pos_y=(separation/pixscl) * sin(position_angle2*!dtor)
	;print, 'pos_x,pos_y,',pos_x,pos_y
	; now we rotate by 24.5 degrees
	rot_ang=gpi_get_constant('ifs_rotation_angle', default=-24.5)
	rpos_x=pos_x*cos(rot_ang*!dtor)+pos_y*sin(rot_ang*!dtor)
	rpos_y=-pos_x*sin(rot_ang*!dtor)+pos_y*cos(rot_ang*!dtor)
	;print, 'rpos_x,rpos_y,',rpos_x,rpos_y

	; now we want to put the center of the planet_psf at this position
	; for every slice in the cube

	; will need hte psf centroid
	xcen=(backbone->get_keyword('PSFCENTX'))
	ycen=(backbone->get_keyword('PSFCENTY'))
	;measure displacement from center
	dx=xcen-image_size[1]/2
	dy=ycen-image_size[2]/2
	for w=0, image_size[3]-1 do begin
		;create a blank sheet
		planet_plane=fltarr(image_size[1],image_size[2])
		;put the planet in the center but with respect to the star
		; so use the satellites
		planet_plane[image_size[1]/2-app/2,image_size[2]/2-app/2]=planet_psf[*,*,w]
		; now translate
		; must compensate for center of psf being displaced
		planet_plane2=translate(planet_plane,rpos_x+dx,rpos_y+dy,missing=0)
		; now add the planet to the cube
		cube[*,*,w]+=planet_plane2
	endfor
 	; put cube (with planet) back into pipeline
	*dataset.currframe=cube
	
	; write header information
	backbone->set_keyword,'StarMAG0',star_mag0, "Measured Central star "+filter+" magnitude"
	backbone->set_keyword,'StarMag',star_mag, "Scaled central star "+filter+" magnitude"
	backbone->set_keyword,'Satmags',star_mag-2.5*alog10(gridfac), "Avg magnitude of satellite spots"
	if write_header_info[0] ne 0 then begin
	backbone->set_keyword,'Sys_dist',distance, "System distance in pc"
	backbone->set_keyword,'PL_age',distance, "Planet age in Myr"
	backbone->set_keyword,'PL_mass',mass, "Planet mass in Jupiter masses"
	backbone->set_keyword,'PL_form_sc',model_type, "Planet formation scenario. Hot/Cold start"
	backbone->set_keyword,'PL_entropy',model_type, "Planet initial entropy kb per baryon"
	backbone->set_keyword,'PL_sep',separation, "Planet separation in mas"
	backbone->set_keyword,'PL_PA',position_angle, "Planet position angle E of N in degrees"
	backbone->set_keyword,'PL_abs_mag',planet_absolute_mag, "Planet "+filter+" band absolute magnitude"
	backbone->set_keyword,'PL_app_mag',planet_apparent_mag, "Planet "+filter+" band apparent magnitude"
	endif	

@__end_primitive

end
