;+
; NAME: find_pol_positions_quadrant
;find_spectra_positions_quadrant detects positions of spectra in the image with narrow band lamp image.
;find_spectra_positions_quadrant starts with the central peak of the image.
;Next, starting with a initial value of w & P, find the nearest peak (with an increment on the microlens coordinates)
;when nearest peak has been detected, it reevaluate w & P and so forth..
;
;
; INPUTS: 
; 	quad	which quadrant to consider [1,2,3,4]
; 	wcst
; 	Pcst
; 	nlens	number of lenslets
; 	idx		Array [nlens,nlens] in size, giving positions in lenslet units
; 			relative to the center lenslet. "X" coord  
; 	idy		Array [nlens,nlens] in size, giving positions in lenslet units
; 			relative to the center lenslet. "Y" coord
; 	cen1	2-element array giving [x,y] coordinates of centermost spot peak
; 	wx		
; 	wy
;	hh
;	szim
;	spotpos	3D array to store the detected spot positions in. 
;	im		The 2D detector image
;
; KEYWORDS:
; OUTPUTS:
;	Output is returned in the following keyword arguments: 
;	
;	spotpos				Spot positions as coordinates of Gaussians
;	spotpos_pixels		Spot positions, as pixel list
;	spotpos_pixvals		Spot positions, as values (weights) for each pixel on
;						the list
;
; HISTORY:
;    Jerome Maire 2008-10
;    2009-06 : JM fix a bug for w&P  when (i=0,j) not in the raw image
;    2009-06-17: MDP split for polarization dual-spot routine
;
;-

function is_pixel_in_usable_region,px, py, szim 
; Is a pixel (px, py) inside the usable region of the detector (defined as the
; region excluding the reference pixel rows)

; How many reference pixels to ignore around rows and columns?
	;H2RG_REFPIX = 4

    	;if (px ge H2RG_REFPIX) && (px lt szim[1]-H2RG_REFPIX) && (py ge H2RG_REFPIX) && (py lt szim[2]-H2RG_REFPIX) then return, 1 else return, 0
    	;return ((px ge H2RG_REFPIX) && (px lt szim[1]-H2RG_REFPIX) && (py ge H2RG_REFPIX) && (py lt szim[2]-H2RG_REFPIX))
    	return, ((px ge 4) && (px lt 2044) && (py ge 4) && (py lt 2044))

end

;------------------------------

forward_function mpfit, mpfitfun, mpfit2dpeak, mpfit2dpeak_gauss, $
	  mpfit2dpeak_lorentz, mpfit2dpeak_moffat, mpfit2dpeak_u


function localizepeak_mpfitpeak,  im, cenx, ceny,wx,wy, hh, pixels=pixels, pixvals=pixvals, disp=disp, badpixmap=badpixmap
	; a drop-in replacement for localizepeak which calls MPFIT2DPeak
	;
	; TBD here. 
	;
	; return [X, Y, rotangle, width_X, width_Y] where widths are at 25% max?
	; default values will be [cenx, ceny, 0,1.5,1.5] 
	
	if wx eq 0 or wy eq 0 then message, "Input parameters wx or wy are 0 - can't localize a size-zero box!"
	szim=size(im)
	x1=floor(cenx-wx)>0 & x2=ceil(cenx+wx)<szim[1]-1
	y1=floor(ceny-wy)>0 & y2=ceil(ceny+wy)<szim[2]-1

	; find the maximum location inside the specified box
	; and get the corresponding coordinates in the full array
	
	array=im[x1:x2,y1:y2]
	if keyword_set(badpixmap) && total(badpixmap[x1:x2 , y1:y2 ]) ne 0. then begin
	      weights=replicate(1.,x2-x1+1,y2-y1+1)
	      indbp=where(badpixmap[x1:x2 , y1:y2 ] eq 1)
	      array[indbp]=!values.f_nan
	      if total(finite(array)) gt n_elements(array)/2 then begin
	      fixpix, array,0, outim, /nan, /silent
	      array=outim
	      endif
	endif
	 
	if total(finite(array)) gt n_elements(array)/2 then begin
		yfit = mpfit2dpeak(float(array), A,x, y,/gaussian,/tilt) 
		;stop
			; MP edit - no reason to work in doubles here...
			; force to double to match what localizepeak does.
				; mpfit2dpeak is slow here, but not terribly slow. And besides this
				; could easily be parallelized...
		a = float(a)
    
    ; figure out the half-width at some chosen fraction of the maximum.
		; e.g. set frac=0.5 to get the half-width at half max.
		frac = 0.02
		hwxm_coeff = sqrt(2*alog(1./frac))


		if arg_present(pixels) then begin
			; find pixels which are 
			;   (a) more than 1e-3 times the peak pixel in that subregion, and
			;   (b) in the core of the best-fit gaussian (>1e-3)
			; This is a fairly arbitrary cut and can probably be improved!!
			if keyword_set(badpixmap) && total(badpixmap[x1:x2 , y1:y2 ]) ne 0. then begin
				indbp=where(badpixmap[x1:x2 , y1:y2 ] eq 1,cbp)
				if cbp gt 0 then array[indbp]=!values.f_nan
			endif
			indices, array, xx, yy
			u= mpfit2dpeak_u(xx,yy,a,/tilt)
			cutoff = alog(1e-4)/(-0.5) ;alog(1e-3)/(-0.5)
			ma = max(array,/nan)
		;	wpeak = where( ((u lt cutoff) and (array gt 1e-3*ma)) or (array gt 0.2*ma) , wct)
			;wpeak = where( ((u lt cutoff) and (array gt 1e-4*ma)) or (array gt 0.01*ma) , wct)
			wpeak = where( (u lt cutoff) and (array gt 3e-4*ma)  , wct)
			if wct eq 0 then begin
				; if we have no good pixel fits, then make the X and Y widths of the
				; gaussian at least 1 pixel
				message, "Problem with lenslet pixel fit! Trying slightly wider fit...",/info
				a2= a
				a2[2:3] >=1
				u2= mpfit2dpeak_u(xx,yy,a2)
				wpeak = where( (u2 lt cutoff) and (array gt 1e-3*max(array)) , wct)
				if wct eq 0 then message, "Unfixable problem with lenslet pixel fit!",/info
		
			endif
			if wct ne 0 then begin
				pixels = array_indices(array,wpeak)
				pixels[0,*] += x1 ; make them relative to the overall array
				pixels[1,*] += y1
				pixvals = array[wpeak]
			endif 
		
			npix = 45 ; enough to save for each lenslet?
					  ; NOTE: this **MUST** match the nspot_pixels value in
					  ; gpi_extract_polcal.pro

			if (wct lt npix) && (wct ne 0) then begin
				pixvals = [pixvals, replicate(!values.f_nan, npix-wct)]
				pixels = [[pixels], [replicate(0, 2,npix-wct)]]
			endif else if wct gt npix then begin
				s = reverse(sort(pixvals))
				s=s[0:npix-1]
				pixvals=pixvals[s]
				pixels =pixels[*,s]
			endif
			if (wct eq 0) then begin
		  pixvals = [replicate(!values.f_nan, npix-wct)]
		  pixels = [[replicate(0, 2,npix-wct)]]
		endif

	endif



	;disp=1
	if keyword_set(disp) then begin
		; vals in display coords
		vals =  [A[4], A[5], A[6]*!radeg, hwxm_coeff*A[2], hwxm_coeff*A[3]]
		xr = minmax(findgen(x2-x1+2)-0.5)
		yr = minmax(findgen(y2-y1+2)-0.5)
			; the half pixel offset and extra width are to enforce the FITS convention that
			; coordinates are the center of the pixels...

		win, 1	,/keep
		loadct,0,/silent
		!p.multi=[0,3,1]
		imdisp, array,/axis, xr=xr,yr=yr, title="Original subarray"
		tvellipse, vals[3], vals[4], vals[0], vals[1], -vals[2], color=cgcolor('red'),/major,/data
		imdisp, yfit,/axis, xr=xr,yr=yr, title="Gaussian fit"
		tvellipse, vals[3], vals[4], vals[0], vals[1], -vals[2], color=cgcolor('red'),/major,/data
		mask=array*0
		mask[wpeak]=1
		imdisp, mask,/axis, xr=xr,yr=yr, title="Pixel mask"


	endif
  ;Check for nans
 
  if ~finite(total(a)) then begin 
    print, "Bad lenslet fit near "+string(cenx, ceny)+" setting to default values"
    A=[1,1.5/hwxm_coeff,1.5/hwxm_coeff,cenx, ceny, 0]
  endif

	vals = [A[4]+x1, A[5]+y1, A[6]*!radeg, hwxm_coeff*A[2], hwxm_coeff*A[3]]
	return, vals

endif else begin
    print, "Too few pixels near "+string(cenx, ceny)+" to get a good fit, setting to default values"
    vals=[cenx, ceny, 0, 1.5,1.5]
    return, vals
endelse

end

;------------------------------

pro find_pol_positions_quadrant, quad,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,spotpos,im, spotpos_pixels, spotpos_pixvals, $
		tight_pos, boxwidth,display=display_flag, badpixmap=badpixmap, loud=loud

; What is the default offset for the polarization spots?
;   The following values were determined from DST images on 2009-06-16;
;   they will almost certainly need to be changed for real data. - MDP
;
;POL_DX = 7 ;this parameter needs to be used for DST image
;POL_DY = -3  ;this parameter needs to be used for DST image
POL_DX = 2  ;good for USC test data
POL_DY = -7 ;good for USC test data

print, "   *** fitting polarization spots in quadrant "+strc(quad)

nlens=fix(nlens) ; make sure this is signed rather than unsigned, or the divisions below will be bogus:
case quad of 
  1: begin 
      jlim1=0 & jlim2=nlens/2 & jdir=1 & ilim=nlens/2 & idir=1 
      end
  2: begin 
      jlim1=0 & jlim2=nlens/2 & jdir=1 & ilim=-nlens/2 & idir=-1 
      end
  3: begin 
      jlim1=-1 & jlim2=-nlens/2 & jdir=-1 & ilim=-nlens/2 & idir=-1 
     end
  4: begin 
      jlim1=-1 & jlim2=-nlens/2 & jdir=-1 & ilim=nlens/2 & idir=1
     end
endcase

wtab=dblarr(nlens,nlens) & ptab=dblarr(nlens,nlens)

counter=0 ; for display
reset_counter=0 ; how many times have w and P been reset
predict_counter=0 ; how many times the spots have been reset to their predicted locations

w0=wcst & P0=Pcst ;initial guess
for j=jlim1,jlim2,jdir do begin
w=w0 & P=P0 ;initial guess ; note that w0 and P0 get changed below so this does adapt as it goes, in both directions

;print, 'w=',w,'  P=',P
statusline, "Fitting spots in column "+strc(abs(j-jlim1)+1) +" of "+strc(abs(jlim2-jlim1)+1)+"   "
 ;print, "Fitting spots in column "+strc(abs(j-jlim1)+1) +" of "+strc(abs(jlim2-jlim1)+1)+"   "
 
 ;For predicting spot locations
  
for i=0,ilim,idir do begin
  predict_flag=0
	;calculate approximate position of the next spectrum with w&P
;if (nlens/2+i eq 144) && (nlens/2+j eq 141) then stop
;if (nlens/2+i eq 132) && (nlens/2+j eq 141) then stop
	; the central peak was already fit in gpi_extrac_polcal, but
	; redo the central spot here to get both polarizations, 
	; and all the spotpos_ stuff.
	if (abs(i)+abs(j) eq 0) then if quad gt 1 then continue ;we already have position of the central spectrum 

	dx=idx[nlens/2+i,nlens/2+j]*W*P+jdy[nlens/2+i,nlens/2+j]*W
	dy=jdy[nlens/2+i,nlens/2+j]*W*P-W*idx[nlens/2+i,nlens/2+j]
	
	;print, 'dx=',dx+cen1[0],'  dy=',dy+cen1[1]
  
	;if the box around this spot is inside the valid region
	; as inferred from its two corners
	; **AND** the 2nd polarization spot is valid too, then we can proceed
	;
	; TODO:  This algorithm seems to be a bit conservative, and does not
	; find some spots near the bottom & right sides which DO have both spots
	; on the valid region of the chip. TBD how to improve it - smaller
	; constraint box? - MDP 2009-06-22
	;
	if is_pixel_in_usable_region(dx+cen1[0]-wx-hh, dy+cen1[1]-wy-hh, szim) && $
	   is_pixel_in_usable_region(dx+cen1[0]+wx+hh, dy+cen1[1]+wy+hh, szim) && $
	   is_pixel_in_usable_region(dx+cen1[0]-wx-hh+POL_DX, dy+cen1[1]-wy-hh+POL_DY, szim) && $
	   is_pixel_in_usable_region(dx+cen1[0]+wx+hh+POL_DX, dy+cen1[1]+wy+hh+POL_DY, szim) then begin
	;if (dx+cen1[0]-wx-hh ge 0) && (ceil(dx+cen1[0]+wx+hh) lt szim[1]) && (dy+cen1[1]-wy-hh ge 0) && (ceil(dy+cen1[1]+wy+hh) lt szim[2]) then begin
	  ;if (idir eq -1)&& (j eq 116) then stop
	  ;if (idir eq -1)&& (j eq 115) then print, 'j=115 w=',w,'  P=',P
	  ;;calculate centroid to have more accurate position for both spots
		mpfit_wx = boxwidth
		
		spotpos[*,nlens/2+i,nlens/2+j,0]=localizepeak_mpfitpeak( im, cen1[0]+dx,cen1[1]+dy,mpfit_wx,mpfit_wx,hh,pixels=pixels, pixvals=pixvals, disp=(((counter mod 200) eq 0) and keyword_set(display_flag) ) , badpixmap=badpixmap)

		;if the centroid is too far from where it should be then use the predicted location
		if (sqrt((spotpos[0,nlens/2+i,nlens/2+j,0]-(cen1[0]+dx))^2+(spotpos[1,nlens/2+i,nlens/2+j,0]-(cen1[1]+dy))^2) gt double(tight_pos))  then begin
		      if keyword_set(loud) then begin
          print, "    *** Found a funny looking spot location. Going with predicted location instead"
          print, "    *** Bad Location at ["+string(spotpos[0,nlens/2+i,nlens/2+j,0])+","+string(spotpos[1,nlens/2+i,nlens/2+j,0])+"]"
          print, "    *** Replacing it with ["+string(cen1[0]+dx)+","+string(cen1[1]+dy)+"]"
          endif
          spotpos[0,nlens/2+i,nlens/2+j,0]=cen1[0]+dx
          spotpos[1,nlens/2+i,nlens/2+j,0]=cen1[1]+dy
          predict_counter++
          predict_flag=1
          
          ; Let's use the previous spot pixels in this case.           
          pix_loc=where(spotpos_pixels[0,*,nlens/2+i-idir, nlens/2+j,0] ne 0.)
          spotpos_pixels[0,0,nlens/2+i,nlens/2+j,0] = spotpos_pixels[0,pix_loc,nlens/2+i-idir,nlens/2+j,0]+spotpos[0,nlens/2+i,nlens/2+j,0]-spotpos[0,nlens/2+i-idir,nlens/2+j,0]
          spotpos_pixels[1,0,nlens/2+i,nlens/2+j,0] = spotpos_pixels[1,pix_loc,nlens/2+i-idir,nlens/2+j,0]+spotpos[1,nlens/2+i,nlens/2+j,0]-spotpos[1,nlens/2+i-idir,nlens/2+j,0]
          spotpos_pixvals[0:n_elements(pix_loc)-1,nlens/2+i,nlens/2+j,0]=im[spotpos_pixels[0,pix_loc,nlens/2+i,nlens/2+j,0]+szim[1]*spotpos_pixels[1,pix_loc,nlens/2+i,nlens/2+j,0]]
     endif else begin

        spotpos_pixvals[0,nlens/2+i,nlens/2+j,0] = pixvals
        spotpos_pixels[0,0,nlens/2+i,nlens/2+j,0] = pixels
     endelse
        
        
        
    ;Now Spot 2
		spotpos[*,nlens/2+i,nlens/2+j,1]=localizepeak_mpfitpeak( im, cen1[0]+dx+POL_DX,cen1[1]+dy+POL_DY,mpfit_wx,mpfit_wx,hh,pixels=pixels, pixvals=pixvals, badpixmap=badpixmap)
		
		;if the centroid is too far from where it should be then use the predicted location
    if (sqrt((spotpos[0,nlens/2+i,nlens/2+j,1]-(cen1[0]+dx+POL_DX))^2+(spotpos[1,nlens/2+i,nlens/2+j,1]-(cen1[1]+dy+POL_DY))^2) gt double(tight_pos))  then begin
          if keyword_set(loud) then begin
          print, " SPOT 2"
          print, "    *** Found a funny looking spot location. Going with predicted location instead"
          print, "    *** Bad Location at ["+string(spotpos[0,nlens/2+i,nlens/2+j,1])+","+string(spotpos[1,nlens/2+i,nlens/2+j,1])+"]"
          print, "    *** Replacing it with ["+string(cen1[0]+dx+POL_DX)+","+string(cen1[1]+dy+POL_DY)+"]" 
          endif
          spotpos[0,nlens/2+i,nlens/2+j,1]=cen1[0]+dx+POL_DX
          spotpos[1,nlens/2+i,nlens/2+j,1]=cen1[1]+dy+POL_DY
          
          ; Let's use the previous spot pixels in this case. 
          pix_loc=where(spotpos_pixels[0,*,nlens/2+i-idir, nlens/2+j,1] ne 0.)
          spotpos_pixels[0,0,nlens/2+i,nlens/2+j,1] = spotpos_pixels[0,pix_loc,nlens/2+i-idir,nlens/2+j,1]+spotpos[0,nlens/2+i,nlens/2+j,1]-spotpos[0,nlens/2+i-idir,nlens/2+j,1]
          spotpos_pixels[1,0,nlens/2+i,nlens/2+j,1] = spotpos_pixels[1,pix_loc,nlens/2+i-idir,nlens/2+j,1]+spotpos[1,nlens/2+i,nlens/2+j,1]-spotpos[1,nlens/2+i-idir,nlens/2+j,1]
          spotpos_pixvals[0:n_elements(pix_loc)-1,nlens/2+i,nlens/2+j,1]=im[spotpos_pixels[0,pix_loc,nlens/2+i,nlens/2+j,1]+szim[1]*spotpos_pixels[1,pix_loc,nlens/2+i,nlens/2+j,1]]
     endif else begin
        spotpos_pixvals[0,nlens/2+i,nlens/2+j,1] = pixvals
        spotpos_pixels[0,0,nlens/2+i,nlens/2+j,1] = pixels
     endelse

    

		counter++
		if keyword_set(debug_mpfit) then begin
					spotpos[0:1,nlens/2+i,nlens/2+j,0]=localizepeak( im, cen1[0]+dx,cen1[1]+dy,wx,wy,hh)
					spotpos[0:1,nlens/2+i,nlens/2+j,1]=localizepeak( im, cen1[0]+dx+POL_DX,cen1[1]+dy+POL_DY,wx,wy,hh)
					vals1 = localizepeak_mpfitpeak( im, cen1[0]+dx,cen1[1]+dy,mpfit_wx,mpfit_wx,0)
					vals2 = localizepeak_mpfitpeak( im, cen1[0]+dx+POL_DX,cen1[1]+dy+POL_DY,mpfit_wx,mpfit_wx,0)
			print,  vals1[0:1], reform(spotpos[0:1,nlens/2+i,nlens/2+j,0],2) 
			print, ""
			print, vals2[0:1], reform(spotpos[0:1,nlens/2+i,nlens/2+j,1],2)
			stop
		endif

		if predict_flag then continue ;If the pixel had to be reset to the predicted location then don't re-estimate w & P
		
		if (abs(i)+abs(j) eq 0)  then continue ; don't try to re-estimate for the central pixel!

		;;re-estimate w & P using the central spectrum
		dx2=spotpos[0,nlens/2+i,nlens/2+j,0]-spotpos[0,nlens/2,nlens/2,0]
		dy2=spotpos[1,nlens/2+i,nlens/2+j,0]-spotpos[1,nlens/2,nlens/2,0]
		if (jdy[nlens/2+i,nlens/2+j]^2-(idx[nlens/2+i,nlens/2+j])^2) then $
		  W=abs((jdy[nlens/2+i,nlens/2+j]*dx2-idx[nlens/2+i,nlens/2+j]*dy2)/(jdy[nlens/2+i,nlens/2+j]^2+(idx[nlens/2+i,nlens/2+j])^2))
		if (i ne 0) then begin
		  if (idx[nlens/2+i,nlens/2+j]*w) ne 0 then begin ;if division by zero, use the second relation 
			P=(dx2-jdy[nlens/2+i,nlens/2+j]*w)/(idx[nlens/2+i,nlens/2+j]*w)
		  endif else begin
			P=(idx[nlens/2+i,nlens/2+j]*dx2+jdy[nlens/2+i,nlens/2+j]*idx[nlens/2+i,nlens/2+j]*dy2)/(((idx[nlens/2+i,nlens/2+j])^2+(jdy[nlens/2+i,nlens/2+j])^2)*w)
		  endelse
		endif else begin
		  P=dy2/(jdy[nlens/2+i,nlens/2+j]*w)
		endelse
	endif else begin; in the frame, else (for corner quad=2 where i starts>0) get the w&P of (j-1) lines 
		if (wtab[nlens/2+i,nlens/2+j-jdir*1] ne 0.) then  begin
			  w=wtab[nlens/2+i,nlens/2+j-jdir*1] 
			  p=ptab[nlens/2+i,nlens/2+j-jdir*1]
		endif      
	endelse
	

  wtab[nlens/2+i,nlens/2+j]=w  
  ptab[nlens/2+i,nlens/2+j]=p
  
  if (i eq 0) and finite(w) and finite(p) then begin
    w0=w & P0=p
  endif
	
	
endfor
endfor
  print, "--- The pixel centroid was reset "+string(predict_counter)+" times"

end
