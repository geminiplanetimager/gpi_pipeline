;+
; NAME: gpi_lookup_template_filename 
;
; INPUTS:
;		requestedname		Descriptive string name for template
;			
; KEYWORDS:
;		/scanonly			Just scan list of templates into common block then
;							return without doing anything else
;		parent_window=		widget ID of parent window, if in a GUI program.
;							Only used for modal dialog box parent if there is an
;							error.  
; OUTPUTS:
;	returns filename on disk. 
;
; HISTORY:
;	Began 2014-10-31 by Marshall Perrin, refactoring code from parsergui
;	 into a standalone routine.
;-


pro gpi_lookup_template_filename_scan_templates, verbose=verbose

    compile_opt DEFINT32, STRICTARR
	common GPI_TEMPLATES, templates, template_types


	templatedir = 	gpi_get_directory('GPI_DRP_TEMPLATES_DIR')

    if keyword_set(verbose) then message,/info, "Scanning for templates in "+ templatedir
    template_file_list = file_search(templatedir + path_sep() + "*.xml")


    first_drf = obj_new('drf', template_file_list[0],/quick,/silent)
    templates = replicate(first_drf->get_summary(), n_elements(template_file_list))

    for i=0,n_elements(template_file_list)-1 do begin
        if keyword_set(verbose) then message,/info, 'scanning '+template_file_list[i]
		template = obj_new('drf', template_file_list[i],/quick,/silent)
        templates[i] = template->get_summary()
    endfor

    types = uniqvals(templates.reductiontype)

    ; What order should the template types be listed in, in the GUI?
	type_order  = ['SpectralScience','PolarimetricScience','Calibration','Testing']
    
    ; FIXME check if there are any new types not specified in the above list but
    ; present in the templates?
    
    ; conveniently, these filenames will already be in alphabetical order from
    ; the above.
    if keyword_set(verbose) then print, "----- Templates located: ----- "
    for it=0, n_elements(type_order)-1 do begin
        if keyword_set(verbose) then print, " -- "+type_order[it]+" -- "
        wm = where(templates.reductiontype eq type_order[it], mct)
        for im=0,mct-1 do begin
            if keyword_set(verbose) then print, "    "+templates[wm[im]].name+"     "+ templates[wm[im]].filename
        endfor
    endfor

	template_types = type_order

end


;--------------------------------------------------------a
;
;
function gpi_lookup_template_filename, requestedname, scanonly=scanonly, parent_window=parent_window, verbose=verbose

    compile_opt DEFINT32, STRICTARR
	common GPI_TEMPLATES, templates, template_types

    if ~(keyword_set(templates)) then gpi_lookup_template_filename_scan_templates, verbose=verbose
	if keyword_set(scanonly) then return, ''



	wm = where(  strmatch( templates.name, requestedname,/fold_case), ct)
	if ct eq 0 then begin
        ret=dialog_message("ERROR: Could not find any matching template file for name='"+requestedname+"'. Cannot load template.",/error,/center,dialog_parent=parent_window)
		return, ""
	endif else if ct gt 1 then begin
        ret=dialog_message("WARNING: Found multiple matching template files for name='"+requestedname+"'. Going to load the first one, from file="+(templates[wm[0]]).filename,/information,/center,dialog_parent=parent_window)
	endif
	wm = wm[0]

	return, (templates[wm[0]]).filename




end
