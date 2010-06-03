function orbit,jd,a,e,i,w1,w2,t0,p,sep=sep,pa=pa

; Given a set of orbital elements, compute the 
; position on a given JD. Return the separation 
; (in RA and DEC, measured in arcsec)
; and optionally the separation radius and PA
; can be returned in keywords
;
; ARGUMENTS:
;	jd: Julian Day of desired coordinates
;	a: semi-major axis (arcsec)
;	e: eccentricity
;	i: inclination of orbit (degrees)
;	w1: argument of periastron  (degrees)
;	w2: position angle of ascending node (degrees)
;	t0: time of periastron (JD)
;	p: period (days)
;
; HISTORY:
;   2010-01-19: Documentation updated. MDP

npt=n_elements(jd)

;mean anomaly
twopi=6.283185307179586232d0
m=twopi*(jd-t0)/p
m=((m mod twopi)+twopi) mod twopi

;solve for eccentric anomaly
ea=eanomaly(m,e)

;convert all angles to radians
w1r=w1*!dtor
w2r=w2*!dtor
ir=i*!dtor

;compute Thiele-Innes constants
cw1=cos(w1r) & cw2=cos(w2r)
sw1=sin(w1r) & sw2=sin(w2r)
ci=cos(i*!dtor)
x1=a*(cw1*sw2+sw1*cw2*ci)
y1=a*(cw1*cw2-sw1*sw2*ci)
x2=a*(-sw1*sw2+cw1*cw2*ci)
y2=a*(-sw1*cw2-cw1*sw2*ci)

;compute projected (sky) coordinates of planets
cea=cos(ea)
sea=sin(ea)
x=x1*(cea-e)+x2*sqrt(1.-e^2)*sea
y=y1*(cea-e)+y2*sqrt(1.-e^2)*sea

if arg_present(sep) then begin
    sep=sqrt(x^2+y^2)
    pa=(atan(x,y)*!radeg+360.) mod 360.
endif

return,[[x],[y]]

end
