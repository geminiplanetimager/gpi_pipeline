;+
; FUNCTION: mueller_retarder_rot
; 	Returns the 4x4 Mueller matrix for a plate with retardance d
;
; INPUTS:
; 	retardance	retardance in WAVES
; 	angle		rotation from the x (Stokes Q) axis, 
;				in radians by default unless /degrees is set
; KEYWORDS:
;   /degrees	specifies that the angle is given in degrees
;   /half		shorthand for retardance=0.50 waves
;   /quarter	shorthand for retardance=0.25 waves
;
; OUTPUTS:
;
; HISTORY:
;   2004-ish by Marshall
;   2014-02 MP: updated for GPI DRP
;
;-

FUNCTION mueller_retarder_rot, retardance, angle, half=half, quarter=quarter

	if n_elements(angle) eq 0 then angle=0.0
	if keyword_set(degrees) then angle = angle*!dtor ; convert to radians


	if keyword_set(half) then retardance=0.5
	if keyword_set(quarter) then retardance=0.25
	if (keyword_set(half) and keyword_set(quarter)) then $
		message,"Keywords HALF and QUARTER should not both be set."
	
	d = retardance*2*!pi  ; convert to radians

	S2 = sin(2*angle)
	C2 = cos(2*angle)
	
	return,[ [1, 0, 				0, 					0			],$
			 [0, C2^2+S2^2*cos(d),	S2*C2*(1-cos(d)), 	-S2*sin(d)	],$
			 [0, S2*C2*(1-cos(d)), 	S2^2+C2^2*cos(d),	C2*sin(d)	],$
			 [0, S2*sin(d), 		-C2*sin(d), 		cos(d)		]]

end
