;+
; NAME: alogscale.pro
; PURPOSE:
; 	intelligently logarithmicly scale an image for 
;	display. 
; NOTES:
;	Based on the log scale code from ATV.pro
;
; INPUTS:
; KEYWORDS:
; 	/print
; 	/auto	like ATV's autoscale
; OUTPUTS:
;
; HISTORY:
; 	Began 2003-10-20 01:23:02 by Marshall Perrin 
; 	2004-09-15		Made NaN-aware		MDP
;-

FUNCTION alogscale,image,minval,maxval,min=min,print=print,$
	auto=auto

	if n_elements(min) gt 0 then minval=min
	
	if keyword_set(auto) then begin
		med = median(image)
		sig = stddev(image,/NaN)
		maxval = (med + (10 * sig)) < max(image,/nan)
		minval = (med - (2 * sig))  > min(image,/nan)
	endif

	
	if (n_elements(minval) eq 0) then minval = min(image,/nan)
	if (n_elements(maxval) eq 0) then maxval = max(image,/nan)

	minval=float(minval)
	maxval=float(maxval)
	

    offset = minval - (maxval - minval) * 0.01
      

	if keyword_set(print) then print,minval,maxval,offset

     scaled_image = $
          bytscl( alog10(image - offset), $
                  min=alog10(minval - offset), /nan, $
                  max=alog10(maxval - offset))

   return,scaled_image 

end
