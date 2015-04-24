;+
; NAME: gpi_unixobridgekill.pro
; 
; Kill bridges in UNIX
;
; INPUTS: none
; 	
; KEYWORDS: none
; 	
; OUTPUTS: none
; 	
;	
; HISTORY:
;    Began 2015-02-12 by Christian Marois
;-  


pro gpi_unixobridgekill

spawn,'ps aux',a
s=size(a)
dim=s[1]
;stop
for i=0,dim-1 do begin
 b=strsplit(a[i],' ',/extract) 
 found=strcmp(strcompress(b[10],/remove_all),'idl_opserver')

 if found eq 1 then begin
  pid=b[1] 
  spawn,'kill -KILL '+pid
 endif
endfor

end
