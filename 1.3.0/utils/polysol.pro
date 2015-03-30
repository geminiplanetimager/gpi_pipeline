; for distortion correction;
; made by Quinn - 2013-04 -JM
FUNCTION POLYSOL, x, y, p

n = p[0] + p[1]*x + p[2]*y + p[3]*x^2. + p[4]*x*y + p[5]*y^2. + $
     p[6]*x^3. + p[7]*x^2*y + p[8]*x*y^2 + p[9]*y^3 + $
     p[10]*x^4. + p[11]*x^3.*y + p[12]*x^2.*y^2. + p[13]*x*y^3. + p[14]*y^4. + $
     p[15]*x^5 + p[16]*x^4*y + p[17]*x^3*y^2 + p[18]*x^2*y^3 + p[19]*x*y^4 + p[20]*y^5

RETURN,n

END