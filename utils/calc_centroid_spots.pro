function calc_centroid_spots,  x,y,image, maxaper, centroidaper,gauss=gauss
;define first sat. box
  x1=0>x- maxaper
  x2=x+ maxaper<((size(image))(1)-1)
  y1=0>y- maxaper
  y2=y+ maxaper<((size(image))(1)-1)


 
  badind=where(~FINITE(  image),cc)
  if cc ne 0 then  image(badind )=0 ;TODO:median value

  ;windowing 1 & max
  array= image[x1:x2,y1:y2]
  max1=max(array,location)
  ind1 = ARRAY_INDICES(array, location)
  ind1[0]=ind1[0]+x1
  ind1[1]=ind1[1]+y1
 
      
 
  hh=double(centroidaper) ; box for fit   'Barycent. centroid', 
  if keyword_set(gauss) then begin
  yfit = GAUSS2DFIT( image[ind1[0]-hh:ind1[0]+hh,ind1[1]-hh:ind1[1]+hh], paramgauss1)
  endif else begin
  centro=centroid(image[ind1[0]-hh:ind1[0]+hh,ind1[1]-hh:ind1[1]+hh])
  paramgauss1=[0.,0.,0.,0.,centro[0],centro[1]]
  endelse
    ; centroid coord:
  cen1=double(ind1) 
  ; cent coord in initial image coord
  cen1(0)=double(ind1(0))-hh+paramgauss1(4)
  cen1(1)=double(ind1(1))-hh+paramgauss1(5)
  
    if (~finite(cen1(0))) || (~finite(cen1(1))) || $
    (cen1(0) lt 0) || (cen1(0) gt (size(image))(1)) || $
    (cen1(1) lt 0) || (cen1(1) gt (size(image))(1))  then begin
       print, 'Warning: **** Satellite PSFs not well detected ****'

   endif
return, cen1

end