;+
; NAME: gpi_img_xcorr_pol.pro
; PIPELINE PRIMITIVE DESCRIPTION: Flexure 2D x correlation with polcal model
;
;   This primitive uses the relevent microlense PSF and pol cal to generate a model detector image to cross correlate with a science image. 
;   The resulting output can be used as a flexure offset prior to flux extraction.
;
; INPUTS: Science image, microlens PSF, wavecal
;
; OUTPUTS: Flexure offset in xy detector coordinates.
;
; PIPELINE COMMENT: This primitive uses the relevent microlense PSF and pol cal to generate a model detector image to cross correlate with a science image and find the flexure offset. 
;   The resulting output can be used as a flexure offset prior to flux extraction.
; PIPELINE ARGUMENT: Name="range" Type="float" Default="2" Range="[0,5]" Desc="Range of cross corrleation search in pixels."
; PIPELINE ARGUMENT: Name="resolution" Type="float" Default="0.01" Range="[0,1]" Desc="Subpixel resolution of cross correlation"
; PIPELINE ARGUMENT: Name="psf_sep" Type="float" Default="0.01" Range="[0,1]" Desc="PSF separation in pixels"
; PIPELINE ARGUMENT: Name="stopidl" Type="int" Range="[0,1]" Default="1" Desc="1: stop IDL, 0: dont stop IDL"
; PIPELINE ARGUMENT: Name="x_off" Type="float" Default="0" Range="[-5,5]" Desc="initial guess for large offsets"
; PIPELINE ARGUMENT: Name="y_off" Type="float" Default="0" Range="[-5,5]" Desc="initial guess for large offsets"
; PIPELINE ARGUMENT: Name="badpix" Type="float" Default="0" Range="[0,1]" Desc="Weight by bad pixel map?"
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

;-----------------------------
;

function gpi_img_xcorr_pol, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id: gpi_img_xcorr.pro 2878 2014-04-29 04:11:51Z mperrin $' ; get version from subversion to store in header history

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

@__start_primitive
suffix='' 		 ; set this to the desired output filename suffix

 	if tag_exist( Modules[thisModuleIndex],"range") then range=float(Modules[thisModuleIndex].range) else range=2.0
	if tag_exist( Modules[thisModuleIndex],"resolution") then resolution=float(Modules[thisModuleIndex].resolution) else resolution=0.01

	if tag_exist( Modules[thisModuleIndex],"psf_sep") then steps=float(Modules[thisModuleIndex].psf_sep) else steps=0.01

	;stop idl session
	if tag_exist( Modules[thisModuleIndex],"stopidl") then stopidl=long(Modules[thisModuleIndex].stopidl) else save=0

	if tag_exist(Modules[thisModuleIndex],"x_off") then x_off=float(Modules[thisModuleIndex].x_off) else x_off=0
	if tag_exist(Modules[thisModuleIndex],"y_off") then y_off=float(Modules[thisModuleIndex].y_off) else y_off=0

	img = *dataset.currframe

	;define the common wavelength vector with the IFSFILT keyword:
  	filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  	if (filter eq '') then return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 

	;run badpixel suppresion
	if tag_exist(Modules[thisModuleIndex],"badpix") then $
		badpix=float(Modules[thisModuleIndex].badpix) else badpix=0

	if (badpix eq 1) then begin
		badpix_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header('badpix',*(dataset.headersphu)[numfile],*(dataset.headersext)[numfile])
		badpix = gpi_READFITS(badpix_file)
		ones = bytarr(2048,2048)+1
		badpix = ones-badpix
		;supress all bad pixels 
		img=img*badpix
	endif

  	;;error handle if readpolcal or not used before
	if ~(keyword_set(polcal.coords)) then return, error("You must use Load Polarization Calibration before Assemble Polarization Cube")

	; get mlens PSF filename
	if (total(size(mlens_file)) eq 0) then $
		return, error('FAILURE ('+functionName+'): Failed to load microlens PSF data prior to calling this primitive.') 
	
	;free optimization knobs
	xsize=16			;spectra sub image size
	ysize=64			;	extracted for lsqr

	;lens_arr=[[46,175],[178,226],[85,116],[210,170]] 	; center lens locations for sub image extraction.
	;lens_arr=[[85,116],[210,170],[167,87],[114,190]] 
	lens_arr=[[85,116],[210,170],[46,175],[178,200]]
	; make a function to determine satellite spot locations for beter performance?

	blank2 = fltarr(xsize,ysize)

	;get filter wavelength range
	cwv=get_cwv(filter)	
	gpi_lambda=cwv.lambda	
	para=cwv.CommonWavVect

	wcal_off = [0,0,0,0,0]
	del_lam_best=0
	del_x_best=0
	del_theta_best=0

	;extract stellar spectra in order to match shape of microspectra 
	;	add more extractions to make an average? tune to lenslet at satellite spots or edge of choronograph?
	exe_tst = execute("resolve_routine,'gpi_lsqr_mlens_extract_pol_dep',/COMPILE_FULL_FILE")

	n=0
	b=0
	a=0
	xsft=resolution
	xsft_sav=xsft
	ysft=resolution
	range_start=range
	stddev_mem=[0]
	y_off_mem=[0]
	flux_mem=[0]

	pcal = polcal.spotpos
	;stop
	while (abs(ysft) gt (2*resolution)) or (abs(xsft) gt (resolution/2)) do begin

			;stop

			mdl_full = fltarr(xsize*4,ysize*1)
			sub_full = fltarr(xsize*4,ysize*1)

			for z=0,3 do begin

				x_lens_cen=lens_arr[0,z]
				y_lens_cen=lens_arr[1,z]
				;get psf positions from wave cal

				sub_mdl_img=make_mdl_img_pol(x_lens_cen,y_lens_cen,pcal,x_off,y_off,blank2,xsize,ysize,img,mlens,0)
					   ;make_mdl_img_pol,x_lens_cen,y_lens_cen,pcal,x_off,y_off,blank2,xsize,ysize,img,mlens,pol_flx

				;stack sub images length wise
				mdl_full[z*xsize:(z+1)*xsize-1,0:ysize-1]=sub_mdl_img[*,*,0]/total(sub_mdl_img[*,*,0])
				sub_full[z*xsize:(z+1)*xsize-1,0:ysize-1]=sub_mdl_img[*,*,1]

				;twod_img_corr,sub_mdl_img[*,*,1],sub_mdl_img[*,*,0],range,resolution,xsft,ysft,corr
				;print,xsft,ysft

				;stop
			endfor

			;mdl_full=mdl_full-median(mdl_full)
			;non-negative model
			ids = where_xyz(mdl_full lt 0)
			if ids[0] ne -1 then mdl_full[ids]=0

			;stop

			mdl_full_save = mdl_full
			twod_img_corr,sub_full,mdl_full,range,resolution,xsft,ysft,corr

			print,xsft,ysft
		
			x_off=x_off+xsft

		range=min([range_start,max(abs([ysft,xsft]))])
		range=max([range,7*resolution])
		;range=range_start

		ysft=ysft
		y_off=y_off+ysft

		print,x_off,y_off
		
		;window,1
		;imdisp,corr,/axis
		;window,2
		;imdisp,mdl_full,/axis
		;window,3
		;imdisp,sub_full-(total(sub_full)/total(mdl_full))*mdl_full
		;print,sdev
		;print,total(spec_flx_all)

		;tstimg=fltarr(3*xsize,ysize)
		;data = sub_mdl_img[*,*,1]*(total(sub_mdl_img[*,*,0])/total(sub_mdl_img[*,*,1]))
		;tstimg[0:xsize-1,0:ysize-1] = data
		;model = sub_mdl_img[*,*,0]
		;tstimg[xsize:(2*xsize)-1,0:ysize-1] = model
		;residual = sub_mdl_img[*,*,1]-(total(sub_mdl_img[*,*,1])/total(sub_mdl_img[*,*,0]))*sub_mdl_img[*,*,0]
		;tstimg[(2*xsize):(3*xsize)-1,0:ysize-1] = residual
		;imdisp,tstimg,/axis

		;cgimage, residual, /keep_aspect_ratio, /axis    
		;cgColorbar, /fit, /vertical, position=[0.10, 0.90, 0.90, 0.91]
				
		;stop
	endwhile


	backbone->set_keyword,'HISTORY',functionname+ " Flexure determined by 2D xcorrelation with wavecal"
	;fxaddpar not working to add keyword ??
	;backbone->set_keyword,'FLEXURE_X',xsft
	;backbone->set_keyword,'FLEXURE_Y',ysft

	;itime = backbone->get_keyword('ITIME')

	backbone->Log, "Flexure offset determined to be; X: "+string(x_off)+" Y: "+string(y_off)

@__end_primitive

end
