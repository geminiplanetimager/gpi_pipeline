pro h12,mode, lpivot, l1, m, u, up, c, ice, icv, ncv
; this is used by nnls.pro

;  CONSTRUCTION AND/OR APPLICATION OF A SINGLE
;  HOUSEHOLDER TRANSFORMATION..     Q = I + U*(U**T)/B
;     ------------------------------------------------------------------
;                     Subroutine Arguments
;
;     MODE   = 1 OR 2   Selects Algorithm H1 to construct and apply a
;            Householder transformation, or Algorithm H2 to apply a
;            previously constructed transformation.
;     LPIVOT IS THE INDEX OF THE PIVOT ELEMENT.
;     L1,M   IF L1  <=  M   THE TRANSFORMATION WILL BE CONSTRUCTED TO
;            ZERO ELEMENTS INDEXED FROM L1 THROUGH M.   IF L1 GT. M
;            THE SUBROUTINE DOES AN IDENTITY TRANSFORMATION.
;     U(),IUE,UP    On entry with MODE = 1, U() contains the pivot
;            vector.  IUE is the storage increment between elements.
;            On exit when MODE = 1, U() and UP contain quantities
;            defining the vector U of the Householder transformation.
;            on entry with MODE = 2, U() and UP should contain
;            quantities previously computed with MODE = 1.  These will
;            not be modified during the entry with MODE = 2.
;     C()    ON ENTRY with MODE = 1 or 2, C() CONTAINS A MATRIX WHICH
;            WILL BE REGARDED AS A SET OF VECTORS TO WHICH THE
;            HOUSEHOLDER TRANSFORMATION IS TO BE APPLIED.
;            ON EXIT C() CONTAINS THE SET OF TRANSFORMED VECTORS.
;     ICE    STORAGE INCREMENT BETWEEN ELEMENTS OF VECTORS IN C().
;     ICV    STORAGE INCREMENT BETWEEN VECTORS IN C().
;     NCV    NUMBER OF VECTORS IN C() TO BE TRANSFORMED. IF NCV  <=  0
;            NO OPERATIONS WILL BE DONE ON C().
;     ------------------------------------------------------------------

one = 1.0
u_idim = 100

if (0 GE lpivot OR lpivot GE l1 OR l1 GT m) then RETURN
cl = ABS(u(lpivot))

if (mode NE 2) then begin
;                            ****** CONSTRUCT THE TRANSFORMATION. ******


  
  for j = l1, m do begin
    if cl LT ABS(u(j)) then cl=ABS(u(j))  
  endfor

  if (cl LE 0) then RETURN

  clinv = one / cl
  sm = (u(lpivot)*clinv)^ 2 ;+ SUM( (u(l1:m)*clinv)^2 )
  for j = l1, m do begin
    d_i_i1= u[j] * clinv;
    sm = sm + d_i_i1 * d_i_i1
  endfor

  cl = cl * SQRT(sm)

  if (u(lpivot) GT 0) then begin
    cl = -cl

  endif
  up = u(lpivot) - cl
  u(lpivot) = cl

endif else if (cl LE 0) then RETURN


;            ****** APPLY THE TRANSFORMATION  I+U*(U**T)/B  TO C. ******


IF (ncv LE 0) then RETURN

b = up * u(lpivot)

;                       B  MUST BE NONPOSITIVE HERE.  IF B = 0., RETURN.

if (b LT 0) then begin

  b = one / b
  i2 = 1 - icv + ice * (lpivot-1)
  incr = ice * (l1-lpivot)
  for j = 1, ncv do begin
    i2 = i2 + icv
    i3 = i2 + incr
    i4 = i3
    sm = c(i2) * up
    for i = l1, m do begin
      sm = sm + c(i3) * u(i)
      i3 = i3 + ice
    endfor
  
    if (sm NE 0) then begin
      sm = sm * b
      c(i2) = c(i2) + sm * up
      for i = l1, m do begin
        c(i4) = c(i4) + sm * u(i)
        i4 = i4 + ice
      endfor
    endif
      
 
  endfor ;! j = 1, ncv
endif
RETURN
END ;SUBROUTINE h12


