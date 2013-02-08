;+
; NAME: localizepeak
;		calculate max and centroid to detect peak position
;
; INPUTS: 2D image from narrow band arclamp
; common needed:
;
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	 Jerome Maire 2008-10
;   JM 2010-08-16 : added badpixel map 
;   JM 2012-12-20 added more methods for centroid meas.
function localizepeak, im, cenx, ceny,wx,wy, hh, badpixmap=badpixmap, meth=meth
  
  
  szim=size(im)
;	x1=(cenx-wx) & x2=(cenx+wx)
;	y1=(ceny-wy) & y2=(ceny+wy)
  x1=floor(cenx-wx) & x2=ceil(cenx+wx)
  y1=floor(ceny-wy) & y2=ceil(ceny+wy)
  if (x1 eq x2) then x2+=1 
  if (y1 eq y2) then y2+=1 
;print, 'x1=', x1, '	y1=', y1, '	x2=', x2, '	y2=', y2
; to do outside this function:
;	badind=where(~FINITE( im),cc)
;	if cc ne 0 then im(badind )=0 ;TODO:median value
  
                                ;windowing 1 & max
  array=im(x1:x2,y1:y2)
  max1=max(array,location)
                                ;stop
  ind1 = ARRAY_INDICES(array, location)
  ind1(0)=ind1(0)+x1
  ind1(1)=ind1(1)+y1
  
;print, 'max at=',ind1
  
                                ;oversize=9.
                                ;yfit = mpfit2dpeak(im[ind1[0]-hh:ind1[0]+hh , ind1[1]-hh :ind1[1]+hh ], paramgauss0)
                                ;yfit = mpfit2dpeak(padarr(im[ind1[0]-hh:ind1[0]+hh , ind1[1]-hh :ind1[1]+hh ],oversize), paramgauss0)
                                ;yfit = GAUSS2DFIT(padarr(im[ind1[0]-hh:ind1[0]+hh , ind1[1]-hh :ind1[1]+hh ],oversize), paramgauss0)
                                ;paramgauss1=paramgauss0[4:5] ;- (oversize-hh)/2.
  cen1=double(ind1)
  
;	     if keyword_set(badpixmap) then begin
;          if total(badpixmap[ind1[0]-hh:ind1[0]+hh , ind1[1]-hh :ind1[1]+hh ]) eq 0. then begin
;          paramgauss1=gpicentroid( im[ind1[0]-hh:ind1[0]+hh , ind1[1]-hh :ind1[1]+hh ])
;
;          	;paramgauss1=centroid( im[ind1[0]-hh >0:ind1[0]+hh< (size(im))(1)-1 , ind1[1]-hh > 0:ind1[1]+hh < (size(im))(2)-1])
;          		; centroid coord:
;          
;          	; cent coord in initial image coord
;          ;	if (paramgauss1(4) ge 1) && (paramgauss1(4) lt szim(1)) then $
;          ;	cen1(0)=double(ind1(0))-hh+paramgauss1(4)
;          ;	if (paramgauss1(5) ge 1) && (paramgauss1(5) lt szim(2)) then $
;          ;	cen1(1)=double(ind1(1))-hh+paramgauss1(5)
;          	if (paramgauss1[0] ge 0) && (paramgauss1[0] le 2.*hh+1.) then $
;          	cen1[0]=double(ind1[0])-hh+paramgauss1(0)
;          	if (paramgauss1[1] ge 0) && (paramgauss1[1] le 2.*hh+1.) then $
;          	cen1[1]=double(ind1[1])-hh+paramgauss1[1]
;          endif else begin
;            cen1[0]=cenx & cen1[1]=ceny
;           endelse
; 
;        endif else begin
  if keyword_set(meth) && strmatch(meth,"barycentric") then begin
     paramgauss1=gpicentroid( im[ind1[0]-hh:ind1[0]+hh , ind1[1]-hh :ind1[1]+hh ])
     if (paramgauss1[0] ge 0) && (paramgauss1[0] le 2.*hh+1.) then $
        cen1[0]=double(ind1[0])-hh+paramgauss1[0] else $
           cen1[0]=-1
     if (paramgauss1[1] ge 0) && (paramgauss1[1] le 2.*hh+1.) then $
        cen1[1]=double(ind1[1])-hh+paramgauss1[1] else $
           cen1[1]=-1
  endif        
                                ;      endelse  
  if keyword_set(meth) && strmatch(meth,"mpfit") then begin
     sect=im[ind1[0]-hh:ind1[0]+hh, ind1[1]-hh :ind1[1]+hh] ; piece of interest in image
; set up a parinfo
; Fit the function
     parinfo = replicate({value:0.D, fixed:0, limited:[0,0], limits:[0.D,0],mpmaxstep:[0.D,0],parname:''},7)
     parinfo(0).parname='constant_offset'
     parinfo(0).value=min(sect,/nan)
     parinfo(0).fixed=0
;parinfo(0).limited[0]=1 & parinfo(0).limits[0]=max(sect,/nan)
;parinfo(0).limited[1]=0 & parinfo(0).limits[1]=min(sect,/nan)
     
     parinfo(1).parname='Amplitude'
     parinfo(1).value=abs(max(sect,/nan)-min(sect,/nan))
     parinfo(1).fixed=0
;parinfo(1).limited[0]=1 & parinfo(1).limits[0]=1e-12
;parinfo(1).limited[1]=0; & parinfo(1).limits[1]=1
     
     parinfo(2).parname='xwidth'
     parinfo(2).value=1.7/2.355
     parinfo(2).fixed=1
     
     parinfo(3).parname='ywidth'
     parinfo(3).value=1.7/2.355
     parinfo(3).fixed=1
     
     parinfo[4].parname='x_cen_pos'
     parinfo[4].value=hh+1.0
     parinfo[4].fixed=0
     parinfo[4].limited[0]=1 & parinfo[4].limits[0]=0.0 & parinfo[4].mpmaxstep=1.45
     parinfo[4].limited[1]=1 & parinfo[4].limits[1]=hh*2+hh/2
     
     parinfo(5).parname='y_cen_pos'
     parinfo(5).value=hh+1
     parinfo(5).fixed=0
     parinfo(5).limited[0]=1 & parinfo(5).limits[0]=0.0
     parinfo(5).limited[1]=1 & parinfo(5).limits[1]=hh*2+hh/2
     
     parinfo(6).parname='theta'
     parinfo(6).value=0
     parinfo(6).fixed=1
     
     delvarx,paramgauss0
     
     yfit = mpfit2dpeak(sect, paramgauss0, parinfo=parinfo,status=status,weights=1.0,/gaussian)
     if status eq 0 then paramgauss0[4:5]=[-1,-1]
     paramgauss1=paramgauss0[4:5] 
     
                                ;window,3,retain=2
                                ;loadct,0             
                                ;tvdl,sect,/no_int
                                ;stop, 'inside localizepeak'     
     if (paramgauss1[0] ge 0) && (paramgauss1[0] le 2.*hh+1.) then $
        cen1[0]=double(ind1[0])-hh+paramgauss1[0] else $
           cen1[0]=-1
     if (paramgauss1[1] ge 0) && (paramgauss1[1] le 2.*hh+1.) then $
        cen1[1]=double(ind1[1])-hh+paramgauss1[1] else $
           cen1[1]=-1
  endif
  
  if keyword_set(meth) && strmatch(meth,"gaussfit") then begin      
     oversize=9.
     yfit = GAUSS2DFIT(padarr(im[ind1[0]-hh:ind1[0]+hh , ind1[1]-hh :ind1[1]+hh ],oversize), paramgauss0)         
     paramgauss1=paramgauss0[4:5] - (oversize-hh)/2.+1.
     if (paramgauss1[0] ge 0) && (paramgauss1[0] le 2.*hh+1.) then $
        cen1[0]=double(ind1[0])-hh+paramgauss1[0] else $
           cen1[0]=-1
     if (paramgauss1[1] ge 0) && (paramgauss1[1] le 2.*hh+1.) then $
        cen1[1]=double(ind1[1])-hh+paramgauss1[1]      else $
           cen1[1]=-1  
  endif  
  
  
  return,cen1
  
end
