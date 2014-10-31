function calc_satloc,x0,y0,PSFcenter,lambda0,lambda_out
;+
;NAME: calc_satloc
;
;calculate
;
;INPUTS:
;	x0,y0: initial location of the spot at lambda0
;	PSFcenter: 2-elements vector of the location of the PSF  center
;	lambda_out: wavelength for which output locations are calculated 
;
;OUTPUT: 
;	locations of spot at wavelength lambda_out
;
;HISTORY: begin 2010-02-09 JM
;-

polcoord=cv_coord(from_rect=[x0-PSFcenter[0],y0-PSFcenter[1]],/TO_POLAR)
cartcoord=cv_coord(from_polar=[polcoord[0],(double(lambda_out)/double(lambda0))*polcoord[1]],/TO_RECT)
cartcoord[0]+=PSFcenter[0]
cartcoord[1]+=PSFcenter[1]
return, cartcoord
end
