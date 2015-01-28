;+
; NAME:  
;
; INPUTS:
; KEYWORDS:
;	recipedir	where the RECIPE should be written to
;	outputdir	where the FITS FILES should be written to when the recipe is
;				executed
; OUTPUTS:
;
; HISTORY:
;	Began 2014-10-31 by Marshall, refactoring code from parsergui to 
;		a standalone routine.
;
;-


function gpi_create_recipe_from_template, templateFilename, fitsfilenames, recipedir=recipedir, $
	outputdir=outputdir, filename_counter=filename_counter, $
	outputfilename=outputfilename

	; load the template, save with new filenames

	if ~(keyword_set(filename_counter)) then filename_counter=1

	if ~file_test(TemplateFilename, /read) then begin
        message, "Requested recipe file does not exist: "+TemplateFilename,/info
		return, -1
	endif

	catch, parse_error
	;parse_error=0
	if parse_error eq 0 then begin
		drf = obj_new('drf', TemplateFilename,/silent)
	endif else begin
        message, "Could not parse Recipe File: "+TemplateFilename,/info
        return, -1
	endelse
	catch,/cancel


	; set the data files in that recipe to the requested ones
	drf->set_datafiles, fitsfilenames 

	if keyword_set(outputdir) then drf->set_outputdir, outputdir

	; Generate output file name
	recipe=drf->get_summary() 

    first_file=strsplit(fitsfilenames[0],path_sep(),/extract) ; split filename apart from other parts of path 
    first_file=strsplit(first_file[size(first_file,/n_elements)-1],'S.',/extract) ; split on letter S or period

	last_file=strsplit(fitsfilenames[size(fitsfilenames,/n_elements)-1],path_sep(),/extract)
    last_file=strsplit(last_file[size(last_file,/n_elements)-1],'S.',/extract)


	if n_elements(first_file) gt 2 then begin
		; normal Gemini style filename
        outputfilename='S'+first_file[0]+'S'+first_file[1]+'-'+last_file[1]+'_'+recipe.shortname+'_drf.waiting.xml'
	endif else begin
		; something else? e.g. temporary workaround for engineering or other
		; data with nonstandard filenames
        outputfilename=file_basename(first_file[0])+'-'+file_basename(last_file[0])+'_'+recipe.shortname+'_recipe.waiting.xml'
	endelse

	if keyword_set(filename_counter) then begin
		prefixname=string(filename_counter, format="(I03)")
		outputfilename = prefixname+"_"+outputfilename
	endif


	if keyword_set(recipedir) then drfsavepath = recipedir else cd, curr=drfsavepath
	outputfilename = drfsavepath + path_sep() + outputfilename
	message,/info, 'Writing recipe file to :' + outputfilename

	drf->save, outputfilename, comment=" Created by gpi_create_recipe_from_template based on "+file_basename(templateFilename)

	return, drf

end


