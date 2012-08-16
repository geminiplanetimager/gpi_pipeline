;+
; NAME: testextendedobjectflux
; PIPELINE PRIMITIVE DESCRIPTION: Test the extended object photometry 
;
; INPUTS: 
;
;
; KEYWORDS:
; 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Test the algorithm of the Extended object photometric measurement by comparing it with DST debris disk inputs.
; PIPELINE ARGUMENT: Name="ComparisonFile" Type="string" Default="E:\GPIdatabase\GPIreduced\testdata\input_ext1.fits" Desc="Enter DST input Stokes params"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-ErrStokes" Desc="Enter suffix of figures names"
; PIPELINE ARGUMENT: Name="legendfig" Type="string"  Default="" Desc="If needed, enter a legend for figures"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying wavcal file, 0: no display "
; PIPELINE ORDER: 4.3
; PIPELINE TYPE: ALL-SPEC 
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2010-11-08
;- 

function testextendedobjectflux, DataSet, Modules, Backbone
primitive_version= '$Id: testextendedobjectflux.pro 11 2010-11-25 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive
mydevice = !D.NAME
;retrieve DST input parameters:
InputObjFilename= Modules[thisModuleIndex].ComparisonFile

InputObj=readfits(InputObjFilename)
;stop
if (size(inputobj))[0] eq 3 then spectchannels=float((size(inputobj))[3]) else spectchannels=1.
;InputStokesband=reform(median(InputStokes[*,*,*,*],dimension=3))
if (size(inputobj))[0] eq 3 then InputObj=reform(median(Inputobj[*,*,*],dimension=3))

truitime=float(backbone->get_keyword('ITIME', count=ct))
print, 'truitime=',truitime
InputObj*=(1./truitime) ;per second
InputObj*=(spectchannels/(1000.*0.3)) ;per nm (! H-band !)
transmi=0.15 ;input cubes have been multiplied by the instru. transmission in the DST
InputObj*=(1./transmi)
;get back to astrophys. flux
   Dtel=double(backbone->get_keyword('TELDIAM', count=ct))
   Obscentral=double(backbone->get_keyword('SECDIAM', count=ct))
   SURFA=!PI*(Dtel^2.)/4.-!PI*((Obscentral)^2.)/4.
   InputObj*=(1./SURFA) ;per m^2

sz=size(InputObj)
;InputStokesband[*,*,1]=fltarr(sz[1],sz[2])-InputStokesband[*,*,1]
;InputStokesband[*,*,2]=fltarr(sz[1],sz[2])-InputStokesband[*,*,2]

;reformat measurement with DST inputs format
measurement=*(dataset.currframe[0]) 
if (size(measurement))[0] eq 3 then measurement=reform(median(measurement[*,*,*],dimension=3))


measObj=transpose(shift(subarr(measurement,277),1,-2))

;comparisons begin here: 
;calculate relative difference [%] between input and output Stokesn param.
comparobj=100.*(measobj-Inputobj)/Inputobj 

;if pairs eq 1 then comparStokes2=100.*(measStokes2-InputStokesband)/InputStokesband       
;linear polar
;linpoldst=sqrt(((InputStokesband[*,*,1])^2.+(InputStokesband[*,*,2])^2.)/InputStokesband[*,*,0])
;linpoldrp=sqrt(((measStokes[*,*,1])^2.+(measStokes[*,*,2])^2.)/measStokes[*,*,0])
;comparLinearPol=100.*(linpoldrp-linpoldst)/linpoldst   
;if pairs eq 1 then begin
;linpoldrp2=sqrt(((measStokes2[*,*,1])^2.+(measStokes2[*,*,2])^2.)/measStokes2[*,*,0])
;comparLinearPol2=100.*(linpoldrp2-linpoldst)/linpoldst        
;endif     
  
 
 indsignal=where(inputobj gt 0.8*max(inputobj))
        ; if cz gt 0 then zemdispX[indout]=!VALUES.F_NAN 
;calculate histogram of relative difference        
xmax=80.& xmin=-xmax 
fac=100.
bin=fac
histI=HISTOGRAM(comparobj[indsignal], min=xmin,max=xmax,nbins=bin,locations=loc)
;histQ=HISTOGRAM(comparobj[*,*,1], min=xmin,max=xmax,nbins=bin,locations=loc)
;histU=HISTOGRAM(comparobj[*,*,2], min=xmin,max=xmax,nbins=bin,locations=loc)
;histV=HISTOGRAM(comparobj[*,*,3], min=xmin,max=xmax,nbins=bin,locations=loc) 
;histLin=HISTOGRAM(comparobj, min=xmin,max=xmax,nbins=bin,locations=loc) 
;if pairs eq 1 then begin
;    histI2=HISTOGRAM(comparStokes2[*,*,0], min=xmin,max=xmax,nbins=bin,locations=loc)
;    histQ2=HISTOGRAM(comparStokes2[*,*,1], min=xmin,max=xmax,nbins=bin,locations=loc)
;    histU2=HISTOGRAM(comparStokes2[*,*,2], min=xmin,max=xmax,nbins=bin,locations=loc)
;    histV2=HISTOGRAM(comparStokes2[*,*,3], min=xmin,max=xmax,nbins=bin,locations=loc) 
;    histLin2=HISTOGRAM(comparLinearPol2, min=xmin,max=xmax,nbins=bin,locations=loc)   
;endif     
;prepare result filename and plots        
h=*(dataset.headersPHU[numfile]) 
filnm=sxpar(*(DataSet.HeadersPHU[numfile]),'DATAFILE')
slash=strpos(filnm,path_sep(),/reverse_search)
filter = strcompress(sxpar( h ,'IFSFILT', count=fcount),/REMOVE_ALL)
if fcount eq 0 then filter = strcompress(sxpar( h ,'FILTER'),/REMOVE_ALL)
suffixplot=(Modules[thisModuleIndex].suffix)
legends=(Modules[thisModuleIndex].legendfig)

    fnameps=gpi_get_directory('GPI_REDUCED_DATA_DIR')+path_sep()+'test13_'+strmid(filnm,slash+1,STRLEN(filnm)-5-slash)+suffixplot+filter        
  openps,fnameps+'.ps', xsize=17, ysize=27
  xr=xmax
      !P.MULTI = [0, 2, 3, 0, 0] 
      PLOT, loc,histI, $ 
        XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
       XTITLE = 'Relative difference [%]', $ 
       YTITLE = 'Number of lenslet of That Value' ,ystyle=9,linestyle=0 ,yrange=[0,max(histI)] , xrange=[-xr,xr] ;,/noerase
       xyouts,-20.,max(histI)/10.,legends
              xyouts,-18.,max(histI)/2.,'Extented object'  
 ;            if pairs eq 1 then oPLOT, loc,histI2,psym=1
;              plot, [0], position=[0.25,0.9,0.35,0.95],ystyle=1,xtickname=REPLICATE(' ', 6),ytickname=REPLICATE(' ', 6),xtitle='measured';,/noerase
;              cgimage,   measStokes[*,*,0], /overplot ;InputStokesband
;      PLOT,loc,histQ,yrange=[0,max(histQ)] , xrange=[-xr,xr], XTITLE = 'Relative difference [%]', YTITLE = 'Number of lenslet of That Value'
;              xyouts,-18.,max(histQ)/2.,'Stokes Q'  
;              if pairs eq 1 then oPLOT, loc,histQ2,psym=1
;      PLOT,loc,histU,yrange=[0,max(histU)] , xrange=[-xr,xr] , XTITLE = 'Relative difference [%]', YTITLE = 'Number of lenslet of That Value'
;             xyouts,-18.,max(histU)/2.,'Stokes U'   
;             if pairs eq 1 then oPLOT, loc,histU2,psym=1
;      PLOT,loc,histV,yrange=[0,max(histV)] , xrange=[-xr,xr] , XTITLE = 'Relative difference [%]', YTITLE = 'Number of lenslet of That Value'
;             xyouts,-18.,max(histV)/2.,'Stokes V' 
;             if pairs eq 1 then oPLOT, loc,histV2,psym=1 
;      PLOT,loc,histLin,yrange=[0,max(histLin)] , xrange=[-xr,xr] , XTITLE = 'Relative difference [%]', YTITLE = 'Number of lenslet of That Value'
;             xyouts,-18.,max(histLin)/2.,'Linear Pol.'
;             if pairs eq 1 then oPLOT, loc,histLin2,psym=1   
  closeps
  SET_PLOT, mydevice ;  set_plot,'win'

 end
