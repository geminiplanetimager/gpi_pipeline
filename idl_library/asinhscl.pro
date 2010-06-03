;+
; NAME:
;       ASINHSCL
;
; PURPOSE:
;
;       This is a utility routine to perform an inverse hyperbolic sine
;       function intensity transformation on an image. I think of this
;       as a sort of "tuned" gamma or power-law function. The algorithm,
;       and notion of "asinh magnitudes", comes from a paper by Lupton,
;       et. al, in The Astronomical Journal, 118:1406-1410, 1999 September.
;       I've relied on the implementation of Erin Sheldon, found here:
;
;           http://cheops1.uchicago.edu/idlhelp/sdssidl/plotting/tvasinh.html
;
;       I'm also grateful of discussions with Marshall Perrin on the IDL
;       newsgroup with respect to the meaning of the "softening parameter", beta,
;       and for finding (and fixing!) small problems with the code.
;
;       Essentially this transformation allow linear scaling of noise values,
;       and logarithmic scaling of signal values, since there is a small
;       linear portion of the curve and a much large logarithmic portion of
;       the curve. (See the EXAMPLE section for some tips on how to view this
;       transformation curve.)
;
; AUTHOR:
;
;       FANNING SOFTWARE CONSULTING
;       David Fanning, Ph.D.
;       1645 Sheely Drive
;       Fort Collins, CO 80526 USA
;       Phone: 970-221-0438
;       E-mail: davidf@dfanning.com
;       Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; CATEGORY:
;
;       Utilities
;
; CALLING SEQUENCE:
;
;       outputImage = ASINHSCL(image)
;
; ARGUMENTS:
;
;       image:         The image or signal to be scaled. Written for 2D images, but arrays
;                      of any size are treated alike.
;
; KEYWORDS:
;
;       BETA:          This keyword corresponds to the "softening parameter" in the Lupon et. al paper.
;                      This factor determines the input level at which linear behavior sets in. Beta
;                      should be set approximately equal to the amount of "noise" in the input signal.
;                      IF BETA=0 there is a very small linear portion of the curve; if BETA=200 the
;                      curve is essentially all linear. The default value of BETA is set to 3, which
;                      is appropriate for a small amount of noise in your signal. The value is always
;                      positive.
;
;		(This keyword is redundant with BETA, above, but personally I prefer it,
;		since it lets you specify the curve shape independent of the range of
;		input data, which BETA does not. Hence I'm keeping it in my copy of this
;		routine, even though David Fanning dropped it from his copy. - Marshall)
;       NONLINEARITY:  A positive value from 0 to infinity that affects the non-linearity
;                      of the hyperbolic sine curve. A value of 0 results in a linear stretch.
;                      The default value is 100. In general, this value should change logarithmically
;                      for best results. Larger values result in shorter (and steeper) linear sections of the
;                      curve and longer (and flatter) logarithmic sections.
;                      Note that NONLIN=50 does a pretty good job of matching
;                      regular log scaling.
;
;       NEGATIVE:      If set, the "negative" of the result is returned.
;
;       MAX:           Any value in the input image greater than this value is
;                      set to this value before scaling.
;
;       MIN:           Any value in the input image less than this value is
;                      set to this value before scaling.
;
;       OMAX:          The output image is scaled between OMIN and OMAX. The
;                      default value is 255.
;
;       OMIN:          The output image is scaled between OMIN and OMAX. The
;                      default value is 0.
; RETURN VALUE:
;
;       outputImage:   The output, scaled into the range OMIN to OMAX. A byte array.
;
; COMMON BLOCKS:
;       None.
;
; EXAMPLES:
;
;       Plot,  ASinhScl(Indgen(256), NonLinearity=0), LineStyle=0
;       OPlot, ASinhScl(Indgen(256), NonLinearity=10), LineStyle=1
;       OPlot, ASinhScl(Indgen(256), NonLinearity=100), LineStyle=2
;       OPlot, ASinhScl(Indgen(256), NonLinearity=1000), LineStyle=3
;
; RESTRICTIONS:
;
;     Requires SCALE_VECTOR from the Coyote Library:
;
;        http://www.dfanning.com/programs/scale_vector.pro
;
;     Incorporates ASINH from the NASA Astronomy Library and renamed ASINHSCL_ASINH.
;
;       http://idlastro.gsfc.nasa.gov/homepage.html
;
;     The 'auto' option requires MMM from the NASA Astronomy Library.
;
; MODIFICATION HISTORY:
;
;       Written by:  David W. Fanning, 24 February 2006.
;       Made the ALPHA and BETA keywords obsolete. Replaced with NONLINEARITY keyword,
;         following suggestions of Marshall Perrin on IDL newsgroup. 24 April 2006. DWF.
;       /auto option added. Marshall Perrin, 24 April 2006
;       Changed /auto to use sky instead of mmm.  Marshall Perrin 05 May 2008
;-
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright © 2006 Fanning Software Consulting
;
; This software is provided "as-is", without any express or
; implied warranty. In no event will the authors be held liable
; for any damages arising from the use of this software.
;
; Permission is granted to anyone to use this software for any
; purpose, including commercial applications, and to alter it and
; redistribute it freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must
;    not claim you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation
;    would be appreciated, but is not required.
;
; 2. Altered source versions must be plainly marked as such, and must
;    not be misrepresented as being the original software.
;
; 3. This notice may not be removed or altered from any source distribution.
;
; For more information on Open Source Software, visit the Open Source
; web site: http://www.opensource.org.
;
;###########################################################################
FUNCTION ASinhScl_ASinh, x
;
; NAME:
;     ASINH
; PURPOSE:
;     Return the inverse hyperbolic sine of the argument
; EXPLANATION:
;     The inverse hyperbolic sine is used for the calculation of asinh
;     magnitudes, see Lupton et al. (1999, AJ, 118, 1406)
;
; CALLING SEQUENCE
;     result = asinh( x)
; INPUTS:
;     X - hyperbolic sine, numeric scalar or vector or multidimensional array
;        (not complex)
;
; OUTPUT:
;     result - inverse hyperbolic sine, same number of elements as X
;              double precision if X is double, otherwise floating pt.
;
; METHOD:
;     Expression given in  Numerical Recipes, Press et al. (1992), eq. 5.6.7
;     Note that asinh(-x) = -asinh(x) and that asinh(0) = 0. and that
;     if y = asinh(x) then x = sinh(y).
;
; REVISION HISTORY:
;     Written W. Landsman                 February, 2001
;     Work for multi-dimensional arrays  W. Landsman    August 2002
;     Simplify coding, and work for scalars again  W. Landsman October 2003
;
   On_Error, 2

    y = ALog( Abs(x) + SQRT( x^2 + 1.0) )

    index = Where(x LT 0 ,count)
    IF count GT 0 THEN y[index] = -y[index]

    RETURN, y

 END ;-------------------------------------------------------------------------------



 FUNCTION ASinhScl, image, $
   BETA=beta, $   ; Obsolete
   NEGATIVE=negative, $
   NONLINEARITY=nonlinearity, $
   MAX=maxValue, $
   MIN=minValue, $
   OMAX=maxOut, $
   OMIN=minOut, $
   auto=auto

   ; Return to caller on error.
   On_Error, 2

   ; Check arguments.
   IF N_Elements(image) EQ 0 THEN Message, 'Must pass IMAGE argument.'

   ; Check for underflow of values near 0. Yuck!
   curExcept = !Except
   !Except = 0
   i = Where(image GT -1e-35 AND image LT 1e-35, count)
   IF count GT 0 THEN image[i] = 0.0
   void = Check_Math()
   !Except = curExcept

   ; Work in double precision.
   output = Double(image)

   ; Check keywords.
   IF N_Elements(nonlinearity) EQ 0 THEN nonlinearity = 100.0D
   nonlinearity = nonlinearity > 1e-12 ; Always greater than 0.
   IF N_Elements(maxOut) EQ 0 THEN maxOut = 255B ELSE maxout = 0 > Byte(maxOut) < 255
   IF N_Elements(minOut) EQ 0 THEN minOut = 0B ELSE minOut = 0 > Byte(minOut) < 255
   IF minOut GE maxout THEN Message, 'OMIN must be less than OMAX.'

   ; Too damn many floating underflow warnings, no matter WHAT I do! :-(
   thisExcept = !Except
   !Except = 0

   ; Perform initial scaling of the image into 0 to 1.0.
   output = Scale_Vector(Temporary(output), 0.0, 1.0, MaxValue=maxValue, $
      MinValue=minValue, /NAN, Double=1)
   
   ; Obsolete keywords.
   IF N_Elements(beta) NE 0 THEN BEGIN
	   ; Create a non-linear factor from the BETA value.
 	  scaled_beta = ((beta > 0) - minValue)/(maxValue - minValue)
 	  nonlinearity = 1.0D/(scaled_beta > 1e-12)
   ENDIF

    if keyword_set(auto) then begin
		sky,image,skymean,skysig,/silent ; was mmm but this didn't always work?
		; If sky fails to converge, it returns exactly -1.0. Then fallback to
		; other algorith for sky?
		if skysig eq -1.0 then sky,image,skymean,skysig,/meanback ; was mmm but this didn't always work?
		if skysig ne 0 then beta = skysig*auto
	    scaled_beta = beta / (MaxValue-MinValue)
 	  	nonlinearity = 1.0D/(scaled_beta > 1e-12)
   endif


  ; Find out where 0 and 1 map in ASINH, then set these as MINVALUE and MAXVALUE
   ; in next SCALE_VECTOR call. This is necessary to preserve proper scaling.
   extrema = ASinhScl_ASinh([0, 1.0D] * nonlinearity)

   ; Inverse hyperbolic sine scaling.
   output = Scale_Vector(ASinhScl_ASinh(Temporary(output)*nonlinearity), $
      minOut, maxOut, /NAN, Double=1, MinValue=extrema[0], MaxValue=extrema[1])

   ; Clear math errors.
   void = Check_Math()
   !Except = thisExcept

   ; Does the user want the negative result?
   IF Keyword_Set(negative) THEN RETURN, BYTE(maxout - Round(output) + minOut) $
      ELSE RETURN, BYTE(Round(output))

 END ;-------------------------------------------------------------------------------

