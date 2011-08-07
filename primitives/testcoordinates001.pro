;+
; NAME: testcoordinates001
; PIPELINE PRIMITIVE DESCRIPTION: Test the measured angular separation and PA
;
; INPUTS: 
;
;
; KEYWORDS:
; 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Test the measured angular separation and PA
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-test08" Desc="Enter suffix of figure name"
; PIPELINE ARGUMENT: Name="title" Type="string" Default="" Desc="Enter figure title"
; PIPELINE ORDER: 2.52
; PIPELINE TYPE: ALL-SPEC 
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2011-02-16
;- 

function testcoordinates001, DataSet, Modules, Backbone
primitive_version= '$Id: testcoordinates001.pro 11 2011-02-11 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive
mydevice = !D.NAME

  cubef3D=*(dataset.currframe[0])

  cubef3Dz=cubef3D
  wnf1 = where(~FINITE(cubef3D),nancount1)
  if nancount1 gt 0 then cubef3Dz[wnf1]=0.

  sz=size(cubef3Dz)
  posmax1=intarr(2)
  gfit1=dblarr(7,CommonWavVect[2])
  cubef3dmaskbinary1=cubef3Dz
  ; find where the maximum brightness is
    maxintensity= max(cubef3Dz[*,*,CommonWavVect[2]/2],indmax,/Nan)
    posmax1=array_indices(cubef3Dz[*,*,CommonWavVect[2]/2],indmax)

   ; For each wavelength, fit a 2D Gaussian around the location of the maximum
   ; brightness. 
   ; Create a modified copy of the array where that peak is masked out too, for
   ; the binary fit.
for i=0,CommonWavVect[2]-1 do begin
   gfit = GAUSS2DFIT(cubef3Dz[((posmax1[0]-10)>0):((posmax1[0]+10)<sz[1]),((posmax1[1]-10)>0):((posmax1[1]+10)<sz[1]),i], B)
   gfit1[*,i]=B[*] 
   gfit1[4,i]+=posmax1[0]-10
   gfit1[5,i]+=posmax1[1]-10
   ;mask binary 1 for detection of binary 2
   cubef3dmaskbinary1[((posmax1[0]-10)>0):((posmax1[0]+10)<sz[1]),((posmax1[1]-10)>0):((posmax1[1]+10)<sz[1]),i]=0.
endfor
print, 'Max intens. of binary 1 x-Pos :',reform(posmax1[0])
print, 'Max intens. of binary 1 y-Pos :',reform(posmax1[1])
print, 'x-Pos of binary 1:',reform(gfit1[4,*])
print, 'y-Pos of binary 1:',reform(gfit1[5,*])


; Now do the fit for the second star.
posmax2=intarr(2,CommonWavVect[2])
gfit2=dblarr(7,CommonWavVect[2])
for i=0,CommonWavVect[2]-1 do begin
   maxintensity= max(cubef3dmaskbinary1[*,*,i],indmax,/Nan)
   posmax2[*,i]=array_indices(cubef3dmaskbinary1[*,*,i],indmax)
   gfit = GAUSS2DFIT(cubef3dmaskbinary1[((posmax2[0,i]-10)>0):((posmax2[0,i]+10)<sz[1]),((posmax2[1,i]-10)>0):((posmax2[1,i]+10)<sz[1]),i], B)
   gfit2[*,i]=B[*] 
   gfit2[4,i]+=posmax2[0,i]-10
   gfit2[5,i]+=posmax2[1,i]-10
endfor
print, 'Max intens. of binary 2 x-Pos :',reform(posmax2[0])
print, 'Max intens. of binary 2 y-Pos :',reform(posmax2[1])
print, 'x-Pos of binary 2:',reform(gfit2[4,*])
print, 'y-Pos of binary 2:',reform(gfit2[5,*])


hdr= *(dataset.headersPHU)[0]
name=(SXPAR( hdr, 'OBJECT'))
dateobs=(SXPAR( hdr, 'DATE-OBS'))
timeobs=(SXPAR( hdr, 'TIME-OBS'))
res=read6thorbitcat( name, dateobs, timeobs) 

; TODO error checking here, in case that object is
; not present in the catalog.

rho=res.sep ;float(Modules[thisModuleIndex].rho) ;get current separation of the binaries
pa=res.pa ;float(Modules[thisModuleIndex].pa) ;get current position angle of the binaries

cdelt1=float(SXPAR( *(dataset.headersExt)[0], 'CDELT1'))

;;calculate distance in pixels
dist= cdelt1*3600.* sqrt( ((gfit1[4,*]-gfit2[4,*])^2.) + ((gfit1[5,*]-gfit2[5,*])^2.)  )
angle_star_deg=(180./!dpi)*atan((gfit1[5,*]-gfit2[5,*])/(gfit1[4,*]-gfit2[4,*])) + 90.

;name=(SXPAR( hdr, 'OBJECT'))
print, 'dist between binaries [mas]=',1000.*dist
print, ' angle x-axis [deg]', angle_star_deg

filter= gpi_simplify_keyword_value(SXPAR( *(dataset.headersPHU)[0], 'FILTER1'))
        ;get the common wavelength vector
            ;error handle if extractcube not used before
         cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]
        
thisLetter = "155B
greekLetter = '!9' + String(thisLetter) + '!X'
thisModuleIndex = Backbone->GetCurrentModuleIndex()
;figtitle=(Modules[thisModuleIndex].title)
openps,getenv('GPI_DRP_OUTPUT_DIR')+path_sep()+'test08.ps', xsize=18, ysize=27 ;, ysize=10, xsize=15
  !P.MULTI = [0, 1, 2, 0, 0] 
  plot, lambda, 1000.*dist,ytitle='measured separation [mas]', xtitle='Wavelength (' + greekLetter + 'm)',$
   xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=0, psym=1,charsize=1.,yrange=1000.*[min(dist)-15.,max(dist)+15.];,title=''
   oplot,lambda, replicate(1000.*rho,n_elements(lambda)),linestyle=1
   legend,[name+'measured separation [mas]='+strc(1000.*mean(dist)),'separation from 6th orbit cat. at dateobs'+strc(1000.*mean(rho))],linestyle=[0,1],psym=[1,0]
   plot, lambda, angle_star_deg,ytitle='measured PA (CRPA=0) [deg]', xtitle='Wavelength (' + greekLetter + 'm)',$
   xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=0,psym=1, charsize=1.,yrange=[min(angle_star_deg)-5.,max(angle_star_deg)+5.];,title=''
   oplot,lambda, replicate(pa,n_elements(lambda)),linestyle=1
   legend,[name+'measured PA (CRPA=0) [deg] ='+strc(mean(angle_star_deg)),'DST PA [deg]='+strc(mean(pa))],linestyle=[0,1],psym=[1,0]
closeps
  SET_PLOT, mydevice ;set_plot,'win'

return, ok
 end