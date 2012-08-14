function smartshift, img0, dx, dy, nofftw=nofftwflag

;if dx mod 1. + dy mod 1. ne 0. then $
;   return, subpixelshift(img0,dx,dy,nofftw=nofftwflag) $
;else return, shift(img0,dx,dy)

;;temporary hack until I sort out subpixelshift - ds
 return, shift(img0,dx,dy)

end
