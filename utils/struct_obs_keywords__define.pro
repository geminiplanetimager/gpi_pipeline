;+
; NAME:  struct_obs_keywords Definition
;
; 	No actual IDL code here, just a structure definition.
; 	Stored in its own file to be globally available. 
;
;-

pro struct_obs_keywords__define
	compile_opt defint32, strictarr, logical_predicate

 	obsstruct = {struct_obs_keywords, $
				FILENAME: '',$
				ASTROMTC: '', $
				OBSCLASS: '', $
				obstype:  '', $ ; strc(  gpi_get_keyword(head, ext_head,  'OBSTYPE',  count=ct2)), $
				obsmode:  '', $ ;strc(  gpi_get_keyword(head, ext_head,  'OBSMODE',  count=ctobsmode)), $
				OBSID:    '', $ ;strc(  gpi_get_keyword(head, ext_head,  'OBSID',    count=ct3)), $
				filter:   '', $ ;strc(gpi_simplify_keyword_value(strc(   gpi_get_keyword(head, ext_head,  'IFSFILT',   count=ct4)))), $
				dispersr: '', $ ;strc(gpi_simplify_keyword_value(gpi_get_keyword(head, ext_head,  'DISPERSR', count=ct5))), $
				OCCULTER: '', $ ;strc(gpi_simplify_keyword_value(gpi_get_keyword(head, ext_head,  'OCCULTER', count=ct6))), $
				LYOTMASK: '', $ ;strc(  gpi_get_keyword(head, ext_head,  'LYOTMASK',     count=ct7)), $
				APODIZER: '', $ ;strc(  gpi_get_keyword(head, ext_head,  'APODIZER',     count=ct8)), $
				DATALAB:  '', $ ;strc(  gpi_get_keyword(head, ext_head,  'DATALAB',     count=ct11)), $
				ITIME:    0.0,$ ;float( gpi_get_keyword(head, ext_head,  'ITIME',    count=ct9)), $
				COADDS:   0,  $ ; fix( gpi_get_keyword(head, ext_head,  'COADDS',    count=ctcoadd)), $
				OBJECT:   '', $ ;string(  gpi_get_keyword(head, ext_head,  'OBJECT',   count=ct10)), $
      			ELEVATIO: 0.0,$ ;float(  gpi_get_keyword(head, ext_head,  'ELEVATIO',   count=ct12)), $
				MJDOBS:   0.0,$ 
				summary: '',$
				valid: 0}

end
