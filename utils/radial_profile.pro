pro radial_profile,im0,cens,lambda=lambda,rmax=rmax,rsum=rsum,$  ;;inputs
                   dointerp=dointerp,doouter=doouter,$           ;;options
                   imed=imed,isig=isig,imn=imn,asec=asec         ;;outputs

  ;;defaults, sizes and scalings
  if not keyword_set(lambda) then lambda = 1.5121622d
  sz = size(im0,/dim)
  cent = [mean(cens[0,*]),mean(cens[1,*])]
  scl = 0.12d*lambda/1.5121622d

  pixscl = gpi_get_setting('ifs_lenslet_scale')
  if ~strcmp(pixscl,'ERROR',/fold_case) then pixscl = double(pixscl) else $
     pixscl = 0.014d

  pix_to_ripple = gpi_get_setting('pix_to_ripple')
  if ~strcmp(pix_to_ripple,'ERROR',/fold_case) then pix_to_ripple = double(pix_to_ripple) else $
       pix_to_ripple = 44d*lambda*1d-6/8d * 180d/!dpi*3600d/pixscl

  memsrot = gpi_get_setting('mems_rotation')
  if ~strcmp(memsrot,'ERROR',/fold_case) then memsrot = double(memsrot)*!dpi/180d else $
     memsrot = 1d*!dpi/180d

  if not keyword_set(rmax) then rmax = ceil(pix_to_ripple)
  if not keyword_set(rsum) then rsum = 1

  ;;mask satellites and center
  bsz = ceil(scl/pixscl*2d)
  if ~(bsz mod 2.) then bsz += 1d ;;want odd number of pixels to match centers well
  tmp = make_annulus(bsz)
  coresatmask = fltarr(sz[0],sz[1])+1d
  coresatmask[round(cent[0]+tmp[*,0]),round(cent[1]+tmp[*,1])] = !values.d_nan
  for j=0,3 do coresatmask[round(cens[0,j]+tmp[*,0]),round(cens[1,j]+tmp[*,1])] = !values.d_nan
  im = im0*coresatmask

  ;;generate mask for dark hole
  satang = atan((cens[1,*]-cent[1])/(cens[0,*]-cent[0]))
  satang[where(satang lt 0)] += !dpi/2d
  rotang = mean(satang) - memsrot
  rotMat = [[cos(rotang),sin(rotang)],$
            [-sin(rotang),cos(rotang)]]
  dhl = ceil(pix_to_ripple)*2
  x = ((findgen(dhl)/dhl*2-1.)/2. + 1./dhl/2.)*pix_to_ripple
  x = x ## (fltarr(dhl)+1.)
  y = reform(transpose(x),n_elements(x))
  x = reform(x,n_elements(x))
  dh_inds = rotMat ## [[x],[y]]
  dh_msk = fltarr(sz[0],sz[1]) + 1
  dh_msk[round(cent[0]+dh_inds[*,0]),round(cent[1]+dh_inds[*,1])] = 0
  dh_in = 1 - dh_msk
  dh_in[where(dh_in eq 0)] = !values.d_nan
  im_dh = im*dh_in
  if keyword_set(doouter) then begin
     dh_out = dh_msk
     dh_out[where(dh_out eq 0)] = !values.d_nan
     im_o = im*dh_out
  endif

  ;;figure out which pixels we'll be considering
  rs = dindgen(rmax - (bsz+1) + 1) + bsz + 1

  ;;calculate radial mean, median & sigma, as requested
  if arg_present(imed) then if keyword_set(doouter) then imed = dblarr(n_elements(rs),2) + !values.d_nan $
  else imed = dblarr(n_elements(rs)) + !values.d_nan
  if arg_present(isig) then if keyword_set(doouter) then isig = dblarr(n_elements(rs),2) + !values.d_nan $
  else isig = dblarr(n_elements(rs)) + !values.d_nan
  if arg_present(imn) then if keyword_set(doouter) then imn = dblarr(n_elements(rs),2) + !values.d_nan $ 
  else imn = dblarr(n_elements(rs)) + !values.d_nan
  if arg_present(asec) then asec = rs*pixscl
  
  ;;prepare for interpolation
  if keyword_set(dointerp) then begin
     nth = max(rs)*2*!dpi
     th = findgen(nth)/nth*2d*!dpi 
  endif else begin
     indices, im, r=rall, center = cent
     ind = where(rall le rmax + 1d/sqrt(2d), npts)
     rall = rall[ind]
     sind = sort(rall) & rall = rall[sind] & ind = ind[sind]
     
     ;;define interpolating mask & calculate intensities at each pixel
     ic0 = myaper(im,cent[0],cent[1],rsum,mask,imask)
     if (rsum eq 0.) then begin mask = 1. & imask = 0 & endif
     imask = imask - median(imask)
     iall = dblarr(npts) + !values.d_nan
     if keyword_set(doouter) then iall2 = dblarr(npts) + !values.d_nan
     for n=0l,npts-1 do begin 
        tmp = mask*im_dh[imask+ind[n]] 
        if n_elements(where(tmp ne tmp)) lt n_elements(mask) then iall[n] = total(tmp,/nan)
        if keyword_set(doouter) then begin
           tmp = mask*im_o[imask+ind[n]] 
           if n_elements(where(tmp ne tmp)) lt n_elements(mask) then iall2[n] = total(tmp,/nan)  
        endif 
     endfor
     rrall = round(rall)
  endelse

  ;;step through radii and calculate requested values
  for j = 0,n_elements(rs)-1 do begin
     if keyword_set(dointerp) then begin
        x = rs[j]*cos(th)+cent[0]
        y = rs[j]*sin(th)+cent[1]
        vals = interpolate(im_dh,x,y,cubic=-0.5) 
     endif else begin
        i = where(rrall eq rs[j],ct)
        if (ct eq 0)  then continue
        vals = iall[i]
     endelse
     if (where(vals eq vals))[0] eq -1 then continue
     
     if arg_present(imed) then imed[j,0] = median(vals)
     if arg_present(imn) then imn[j,0] = mean(vals,/nan)
     if arg_present(isig) then isig[j,0] = robust_sigma(vals)

     if keyword_set(doouter) then begin
        if keyword_set(dointerp) then $
           vals = median(interpolate(im_o,x,y,cubic=-0.5)) $
        else vals = iall2[i]
        if arg_present(imed) then imed[j,1] = median(vals)
        if arg_present(imn) then imn[j,1] = mean(vals,/nan)
        if arg_present(isig) then isig[j,1] = robust_sigma(vals)
     endif
  endfor

end

