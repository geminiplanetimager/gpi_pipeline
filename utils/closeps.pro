pro closeps
;+
; NAME:
;      closeps
; PURPOSE:
;      use it to end the postscript writing
;
; EXPLANATION:
;       
;
; Calling SEQUENCE:
;      
;
; INPUT/OUTPUT:
;

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

device,/close
;set_plot,'x'
!p.thick=1 & !p.charthick=1 & !p.font=-1 & !x.thick=1 & !y.thick=1

end
