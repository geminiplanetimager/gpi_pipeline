;+
; NAME: gpi_extract_1d_spectrum
; PIPELINE PRIMITIVE DESCRIPTION: Extract 1D spectrum from a datacube
;
; WARNING: This primitive will not provide spectra of publishable quality
; it is designed to perform a quick extraction of a source. 
;
;
; This primitive extracts a spectrum from a data cube. It is meant to be used 
; on datacubes that have been calibrated by gpi_apply_photometric_calibration, 
; but this is not strictly required.
;
; The extraction radius is pulled out of the header such that is uses the 
; same as what was used to calibrate the cube. If they keyword is not found, 
; then the extraction_radius keyword is used. The extraction_radius keyword will 
; also be used if the override keyword is set to 1. Note that this is NOT
; recommended and will introduce systematics into the data. 
;
; The centroiding is performed by fitting a gaussian to the region of interest. 
; A line is then fit to the centroids and used. In this fit, the first and last 
; 4 data points are excluded due to low transmission. The errors for each centroid 
; are determined by taking the largest of the offsets between the subtraction of adjacent 
; centroids (e.g. yerr[j]=0.1>abs(yarr0[j]-yarr0[j+1])>abs(yarr0[j]-yarr0[j-1]) )
;
; All photometry is done in ADU/coadd. This is performed by converting the cube to 
; ADU/coadd then converting back to whatever units the cube was input with.
;
; The error bars are determined using the same method as the satellite spots
; in gpi_calibrate_photometric_flux primitive. The user specifies the sky radii used in performing the aperture photometry. Note that the 'annuli' only represent the radial size of the extraction. The background is extracted by fitting a constant to an annulus surrounding the central star at the same radius as the planet. The inner width of the annulus is equal to the inner_sky_radius, the outer annulus describes the distance from the companion to the edges of the annulus that should be considered when fitting the constant. If the user wishes to examine the section being fit, they should modify line 350 accordingly.
;
; Highpass filtering the image is recommended to determine the centroids, note that the highpass filtered image
; is not used when measuring the extracted spectrum.
;
; INPUTS: Datacube containing a source that needs extracting, located by the xcenter and ycenter arguments
; OUTPUTS: 1D spectrum
;
; KEYWORDS:
;
; Save: Set to 1 to save the spectrum to a disk file (.fits). 
; xcenter: x-location of extraction (in pixels)
; ycenter: y-location of extraction (in pixels)
; highpass: highpass filter the image when determining centroid?
; inner_sky_radius: inner radius used in defining sky subtraction annulus section
; outer_sky_radius: outer radius used in defining sky subtraction annulus section
; override: allows input of a new extraction radius, and the use/non-use of c_ap_scaling
; extraction_radius: Radius used to define annulus for source extraction. This keyword is only active if the override keyword is set, or if the CEXTR_AP keyword, set by the Calibrate Photometric Flux primitive (gpi_calibrate_photometric_flux.pro) is not present in the header
; c_ap_scaling: keyword that activates the scaling of the apertures with wavelength. This keyword is only active if the override keyword is set, or if the C_AP_SC keyword, set by the Calibrate Photometric Flux primitive (gpi_calibrate_photometric_flux.pro) is not present in the header
; display: window used to display the extracted spectrum plot
; save_ps_plot: saves a postscript version of the plot if desired
; write_ascii_file: writes as ascii output of the spectra - no header info included
;
; GEM/GPI KEYWORDS:FILTER,IFSUNIT
; DRP KEYWORDS: CUNIT,DATAFILE,SPECCENX,SPECCENY
;
; PIPELINE COMMENT: Extract one spectrum from a datacube somewhere in the FOV specified by the user.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="xcenter" Type="float" Range="[-1,280]" Default="-1" Desc="x-location in pixels on datacube where extraction will be made"
; PIPELINE ARGUMENT: Name="ycenter" Type="float" Range="[-1,280]" Default="-1" Desc="y-location in pixels on datacube where extraction will be made"
; PIPELINE ARGUMENT: Name="highpass" Type="int" Range="[0,25]" Default="0" Desc="highpass filter box size for centroiding"
; PIPELINE ARGUMENT: Name="no_centroid_override" Type="int" Range="[0,1]" Default="0" Desc="Do not centroid on extraction source?"
; PIPELINE ARGUMENT: Name="inner_sky_radius" Type="float" Range="[1,100]" Default="10." Desc="Inner aperture radius at middle wavelength slice (in spaxels i.e. mlens) to extract sky"
; PIPELINE ARGUMENT: Name="outer_sky_radius" Type="float" Range="[1,100]" Default="20." Desc="Outer aperture radius at middle wavelength slice (in spaxels i.e. mlens) to extract sky"
; PIPELINE ARGUMENT: Name="override" Type="int" Range="[0,1]" Default="0" Desc="Override apertures/scaling from spectrophotometric calibration?"
; PIPELINE ARGUMENT: Name="extraction_radius" Type="float" Range="[0,1000]" Default="5." Desc="Aperture radius at middle wavelength (in spaxels i.e. mlens) to extract photometry for each wavelength. (only active if Override is set)"
; PIPELINE ARGUMENT: Name="c_ap_scaling" Type="int" Range="[0,1]" Default="1" Desc="Perform aperture scaling with wavelength?"
; PIPELINE ARGUMENT: Name="display" Type="int" Range="[-1,100]" Default="17" Desc="-1 = No display; 0 = New (unused) window; else = Window number to display diagnostic plot."
; PIPELINE ARGUMENT: Name="save_ps_plot" Type="int" Range="[0,1]" Default="0" Desc="Save PostScript of plot?"
; PIPELINE ARGUMENT: Name="write_ascii_file" Type="int" Range="[0,1]" Default="0" Desc="Save ascii file of spectrum (.dat)?"
; PIPELINE ORDER: 2.52
; PIPELINE CATEGORY: SpectralScience
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
if tag_exist( Modules[thisModuleIndex], "no_centroid_override") then no_centroid_override=float(Modules[thisModuleIndex].no_centroid_override) else no_centroid_override=0
if tag_exist( Modules[thisModuleIndex], "highpass") then highpass=float(Modules[thisModuleIndex].highpass) else highpass=0

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
    source_cube=*(dataset.currframe[0])

    badpix = [0,0] & phpadu=1     

	if c_ap_scaling eq 1 then begin
		aperrad0=fltarr(N_ELEMENTS(lambda))
		aperrad0[*]=extraction_radius/lambda[N_ELEMENTS(lambda)/2]  
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
				
				; highpass filter the data?
				s0i=source_cube[*,*,i]
				if keyword_set(highpass) eq 1 then s0i -= filter_image(s0i,median=highpass)	 
				; centroid on the companion
				stamp2 = s0i[x0-hh:x0+hh,y0-hh:y0+hh]/fscale_arr[i]
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

; throw and error if there is a centroiding issue
	if total(finite(xarr0)) eq 0 or total(finite(yarr0)) eq 0 then $
		return, error('FAILURE ('+functionName+'): entire x or y centroids are NaNs; make sure the spectral extraction position is correct') 

	;determine error from the data
	for j=1,N_ELEMENTS(lambda)-2 do xerr[j]=0.1>abs(xarr0[j]-xarr0[j+1])>abs(xarr0[j]-xarr0[j-1])
	for j=1,N_ELEMENTS(lambda)-2 do yerr[j]=0.1>abs(yarr0[j]-yarr0[j+1])>abs(yarr0[j]-yarr0[j-1])
	delvarx,ax,bx,ay,by
	; make sure all are finite and ignore first and last 3 points in the cube since hte SNR is crap
	ind = where(finite(xarr0+yarr0) ne 0 and xerr ne 0 and yerr ne 0 and (lambda gt lambda[3] and lambda lt lambda[N_ELEMENTS(lambda)-4]))
	fitexy,lambda[ind],xarr0[ind],Ax,Bx,X_sig=1e-3,y_sig=xerr[ind]
	fitexy,lambda[ind],yarr0[ind],Ay,By,X_sig=1e-3,y_sig=yerr[ind]
	xarr=lambda*Bx+Ax
	yarr=lambda*By+Ay
	; examine the fits?
	if 0 eq 1 then begin
		window,23,title='xcentroid vs extracted position relative to xcenter',xsize=700,ysize=400
		plot,lambda,xarr0-xcenter,yr=[min(xarr-xcenter,/nan),max(xarr-xcenter,/nan)],background=cgcolor('white'),color=cgcolor('black'),xtitle='wavelength',ytitle='[x,y] centroid minus [x,y] center',charsize=1.5,thick=2
		oplot, lambda,xarr-xcenter,linestyle=2,color=cgcolor('black'),thick=2
		window,24,title='ycentroid vs extracted position relative to ycenter',xsize=700,ysize=400
		plot,lambda,yarr0-ycenter,color=cgcolor('black'),yr=[0.9*min(yarr-ycenter,/nan),1.1*max(yarr-ycenter,/nan)],background=cgcolor('white'),xtitle='wavelength',ytitle='[x,y] centroid minus [x,y] center',charsize=1.5,thick=2
		oplot,lambda,yarr-ycenter,color=cgcolor('black'),linestyle=2,thick=2
	endif ; 
	endif else begin
		; just hard set to the define centroid
		; but it still must be centered on a half pixel
		xarr=replicate(xcenter,N_ELEMENTS(lambda))
		yarr=replicate(ycenter,N_ELEMENTS(lambda))	
	endelse

; start photometry
ygrid=findgen(281)##(fltarr(281)+1)
xgrid=transpose(ygrid)
; but want the grids centered on 
PSFCENTX=(backbone->get_keyword('PSFCENTX',count=count,ext_num=1))
PSFCENTY=(backbone->get_keyword('PSFCENTY',count=count,ext_num=1))
ygrid-=psfcenty
xgrid-=psfcentx

; first rotate the grids such that the angle is defined to be zero
; where the planet is

; get the angle from the declared position [x0,y0]
theta0=atan((y0-psfcenty)/(x0-psfcentx))

; want to rotate away not towards
theta=-theta0

xgrid2=xgrid*cos(theta)-ygrid*sin(theta) ; rotate coord system
ygrid2=xgrid*sin(theta)+ygrid*cos(theta)
rad_arr=sqrt(xgrid2^2+ygrid2^2); make radius array
ang_arr=atan(ygrid2/(xgrid2)) ; make angle array

xgrid=temporary(xgrid2)
ygrid=temporary(ygrid2)

; make a polar coordinate system where the 
     for i=0,CommonWavVect[2]-1 do begin
				if finite(xarr[i]+yarr[i]) eq 0 then continue	
				aperrad = aperrad0[i]*lambda[i]
				skyrad  = skyrad0*lambda[i]
				trans_cube_slice=translate(source_cube[*,*,i]/fscale_arr[i],x0-xarr[i],y0-yarr[i])

				; highpass filter FOR TESTING ONLY!
				;trans_cube_slice -= filter_image(trans_cube_slice,median=30)	



			; do an error approximation - the error is useless from aper unless in photons and
				; even then it adds photon noise that won,t be correct.
				;get size of aperture in pixels - this is not really exact...
				src_ind=get_xycind(281,281,x0,y0,aperrad)
				
				; lets look at fitting a piece of an annulus instead
				; first find the planet/star separation
				sep=sqrt((x0-psfcentx)^2+(y0-psfcenty)^2)
				dr= ceil(aperrad*2)
				; set to REAL ANGLE SOON
				dang=(skyrad[1]/sep)

				parity=(x0-psfcentx)/abs((x0-psfcentx))
				bkg_ind0=where(xgrid/abs(xgrid) eq parity and  ang_arr gt ((-dang) mod !pi) and $
					 ang_arr lt ((dang) mod !pi) and $
				rad_arr gt sep-dr and rad_arr lt sep+dr )

				; just to check bkg region
				if 0 eq 1 and i eq 15 then begin
					tmp=fltarr(281,281)
					tmp[bkg_ind0]=1
					window,13,xsize=300,ysize=300,title='companion bkg region'
					tvdl,tmp*trans_cube_slice
					;wait,1
				endif
				; mask source region+1 pixel
				tmp_src_ind=get_xycind(281,281,x0,y0,ceil(skyrad[0]))
				bkg_ind=setdifference(bkg_ind0,tmp_src_ind)
				
				; declare arrays when in the first iteration of loop
				if i eq 0 then begin
					bkg_ind_slice0=bkg_ind			
					bkg_ind_arr=fltarr(N_ELEMENTS(lambda),N_ELEMENTS(bkg_ind_slice0))
				endif
				bkg_ind_arr[i,*]=trans_cube_slice[bkg_ind_slice0]

				; error check to see that not all nan's are encountered
				if bkg_ind[0] eq -1 or total(finite(trans_cube_slice[bkg_ind])) eq 0 or total(finite(trans_cube_slice[src_ind])) eq 0 then begin
					phot_comp[i]=!values.f_nan
					phot_comp_err[i]=!values.f_nan
					continue
				endif
				; fit plane to bkg
				weights=0
				finite_bkg_ind=bkg_ind[where(finite(trans_cube_slice[bkg_ind]) eq 1)]
				; fits and subtracts a plane to get proper error estimation
				; this should be done in POLAR COORDs
				coef = PLANEFIT( finite_bkg_ind mod 281 ,finite_bkg_ind / 281,trans_cube_slice[finite_bkg_ind],weights, yfit )
				xinds=src_ind mod 281 & yinds=src_ind / 281	
				src_bkg_plane=coef[0]+coef[1]*xinds+coef[2]*yinds

				; OVERRIDE
				yfit[*]=median(trans_cube_slice[finite_bkg_ind])
				src_bkg_plane[*]=median(trans_cube_slice[finite_bkg_ind])

				; do the photometry and error calculation
				phot_comp[i]=total(trans_cube_slice[src_ind]-src_bkg_plane)

				; now do the error bar - this is dirty and must be cleaned up.. 
				; must convolve the bkg by the source annulus, then 
				bkg=fltarr(281,281) & mask=fltarr(281,281)+1
				bkg[finite_bkg_ind]=trans_cube_slice[finite_bkg_ind]-yfit
				; mask bad regions in background
				bkg_bad=where(bkg eq 0) ;
				bkg[bkg_bad]=!values.f_nan & mask[bkg_bad]=!values.f_nan
				bkg[src_ind]=!values.f_nan
				kernel0=fltarr(281,281)
				kernel0[src_ind]=1
				kernel=subarr(kernel0,ceil(aperrad*2)+2,[x0,y0])
				bkg_conv=convol(bkg,kernel,/nan)
				mask2=convol(mask,kernel,/nan)
				; elements where there was no vignetting of the convolution
				good_ind=where(mask2 eq N_ELEMENTS(src_ind))
				mask2[*,*]=!values.f_nan
				mask2[good_ind]=1
				phot_comp_err[i]=stddev(bkg_conv[good_ind],/nan,/double)
				if finite(phot_comp_err[i]) eq 0 then stop, 'bad extraction'
				
					; examine the fit
				if 1 eq 1 and i eq 31 then begin
					yfit2d=fltarr(281,281)
					yfit2d[*,*]=!values.f_nan
					yfit2d[finite_bkg_ind]=yfit
					yfit2d[src_ind]=src_bkg_plane
					tmask=fltarr(281,281)
					tmask[*,*]=!values.f_nan
					tmask[good_ind]=1 & tmask[src_ind]=1
					rmax=max(trans_cube_slice[good_ind],/nan)
					rmin=min(trans_cube_slice[good_ind],/nan)
					sz=skyrad[1]*2*3 
					sz=300
					loadct,1
					window,0, xsize=sz*4,ysize=sz,title='companion background region/fit/residuals/error',xpos=0,ypos=400
					tvdl, subarr(trans_cube_slice*tmask,ceil(skyrad[1]+1)*2,[x0,y0]),rmin,rmax,position=0
					tvdl, subarr(yfit2d*tmask,          ceil(skyrad[1]+1)*2,[x0,y0]),rmin,rmax,position=1
					tvdl, subarr((trans_cube_slice-yfit2d)*tmask,ceil(skyrad[1]+1)*2,[x0,y0]),position=2					
					
					tmask[src_ind]=!values.f_nan
					tvdl, subarr(bkg_conv*tmask,ceil(skyrad[1]+1)*2,[x0,y0]),position=3
					print,phot_comp[i],phot_comp_err[i]
					print,'SNR at slice '+strc(i)+' ('+strc(lambda[i])+' um)', phot_comp[i]/phot_comp_err[i]

					;stop

				endif

				; now normalize for missing flux ratio in aperture used in gpi_calibrate_photometric flux
				; this just cancels out if the extraction aperture is unchanged, which it should be! 
				; this area of the code will be modified once we start using different apertures. 
				phot_comp[i]/=(contained_flux_ratio)
				phot_comp_err[i]/=(contained_flux_ratio)
		endfor
;window,2,retain=2,xsize=600,ysize=400
;ploterror,lambda,phot_comp,phot_comp_err

; now convert back to desired units
for l=0, N_ELEMENTS(lambda)-1 do phot_comp[l]*=fscale_arr[l]
for l=0, N_ELEMENTS(lambda)-1 do phot_comp_err[l]*=fscale_arr[l]

;window,3,retain=2,xsize=600,ysize=400
;ploterror,lambda,phot_comp,phot_comp_err
;stop
;wdelete,2
;wdelete,3

; we want to correlate wrt to which wavelength?
;correl_arr=fltarr(N_ELEMENTS(lambda))
;for l=0, N_ELEMENTS(lambda)-1 do correl_arr[l]=CORRELATE(bkg_ind_arr[22,*], bkg_ind_arr[l,*], /COVARIANCE)
;stop


if display ne -1 then begin
  if display eq 0 then window,/free,xsize=700,ysize=400 else select_window, display,xsize=700,ysize=400
	units=(backbone->get_keyword('BUNIT'))
	phot_comp_err_total=phot_comp*sqrt((cal_percent_err/100.)^2+(phot_comp_err/phot_comp)^2)
	ploterror,lambda,phot_comp, phot_comp_err_total,ytitle='flux ['+units+']',xtitle='wavelength (um)',position=[0.16,0.11,0.97,0.97],xr=[min(lambda)-0.01,max(lambda)+0.01],xs=1,color=cgcolor('black'),background=cgcolor('white'),yr=[min(phot_comp[3:N_ELEMENTS(lambda)-4],/nan)*0.9,max(phot_comp[3:N_ELEMENTS(lambda)-4],/nan)*1.1];,yr=[6,18]*1e-17,/ys;

; ######## testing
;
;model0=mrdfits('/Users/patrickingraham/GPI/pipeline/config/planet_models/gpi_spec_hy1s_mass_010_age_0030.fits',1)
;;ind=where(model.wavelength_in_microns ge lambda[0] and model.wavelength_in_microns le lambda[35])
;model=interpol(model0.GPI_hot_SPEC_IN_ERG_CM2_S_UM,model0.wavelength_in_microns,lambda)
;
;norm=median(phot_comp)/median(model)
;
;oplot,lambda,model*norm,color=cgcolor('red')
; end testing

;stop

endif

if save_ps_plot eq 1 then begin
mydevice=!d.name
	filename=strmid(dataset.filenames[0],0,strlen(dataset.filenames[0])-5)+'-spectrum-x'+strc(round(xcenter))+'-y'+strc(round(ycenter))+'.ps'
	openps,Modules[thisModuleIndex].OutputDir+path_sep()+filename, xsize=6, ysize=4,/inches
	units=(backbone->get_keyword('BUNIT'))
	phot_comp_err_total=phot_comp*sqrt((cal_percent_err/100.)^2+(phot_comp_err/phot_comp)^2)
yr=[min(phot_comp[3:N_ELEMENTS(lambda)-4],/nan)*0.9,max(phot_comp[3:N_ELEMENTS(lambda)-4],/nan)*1.1]
	ploterror,lambda,phot_comp, phot_comp_err_total,ytitle='flux ['+units+']',xtitle='wavelength (um)',position=[0.16,0.11,0.97,0.97],xr=[min(lambda)-0.01,max(lambda)+0.01],xs=1,yr=yr,color=cgcolor('black'),background=cgcolor('white'),font=1

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
