;+
; NAME: find_spectra_positions_quadrant
;find_spectra_positions_quadrant detects positions of spectra in the image with narrow band lamp image.
;find_spectra_positions_quadrant starts with the central peak of the image.
;Next, starting with a initial value of w & P, find the nearest peak (with an increment on the microlens coordinates)
;when nearest peak has been detected, it reevaluate w & P and so forth..
;
;
; INPUTS: 
; common needed:
;
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;    Jerome Maire 2008-10
;    2009-06 : JM fix a bug for w&P  when (i=0,j) not in the raw image

pro find_spectra_positions_quadrant, quad,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,specpos,im

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

w0=wcst & P0=Pcst ;initial guess
for j=jlim1,jlim2,jdir do begin
w=w0 & P=P0 ;initial guess
;print, j
;print, 'w=',w,'  P=',P
  for i=0,ilim,idir do begin
  ;if (i gt 100) then stop
    ;calculate approximate position of the next spectrum with w&P
    if (abs(i)+abs(j) ne 0) then begin ;we already have position of the central spectrum 
      dx=idx[nlens/2+i,nlens/2+j]*W*P+jdy[nlens/2+i,nlens/2+j]*W
      dy=jdy[nlens/2+i,nlens/2+j]*W*P-W*idx[nlens/2+i,nlens/2+j]
      ;print, 'dx=',dx+cen1[0],'  dy=',dy+cen1[1]
      
      ;if this spectrum is in the raw image, 
      if (dx+cen1[0]-wx-hh ge 0) && (ceil(dx+cen1[0]+wx+hh) lt szim[1]) && (dy+cen1[1]-wy-hh ge 0) && (ceil(dy+cen1[1]+wy+hh) lt szim[2]) then begin
          ;if (idir eq -1)&& (j eq 116) then stop
          ;if (idir eq -1)&& (j eq 115) then print, 'j=115 w=',w,'  P=',P
          ;;calculate centroid to have more accurate position
            specpos[nlens/2+i,nlens/2+j,0:1]=localizepeak( im, cen1[0]+dx,cen1[1]+dy,wx,wy,hh)

            ;;re-estimate w & P using the central spectrum
            dx2=specpos[nlens/2+i,nlens/2+j,0]-specpos[nlens/2,nlens/2,0]
            dy2=specpos[nlens/2+i,nlens/2+j,1]-specpos[nlens/2,nlens/2,1]
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
       endif ;not the central spectrum
       if (i eq 0) then begin
        w0=w & P0=p
       endif
   endfor
endfor

end