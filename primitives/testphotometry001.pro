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
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-photom" Desc="Enter suffix of figures names"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying wavcal file, 0: no display "
; PIPELINE ORDER: 2.52
; PIPELINE TYPE: ALL-SPEC 
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2010-08-16
;- 

function testphotometry001, DataSet, Modules, Backbone
primitive_version= '$Id: testphotometry001.pro 11 2010-08-16 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive



;;get last  measured companion spectrum
compspecname=DataSet.OutputFilenames[numfile]
compspecnamewoext=strmid(compspecname,0,strlen(compspecname)-5)
res=file_search(compspecnamewoext+'*spec*fits')
extr=readfits(res[0],hdrextr)
COMPMAG=float(sxpar(hdrextr,'COMPMAG'))
COMPSPEC=sxpar(hdrextr,'COMPSPEC') ;we could have compsep&comprot

;;get DST companion spectrum
restore, 'E:\GPI\dst\'+strcompress(compspec,/rem)+'compspectrum.sav'
case strcompress(filter,/REMOVE_ALL) of
  'Y':specresolution=30.
  'J':specresolution=35.
  'H':specresolution=45.
  'K1':specresolution=55.
  'K2':specresolution=60.
endcase

lambdamin=lambda[0]
lambdamax=lambda[n_elements(lambda)-1]
dlam=((lambdamin+lambdamax)/2.)/specresolution
nlam=(lambdamax-lambdamin)/dlam
lambdalow= lambdamin+(lambdamax-lambdamin)*(findgen(floor(nlam))/floor(nlam))
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

valwav=value_locate(lamb,[lambda[0]-(lambda[1]-lambda[0]),lambda[n_elements(lambda)-1]+(lambda[1]-lambda[0])])
lambcomp=lamb[valwav[0]:valwav[1]]
verylowspec=changeres(lowresolutionspec, lambda,lambdalow)
verylowspec2=changeres(verylowspec, lambdalow,lambda)


;;prepare the plot
maxvalue=max([verylowspec2,espe])
expo=floor(abs(alog10(maxvalue))+1.)
factorexpo=10.^expo ;1.e13
;expostr='1e-13 '
ewav=extr[*,0]
espe=extr[*,2]
thisLetter = "155B
greekLetter = '!9' + String(thisLetter) + '!X'
print, greekLetter
units=' W/m^2/'+greekLetter+'m'
truitime=float(sxpar(header,'TRUITIME'))
starmag=double(SXPAR( hdr, 'Hmag'))

basen=file_basename(res[0])
basenwoext=strmid(basen,0,strlen(basen)-5)
openps,getenv('GPI_DRP_OUTPUT_DIR')+path_sep()+basenwoext+'.ps', ysize=10, xsize=15
units=TeXtoIDL(" W/m^{2}/\mum")
deltaH=TeXtoIDL(" \Delta H=")
print, 'units=',units
expostr = TeXtoIDL(" 10^{-"+strc(expo)+"}")
plot, ewav, factoexpo*espe,ytitle='Flux density ['+expostr+units+']', xtitle='Wavelength (' + greekLetter + 'm)', xrange=[1.5,1.8],yrange=[0,10.],psym=1 
;oplot, lambda,(2.55^(3.09))*30.*lowresolutionspec,linestyle=1
oplot, lambda,factoexpo*(2.5^(refmag-compmag))*(1e-3*truitime)*verylowspec2,linestyle=0
legend,['measured spectrum','input '+strcompress(compspec,/rem)+' spectrum, H='+strc(compmag)+deltaH+strc(compmag-starmag)],psym=[1,-0]
closeps
set_plot,'win'
 
return, ok
 end