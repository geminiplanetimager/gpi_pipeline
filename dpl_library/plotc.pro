;;this is a simple function for displaying some 2d data with colorbar
;may not work perfectly...
;
pro plotc, image, w, xsi,ysi,xtitle,ytitle,ztitle,valmin=valmin,valmax=valmax



window,w,Xsize=xsi, YSize=ysi
;openps, '', xsize=15,ysize=15
out=where(~finite(image),co)
in=where(finite(image))
 image2=image
 neg=where((image lt 0.),cn)
 
  if co gt 0 then image2[out]=0.
 if (cn gt 5) && (co gt 0) then image2[out]=min(min(image)) 
 image=image2

if ~keyword_set(valmin) then $
valmin=min(min(image[in]))
if ~keyword_set(valmax) then $
valmax=max(max(image[in]))


ncolors=!D.Table_size
position=[0.1,0.1,0.9,0.9]
xsize=(position[2]-position[0])* !D.X_VSize
ysize=(position[3]-position[1])* !D.Y_VSize
xstart=position[0]* !D.X_VSize
ystart=position[1]* !D.Y_VSize
if !D.Name eq 'PS' then $
tv, image, XSize=xsize, YSize=ysize, xstart, ystart $
else $
tv, Congrid(image,xsize, ysize), xstart, ystart
erase, color=ncolors-1
;barposition=[32,32,52,292]/320.0
barposition=[42,32,62,292]/320.0
imagePosition = [92,64,284,256]/320.0
colorbar=Replicate(1B,20)# BIndGen(256)
tvimage, BytScl(colorbar, Top=ncolors-2), Position=barPosition
TVImage, BytScl(image, Top=ncolors-2,min=valmin,max=valmax ), Position=imagePosition
tvlct,255,255,255, ncolors-1
;plot, [0, !D.Table_Size], YRange=[0,!D.Table_Size], $
;      /NoData, Color=0, Position=barPosition, Xticks=1, $
;      /NoErase, XStyle=1, YStyle=1, XTickFormat='(A1)', $
;      YTicks=4
plot, [0, !D.Table_Size], YRange=[valmin,valmax], $
      /NoData, Color=0, Position=barPosition, Xticks=1, $
      /NoErase, XStyle=1, YStyle=1, XTickFormat='(A1)', $
      YTicks=4,ytitle=ztitle, charsize=1.5
plot, Indgen((size(image))[1]),Indgen((size(image))[2]), /NoData , $
Position=imagePosition, /NoErase, $
XStyle=1, YStyle=1, Color=0   ,Ytitle=ytiltle,Xtitle=xtitle, charsize=1.3

end
;closeps
