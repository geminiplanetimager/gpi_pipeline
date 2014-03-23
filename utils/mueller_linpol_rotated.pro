;+
; FUNCTION: mueller_linpol_rot
;   Returns the 4x4 Mueller polarization matrix for a perfect linear polarizer
;   at position angle theta.
;
; INPUTS:
;   theta		an angle, in radians by default
;   /degrees	specifies that the angle is given in degrees
; HISTORY:
;   by Marshall, 2005-ish
;
;-
FUNCTION mueller_linpol_rotated, theta, degrees=degrees
;
; The following formula is taken from C.U.Keller's Instrumentation for
;  Astronomical Spectropolarimetry, page 11.
;
;  Or equivalently see Eq. 4.47 of "Introduction to Spectropolarimetry" by 
;  Jose Carlos del Toro Iniesta, Cambridge University Press 2003


th = theta
if keyword_set(degrees) then th = th*!dtor ; convert to radians

ct = cos(2*th)
st = sin(2*th)
return,0.5*[[1.0,   ct,     st,     0],$
            [ct,    ct^2,   ct*st,  0],$
            [st,    st*ct,  st^2,   0],$
            [0,     0,      0,      0]]

end


