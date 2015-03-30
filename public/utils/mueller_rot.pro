;+
; NAME: mueller_rot
;
;  The Mueller matrix for a rotation of angle theta
;
;   If this rotation matrix is called R, and some polarizing optic has Mueller
;   matrix M, then after a rotation of that component through an angle t, the
;   Muller matrix for the rotated compnent is:
;
;           M' = R(-t) M R(t)
;
;   Be careful about angle signs: a rotation of the reference frame by \theta
;   has the effect of rotating the angle of the Stokes vector by -\theta
;   relative to the new frame axes.
;
;   Note that transpose( R(a) ) = R(-a)
; 
;
;
; INPUTS:
;   theta - the angle of rotation for the matrix in radians
; OUTPUTS:
;   a 4 x 4 mueller matrix 
; HISTORY:
;   Began 2012 - MMB  
;   2014-02-28  Doc updated
;
;-
function mueller_rot, theta
theta=double(theta)

; warn if possibly called with degrees
if abs(theta) gt 2*!pi then begin
	message,/info, "WARNING: you've called muller_rot with an angle > 2pi radians - did you accidentally pass in a value in degrees?"
endif

M= [[1,0,0,0],$
	[ 0,  cos(2*theta), sin(2*theta),0], $
	[ 0, -sin(2*theta), cos(2*theta),0],$
	[ 0, 0, 0, 1]]

return, M
end


