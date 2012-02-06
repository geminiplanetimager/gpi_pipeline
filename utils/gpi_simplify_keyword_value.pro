;+
; NAME: gpi_simplify_keyword_value
;
;	Extract the middle substring of a keyword separated by underscores. 
;
;		some keywords have large string value, e.g. "IFSFILT_K2_G1215"
; this routine returns value between _*_ ,e.g. "K2" in the precedent example
; This routine does not modify the keyword value in the header
;
; important note: This doesn't actually implement any sort of translation table,
; it just grabs the middle substring between two _s. 
;
; INPUTS:
; 	keyword value
; KEYWORDS:
; OUTPUTS:
; 	string
;
; HISTORY:
; 	Began 2011-08-01 18:06:55 by JM 
;-


FUNCTION gpi_simplify_keyword_value, value

  newvaltab=strsplit(value,'_',/EXTRACT,count=cc)
  if cc gt 1 then value=newvaltab[1]

	return, value


end
