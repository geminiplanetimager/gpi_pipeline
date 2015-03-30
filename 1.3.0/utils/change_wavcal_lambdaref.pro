;+
; NAME: change_wavcal_lambdaref
; DESCRIPTION: for a wavecal datacube, change the reference wavelength.
;
;	I.e. if you have an H band wavelength calibration but instead you want a K1
;	wavecal, you can use this to get the K1 spectral positions as predicted from
;	the H wavecal. 
;
;	CAUTION: This assumes a linear dispersion model which is not
;	quite correct
;
; INPUTS:
;	wavcal		A datacube containing a wavelength calibration, i.e. a data cube
;				with 5 slices containing y0, x0, lambda0, tilt, dispersion
;	lambdaout	New wavelength you desire as lambda0 in the output wavecal
; KEYWORDS:
; OUTPUTS:
;				A new datacube containing an adjusted wavelength calibration,
;				with lambda0 adjusted to the requested lambdaout, and x0 and y0
;				updated accordingly. 
;
;
; HISTORY:
;   created: Jerome Maire 2009-06
;   2010-07-16 JM: added quadratic case
;   2013-03-13 MP: Vectorized for efficiency. 
;   2013-08-29 MP: Updated documentation
;-

function change_wavcal_lambdaref, wavcal, lambdaout

szw=size(wavcal)
wavcalout=dblarr(szw[1],szw[2],szw[3])

	case szw[3] of
	5: begin  ; linear relation of dispersion
		; wavecal is: Y0, X0, lambda0, disp, tilt
		d2=(lambdaout-wavcal[*,*,2])/wavcal[*,*,3]  
		wavcalout[*,*,0]= -d2*cos(wavcal[*,*,4])+wavcal[*,*,0]
		wavcalout[*,*,1]=  d2*sin(wavcal[*,*,4])+wavcal[*,*,1]
	end
	7: begin ; quadratic relation of dispersion
		; wavecal is: Y0, X0, lambda0, C, B, A, tilt
		;  where the distance is A*lambda^2 + B*lambda *C
		d2=wavcal[*,*,3]+wavcal[*,*,4]*(lambdaout) + wavcal[*,*,5]*((lambdaout)^2.) 
		wavcalout[*,*,0]= -d2*cos(wavcal[*,*,6])+wavcal[*,*,0]
		wavcalout[*,*,1]=  d2*sin(wavcal[*,*,6])+wavcal[*,*,1] 
	end
	endcase
        
	wavcalout[*,*,2]=lambdaout
	wavcalout[*,*,3]=wavcal[*,*,3]
	wavcalout[*,*,4]=wavcal[*,*,4]
	if szw[3] eq 7 then  begin
		wavcalout[*,*,5]=wavcal[*,*,5]
		wavcalout[*,*,6]=wavcal[*,*,6]
	endif

	return, wavcalout 
end
