pro radial_profile,im0,cens,lambda=lambda,rmax=rmax,rsum=rsum,$  ;;inputs
                   dointerp=dointerp,doouter=doouter,$           ;;options
                   imed=imed,isig=isig,imn=imn,asec=asec         ;;outputs
;+
; NAME:
;       radial_profile
; PURPOSE:
;       generate radialy averaged values for GPI image cube slices
;
; EXPLANATION:
;       Masks the core & all satellite spots and calculates the mean,
;       median, and/or standard deviation in radial slices of 1 pixel width.
;
; Calling SEQUENCE:
;       radial_profile,im0,cens,[lambda=lambda,rmax=rmax,rsum=rsum,/dointerp,/doouter,isig=isig,asec=asec]
;
; INPUT/OUTPUT:
;       im0 - 2D image (must be consistent with a cube slice produced by the
;             gpi pipeline)
;       cens - 2 x 4 element array of pixel locations of satellite spots
;       rmax - Maximum pixel radius to consider (defaults to 1.4 as ~
;              100 pix)
;       rsum - summing mask for interpolations (defaults to zero)
;       /dointerp - Use cubic interpolation (overrides rsum)
;       /doouter - Calculate curve for region outside of the dark hole
;      
; OPTIONAL OUTPUT:
;       imed - array of median values
;       imn - array of mean values
;       isig - array of 1 sigma values
;
; EXAMPLE:
;
;
; DEPENDENCIES:
;
;
; NOTES: 
;      Images must be pre-scaled for proper contrast calculation.
;      If /doouter is set, any returned arrays will be 2D with a
;      second dimension of 2 elements - the values inside and outside
;                                       the dark hole respectively.
;             
; REVISION HISTORY
;       Written  08/07/2012. Based partially on code by Perrin and
;                            Maire - savransky1@llnl.gov 
;-

  ;;defaults, sizes and scalings
  lambda0 = 1.5040541d
  if not keyword_set(lambda) then lambda = lambda0
  sz = size(im0,/dim)
  cent = [mean(cens[0,*]),mean(cens[1,*])]
  scl = 0.12d;;*lambda/lambda0 ;temporary hack to work with gpitv

  pixscl = gpi_get_setting('ifs_lenslet_scale')
  if ~strcmp(pixscl,'ERROR',/fold_case) then pixscl = double(pixscl) else $
     pixscl = 0.014d

  pix_to_ripple = gpi_get_setting('pix_to_ripple')
  if ~strcmp(pix_to_ripple,'ERROR',/fold_case) then pix_to_ripple = double(pix_to_ripple)*lambda/lambda0 else $
       pix_to_ripple = 44d*lambda*1d-6/8d * 180d/!dpi*3600d/pixscl

  memsrot = gpi_get_setting('mems_rotation')
  if ~strcmp(memsrot,'ERROR',/fold_case) then memsrot = double(memsrot)*!dpi/180d else $
     memsrot = 1d*!dpi/180d

  if n_elements(rmax) eq 0 then rmax = ceil(1.4/pixscl)
  if n_elements(rsum) eq 0 then rsum = 0.

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

     ;;have to mask the outer satellites as well
     c0 = cent # (fltarr(4)+1.)
     censp = cv_coord(from_rect=cens - c0,/to_polar)
     cens2 = cv_coord(from_polar=[censp[0,*],2*censp[1,*]],/to_rect) + c0
     bad = where(cens2 lt 0 or cens2 gt sz[0]-1,ct)
     if ct gt 0 then begin 
        bad = array_indices(cens2,bad)
        cens2[*,bad[1,*]] = !values.d_nan
     endif
     for j=0,3 do if finite(cens2[0,j]) then $
        dh_out[round(cens2[0,j]+tmp[*,0]),round(cens2[1,j]+tmp[*,1])] = !values.d_nan
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
     if (rsum eq 0.) then begin 
        mask = 1. 
        imask = 0L
     endif else begin
        ic0 = myaper(im,cent[0],cent[1],rsum,mask,imask)
        imask = imask - median(imask)
     endelse
     iall = dblarr(npts) + !values.d_nan
     if keyword_set(doouter) then iall2 = dblarr(npts) + !values.d_nan
     for n=0l,npts-1 do begin
        tmp = mask*im_dh[imask+ind[n]]
        tmp2 = where(tmp ne tmp,ct)
        if ct lt n_elements(mask) then iall[n] = total(tmp,/nan)
        if keyword_set(doouter) then begin 
           tmp = mask*im_o[imask+ind[n]]
           tmp2 = where(tmp ne tmp,ct)
           if ct lt n_elements(mask) then iall2[n] = total(tmp,/nan) 
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
     if (where(vals eq vals))[0] ne -1 then begin
        if arg_present(imed) then imed[j,0] = median(vals)
        if arg_present(imn) then imn[j,0] = mean(vals,/nan)
        if arg_present(isig) then isig[j,0] = robust_sigma(vals)
     endif

     if keyword_set(doouter) then begin
        if keyword_set(dointerp) then $
           vals = interpolate(im_o,x,y,cubic=-0.5) $
        else vals = iall2[i]
        if (where(vals eq vals))[0] ne -1 then begin
           if arg_present(imed) then imed[j,1] = median(vals)
           if arg_present(imn) then imn[j,1] = mean(vals,/nan)
           if arg_present(isig) then isig[j,1] = robust_sigma(vals)
        endif
     endif
  endfor

;;cleanup sigma if needed
if arg_present(isig) then begin
   weird = where(isig eq -1d,ct)
   if ct gt 0 then isig[weird] = !values.d_nan
endif

end

