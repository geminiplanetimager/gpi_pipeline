pro openps,filename,color=color,xsize=xsize,ysize=ysize,inches=inches,$
           xoffset=xoffset,yoffset=yoffset,letter=letter,landscape=landscape,$
           bits=bits
;+
; NAME:
;      openps
; PURPOSE:
;      use it to do postscript plot
;
; EXPLANATION:
;       
;
; Calling SEQUENCE:
;      
;
; INPUT/OUTPUT:
;

; OPTIONAL OUTPUT:
;       
;
; EXAMPLE:
;
;
; DEPENDENCIES:
;
;
; NOTES: 
;      
;             
; REVISION HISTORY
;       Written  before 2008, Mathilde beaulieu/Jean-Francois Lavigne/David Lafreniere/Jerome Maire. 
;-

;

if ~keyword_set(xoffset) then xoffset=0.5
if ~keyword_set(yoffset) then yoffset=0.5

if keyword_set(inches) and ~keyword_set(xoffset) then begin
    xoffset/=2.54
    yoffset/=2.54
endif

if keyword_set(letter) then begin
    xsize=8.
    ysize=10.5
    xoffset=0.25
    yoffset=0.25
    inches=1
endif
if keyword_set(landscape) then begin
    landscape=1
    xsize0=xsize & xoffset0=xoffset

    xsize=ysize
    ysize=xsize0
    xoffset=yoffset
    yoffset=xsize+xoffset0
endif

thick=3
!p.thick=thick & !p.charthick=thick & !p.font=0 & !x.thick=thick & !y.thick=thick
set_plot,'ps'
device,filename=filename,/isolatin1,xsize=xsize,ysize=ysize,inches=inches,$
  xoffset=xoffset,yoffset=yoffset,landscape=landscape,bits=bits
if (keyword_set(color)) then device,/color,bits=8

end
