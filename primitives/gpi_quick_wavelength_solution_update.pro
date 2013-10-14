;+
; NAME: quick_wavelength_solution_update.pro
; PIPELINE PRIMITIVE DESCRIPTION: Quick Wavelength Solution Update
;
;   This Wavelength Solution generator simulates an arclamp spectrum
;   for each lenslet and uses mpfit2dfunc to fit the relevant
;   wavelength solution variables (ie. xo, yo, lambdao, dispersion,
;   tilt). A wavelength solution file is output along with a
;   simulated detector image. 
;
; INPUTS: An Xe/Ar lamp detector image
;
; KEYWORDS:
; GEM/GPI KEYWORDS:FILTER,IFSFILT,GCALLAMP
; DRP KEYWORDS: FILETYPE,HISTORY,ISCALIB
;
; OUTPUTS: A wavelength solution cube (and a simulated Xe/Ar lamp
; detector image; to come)
;
; PIPELINE COMMENT: Given an existing wavecal and a new Xe lamp image, this primitive updates the wavecal roughly based on the X,Y positions measured for a subset of the Xe spectra. 
;
;
; PIPELINE ARGUMENT: Name="display" Type="Int" Range="[0,1]" Default="0" Desc="Whether or not to plot each lenslet in comparison to the detector lenslet: 1;display, 0;no display"
; PIPELINE ARGUMENT: Name="spacing" Type="Int" Range="[0,20]" Default="10" Desc="Test every Nth lenslet for this value of N."
; PIPELINE ARGUMENT: Name="boxsizex" Type="Int" Range="[0,15]" Default="7" Desc="x dimension of a lenslet cutout"
; PIPELINE ARGUMENT: Name="boxsizey" Type="Int" Range="[0,50]" Default="24" Desc="y dimension of a lenslet cutout"
; PIPELINE ARGUMENT: Name="whichpsf" Type="Int" Range="[0,1]" Default="0" Desc="Type of psf 0;gaussian, 1;microlens"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="wavcal" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitvim_dispgrid" Type="int" Range="[0,500]" Default="15" Desc="1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display "
; 
; where in the order of the primitives should this go by default?
; PIPELINE ORDER: 1.7
;
; pick one of the following options for the primitive type:
; PIPELINE NEWTYPE: Calibration
;
; HISTORY:
;    2013-09-19 SW: 2-dimensionsal wavelength solution 
;-  

function gpi_quick_wavelength_solution_update, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id: __template.pro 1742 2013-07-19 18:03:57Z mperrin $' ; get version from subversion to store in header history

calfiletype='wavecal'

; the following line sources a block of code common to all primitives
; It loads some common blocks, records the primitive version in the header for
; history, then if calfiletype is not blank it queries the calibration database
; for that file, and does error checking on the returned filename.
@__start_primitive


;Beginning of Wavelength Solution code:

;Initialize the input parameters:
 	if tag_exist( Modules[thisModuleIndex], "display") then display=uint(Modules[thisModuleIndex].display) else display=0
 	if tag_exist( Modules[thisModuleIndex], "spacing") then spacing=uint(Modules[thisModuleIndex].spacing) else spacing=10
 	if tag_exist( Modules[thisModuleIndex], "boxsizex") then boxsizex=uint(Modules[thisModuleIndex].boxsizex) else boxsizex=7
 	if tag_exist( Modules[thisModuleIndex], "boxsizey") then boxsizey=uint(Modules[thisModuleIndex].boxsizey) else boxsizey=24
 	if tag_exist( Modules[thisModuleIndex], "whichpsf") then whichpsf=uint(Modules[thisModuleIndex].whichpsf) else whichpsf=0
 	if tag_exist( Modules[thisModuleIndex], "display") then display=uint(Modules[thisModuleIndex].display) else display=0


;Define common block to be used in wrapper.pro and ngauss.pro
common ngausscommon, numgauss, wl, flux, lambdao,my_psf


;Load in the image. Primitive assumes a dark,flat,badpixel,flexure, and microphonics corrected lamp image. 

        image=*dataset.currframe
        

;READ IN REFERENCE WAVELENGTH CALIBRATION


	c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( 'wavecal',*(dataset.headersphu)[numfile],*(dataset.headersext)[numfile], /verbose) 

        ;open the reference wavecal file. Save into common block variable.
        refwlcal = gpi_readfits(c_File,header=Header)
        wlcalsize=size(refwlcal,/dimensions)
        print,wlcalsize

        newwavecal=dblarr(wlcalsize)
        newwavecal[*,*,2]=refwlcal[*,*,2]


        ;READ IN BAD PIXEL MAP
        badpix=*dataset.currdq GT 0
        ;badpix=dblarr(size(image))
        ;badpix[*]=0

       ; Load in the microlens psf array. NOT YET SUPPORTED
        ;open the appropriate micrlens psf file and assign it to the 
        ;variable my_psf. Pass this through to the wrapper function.
        ;myPSFs_array = read_PSFs(psffn, [281,281,1])
	

		lamp = backbone->get_keyword('GCALLAMP', count=ct1)
		filternm = backbone->get_keyword('IFSFILT', count=ct2)
        filter = gpi_simplify_keyword_value(filternm)
		obstype= backbone->get_keyword('OBSTYPE', count=ct3)
        
		if ct1 eq 0 then return, error("No GCALLAMP keyword was present, therefore cannot determine what spectrum to fit.")
		if ct2 eq 0 then return, error("No IFSFILT keyword was present, therefore cannot determine what spectrum to fit.")
		if ct3 eq 0 then return, error("No OBSTYPE keyword was present, therefore cannot determine what spectrum to fit.")

        ;backbone->Log,filter+lamp
        ;backbone->Log, gpi_get_directory('GPI_DRP_CONFIG_DIR')

		if (filter ne 'Y') and (filter ne 'J') and (filter ne 'H') and (filter ne 'K1') and (filter ne 'K2') then return, error("Invalid IFSFILT keyword: "+filter)

        datafn = gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+filter+lamp+'.dat'
        readcol, datafn,wl,flux,skipline=1,format='F,F'
        readcol,datafn,nmgauss,numline=1,format='I'
        numgauss=nmgauss[0]

        ;Create an array to serve as the simulated detector image
        ;lensletmodel=dblarr(size(image,/dimensions))
        
        ; Initialize some variables used for the error catcher
        xinterp=dblarr(78961) ; assumes 281x281 size of output cubes
        yinterp=dblarr(78961)
        q=0L

istart=0
iend=280
jstart=0
jend=280

	backbone->Log, "Fitting spectral lines for every "+strc(spacing)+"th lenslet"
counter=0

for i = istart,iend,spacing do begin
	for j = jstart,jend,spacing do begin
           xo=refwlcal[i,j,1]
           yo=refwlcal[i,j,0]
           startx=floor(xo-boxsizex/2.0)
           starty=round(yo)-20
           stopx = startx+boxsizex
           stopy = starty+boxsizey

           ;statusline,
          ; backbone->Log, "Lenslet index in datacube:   i="+strc(i)+", j="+strc(j)
          ; backbone->Log, "Initial guess from prior wavecal:   x0="+xo+"y0="+yo
         
           if refwlcal[i,j,0] NE refwlcal[i,j,0] then begin
               newwavecal[i,j,*]=!values.f_nan
               continue
           endif
			counter+=1
           if starty LT 0 then begin
               starty=0
            endif

           if startx LT 0 then begin
              startx=0
           endif

           ;Trim out the image and badpixel map for a single lenslet
           lensletarray=image[startx:stopx, starty:stopy] 
           badpixmap=badpix[startx:stopx, starty:stopy] 
 
           ;Choose the correct microlens psf for this lenslet 
           ;NOT YET SUPPORTED
           ; If the psf exists for this
           ; combination of i and j, then assign
           ; the psf to my_psf variable
           ;if ptr_valid(myPSFs_array[i,j]) then begin
           ;   my_psf = *myPSFs_array[i,j]
           ;   print, 'the PSF was valid'
           ;endif else begin
           ;   print, 'the PSF did not work for some reason'
           ;endelse

           catch,error_status
           ;error_status=0

                  ;print, 'errorstatus =====',error_status,i,j

                                ; Catch an error in the mpfit
                                ; calculation and interpolate
                 
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

		  res=wrapper(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"ngauss")                  

		; note swap of Y and X here to match GPI convention:
                  newwavecal[i,j,1]=res[0]+startx
                  newwavecal[i,j,0]=res[1]+starty
                  newwavecal[i,j,3]=res[2]      ;w
                  newwavecal[i,j,4]=res[3]      ;theta
                  

                  sizearray=size(lensletarray,/dimension)
                  ydimension=sizearray[1]
                  xdimension=sizearray[0]
                  x=indgen(xdimension)
                  y=indgen(ydimension)
                  
                  ;case whichpsf of
                  ;   'nmicrolens': begin
                  ;      zmodplot=nmicrolens(x,y,res)
                  ;   end
                  ;   'ngauss': begin
                  ;      zmodplot=ngauss(x,y,res)
                  ;   end
                  ;endcase

                  ;lensletmodel[startx:stopx, starty:stopy] += zmodplot

;                if display EQ 1  then begin
;				  !p.multi= [0,2,1]
;				  vmax = max(lensletarray)
;				  imdisp, alogscale(lensletarray, 0, vmax), /axis, title='Real data subarray', /xs, /ys
;				  imdisp, alogscale(zmodplot, 0, vmax), /axis,  title='Model', /xs, /ys
;				endif
                
               endfor

        ;backbone->Log,"Have now fit"+strc(i*j)+"/78961 lenslets"

        endfor

	backbone->Log, " Performed spectral fit for "+strc(counter)+" lenslets total."
	; now we compare the properties derived for the subset of lenslets we just fit, 
	; versus the existing properties of the prior wavecal
	wg = where((newwavecal[*,*,0] ne 0) and finite(newwavecal[*,*,0]))
	
	xdiffs = (newwavecal[*,*,0])[wg] - (refwlcal[*,*,0])[wg]
	ydiffs = (newwavecal[*,*,1])[wg] - (refwlcal[*,*,1])[wg]

	mnx = mean(xdiffs)
	mny = mean(ydiffs)

	backbone->Log, "Mean shifts (X,Y) of this file vs. old wavecal: "+printcoo(mnx, mny)+" pixels"

	if keyword_set(display) then begin
		!p.multi=[0,1,2]
		if n_elements(uniqvals(xdiffs)) gt 1 then begin
			plothist, xdiffs, bin=0.01, title="X pos offset [current-old]", xtitle="Detector pixels", $
				ytitle='# of tested lenslets'
			ver, mnx,/line
		endif

		if n_elements(uniqvals(ydiffs)) gt 1 then begin
			plothist, ydiffs, bin=0.01, title="Y pos offset [current-old]", xtitle="Detector pixels", $
				ytitle='# of tested lenslets'
			ver, mny,/line
		endif
	endif


	shiftedwavecal = refwlcal
	shiftedwavecal[*,*,0] += mnx
	shiftedwavecal[*,*,1] += mny
;Edit the header of the original raw data products to (-mean.fits
;filenames) to include the information about the new wavelength
;calibration. Taken from the gpi_measure_wavelength_calibration.pro
;primitive file. 

backbone->set_keyword, "FILETYPE", "Wavelength Solution Cal File"
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


backbone->set_keyword, "HISTORY", "  This is a **quick** wavecal from a subset of lenslets ",ext_num=0
backbone->set_keyword, "HISTORY", "  Quality may not be as good as a full thorough wavecal.",ext_num=0
backbone->set_keyword, "HISTORY", " ",ext_num=0;,/blank
backbone->set_keyword, "HISTORY", ext_num=0, "    Performed spectral fit for "+strc(counter)+" lenslets total."
backbone->set_keyword, "HISTORY", ext_num=0, "    Mean shifts (X,Y) vs. prior wavecal: "+printcoo(mnx, mny)+" pixels"

;SAVE THE NEW WAVELENGTH CALIBRATION:

  suffix='wavecal'

;Note the below is a quick hack stolen from save_currdata.pro and should be replaced
;wavecalimage=save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, "-"+filter+"-"+suffix, savedata=newwavecal,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile] ,output_filename=output_filename)
	  prev_saved_fn = backbone_comm->get_last_saved_file() ; ideally this will be the 2D image which was saved right before this step


    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, filter+"-"+suffix, display=display,savedata=shiftedwavecal,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile] ,output_filename=output_filename)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
      if tag_exist( Modules[thisModuleIndex], "gpitvim_dispgrid") && ( fix(Modules[thisModuleIndex].gpitvim_dispgrid) ne 0 ) then $
           if strcmp(obstype,'flat',4,/fold) then im=im0


	  last_saved_fn = backbone_comm->get_last_saved_file()
	  my_base_fn = (strsplit(dataset.filenames[numFile], '_',/extract))[0]
	  if strpos(prev_saved_fn, my_base_fn) ge 0 then begin

		backbone_comm->gpitv, prev_saved_fn, session=fix(Modules[thisModuleIndex].gpitvim_dispgrid), dispwavecalgrid=output_filename, imname='Wavecal grid for '+  dataset.filenames[numfile]  ;Modules[thisModuleIndex].name
	  endif else begin

		backbone_comm->gpitv, double(image), session=fix(Modules[thisModuleIndex].gpitvim_dispgrid), header=*(dataset.headersPHU)[numfile], dispwavecalgrid=output_filename, imname='Wavecal grid for '+  dataset.filenames[numfile]  ;Modules[thisModuleIndex].name
	  endelse

	  
          
           ;gpitvms, double(im), ses=fix(Modules[thisModuleIndex].gpitvim_dispgrid),head=h,opt='dispwavcalgrid='+output_filename
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          backbone_comm->gpitv, double(*DataSet.currFrame), session=fix(Modules[thisModuleIndex].gpitv), header=*(dataset.headersPHU)[numfile], imname='Pipeline result from '+ Modules[thisModuleIndex].name,dispwavecalgrid=output_filename
          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=h
    endelse

return, ok


@__end_primitive

end
