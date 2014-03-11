;+
; NAME: gpi_lsqr_mlens_extract_pol_dep.pro
; 
; The following are code dependencies for gpi_lsqr_mlens_extract_pol
;
; INPUTS: none
; 	
; KEYWORDS: none
; 	
; OUTPUTS: none
; 	
;	
; HISTORY:
;    Began 2014-02-17 by Zachary Draper
;-  

function get_gaus_psf

	xo=5.5
	yo=5.5
	sigx=0.6
	sigy=0.6
	A=2

	psfsize=11
	psf = fltarr(psfsize,psfsize)
	for x=0,psfsize-1 do begin
		for y=0,psfsize-1 do begin
			for i=-4,5 do begin
				psf[x,y] = A*exp(-0.5*((x-(xo))/sigx)^2-((y-(yo))/sigy)^2)
			endfor
		endfor
	endfor

return,psf
end

;--------------------------------------------------
;Lsqr extraction given reference images 

function gpi_pol_lsqr,sub_img,r_cube,resid=resid,pol=pol

	sc = size(r_cube,/dimensions)
	if (n_elements(sc) eq 2) then num=1 else num=sc[2]

;value vector
	v=fltarr(num)
	
	for i=0,num-1 do begin	
		v[i]=total(sub_img*r_cube[*,*,i])
	endfor

;create correlation matrix from cube
	C = fltarr(num,num)
	for i=0,num-1 do begin
		for j=0,num-1 do begin
			C[i,j] = total(r_cube[*,*,i]*r_cube[*,*,j],/DOUBLE)
		endfor
	endfor
	iC=invert(C,/DOUBLE)
	;iC=svd_invert(C,1e-7)

;generate value vector and image solution
	tspec=[0]
	fspec=fltarr(sc[0],sc[1])
	for i=0,num-1 do begin
		val = total(v*iC[*,i])
		tspec=[tspec,val]
		fspec=fspec+r_cube[*,*,i]*val
	endfor
	tspec=tspec[1:*]

;exit with either value vector or residual image
if (keyword_set(pol)) then return,tspec
if (keyword_set(resid)) then return,sub_img-fspec
end

;--------------------------------------------------
; Get a binned PSF from high-res model

function get_jbp_psf,myPSFs_array,pix_x,pix_y,lens_x,lens_y,int,xsize,ysize,x_grid,y_grid

	my_eval_psf = fltarr(xsize,ysize)
	ptr = gpi_highres_microlens_psf_get_local_highres_psf(myPSFs_array,[lens_x,lens_y,0])
	if ptr_valid(myPSFs_array[lens_x,lens_y]) then my_psf = *myPSFs_array[lens_x,lens_y]

	common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary
	gpi_highres_microlens_psf_initialize_psf_interpolation, my_psf.values, my_psf.xcoords, my_psf.ycoords

	my_eval_psf = gpi_highres_microlens_psf_evaluate_detector_psf(x_grid,y_grid, [pix_x, pix_y, int])

;stop
return,my_eval_psf

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

function get_psf_pos_pol,x_lens,y_lens,polcal,del_x,del_y,x_off,y_off,eo

	;del_xy for iterative solver
	;x_off,y_off for fixed predetermined flexure
	; nulling one another?

	spt = polcal[*,x_lens,y_lens,eo]

	spt_x = spt[0]+del_x+x_off
	spt_y = spt[1]+del_y+y_off

	if (total(finite(spt))) eq 0 then return,[0,0]

return,[spt_x,spt_y]

end

;--------------------------------------------------
; Extract spectra individual spot

function pol_ext_amoeba,P,best=best

	common img_pol_ext_common,com_struc

	polcal=com_struc.polcal
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
	x_off=com_struc.x_off
	y_off=com_struc.y_off
	psfpos_cen=com_struc.psfpos_cen

	del_x=P[0]
	del_y=P[1]

	;print,del_x,del_theta

;get psf reference images

	s=size(psfpos_cen)

	tstimage=blank
	psfcube=[[blank2]]

	j=0
	buff_psf=[0]
	spectra=[0,0,0]

	x_grid = rebin(findgen(xsize)+x_sub1,xsize,ysize)
	y_grid = rebin(reform(findgen(ysize)+y_sub1,1,ysize),xsize,ysize)

	ptr = gpi_highres_microlens_psf_get_local_highres_psf(PSFs_array,[lens_x,lens_y,0])
	if ptr_valid(PSFs_array[lens_x,lens_y]) then psf = *PSFs_array[lens_x,lens_y]
	
	common psf_lookup_table, com_psf, com_x_grid_PSF, com_y_grid_PSF, com_triangles, com_boundary
	gpi_highres_microlens_psf_initialize_psf_interpolation, psf.values, psf.xcoords, psf.ycoords

	;t3=systime(/seconds)
	
	;bin and position within sub image
	r1 = gpi_highres_microlens_psf_evaluate_detector_psf(x_grid,y_grid, [spec_spix3[0,k], spec_spix3[1,k], 1])

	tstimage=tstimage+r1
	psfcube = [[[psfcube]],[[r1]]]
	;spectra = [[spectra],[[spec_spix3[2,k],spec_spix3[3,k],spec_spix3[4,k],spec_spix3[0,k],spec_spix3[1,k]]]]

	;t4=systime(/seconds)
	;print,t4-t3,'jbp_psf_amoeba'

	if (micphn) then r_cube = [[[micphncube]],[[psfcube]]] else r_cube = psfcube

	resid = stddev(gpi_pol_lsqr(sub_img,r_cube,/resid))

if (keyword_set(best)) then return,{r_cube:r_cube} else return,resid

end

;--------------------------------------------------
; Prep subsection of detector image for spectra extraction.

pro img_pol_ext_amoeba,x_lens_cen,y_lens_cen,img,PSFs_array,polcal,pol,pol_img,mic_pol,del_x,del_y,x_off,y_off,pcal_off,eo,resid=resid,micphn=micphn,iter=iter

	;tuning knobs

	xsize=10			;spectra sub image size
	ysize=10			; extracted for lsqr

	n_modes=8			;(number of fourier modes - 1) used for microphonics 

	if (micphn) then n_modes=n_modes else n_modes=0

	blank = fltarr(xsize+20,ysize+20)
	blank2 = fltarr(xsize,ysize)

;get psf positions from wave cal

	psfpos_cen = get_psf_pos_pol(x_lens_cen,y_lens_cen,polcal,0,0,x_off,y_off,eo)
	x_med = floor(mean(psfpos_cen[0,*]))
	y_med = floor(mean(psfpos_cen[1,*]))
	x_sub1 = x_med-ceil(xsize/2)+1
	x_sub2 = x_med+ceil(xsize/2)
	y_sub1 = y_med-ceil(ysize/2)+1
	y_sub2 = y_med+ceil(ysize/2)

	imsz=size(img)
	if x_sub2 gt imsz[1]-1 or y_sub2 gt imsz[2]-1 or x_sub1 lt 0 or y_sub1 lt 0 then begin
		pol=[-1,-1]
		pol_img=blank2
		mic_img=blank2
		pcal_off=[0,0,0]
		return
	endif

	sub_img=img[x_sub1:x_sub2,y_sub1:y_sub2]
	
	micphncube=[[blank2]]
	if (micphn) then begin
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

;begin iteration for pol spt parameters
	
	common img_pol_ext_common,com_struc

	com_struc = {polcal:polcal,$
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
		psfpos_cen:psfpos_cen}
	
;AMOEBA calling lsqr

	if (iter) then begin
		R=AMOEBA(0.01,FUNCTION_NAME='pol_ext_AMOEBA',P0=[del_x,del_y],SCALE=[3,3],NCALLS=ncalls,NMAX=100,FUNCTION_VALUE=resid_arr)
		if n_elements(R) eq 1 then begin
			print,'AMOEBA failed to converge',x_lens_cen,y_lens_cen
			pol=[-1,-1]
			pol_img=blank2
			mic_img=blank2
			pcal_off=[0,0,0]
			return
		endif else begin
			fit_bests=pol_ext_amoeba(R,/best)
			del_x=R[0]
			del_y=R[1]
		endelse
	endif else begin
		fit_bests=pol_ext_amoeba([del_x,del_y],/best)
		resid_arr=[1]
	endelse

	r_cube_best=fit_bests.r_cube
	;pol_eo=fit_bests.pol_eo

	pol_eo = gpi_pol_lsqr(sub_img,r_cube_best,/pol)

	if (micphn) then polspts = pol_eo[n_modes-1:*] else polspts = pol_eo
	;idt = where(pol_eo[0,*] eq x_lens_cen and pol_eo[1,*] eq y_lens_cen)
;stop
	;if n_elements(idt) eq 1 then begin
	;	print,'Lenslet sum zero, (edge of detector?)',x_lens_cen,y_lens_cen
		;stop
	;	pol=[-1,-1]
	;	pol_img=blank2
	;	mic_pol=blank2
	;	pcal_off=[0,0,0]
	;	return
	;endif

	;pol_eo = polspts[idt]

	if (resid) then begin
		pol_img_s = blank2
		
		psfcube2 = r_cube_best[*,*,n_modes]
		rs = size(psfcube2,/dimensions)
		if (n_elements(rs) eq 2) then num=1 else num=sc[2]
		for m=0,(num-1) do begin
			pol_img_s = pol_img_s + psfcube2[*,*,m]*pol_eo[m]
		endfor
		bfimg=fltarr(imsz[1],imsz[2])
		bfimg[x_sub1:x_sub2,y_sub1:y_sub2]=pol_img_s
		pol_img=bfimg

		if (micphn) then begin
			mic_pol_s = blank2
			mic_pol = pol[0:n_modes-1]
			for m=0,n_modes-1 do begin
				mic_pol_s = mic_pol_s + micphncube[*,*,m]*mic_pol[m]
			endfor
			bfimg[x_sub1:x_sub2,y_sub1:y_sub2]=mic_pol_s
			mic_pol = bfimg
		endif

		;stop

		chi_sqr = (total(sub_img-pol_img_s)^2)/((n_elements(pol_img_s)-2-1)*(resid_arr[0])^2)
	endif else begin
		chi_sqr = 0
	endelse
;print,n_elements(psfpos_cen[2,*]),n_elements(transpose(spectrum))
	;if n_elements(pol[2,idt]) ne n_elements(pol_eo) then begin
	;	print,'pol flx and lambda misaligned',x_lens_cen,y_lens_cen,n_elements(psfpos_cen[2,*]),n_elements(transpose(spectrum))
	;	pol=[-1,-1]
	;	pol_img=blank2
	;	mic_pol=blank2
	;	pcal_off=[0,0,0]
	;	return	
	;endif
pol=pol_eo
wcal_off=[del_x,del_y,chi_sqr]

; display model and data spectra sub images 
;print,wcal_off
full_resid = fltarr(3*xsize,ysize)
z=0
full_resid[z*xsize:(z+1)*xsize-1,0:ysize-1]=sub_img
z=1
full_resid[z*xsize:(z+1)*xsize-1,0:ysize-1]=pol_img_s
z=2
full_resid[z*xsize:(z+1)*xsize-1,0:ysize-1]=sub_img-pol_img_s
window,0
imdisp,full_resid
stop
end

;--------------------------------------------------
; Parrallel child process to extract all lenslets known from polcal and save residual

pro img_ext_pol_para,cut1,cut2,z,img,pcal_off_cube,pol_cube,mic_pol,gpi_pol,polcal,mlens_file,resid=resid,micphn=micphn,iter=iter,x_off=x_off,y_off=y_off,lens=lens

	t_start=systime(/seconds)

	;saved memory checks
	;help,/shared_memory

	mlens = gpi_highres_microlens_psf_read_highres_psf_structure(mlens_file,[281,281,1])

	print,"main child loop executing "+string(cut1)+string(cut2)

	pcal_off=[0,0,0]
	pcal_off2=[0,0,0]
	
	print,"resid:"+string(resid)+"  micphn:"+string(micphn)+"  iter:"+string(iter)
	for i=long(cut1),long(cut2) do begin
		x=lens[0,i]
		y=lens[1,i]
		print,x,y,i
		img_pol_ext_amoeba,x,y,img,mlens,polcal,e,pol_img,mic_pol,del_x,del_y,x_off,y_off,pcal_off,0,resid=resid,micphn=micphn,iter=iter

img_pol_ext_amoeba,x,y,img,mlens,polcal,o,pol_img,mic_pol,del_x,del_y,x_off,y_off,pcal_off,1,resid=resid,micphn=micphn,iter=iter

		if (pol[0] ne -1) then begin
			gpi_pol[x,y,0:1] = [e,o]
			
			if (resid) then begin
				pol_cube=pol_cube+pol_img
				pcal_off_cube[x,y,0:2] = pcal_off[0:2]
				if (micphn) then mic_cube_pol=stitch_images(mic_cube_pol,mic_pol)
			endif
		endif
	endfor

	; save outputs into scratch space to recover
	dir = gpi_get_directory('GPI_REDUCED_DATA_DIR')
	;print,dir
	if (resid) then begin
		exe_tst = execute(strcompress('pol_cube_'+string(z)+'=pol_cube',/remove_all))
		exe_tst = execute(strcompress('save,pol_cube_'+string(z)+',filename="'+dir+'/pol_cube_'+string(z)+'.sav"',/remove_all))
		exe_tst = execute(strcompress('mic_cube_pol_'+string(z)+'=mic_cube_pol',/remove_all))
		exe_tst = execute(strcompress('save,mic_cube_pol_'+string(z)+',filename="'+dir+'/mic_cube_pol_'+string(z)+'.sav"',/remove_all))
	endif
	if (iter) then begin
		exe_tst = execute(strcompress('pcal_off_cube_'+string(z)+'=pcal_off_cube',/remove_all))
		exe_tst = execute(strcompress('save,pcal_off_cube_'+string(z)+',filename="'+dir+'/pcal_off_cube_'+string(z)+'.sav"',/remove_all))
	endif
	exe_tst = execute(strcompress('gpi_pol_'+string(z)+'=gpi_pol',/remove_all))
	exe_tst = execute(strcompress('save,gpi_pol_'+string(z)+',filename="'+dir+'/gpi_pol_'+string(z)+'.sav"',/remove_all))

	t_fin=systime(/seconds)
	print,(t_fin-t_start)/60,': execution time (mins)'

end
