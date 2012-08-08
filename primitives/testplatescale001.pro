;+
; NAME: testplatescale001
; PIPELINE PRIMITIVE DESCRIPTION: Test the astrometric calibration
;
; INPUTS: 
;
;
; KEYWORDS:
; 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Test the plate scale and orientation
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-satspotloc" Desc="Enter suffix of figure name"
; PIPELINE ARGUMENT: Name="title" Type="string" Default="" Desc="Enter figure title"
; PIPELINE ORDER: 2.52
; PIPELINE TYPE: ALL-SPEC 
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2011-02-16
;- 

function testplatescale001, DataSet, Modules, Backbone
primitive_version= '$Id: testplatescale001.pro 11 2011-02-11 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive
mydevice = !D.NAME


hdr= *(dataset.headersPHU)[0]
name=(SXPAR( hdr, 'OBJECT'))
dateobs=(SXPAR( hdr, 'DATE-OBS'))
timeobs=(SXPAR( hdr, 'TIME-OBS'))
res=read6thorbitcat( name, dateobs, timeobs) 

Result=*(dataset.currframe[0])
pixelscale=Result[0]
xaxis_pa_at_zeroCRPA=Result[1]

rho=res.sep ;float(Modules[thisModuleIndex].rho) ;get current separation of the binaries
pa=res.pa ;float(Modules[thisModuleIndex].pa) ;get current position angle of the binaries


;;calculate distance in pixels
;dist=  sqrt( ((gfit1[4,*]-gfit2[4,*])^2.) + ((gfit1[5,*]-gfit2[5,*])^2.)  )
;angle_xaxis_deg=(180./!dpi)*atan((gfit1[5,*]-gfit2[5,*])/(gfit1[4,*]-gfit2[4,*]))

;;now calculate position angle of x-axis
;
;xaxis_pa=pa-mean(angle_xaxis_deg,/nan)
;;;calculate this angle for CRPA=0.
;   obsCRPA=float(SXPAR( hdr, 'CRPA'))
;   xaxis_pa_at_zeroCRPA=xaxis_pa-obsCRPA

filter=gpi_simplify_keyword_value(SXPAR( *(dataset.headersPHU)[0], 'IFSFILT'))
        ;get the common wavelength vector
            ;error handle if extractcube not used before
         cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]

;if the median value have been recorded, replicate the value
if n_elements(pixelscale) eq 1 then pixelscale=replicate(pixelscale, n_elements(lambda))
if n_elements(xaxis_pa_at_zeroCRPA) eq 1 then xaxis_pa_at_zeroCRPA=replicate(xaxis_pa_at_zeroCRPA, n_elements(lambda))

thisLetter = "155B
greekLetter = '!9' + String(thisLetter) + '!X'
thisModuleIndex = Backbone->GetCurrentModuleIndex()
;figtitle=(Modules[thisModuleIndex].title)
openps,getenv('GPI_REDUCED_DATA_DIR')+path_sep()+'test07.ps', xsize=18, ysize=27 ;, ysize=10, xsize=15
  !P.MULTI = [0, 1, 2, 0, 0] 
  plot, lambda, 1000.*pixelscale,ytitle='Plate scale [mas]', xtitle='Wavelength (' + greekLetter + 'm)',$
   xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=0, psym=1,charsize=1.,yrange=[0,20.];,title=''
   oplot,lambda, replicate(14.,n_elements(lambda)),linestyle=1
   legend,['measured plate scale [mas]='+strc(1000.*mean(pixelscale)),'DST plate scale = 14. mas'],linestyle=[0,1],psym=[1,0]
   plot, lambda, xaxis_pa_at_zeroCRPA,ytitle='x-axis PA (CRPA=0) [deg]', xtitle='Wavelength (' + greekLetter + 'm)',$
   xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=0,psym=1, charsize=1.,yrange=[80.,100.];,title=''
   oplot,lambda, replicate(90.,n_elements(lambda)),linestyle=1
   legend,['measured x-axis PA (CRPA=0) [deg] ='+strc(mean(xaxis_pa_at_zeroCRPA)),'DST PA [deg]=90.'],linestyle=[0,1],psym=[1,0]
closeps
  SET_PLOT, mydevice ;set_plot,'win'

return, ok
 end
