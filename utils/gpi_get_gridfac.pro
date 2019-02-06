function gpi_get_gridfac,apodizer,spot_order
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

compile_opt defint32, strictarr, logical_predicate

;; if spot_order is invalid, set it to 1
if spot_order gt 2 then spot_order = 1

fname = gpi_expand_path(gpi_get_setting('apodizer_spec',default=gpi_get_directory('GPI_DRP_CONFIG_DIR')+'/apodizer_spec.txt',/silent))
if ~file_test(fname) then begin
   message,'Could not find apodizer spec file.',/continue
   return,!values.f_nan
endif

readcol, fname, format='A,F,I', comment='#', names, values, order, count=count, /silent

res = where(strmatch(names,'*'+apodizer+'*',/fold_case) and (order eq spot_order),cc)
if cc ne 1 then begin
   message,'Could not match apodizer name.',/continue
   return,!values.f_nan
endif

;;expecting a scalar back
return,(values[res])[0]

end
