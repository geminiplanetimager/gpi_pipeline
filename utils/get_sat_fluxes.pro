function get_sat_fluxes,im0,band=band,good=good,cens=cens,warns=warns

;;clean up image
im = im0
badind = where(~FINITE(im),cc)
if cc ne 0 then im[badind] = 0
sz = size(im,/dim)

;;grab first slice and find spots
s0 = im[*,*,0]
cens0 = find_sat_spots(s0)

;;wavelength information
if not keyword_set(band) then band = 'H'
cwv = get_cwv(band,spectralchannels=sz[2])
lambda = cwv.lambda
scl = lambda[0]/lambda

;;convert cens0 to polar coords, scale and revert to cartesians
cens = dblarr(2,4,sz[2])
cens[*,*,0] = cens0
c0 = mean(cens0,dim=2) # (fltarr(4)+1.)
cens0p = cv_coord(from_rect=cens0 - c0,/to_polar)
for j=1,sz[2]-1 do cens[*,*,j] = cv_coord(from_polar=[cens0p[0,*],cens0p[1,*]/scl[j]],/to_rect) + c0

;;get rid of slices where satellites can't be found
bad = where(cens ne cens)
if bad[0] ne -1 then begin
   bad = (array_indices(cens,bad))[2,*]
   bad = bad[uniq(bad,sort(bad))]
endif else bad = []
good = findgen(sz[2])
good[bad] = -1
good = good[where(good ne -1)]
cens = cens[*,*,good]
sz[2] = n_elements(good)

;;get satellite fluxes
ic_psfs = fltarr(4,sz[2])
warns = fltarr(sz[2])
for j=0,sz[2]-1 do begin 
   for i=0,3 do ic_psfs[i,j]=total(subarr(im[*,*,j],7,cens[*,i,j],/zeroout)) 
   if total(abs((ic_psfs[*,j] - mean(ic_psfs[*,j]))/mean(ic_psfs[*,j])) gt 0.25) ne 0 then warns[j] = 1 
endfor 

return, ic_psfs

end
