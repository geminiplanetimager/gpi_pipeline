;+
; NAME:  like Python's indices
;
; INPUTS:
; KEYWORDS:
; 	center= optional coords of center
; OUTPUTS:
; 	x,y,z	indices
; 	r=		optional radial coord
;
;
; HISTORY:
; 	Began 2008-06-12 20:04:55 by Marshall Perrin 
;-


PRO indices, im, x, y, z, center=center, r=r, theta=theta, pixelscale=pixelscale

	sz = size(im)
	case sz[0] of
	1: begin
	x = findgen(sz[1])
	end
	2: begin
	x = findgen(sz[1],sz[2]) mod sz[1]
	y = (findgen(sz[1],sz[2]) - x) / sz[1]
	end
	3: begin
	x = findgen(sz[1],sz[2],sz[3]) mod sz[1]
	message, '3d not implemented yet'

	end
	endcase

	if keyword_set(center) then begin
		; could use some error checking
		if keyword_set(x) then x -= center[0]
		if keyword_set(y) then y -= center[1]
		if keyword_set(z) then z -= center[2]
	endif
	if arg_present(r) then begin
		case sz[0] of
		1: begin
			r=abs(x)
		end
		2: begin
			r = sqrt(x^2+y^2)
		end
		3: begin
			r = sqrt(x^2+y^2+z^2)
		end
		endcase

		
	endif

	if arg_present(theta) then begin
		theta = atan(y,x)*!radeg
		wneg = where(theta lt 0, negct)
		if negct gt 0 then theta[wneg]+=360
	endif

	if keyword_set(pixelscale) then begin
		if keyword_set(x) then  x*= pixelscale
		if keyword_set(y) then  y*= pixelscale
		if keyword_set(z) then  z*= pixelscale
		if keyword_set(r) then  r*= pixelscale
	endif

end
