function find_sat_spots,s0,lambda=lambda

sz = size(s0,/dim)
if not keyword_set(lambda) then leg = 80d else leg = 80d * lambda/1.5121622

winap = 20
refpix = 11
generate_grids, fx, fy, refpix, /whole
fr = sqrt(fx^2 + fy^2)
ref = exp(-0.5*fr^2)

fourier_coreg,ref,s0,out

msk = make_annulus(winap)
locs = []
dists = []
cal_spots = []
val = max(out,ind)

counter = 0
while counter lt 100 do begin
   inds = array_indices(out,ind) 
   if n_elements(locs) ne 0 then dists = [dists,sqrt(total((locs - (inds # (fltarr(n_elements(locs)/2.)+1.)))^2.,1))] 
   locs = [[locs],[inds]] 
   if n_elements(dists) gt 1 then begin 
      tmp = where(dists gt leg - 2d and dists lt leg + 2d) 
      if tmp[0] ne -1 then begin 
         cal_spots = lonarr(n_elements(tmp)*2)
         for j=0,n_elements(tmp)-1 do cal_spots[j*2:(j+1)*2-1] = listind2comb(tmp[j]) 
         cal_spots = cal_spots[UNIQ(cal_spots, SORT(cal_spots))] 
         if n_elements(cal_spots) eq 4 then break 
      endif 
   endif 
   out[msk[*,0]+inds[0],msk[*,1]+inds[1]] = min(out)  
   val = max(out,ind)  
   counter += 1
endwhile

if counter eq 100 then begin
   message,'Could not locate satellites.',/continue
   return, -1
endif

locs = locs[*,cal_spots]
ap = winap
x1 = 0 > locs[0,*] - ap < sz[0] - 1
x2 = 5 > locs[0,*] + ap < sz[0] - 2
y1 = 0 > locs[1,*] - ap < sz[1] - 1
y2 = 5 > locs[1,*] + ap < sz[1] - 2

hh = 5.
cens = dblarr(2,4)
for i=0,3 do begin 
   array = s0[x1[i]:x2[i],y1[i]:y2[i]]

   max1=max(array,location)
   ind1 = ARRAY_INDICES(array, location)
   ind1[0] = hh > (ind1[0]+x1[i]) < (sz[0]-hh-1)
   ind1[1] = hh > (ind1[1]+y1[i]) < (sz[1]-hh-1) 
   subimage = s0[ind1[0]-hh:ind1[0]+hh,ind1[1]-hh:ind1[1]+hh]

   paramgauss = [median(subimage), max(subimage), 3, 3, hh, hh, 0]
   yfit = gauss2dfit(subimage, paramgauss, /tilt)

   ;;center coord in initial image coord
   cens[*,i] = double(ind1) - hh + paramgauss[4:5]
   
   ;;check for bad values
   if (~finite(cens[0,i])) || (~finite(cens[1,i])) || $
      (cens[0,i] lt 0) || (cens[0,i] gt sz[0]) || $
      (cens[1,i] lt 0) || (cens[1,i] gt sz[1]) then cens[*,i] = !VALUES.F_NAN
endfor

return, cens
end
