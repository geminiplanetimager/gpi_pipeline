;+
; NAME: sat_spots_calib_from_unocc
; PIPELINE PRIMITIVE DESCRIPTION: Measure satellite spot flux ratios
;
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	
; DRP KEYWORDS: FILETYPE,ISCALIB,PSFCENTX,PSFCENTY,SPOT[1-4][x-y],SPOTWAVE
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Calculate flux ratio between satellite spots and unocculted star image in a given aperture.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="tests" Type="int" Range="[0,1]" Default="0" Desc="1 only for DRP tests "
; PIPELINE ORDER: 2.515
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   JM 2010-08: routine optimized with simulated test data
;- 

function sat_spots_calib_from_unocc, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id$' ; get version from subversion to store in header history
    getmyname, functionname
@__start_primitive
   ; save starting time
   T = systime(1)

  cubef3D=*(dataset.currframe[0])
;;TOCHECK: unocculted image?
;;TOCHECK: is datacube registered?

        ;get the common wavelength vector
        filter = gpi_simplify_keyword_value(backbone->get_keyword('FILTER1', count=ct))
            ;error handle if extractcube not used before
            if ((size(cubef3D))[0] ne 3) || (strlen(filter) eq 0)  then $
            return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before.')        
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]



;hdr= *(dataset.headers)[0]

   ; if numext eq 0 then hdr= *(dataset.headers)[numfile] else hdr= *(dataset.headersPHU)[numfile]


;; set the photometric apertures and parameters
phpadu = 1.0                    ; don't convert counts to electrons
;apr = [6.]   ;constant is ok as the same aperture radius is used for sat. and star itself ;5
   ;;apr is 2.*lambda/D (EE=94%) 2.7
               case strcompress(filter,/REMOVE_ALL) of
              'Y':apr0=1.4
              'J':apr0=1.4
              'H':apr0=1.4
              'K1':apr0=1.4
              'K2':apr0=1.4
            endcase
    apr = apr0*(lambda[n_elements(lambda)/2]*1.e-6/7.7)*(180.*3600./!dpi)/0.014;[radaper];lambda[0]*[3.];lambda[0]*[5.];lambda[0]*[3.] 
skyrad = [apr+2.,apr+6.]
;skyrad = [6.,8.] 
;if (filter eq 'J')||(filter eq 'Y') then apr-=1.  ;satellite spots are close to the dark hole in these bands...
;if (filter eq 'J')||(filter eq 'Y') then skyrad-=2.1
; Assume that all pixel values are good data
badpix = [-1.,1e6]

;;; handle the spot locations
SPOTWAVE=backbone->get_keyword('SPOTWAVE', count=cc4)
  
  
 ;SPOTWAVE=sxpar( *(dataset.headers)[numfile], 'SPOTWAVE',  COUNT=cc4)
   if cc4 gt 0 then begin
   spotloc=fltarr(5,2) ;1+ due for PSF center 
          spotloc[0,0]=backbone->get_keyword('PSFCENTX');sxpar( *(dataset.headers[numfile]),"PSFCENTX")
          spotloc[0,1]=backbone->get_keyword('PSFCENTY');sxpar( *(dataset.headers[numfile]),"PSFCENTY")      
        for ii=1,(size(spotloc))[1]-1 do begin
          spotloc[ii,0]=backbone->get_keyword("SPOT"+strc(ii)+'x') ;sxpar( *(dataset.headers[numfile]),"SPOT"+strc(ii)+'x')
          spotloc[ii,1]=backbone->get_keyword("SPOT"+strc(ii)+'y') ;sxpar( *(dataset.headers[numfile]),"SPOT"+strc(ii)+'y')
        endfor  
   endif else begin
      SPOTWAVE=lambdamin
      print, 'NO SPOT LOCATIONS FOUND: assume PSF is centered'
      print, 'Use hard-coded value for spot locations in function '+functionname
        cs=1
       if cs eq 1 then spotloc=fltarr(1+4,2) else spotloc=fltarr(1+2,2) ;1+ due for PSF center 
            spotloc[0,0]=(size(cubef3D))[1]/2
            spotloc[0,1]=(size(cubef3D))[1]/2  
            print, 'Assume PSF center is [in pix on datacube slice]', spotloc[0,*] 
            ;;; if spot location calibration is NOT available, 
            ;;; enter hereafter the pixel coordinates of satellite images in datacube at the minimum wavelength 
            ;;; in the format: spotloc=[[PSFcenterX,sat1-x,sat2-x,sat3-x,sat4-x],[PSFcenterY,sat1-y,sat2-y,sat3-y,sat4-y]]
            ;;; Note that the spot location calibration can be obtained using the CAL-SPEC DRF templates in the DRF GUI.
            ;;; Note also that the wavelength reference SPOTWAVE for these locations can be different. 
            case strcompress(filter,/REMOVE_ALL) of
              'Y':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
              'J':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
              'H':spotloc=[[140.,140.,140.,140.,140.],[140.,69.,69.,69.,69.]]
              'K1':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
              'K2':spotloc=[[1.,2.,3.,4.,5.],[10.,11.,12.,13.,14.]]
            endcase
              for ii=1,(size(spotloc))[1]-1 do $
              print, 'ASSUME SPOT locations at ',lambdamin,' microms are',spotloc[ii,*]
    endelse


cubcent2=cubef3D

thisModuleIndex = Backbone->GetCurrentModuleIndex()
if tag_exist( Modules[thisModuleIndex], "tests") then $
tests=fix(Modules[thisModuleIndex].tests) else $;we test this routine not with satellites but with two objects of known flux (their locations (vs wavelength) are constant) 
tests=0
 if tests eq 2 then begin ;only for DRP tests:this is because unfortunately occulted and unocculted reference PSF do not have spots at same locations
                case strcompress(filter,/REMOVE_ALL) of
                  'Y':begin
                      spotloc=[[140.,2.,3.,4.,5.],[140.,11.,12.,13.,14.]] 
                      SPOTWAVE=0.
                     end
                  'J':begin
                      spotloc=[[140.,2.,3.,4.,5.],[140.,11.,12.,13.,14.]] 
                      SPOTWAVE=0.
                      end
                  'H':
                  'K1':begin 
                      spotloc=[[140.,218.,114.5,63.,166.5],[140.,166.,218.,114.,62.5]] 
                       SPOTWAVE=2.049
                       end
                  'K2':begin
                      spotloc=[[140.,2.,3.,4.,5.],[140.,11.,12.,13.,14.]] 
                       SPOTWAVE=0.
                       end
                endcase
 endif
;stop
 for ii=1,(size(spotloc))[1]-1 do $
              print, 'SPOT locations at ',SPOTWAVE,' microms are',spotloc[ii,*]
;;do the photometry of the spots
intens_sat=fltarr((size(spotloc))[1]-1,CommonWavVect[2])
sidelen=8
for spot=1,(size(spotloc))[1]-1 do begin
  for i=0,CommonWavVect[2]-1 do begin
      ;;extrapolate sat -spot at a given wavelength
      if tests ne 1 then $
      pos2=calc_satloc(spotloc[spot,0],spotloc[spot,1],spotloc[0,*],SPOTWAVE,lambda[i]) else $
      pos2=[spotloc[spot,0],spotloc[spot,1]]      
      print, 'pos ini=',pos2
      getsatpos=centroid(subarr(cubcent2[*,*,i],sidelen,[pos2[0],pos2[1]]))
      ;x=spotloc[spot,0]-sidelen/2.+getsatpos[0] & y=spotloc[spot,1]-sidelen/2.+getsatpos[1]
      x=pos2[0]-sidelen/2.+getsatpos[0] & y=pos2[1]-sidelen/2.+getsatpos[1]
        ;x=pos2[0]
        ;y=pos2[1]
      aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, (lambda[i]/lambda[0])*apr, $
        (lambda[i]/lambda[0])*skyrad, badpix, /flux, /silent ;, flux=abs(state.magunits-1)
        print, 'slice#',i,' flux sat #'+strc(spot)+'=',flux[0],' at x=',x,' y=',y,' sky=',sky[0]
      intens_sat[spot-1,i]=flux[0] ;(flux[0]-sky[0])
  endfor

endfor

;;unocculted STAR location; ok if it is not perfectly centered (it uses a centroid algo to localize center)
inputS=dblarr(CommonWavVect[2])
;star location
sidelen=8;20
getstarpos=centroid(subarr(cubcent2[*,*,0],sidelen,spotloc[0,*]))
x=spotloc[0,0]-sidelen/2.+getstarpos[0] & y=spotloc[0,1]-sidelen/2.+getstarpos[1]
for i=0,CommonWavVect[2]-1 do begin
    aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, (lambda[i]/lambda[0])*apr, $
      (lambda[i]/lambda[0])*skyrad, badpix, /flux, /silent 
      print, 'slice=',i,' star flux=',flux[0],' sky=',sky[0],' at x=',x,' y=',y
        inputS[i]=flux[0] ;(flux[0]-sky[0])
endfor
nbspot=(size(spotloc))[1]-1

;print, 'Star/sat ratio 1:',inputS/intens_sat[0,*]
;print, 'Star/sat ratio 2:',inputS/intens_sat[1,*]

for i=0,nbspot-1 do $
gridratio=inputS*float(nbspot)/total(intens_sat,1)

print, 'nb spots=',float(nbspot)
print, 'tot intens sat=',total(intens_sat,1)
print, 'grid_ratios=',gridratio
print, 'mean grid ratio=',mean(gridratio[0:n_elements(gridratio)-1], /nan) ;remove edges that can be affected by the interpolation on wavelength?
print, 'median grid ratio=',median(gridratio[0:n_elements(gridratio)-1])
print, 'applied median grid ratio=',median(gridratio[10:n_elements(gridratio)-10])
lambda_gridratio=[[lambda],[gridratio]]

suffix+='-fluxcal'


  ; Set keywords for outputting files into the Calibrations DB
  if tests ne 1 then begin

  backbone->set_keyword, "FILETYPE", "Grid ratio", "What kind of IFS file is this?", ext_num=0
  backbone->set_keyword,"ISCALIB", "YES", 'This is a reduced calibration file of some type.', ext_num=0
    
	thisModuleIndex = Backbone->GetCurrentModuleIndex()
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
		  if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, savedata=lambda_gridratio ,display=display)
    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
          Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
    endelse
   endif 
if tests eq 1 then begin
    mydevice = !D.NAME
    thisLetter = "155B
    greekLetter = '!9' + String(thisLetter) + '!X'
    thisModuleIndex = Backbone->GetCurrentModuleIndex()
    ;figtitle=(Modules[thisModuleIndex].title)
    openps,getenv('GPI_DRP_OUTPUT_DIR')+path_sep()+'test04.ps', xsize=18, ysize=17 ;, ysize=10, xsize=15
      ;!P.MULTI = [0, 1, 2, 0, 0] 
;      plot, lambda, gridratio,ytitle='Grid ratio', xtitle='Wavelength (' + greekLetter + 'm)',$
;       xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=0, psym=1,charsize=1.,yrange=[0.8e4,1.2e4];,title=''
     plot, lambda, replicate(median(gridratio[10:n_elements(lambda)-10]),n_elements(lambda)),ytitle='Grid ratio', xtitle='Wavelength (' + greekLetter + 'm)',$
       xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=0, psym=1,charsize=1.,yrange=[0.8e4,1.2e4];,title=''
     ;  oplot,lambda, replicate(median(lambda_gridratio[10:nelem-10,1]),n_elements(lambda)),linestyle=1
       oplot,lambda, replicate(1.e4,n_elements(lambda)),linestyle=1
       ;legend,['measured grid ratio (mean)='+strc(mean(gridratio)),'DST flux ratio'],linestyle=[0,1],psym=[1,0]
     ;  legend,['measured grid ratio (median)='+strc(median(gridratio))+'med tron='+strc(median(gridratio[10:n_elements(gridratio)-10])),'DST flux ratio'],linestyle=[0,1],psym=[1,0],/bottom
        legend,['measured grid ratio (median)='+strc(median(gridratio[10:n_elements(gridratio)-10]))+' Err[%]='+strc(100.*((median(gridratio[10:n_elements(gridratio)-10])-1.e4)/1.e4),format='(g4.2)'),'DST flux ratio'],linestyle=[0,1],psym=[1,0],/bottom
     closeps
      SET_PLOT, mydevice ;set_plot,'win'
endif
;drpPushCallStack, functionName
return, ok


end
