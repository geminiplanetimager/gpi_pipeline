;here is the newtest.pro (test program) and the nnls routine.
;
;to run them just do
;IDL>.r uv_to_matrix.pro
;IDL>.r nnls.pro
;IDL>.r newtest.pro
;
;IDL> newtest
;
;
;Jay Dinsick
;NASA Intern (HESSI)
;building 21 room C120
;dinsick@fourier.gsfc.nasa.gov
;(301)286-5114

;============================================================================
; PROJECT:
;       HESSI
;
; NAME:
;       NNLS - Nonnegative Least Squares
;
; PURPOSE: 
;	Given an m by n matrix, a, and a m-vector, b, 
;       compute and n vector, x, that solves the least spuares problem:
;	A * X = B subject to X >= 0
;
; METHOD:
;	NNLS distinguishes itself on bright, compact sources that neither
;	`CLEAN' nor MEM can process adequately. On such	sources, both 
;	CLEAN and MEM produce artifacts that resemble calibration errors 
;	and that limit dynamic range. NNLS has no difficulty imaging such 
;	sources. It also has no difficulty with sharp edges, such as 
;	those of planets or of strong shocks, and can be very advantageous 
;	in producing models for self-calibration for both types of sources. 
;	NNLS deconvolution can reach the thermal noise limit in VLBA 
;	images for which `CLEAN' produces demonstrably worse solutions.  
;	NNLS is therefore a powerful deconvolution algorithm for making 
;	high dynamic range images of compact sources for which strong 
;	finite support constraints are applicable. 
;
; CATEGORY:
;       imaging (hessi/image)
; 
; CALLING SEQUENCE: 
;       nnls, x, m, n, b, x, rnorm, w, indx, mode
;
; INPUTS: 
;
;       m=	The number of rows 
; 	n= 	The number of colums
;  	a(m,n)= The m by n matrix
;  	b(m)=   On entry b contains the m vector 
;	x(n)=   On entry x need not be initialized
;  	w(n)=   An n-array of working space
;  	indx(n)=An n integer working array of length at least n
;      
; OUTPUTS:
;	a=	On exit, a() contains the product matrix, q*a, where q is an
;	        m x m orthogonal matrix generated implicity by this subroutine
;	b=	On exit b() contains q*b
;	x=	On exit x() will contain the solution vector
;  	rnorm=  On exit rnorm contains the Euclidean norm of the residual vector
;	w=	On exit w() will contain the dual solution vector   
;    		w will satisfy w(i) = 0. For all i in set p
; 		and w(i) <=0. For all i in set z
;       indx=   On exit the contents of this array define the sets p and z as follows..
;              	indx(1) thru indx(nsetp) = set p
;              	indx(iz1) thru indx(iz2) = set z
;              	iz1 = nsetp +1 = npp1
;              	iz2 = n
;  	mode=   This is a success-failure flag with the following meanings
;          	1   The solutions has been computed successfully
;          	2   The dimensions of the problem are bad
;              	    either m <= 0 or n<= 0
;          	3   Iteration count exceeded.  More than 3*n iterations
;       
; EXAMPLE:
;       This procedure needs to be called by an outside routine.  i.e. test.pro
;       IDL> test.pro
; SEE ALSO:
;       http://hesperia.gsfc.nasa.gov~schmahl/nnls/index.html
;
; HISTORY:
;  	The original version of this code was developed by
;  	Charles L. Lawson and Richard J. Hanson at Jet Propulsion Laboratory
;  	1973 JUN 12, and published in the book
;  	"SOLVING LEAST SQUARES PROBLEMS", Prentice-HalL, 1974.
;  	Revised FEB 1995 to accompany reprinting of the book by SIAM.
;
;       IDL Release 0: Converted to IDL and Adapted for the HESSI imaging suite 
;       Development for IDL Release 0, January 2002 
;	   by Jay Dinsick, dinsick@fourier.gsfc.nasa.gov
;       Release 1 in Fortran 90 
;	   by Alan Miller, April 1997
;       Release 0, June 1973, 
;	   by Charles L> Lawson and Richard J. Hanson
;============================================================================

pro nnls,a,m,n,b,x,rnorm,w,indx,mode

indx=intarr(n)

;local variables

count = 0
zero=0.0
xtest = 0
factor =0.01
two = 2.0
zz = dblarr(m+1)
dummy=dblarr(m+1)

;These arrays a_i, b_i, x_i, indx_i, and w_i are used in this NNLS procedure because
;IDL and most languages access an array, N, by elements 0 to N-1 while Fortran 
;accesses an array, N, from 1 to N.  This enables the calling routing for nnls 
;to access/pass arrays like most IDL programs to prevent this routine for 
;having to be completely redone after the conversion from Fortran, these temp 
;variables are used.  They are 1 cell bigger than the the values passed in 
;from the calling program.  
;i.e.
;a(100,100) : passed in value for a 
;a_i(101,101): temporary array to hold the array, a, for this procedure 
;the shifting of the elements
;a_i(1:100,1:100) = a(0:99, 0:99) 
;The elements are shifted back by doing the opposite:
;a(0:99,0:99) = a_i(1:100,1:100)
;this is done at the end before being passed back to the main calling routine

;This saved a considerable amount of time during the conversion of the program, 
;since it was written in a strange way to begin with in Fortran.  One could 
;not just convert the intial values to 0 from 1, the answers would not be the same 

;This array shifting also does not increase the runtime speed more than .1 second 
;since it is only done twice in the routine

a_i = dblarr(n+1,m+1)
b_i = dblarr(m+1)
x_i = dblarr(m+1)
indx_i = intarr(n+1)
w_i = dblarr(n+1)

;shifting of the array elements
a_i(1:n,1:m) = a(0:n-1,0:m-1)
b_i(1:m) = b(0:m-1)
x_i(1:m) = x(0:m-1)
indx_i(1:n) = indx(0:n-1)
w_i(1:n) = w(0:n-1)

;Temp arrays for passing to different procedures
;since idl does not pass 2 dim arrays the same way as fortran does
;changed after the conversion
tempj = dblarr(m+1) 
tempjj = dblarr(m+1) 
h12tempa = dblarr(m+1)
h12temp = dblarr(m+1)

;;;;; end local variable declaration
 
mode = 1
if (m LE 0 OR n LE 0) then begin
  mode = 2
  return
endif
iter = 0
itmax = 3*n
;                     INITIALIZE THE ARRAYS indx_ii() AND X().
for i = 1,n do begin
  x_i(i) = zero
  indx_i(i) = i
endfor
iz2 = n
iz1 = 1
nsetp = 0
npp1 = 1
j=1

;                             ******  MAIN LOOP BEGINS HERE  ******
;                  QUIT IF ALL COEFFICIENTS ARE ALREADY IN THE SOLUTION.
;                        OR IF M COLS OF A HAVE BEEN TRIANGULARIZED.

num30:

if ((iz1 GT iz2) OR (nsetp GE m)) then begin 
  GOTO, num350
endif
;         COMPUTE COMPONENTS OF THE DUAL (NEGATIVE GRADIENT) VECTOR W().

i_i_i1 = iz2
i_i_i2 = m

for iz=iz1,i_i_i1 do begin
  j = indx_i(iz)
  sm = 0
  i_i_i2 = m
  for l=npp1, i_i_i2 do begin
    sm = sm + a_i(j,l) * b_i(l)
  endfor
  w_i(j)=sm
endfor

sm=0
;                                   FIND LARGEST POSITIVE W(J).
num60: 
wmax = zero
for iz = iz1,iz2 do begin
  j = indx_i(iz)
  if (w_i(j) GT wmax) then begin  
    wmax = w_i(j)
    izmax = iz
  endif
endfor

;             IF WMAX  <=  0. GO TO TERMINATION.
;             THIS INDICATES SATISFACTION OF THE KUHN-TUCKER CONDITIONS.;


if (wmax LE zero) then begin
GOTO, num350
endif

iz = izmax
j = indx_i(iz)

;     THE SIGN OF W(J) IS OK FOR J TO BE MOVED TO SET P.
;     BEGIN THE TRANSFORMATION AND CHECK NEW DIAGONAL ELEMENT TO AVOID
;     NEAR LINEAR DEPENDENCE.

asave = a_i(j,npp1)
h12tempa= a_i(j,*)
Tstart= systime(1)
h12,1, npp1, npp1+1, m, h12tempa, up, dummy, 1, 1, 0
a_i(j,*) = h12tempa

unorm = zero

if (nsetp NE 0) then begin
  i_i_i1 = nsetp
  for l=1, i_i_i1 do begin
    d_i_i1 = a_i(j,l)
    unorm = unorm + d_i_i1 * d_i_i1
  endfor
endif
unorm = SQRT(unorm)

if (unorm + ABS(a_i(j,npp1))*factor - unorm  GT  zero) then begin

;        COL J IS SUFFICIENTLY INDEPENDENT.  COPY B INTO ZZ, UPDATE ZZ
;        AND SOLVE FOR ZTEST ( = PROPOSED NEW VALUE FOR X(J) ).

  zz(1:m) = b_i(1:m)
  h12tempb = a_i(j,*)  ;used as a place holder since IDL didn't pass the value correctly otherwise
  h12,2, npp1, npp1+1, m, h12tempb, up, zz, 1, 1, 1  ;calls h12 sub
  a_i(j,*) = h12tempb
  ztest = zz(npp1)/a_i(j,npp1) ;zz/a

;                                     SEE IF ZTEST IS POSITIVE

  IF (ztest GT zero) then begin
    GOTO, num140
  endif
endif
;     REJECT J AS A CANDIDATE TO BE MOVED FROM SET Z TO SET P.
;     RESTORE A(NPP1,J), SET W(J) = 0., AND LOOP BACK TO TEST DUAL
;     COEFFS AGAIN.

a_i(j,npp1) = asave
w_i(j) = zero
GOTO, num60

;     THE INDEX  J = indx_i(IZ)  HAS BEEN SELECTED TO BE MOVED FROM
;     SET Z TO SET P.    UPDATE B,  UPDATE INDICES,  APPLY HOUSEHOLDER
;     TRANSFORMATIONS TO COLS IN NEW SET Z,  ZERO SUBDIAGONAL ELTS IN
;     COL J,  SET W(J) = 0.

num140:

b_i(1:m) = zz(1:m)
 
indx_i(iz) = indx_i(iz1)  
indx_i(iz1) = j

iz1 = iz1+1
nsetp = npp1
npp1 = npp1+1
mda = SIZE(a_i(1,*), /N_Elements)
mda = mda - 1 
Tstart = systime(1)
if (iz1  LE  iz2) then begin
  for jz = iz1,iz2 do begin
    jj = indx_i(jz)
    tempj = a_i(j,*)
    tempjj = a_i(jj,*)
    h12,2, nsetp, npp1, m, tempj, up, tempjj, 1, mda, 1  
    a_i(j,*) = tempj
    a_i(jj,*) = tempjj
  endfor
endif

if (nsetp NE m) then begin
  a_i(j,npp1:m) = zero
endif
w_i(j) = zero
;                                SOLVE THE TRIANGULAR SYSTEM.
;                                STORE THE SOLUTION TEMPORARILY IN ZZ().

solve_triangular,a_i,indx_i,zz,nsetp

;                       ******  SECONDARY LOOP BEGINS HERE ******

;                          ITERATION COUNTER.

num210:
iter = iter+1
if (iter GT itmax) then begin
  mode = 3
  GOTO, num350
endif

;                    SEE IF ALL NEW CONSTRAINED COEFFS ARE FEASIBLE.
;                                  IF NOT COMPUTE ALPHA.

alpha = two
for ip = 1,nsetp do begin
  l = indx_i(ip)
  if (zz(ip)  LE  zero) then begin
    t = -x_i(l)/(zz(ip)-x_i(l))
    if (alpha GT t) then begin
      alpha = t
      jj = ip
    endif
  endif
endfor

;          IF ALL NEW CONSTRAINED COEFFS ARE FEASIBLE THEN ALPHA WILL
;          STILL = 2.    IF SO EXIT FROM SECONDARY LOOP TO MAIN LOOP.



if (alpha EQ two) then GOTO, num330
;          OTHERWISE USE ALPHA WHICH WILL BE BETWEEN 0. AND 1. TO
;          INTERPOLATE BETWEEN THE OLD X AND THE NEW ZZ.

for ip = 1,nsetp do begin
  l = indx_i(ip)
  x_i(l) = x_i(l) + alpha*(zz(ip)-x_i(l))

endfor

;        MODIFY A AND B AND THE INDEX ARRAYS TO MOVE COEFFICIENT I
;        FROM SET P TO SET Z.

i = indx_i(jj)

num260:
x_i(i) = zero

if (jj NE nsetp) then begin 
  jj = jj+1
  for j = jj,nsetp do begin
    ii = indx_i(j)
    indx_i(j-1) = ii
    gtemp = a_i(ii,j-1) ;temp vars since idl doesn't pass them correctly otherwise
    gtemp2 = a_i(ii,j)
    sig = a_i(ii,j-1)
    g1,gtemp,gtemp2, cc, ss, sig  ;calls pro g1
    a_i(ii,j) = gtemp2  ;sets the a_i(m,n) matrix equal to the temp values after calling g1
    a_i(ii,j-1) = sig
    a_i(ii,j) = zero
    for l = 1,n do begin
      if (l NE ii) then begin  ;problem lies here

;                 Apply procedure G2 (CC,SS,A(J-1,L),A(J,L))

        temp = a_i(l,j-1)
        a_i(l,j-1) = cc*temp + ss*a_i(l,j)
        a_i(l,j)   = -ss*temp + cc*a_i(l,j)
      endif

    endfor

;                 Apply procedure G2 (CC,SS,B(J-1),B(J))

    temp = b_i(j-1)
    b_i(j-1) = cc*temp + ss*b_i(j)
    b_i(j)   = -ss*temp + cc*b_i(j)
  endfor
endif

npp1 = nsetp
nsetp = nsetp-1
iz1 = iz1-1
indx_i(iz1) = i


;        SEE IF THE REMAINING COEFFS IN SET P ARE FEASIBLE.  THEY SHOULD
;        BE BECAUSE OF THE WAY ALPHA WAS DETERMINED.
;        IF ANY ARE INFEASIBLE IT IS DUE TO ROUND-OFF ERROR.  ANY
;        THAT ARE NONPOSITIVE WILL BE SET TO ZERO
;        AND MOVED FROM SET P TO SET Z.

for jj = 1,nsetp do begin
  i = indx_i(jj)
  if (x_i(i) LE zero) then begin

    GOTO, num260
  endif
endfor

;         COPY B( ) INTO ZZ( ).  THEN SOLVE AGAIN AND LOOP BACK.
zz(1:m) = b_i(1:m)

;solves a triangular
solve_triangular,a_i,indx_i,zz,nsetp

GOTO, num210
;                      ******  END OF SECONDARY LOOP  ******

num330:
for ip = 1,nsetp do begin
  i = indx_i(ip)
  x_i(i) = zz(ip)
endfor
;        ALL NEW COEFFS ARE POSITIVE.  LOOP BACK TO BEGINNING.

GOTO, num30

;                        ******  END OF MAIN LOOP  ******

;                        COME TO HERE FOR TERMINATION.
;                     COMPUTE THE NORM OF THE FINAL RESIDUAL VECTOR.

num350:

sm = zero

if (npp1 LE m) then begin 
  i_i_i1 = m
  for i=npp1, i_i_i1 do begin
    d_i_i1 = b_i(i)
    sm = sm + ( d_i_i1 * d_i_i1)
  endfor
endif else w_i(1:n) = zero 
rnorm = SQRT(sm)

;This shifts the temp values back to the arrays
;before passing them back to the main routine
;since the calling routine accesses the arrays 0:N-1

a(0:n-1,0:m-1) = a_i(1:n,1:m)
b(0:m-1) = b_i(1:m)
x(0:m-1) = x_i(1:m)
indx(0:n-1) = indx_i(1:n)
w(0:n-1) = w_i(1:n)

RETURN

end

pro solve_triangular, a,indx, zz, nsetp

for l = 1,nsetp do begin
  ip = nsetp+1-l
  if (l  NE  1) then zz(1:ip) = zz(1:ip) - a(jj,1:ip)*zz(ip+1)
  jj = indx(ip)
  zz(ip) = zz(ip) / a(jj,ip)
endfor

end

pro g1, a,b,cterm, sterm, sig
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


;used by NNLS
pro h12,mode, lpivot, l1, m, u, up, c, ice, icv, ncv
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

;--Business_of_Ferrets_449_000
;Content-Type: TEXT/plain; name="newtest.pro"; charset=us-ascii; x-unix-mode=0666
;Content-Description: newtest.pro
;Content-MD5: HNuW4poR1+ijic4PWoh8hA==

; NAME: newtest.pro
;
; CALLING SEQUENCE:
;	IDL> newtest
;
; PURPOSE:
; 	Fit a mixture of exponentials by NNLS.
;
; INPUTS: 
;
;       m=	The number of rows 
; 	n= 	The number of colums
;	t0=	Time constant 
;  	a(m,n)= Puts values in the the m by n matrix
;  	b(m)=   Puts values into b() vector (random values)
;	x(n)=   On entry b need not be initialized will return x
;  	w(n)=   An n-array of working space
;	ai(m,n)=An m by n array of random numbers. ai(i,j) = 1 where i = j
;  	indx()= An n integer working array of length at least n
;      
; OUTPUTS:
;	a=	On exit, a() contains the product matrix, q*b, where q is an
;	        m x m orthogonal matrix generated implicity by this subroutine
;	b=	On exit b() contains q*b
;	x=	On exit x() will contain the solution vector;  all x's >= 0 are printed
;	t0 =	The time constraint is printed all with it's corresponding x value that is >= 0
;  	rnorm=  On exit rnorm contains the Euclidean norm of the residual vector
;	w=	On exit w() will contain the dual solution vector   
;    		w will satisfy w(i) = 0. For all i in set p
; 		and w(i) <=0. For all i in set z
;       indx=   On exit the contents of this array define the sets p and z as follows..
;              	indx(1) thru indx(nsetp) = set p
;              	indx(iz1) thru indx(iz2) = set z
;              	iz1 = nsetp +1 = npp1
;              	iz2 = n
;  	mode=   This is a success-failure flag with the following meanings
;          	1   The solutions has been computed successfully
;          	2   The dimensions of the problem are bad
;              	    either m <= 0 or n<= 0
;          	3   Iteration count exceeded.  More than 3*n iterations
;
; HISTORY:
;       Created by Dr. Edward Schmahl and Jay Dinsick as another test case for NNLS
;       Coded by Jay Dinsick, dinsick@fourier.gsfc.nasa.gov
;


pro newtest

;IDL does column, row when accessing 2 dim arrays
;most languages do row, column.  i.e. C, Fortran

;declaring and initializing variables to be passed to the NNLS routine


restore, 'a_vis.sav'
m = SIZE(a(0,*), /N_Elements)
n = SIZE(vis(*), /N_Elements)
print,'a(*,0) = ',SIZE(a(*,0), /N_Elements)
print,'a(0,*) = ',SIZE(a(0,*), /N_Elements)
print,'vis = ', SIZE(vis(*), /N_Elements)
x = dblarr(n)
b = dblarr(m)
t0=dblarr(m)
mode=0
w = dblarr(n)
indx = intarr(n)
rnorm =0.00
ai = dblarr(n,m)
b = randomu(seed,m)

;calculates the time constant
t0(0) = 2.0
t0(1) = t0(0) * SQRT(2.0)
for i = 2, m-1 do begin
  t0[i] = 2.0 * t0[i-2]
endfor

; Calculate the X-matrix, avoiding underflow

;makes ai a 100 x 100 array of random numbers between 0 and .5
;ai = .5*randomu(seed,n,m)

for j = 0, n-1 do begin
  for i = 0, m-1 do begin
    if j EQ i then ai[j,i] = 1
  endfor
endfor

;inverts the matrix ai
;a = INVERT(ai) 

;matrix multiplication of ai and b
;x = a##vis
x0 = x
window, 0
;plot, x, title = 'x before running nnls'

;! Now call NNLS to do the fitting.
Tinit = systime(1)
print, 'Calling NNLS...'
nnls, a, m, n, vis, x, rnorm, w, indx, mode
print, 'NNLS Runtime:  ', systime(1) - Tinit, ' Seconds'

plot, x, title ='x after nnls '
;plot, x-x0, title ='x_after-x_before (nnls)'

CASE mode OF
1: begin
    for i = 0, m-1 do begin
         if (b(i) GT 0) then begin
        print, ' Time constant: ', t0(i), '  Fitted amplitude = ', x(i), Format = '(a,F25.5,a, F10.5)'
      endif
   endfor
    print, ''
    print,' Array INDX =', indx, Format = '(a,19i3)'
    print, ''
    print,' Alternate solution:', w, Format ='(a/ (" ", 10f10.5))'
    print,''
    print,' rnorm = ', rnorm, Format = '(a,F9.4)'
 end
2:  print, 'Error in input argument 2 or 3'
3:  print,'Failed to converge'

endcase

stop
end 


