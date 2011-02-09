;+
; NAME: wavcalplots
; PIPELINE PRIMITIVE DESCRIPTION: plots using the wavelength solution
;
;	
;	
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	/Save	Set to 1 to save the output image to a disk file.
; KEYWORDS:
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: plots using the wavelength solution
; PIPELINE ARGUMENT: Name="ps_figure" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose # of saved fig suffix name, 0: no ps figure "
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-spec" Desc="Enter output suffix (fits)"
; PIPELINE ORDER: 2.51
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	
;   JM 2010-03 : created module.
;- 

function wavcalplots, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS

primitive_version= '$Id: wavcalplots.pro 96 2010-10-20 13:47:13Z maire $' ; get version from subversion to store in header history
	;getmyname, functionname
	  @__start_primitive

   	; save starting time
   	T = systime(1)

  	wavcal=*(dataset.currframe[0])

        band=strcompress(sxpar( *(dataset.headers[numfile]), 'FILTER',  COUNT=cc),/rem)
        if cc eq 1 then begin
          cwv=get_cwv(band)
          CommonWavVect=cwv.CommonWavVect
          lambda=cwv.lambda
          lambdamin=CommonWavVect[0]
          lambdamax=CommonWavVect[1]
          NLam=CommonWavVect[2]
        endif else begin
          NLam=0
          lambda=(indgen((size(main_image_stack))[3]))
        endelse
	
	thisModuleIndex = Backbone->GetCurrentModuleIndex()

 
;;;;;estimate spectral resolution from H-band Argon lamp image 
h=*(dataset.headers[0])
obstype=SXPAR( h, 'OBSTYPE',count=c1)
lamp=SXPAR( h, 'GCALLAMP',count=c2)

 if strmatch(obstype, '*wavecal*') && strmatch(lamp, '*Argon*') then begin
endif
 
tilt3= (180./!dpi)*(wavcal[*,*,4])
w3=((wavcal[*,*,0]-shift(wavcal[*,*,0],0,1)))
w3m=mean(w3)
dp=((sqrt( (wavcal[*,*,0]-shift(wavcal[*,*,0],2,-1))^2 + (wavcal[*,*,1]-shift(wavcal[*,*,1],2,-1))^2) ))
dpm=mean(dp)
P3=sqrt(abs((dp-w3)/w3))
theta=(180./!dpi)*atan(1./P3)


tx=900
ty=900
plotc, tilt3, 3, tx,ty,'micro-lens','micro-lens','Tilt of spectra [degrees]'
plotc, w3, 4, tx,ty,'micro-lens','micro-lens','w [detector pixel]'
plotc, p3, 5, tx,ty,'micro-lens','micro-lens','P micro-pupil pattern'
plotc, ((180./!dpi)*p3 mod 180.), 6, tx,ty,'micro-lens','micro-lens','P micro-pupil pattern'
plotc, dp, 7, tx,ty,'micro-lens','micro-lens','distance between spectra [detector pixel]'
plotc, theta, 8, tx,ty,'micro-lens','micro-lens','distance between spectra [detector pixel]'
plotc, reform(wavcal[*,*,3]), 9, tx,ty,'micro-lens','micro-lens','coeef wavcal'

;
;window,Xsize=800, YSize=800
;;openps, 'tilt.ps', xsize=15,ysize=15
;in=where(~finite(image))
; image2=image
; image2[in]=0.
; image=image2
;
;ncolors=!D.Table_size
;position=[0.1,0.1,0.9,0.9]
;xsize=(position[2]-position[0])* !D.X_VSize
;ysize=(position[3]-position[1])* !D.Y_VSize
;xstart=position[0]* !D.X_VSize
;ystart=position[1]* !D.Y_VSize
;if !D.Name eq 'PS' then $
;tv, image, XSize=xsize, YSize=ysize, xstart, ystart $
;else $
;tv, Congrid(image,xsize, ysize), xstart, ystart
;erase, color=ncolors-1
;barposition=[32,32,52,292]/320.0
;imagePosition = [92,64,284,256]/320.0
;colorbar=Replicate(1B,20)# BIndGen(256)
;tvimage, BytScl(colorbar, Top=ncolors-2), Position=barPosition
;TVImage, BytScl(image, Top=ncolors-2), Position=imagePosition
;tvlct,255,255,255, ncolors-1
;;plot, [0, !D.Table_Size], YRange=[0,!D.Table_Size], $
;;      /NoData, Color=0, Position=barPosition, Xticks=1, $
;;      /NoErase, XStyle=1, YStyle=1, XTickFormat='(A1)', $
;;      YTicks=4
;plot, [0, !D.Table_Size], YRange=[-12,12], $
;      /NoData, Color=0, Position=barPosition, Xticks=1, $
;      /NoErase, XStyle=1, YStyle=1, XTickFormat='(A1)', $
;      YTicks=4,ytitle='Degrees', charsize=1.5
;plot, Indgen((size(image))[1]),Indgen((size(image))[2]), /NoData , $
;Position=imagePosition, /NoErase, $
;XStyle=1, YStyle=1, Color=0   ,Ytitle='micro-lens',Xtitle='micro-lens', charsize=1.5
;;closeps


;if (ps_figure gt 0.)  then begin
;  
; ; if numfile eq 0 then begin
; ;if ~file_test(psFilename) then begin
;    openps, psFilename
;    plot, xlam,photcomp, xtitle='Wavelength (um)', ytitle='Intensity',psym=-1, yrange=[0,1.3*max(photcomp)]
;    if strmatch(obstype, '*wavecal*') then $
;    for i=0L,gct-1 do  plots, wavelen[wg[[i,i]]], max(photcomp)*[0, strength[wg[i]]], color=fsc_color('blue'), /clip
;    xyouts,xlam[3], 1.2*max(photcomp), 'Median spectrum of '+strc((size(inda))[2])+' spectra centered on mlens ['+strc(x0,format='(I3)')+','+strc(y0,format='(I3)')+']'
;     if n_elements(specres) gt 0 then xyouts,xlam[3], 1.1*max(photcomp), 'Spectral Resolution='+strc(specres, format='(g5.3)') 
;;  endif else begin
;;  set_plot,'ps'
;;    oplot, xlam,photcomp
;;  endelse
;  ;if numfile eq 2 then begin
;    closeps
;    
; ; endif
;  set_plot,'win'
;endif 
;suffix+='-spec'


lamzem=readfits('E:\testsvn3\DST\zemdispLamH.fits')
zemY=readfits('E:\testsvn3\DST\zemdispXH.fits')+1024.
zemX=readfits('E:\testsvn3\DST\zemdispYH.fits')+1024.
shiftx=5
shifty=-5
zemX0=shift(zemX[*,*,0], shiftx,shifty)
zemY0=shift(zemY[*,*,0], shiftx,shifty)
    zemtheoX=zemx
      zemtheoY=zemy
      zemtilt=(180./!dpi)*atan((zemtheoY[*,*,36]-zemtheoY[*,*,0])/(zemtheoX[*,*,36]-zemtheoX[*,*,0]))
      zemw=zemy[*,*,0]-shift(zemy[*,*,0],0,1)
      dpzem=sqrt( (zemx[*,*,0]-shift(zemx[*,*,0],-1,2))^2 + ((zemy[*,*,0]-shift(zemy[*,*,0],-1,2))^2)) 
      zemP=sqrt(abs((dpzem[*,*]-zemw[*,*])/zemw[*,*]))      
      theta_zem=(180./!dpi)*atan(1./zemP)
      pl=30
      coefzem=(lambda[pl]-lambda[0])/(sqrt((zemX[*,*,pl]-zemX[*,*,0])^2+(zemY[*,*,pl]-zemY[*,*,0])^2))
      
      indout=where(~finite(tilt3),cout)
      zemtilt2=rotate(transpose(zemtilt),2)
      zemtilt2[indout]= !VALUES.F_NAN
      
      zemw2=rotate(transpose(zemw),2)
      zemw2[indout]= !VALUES.F_NAN
      
      dpzem2=rotate(transpose(dpzem),2)
      dpzem2[indout]= !VALUES.F_NAN
      
      zemp2=rotate(transpose(zemp),2)
      zemp2[indout]= !VALUES.F_NAN
      
      theta_zem2=rotate(transpose(theta_zem),2)
      theta_zem2[indout]= !VALUES.F_NAN
      
      coefzem2=rotate(transpose(coefzem),2)
      coefzem2[indout]= !VALUES.F_NAN
 ;plotc, zemtilt, 13, tx,ty,'Zemax micro-lens','Zemax  micro-lens','Tilt of spectra [degrees]'
 plotc, tilt3, 3, tx,ty,'micro-lens','micro-lens','Tilt of spectra [degrees]',valmin=valmin1,valmax=valmax1
  plotc, zemtilt2, 23, tx,ty,'Zemax micro-lens','Zemax  micro-lens','Tilt of spectra [degrees]',valmin=valmin1,valmax=valmax1

  plotc, zemw2, 24, tx,ty,'Zemax micro-lens','Zemax micro-lens','w [detector pixel]';,valmin=valmin2,valmax=valmax2
  plotc, w3, 4, tx,ty,'micro-lens','micro-lens','w [detector pixel]';,valmin=valmin2,valmax=valmax2

  plotc, dpzem2, 27, tx,ty,'Zemax micro-lens','Zemax micro-lens','Dispersion distance [detector pixel]',valmin=valmin2,valmax=valmax2
  plotc, dp, 7, tx,ty,'micro-lens','micro-lens','Dispersion distance [detector pixel]',valmin=valmin2,valmax=valmax2
  
  plotc, zemp2, 25, tx,ty,'Zemax micro-lens','Zemax micro-lens','P micro-pupil pattern';,valmin=valmin3,valmax=valmax3
    plotc, p3, 5, tx,ty,'micro-lens','micro-lens','P micro-pupil pattern';,valmin=valmin3,valmax=valmax3
  
plotc, ((180./!dpi)*zemp2 mod 180.), 26, tx,ty,'Zemax micro-lens','Zemax micro-lens','P micro-pupil pattern',valmin=valmin4,valmax=valmax4
plotc, ((180./!dpi)*p3 mod 180.), 6, tx,ty,'micro-lens','micro-lens','P micro-pupil pattern',valmin=valmin4,valmax=valmax4

plotc, theta_zem2, 28, tx,ty,'Zemax micro-lens','Zemax micro-lens','Theta [degree]',valmin=valmin6,valmax=valmax6
plotc, theta, 8, tx,ty,'micro-lens','micro-lens','Theta [degree]'  ,valmin=21.,valmax=22.


plotc, coefzem2, 29, tx,ty,'Zemax micro-lens','Zemax micro-lens','Dlambda [microms / detector pixel]',valmin=valmin9,valmax=valmax9
plotc, reform(wavcal[*,*,3]), 9, tx,ty,'micro-lens','micro-lens','Dlambda [microms / detector pixel]',valmin=valmin9,valmax=valmax9


hdr=*(dataset.headers[numfile])



	thisModuleIndex = Backbone->GetCurrentModuleIndex()
  

 
;drpPushCallStack, functionName

return, ok


end
