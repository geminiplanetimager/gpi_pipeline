;-----------------------------------------------------------------------------------------------------
; CLASS gpiDRFParser
;
; DESCRIPTION:
;	gpiDRFParser is responsible for parsing a DRF and reading the input data files.
;	Data set information is placed in structDataSet variables and module information
;	placed in structModule variables.
;
;	drpParser inherits the IDL IDLffXMLSAX class, a general XML parser.  IDLffXMLSAX is
;	an event driven parser, using callback functions to handle XML elements on the fly.
;
;	Note: Due to how IDLffXMLSAX parser works, this is sort of user-unfriendly.
;	See drf__define for a wrapper that hides this complexity mostly and gives
;	a more convenient high level interface.
;
;
; NOTES BY MDP:
;   For record-keeping purposes, a copy of the DRF is written into each FITS
;   header. This happens in gpidrfparser::enddocument
;
;
;   This parser may be invoked in one of **THREE WAYS**:
;      (a) inside the Pipeline itself, in which case it both
;         - logs actions to the pipeline log, and 
;         - sticks various items into the pipeline's memory as it works; or
;      (b) in one of the DRF or Parser GUIs, in which case it parses things but
;         doesn't actually do anything else other than hand back the results.
;      (c) hidden inside an invokation of the 'drf' object class, which is
;          generally more user-friendly than working with this directly.
;          This is pretty close to mode (b) in terms of functionality.
;
;   If the object is created with a backbone= argument that is a GPI Pipeline
;   Backbone, then it will run in Method (a), otherwise it runs in Method (b) 
;

;-----------------------------------------------------------------------------------------------------
FUNCTION gpidrfparser::init, backbone=backbone, no_log = no_log
  retval = Self->IDLffXMLSAX::Init()

  ;self.no_log = 1 ; default is to assume we're running in Mode (b), defined above
  if keyword_set(backbone) then if obj_valid(backbone) then begin
	  self.backbone=backbone
	  self.no_log = 0
  endif

  return, retval

end

;------------------------------------------------------------
PRO gpidrfparser::cleanup

	self->free_dataset_pointers

    Self->IDLffXMLSAX::Cleanup

END


;------------------------------------------------------------
; gpidrfparser::comment
;
; Print a comment found in the XML to screen (optional)
;

PRO gpidrfparser::comment, newComment
  if ~self.silent then PRINT, "Comment found.  Text = " + newComment
END

;------------------------------------------------------------
; A simple helper/accessor routine for the two different modes this object can run
; in.
function gpidrfparser::do_continueAfterRecipeXMLParsing
	if obj_valid(self.backbone) then return, self.backbone->getContinueAfterRecipeXMLParsing() $
	else return, 0

end

;------------------------------------------------------------
; gpidrfparser::get_contents
;
; Return a struct containing the contents of an XML recipe
;
function gpidrfparser::get_contents
	if ~ ptr_valid(self.data) or ~ ptr_valid(self.modules) then begin
		message, "No valid DRF loaded!",/info
		return, {fitsfilenames: [''], modules: [''], inputdir: '', outputdir: '', reductiontype: ''}
	endif


	if (*self.data).validframecount gt 0 then begin
	   fitsfilenames = (*self.data).filenames[0:(*self.data).validframecount-1]
	endif else begin
	   fitsfilenames = [''] ; FIXME should be null array in IDL >=8
	endelse

	if n_elements(*self.modules) gt 0 then modules = (*self.modules) else modules = ['']

	return, {fitsfilenames: fitsfilenames, inputdir: (*self.data).inputdir, outputdir: (*self.data).outputdir, modules: modules }
end

;------------------------------------------------------------
; gpidrfparser::get_summary
;
; return a brief summary of the DRF element in a given file. 
; This is used by the Template scanning functions in DRFGUI.
;
function gpidrfparser::get_summary

	if ~ ptr_valid(self.data) or not ptr_valid(self.modules) then begin
		message, "No valid DRF loaded!",/info
		return, {filename: '', reductiontype: '', name: '', ShortName: '', nsteps: 0L,nfiles: 0L}
	endif

	return, {filename: self.most_recent_filename,  $
			 reductiontype: self.ReductionType, $
			 name: self.DRFname, $
			ShortName: self.ShortName, $
			 nsteps: long(n_elements(*self.modules)) , $
			 nfiles: long((*self.data).validframecount) }
end



;------------------------------------------------------------
pro gpidrfparser::set_module_argument, modnum, argname, value
	all_arg_names = tag_names( (*self.modules)[modnum])

	warg = where(strupcase(argname) eq all_arg_names, mct)
	if mct ne 1 then message, 'Could not find argument '+argname+" for module number "+string(modnum)

	(*self.modules)[modnum].(warg[0]) = string(value)


end

;------------------------------------------------------------
PRO gpidrfparser::free_dataset_pointers

	; Free any data which are currently read into memory
	IF PTR_VALID(Self.Data) THEN if keyword_set(*self.data) then BEGIN
			PTR_FREE, (*Self.Data).QualFrames[*]
			PTR_FREE, (*Self.Data).UncertFrames[*]
			PTR_FREE, (*Self.Data).HeadersExt[*]
			PTR_FREE, (*Self.Data).HeadersPHU[*]
			PTR_FREE, (*Self.Data).Frames[*]
			PTR_FREE, (*Self.Data).CurrFrame
	ENDIF
	PTR_FREE, Self.Modules
	PTR_FREE, Self.Data

end

;------------------------------------------------------------

PRO gpidrfparser::parsefile, FileName, ConfigParser, Backbone=backbone, gui_obj=gui_obj, silent=silent, status=status
	; This is the main routine that actually parses a given file. 
	;
	; Depending on how it's called, it can either just read some info from the
	; XML, or it can load a whole bunch of data into memory...
	;
	; INPUTS:
	;   Filename	String naming the XML file to parse
	;   ConFigParser	A DRSConfigParser object, for translating method names
	;   				into IDL function calls.  Optional. That translation
	;   				will not take place if this is not provided.
	;
	; KEYWORDS:
	;  
	; HISTORY:
	;    2012-08-09 MP: updated to make configparser optional.

	OK = 0
	NOT_OK = -1

	status = NOT_OK
	self.silent  = keyword_set(silent)
	if ~self.silent then self->Log, "Parsing: "+filename 
	; Free any previous structDataSet, structModule and structUpdateLists data
	; See note for gpiDRFParser::Cleanup
	self->free_dataset_pointers

	self.most_recent_filename = Filename

	; update my own modules and data lists. 
	if ~file_test(filename) then begin
		self->Log, 'ERROR: The recipe file '+filename+" no longer exists! Cannot parse it.", depth=1
		status = NOT_OK
		return
	endif

    ;initialize just in case there is no present before scanning
    Self.DRFName=''

	catch, parse_error
	if parse_error eq 0 then Self -> IDLffXMLSAX::ParseFile, FileName

	if parse_error ne 0 or ~ptr_valid(self.modules) then begin
		self->Log,"ERROR: Some sort of fatal error has occured while parsing the recipe file "+filename+".",depth=1
		; IDLffXMLSAX doesn't set !error_state.msg, so the following line was
		; printing totally unrelated error messages from earlier in the IDL
		; session. - MP
		;backbone->Log,!error_state.msg, depth=1
		status = NOT_OK
		return

	endif
	
	; Now use the ConfigParser's translation table to look up the IDL commands.
	; By default, assume the module names *are* the IDL commands
	(*self.modules).idlcommand=(*self.modules).name
	; but if we have a configparser  then we can do the translation
	if keyword_set(configparser) then begin
		; for each module, check to see if there's a match in the lookup table
		for i=0L,n_elements(*self.modules)-1 do begin
			cmd = ConfigParser->GetIDLCommand((*self.modules)[i].Name, matched=matched)
			if matched eq 0 then begin
				self->Log, "WARNING: No match found for "+(*self.modules)[i].Name, depth=1
				self->Log, "         Going to try using that as the IDL command directly, but this will likely not work:", depth=1
				cmd = (*self.modules)[i].Name 
			endif
			(*self.modules)[i].IDLCommand = cmd

		endfor 
	endif


	; Validate presence of output directory:
	; if *any* of the available primitives have a 'save' option set to 1, then
	; the output directory must not be blank.
	if strc( (*self.data).outputdir) eq '' then begin
		for i=0L,n_elements(*self.modules)-1 do begin
			if tag_exist( (*self.modules)[i], 'SAVE') then begin
				if (*self.modules)[i].Save eq 1 then begin
					self->Log, 'ERROR: Invalid Recipe. Output directory is blank, but saving a file is requested in step '+strc(i+1)+". ", depth=1
					self->Log, " Since it's not clear where to write it, cannot proceed, therefore failing this recipe. Please set OutputDir.", depth=1
					status=NOT_OK
					return
				endif
			endif
		endfor
	endif



	status = OK ; completed OK!

END

;------------------------------------------------------------
;  Check whether the contents of a parsed DRF are valid, 
;      in particular whether the file names all correspond to valid files on
;      disk.
function gpidrfparser::validate_contents


valid = 1 ; assume valid unless we find a problem? 

for i=0L, (*Self.Data).ValidFrameCount - 1 do begin
	full_input_filename = gpi_expand_path((*self.data).inputdir + path_sep() + (*Self.Data).Filenames[i])
	;full_input_filename = (*Self.Data).Filenames[i]
	if ~ file_test(full_input_filename,/read) then begin
		self->Log, 'ERROR: The file "'+ full_input_filename+'" does not exist on disk or is unreadable.  Cannot load requested data.'
			;!error_state.msg =  "File "+ full_input_filename+" does not exist or is unreadable."
		valid = 0
		;;  self->StopParsing
	endif 

endfor 

if keyword_set(valid) then begin
	self->Log, "Validation OK: all input files in that recipe exist."
endif else begin
	self->Log, "ERROR: Validation FAILED!  One or more input files in that recipe are unreadable."
endelse

return, valid


end

;------------------------------------------------------------

pro gpidrfparser::load_data_to_pipeline, backbone=backbone, status=status
	; Load all available data into the pipeline backbone for
	; actual reduction
    ; 
    ; This is called by the backbone after a file has been
    ; successfully parsed.
	;
	; Subtle caution: This does NOT actually load all the FITS files themselves
	; anymore! They are read one at a time now. This just passes all the
	; filenames, primitive names and arguments, and other information to the
	; pipeline.

	OK = 0
	NOT_OK = -1


	status=NOT_OK 


	if ~ self->validate_contents() then begin
		self->Log, "Recipe file is invalid, due to one or more missing files. Cannot load data!"
		status = NOT_OK
		return
	endif

    ; Now place a copy of the current DRF into each available header
    ; First, get the file name of the file we are parsing
    ;Self -> IDLffXMLSAX::GetProperty, FILENAME=myOwnFileName
    myOwnFileName = self.most_recent_filename
  
    ; Open the DRF file and read it into a string array
    fileAsStringArray = ['']
    inputString = ''
    GET_LUN, myunit
    OPENR, myunit, myOwnFileName
    count = 0
    WHILE ~EOF(myunit) DO BEGIN
      READF, myunit, inputString
      IF count EQ 0 THEN fileAsStringArray = [inputString] $
      ELSE fileAsStringArray = [fileAsStringArray, inputString]
      count += 1
    ENDWHILE
    CLOSE, myunit
    FREE_LUN, myunit
  
    ; Parse file for environment variables, and store
    complete_drf = strjoin(fileAsStringArray, " ")
    expanded = gpi_expand_path(complete_drf, vars_expanded=vars_expanded)
    if keyword_set(vars_expanded) then begin
		record = "$"+vars_expanded +" = "+getenv(vars_expanded)
;	  wlong = where(strlen(record) gt 67, longct)
;	  if longct gt 0 then begin
;		  newrecord=['']
;		for j=0L,longct-1 do begin
;			nparts = ceil(strlen(record[j]) / 67.)
;			parts = strmid(record[j], indgen(nparts)*67, indgen(nparts)*67+66)
;
;
;		endfor 
;	  endif
  	; Split into no more than 67 chars per line, to stick into FITS header
		newrecord=[' -- Variables used in DRF: --']
		for j=0L,n_elements(record)-1 do begin
			if strlen(record[j]) le 67 then newrecord=[newrecord, record[j]] else begin
				nparts = ceil(strlen(record[j]) / 67.)
				parts = strmid(record[j], indgen(nparts)*67, indgen(nparts)*67+67)
				newrecord=[newrecord,parts]
			endelse
		endfor
		var_record=temporary(newrecord) 
    endif


    ; Get the number of headers to do
    stopHeader = (*Self.Data).ValidFrameCount - 1
    FOR indexHeader = 0, stopHeader DO BEGIN	; For all headers
      SXADDPAR, *(*Self.Data).HeadersPHU[indexHeader], 'COMMENT', '////////////////////////////////////////////////////////////////////////'
      ; Save the file name as one or more comments
      ; Figure out how many 68 character strings there are in the file name string
      clen = STRLEN(myOwnFileName)
      n = (clen/68) + 1
      FOR j=0, n-1 DO BEGIN
        newsubstring = STRMID(myOwnFileName, j*68, 68)
        SXADDPAR, *(*Self.Data).HeadersPHU[indexHeader], 'COMMENT', 'DRFN' + newsubstring
      ENDFOR
      FOR i=0, N_ELEMENTS(fileAsStringArray)-1 DO BEGIN
        IF STRLEN(fileAsStringArray[i]) LT 68 THEN BEGIN
          SXADDPAR, *(*Self.Data).HeadersPHU[indexHeader], 'COMMENT', 'DRF ' + fileAsStringArray[i]
        ENDIF ELSE BEGIN
          ; Figure out how many 68 character strings there are in the current string
          clen = STRLEN(fileAsStringArray[i])
          n = (clen/68) + 1
          FOR j=0, n-1 DO BEGIN
            newsubstring = STRMID(fileAsStringArray[i], j*68, 68)
            SXADDPAR, *(*Self.Data).HeadersPHU[indexHeader], 'COMMENT', 'DRFC' + newsubstring
          ENDFOR
        ENDELSE
      ENDFOR

	  if obj_valid(self.backbone) then if keyword_set(var_record) then begin	; record environment variables into header
		  for j=0L,n_elements(var_record)-1 do SXADDPAR,  *(*Self.Data).HeadersPHU[indexHeader], 'COMMENT', 'DRFV'+ var_record[j]
	  endif

      SXADDPAR, *(*Self.Data).HeadersPHU[indexHeader], 'COMMENT', '\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\'
    ENDFOR



	IF self->do_continueAfterRecipeXMLParsing()  EQ 1 THEN BEGIN
		; pass the updates back up to the backbone
		;Backbone.ReductionType = Self.ReductionType
		Backbone.Data = Self.Data
		Backbone.Modules = Self.Modules
	ENDIF 

	status=OK 

end



;==================================================================================================
;   Actual low level XML parsing related code below here. 
;
;------------------------------------------------------------
;
;

PRO gpidrfparser::error, SystemID, LineNumber, ColumnNumber, Message
  ; Any error parsing the input file is too much error for you.

  ; Log the error info
  self->Log, 'Recipe parsing non-fatal error',  DEPTH=1
  self->Log, '    Filename: ' + SystemID, DEPTH=2
  self->Log, '  LineNumber: ' + STRTRIM(STRING(LineNumber),2), DEPTH=2
  self->Log, 'ColumnNumber: ' + STRTRIM(STRING(ColumnNumber),2), DEPTH=2
  self->Log, '     Message: ' + Message, DEPTH=2

END

;------------------------------------------------------------
;
;


PRO gpidrfparser::fatalerror, SystemID, LineNumber, ColumnNumber, Message

  ; Any fatal error parsing the input file is certainly too much error for you.

  ; Log the error info
  self->Log, 'Recipe parsing fatal error', DEPTH=1
  self->Log, '    Filename: ' + SystemID, DEPTH=2
  self->Log, '  LineNumber: ' + STRTRIM(STRING(LineNumber),2), DEPTH=2
  self->Log, 'ColumnNumber: ' + STRTRIM(STRING(ColumnNumber),2), DEPTH=2
  self->Log, '     Message: ' + Message, DEPTH=2

  self->free_dataset_pointers
END


;-----------------------------------------------------------------------------------------------------
; Procedure StartDocument
;
; DESCRIPTION:
; 	This procedure is inherited from the IDLffxMLSAX parent class.  StartDocument is
;	called automatically when the parser begins parsing an XML document.
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO gpidrfparser::startdocument

	Self.Data = PTR_NEW(/ALLOCATE_HEAP)
	Self.Modules = PTR_NEW(/ALLOCATE_HEAP)

	; ----------------- TO DO: Validate the document ----------------------------
	self->Log, 'Starting to parse recipe file', DEPTH=1
	self->Log, 'Recipe file is currently unvalidated and is assumed to be valid', DEPTH=1

END

;-----------------------------------------------------------------------------------------------------
; Procedure EndDocument
;
; DESCRIPTION:
; 	This procedure is inherited from the IDLffxMLSAX parent class.  EndDocument is
;	called automatically when the parser finishes parsing an XML document.  
;
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO gpidrfparser::enddocument

	self->Log, "XML parsing complete."

END

;-----------------------------------------------------------------------------------------------------
; Procedure StartElement
;
; DESCRIPTION:
; 	This procedure is inherited from the IDLffxMLSAX parent class.  StartElement is
;	called automatically when the parser encounters an XML element.
;
; ARGUMENTS:
;	URI
;	Local
;	qName		Name of the XML element
;	AttNames	Array of attribute names
;	AttValues	Array of atribute values
;
; KEYWORDS:
;	Inherited from parent class.  See documentation.
;-----------------------------------------------------------------------------------------------------
PRO gpidrfparser::startelement, URI, Local, qName, AttNames, AttValues
	;print, strupcase(qName)
	CASE strupcase(qName) OF
		'DRF': BEGIN
			; This FOR statement allows the attributes to be in any order in the XML file
			FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values in the
				CASE strupcase(AttNames[i]) OF			; variable fields.
					'REDUCTIONTYPE':   begin
						if strmatch('-', AttValues[i]) then begin
							; need to convert old style type names to new ones...
							if strmatch('CAL', strupcase(AttValues[i])) then begin
								AttValues[i] = 'Calibrations'
							endif else begin
								if strmatch('ASTR', strupcase(AttValues[i])) then AttValues[i] = 'SpectralScience'
								if strmatch('POL', strupcase(AttValues[i])) then AttValues[i] = 'PolarimetricScience'
							endelse

						endif

						Self.ReductionType = AttValues[i]
					end
					'NAME':			    Self.DRFName = AttValues[i]
                                        'SHORTNAME':             Self.ShortName = AttValues[i]
					ELSE:
				ENDCASE
			END
		END
		'RECIPE': BEGIN  ;;--- clone of DRF option for Gemini preferred naming convention ---
			; This FOR statement allows the attributes to be in any order in the XML file
			FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values in the
				CASE strupcase(AttNames[i]) OF			; variable fields.
					'REDUCTIONTYPE':   	Self.ReductionType = AttValues[i]
					'NAME':			    Self.DRFName = AttValues[i]
                                        'SHORTNAME':             Self.ShortName = AttValues[i]
					ELSE:
				ENDCASE
			END
		END

		'DATASET': Self -> NewDataSet, AttNames, AttValues	; Add a new data set
		'FITS':	BEGIN
			DataFileName = ''
			FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values in the
				CASE strupcase(AttNames[i]) OF			; variable fields.
					'FILENAME':	   DataFileName = AttValues[i]
					ELSE: self->Log, 'Error in gpiDRFParser::StartElement - Illegal/Unnecessary attribute ' + AttNames[i], Depth=1
				ENDCASE
			END
			IF DataFileName NE '' THEN BEGIN
			; TODO: Read in files here? For now just parse the XML.
				full_input_filename = gpi_expand_path((*self.data).inputdir + path_sep() + DataFileName)
				if obj_valid(self.backbone) then begin
					(*self.data).Frames[(*self.data).ValidFrameCount] = ptr_new( full_input_filename )
					if ~(keyword_set(self.silent)) then PRINT, FORMAT='(".",$)'
				endif

				; Just take the FITS files, don't attempt to load them yet. 
				(*Self.Data).Filenames[(*Self.Data).ValidFrameCount] = DataFileName
				(*Self.Data).ValidFrameCount = (*Self.Data).ValidFrameCount + 1


;				IF (self->do_continueAfterRecipeXMLParsing() EQ 1) or ~obj_valid(self.backbone)  THEN BEGIN
;					; FIXME check the file exists and is a valid GPI fits file 
;
;					if ~ file_test(full_input_filename,/read) then begin
;						  self->Log, 'ERROR: The file "'+ full_input_filename+'" does not exist on disk or is unreadable.  Cannot load requested data.'
;							!error_state.msg =  "File "+ full_input_filename+" does not exist or is unreadable."
;						  self->StopParsing
;						  ;Skipping this file and trying to continue anyway...', DEPTH=2;;
;					endif else begin
;
;					;valid = gpi_validate_file(full_input_filename)
;
;	        	    ;fits_info, full_input_filename, n_ext = numext, /silent
;	            	;validtelescop=self->validkeyword( full_input_filename, 1,'TELESCOP','Gemini')
;		            ;validinstrum= self->validkeyword( full_input_filename, 1,'INSTRUME','GPI')
;		            ;validinstrsub=self->validkeyword( full_input_filename, 1,'INSTRSUB','IFS') 
;		            ;if (validtelescop* validinstrum*validinstrsub eq 1) then begin   
;					;if valid then begin
;		              ;self->Log, DataFileName +' is a valid GEMINI-GPI-IFS image.', DEPTH=2
;		            ;endif else begin
;		              ;self->Log, 'ERROR:'+ DataFileName +' is NOT a GEMINI-GPI-IFS image. File ignored!', DEPTH=2
;		            ;endelse
;		          endelse
;				ENDIF
			ENDIF ELSE BEGIN
				self->Log, 'NOTE: <fits/> element has empty filename', DEPTH=2
				;stop
   			    ;pipelineconfig.continueAfterDRFParsing = 0
			ENDELSE
		END
		'MODULE': Self -> NewModule, AttNames, AttValues	; Add a new module
		'PRIMITIVE': Self -> NewModule, AttNames, AttValues	; Add a new primitive (copy for Gemini preferred naming convention)

		; Remove these weird old OSIRIS options which are never used with GPI:
		; -MP
		;'UPDATE': Self -> NewUpdateList, AttNames, AttValues	; Start a new update list
		;'UPDATEPARAMETER':  Self -> AddUpdateParameter, AttNames, AttValues	; Add parms to latest list
	ENDCASE


END

;-----------------------------------------------------------------------------------------------------
; Procedure NewDataSet
;
; DESCRIPTION:
; 	Creates a new structDataSet variable, enters the information from the DRF into the
;	variable fields and reads the specified FITS files in to the variables Frames
;	field.
;
; ARGUMENTS:
;	AttNames	Array of attribute names
;	AttValues	Array of attribute values
;-----------------------------------------------------------------------------------------------------
PRO gpidrfparser::newdataset, AttNames, AttValues

	DataSet = {structDataSet}			; Create a new structDataSet variable

	MAXFRAMESINDATASETS = gpi_get_setting('max_files_per_recipe', default=200)
	DataSet.Frames = PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)
	DataSet.HeadersPHU = PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)
	DataSet.HeadersExt = PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)
	DataSet.UncertFrames = PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)
	DataSet.QualFrames = PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)

	FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values in the
		CASE AttNames[i] OF			; variable fields.
		'InputDir':	begin
		            if strlen(getenv(AttValues[i])) ne 0 then $
		            DataSet.InputDir = getenv(AttValues[i]) else $
		            DataSet.InputDir = AttValues[i]		            
		            end
;		'Name': BEGIN
;			IF Self -> DataSetNameIsUnique(AttValues[i]) THEN BEGIN
;			  DataSet.Name = AttValues[i]
;			ENDIF ELSE BEGIN
;				self->Log, 'DataSet Name ' + AttValues[i] + ' attribute is duplicated.', DEPTH=2
;				self->Log, 'DRF will be aborted', DEPTH = 2
;				continueAfterRecipeXMLParsing = 0
;			ENDELSE
;	    END
		'OutputDir':	begin
                if strlen(getenv(AttValues[i])) ne 0 then $
                DataSet.OutputDir = getenv(AttValues[i]) else $
                DataSet.OutputDir = AttValues[i]               
                end
		ELSE:
		ENDCASE
	END

	; This adds the new dataset to the array of datasets; this is an array
	; of structDataSet elements.
	if N_ELEMENTS(*Self.Data) EQ 0 THEN *Self.Data = DataSet $	; Add the DataSet
	ELSE *Self.Data = [*Self.Data, DataSet]				; variable to the
									; array.


END

;-----------------------------------------------------------------------------------------------------
; Procedure NewModule
;
; DESCRIPTION:
; 	Creates a new structModule variable, enters the information from the DRF
;	<module/> element into the variable fields.
;
; ARGUMENTS:
;	AttNames	Array of attribute names
;	AttValues	Array of attribute values
;
;
; HISTORY:
; 	2006-04-20	Modified to allow arbitrary additional attributes in modules.
; 				Requires struct_merge.pro and struct_trimtags.pro
; 				 - Marshall Perrin
;-----------------------------------------------------------------------------------------------------
PRO gpidrfparser::newmodule, AttNames, AttValues

	;verbose = 1
	Module = {structModule}				; Create structModule variable

    module.outputdir=(*self.data)[0].outputdir

	FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN		; Enter attribute values
		; if this attribute is already a tag in the structure, just add the value to
		; that tag.
		indx = where(tag_names(module) eq strupcase(attnames[i]))
		if (indx ge 0) then begin
			module.(indx) = attvalues[i]
		endif else begin
			; otherwise, add a new tag
			module = create_struct(module,AttNames[i],AttValues[i])
		endelse
	ENDFOR

	;if keyword_set(verbose) then print, "New Module", module
	IF N_ELEMENTS(*Self.Modules) EQ 0 THEN *Self.Modules = [Module] $	; Add to the array
	ELSE *Self.Modules = struct_merge(*Self.Modules, Module)

    if ~(keyword_set(self.silent)) then 	self->Log, "    Found primitive "+strc(n_elements(*Self.Modules))+": "+module.name

END


;-----------------------------------------------------------------------------------------------------
; Procedure Log
;
; DESCRIPTION:
; 	Pass a log message back up to the parent backbone object, or print to
; 	screen.
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------

pro gpidrfparser::log, text, _extra=_extra

	if self.no_log then return

	if obj_valid(self.backbone) then begin
		self.backbone->log, text, _extra=_extra
	endif else begin
		;message,"Log facility not available! Can't log: ",/info
		if ~self.silent then message, text,/info, level=-1
	endelse

end


;-----------------------------------------------------------------------------------------------------
; Procedure gpiDRFParser__define
;
; DESCRIPTION:
; 	This defines the struct
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------

PRO gpidrfparser__define

	void = {gpiDRFParser, INHERITS IDLffXMLSAX, $
			ReductionType:'', $  ; Type of reduction recipe 
			DRFName: '', $   ; a descriptive name for the DRF. Used by Template DRFs.
                        ShortName: '', $ ; a short name to be used in recipe filenames
			most_recent_filename: '', $ ; remember this for get_summary
			no_log: 0, $     ; flag for not logging actions if ran in some other mode
			silent: 0, $	 ; suppress printed output?
			Data:PTR_NEW(), $
			Modules:PTR_NEW(), $
			backbone: obj_new() }

END



