;+
; NAME: testspecklesuprpolar001
; PIPELINE PRIMITIVE DESCRIPTION: Test the speckle suppression algorithms of dual-channel polarimetry.
;
; INPUTS: 
;
;
; KEYWORDS:
; 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Test the speckle suppression algorithms.
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-photom" Desc="Enter suffix of figure name"
; PIPELINE ARGUMENT: Name="title" Type="string" Default="" Desc="Enter figure title"
; PIPELINE ORDER: 2.52
; PIPELINE TYPE: ALL-SPEC 
; PIPELINE NEWTYPE: Testing
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2010-08-16
;- 

function testspecklesuprpolar001, DataSet, Modules, Backbone
primitive_version= '$Id: testspecklesuprpolar001.pro 11 2010-09-14 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive
mydevice = !D.NAME

;COMPSPEC=sxpar(header,'COMPSPEC') 

;;get DST companion spectrum
;restore, 'E:\GPI\dst\'+strcompress(compspec,/rem)+'compspectrum.sav'
;filter=SXPAR( header, 'FILTER')
;case strcompress(filter,/REMOVE_ALL) of
;  'Y':specresolution=35.
;  'J':specresolution=37.
;  'H':specresolution=45.
;  'K1':specresolution=65.
;  'K2':specresolution=75.
;endcase

        ;get the common wavelength vector
            ;error handle if extractcube not used before
;         cwv=get_cwv(filter)
;        CommonWavVect=cwv.CommonWavVect
;        lambda=cwv.lambda
;        lambdamin=CommonWavVect[0]
;        lambdamax=CommonWavVect[1]

;;photometry of the comp
 cubcent2=*(dataset.currframe[0])
;if (size(cubcent2))[0] eq 3 then begin

;;;now calculate the rms noise near the first companion both in the datacube and ADI reduced output
 ;;;now, look at the SNR in the initial datacube
  filnm=sxpar(*(DataSet.HeadersPHU[numfile]),'DATAFILE')
  ;filnm+='I.fits' ;until DATAFILE problem of length in header is fixed
  ;slash=strpos(filnm,'phot',/reverse_search)
;       slash=strpos(filnm,path_sep(),/reverse_search)
  filnm0=strmid(filnm, 0,strlen(filnm)-5)+suffix
   slash=strpos(filnm0,'-stokesdc')
  filnm2=strmid(filnm0, 0,slash)+'-podc.fits'
  print, 'opening initial cube:', filnm2
  fits_info,Modules[thisModuleIndex].OutputDir+path_sep()+filnm2,n_ext=n_ext
  im=mrdfits(Modules[thisModuleIndex].OutputDir+path_sep()+filnm2,n_ext)

  nbcomp=1
dcomp=15
hh=30
;stddevnoiseini=fltarr(CommonWavVect[2])
;stddevnoise=fltarr(CommonWavVect[2])
;attenuation=fltarr(CommonWavVect[2])
;     for i=0,CommonWavVect[2]-1 do begin 
;          stddevnoiseini[i]=stddev(im[loc_comp[nbcomp-1,0]+dcomp:loc_comp[nbcomp-1,0]+dcomp+hh,loc_comp[nbcomp-1,1]-dcomp:loc_comp[nbcomp-1,1]-dcomp+hh,i],/Nan)
;          stddevnoise[i]=stddev(cubcent2[loc_comp[nbcomp-1,0]+dcomp:loc_comp[nbcomp-1,0]+dcomp+hh,loc_comp[nbcomp-1,1]-dcomp:loc_comp[nbcomp-1,1]-dcomp+hh,i],/Nan)
;          attenuation[i]=stddevnoiseini[i]/stddevnoise[i]
;     endfor
; ;stop    
;     slash=strpos(filnm,path_sep(),/reverse_search)
;     s_Ext='-atten_x'+strc(floor(loc_comp[0,0]))+'_y'+strc(floor(loc_comp[0,1]))
;     if strmatch(filnm,'.fits') then filnm=strmid(filnm, slash,strlen(filnm)-5-slash) else filnm=strmid(filnm, slash,strlen(filnm)-slash)
;psFilenameSNR =Modules[thisModuleIndex].OutputDir+filnm+suffix+s_Ext+'ATTEN.ps'
;print, 'ps file:',psFilenameSNR
;   openps,psFilenameSNR, xsize=17, ysize=27 ;, ysize=10, xsize=15
;      !P.MULTI = [0, 1, 3, 0, 0] 
;    plot, ewav, attenuation,ytitle='Attenuation: rms noise ratio LOCI/datacube', xtitle='Wavelength (' + greekLetter + 'm)';,$
;    ; xrange=[ewav[0],ewav[n_elements(ewav)-1]],yrange=[0,10.],psym=1, charsize=1.5, title=title
;    legend,['Attenuation: rms noise ratio ADI/datacube at '+strc(compangsep[0],format='(g4.2)')+'", angle='+strc(compangsep[0],format='(g4.2)')],psym=[1]
;    closeps
; SET_PLOT, mydevice; set_plot,'win'
;stop
;;;; Attenuation vs radius
slice=0
        im1=im[*,*,slice]
        im2=im1;median(im1,7)
        ;total intensity [sum of e- and o- images]:
        imtot=im[*,*,0]+im[*,*,1]
         ;;cubes must have same dimensions:
        szim=size(im2)
;        if (szim[1] mod 2) then begin
;          im2=im2[0:szim[1]-2,0:szim[2]-2]
;        endif 
dimcub=(size(im2))[1]
distarray=shift(dist(dimcub),dimcub/2,dimcub/2)
  ;array des angles
  ang=(angarr(dimcub)+2.*!pi) mod (2.*!pi)
  
    drim=2.
    rmin=0.
    rimmax=1.2*dimcub/2
    nrim=ceil((rimmax-rmin)/drim)
    rim=findgen(nrim)*drim+rmin
stddevnoiseinir=fltarr(nrim)
stddevnoiser=fltarr(nrim)
attenuationr=fltarr(nrim)

stddevnoiseinir_alt=fltarr(nrim)
stddevnoiser_alt=fltarr(nrim)
attenuationr_alt=fltarr(nrim)

    ;get indices of pixels included in each annulus 
    for ir=0,nrim-1 do begin
      ri=rim[ir] & rf=ri+drim
      ia=where(distarray lt rf and distarray ge ri and ang lt (!dpi/6.) and ang ge 0.)
     ; for i=0,CommonWavVect[2]-1 do begin
     
        cubcent1=cubcent2[*,*,1] ;test Stokes Q 
        cubcent1_alt=sqrt(cubcent2[*,*,1]^2. + cubcent2[*,*,2]^2. + cubcent2[*,*,3]^2.) ;test polarized intensity sqrt(Q^2 + U^2 + V^2) 
        if (n_elements(ia) eq 1) || (total(finite(cubcent1[ia])) lt 3) || (total(finite(im2[ia])) lt 3) then continue
          stddevnoiseinir[ir]=stddev(im2[ia],/Nan)
          stddevnoiser[ir]=stddev(cubcent1[ia],/Nan)
          attenuationr[ir]=stddevnoiseinir[ir]/stddevnoiser[ir] 
          ;alternative2:
           stddevnoiseinir_alt[ir]=stddev(imtot[ia],/Nan)
          stddevnoiser_alt[ir]=stddev(cubcent1_alt[ia],/Nan)
          attenuationr_alt[ir]=stddevnoiseinir_alt[ir]/stddevnoiser_alt[ir]
      ; endfor   
    endfor
  ;stop
attenuationr7=attenuationr  ;[*,7]
;attenuationrmoy=median(attenuationr, dimension=2)
;print, 'Atten vs rad (moy sur lambda)=',attenuationrmoy
 slash=strpos(filnm,path_sep(),/reverse_search)
 if strmatch(filnm,'.fits') then filnm=strmid(filnm, slash+1,strlen(filnm)-5-slash) else filnm=strmid(filnm, slash+1,strlen(filnm)-slash)
psFilenameSNR2 =Modules[thisModuleIndex].OutputDir+'test12_'+filnm+suffix+'POLATTEN.ps'
 openps,psFilenameSNR2, xsize=17, ysize=27 ;, ysize=10, xsize=15
      !P.MULTI = [0, 1, 2, 0, 0] 
    plot, rim, attenuationr7,ytitle='Attenuation', xtitle='radius [pixel]',xrange=[0.,140.], ylog=1,yrange=[1.e0,1.2*max(attenuationr7)];,$
    oplot, rim, replicate(5., n_elements(rim)),linestyle=2
    ; xrange=[ewav[0],ewav[n_elements(ewav)-1]],yrange=[0,10.],psym=1, charsize=1.5, title=title
    ;legend,['Attenuation: slice#7','Att. median (over wav.)'],linestyle=[0,2]
    legend,['(rms of e- polarization image) / (rms of Q image)','Requirements Att=5'],linestyle=[0,2]
    closeps
    ;plot alternative 2
    psFilenameSNR2 =Modules[thisModuleIndex].OutputDir+'test12_'+filnm+suffix+'POLATTEN2.ps'
 openps,psFilenameSNR2, xsize=17, ysize=27 ;, ysize=10, xsize=15
      !P.MULTI = [0, 1, 2, 0, 0] 
    plot, rim, attenuationr_alt,ytitle='Attenuation', xtitle='radius [pixel]',xrange=[0.,140.], ylog=1,yrange=[1.e0,1.2*max(attenuationr7)];,$
    oplot, rim, replicate(5., n_elements(rim)),linestyle=2
    ; xrange=[ewav[0],ewav[n_elements(ewav)-1]],yrange=[0,10.],psym=1, charsize=1.5, title=title
    ;legend,['Attenuation: slice#7','Att. median (over wav.)'],linestyle=[0,2]
    legend,['(rms of total intensity [sum of e- and o- images]) / (rms of polarized intensity)','Requirements Att=5'],linestyle=[0,2]
    closeps
   SET_PLOT, mydevice ;set_plot,'win'
return, ok
 end
