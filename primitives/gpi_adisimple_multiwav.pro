;+
; NAME: gpi_ADIsimple_multiwav
; 		ADI algo based on Marois et al (2006) paper.
;
; PIPELINE PRIMITIVE DESCRIPTION: Basic ADI 
;
;
; KEYWORDS:
; GEM/GPI KEYWORDS:FILTER,PAR_ANG,TELDIAM
; DRP KEYWORDS: PSFCENTX,PSFCENTY
; OUTPUTS:
;  INPUTS:
;          numimmed:  number of images for the calculation of the PSF reference
;          nfwhm: number of fwhm to calculate the minimal distance for reference calculation
;          save: save results (datacubes with reference subtracted and then rotated )
;          gpitv: display result in gpitv session # (gpitv="0" means no display)
; PIPELINE ARGUMENT: Name="numimmed" Type="int" Range="[1,100]" Default="3" Desc="number of images for the calculation of the PSF reference"
; PIPELINE ARGUMENT: Name="nfwhm" Type="enum" Range="[0,1]" Default="1.5" Desc="number of FWHM to calculate the minimal distance for reference calculation"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-adim" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="10" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE COMMENT: Implements the basic ADI algorithm described by Marois et al. (2006).
; PIPELINE ORDER: 4.1
; PIPELINE TYPE: ASTR/SPEC
; PIPELINE SEQUENCE: 02-03-
; EXAMPLE: 
;  <module name="gpi_ADIsimple_multiwav" numimmed="3" nfwhm="1.5" Save="1" gpitv="1" />
; HISTORY:
; 	 Adapted for GPI - Jerome Maire 2008-08
;    multiwavelength - JM 
;   2009-09-17 JM: added DRF parameters
;    2010-04-26 JM: verify how many spectral channels to process and adapt ADI for that, 
;                so we can use ADI on collapsed datacubes or SDI outputs
;-

Function gpi_ADIsimple_multiwav, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

;;if all images have been processed into datacubes then start ADI processing...
if numfile  lt ((dataset.validframecount)-1) then return,0



  nfiles=dataset.validframecount
  silent=1
  
  ;;get PA angles of images for final ADI processing
   paall=dblarr(dataset.validframecount)
  haall=dblarr(dataset.validframecount)
  for n=0,dataset.validframecount-1 do begin
    ;header=*(dataset.headers[n])
    haall[n]=double(backbone->get_keyword('HA', indexFrame=n))
    paall[n]=double(backbone->get_keyword('PAR_ANG', indexFrame=n ,count=ct))
    lat = ten_string('-30 14 26.700') ; Gemini South
    dec=double(backbone->get_keyword('DEC'))
    if ct eq 0 then paall[n]=parangle(haall[n],dec,lat)
  endfor
  
  
  dtmean=mean((abs(paall-shift(paall,-1)))[0:nfiles-2])*!dtor ;calculate the PA distance between acquisitions
  
  ;;get some parameters of datacubes, could have been already defined before; ToDo:check if already defined and remove this piece of code..
  dimcub=(size(*(dataset.currframe[0])))[1]  ;
  xc=dimcub/2 & yc=dimcub/2
  ;filter=SXPAR( header, 'FILTER')
  filter = gpi_simplify_keyword_value(backbone->get_keyword('FILTER1', count=ct))
  cwv=get_cwv(filter)
  CommonWavVect=cwv.CommonWavVect
  
  lambdamin=CommonWavVect[0]
  lambdamax=CommonWavVect[1]
  ;Common Wavelength Vector
  lambda=dblarr(CommonWavVect[2])
  for i=0,CommonWavVect[2]-1 do lambda[i]=lambdamin+double(i)*(lambdamax-lambdamin)/(CommonWavVect[2]-1)

  nimmed=Modules[thisModuleIndex].numimmed ;get the # of image for the calculation of the PSF reference (user defined)

  dr=5
  rmin=0
  ;nombre de points radiaux
  rmin+=dr/2
  nrad=ceil((dimcub/2.-rmin)/dr)
  rall=findgen(nrad)*dr+rmin
  
  ;array des distances
  distarr=shift(dist(dimcub),dimcub/2,dimcub/2)

  tim=systime(1)
  timsub=systime(1)
  ;loop on images to do the PSF subtraction
    for n=0,dataset.validframecount-1 do begin
       ;;get the filenames of sc. data
    ;  fn=*((dataset.frames)[n])
      ;;get the datacube filename
    ;  fn=Modules[0].OutputDir+path_sep()+strmid(fn,1+strpos(fn,path_sep(),/REVERSE_SEARCH ),STRPOS(fn,'.fits')-strpos(fn,path_sep(),/REVERSE_SEARCH )-1)+suffix+'.fits'
      fn=dataset.outputFileNames[n]
    ;  imt=readfits(fn,header,/silent)
      imt=accumulate_getimage( dataset, n)

      
      ;we want ADI for datacubes, i.e. several specral channels but also for 
      ;other type of data: collapsed datacubes, single spectral channel ADI, ADI after SDI,etc...
      ; so we have to verify the dimension of ADI inputs hereafter:
      szinput=size(imt)
      if (szinput[0] eq 2) then lambda=(lambdamax+lambdamax)/2.
  
      if (szinput[0] eq 2) then im=dblarr(szinput[1], szinput[2]) $
                            else im=dblarr(szinput[1], szinput[2], szinput[3])
      
        ;loop on wavelength
      for il=0, n_elements(lambda)-1 do begin
        nfwhm=Modules[thisModuleIndex].nfwhm ;get the user-defined minimal distance for the subtraction
        Dtel=double(backbone->get_keyword( 'TELDIAM'))
		if dtel eq -1 then return, error('FAILURE ('+functionName+'): missing TELDIAM keyword')

        fwhm=1.03*(1.e-6*lambda[il]/Dtel)*(180.*3600./!dpi)/0.014 

        im1=imt[*,*,il]

        ;frame that will contain the difference
        im1s=fltarr(dimcub,dimcub,/nozero)+!values.f_nan

        ;loop on annulus
        for ir=0,nrad-1 do begin
            r=rall[ir] & ri=r-dr/2. & rf=r+dr/2.
            if silent eq 0 then print,'frame#'+strc(n+1)+'(/'+strc(dataset.validframecount)+')'+' Wavelength(um)='+strc(lambda(il),format='(f5.2)')+' Annulus with radius '+string(r,format='(f5.1)')+$
              ' [>='+string(ri,format='(f5.1)')+', <'+string(rf,format='(f5.1)')+']'

            ;indices of all pixels included in this annulus
            ia=where(distarr lt ((r+dr/2.)<dimcub/2) and distarr ge r-dr/2.,count)
            if (count eq 0) then break

            ;user-defined minimal angular separation
            theta0=(nfwhm*fwhm)/r*180.d/!dpi ;en degres

            ;selection of images for the calculation of the median PSF ref.
            padiff=abs(paall[*]-paall[n])
            ind=where(padiff gt theta0,ci)
            ;check if images are sufficiently shifted ;determine images suffisament decalees pour la soustraction
            if ci eq 0  then begin
              im1s[ia]=!values.f_nan
            endif else begin
              ind=ind[sort(padiff[ind])]
              if n_elements(ind) ne 1 then $
              ind=ind[0:(n_elements(ind)-1)<(nimmed-1)]

              if silent eq 0 then print,'  selected images for the calculation of the median PSF ref.: ',(dataset.outputFileNames)[ind] ;fn ;strjoin(strtrim(*((dataset.frames)[(ind)]),2),',')
              if silent eq 0 then print,'  Read these images...'
              ;keep only this annulus for all images to be processed in the PSF ref. calculation
              im2=dblarr(count,n_elements(ind),/nozero)
              for i=0,n_elements(ind)-1 do begin 
                ;im2[*,i]=(readfits(Modules[0].OutputDir+path_sep()+strmid(*((dataset.frames)[(ind[i])]),1+strpos(*((dataset.frames)[(ind[i])]),path_sep(),/REVERSE_SEARCH ),STRPOS(*((dataset.frames)[(ind[i])]),'.fits')-strpos(*((dataset.frames)[(ind[i])]),path_sep(),/REVERSE_SEARCH )-1)+suffix+'.fits',NSLICE=il,/silent))[ia]
                ;im2[*,i]=(readfits(dataset.outputFileNames[(ind[i])],/silent))[ia]
                im2[*,i]=((accumulate_getimage( dataset, (ind[i])))[*,*,il])[ia]
              endfor

              if silent eq 0 then print,'  Calculation of the median PSF ref...'
              if n_elements(ind) gt 1 then $
              im2=median(im2,dimension=2,/even)

              ;time to do the subtraction
              if silent eq 0 then print,'  Subtract...'
              im1s[ia]=im1[ia]-im2
            endelse; ci ne 0
          endfor ;loop annulus

          ;rotation to have same orientation than the first image
          if silent eq 0 then print,' Rotation to have same orientation than the first image...'
          theta=-(paall[n]-paall[0])
           x0=double(backbone->get_keyword('PSFCENTX',count=ccx,/silent)) ;float(SXPAR( *(dataset.headers[n]), 'PSFCENTX',count=ccx))
            y0=double(backbone->get_keyword('PSFCENTY',count=ccy,/silent)) ;float(SXPAR( *(dataset.headers[n]), 'PSFCENTY',count=ccy))

          hdr=*(dataset.headersExt[n]) ;JM 2010-03-19
		  if ((ccx eq 0) || (ccy eq 0) || ~finite(x0) || ~finite(y0))  then begin           
              if n ne 0 then im1s=gpi_adi_rotat(im1s,theta,missing=!values.f_nan,hdr=hdr) ;(do not rotate first image)
          endif else begin
              if n ne 0 then im1s=gpi_adi_rotat(im1s,theta,x0,y0,missing=!values.f_nan,hdr=hdr) ;(do not rotate first image)
          endelse  
            *(dataset.headersExt[n])=hdr
          im[*,*,il]=im1s
        endfor ;loop on lambda

    ;save the difference
      if tag_exist( Modules[thisModuleIndex], "suffix") then subsuffix=Modules[thisModuleIndex].suffix
    
    ;subsuffix='-adim'  ;this the suffix that will be added to the name of the ADI residual  
	  fname=strmid(fn,0,strpos(fn,suffix)-1)+suffix+subsuffix+'.fits'
	  ;header=*(dataset.headers[n])
;      sxaddhist,'One rotation of '+string(theta,format='(f7.3)')+$
;      ' degrees has been applied.',header
       backbone->set_keyword,'HISTORY','One rotation of '+string(theta,format='(f7.3)')+$
      ' degrees has been applied.',ext_num=1,indexFrame=n
        backbone->set_keyword,'ADIROTAT',strc(theta,format='(f7.3)'),"Applied ADI FOV derotation [degrees]",ext_num=1,indexFrame=n
      
      *(dataset.currframe[0])=im
     ; *(dataset.headers[n])=header

	  ; FIXME what is this next line for?? - MDP
	  ; JM: not really necessary, this is in case you use ADI with collapsed or sdi data; 
	  ;     in this case, ADI calculation is so fast that you don't have time to visualize ADI outputs with GPItv as it refresh frames too fast.
	  ;     Eventually, this waiting time should be implemented in gpitv and commented here.
	if timsub-systime(1) lt 3. then wait, 2.5
	timsub=systime(1)

    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix+subsuffix, display=display,level2=n+1)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
          Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
    endelse
    filename=fn
    ;update_progressbar,Modules,thisModuleIndex,Dataset.validframecount, n ,'working...',/adi    
    endfor ; loop on images

  print, 'proc time adim(s)=',-tim+systime(1)

  suffix=suffix+subsuffix

return, ok
end
