function gpi_highres_microlens_plot_pixel_phase,spaxels_xcentroids,spaxels_ycentroids,pp_neighbors,n_per_lenslet,degree_of_the_polynomial_fit=degree_of_the_polynomial_fit,xtransf_im_to_ref=xtransf_im_to_ref,ytransf_im_to_ref=ytransf_im_to_ref
; this is a routine used to plot the pixel phase when working to derive the highres_psfs
; must loop over the files

; note that the above parameters are ONLY for the region of interest defined by pp_neighbours

; realized that the original calculates a reference psf for each star, we want a single reference psf for the entire section!


sz=size(spaxels_xcentroids)
if N_ELEMENTS(sz) eq 5 then begin
print,'gpi_highres_microlens_plot_pixel_phase does not currently work when only 1 file is supplied '
;return, -1
nfiles=1
endif else nfiles=sz[4]



; get the number of array elements we're dealing with in each image
nelem=N_ELEMENTS(spaxels_xcentroids[*,*,*,0]) ; also equal to n_per_lenslet*(2*pp_neighbors+1.0)^2

;loop over the different elevations
	for f=0,nfiles-1 do begin
	; only want the values from the neighbours

	; get centroids at given elevation/frame and put into 1D array
           xcen = reform(spaxels_xcentroids[*,*,*,f], nelem) 
           ycen = reform(spaxels_ycentroids[*,*,*,f], nelem)

		
           ; bring neighbour positions into reference frame
	xcen_in_ref = fltarr(n_elements(xcen)) ; xcentroid in reference frame
	ycen_in_ref = fltarr(n_elements(ycen))


          	; this is the old way for polynomial fitting
	if keyword_set(degree_of_the_polynomial_fit) eq 1 then begin
		; first x
           for i=0,degree_of_the_polynomial_fit do $
              for j= 0,degree_of_the_polynomial_fit do $
                 xcen_in_ref += xtransf_im_to_ref[i,j,f]*xcen^j * ycen^i
           ;now y
           for i=0,degree_of_the_polynomial_fit do $
              for j= 0,degree_of_the_polynomial_fit do $
                 ycen_in_ref += ytransf_im_to_ref[i,j,f]*xcen^j * ycen^i

	endif else begin
	; this is the case that the xtransf_im_to_ref are just shifts
		
		xcen_in_ref=( (xcen+reform(xtransf_im_to_ref[*,*,f],nelem) ) )
		ycen_in_ref=( (ycen+reform(ytransf_im_to_ref[*,*,f],nelem) ) )
	endelse
        
	; delare arrays - can't do this outside since the number of psfs changes etc
           ; now we want to create/calculate a mean
           if f eq 0 then begin
		; array of centroids in reference frame
	      xcen_ref_arr=fltarr(nelem, nfiles)
	      ycen_ref_arr=fltarr(nelem, nfiles)

              xcen_ref_arr[*,f]=xcen_in_ref
              ycen_ref_arr[*,f]=ycen_in_ref
              ; now create centroid arrays in their local frame
              xcen_arr=xcen
              ycen_arr=ycen
           endif else begin
		; append arrays if not the first pass
              xcen_ref_arr[*,f] = xcen_in_ref
              ycen_ref_arr[*,f] = ycen_in_ref
              xcen_arr=[xcen_arr,[xcen]]
              ycen_arr=[ycen_arr,[ycen]]
           endelse
      
	endfor ; end loop over elevations

; must calculate the mean position for each psf in it's reference frame
mean_xcen_ref=fltarr(nelem)
mean_ycen_ref=fltarr(nelem)

; loop over each PSF in the reference frame and calculate it's mean position
; we want to do this with rejection so it takes extra loops
for i=0, nelem-1 do begin
	meanclip,xcen_ref_arr[i,*],tmp_mean,tmp2, clipsig=2.5
	mean_xcen_ref[i]=tmp_mean
endfor

for i=0, nelem-1 do begin
	meanclip,ycen_ref_arr[i,*], tmp_mean, tmp, clipsig=2.5
	mean_ycen_ref[i]=tmp_mean
endfor

; now calculate the xresiduals
;xresid=fltarr(nelem*nfiles) ; this is the x-position residual in the reference frame (y axis in fig 2 of anderson et al)

; loop over each psf and do position-mean for all files in the reference frame
;for i=0,nelem-1 do xresid[nfiles*i : nfiles*(i+1)-1]=xcen_ref_arr[i,*]-mean_xcen_ref[i]

; want to put reference into the individual frames - then look at the distribution of residuals
mean_xcen_in_im=fltarr(nelem*nfiles)
for f=0, nfiles-1 do mean_xcen_in_im[f*nelem:(f+1)*nelem-1]=mean_xcen_ref[*]-reform(xtransf_im_to_ref[*,*,f],nelem)
xresid=xcen_arr-mean_xcen_in_im


; now calculate the yresiduals
;yresid=fltarr(nelem*nfiles) ; this is the y-position residual in the reference frame - not shown in paper
;for i=0,nelem-1 do yresid[nfiles*i:nfiles*(i+1)-1]=[ycen_ref_arr[i,*]-mean_ycen_ref[i]]

; want to put reference into the individual frames - then look at the distribution of residuals
mean_ycen_in_im=fltarr(nelem*nfiles)
for f=0, nfiles-1 do mean_ycen_in_im[f*nelem:(f+1)*nelem-1]=mean_ycen_ref[*]-reform(ytransf_im_to_ref[*,*,f],nelem)
yresid=ycen_arr-mean_ycen_in_im

; now calculate the x & y pixel phase (y axis in fig 2 of anderson et al)
; this is the position of the peak relative to the center of the pixel
; in the initial frame
xpp=xcen_arr-(floor(xcen_arr)+0.5)
ypp=ycen_arr-(floor(ycen_arr)+0.5)

; sort in order of increasing pixel phase
xind=sort(xpp)
yind=sort(ypp)

; now plot the equivalent of fig 2
window,2,retain=2,xsize=600,ysize=400
plot, xpp[xind], xresid[xind], psym = 3,xr=[-0.5,0.5],yr=[-0.1,0.1],/xs,/ys,xtitle='X-pixel phase in initial frame',ytitle='residuals (x-xbar) in reference frame',background=cgcolor('white'),color=cgcolor('black'),/nodata,charsize=1.5
oplot, xpp[xind], xresid[xind], psym = 3,color=cgcolor('grey')


; move through the bins and calculate a median and stdev
nbins=20
bins=(findgen(nbins)+1)/nbins -0.5
x_med_arr=fltarr(nbins) & x_stddev_arr=fltarr(nbins)
for b=1,nbins-1 do begin
		ind=where(xpp ge bins[b]-1./nbins and xpp lt bins[b]+1./nbins)

	if ind[0] eq -1 then begin
		x_med_arr[b]=!values.f_nan
		x_stddev_arr[b]=!values.f_nan
	endif else begin
		x_med_arr[b]=median(xresid[ind])
		x_stddev_arr[b]=robust_sigma(xresid[ind])
	endelse
endfor
oploterror,bins,x_med_arr,x_stddev_arr,color=cgcolor('black')


window,4,retain=2,xsize=600,ysize=400
plot, ypp[yind], yresid[yind], psym = 3,/xs,/ys,xtitle='Y-pixel phase in initial frame',ytitle='residuals (y-ybar) in reference frame',xr=[-0.5,0.5],yr=[-0.1,0.1],background=cgcolor('white'),color=cgcolor('black'),charsize=1.5,/nodata
oplot, ypp[yind], yresid[yind], psym = 3, color=cgcolor('grey')

nbins=20
bins=(findgen(nbins)+1)/nbins -0.5
y_med_arr=fltarr(nbins) & y_stddev_arr=fltarr(nbins)
for b=1,nbins-1 do begin
		ind=where(ypp ge bins[b]-1./nbins and ypp lt bins[b]+1./nbins)

	if ind[0] eq -1 then begin
		y_med_arr[b]=!values.f_nan
		y_stddev_arr[b]=!values.f_nan
	endif else begin
		y_med_arr[b]=median(yresid[ind])
		y_stddev_arr[b]=robust_sigma(yresid[ind])
	endelse
endfor
oploterror,bins,y_med_arr,y_stddev_arr,color=cgcolor('black')


;stop, 'at the end of pixel-phase2'
return,[[xpp,xresid],[ypp,yresid]]
end
