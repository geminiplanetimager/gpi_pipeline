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

pro drf::set_datafiles, filenames
	; TODO validate existence of files?
	ptr_free, self.filenames
	self.filenames = ptr_new(filenames)


	self.inputdir = file_dirname(filenames[0])

end
;-------------

FUNCTION drf::get_datafiles
	if ptr_valid(self.filenames) then return, *self.filenames else return, ''

end

;--------------------------------------------------------------------------------

function drf::get_datestr
	; return the datedir formatted string corresponding to the
	; first data file in this DRF
	; This is used for the DRF output path if organize by dates is set
	if ptr_valid(self.filenames) and file_test(*self.filenames[0]) then begin
		; determine the output dir based on the date associated with the first
		; FITS header
		head = headfits(*self.filenames[0])
		dateobs = sxpar(head,'DATE-OBS', count=count)
		if count gt 0 then begin
			parts = strsplit(dateobs,'-',/extract)
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

pro drf::set_outputdir, dir=dir, autodir=autodir

	if keyword_set(autodir) then begin
		; figure out the output directory?
		if gpi_get_setting('organize_reduced_data_by_dates',/bool) then begin
			outputdir = gpi_get_directory('GPI_REDUCED_DATA_DIR')+path_sep()+self->get_datestr()
		endif else begin
			outputdir = gpi_get_directory('GPI_REDUCED_DATA_DIR')
		endelse
	endif

	self.outputdir = outputdir
end
;-------------

FUNCTION drf::get_outputdir
	return, self.outputdir
end

FUNCTION drf::get_inputdir
	return, self.inputdir
end



;--------------------------------------------------------------------------------
;pro drf::set_logdir
;	self.logdir = dir
;end
;;-------------
;
;FUNCTION drf::get_logdir
;	return, self.logdir
;end
;
;--------------------------------------------------------------------------------
pro drf::set_module_args, modnum, arginfo
	stop
end
;-------------

FUNCTION drf::get_module_args, modnum, count=count
	; Return the module arguments for a given module
	;
	; PARAMETERS:
	; 	modnum	int
	; 		The index of the desired module in the current DRF
	;
	; RETURNS
	; 	module argument info, as a structure
	;
    drf_contents = self->get_contents()

	; look up from the DRS config file what the allowed arguments of this module
	; are
	module_number = where((*self.ConfigDRS).names eq (drf_contents.modules.name)[modnum]) ; index of the module *in the config file!*
	module_argument_indices = where(   ((*self.ConfigDRS).argmodnum) eq module_number[0]+1, count)

	if count eq 0 then return, ''
	
	module_argument_names=((*self.ConfigDRS).argname)[module_argument_indices]
	module_argument_defaults=((*self.ConfigDRS).argdefault)[module_argument_indices]

	
	; look in the contents of the DRF for what they are
	module_argument_values= strarr(n_elements(module_argument_names))

	for i=0,count-1 do begin

		tmp = tag_exist(drf_contents.modules[modnum], module_argument_names[i], index=j)
		if j gt 0 then module_argument_values[i] = drf_contents.modules[modnum].(j)
		if module_argument_values[i] eq '' then module_argument_values[i] = module_argument_defaults[i]
	endfor

	return, {names: module_argument_names, values:module_argument_values, defaults:module_argument_defaults}
end

;
;--------------------------------------
function drf::check_output_path_exists, path
	if strc(path) eq "" then return, 0 ; blank paths are invalid

	if file_test(path,/dir,/write) then begin
		return, 1 
	endif else  begin
		if gpi_get_setting('prompt_user_for_outputdir_creation',/bool) then res =  dialog_message('The requested output directory '+path+' does not exist. Should it be created now?', title="Nonexistent Output Directory", /question) else res='Yes'
		if res eq 'Yes' then begin
			file_mkdir, path
			return, 1
		endif else return, 0

	endelse
	return, 0

end


;--------------------------------------------------------------------------------
; back compatibility hook for old method name: 
pro drf::savedrf, outputfile0, absolutepaths=absolutepaths,autodir=autodir,silent=silent
	self->save, outputfile0, absolutepaths=absolutepaths,autodir=autodir,silent=silent
end

;--------------------------------------------------------------------------------

pro drf::save, outputfile0, absolutepaths=absolutepaths,autodir=autodir,silent=silent
	; write out to disk!
	;
	; KEYWORDS:
	; 	/absolutepaths		write DRFs using absolute paths in their text, not
	; 						environment variables for relative paths
	; 	/autodir			Automatically decide the best output directory to
	; 						save this file to

	outputfile=outputfile0 ; don't modify input outputfile variable.

	if keyword_set(autodir) then begin 
		if gpi_get_setting('organize_DRFs_by_dates',/bool) then begin
			outputdir = gpi_get_directory('GPI_DRF_OUTPUT_DIR')+path_sep()+self->get_datestr()
		endif else begin
			; if the organize by dates is turned off, then 
			; FIXME should this output to the current directory, or what
			outputdir = gpi_get_directory('GPI_REDUCED_DATA_DIR')
		endelse
		outputfile=outputdir +path_sep()+file_basename(outputfile)
	end


	valid = self->check_output_path_exists(file_dirname(outputfile))
	if ~valid then begin
		self->Log, "Could not write to nonexistent directory: "+file_dirname(outputfile)
		return
	endif
	if ~(keyword_set(silent)) then self->log,'Writing DRF to '+outputfile

	OpenW, lun, outputfile, /Get_Lun


	PrintF, lun, self->tostring(absolutepaths=absolutepaths)
	Free_Lun, lun
	;self->log,'Saved  '+outputfile
	self.last_saved_filename=outputfile

end

;-------------
PRO drf::queue, filename=filename
	; save a DRF into the queue

	if ~(keyword_set(filename)) then filename=self.last_saved_filename

	if ~(keyword_set(filename)) then message,"Need to specify a filename to queue it!"

	outname = file_basename(filename)
	outname = strepex(outname,"([^\.]+)\..+$", "&0.waiting.xml") ; replace file extension to .waiting.xml
	queue_filename = gpi_get_directory("GPI_DRP_QUEUE_DIR")+path_sep()+outname


	prev_outputfile = self.last_saved_filename ; save value before this gets overwritten in save

	self->saveDRF, queue_filename,/silent

	self.last_saved_filename= prev_outputfile ; restore previous value

	self->Log, "    Queued "+file_basename(queue_filename)

end

;-------------

function drf::tostring, absolutepaths=absolutepaths
	; Return a DRF formatted as an XML string


	if ~(keyword_set(absolutepaths ))then begin
		;relative pathes with environment variables        
	  	;logdir=gpi_shorten_path(self.logdir) 
	  	inputdir=gpi_shorten_path(self.inputdir) 
	  	outputdir=gpi_shorten_path(self.outputdir) 
	endif else begin
	  	;logdir=gpi_expand_path(self.logdir)
	  	inputdir=gpi_expand_path(self.inputdir)
	  	outputdir=gpi_expand_path(self.outputdir)
	endelse  

	;if logdir eq '' then logdir = outputdir ; if log dir is not explicitly set, write log to output directory

 
	if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)

	outputstring = ''
        
	outputstring +='<?xml version="1.0" encoding="UTF-8"?>'+newline 
    
	outputstring +='<DRF Name="'+self.name+'" ReductionType="'+self.reductiontype+'">'+newline

	outputstring +='<dataset InputDir="'+inputdir+'" OutputDir="'+outputdir+'">'+newline 
 
	if ptr_valid(self.filenames) then $
	FOR j=0,N_Elements(*self.filenames)-1 DO BEGIN
		outputstring +='   <fits FileName="' + file_basename( (*self.filenames)[j]) + '" />'+newline
	ENDFOR
	outputstring +='</dataset>'+newline

    drf_contents = self->get_contents()
    drf_module_names = drf_contents.modules.name


	FOR j=0,n_elements(drf_module_names)-1 DO BEGIN

		module_args = self->get_module_args(j, count=count)
		strarg='' ; no arguments yet

		if count gt 0 then begin
			  for i=0,n_elements(module_args.names)-1 do begin
				  strarg+=module_args.names[i]+'="'+module_args.values[i]+'" '
			  endfor
		endif
		  
	
		outputstring +='<module name="' + drf_module_names[j] + '" '+ strarg +'/>'+newline
	ENDFOR
	outputstring +='</DRF>'+newline
	
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
function drf::init, filename, parent_object=parent_object,silent=silent,quick=quick
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

    ; now parse the requested DRF.
	if ~(keyword_set(quick)) then begin
		; First re-parse the config file (so we know about all the available modules
		; and their arguments)
		ConfigParser = self->get_configParser()
	endif 

    ; then parse the DRF and get its contents
    self.parsed_drf= OBJ_NEW('gpiDRFParser')
    self.parsed_drf->ParseFile, self.loaded_filename,  ConfigParser, gui=self, silent=silent

    drf_summary = self->get_summary()
    drf_contents = self->get_contents()
    ;drf_module_names = drf_contents.modules.name

	self.inputdir = drf_contents.inputdir
	self.name = drf_summary.name
	self.reductiontype = drf_summary.reductiontype

	return, 1
end

;--------------------------------------------------------------------------------
function drf::get_summary
	summary = self.parsed_drf->get_summary()
	if ptr_valid(self.filenames) then summary.nfiles = n_elements(*self.filenames) else summary.nfiles=0
	return, summary
end
;--------------------------------------------------------------------------------

function drf::get_contents
	return, self.parsed_drf->get_contents()
end


;--------------------------------------------------------------------------------
pro drf::cleanup

	obj_destroy, self.parsed_drf
	ptr_free, self.filenames
	ptr_free, self.configDRS

end



;--------------------------------------------------------------------------------

PRO drf__define

	state = {drf, $
		loaded_filename: '',$		; name of input file loaded from disk
		last_saved_filename: '', $	; last saved filename
		name: '', $			; descriptive string name
		reductiontype: '',$	; what type of reduction?
		parsed_drf: obj_new(), $	;gpiDRFParser object for the XML file itself
		where_to_log: obj_new(),$		;; optional target object for log messages
		inputdir: '', $
		outputdir: '', $
		filenames: ptr_new(), $
		configDRS: ptr_new() $  ; DRS modules configuration info
		}

end
