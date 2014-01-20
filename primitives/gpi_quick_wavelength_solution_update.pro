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
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[-1,100]" Default="-1" Desc="-1 = No display; 0 = New (unused) window; else = Window number to display each lenslet in comparison to the detector lenslet in."
; PIPELINE ARGUMENT: Name="spacing" Type="Int" Range="[0,20]" Default="10" Desc="Test every Nth lenslet for this value of N."
; PIPELINE ARGUMENT: Name="boxsizex" Type="Int" Range="[0,15]" Default="7" Desc="x dimension of a lenslet cutout"
; PIPELINE ARGUMENT: Name="boxsizey" Type="Int" Range="[0,50]" Default="24" Desc="y dimension of a lenslet cutout"
; PIPELINE ARGUMENT: Name="whichpsf" Type="Int" Range="[0,1]" Default="0" Desc="Type of psf 0;gaussian, 1;microlens"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type='String' CalFileType="wavecal" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitvim_dispgrid" Type="int" Range="[0,500]" Default="15" Desc="1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display "
; PIPELINE ORDER: 1.7
; PIPELINE NEWTYPE: Calibration
;
; HISTORY:
;	2013-09-19 SW: 2-dimensionsal wavelength solution 
;   2013-12-16 MP: CalibrationFile argument syntax update. 
;-  

function gpi_quick_wavelength_solution_update, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id$' ; get version from subversion to store in header history

calfiletype='wavecal'

; the following line sources a block of code common to all primitives
; It loads some common blocks, records the primitive version in the header for
; history, then if calfiletype is not blank it queries the calibration database
; for that file, and does error checking on the returned filename.
@__start_primitive


;Beginning of Wavelength Solution code:

;Initialize the input parameters:
 	if tag_exist( Modules[thisModuleIndex], "display") then display=fix(Modules[thisModuleIndex].display) else display=-1
 	if tag_exist( Modules[thisModuleIndex], "spacing") then spacing=uint(Modules[thisModuleIndex].spacing) else spacing=10
 	if tag_exist( Modules[thisModuleIndex], "boxsizex") then boxsizex=uint(Modules[thisModuleIndex].boxsizex) else boxsizex=7
 	if tag_exist( Modules[thisModuleIndex], "boxsizey") then boxsizey=uint(Modules[thisModuleIndex].boxsizey) else boxsizey=24
 	if tag_exist( Modules[thisModuleIndex], "whichpsf") then whichpsf=uint(Modules[thisModuleIndex].whichpsf) else whichpsf=0

;Define common block to be used in wrapper.pro and ngauss.pro
common ngausscommon, numgauss, wl, flux, lambdao,my_psf


;Load in the image. Primitive assumes a dark,flat,badpixel,flexure, and microphonics corrected lamp image. 

        image=*dataset.currframe
        

;READ IN REFERENCE WAVELENGTH CALIBRATION

;Uncommenting next line will override the users ability to manually
;choose a wavecal.
;	c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( 'wavecal',*(dataset.headersphu)[numfile],*(dataset.headersext)[numfile], /verbose) 
	
	; put into header
	backbone->set_keyword, "HISTORY", functionname+": get wav. calibration file",ext_num=0
        backbone->set_keyword, "HISTORY", functionname+": "+c_File,ext_num=0
        backbone->set_keyword, "DRPWVCLF", c_File, "DRP wavelength calibration file used.", ext_num=0
				

        ;open the reference wavecal file. Save into common block variable.
        refwlcal = gpi_readfits(c_File,header=Header)
        wlcalsize=size(refwlcal,/dimensions)
        print,wlcalsize

        newwavecal=dblarr(wlcalsize)
        newwavecal[*,*,2]=refwlcal[*,*,2]


        ;READ IN BAD PIXEL MAP
		if ptr_valid(dataset.currdq) then begin
	        badpix=*dataset.currdq GT 0
		endif else begin
			sz = size(image)
			badpix = bytarr(sz[0], sz[1])
		endelse
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
statuswindow = backbone->getstatusconsole()

numiterations = float(iend-istart)*(iend-istart)/(spacing^2)

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

		  res=gpi_wavecal_wrapper(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"ngauss") 

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


				  statuswindow->set_percent,-1,1d/numIterations*100d/double(N_ELEMENTS(Modules)),/append
                  
               endfor

        endfor


		catch,/cancel
	backbone->Log, " Performed spectral fit for "+strc(counter)+" lenslets total."
	; now we compare the properties derived for the subset of lenslets we just fit, 
	; versus the existing properties of the prior wavecal
	wg = where((newwavecal[*,*,0] ne 0) and finite(newwavecal[*,*,0]))
	
	xdiffs = (newwavecal[*,*,0])[wg] - (refwlcal[*,*,0])[wg]
	ydiffs = (newwavecal[*,*,1])[wg] - (refwlcal[*,*,1])[wg]

;	mnx = mean(xdiffs,/nan)
;	mny = mean(ydiffs,/nan)
;	sdx = stddev(xdiffs[xsubs],/nan)
;	sdy = stddev(ydiffs[ysubs],/nan)

; replacing with clipped values
	meanclip,xdiffs,mnx,sdx,clipsig=2,subs=xsubs
	meanclip,ydiffs,mny,sdy,clipsig=2,subs=ysubs


	backbone->Log, "Mean shifts (X,Y) of this file vs. old wavecal: "+printcoo(mnx, mny)+" pixels,   +- "+printcoo(sdx,sdy)+" pixels 1 sigma"

	if display ne -1 then begin
		if display eq 0 then window,/free else select_window, display
		!p.multi=[0,1,2]
		if n_elements(uniqvals(xdiffs)) gt 1 then begin
			plothist, xdiffs, bin=0.01, title="X pos offset [current-old]", xtitle="Detector pixels", $
				ytitle='# of tested lenslets'
			;ver, mnx,/line
			oplot,[mnx,mnx],[0,counter],color=100
		endif

		if n_elements(uniqvals(ydiffs)) gt 1 then begin
			plothist, ydiffs, bin=0.01, title="Y pos offset [current-old]", xtitle="Detector pixels", $
				ytitle='# of tested lenslets'
			oplot,[mny,mny],[0,counter],color=100
    endif
                !p.multi=0
  endif 

	shiftedwavecal = refwlcal
;        shiftedwavecal[*,*,0]=newwavecal[*,*,0]
;        shiftedwavecal[*,*,1]=newwavecal[*,*,1]
	shiftedwavecal[*,*,0] += mnx
	shiftedwavecal[*,*,1] += mny
; Edit the header of the original raw data products 
; to include the information about the new wavelength
; calibration. Taken from the gpi_measure_wavelength_calibration.pro
; primitive file. 

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
backbone->set_keyword, "HISTORY", ext_num=0, "                    1 sigma dispersions: "+printcoo(sdx, sdy)+" pixels"


  suffix='wavecal'
*dataset.currframe = shiftedwavecal
ptr_free, dataset.currDQ, dataset.currUncert


@__end_primitive_wavecal

end
