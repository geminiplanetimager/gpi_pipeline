FUNCTION distarr, xsize, ysize, xcen, ycen, dxs, dys, mem=mem
;+
; NAME:
;	DISTARR
;
; PURPOSE:
;	This function generates an array whose elements are the Euclidean
;	distance from a given point.
;
; CATEGORY:
;	LASCO UTIL
;
; CALLING SEQUENCE:
;	Resut = DISTARR([xsize[,ysize[,xcen[,ycen[,dxs[,dys]]]]]])
;
; OPTIONAL INPUTS:
;	Xsize:	The size of the array along the abscissa.  Default is 1024
;	YSIZE:	The size of the array along the ordinate.  Default is equal to xsize
;	XCEN:	The position of the center.  Default is half of xsize
;	YCEN:	The position of the center.  Default is half of ysize
;
; KEYWORDS:
;	MEM:	Setting this keyword sacrifices some speed for lower memory consumption 
;	during routine.  Has no effect on output or side effects, nor does it have any effect if
;	either xcen or ycen are float or double.
;
; OUTPUTS:
;	Result:	The euclidean distance from (Xcen, Ycen)
;
;OPTIONAL OUTPUTS:
;	Dxs:	The distance from (Xcen,0)
;	Dys:	The distance from (0,Ycen)
;
; PROCEDURE:
;  Generates a 2D matrix whose elements are the RMS distance from sun center
;  in pixels.  Also returns two matrices whose elements are the signed
;  distances in either x or y from sun center
;
; EXAMPLE:
; To generate a 1024x1024 matrix whose values are the Euclidean distance from (512,512)
;	result = distarr()
;
; To generate a 1024-element by 512-element matrix whose values are the Euclidean
; distance from (X,Y)
;	result = distarr(512,1024,X,Y)
;
; MODIFICATION HISTORY:
; 	Written by:	Andrew Hayes, NRL Dec, 1998
;	Modified by:	Andrew Hayes, NRL Aug, 2000	Rewritten for greater speed if parameters
;		are integers, changed inputs to optional input parameters, now chooses calculation
;		method and output type intelligently depending on the type[s] of the input 
;		parameters instead of forcing double.
;
;
;	%W% %H% LASCO IDL LIBRARY
;-
	if n_params() lt 1 then xsize=1024	;set to defaults if some parameters missing
	if n_params() lt 2 then ysize=xsize
	if n_params() lt 3 then xcen=xsize/2
	if n_params() lt 4 then ycen=ysize/2

	sx=size(xcen)	;determine if we can use the all-integer shortcut or if we need double
	typex=sx[sx[0]+1]
	sy=size(ycen)
	typey=sy[sy[0]+1]
	typeflag=(typex eq 4)*4 > (typex eq 5)*5 > (typey eq 4)*4 > (typey eq 5)*5 > 2

	if n_params() ge 5 or typeflag gt 2 then $
		dxs=(indgen(xsize)-xcen)#replicate(1,1,ysize)	;will take on type of xcen

	if n_params() ge 6 or typeflag gt 2 then $
		dys=replicate(1,xsize)#transpose(indgen(ysize)-ycen) ;will take on type of ycen

	if keyword_set(mem) or typeflag gt 2 then RETURN, sqrt(dxs^2+dys^2)

	arr=shift(    dist(2* (xsize-xcen>xcen), 2* (ysize-ycen>ycen) ),    xcen,   ycen)
	RETURN, arr[0:xsize-1,0:ysize-1]
END
