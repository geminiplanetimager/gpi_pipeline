;+
; NAME: gpi_lsqr_mlens_extract_pol.pro
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Polarization Datacube (Lsqr, microlens psf) 
;
;	This primitive will extract flux from a 2D detector image of Wollaston spots into a GPI polarization cube using a least-square, matrix inversion algorithm and microlenslet PSFs.  
;	Optionally can produce a residual detector image, solve for microphonics, and iterate the polcal solution to find a minimum residual.
;	Ideally run in parrallel enviroment.
;
; INPUTS: 2D detector image, polcal, microlens PSF reference.
;
; OUTPUTS: GPI datacube
;
; PIPELINE COMMENT: This primitive will extract flux from a 2D detector image into a GPI polarization cube using a least-square algorithm and microlenslet PSFs. Optionally can produce a residual detector image, solve for microphonics, and iterate the polcal solution to find a minimum residual.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="stopidl" Type="int" Range="[0,1]" Default="0" Desc="1: stop IDL, 0: dont stop IDL"
; PIPELINE ARGUMENT: Name="np" Type="float" Default="2" Range="[0,100]" Desc="Number of processors to use in reduction (double check enviroment before running)"
; PIPELINE ARGUMENT: Name="resid" Type="int" Default="1" Range="[0,1]" Desc="Save residual detector image?"
; PIPELINE ARGUMENT: Name="micphn" Type="int" Default="0" Range="[0,1]" Desc="Solve for microphonics?"
; PIPELINE ARGUMENT: Name="iter" Type="int" Default="1" Range="[0,1]" Desc="Run iterative solver of polcal?"
; PIPELINE ARGUMENT: Name="x_off" Type="float" Default="0" Range="[-5,5]" Desc="Offset from wavecal in x pixels"
; PIPELINE ARGUMENT: Name="y_off" Type="float" Default="0" Range="[-5,5]" Desc="Offset from wavecal in y pixels"
;
; 
; where in the order of the primitives should this go by default?
; PIPELINE ORDER: 5.0
;
; pick one of the following options for the primitive type:
; PIPELINE NEWTYPE: PolarimetricScience
;
; HISTORY:
;    Began 2014-02-17 by Zachary Draper
;-  

;--------------------------------------------------
;MAIN FUNCTION

function gpi_lsqr_mlens_extract_pol, DataSet, Modules, Backbone
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id: gpi_lsqr_mlens_extract.pro 2563 2014-02-14 21:37:20Z zhd $' ; get version from subversion to store in header history

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

@__start_primitive
suffix='-podc' 		 ; set this to the desired output filename suffix

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

		
	; get mlens PSF filename
	mlens_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( 'mlenspsf',*(dataset.headersphu)[numfile],*(dataset.headersext)[numfile], /verbose)

	;define the common wavelength vector with the IFSFILT keyword:
  	filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  	if (filter eq '') then return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 

	
  	;;error handle if readpolcal or not used before
	if ~(keyword_set(polcal.coords)) then return, error("You must use Load Polarization Calibration before Assemble Polarization Cube")

	; get 2d detector image put into shared memory
	img=*(dataset.currframe[0])
	szim=size(img)
	;shmmap,'imshr',type=szim[0],szim[1],szim[2]
	;imshr=shmvar('imshr')
	;imshr[0,0]=img
	
	;The Data quality array
	dqarr=*(dataset.currdq)

  nlens=281;szim[1] ;The number of lenslets
  
	;setup memory for model images, wavecal offsets, and pol cube data
	pcal_off_cube=fltarr(nlens,nlens,3)
	;shmmap,'wcal_off_cube',type=4,nlens,nlens,7,/sysv
	;wcal_off_cube=shmvar('wcal_off_cube')
	pcal_off_cube[0,0,0]=pcal_off_cube

	pol_cube=fltarr(szim[1],szim[2])
	;shmmap,'spec_cube',type=4,szim[1],szim[2],/sysv
	;spec_cube=shmvar('spec_cube')
	pol_cube[0,0]=pol_cube

	mic_cube=fltarr(szim[1],szim[2])
	;shmmap,'mic_cube',type=4,szim[1],szim[2],/sysv
	;mic_cube=shmvar('mic_cube')
	mic_cube[0,0]=mic_cube

	gpi_pol=fltarr(nlens,nlens,2)
	shmmap,'gpi_cube',type=4,nlens,nlens,2,/sysv
	gpi_cube=shmvar('gpi_cube')
	gpi_pol[0,0,0]=gpi_pol
  
  cwv=get_cwv(filter) 
  gpi_lambda=cwv.lambda 
  para=cwv.CommonWavVect
  
  ;Copied from the spectral mode equivalent
  id = where_xyz(finite(reform(polcal.spotpos[0,*,*,0])),XIND=xarr,YIND=yarr)
  nlens_tot = n_elements(xarr)
  lens = [transpose(xarr),transpose(yarr)]

  ;randomly sort lenslet list to equalize job time.
  lens=lens[*,sort(randomu(seed,n_elements(lens)/2))]

;*******Parallel start *********

 
  ;*******Parallel over ********* 
 
  ;******* Non Parallel version *******
  cut1=1000
  cut2=1025
  j=0 
  np=1
  ex=execute(strcompress('img_ext_pol_para,'+string(cut1)+','+string(cut2)+','+string(j)+',img,dqarr,pcal_off_cube,pol_cube,mic_cube,gpi_pol,polcal.spotpos,"'+mlens_file+'",'+'x_off='+string(xsft)+','+'y_off='+string(ysft)+',lens=lens'+keywords,/remove_all))
  
;  Clean up variables before reloading them
  gpi_pol[*]=0
  pol_cube[*]=0
  mic_cube[*]=0
  pcal_ofF_cube[*]=0
  

	dir = gpi_get_directory('GPI_REDUCED_DATA_DIR')
	;recover from scratch since shared memory doesnt work yet
	for n=0,np-1 do begin
		exe_tst = execute(strcompress('restore,"'+dir+'gpi_pol_'+string(n)+'.sav"',/remove_all))
		exe_tst = execute(strcompress('gpi_pol=gpi_pol+gpi_pol_'+string(n),/remove_all))
		;exe_tst = execute('file_delete,"'+dir+'gpi_cube_'+strcompress(string(n)+'.sav"',/remove_all))
		if (resid eq 1) then begin
			exe_tst = execute(strcompress('restore,"'+dir+'pol_cube_'+string(n)+'.sav"',/remove_all))
			exe_tst = execute(strcompress('pol_cube=pol_cube+pol_cube_'+string(n),/remove_all))
			;exe_tst = execute('file_delete,"'+dir+'spec_cube_'+strcompress(string(n)+'.sav"',/remove_all))
      if (micphn eq 1) then begin
			 exe_tst = execute(strcompress('restore,"'+dir+'mic_cube_pol_'+string(n)+'.sav"',/remove_all))
       exe_tst = execute(strcompress('mic_cube=mic_cube+mic_cube_pol_'+string(n),/remove_all))
       ;exe_tst = execute('file_delete,"'+dir+'mic_cube_'+strcompress(string(n)+'.sav"',/remove_all))
			endif
		endif
		if (iter eq 1) then begin
			exe_tst = execute(strcompress('restore,"'+dir+'pcal_off_cube_'+string(n)+'.sav"',/remove_all))
			exe_tst = execute(strcompress('pcal_off_cube=pcal_off_cube+pcal_off_cube_'+string(n),/remove_all))
			;exe_tst = execute('file_delete,"'+dir+'wcal_off_cube_'+strcompress(string(n)+'.sav"',/remove_all))
		endif
	endfor

	;Save residual
	if (resid eq 1) then begin
		residual_pol=img-pol_cube
		if (micphn eq 1) then residual_pol=residual_pol-mic_pol
		*(dataset.currframe)=residual_pol
		b_Stat = save_currdata( Dataset,  Modules[thisModuleIndex].OutputDir, 'residual_pol', SaveData=residual, SaveHead=Header)
	endif	

	;Save pcal offsets
	if (iter eq 1) then begin
	*(dataset.currframe)=pcal_off_cube
		b_Stat = save_currdata( Dataset,  Modules[thisModuleIndex].OutputDir, 'pcaloff', SaveData=pcal_off_cube, SaveHead=Header)
	endif		
	
	;; Update FITS header 

	;; Update WCS with RA and Dec information As long as it's not a TEL_SIM image
	sz = size(gpi_pol)    
	if ~strcmp(string(backbone->get_keyword('OBJECT')), 'TEL_SIM') then gpi_update_wcs_basic,backbone,imsize=sz[1:2]

	backbone->set_keyword, 'COMMENT', "  For specification of Stokes WCS axis, see ",ext_num=1
	backbone->set_keyword, 'COMMENT', "  Greisen & Calabretta 2002 A&A 395, 1061, section 5.4",ext_num=1

	backbone->set_keyword, "NAXIS",    sz[0], /saveComment
	backbone->set_keyword, "NAXIS1",   sz[1], /saveComment, after='NAXIS'
	backbone->set_keyword, "NAXIS2",   sz[2], /saveComment, after='NAXIS1'
	backbone->set_keyword, "NAXIS3",   sz[3], /saveComment, after='NAXIS2'

	backbone->set_keyword, "FILETYPE", "Stokes Cube", "What kind of IFS file is this?"
	backbone->set_keyword, "WCSAXES",  3, "Number of axes in WCS system"
	backbone->set_keyword, "CTYPE3",   "STOKES",     "Polarization"
	backbone->set_keyword, "CUNIT3",   "N/A",       "Polarizations"
	backbone->set_keyword, "CRVAL3",   -6, " Stokes axis: image 0 is Y parallel, 1 is X parallel "

	backbone->set_keyword, "CRPIX3", 1.,         "Reference pixel location" ;;ds - was 0, but should be 1, right?
	backbone->set_keyword, "CD3_3",  1, "Stokes axis: images 0 and 1 give orthogonal polarizations." ; 

	*(dataset.currframe)=gpi_pol

	;unmap shared mem
	;SHMUNMAP, 'wcal_off_cube'
	;SHMUNMAP, 'spec_cube'
	;SHMUNMAP, 'mic_cube'
	;SHMUNMAP, 'gpi_cube'
	
@__end_primitive

end
