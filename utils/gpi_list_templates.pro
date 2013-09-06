;+
; NAME: gpi_list_templates
;
;	Return a structure list giving information on all available
;	reduction recipe templates. 
;
; INPUTS:
; KEYWORDS:
; 	/verbose	print more stuff while working
; 	configParser	a pipeline configuration parser object, if already
; 					available. Saves having to reinstantiate it every time
; OUTPUTS:
;
; HISTORY:
; 	Began 2012-08-09 23:20:44 by Marshall Perrin, based on code in drfgui__define
;-

function gpi_list_templates, verbose=verbose, configParser=configParser

	templatedir = gpi_get_directory('GPI_DRP_TEMPLATES_DIR')

    message,/info, "Scanning for templates in "+templatedir
    template_file_list = file_search(templatedir + path_sep() + "*.xml")

	if n_elements(template_file_list) eq 0 then begin
		message,/info, "ERROR: There are no templates at all in the template directory!"
		message,/info, '  Check paths and config. Looking for templates in '+templatedir
		return, -1
	endif

	dd = obj_new('drf', template_file_list[0],/quick,/silent)
	summary = dd->get_summary()
	obj_destroy, dd
	summaries = replicate(summary, n_elements(template_file_list))

	for i=1L,n_elements(template_file_list)-1 do begin
		dd = obj_new('drf', template_file_list[i],/quick,/silent)
		summaries[i] = dd->get_summary()
		obj_destroy, dd
	endfor 

	return, summaries




end
