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
distorted_cube=readfits(res[subs],exten=1)
;stop
        ;get the common wavelength vector
            ;error handle if extractcube not used before
         cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]

undistorted_File = (Modules[thisModuleIndex].InFile)
  if strmatch(undistorted_File,'GPI_REDUCED_DATA_DIR$*') then strreplace, undistorted_File, 'GPI_REDUCED_DATA_DIR$', getenv('GPI_REDUCED_DATA_DIR')

undistorted_cube=readfits(undistorted_File,exten=1)

corrected_cube=*(dataset.currframe[0])

diffrelatuncorr=abs((undistorted_cube-distorted_cube)/undistorted_cube)
diffrelatcorr=abs((undistorted_cube-corrected_cube)/undistorted_cube)
;stop
thresh=1.
err_relat_uncorr=fltarr(n_elements(lambda))
for ii=0,n_elements(lambda)-1 do begin
   slice=diffrelatuncorr[*,*,ii]
   ind=where(finite(slice))
   ind2=  where(slice[ind] gt thresh*median(slice[ind]))
   err_relat_uncorr[ii]=median((slice[ind])[ind2])
endfor
;stop
err_relat_corr=fltarr(n_elements(lambda))
for ii=0,n_elements(lambda)-1 do begin
   slice=diffrelatcorr[*,*,ii]
   ind=where(finite(slice))
   ind2=  where(slice[ind] gt thresh*median(slice[ind]))
   err_relat_corr[ii]=median((slice[ind])[ind2])
  ; err_relat_corr[ii]=median(slice[ind])
endfor

;for ii=0,n_elements(lambda)-1 do err_relat_corr[ii]=mean(diffrelatcorr[*,*,ii], /nan)

print, 'Median relative error [%] of uncorrected distorted slices (vs wav):',100.*err_relat_uncorr
print, 'Median relative error [%] of corrected distorted slices (vs wav):',100.*err_relat_corr

;stop
;test location of comp
poscompx_und=fltarr(n_elements(lambda))
poscompy_und=fltarr(n_elements(lambda))
poscompx_dist=fltarr(n_elements(lambda))
poscompy_dist=fltarr(n_elements(lambda))
poscompx_corr=fltarr(n_elements(lambda))
poscompy_corr=fltarr(n_elements(lambda))
;distorted_cube
;corrected_cube
pos2=[141,91]  
sidelen=6
for ii=0,n_elements(lambda)-1 do begin          
      getsatpos=centroid(subarr(undistorted_cube[*,*,ii],sidelen,[pos2[0],pos2[1]]))
      poscompx_und[ii]=pos2[0]-sidelen/2.+getsatpos[0] 
      poscompy_und[ii]=pos2[1]-sidelen/2.+getsatpos[1]
      
      getsatpos=centroid(subarr(distorted_cube[*,*,ii],sidelen,[pos2[0],pos2[1]]))
      poscompx_dist[ii]=pos2[0]-sidelen/2.+getsatpos[0] 
      poscompy_dist[ii]=pos2[1]-sidelen/2.+getsatpos[1]
      
      getsatpos=centroid(subarr(corrected_cube[*,*,ii],sidelen,[pos2[0],pos2[1]]))
      poscompx_corr[ii]=pos2[0]-sidelen/2.+getsatpos[0] 
      poscompy_corr[ii]=pos2[1]-sidelen/2.+getsatpos[1]
end
;stop


thisLetter = "155B
greekLetter = '!9' + String(thisLetter) + '!X'
basen=file_basename(compspecnamewoext)
method=(Modules[thisModuleIndex].title)
openps,getenv('GPI_REDUCED_DATA_DIR')+'test9_distor.ps', xsize=15, ysize=25 ;, ysize=10, xsize=15
  !P.MULTI = [0, 1, 3, 0, 0] 
;units=TeXtoIDL(" W/m^{2}/\mum")
;deltaH=TeXtoIDL(" \Delta H=")
;print, 'units=',units
;expostr = TeXtoIDL(" 10^{-"+strc(expo)+"}")
platescale=14.
plot,lambda,platescale*(poscompy_und-poscompy_und),ytitle='companion centroid y-location [mas]', xtitle='Wavelength (' + greekLetter + 'm)',$
 xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=1, charsize=1.5 ,yrange=platescale*[-1.,1.];,yrange=platescale*[min(poscompy_und)-1.,max(poscompy_und)+1.]
oplot, lambda,platescale*(poscompy_dist-poscompy_und),psym=1
oplot, lambda,platescale*(poscompy_corr-poscompy_und),psym=2
legend,['undistorted','distorted','corrected'], linestyle=[1,0,0],psym=[0,1,2]

plot,lambda,platescale*(poscompx_und-poscompx_und),ytitle='companion centroid x-location [mas]', xtitle='Wavelength (' + greekLetter + 'm)',$
 xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=1, charsize=1.5, yrange=platescale*[-1.,1.];,yrange=platescale*[min(poscompx_und)-1.,max(poscompx_und)+1.], charsize=1.5 
oplot, lambda,platescale*(poscompx_dist-poscompx_und),psym=1
oplot, lambda,platescale*(poscompx_corr-poscompx_und),psym=2
legend,['undistorted','distorted','corrected'], linestyle=[1,0,0],psym=[0,1,2]

plot, lambda, 100.*err_relat_uncorr,ytitle='Median Relative Error [%]', xtitle='Wavelength (' + greekLetter + 'm)',$
 xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=1,yrange=[0,max([max(100.*err_relat_uncorr),max(100.*err_relat_corr)])], charsize=1.5 
;oplot, lambda,(2.55^(3.09))*30.*lowresolutionspec,linestyle=1
oplot, lambda,100.*err_relat_corr,linestyle=0
legend,['Uncorrected distortion','Corrected distortion:'+method],linestyle=[1,0]
closeps
 SET_PLOT, mydevice ;set_plot,'win'

return, ok
 end
