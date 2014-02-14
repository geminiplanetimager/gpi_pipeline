function find_sat_spots_all,im0,band=band,indx=indx,good=good,$
                            refinefits=refinefits,winap=winap,locs=locs,$
                            highpass=highpass,constrain=constrain
;+
; NAME:
;       find_sat_spots_all
; PURPOSE:
;       Find satellite spot locations in all cube slices
;
; EXPLANATION:
;       Identifies the locations of the satellite flux in all image
;       slices (where they can be found)
;
; Calling SEQUENCE:
;       res = find_sat_spots_all(im0,[band=band,good=good,cens=cens,warns=warns,/refinefits,/highpass,/constrain])
;
; INPUT/OUTPUT:
;       im0 - 3D image (must be consistent with a cube produced by the
;             gpi pipeline)
;       band - Band of the cube (some identifiable version of the band
;              name.  Defaults to 'H')
;       /refinefits - Rerun find_sat_spots on the locations found by
;                     extrapolating by wavelength
;       winap - Window size for finding sat spots (defaults to 20)
;       locs - If set, use these postions for the satellite spots,
;              rather than trying to auto-find.
;       indx - Index of slice to start with (defaults to zero)
;      
;       cens - 2x4xl array of sat spot center pixel locations
;
;       /highpass - High pass filter image used for initial sat spot
;                   finding
;       /constrain - Apply constraints on box sizes based on
;                    wavelength and apodizer
;
; OPTIONAL OUTPUT:
;       good - Indices of the slices where sat spots could be found
;
; EXAMPLE:
;
;
; DEPENDENCIES:
;	find_sat_spots.pro
;
; NOTES: 
;             
; REVISION HISTORY
;       Written  09/18/2012.  savransky1@llnl.gov 
;       11/13 - Added highpass option - ds
;       2/13/14 - Added /constrain option - ds
;-

;;check input
sz = size(im0,/dim)
if n_elements(sz) ne 3 then begin
   message,'Input must be 3D cube.',/continue
   return,-1
endif

;;clean up image
im = im0
badind = where(~FINITE(im),cc)
if cc ne 0 then im[badind] = 0

;;wavelength information
if not keyword_set(band) then band = 'H'
if n_elements(indx) eq 0 then indx = 0
cwv = get_cwv(band,spectralchannels=sz[2])
lambda = cwv.lambda
scl = lambda[indx]/lambda

if keyword_set(constrain) then begin
   bands = ['Y','J','H','K1','K2'];
   cvals = [49,56,53,57,57];
   cval = cvals(where(bands eq band))*lambda[indx]
endif else cval = 0

;;grab reference slice and find spots
s0 = im[*,*,indx]
if strcmp(band,'Y',/fold_case) then s0 *= hanning(sz[0],sz[1],alpha=0.01)
cens0 = find_sat_spots(s0, winap=winap,locs=locs,highpass=highpass,constrain=cval)
badcens = where(~finite(cens0),ct)
if n_elements(cens0) eq 1 || ct ne 0 then return, -1

;;convert cens0 to polar coords, scale and revert to cartesians
cens = dblarr(2,4,sz[2])
cens[*,*,indx] = cens0
c0 = (total(cens0,2)/4) # (fltarr(4)+1.)
;c0 = mean(cens0,dim=2) # (fltarr(4)+1.)
cens0p = cv_coord(from_rect=cens0 - c0,/to_polar)
for j=0,sz[2]-1 do if j ne indx then $
   cens[*,*,j] = cv_coord(from_polar=[cens0p[0,*],cens0p[1,*]/scl[j]],/to_rect) + c0

;;refine, if asked
if keyword_set(refinefits) then $
   for j=0,sz[2]-1 do if j ne indx then $
      cens[*,*,j] = find_sat_spots(im[*,*,j],locs=cens[*,*,j])

;;get rid of slices where satellites can't be found
bad = where(cens ne cens, badct)
if bad[0] ne -1 then begin
   bad = (array_indices(cens,bad))[2,*]
   bad = bad[uniq(bad,sort(bad))]
endif ;else bad = !null
good = findgen(sz[2])
if badct gt 0 then good[bad] = -1
good = good[where(good ne -1)]

return, cens

end
