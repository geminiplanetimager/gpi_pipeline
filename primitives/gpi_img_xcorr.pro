;+
; NAME: gpi_img_xcorr.pro
; PIPELINE PRIMITIVE DESCRIPTION: Flexure 2D x correlation with wavecal model
;
;   This primitive uses the relevent microlense PSF and wave cal to generate a model detector image to cross correlate with a science image. 
;   The resulting output can be used as a flexure offset prior to flux extraction.
;
; INPUTS: Science image, microlens PSF, wavecal
;
; OUTPUTS: Flexure offset in xy detector coordinates.
;
; PIPELINE COMMENT: This primitive uses the relevent microlense PSF and wave cal to generate a model detector image to cross correlate with a science image. 
;   The resulting output can be used as a flexure offset prior to flux extraction.
; PIPELINE ARGUMENT: Name="range" Type="float" Default="2" Range="[0,5]" Desc="Range of cross corrleation search in pixels."
; PIPELINE ARGUMENT: Name="resolution" Type="float" Default="0.01" Range="[0,1]" Desc="Subpixel resolution of cross correlation convergence"
; PIPELINE ARGUMENT: Name="psf_sep" Type="float" Default="0.1" Range="[0,1]" Desc="PSF separation in pixels"
; PIPELINE ARGUMENT: Name="stopidl" Type="int" Range="[0,1]" Default="1" Desc="1: stop IDL, 0: dont stop IDL"
; PIPELINE ARGUMENT: Name="x_spec_lens" Type="float" Default="150" Range="[0,281]" Desc="x lenslet number for spectra extraction"
; PIPELINE ARGUMENT: Name="y_spec_lens" Type="float" Default="150" Range="[0,281]" Desc="same for y"
; PIPELINE ARGUMENT: Name="x_off" Type="float" Default="0" Range="[-5,5]" Desc="initial guess for large offsets"
; PIPELINE ARGUMENT: Name="y_off" Type="float" Default="0" Range="[-5,5]" Desc="initial guess for large offsets"
; PIPELINE ARGUMENT: Name="badpix" Type="float" Default="0" Range="[0,1]" Desc="Weight by bad pixel map?"
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

;-----------------------------
;

function gpi_img_xcorr, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id: __template.pro 2340 2014-01-06 16:52:56Z ingraham $' ; get version from subversion to store in header history

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

; the following line sources a block of code common to all primitives
; It loads some common blocks, records the primitive version in the header for
; history, then if calfiletype is not blank it queries the calibration database
; for that file, and does error checking on the returned filename.
@__start_primitive
suffix='' 		 ; set this to the desired output filename suffix

 	if tag_exist( Modules[thisModuleIndex], "range") then range=float(Modules[thisModuleIndex].range) else range=2.0
	if tag_exist( Modules[thisModuleIndex], "resolution") then resolution=float(Modules[thisModuleIndex].resolution) else resolution=0.01

	if tag_exist( Modules[thisModuleIndex], "psf_sep") then steps=float(Modules[thisModuleIndex].psf_sep) else steps=0.1

	;stop idl session
	if tag_exist( Modules[thisModuleIndex], "stopidl") then stopidl=long(Modules[thisModuleIndex].stopidl) else save=0

	;Lenslet number for spectra extraction
	if tag_exist(Modules[thisModuleIndex],"x_spec_lens") then x_spec_lens=float(Modules[thisModuleIndex].x_spec_lens) else x_spec_lens=150
	if tag_exist(Modules[thisModuleIndex],"y_spec_lens") then y_spec_lens=float(Modules[thisModuleIndex].y_spec_lens) else y_spec_lens=150

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
		badpix=ones-badpix
	endif

  	nlens=(size(wavcal))[1]       ;pixel sidelength of final datacube (spatial dimensions) 	
  	;;error handle if readwavcal or not used before
  	if (nlens eq 0)  then $
		return, error('FAILURE ('+functionName+'): Failed to load wavelength calibration data prior to calling this primitive.') 

	; get mlens PSF filename
	if (total(size(mlens_file)) eq 0) then $
		return, error('FAILURE ('+functionName+'): Failed to load microlens PSF data prior to calling this primitive.') 
	
	;free optimization knobs
	xsize=32			;spectra sub image size
	ysize=32			;	extracted for lsqr

	lens_arr=[[46,175],[178,226],[106,51],[237,107]] 	; center lens locations for sub image extraction.
	; make a function to determine satellite spot locations for beter performance?

	blank = fltarr(xsize+20,ysize+20)
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
	exe_tst = execute("resolve_routine,'gpi_lsqr_mlens_extract_dep',/COMPILE_FULL_FILE")

	n=0
	b=0
	a=0
	xsft=resolution
	xsft_sav=xsft
	ysft=resolution
	range_start=range

	while (abs(ysft) gt (resolution/2)) or (abs(xsft_sav) gt (resolution/2)) do begin
		img_spec_ext_amoeba,x_spec_lens,y_spec_lens,img,mlens,wavcal,spec1,spec_img,mic_img,del_lam_best,del_x_best,del_theta_best,x_off,y_off,wcal_off,para,badpix,resid=1,micphn=0,iter=0
		img_spec_ext_amoeba,x_spec_lens+2,y_spec_lens+2,img,mlens,wavcal,spec2,spec_img,mic_img,del_lam_best,del_x_best,del_theta_best,x_off,y_off,wcal_off,para,badpix,resid=1,micphn=0,iter=0
		img_spec_ext_amoeba,x_spec_lens+5,y_spec_lens-5,img,mlens,wavcal,spec3,spec_img,mic_img,del_lam_best,del_x_best,del_theta_best,x_off,y_off,wcal_off,para,badpix,resid=1,micphn=0,iter=0
		img_spec_ext_amoeba,x_spec_lens-5,y_spec_lens+5,img,mlens,wavcal,spec4,spec_img,mic_img,del_lam_best,del_x_best,del_theta_best,x_off,y_off,wcal_off,para,badpix,resid=1,micphn=0,iter=0

			spec_lam = transpose([[spec1[0,*]],[spec2[0,*]],[spec3[0,*]],[spec4[0,*]]])
			spec_flx = transpose([[spec1[1,*]],[spec2[1,*]],[spec3[1,*]],[spec4[1,*]]])

			r = UNIQ(spec_lam,sort(spec_lam))
			spec_lam = spec_lam[r]
			spec_flx = spec_flx[r]

			off1=total(spec1[1,*])/total(spec2[1,*])
			off2=total(spec1[1,*])/total(spec3[1,*])
			off3=total(spec1[1,*])/total(spec4[1,*])

			spec2[1,*]=spec2[1,*]*off1
			spec3[1,*]=spec3[1,*]*off2
			spec4[1,*]=spec4[1,*]*off3

			;window,0
			;plot,spec1[0,*],spec1[1,*]
			;oplot,spec2[0,*],spec2[1,*]
			;oplot,spec3[0,*],spec3[1,*]
			;oplot,spec4[0,*],spec4[1,*]

			spec_flx=(spec1[1,*]+spec2[1,*]+spec3[1,*]+spec4[1,*])/4
			spec_lam=(spec1[0,*]+spec2[0,*]+spec3[0,*]+spec4[0,*])/4

			;stop

			mdl_full = fltarr(xsize*4,ysize*1)
			sub_full = fltarr(xsize*4,ysize*1)

			for z=0,3 do begin

				x_lens_cen=lens_arr[0,z]
				y_lens_cen=lens_arr[1,z]
				;get psf positions from wave cal

					psfpos_cen = get_psf_pos(x_lens_cen,y_lens_cen,wavcal,para[0],para[1],steps,0,0,0,x_off,y_off)
					x_med = floor(mean(psfpos_cen[0,*]))
					y_med = floor(mean(psfpos_cen[1,*]))
					x_sub1 = x_med-ceil(xsize/2)+1
					x_sub2 = x_med+ceil(xsize/2)
					y_sub1 = y_med-ceil(ysize/2)+1
					y_sub2 = y_med+ceil(ysize/2)

					x_grid = rebin(findgen(xsize)+x_sub1,xsize,ysize)
					y_grid = rebin(reform(findgen(ysize)+y_sub1,1,ysize),xsize,ysize)

					imsz=size(img)
					if x_sub2 gt imsz[1]-1 or y_sub2 gt imsz[2]-1 or x_sub1 lt 0 or y_sub1 lt 0 then begin
						spec=[-1,-1]
						spec_img=blank2
						mic_img=blank2
						wcal_off=[0,0,0,0,0]
					endif

					sub_img=img[x_sub1:x_sub2,y_sub1:y_sub2]

				;find psf spot locations

					xr = 35
					yr = 43

					lens_x = (findgen(xr)-floor(xr/2))+x_lens_cen
					lens_y = (findgen(yr)-floor(yr/2))+y_lens_cen

					;print,del_x,del_theta
					spec_spix = [0,0,0,0,0]
					for i=0L,n_elements(lens_x)-1 do begin
						for j=0L,n_elements(lens_y)-1 do begin
							if finite(wavcal[lens_x[i],lens_y[j],0]) then begin
								psfpos = get_psf_pos(lens_x[i],lens_y[j],wavcal,para[0],para[1],steps,0,0,0,x_off,y_off)
								num = n_elements(psfpos[0,*])
								psflens = fltarr(5,num)
								psflens[0:1,*] = psfpos[0:1,*]
				 				psflens[2,*] = lens_x[i]
								psflens[3,*] = lens_y[j]
								psflens[4,*] = psfpos[2,*]
								spec_spix = [[spec_spix],[psflens]]
								;print,[lens_x[i],lens_y[j]]
							endif
						endfor
					endfor
					spec_spix = spec_spix[*,1:*]

					;clean for positions within sub_img
					spec_spix2 = spec_spix[*,where(spec_spix[0,*] gt x_sub1-2 and spec_spix[0,*] lt x_sub2+2)]
					spec_spix3 = spec_spix2[*,where(spec_spix2[1,*] gt y_sub1-2 and spec_spix2[1,*] lt y_sub2+2)]

				;get psf reference images

					s=size(spec_spix3)

					tstimage=blank
					mdl_img=[[blank2]]
					psf_offset = [0,1]

					x_grid = rebin(findgen(xsize)+x_sub1,xsize,ysize)
					y_grid = rebin(reform(findgen(ysize)+y_sub1,1,ysize),xsize,ysize)

					lens_x = long(lens_x[0])
					lens_y = long(lens_y[0])

					;read in high-res of central microlens PSF for and use on whole sub_img
					ptr = gpi_highres_microlens_psf_get_local_highres_psf(mlens,[lens_x,lens_y,0])
					if ptr_valid(mlens[lens_x,lens_y]) then psf = *mlens[lens_x,lens_y]

					common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary
					gpi_highres_microlens_psf_initialize_psf_interpolation, psf.values, psf.xcoords, psf.ycoords

					for k=0L,s[2]-1 do begin

						r1 = gpi_highres_microlens_psf_evaluate_detector_psf(x_grid,y_grid, [spec_spix3[0,k], spec_spix3[1,k], 1])

						;r1=blank
						;r1[(floor(pos_sub[0])-5):(floor(pos_sub[0])+5),(floor(pos_sub[1])-5):(floor(pos_sub[1])+5)]=psf

						;trim off buffer
						;r1=r1[10:(xsize+9),10:(ysize+9)]

						;if total(r1) ne 0 then begin
							lam = spec_spix3[4,k]
							flx = interpol(spec_flx,spec_lam,lam)
							mdl_img = mdl_img+(r1*flx[0])
							;print,flx,lam
						;endif
						;if k eq 0 then stop
					endfor

				;stack sub images length wise
				mdl_full[z*xsize:(z+1)*xsize-1,0:ysize-1]=mdl_img
				sub_full[z*xsize:(z+1)*xsize-1,0:ysize-1]=sub_img

				;twod_img_corr,mdl_img,sub_img,range,resolution,xsft,ysft,corr
				;print,xsft,ysft
				;stop
			endfor

			;mdl_full=mdl_full-median(mdl_full)
			ids = where_xyz(mdl_full lt 0)
			if ids[0] ne -1 then mdl_full[ids]=0

			mdl_full_save = mdl_full
			twod_img_corr,mdl_full,sub_full,range,resolution,xsft,ysft,corr
		;stop
			x_off=x_off-xsft


		;window,1
		;imdisp,corr,/axis
		range=min([range_start,max(abs([ysft,xsft]))])
		range=max([range,7*resolution])

		y_off=y_off-ysft

		print,x_off,y_off

		xsft_sav=xsft

		if (n lt 2) then ysft=0
		n=n+1
	endwhile

	backbone->set_keyword,'HISTORY',functionname+ " Flexure determined by 2D xcorrelation with wavecal"
	;fxaddpar not working to add keyword ??
	;backbone->set_keyword,'FLEXURE_X',xsft
	;backbone->set_keyword,'FLEXURE_Y',ysft

	;itime = backbone->get_keyword('ITIME')

	backbone->Log, "Flexure offset determined to be; X: "+string(x_off)+" Y: "+string(y_off)

@__end_primitive

end
