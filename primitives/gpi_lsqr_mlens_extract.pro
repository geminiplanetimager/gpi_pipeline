;+
; NAME: gpi_lsqr_mlens_extract.pro
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Spectral Datacube (Lsqr, microlens psf) 
;
;	This primitive will extract flux from a 2D detector image into a GPI spectral cube using a least-square, matrix inversion algorithm and microlenslet PSFs.  
;	Optionally can produce a residual detector image, solve for microphonics, and iterate the wavecal solution to find a minimum residual.
;	Ideally run in parrallel enviroment.
;
; INPUTS: 2D detector image, wavecal, microlens PSF reference.
;
; OUTPUTS: GPI datacube
;
; PIPELINE COMMENT: This primitive will extract flux from a 2D detector image into a GPI spectral cube using a least-square algorithm and microlenslet PSFs. Optionally can produce a residual detector image, solve for microphonics, and iterate the wavecal solution to find a minimum residual.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="stopidl" Type="int" Range="[0,1]" Default="1" Desc="1: stop IDL, 0: dont stop IDL"
; PIPELINE ARGUMENT: Name="np" Type="float" Default="4" Range="[0,100]" Desc="Number of processors to use in reduction (double check enviroment before running)"
; PIPELINE ARGUMENT: Name="resid" Type="int" Default="1" Range="[0,1]" Desc="Save residual detector image?"
; PIPELINE ARGUMENT: Name="micphn" Type="int" Default="0" Range="[0,1]" Desc="Solve for microphonics?"
; PIPELINE ARGUMENT: Name="iter" Type="int" Default="0" Range="[0,1]" Desc="Run iterative solver of wavecal?"
; PIPELINE ARGUMENT: Name="badpix" Type="float" Default="0" Range="[0,1]" Desc="Weight by bad pixel map?"
; PIPELINE ARGUMENT: Name="del_x_best" Type="float" Default="0" Range="[-5,5]" Desc="Best initial guess for flexure perpandicular to dispersion shift (pixels)"
; PIPELINE ARGUMENT: Name="del_theta_best" Type="float" Default="0" Range="[-5,5]" Desc="Best initial guess for rotation angle shift (degrees)"
; PIPELINE ARGUMENT: Name="del_lam_best" Type="float" Default="0" Range="[-5,5]" Desc="Best initial guess for flexure parrallel to dispersion shift (pixels)"
; PIPELINE ARGUMENT: Name="x_off" Type="float" Default="0" Range="[-5,5]" Desc="Offset from wavecal in x pixels"
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

function gpi_lsqr_mlens_extract, DataSet, Modules, Backbone
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id$' ; get version from subversion to store in header history

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

@__start_primitive
suffix='spdc' 		 ; set this to the desired output filename suffix

	;processors
 	if tag_exist( Modules[thisModuleIndex], "np") then np=float(Modules[thisModuleIndex].np) else np=2

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
  	if (n_elements(xsft) eq 0) or (n_elements(ysft) eq 0) then begin
     		backbone->Log,'Flexure shift not determined prior to flux extraction, using primitive parameters instead.' 
		if tag_exist(Modules[thisModuleIndex],"x_off") then xsft=float(Modules[thisModuleIndex].x_off) else xsft=0
		if tag_exist(Modules[thisModuleIndex],"y_off") then ysft=float(Modules[thisModuleIndex].y_off) else ysft=0
	endif else begin
		backbone->Log,"Using prior flexure offsets; X: "+string(xsft)+" Y: "+string(ysft)
	endelse

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
	
	; get mlens PSF filename
	if ((size(mlens_file))[1] eq 0) then $
		return, error('FAILURE ('+functionName+'): Failed to load microlens PSF data prior to calling this primitive.') 

	;define the common wavelength vector with the IFSFILT keyword:
  	filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  	if (filter eq '') then return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 

  	nlens=(size(wavcal))[1]       ;pixel sidelength of final datacube (spatial dimensions) 	

	id = where_xyz(finite(wavcal[*,*,0]),XIND=xarr,YIND=yarr)
	nlens_tot = n_elements(xarr)
	lens = [transpose(xarr),transpose(yarr)]

	;lenslets found to cause unknown crashes (CPU driven to max percent) with offsets
	lens_exclude=[[98,15],[94,13],[96,14]]
	for i=0,2 do begin
		id1 = where(lens[0,*] eq lens_exclude[0,i] and lens[1,*] eq lens_exclude[1,i])
		id = where(~histogram([id1], min=0, max=nlens_tot-1))
		lens=lens[*,id]
	endfor
	nlens_tot=nlens_tot-4

	;randomly sort lenslet list to equalize job time.
	lens=lens[*,sort(randomu(seed,n_elements(lens)/2))]
	
  	;;error handle if readwavcal or not used before
  	if (nlens eq 0) then $
		return, error('FAILURE ('+functionName+'): Failed to load wavelength calibration data prior to calling this primitive.') 

	; get 2d detector image put into shared memory
	img=*(dataset.currframe[0])
	szim=size(img)
	;shmmap,'imshr',type=szim[0],szim[1],szim[2]
	;imshr=shmvar('imshr')
	;imshr[0,0]=img

	;setup memory for model images, wavecal offsets, and spectral cube data
	wcal_off_cube=fltarr(nlens,nlens,7)
	;shmmap,'wcal_off_cube',type=4,nlens,nlens,7,/sysv
	;wcal_off_cube=shmvar('wcal_off_cube')
	wcal_off_cube[0,0,0]=wcal_off_cube

	spec_cube=fltarr(szim[1],szim[2])
	;shmmap,'spec_cube',type=4,szim[1],szim[2],/sysv
	;spec_cube=shmvar('spec_cube')
	spec_cube[0,0]=spec_cube

	mic_cube=fltarr(szim[1],szim[2])
	;shmmap,'mic_cube',type=4,szim[1],szim[2],/sysv
	;mic_cube=shmvar('mic_cube')
	mic_cube[0,0]=mic_cube

	gpi_cube=fltarr(nlens,nlens,37)
	;shmmap,'gpi_cube',type=4,nlens,nlens,37,/sysv
	;gpi_cube=shmvar('gpi_cube')
	gpi_cube[0,0,0]=gpi_cube

	; need to interpolate into a regular grid during reduction since lsqr algo can have diffrent psf per spectra with IDL array constraints
	cwv=get_cwv(filter)	
	gpi_lambda=cwv.lambda	
	para=cwv.CommonWavVect
	;stop

	;runtime only single processor

	if lmgr(/runtime) and np gt 1 then begin
		backbone->Log, "Cannot use parallelization in IDL runtime. Switching to single thread only."
		call_function,'img_ext_para',cut1,cut2,0,img,wcal_off_cube,spec_cube,mic_cube,gpi_cube,gpi_lambda,para,wavcal,mlens_file,del_x_best=del_x_best,del_theta_best=del_theta_best,del_lam_best=del_lam_best,x_off=xsft,y_off=ysft,lens=lens,badpix=badpix,resid=resid,micphn=micphn,iter=iter

	endif else begin
		; start bridges from utils function
		oBridge=gpi_obridgestartup(nbproc=np)
	
		for j=0,np-1 do begin
			oBridge[j]->Setvar,'img',img
			oBridge[j]->Setvar,'gpi_lambda',gpi_lambda
			oBridge[j]->Setvar,'para',para
			oBridge[j]->Setvar,'spec_cube',spec_cube
			oBridge[j]->Setvar,'mic_cube',mic_cube
			oBridge[j]->Setvar,'gpi_cube',gpi_cube
			oBridge[j]->Setvar,'wcal_off_cube',wcal_off_cube
			oBridge[j]->Setvar,'wavcal',wavcal
			oBridge[j]->Setvar,'lens',lens
			oBridge[j]->Setvar,'badpix',badpix

			cut1 = floor((nlens_tot/np)*j)
			cut2 = floor((nlens_tot/np)*(j+1))-1

			;oBridge[j]->Execute, "shmmap,'spec_cube',type=4"+","+string(szim[1])+","+string(szim[2])+",/sysv"
			;oBridge[j]->Execute, "shmmap,'wcal_off_cube',type=4"+","+string(nlens)+","+string(nlens)+",7,/sysv"
			;oBridge[j]->Execute, "shmmap,'mic_cube',type=4"+","+string(szim[1])+","+string(szim[2])+",/sysv"
			;oBridge[j]->Execute, "shmmap,'gpi_cube',type=4"+","+string(nlens)+","+string(nlens)+",37,/sysv"

			;oBridge[j]->Execute, "spec_cube=shmvar('spec_cube')"
			;oBridge[j]->Execute, "wcal_off_cube=shmvar('wcal_off_cube')"
			;oBridge[j]->Execute, "mic_cube=shmvar('mic_cube')"
			;oBridge[j]->Execute, "gpi_cube=shmvar('gpi_cube')"

			oBridge[j]->Execute, strcompress('wait,'+string(5),/remove_all)
			oBridge[j]->Execute, "print,'loading PSFs'"
			oBridge[j]->Execute, ".r "+gpi_get_directory('GPI_DRP_DIR')+"/utils/gpi_lsqr_mlens_extract_dep.pro"
			process=strcompress('img_ext_para,'+string(cut1)+','+string(cut2)+','+string(j)+',img,wcal_off_cube,spec_cube,mic_cube,gpi_cube,gpi_lambda,para,wavcal,"'+mlens_file+'",'+'del_x_best='+string(del_x_best)+','+'del_theta_best='+string(del_theta_best)+','+'del_lam_best='+string(del_lam_best)+','+'x_off='+string(xsft)+','+'y_off='+string(ysft)+',lens=lens,badpix=badpix'+keywords,/remove_all)

			oBridge[j]->Execute, "print,'"+process+"'"
			oBridge[j]->Execute, process, /nowait		

		endfor
	  
		waittime=10
		  ;check status if finish kill bridges
		backbone->Log, 'Waiting for jobs to complete...'
	  	status=intarr(np)
	  	statusinteg=1
	  	wait,1
	  	t2start=systime(/seconds)
	  	while statusinteg ne 0 do begin
	   		t2=systime(/seconds)
	   		if (round(t2-t2start))mod(300.) eq 0 then print,'Processors have been working for = ',round((t2-t2start)/60),'min'
	   			for i=0,np-1 do begin
	    				status[i] = oBridge[i]->Status()
	   			endfor
	   		print,status
	   		statusinteg=total(status)
	   		wait,waittime
	  	endwhile
	  	backbone->Log, 'Job status:'+string(status)

		gpi_obridgekill,oBridge
	endelse

	dir = gpi_get_directory('GPI_REDUCED_DATA_DIR')
	;recover from scratch since shared memory doesnt work yet
	for n=0,np-1 do begin
		exe_tst = execute(strcompress('restore,"'+dir+'gpi_cube_'+string(n)+'.sav"',/remove_all))
		exe_tst = execute(strcompress('gpi_cube=gpi_cube+gpi_cube_'+string(n),/remove_all))
		exe_tst = execute('file_delete,"'+dir+'gpi_cube_'+strcompress(string(n)+'.sav"',/remove_all))
		if (resid eq 1) then begin
			exe_tst = execute(strcompress('restore,"'+dir+'spec_cube_'+string(n)+'.sav"',/remove_all))
			exe_tst = execute(strcompress('spec_cube=spec_cube+spec_cube_'+string(n),/remove_all))
			exe_tst = execute('file_delete,"'+dir+'spec_cube_'+strcompress(string(n)+'.sav"',/remove_all))
			exe_tst = execute(strcompress('restore,"'+dir+'mic_cube_'+string(n)+'.sav"',/remove_all))
			exe_tst = execute(strcompress('mic_cube=mic_cube+mic_cube_'+string(n),/remove_all))
			exe_tst = execute('file_delete,"'+dir+'mic_cube_'+strcompress(string(n)+'.sav"',/remove_all))
		endif
		if (iter eq 1) then begin
			exe_tst = execute(strcompress('restore,"'+dir+'wcal_off_cube_'+string(n)+'.sav"',/remove_all))
			exe_tst = execute(strcompress('wcal_off_cube=wcal_off_cube+wcal_off_cube_'+string(n),/remove_all))
			exe_tst = execute('file_delete,"'+dir+'wcal_off_cube_'+strcompress(string(n)+'.sav"',/remove_all))
		endif
	endfor

	;Save residual
	if (resid eq 1) then begin
		residual=img-spec_cube
		if (micphn eq 1) then residual=residual-mic_cube
		b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, 'residual', SaveData=residual, SaveHead=Header)
		;b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, 'spec_cube', SaveData=spec_cube, SaveHead=Header)
	endif	

	;Save wcal offsets
	if (iter eq 1) then begin
		b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, 'wcaloff', SaveData=wcal_off_cube, SaveHead=Header)
	endif		
	
	wavestep = (para[1]-para[0])/(para[2])

	;set keywords for spectral cube
	backbone->set_keyword,'NAXIS',3,ext_num=1
	backbone->set_keyword,'NAXIS1',nlens,ext_num=1
	backbone->set_keyword,'NAXIS2',nlens,ext_num=1
	backbone->set_keyword,'NAXIS3',para[2],ext_num=1
	backbone->set_keyword,'FILETYPE','Spectral Cube','What kind of IFS file is this?'
	backbone->set_keyword,'CD3_3',wavestep,'wavelength step [micron]',ext_num=1
	backbone->set_keyword,'CRPIX3',1.,'Spectral wavelengths are references to the first slice',ext_num=1
	backbone->set_keyword,'CRVAL3',para[0]+wavestep/2,'Center wavelength for first spectral channel [micron]',ext_num=1
	backbone->set_keyword,'CTYPE3','WAVE','3rd axis is vaccuum wavelength',ext_num=1
	backbone->set_keyword,'CUNIT3','microns','Wavelengths are in microns.',ext_num=1

	*(dataset.currframe)=gpi_cube

	;unmap shared mem
	;SHMUNMAP, 'wcal_off_cube'
	;SHMUNMAP, 'spec_cube'
	;SHMUNMAP, 'mic_cube'
	;SHMUNMAP, 'gpi_cube'
	
@__end_primitive

end
