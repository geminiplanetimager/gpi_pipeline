;+
; NAME: gpi_lsqr_mlens_extract_dep.pro
; 
; The following are code dependencies for gpi_lsqr_mlens_extract and gpi_img_xcorr for loading on parrallel nodes
;
; INPUTS: none
; 	
; KEYWORDS: none
; 	
; OUTPUTS: none
; 	
;	
; HISTORY:
;    Began 2014-01-13 by Zachary Draper
;-  

function combine_dith_spec,spec,spec2,spec3,w_stan

;combine spectra with staright forward splitting given non-uniform sampling 

	f=[[spec[1,*]],[spec2[1,*]],[spec3[1,*]]]

	l=[[spec[0,*]],[spec2[0,*]],[spec3[0,*]]]

	ids=sort(l)

	f = f[ids]
	l = l[ids]

	f_n = [0]
	l_n = [0]
	x=0
	;int = (w_stan[1]-w_stan[0])/2
	;for i=0,n_elements(w_stan) do begin
	;	ids = where((l gt w_stan[i]-int) and (l lt w_stan[i]+int),count)
	;	if (ids ne -1) then begin
	;		f_n = [f_n,(total(f[ids])/count)]
	;		l_n = [l_n,w_stan]
	;		x=x+1
	;	endif		
	;endfor
	;f_n = [1:*]
	;l_n = [1:*]

	;if (i ne x) then lens_spectrum = interpol(f,l,gpi_lambda)
	
stop
return,[[l_n],[f_n]]
end

function combine_spec,spec,spec2,spec3
	
	f=[[spec[1,*]],[spec2[1,*]],[spec3[1,*]]]

	l=[[spec[0,*]],[spec2[0,*]],[spec3[0,*]]]

	ids=sort(l)

return,[[l[ids]],[f[ids]]]
end

;--------------------------------------------------
; X-correlation for two images
pro twod_img_corr,img_a,img_b,range,resolution,xsft,ysft,corr,cm=cm
	;returns shift for image b in x and y to get image A
	
	x_arr = indgen((2*range)/resolution)*resolution-range
	y_arr = x_arr

	img_a=img_a/total(img_a)
	img_b=img_b/total(img_b)

	corr = fltarr(n_elements(x_arr),n_elements(y_arr))

	for i=0,n_elements(x_arr)-1 do begin
		x_off = x_arr[i]
		for j=0,n_elements(y_arr)-1 do begin
			y_off = y_arr[j]

			img_b_tmp = fftshift(img_b,x_off,y_off,/silent)
			
			corr[i,j] = total(img_b_tmp*img_a)
			;corr[i,j] = stddev(img_b_tmp-img_a)
			
		endfor
	endfor
	
	if(keyword_set(cm)) then begin 
		;centroid value
		s = size(corr, /dimensions)
   		totalm = total(corr)
   		xcm = total(total(corr,2)*indgen(s[0]))/totalm
   		ycm = total(total(corr,1)*indgen(s[1]))/totalm        
		xsft=(xcm*resolution)-range
		ysft=(ycm*resolution)-range
	endif else begin 
		;maximal value
		id = where_xyz(max(corr) eq corr,xind=xind,yind=yind)
		xsft=(xind*resolution)-range
		ysft=(yind*resolution)-range
	endelse

	xsft=xsft[0]
	ysft=ysft[0]

end

;--------------------------------------------------
; X-correlation for two images in perpandicular frame

pro twod_img_corr_perp,img_a,img_b,range,resolution,psft,del_x_best,corr,angle,cm=cm
	;returns shift for image b in x and y to get image A
	
	perp = indgen((2*range)/resolution)*resolution-range

	img_a=img_a/total(img_a)
	img_b=img_b/total(img_b)
	
	np = n_elements(perp)

	corr = fltarr(np)
	 
	for i=0,np-1 do begin
		x_off = (perp[i])*cos(2*!pi-angle)
		y_off = (perp[i])*sin(2*!pi-angle)

		img_b_tmp = fftshift(img_b,x_off,y_off,/silent)
		;print,x_off,y_off
		corr[i] = total(img_b_tmp*img_a)
	endfor
	
	if(keyword_set(cm)) then begin 
		;centroid value
   		pcm = total(total(corr)*indgen(np))/total(corr)   
		psft=(pcm*resolution)-range
	endif else begin 
		;maximal value
		id = where(corr eq max(corr))
		psft=perp[id]
	endelse

	psft=psft[0]

end

;--------------------------------------------------
;Lsqr extraction given reference images 

function gpi_spec_lsqr,sub_img,r_cube,resid=resid,spec=spec

	t3=systime(/seconds)
	sc = size(r_cube)

;correlation vector
	v=fltarr(sc[3])

	for i=0,sc[3]-1 do begin
		r_cube[*,*,i]=r_cube[*,*,i]/total(r_cube[*,*,i])
	endfor

	for i=0,sc[3]-1 do begin	
		v[i]=total(sub_img*r_cube[*,*,i])
	endfor

;create correlation matrix from cube
	C = fltarr(sc[3],sc[3])
	for i=0,sc[3]-1 do begin
		for j=0,sc[3]-1 do begin
			C[i,j] = total(r_cube[*,*,i]*r_cube[*,*,j],/DOUBLE)
		endfor
	endfor
	iC=invert(C,/DOUBLE)
	;iC=svd_invert(C,1e-7)
	;val=fltarr(sc[3])
	;idx=fltarr(sc[3])
	;w=fltarr(sc[3])
	;nnls, C, sc[3], sc[3], v, val, rnorm, w, idx, mode

;generate correlation vector and image solution
	tspec=[0]
	fspec=fltarr(sc[1],sc[2])
	for i=0,sc[3]-1 do begin
		val = total(v*iC[*,i])
		tspec=[tspec,val]
		fspec=fspec+r_cube[*,*,i]*val
	endfor
	tspec=tspec[1:*]
	;tspec=val
	
	t4=systime(/seconds)
	print,t4-t3,'gpi_spec_lsqr'
;exit with either value vector or residual image
;if (keyword_set(spec)) then return,tspec
;if (keyword_set(resid)) then return,sub_img-fspec

	return,{spec:tspec,resid:stddev(sub_img-fspec)}
end

;--------------------------------------------------
; Find amplifier to use for microphonics estimate.

function amp_micphn,inp

	microbox=fltarr(4)
	
	ampnum = floor((inp[0])/64)
	hblknum = floor((inp[1])/64)

	microbox[0:3]= [64*ampnum,64*(ampnum+1)-1,64*hblknum,64*(hblknum+1)-1]
	
return,microbox
end

;--------------------------------------------------
; Stitch microphonics images for residual

function stitch_images,img1,img2

	stitimg=img1+img2

	if total(where(img1 ne 0 and img2 ne 0)) ne -1 then begin
		stitimg[where(img1 ne 0 and img2 ne 0)] = stitimg[where(img1 ne 0 and img2 ne 0)]/2
	endif
	
return,stitimg
end

;--------------------------------------------------
; Get the PSF positions along the micro-spectra

function get_psf_pos,x_lens,y_lens,wavecal,lam_min,lam_max,r_step,del_lam,del_x,del_theta,x_off,y_off

	y0 = wavecal[x_lens,y_lens,0]+y_off[0]
	x0 = wavecal[x_lens,y_lens,1]+x_off[0]
	lam0 = wavecal[x_lens,y_lens,2]
	w3 = wavecal[x_lens,y_lens,3]
	theta = wavecal[x_lens,y_lens,4]

	y0 = y0+del_x*sin(2*!pi-theta)
	x0 = x0+del_x*cos(2*!pi-theta)
	
	theta=theta+del_theta

	if finite(w3) eq 0 or w3 eq 0 then return,[0,0,0]

	lam_min=lam_min-0.02

	r_min = (lam0-lam_max)/w3+del_lam
	r_max = (lam0-lam_min)/w3+del_lam

	x_min = r_min*sin(2*!pi-theta)+x0
	y_min = r_min*cos(2*!pi-theta)+y0

	r=[x_min,y_min]

	steps=floor(abs(r_min-r_max)/r_step)

	for i=1L,steps do begin
		r=[[r],[[(r_min+r_step*i)*sin(2*!pi-theta)+x0,(r_min+r_step*i)*cos(2*!pi-theta)+y0]]]
	endfor
	
	sign = -(r[1,*]-y0)/abs(r[1,*]-y0) 

	l=sign*sqrt((r[0,*]-x0[0])^2+(r[1,*]-y0[0])^2)*w3+lam0

return,[r,l]

end

;--------------------------------------------------
; Generate PSF cube

pro mk_psf_cube,psfcube,spectra,wavecal,para,steps,lens_x,lens_y,blank,x_sub1,x_sub2,y_sub1,y_sub2,PSFs_array,xsize,ysize,blank2,x_off,y_off,del_lam,del_x,del_theta

	;print,del_x,del_theta
	t3=systime(/seconds)
	spec_spix = [0,0,0,0,0]
	for i=0L,n_elements(lens_x)-1 do begin
		for j=0L,n_elements(lens_y)-1 do begin
			if finite(wavecal[lens_x[i],lens_y[j],0]) then begin
				psfpos = get_psf_pos(lens_x[i],lens_y[j],wavecal,para[0],para[1],steps,del_lam,del_x,del_theta,x_off,y_off)
				num = n_elements(psfpos[0,*])
				psflens = fltarr(5,num)
				psflens[0:1,*] = psfpos[0:1,*]
 				psflens[2,*] = lens_x[i]
				psflens[3,*] = lens_y[j]
				psflens[4,*] = psfpos[2,*]
				spec_spix = [[spec_spix],[psflens]]
				;print,[lens_x[i],lens_y[j]]
			endif
		endfor
	endfor
	spec_spix = spec_spix[*,1:*]

	;clean for positions within sub_img
	buff = 0
	spec_spix2 = spec_spix[*,where(spec_spix[0,*] gt x_sub1-buff and spec_spix[0,*] lt x_sub2+buff)]
	spec_spix3 = spec_spix2[*,where(spec_spix2[1,*] gt y_sub1-buff and spec_spix2[1,*] lt y_sub2+buff)]

;get psf reference images

	s=size(spec_spix3)

	psfcube=[[blank2]]
	tstimage=blank2
	spectra=[0,0,0,0,0]

	x_grid = rebin(findgen(xsize)+x_sub1,xsize,ysize)
	y_grid = rebin(reform(findgen(ysize)+y_sub1,1,ysize),xsize,ysize)

	lens_x = long(median(lens_x))
	lens_y = long(median(lens_y))

	;read in high-res of central microlens PSF for and use on whole sub_img
	ptr = gpi_highres_microlens_psf_get_local_highres_psf(PSFs_array,[lens_x,lens_y,0])
	if ptr_valid(PSFs_array[lens_x,lens_y]) then psf = *PSFs_array[lens_x,lens_y]
	
	common hr_psf_common, c_psf, c_x_vector_psf_min, c_y_vector_psf_min, c_sampling
	c_psf = (psf).values
	c_x_vector_psf_min = min((psf).xcoords)
	c_y_vector_psf_min = min((psf).ycoords)
	c_sampling=round(1/( ((psf).xcoords)[1]-((psf).xcoords)[0] ))

	;gpi_highres_microlens_psf_initialize_psf_interpolation, psf.values, psf.xcoords, psf.ycoords

	t3=systime(/seconds)
	for k=0L,s[2]-1 do begin
		;bin and position within sub image
		r1 = gpi_highres_microlens_psf_evaluate_detector_psf(x_grid,y_grid, [spec_spix3[0,k], spec_spix3[1,k], 1])
		r1 = r1/total(r1)

		tstimage=tstimage+r1
		psfcube = [[[psfcube]],[[r1]]]
		spectra = [[spectra],[[spec_spix3[2,k],spec_spix3[3,k],spec_spix3[4,k],spec_spix3[0,k],spec_spix3[1,k]]]]

	endfor
	t4=systime(/seconds)
	print,t4-t3,'mk_psf_cube'

	psfcube=psfcube[*,*,1:*]
	spectra=spectra[*,1:*]

	;stop

end

;--------------------------------------------------
; Generate a full model image from wavecal

function make_mdl_img,x_lens_cen,y_lens_cen,wavcal,para,steps,x_off,y_off,blank2,xsize,ysize,img,PSFs_array,spec_flx,spec_lam,del_x_best

		psfpos_cen = get_psf_pos(x_lens_cen,y_lens_cen,wavcal,para[0],para[1],steps,0,del_x_best,0,x_off,y_off)
		x_med = floor(mean(psfpos_cen[0,*]))
		y_med = floor(mean(psfpos_cen[1,*]))
		x_sub1 = x_med-ceil(xsize/2)+1
		x_sub2 = x_med+ceil(xsize/2)
		y_sub1 = y_med-ceil(ysize/2)+1
		y_sub2 = y_med+ceil(ysize/2)

		x_grid = rebin(findgen(xsize)+x_sub1,xsize,ysize)
		y_grid = rebin(reform(findgen(ysize)+y_sub1,1,ysize),xsize,ysize)

		imsz=size(img)
		if x_sub2 gt imsz[1]-1 or y_sub2 gt imsz[2]-1 or x_sub1 lt 0 or y_sub1 lt 0 then begin
			spec=[-1,-1]
			spec_img=blank2
			mic_img=blank2
			wcal_off=[0,0,0,0,0]
		endif

		sub_img=img[x_sub1:x_sub2,y_sub1:y_sub2]

		sbp = size(badpix)
		if (sbp[0] ne 0) then begin
			sub_img=sub_img*badpix[x_sub1:x_sub2,y_sub1:y_sub2]
		endif

	;find psf spot locations

		xr = 35
		yr = 43

		lens_x = (findgen(xr)-floor(xr/2))+x_lens_cen
		lens_y = (findgen(yr)-floor(yr/2))+y_lens_cen

		;print,del_x,del_theta
		spec_spix = [0,0,0,0,0]
		for i=0L,n_elements(lens_x)-1 do begin
			for j=0L,n_elements(lens_y)-1 do begin
				if finite(wavcal[lens_x[i],lens_y[j],0]) then begin
					psfpos = get_psf_pos(lens_x[i],lens_y[j],wavcal,para[0],para[1],steps,0,del_x_best,0,x_off,y_off)
					num = n_elements(psfpos[0,*])
					psflens = fltarr(5,num)
					psflens[0:1,*] = psfpos[0:1,*]
	 				psflens[2,*] = lens_x[i]
					psflens[3,*] = lens_y[j]
					psflens[4,*] = psfpos[2,*]
					spec_spix = [[spec_spix],[psflens]]
					;print,[lens_x[i],lens_y[j]]
				endif
			endfor
		endfor
		spec_spix = spec_spix[*,1:*]

		;clean for positions within sub_img
		spec_spix2 = spec_spix[*,where(spec_spix[0,*] gt x_sub1-2 and spec_spix[0,*] lt x_sub2+2)]
		spec_spix3 = spec_spix2[*,where(spec_spix2[1,*] gt y_sub1-2 and spec_spix2[1,*] lt y_sub2+2)]

	;get psf reference images

		s=size(spec_spix3)

		mdl_img=[[blank2]]

		x_grid = rebin(findgen(xsize)+x_sub1,xsize,ysize)
		y_grid = rebin(reform(findgen(ysize)+y_sub1,1,ysize),xsize,ysize)

		lens_x = long(median(lens_x))
		lens_y = long(median(lens_y))

		;read in high-res of central microlens PSF for and use on whole sub_img
		ptr = gpi_highres_microlens_psf_get_local_highres_psf(PSFs_array,[lens_x,lens_y,0])
		if ptr_valid(PSFs_array[lens_x,lens_y]) then psf = *PSFs_array[lens_x,lens_y]
	
		common hr_psf_common, c_psf, c_x_vector_psf_min, c_y_vector_psf_min, c_sampling
		c_psf = (psf).values
		c_x_vector_psf_min = min((psf).xcoords)
		c_y_vector_psf_min = min((psf).ycoords)
		c_sampling=round(1/( ((psf).xcoords)[1]-((psf).xcoords)[0] ))

		;stop
		for k=0L,s[2]-1 do begin

			r1 = gpi_highres_microlens_psf_evaluate_detector_psf(x_grid,y_grid, [spec_spix3[0,k], spec_spix3[1,k], 1])

			lam = spec_spix3[4,k]
			flx = interpol(spec_flx,spec_lam,lam)
			if (flx[0] lt 0) then flx = 0 else flx = flx[0]
			;print,flx
			mdl_img = mdl_img+(r1*flx*(steps/2))

		endfor
return,[[[mdl_img]],[[sub_img]]]

end

;--------------------------------------------------
; Extract spectra individual spectra

function spec_ext_amoeba,P,best=best
	t3=systime(/seconds)

	common img_spec_ext_common,com_struc

	wavecal=com_struc.wavecal
	para=com_struc.para
	steps=com_struc.steps
	lens_x=com_struc.lens_x
	lens_y=com_struc.lens_y
	blank=com_struc.blank
	x_sub1=com_struc.x_sub1
	x_sub2=com_struc.x_sub2
	y_sub1=com_struc.y_sub1
	y_sub2=com_struc.y_sub2
	PSFs_array=com_struc.PSFs_array
	xsize=com_struc.xsize
	ysize=com_struc.ysize
	blank2=com_struc.blank2
	micphncube=com_struc.micphncube
	sub_img=com_struc.sub_img
	micphn=com_struc.micphn
	badpix=com_struc.badpix
	iter=com_struc.iter

	iter=fix(iter)
	case iter of
		0: begin
			x_off=P[0]
			y_off=P[1]
			del_x=P[2]
			del_theta=P[3]
			del_lam=P[4]
		end
		1: begin
			x_off=com_struc.x_off
			y_off=com_struc.y_off
			del_x=P[0]
			del_theta=P[1]
			del_lam=P[2]
		end
		2: begin
			x_off=P[0]
			y_off=P[1]
			del_x=0
			del_theta=0
			del_lam=0
		end
	endcase
	mk_psf_cube,psfcube,spectra,wavecal,para,steps,lens_x,lens_y,blank,x_sub1,x_sub2,y_sub1,y_sub2,PSFs_array,xsize,ysize,blank2,x_off,y_off,del_lam,del_x,del_theta

	if (micphn eq 1) then begin
		r_cube = [[[micphncube]],[[psfcube]]] 
		ms=size(micphncube,/dimensions)
	endif else begin 
		r_cube = psfcube
		ms=[0,0,0]
	endelse

	s=size(r_cube,/dimensions)
	
	sbp = size(badpix)
	ids=[-1]
	w=fltarr(s[2])+1
	if (sbp[0] ne 0) then begin
		sub_badpix = badpix[x_sub1:x_sub2,y_sub1:y_sub2]
		for i=0,s[2]-1 do begin
			r_cube[*,*,i]=r_cube[*,*,i]*sub_badpix
			if (total(r_cube[*,*,i]) lt 0.8) then begin
				ids = [[ids],[i]]
			endif
			w[i]=total(r_cube[*,*,i])
		endfor
	endif
	
	id = where(~histogram(ids, min=0, max=s[2]-1))

	temp = gpi_spec_lsqr(sub_img,r_cube)
	spec = temp.spec
	resid=temp.resid
	spec = spec/w
;stop
	spec=spec[id]
	r_cube = r_cube[*,*,id]
	spectra = spectra[*,id]

	t4=systime(/seconds)
	print,t4-t3,'spec_ext_amoeba_primary'

	;check centering of wavecal and reference PSFs
	;window,0		
	;imdisp,sub_img,/axis
	;plots,[spec_spix3[0,*]-x_sub1],[spec_spix3[1,*]-y_sub1],psym=2
	;window,1
	;imdisp,tstimage*sub_badpix,/axis
	;plots,[spec_spix3[0,*]-x_sub1],[spec_spix3[1,*]-y_sub1],psym=2
	;stop

if (keyword_set(best)) then return,{r_cube:r_cube,spectra:spectra,spec:spec} else return,resid

end

;--------------------------------------------------
; Prep subsection of detector image for spectra extraction.

pro img_spec_ext_amoeba,x_lens_cen,y_lens_cen,img,PSFs_array,wavecal,spec,spec_img,mic_img,del_lam_best,del_x_best,del_theta_best,x_off,y_off,wcal_off,para,badpix,resid=resid,micphn=micphn,iter=iter

	t1=systime(/seconds)

	;tuning knobs

	xsize=16			;spectra sub image size
	ysize=34			; extracted for lsqr

	steps=2			;PSF seperation in pixel units approx lambda / D in all bands

	n_modes=8			;(number of fourier modes - 1) used for microphonics 

	if (micphn eq 1) then n_modes=n_modes else n_modes=0

	blank = fltarr(xsize+20,ysize+20)
	blank2 = fltarr(xsize,ysize)

;get psf positions from wave cal

	psfpos_cen = get_psf_pos(x_lens_cen,y_lens_cen,wavecal,para[0],para[1],steps,0,0,0,x_off,y_off)
	x_med = floor(mean(psfpos_cen[0,*]))
	y_med = floor(mean(psfpos_cen[1,*]))
	x_sub1 = x_med-ceil(xsize/2)+1
	x_sub2 = x_med+ceil(xsize/2)
	y_sub1 = y_med-ceil(ysize/2)+1
	y_sub2 = y_med+ceil(ysize/2)

	imsz=size(img,/dimensions)
	if x_sub2 lt imsz[0]-1 && y_sub2 lt imsz[1]-1 && x_sub1 gt 0 && y_sub1 gt 0 && x_sub1 lt x_sub2 && y_sub1 lt y_sub2 then begin
		sub_img=img[x_sub1:x_sub2,y_sub1:y_sub2]
		;print,'sub image'
	endif else begin
		spec=[-1,-1]
		spec_img=blank2
		mic_img=blank2
		wcal_off=[0,0,0,0,0,0,0]
		return
	endelse
	
	micphncube=[[blank2]]
	if (micphn eq 1) then begin
	;get microphonics striping

		microbox = amp_micphn([x_med,y_med])
	
		;median quick fix to removing bad pixels
		prefft = median(img[microbox[0]:microbox[1],microbox[2]:microbox[3]],5)
		fftimg = fft(prefft)
		fftimg = abs(shift(fftimg, [32,32]))
		s2 = size(fftimg)

		fftimg[s2[1]/2,s2[2]/2] = 0

	;generate microphonic reference images

		slice1 = fftimg[s2[1]/2,0:s2[2]/2]
		slice2 = fftimg[s2[1]/2,s2[2]/2:63]
		slice = slice1[reverse(slice1)]+slice2
		modes = reverse(sort(slice))
	
		;try most relevent periods
		modes=modes[0:n_modes-1]
	
		for j=0L,n_modes-1 do begin
			r1 = blank2
			r2 = blank2

			ln = findgen(ysize)
			sinln = sin((2*!pi)/(64.0/modes[j])*ln)
			cosln = cos((2*!pi)/(64.0/modes[j])*ln)

			for k=0,xsize-1 do begin
				r1[k,0:ysize-1] = sinln
				r2[k,0:ysize-1] = cosln
			endfor 

			r1=r1/total(r1)
			r2=r2/total(r2)

			micphncube=[[[micphncube]],[[r1]],[[r2]]]
		
			j=j+1
		endfor
		micphncube=micphncube[*,*,1:*]
	endif
	
;find psf spot locations

	lens_x = (findgen(3)-1)+x_lens_cen
	lens_y = (findgen(5)-2)+y_lens_cen

;begin iteration for mspec parameters
	
	common img_spec_ext_common,com_struc

	com_struc = {wavecal:wavecal,$
		para:para,$
		steps:steps,$
		lens_x:lens_x,$
		lens_y:lens_y,$
		blank:blank,$
		x_sub1:x_sub1,$
		y_sub1:y_sub1,$
		x_sub2:x_sub2,$
		y_sub2:y_sub2,$
		PSFs_array:PSFs_array,$
		xsize:xsize,$
		ysize:ysize,$
		blank2:blank2,$
		micphncube:micphncube,$
		sub_img:sub_img,$
		micphn:micphn,$
		x_off:x_off,$
		y_off:y_off,$
		iter:iter,$
		badpix:badpix}
	
;AMOEBA calling lsqr
	t3=systime(/seconds)

	; (0) dont iterate from wavcal, (1) iterate in dispersion coordiantes, or (2) iterate in xy offsets
	iter=fix(iter)
	case iter of
		0: begin
			fit_bests=spec_ext_amoeba([x_off,y_off,del_x_best,del_theta_best,del_lam_best],/best)
			resid_arr=[1]
		end
		1: begin
			R=AMOEBA(0.01,FUNCTION_NAME='spec_ext_AMOEBA',P0=[del_x_best,del_theta_best,del_lam_best],SCALE=[2,(3*!dtor),2],NCALLS=ncalls,NMAX=100,FUNCTION_VALUE=resid_arr)
			t4=systime(/seconds)
			print,t4-t3,'Amoeba'
			if n_elements(R) eq 1 then begin
				print,'AMOEBA failed to converge',x_lens_cen,y_lens_cen
				spec=[-1,-1]
				spec_img=blank2
				mic_img=blank2
				wcal_off=[0,0,0,0,0,0,0]
				return
			endif else begin
				fit_bests=spec_ext_amoeba(R,/best)
				del_x_best=R[0]
				del_theta_best=R[1]
				del_lam_best=R[2]
			endelse
		end
		2: begin
			R=AMOEBA(1e-9,FUNCTION_NAME='spec_ext_AMOEBA',P0=[x_off,y_off],SCALE=[0.01,0.01],NCALLS=ncalls,NMAX=100,FUNCTION_VALUE=resid_arr)
			if n_elements(R) eq 1 then begin
				print,'AMOEBA failed to converge',x_lens_cen,y_lens_cen
				spec=[-1,-1]
				spec_img=blank2
				mic_img=blank2
				wcal_off=[0,0,0,0,0,0,0]
				return
			endif else begin
				fit_bests=spec_ext_amoeba(R,/best)
				x_off=R[0]
				y_off=R[1]
			endelse
		end
	endcase

	t4=systime(/seconds)
	print,t4-t3,'amoeba'

	t3=systime(/seconds)

	r_cube_best=fit_bests.r_cube
	spectra=fit_bests.spectra
	spec=fit_bests.spec

	if (micphn eq 1) then specline = spec[n_modes-1:*] else specline = spec
	idt = where(spectra[0,*] eq x_lens_cen and spectra[1,*] eq y_lens_cen)

	if n_elements(idt) eq 1 then begin
		print,'Lenslet sum zero, (edge of detector?)',x_lens_cen,y_lens_cen
		spec=[-1,-1]
		spec_img=blank2
		mic_img=blank2
		wcal_off=[0,0,0,0,0,0,0]
		return	
	endif

	spectrum = specline[idt]

	if (resid eq 1) then begin
		spec_img_s = blank2
		
		psfcube2 = r_cube_best[*,*,idt+n_modes]
		rs = size(psfcube2)
		for m=0,(rs[3]-1) do begin
			spec_img_s = spec_img_s + psfcube2[*,*,m]*spectrum[m]
		endfor
		
		bfimg=fltarr(imsz[0],imsz[1])
		bfimg[x_sub1:x_sub2,y_sub1:y_sub2]=spec_img_s
		spec_img=bfimg

		if (micphn eq 1) then begin
			mic_img_s = blank2
			mic_spec = spec[0:n_modes-1]
			for m=0,n_modes-1 do begin
				mic_img_s = mic_img_s + micphncube[*,*,m]*mic_spec[m]
			endfor
			bfimg[x_sub1:x_sub2,y_sub1:y_sub2]=mic_img_s
			mic_img = bfimg
		endif

		chi_sqr = (total(sub_img-spec_img_s)^2)/((n_elements(spec_img_s)-2-1)*(resid_arr[0])^2)
	endif else begin
		chi_sqr = 0
	endelse

	t4=systime(/seconds)
	print,t4-t3,'post amoeba'

;print,n_elements(psfpos_cen[2,*]),n_elements(transpose(spectrum))
	if n_elements(spectra[2,idt]) ne n_elements(spectrum) then begin
		print,'Spectra flx and lambda misaligned',x_lens_cen,y_lens_cen,n_elements(psfpos_cen[2,*]),n_elements(transpose(spectrum))
		spec=[-1,-1]
		spec_img=blank2
		mic_img=blank2
		wcal_off=[0,0,0,0,0,0,0]
		return	
	endif
	spec=[spectra[2,idt],transpose(spectrum)]
	wcal_off=[resid_arr[0],del_x_best,del_theta_best,del_lam_best,chi_sqr,x_off,y_off]

	; display model and data spectra sub images 
	;spec_img_s_2 = make_mdl_img(x_lens_cen,y_lens_cen,wavecal,para,0.1,x_off,y_off,blank2,xsize,ysize,img,PSFs_array,transpose(spec[1,*]),transpose(spec[0,*]),del_x_best)
	;residual = spec_img_s_2[*,*,1]-spec_img_s_2[*,*,0]*25
	;print,wcal_off
	;full_resid = fltarr(4*xsize,ysize)
	;z=0
	;full_resid[z*xsize:(z+1)*xsize-1,0:ysize-1]=sub_img
	;z=1
	;full_resid[z*xsize:(z+1)*xsize-1,0:ysize-1]=spec_img_s
	;z=2
	;full_resid[z*xsize:(z+1)*xsize-1,0:ysize-1]=sub_img-spec_img_s
	;z=3
	;full_resid[z*xsize:(z+1)*xsize-1,0:ysize-1]=residual
	;window,4
	;imdisp,full_resid
	;stop

	;pretty plot hacks

	;loadCT,13
	;ext_resid=sub_img-spec_img_s
	;cgImage,bytscl(sub_img,min=min(ext_resid),max=max(sub_img)),/keep_aspect_ratio,/axes,output='eps',outfilename='~/Desktop/ext_data.eps'
	;cgImage,bytscl(spec_img_s,min=min(ext_resid),max=max(sub_img)),/keep_aspect_ratio,/axes,output='eps',outfilename='~/Desktop/ext_model.eps'
	;cgImage,bytscl(ext_resid,min=min(ext_resid),max=max(sub_img)),/keep_aspect_ratio,/axes,output='eps',outfilename='~/Desktop/ext_resid.eps'
	;cgImage,bytscl(residual,min=min(ext_resid),max=max(sub_img)),/keep_aspect_ratio,/axes,output='eps',outfilename='~/Desktop/ext_full_resid.eps'
	;loadct,0
	;sub_badpix = badpix[x_sub1:x_sub2,y_sub1:y_sub2]
	;cgImage,bytscl((bytarr(x_sub1-x_sub2,y_sub1-ysub2)+1)-sub_badpix,min=0,max=1),/keep_aspect_ratio,/axes,output='eps',outfilename='~/Desktop/ext_bpx.eps'
	;stop
	;test_resid = fltarr(2*xsize,ysize)
	;z=0
	;test_resid[z*xsize:(z+1)*xsize-1,0:ysize-1]=spec_img_s_2[*,*,1]
	;z=1
	;test_resid[z*xsize:(z+1)*xsize-1,0:ysize-1]=spec_img_s_2[*,*,0]*25

	;window,2
	;imdisp,test_resid

	;print,spec
	;stop

	t2=systime(/seconds)
	print,t2-t1,'spectra_ext'

end

;--------------------------------------------------
; Parrallel child process to extract all lenslets known from wavecal and save residual

pro img_ext_para,cut1,cut2,z,img,wcal_off_cube,spec_cube,mic_cube,gpi_cube,gpi_lambda,para,wavcal,mlens_file,resid=resid,micphn=micphn,iter=iter,del_x_best=del_x_best,del_theta_best=del_theta_best,del_lam_best=del_lam_best,x_off=x_off,y_off=y_off,lens=lens,badpix=badpix

	t_start=systime(/seconds)

	;saved memory checks
	;help,/shared_memory

	del_theta_best=del_theta_best*!dtor

	mlens = gpi_highres_microlens_psf_read_highres_psf_structure(mlens_file,[281,281,1])

	print,"main child loop executing "+string(cut1)+string(cut2)

	wcal_off=[0,0,0,0,0,0,0]
	wcal_off2=[0,0,0,0,0,0,0]
	
	print,"resid:"+string(resid)+"  micphn:"+string(micphn)+"  iter:"+string(iter)
	for i=long(cut1),long(cut2) do begin
		t1=systime(/seconds)
		x=lens[0,i]
		y=lens[1,i]
		print,x,y,i

img_spec_ext_amoeba,x,y,img,mlens,wavcal,spectrum,spec_img,mic_img,del_lam_best,del_x_best,del_theta_best,x_off,y_off,wcal_off,para,badpix,resid=resid,micphn=micphn,iter=iter
		
img_spec_ext_amoeba,x,y,img,mlens,wavcal,spectrum2,spec_img2,mic_img2,del_lam_best+0.66,del_x_best,del_theta_best,x_off,y_off,wcal_off2,para,badpix,resid=resid,micphn=micphn,iter=0

img_spec_ext_amoeba,x,y,img,mlens,wavcal,spectrum3,spec_img2,mic_img2,del_lam_best-0.66,del_x_best,del_theta_best,x_off,y_off,wcal_off2,para,badpix,resid=resid,micphn=micphn,iter=0

		if (spectrum[0] ne -1 and spectrum2[0] ne -1) then begin
			;hr_spec=combine_dith_spec(spectrum,spectrum2,spectrum3,gpi_lambda)
			hr_spec=combine_spec(spectrum,spectrum2,spectrum3)
			lens_spectrum = interpol(hr_spec[*,1],hr_spec[*,0],gpi_lambda)
			;print,lens_spectrum
				;window,2
				;plot,gpi_lambda,lens_spec
				;oplot,spec[0,*],spec[1,*],psym=5
				;oplot,spec2[0,*],spec2[1,*],psym=5
				;oplot,spec3[0,*],spec3[1,*],psym=5
				;lens_spec = SPL_INTERP(spec_l[srt], spec_f[srt], lens_spec, gpi_lambda)
			gpi_cube[x,y,*] = lens_spectrum
			
			if (resid eq 1) then begin
				spec_cube=spec_cube+(spec_img+spec_img2)/2
				if (micphn eq 1) then mic_cube=stitch_images(mic_cube,(mic_img+mic_img2)/2)
			endif
			if (iter eq 1) then wcal_off_cube[x,y,0:6] = wcal_off[0:6]
		endif
		t2=systime(/seconds)
		print,t2-t1,' finish lenslet'
		;print,transpose([[gpi_lambda],[lens_spec]])
	endfor

	; save outputs into scratch space to recover
	dir = gpi_get_directory('GPI_REDUCED_DATA_DIR')
	;print,dir
	if (resid eq 1) then begin
		exe_tst = execute(strcompress('spec_cube_'+string(z)+'=spec_cube',/remove_all))
		exe_tst = execute(strcompress('save,spec_cube_'+string(z)+',filename="'+dir+'/spec_cube_'+string(z)+'.sav"',/remove_all))
		exe_tst = execute(strcompress('mic_cube_'+string(z)+'=mic_cube',/remove_all))
		exe_tst = execute(strcompress('save,mic_cube_'+string(z)+',filename="'+dir+'/mic_cube_'+string(z)+'.sav"',/remove_all))
	endif
	if (iter eq 1) then begin
		exe_tst = execute(strcompress('wcal_off_cube_'+string(z)+'=wcal_off_cube',/remove_all))
		exe_tst = execute(strcompress('save,wcal_off_cube_'+string(z)+',filename="'+dir+'/wcal_off_cube_'+string(z)+'.sav"',/remove_all))
	endif
	exe_tst = execute(strcompress('gpi_cube_'+string(z)+'=gpi_cube',/remove_all))
	exe_tst = execute(strcompress('save,gpi_cube_'+string(z)+',filename="'+dir+'/gpi_cube_'+string(z)+'.sav"',/remove_all))

	t_fin=systime(/seconds)
	print,(t_fin-t_start)/60,': execution time (mins)'
	
end

;--------------------------------------------------
; defining function

pro gpi_lsqr_mlens_extract_dep
	;do nothing
end
