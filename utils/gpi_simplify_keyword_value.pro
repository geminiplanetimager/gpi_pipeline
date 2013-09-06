;+
; NAME: gpi_simplify_keyword_value
;
;	Extract the middle substring of a keyword separated by underscores. 
;
;	Some keywords have large string value, e.g. "IFSFILT_K2_G1215"
; 	This routine returns the value between _*_ , for instance  "K2" in 
; 	the previous example. 
; 	This routine does not modify the keyword value in the header, it just
; 	cuts out a substring to return.
;
; 	Important note: This doesn't actually implement any sort of translation table,
; 	It just grabs the middle substring between two underscore characters. 
;
; INPUTS:
; 	keyword value
; KEYWORDS:
; 	None
; OUTPUTS:
; 	substring for the value
;
; HISTORY:
; 	Began 2011-08-01 18:06:55 by JM 
; 	2013-07-12 MP: Documentation
;-


FUNCTION gpi_simplify_keyword_value, value
  compile_opt defint32, strictarr, logical_predicate

  newvaltab=strsplit(value,'_',/EXTRACT,count=cc)
  if cc gt 1 then value=newvaltab[1]

	return, value


end
