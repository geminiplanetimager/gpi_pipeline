;+
; NAME: testpolcal
; PIPELINE PRIMITIVE DESCRIPTION: Test the polarization calibration measurement 
;
; INPUTS: 
;
;
; KEYWORDS:
; 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Test the algorithm of the polarization calibration measurement by comparing with DST-Zemax reference wavelength solution.
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-ErrPolcal" Desc="Enter suffix of figures names"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying wavcal file, 0: no display "
; PIPELINE ORDER: 4.3
; PIPELINE TYPE: ALL-POL 
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2010-10-28
;- 

function testpolcal001, DataSet, Modules, Backbone
primitive_version= '$Id: testpolcal001.pro 11 2010-10-28 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive
mydevice = !D.NAME
;;; First, if not already done, need to format the DST Zemax file as a DRP wavelength solution
rep=getenv('GPI_IFS_DIR')+path_sep()+'dst'+path_sep()

;filter='H'
;nlens=281
nlens=(size(*(dataset.currframe[0])))[3]
   wavcal1=*(dataset.currframe[0])
  
   ;zemwav=float(Modules[thisModuleIndex].refwav)
   h=*(dataset.headersPHU[0])
     bandeobs=gpi_simplify_keyword_value(SXPAR( h, 'IFSFILT',count=c4))
   if c4 eq 0 then bandeobs=SXPAR( h, 'IFSFILT',count=c4)  
case strcompress(bandeobs,/REMOVE_ALL) of
  'Y':zemwav=1.05
  'J':zemwav=1.25
  'H':zemwav=1.65
  'K1':zemwav=2.05
  'K2':zemwav=2.25
  else:zemwav=1.65
endcase  
   
   
   
          filter = gpi_simplify_keyword_value(strcompress(sxpar( h ,'IFSFILT', count=fcount),/REMOVE_ALL))
       ; if fcount eq 0 then filter = strcompress(sxpar( header ,'FILTER'),/REMOVE_ALL)
   
     zemdisplamraw=readfits(rep+'zemdispLam'+filter+'.fits')
     void=min(abs(zemdisplamraw-zemwav),zemwavind)
     print, 'Reference wav. at  ',zemdisplamraw[zemwavind] 
     ;wavcal2=change_wavcal_lambdaref( wavcal1, zemdisplamraw[zemwavind])

if (Modules[thisModuleIndex].CalibrationFile eq '') then begin
  zemdispraw=readfits(rep+'zemdisp_pol'+filter+'.fits')
  ;zemdispXraw=readfits(rep+'zemdispY'+filter+'.fits')

  
  ;zemdisp=(subarr(reform(zemdispraw[*,*,zemwavind,*]),nlens))
  zemdisp=reform(zemdispraw[*,*,zemwavind,*])
 ; zemdispX=(subarr(zemdispXraw,nlens))

;  tilt=dblarr(nlens,nlens)
;  w3=dblarr(nlens,nlens)
;  ;w3d=dblarr(nlens,nlens)
; for i=0,nlens-1 do begin
;  for j=0,nlens-1 do begin
;        tiltp=dblarr(n_elements(zemdisplamraw))
;        w3p=dblarr(n_elements(zemdisplamraw))
;      ;  if (abs(zemdispY[i,j,zemwavind]-1024.+1024.) lt 3.) && (abs(zemdispX[i,j,zemwavind]-1073.+1024.) lt 3.) then stop
;    for p=0,n_elements(zemdisplamraw)-1 do begin
;    tiltp(p)=atan((zemdispY[i,j,p]-zemdispY[i,j,zemwavind])/(zemdispX[i,j,p]-zemdispX[i,j,zemwavind]))
;    w3p(p)=abs(zemdisplamraw[p]-zemdisplamraw[zemwavind])/(sqrt(((zemdispY[i,j,p]-zemdispY[i,j,zemwavind]))^2+(zemdispX[i,j,p]-zemdispX[i,j,zemwavind])^2))
;        tilt[i,j]=median(tiltp)
;    w3[i,j]=median(w3p)
;  ;  w3d[i,j]=stddev(w3p)
;    endfor
;   endfor
;  endfor
    

    ;wavcal1=readfits('E:\GPIdatabase\GPIreduced\dstsim_H_spec_025XennH-wavcal.fits')
    ;wavcal1=readfits('E:\GPIdatabase\GPIreduced\dstsim_H_spec_011XeH-wavcal.fits')
    
     zemdispX=reform(zemdisp[*,*,0])+1024.  ;only one polar state
     zemdispY=reform(zemdisp[*,*,1])+1024. ;only one polar state
          indout=where(zemdispX le 0.,cz)
         if cz gt 0 then zemdispX[indout]=!VALUES.F_NAN 
         indout=where(zemdispX gt 2048.,cz)
         if cz gt 0 then zemdispX[indout]=!VALUES.F_NAN 
         indout=where(zemdispY le 0.,cz)
         if cz gt 0 then zemdispX[indout]=!VALUES.F_NAN 
         indout=where(zemdispY gt 2048.,cz)
         if cz gt 0 then zemdispX[indout]=!VALUES.F_NAN 
               indout=where(zemdisp[*,*,0]+1024. le 0.,cz) 
                if cz gt 0 then     zemdispY[indout]=!VALUES.F_NAN 
                indout=where(zemdisp[*,*,0]+1024. gt 2048.,cz)
                if cz gt 0 then     zemdispY[indout]=!VALUES.F_NAN 
                indout=where(zemdispY le 0.,cz)
                if cz gt 0 then     zemdispy[indout]=!VALUES.F_NAN 
                indout=where(zemdispY gt 2048.,cz)
                if cz gt 0 then     zemdispY[indout]=!VALUES.F_NAN  
           
     zemdispX2=reform(zemdisp[*,*,2])+1024.  ;only one polar state
     zemdispY2=reform(zemdisp[*,*,3])+1024. ;only one polar state
     indout=where(zemdispX2 le 0.,cz)
     if cz gt 0 then zemdispX2[indout]=!VALUES.F_NAN 
     indout=where(zemdispX2 gt 2048.,cz)
     if cz gt 0 then zemdispX2[indout]=!VALUES.F_NAN 
     indout=where(zemdispY2 le 0.,cz)
     if cz gt 0 then zemdispX2[indout]=!VALUES.F_NAN 
     indout=where(zemdispY2 gt 2048.,cz)
     if cz gt 0 then zemdispX2[indout]=!VALUES.F_NAN  
      indout=where(zemdisp[*,*,2]+1024. le 0.,cz) 
      if cz gt 0 then     zemdispY2[indout]=!VALUES.F_NAN 
      indout=where(zemdisp[*,*,2]+1024. gt 2048.,cz)
      if cz gt 0 then     zemdispY2[indout]=!VALUES.F_NAN 
      indout=where(zemdispY2 le 0.,cz)
      if cz gt 0 then     zemdispy2[indout]=!VALUES.F_NAN 
      indout=where(zemdispY2 gt 2048.,cz)
      if cz gt 0 then     zemdispY2[indout]=!VALUES.F_NAN  
          
            
  ;creation de la zem-wavcal au format DRP
  szwcdrp=size(wavcal1)
  zemwavcal=fltarr(szwcdrp[2],szwcdrp[3],4)
  zemwavcal[*,*,0]=transpose(zemdispX2[*,*]) ;rotate(transpose(zemdispX2[*,*]),1) ;+4.
  zemwavcal[*,*,1]=transpose(zemdispY2[*,*]);rotate(transpose(zemdispY2[*,*]),3) ;+4.
  zemwavcal[*,*,2]=transpose(zemdispX[*,*]) ;rotate(transpose(zemdispX2[*,*]),1) ;+4.
  zemwavcal[*,*,3]=transpose(zemdispY[*,*])
  ;zemwavcal[*,*,2]=zemdisplamraw[zemwavind]
;  zemwavcal[*,*,3]=rotate(transpose(w3),2)
;  zemwavcal[*,*,4]=rotate(transpose(tilt),2)
 ; gpitve, zemwavcal & gpitv_activate
 ; if fix(Modules[thisModuleIndex].gpitv) ne 0 then gpitve, zemwavcal 
  
  ;;create header
  mkhdr, hdr, zemwavcal
  FXADDPAR, hdr, 'NLENS', szwcdrp[1],'#lenslet'
  FXADDPAR, hdr, 'LAMBREF', zemdisplamraw[zemwavind],'wavelength reference'
  FXADDPAR, hdr, 'FILEINIT', 'zemdisp_pol'+filter+'.fits', 'Zemax file used' 
  FXADDPAR, hdr, 'FILEDATE', '2010-07-06', 'last modif of the Zemax file';;
  
 ; writefits,'zemax-pol-'+filter+'-281-01-wavcal.fits',zemwavcal,hdr
endif else begin
  zemwavcal=readfits(Modules[thisModuleIndex].CalibrationFile)
endelse


; gpitve, wavcal2-zemwavcal & gpitv_activate
; if fix(Modules[thisModuleIndex].gpitv) ne 0 then stop ;gpitve, wavcal2-zemwavcal
sz=size(zemwavcal)
 wavcal2=fltarr(sz[1],sz[2],sz[3])
wavcal2[*,*,2]=reform(wavcal1[0,*,*,1])  ;only one polar state
wavcal2[*,*,1]=reform(wavcal1[1,*,*,0])  ;only one polar state
wavcal2[*,*,0]=reform(wavcal1[0,*,*,0])  
wavcal2[*,*,3]=reform(wavcal1[1,*,*,1]) 
;stop
diff=wavcal2-shift(subarr(zemwavcal,nlens),2,-1,0)
diffrel=100.*(wavcal2-zemwavcal)/wavcal2
print, 'mean diff x=',mean(diff[*,*,0],/nan),'y=',mean(diff[*,*,1],/nan)

      xmax=0.5& xmin=-xmax 
    fac=100.
    bin=fac
    hist1x=HISTOGRAM(diff[*,*,0], min=xmin,max=xmax,nbins=bin,locations=loc)
    hist1y=HISTOGRAM(diff[*,*,1], min=xmin,max=xmax,nbins=bin,locations=loc)
        hist2x=HISTOGRAM(diff[*,*,2], min=xmin,max=xmax,nbins=bin,locations=loc)
    hist2y=HISTOGRAM(diff[*,*,3], min=xmin,max=xmax,nbins=bin,locations=loc)
       xmaxrel=50.& xminrel=-xmaxrel & binrel=10.*fac
   ; histcoef=HISTOGRAM(diffrel[*,*,3], min=xminrel,max=xmaxrel,nbins=binrel,locations=locrel)
   ;    xmaxtilt=50.& xmintilt=-xmaxtilt & bintilt=10.*fac
   ;    if (size(wavcal2))[3] eq 5 then slice=4 else slice=6 ;deal with slice# for Non-linear wavcal
   ; histtilt=HISTOGRAM((180./!dpi)*(wavcal1[*,*,slice]-zemwavcal[*,*,4]), min=xmintilt,max=xmaxtilt,nbins=bintilt,locations=loctilt)

filnm=sxpar(*(DataSet.HeadersPHU[numfile]),'DATAFILE')
slash=strpos(filnm,path_sep(),/reverse_search)

h=*(dataset.headersPHU[numfile])
testwav=SXPAR( h, 'TESTWAV',count=c1)
if c1 ne 0 then testchr='nbpk'+strc(n_elements(strsplit(testwav,'/'))) else testchr=''
suffixplot=(Modules[thisModuleIndex].suffix)
    fnameps=getenv('GPI_DRP_OUTPUT_DIR')+'test2_'+strmid(filnm,slash+1,STRLEN(filnm)-5-slash)+suffixplot+filter+testchr+strc(zemwav)        
  openps,fnameps+'dst.ps', xsize=17, ysize=27
  !P.MULTI = [0, 1, 2, 0, 0] 
  PLOT, loc,hist1x, $ 
   TITLE = 'Histogram of localization error for !c'+filename+' '+filter+' band', $ 
    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'localization difference (pix) , [bin_width='+string(((xmax-xmin)/fac),format='(F5.2)')+']', $ 
   YTITLE = 'Number of lenslet of That Value' ,ystyle=9,linestyle=0 ,yrange=[0,max([hist1x,hist1y])] , xrange=[-1.,1.]      
  OPLOT,loc,hist1y,linestyle=1
  OPLOT,loc,hist2x,linestyle=2
  OPLOT,loc,hist2y,linestyle=3
    ;legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0      ;,position=[-145,300]
    legend,['Polar -- :x-positions (spectral axis)','y-positions','Polar | :x-positions (spectral axis)','y-positions'],linestyle=[0,1,2,3],box=0
    ;if c1 ne 0 then xyouts,-0.55,1000,'peak wav used:'+testwav 
    
;    PLOT, locrel,histcoef, $ 
;   TITLE = 'Histogram of linear coefficient relative error ('+string(zemwav,format='(g4.3)')+'microns) for '+filename+'-wav.-solution '+filter+' band', $ 
;    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
;   XTITLE = 'Relative error [%] , [bin_width='+string(((xmaxrel-xminrel)/binrel),format='(F5.2)')+']', $ 
;   YTITLE = 'Number of spectra of That Value' ,ystyle=9,linestyle=0    
    
;        PLOT, loctilt,histtilt, $ 
;   TITLE = 'Histogram of tilt error ('+string(zemwav,format='(g4.3)')+'microns) for '+filename+'-wav.-solution '+filter+' band', $ 
;    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
;   XTITLE = 'Tilt error [in degrees] , [bin_width='+string(((xmaxtilt-xmintilt)/bintilt),format='(F5.2)')+']', $ 
;   YTITLE = 'Number of spectra of That Value' ,ystyle=9,linestyle=0 , xrange=[-5.,5.] , psym=10
;   valmax=max(histtilt,maxind)
;   maxat=loctilt[maxind] 
;   int1=value_locate(histtilt[0:maxind], 0.5*valmax)
;   int2=value_locate(histtilt[maxind:(n_elements(histtilt)-1)], 0.5*valmax)+maxind
;   FWHM=  loctilt[int2]-loctilt[int1]
;    xyouts, 2,500,'max at='+strc(maxat,format='(3g0.2)')+'deg'+'  Fwhm='+strc(FWHM,format='(f4.2)')+'deg'
;

      
; for zind=0,n_elements(zemdisplamraw)-1 do begin
;  wavcalz=change_wavcal_lambdaref( wavcal1, zemdisplamraw[zind])
;    zemwavcalz=fltarr(szwcdrp[1],szwcdrp[2],szwcdrp[3])
;  zemwavcalz[*,*,0]=rotate(transpose(zemdispX2[*,*,zind]),2)+4.
;  zemwavcalz[*,*,1]=rotate(transpose(zemdispY2[*,*,zind]),2)+4.
;  diffz=wavcalz-zemwavcalz
;      hist1xz=HISTOGRAM(diffz[*,*,0], min=xmin,max=xmax,nbins=bin,locations=loc)
;    hist1yz=HISTOGRAM(diffz[*,*,1], min=xmin,max=xmax,nbins=bin,locations=loc)
;    cumx=reform(diffz[*,*,0],szwcdrp[1]*szwcdrp[2])
;    cumy=reform(diffz[*,*,1],szwcdrp[1]*szwcdrp[2])
;  if zind ne 0 then begin
;   histtotx+=hist1xz
;   histtoty+=hist1yz
;   histcumx=[histcumx,cumx]
;   histcumy=[histcumy,cumy]
;  endif else begin
;   histtotx=hist1xz
;   histtoty=hist1yz
;   histcumx=cumx
;   histcumy=cumy
;  endelse
; endfor
;
;    PLOT, loc,histtotx, $ 
;   TITLE = 'Histogram of localization error (all wavelengths) for '+filename+'-wav.-solution '+filter+' band', $ 
;    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
;   XTITLE = 'localization difference (pix) , [bin_width='+string(((xmax-xmin)/fac),format='(F5.2)')+']', $ 
;   YTITLE = 'Number of spectra of That Value' ,ystyle=9,linestyle=0 ,yrange=[0,max([histtotx,histtoty])]       
;  OPLOT,loc,histtoty,linestyle=1
;    ;legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0      ;,position=[-145,300]
;    legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0
; 
 histcumx1=total(HISTOGRAM(abs(diff[*,*,0]), min=0.,max=2.*xmax,nbins=bin,locations=loccum),/cum)
 histcumy1=total(HISTOGRAM(abs(diff[*,*,1]), min=0.,max=2.*xmax,nbins=bin,locations=loccum),/cum)
  histcumx2=total(HISTOGRAM(abs(diff[*,*,2]), min=0.,max=2.*xmax,nbins=bin,locations=loccum),/cum)
 histcumy2=total(HISTOGRAM(abs(diff[*,*,3]), min=0.,max=2.*xmax,nbins=bin,locations=loccum),/cum)
 void=where(finite(abs(diff[*,*,0])),cfx)
 void=where(finite(abs(diff[*,*,1])),cfy)
  void=where(finite(abs(diff[*,*,2])),cfx2)
 void=where(finite(abs(diff[*,*,3])),cfy2)
 histcumx3=(100./float(cfx))*histcumx1
 histcumy3=(100./float(cfy))*histcumy1
  histcumx4=(100./float(cfx2))*histcumx2
 histcumy4=(100./float(cfy2))*histcumy2
; 
    PLOT, loccum,histcumx3, $ 
   TITLE = 'Cum. hist. of localization error  for !c'+filename+' '+filter+' band', $ 
    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'localization difference (pix) , [bin_width='+string(((xmax-xmin)/fac),format='(F5.2)')+']', $ 
   YTITLE = 'Cum. # of lenslet of That Value [%]' ,ystyle=9,linestyle=0 ,yrange=[0,100]       
  OPLOT,loccum,histcumy3,linestyle=1
  OPLOT,loccum,histcumx4,linestyle=2
  OPLOT,loccum,histcumy4,linestyle=3
    ;legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0      ;,position=[-145,300]
    legend,['Polar --:x-positions (spectral axis)','y-positions','Polar |:x-positions (spectral axis)','y-positions'],linestyle=[0,1,2,3],box=0
 xyouts,0.2,30,'Polar --:80% x:'+strc(loccum[value_locate(histcumx3,80.)],format='(f4.2)')+'pix  '+$
        'y:'+strc(loccum[value_locate(histcumy3,80.)],format='(f4.2)')+'pix'
  xyouts,0.2,20,'Polar --:90% x:'+strc(loccum[value_locate(histcumx3,90.)],format='(f4.2)')+'pix  '+$
        '90% y:'+strc(loccum[value_locate(histcumy3,90.)],format='(f4.2)')+'pix'
   closeps  
    SET_PLOT, mydevice ;set_plot,'win'
print,'80% x:'+strc(loccum[value_locate(histcumx3,80.)],format='(f4.2)')+'pix  '+$
        'y:'+strc(loccum[value_locate(histcumy3,80.)],format='(f4.2)')+'pix'
print,'90% x:'+strc(loccum[value_locate(histcumx3,90.)],format='(f4.2)')+'pix  '+$
        '90% y:'+strc(loccum[value_locate(histcumy3,90.)],format='(f4.2)')+'pix'
;print,'max at='+strc(maxat,format='(3g0.2)')+'deg'+'  Fwhm='+strc(FWHM,format='(f4.2)')+'deg'

  ;plot dispersion for a specific spectrum with coordinates (xs,ys)
;  xs=140
;  ys=140
;  xwav=fltarr(n_elements(zemdisplamraw))
;  ywav=fltarr(n_elements(zemdisplamraw))
;  xwavzem=fltarr(n_elements(zemdisplamraw))
;  ywavzem=fltarr(n_elements(zemdisplamraw))
;  xzem=fltarr(n_elements(zemdisplamraw))
;  yzem=fltarr(n_elements(zemdisplamraw))
;  for ind=0,n_elements(zemdisplamraw)-1 do begin
;    wavcalind=change_wavcal_lambdaref( wavcal1, zemdisplamraw[ind])
;    xwav[ind]=wavcalind[xs,ys,0]
;    ywav[ind]=wavcalind[xs,ys,1]
;    wavcalind=change_wavcal_lambdaref( zemwavcal, zemdisplamraw[ind])
;    xwavzem[ind]=wavcalind[xs,ys,0]
;    ywavzem[ind]=wavcalind[xs,ys,1]
;    zemdispX3=zemdispX2[*,*,ind]
;    zemdispY3=zemdispY2[*,*,ind]
;    xzem[ind]=(rotate(transpose(zemdispX3),2)+4.)[xs,ys]
;    yzem[ind]=(rotate(transpose(zemdispY3),2)+4.)[xs,ys]
;  endfor  
;
;  openps,fnameps+'disp_x'+strc(xs)+'_y'+strc(ys)+testchr+'dst.ps', xsize=17, ysize=27
;   !P.MULTI = [0, 1, 2, 0, 0] 
;   PLOT, zemdisplamraw,xwav, $ 
;   TITLE = 'Dispersion X  for '+filename+'-wav.-solution '+filter+' band', $ 
;   ;XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
;   XTITLE = 'Wavelength (microms)', $ 
;   YTITLE = 'X-coordinates [detector pixels]' ,ystyle=9,linestyle=0 ,yrange=[min([xwav,xwavzem,xzem]),max([xwav,xwavzem,xzem])]       
;   ;oplot, zemdisplamraw, xwavzem,psym=1
;   oplot, zemdisplamraw, xzem,psym=4
;   ;legend, ['from detector image','from Zemax  linear wav solution','raw Zemax locations'],psym=[-0,1,4],  /bottom, /right
;   legend, ['from detector image','raw Zemax locations'],psym=[-0,4],  /bottom, /right
;   xyouts,zemdisplamraw[4],xzem[34],'Maximal difference [detector pixels]= '+strcompress(string(max(abs(xwav-xzem))),/rem) 
;   
;   PLOT, zemdisplamraw,ywav, $ 
;   TITLE = 'Dispersion Y  for '+filename+'-wav.-solution '+filter+' band', $ 
;   ;XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
;   XTITLE = 'Wavelength (microms)', $ 
;   YTITLE = 'Y-coordinates  [detector pixels]' ,ystyle=9,linestyle=0 ,yrange=[min([ywav,ywavzem,yzem]),max([ywav,ywavzem,yzem])]            
;   ;oplot, zemdisplamraw, ywavzem,psym=1
;   oplot, zemdisplamraw, yzem,psym=4
;   ;legend, ['from detector image','from Zemax  linear wav solution','raw Zemax locations'],psym=[-0,1,4],  /bottom, /right
;   legend, ['from detector image','raw Zemax locations'],psym=[-0,4],  /bottom, /right
;   xyouts,zemdisplamraw[4],yzem[34],'Maximal difference [detector pixels]= '+strcompress(string(max(abs(ywav-yzem))),/rem)
;   
;  closeps 
;   set_plot,'win'

 end
