;+
; NAME: testspecklesupr001
; PIPELINE PRIMITIVE DESCRIPTION: Test the speckle suppression algorithms.
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
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2010-08-16
;- 

function testspecklesupr001, DataSet, Modules, Backbone
primitive_version= '$Id: testspecklesupr001.pro 11 2010-09-14 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive
mydevice = !D.NAME

COMPSPEC=sxpar(header,'COMPSPEC') 

;;get DST companion spectrum
;restore, 'E:\GPI\dst\'+strcompress(compspec,/rem)+'compspectrum.sav'
filter=SXPAR( header, 'FILTER')
case strcompress(filter,/REMOVE_ALL) of
  'Y':specresolution=35.
  'J':specresolution=37.
  'H':specresolution=45.
  'K1':specresolution=65.
  'K2':specresolution=75.
endcase

        ;get the common wavelength vector
            ;error handle if extractcube not used before
         cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]

dlam=((lambdamin+lambdamax)/2.)/specresolution
nlam=(lambdamax-lambdamin)/dlam
lambdalow= lambdamin+(lambdamax-lambdamin)*(findgen(floor(nlam))/floor(nlam))+0.5*(lambdamax-lambdamin)/floor(nlam)
print, 'delta_lambda [um]=', dlam, 'spectral resolution=',specresolution,'#canauxspectraux=',nlam,'vect lam=',lambdalow

repDST=getenv('GPI_IFS_DIR')+path_sep()+'dst'+path_sep()
case strcompress(compspec,/rem) of
'L1': begin
fileSpectra=repDST+'compspec'+path_sep()+'L1_2MASS0345+25.txt'
refmag=13.169 ;Stephens et al 2003
end
'L5':begin
fileSpectra=repDST+'compspec'+path_sep()+'L5_SDSS2249+00.txt'
refmag=15.366 ;Stephens et al 2003
end
'L8':begin
fileSpectra=repDST+'compspec'+path_sep()+'L8_SDSS0857+57.txt'
refmag=13.855 ;Stephens et al 2003
end
'M9V':begin
fileSpectra=repDST+'compspec'+path_sep()+'M9V_LP944-20.txt'
refmag=10.017 ;Cushing et al 2004
end
'T3':begin
fileSpectra=repDST+'compspec'+path_sep()+'T3_SDSS1415+57.txt'
refmag=16.09 ;Chiu et al 2006
end
'T7':begin
fileSpectra=repDST+'compspec'+path_sep()+'T7_Gl229B.txt'
refmag=14.35 ;Leggett et al 1999
end
'T8':begin
fileSpectra=repDST+'compspec'+path_sep()+'T8_2MASS0415-09.txt'
refmag=15.7 ; Knapp et al. 2004 AJ
end
'Flat':begin
fileSpectra=repDST+'compspec'+path_sep()+'Flat.txt'
refmag=15.7 ; arbitrary
end
endcase
readcol, fileSpectra[0], lamb, spec,/silent  


    cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect        
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]
dlam=((lambdamin+lambdamax)/2.)/specresolution
;is the sampling of this spectrum constant?
; fit the spec on a constant wav. sampling
bandloc = VALUE_LOCATE(Lamb, [lambdamin,lambdamax])
dlam0=lamb[bandloc[0]+1]-lamb[bandloc[0]]
extralam=VALUE_LOCATE(Lamb, [lambdamin])-VALUE_LOCATE(Lamb, [lambdamin-(lambda[1]-lambda[0])])
nbchannel=floor((lamb[bandloc[1]+extralam]-lamb[bandloc[0]-extralam])/dlam0)
lamb2= replicate(lamb[bandloc[0]-extralam],nbchannel)+(findgen(nbchannel))*replicate((lamb[bandloc[1]+extralam]-lamb[bandloc[0]-extralam])/float(nbchannel),nbchannel)
spec2=  resample(lamb[bandloc[0]-extralam:bandloc[1]+extralam], spec[bandloc[0]-extralam:bandloc[1]+extralam],lamb2)

fwhmloc = VALUE_LOCATE(Lamb2, [(lambda[0]),(lambda[0]+dlam)])
fwhm=float(fwhmloc[1]-fwhmloc[0])
print, 'fwhm=',fwhm
gaus = PSF_GAUSSIAN( Npixel=3*fwhm, FWHM=fwhm, NDIMEN =1, /NORMAL )
;bandloc2=VALUE_LOCATE(Lamb2, [lambdamin,lambdamax])
LowSpec = CONVOL( (reform(Spec2)), gaus , /EDGE_TRUNCATE ) 

  LowResolutionSpec=fltarr(n_elements(lambda))
  widthL=(lambda[1]-lambda[0])
  for i=0,n_elements(lambda)-1 do begin
    dummy = VALUE_LOCATE(Lamb2, [lambda(i)-widthL/2.])
    dummy2 = VALUE_LOCATE(Lamb2, [lambda(i)+widthL/2.])
    if dummy eq dummy2 then LowResolutionSpec[i] = lowSpec(dummy) else $
    LowResolutionSpec[i] = (1./((Lamb2(dummy+1)-Lamb2(dummy))*(dummy2-dummy)))*INT_TABULATED(Lamb2(dummy:dummy2),LowSpec(dummy:dummy2),/DOUBLE)
  endfor

;;get info about simulated companions
val=sxpar( *(dataset.headers[0]),"PAR_ANG",count=ck)
if ck eq 1 then parangle=float(val)
script=SXPAR( header, 'DSTSCRIP',count=cscr)
          nbcomp=0
          compangsep=fltarr(100) & compangrot=fltarr(100) & compmagh=fltarr(100)
if cscr gt 0 then begin
system_file=getenv('GPI_IFS_DIR')+path_sep()+'dst'+path_sep()+script;'system_script3.idl'
  if ~file_test(system_file) then message, "That file "+system_file+" does not exist!"
          tfile = rd_tfile(system_file)
          message,/info, "now reading script file "+system_file

          
          for line=0L,n_elements(tfile)-1 do begin
            if strmatch(tfile[line],'*comp_angsep*') then begin
              print, "   >> "+tfile[line]
              res = execute(tfile[line])
              compangsep[nbcomp]=comp_angsep & compangrot[nbcomp]=comp_rot & compmagh[nbcomp]=comp_mag
              nbcomp+=1
            endif
          endfor
endif
;;add main comp
val=sxpar( *(dataset.headers[0]),"COMPSEP",count=ck)
if ck eq 1 then compangsep[nbcomp]=float(val)
val=sxpar( *(dataset.headers[0]),"COMPROT",count=ck)
 if ck eq 1 then compangrot[nbcomp]=float(val)
 val=sxpar( *(dataset.headers[0]),"COMPMAG",count=ck)
 if ck eq 1 then compmagh[nbcomp]=float(val)
 nbcomp+=1
;;calculate locations of comp
          psfcentx=sxpar( *(dataset.headers[0]),"PSFCENTX")
          psfcenty=sxpar( *(dataset.headers[0]),"PSFCENTY") 
          loc_comp=fltarr(nbcomp,2) 
          ;assume platescale=0.014"  
          platescale=0.0145
for ii=0,nbcomp-1 do begin
  loc_comp[ii,0]=psfcentx+(compangsep[ii]/platescale)*sin((!dpi/180.)*(compangrot[ii]-parangle))+2.
  loc_comp[ii,1]=psfcenty-(compangsep[ii]/platescale)*cos((!dpi/180.)*(compangrot[ii]-parangle))
  print, "companion"+strc(ii)+"   >> at x=",loc_comp[ii,0],'  y=',loc_comp[ii,1]
  
         band=strcompress(sxpar( *(dataset.headers[0]), 'FILTER',  COUNT=cc),/rem)
        if cc eq 1 then begin
          cwv=get_cwv(band)
          CommonWavVect=cwv.CommonWavVect
          lambda=cwv.lambda
          lambdamin=CommonWavVect[0]
          lambdamax=CommonWavVect[1]
          NLam=CommonWavVect[2]
         endif else begin
          print, "No filter keyword was found, band undetermined!"
         endelse
  
  ;;;;photometric measurement of the comp
    cubcent2=*(dataset.currframe[0])
    
    ;;set photometric aperture and parameters
    phpadu = 1.0                    ; don't convert counts to electrons
    radi=4.5 & apr = (1./2.)*lambda[0]*float(radi)
    skyrad = (1./2.)*lambda[0]*[float(radi),float(radi)+2.] 
    if (skyrad[1]-skyrad[0] lt 2.) then skyrad[1]=skyrad[0]+2.
    ; Assume that all pixel values are good data
    badpix = [-1.,1e6];state.image_min-1, state.image_max+1
    hh=3.
    ;;do the photometry of the companion
    phot_comp=fltarr(CommonWavVect[2])+!VALUES.F_NAN 
    rsb=fltarr(CommonWavVect[2])+!VALUES.F_NAN 
    errsky=fltarr(CommonWavVect[2])+!VALUES.F_NAN 

    while (total(~finite(phot_comp)) ne 0) && (skyrad[1]-skyrad[0] lt 20.) do begin
      for i=0,CommonWavVect[2]-1 do begin
                ;;extrapolate sat -spot at a given wavelength          
          cent=centroid(cubcent2[loc_comp[ii,0]-hh:loc_comp[ii,0]+hh,loc_comp[ii,1]-hh:loc_comp[ii,1]+hh,i])
            x=loc_comp[ii,0]+cent[0]-hh
            y=loc_comp[ii,1]+cent[1]-hh
          aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, (lambda[i]/lambda[0])*apr, $
            (lambda[i]/lambda[0])*skyrad, badpix, /flux, /silent ;, flux=abs(state.magunits-1)
            if i eq 0 then print, 'slice#',i,' flux comp #'+'=',flux[0],'at positions ['+strc(x)+','+strc(y)+']',' sky=',sky[0]
          phot_comp[i]=(flux[0])
          rsb[i]=(errap/skyerr)^2.
          errsky[i]=skyerr
      endfor
      skyrad[1]+=1.
    endwhile
   
lambdaspec=lambda
;espe=extr[*,2]
COMPMAG=compmagh[ii]

theospectrum=(10.^(-(compmag-refmag)/2.5))*LowResolutionSpec
print, 'theo comp. spec=',theospectrum
ewav=lambda
espe=phot_comp 


truitime=float(sxpar(header,'TRUITIME'))
starmag=double(SXPAR( header, 'Hmag'))
;;;PLOT RESULTS
;;prepare the plot
maxvalue=max([(10.^(-(compmag-refmag)/2.5))*LowResolutionSpec,espe])
expo=floor(abs(alog10(maxvalue))+1.)
factorexpo=10.^expo 
thisLetter = "155B
greekLetter = '!9' + String(thisLetter) + '!X'
print, greekLetter
units=' W/m^2/'+greekLetter+'m'
title=strcompress(SXPAR( header, 'SPECTYPE'),/rem)+' star, Exposure='+strcompress(string(sxpar(header,'EXPTIME')),/rem)+'s, '+Modules[thisModuleIndex].title
if ii gt 0 then numcomp='comp'+strc(floor(ii)) else numcomp=''
s_Ext='-comp_x'+strc(floor(x))+'_y'+strc(floor(y))+numcomp
filnm=sxpar(*(DataSet.Headers[0]),'DATAFILE')
filnm=dataset.FileNames[numfile]
if (size(suffix))[1] eq 0 then suffix=''
     slash=strpos(filnm,path_sep(),/reverse_search)
     ;psFilename = Modules[thisModuleIndex].OutputDir+'fig'+path_sep()+strmid(filnm, slash,strlen(filnm)-5-slash)+s_Ext+'.ps'
      psFilename = Modules[thisModuleIndex].OutputDir+'fig'+path_sep()+strmid(filnm, 0,strlen(filnm)-5)+suffix+s_Ext+'.ps'
   
    if total(finite(espe)) gt 30 then begin
    openps,psFilename, xsize=17, ysize=27 ;, ysize=10, xsize=15
      !P.MULTI = [0, 1, 3, 0, 0] 
    units=TeXtoIDL(" W/m^{2}/\mum")
    deltaH=TeXtoIDL(" \Delta H=")
    print, 'units=',units
    expostr = TeXtoIDL(" 10^{-"+strc(expo)+"}")
    plot, ewav, factorexpo*espe,ytitle='Flux density ['+expostr+units+']', xtitle='Wavelength (' + greekLetter + 'm)',$
     xrange=[ewav[0],ewav[n_elements(ewav)-1]],yrange=[0,10.],psym=1, charsize=1.5, title=title 
    ;oplot, lambda,(2.55^(3.09))*30.*lowresolutionspec,linestyle=1
    oplot, lambda,factorexpo*theospectrum,linestyle=0
    legend,['measured companion spectrum','input '+strcompress(compspec,/rem)+' spectrum, H='+strc(compmag)+deltaH+strc(compmag-starmag)],psym=[1,-0]
    
    plot,ewav,(espe-theospectrum),ytitle='Difference of Flux density ['+units+'] (meas.-theo.)', xtitle='Wavelength (' + greekLetter + 'm)', $
    xrange=[ewav[0],ewav[n_elements(ewav)-1]],psym=-1, charsize=1.5 
    plot,ewav, 100.*abs(espe-theospectrum)/theospectrum,ytitle='Abs. relative Diff. of Flux density [%] (abs(meas.-theo.)/theo)', xtitle='Wavelength (' + greekLetter + 'm)',$
     xrange=[ewav[0],ewav[n_elements(ewav)-1]],yrange=[0,100.],psym=-1, charsize=1.5 
     indfini=where(finite(espe))
    xyouts, ewav[2],70.,'mean error='+strc(mean(100.*abs(espe[indfini]-theospectrum[indfini])/theospectrum[indfini]), format='(f5.2)')+' %'
    closeps
    set_plot,'win'
    endif
 ;;;now, look at the SNR in the initial datacube
  filnm=sxpar(*(DataSet.Headers[numfile]),'DATAFILE')
  ;filnm+='I.fits' ;until DATAFILE problem of length in header is fixed
  ;slash=strpos(filnm,'phot',/reverse_search)
       slash=strpos(filnm,path_sep(),/reverse_search)
     filnm00 = strmid(filnm, slash+1,strlen(filnm)-1)  
  filnm0=strmid(filnm00, 0,strlen(filnm00)-5)+suffix
  slash=strpos(filnm0,'-phot')
  filnm2=strmid(filnm0, 0,slash+5)+'.fits'
  print, 'opening initial cube:', filnm2
  im=readfits(Modules[thisModuleIndex].OutputDir+path_sep()+filnm2)
;      ;;do the photometry of the companion in the initial datacube
;          apr = (1./2.)*lambda[0]*float(radi)
;    skyrad = (1./2.)*lambda[0]*[float(radi),float(radi)+2.] 
;    if (skyrad[1]-skyrad[0] lt 2.) then skyrad[1]=skyrad[0]+2.
;      
;    phot_compini=fltarr(CommonWavVect[2])+!VALUES.F_NAN 
;    rsbini=fltarr(CommonWavVect[2])+!VALUES.F_NAN 
;    errskyini=fltarr(CommonWavVect[2])+!VALUES.F_NAN 
;
;    while (total(~finite(phot_compini)) ne 0) && (skyrad[1]-skyrad[0] lt 20.) do begin
;      for i=0,CommonWavVect[2]-1 do begin
;                ;;extrapolate sat -spot at a given wavelength          
;          cent=centroid(im[loc_comp[ii,0]-hh:loc_comp[ii,0]+hh,loc_comp[ii,1]-hh:loc_comp[ii,1]+hh,i])
;            x=loc_comp[ii,0]+cent[0]-hh
;            y=loc_comp[ii,1]+cent[1]-hh
;          aper, im[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, (lambda[i]/lambda[0])*apr, $
;            (lambda[i]/lambda[0])*skyrad, badpix, /flux, /silent ;, flux=abs(state.magunits-1)
;            if i eq 0 then print, 'slice#',i,' flux comp #'+'=',flux[0],'at positions ['+strc(x)+','+strc(y)+']',' sky=',sky[0]
;          phot_compini[i]=(flux[0])
;          rsbini[i]=(errap/skyerr)^2.
;          errskyini[i]=skyerr
;      endfor
;      skyrad[1]+=1.
;    endwhile
;        psFilenameSNR =Modules[thisModuleIndex].OutputDir+'fig'+path_sep()+strmid(filnm, slash,strlen(filnm)-5-slash)+s_Ext+'SNR.ps'
;        stop
;if ii eq 10 then stop   
;if total(finite(rsb/rsbini)) gt 30 then begin 
;    openps,psFilenameSNR, xsize=17, ysize=27 ;, ysize=10, xsize=15
;      !P.MULTI = [0, 1, 3, 0, 0] 
;    units=TeXtoIDL(" W/m^{2}/\mum")
;    deltaH=TeXtoIDL(" \Delta H=")
;
;    plot, ewav, rsb/rsbini,ytitle='SNR ratio LOCI/datacube', xtitle='Wavelength (' + greekLetter + 'm)';,$
;    ; xrange=[ewav[0],ewav[n_elements(ewav)-1]],yrange=[0,10.],psym=1, charsize=1.5, title=title
;    legend,['SNR ratio (before/after) speckle suppr. at '+strc(compangsep[ii],format='(g4.2)')+'", angle='+strc(compangsep[ii],format='(g4.2)')],psym=[1]
;     
;    plot, ewav, errskyini/errsky,ytitle='Sky ratio (original/loci)', xtitle='Wavelength (' + greekLetter + 'm)'
;    legend,['Sky ratio (original/loci)'],linestyle=1
; 
;     closeps
;  set_plot,'win'
;  endif
endfor

;;;now calculate the rms noise near the first companion both in the datacube and ADI reduced output
dcomp=15
hh=30
stddevnoiseini=fltarr(CommonWavVect[2])
stddevnoise=fltarr(CommonWavVect[2])
attenuation=fltarr(CommonWavVect[2])
     for i=0,CommonWavVect[2]-1 do begin 
          stddevnoiseini[i]=stddev(im[loc_comp[nbcomp-1,0]+dcomp:loc_comp[nbcomp-1,0]+dcomp+hh,loc_comp[nbcomp-1,1]-dcomp:loc_comp[nbcomp-1,1]-dcomp+hh,i],/Nan)
          stddevnoise[i]=stddev(cubcent2[loc_comp[nbcomp-1,0]+dcomp:loc_comp[nbcomp-1,0]+dcomp+hh,loc_comp[nbcomp-1,1]-dcomp:loc_comp[nbcomp-1,1]-dcomp+hh,i],/Nan)
          attenuation[i]=stddevnoiseini[i]/stddevnoise[i]
     endfor
 ;stop    
     slash=strpos(filnm,path_sep(),/reverse_search)
     s_Ext='-atten_x'+strc(floor(loc_comp[0,0]))+'_y'+strc(floor(loc_comp[0,1]))
     if strmatch(filnm,'.fits') then filnm=strmid(filnm, slash,strlen(filnm)-5-slash) else filnm=strmid(filnm, slash,strlen(filnm)-slash)
psFilenameSNR =Modules[thisModuleIndex].OutputDir+'fig'+path_sep()+filnm+suffix+s_Ext+'ATTEN.ps'
print, 'ps file:',psFilenameSNR
   openps,psFilenameSNR, xsize=17, ysize=27 ;, ysize=10, xsize=15
      !P.MULTI = [0, 1, 3, 0, 0] 
    plot, ewav, attenuation,ytitle='Attenuation: rms noise ratio LOCI/datacube', xtitle='Wavelength (' + greekLetter + 'm)';,$
    ; xrange=[ewav[0],ewav[n_elements(ewav)-1]],yrange=[0,10.],psym=1, charsize=1.5, title=title
    legend,['Attenuation: rms noise ratio ADI/datacube at '+strc(compangsep[0],format='(g4.2)')+'", angle='+strc(compangsep[0],format='(g4.2)')],psym=[1]
    closeps
  set_plot,'win'

;;;; Attenuation vs radius
dimcub=(size(im))[1]
distarray=shift(dist(dimcub),dimcub/2,dimcub/2)
    drim=2.
    rmin=0.
    rimmax=1.2*dimcub/2
    nrim=ceil((rimmax-rmin)/drim)
    rim=findgen(nrim)*drim+rmin
stddevnoiseinir=fltarr(nrim,CommonWavVect[2])
stddevnoiser=fltarr(nrim,CommonWavVect[2])
attenuationr=fltarr(nrim,CommonWavVect[2])
    ;get indices of pixels included in each annulus 
    for ir=0,nrim-1 do begin
      ri=rim[ir] & rf=ri+drim
      ia=where(distarray lt rf and distarray ge ri)
      for i=0,CommonWavVect[2]-1 do begin
        im1=im[*,*,i]
        im2=median(im1,7)
        cubcent1=cubcent2[*,*,i] 
        if (total(finite(cubcent1[ia])) lt 3) || (total(finite(im2[ia])) lt 3) then continue
          stddevnoiseinir[ir,i]=stddev(im2[ia],/Nan)
          stddevnoiser[ir,i]=stddev(cubcent1[ia],/Nan)
          attenuationr[ir,i]=stddevnoiseinir[ir,i]/stddevnoiser[ir,i] 
       endfor   
    endfor
 ;   stop
attenuationr7=attenuationr[*,7]
attenuationrmoy=median(attenuationr, dimension=2)
print, 'Atten vs rad (moy sur lambda)=',attenuationrmoy
psFilenameSNR2 =Modules[thisModuleIndex].OutputDir+'fig'+path_sep()+filnm+suffix+s_Ext+'ATTEN2.ps'
 openps,psFilenameSNR2, xsize=17, ysize=27 ;, ysize=10, xsize=15
      !P.MULTI = [0, 1, 3, 0, 0] 
    plot, rim, attenuationr7,ytitle='Attenuation', xtitle='radius [pixel]';,$
    plot, rim, attenuationrmoy,linestyle=2
    ; xrange=[ewav[0],ewav[n_elements(ewav)-1]],yrange=[0,10.],psym=1, charsize=1.5, title=title
    legend,['Attenuation: slice#7','Att. median (over wav.)'],linestyle=[0,2]
    closeps
   SET_PLOT, mydevice ;set_plot,'win'
return, ok
 end