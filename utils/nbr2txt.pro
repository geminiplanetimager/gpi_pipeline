function nbr2txt,n,ndigit
;+
; NAME:
;      nbr2txt
; PURPOSE:
;      return a number in string format completed with zeros on left side where number of zeros depends on the asked number of character 
;retourne un nombre en format string complete par la gauche
;avec des 0 a un nombre de caracteres donne
;
; EXPLANATION:
;       
;
; Calling SEQUENCE:
;      
;
; INPUT/OUTPUT:
;
; n= number to return
;n=nombre a retourner
;ndigit=number of character of the string
;ndigit=nombre de caratere du string
; OPTIONAL OUTPUT:
;       
;
; EXAMPLE:
;
;
; DEPENDENCIES:
;
;
; NOTES: 
;      
;             
; REVISION HISTORY
;       Written  before 2008, Mathilde beaulieu/Jean-Francois Lavigne/David Lafreniere/Jerome Maire. 
;-

;


nn=n_elements(n)

textnumber=strmid('0000000000000',0,ndigit)
if nn gt 1 then textnumber=replicate(textnumber,nn)

for i=0,nn-1 do begin
    tmp=textnumber[i]
    strput,tmp,strtrim(n[i],2),ndigit-1-fix(alog10(n[i]))
    textnumber[i]=tmp
endfor

return,textnumber
end
