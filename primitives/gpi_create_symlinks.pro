;+
; NAME: gpi_create_symlinks.pro
; PIPELINE PRIMITIVE DESCRIPTION: Create Symbolic Links
;
;     This primitive creates symbolic links for files either input to or output
;     from the pipeline.
;
; INPUTS: Some datacube
;
; OUTPUTS: That datacube multiplied by a constant.
;
; PIPELINE COMMENT: Create symbolic links on the file system for files either input to or output from the data pipeline.
; PIPELINE ARGUMENT: Name="filetolink" Type="string" Default="INPUT_FILE" Desc="File to create a link for. Either 'INPUT_FILE', 'LAST_OUTPUT_FILE', or the specific filename of some existing disk file"
; PIPELINE ARGUMENT: Name="createlinkdir" Type="string" Default="${GPI_REDUCED_DATA_DIR}" Desc="Directory to create a link in. Must be a directory, not any other filename."
; PIPELINE ARGUMENT: Name="appenddatedir" Type="int" Range="[0,1]" Default="1" Desc="Append the YYMMDD date string to createlinkdir"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; 
; PIPELINE ORDER: 5.0
;
; PIPELINE NEWTYPE: Testing
;
; HISTORY:
;    2013-10-07 MP: Started based on template
;-  

function gpi_create_symlinks, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id$' ; get version from subversion to store in header history


@__start_primitive


	if !version.os_family ne 'unix' then return, error('Symbolic link creation only available on Unix platforms')


 	if tag_exist( Modules[thisModuleIndex], "filetolink") then filetolink=str(Modules[thisModuleIndex].filetolink) else filetolink='INPUT_FILE'
 	if tag_exist( Modules[thisModuleIndex], "createlinkdir") then createlinkdir=str(Modules[thisModuleIndex].createlinkdir) else createlinkdir='${GPI_REDUCED_DATA_DIR}'
 	if tag_exist( Modules[thisModuleIndex], "appenddatedir") then appenddatedir=float(Modules[thisModuleIndex].appenddatedir) else appenddatedir=1

	
	;--- What are we linking TO?
	if strupcase(filetolink) eq 'INPUT_FILE' then begin
		file_to_link = dataset.inputdir + path_sep() + dataset.filenames[indexframe]
		stop	

	endif else if strupcase(filetolink) eq 'LAST_OUTPUT_FILE' then begin
		file_to_link = backbone->get_last_saved_file()
	endif else begin
		if not file_test(filetolink) then return, error("File requested for symlink does not exist: "+filetolink)
		file_to_link = filetolink
	endelse
	backbone->Log, "Creating symlink to: "+file_to_link



	;--- Where are we linking FROM?
	link_destination = gpi_expand_path(createlinkdir)

	if keyword_set(appenddatedir) then begin
		head = headfits(filetolink)
		dateobs = sxpar(head,'DATE-OBS', count=ct)
		if ct eq 0 then return, error("File is missing DATE-OBS keyword, cannot create a symbolic link with an appended date.")
		dateparts = strsplit(dateobs,'-',/extract)
		datestr = strmid(dateparts[0],2,2)+dateparts[1]+dateparts[2]
		
		link_destination = link_destination+path_sep()+datestr

	endif
	backbone->Log, "Creating symlink in: "+link_destination

	backbone->set_keyword,'HISTORY',functionname+ " Added symlink to: "+file_to_link
	backbone->set_keyword,'HISTORY',functionname+ " Added symlink in: "+link_destination


    dir_ok = gpi_check_dir_exists(link_destination)
    if dir_ok = NOT_OK then return, NOT_OK


	file_link,  file_to_link, link_destination

@__end_primitive

end
