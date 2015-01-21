;+
; NAME: gpi_lsqr_mlens_quick_flx.pro
; PIPELINE PRIMITIVE DESCRIPTION: Flexure Quicklook for Spectra (Lsqr, microlens psf) 
;
;	This primitive will extract flux from a 2D detector image into a GPI spectral cube using a least-square, matrix inversion algorithm and microlenslet PSFs.  
;	Optionally can produce a residual detector image, solve for microphonics, and iterate the wavecal solution to find a minimum residual.
;	Ideally run in parrallel enviroment.
;
; INPUTS: 2D detector image, wavecal, microlens PSF reference.
;
; OUTPUTS: None
;
; PIPELINE COMMENT: This primitive will extract flux from a 2D detector image into a GPI spectral cube using a least-square algorithm and microlenslet PSFs. Optionally can produce a residual detector image, solve for microphonics, and iterate the wavecal solution to find a minimum residual.
; PIPELINE ARGUMENT: Name="stopidl" Type="int" Range="[0,1]" Default="1" Desc="1: stop IDL, 0: dont stop IDL"
; PIPELINE ARGUMENT: Name="x_lens" Type="float" Default="150" Range="[0,281]" Desc="Lenslet number in x so start search"
; PIPELINE ARGUMENT: Name="y_lens" Type="float" Default="150" Range="[0,281]" Desc="Lenslet number in y so start search"
; PIPELINE ARGUMENT: Name="size" Type="float" Default="5" Range="[0,30]" Desc="Size of region to iterate"
; PIPELINE ARGUMENT: Name="resid" Type="float" Default="1" Range="[0,1]" Desc="Save residual detector image?"
; PIPELINE ARGUMENT: Name="micphn" Type="float" Default="0" Range="[0,1]" Desc="Solve for microphonics?"
; PIPELINE ARGUMENT: Name="iter" Type="float" Default="1" Range="[0,2]" Desc="Run iterative solver of wavecal?"
; PIPELINE ARGUMENT: Name="badpix" Type="float" Default="0" Range="[0,1]" Desc="Weight by bad pixel map?"
; PIPELINE ARGUMENT: Name="del_x_best" Type="float" Default="0" Range="[-5,5]" Desc="Best initial guess for flexure perpendicular to dispersion shift (pixels)"
; PIPELINE ARGUMENT: Name="del_theta_best" Type="float" Default="0" Range="[-5,5]" Desc="Best initial guess for rotation angle shift (degrees)"
; PIPELINE ARGUMENT: Name="del_lam_best" Type="float" Default="0" Range="[-5,5]" Desc="Best initial guess for flexure parrallel to dispersion shift (pixels)"
; PIPELINE ARGUMENT: Name="x_off" Type="float" Default="0" Range="[-5,5]" Desc="Offset from wavecal in x pixels (used only if xcorrelariotn wasn't run!)"
; PIPELINE ARGUMENT: Name="y_off" Type="float" Default="0" Range="[-5,5]" Desc="Offset from wavecal in y pixels"
;
; 
; where in the order of the primitives should this go by default?
; PIPELINE ORDER: 5.0
;
; pick one of the following options for the primitive type:
; PIPELINE NEWTYPE: SpectralScience
;
; HISTORY:
;    Began 2014-01-13 by Zachary Draper
;-  

;--------------------------------------------------
;MAIN FUNCTION

function gpi_lsqr_mlens_quick_flx, DataSet, Modules, Backbone
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id: __template.pro 2340 2014-01-06 16:52:56Z ingraham $' ; get version from subversion to store in header history

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

@__start_primitive
suffix='quick_residual' 		 ; set this to the desired output filename suffix

	if tag_exist(Modules[thisModuleIndex],"x_lens") then x_lens=Modules[thisModuleIndex].x_lens else x_lens=150

	if tag_exist(Modules[thisModuleIndex],"y_lens") then y_lens=Modules[thisModuleIndex].y_lens else y_lens=150

	if tag_exist(Modules[thisModuleIndex],"size") then size=Modules[thisModuleIndex].size else size=5

	;keywords for solver
	keywords=''
	if tag_exist(Modules[thisModuleIndex],"resid") then resid=Modules[thisModuleIndex].resid else resid=0
	keywords=keywords+',resid='+string(resid)

	if tag_exist(Modules[thisModuleIndex],"micphn") then micphn=Modules[thisModuleIndex].micphn else micphn=0
	keywords=keywords+',micphn='+string(micphn)

	if tag_exist(Modules[thisModuleIndex],"iter") then iter=Modules[thisModuleIndex].iter else iter=0 
	keywords=keywords+',iter='+string(iter)

	;initial flexure offsets in dispersion coordiantes
	if tag_exist(Modules[thisModuleIndex],"del_x_best") then del_x_best=float(Modules[thisModuleIndex].del_x_best) else del_x_best=0
	if tag_exist(Modules[thisModuleIndex],"del_theta_best") then del_theta_best=float(Modules[thisModuleIndex].del_theta_best) else del_theta_best=0
	if tag_exist(Modules[thisModuleIndex],"del_lam_best") then del_lam_best=float(Modules[thisModuleIndex].del_lam_best) else del_lam_best=0

	;flexure offset in xy pixel detector coordiantes
	if tag_exist(Modules[thisModuleIndex],"x_off") then x_off=float(Modules[thisModuleIndex].x_off) else x_off=0
	if tag_exist(Modules[thisModuleIndex],"y_off") then y_off=float(Modules[thisModuleIndex].y_off) else y_off=0

	;save final output
	if tag_exist( Modules[thisModuleIndex], "save") then save=long(Modules[thisModuleIndex].save) else save=0

	;stop idl session
	if tag_exist( Modules[thisModuleIndex], "stopidl") then stopidl=long(Modules[thisModuleIndex].stopidl) else stopidl=0

	;run badpixel suppresion
	if tag_exist(Modules[thisModuleIndex],"badpix") then $
		badpix=float(Modules[thisModuleIndex].badpix) else badpix=0

	if (badpix eq 1) then begin
		badpix_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header('badpix',*(dataset.headersphu)[numfile],*(dataset.headersext)[numfile])
		if ((size(badpix_file))[1] eq 0) then $
			return, error('FAILURE ('+functionName+'): Failed to find badpixel map, set to 0 or make badpixel map prior.')
		badpix = gpi_READFITS(badpix_file)
		ones = bytarr(2048,2048)+1
		badpix=ones-badpix
	endif

	;Lenslet number for spectra extraction
	if tag_exist(Modules[thisModuleIndex],"x_spec_lens") then x_spec_lens=float(Modules[thisModuleIndex].x_spec_lens) else x_spec_lens=150
	if tag_exist(Modules[thisModuleIndex],"y_spec_lens") then y_spec_lens=float(Modules[thisModuleIndex].y_spec_lens) else y_spec_lens=150
	
	; get mlens PSF filename
	if ((size(mlens_file))[1] eq 0) then $
		return, error('FAILURE ('+functionName+'): Failed to load microlens PSF data prior to calling this primitive.') 

	;define the common wavelength vector with the IFSFILT keyword:
  	filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  	if (filter eq '') then return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 

  	nlens=(size(wavcal))[1]       ;pixel sidelength of final datacube (spatial dimensions) 
	
  	;;error handle if readwavcal or not used before
  	if (nlens eq 0) then $
		return, error('FAILURE ('+functionName+'): Failed to load wavelength calibration data prior to calling this primitive.') 

	; get 2d detector image put into shared memory
	img=*(dataset.currframe[0])
	szim=size(img)

	;setup memory for model images, wavecal offsets, and spectral cube data
	wcal_off_cube=fltarr(nlens,nlens,7)-1
	wcal_off_cube[0,0,0]=wcal_off_cube

	spec_cube=fltarr(szim[1],szim[2])
	spec_cube[0,0]=spec_cube

	mic_cube=fltarr(szim[1],szim[2])
	mic_cube[0,0]=mic_cube

	gpi_cube=fltarr(nlens,nlens,37)
	gpi_cube[0,0,0]=gpi_cube

	; need to interpolate into a regular grid during reduction since lsqr algo can have diffrent psf per spectra with IDL array constraints
	cwv=get_cwv(filter)	
	gpi_lambda=cwv.lambda	
	para=cwv.CommonWavVect

	lens_sz = findgen(size*2)
	lens_x = (lens_sz+x_lens)-size;<- spot low left [104,59]
	lens_y = (lens_sz+y_lens)-size
	lens=[0,0]
	for i=0,n_elements(lens_x)-1 do begin
		for j=0,n_elements(lens_y)-1 do begin
			lens = [[lens],[lens_x[i],lens_y[j]]]
		endfor
	endfor
	lens=lens[*,1:*]
stop	 	
	exe_tst = execute("resolve_routine,'gpi_lsqr_mlens_extract_dep',/COMPILE_FULL_FILE,/EITHER")
	img_ext_para,0,(n_elements(lens)/2)-1,99,img,wcal_off_cube,spec_cube,mic_cube,gpi_cube,gpi_lambda,para,wavcal,mlens_file,del_x_best=del_x_best,del_theta_best=del_theta_best,del_lam_best=del_lam_best,badpix=badpix,x_off=x_off,y_off=y_off,resid=resid,iter=iter,micphn=micphn,lens=lens	
	
	wavestep = (para[1]-para[0])/(para[2])
	
	id = where_xyz(wcal_off_cube[*,*,4] ne 0.001,XIND=xarr,YIND=yarr)

	sft = wcal_off_cube[xarr,yarr,1]
	deg = wcal_off_cube[xarr,yarr,2]
	lam = wcal_off_cube[xarr,yarr,3]
	chi = wcal_off_cube[xarr,yarr,4]

	x = wcal_off_cube[xarr,yarr,5]
    	y = wcal_off_cube[xarr,yarr,6]

	backbone->Log, string(mean(sft))+string(mean(deg))+string(mean(lam))+string(mean(x))+string(mean(y))

	tst=gpi_cube[xarr,yarr,*]

	;plot histograms of fits
	;window,0
	;cgHistoplot, sft, BINSIZE=0.1, /FILL, xtitle='Shift (Pixels)', MAXINPUT=1, MININPUT=-1, output=gpi_get_directory('GPI_DRP_DIR')+"/shift_pixels.png"
	;cgHistoplot, deg/!dtor, BINSIZE=0.1, /FILL, xtitle='Rotation (Degrees)', MAXINPUT=6, MININPUT=-6, output=gpi_get_directory('GPI_DRP_DIR')+"/shift_degrees.png"
	;cgHistoplot, lam, BINSIZE=0.1, /FILL, xtitle='lambda shift (Pixels)', MAXINPUT=3, MININPUT=-3, output=gpi_get_directory('GPI_DRP_DIR')+"/shift_lam.png"
	;cgHistoplot, chi, BINSIZE=100, /FILL, xtitle='chi test', MAXINPUT=max(chi), MININPUT=0, output=gpi_get_directory('GPI_DRP_DIR')+"/chi.png"
	window,1
	cgHistoplot, x, BINSIZE=0.1, /FILL, xtitle='X', MAXINPUT=max(x), MININPUT=min(x);, output=gpi_get_directory('GPI_DRP_DIR')+"/x.png"
	window,2	
	cgHistoplot, y, BINSIZE=0.1, /FILL, xtitle='Y', MAXINPUT=max(y), MININPUT=min(y);, output=gpi_get_directory('GPI_DRP_DIR')+"/y.png"

	;unmap shared mem
	;SHMUNMAP, 'wcal_off_cube'
	;SHMUNMAP, 'spec_cube'
	;SHMUNMAP, 'mic_cube'
	;SHMUNMAP, 'gpi_cube'

	if (resid eq 1) then begin
		residual=img-spec_cube
		if (micphn eq 1) then residual=residual-mic_cube
	endif

	*(dataset.currframe)=residual

@__end_primitive

end
