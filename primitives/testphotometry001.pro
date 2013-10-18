;+
; NAME: testphotometry001
; PIPELINE PRIMITIVE DESCRIPTION: Test the photometric calibration 
;
; INPUTS: 
;
;
; KEYWORDS:
; 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Test the photometry calibration by comparing extracted companion spectrum with DST initial spectrum.
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-photom" Desc="Enter suffix of figure name"
; PIPELINE ARGUMENT: Name="title" Type="string" Default="" Desc="Enter figure title"
; PIPELINE ORDER: 2.52
; PIPELINE NEWTYPE: Testing
;
; HISTORY:
;   Jerome Maire 2010-08-16
;   2013-08-07 ds: idl2 compiler compatible 
;- 

function testphotometry001, DataSet, Modules, Backbone
primitive_version= '$Id: testphotometry001.pro 11 2010-08-16 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive
mydevice = !D.NAME


;;get last  measured companion spectrum
compspecname=DataSet.OutputFilenames[numfile]
compspecnamewoext=strmid(compspecname,0,strlen(compspecname)-5)
res=file_search(compspecnamewoext+'*spec*fits')
;if numext eq 0 then begin
;  extr=readfits(res[0],hdrextr) 
;endif else begin
;  extr= mrdfits(res[0], 1, hdr)
;  hdrextr= headfits(res[0], exten=0)
;endelse
extr= gpi_readfits(res[0],header=hdrextr)

lambdaspec=extr[*,0]
;espe=extr[*,2]
COMPMAG=float(sxpar(*(dataset.headersPHU[numfile]),'COMPMAG'))
COMPSPEC=sxpar(*(dataset.headersPHU[numfile]),'COMPSPEC') ;we could have compsep&comprot

;;get DST companion spectrum
;restore, 'E:\GPI\dst\'+strcompress(compspec,/rem)+'compspectrum.sav'
         
        filter = gpi_simplify_keyword_value(strcompress(sxpar( *(dataset.headersPHU[numfile]) ,'IFSFILT', count=fcount),/REMOVE_ALL))
        ;if fcount eq 0 then filter = strcompress(sxpar( hdrextr ,'FILTER', count=fcount),/REMOVE_ALL)
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

repDST=gpi_get_directory('GPI_DST_DIR')
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
;spec2=  resample(lamb[bandloc[0]-extralam:bandloc[1]+extralam], lamb[bandloc[0]-extralam:bandloc[1]+extralam]*spec[bandloc[0]-extralam:bandloc[1]+extralam],lamb2)
spec2=  resample(lamb[bandloc[0]-extralam:bandloc[1]+extralam], spec[bandloc[0]-extralam:bandloc[1]+extralam],lamb2)



fwhmloc = VALUE_LOCATE(Lamb2, [(lambda[0]),(lambda[0]+dlam)])
fwhm=float(fwhmloc[1]-fwhmloc[0])
print, 'fwhm=',fwhm
gaus = PSF_GAUSSIAN( Npixel=3*fwhm, FWHM=fwhm, NDIMEN =1, /NORMAL )
;bandloc2=VALUE_LOCATE(Lamb2, [lambdamin,lambdamax])
LowSpec = CONVOL( (reform(Spec2)), gaus , /EDGE_TRUNCATE ) 




;nlambdapsf=37.
;lambdapsf=fltarr(nlambdapsf)
;
; ; for i=0,n_elements(lambdapsf)-1 do lambdapsf[i]=lambda[0]+(lambda[nlambdapsf-1]-lambda[0])/(2.*nlambdapsf)+double(i)*(lambda[nlambdapsf-1]-lambda[0])/nlambdapsf
;for i=0,n_elements(lambdapsf)-1 do lambdapsf[i]=lambdamin+double(i)*(lambdamax-lambdamin)/nlambdapsf

  LowResolutionSpec=fltarr(n_elements(lambda))
  widthL=(lambda[1]-lambda[0])
  for i=0,n_elements(lambda)-1 do begin
    dummy = VALUE_LOCATE(Lamb2, [lambda[i]-widthL/2.])
    dummy2 = VALUE_LOCATE(Lamb2, [lambda[i]+widthL/2.])
    if dummy eq dummy2 then LowResolutionSpec[i] = lowSpec[dummy] else $
       LowResolutionSpec[i] = (1./((Lamb2[dummy+1]-Lamb2[dummy])*(dummy2-dummy)))*INT_TABULATED(Lamb2[dummy:dummy2],LowSpec[dummy:dummy2],/DOUBLE)
  endfor


;smooth to the resolution of the spectrograph:
;verylowspec=changeres(LowResolutionSpec, lambda,lambdalow)
;then resample on the common wavelength vector:
;verylowspec2=changeres(verylowspec, lambdalow,lambda)

; xc=float(sxpar(hdrextr,'SPECCENX' ))
; yc=float(sxpar(hdrextr,'SPECCENY' ))          
;verylowspec2= decrease_spec_res(lambda, LowResolutionSpec,[[-1.,xc],[-1.,yc]])

theospectrum=(10.^(-(compmag-refmag)/2.5))*LowResolutionSpec
print, 'theo comp. spec=',theospectrum
ewav=extr[*,0]
espe=extr[*,2] ;indice 2 selects the standard photometric measurement (DAOphot-like)


truitime=float(sxpar(header,'ITIME'))
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
title=strcompress(COMPSPEC,/rem)+' star, Exposure='+strcompress(truitime,/rem)+'s, '+Modules[thisModuleIndex].title

basen=file_basename(res[0])
basenwoext=strmid(basen,0,strlen(basen)-5)
openps,gpi_get_directory('GPI_REDUCED_DATA_DIR')+path_sep()+'test5_'+basenwoext+'.ps', xsize=17, ysize=27 ;, ysize=10, xsize=15
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
xyouts, ewav[2],70.,'mean error='+strc(mean(100.*abs(espe-theospectrum)/theospectrum), format='(f5.2)')+' %'
closeps
 SET_PLOT, mydevice ;set_plot,'win'
!P.MULTI = 0
return, ok
 end
