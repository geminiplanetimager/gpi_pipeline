function get_sat_fluxes,im0,band=band,good=good,cens=cens,warns=warns,$
                        gaussfit=gaussfit,refinefits=refinefits,$
                        winap=winap,gaussap=gaussap,locs=locs,indx=indx
;+
; NAME:
;       get_sat_fluxes
; PURPOSE:
;       Extract peak fluxes of satellite spots in a gpi image cube
;
; EXPLANATION:
;       Identifies the locations of the satellite flux in all image
;       slices (where they can be found) and extracts either the raw
;       or fit maximum flux
;
; Calling SEQUENCE:
;       res = get_sat_fluxes(im0,[band=band,good=good,cens=cens,warns=warns,/gaussfit,/refinefits])
;
; INPUT/OUTPUT:
;       im0 - 3D image (must be consistent with a cube produced by the
;             gpi pipeline)
;       band - Band of the cube (some identifiable version of the band
;              name.  Defaults to 'H')
;       /gaussfit - Rather than extracting the raw pixel maximum,
;                   return the maximum of a 2D gaussian fit to the
;                   satellite spot pixels
;       /refinefits - Rerun find_sat_spots on the locations found by
;                     extrapolating by wavelength
;       winap - Window size for finding sat spots (defaults to 20)
;       gaussap - half length of gaussian box (defaults to 7)
;       locs - If set, use these postions for the satellite spots,
;              rather than trying to auto-find.
;       indx - Index of slice to start with (defaults to zero)
;      
;       res - 4xl array of satellite spot max fluxes (where l is the
;             number of slices in im0)
;
; OPTIONAL OUTPUT:
;       good - Indices of the slices where sat spots could be found
;       cens - 2x4xl array of sat spot center pixel locations
;       warns - Array of warning flags.  0 = no warning, 1 = fluxes
;               vary by more than 25%, -1 = sat spots could not be
;               found
;
; EXAMPLE:
;
;
; DEPENDENCIES:
;	find_sat_spots.pro
;
; NOTES: 
;      curvefit (called by gauss2dfit) is finicky. you will get tons
;      of convergence errors and bad fit messages.  However, the code
;      will attempt to compensate you, and, if failing, will replace
;      bad values with the pixel max.
;
;      Refining the center locations typically moves them by less than
;      0.1 pixels in each dimension.  This has no effect at all on the
;      satellite spot values when using the pixel maximum, and a very
;      small effect when using the gaussian fit.
;             
; REVISION HISTORY
;       Written  08/02/2012. Based partially on code by Perrin and
;                            Maire - savransky1@llnl.gov 
;-

if not keyword_set(gaussap) then gaussap = 7.
if n_elements(indx) eq 0 then indx = 0

;;clean up image
im = im0
badind = where(~FINITE(im),cc)
if cc ne 0 then im[badind] = 0
sz = size(im,/dim)

;;wavelength information
if not keyword_set(band) then band = 'H'
cwv = get_cwv(band,spectralchannels=sz[2])
lambda = cwv.lambda
scl = lambda[indx]/lambda

;;grab first slice and find spots
s0 = im[*,*,indx]
cens0 = find_sat_spots(s0,lambda=lambda[indx], winap=winap,locs=locs)
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
      cens[*,*,j] = find_sat_spots(im[*,*,j],lambda = lambda[j],locs=cens[*,*,j])

;;get rid of slices where satellites can't be found
bad = where(cens ne cens, badct)
if bad[0] ne -1 then begin
   bad = (array_indices(cens,bad))[2,*]
   bad = bad[uniq(bad,sort(bad))]
endif ;else bad = !null
good = findgen(sz[2])
if badct gt 0 then good[bad] = -1
good = good[where(good ne -1)]

;;get satellite fluxes
ic_psfs = fltarr(4,sz[2])
warns = fltarr(sz[2])
if badct gt 0 then warns[bad] = -1

;;get the grids for the subap
generate_grids, fx, fy, gaussap, /whole
fr2 = fx^2 + fy^2
for j=0,n_elements(good)-1 do begin 
   for i=0,3 do begin

      ;;subimage = subarr(im[*,*,good[j]],gaussap,cens[*,i,good[j]],/zeroout)
      if keyword_set(gaussfit) then begin
         ;;   c0 = gaussap/2d - (round(cens[*,i,good[j]])-cens[*,i,good[j]])
         ;;   paramgauss = [median(subimage), max(subimage) - median(subimage), 3, 3, c0, 0]
         ;;   ;;paramgauss = [median(subimage), max(subimage), 3, 3, gaussap/2., gaussap/2., 0]
         ;;   yfit = gauss2dfit(subimage, paramgauss, /tilt)
         ;;   if total(abs(yfit - mean(yfit))) lt 1e-10 or paramgauss[1] lt 0 then begin
         ;;      print, 'Bad fit detected, trying again.'
         ;;      ;;retry with larger area
         ;;      subimage = subarr(im[*,*,good[j]],gaussap+2,cens[*,i,good[j]],/zeroout)
         ;;      paramgauss = [median(subimage), max(subimage), 3, 3, gaussap/2.+1., gaussap/2.+1., 0]
         ;;      yfit = gauss2dfit(subimage, paramgauss, /tilt)
         ;;      if total(abs(yfit - mean(yfit))) lt 1e-10 or paramgauss[1] lt 0 then begin 
         ;;         print,'Fitting failed.  Using maximum.'
         ;;         ic_psfs[i,good[j]]=max(subimage)
         ;;      endif else ic_psfs[i,good[j]] = total(paramgauss[0:1])
         ;;   endif else ic_psfs[i,good[j]] = total(paramgauss[0:1])

         ;;grab the subaperture and get the radial profile
         subim = interpolate(im[*,*,good[j]],fx+cens[0,i,good[j]],fy+cens[1,i,good[j]],cubic=-0.5)
         rs = dindgen((gaussap-1d)/2d)+1
         nth = max(rs)*2*!dpi
         th = dindgen(nth)/nth*2d*!dpi 
         mns = dblarr(n_elements(rs))
         for k = 0,n_elements(rs)-1 do begin
            x = rs[k]*cos(th)+gaussap/2. 
            y = rs[k]*sin(th)+gaussap/2. 
            mns[k] = mean(interpolate(subim,x,y,cubic=-0.5)) 
         endfor
         
         ;; find FWHM & sigma and define gaussian mask
         fwhm = 2d*interpol(rs,mns,max(subim)/2d)
         sig = fwhm/2d/sqrt(2d*alog(2d))
         gmsk = exp(-fr2/sig^2d/2d)

         ic_psfs[i,good[j]] = total(subim*gmsk)/total(gmsk*gmsk)   
      endif else ic_psfs[i,good[j]]=max(subarr(im[*,*,good[j]],gaussap,cens[*,i,good[j]],/zeroout))
   endfor
   if total(abs((ic_psfs[*,good[j]] - mean(ic_psfs[*,good[j]]))/mean(ic_psfs[*,good[j]])) gt 0.25) ne 0 then $
      warns[good[j]] = 1 
endfor 

return, ic_psfs

end
