;+
; NAME: gpi_extract_1d_spectrum
; PIPELINE PRIMITIVE DESCRIPTION: Extract 1D spectrum from a datacube
;
;	This primitive extracts a spectrum from a data cube. It is meant to be used on datacubes that have been calibrated by gpi_apply_photometric_calibration, but this is not required.
;
;; INPUTS: 
; 1: datacube that requires calibration (loaded as the Input FITS file)
; AND
; 2a: datacube or to be used to determine the calibration (with or without a accompanying model spectrum of the star)
; OR
; 2b: a 2D spectrum (in ADU per COADD, where the COADD corresponds to input #1). The file format must be three columns, the first being wavelength in microns, the second being the flux in erg/s/cm2/A, the third being the uncertainty
;
; if neither 2a nor 2b or defined, the satellites of the input file are used.
;
;
; KEYWORDS:
;	/Save	Set to 1 to save the spectrum to a disk file (.fits). 
;
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

primitive_version= '$Id: extract_one_spectrum.pro 2202 2013-12-04 00:34:59Z maire $' ; get version from subversion to store in header history
@__start_primitive

thisModuleIndex = Backbone->GetCurrentModuleIndex()

if tag_exist( Modules[thisModuleIndex], "xcenter") then xcenter=float(Modules[thisModuleIndex].xcenter) else xcenter=-1
if tag_exist( Modules[thisModuleIndex], "ycenter") then ycenter=float(Modules[thisModuleIndex].ycenter) else ycenter=-1
if tag_exist( Modules[thisModuleIndex], "display") then display=float(Modules[thisModuleIndex].display) else display=17
if tag_exist( Modules[thisModuleIndex], "save_ps_plot") then save_ps_plot=float(Modules[thisModuleIndex].save_ps_plot) else save_ps_plot=0

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
    source_cube=*(dataset.currframe[0])

     badpix = [0,0] & phpadu=1     

			if c_ap_scaling eq 1 then begin
  			aperrad0=extraction_radius/lambda[N_ELEMENTS(lambda)/2]  
				skyrad0 =[inner_sky_radius, outer_sky_radius]/lambda[N_ELEMENTS(lambda)/2]
			endif else begin
				aperrad0=extraction_radius/lambda 
				skyrad0 =[inner_sky_radius, outer_sky_radius]/lambda
			endelse

     ;;do the photometry of the companion
     x0=xcenter & y0=ycenter & hh=3.
     phot_comp=fltarr(N_ELEMENTS(lambda)) 
		 phot_comp_err=fltarr(N_ELEMENTS(lambda))
		
     for i=0,CommonWavVect[2]-1 do begin
				if keyword_set(no_centroid_override) eq 0 then begin
        	cent=centroid(source_cube[x0-hh:x0+hh,y0-hh:y0+hh,i])
         	x=x0+cent[0]-hh
         	y=y0+cent[1]-hh
				endif else begin
					x=x0 & y=y0
				endelse
				
				aperrad = aperrad0*lambda[i]
				skyrad  = skyrad0*lambda[i]
		
				aper, source_cube[*,*,i], [x], [y], flux, errflux, sky, skyerr, phpadu, aperrad, $
              skyrad, badpix, /flux, /silent,/nan,/exact
; the 0.6 is the correction used for a 3 pixel aperture, at the moment, it is the only info we have 
        phot_comp[i]=(flux[0])*(0.6/contained_flux_ratio)

				; do an error approximation - the error is useless from aper unless in photons and even then it adds photon noise that won,t be correct.
				tmp=source_cube[*,*,i]
				ind=get_xyaind(281,281,x,y,skyrad[0],skyrad[1])
				if ind[0] eq -1 then begin
					phot_comp_err[i]=!values_f.nan
					continue
				endif
				phot_comp_err[i]=sqrt((!pi*(aperrad)^2)*(robust_sigma(tmp[ind])^2))*(0.6/contained_flux_ratio)
		endfor

if display ne -1 then begin
  if display eq 0 then window,/free else select_window, display
	units=(backbone->get_keyword('BUNIT'))
	phot_comp_err_total=phot_comp*sqrt((cal_percent_err/100.)^2+(phot_comp_err/phot_comp)^2)
	ploterror,lambda,phot_comp, phot_comp_err_total,ytitle='flux ['+units+']',xtitle='wavelength (um)',position=[0.16,0.11,0.97,0.97],xr=[min(lambda)-0.01,max(lambda)+0.01],xs=1

;	if file_test('~/bp_test.fits') then begin
;		loadcolors
;		tmp=readfits('~/bp_test.fits')
;		oploterror,tmp[0,*],tmp[1,*],tmp[2,*],errcolor=2,color=2
;	endif

endif

if save_ps_plot eq 1 then begin
mydevice=!d.name
	filename=strmid(dataset.filenames[0],0,strlen(dataset.filenames[0])-5)+'-spectrum-x'+strc(xcenter)+'-y'+strc(ycenter)+'.ps'
	openps,Modules[thisModuleIndex].OutputDir+path_sep()+filename, xsize=6, ysize=4,/inches
	units=(backbone->get_keyword('BUNIT'))
	phot_comp_err_total=phot_comp*sqrt((cal_percent_err/100.)^2+(phot_comp_err/phot_comp)^2)
	ploterror,lambda,phot_comp, phot_comp_err_total,ytitle='flux ['+units+']',xtitle='wavelength (um)',position=[0.16,0.11,0.97,0.97],xr=[min(lambda)-0.01,max(lambda)+0.01],xs=1
	closeps
set_plot,mydevice
endif

thisModuleIndex = Backbone->GetCurrentModuleIndex()
if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin

	backbone->set_keyword, 'xcenter', xcenter, 'x-pixel in datacube where extraction has been made', ext_num=0
	backbone->set_keyword, 'ycenter', ycenter,"x-pixel in datacube where extraction has been made", ext_num=0

	suffix='-spectrum-x'+strc(xcenter)+'-y'+strc(ycenter)
  wav_spec=[[lambda],[phot_comp],[phot_comp_err_total]] 
	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix ,savedata=wav_spec) ;saveheader=hdr,
  if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
endif

display=0 ; ensure no gpitv is invoked to display

 @__end_primitive 

end
