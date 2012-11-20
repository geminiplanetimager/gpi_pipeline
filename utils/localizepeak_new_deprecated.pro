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
function localizepeak, im, cenx, ceny,wx,wy, hh

;if wx eq 0 or wy eq 0 then message, "Input parameters wx or wy are 0 - can't localize a size-zero box!"

szim=size(im)
;	x1=(cenx-wx) & x2=(cenx+wx)
;	y1=(ceny-wy) & y2=(ceny+wy)
	x1=floor(cenx-wx)>0 & x2=ceil(cenx+wx)<szim[1]-1
	y1=floor(ceny-wy)>0 & y2=ceil(ceny+wy)<szim[2]-1
;print, 'x1=', x1, '	y1=', y1, '	x2=', x2, '	y2=', y2
; to do outside this function:
;	badind=where(~FINITE( im),cc)
;	if cc ne 0 then im(badind )=0 ;TODO:median value

	; find the maximum location inside the specified box
	; and get the corresponding coordinates in the full array
	array=im(x1:x2,y1:y2)
	max1=max(array,location)
	ind1 = ARRAY_INDICES(array, location)
	ind1[0]=ind1(0)+x1
	ind1[1]=ind1[1]+y1

;print, 'max at=',ind1
	;yfit = GAUSS2DFIT(im[ind1[0]-hh:ind1[0]+hh,ind1[1]-hh:ind1[1]+hh], paramgauss1)
	paramgauss1=centroid( im[ind1[0]-hh:ind1[0]+hh , ind1[1]-hh :ind1[1]+hh ])

	;paramgauss1=centroid( im[ind1[0]-hh >0:ind1[0]+hh< (size(im))(1)-1 , ind1[1]-hh > 0:ind1[1]+hh < (size(im))(2)-1])
		; centroid coord:
	cen1=double(ind1)
	; cent coord in initial image coord
;	if (paramgauss1(4) ge 1) && (paramgauss1(4) lt szim(1)) then $
;	cen1(0)=double(ind1(0))-hh+paramgauss1(4)
;	if (paramgauss1(5) ge 1) && (paramgauss1(5) lt szim(2)) then $
;	cen1(1)=double(ind1(1))-hh+paramgauss1(5)
	if (paramgauss1(0) ge 0) && (paramgauss1(0) le 2.*hh+1.) then $
	cen1(0)=double(ind1(0))-hh+paramgauss1(0)
	if (paramgauss1(1) ge 0) && (paramgauss1(1) le 2.*hh+1.) then $
	cen1(1)=double(ind1(1))-hh+paramgauss1(1)

;print, 'centroid=',cen1
return,cen1

end
