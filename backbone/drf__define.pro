;+
; NAME:  DRF
;
;	An object-oriented interface to GPI data reduction files / "Recipes".
;
;	No GUI here, this is just an access wrapper. 
;
;	Much of this code was originally in ParserGUI or DRFGUI, but I 
;	ripped it out for more flexibility.
;
;	This is now the preferred implementation for manipulating recipe files.
;
; RELATIVE AND ABSOLUTE PATHS:
;
;		For historical reasons, some recipes use a non-null inputdir and then
;		provide just filenames. Others can provide absolute filenames for each
;		FITS file, in which case inputdir should be a null string. 
;
;		In either case it should be permissible to use defined environment
;		variables in path names. 
;
;		The internal variable self.datafilenames should essentially always be an
;		array of absolute pathnames. 
;
; INTERNAL VARIABLES:
;	.datafilenames			list of data filenames present   
;	.name				Descriptive Name  
;	.shortname			Short name for use in filenames
;	.reductiontype		Descriptive Type of reduction
;	.inputdir			Input directory
;
;
; MANIPULATING DATA FILENAMES: 
;
;    use add_datafiles, set_datafiles, clear_datafiles, get_datafiles
; 
;
; MANIPULATING PRIMITIVES:
;  
;	
;    use list_primitives, add_primitive, remove_primitive, reorder_primitives
;    also use get_primitive_args, set_primitive_args
; 
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2012-02-06 21:09:02 by Marshall Perrin 
;-
;--------------------------------------------------------------------------------


pro drf::log, messagestr
	; print a log message, optionally to some parent object
	if obj_valid(self.where_to_log) then self.where_to_log->Log, messagestr $
	else print, messagestr
end

;--------------------------------------------------------------------------------
pro drf::set_datafiles, filenames, validate=validate, status=status
	; Given a list of filenames, set the recipe's data filenames to that list
	;
	; KEYWORDS:
	;	/validate		Check that all files exist
	;
	;	status			Return 0 if add is OK, -1 if not OK

	self.modified = 1
	ptr_free, self.datafilenames

	newfilenames = strarr(n_elements(filenames))
	for i=0,n_elements(filenames)-1 do newfilenames[i] = gpi_expand_path(filenames[i])

	self.datafilenames = ptr_new(newfilenames)

	status=0 ; OK
	if keyword_set(validate) then status=self->validate_contents()

end
;-------------
pro drf::add_datafiles, filenames_to_add, validate=validate, status=status
	; Add one or more files to a recipe
	;
	; KEYWORDS:
	;	/validate		Check that all files exist
	;
	;	status			Return 0 if add is OK, -1 if not OK
	;
	self.modified = 1
	

	if ~ptr_valid(self.datafilenames) then begin
		; if we don't already have some files then we can just set the filenames
		; equal to the new ones
		self->set_datafiles, uniqvals(filenames_to_add), validate=validate, status=status
	endif else begin
		newfilenames = strarr(n_elements(filenames_to_add))
		for i=0,n_elements(filenames_to_add)-1 do newfilenames[i] = gpi_expand_path(filenames_to_add[i])

		*self.datafilenames = uniqvals([*self.datafilenames, newfilenames])

	endelse

	status=0 ; OK
	if keyword_set(validate) then status=self->validate_contents()

end

;-------------
FUNCTION drf::get_datafiles, absolute=absolute, status=status
	; obtain the list of files in a recipe
	;
	; KEYWORDS:
	;   /absolute		return absolute paths. Default is to use GPI env vars
	
	if ptr_valid(self.datafilenames) then begin
		tmpfiles= *self.datafilenames 

		; enforce absolute paths if requested
		if keyword_set(absolute) then for i=0,n_elements(tmpfiles)-1 do tmpfiles[i] = gpi_expand_path(tmpfiles[i]) $
			else for i=0,n_elements(tmpfiles)-1 do tmpfiles[i] = gpi_shorten_path(tmpfiles[i]) 

		status=0 ; OK
	endif else begin
		tmpfiles = ['']
		status=-1 ; NOT_OK
	endelse

		
	return, tmpfiles


end


;-------------
PRO drf::remove_datafile, filename, status=status
	; remove one datafile from the current list of filenames
	
	absfilename = gpi_expand_path(filename)

	if ~ptr_valid(self.datafilenames) then begin
		self->Log, "WARNING: There are NO filenames present in this recipe; cannot remove "+filename+"."
		status=-1
		return
	endif

	wmatch = where(*self.datafilenames eq absfilename, ct, complement=wcomplement, ncomplement=ncomplement)

	if ct eq 0 then begin
		self->Log, "WARNING: There is no filename named "+filename+" present in this recipe to remove."
		status=-1
	endif else begin
		self->Log, "Removed from recipe: "+filename
 		if ncomplement gt 0 then *self.datafilenames = (*self.datafilenames)[wcomplement] else ptr_free, self.datafilenames
		self.modified = 1
		status=0
	endelse

end

;-------------
PRO drf::clear_datafiles
	; Remove all data files from this recipe
	self.modified = 1
	ptr_free, self.datafilenames
	
end

;--------------------------------------------------------------------------------

function drf::get_datestr
	; return the datedir formatted string corresponding to the
	; first data file in this DRF
	;
	; This is used for the DRF output path if organize by dates is set
	if ptr_valid(self.datafilenames) && file_test((*self.datafilenames)[0]) then begin
		; determine the output dir based on the date associated with the first
		; FITS header
		head = headfits((*self.datafilenames)[0])
		dateobs = sxpar(head,'DATE-OBS', count=count)
		timeobs= sxpar(head,'UTSTART', count=count2)
		if count gt 0 then begin
			parts = strsplit(dateobs,'-',/extract)

			if count2 gt 0 then begin
				utctimeparts = strsplit(timeobs,':',/extract)
			endif else utctimeparts = [0,6,0]  ; will give wrong values but at least won't crash the code. 

			; Rules for selecting current date and time at the observatory are
			; such that it won't increment in the middle of the night. 
			;
			; the date string YYMMDD increments at 1400 local Chilean time, regardless of 
			; whether it's standard or daylight time
			;
			; However, annoyingly, we don't keep Chilean local time in the 
			; FITS header. We can use as a proxy the 3 hour times from UTC
			; that is appropriate for Chilean summer time, under the assumption
			; that most GPI data will be taken in the summer and a 1 hour
			; offset in the winter on the date rollover is not that big a deal. 
			; FIXME: do this more carefully eventually.
			; Or just grab the datestr from the original filename or some
			; related string in the header?
			chile_time_hours = utctimeparts[1]-3
			if chile_time_hours lt 0 then chile_time_hours += 24
			if chile_time_hours gt 14d0 then parts[2] += 1d0 ; increment to next day preemptively after 2 pm Chilean

			datestr = string(parts[0] mod 100,parts[1],parts[2],format='(i2.2,i2.2,i2.2)')



		endif else begin
			self->Log, 'ERROR: output data should be organized by date, but no DATE-OBS keyword present.'
			self->Log, "Assuming today's date just as a guess...."
			datestr = gpi_datestr()
		endelse
	endif else begin
		self->Log, 'ERROR: output data should be organized by date, but no data present to *have* a date'
		self->Log, "Assuming today's date just as a guess...."
		datestr = gpi_datestr()
	endelse 
	return,datestr

end

;--------------------------------------------------------------------------------

pro drf::set_outputdir, dir, verbose=verbose ;, autodir=autodir
	if self.outputdir eq dir then return  ; no change, so just return
	if n_elements(dir) eq 0 then begin
		self->Log, "ERROR: missing argument to set_outputdir. Therefore no change."
		return
	endif

	self.modified = 1

;	if keyword_set(autodir) or (strupcase(dir) eq 'AUTOMATIC') then begin
;		; figure out the output directory?
;		if gpi_get_setting('organize_reduced_data_by_dates',/bool,default=1) then begin
;			outputdir = gpi_get_directory('GPI_REDUCED_DATA_DIR')+path_sep()+self->get_datestr()
;		endif else begin
;			outputdir = gpi_get_directory('GPI_REDUCED_DATA_DIR')
;		endelse
;	endif else begin
;		outputdir = dir
;	endelse

	self.outputdir = dir
	if keyword_set(verbose) then self->Log, "Output dir set to "+self.outputdir
end
;-------------
FUNCTION drf::get_automatic_default_outputdir
	; Return a plausible output directory based on the pipeline configurations
	if gpi_get_setting('organize_reduced_data_by_dates',/bool,default=1) then begin
		outputdir = gpi_get_directory('GPI_REDUCED_DATA_DIR')+path_sep()+self->get_datestr()
	endif else begin
		outputdir = gpi_get_directory('GPI_REDUCED_DATA_DIR')
	endelse
	return, outputdir
end


;-------------
FUNCTION drf::get_outputdir
	; return output directory. If the actual value in the
	; XML file is the string 'AUTOMATIC' then return instead
	; the default output directory (which may or may not have a date in it)
	

	if (strupcase(self.outputdir) eq 'AUTOMATIC') then begin
		return, self->get_automatic_default_outputdir()
	endif else begin
		return, self.outputdir
	endelse

end


;----------------

;--------------------------------------------------------------------------------
pro drf::reorder_primitives, new_order,  verbose=verbose, _extra=arginfo
	; Change order of primitives. 
	; argument new_order must be some permutation of the integers 0 to N-1 where
	; N is the total number of primitives present

	nprims = n_elements(*self.primitives)

	; sanity check!

	if n_elements(new_order) ne nprims then begin
		message, "Invalid primitive ordering: wrong number of elements in array",/info
        return
    end
	for i=0,nprims-1 do begin
		wm = where(new_order eq i, ct)
		if ct gt 1 then begin
			message,"Invalid primitive ordering: index "+strc(i)+" is present more than once.",/info
			return
		endif else if ct eq 0 then begin
			message,"Invalid primitive ordering: index "+strc(i)+" is not present.",/info
			return
		end
	endfor


	self->log, "Primitives reordered: "+aprint(new_order)

	self.modified = 1
	*self.primitives = (*self.primitives)[new_order]
	
end

;--------------------------------------------------------------------------------

pro drf::add_primitive, primitive_name, index=index, status=status
	;+
	; Add a primitive to this DRF
	;
	; Arguments: 
	;    primitive name:  Descriptive name of that primitive
	;    index:			  Where in the order to add that primitive.
	;					  Leave empty to use the default based on the defined
	;					  order values. 0-based like all IDL indices.
	;
	;-
	self.modified = 1
	


	self->load_configdrs
	module_number = where((*self.ConfigDRS).names eq primitive_name, count) ; index of the module *in the config file!*
	module_number = module_number[0] ; scalarize, since IDL will probably hand back a 1-element array here.
	if count ne 1 then begin
		message, /info, "ERROR: Cannot find that primitive in the config file: "+primitive_name+".  Cannot add primitive."
		status= -1 ; NOT_OK
		return
	endif




	;--- Create a structure describing that primitive and its arguments
	

	; look up the arguments of that new primitive
	module_argument_indices = where(   ((*self.ConfigDRS).argmodnum) eq module_number[0]+1, count)
	module_argument_names=((*self.ConfigDRS).argname)[module_argument_indices]
	module_argument_defaults=((*self.ConfigDRS).argdefault)[module_argument_indices]


	new_primitive_info = {structModule} 
	new_primitive_info.name = primitive_name

	for i=0, n_elements(module_argument_names)-1 do begin
		present_tags= tag_names(new_primitive_info)
		wm = where(present_tags eq strupcase(module_argument_names[i]), mct)
		if mct eq 0 then new_primitive_info = create_struct(new_primitive_info, module_argument_names[i], module_argument_defaults[i]) else new_primitive_info.(wm[0]) = module_argument_defaults[i]
	endfor


	;--- Now determine where we should add that in to the existing structure array
	if n_elements(index) gt 0 then begin
		; sanity check
		index = fix(index)
		if index lt 0 then index = 0
		if index gt n_elements(*self.primitives) then index=n_elements(*self.primitives)
	endif else begin
		; determine default position
		; first look up the orders of all the primitives already present in this
		; recipe

		names = (*self.primitives).name
		orders = fltarr( n_elements(names))
		for i=0,n_elements(names)-1 do begin
			wm = where( (*self.ConfigDRS).names eq names[i], count)
			if count gt 0 then orders[i] = ((*self.ConfigDRS).order)[wm[0]]
		endfor
		; now find the first primitive which has an order greater than that of
		; the newly added primitive
		new_prim_order = ((*self.ConfigDRS).order)[module_number]
		wmin = where( orders gt new_prim_order, count)
		; if they're all lower then add at the end
		if count eq 0 then index = n_elements(*self.primitives) else index=wmin[0]
	endelse

	;--- Now merge the new structure into the primitives array, and order it appropriately

	; add an entry to the primitives array 
	if ~ ptr_valid(self.primitives) then begin
		; (including the case where that array might be null?)
		self.primitives=ptr_new(new_primitive_info) 
	endif else begin

		*self.primitives = struct_merge( *self.primitives, new_primitive_info) ; this will append the new primitive onto the end, as well as merging the fields

		; if we want it somewhere other than at the end, move it there
		nlast =  n_elements(*self.primitives)-1
		if index eq 0 then begin
			if nlast gt 1 then newindices = [ nlast, indgen( nlast-1)] else newindices = [ nlast, 0] 
			*self.primitives = (*self.primitives)[newindices]
		endif else if index ne nlast then begin 
			newindices = [ indgen(index), nlast, indgen( nlast-index)+index ]
			*self.primitives = (*self.primitives)[newindices]
		endif 
	endelse


	status= 0 ; OK

end

;--------------------------------------------------------------------------------

pro drf::remove_primitive, index_to_remove
	;+
	; Add a primitive to this DRF
	;
	; Arguments: 
	;    primitive_index:  Integer index of the primitive to remove
	;
	;-
	self.modified = 1
	
	if index_to_remove lt 0 then return ; invalid index

	indices = indgen(n_elements(*self.primitives))

	new_indices = indices[where(indices ne index_to_remove)]

	self->Log, "Removing primitive: "+ ((*self.primitives)[index_to_remove]).name
	*self.primitives = (*self.primitives)[new_indices]


end


;--------------------------------------------------------------------------------
pro drf::set_primitive_args, modnum, verbose=verbose, status=status, _extra=arginfo
	; this code is convoluted for various historical reasons. 
	;
	; Set the arguments for a given primitive. Must call for one primitive at a time.
	;
	; uses the _extra syntax so you can just do e.g.
	;    drf->set_primitive_args, 3, calibrationfile='something.fits', my_parameter=5.2

	OK = 0
	NOT_OK = -1


	if n_elements(modnum) eq 0 then begin
		message,/info, 'You must provide a primitive index when calling set_primitive_args'
		status=NOT_OK
		return
	endif
 

	self.modified = 1
	;drf_contents = self->get_contents()

	; look up from the DRS config file what the allowed arguments of this module
	; are
	self->load_configdrs
	module_number = where((*self.ConfigDRS).names eq ((*self.primitives)[modnum]).name, count) ; index of the module *in the config file!*
	if count ne 1 then begin
		message, /info, "ERROR: Can't lookup requested module from the primitives config file. Can't set arguments."
		status=NOT_OK
		;return
	endif

	module_argument_indices = where(   ((*self.ConfigDRS).argmodnum) eq module_number[0]+1, count)

	module_argument_names=((*self.ConfigDRS).argname)[module_argument_indices]
	if keyword_set(verbose) then print,  "ARGS: ", module_argument_names

	newargnames = tag_names(arginfo)
	for i=0,n_elements(newargnames)-1 do begin
		if keyword_set(verbose) then print, newargnames[i], arginfo.(i)

		wm = where(strupcase(module_argument_names) eq newargnames[i], mct)
		if mct eq 0 then begin
			message,/info, "Not a valid argument for that primitive: "+newargnames[i]
			status=NOT_OK
			return
			;stop
		endif else begin
			if keyword_set(verbose) then message,/info, "Setting argument "+strc(wm)+" to value = "+strc(arginfo.(i))
			; FIXME
			;self.parsed_drf->set_module_argument, modnum, newargnames[i],  arginfo.(i)

			all_arg_names = tag_names( (*self.primitives)[modnum])

			warg = where(strupcase(newargnames[i]) eq all_arg_names, mct)
			if mct eq 1 then begin
				(*self.primitives)[modnum].(warg[0]) = string(arginfo.(i))
			endif else begin
				message, 'Could not find argument '+strupcase(newargnames[i])+" for primitive number "+string(modnum),/info
				message, 'Appending new field to the primitive arguments struct array',/info

				; we have to jump through some hoops here to append an
				; additional field into the array of primitive info structures.
				; First, update the info for just this one primitive
				combined_primitive_info =create_struct((*self.primitives)[modnum], newargnames[i], string(arginfo.(i)))
				; then merge that into the overall structure (which will update
				; fields for all of them, but appends an extra redundant
				; primitive info record at the end)
				*self.primitives = struct_merge( *self.primitives, combined_primitive_info) ; this will append the new primitive onto the end, as well as merging the fields
				; then put it back in the right order and delete the redundant
				; record
				(*self.primitives)[modnum] = (*self.primitives)[n_elements(*self.primitives)-1]
				*self.primitives = (*self.primitives)[0:n_elements(*self.primitives)-2]
			endelse



		endelse

	endfor
	status=OK

end
;-------------
FUNCTION drf::list_primitives, count=count
	; Return the string names of the primitives in this recipe, in order
	
	if arg_present(count) then count = total((*self.primitives).name ne '')
	
	return, (*self.primitives).name

end

;-------------
FUNCTION drf::get_primitive_args, modnum, count=count,verbose=verbose, status=status
	; Return the primitive arguments for a given primitive
	;
	; PARAMETERS:
	; 	modnum	int
	; 		The index of the desired module in the current DRF
	;
	; RETURNS
	; 	module argument info, as a structure
	;
	OK = 0
	NOT_OK = -1

	if n_elements(modnum) eq 0 then begin
		message,/info, 'You must provide a primitive index when calling get_primitive_args'
		status=NOT_OK
		return, {names: '', values:'', defaults:'', ranges: '', descriptions: '', types:''}
	endif

	nprims = n_elements(*self.primitives)
	if (modnum lt 0) or (modnum gt nprims-1) then begin
		message, /info, 'Invalid primitive index outside of 0 to '+strc(nprims-1)
		status=NOT_OK
		return, {names: '', values:'', defaults:'', ranges: '', descriptions: '', types:''}
	endif

    
	; look up from the DRS config file what the allowed arguments of this module are
	self->load_configdrs
	module_number = where((*self.ConfigDRS).names eq ((*self.primitives).name)[modnum], mct) ; index of the module *in the config file!*

	if mct eq 0 then begin
		message,/info, 'Unknown primitive: '+((*self.primitives).name)[modnum] +" is not in the primitives config file."
		count=-1
		status=NOT_OK
		return, {names: '', values:'', defaults:'', ranges: '', descriptions: '', types:''}
	endif
	module_argument_indices = where(   ((*self.ConfigDRS).argmodnum) eq module_number[0]+1, count)

	if keyword_set(verbose) then print,  ((*self.primitives).name)[modnum]

	status=OK
	if count eq 0 then return, ''
	
	module_argument_names=((*self.ConfigDRS).argname)[module_argument_indices]
	module_argument_defaults=((*self.ConfigDRS).argdefault)[module_argument_indices]
	module_argument_ranges=((*self.ConfigDRS).argrange)[module_argument_indices]
	module_argument_descs=((*self.ConfigDRS).argdesc)[module_argument_indices]
	module_argument_types=((*self.ConfigDRS).argtype)[module_argument_indices]

		if keyword_set(verbose) then print,  "ARGS: ", module_argument_names
		if keyword_set(verbose) then print,  "DEFS: ", module_argument_defaults
		if keyword_set(verbose) then print,  "RANGE:", module_argument_ranges
		if keyword_set(verbose) then print,  "DESCR:", module_argument_descs
		if keyword_set(verbose) then print,  "TYPES:", module_argument_types


	; look in the contents of the DRF for what they are
	module_argument_values= strarr(n_elements(module_argument_names))

	for i=0,count-1 do begin

		exists = tag_exist( (*self.primitives)[modnum], module_argument_names[i], index=j)
		if exists eq 1 then module_argument_values[i] = (*self.primitives)[modnum].(j)
		if module_argument_values[i] eq '' then module_argument_values[i] = module_argument_defaults[i]
	endfor

	return, {names: module_argument_names, values:module_argument_values, defaults:module_argument_defaults, ranges: module_argument_ranges, descriptions: module_argument_descs, types:module_argument_types}
end

;
;--------------------------------------
function drf::check_output_path_exists, path
	if strc(path) eq "" then return, 0 ; blank paths are invalid
	return, gpi_check_dir_exists(path)

;	if file_test(path,/dir,/write) then begin
;		return, 1 
;	endif else  begin
;		if gpi_get_setting('prompt_user_for_outputdir_creation',/bool, default=0) then res =  dialog_message('The requested output directory '+path+' does not exist. Should it be created now?', title="Nonexistent Output Directory", /question) else res='Yes'
;		if res eq 'Yes' then begin
;			file_mkdir, path
;			return, 1
;		endif else return, 0
;
;	endelse
;	return, 0

end



;--------------------------------------
function drf::validate_contents
	OK = 0
	NOT_OK = -1


	valid = OK ; assume valid unless we find a problem? 

	if ~ptr_valid(self.datafilenames) then return, NOT_OK
	if ~ptr_valid(self.primitives) then return, NOT_OK

	nfiles = n_elements(*self.datafilenames)

	for i=0L, nfiles - 1 do begin
		full_input_filename = gpi_expand_path( (*Self.DataFilenames)[i])
		if ~ file_test(full_input_filename,/read) then begin
			self->Log, 'ERROR: The file "'+ full_input_filename+'" does not exist on disk or is unreadable.  Cannot load requested data.'
			valid = NOT_OK
		endif 
	endfor 

	if valid eq OK then begin
		self->Log, "Validation OK: all input files in that recipe exist."
	endif else begin
		self->Log, "ERROR: Validation FAILED!  One or more input files in that recipe are unreadable."
	endelse

	return, valid


end


;--------------------------------------------------------------------------------

pro drf::save, outputfile0, absolutepaths=absolutepaths,autodir=autodir,silent=silent, status=status, outputfilename=outputfile
	; write out to disk!
	;
	; KEYWORDS:
	; 	/absolutepaths		write DRFs using absolute paths in their text, not
	; 						environment variables for relative paths
	; 	/autodir			Automatically decide the best output directory to
	; 						save **this recipe file** to. This is distinct from
	;						the "automatic" option for the recipe file's actual
	;						internal output directory, which sets the output
	;						directory for pipeline processed FITS files. 
	OK = 0
	NOT_OK = -1

	outputfile=outputfile0 ; don't modify input outputfile variable.

	if keyword_set(autodir) then begin 
		recipe_outputdir = gpi_get_directory('GPI_RECIPE_OUTPUT_DIR')
		if gpi_get_setting('organize_recipes_by_dates',/bool) then  begin
			recipe_outputdir += path_sep()+self->get_datestr()
		endif 
		if  self->check_output_path_exists(recipe_outputdir) eq NOT_OK then begin
			self->Log, "Could not write to nonexistent directory: "+file_dirname(outputfile)
			status=NOT_OK
			return
		endif

		outputfile=recipe_outputdir +path_sep()+file_basename(outputfile)

	end

	recipe_outputdir = file_dirname(outputfile)
	dir_ok = gpi_check_dir_exists(recipe_outputdir)
	if dir_ok ne OK then begin
		self->Log, "Invalid output directory: " +recipe_outputdir
		status=NOT_OK
		return
	endif



	if ~(keyword_set(silent)) then self->log,'Writing recipe to '+gpi_shorten_path(outputfile)

	OpenW, lun, outputfile, /Get_Lun
	PrintF, lun, self->tostring(absolutepaths=absolutepaths)
	Free_Lun, lun

	self.last_saved_filename=outputfile
	self.modified= 0 ; we're now synced with the disk version of this file.
	status=OK

end

;-------------
PRO drf::queue, filename=filename, queued_filename=queued_filename, status=status
	; save a DRF into the queue

	OK = 0
	NOT_OK = -1

	if ~(keyword_set(filename)) then filename=self.last_saved_filename

	if ~(keyword_set(filename)) then message,"Need to specify a filename to queue it!"

	outname = file_basename(filename)
	outname = strepex(outname,"([^\.]+)\..+$", "&0.waiting.xml") ; replace file extension to .waiting.xml
	queued_filename = gpi_get_directory("GPI_DRP_QUEUE_DIR")+path_sep()+outname


	prev_outputfile = self.last_saved_filename ; save value before this gets overwritten in save

	self->save, queued_filename,/silent

	self.last_saved_filename= prev_outputfile ; restore previous value

	self->Log, "    Queued "+queued_filename

end

;-------------

function drf::tostring, absolutepaths=absolutepaths
	; Return a DRF formatted as an XML string


	if ~(keyword_set(absolutepaths ))then begin
		;relative pathes with environment variables        
	  	;inputdir=gpi_shorten_path(self.inputdir) 
	  	outputdir=gpi_shorten_path(self.outputdir) 
	endif else begin
	  	;inputdir=gpi_expand_path(self.inputdir)
	  	outputdir=gpi_expand_path(self.outputdir)
	endelse  
        
	; Are all the input files in the same directory?
	filenames = self->get_datafiles()
	dirnames = strarr(n_elements(filenames))
	for i=0,n_elements(filenames)-1 do dirnames[i] = file_dirname(filenames[i])
	uniqdirs = uniqvals(dirnames)

	if n_elements(uniqdirs) eq 1 then begin
		; all files are from a common input directory! So pull that out to the
		; inputdir parameter
		inputdir = uniqdirs[0]
		for i=0,n_elements(filenames)-1 do filenames[i] = file_basename(filenames[i])

		if keyword_set(absolutepaths) then inputdir=gpi_expand_path(inputdir) else inputdir=gpi_shorten_path(inputdir)
	endif else begin
		; filenames are in multiple directories
		; So leave the paths on the individual filenames.
		inputdir = ''

		for i=0,n_elements(filenames)-1 do $
			if keyword_set(absolutepaths) then filenames[i]=gpi_expand_path(filenames[i]) else filenames[i]=gpi_shorten_path(filenames[i])

	endelse


 
	if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)

	outputstring = ''
        
	outputstring +='<?xml version="1.0" encoding="UTF-8"?>'+newline 
    
	outputstring +='<recipe Name="'+self.name+'" ReductionType="'+self.reductiontype+'" ShortName="'+self.ShortName+'">'+newline

	outputstring +='<dataset '
	if inputdir ne '' then outputstring+= 'InputDir="'+inputdir+'" ' ; only write an inputdir parameter if it's non-null!
	outputstring +='OutputDir="'+outputdir+'">'+newline 
 
	if ptr_valid(self.datafilenames) then $
	FOR j=0,N_Elements(*self.datafilenames)-1 DO BEGIN
		outputstring +='   <fits FileName="' + filenames[j] + '" />'+newline
	ENDFOR
	outputstring +='</dataset>'+newline

    drf_primitive_names = (*self.primitives).name 

	FOR j=0,n_elements(drf_primitive_names)-1 DO BEGIN

		primitive_args = self->get_primitive_args(j, count=count)
		strarg='' ; no arguments yet

		if count gt 0 then begin
			  for i=0,n_elements(primitive_args.names)-1 do begin
				  strarg+=primitive_args.names[i]+'="'+primitive_args.values[i]+'" '
			  endfor
		endif
		  
	
		outputstring +='<primitive name="' + drf_primitive_names[j] + '" '+ strarg +'/>'+newline
	ENDFOR
	outputstring +='</recipe>'+newline
	
	return, outputstring

end

;--------------------------------------------------------------------------------
function drf::get_configParser
	; Parse the Primitive Config XML file 
	; and update my knowledge of available modules
	;
	; This function returns an object reference; be sure to destroy it when you're
	; done

	config_file = gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+"gpi_pipeline_primitives.xml"

    if ~file_test(config_file) then message, 'ERROR: Cannot find DRS Config File! It ought to be at '+config_file+" but is not."

    ConfigParser = OBJ_NEW('gpiDRSConfigParser')
    ConfigParser -> ParseFile, config_file 

    if ~ptr_valid(self.ConfigDRS) then self.ConfigDRS = ptr_new(ConfigParser->getidlfunc())

    return, ConfigParser

end
;--------------------------------------------------------------------------------
pro drf::load_configdrs
    if ~ptr_valid(self.ConfigDRS) then begin
		configparser = self->get_configparser()
		self.ConfigDRS = ptr_new(ConfigParser->getidlfunc())
		obj_destroy, configparser
	endif

end


;--------------------------------------------------------------------------------
function drf::init, filename, parent_object=parent_object,silent=silent,quick=quick, $
	as_template=as_template
	;
	; INPUTS:
	; 	filename	name of DRF XML file to read in and create an object from.
	;
	; KEYWORDS:
	; 	parent_object=	object handle to some parent, used for logging if
	; 					provided. Optional.
	; 	/silent			don't print text to screen while working.
	;
	; 	/quick			By default, when you parse a DRF it also parses the
	; 					pipeline primitives config XML file, so it can convert
	; 					descriptive string routine names into IDL function names. 
	; 					If you're not actually the pipeline, you probably don't
	; 					care about this, and it's faster to not do the
	; 					conversion.
	; 	/as_template	We're opening this file as a template, so don't load any
	;					FITS files that might be present
	;
	; 					FIXME: this could almost certainly be programmed more
	; 					elegantly; This is already a workaround for legacy
	; 					OSIRIS code that is clunkier than I would like. 
	;
	; 					Unless you are the GPI pipeline itself, you can
	; 					probably get away with using /quick. Maybe it should be
	; 					the default?   -MP 2012-08-09

	if obj_valid(parent_object) then self.where_to_log = parent_object

	if ~(keyword_set(filename)) then invalid=1
	if ~file_test(filename) then invalid=1
	
	if keyword_set(invalid) then begin
		self->Log,'You tried to create a DRF object with a file path pointing to an invalid/nonexistent file on disk.'
	
		self->Log,'  requested filename was: '+filename
		return, 0
	endif

	self.loaded_filename=filename
	self.last_saved_filename=''
	self.modified=0

    ; now parse the requested DRF.
	if ~(keyword_set(quick)) then begin
		; First re-parse the config file (so we know about all the available modules
		; and their arguments)
		ConfigParser = self->get_configParser()
	endif 

    ; then parse the DRF and get its contents
    self.parsed_drf= OBJ_NEW('gpiDRFParser')
    self.parsed_drf->ParseFile, self.loaded_filename,  ConfigParser, gui=self, silent=silent
    drf_summary = self.parsed_drf->get_summary()
    drf_contents = self.parsed_drf->get_contents()

	; set this object's state accordingly
	self.reductiontype =	drf_summary.reductiontype
	self.name =				drf_summary.name
	self.shortname =		drf_summary.shortname
	if self.shortname eq '' then self.shortname = strcompress(self.name,/remove_all) ; handle old recipes lacking a shortname

	self.outputdir =		drf_contents.outputdir
	self.primitives =		ptr_new(drf_contents.modules)

	if ~ keyword_set(as_template) then begin
		self.datafilenames =	ptr_new(drf_contents.fitsfilenames)
		if strc(drf_contents.inputdir) ne '' then begin ; convert to absolute pathnames.
			*self.datafilenames = drf_contents.inputdir + path_sep() + *self.datafilenames
		endif

		; and convert to absolute pathnames
		for i=0,n_elements(*self.datafilenames)-1 do (*self.datafilenames)[i] = gpi_expand_path(  (*self.datafilenames)[i] )

	endif else begin
		; ignore any specified input dir if we're opening as a template.
	endelse

	return, 1
end

;--------------------------------------------------------------------------------

function drf::find_module_by_name, modulename, count
	; Given a primitive name, return the corresponding index

	;modules = (self->get_contents()).modules
	wm = where( (*self.primitives).name eq modulename, count)
	return, wm

end
;--------------------------------------------------------------------------------
function drf::is_modified ; has the currently loaded DRF been modified since it was loaded?
	return, self.modified
end

;--------------------------------------------------------------------------------
function drf::get_summary
	; Like the get_summary of gpidrfparser
	if ptr_valid(self.datafilenames) then nfiles = n_elements(*self.datafilenames) else nfiles=0
	if ptr_valid(self.primitives) then nsteps = n_elements(*self.primitives) else nsteps=0


	if self.last_saved_filename eq '' then myfilename = self.loaded_filename else myfilename=self.last_saved_filename
	return, {filename: myfilename,  $
			 reductiontype: self.ReductionType, $
			 name: self.name, $
			 ShortName: self.ShortName, $
			 nsteps: nsteps , $
			 nfiles: nfiles }

end
;--------------------------------------------------------------------------------

function drf::get_contents
	; Like the get_contents of gpidrfparser, except without inputdir
	;   (since part of the point of this object is to hide the inputdir 
	;   manipulations from the calling program and just always provide
	;   absolute pathnames!)

	if ptr_valid(self.datafilenames) then begin
		fitsfilenames = *self.datafilenames 
	endif else begin
		fitsfilenames = ''
	endelse

	return, {fitsfilenames: fitsfilenames,  $
			 ;inputdir: self.inputdir, $
			 outputdir: self.outputdir, $
			 modules: *self.primitives, $  ; return using both 'modules' and 'primitives' label for back compatibility
			 primitives: *self.primitives  }
end


;--------------------------------------------------------------------------------
pro drf::cleanup

	obj_destroy, self.parsed_drf
	ptr_free, self.datafilenames
	ptr_free, self.primitives
	ptr_free, self.configDRS

end

;--------------------------------------------------------------------------------
; back compatibility hooks for old method names: 
pro drf::savedrf, outputfile0, absolutepaths=absolutepaths,autodir=autodir,silent=silent
	self->save, outputfile0, absolutepaths=absolutepaths,autodir=autodir,silent=silent
end

pro drf::set_module_args, modnum, verbose=verbose, _extra=arginfo
	self->set_primitive_args, modnum, verbose=verbose, _extra=arginfo

end

FUNCTION drf::get_module_args, modnum, count=count,verbose=verbose
	return, self->get_primitive_args( modnum, count=count,verbose=verbose)
end



;--------------------------------------------------------------------------------

PRO drf__define

	state = {drf, $
        loaded_filename: '',$       ; name of input file loaded from disk
        last_saved_filename: '', $  ; last saved filename
        modified: 0, $              ; has this DRF been modified relative to the disk file?
        name: '', $                 ; descriptive string name
        reductiontype: '',$         ; what type of reduction?
        ShortName: '', $            ; short name to be used in naming of recipes
        parsed_drf: obj_new(), $    ;gpiDRFParser object for the XML file itself
        where_to_log: obj_new(),$   ; optional target object for log messages
        ;inputdir: '', $            ; Deprecated, may still be present in XML but 
                                    ; automatically gets folded in to datafilenames
        outputdir: '', $			; Output directory for the contents of this recipe
        datafilenames: ptr_new(), $
        primitives: ptr_new(), $
        configDRS: ptr_new() $  ; DRS modules configuration info
        }

end
