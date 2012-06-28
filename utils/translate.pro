;+
; NAME: translate
;
;	Shift an image by [dx, dy], with rotation, using cubic interpolation
;
; INPUTS:
; 	im		either a 2d or 3d image
; 	dx, dy	shifts. Can be fractional pixels I believe.
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;   2007 JM
; 	2008-01-18 MDP: Change array indexing to use zero syntax for speedup
;-

function translate,im,dx,dy,missing=missing

;shift avec rot

if (size(im))[0] le 2 then begin

  if (dx eq 0 and dy eq 0) then return,im
  if n_params() lt 3 then dy=0

  s=size(im) & dimx=s[1] & dimy=s[2]
  xc=(dimx-1)/2.0 & yc=(dimy-1)/2.0
  imt=rot(im,0,1.0,xc-dx,yc-dy,missing=missing,cubic=-0.5)

endif
if (size(im))[0] eq 3 then begin

  if (dx eq 0 and dy eq 0) then return,im

  s=size(im) & dimx=s[1] & dimy=s[2] & dimz=s[3]
  xc=(dimx-1)/2.0 & yc=(dimy-1)/2.0

  imt=dblarr(dimx,dimy,dimz)

  for z=0,dimz-1 do begin
  imt[0,0,z]=rot(im(*,*,z),0,1.0,xc-dx,yc-dy,missing=missing,cubic=-0.5)
  print, 'translate slice no',z
  endfor

endif


return,imt
end
