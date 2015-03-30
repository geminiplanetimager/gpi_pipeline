;+
; NAME: gpi_lsqr_mlens_pol_quick_flx.pro
; PIPELINE PRIMITIVE DESCRIPTION: Flexure Quicklook for Pol (Lsqr, microlens psf) 
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
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="stopidl" Type="int" Range="[0,1]" Default="1" Desc="1: stop IDL, 0: dont stop IDL"
; PIPELINE ARGUMENT: Name="x_lens" Type="float" Default="150" Range="[0,281]" Desc="Lenslet number in x so start search"
; PIPELINE ARGUMENT: Name="y_lens" Type="float" Default="150" Range="[0,281]" Desc="Lenslet number in y so start search"
; PIPELINE ARGUMENT: Name="size" Type="float" Default="4" Range="[0,30]" Desc="Size of region to iterate"
; PIPELINE ARGUMENT: Name="resid" Type="float" Default="1" Range="[0,1]" Desc="Save residual detector image?"
; PIPELINE ARGUMENT: Name="micphn" Type="float" Default="0" Range="[0,1]" Desc="Solve for microphonics?"
; PIPELINE ARGUMENT: Name="iter" Type="float" Default="1" Range="[0,1]" Desc="Run iterative solver of wavecal?"
; PIPELINE ARGUMENT: Name="del_x" Type="float" Default="0" Range="[-5,5]" Desc="Best initial guess for flexure in detector x (pixels)"
; PIPELINE ARGUMENT: Name="del_y" Type="float" Default="0" Range="[-5,5]" Desc="Best initial guess for flexure in detector y (pixels)"
; PIPELINE ARGUMENT: Name="x_off" Type="float" Default="0" Range="[-5,5]" Desc="Offset from wavecal in x pixels (used only if xcorrelariotn wasn't run!)"
; PIPELINE ARGUMENT: Name="y_off" Type="float" Default="0" Range="[-5,5]" Desc="Offset from wavecal in y pixels"
; PIPELINE ARGUMENT: Name="badpix" Type="float" Default="0" Range="[0,1]" Desc="Offset from wavecal in y pixels"
;
; 
; where in the order of the primitives should this go by default?
; PIPELINE ORDER: 5.0
;
; pick one of the following options for the primitive type:
; PIPELINE NEWTYPE: PolarimetricScience
;
; HISTORY:
;    Began 2014-01-13 by Zachary Draper
;-  

;--------------------------------------------------
;MAIN FUNCTION

function gpi_lsqr_mlens_pol_quick_flx, DataSet, Modules, Backbone
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id: __template.pro 2340 2014-01-06 16:52:56Z ingraham $' ; get version from subversion to store in header history

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

@__start_primitive
suffix='' 		 ; set this to the desired output filename suffix

	if tag_exist(Modules[thisModuleIndex],"x_lens") then x_lens=Modules[thisModuleIndex].x_lens else x_lens=150

	if tag_exist(Modules[thisModuleIndex],"y_lens") then y_lens=Modules[thisModuleIndex].y_lens else y_lens=150

	if tag_exist(Modules[thisModuleIndex],"size") then size=Modules[thisModuleIndex].size else size=3

	if tag_exist(Modules[thisModuleIndex],"resid") then resid=Modules[thisModuleIndex].resid else resid=0

	if tag_exist(Modules[thisModuleIndex],"micphn") then micphn=Modules[thisModuleIndex].micphn else micphn=0

	if tag_exist(Modules[thisModuleIndex],"iter") then iter=Modules[thisModuleIndex].iter else iter=0 

	;flexure offset in xy pixel detector coordiantes
	if tag_exist(Modules[thisModuleIndex],"del_x") then del_x=float(Modules[thisModuleIndex].del_x) else del_x=0
	if tag_exist(Modules[thisModuleIndex],"del_y") then del_y=float(Modules[thisModuleIndex].del_y) else del_y=0

	;flexure offset in xy pixel detector coordiantes
	if tag_exist(Modules[thisModuleIndex],"x_off") then x_off=float(Modules[thisModuleIndex].x_off) else x_off=0
	if tag_exist(Modules[thisModuleIndex],"y_off") then y_off=float(Modules[thisModuleIndex].y_off) else y_off=0

	;save final output
	if tag_exist( Modules[thisModuleIndex], "save") then save=long(Modules[thisModuleIndex].save) else save=0

	;stop idl session
	if tag_exist( Modules[thisModuleIndex], "stopidl") then stopidl=long(Modules[thisModuleIndex].stopidl) else stopidl=0

	;;error handle if readpolcal or not used before
	if ~(keyword_set(polcal.coords)) then return, error("You must use Load Polarization Calibration before Assemble Polarization Cube")

	;define the common wavelength vector with the IFSFILT keyword:
  	filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  	if (filter eq '') then return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 

  	nlens=281       ;pixel sidelength of final datacube (spatial dimensions) 

	; get mlens PSF filename
	if ((size(mlens_file))[1] eq 0) then $
		return, error('FAILURE ('+functionName+'): Failed to load microlens PSF data prior to calling this primitive.') 

	;calimg = gpi_readfits(wlcal_file,header=Header)
	
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
	
	id = where_xyz(finite(reform(polcal.spotpos[0,*,*,0])),XIND=xarr,YIND=yarr)
  	nlens_tot = n_elements(xarr)
  	lens = [transpose(xarr),transpose(yarr)]
	
  	;;error handle if readwavcal or not used before
  	if (nlens eq 0)  then $
		return, error('FAILURE ('+functionName+'): Failed to load wavelength calibration data prior to calling this primitive.') 

	; get 2d detector image
	img=*(dataset.currframe[0])
	szim=size(img)

	;setup memory for model images, wavecal offsets, and spectral cube data
	pcal_off_cube=fltarr(nlens,nlens,5)
	pcal_off_cube[0,0,0]=pcal_off_cube

	pol_cube=fltarr(szim[1],szim[2])
	pol_cube[0,0]=pol_cube

	mic_cube=fltarr(szim[1],szim[2])
	mic_cube[0,0]=mic_cube

	gpi_pol=fltarr(nlens,nlens,2)
	gpi_pol[0,0,0]=gpi_pol

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

	exe_tst = execute("resolve_routine,'gpi_lsqr_mlens_extract_pol_dep',/COMPILE_FULL_FILE")	
		img_ext_pol_para,0,(n_elements(lens)/2)-1,99,img,pcal_off_cube,pol_cube,mic_cube,gpi_pol,polcal.spotpos,mlens_file,resid=resid,micphn=micphn,iter=iter,del_x=del_x,del_y=del_y,x_off=x_off,y_off=y_off,lens=lens,badpix=badpix
	
	id = where_xyz(pcal_off_cube[*,*,0] ne 0,XIND=xarr,YIND=yarr)
	if (id ne -1) then begin
		x = pcal_off_cube[*,*,id]
    		y = pcal_off_cube[*,*,id]	

		backbone->Log, string(string(mean(x))+string(mean(y)))
		tst=gpi_pol[xarr,yarr,*]
	endif

@__end_primitive

end
