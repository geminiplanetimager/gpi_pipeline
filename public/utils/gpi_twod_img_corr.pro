;+
; NAME: gpi_twod_img_corr
;
;	Performs a cross correlation of two images to get the x and y shift between the two images
;
; INPUTS:	
;	img_a - One image
;	img_b - Another image
;	resolution - the subpixel resolution
;	range - the range over which to search
;	
; KEYWORDS:
;	cm 
;
; OUTPUTS:
;	xsft - the shift in the x direction
;	ysft - the shift in the y direction
; 	corr - the overall correlation between the two images (maybe?)
;
; HISTORY:
;	Began 2014-11-19 Pulled by MMB from gpi_lsqr_mlens_extract_pol_dep
;
;-

pro gpi_twod_img_corr,img_a,img_b,range,resolution,xsft,ysft,corr,cm=cm
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