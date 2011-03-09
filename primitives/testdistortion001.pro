;+
; NAME: testdistortion001
; PIPELINE PRIMITIVE DESCRIPTION: Test the distortion correction
;
; INPUTS: 
;
;
; KEYWORDS:
; 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Test the distortion correction
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-disto" Desc="Enter suffix of figure name"
; PIPELINE ARGUMENT: Name="InFile" Type="string" Default="GPI-spdc.fits" Desc="Filename of input undistorted data to be read"
; PIPELINE ARGUMENT: Name="title" Type="string" Default="" Desc="Enter figure title"
; PIPELINE ORDER: 2.52
; PIPELINE TYPE: ALL-SPEC 
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2010-08-16
;- 

function testdistortion001, DataSet, Modules, Backbone
primitive_version= '$Id: testdistortion001.pro 11 2011-01-11 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive
mydevice = !D.NAME


;;get last  measured companion spectrum
compspecname=DataSet.OutputFilenames[numfile]
compspecnamewoext=strmid(compspecname,0,strlen(compspecname)-12)
res=file_search(compspecnamewoext+'*fits')
;extr=readfits(res[0],hdrextr)
strl=strlen(res)
minlen=min(strl,subs)
distorted_cube=readfits(res[subs])
;stop
        ;get the common wavelength vector
            ;error handle if extractcube not used before
         cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]

undistorted_File = (Modules[thisModuleIndex].InFile)
undistorted_cube=readfits(undistorted_File)

corrected_cube=*(dataset.currframe[0])

diffrelatuncorr=abs((undistorted_cube-distorted_cube)/undistorted_cube)
diffrelatcorr=abs((undistorted_cube-corrected_cube)/undistorted_cube)
;stop

err_relat_uncorr=fltarr(n_elements(lambda))
for ii=0,n_elements(lambda)-1 do begin
   slice=diffrelatuncorr[*,*,ii]
   ind=where(finite(slice))
   ind2=  where(slice[ind] gt 3.*median(slice[ind]))
   err_relat_uncorr[ii]=median((slice[ind])[ind2])
endfor
stop
err_relat_corr=fltarr(n_elements(lambda))
for ii=0,n_elements(lambda)-1 do begin
   slice=diffrelatcorr[*,*,ii]
   ind=where(finite(slice))
   ind2=  where(slice[ind] gt 3.*median(slice[ind]))
   err_relat_corr[ii]=median((slice[ind])[ind2])
  ; err_relat_corr[ii]=median(slice[ind])
endfor

;for ii=0,n_elements(lambda)-1 do err_relat_corr[ii]=mean(diffrelatcorr[*,*,ii], /nan)

print, 'Median relative error [%] of uncorrected distorted slices (vs wav):',100.*err_relat_uncorr
print, 'Median relative error [%] of corrected distorted slices (vs wav):',100.*err_relat_corr

thisLetter = "155B
greekLetter = '!9' + String(thisLetter) + '!X'
basen=file_basename(compspecnamewoext)
method=(Modules[thisModuleIndex].title)
openps,getenv('GPI_DRP_OUTPUT_DIR')+path_sep()+'fig'+path_sep()+basen+'distor.ps', xsize=15, ysize=10 ;, ysize=10, xsize=15
 ; !P.MULTI = [0, 1, 3, 0, 0] 
;units=TeXtoIDL(" W/m^{2}/\mum")
;deltaH=TeXtoIDL(" \Delta H=")
;print, 'units=',units
;expostr = TeXtoIDL(" 10^{-"+strc(expo)+"}")
plot, lambda, 100.*err_relat_uncorr,ytitle='Median Relative Error [%]', xtitle='Wavelength (' + greekLetter + 'm)',$
 xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=1,yrange=[0,max([max(100.*err_relat_uncorr),max(100.*err_relat_corr)])], charsize=1.5 
;oplot, lambda,(2.55^(3.09))*30.*lowresolutionspec,linestyle=1
oplot, lambda,100.*err_relat_corr,linestyle=0
legend,['Uncorrected distortion','Corrected distortion:'+method],linestyle=[1,0]
closeps
 SET_PLOT, mydevice ;set_plot,'win'

return, ok
 end