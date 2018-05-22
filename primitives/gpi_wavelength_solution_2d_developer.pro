;+
; NAME: gpi_wavelength_solution_2d_developer.pro
; PIPELINE PRIMITIVE DESCRIPTION: 2D Wavelength Solution Developer
;
;	This is the main wavelength calibration generation primitive.
;
;   This Wavelength Solution generator models an arclamp spectrum
;   for each lenslet and uses mpfit2dfunc to fit the relevant
;   wavelength solution variables (ie. xo, yo, lambdao, dispersion,
;   tilt). A wavelength solution file is output along with a
;   simulated detector image. 
;
;	A previous wavelength calibration file is used to supply the
;	initial guess for the fitting process, which is then updated
;	by this primitive.
;
;	This is fairly computationally intensive and requires
;	relatively high S/N data. See Quick Wavelength Solution if
;	you need faster results (albeit more limited and requiring you
;	already have a reference wavecal)
;
; INPUTS: An Xe/Ar lamp detector image
;
; OUTPUTS: A wavelength solution cube (and a simulated Xe/Ar lamp detector image; to come)
;
; PIPELINE COMMENT: This primitive uses an existing wavelength solution file to construct a new wavelength solution file by simulating the detector image and performing a least squares fit.
;
;
; PIPELINE ARGUMENT: Name="display" Type="Int" Range="[0,1]" Default="0" Desc="Whether or not to plot each lenslet spectrum model in comparison to the detector measured spectrum: 1;display, 0;no display"
; PIPELINE ARGUMENT: Name="whichpsf" Type="Int" Range="[0,1]" Default="0" Desc="Type of lenslet PSF model, 0: gaussian, 1: microlens"
; PIPELINE ARGUMENT: Name="parallel" Type="Int" Range="[0,1]" Default="0" Desc="Option for Parallelization,  0: none, 1: parallel"
; PIPELINE ARGUMENT: Name="numsplit" Type="Int" Range="[0,100]" Default="0" Desc="Number of cores for parallelization. Set to 0 for autoselect."
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1"
; Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="Smooth" Type="int" Range="[0,1]"
; Default="1" Desc="1: smooth final wavelength solution, 0: don't smooth"
; PIPELINE ARGUMENT: Name="Save_model_image" Type="int" Range="[0,1]" Default="0" Desc="1: save 2d detector model fit image to disk, 0:don't save"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="wavcal" Default="AUTOMATIC" Desc="Filename of the desired reference wavelength calibration file to be read"
; PIPELINE ARGUMENT: Name="Save_model_params" Type="int" Range="[0,1]" Default="0" Desc="1: save model nuisance parameters to disk, 0: don't save"
; PIPELINE ARGUMENT: Name="AutoOffset" Type="int" Range="[0,1]" Default="0" Desc="Automatically determine x/yoffset values 0;NO, 1;YES"
; PIPELINE ARGUMENT: Name="Quadratic" Type="int" Range="[0,1]"
; Default="0" Desc="Fit the lenslets with a quadratic
; dispersion solution 0;NO, 1;YES"
;
;
; PIPELINE ORDER: 1.7
;
; PIPELINE CATEGORY: Calibration
;
; HISTORY:
;    2013-09-19 SW: 2-dimensionsal wavelength solution 
;-  

function gpi_wavelength_solution_2d_developer, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id: gpi_wavelength_solution_2d_developer.pro 2821 2014-04-22 18:32:53Z swolff $' ; get version from subversion to store in header history
calfiletype = 'wavecal'
; the following line sources a block of code common to all primitives
; It loads some common blocks, records the primitive version in the header for
; history, then if calfiletype is not blank it queries the calibration database
; for that file, and does error checking on the returned filename.
@__start_primitive


;Beginning of Wavelength Solution code:

;Initialize the input parameters:
 	if tag_exist( Modules[thisModuleIndex], "display") then display=uint(Modules[thisModuleIndex].display) else display=0
 	if tag_exist( Modules[thisModuleIndex], "whichpsf") then whichpsf=uint(Modules[thisModuleIndex].whichpsf) else whichpsf=0
  	if tag_exist( Modules[thisModuleIndex], "parallel") then parallel=uint(Modules[thisModuleIndex].parallel) else parallel=1
 	if tag_exist( Modules[thisModuleIndex], "numsplit") then numsplit=fix(Modules[thisModuleIndex].numsplit) else numsplit=!CPU.TPOOL_NTHREADS*2
	if numsplit lt 1 then numsplit=!CPU.TPOOL_NTHREADS*2
  	if tag_exist( Modules[thisModuleIndex], "Save") then Save=uint(Modules[thisModuleIndex].Save) else Save=0
  	if tag_exist( Modules[thisModuleIndex], "Smooth") then Smooth=uint(Modules[thisModuleIndex].Smooth) else Smooth=1
  	if tag_exist( Modules[thisModuleIndex], "Save_model_image") then Save_model_image=uint(Modules[thisModuleIndex].Save_model_image) else Save_model_image=0
  	if tag_exist( Modules[thisModuleIndex], "Save_model_params") then Save_model_params=uint(Modules[thisModuleIndex].Save_model_params) else Save_model_params=0
 	if tag_exist( Modules[thisModuleIndex], "AutoOffset") then AutoOffset=uint(Modules[thisModuleIndex].AutoOffset) else AutoOffset=0
 	if tag_exist( Modules[thisModuleIndex], "Quadratic") then Quadratic=uint(Modules[thisModuleIndex].Quadratic) else Quadratic=0

;Load in the image. Primitive assumes a dark,flat,badpixel,flexure, and microphonics corrected lamp image. 

        image=*dataset.currframe
        

	;READ IN REFERENCE WAVELENGTH CALIBRATION
;	c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( 'wavecal',*(dataset.headersphu)[numfile],*(dataset.headersext)[numfile], /verbose) 

	backbone->set_keyword, 'HISTORY','Reference Wavecal used as a starting point for fit: ',ext_num=0
	backbone->set_keyword, 'HISTORY', c_File,ext_num=0
	backbone->set_keyword, 'REFWVCLF', c_File, 'Prior reference cal used as a starting point',ext_num=0

	;open the reference wavecal file. Save into common block variable.
	refwlcal = gpi_readfits(c_File,header=Header)
        
;Use the next line to manually select a wavecal by hand until that
;software bug is fixed.
        ;refwlcal=mrdfits('/Users/schuylerwolff/gpi/data/Reduced/calibrations/wavecals/S20130315S0059-J--wavecal.fits',1,HEADER)
	wlcalsize=size(refwlcal,/dimensions)
	
	nlens = wlcalsize[0]
	n_valid_lenslets = long(total(finite(refwlcal[*,*,0])))

	newwavecal=dblarr(wlcalsize) 
        if Quadratic eq 1 then newwcsz = 6
        if Quadratic eq 0 then newwcsz = 5
	;sizeres = 9+nmgauss[0]
        newwavecal=dblarr( (size(refwlcal))[1],(size(refwlcal))[2],newwcsz)+!values.f_nan
 
	
;        print,wlcalsize
;	valid = gpi_wavecal_sanity_check(c_File, errmsg=errmsg,/noplot)
;	if ~(keyword_set(valid)) then return, error("The chosen starting reference wavecal, "+c_File+", does not pass the qualty check. Cannot be used to generate a new wavecal. Remove it from your calibration DB and rescan before trying again. ")

	;READ IN BAD PIXEL MAP
	; assume this is already present in the DQ extension.
	badpix=*dataset.currdq GT 0

        ;;  if keyword_set(Smoothed) then begin
        ;;                         ;Note: this is causing strange
        ;;                         ;artifacts when plotted in gpitv, need
        ;;                         ;a solution that doesn't smooth
        ;;                         ;around edges.
;            smoothedw=smooth(refwlcal[*,*,3],5,/nan)
;            smoothedt=smooth(refwlcal[*,*,4],5,/nan)
;            smoothedw[where(~Finite(refwlcal[*,*,0]))] = !values.f_nan
;            smoothedt[where(~Finite(refwlcal[*,*,0]))] = !values.f_nan
;            minsm=80
;            maxsm=200
            ;smoothedx=smooth(refwlcal[minsm:maxsm,minsm:maxsm,1],5,/nan)
            ;smoothedy=smooth(refwlcal[minsm:maxsm,minsm:maxsm,0],5,/nan)
            ;refwlcal[minsm:maxsm,minsm:maxsm,1]=smoothedx
            ;refwlcal[minsm:maxsm,minsm:maxsm,0]=smoothedy
;            refwlcal[*,*,3]=smoothedw
;            refwlcal[*,*,4]=smoothedt
        ;; endif



	lamp = backbone->get_keyword('GCALLAMP', count=ct1)
	filternm = backbone->get_keyword('IFSFILT', count=ct2)
        filter = gpi_simplify_keyword_value(filternm)

        
	if ct1 EQ 0 then return, error( "Missing GCALLAMP header keyword.")
	if ct2 EQ 0 then return, error( "Missing IFSFILT header keyword.")
        
        backbone->Log,"Now finding wavelength solution for "+filter+", "+lamp, depth=3
		backbone->set_keyword, "HISTORY", "Performed wavelength solution for "+filter+", "+lamp
        ;backbone->Log, gpi_get_directory('GPI_DRP_CONFIG_DIR')
        datafn = gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+filter+lamp+'.dat'
 

	if whichpsf eq 1 then begin
           case filter of
              'H': psfn = '140522b_highres-1650um-psf_structure-updatedheaders.fits'
              'J': psfn = '140520_highres-1150um-psf_structure-updatedheaders.fits'
              'Y': psfn = '140529_highres-1000um-psf_structure-updatedheaders.fits'
              'K1': psfn = '140524_highres-2058um-psf_structure-updatedheaders.fits'
              'K2': psfn = '140524_highres-2058um-psf_structure-updatedheaders.fits'
           endcase

           cal_dir = gpi_get_directory('GPI_DRP_CALIBRATIONS_DIR')
           wherefile = file_search(cal_dir,psfn)
           psffn = wherefile[0]
           if ~file_test(psffn) then return, error("Microlens PSF file not found. File must be in your calibrations directory (or subdir) and cannot be accessed via a symbolic link. "+psfn)
           print, psfn
        endif



        ;Create an array to serve as the simulated detector image
        lensletmodel=dblarr(size(image,/dimensions))
        lensletmodel_counts=bytarr(size(image,/dimensions)) ; pixel map of how many times each pixel of this image has been fit

		; Create an array to store other model parameter fits
		; (PSF shape)
        
        ; Initialize some variables used for the error catcher
        xinterp=dblarr(nlens*nlens)
        yinterp=dblarr(nlens*nlens)
        q=0L


istart=0
iend=nlens-1
jstart=0
jend=nlens-1


im_uncert = gpi_estimate_2d_uncertainty_image( *dataset.currframe , *dataset.headersPHU[numfile], *dataset.headersExt[numfile])

;Add an offset to the reference wavelength solution manually. 
;refwlcal[*,*,1]=refwlcal[*,*,1]+4.0
;refwlcal[*,*,0]=refwlcal[*,*,0]+5.0

if keyword_set(parallel) then begin

	backbone->Log,"Parallelizing over "+strc(numsplit)+" IDL processes", depth=3,/flush
	backbone->set_keyword, 'HISTORY',"Parallelizing over "+strc(numsplit)+" IDL processes", depth=3,/flush
	readcol, datafn,wla,fluxa,skipline=1,format='F,F'
	readcol,datafn,nmgauss,numline=1,format='I'
       
	count=0 ; count of lenslet columns fit
	lensletcount = 0 ; count of individual lenslets fit

	; must create these after reading # of emission lines
        if Quadratic eq 1 then sizeres = 10+nmgauss[0]
        if Quadratic eq 0 then sizeres = 9+nmgauss[0]
        ;print, "Size of the modelparams array:"
        ;print, sizeres
	;sizeres = 9+nmgauss[0]
        if ~(keyword_set(modelparams)) then modelparams=fltarr( (size(refwlcal))[1],(size(refwlcal))[2],sizeres )+!values.f_nan
        if ~(keyword_set(modelbackgrounds)) then modelbackgrounds = fltarr( (size(refwlcal))[1],(size(refwlcal))[2] ) + !values.f_nan


;;     if AutoOffset EQ 1 then begin
;;            ngausspars=dblarr(sizeres)
;;            boxsizex=7
;;            boxsizey=24
;;            xindex=140
;;            yindex=140
;;            xo=refwlcal[xindex,yindex,1]
;;            yo=refwlcal[xindex,yindex,0]
;;            startx=floor(xo-boxsizex/2.0)
;;            starty=round(yo)-20
;;            stopx = startx+boxsizex
;;            stopy = starty+boxsizey

;;            rawarray=image[startx:stopx, starty:stopy] 

;;            xposo=xo-startx
;;            yposo=yo-starty
;;            theta=refwlcal[xindex,yindex,3]
;;            w=refwlcal[xindex,yindex,4]
;;            fwhmx=1.9
;;            fwhmy=1.9
;;            lambdaref=refwlcal[xindex,yindex,2]
;;            rotation=0
;;            background=20
;;            for z=0,nmgauss[0]-1 do begin
;;               ngausspars[9+z]=fluxa[z]
;;            endfor

;;            x=indgen(boxsizex)
;;            y=indgen(boxsizey)
;;            szx=size(x,/n_elements)
;;            szy=size(y,/n_elements)
;;            zmod=dblarr(szx,szy)
;;            xvals = make_array(szx,szy,/index,/integer) mod szx
;;            yvals = make_array(szx,szy,/index,/integer) / szx
           
;;            for i=0, nmgauss[0]-1 do begin
;;               lambda=wla[i]
;;               coeff=ngausspars[9+i]
;;               xcent=xposo+sin(theta)*(lambda-lambdaref)/w
;;               ycent=yposo-cos(theta)*(lambda-lambdaref)/w
;;               zmod += coeff*psf_gaussian(npixel=[szx,szy],fwhm=[fwhmx,fwhmy],centroid=[xcent,ycent],ndimen=2,/double,/normalize)

;; ;one_2d_gaussian(xvals, yvals, fwhm=[fwhmx,fwhmy],centroid=[xcent,ycent],ndimen=2,/double,/normalize,rotation=rotation)              
;;            endfor

;; ;normalize this to the scale factor relative to the science image
;;            zmod=zmod*total(rawarray)/total(zmod)
;; ; and add in constant background              
;;            simarray=zmod+background


;;            corrmat_analyze, CORREL_IMAGES(rawarray,simarray,xshift=4,yshift=4),xoffset_auto,yoffset_auto,/print

;;            backbone->Log, "Applying a prelimiinary shift of (X,Y) = ("+strc(xoffset_auto)+", "+strc(yoffset_auto)+")"
         
;           refwlcal[*,*,0]=refwlcal[*,*,0]-1
;           refwlcal[*,*,1]=refwlcal[*,*,1]+3
;;         endif




	waveinfo = get_cwv(filter)
	lambda_min  = waveinfo.commonwavvect[0]
	lambda_max  = waveinfo.commonwavvect[1]
	locations_lambda_min = (change_wavcal_lambdaref( refwlcal, lambda_min) )[*,*,0:1]
	locations_lambda_max = (change_wavcal_lambdaref( refwlcal, lambda_max) )[*,*,0:1]
	n_valid_lenslets = long(total(finite(refwlcal[*,jstart:jend,0])))
	boxpad=2

	;Parallelize the top level for loop

	; Note : the following block of code is mostly comment free. 
	; See the same algorithm implemented below in the single threaded code for
	; the comments. 



	 gpi_split_for, istart,iend, nsplit=numsplit,$ 
		 varnames=['jstart','jend','refwlcal','image','im_uncert','badpix','newwavecal','psffn','lambda_min','Quadratic',$
		           'q','wlcalsize','xinterp','yinterp','wla','fluxa','nmgauss','count','lensletmodel','lensletcount',$
                           'modelparams','modelbackgrounds','locations_lambda_min','locations_lambda_max','n_valid_lenslets','boxpad','whichpsf'], $
		 outvar=['newwavecal','count','lensletcount','lensletmodel','modelparams','modelbackgrounds'], commands=[$
	'common ngausscommon, numgauss, wl, flux, lambdao, my_psf',$
        'common highrespsfstructure, myPSFs_array',$
	'numgauss=nmgauss[0]',$
	'wl=wla',$
        'lambdao=refwlcal[140,140,2]',$
	'flux=fluxa',$
	'count+=1',$
	'for j = jstart,jend do begin',$
	'	 startx = floor(min([locations_lambda_min[i,j,1], locations_lambda_max[i,j,1]]) - boxpad) > 4',$
	'	 starty = floor(min([locations_lambda_min[i,j,0], locations_lambda_max[i,j,0]]) - boxpad) > 4',$
	'	 stopx = ceil(max([locations_lambda_min[i,j,1], locations_lambda_max[i,j,1]]) + boxpad) < 2043',$
	'	 stopy = ceil(max([locations_lambda_min[i,j,0], locations_lambda_max[i,j,0]]) + boxpad) < 2043',$
        '    if total(~finite(refwlcal[i,j,*])) gt 0 then begin',$
	'        newwavecal[i,j,*]=!values.f_nan' ,$
	'        continue' ,$
	'    endif' ,$
	'    if (stopx lt 4) || (stopy lt 4) || (startx gt 2040) || (starty gt 2040) then begin',$
        '        newwavecal[i,j,*]=!values.f_nan',$
        '        continue',$
	'    endif' ,$
	'    if (startx lt 4) || (starty lt 4) || (stopx gt 2040) || (stopy gt 2040) then begin',$
        '        newwavecal[i,j,*]=!values.f_nan',$
        '        continue',$
	'    endif' ,$
        '    if (startx eq stopx) || (starty eq stopy) then begin',$
        '        newwavecal[i,j,*]=!values.f_nan',$
        '        continue',$
	'    endif' ,$
	'    lensletarray=image[startx:stopx, starty:stopy]',$
	'    lensletarray_uncert=image[startx:stopx, starty:stopy]',$
	'    badpixmap=badpix[startx:stopx, starty:stopy]',$
	'    catch,error_status',$
	'    if error_status NE 0 then begin',$
	'       catch,/cancel',$
	'       print, "errorstatus, i, j =====",error_status,i,j',$
	'       print, "error message =====",!error_state.msg',$
	'       print, "q ============", q',$
	'       xinterp[q]=i',$
	'       yinterp[q]=j',$
	'       q++',$
	'       continue',$
	'    endif',$
        '    case whichpsf of',$
        '        1: begin',$
        '             case Quadratic of',$
        '                  0: begin',$
        '                       res=gpi_wavecal_wrapper(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"nmicrolens",modelimage=modelimage, modelbackground=modelbackground,psffn=psffn)',$
        '                  end',$
        '                  1: begin',$
        '                       res=gpi_wavecal_wrapper_quadratic(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"nmicrolens",modelimage=modelimage, modelbackground=modelbackground,psffn=psffn)',$
        '                       newwavecal[i,j,5]=res[9]',$
        '                  end',$
        '             end',$
        '        end',$
        '        0: begin',$
        '             res=gpi_wavecal_wrapper(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"ngauss",modelimage=modelimage, modelbackground=modelbackground,psffn=psffn)',$
        '        end',$
        '    endcase',$
        '    if res[0] EQ !values.f_nan then begin',$
        '        newwavecal[i,j,*]=!values.f_nan',$
        '    endif else begin',$
	'        newwavecal[i,j,1]=res[0]+startx',$
	'        newwavecal[i,j,0]=res[1]+starty',$
	'        newwavecal[i,j,2]=refwlcal[i,j,2]',$
	'        newwavecal[i,j,3]=res[2]',$
	'        newwavecal[i,j,4]=res[3]',$
        '    endelse',$
        '    modelparams[i,j,*] = res',$
        '    modelbackgrounds[i,j] = modelbackground',$
	'    modelparams[i,j,1] = res[0]+startx',$
	'    modelparams[i,j,0] = res[1]+starty',$
	'    lensletmodel[startx:stopx, starty:stopy] += modelimage',$
	'    lensletcount+=1',$
 	'endfor'];,$


	backbone->Log,"Parallel process execution complete.", depth=3,/flush

	width=dblarr(numsplit)

	for k=0,numsplit-1 do begin
	   width[strc(k)] = scope_varfetch('count' + strc(k))
	   if k EQ 0 then istart=0 else istart=total(width[0:k-1])
	   iend=istart+width[k]-1
	   dummywave = scope_varfetch('newwavecal'+strc(k))
	   newwavecal[istart:iend,*,*]=dummywave[istart:iend,*,*]
	   dummymodel = scope_varfetch('lensletmodel'+strc(k))
	   lensletmodel+= dummymodel
	   dummyparams = scope_varfetch('modelparams'+strc(k))
	   wf = where(finite(dummyparams),fct)
	   if fct gt 0 then modelparams[wf] = dummyparams[wf]
	   dummyparams = scope_varfetch('modelbackgrounds'+strc(k))
	   wf = where(finite(dummyparams),fct)
	   if fct gt 0 then modelbackgrounds[wf] = dummyparams[wf]
	endfor
	backbone->Log,"Calculation results retrieved from child processes.", depth=3,/flush


endif else begin

	;Define common block to be used in wrapper.pro and ngauss.pro
	common ngausscommon, numgauss, wl, flux, lambdao, my_psf

	; Read in the emission line information
	readcol, datafn,wl,flux,skipline=1,format='F,F'
	readcol,datafn,nmgauss,numline=1,format='I'
	numgauss=nmgauss[0]
        lambdao = refwlcal[140,140,2]

	; determine the min and max locations of each lenslet based on
	; the prior wavecal
	waveinfo = get_cwv(filter)
	lambda_min  = waveinfo.commonwavvect[0]
	lambda_max  = waveinfo.commonwavvect[1]

	locations_lambda_min = (change_wavcal_lambdaref( refwlcal, lambda_min) )[*,*,0:1]
	locations_lambda_max = (change_wavcal_lambdaref( refwlcal, lambda_max) )[*,*,0:1]

	newwavecal[*,*,2]=refwlcal[*,*,2]

	lensletcount= 0
        boxpad = 2
        count = 0


	for i = istart,iend do begin
        for j = jstart,jend do begin
           
           count+=1

			if keyword_set(debuglenslet) then begin
				if (i ne debuglenslet[0]) or (j ne debuglenslet[1]) then continue
			endif
			; compute an enlarged circumcribing rectangle around the 
			; extreme pixels in that lenslet, based on the prior wavecal.

			startx = floor(min([locations_lambda_min[i,j,1], locations_lambda_max[i,j,1]]) - boxpad) > 4
			starty = floor(min([locations_lambda_min[i,j,0], locations_lambda_max[i,j,0]]) - boxpad) > 4

			stopx = ceil(max([locations_lambda_min[i,j,1], locations_lambda_max[i,j,1]]) + boxpad) < 2043
			stopy = ceil(max([locations_lambda_min[i,j,0], locations_lambda_max[i,j,0]]) + boxpad) < 2043


            if total(~finite(refwlcal[i,j,*])) gt 0 then begin
                newwavecal[i,j,*]=!values.f_nan
                continue
            endif

			if (startx lt 4) || (starty lt 4) || (stopx gt 2040) || (stopy gt 2040) then continue ; don't try to fit anything outside the valid region
			if (stopx lt 4) || (stopy lt 4) || (startx gt 2040) || (starty gt 2040) then continue ; don't try to fit anything way outside the valid region

;;            ;Trim out the image and badpixel map for a single lenslet
            lensletarray=image[startx:stopx, starty:stopy] 
            lensletarray_uncert=im_uncert[startx:stopx, starty:stopy] 
            badpixmap=badpix[startx:stopx, starty:stopy] 


 
            ;if whichpsf EQ 1 then begin
            ;   ptr = gpi_highres_microlens_psf_get_local_highres_psf(myPSFs_array,[i,j,0])
            ;   if ptr_valid(myPSFs_array[i,j]) then begin
            ;      my_psf = *myPSFs_array[i,j]
            ;      print,'psf was valid
            ;   endif else print, 'ERROR: PSF was not valid'
            ;endif

            catch,error_status
			;error_status=0

;;                                 ; Catch an error in the mpfit
;;                                 ; calculation and interpolate
                 
 		  if error_status NE 0 then begin
 			  catch,/cancel
 			  print, 'errorstatus, i, j =====',error_status,i,j
 			  print, 'error message =====',!error_state.msg
 			  print, 'q ============', q
 			  ;get x,y indices for later interpolation
 				  xinterp[q]=i
 				  yinterp[q]=j
 				  q++
			 
 			  continue

 		  endif

		  ; Now do an actual fit for one lenslet's spectrum! 
                  case whichpsf of
                     0: begin
                         res=gpi_wavecal_wrapper(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"ngauss",modelimage=modelimage, modelbackground=modelbackground,psffn=psffn)
                        ;res=gpi_wavecal_wrapper(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"ngauss",$
			 ; modelimage=modelimage, modelbackground=modelbackground, debug=keyword_set(debuglenslet) or keyword_set(debugall),psffn=psffn)
                     end
                     1: begin
                         res=gpi_wavecal_wrapper(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"nmicrolens",modelimage=modelimage, modelbackground=modelbackground,psffn=psffn)
;res=gpi_wavecal_wrapper(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"nmicrolens",$
			  ;modelimage=modelimage, modelbackground=modelbackground, debug=keyword_set(debuglenslet) or keyword_set(debugall),psffn=psffn)
                     end
                  endcase
                
                  
		  lensletcount +=1

		  ;take a running average of the unused
		  ;result parameters to be used in interpolation
		  sizeres=size(res,/dimensions)

			; note swap of Y and X here to match GPI convention:
            if sizeres LT 3 then begin
				 print,'Setting the wavecal to default values'
				 xshift=mean(newwavecal[i-5:i-1,j-5:j-1,1],/nan)-mean(refwlcal[i-5:i-1,j-5:j-1,1],/nan)
				 yshift=mean(newwavecal[i-5:i-1,j-5:j-1,0],/nan)-mean(refwlcal[i-5:i-1,j-5:j-1,0],/nan)
				 newwavecal[i,j,1]=xo+xshift
				 newwavecal[i,j,0]=yo+yshift
				 newwavecal[i,j,3]=7.0      ;w
				 newwavecal[i,j,4]=7.0     ;theta
            endif else begin
				 newwavecal[i,j,1]=res[0]+startx
				 newwavecal[i,j,0]=res[1]+starty
				 newwavecal[i,j,3]=res[2] ;w
				 newwavecal[i,j,4]=res[3] ;theta
            endelse

			; save all model wavecal fit parameters
			if ~(keyword_set(modelparams)) then begin
				modelparams=fltarr( (size(refwlcal))[1],(size(refwlcal))[2],sizeres )+!values.f_nan
				modelbackgrounds = fltarr( (size(refwlcal))[1],(size(refwlcal))[2] ) + !values.f_nan
			endif
			modelparams[i,j,*] = res
			modelbackgrounds[i,j] = modelbackground
			; swap Y and X to match wavecal file convention (consistency will
			; minimize confusion)
			modelparams[i,j,1] = res[0]+startx
			modelparams[i,j,0] = res[1]+starty


                   lensletmodel[startx:stopx, starty:stopy] += modelimage
                   ;lensletmodel_counts[startx:stopx, starty:stopy] += 1

;; ;                if display EQ 1  then begin
;; ;				  !p.multi= [0,2,1]
;; ;				  vmax = max(lensletarray)
;; ;				  imdisp, alogscale(lensletarray, 0, vmax), /axis, title='Real data subarray', /xs, /ys
;; ;				  imdisp, alogscale(zmodplot, 0, vmax), /axis,  title='Model', /xs, /ys
;; ;				endif
                
            endfor

			backbone->Log,"Column "+strc(i)+"/"+strc(iend-istart+1)+". Have now fit " +strc(lensletcount)+"/"+strc(n_valid_lenslets)+" lenslets"
;			if keyword_set(debug) and (lensletcount gt 0) and (i mod debug eq 0) then stop


         endfor

endelse


wherenan = where(~Finite(newwavecal))
;if keyword_set(debug) or keyword_set(debuglenslet) then stop


wg = where(finite(modelbackgrounds), wgcount)
if wgcount lt 5 then return, error('FAILURE in gpi_wavelength_solution_2d_developer: Error in parallelized computing.')
;OPTIONAL: SAVE THE DETECTOR MODEL IMAGE
if keyword_set(save_model_image) then begin

	;Generate 2D backgrounds, smoothed from above 
	bkgx = (modelparams[*,*,1])[wg]
	bkgy = (modelparams[*,*,0])[wg]
	triangulate, bkgx, bkgy, triangles, b
	smoothed_background =griddata(bkgx, bkgy, modelbackgrounds[wg], xout=findgen(2048), yout=findgen(2048),/grid, /nearest, triangles=triangles)
	smoothed_background = filter_image(smoothed_background,fwhm=30)

	smoothed_background = trigrid(  bkgx, bkgy, modelbackgrounds[wg], triangles, xout=indgen(2048), yout=indgen(2048) )
	smoothed_background[*,0:3] = 0
	smoothed_background[0:3,*] = 0
	smoothed_background[2044:2047,*] = 0
	smoothed_background[*,2044:2047] = 0

	lensletmodel -= smoothed_background


referencex=1025.0  ;roughly x-position in H
referencey=1008.0  ;roughly y-position in H
yposition=newwavecal[140,140,0]
xposition=newwavecal[140,140,1]
absxshift=xposition-referencex
absyshift=yposition-referencey


	pheader_copy = *dataset.headersPHU[numfile]
	eheader_copy = *dataset.headersExt[numfile]
	sxaddpar, pheader_copy, 'FILETYPE','Detector Model Synthesized during Wavecal Fit'
	sxaddpar, pheader_copy, 'ISCALIB','NO','Not a reduced calibration file, just an ancillary product.'
	sxaddpar, pheader_copy, 'HISTORY','Created as a byproduct of wavelength calibration 2D fit.'
	sxaddpar, pheader_copy, 'HISTORY','   Slice 1:  Synthetic Detector Model Image (result of fit)'
	sxaddpar, pheader_copy, 'HISTORY','   Slice 2:  Actual Detector Image (target of fit)'
	sxaddpar, pheader_copy, 'HISTORY','   Slice 3:  Difference Actual-Model'
	sxaddpar, eheader_copy, 'NAXIS',3
	sxaddpar, eheader_copy, 'NAXIS3',3,after='NAXIS2'


	modelstack = [[[lensletmodel]],[[image]],[[image-lensletmodel]]]

	wavecalimage=save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, "_model",display=0, savedata=modelstack, $
		saveheader=eheader_copy, savePHU=pheader_copy ,output_filename=output_filename)
	backbone->Log, "Saved 2D detector model to "+output_filename

endif

if keyword_set(save_model_params) then begin
	pheader_copy = *dataset.headersPHU[numfile]
	eheader_copy = *dataset.headersExt[numfile]

	psf_labels = ['Gaussian PSFs','Empirical Microlens ePSFs']
	sxaddpar, pheader_copy, 'FILETYPE','Detector Model Parameters from Wavecal Fit'
	sxaddpar, pheader_copy, 'ISCALIB','NO','Not a reduced calibration file, just an ancillary product.'
	sxaddpar, pheader_copy, 'HISTORY','  '
	sxaddpar, pheader_copy, 'HISTORY','Wavecal Fit using PSFs = '+psf_labels[whichpsf]
	sxaddpar, pheader_copy, 'HISTORY','  '
	sxaddpar, pheader_copy, 'HISTORY','Created as a byproduct of wavelength calibration 2D fit.'
	sxaddpar, pheader_copy, 'HISTORY','   Slice 1:  X coord at ref wavelength'
	sxaddpar, pheader_copy, 'HISTORY','   Slice 2:  Y coord at ref wavelength'
	sxaddpar, pheader_copy, 'HISTORY','   Slice 3:  Dispersion'
	sxaddpar, pheader_copy, 'HISTORY','   Slice 4:  Rotation'
	sxaddpar, pheader_copy, 'HISTORY','   Slice 5-N: see doc header of gpi_wavecal_wrapper '
	sxaddpar, pheader_copy, 'HISTORY','  '
	sxaddpar, eheader_copy, 'NAXIS',3
	sxaddpar, eheader_copy, 'NAXIS3',3,after='NAXIS2'

	stat=save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, "_modelparams",display=0, savedata=model_params, $
		saveheader=eheader_copy, savePHU=pheader_copy ,output_filename=output_filename)
	backbone->Log, "Saved 2D detector model parameters to "+output_filename


endif

; Edit the header of the original raw data products to include the information
; about the new wavelength calibration. 


backbone->set_keyword, "FILETYPE", "Wavelength Solution Cal File (Deep)"
backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'

sxaddpar,*dataset.headersExt[numfile],'NAXIS',3
sxaddpar,*dataset.headersExt[numfile],'NAXIS3',5,after='NAXIS2'

backbone->set_keyword, "HISTORY", " ",ext_num=0;,/blank
backbone->set_keyword, "HISTORY", " Wavelength solution File Format:",ext_num=0
backbone->set_keyword, "HISTORY", " Dispersion for each spectrum is defined as ",ext_num=0
backbone->set_keyword, "HISTORY", " lambda=w * (sqrt((x-x0)^2+(y-y0)^2))+lambda0",ext_num=0
backbone->set_keyword, "HISTORY", "    Slice 1:  Y-positions (y0) of spectra (Y=spectral direction) at [lambda0]",ext_num=0
backbone->set_keyword, "HISTORY", "    Slice 2:  X-positions (x0) of spectra at [lambda0]",ext_num=0
backbone->set_keyword, "HISTORY", "    Slice 3:  lambda0 [um]",ext_num=0
backbone->set_keyword, "HISTORY", "    Slice 4:  dispersion w [um/pixel]",ext_num=0
backbone->set_keyword, "HISTORY", "    Slice 5:  tilts of spectra [radians]",ext_num=0
backbone->set_keyword, "HISTORY", " ",ext_num=0;,/blank

ydummy = newwavecal[*,*,0]
xdummy = newwavecal[*,*,1]
wdummy = newwavecal[*,*,3]
tdummy = newwavecal[*,*,4]
;for columnind=0,280 do begin
;   ydummy[where(newwavecal[columnind,*,0] EQ !values.f_nan)]=mean(newwavecal[columnind,*,0],/nan)
;   xdummy[where(newwavecal[*,columnind,1] EQ !values.f_nan)]=mean(newwavecal[*,columnind,1],/nan)
;endfor


; Correct for poorly fit lenslets

median_filt = 21
smooth_in = 40

nany = where(~Finite(ydummy))
;finitey = where(Finite(ydummy));, ngoody, comp=nany, ncomp=nbady) 
; interpolate at the locations of the bad data using the good data 
;if nbady gt 0 then ydummy[bady] = interpol(ydummy[goody], goody,
;bady,/LSQUADRATIC)

; Perform same test for x,y slices that is performed in quality check
; wavecal util. Add any poorly fit lenslets to array of bad values.

ydiff = ydummy-shift(ydummy,1)
wg = where(finite(ydiff))
pct_wide_y = abs(ydiff[wg]-mean(ydiff[wg]))
;wb = where(pct_wide_y gt 2)
;bady = [nany,wb]

goody = where((Finite(ydummy) or (pct_wide_y gt 2)),ngoody,comp=bady,ncomp=nbady)


ydata = dblarr(3,ngoody)
sz = SIZE(ydummy[goody])
;print,sz
ncol = 281
ydata[0,*] = goody MOD ncol
ydata[1,*] = goody / ncol
ydata[2,*] = ydummy[goody]
;sbad = SIZE(ydummy[bady])
ncolbad = 281
ydatabadx = bady MOD ncolbad
ydatabady = bady / ncolbad
ydf = SFIT( ydata, 3, kx=yplanefit, /IRREGULAR, /MAX_DEGREE)
ydummy[bady] = ydf[0] + ydf[1]*ydatabady + ydf[2]*ydatabady*ydatabady + ydf[3]*ydatabady*ydatabady*ydatabady + ydf[4]*ydatabadx + ydf[5]*ydatabadx*ydatabady + ydf[6]*ydatabadx*ydatabady*ydatabady + ydf[7]*ydatabadx*ydatabadx + ydf[8]*ydatabadx*ydatabadx*ydatabady + ydf[9]*ydatabadx*ydatabadx*ydatabadx

ydummy = filter_image(ydummy, median=median_filt, /ALL_PIXELS, /ITERATE)
ydummy[nany] =  !values.f_nan
 
nanx = where(~Finite(xdummy))
;goodx = where(Finite(xdummy), ngoodx, comp=nanx, ncomp=nbadx) 
; interpolate at the locations of the bad data using the good data 
;if nbadx gt 0 then xdummy[badx] = interpol(xdummy[goodx], goodx, badx,/LSQUADRATIC) 
xdiff = xdummy-shift(xdummy,1)
wg = where(Finite(xdiff))
pct_wide_x = abs(xdiff[wg]-mean(xdiff[wg]))
;wb = where(pct_wide_x gt 2)
;badx =[nanx,wb]

goodx = where((Finite(xdummy) or (pct_wide_x gt 2)),ngoodx,comp=badx,ncomp=nbadx)

xdata = dblarr(3,ngoodx)
sz = SIZE(xdummy[goodx])
ncol = 281
xdata[0,*] = goodx MOD ncol
xdata[1,*] = goodx / ncol
xdata[2,*] = xdummy[goodx]
sbad = SIZE(xdummy[badx])
ncolbad = 281
xdatabadx = badx MOD ncolbad
xdatabady = badx / ncolbad
xdf = SFIT( xdata, 3, kx=xplanefit, /IRREGULAR, /MAX_DEGREE)
xdummy[badx] = xdf[0] + xdf[1]*xdatabady + xdf[2]*xdatabady*xdatabady + xdf[3]*xdatabady*xdatabady*xdatabady + xdf[4]*xdatabadx + xdf[5]*xdatabadx*xdatabady + xdf[6]*xdatabadx*xdatabady*xdatabady + xdf[7]*xdatabadx*xdatabadx + xdf[8]*xdatabadx*xdatabadx*xdatabady + xdf[9]*xdatabadx*xdatabadx*xdatabadx
;xdummy[badx] = xplanefit[0] + xplanefit[1]*xdatabady + xplanefit[2]*xdatabadx ; + xplanefit[3]*xdatabadx*xdatabady
;print, xplanefit, yplanefit
;stop
xdummy = filter_image(xdummy, median=median_filt, /ALL_PIXELS, /ITERATE)
xdummy[nanx] =  !values.f_nan

median_filt=21



goodw = where(Finite(wdummy), ngoodw, comp=badw, ncomp=nbadw) 
; interpolate at the locations of the bad data using the good data 
;if nbadw gt 0 then wdummy[badw] = interpol(wdummy[goodw], goodw, badw,/LSQUADRATIC) 
wdummy = filter_image(wdummy, median=median_filt, /ALL_PIXELS, /ITERATE)
wdummy[badw] =  !values.f_nan


goodt = where(Finite(tdummy), ngoodt, comp=badt, ncomp=nbadt) 
; interpolate at the locations of the bad data using the good data 
;if nbadt gt 0 then tdummy[badt] = interpol(tdummy[goodt], goodt, badt,/LSQUADRATIC) 
tdummy = filter_image(tdummy, median=median_filt, /ALL_PIXELS, /ITERATE)
tdummy[badt] =  !values.f_nan


;if ~keyword_set(Smooth) then begin
;   newwavecal[*,*,0]=ydummy
;   newwavecal[*,*,1]=xdummy
;   newwavecal[*,*,3]=wdummy
;   newwavecal[*,*,4]=tdummy
;endif


if keyword_set(Smooth) then begin


           if keyword_set(Quadratic) then begin
              qdummy = newwavecal[*,*,5]
              goodq = where(Finite(qdummy), ngoodq, comp=badq, ncomp=nbadq)
              qdummy = filter_image(qdummy,median=median_filt)
              qdummy[badq] = !values.f_nan
              wdummy[where(~Finite(refwlcal[*,*,0]))] = !values.f_nan
              newwavecal[*,*,5]=qdummy
           endif



           ;minsm=90
           ;maxsm=190
           ;smoothedw=median(wdummy,6,/even)
           ;smoothedt=median(tdummy,6,/even)
           ;smoothedx=smooth(xdummy[where(Finite(refwlcal[*,*,1]))],5,/nan)
           ;smoothedy=smooth(ydummy[where(Finite(refwlcal[*,*,0]))],5,/nan)
           ;smoothedx=median(xdummy,5)
           ;smoothedy=median(ydummy,5)
           ;wdummy=smoothedw
           ;tdummy=smoothedt  
           ;xdummy=smoothedx
           ;ydummy=smoothedy
         
           wdummy[where(~Finite(refwlcal[*,*,0]))] = !values.f_nan
           tdummy[where(~Finite(refwlcal[*,*,0]))] = !values.f_nan
           xdummy[where(~Finite(refwlcal[*,*,0]))] = !values.f_nan
           ydummy[where(~Finite(refwlcal[*,*,0]))] = !values.f_nan


           newwavecal[smooth_in:ncol-smooth_in,smooth_in:ncol-smooth_in,4]=tdummy[smooth_in:ncol-smooth_in,smooth_in:ncol-smooth_in]
           newwavecal[smooth_in:ncol-smooth_in,smooth_in:ncol-smooth_in,3]=wdummy[smooth_in:ncol-smooth_in,smooth_in:ncol-smooth_in]
           newwavecal[smooth_in:ncol-smooth_in,smooth_in:ncol-smooth_in,0]=ydummy[smooth_in:ncol-smooth_in,smooth_in:ncol-smooth_in]
           newwavecal[smooth_in:ncol-smooth_in,smooth_in:ncol-smooth_in,1]=xdummy[smooth_in:ncol-smooth_in,smooth_in:ncol-smooth_in]
           newwavecal[wherenan] = !values.f_nan
endif


;SAVE THE NEW WAVELENGTH CALIBRATION:

suffix='wavecal'
*dataset.currframe = newwavecal

*dataset.currdq = finite(newwavecal[*,*,0])

;wavecalimage=save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, "_"+filter+"_"+suffix,display=0, savedata=newwavecal,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile] ,output_filename=output_filename)

	; Now the wavecal is done and ready to be saved.	
	; We handle this a bit differently here than is typically done via __end_primitive,
	; because we want to make use of some nonstandard display hooks to show the wavecal (optionally).
	

@__end_primitive_wavecal

end
