function gpi_highres_microlens_plot_pixel_phase,spaxels_xcentroids,spaxels_ycentroids,pp_neighbors,n_per_lenslet,degree_of_the_polynomial_fit,xtransf_im_to_ref,ytransf_im_to_ref
; this is a routine used to plot the pixel phase when working to derive the highres_psfs
; must loop over the files

sz=size(spaxels_xcentroids)
if N_ELEMENTS(sz) eq 5 then begin
print,'gpi_highres_microlens_plot_pixel_phase does not currently work when only 1 file is supplied '
return, -1
endif
nfiles=sz[4]
;loop over the different elevations
for f=0,nfiles-1 do begin
; only want the values from the neighbours
       	
           pp_xcen = reform(spaxels_xcentroids[*,*,*,f], n_per_lenslet*(2*pp_neighbors+1.0)^2)
           pp_ycen = reform(spaxels_ycentroids[*,*,*,f], n_per_lenslet*(2*pp_neighbors+1.0)^2)
           ; bring into reference
           ; first x
           pp_xcen_in_ref = fltarr(n_elements(pp_xcen)*n_per_lenslet)
           for i=0,degree_of_the_polynomial_fit do $
              for j= 0,degree_of_the_polynomial_fit do $
                 pp_xcen_in_ref += xtransf_im_to_ref[i,j,f]*pp_xcen^j * pp_ycen^i
           ;now y
           pp_ycen_in_ref = fltarr(n_elements(pp_ycen)*n_per_lenslet)
           for i=0,degree_of_the_polynomial_fit do $
              for j= 0,degree_of_the_polynomial_fit do $
                 pp_ycen_in_ref += ytransf_im_to_ref[i,j,f]*pp_xcen^j * pp_ycen^i
        
           ; now we want to create/calculate a mean
           if f eq 0 then begin
						  pp_xcen_ref_arr=fltarr(n_per_lenslet*(2*pp_neighbors+1.0)^2, nfiles)
					    pp_ycen_ref_arr=fltarr(n_per_lenslet*(2*pp_neighbors+1.0)^2, nfiles)

              pp_xcen_ref_arr[*,f]=pp_xcen_in_ref
              pp_ycen_ref_arr[*,f]=pp_ycen_in_ref
              ; now create centroid arrays
              pp_xcens_arr=pp_xcen_in_ref
              pp_ycens_arr=pp_ycen_in_ref
           endif else begin
              pp_xcen_ref_arr[*,f] = pp_xcen_in_ref
              pp_ycen_ref_arr[*,f] = pp_ycen_in_ref
              pp_xcens_arr=[pp_xcens_arr,[pp_xcen_in_ref]]
              pp_ycens_arr=[pp_ycens_arr,[pp_ycen_in_ref]]
           endelse
        ;  window, 11 ;pixel phase of the image in the reference
;  plot, mean_xcen_ref - floor(mean_xcen_ref) ,xcen_in_ref-mean_xcen_ref, psym = 3

      
endfor ; end loop over elevations

;  pp_xcens_arr - these are the centroids in the reference image.

; must calculate the means for pp_mean_xcen_ref
pp_mean_xcen_ref=fltarr((2*pp_neighbors+1.0)^2)
pp_mean_ycen_ref=fltarr((2*pp_neighbors+1.0)^2)

for i=0, (2*pp_neighbors+1.0)^2-1 do begin
	meanclip,pp_xcen_ref_arr[i,*],tmp_mean,tmp2, clipsig=2.5
	pp_mean_xcen_ref[i]=tmp_mean
endfor

for i=0, (2*pp_neighbors+1.0)^2-1 do begin
	meanclip,pp_ycen_ref_arr[i,*], tmp_mean, tmp, clipsig=2.5
	pp_mean_ycen_ref[i]=tmp_mean
endfor

xresid=fltarr((2*pp_neighbors+1.0)^2*nfiles)
xpp=fltarr((2*pp_neighbors+1.0)^2*nfiles)
incre=(2*pp_neighbors+1.0)^2
for i=1,nfiles-1 do xresid[incre*i:incre*(i+1)-1]=pp_xcens_arr[incre*i:incre*(i+1)-1]-pp_mean_xcen_ref
;for i=0,nfiles-1 do xpp[incre*i:incre*(i+1)-1]=pp_mean_xcen_ref-floor(pp_mean_xcen_ref+0.5)  
xpp2=pp_xcens_arr-floor(pp_xcens_arr+0.5)  
;window,1,retain=2,xsize=600,ysize=400
;plot, xpp, xresid, psym = 3,xr=[-0.5,0.5],yr=[-0.12,0.12],/xs,/ys
window,2,retain=2,xsize=600,ysize=400
plot, xpp2, xresid, psym = 3,xr=[-0.5,0.5],yr=[-0.2,0.2],/xs,/ys,xtitle='X-pixel phase',ytitle='residuals (x-xbar)'

yresid=fltarr((2*pp_neighbors+1.0)^2*nfiles)
ypp=fltarr((2*pp_neighbors+1.0)^2*nfiles)
incre=(2*pp_neighbors+1.0)^2
for i=1,nfiles-1 do yresid[incre*i:incre*(i+1)-1]=pp_ycens_arr[incre*i:incre*(i+1)-1]-pp_mean_ycen_ref
;for i=0,nfiles-1 do ypp[incre*i:incre*(i+1)-1]=pp_mean_ycen_ref-floor(pp_mean_ycen_ref+0.5)  
ypp2=pp_ycens_arr-floor(pp_ycens_arr+0.5)  
;window,3,retain=2,xsize=600,ysize=400
;plot, ypp, yresid, psym = 3,xr=[-0.5,0.5],yr=[-0.12,0.12],/xs,/ys
window,4,retain=2,xsize=600,ysize=400
plot, ypp2, yresid, psym = 3,xr=[-0.5,0.5],yr=[-0.2,0.2],/xs,/ys,xtitle='Y-pixel phase',ytitle='residuals (y-ybar)'


return,[[xpp2,xresid],[ypp2,yresid]]
end
