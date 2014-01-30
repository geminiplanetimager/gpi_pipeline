;+
; NAME: gpi_extract_1d_spectrum
; PIPELINE PRIMITIVE DESCRIPTION: Extract 1D spectrum from a datacube
;
;	This primitive extracts a spectrum from a data cube. It is meant to be used on datacubes that have been calibrated by gpi_apply_photometric_calibration, but this is not required.
;
; The extraction radius is pulled out of the header such that is uses the same as what was used to calibrate the cube. If they keyword is not found, then the extraction_radius keyword is used. The extraction_radius keyword will also be used if the override keyword is set to 1. Note that this is very dangerous and will introduce systematics into the data. 
;
; The centroiding is performed by fitting a gaussian to the region of interest. A line is then fit to the centroids and used. In this fit, the first and last 4 data points are excluded due to low transmission. The errors for each centroid are determined by taking the largest of the offsets between the subtraction of adjacent centroids (e.g. yerr[j]=0.1>abs(yarr0[j]-yarr0[j+1])>abs(yarr0[j]-yarr0[j-1]) )
;
; All photometry is done in ADU/coadd. This is performed by converting the cube to ADU/coadd then converting back to whatever units the cube was input with
;
;
;
;; INPUTS: Datacube of which a source needs extracting, xcenter and ycenter keywords
;
; KEYWORDS:
;
; Save: Set to 1 to save the spectrum to a disk file (.fits). 
; xcenter: x-location of extraction (in pixels)
; ycenter: y-location of extraction (in pixels)
; inner_sky_radius: inner radius used in defining sky subtraction annulus 
; outer_sky_radius: outer radius used in defining sky subtraction annulus 
;	override: allows input of a new extraction radius, and the use/non-use of c_ap_scaling
;	extraction_radius: Radius used to define annulus for source extraction. This keyword is only active if the override keyword is set, or if the CEXTR_AP keyword, set by the Calibrate Photometric Flux primitive (gpi_calibrate_photometric_flux.pro) is not present in the header
; c_ap_scaling: keyword that activates the scaling of the apertures with wavelength. This keyword is only active if the override keyword is set, or if the C_AP_SC keyword, set by the Calibrate Photometric Flux primitive (gpi_calibrate_photometric_flux.pro) is not present in the header
; display: window used to display the extracted spectrum plot
; save_ps_plot: saves a postscript version of the plot if desired
; write_ascii_file: writes as ascii output of the spectra - no header info included
;
;	/Save	;
; GEM/GPI KEYWORDS:FILTER,IFSUNIT
; DRP KEYWORDS: CUNIT,DATAFILE,SPECCENX,SPECCENY
; OUTPUTS:  
;
; PIPELINE COMMENT: Extract one spectrum from a datacube somewhere in the FOV specified by the user.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="xcenter" Type="float" Range="[-1,280]" Default="-1" Desc="x-locations in pixel on datacube where extraction will be made"
; PIPELINE ARGUMENT: Name="ycenter" Type="float" Range="[-1,280]" Default="-1" Desc="y-locations in pixel on datacube where extraction will be made"
; PIPELINE ARGUMENT: Name="inner_sky_radius" Type="float" Range="[1,100]" Default="10." Desc="Inner aperture radius at middle wavelength slice (in spaxels i.e. mlens) to extract sky"
; PIPELINE ARGUMENT: Name="outer_sky_radius" Type="float" Range="[1,100]" Default="20." Desc="Outer aperture radius at middle wavelength slice (in spaxels i.e. mlens) to extract sky"
; PIPELINE ARGUMENT: Name="override" Type="int" Range="[0,1]" Default="0" Desc="Override apertures/scaling from spectrophotometric calibration?"
; PIPELINE ARGUMENT: Name="extraction_radius" Type="float" Range="[0,1000]" Default="5." Desc="Aperture radius at middle wavelength (in spaxels i.e. mlens) to extract photometry for each wavelength"
; PIPELINE ARGUMENT: Name="c_ap_scaling" Type="int" Range="[0,1]" Default="1" Desc="Perform aperture scaling with wavelength?"
; PIPELINE ARGUMENT: Name="no_centroid_override" Type="int" Range="[0,1]" Default="0" Desc="Do not centroid on extraction source?"
; PIPELINE ARGUMENT: Name="display" Type="int" Range="[-1,100]" Default="17" Desc="-1 = No display; 0 = New (unused) window; else = Window number to display diagnostic plot."
; PIPELINE ARGUMENT: Name="save_ps_plot" Type="int" Range="[0,1]" Default="0" Desc="Save PostScript of plot?"
; PIPELINE ARGUMENT: Name="write_ascii_file" Type="int" Range="[0,1]" Default="0" Desc="Save ascii file of spectrum (.dat)?"
; PIPELINE ORDER: 2.52
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: SpectralScience
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	
;   2014-01-07 PI: Created Module - big overhaul from the original extract 1d spectrum 
;- 

function gpi_extract_1d_spectrum, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

thisModuleIndex = Backbone->GetCurrentModuleIndex()

if tag_exist( Modules[thisModuleIndex], "xcenter") then xcenter=float(Modules[thisModuleIndex].xcenter) else xcenter=-1
if tag_exist( Modules[thisModuleIndex], "ycenter") then ycenter=float(Modules[thisModuleIndex].ycenter) else ycenter=-1
if tag_exist( Modules[thisModuleIndex], "display") then display=float(Modules[thisModuleIndex].display) else display=17
if tag_exist( Modules[thisModuleIndex], "save_ps_plot") then save_ps_plot=float(Modules[thisModuleIndex].save_ps_plot) else save_ps_plot=0
if tag_exist( Modules[thisModuleIndex], "write_ascii_file") then write_ascii_file=float(Modules[thisModuleIndex].write_ascii_file) else write_ascii_file=0
if tag_exist( Modules[thisModuleIndex], "override") then override=float(Modules[thisModuleIndex].override) else override=0
if tag_exist( Modules[thisModuleIndex], "inner_sky_radius") then inner_sky_radius=float(Modules[thisModuleIndex].inner_sky_radius) else inner_sky_radius=10
if tag_exist( Modules[thisModuleIndex], "outer_sky_radius") then outer_sky_radius=float(Modules[thisModuleIndex].outer_sky_radius) else outer_sky_radius=20

if xcenter le 0 or xcenter ge 280 then return, error('FAILURE ('+functionName+'): xcenter not defined or out of range ') 
if ycenter le 0 or ycenter ge 280 then return, error('FAILURE ('+functionName+'): ycenter not defined or out of range ') 

band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=cc))
cwv=get_cwv(band)
CommonWavVect=cwv.CommonWavVect
lambda=cwv.lambda

; is a calibrated cube ?
contained_flux_ratio = (backbone->get_keyword('EFLUXRAT',count=count,ext_num=0))
if count eq 0 then begin
	backbone->Log,functionname+":  This is not a calibrated cube, assuming all flux is contained in the extraction aperture"
	backbone->Log,functionname+":   Using user-specified extraction and sky annuli. Override being set to 1"
	fscale=fltarr(N_ELEMENTS(lambda))+1
	contained_flux_ratio=1.0
	override=1.0
	; set error to zero
	cal_percent_err=fltarr(N_ELEMENTS(lambda))
endif else begin
; pull extraction_radius and c_ap_scaling from header
	c_ap_scaling=(backbone->get_keyword('C_AP_SC',count=count,ext_num=0))
	extraction_radius=(backbone->get_keyword('CEXTR_AP',count=count,ext_num=0))
; also pull cal_percent_err
	cal_percent_err=fltarr(N_ELEMENTS(lambda))
	for l=0, N_ELEMENTS(lambda)-1 do cal_percent_err[l]=(backbone->get_keyword('CERR_'+strc(l),count=count,ext_num=1))
; pull flux scaling from headers
fscale_arr=fltarr(N_ELEMENTS(lambda))
	for l=0, N_ELEMENTS(lambda)-1 do fscale_arr[l]=(backbone->get_keyword('FSCALE'+strc(l),count=count,ext_num=1))
endelse

if override eq 1 then begin
	backbone->Log,functionname+":  WARNING override is set - This may introduce systematic errors to your extraction"
	backbone->Log,functionname+":  Override is set; Taking user specified (or default) extraction_radius, c_ap_scaling, inner_sky_radius, outer_sky_radius"
	if tag_exist( Modules[thisModuleIndex], "extraction_radius") then extraction_radius=float(Modules[thisModuleIndex].extraction_radius) else extraction_radius=3
	if tag_exist( Modules[thisModuleIndex], "c_ap_scaling") then c_ap_scaling=float(Modules[thisModuleIndex].c_ap_scaling) else c_ap_scaling=1
endif

; #############################
; now extract the source
; #############################
    source_cube=*(dataset.currframe[numfile])

     badpix = [0,0] & phpadu=1     

			if c_ap_scaling eq 1 then begin
  			aperrad0=extraction_radius/lambda[N_ELEMENTS(lambda)/2]  
				skyrad0 =[inner_sky_radius, outer_sky_radius]/lambda[N_ELEMENTS(lambda)/2]
			endif else begin
				aperrad0=extraction_radius/lambda 
				skyrad0 =[inner_sky_radius, outer_sky_radius]/lambda
			endelse

     ;;do the photometry of the companion
		; we actually want the peak in the center of a pixel, so centers must be half integers
     x0=floor(xcenter)+0.5 & y0=floor(ycenter)+0.5 & hh=5.
     phot_comp=fltarr(N_ELEMENTS(lambda)) 
		 phot_comp_err=fltarr(N_ELEMENTS(lambda))
		xarr0=fltarr(N_ELEMENTS(lambda))
		yarr0=fltarr(N_ELEMENTS(lambda))
		xerr=fltarr(N_ELEMENTS(lambda))
		yerr=fltarr(N_ELEMENTS(lambda))

		; first do centroiding
		if keyword_set(no_centroid_override) eq 0 then begin	
				refpix = hh*2+1  ;search window size
				;;create pure 2d gaussian
				generate_grids, fx, fy, refpix, /whole
				fr = sqrt(fx^2 + fy^2)
				ref = exp(-0.5*fr^2)
				
		for i=0,CommonWavVect[2]-1 do begin
			; centroid from the source
					;stamp1=source_cube[x0-hh:x0+hh,y0-hh:y0+hh,i]
        	;cent=centroid(stamp1)
         	;x=x0+cent[0]-hh
         	;y=y0+cent[1]-hh
					
					;cent=centroid(translate(source_cube[x0-hh:x0+hh,y0-hh:y0+hh,i],x0-x,y0-y))
					;x2=x0+cent[0]-hh
         	;y2=y0+cent[1]-hh
									
							stamp2 = source_cube[x0-hh:x0+hh,y0-hh:y0+hh,i]/fscale_arr[i]
			  fourier_coreg,stamp2,ref,shft,/findshift
				x3=x0-shft[0] & y3=y0-shft[1]
				;print,x,y,x2,y2,x3,y3
				x=x3 & y=y3
				xarr0[i]=x & yarr0[i]=y
				if finite(xarr0[i]+yarr0[i]) eq 0 then begin
					phot_comp[i]=!values.f_nan & phot_comp_err[i]=!values.f_nan
					;print,'infinite shifts encountered'
				continue
				endif
					;can also centroid from the star - this code only here for if someone wants to implement it.
			;tmp = sxpar(*calib_cube_struct.ext_header,"SATSMASK",count=ct)
			;if ct eq 0 then return, error('FAILURE ('+functionName+'): SATSMASK undefined.  Use "Measure satellite spot locations" before this one.')
			;goodcode = hex2bin(tmp,(size(calib_cube,/dim))[2])
			;good = long(where(goodcode eq 1))
			;cens = fltarr(2,4,(size(calib_cube,/dim))[2])
			;for s=0,n_elements(good) - 1 do begin 
			;   for j = 0,3 do begin 
			;      tmp = fltarr(2) + !values.f_nan 
;      reads,backbone->get_keyword('SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2),ext_num=1),tmp,format='(F7," ",F7)'
			;			reads,sxpar(*calib_cube_struct.ext_header,'SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2)),tmp,format='(F7," ",F7)'
			;      cens[*,j,good[s]] = tmp 
			;   endfor 
			;endfor

			;tmp=*self.satspots[*].cens
			;cents=fltarr(2,N_ELEMENTS(tmp[0,0,*]))
			;for p=0, N_ELEMENTS(tmp[0,0,*]) -1 do begin
   		;	for q=0, 1 do cents[q,p]=mean(tmp[q,*,p])
			;endfor
	
		endfor ; end centroiding loop

	if total(finite(xarr0)) eq 0 or total(finite(yarr0)) eq 0 then $
		return, error('FAILURE ('+functionName+'): entire x or y centroids are NaNs; make sure the spectral extraction position is correct') 

	;determine error from the data
	for j=1,N_ELEMENTS(lambda)-2 do	xerr[j]=0.1>abs(xarr0[j]-xarr0[j+1])>abs(xarr0[j]-xarr0[j-1])
	for j=1,N_ELEMENTS(lambda)-2 do	yerr[j]=0.1>abs(yarr0[j]-yarr0[j+1])>abs(yarr0[j]-yarr0[j-1])
	delvarx,ax,bx,ay,by
	; make sure all are finite and ignore first and last 3 points in the cube since hte SNR is crap
	ind = where(finite(xarr0+yarr0) ne 0 and xerr ne 0 and yerr ne 0 and (lambda gt lambda[3] and lambda lt lambda[N_ELEMENTS(lambda)-4]))
	fitexy,lambda[ind],xarr0[ind],Ax,Bx,X_sig=1e-3,y_sig=xerr[ind]
	fitexy,lambda[ind],yarr0[ind],Ay,By,X_sig=1e-3,y_sig=yerr[ind]
	xarr=lambda*Bx+Ax
	yarr=lambda*By+Ay

	;window,23
	;plot,lambda,xarr0,yr=[min(xarr,/nan),max(xarr,/nan)]
	;oplot, lambda,xarr

		endif else begin
		; just hard set to the define centroid
			xarr[*]=x0 & yarr[*]=y0	
		endelse

; start photometry
     for i=0,CommonWavVect[2]-1 do begin
					if finite(xarr[i]+yarr[i]) eq 0 then continue	
				aperrad = aperrad0*lambda[i]
				skyrad  = skyrad0*lambda[i]
				trans_cube_slice=translate(source_cube[*,*,i]/fscale_arr[i],x0-xarr[i],y0-yarr[i])
				;aper, trans_cube , [x0], [y0], flux, errflux, sky, skyerr, phpadu, aperrad, $
        ;      skyrad, badpix, /flux, /silent,/nan,/exact
				;aper, source_cube[*,*,i], [x], [y], flux, errflux, sky, skyerr, phpadu, aperrad, $
        ;      skyrad, badpix, /flux, /silent,/nan,/exact

				; the 0.6 is the correction used for a 3 pixel aperture, at the moment, it is the only info we have 
        ;phot_comp[i]=(flux[0])*(0.6/contained_flux_ratio)
			
				; do an error approximation - the error is useless from aper unless in photons and
				; even then it adds photon noise that won,t be correct.
				;get size of aperture in pixels - this is not really exact...
				src_ind=get_xycind(281,281,x0,y0,aperrad)
				bkg_ind=get_xyaind(281,281,x0,y0,skyrad[0],skyrad[1]-skyrad[0])
				if bkg_ind[0] eq -1 or total(finite(trans_cube_slice[bkg_ind])) eq 0 or total(finite(trans_cube_slice[src_ind])) eq 0 then begin
					phot_comp[i]=!values.f_nan
					phot_comp_err[i]=!values.f_nan
					continue
				endif
				; fit plane to bkg
				weights=0
				finite_bkg_ind=bkg_ind[where(finite(trans_cube_slice[bkg_ind]) eq 1)]
				; fits and subtracts a plane to get proper error estimation
				coef = PLANEFIT( finite_bkg_ind mod 281 ,finite_bkg_ind / 281,trans_cube_slice[finite_bkg_ind],weights, yfit )
				xinds=src_ind mod 281 & yinds=src_ind / 281	
				src_bkg_plane=coef[0]+coef[1]*xinds+coef[2]*yinds	

				;phot_comp[i]=total(trans_cube[src_ind])-(N_ELEMENTS(src_ind)*median(trans_cube[finite_bkg_ind]))*(0.6/contained_flux_ratio)
				phot_comp[i]=total(trans_cube_slice[src_ind]-src_bkg_plane)
				;phot_comp_err[i]=sqrt((!pi*(aperrad)^2)*(robust_sigma(tmp[ind])^2))*(0.6/contained_flux_ratio)
				bkg_stddev=stddev(trans_cube_slice[finite_bkg_ind]-yfit,/nan)
				phot_comp_err[i]=sqrt(float(N_ELEMENTS(src_ind))*(bkg_stddev)^2)

				; now normalize for missing flux ratio in aperture used in gpi_calibrate_photometric flux
				; this just cancels out if the extraction aperture is unchanged, which it should be!  
				phot_comp[i]*=(0.6/contained_flux_ratio)
				phot_comp_err[i]*=(0.6/contained_flux_ratio)
;if i eq 36 then stop
		endfor
; now convert back to desired units
for l=0, N_ELEMENTS(lambda)-1 do phot_comp[l]*=fscale_arr[l]
for l=0, N_ELEMENTS(lambda)-1 do phot_comp_err[l]*=fscale_arr[l]


if display ne -1 then begin
  if display eq 0 then window,/free else select_window, display
	units=(backbone->get_keyword('BUNIT'))
loadcolors
	phot_comp_err_total=phot_comp*sqrt((cal_percent_err/100.)^2+(phot_comp_err/phot_comp)^2)
	ploterror,lambda,phot_comp, phot_comp_err_total,ytitle='flux ['+units+']',xtitle='wavelength (um)',position=[0.16,0.11,0.97,0.97],xr=[min(lambda)-0.01,max(lambda)+0.01],xs=1,color=cgcolor('black'),background=cgcolor('white')


;	if file_test('~/bp_test.fits') then begin
;		loadcolors
;		tmp=readfits('~/bp_test.fits')
;		oploterror,tmp[0,*],tmp[1,*],tmp[2,*],errcolor=2,color=2
;	endif

;	bb=planck(lambda*1e4,18800)
;	oplot, lambda,bb*(median(phot_comp)/median(bb)),linestyle=2,color=cgcolor('black')


; So the 2mass data + the zerlo point gives a flux of 3.556e-19 W/cm2/umat 1.662 um  which is 3.56E-16 erg/cm2/s/A
; the errorbar is complicated - the zero point has a 2% error, the datapoint has a 1.5% error (abouts)
;sats_stddev=(backbone->get_keyword('SATNSTD')) & sats_norm=(backbone->get_keyword('SATSNORM'))
;	oploterror, [1.662,1.662],[3.56E-16,3.56E-16],[3.56E-16,3.56E-16]*0.02,psym=2,color=cgcolor('blue')


;	oploterror, [1.785,1.785],[7.56E-16,7.56E-16],[3.56E-16,3.56E-16]*sats_stddev/sats_norm,psym=3,color=cgcolor('blue')
;	legend,['GPI data','Normalized 18800 K blackbody', 'HD 8049b Photometric Flux estimate'],textcolor=cgcolor('black'),linestyle=[0,2,0],psym=[0,0,2],/right,/top,color=[cgcolor('black'),cgcolor('black'),cgcolor('blue')],box=0

;	XYOUTS, 1.69 , 7.56E-16, 'GPI Flux Normalization Unc.',color=cgcolor('black')
	

endif

if save_ps_plot eq 1 then begin
mydevice=!d.name
	filename=strmid(dataset.filenames[0],0,strlen(dataset.filenames[0])-5)+'-spectrum-x'+strc(round(xcenter))+'-y'+strc(round(ycenter))+'.ps'
	openps,Modules[thisModuleIndex].OutputDir+path_sep()+filename, xsize=6, ysize=4,/inches
	units=(backbone->get_keyword('BUNIT'))
	phot_comp_err_total=phot_comp*sqrt((cal_percent_err/100.)^2+(phot_comp_err/phot_comp)^2)
	ploterror,lambda,phot_comp, phot_comp_err_total,ytitle='flux ['+units+']',xtitle='wavelength (um)',position=[0.16,0.11,0.97,0.97],xr=[min(lambda)-0.01,max(lambda)+0.01],xs=1,yr=[2e-16,7e-16],/ys
;	closeps

	bb=planck(lambda*1e4,18800)
	oplot, lambda,bb*(median(phot_comp[5:30])/median(bb[5:30])),linestyle=2,color=cgcolor('black')


; So the 2mass data + the zerlo point gives a flux of 3.556e-19 W/cm2/umat 1.662 um  which is 3.56E-16 erg/cm2/s/A
; the errorbar is complicated - the zero point has a 2% error, the datapoint has a 1.5% error (abouts)
sats_stddev=(backbone->get_keyword('SATNSTD')) & sats_norm=(backbone->get_keyword('SATSNORM'))
;	oploterror, [1.662,1.662],[3.56E-16,3.56E-16],[3.56E-16,3.56E-16]*0.02,psym=2,color=cgcolor('blue')


	oploterror, [1.77,1.77],[7.56E-16,7.56E-16],[3.56E-16,3.56E-16]*sats_stddev/sats_norm,psym=3,color=cgcolor('blue')
;	legend,['GPI data','Normalized 18800 K blackbody', 'HD 8049b Photometric Flux estimate'],textcolor=cgcolor('black'),linestyle=[0,2,0],psym=[0,0,2],/right,/top,color=[cgcolor('black'),cgcolor('black'),cgcolor('blue')],box=0
;	XYOUTS, 1.69-0.12 , 7.56E-16, 'GPI Flux Normalization Uncertainty',color=cgcolor('black')
	legend,['GPI data','Normalized 18800 K blackbody'],textcolor=cgcolor('black'),linestyle=[0,2],psym=[0,0],/right,/top,color=[cgcolor('black'),cgcolor('black')],box=0


	
closeps


set_plot,mydevice
endif

thisModuleIndex = Backbone->GetCurrentModuleIndex()
if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin

	backbone->set_keyword, 'xcenter', xcenter, 'x-pixel in datacube where extraction has been made', ext_num=0
	backbone->set_keyword, 'ycenter', ycenter,"x-pixel in datacube where extraction has been made", ext_num=0

	suffix='-spectrum-x'+strc(round(xcenter))+'-y'+strc(round(ycenter))
  wav_spec=[[lambda],[phot_comp],[phot_comp_err_total]]
	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix ,savedata=wav_spec,display=0) ;saveheader=hdr,
  if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save .fits dataset.')

	; write ascii file?
		
	if write_ascii_file eq 1 then begin
		  openw,funit,Modules[thisModuleIndex].OutputDir+path_sep()+strmid(dataset.filenames[0],0,strlen(dataset.filenames[0])-5)+suffix+'.dat',/get_lun
			for i=0, N_ELEMENTS(lambda)-1 do begin		
			if i eq 0 then printf,funit,'# wavelength [um] flux ['+units+'] flux_err ['+units+']'
		      printf,funit,lambda[i],phot_comp[i],phot_comp_err_total[i], format='(A,A,A)'
			endfor
    
  free_lun,funit
	close,funit
	endif

endif

display=0 ; ensure no gpitv is invoked to display
gpitv=0
if tag_exist( Modules[thisModuleIndex], "Save") eq 1 then Modules[thisModuleIndex].Save=0
 @__end_primitive 

end
