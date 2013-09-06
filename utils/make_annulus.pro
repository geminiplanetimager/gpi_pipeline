function make_annulus,d,di,alpha=alpha,rot=rot,overlap=overlap,center_pix=center_pix,mask=mask
;+
; NAME:
;       make_annulus
; PURPOSE:
;       Generate indices of annular regions.
;
; EXPLANATION:
;       Calculates the indicies of pixels in a circular region with an
;       optional central obscuration, or splits this region into
;       annuli both radially and sectionally with optional overlap and rotation.
;
; Calling SEQUENCE:
;       res = make_annulus(d,[di,alpha=alpha,rot=rot,overlap=overlap])
;
; INPUT/OUTPUT:
;       d - Outer diameter of circular region (pixels)
;       di - Inner diameter of circular region (pixels; defaults to 0)
;       alpha - If set, split each annulus into alpha-degree wedges
;       rot - Rotate starting position of wedges by rot degrees (does
;             nothing if alpha is not set)
;       overlap - Overlap wedges by a factor of overlap (does nothing
;                 if alpha is not set)
;      
;       res - If alpha is not set, nx2 array of pixel indices relative
;             to center pixel at [0,0].  If alpha is set, HDF5 pointer
;             array of n_i x 2 arrays of pixel indices for each of
;             i=0,N-1 wedges, where N ~ 360^\deg/alpha.
;
; OPTIONAL OUTPUT:
;       center_pix - Central pixel of equivalent ceil(d) x ceil(d)
;                    array
;       mask - Generate a mask of size ceil(d) x ceil(d) with the
;              entire region di to d set to 1 and everything else set
;              to zero.
;
; EXAMPLE:
;       inds = make_annulus(100,20,center_pix=c,mask=m)
;
; DEPENDENCIES:
;	
;
; NOTES: 
;       While the inputs can be in fractional pixels, the generated
;       annuli are strictly binary a pixel is either in the annulus or
;       outside it.
;
;       Even vs. odd number of pixels is very important.  If you
;       generate an odd number of pixel array and attempt to place it
;       around an even number of pixel center, you will be offset by
;       half a pixel, so pay attention.
;             
; REVISION HISTORY
;       Written  08/06/2012 - savransky1@llnl.gov 
;-

  if not keyword_set(di) then di = 0.
  if not keyword_set(rot) then rot = 0.
  if not keyword_set(overlap) then overlap = 0.

  if di ge d then begin
     message,'Inner diameter cannot be larger than the outer diameter.',/continue
     return,-1
  endif

  ;;we can deal with non integer pixels, but make sure we create an
  ;;array large enough to hold everything and calculate the center pixel
  dint = ceil(d)
  if dint mod 2 then center_pix = (dint-1)/2. else center_pix = dint/2. - 0.5
  
  ;;generate grid of distances from center pixel (0,0)
  x = (findgen(dint)/dint*2-1.)/2. + 1./dint/2. 
  x = x ## (fltarr(dint)+1.)
  x = x^2+transpose(x)^2.

  ;;find indices inside of outer diameter and outside of inner one
  inds = where((x le (0.5/dint*d)^2.) AND (x ge (0.5/dint*di)^2.))
  inds = array_indices(x,inds)
  inds -= center_pix
  inds = transpose(inds)

  if arg_present(mask) then begin
     mask = fltarr(dint,dint)
     mask[center_pix+inds[*,0],center_pix+inds[*,1]] = 1
  endif 

  ;;if required, generate wedges
  if keyword_set(alpha) then begin
     inds0 = inds
     alpha0 = 360./round(360./alpha)
     n = fix(360/alpha0)
     angs = ((findgen(n)*alpha0 + rot) * !pi/180.) mod (2*!pi)
     alpha0 *= !pi/180

     res = atan(inds0[*,1],inds0[*,0])
     res[where(res lt 0)] += 2*!pi

     inds = REPLICATE({IDL_H5_VLEN},n)
     for j=0,n-1 do begin
        ldiff = angs[j]-(alpha0*overlap)
        rdiff = angs[j]+alpha0*(1+overlap)
        tmp = inds0[where((res ge ldiff) and (res lt rdiff)),*]
        if ldiff lt 0 then tmp = [tmp,inds0[where(res gt (2*!pi + ldiff)),*]]    
        if rdiff gt 2*!pi then tmp = [tmp,inds0[where(res le (rdiff - 2*!pi)),*]]
        inds[j].pdata = PTR_NEW(tmp)
     endfor
  endif
  
  return, inds
end
