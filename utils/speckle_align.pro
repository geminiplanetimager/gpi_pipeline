function speckle_align,cubein,refslice=refslice,band=band,locs=locs0,$
                       usefft=usefft,parmsarr=parmsarr,silent=silent, $
                       reverse=reverse
;+
; NAME:
;       speckle_align
; PURPOSE:
;       Rescale image slices such that speckles (and sat spots) are in
;       the same location in each slice.
;
; EXPLANATION:
;       Using the sat spots to identify the image center in a given
;       reference slice, spatially scale all other slices by the ratio
;       of central wavelengths, using either bicubic interpolation or
;       Fourier transform.
;
; Calling SEQUENCE:
;       res = speckle_align(cube,[refslice=refslice,band=band,locs=locs0,/usefft,parmsarr=parmsarr,/silent,/reverse])
;
; INPUT/OUTPUT:
;       cubein - #D image (must be consistent with cubes produced by
;                the gpi pipeline)
;       refslice - Index of reference slice (defaults to 0)
;       locs - 2x4 array of Sat spot locations.  If not set, are recalculated for refslice.
;       band - Cube spectral band (defaults to H)
;       /usefft - Use FFT method (defaults to interpolation)
;       parmsarr - Parm structure for FFT method (/usefft only)
;       /silent - Do not display info (/usefft only)
;       /reverse - Scale the other way (i.e., go from speckle aligned
;                  to signal aligned).
;      
;       res - Cube with all slices speckle aligned to reference slice.
;
; OPTIONAL OUTPUT:
;       None
;
; EXAMPLE:
;
;
; DEPENDENCIES:
;	fftscale.pro
;       get_cwv.pro
;       fidn_sat_spots.pro
;
; NOTES: 
;      
;             
; REVISION HISTORY
;       Written  2012. Based partially on code by Perrin, Maire and
;       Marois - ds
;       06.10.13 - added /reverse keyword - Tyler Barker
;-

;;cube dimensions
sz = double(size(cubein,/dim))
typ = size(cubein,/type)
if n_elements(sz) ne 3 then begin
   message,'You must supply a 3D image cube.',/continue
   return,-1
endif

;;by defulat use 0th slice as reference and assume H band
if n_elements(refslice) eq 0 then refslice = 0

;;get wavelength information and generate wavelengths
if not keyword_set(band) then band = 'H'
cwv = get_cwv(band,spectralchannels=sz[2])
lambda = cwv.lambda
if keyword_set(reverse) then scl = lambda/lambda[refslice] else $
   scl = lambda[refslice]/lambda

;;interpolating method:
if not keyword_set(usefft) then begin 
   ;;find sat spots of reference slice to get center
   if not keyword_set(locs0) then begin
      s0 = cubein[*,*,refslice]
      bad = where(~finite(s0),ct)
      if ct ne 0 then s0[bad] = 0
      locs =  find_sat_spots(s0)
   endif else begin
      locs = locs0
      if n_elements(locs) gt 8 then locs = locs[*,*,refslice]
   endelse

   ;;find coordinates of all finite points in reference slice
   goodmap = where(finite(cubein[*,*,refslice]))
   goodinds = array_indices(cubein[*,*,refslice],goodmap)
   c0 = (total(locs,2)/4) # (fltarr(n_elements(goodmap))+1.)
   coordsp = cv_coord(from_rect=goodinds - c0,/to_polar)

   out = make_array(sz,type=typ)
   for j=0,sz[2]-1 do begin
      if j ne refslice then begin 
         tmp = make_array(sz[0:1],type=typ) + !values.f_nan  
         coordsj = cv_coord(from_polar=[coordsp[0,*],coordsp[1,*]/scl[j]],/to_rect) + c0 
         tmp[goodmap] =  interpolate(cubein[*,*,j],coordsj[0,*],coordsj[1,*],cubic=-0.5) 
      endif else tmp = cubein[*,*,j] 
      out[*,*,j] = tmp 
   endfor

;;fftscale method:
endif else begin 
   if not keyword_set(parmsarr) then begin
      redoparms = 1
      parms = create_struct('padinit',0L,$
                            'padinit2',0L,$
                            'padfft',0L,$
                            'padfft2',0L,$
                            'scf',0d,$
                            'dimx',0L,$
                            'dimy',0L,$
                            'scx',0d,$
                            'scy',0d,$
                            'meilprec',0d)
      parmsarr = replicate(parms,sz[2])
   endif else begin
      redoparms = 0
      if n_elements(parmsarr) ne sz[2] then begin
         message,'Input parmsarr must have the same z dimension as input cube.',/continue
         return,-1
      endif
   endelse

   ;;remove NaNs from input
   in = make_array(sz[0] + (sz[0] mod 2.), sz[1] + (sz[1] mod 2.), sz[2])
   in[0:sz[0]-1,0:sz[1]-1,*] = cubein
   badmap = where(~FINITE(in))
   in[badmap] = 0.

   ;;apply scaling
   out = make_array(size(in,/dim),type=size(cubin,/type))
   for j = 0,sz[2]-1 do begin
      if j ne refslice then begin
         if redoparms then begin
            out[*,*,j] = fftscale(in[*,*,j],scl[j],scl[j],1e-7,parms=tmp,silent=silent)
            parmsarr[j] = temporary(tmp)
         endif else out[*,*,j] = fftscale(in[*,*,j],scl[j],scl[j],1e-7,parms=parmsarr[j],silent=silent)
      endif else out[*,*,j] = in[*,*,j]
   endfor

   ;;put NaNs back
   out[badmap] = !VALUES.F_NAN
   out = out[0:sz[0]-1,0:sz[1]-1,*]
endelse

return, out

end
