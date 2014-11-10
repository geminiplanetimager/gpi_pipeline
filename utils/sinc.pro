;+
; FUNCTION SINC(X) (cardinal sinus)
;
;        Computes SINC(X) X:-> SIN(PI*X)/(PI*X)
;
; INPUTS: name | type | unit
;
;        X | 1 to 6 or 9 | any
;        Variable the cardinal sinus has to be given.
;
; OUTPUTS: name | type | unit
;
;        RES | 4,5,6 or 9 | 1
;        cardinal sinus of X. The result is of the same type as the
;        input, except for byte, integer & long integer which are
;        given a floating point output.
;
; EXAMPLE:
;
; IDL> print,sinc(!dpi)
;     -0.043598629
; IDL> print,sinc(!pi)
;    -0.0435987
;
; MODIFICATION HISTORY
;
;        Feb 08, 2003 Laurent Jolissaint HIA/NRC written
;        Feb 18, 2003 LJ removed DOUBLE keyword (useless).
;        Nov 13, 2003 LJ corrected the documentation.
;        Nov 27, 2003 LJ introduced ERR_EXIT for error management
;
; BUGS : laurent.jolissaint@nrc-cnrc.gc.ca
;-
function SINC,X

  ; ARGUMENT CHECK-IN
  if n_params() ne 1 then ERR_EXIT,FUN='SINC.PRO',ERR='AN ARGUMENT MUST BE GIVEN'
  typ=size(X,/type)
  if typ lt 1 then ERR_EXIT,FUN='SINC.PRO',ERR='WRONG TYPE OF ARGUMENT'
  if typ gt 6 and typ ne 9 then ERR_EXIT,FUN='SINC.PRO',ERR='WRONG TYPE OF ARGUMENT'

  ; CARDINAL SINUS
  if (typ ge 1 and typ le 4) or typ eq 6 then begin
    if typ ne 6 then mat=float(X)
    if typ eq 6 then mat=X
    w=where(X eq 0)
    if w(0) ne -1 then mat(w)=1
    w=where(X ne 0)
    if w(0) ne -1 then begin
      if typ ne 6 then mat(w)=float(sin(!dpi*X(w))/(!dpi*X(w)))
      if typ eq 6 then mat(w)=complex(sin(!dpi*X(w))/(!dpi*X(w)))
    endif
  endif else begin
    mat=X
    w=where(X eq 0)
    if w(0) ne -1 then mat(w)=1
    w=where(X ne 0)
    if w(0) ne -1 then mat(w)=sin(!dpi*X(w))/(!dpi*X(w))
  endelse

  return,mat

end
