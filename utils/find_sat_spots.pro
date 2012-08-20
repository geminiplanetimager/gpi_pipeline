function find_sat_spots,s0,leg=leg,locs=locs0, winap = winap
;+
; NAME:
;       find_sat_spots
; PURPOSE:
;       Find satellite spots in GPI images
;
; EXPLANATION:
;       Performs a fourier coregistration with a pure gaussian, and
;       then looks for four locations equidistant from each other in
;       the image (distance given by optional keyword leg).  Then
;       refines the locations by performing 2d gaussian fits.
;
; Calling SEQUENCE:
;       res = find_sat_spots(s0,[leg=leg,locs=locs,winap=winap])
;
; INPUT/OUTPUT:
;       s0 - 2D image (must be consistent with one slice of the cubes
;            produced by the gpi pipeline)
;       locs - Initial sat locations to refine.  If set,
;              coregistration step is skipped.
;       winap - Size of aperture to use (pixels) defaults to 20
;      
;       res - 2x4 array of satellite spot pixel locations
;
; OPTIONAL OUTPUT:
;       leg - Distance between sat spots in pixels
;
; EXAMPLE:
;
;
; DEPENDENCIES:
;	fourier_coreg.pro
;
; NOTES: 
;      
;             
; REVISION HISTORY
;       Written  08/02/2012. Based partially on code by Perrin and
;                            Maire - savransky1@llnl.gov 
;       08.14.12 - Rewrite to automatically find the 'leg' distance.
;                  lambda/leg inputs no longer needed.
;-

;;get dimensions and set defaults
sz = size(s0,/dim)
if not keyword_set(winap) then winap = 20
hh = 5
refpix = hh*2+1  ;search window size
;;create pure 2d gaussian
generate_grids, fx, fy, refpix, /whole
fr = sqrt(fx^2 + fy^2)
ref = exp(-0.5*fr^2)

;;if not given initial centers, need to hunt for them
if not keyword_set(locs0) then begin
   ;;fourier coregister with gaussian to smooth image
   fourier_coreg,s0,ref,out,/wind

   ;;define mask and 4C2 comb set
   msk = make_annulus(winap)
   combs0 = nchoosek(lindgen(4),2)

   ;;initialize loop & go   
   val = max(out,ind)
   counter = 0
   maxcounter = 50
   while counter lt maxcounter do begin  
      ;;update locations
      inds = array_indices(out,ind)  
      if n_elements(locs) ne 0 then locs = [[locs],[inds]] else locs = [inds]  
      
      ;;we only get started once we have 4 locations
      if n_elements(locs)/2. ge 4 then begin  
         ;;only need to check the combinations of the previous locations
         ;;with the newest one. So, we generate all of the combinations of
         ;;the existing locations in groups of 3, and append the last index
         combs = nchoosek(lindgen(n_elements(locs)/2-1),3)  
         combs = [[combs],[lonarr(n_elements(combs)/3)+n_elements(locs)/2-1]]  
         ;;now scan the combinations.
         for j=0,n_elements(combs)/4 - 1 do begin  
            dists = sqrt(total(((locs[*,combs[j,*]])[*,combs0[*,0]] - (locs[*,combs[j,*]])[*,combs0[*,1]])^2d,1))  
            dists = dists[sort(dists)]  
            d1 = max(abs(dists[0:2]-dists[1:3]))  
            d2 = abs(dists[4] - dists[5])  
            ;;we're looking for 4 equal distances, and 2 equal distances sqrt(2) larger
            if (d1 le 2d) && (d2 le 2d) && (abs(mean(dists[4:5])/mean(dists[0:3]) - sqrt(2d)) lt 1e-4) then begin  
               finallocs = locs[*,combs[j,*]]  
               counter = maxcounter  
               break  
            endif   
         endfor  
      endif     
      
      ;;set up next iteration
      out[msk[*,0]+inds[0],msk[*,1]+inds[1]] = min(out)     
      val = max(out,ind)     
      counter += 1   
   endwhile
   if n_elements(finallocs) eq 0 then begin
      message,'Could not locate satellites.',/continue
      return, -1
   endif else locs = finallocs
endif else begin
   if n_elements(locs0) ne 8 || total(size(locs0,/dim) - [2,4]) ne 0 then begin
      message,/continue,'locs input must be 2x4 array'
      return,-1
   endif
   locs = round(locs0)
endelse

;;find centers
cens = dblarr(2,4)
for i=0,3 do begin 
   ;;correlate
   subimage = s0[locs[0,i]-hh:locs[0,i]+hh,locs[1,i]-hh:locs[1,i]+hh]
   fourier_coreg,subimage,ref,shft,/findshift
   cens[*,i] = locs[*,i] - shft
endfor
cens = cens[*,sort(cens[0,*])]
dists = sqrt(total((cens[*,[0,0,0,1,1,2]] - cens[*,[1,2,3,2,3,3]])^2d,1))
leg = mean((dists[sort(dists)])[0:3])

return, cens
end
