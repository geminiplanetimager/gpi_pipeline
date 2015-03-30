pro g1, a,b,cterm, sterm, sig
; this is called from inside nnls.pro

;     COMPUTE ORTHOGONAL ROTATION MATRIX..
;
;     COMPUTE.. MATRIX   (C, S) SO THAT (C, S)(A) = (SQRT(A**2+B**2))
;                        (-S,C)         (-S,C)(B)   (   0          )
;     COMPUTE SIG = SQRT(A**2+B**2)
;        SIG IS COMPUTED LAST TO ALLOW FOR THE POSSIBILITY THAT
;        SIG MAY BE IN THE SAME LOCATION AS A OR B .
;     ------------------------------------------------------------------

one = 1.00
zero = 0.0
;     ------------------------------------------------------------------

if (ABS(a) GT ABS(b)) then begin
  xr = b / a
  yr = SQRT(one + xr^2)
  if a LT 0 then signb = -1
  if a GT 0 then signb = 1
  cterm = ABS(one/yr) * signb
  sterm = cterm * xr
  sig = ABS(a) * yr
  RETURN
endif
if (b NE zero) then begin
  xr = a / b
  yr = SQRT(one + xr^2)
  if b LT 0 then signb = -1
  if b GT 0 then signb = 1
  sterm = ABS(one/yr) * signb
  cterm = sterm * xr
  sig = ABS(b) * yr
  RETURN
endif

;!      SIG = ZERO
cterm = zero
sterm = one
RETURN
END ;SUBROUTINE g1


