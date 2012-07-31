function speckle_align,cubein,refslice=refslice,band=band,parmsarr=parmsarr,silent=silent

;;cube dimensions
sz = double(size(cubein,/dim))
if n_elements(sz) ne 3 then begin
   message,'You must supply a 3D image cube.',/continue
   return,-1
endif

;;by defulat use 0th slice as reference and assume H band
if n_elements(refslice) eq 0 then refslice = 0
if not keyword_set(band) then band = 'H'
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

;;get wavelength information and generate wavelengths
cwv = get_cwv(band)
dl = cwv.CommonWavVect[1] - cwv.CommonWavVect[0]
dx = dl/sz[2]
lambda = dindgen(sz[2])/sz[2]*dl + cwv.CommonWavVect[0] + dx/2d

;;remove NaNs from input
in = make_array(sz[0] + (sz[0] mod 2.), sz[1] + (sz[1] mod 2.), sz[2])
in[0:sz[0]-1,0:sz[1]-1,*] = cubein
badmap = where(~FINITE(in))
in[badmap] = 0.

;;apply scaling
out = make_array(size(in,/dim),type=size(cubin,/type))
for j = 0,sz[2]-1 do begin
   if j ne refslice then begin
      scl = lambda[refslice]/lambda[j]
      if redoparms then begin
         out[*,*,j] = fftscale(in[*,*,j],scl,scl,1e-7,parms=tmp,silent=silent)
         parmsarr[j] = temporary(tmp)
      endif else out[*,*,j] = fftscale(in[*,*,j],scl,scl,1e-7,parms=parmsarr[j],silent=silent)
   endif else out[*,*,j] = in[*,*,j]
endfor

;;put NaNs back
out[badmap] = !VALUES.F_NAN
out = out[0:sz[0]-1,0:sz[1]-1,*]
return, out
   
end
