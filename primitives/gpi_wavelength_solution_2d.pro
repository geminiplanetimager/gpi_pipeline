;+
; NAME: wavelength_solution_2d.pro
; PIPELINE PRIMITIVE DESCRIPTION: 2D Wavelength Solution
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
; PIPELINE COMMENT: This primitive uses an existing wavelength solution file 
; to construct a new wavelength solution file by simulating the detector image 
; and performing a least squares fit.


; PIPELINE ARGUMENT: Name="display" Type="Int" Range="[0,1]" Default="0" Desc="Whether or not to plot each lenslet in comparison to the detector lenslet: 1;display, 0;no display"
; PIPELINE ARGUMENT: Name="boxsizex" Type="Int" Range="[0,15]" Default="7" Desc="x dimension of a lenslet cutout"
; PIPELINE ARGUMENT: Name="boxsizey" Type="Int" Range="[0,50]" Default="24" Desc="y dimension of a lenslet cutout"
; PIPELINE ARGUMENT: Name="whichpsf" Type="Int" Range="[0,1]" Default="0" Desc="Type of psf 0;gaussian, 1;microlens"
; PIPELINE ARGUMENT: Name="parallel" Type="Int" Range="[0,1]" Default="0" Desc="Option for Parallelization 0;none, 1;parallel"
; PIPELINE ARGUMENT: Name="numsplit" Type="Int" Range="[1,281]" Default="1" Desc="Number of cores for parallelization"
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

function gpi_wavelength_solution_2d, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id$' ; get version from subversion to store in header history

; the following line sources a block of code common to all primitives
; It loads some common blocks, records the primitive version in the header for
; history, then if calfiletype is not blank it queries the calibration database
; for that file, and does error checking on the returned filename.
@__start_primitive


;Beginning of Wavelength Solution code:

;Initialize the input parameters:
 	if tag_exist( Modules[thisModuleIndex], "display") then display=uint(Modules[thisModuleIndex].display) else display=0
 	if tag_exist( Modules[thisModuleIndex], "boxsizex") then boxsizex=uint(Modules[thisModuleIndex].boxsizex) else boxsizex=7
 	if tag_exist( Modules[thisModuleIndex], "boxsizey") then boxsizey=uint(Modules[thisModuleIndex].boxsizey) else boxsizey=24
 	if tag_exist( Modules[thisModuleIndex], "whichpsf") then whichpsf=uint(Modules[thisModuleIndex].whichpsf) else whichpsf=0
  	if tag_exist( Modules[thisModuleIndex], "parallel") then parallel=uint(Modules[thisModuleIndex].parallel) else parallel=1
 	if tag_exist( Modules[thisModuleIndex], "numsplit") then numsplit=uint(Modules[thisModuleIndex].numsplit) else numsplit=1


;Load in the image. Primitive assumes a dark,flat,badpixel,flexure, and microphonics corrected lamp image. 

        image=*dataset.currframe
        

;READ IN REFERENCE WAVELENGTH CALIBRATION


	c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( 'wavecal',*(dataset.headersphu)[numfile],*(dataset.headersext)[numfile], /verbose) 

        ;open the reference wavecal file. Save into common block variable.
        refwlcal = gpi_readfits(c_File,header=Header)
        wlcalsize=size(refwlcal,/dimensions)
        print,wlcalsize

        newwavecal=dblarr(wlcalsize)
        


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
        
        if ct1 OR ct2 EQ 0 then print,"One of the header keywords doesn't exist"
        
        backbone->Log,"Now finding wavelength solution for "+filter+lamp, depth=3
        ;backbone->Log, gpi_get_directory('GPI_DRP_CONFIG_DIR')
        datafn = gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+filter+lamp+'.dat'
 

;print,'numgauss=',numgauss

        ;Create an array to serve as the simulated detector image
        ;lensletmodel=dblarr(size(image,/dimensions))
        
        ; Initialize some variables used for the error catcher
        xinterp=dblarr(78961)
        yinterp=dblarr(78961)
        q=0L

   


istart=0
iend=280
jstart=0
jend=280

        backbone->Log,"Parallelizing over "+strc(numsplit)+" IDL processes", depth=3,/flush

if parallel EQ 1 then begin

readcol, datafn,wla,fluxa,skipline=1,format='F,F'
readcol,datafn,nmgauss,numline=1,format='I'
 

count=0

;Parallelize the top level for loop

 split_for, istart,iend, nsplit=numsplit,varnames=['jstart','jend','refwlcal','boxsizex','boxsizey','image','badpix','newwavecal','q','wlcalsize','xinterp','yinterp','wla','fluxa','nmgauss','count'],outvar=['newwavecal','count'], commands=[$
'common ngausscommon, numgauss, wl, flux, lambdao,my_psf',$
'numgauss=nmgauss[0]',$
'wl=wla',$
'flux=fluxa',$
'count=count+1',$
'for j = jstart,jend do begin',$
'xo=refwlcal[i,j,1]',$
'yo=refwlcal[i,j,0]',$
'startx=floor(xo-boxsizex/2.0)',$
'starty=round(yo)-20',$
'stopx = startx+boxsizex' ,$
'stopy = starty+boxsizey' ,$
'if refwlcal[i,j,0] NE refwlcal[i,j,0] then begin' ,$
'    newwavecal[i,j,*]=!values.f_nan' ,$
'    continue' ,$
'endif' ,$
'if starty LT 0 then starty=0' ,$
'if startx LT 0 then startx=0' ,$
'lensletarray=image[startx:stopx, starty:stopy]',$
'badpixmap=badpix[startx:stopx, starty:stopy]',$
'catch,error_status',$
'if error_status NE 0 then begin',$
'   catch,/cancel',$
'   print, "errorstatus, i, j =====",error_status,i,j',$
'   print, "error message =====",!error_state.msg',$
'   print, "q ============", q',$
'   xinterp[q]=i',$
'   yinterp[q]=j',$
'   q++',$
'   continue',$
'endif',$
'res=gpi_wavecal_wrapper(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"ngauss")',$              
'newwavecal[i,j,1]=res[0]+startx',$
'newwavecal[i,j,0]=res[1]+starty',$
'newwavecal[i,j,2]=refwlcal[i,j,2]',$
'newwavecal[i,j,3]=res[2]',$
'newwavecal[i,j,4]=res[3]',$
'endfor',$
'print,"Have now fit "+strc(i*j)+"/78961 lenslets"']


width=dblarr(numsplit)

for k=0,numsplit-1 do begin
   width[strc(k)] = scope_varfetch('count' + strc(k))
   if k EQ 0 then istart=0 else istart=total(width[0:k-1])
   iend=istart+width[k]-1
   dummywave = scope_varfetch('newwavecal'+strc(k))
   newwavecal[istart:iend,*,*]=dummywave[istart:iend,*,*]
endfor


endif else begin

;Define common block to be used in wrapper.pro and ngauss.pro
common ngausscommon, numgauss, wl, flux, lambdao,my_psf

 readcol, datafn,wl,flux,skipline=1,format='F,F'
 readcol,datafn,nmgauss,numline=1,format='I'
 numgauss=nmgauss[0]

newwavecal[*,*,2]=refwlcal[*,*,2]

for i = istart,iend do begin
      for j = jstart,jend do begin
            xo=refwlcal[i,j,1]
            yo=refwlcal[i,j,0]
            startx=floor(xo-boxsizex/2.0)
            starty=round(yo)-20
            stopx = startx+boxsizex
            stopy = starty+boxsizey

;;            ;statusline,
;;           ; backbone->Log, "Lenslet index in datacube:   i="+strc(i)+", j="+strc(j)
;;           ; backbone->Log, "Initial guess from prior wavecal:   x0="+xo+"y0="+yo
         
            if refwlcal[i,j,0] NE refwlcal[i,j,0] then begin
                newwavecal[i,j,*]=!values.f_nan
                continue
            endif

            if starty LT 0 then begin
                starty=0
             endif

            if startx LT 0 then begin
               startx=0
            endif

;;            ;Trim out the image and badpixel map for a single lenslet
            lensletarray=image[startx:stopx, starty:stopy] 
            badpixmap=badpix[startx:stopx, starty:stopy] 
 
;;            ;Choose the correct microlens psf for this lenslet 
;;            ;NOT YET SUPPORTED
;;            ; If the psf exists for this
;;            ; combination of i and j, then assign
;;            ; the psf to my_psf variable
;;            ;if ptr_valid(myPSFs_array[i,j]) then begin
;;            ;   my_psf = *myPSFs_array[i,j]
;;            ;   print, 'the PSF was valid'
;;            ;endif else begin
;;            ;   print, 'the PSF did not work for some reason'
;;            ;endelse

            catch,error_status
;;            ;error_status=0

;;                   ;print, 'errorstatus =====',error_status,i,j

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

 		  res=gpi_wavecal_wrapper(i,j,refwlcal,lensletarray,badpixmap,wlcalsize,startx,starty,"ngauss")                  


                  ;take a running average of the unused
                  ;result parameters to be used in
                  ;interpolation
                  sizeres=size(res,/dimensions)

;; 		; note swap of Y and X here to match GPI convention:
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

;;                   sizearray=size(lensletarray,/dimension)
;;                   ydimension=sizearray[1]
;;                   xdimension=sizearray[0]
;;                   x=indgen(xdimension)
;;                   y=indgen(ydimension)
                  
;;                   ;case whichpsf of
;;                   ;   'nmicrolens': begin
;;                   ;      zmodplot=nmicrolens(x,y,res)
;;                   ;   end
;;                   ;   'ngauss': begin
;;                   ;      zmodplot=ngauss(x,y,res)
;;                   ;   end
;;                   ;endcase

;;                   ;lensletmodel[startx:stopx, starty:stopy] += zmodplot

;; ;                if display EQ 1  then begin
;; ;				  !p.multi= [0,2,1]
;; ;				  vmax = max(lensletarray)
;; ;				  imdisp, alogscale(lensletarray, 0, vmax), /axis, title='Real data subarray', /xs, /ys
;; ;				  imdisp, alogscale(zmodplot, 0, vmax), /axis,  title='Model', /xs, /ys
;; ;				endif
                
                endfor

         backbone->Log,"Have now fit"+strc(i*j)+"/78961 lenslets"

         endfor

endelse


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


;SAVE THE NEW WAVELENGTH CALIBRATION:

  suffix='wavecal'

wavecalimage=save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, "-"+filter+"-"+suffix,display=0, savedata=newwavecal,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile] ,output_filename=output_filename)


@__end_primitive

end
