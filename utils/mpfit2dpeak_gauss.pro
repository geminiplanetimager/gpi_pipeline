; Gaussian Function stolen from mpfit2dpeak
function mpfit2dpeak_gauss, x, y, p, tilt=tilt, symmetric=sym, _extra=extra
  COMPILE_OPT strictarr
  sz = size(x)
  if sz[sz[0]+1] EQ 5 then smax = 26D else smax = 13.

  u = mpfit2dpeak_u(x, y, p, tilt=keyword_set(tilt), symmetric=keyword_set(sym))
  mask = u LT (smax^2)  ;; Prevents floating underflow
  return, p[0] + p[1] * mask * exp(-0.5 * u * mask)
end