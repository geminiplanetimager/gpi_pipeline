;+
; NAME: testwavcal
; PIPELINE PRIMITIVE DESCRIPTION: Test the wavelength solution measurement 
;
; INPUTS: 
;
;
; KEYWORDS:
; 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Test the algorithm of the wavelength solution measurement by comparing with DST-Zemax reference wavelength solution.
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-ErrWavcal" Desc="Enter suffix of figures names"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying wavcal file, 0: no display "
; PIPELINE ORDER: 4.3
; PIPELINE TYPE: ALL-SPEC 
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2010-07-06
;- 

function testwavcal001, DataSet, Modules, Backbone
primitive_version= '$Id: testwavcal001.pro 11 2010-08-09 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive

;;; First, if not already done, need to format the DST Zemax file as a DRP wavelength solution
  rep=getenv('GPI_IFS_DIR')+path_sep()+'dst'+path_sep()
  nlens=(size(*(dataset.currframe[0])))[1]
  wavcal1=*(dataset.currframe[0])
  h=*(dataset.headers[0])
  ;need to know which filter is used to get the right zemax file 
  bandeobs=SXPAR( h, 'FILTER',count=c4)
  if c4 eq 0 then bandeobs=SXPAR( h, 'FILTER1',count=c4)  
  case strcompress(bandeobs,/REMOVE_ALL) of
    'Y':zemwav=1.05
    'J':zemwav=1.25
    'H':zemwav=1.65
    'K1':zemwav=2.05
    'K2':zemwav=2.2
    else:zemwav=1.65
  endcase  
  filter = strcompress(sxpar( header ,'FILTER1', count=fcount),/REMOVE_ALL)
  if fcount eq 0 then filter = strcompress(sxpar( header ,'FILTER'),/REMOVE_ALL)
  zemdisplamraw=readfits(rep+'zemdispLam'+filter+'.fits')
  void=min(abs(zemdisplamraw-zemwav),zemwavind)
  print, 'Reference wav. at  ',zemdisplamraw[zemwavind] 
  wavcal2=change_wavcal_lambdaref( wavcal1, zemdisplamraw[zemwavind])

  ;is the formated Zemax files  already saved?
  if (Modules[thisModuleIndex].CalibrationFile eq '') then begin
    ;here are the raw zemax files:
    zemdispYraw=readfits(rep+'zemdispX'+filter+'.fits')
    zemdispXraw=readfits(rep+'zemdispY'+filter+'.fits')
    ;actually the raw zemax files has a larger lenslet array, so adjust the size for the comparison 
    zemdispY=(subarr(zemdispYraw,nlens))
    zemdispX=(subarr(zemdispXraw,nlens))
    ;tilt and coeff need to be calculated from zemax lenslet locations:
    tilt=dblarr(nlens,nlens)
    w3=dblarr(nlens,nlens)  
     for i=0,nlens-1 do begin
      for j=0,nlens-1 do begin
            tiltp=dblarr(n_elements(zemdisplamraw))
            w3p=dblarr(n_elements(zemdisplamraw))
          ;  if (abs(zemdispY[i,j,zemwavind]-1024.+1024.) lt 3.) && (abs(zemdispX[i,j,zemwavind]-1073.+1024.) lt 3.) then stop
        for p=0,n_elements(zemdisplamraw)-1 do begin
        tiltp(p)=atan((zemdispY[i,j,p]-zemdispY[i,j,zemwavind])/(zemdispX[i,j,p]-zemdispX[i,j,zemwavind]))
        w3p(p)=abs(zemdisplamraw[p]-zemdisplamraw[zemwavind])/(sqrt(((zemdispY[i,j,p]-zemdispY[i,j,zemwavind]))^2+(zemdispX[i,j,p]-zemdispX[i,j,zemwavind])^2))
            tilt[i,j]=median(tiltp)
        w3[i,j]=median(w3p)
        endfor
       endfor
      endfor
    
    ;we need to have the same origin and edges
     zemdispX2=zemdispX+1020.
     zemdispY2=zemdispY+1020.
     zemdispX2[where(zemdispX2 le 0.)]=!VALUES.F_NAN 
     zemdispX2[where(zemdispX2 gt 2040.)]=!VALUES.F_NAN 
     zemdispX2[where(zemdispY2 le 0.)]=!VALUES.F_NAN 
     zemdispX2[where(zemdispY2 gt 2040.)]=!VALUES.F_NAN   
          zemdispY2[where(zemdispX+1020. le 0.)]=!VALUES.F_NAN 
          zemdispY2[where(zemdispX+1020. gt 2040.)]=!VALUES.F_NAN 
          zemdispy2[where(zemdispY2 le 0.)]=!VALUES.F_NAN 
          zemdispY2[where(zemdispY2 gt 2040.)]=!VALUES.F_NAN  
          
            
    ;creation de la zem-wavcal au format DRP
    szwcdrp=size(wavcal1)
    zemwavcal=fltarr(szwcdrp[1],szwcdrp[2],szwcdrp[3])
    zemwavcal[*,*,0]=rotate(transpose(zemdispX2[*,*,zemwavind]),2)+4.
    zemwavcal[*,*,1]=rotate(transpose(zemdispY2[*,*,zemwavind]),2)+4.
    zemwavcal[*,*,2]=zemdisplamraw[zemwavind]
    zemwavcal[*,*,3]=rotate(transpose(w3),2)
    zemwavcal[*,*,4]=rotate(transpose(tilt),2)
 ; gpitve, zemwavcal & gpitv_activate
 ; if fix(Modules[thisModuleIndex].gpitv) ne 0 then gpitve, zemwavcal 
  
  ;;create a short header for the zem-wavcal
  mkhdr, hdr, zemwavcal
  FXADDPAR, hdr, 'NLENS', szwcdrp[1],'#lenslet'
  FXADDPAR, hdr, 'LAMBREF', zemdisplamraw[zemwavind],'wavelength reference'
  FXADDPAR, hdr, 'FILEINIT', 'zemdispX'+filter+'.fits', 'Zemax file used' 
  FXADDPAR, hdr, 'FILEDATE', '2009-06-10', 'last modif of the Zemax file';;
  
;  writefits,getenv('GPI_DRP_OUTPUT_DIR')+'zemax-'+filter+'-281-01-wavcal.fits',zemwavcal,hdr
endif else begin
  zemwavcal=readfits(Modules[thisModuleIndex].CalibrationFile)
endelse


;;;;;; Now we can compare DRP and Zemax wavelength solution 
; gpitve, wavcal2-zemwavcal & gpitv_activate
; if fix(Modules[thisModuleIndex].gpitv) ne 0 then stop ;gpitve, wavcal2-zemwavcal 
;absolute difference:
diff=wavcal2-zemwavcal
;relative difference:
diffrel=100.*(wavcal2-zemwavcal)/wavcal2
print, 'mean diff x=',mean(diff[*,*,0],/nan),'y=',mean(diff[*,*,1],/nan)
    ;let's calculate histograms
    xmax=0.5& xmin=-xmax 
    fac=100.
    bin=fac
    hist1x=HISTOGRAM(diff[*,*,0], min=xmin,max=xmax,nbins=bin,locations=loc)
    hist1y=HISTOGRAM(diff[*,*,1], min=xmin,max=xmax,nbins=bin,locations=loc)
    xmaxrel=50.& xminrel=-xmaxrel & binrel=10.*fac
    histcoef=HISTOGRAM(diffrel[*,*,3], min=xminrel,max=xmaxrel,nbins=binrel,locations=locrel)
    xmaxtilt=5.& xmintilt=-xmaxtilt & bintilt=10.*fac
    if (size(wavcal2))[3] eq 5 then slice=4 else slice=6 ;deal with slice# for Non-linear wavcal
    histtilt=HISTOGRAM((180./!dpi)*(wavcal2[*,*,slice]-zemwavcal[*,*,4]), min=xmintilt,max=xmaxtilt,nbins=bintilt,locations=loctilt)
    cumtilt=reform(wavcal2[*,*,slice]-zemwavcal[*,*,4],szwcdrp[1]*szwcdrp[2])
     histcumtilt=total(HISTOGRAM((180./!dpi)*abs(cumtilt), min=0.,max=xmaxtilt,nbins=bintilt,locations=loccumtilt),/cum)
     void=where(finite(histcumtilt),cfx)
     histcumtilt2=(100./max(histcumtilt))*histcumtilt
    
;now, let's plot these histograms
filnm=sxpar(*(DataSet.Headers[numfile]),'DATAFILE')
slash=strpos(filnm,path_sep(),/reverse_search)

h=*(dataset.headers[numfile])
testwav=SXPAR( h, 'TESTWAV',count=c1)
if c1 ne 0 then testchr='nbpk'+strc(n_elements(strsplit(testwav,'/'))) else testchr=''
suffixplot=(Modules[thisModuleIndex].suffix)
;    fnameps=getenv('GPI_DRP_OUTPUT_DIR')+strmid(filnm,slash,STRLEN(filnm)-5-slash)+suffixplot+filter+testchr+strc(zemwav)        
;  openps,fnameps+'dst.ps', xsize=17, ysize=27
  fnameps=getenv('GPI_DRP_OUTPUT_DIR')+'DRPtest01_'+filter+suffixplot        
  openps,fnameps+'.ps', xsize=17, ysize=27
  !P.MULTI = [0, 1, 4, 0, 0] 
  ;this following plot is the histogram of localization difference at a specific wavelength
  if 1 eq 0 then begin
      PLOT, loc,hist1x, $ 
       TITLE = 'Histogram of localization error ('+string(zemwav,format='(g4.3)')+'um) for '+filename+'-wav.-solution '+filter+' band', $ 
        XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
       XTITLE = 'localization difference (pix) , [bin_width='+string(((xmax-xmin)/fac),format='(F5.2)')+']', $ 
       YTITLE = 'Number of spectra of That Value' ,ystyle=9,linestyle=0 ,yrange=[0,max([hist1x,hist1y])] , xrange=[-1.,1.]      
      OPLOT,loc,hist1y,linestyle=1
        ;legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0      ;,position=[-145,300]
        legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0
        ;if c1 ne 0 then xyouts,-0.55,1000,'peak wav used:'+testwav 
  endif  
;    PLOT, locrel,histcoef, $ 
;   TITLE = 'Histogram of linear coefficient relative error ('+string(zemwav,format='(g4.3)')+'microns) for '+filename+'-wav.-solution '+filter+' band', $ 
;    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
;   XTITLE = 'Relative error [%] , [bin_width='+string(((xmaxrel-xminrel)/binrel),format='(F5.2)')+']', $ 
;   YTITLE = 'Number of spectra of That Value' ,ystyle=9,linestyle=0    
    
 

 ; we want to compare localizations at ALL wavelength of the band:     
 for zind=0,n_elements(zemdisplamraw)-1 do begin
  wavcalz=change_wavcal_lambdaref( wavcal1, zemdisplamraw[zind])
    zemwavcalz=fltarr(szwcdrp[1],szwcdrp[2],szwcdrp[3])
  zemwavcalz[*,*,0]=rotate(transpose(zemdispX2[*,*,zind]),2)+4.
  zemwavcalz[*,*,1]=rotate(transpose(zemdispY2[*,*,zind]),2)+4.
  diffz=wavcalz-zemwavcalz
    hist1xz=HISTOGRAM(diffz[*,*,0], min=xmin,max=xmax,nbins=bin,locations=loc)
    hist1yz=HISTOGRAM(diffz[*,*,1], min=xmin,max=xmax,nbins=bin,locations=loc)
    cumx=reform(diffz[*,*,0],szwcdrp[1]*szwcdrp[2])
    cumy=reform(diffz[*,*,1],szwcdrp[1]*szwcdrp[2])
  if zind ne 0 then begin
   histtotx+=hist1xz
   histtoty+=hist1yz
   histcumx=[histcumx,cumx]
   histcumy=[histcumy,cumy]
  endif else begin
   histtotx=hist1xz
   histtoty=hist1yz
   histcumx=cumx
   histcumy=cumy
  endelse
 endfor

    PLOT, loc,histtotx, $ 
   TITLE = 'Histogram of localization error (all spectral channels) for  '+filter+' band', $ 
    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'localization difference [detector pixels] , (bin_width='+string(((xmax-xmin)/binrel),format='(F6.3)')+')', $ 
   YTITLE = 'Number of spectra of That Value' ,ystyle=9,linestyle=0 ,yrange=[0,max([histtotx,histtoty])], charsize=1.5       
  OPLOT,loc,histtoty,linestyle=1
    ;legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0      ;,position=[-145,300]
    legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0
 
 histcumx2=total(HISTOGRAM(abs(histcumx), min=0.,max=2.*xmax,nbins=bin,locations=loccum),/cum)
 histcumy2=total(HISTOGRAM(abs(histcumy), min=0.,max=2.*xmax,nbins=bin,locations=loccum),/cum)
 void=where(finite(histcumx),cfx)
 void=where(finite(histcumy),cfy)
 histcumx3=(100./float(cfx))*histcumx2
 histcumy3=(100./float(cfy))*histcumy2

    PLOT, loccum,histcumx3, $ 
   TITLE = 'Cum. hist. of localization error (all wavelengths) for  '+filter+' band', $ 
    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'localization difference [detector pixels] , (bin_width='+string(((xmax-xmin)/binrel),format='(F6.3)')+')', $ 
   YTITLE = 'Cum. # of spectra of That Value [%]' ,ystyle=9,linestyle=0 ,yrange=[0,100] , charsize=1.5      
  OPLOT,loccum,histcumy3,linestyle=1
    ;legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0      ;,position=[-145,300]
    legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0
 xyouts,0.2,30,'80% spectral channels with  localizations error less than x:'+strc(loccum[value_locate(histcumx3,80.)],format='(f4.2)')+'pix  '+$
        'y:'+strc(loccum[value_locate(histcumy3,80.)],format='(f4.2)')+'pix'
  xyouts,0.2,20,'90% x:'+strc(loccum[value_locate(histcumx3,90.)],format='(f4.2)')+'pix  '+$
        '90% y:'+strc(loccum[value_locate(histcumy3,90.)],format='(f4.2)')+'pix'
        
        
           PLOT, loctilt,histtilt, $ 
   TITLE = 'Histogram of tilt error  '+filter+' band', $ 
    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'Tilt error [in degrees] , [bin_width='+string(((xmaxtilt-xmintilt)/bintilt),format='(F5.2)')+']', $ 
   YTITLE = 'Number of spectra of That Value' ,ystyle=9,linestyle=0 , xrange=[-5.,5.] , psym=10, charsize=1.5
   valmax=max(histtilt,maxind)
   maxat=loctilt[maxind] 
   int1=value_locate(histtilt[0:maxind], 0.5*valmax)
   int2=value_locate(histtilt[maxind:(n_elements(histtilt)-1)], 0.5*valmax)+maxind
   FWHM=  loctilt[int2]-loctilt[int1]
    xyouts, 1,valmax/2.,'max at='+strc(maxat,format='(3g0.2)')+'deg'+'  Fwhm='+strc(FWHM,format='(f4.2)')+'deg'
        
         PLOT, loccumtilt,histcumtilt2, $ 
   TITLE = 'Cum. hist. of tilt error '+filter+' band', $ 
    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'Tilt error (degrees) , [bin_width='+string(((xmaxtilt-xmintilt)/bintilt),format='(F5.2)')+']', $ 
   YTITLE = 'Cum. # of spectra of That Value [%]' ,ystyle=9,linestyle=0 ,yrange=[0,100] , charsize=1.5      
    ;legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0      ;,position=[-145,300]
    ;legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0
 xyouts,0.5,30,'80% specta with tilt error less than:'+strc(loccumtilt[value_locate(histcumtilt2,80.)],format='(f4.2)')+'degrees  '
  xyouts,0.5,20,'90% :'+strc(loccumtilt[value_locate(histcumtilt2,90.)],format='(f4.2)')+'degrees  '
    
   closeps  
print,'80% x:'+strc(loccum[value_locate(histcumx3,80.)],format='(f4.2)')+'pix  '+$
        'y:'+strc(loccum[value_locate(histcumy3,80.)],format='(f4.2)')+'pix'
print,'90% x:'+strc(loccum[value_locate(histcumx3,90.)],format='(f4.2)')+'pix  '+$
        '90% y:'+strc(loccum[value_locate(histcumy3,90.)],format='(f4.2)')+'pix'
print,'max at='+strc(maxat,format='(3g0.2)')+'deg'+'  Fwhm='+strc(FWHM,format='(f4.2)')+'deg'

  ;plot dispersion for a specific spectrum with coordinates (xs,ys)
  xs=140
  ys=140
  xwav=fltarr(n_elements(zemdisplamraw))
  ywav=fltarr(n_elements(zemdisplamraw))
  xwavzem=fltarr(n_elements(zemdisplamraw))
  ywavzem=fltarr(n_elements(zemdisplamraw))
  xzem=fltarr(n_elements(zemdisplamraw))
  yzem=fltarr(n_elements(zemdisplamraw))
  for ind=0,n_elements(zemdisplamraw)-1 do begin
    wavcalind=change_wavcal_lambdaref( wavcal1, zemdisplamraw[ind])
    xwav[ind]=wavcalind[xs,ys,0]
    ywav[ind]=wavcalind[xs,ys,1]
    wavcalind=change_wavcal_lambdaref( zemwavcal, zemdisplamraw[ind])
    xwavzem[ind]=wavcalind[xs,ys,0]
    ywavzem[ind]=wavcalind[xs,ys,1]
    zemdispX3=zemdispX2[*,*,ind]
    zemdispY3=zemdispY2[*,*,ind]
    xzem[ind]=(rotate(transpose(zemdispX3),2)+4.)[xs,ys]
    yzem[ind]=(rotate(transpose(zemdispY3),2)+4.)[xs,ys]
  endfor  

  openps,fnameps+'disp_x'+strc(xs)+'_y'+strc(ys)+testchr+'dst.ps', xsize=17, ysize=27
   !P.MULTI = [0, 1, 2, 0, 0] 
   PLOT, zemdisplamraw,xwav, $ 
   TITLE = 'Dispersion X  for '+filename+'-wav.-solution '+filter+' band', $ 
   ;XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'Wavelength (microms)', $ 
   YTITLE = 'X-coordinates [detector pixels]' ,ystyle=9,linestyle=0 ,yrange=[min([xwav,xwavzem,xzem]),max([xwav,xwavzem,xzem])]       
   ;oplot, zemdisplamraw, xwavzem,psym=1
   oplot, zemdisplamraw, xzem,psym=4
   ;legend, ['from detector image','from Zemax  linear wav solution','raw Zemax locations'],psym=[-0,1,4],  /bottom, /right
   legend, ['from detector image','raw Zemax locations'],psym=[-0,4],  /bottom, /right
   xyouts,zemdisplamraw[4],xzem[34],'Maximal difference [detector pixels]= '+strcompress(string(max(abs(xwav-xzem))),/rem) 
   
   PLOT, zemdisplamraw,ywav, $ 
   TITLE = 'Dispersion Y  for '+filename+'-wav.-solution '+filter+' band', $ 
   ;XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'Wavelength (microms)', $ 
   YTITLE = 'Y-coordinates  [detector pixels]' ,ystyle=9,linestyle=0 ,yrange=[min([ywav,ywavzem,yzem]),max([ywav,ywavzem,yzem])]            
   ;oplot, zemdisplamraw, ywavzem,psym=1
   oplot, zemdisplamraw, yzem,psym=4
   ;legend, ['from detector image','from Zemax  linear wav solution','raw Zemax locations'],psym=[-0,1,4],  /bottom, /right
   legend, ['from detector image','raw Zemax locations'],psym=[-0,4],  /bottom, /right
   xyouts,zemdisplamraw[4],yzem[34],'Maximal difference [detector pixels]= '+strcompress(string(max(abs(ywav-yzem))),/rem)
   
  closeps 
   set_plot,'win'

 end