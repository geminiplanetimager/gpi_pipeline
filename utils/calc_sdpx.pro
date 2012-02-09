;+
; NAME: calc_sdpx
; DESCRIPTION: Calculate length of spectra in pixels
;
; INPUTS: wavcal, filter [xmini, CommonWavVect]
;
; KEYWORDS:
;    None
;
; OUTPUTS:  integer value
;
; HISTORY:
;   2012-02-09 Dmitry Savransky
;-

function calc_sdpx, wavcal, filter, xmini, CommonWavVect

  ; get lambda min and max
  cwv=get_cwv(filter)
  CommonWavVect=cwv.CommonWavVect        
  lambdamin=CommonWavVect[0]
  lambdamax=CommonWavVect[1]

  ;find the pixel corresponding to lambda_min and lambda_max
  xmini=(change_wavcal_lambdaref( wavcal, lambdamin))[*,*,0]
  xminifind=where(finite(xmini), wct)
  if wct eq 0 then return, -1
  xmini[xminifind]=ceil(xmini[xminifind])
  xmaxi=(change_wavcal_lambdaref( wavcal, lambdamax))[*,*,0]

  ;delta x
  xdiff=abs(xmaxi-xmini)
  bordnan=where(~finite(xdiff),cc)
  if cc gt 0 then xdiff[bordnan]=0.

  ;length of spectrum in pix
  sdpx=max(ceil(xdiff))+1

  return, sdpx
end
