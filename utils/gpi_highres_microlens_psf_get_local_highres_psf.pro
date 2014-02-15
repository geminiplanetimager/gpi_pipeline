function gpi_highres_microlens_psf_get_local_highres_psf, high_res_PSFs, lcoords
; this function returns the highres psf for a local lenslet coordinate 
; it reads the large structure then interpolates between the closest four positions in order to determine 
; an average local psf
time1=systime(/seconds)
; check to see if there is already a psf at this position!
ptr_current_PSF = high_res_psfs[lcoords[0],lcoords[1],lcoords[2]]
; if yes, then just return it
   if ptr_valid(ptr_current_PSF) then return,high_res_psfs[lcoords[0],lcoords[1],lcoords[2]] 

; otherwise, grab the 4 closest valid psfs and interpolate
; this will actually create all of the necessary data and add it into 
; the high_res_psfs structure

; find valid pointers
valid=ptr_valid(high_res_psfs)
ygrid=findgen(281)##(fltarr(281)+1)
;xgrid=(fltarr(281)+1)##findgen(281)  ; slower
xgrid=transpose(ygrid)
time1a=systime(/seconds)

; make non-valid points nans
bad=where(valid eq 0,complement=good)
ygrid[bad]=!values.f_nan & xgrid[bad]=!values.f_nan


; now offset these grids so they represent the distance to the nearest points
xgrid-=lcoords[0] & ygrid-=lcoords[1]

; now find the closest indices surrounding the object
rad_dist=fltarr(281,281)
rad_dist[good]=sqrt(xgrid[good]^2+ygrid[good]^2)
time1b=systime(/seconds)

; nearest positive x , positive y
ind=where(ygrid ge 0 and xgrid ge 0)
if ind[0] eq -1 then Q22_ind=-1 else begin
	dump=min(rad_dist[ind],/nan,tmp)
	Q22_ind=ind[tmp]
endelse
; nearest negative x , positive y
ind=where(ygrid ge 0 and xgrid lt 0)
if ind[0] eq -1 then Q12_ind=-1 else begin
	dump=min(rad_dist[ind],/nan,tmp)
	Q12_ind=ind[tmp]
endelse
; nearest negative x , negative y
ind=where(ygrid lt 0 and xgrid lt 0)
if ind[0] eq -1 then Q11_ind=-1 else begin
	dump=min(rad_dist[ind],/nan,tmp)
	Q11_ind=ind[tmp]
endelse

; nearest positive x , negative y
ind=where(ygrid lt 0 and xgrid ge 0)
if ind[0] eq -1 then Q21_ind=-1 else begin
	dump=min(rad_dist[ind],/nan,tmp)
	Q21_ind=ind[tmp]
endelse
time2=systime(/seconds)
;
; so consider the following, our lenslet of interest is P(x,y), so surrounding
; the lenslet on all for corners (although no equidistant) we have Q11,Q12,Q21,Q22
; so what we do is determine the inbetween points (R1x R2x,R1y, R2y)
; then use those points to determine Pxy
;
;		Q12		Rx2		Q22
;		R1y		Pxy		R2y
;		Q11		Rx1		Q21
;
; for the next section, we need at LEAST of one the R's

; now must calculate the median values
if (Q12_ind ne -1 and Q22_ind ne -1) then begin
	; the crappy thing is that the PSFs are all centered differently, so we cannot just add them
	; we need to shift them such that the 0,0 point is always in the same place for all 4
	Q22_ind_psf=(*high_res_psfs[Q22_ind mod 281,Q22_ind / 281]).values
	; the following are the coordinates for this psf which we define as the master
	; so this is the grid that will be the reference, all other psfs will
	; be shifted to this one. So this will define the new interpolated
	; psf as well
	master_xzeroind=where((*high_res_psfs[Q22_ind mod 281,Q22_ind / 281]).xcoords eq 0)
	master_yzeroind=where((*high_res_psfs[Q22_ind mod 281,Q22_ind / 281]).ycoords eq 0)
	master_xcoords=(*high_res_psfs[Q22_ind mod 281,Q22_ind / 281]).xcoords ; for use in new input of high_res_psfs
	master_ycoords=(*high_res_psfs[Q22_ind mod 281,Q22_ind / 281]).ycoords ; for use in new input of high_res_psfs

	; so now we must determine the shifts and put Q11_ind_psf on the same grid
	; note that no interpolation is ever necessary since they all have the same
	; grid spacing
	Q12_ind_psf=(*high_res_psfs[Q12_ind mod 281,Q12_ind / 281]).values
	Q12_xzeroind=where((*high_res_psfs[Q12_ind mod 281,Q12_ind / 281]).xcoords eq 0)
	Q12_yzeroind=where((*high_res_psfs[Q12_ind mod 281,Q12_ind / 281]).ycoords eq 0)
	dx=Q12_xzeroind-master_xzeroind
	dy=Q12_yzeroind-master_yzeroind
	Q12_ind_psf=translate(Q12_ind_psf,-dx,-dy,missing=!values.f_nan)

	; these are just weighted means
	Rx2=( (xgrid[Q22_ind]-0.0)/(xgrid[Q22_ind]-xgrid[Q12_ind]) )*Q12_ind_psf + $
			( (0.0-xgrid[Q12_ind])/(xgrid[Q22_ind]-xgrid[Q12_ind]) )*Q22_ind_psf
	; now check to see if any nans were added
	new_bad=where(finite(rx2) eq 0 and finite(Q22_ind_psf) eq 1)
	if new_bad[0] ne -1 then rx2[new_bad]=Q22_ind_psf[new_bad]
	new_bad=where(finite(rx2) eq 0 and finite(Q12_ind_psf) eq 1)
	if new_bad[0] ne -1 then rx2[new_bad]=Q12_ind_psf[new_bad]

	endif else Rx2=0

if (Q11_ind ne -1 and Q21_ind ne -1) then begin
	Q11_ind_psf0=(*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).values
	; if the master didnt get set above, use these instead!
	if keyword_set(master_xzeroind) eq 0 then master_xzeroind=where((*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).xcoords eq 0)
	if keyword_set(master_yzeroind) eq 0 then master_yzeroind=where((*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).ycoords eq 0)
	if keyword_set(master_xcoords) eq 0 then master_xcoords=(*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).xcoords ; for use in new input of high_res_psfs
	if keyword_set(master_ycoords) eq 0 then master_ycoords=(*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).ycoords ; for use in new input of high_res_psfs

	; so now we must determine the shifts and put Q11_ind_psf on the same grid
	; as Q22_ind_psf (or just on itself if Q11 is the master)
	; note that no interpolation is ever necessary since they all have the same
	; grid spacing
	Q11_xzeroind=where((*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).xcoords eq 0)
	Q11_yzeroind=where((*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).ycoords eq 0)
	dx=Q11_xzeroind-master_xzeroind
	dy=Q11_yzeroind-master_yzeroind
	Q11_ind_psf=translate(Q11_ind_psf0,-dx,-dy,missing=!values.f_nan)

	; so now we must determine the shifts and put Q21_ind_psf on the same grid
	; note that no interpolation is ever necessary since they all have the same
	; grid spacing
	Q21_ind_psf0=(*high_res_psfs[Q21_ind mod 281,Q21_ind / 281]).values
	Q21_xzeroind=where((*high_res_psfs[Q21_ind mod 281,Q21_ind / 281]).xcoords eq 0)
	Q21_yzeroind=where((*high_res_psfs[Q21_ind mod 281,Q21_ind / 281]).ycoords eq 0)
	dx=Q21_xzeroind-master_xzeroind
	dy=Q21_yzeroind-master_yzeroind
	Q21_ind_psf=translate(Q21_ind_psf0,-dx,-dy,missing=!values.f_nan)

	; these are just weighted means
	Rx1=( (xgrid[Q21_ind]-0.0)/(xgrid[Q21_ind]-xgrid[Q11_ind]) )*Q11_ind_psf + $
			( (0.0-xgrid[Q11_ind])/(xgrid[Q21_ind]-xgrid[Q11_ind]) )*Q21_ind_psf
	; now check to see if any nans were added
	new_bad=where(finite(rx1) eq 0 and finite(Q11_ind_psf) eq 1)
	if new_bad[0] ne -1 then rx1[new_bad]=Q11_ind_psf[new_bad]
	new_bad=where(finite(rx1) eq 0 and finite(Q21_ind_psf) eq 1)
	if new_bad[0] ne -1 then rx1[new_bad]=Q21_ind_psf[new_bad]

	endif else Rx1=0

; if both exist, do the average
if keyword_set(Rx1) and keyword_set(Rx2) then begin 
	; so Rx1 and Rx2 are in hybrid positions 
	; if by chance they are on the same line (yposition) then it would be constant - but this will never happen
	; so we need to find the average y position for Rx2 and Rx1
	Rx2_avg_y=(ygrid[Q22_ind]+ygrid[Q12_ind])/2.0
	Rx1_avg_y=(ygrid[Q21_ind]+ygrid[Q11_ind])/2.0

	new_psf= ( (Rx2_avg_y-0.0)/(Rx2_avg_y-Rx1_avg_y) )*(Rx1) + $
					( (0.0-Rx1_avg_y)/(Rx2_avg_y-Rx1_avg_y) )*(Rx2)
	; now check to see if any nans were added
	new_bad=where(finite(new_psf) eq 0 and finite(Rx2) eq 1)
	if new_bad[0] ne -1 then new_psf[new_bad]=Rx2[new_bad]
	new_bad=where(finite(new_psf) eq 0 and finite(Rx1) eq 1)
	if new_bad[0] ne -1 then new_psf[new_bad]=Rx1[new_bad]

; if just one exists, then just use it 
endif else if keyword_set(Rx1) ne 0 or keyword_set(Rx2) ne 0 then if keyword_set(Rx1) ne 0 then new_psf=Rx1 else new_psf=Rx2

; CASE II 
; so if BOTH Rx1 and Rx2 are not finite - this means that there was no lenslet found in each of the top pair and bottom pair	
; so we must try calculating Ry1 and Ry2

if keyword_set(rx1) eq 0 and keyword_set(rx2) eq 0 then begin
; this is rather annoying - but what it means is that it may be possible to do this from the other direction 
; so averaging in X and then in Y

	if (Q21_ind ne -1 and Q22_ind ne -1) then begin
			Q22_ind_psf=(*high_res_psfs[Q22_ind mod 281,Q22_ind / 281]).values
			; reset the master
				master_xzeroind=where((*high_res_psfs[Q22_ind mod 281,Q22_ind / 281]).xcoords eq 0)
				master_yzeroind=where((*high_res_psfs[Q22_ind mod 281,Q22_ind / 281]).ycoords eq 0)
				master_xcoords=(*high_res_psfs[Q22_ind mod 281,Q22_ind / 281]).xcoords ; for use in new input of high_res_psfs
				master_ycoords=(*high_res_psfs[Q22_ind mod 281,Q22_ind / 281]).ycoords ; for use in new input of high_res_psfs

			; so now we must determine the shifts and put Q21_ind_psf on the same grid
			; note that no interpolation is ever necessary since they all have the same
			; grid spacing
			Q21_ind_psf0=(*high_res_psfs[Q21_ind mod 281,Q21_ind / 281]).values
			Q21_xzeroind=where((*high_res_psfs[Q21_ind mod 281,Q21_ind / 281]).xcoords eq 0)
			Q21_yzeroind=where((*high_res_psfs[Q21_ind mod 281,Q21_ind / 281]).ycoords eq 0)
			dx=Q21_xzeroind-master_xzeroind
			dy=Q21_yzeroind-master_yzeroind
			Q21_ind_psf=translate(Q21_ind_psf0,-dx,-dy,missing=!values.f_nan)
	
			; these are just weighted means
			R2y=( (ygrid[Q22_ind]-0.0)/(ygrid[Q22_ind]-ygrid[Q21_ind]) )*Q21_ind_psf + $
					( (0.0-ygrid[Q21_ind])/(ygrid[Q22_ind]-ygrid[Q21_ind]) )*Q22_ind_psf

			; now check to see if any nans were added
			new_bad=where(finite(r2y) eq 0 and finite(Q22_ind_psf) eq 1)
			if new_bad[0] ne -1 then r2y[new_bad]=Q22_ind_psf[new_bad]
			new_bad=where(finite(r2y) eq 0 and finite(Q21_ind_psf) eq 1)
			if new_bad[0] ne -1 then r2y[new_bad]=Q21_ind_psf[new_bad]

	endif else R2y=0

	if (Q11_ind ne -1 and Q12_ind ne -1) then begin
		Q11_ind_psf=(*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).values
			; if the master didnt get set above, use these instead!
		if keyword_set(master_xzeroind) eq 0 then master_xzeroind=where((*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).xcoords eq 0)
		if keyword_set(master_yzeroind) eq 0 then master_yzeroind=where((*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).ycoords eq 0)
		if keyword_set(master_xcoords) eq 0 then master_xcoords=(*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).xcoords ; for use in new input of high_res_psfs
		if keyword_set(master_ycoords) eq 0 then master_ycoords=(*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).ycoords ; for use in new input of high_res_psfs
	
		; so now we must determine the shifts and put Q11_ind_psf on the same grid
		; as Q22_ind_psf (or just on itself if Q11 is the master)
		; note that no interpolation is ever necessary since they all have the same
		; grid spacing
		Q11_xzeroind=where((*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).xcoords eq 0)
		Q11_yzeroind=where((*high_res_psfs[Q11_ind mod 281,Q11_ind / 281]).ycoords eq 0)
		dx=Q11_xzeroind-master_xzeroind
		dy=Q11_yzeroind-master_yzeroind
		Q11_ind_psf=translate(Q11_ind_psf0,-dx,-dy,missing=!values.f_nan)
		
		; so now we must determine the shifts and put Q11_ind_psf on the same grid
		; note that no interpolation is ever necessary since they all have the same
		; grid spacing
		Q12_ind_psf=(*high_res_psfs[Q12_ind mod 281,Q12_ind / 281]).values
		Q12_xzeroind=where((*high_res_psfs[Q12_ind mod 281,Q12_ind / 281]).xcoords eq 0)
		Q12_yzeroind=where((*high_res_psfs[Q12_ind mod 281,Q12_ind / 281]).ycoords eq 0)
		dx=Q12_xzeroind-master_xzeroind
		dy=Q12_yzeroind-master_yzeroind
		Q12_ind_psf=translate(Q12_ind_psf,-dx,-dy,missing=!values.f_nan)

		; these are just weighted means
		R1y=( (ygrid[Q12_ind]-0.0)/(ygrid[Q12_ind]-ygrid[Q11_ind]) )*Q11_ind_psf + $
				( (0.0-ygrid[Q11_ind])/(ygrid[Q12_ind]-ygrid[Q11_ind]) )*Q12_ind_psf
	
		; now check to see if any nans were added
		new_bad=where(finite(r1y) eq 0 and finite(Q11_ind_psf) eq 1)
		if new_bad[0] ne -1 then r1y[ind]=Q11_ind_psf[ind]
		new_bad=where(finite(r1y) eq 0 and finite(Q21_ind_psf) eq 1)
		if new_bad[0] ne -1 then r1y[ind]=Q21_ind_psf[ind]

	
	endif else R1y=0

; we know from above that both R2y and R1y do not exist since a corner (or two) are missing
	if (keyword_set(R1y) ne 0 or keyword_set(R2y) ne 0) then if (keyword_set(R1y) ne 0) then new_psf=R1y else new_psf=R2y

	if keyword_set(r1y) eq 0 and keyword_set(r2y) eq 0 then stop,'this should never happen!'
endif

; now we have the new PSF, so we have to put it into a structure which is the same as high_res_psfs
obj_PSF = {values: new_psf, $
           xcoords: master_xcoords, $
           ycoords: master_ycoords, $
           tilt: 0.0,$
           id: [lcoords] }
; now replace the null pointer in high_res_psfs with a new (and valid) one
high_res_psfs[lcoords[0],lcoords[1],lcoords[2]]=ptr_new(obj_PSF,/no_copy)
;window,2
;tvdl, (*high_res_psfs[lcoords[0],lcoords[1],lcoords[2]]).values
;stop

;time3=systime(/seconds)
;print, time2-time1
;print, time3-time2

;print,''
;print, time1a-time1
;print, time1b-time1a
;print, time2-time1b
;stop
; now return the pointer 
return,high_res_psfs[lcoords[0],lcoords[1],lcoords[2]] 

end
