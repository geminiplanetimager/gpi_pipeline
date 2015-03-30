;+
; NAME: angarr
; 		return an array where each element has the value
;		of its angle defined by the endpoint which is the center of the image,
;		the X-axis, (from -pi to pi with respect to the right X-axis)
;
;
; INPUTS: desired dimension of the array
; common needed:
;
; KEYWORDS:
; OUTPUTS: array with corresponding angles
;
; HISTORY:
; 	Originally by Jerome Maire 2008-07
;

function angarr,dim1,dim2

;retourne un array dont chaque element a la valeur de
;son angle par rapport au centre de l'image
;de -pi a pi par rapport a l'axe des x positifs

if (n_params() eq 1) then dim2=dim1

x=findgen(dim1)#replicate(1.,dim2)-dim1/2
y=replicate(1.,dim1)#findgen(dim2)-dim2/2
ang=atan(y,x)
i=where((x eq 0.) and (y eq 0.))
if (i[0] ne -1) then ang[i]=0.

return,ang
end
