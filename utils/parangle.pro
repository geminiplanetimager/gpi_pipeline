; this is a demo routine

;pro demo_parangle
;
;	common dst_input
;	lat = ten_string(OLa)
;
;	;ha = findgen(12)-6
;	ha = makearr(50, -6, 6)
;
;
;	plot, ha, parangle(ha, -18, lat), title = "Latitude = "+Ola, xtitle = "Hour angle", ytitle="Parallactic Angle", $
;		yr=[-180, 180]
;	oplot, ha, parangle(ha, -40, lat), /lines, color=fsc_color('red')
;	oplot, ha, parangle(ha, -18, lat), /lines, color=fsc_color('green')
;	oplot, ha, parangle(ha, -30, lat), lines=2
;	;oplot, ha, parangle(ha, 0, lat), lines=3
;
;	hrs = [-2, -1, 0.5, 1]
;	oplot, hrs, [-98, -94, 93.6, 94], psym=1 ; Gemini OT -30
;	oplot, hrs, [-120, -134, 152, 134], psym=1 , color=fsc_color('green'); Gemini OT -18
;	oplot, hrs, [-77, -56, 34.0, 56], psym=1 , color=fsc_color('red') ; gemin OT -40
;	
;
;	legend, [ '0', '-18','-30', '-40' ], lines=[2,3,0,1], psym=[-3, -3, -3,-3], /bot, /right
;
;
;end


; 2008-05-09
;   Replaced original function (which was buggy, and did not agree with the
;   Gemini OT's calculations for Cerro Pachon) with this version by Tim
;   Robishaw, which does agree perfectly with the OT according to the above
;   plot. 
;
;   Conveniently, they have the exact same arguments!


function parangle, ha, dec, latitude, DEGREE=degree
;+
; NAME:
;      PARANGLE
;
; PURPOSE:
;      Return the parallactic angle of a source in degrees.
;
; CALLING SEQUENCE:
;      Result = PARANGLE(HA, DEC, LATITUDE [,/DEGREE])
;
; INPUTS:
;      HA - the hour angle of the source in decimal hours, unless /DEGREE
;           keyword is set, in which case input is assumed to be in decimal
;           degrees; a scalar or vector.
;      DEC - the declination of the source in decimal degrees; a scalar or
;            vector.
;      LATITUDE - The latitude of the telescope; a scalar.
;
; KEYWORD PARAMETERS:
;      /DEGREE - If set, then the HA parameter has been input in degrees
;                rather than hours.
;
; OUTPUTS:
;      Function returns a double real scalar or vector.  The parallactic
;      angle is returned in the range [-180,180] degrees.  If either ha or
;      dec is input as a scalar and the other input as a vector, the result
;      will be returned as a vector.  If both are input as vectors, it is
;      expected that the vector have the same number of elements.  If the
;      vectors are not the same length, then excess elements of the longer
;      one will be ignored
;
; COMMON BLOCKS:
;      None.
;
; RESTRICTIONS:
;      For measurements made at the poles, it is imperative that the
;      parallactic angle be calculated from native geocentric apparent
;      coordinates (HA,dec); being a singularity in horizon coordinates
;      (alt,az), if you transform to (HA,dec) you lose all HA information
;      and the parallactic angle becomes singular.  At the NCP the PA is
;      (HA-180) and at the SCP it is equivalent to the HA.
;
; EXAMPLE:
;      The parallactic angle at the north celestial pole should be
;      equivalent to (HA-180)...
;      IDL> ha = dindgen(360*2)/2.-180d0
;      IDL> dec = dblarr(360*2)+90d0
;      IDL> plot, ha, parangle(ha,dec,latitude,/DEG), PS=3
;
;      If you have a set of sexigesimal (RA,dec) coordinates, you'll
;      need to first convert them to decimal and calculate the Hour
;      Angle (HA=LST-RA):
;      IDL> ra = [12,23,34.5] & dec = [-4,12,45.6] & lst = 14.34
;      IDL> pa = parangle(lst-ten(ra),ten(dec),latitude)
;
;      If you have a set of coordinates in horizon coordinates
;      (alt-az) and you'd like to use this routine, just convert to
;      geocentric apparent (HA-dec) using the Goddard routine ALTAZ2HADEC:
;      IDL> altaz2hadec, el, az, latitude, ha, dec
;      IDL> pa = parangle(ha,dec,latitude)
;
; NOTES:
;      The parallactic angle at a point in the sky is the position angle of
;      the vertical, i.e., the angle between the direction to the North
;      Celestial Pole and to the zenith. In precise applications care must
;      be taken only to use geocentric apparent coordinates (HA,DEC). It is
;      measured from North through East and is always negative when the
;      source is in the East and positive when in the West.
;
;      The following references are very informative:
;      van der Kamp, 1967, "Principles of Astrometry" p. 22
;      Green, 1985, "Spherical Astronomy" p. 12
;      Thompson, Moran, Swenson, 2001, "Interferometry and Synthesis
;      in Radio Astronomy" p. 97
;
;      It should be noted that the Goddard IDL Astronomy library has a
;      procedure named POSANG that is capable of calculating the
;      parallactic angle and it even uses the same four-parts formula.  The
;      parallactic angle would be calculated by finding the angle between
;      the source position (ha,dec) and the pole position (0,latitude).
;      POSANG makes its calculations in equatorial coordinates so we need
;      to pass in -ha:
;      IDL> posang, 1, -ha, dec, 0d0, latitude, pa
;      Also, POSANG takes the difference between the two positions
;      introducing a tiny roundoff error into the calculation.
;
; MODIFICATION HISTORY:
;	Written by Tim Robishaw, Berkeley  08 May 2006
;-

if (N_params() lt 3) then begin
   message,'Syntax - Result = parangle(ha, dec, latitude [, /DEGREE])',/INFO
   return, 0
endif

r2d = 180d0/!dpi
d2r = !dpi/180d0

; MAKE SURE THE INPUT HOUR ANGLE IS IN DEGREES...
had = keyword_set(DEGREE) ? ha : 15d0*ha

; USE THE FOUR-PARTS FORMULA FROM SPHERICAL TRIGONOMETRY
; TO DETERMINE THE PARALLACTIC ANGLE...
return, -r2d*atan(-sin(d2r*had),$
                  cos(d2r*dec)*tan(d2r*latitude)-$
                  sin(d2r*dec)*cos(d2r*had))

end; parangle
