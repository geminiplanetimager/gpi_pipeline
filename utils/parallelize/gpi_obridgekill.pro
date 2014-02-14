;+
; NAME: gpi_obridgekill.pro
; 
; Kill bridges
;
; INPUTS: Array of bridges
; 	
; KEYWORDS: none
; 	
; OUTPUTS: none
; 	
;	
; HISTORY:
;    Began 2014-01-13 by Christian Marois
;-  

pro obridgekill,oBridge

sproc=size(oBridge)
nbproc=sproc[1]

for i=0,nbproc-1 do begin
 obj_destroy,oBridge[i]
endfor

end
