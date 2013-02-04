;+
; NAME: find_spectra_positions_quadrant
;find_spectra_positions_quadrant detects positions of spectra in the image with narrow band lamp image.
;find_spectra_positions_quadrant starts with the central peak of the image.
;Next, starting with a initial value of w & P, find the nearest peak (with an increment on the microlens coordinates)
;when nearest peak has been detected, it reevaluate w & P and so forth..
;
;
; INPUTS: 
; 	quad:	which quadrant to consider [1,2,3,4]
; 	wcst: spectral spacing perpendicular to the dispersion axis at the detector in pixel
; 	Pcst: Micro-pupil pattern
; 	nlens:	side length of lenslets matrix
; 	idx:		Array [nlens,nlens] in size, giving positions in lenslet units
; 			relative to the center lenslet. "X" coord  
; 	idy:		Array [nlens,nlens] in size, giving positions in lenslet units
; 			relative to the center lenslet. "Y" coord
; 	cen1:	2-element array giving [x,y] coordinates of centermost spot peak
; 	wx,wy:	define side box length (=2*wx+1) for (first) max detection 
;	  hh: define side box length (=2*hh+1) for (second more accurate) centroid detection
;	  szim: size of im
;	  specpos:	3D array to store the detected spot positions in. 
;	  im:		The 2D detector image
;   edge_x1,x2,y1,y2: locations that define area to consider over im
;   tight_pos: allowed position fluctuations for adjacent mlens
;
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;    Jerome Maire 2008-10
;    2009-06 : JM fix a bug for w&P  when (i=0,j) not in the raw image
;    2010-03-05: JM added tight_pos keyword 
;    2010-08-15: JM added bad pixel map
;-

pro find_spectra_positions_quadrant, quad,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,specpos,im,edge_x1,edge_x2,edge_y1,edge_y2,tight_pos, badpixmap=badpixmap,meth=meth

case quad of 
  1: begin 
      jlim1=0 & jlim2=nlens/2-(1- (nlens mod 2)) & jdir=1 & ilim=nlens/2-(1- (nlens mod 2)) & idir=1 
      end
  2: begin 
      jlim1=0 & jlim2=nlens/2-(1- (nlens mod 2)) & jdir=1 & ilim=-nlens/2 & idir=-1 
      end
  3: begin 
      jlim1=-1 & jlim2=-nlens/2 & jdir=-1 & ilim=-nlens/2 & idir=-1 
     end
  4: begin 
      jlim1=-1 & jlim2=-nlens/2 & jdir=-1 & ilim=nlens/2-(1- (nlens mod 2)) & idir=1
     end
endcase

wtab=dblarr(nlens,nlens) & ptab=dblarr(nlens,nlens)

w0=wcst & P0=Pcst ;initial guess
for j=jlim1,jlim2,jdir do begin
w=w0 & P=P0 ;initial guess
	; note that w0 and P0 get changed below so this does adapt in both
	; directions
;print, 'w=',w,'  P=',P
  for i=0,ilim,idir do begin
      ;if (i eq 1) && (j eq jlim1) then stop
     ;if (nlens/2+i eq 143) && (nlens/2+j eq 143) then stop
    ;calculate approximate position of the next spectrum with w&P
    if (abs(i)+abs(j) ne 0) then begin ;we already have position of the central spectrum 
      dx=idx[nlens/2+i,nlens/2+j]*W*P+jdy[nlens/2+i,nlens/2+j]*W
      dy=jdy[nlens/2+i,nlens/2+j]*W*P-W*idx[nlens/2+i,nlens/2+j]

      ;if this spectrum is in the raw image, 
    	if (dx+cen1[0]-wx-hh ge edge_x1) && (ceil(dx+cen1[0]+wx+hh) le szim[1]-1-edge_x2) && (dy+cen1[1]-wy-hh ge edge_y1) && (ceil(dy+cen1[1]+wy+hh) le szim[2]-1-edge_y2) then begin
          ;if (idir eq -1)&& (j eq 116) then stop
          ;if (idir eq -1)&& (j eq 115) then print, 'j=115 w=',w,'  P=',P
                   ; if (nlens/2+i eq 135) && (nlens/2+j eq 238) then stop
                   ;if (nlens/2-i eq 159) && (nlens/2-j eq 65) then stop
;                   if (nlens/2-i eq 161) && (nlens/2-j eq 64) then stop
;                   if (nlens/2-i eq 157) && (nlens/2-j eq 63) then stop
                  ;if (nlens/2-i eq 147) && (nlens/2-j eq 180) then stop
                  ;if (nlens/2-i eq 145) && (nlens/2-j eq 180) then stop
                  ;if (nlens/2-i eq 33) && (nlens/2-j gt 146) then stop
          ;;calculate centroid to have more accurate position
           ;print, "estimated:",cen1[1]+dy,2047-(cen1[0]+dx)
           if keyword_set(meth) then method="mpfit" else method="barycentric"
                specpos[nlens/2+i,nlens/2+j,0:1]=localizepeak( im, cen1[0]+dx,cen1[1]+dy,wx,wy,hh,badpixmap=badpixmap, meth=method)
               ; print, "estimated:",cen1[0]+dx,cen1[1]+dy, "  specpos=", specpos[nlens/2+i,nlens/2+j,0:1]  mpfit
               ; if (cen1[1]+dy gt 1000) && (cen1[1]+dy lt 1010) && (2047-(cen1[0]+dx) gt 1025) && (2047-(cen1[0]+dx) lt 1037) then stop
            ;if it fails to converge then use an other method
            if specpos[nlens/2+i,nlens/2+j,0] eq -1 then begin
                print, "mpfit failed to converge, let's try gauss2dfit for this mlens..."
                specpos[nlens/2+i,nlens/2+j,0:1]=localizepeak( im, cen1[0]+dx,cen1[1]+dy,wx,wy,hh,badpixmap=badpixmap, meth="gaussfit")
              endif
            if specpos[nlens/2+i,nlens/2+j,0] eq -1 then begin
                print, "gauss2dfit failed to converge, let's use barycentric centroid for this mlens..."
                specpos[nlens/2+i,nlens/2+j,0:1]=localizepeak( im, cen1[0]+dx,cen1[1]+dy,wx,wy,hh,badpixmap=badpixmap, meth="barycentric")
             endif
            
            
;if keyword_set(tight) then begin
    if (sqrt((specpos[nlens/2+i,nlens/2+j,0]-(cen1[0]+dx))^2+(specpos[nlens/2+i,nlens/2+j,1]-(cen1[1]+dy))^2) gt double(tight_pos))  then begin
        specpos[nlens/2+i,nlens/2+j,0]=cen1[0]+dx
        specpos[nlens/2+i,nlens/2+j,1]=cen1[1]+dy
    endif
;endif
            ;;re-estimate w & P using the central spectrum
            dx2=specpos[nlens/2+i,nlens/2+j,0]-specpos[nlens/2,nlens/2,0]
            dy2=specpos[nlens/2+i,nlens/2+j,1]-specpos[nlens/2,nlens/2,1]
            if (jdy[nlens/2+i,nlens/2+j]^2-(idx[nlens/2+i,nlens/2+j])^2) then $
              W=abs((jdy[nlens/2+i,nlens/2+j]*dx2-idx[nlens/2+i,nlens/2+j]*dy2)/(jdy[nlens/2+i,nlens/2+j]^2+(idx[nlens/2+i,nlens/2+j])^2))
		  	;stackpush, wlist, w
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
       endif ;not the central spectrum
       if (i eq 0) then begin
        w0=w & P0=p
       endif
   endfor

endfor

end
