;+
; NAME: gpi_obridgeabort.pro
; 
; Aborts parallel nodes 
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

pro gpi_obridgeabort,oBridge

sproc=size(oBridge)
nbproc=sproc[1]

for i=0,nbproc-1 do begin
	(*oBridge[i])->Execute, ".RESET_SESSION"
	(*oBridge[i])->abort
endfor


end
