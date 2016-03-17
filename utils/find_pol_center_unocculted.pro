function find_pol_center_unocculted, img0, x0, y0 
;+
; NAME:
;        find_pol_center_unocculted
; PURPOSE:
;        Find the UNocculted star poistion in GPI Polarimetry mode
;
; EXPLAINATION
;      
;
; CALLING SEQUENCE:
;        center = find_pol_center_unocculted(img, 148, 147, 5, 5, [maskrad=maskrad, /highpass])
; 
; INPUT/OUTPUT:
;        img0 - 2D or 3D image
;        x0,y0 - inital guess for the center of the occulted star
;        center - 2 element array [x,y] of the calculated star position
;
; OPTIONAL INPUT:
;       
; DEPENDENCIES:
;
; REVISION HISTORY
;        KBF - Written 10/27/15 based on find_pol_center
;-

;make copy of image
img = img0

sz=size(img)
;collapse polarization dimension if not already
if sz[0] eq 3 then img = total(img, 3)

;;note this is a super quick hack. there are much more sophisticated and versatile ways to do this that will appear in a later pipeline iteration. 
gcntrd, img, x0, y0, xcent, ycent, 10
print, x0, y0, xcent, ycent

return, [xcent,ycent]
end
