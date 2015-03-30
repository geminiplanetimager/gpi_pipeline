;Stolen from mpfit2dpeak
; Compute the "u" value = (x/a)^2 + (y/b)^2 with optional rotation
function mpfit2dpeak_u, x, y, p, tilt=tilt, symmetric=sym
  COMPILE_OPT strictarr
  widx  = abs(p[2]) > 1e-20 & widy  = abs(p[3]) > 1e-20 
  if keyword_set(sym) then widy = widx
  xp    = x-p[4]            & yp    = y-p[5]
  theta = p[6]
  if keyword_set(tilt) AND theta NE 0 then begin
      c  = cos(theta) & s  = sin(theta)
      return, ( (xp * (c/widx) - yp * (s/widx))^2 + $
                (xp * (s/widy) + yp * (c/widy))^2 )
  endif else begin
      return, (xp/widx)^2 + (yp/widy)^2
  endelse

end