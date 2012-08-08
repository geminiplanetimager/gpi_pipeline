;+
; NAME: teststokesparam
; PIPELINE PRIMITIVE DESCRIPTION: Test the Stokes parameters measurement 
;
; INPUTS: 
;
;
; KEYWORDS:
; 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Test the algorithm of the Stokes parameters measurement by comparing them with DST Stokes parameter inputs.
; PIPELINE ARGUMENT: Name="ComparisonFile" Type="string" Default="E:\GPIdatabase\GPIreduced\testdata\polscene_H_pol3.fits" Desc="Enter DST input Stokes params"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-ErrStokes" Desc="Enter suffix of figures names"
; PIPELINE ARGUMENT: Name="legendfig" Type="string"  Default="" Desc="If needed, enter a legend for figures"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying wavcal file, 0: no display "
; PIPELINE ORDER: 4.3
; PIPELINE TYPE: ALL-POL 
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2010-11-08
;- 

function teststokesparam, DataSet, Modules, Backbone
primitive_version= '$Id: testStokesparam.pro 11 2010-11-08 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive
mydevice = !D.NAME
;retrieve DST input parameters:
InputStokesFilename= Modules[thisModuleIndex].ComparisonFile
  if strmatch(InputStokesFilename,'GPI_DST$*') then strreplace, InputStokesFilename, 'GPI_DST$', getenv('GPI_IFS_DIR')+path_sep()+'dst'+path_sep()+'testdata'+path_sep()

InputStokes=readfits(InputStokesFilename)

;InputStokesband=reform(median(InputStokes[*,*,*,*],dimension=3))
InputStokesband=reform(total(InputStokes[*,*,*,*],3))
truitime=float(sxpar(header,'ITIME'))
print, 'truitime=',truitime
InputStokesband*=(1000./truitime) ;per second
InputStokesband*=(1./(1000.*0.3)) ;per nm (! H-band !)
transmi=0.15 ;input Stokes have been multiplied by the instru. transmission in the DST
InputStokesband*=(1./transmi)
;get back to astrophys. flux
   Dtel=double(SXPAR( header, 'TELDIAM'))
   Obscentral=double(SXPAR( header, 'SECDIAM'))
   SURFA=!PI*(Dtel^2.)/4.-!PI*((Obscentral)^2.)/4.
   InputStokesband*=(1./SURFA) ;per m^2
;stop
sz=size(InputStokesband)
;InputStokesband[*,*,1]=fltarr(sz[1],sz[2])-InputStokesband[*,*,1]
;InputStokesband[*,*,2]=fltarr(sz[1],sz[2])-InputStokesband[*,*,2]

;reformat measurement with DST inputs format
measurement=*(dataset.currframe[0]) 
measStokes=shift(subarr(measurement,277),1,-2,0)
;for i=0,3 do measStokes[*,*,i]=rotate(measStokes[*,*,i],1)


;  one acting on the pairs of sums and difference images. 
pairs=0
if pairs eq 1 then begin
filnm=sxpar(*(DataSet.Headers[numfile]),'DATAFILE')
slash=strpos(filnm,path_sep(),/reverse_search)
meas=readfits(getenv('GPI_REDUCED_DATA_DIR')+strmid(filnm,slash,STRLEN(filnm)-5-slash)+suffix+'diff.fits')
measStokes2=rotate(shift(subarr(meas,277),1,-2,0),1)
endif
;comparisons begin here: 
;calculate relative difference [%] between input and output Stokesn param.
comparStokes=100.*(measStokes-InputStokesband)/InputStokesband 
if pairs eq 1 then comparStokes2=100.*(measStokes2-InputStokesband)/InputStokesband       
;linear polar
linpoldst=sqrt(((InputStokesband[*,*,1])^2.+(InputStokesband[*,*,2])^2.)/InputStokesband[*,*,0])
linpoldrp=sqrt(((measStokes[*,*,1])^2.+(measStokes[*,*,2])^2.)/measStokes[*,*,0])
comparLinearPol=100.*(linpoldrp-linpoldst)/linpoldst   
if pairs eq 1 then begin
linpoldrp2=sqrt(((measStokes2[*,*,1])^2.+(measStokes2[*,*,2])^2.)/measStokes2[*,*,0])
comparLinearPol2=100.*(linpoldrp2-linpoldst)/linpoldst        
endif     
 ;stop      
        ; if cz gt 0 then zemdispX[indout]=!VALUES.F_NAN 
;calculate histogram of relative difference        
xmax=80.& xmin=-xmax 
fac=100.
bin=fac
histI=HISTOGRAM(comparStokes[*,*,0], min=xmin,max=xmax,nbins=bin,locations=loc)
histQ=HISTOGRAM(comparStokes[*,*,1], min=xmin,max=xmax,nbins=bin,locations=loc)
histU=HISTOGRAM(comparStokes[*,*,2], min=xmin,max=xmax,nbins=bin,locations=loc)
histV=HISTOGRAM(comparStokes[*,*,3], min=xmin,max=xmax,nbins=bin,locations=loc) 
histLin=HISTOGRAM(comparLinearPol, min=xmin,max=xmax,nbins=bin,locations=loc) 
if pairs eq 1 then begin
    histI2=HISTOGRAM(comparStokes2[*,*,0], min=xmin,max=xmax,nbins=bin,locations=loc)
    histQ2=HISTOGRAM(comparStokes2[*,*,1], min=xmin,max=xmax,nbins=bin,locations=loc)
    histU2=HISTOGRAM(comparStokes2[*,*,2], min=xmin,max=xmax,nbins=bin,locations=loc)
    histV2=HISTOGRAM(comparStokes2[*,*,3], min=xmin,max=xmax,nbins=bin,locations=loc) 
    histLin2=HISTOGRAM(comparLinearPol2, min=xmin,max=xmax,nbins=bin,locations=loc)   
endif     
;prepare result filename and plots        
h=*(dataset.headers[numfile]) 
filnm=sxpar(*(DataSet.Headers[numfile]),'DATAFILE')
slash=strpos(filnm,path_sep(),/reverse_search)
filter = strcompress(sxpar( h ,'IFSFILT', count=fcount),/REMOVE_ALL)
if fcount eq 0 then filter = strcompress(sxpar( h ,'FILTER'),/REMOVE_ALL)
suffixplot=(Modules[thisModuleIndex].suffix)
legends=(Modules[thisModuleIndex].legendfig)

    fnameps=getenv('GPI_REDUCED_DATA_DIR')+'test6_'+strmid(filnm,slash+1,STRLEN(filnm)-5-slash)+suffixplot+filter        
  openps,fnameps+'.ps', xsize=17, ysize=27
  xr=xmax
      !P.MULTI = [0, 2, 3, 0, 0] 
      PLOT, loc,histI, $ 
        XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
       XTITLE = 'Relative difference [%]', $ 
       YTITLE = 'Number of lenslet of That Value' ,ystyle=9,linestyle=0 ,yrange=[0,max(histI)] , xrange=[-xr,xr] ;,/noerase
       xyouts,-20.,max(histI)/10.,legends
              xyouts,-18.,max(histI)/2.,'Stokes I'  
             if pairs eq 1 then oPLOT, loc,histI2,psym=1
;              plot, [0], position=[0.25,0.9,0.35,0.95],ystyle=1,xtickname=REPLICATE(' ', 6),ytickname=REPLICATE(' ', 6),xtitle='measured';,/noerase
;              tvimage,   measStokes[*,*,0], /overplot ;InputStokesband
      PLOT,loc,histQ,yrange=[0,max(histQ)] , xrange=[-xr,xr], XTITLE = 'Relative difference [%]', YTITLE = 'Number of lenslet of That Value'
              xyouts,-18.,max(histQ)/2.,'Stokes Q'  
              if pairs eq 1 then oPLOT, loc,histQ2,psym=1
      PLOT,loc,histU,yrange=[0,max(histU)] , xrange=[-xr,xr] , XTITLE = 'Relative difference [%]', YTITLE = 'Number of lenslet of That Value'
             xyouts,-18.,max(histU)/2.,'Stokes U'   
             if pairs eq 1 then oPLOT, loc,histU2,psym=1
      PLOT,loc,histV,yrange=[0,max(histV)] , xrange=[-xr,xr] , XTITLE = 'Relative difference [%]', YTITLE = 'Number of lenslet of That Value'
             xyouts,-18.,max(histV)/2.,'Stokes V' 
             if pairs eq 1 then oPLOT, loc,histV2,psym=1 
      PLOT,loc,histLin,yrange=[0,max(histLin)] , xrange=[-xr,xr] , XTITLE = 'Relative difference [%]', YTITLE = 'Number of lenslet of That Value'
             xyouts,-18.,max(histLin)/2.,'Linear Pol.'
             if pairs eq 1 then oPLOT, loc,histLin2,psym=1   
  closeps
  
  histcum=total(HISTOGRAM(abs(comparLinearPol), min=0.,max=1.*xmax,nbins=bin,locations=loccum),/cum)
 ;void=where(finite(histcum),cfx)
 histcum2=(100./max(histcum))*histcum
  ; stop
  openps,getenv('GPI_REDUCED_DATA_DIR')+'test6.ps', xsize=17, ysize=27
  xr=xmax
      !P.MULTI = [0, 1, 2, 0, 0] 
      PLOT, loc,histLin, $ 
        XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
       XTITLE = 'Linear Pol. relative difference [%]', $ 
       YTITLE = 'Number of lenslet of That Value' ,ystyle=9,linestyle=0 ,yrange=[0,max(histI)] , xrange=[-xr,xr] ;,/noerase
        xyouts,-18.,max(histLin)/2.,'Linear Pol.'
      PLOT,loccum,histcum2,yrange=[0,max(histcum2)] , xrange=[0,xr], XTITLE = 'Cumul. linear pol .relative difference [%]', YTITLE = 'Number of lenslet of That Value'
             ; xyouts,-18.,max(histcum2)/2.,'Linear Pol'  
        xyouts,0.2,30,' # mlens with linear pol. error less  10% :'+strc(histcum2[value_locate(loccum,10.)],format='(f7.2)')+'%'

              
  
  closeps
  
  
  
   SET_PLOT, mydevice; set_plot,'win'

   @__end_primitive

 end
