;+
; NAME:     RESAMPLE
;
; PURPOSE:    Use a spline or linearly interpolate gappy data in 
;     order to resample. Any resampled points which are too  
;     large (1.5*YLIMIT) are set to the mean. These points  
;     are labelled by the BADPTS keyword 
;
; CATEGORY:   Time-Series/Spectral analysis
;
; CALLING SEQUENCE: newy = resample(x,y,newx)
;
;     newy = resample(x,y,newx,ylimit,BADPT=badpts,/SPLINE)
;
;
; INPUTS:
;     x,y = the data to be resampled
;   OPTIONAL PARAMETERS:
;     newx  = the new x coords (defines the resampling).
;         If this is not passed then the data is 
;         simply resampled onto the existing x values,
;         which is useful to interpolate over bad  or 
;         missing data by use of the YLIMIT keyword
;     ylimit  = y values greater than this limit are treated 
;         as missing or bad.
;   KEYWORD PARAMETERS:
;     YLIMIT  = same as the ylimit parameter
;     SPLINE_FIT = if set then use spline interpolants 
;         rather than the default linear interpolants 
;         (the INTERPOL routine)
;
; OUTPUTS:
;     newy  = the interpolated/resampled y values
;   KEYWORD PARAMETERS:
;     YMAX  = the determined maximum(abs(y)) over the 
;         good data prior to resampling
;     MAX = YMAX but after resampling
;     GOOD  = the indices of the determined GOOD data
;     BADPTS  = the indices of the determined BAD data. 
;
; COMMON BLOCKS:
; none.
; SIDE EFFECTS:
; none.
; MODIFICATION HISTORY:
; Written by: Trevor Harris, Physics Dept., University of Adelaide,
;   July, 1990.
;
;-
;-----------------------------------------------------------------------------
    function resample,x,y,newx,ylimit2,ylimit=ylimit,$
      ymax=y1max,max=max1,badpts=badpts,good=good,$
      spline_fit=spline_fit

  if (n_elements(newx) le 0) then newx=x
  if (n_elements(ylimit2) le 0) then ylimit2=max(y)+1
  if (not keyword_set(ylimit)) then ylimit = ylimit2
  good = where(y lt ylimit,count)

  IF (count le 0) THEN BEGIN
    txt = "No GOOD data points to interpolate (all values are >" $
        + string(ylimit)+")"
    message,/info,txt
    message,/info,"No Interpolation performed.."
    ts1 = y

  ENDIF ELSE BEGIN

  y1 = y(good)
  x1 = x(good)
  order = sort(x1)
  x1 = x1(order)
  y1 = y1(order)
  y1max = max(abs(y1))

  if (count gt 1) then  $
    if (keyword_set(spline_fit)) then ts1=spline(x1,y1,newx,0.1) $
    else ts1 = interpol(y1,x1,newx) $
  else ts1 = y1


  tmp = abs(ts1)
  good = where(tmp le y1max*1.5)
  badpts = where(tmp gt y1max*1.5,count)
  max1 = max(tmp(good))
  if (count gt 0) then begin
    mean = total(ts1(good))/n_elements(good)
    ts1(badpts) = mean
  endif 

  ENDELSE

  return,ts1
  end






