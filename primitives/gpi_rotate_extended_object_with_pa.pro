;+
; NAME: gpi_rotate_extended_object_with_PA
; 		
;
; PIPELINE PRIMITIVE DESCRIPTION: Rotate extended object
;
;
; KEYWORDS:
; OUTPUTS:
;  INPUTS:

; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-rot" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="10" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE COMMENT: Rotate extended object using parallactic angle for spectroscopic obs.
; PIPELINE ORDER: 4.1
; PIPELINE TYPE: ASTR/SPEC
; PIPELINE SEQUENCE: 02-03-
; EXAMPLE: 
;  <module name="Rotate extended object" suffix="-rot" Save="1" gpitv="1" />
; HISTORY:
; 	 Created JM 2010-04-23
;
;-

Function gpi_rotate_extended_object_with_PA, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id$' ; get version from subversion to store in header history
   getmyname, functionName
   @__start_primitive

;;if all images have been processed into datacubes then start ADI processing...
if numfile  eq ((dataset.validframecount)-1) then begin
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
  ;thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName) ;module# to get data proc options from user choice
  nfiles=dataset.validframecount
  silent=0
  
  ;;get PA angles of images for final ADI processing
  paall=dblarr(dataset.validframecount)
  for n=0,dataset.validframecount-1 do begin
    header=*(dataset.headers[n])
    paall[n]=double(SXPAR( header, 'PAR_ANG'))
  endfor
  
 ; dtmean=mean((abs(paall-shift(paall,-1)))[0:nfiles-2])*!dtor ;calculate the PA distance between acquisitions
  
  ;;get some parameters of datacubes, could have been already defined before; ToDo:check if already defined and remove this piece of code..
  dimcub=(size(*(dataset.currframe[0])))[1]  ;
  xc=dimcub/2 & yc=dimcub/2
  lambdamin=CommonWavVect[0]
  lambdamax=CommonWavVect[1]
  ;Common Wavelength Vector
  lambda=dblarr(CommonWavVect[2])
  for i=0,CommonWavVect[2]-1 do lambda[i]=lambdamin+double(i)*(lambdamax-lambdamin)/(CommonWavVect[2]-1)

;  nimmed=Modules[thisModuleIndex].numimmed ;get the # of image for the calculation of the PSF reference (user defined)
;;if tag_exist( Modules[thisModuleIndex], "nimmed") then  nimmed=keyword_set( Modules[thisModuleIndex].nimmed)
;
;  dr=5
;  rmin=0
;  ;nombre de points radiaux
;  rmin+=dr/2
;  nrad=ceil((dimcub/2.-rmin)/dr)
;  rall=findgen(nrad)*dr+rmin
;  
;  ;array des distances
;  distarr=shift(dist(dimcub),dimcub/2,dimcub/2)

  tim=systime(1)
  ;loop on images to do the PSF subtraction
    for n=0,dataset.validframecount-1 do begin
      im=dblarr((size(*(dataset.currframe[0])))[1],(size(*(dataset.currframe[0])))[2],(size(*(dataset.currframe[0])))[3])
      ;;get the filenames of sc. data
    ;  fn=*((dataset.frames)[n])
      ;;get the datacube filename
    ;  fn=Modules[0].OutputDir+path_sep()+strmid(fn,1+strpos(fn,path_sep(),/REVERSE_SEARCH ),STRPOS(fn,'.fits')-strpos(fn,path_sep(),/REVERSE_SEARCH )-1)+suffix+'.fits'
      fn=dataset.outputFileNames[n]
    ;  imt=readfits(fn,header,/silent)
      imt=accumulate_getimage( dataset, n, header)
        ;loop on wavelength
        for il=0, n_elements(lambda)-1 do begin
;        nfwhm=Modules[thisModuleIndex].nfwhm ;get the user-defined minimal distance for the subtraction
;        Dtel=7.77
;        fwhm=1.03*(1.e-6*lambda[il]/Dtel)*(180.*3600./!dpi)/0.014 

        im1=imt[*,*,il]

;        ;frame that will contain the difference
;        im1s=fltarr(dimcub,dimcub,/nozero)+!values.f_nan

;          ;loop on annulus
;          for ir=0,nrad-1 do begin
;            r=rall[ir] & ri=r-dr/2. & rf=r+dr/2.
;            if silent eq 0 then print,'frame#'+strc(n+1)+'(/'+strc(dataset.validframecount)+')'+' Wavelength(um)='+strc(lambda(il),format='(f5.2)')+' Annulus with radius '+string(r,format='(f5.1)')+$
;              ' [>='+string(ri,format='(f5.1)')+', <'+string(rf,format='(f5.1)')+']'
;
;            ;indices of all pixels included in this annulus
;            ia=where(distarr lt ((r+dr/2.)<dimcub/2) and distarr ge r-dr/2.,count)
;            if (count eq 0) then break
;
;            ;user-defined minimal angular separation
;            theta0=(nfwhm*fwhm)/r*180.d/!dpi ;en degres
;
;            ;selection of images for the calculation of the median PSF ref.
;            padiff=abs(paall[*]-paall[n])
;            ind=where(padiff gt theta0,ci)
;            ;check if images are sufficiently shifted ;determine images suffisament decalees pour la soustraction
;            if ci eq 0  then begin
;              im1s[ia]=!values.f_nan
;            endif else begin
;              ind=ind[sort(padiff[ind])]
;              if n_elements(ind) ne 1 then $
;              ind=ind[0:(n_elements(ind)-1)<(nimmed-1)]
;
;              if silent eq 0 then print,'  selected images for the calculation of the median PSF ref.: ',fn ;strjoin(strtrim(*((dataset.frames)[(ind)]),2),',')
;              if silent eq 0 then print,'  Read these images...'
;              ;keep only this annulus for all images to be processed in the PSF ref. calculation
;              im2=dblarr(count,n_elements(ind),/nozero)
;              for i=0,n_elements(ind)-1 do begin 
;                ;im2[*,i]=(readfits(Modules[0].OutputDir+path_sep()+strmid(*((dataset.frames)[(ind[i])]),1+strpos(*((dataset.frames)[(ind[i])]),path_sep(),/REVERSE_SEARCH ),STRPOS(*((dataset.frames)[(ind[i])]),'.fits')-strpos(*((dataset.frames)[(ind[i])]),path_sep(),/REVERSE_SEARCH )-1)+suffix+'.fits',NSLICE=il,/silent))[ia]
;                ;im2[*,i]=(readfits(dataset.outputFileNames[(ind[i])],/silent))[ia]
;                im2[*,i]=((accumulate_getimage( dataset, (ind[i])))[*,*,il])[ia]
;              endfor
;
;              if silent eq 0 then print,'  Calculation of the median PSF ref...'
;              if n_elements(ind) gt 1 then $
;              im2=median(im2,dimension=2,/even)
;
;              ;time to do the subtraction
;              if silent eq 0 then print,'  Subtract...'
;              im1s[ia]=im1[ia]-im2
;            endelse; ci ne 0
;          endfor ;loop annulus

          ;rotation to have same orientation than the first image
          if silent eq 0 then print,' Rotation to have same orientation than the first image...'
          theta=paall[n]-paall[0]
            x0=float(SXPAR( *(dataset.headers[n]), 'PSFCENTX',count=ccx))
            y0=float(SXPAR( *(dataset.headers[n]), 'PSFCENTY',count=ccy))
            hdr=*(dataset.headers[n]) ;JM 2010-03-19
            if ((ccx eq 0) || (ccy eq 0) || ~finite(x0) || ~finite(y0))  then begin           
              if n ne 0 then im1=gpi_adi_rotat(im1,theta,missing=!values.f_nan,hdr=*(dataset.headers[n])) ;(do not rotate first image)
            endif else begin
              if n ne 0 then im1=gpi_adi_rotat(im1,theta,x0,y0,missing=!values.f_nan,hdr=*(dataset.headers[n])) ;(do not rotate first image)
            endelse  
            *(dataset.headers[n])=hdr
          im[*,*,il]=im1
        endfor ;loop on lambda

    ;save the difference
      if tag_exist( Modules[thisModuleIndex], "suffix") then subsuffix=Modules[thisModuleIndex].suffix
    
    ;subsuffix='-adim'  ;this the suffix that will be added to the name of the ADI residual  
	  fname=strmid(fn,0,strpos(fn,suffix)-1)+suffix+subsuffix+'.fits'
	  header=*(dataset.headers[n])
    sxaddhist,'One rotation of '+string(theta,format='(f7.3)')+$
      ' degrees has been applied.',header
      *(dataset.currframe[0])=im
      *(dataset.headers[numfile])=header
thisModuleIndex = Backbone->GetCurrentModuleIndex()

    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix+subsuffix, display=display, saveheader=header)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
    endelse
    filename=fn
    ;update_progressbar,Modules,thisModuleIndex,Dataset.validframecount, n ,'working...',/adi    
    endfor ; loop on images

  print, 'proc time adim(s)=',-tim+systime(1)

  suffix=suffix+subsuffix
  endif   ;;if last image has been processed into datacube

;drpPushCallStack, functionName
return, ok
end
