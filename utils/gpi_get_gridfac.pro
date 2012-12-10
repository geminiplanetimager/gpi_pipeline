function gpi_get_gridfac,apodizer
;+
; NAME:
;       gpi_get_gridfac
; PURPOSE:
;       Return apodizer scaling value from lookup table
;
; CALLING SEQUENCE:
;       res = gpi_get_gridfac(apodizer)
;
; INPUT/OUTPUT:
;       apodizer - Name of apodizer (typically from image header)
;       res - gridfac value (or NaN if lookup table couldn't be
;             found, or apodizer couldn't be matched, or
;             apodizer has no grid).
;
; OPTIONAL OUTPUT:
;       None.
;
; EXAMPLE:
;     
; DEPENDENCIES:
;	None.
;
; NOTES: 
;       Lookup table located by default in
;       pipeline/config/apodizer_spec.txt.  Can be ovewritten with
;       'apodizer_spec' gpi setting.
;             
; REVISION HISTORY
;       Written 12/10/2012. ds
;-

fname = gpi_get_setting('apodizer_spec',default=gpi_get_directory('GPI_DRP_CONFIG_DIR')+'apodizer_spec.txt',/silent)
if ~file_test(fname) then begin
   message,'Could not find apodizer spec file.',/continue
   return,!values.f_nan
endif

readcol, fname, format='A,F', comment='#', names, values, count=count, /silent

res = where(strmatch(names,'*'+apodizer+'*',/fold_case),cc)
if cc ne 1 then begin
   message,'Could not match apodizer name.',/continue
   return,!values.f_nan
endif

return,values[res]

end
