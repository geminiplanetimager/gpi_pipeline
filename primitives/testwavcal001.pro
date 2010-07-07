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
; PIPELINE ARGUMENT: Name="ZemaxwavsolFile" Type="wavcal" Default="" Desc="Enter Zemax wav. sol. filename or leave it blank if not already calculated"
; PIPELINE ARGUMENT: Name="refwav" Type="float" Range="[0.8,2.4]" Default="1.65" Desc="Wavelength (microms) reference for Zemax/DRP comparison of spectra locations"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-ErrWavcal" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying wavcal file, 0: no display "
; PIPELINE ORDER: 2.5
; PIPELINE TYPE: ALL-SPEC 
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2010-07-06
;- 

function testwavcal001, DataSet, Modules, Backbone
primitive_version= '$Id: testwavcal001.pro 11 2010-07-07 15:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive

;;; First, if not already done, need to format the DST Zemax file as a DRP wavelength solution
rep=getenv('GPI_IFS_DIR')+path_sep()+'dst'+path_sep()

;filter='H'
;nlens=281
nlens=(size(*(dataset.currframe[0])))[1]
   wavcal1=*(dataset.currframe[0])
   zemwav=float(Modules[thisModuleIndex].refwav)
          filter = strcompress(sxpar( header ,'FILTER1', count=fcount),/REMOVE_ALL)
        if fcount eq 0 then filter = strcompress(sxpar( header ,'FILTER'),/REMOVE_ALL)
   
     zemdisplamraw=readfits(rep+'zemdispLam'+filter+'.fits')
     void=min(abs(zemdisplamraw-zemwav),zemwavind)
     wavcal2=change_wavcal_lambdaref( wavcal1, zemdisplamraw[zemwavind])

if (Modules[thisModuleIndex].CalibrationFile eq '') then begin
  zemdispYraw=readfits(rep+'zemdispX'+filter+'.fits')
  zemdispXraw=readfits(rep+'zemdispY'+filter+'.fits')

  
  zemdispY=(subarr(zemdispYraw,nlens))
  zemdispX=(subarr(zemdispXraw,nlens))

  tilt=dblarr(nlens,nlens)
  w3=dblarr(nlens,nlens)
  ;w3d=dblarr(nlens,nlens)
 for i=0,nlens-1 do begin
  for j=0,nlens-1 do begin
        tiltp=dblarr(n_elements(zemdisplamraw))
        w3p=dblarr(n_elements(zemdisplamraw))
    for p=0,n_elements(zemdisplamraw)-1 do begin
    tiltp(p)=atan((zemdispY[i,j,p]-zemdispY[i,j,0])/(zemdispX[i,j,p]-zemdispX[i,j,0]))
    w3p(p)=(zemdisplamraw[p]-zemdisplamraw[0])/(sqrt(((zemdispY[i,j,p]-zemdispY[i,j,0]))^2+(zemdispX[i,j,p]-zemdispX[i,j,0])^2))
        tilt[i,j]=median(tiltp)
    w3[i,j]=median(w3p)
  ;  w3d[i,j]=stddev(w3p)
    endfor
   endfor
  endfor
    

    ;wavcal1=readfits('E:\GPIdatabase\GPIreduced\dstsim_H_spec_025XennH-wavcal.fits')
    ;wavcal1=readfits('E:\GPIdatabase\GPIreduced\dstsim_H_spec_011XeH-wavcal.fits')
    
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
  if fix(Modules[thisModuleIndex].gpitv) ne 0 then gpitv, zemwavcal
  
  ;;create header
  mkhdr, hdr, zemwavcal
  FXADDPAR, hdr, 'NLENS', szwcdrp[1],'#lenslet'
  FXADDPAR, hdr, 'LAMBREF', zemdisplamraw[zemwavind],'wavelength reference'
  FXADDPAR, hdr, 'FILEINIT', 'zemdispX'+filter+'.fits', 'Zemax file used' 
  FXADDPAR, hdr, 'FILEDATE', '2009-06-10', 'last modif of the Zemax file';;
  
  writefits,'zemax-'+filter+'-281-01-wavcal.fits',zemwavcal,hdr
endif else begin
  zemwavcal=readfits(Modules[thisModuleIndex].CalibrationFile)
endelse



; gpitve, wavcal2-zemwavcal & gpitv_activate
 if fix(Modules[thisModuleIndex].gpitv) ne 0 then gpitv, wavcal2-zemwavcal 
diff=wavcal2-zemwavcal
diffrel=100.*(wavcal2-zemwavcal)/wavcal2

print, 'mean diff x=',mean(diff[*,*,0],/nan),'y=',mean(diff[*,*,1],/nan)

      xmax=0.5& xmin=-xmax 
    fac=100.
    bin=fac
    hist1x=HISTOGRAM(diff[*,*,0], min=xmin,max=xmax,nbins=bin,locations=loc)
    hist1y=HISTOGRAM(diff[*,*,1], min=xmin,max=xmax,nbins=bin,locations=loc)
       xmaxrel=50.& xminrel=-xmaxrel & binrel=10.*fac
    histcoef=HISTOGRAM(diffrel[*,*,3], min=xminrel,max=xmaxrel,nbins=binrel,locations=locrel)
       xmaxtilt=50.& xmintilt=-xmaxtilt & bintilt=10.*fac
    histtilt=HISTOGRAM((180./!dpi)*diff[*,*,4], min=xmintilt,max=xmaxtilt,nbins=bintilt,locations=loctilt)

filnm=sxpar(*(DataSet.Headers[numfile]),'DATAFILE')
slash=strpos(filnm,path_sep(),/reverse_search)

    fnameps=getenv('GPI_DRP_OUTPUT_DIR')+strmid(filnm,slash,STRLEN(filnm)-5-slash)+suffix+filter+strc(zemwav)+'.ps'        
  openps,fnameps, xsize=17, ysize=27
  !P.MULTI = [0, 1, 3, 0, 0] 
  PLOT, loc,hist1x, $ 
   TITLE = 'Histogram of localization error ('+string(zemwav,format='(g4.3)')+'microns) for '+filename+'-wav.-solution '+filter+' band', $ 
    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'localization difference (pix) , [bin_width='+string(((xmax-xmin)/fac),format='(F5.2)')+']', $ 
   YTITLE = 'Number of spectra of That Value' ,ystyle=9,linestyle=0 ,yrange=[0,max([hist1x,hist1y])]       
  OPLOT,loc,hist1y,linestyle=1
    ;legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0      ;,position=[-145,300]
    legend,['x-positions (spectral axis)','y-positions'],linestyle=[0,1],box=0
    
    PLOT, locrel,histcoef, $ 
   TITLE = 'Histogram of linear coefficient relative error ('+string(zemwav,format='(g4.3)')+'microns) for '+filename+'-wav.-solution '+filter+' band', $ 
    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'Relative error [%] , [bin_width='+string(((xmaxrel-xminrel)/binrel),format='(F5.2)')+']', $ 
   YTITLE = 'Number of spectra of That Value' ,ystyle=9,linestyle=0    
    
        PLOT, loctilt,histtilt, $ 
   TITLE = 'Histogram of tilt error ('+string(zemwav,format='(g4.3)')+'microns) for '+filename+'-wav.-solution '+filter+' band', $ 
    XTicklen=1.0, YTicklen=1.0, XGridStyle=1, YGridStyle=1, $
   XTITLE = 'Tilt error [in degrees] , [bin_width='+string(((xmaxtilt-xmintilt)/bintilt),format='(F5.2)')+']', $ 
   YTITLE = 'Number of spectra of That Value' ,ystyle=9,linestyle=0    
    
  closeps  
   set_plot,'win'

 end