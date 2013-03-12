;+
; NAME: calc_sdpx
; DESCRIPTION: Calculate length of spectra in pixels
;
; INPUTS: wavcal, filter [spectra_lambdamin_y, CommonWavVect]
;
; KEYWORDS:
;    None
;
; OUTPUTS:  integer value
;    
;
; HISTORY:
;   2012-02-09 Dmitry Savransky
;   2013-03-08 MP: Updated notation to reflect delta Y instead of X orientations.
;   		"xmini" -> "spectra_lambdamin_y", "xdiff" -> "ydiff"
;-

function calc_sdpx, wavcal, filter, spectra_lambdamin_y, CommonWavVect, spectra_lambdamax_y

  ; get lambda min and max
  cwv = get_cwv(filter)
  CommonWavVect = cwv.CommonWavVect        
  lambdamin = CommonWavVect[0]
  lambdamax = CommonWavVect[1]

  ;find the pixel corresponding to lambda_min and lambda_max
  spectra_lambdamin_y = (change_wavcal_lambdaref( wavcal, lambdamin))[*,*,0]
  spectra_lambdamin_yfind = where(finite(spectra_lambdamin_y), wct)
  if wct eq 0 then return, -1
  spectra_lambdamin_y[spectra_lambdamin_yfind] = ceil(spectra_lambdamin_y[spectra_lambdamin_yfind])
  spectra_lambdamax_y = (change_wavcal_lambdaref( wavcal, lambdamax))[*,*,0]

  ;delta x
  ydiff = abs(spectra_lambdamax_y-spectra_lambdamin_y)
  bordnan = where(~finite(ydiff),cc)
  if cc gt 0 then ydiff[bordnan] = 0.

  ;length of spectrum in pix
  sdpx = max(ceil(ydiff))+1

  return, sdpx
end
