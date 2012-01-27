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
;
;
; NOTES BY MDP:
;   For record-keeping purposes, a copy of the DRF is written into each FITS
;   header. This happens in gpidrfparser::enddocument
;
;
;   This parser may be invoked in one of **TWO WAYS**:
;      (a) inside the Pipeline itself, in which case it both
;         - logs actions to the pipeline log, and 
;         - sticks various items into the pipeline's memory as it works; or
;      (b) in one of the DRF or Parser GUIs, in which case it parses things but
;         doesn't actually do anything else other than hand back the results.
;
;   If the object is created with a backbone= argument that is a GPI Pipeline
;   Backbone, then it will run in Method (a), otherwise it runs in Method (b) 
;

;-----------------------------------------------------------------------------------------------------
;------------------------------------------------------------
;
;
FUNCTION gpidrfparser::init, backbone=backbone, no_log = no_log
  retval = Self->IDLffXMLSAX::Init()

  self.no_log = 1 ; default is to assume we're running in Mode (b), defined above
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



;-----------------------------------------------------------------------------------------------------
; Procedure drpFITSToDataSet
;
; DESCRIPTION:
; 	drpFITSToDataSet reads a standard data frame FITS file into a structDataSet variable
; ARGUMENTS:
;	DataSet			A pointer to structDataSet variable into which the data is placed
;	FileName		Name and path of the data frame FITS file.
;	FileControl	Control bits that determine which HDUs in FileName are read into memory.
;
; KEYWORDS:
;	None.
; MODIFIED:	tmg 2003/09/11 Change type of data set to FLOAT from UINT (at least for testing)
; 		tmg 2004/02/11 Change to use individual pointers to all data arrays
; 		tmg 2004/04/15 On error, issue a MESSAGE to force a catchable error.
;     tmg 2004/06/30(?) Change code to use one file input instead of three.
; 		tmg 2004/07/12 On error, do not issue a MESSAGE to force a catchable error; instead set
;                    a variable to allow the DRF parser to abort the DRF processing.
; 		tmg 2004/09/09 Add file reading control to select parts of data frames to be read
; 	2010-01-27: MDP: Removed lots of commented out old code, merged into GPIDRFParser
;-----------------------------------------------------------------------------------------------------
PRO gpiDRFParser::drpFITSToDataSet, DataSet, ValidFrameCount, FileName

;COMMON APP_CONSTANTS
	; FIXME - need to put these back into the backbone obj while avoiding common
	; blocks!

    ;IF ValidFrameCount EQ 0 THEN BEGIN ; Reset current running total on first file of a DRF
        ;CumulativeMemoryUsedByFITSData = 0L
    ;ENDIF
    ;MemoryBeforeReadingFITSFile = MEMORY(/CURRENT) ; Memory before reading all or part of file
    *DataSet.Frames[ValidFrameCount] = DataSet.InputDir + path_sep() + FileName
    if ~(keyword_set(self.silent)) then PRINT, FORMAT='(".",$)'

END

;------------------------------------------------------------
;
;

PRO gpidrfparser::comment, newComment
  if ~self.silent then PRINT, "Comment found.  Text = " + newComment
END

;------------------------------------------------------------
; A simple helper/accessor routine for the two different modes this object can run
; in.
function gpidrfparser::do_continueAfterDRFParsing
	if obj_valid(self.backbone) then return, self.backbone->getContinueAfterDRFParsing() $
	else return, 0

end

;------------------------------------------------------------
;
function gpidrfparser::get_drf_contents
	if not ptr_valid(self.data) or not ptr_valid(self.modules) then begin
		message, "No valid DRF loaded!",/info
		return, {fitsfilenames: [''], modules: [''], inputdir: '', reductiontype: ''}
	endif

	return, {fitsfilenames: (*self.data).filenames, modules: (*self.modules), inputdir: (*self.data).inputdir, reductiontype: (self.reductiontype)}
end
;
;------------------------------------------------------------
PRO gpidrfparser::free_dataset_pointers
	; This Cleanup supposes that there may be more than one dataset in a DRF
	; though we do not currently create DRFs in this manner.
	IF PTR_VALID(Self.UpdateLists) THEN BEGIN
		FOR i = 0, N_ELEMENTS(*Self.UpdateLists)-1 DO BEGIN
			PTR_FREE, (*Self.UpdateLists)[i].parameters
		ENDFOR
	ENDIF



	; Free any data sets which are currently read into memory
	IF PTR_VALID(Self.Data) THEN BEGIN
		FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
			PTR_FREE, (*Self.Data)[i].QualFrames[*]
			PTR_FREE, (*Self.Data)[i].UncertFrames[*]
			PTR_FREE, (*Self.Data)[i].HeadersExt[*]
			PTR_FREE, (*Self.Data)[i].HeadersPHU[*]
			PTR_FREE, (*Self.Data)[i].Frames[*]
			PTR_FREE, (*Self.Data)[i].CurrFrame
		ENDFOR
	ENDIF
	PTR_FREE, Self.UpdateLists
	PTR_FREE, Self.Modules
	PTR_FREE, Self.Data



end

;------------------------------------------------------------

PRO gpidrfparser::parsefile, FileName, Backbone=backbone, ConfigParser, gui_obj=gui_obj, silent=silent, status=status

	status = -1
	self.silent  = keyword_set(silent)
	if ~self.silent then print, "Parsing: "+filename 
	; Free any previous structDataSet, structModule and structUpdateLists data
	; See note for gpiDRFParser::Cleanup
	self->free_dataset_pointers

	self.most_recent_filename = Filename

	; update my own modules and data lists. 
	if ~file_test(filename) then begin
		message,/info, 'WARNING: The file '+filename+" no longer exists! Cannot parse it."
		message,/info, "WARNING: Any attempt to access the parsed results will have undefined behavior."
		status = -1
		return
	endif

  ;initialize just in case there is no present before scanning
  Self.DRFName=''

	catch, parse_error
	if parse_error eq 0 then Self -> IDLffXMLSAX::ParseFile, FileName

	; Now use the ConfigParser's translation table to look up the IDL commands.
	; By default, assume the module names *are* the IDL commands
	if parse_error or ~ptr_valid(self.modules) then begin
		message,"Some sort of fatal error has occured while parsing the DRF "+filename+":",/info
		message,/info,!error_state.msg
		status = -1
		return

	endif

	(*self.modules).idlcommand=(*self.modules).name
	; but for each module, check to see if there's a match in the lookup table
	for i=0L,n_elements(*self.modules)-1 do begin
		cmd = ConfigParser->GetIDLCommand((*self.modules)[i].Name, matched=matched)
		if matched eq 0 then begin
			message,/info, "No match found for "+(*self.modules)[i].Name+"; using that as the IDL command directly."
			cmd = (*self.modules)[i].Name 
		endif
		(*self.modules)[i].IDLCommand = cmd

	endfor 

	status = 1 ; completed OK!
	; If we are running in one of the GUI modes, hand the data back to the GUI.
	;if obj_valid(gui_obj) then $
	;gui_obj->set_from_parsed_DRF, (*self.data).filenames, (*self.modules), (*self.data).inputdir, (self.reductiontype)

  IF self->do_continueAfterDRFParsing()  EQ 1 THEN BEGIN
  	; pass the updates back up to the backbone
    Backbone.LogPath = Self.LogPath
    Backbone.ReductionType = Self.ReductionType
    Backbone.Data = Self.Data
    Backbone.Modules = Self.Modules
;    IF PTR_VALID(Self.UpdateLists) THEN BEGIN
;      FOR i = 0, N_ELEMENTS(*Self.UpdateLists)-1 DO BEGIN
;        PTR_FREE, (*Self.UpdateLists)[i].parameters
;      ENDFOR
;    ENDIF
;    PTR_FREE, Self.UpdateLists
;

  ENDIF 
  ; MDP change: don't delete things here! This lets us
  ; still access these *after* the parsing is done. 
  ; Used in DRFGUI etc.
  ;
  ; The cleanup will happen in Cleanup when the object is 
  ; destroyed, anyway. 
  ;
;  ELSE BEGIN  ; Cleanup everything and return from parsing.
;    IF PTR_VALID(Self.UpdateLists) THEN BEGIN
;      FOR i = 0, N_ELEMENTS(*Self.UpdateLists)-1 DO BEGIN
;        PTR_FREE, (*Self.UpdateLists)[i].parameters
;      ENDFOR
;    ENDIF
;
;    IF PTR_VALID(Self.Data) THEN BEGIN
;      FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
;        PTR_FREE, (*Self.Data)[i].QualFrames[*]
;        PTR_FREE, (*Self.Data)[i].UncertFrames[*]
;        PTR_FREE, (*Self.Data)[i].Headers[*]
;        PTR_FREE, (*Self.Data)[i].Frames[*]
;      ENDFOR
;    ENDIF
;
;    PTR_FREE, Self.UpdateLists
;    PTR_FREE, Self.Modules
;    PTR_FREE, Self.Data
;  ENDELSE
;
END

;------------------------------------------------------------
; return a brief summary of the DRF element in a given file. 
; This is used by the Template scanning functions in DRFGUI.
function gpidrfparser::get_summary


	return, {filename: self.most_recent_filename, type: self.ReductionType, name: self.DRFname}

end

;------------------------------------------------------------
;
;

PRO gpidrfparser::error, SystemID, LineNumber, ColumnNumber, Message
  ;COMMON APP_CONSTANTS

  ; Any error parsing the input file is too much error for you.

  ; Log the error info
  self->Log, 'DRP parsing non-fatal error', /GENERAL, DEPTH=1
  self->Log, '    Filename: ' + SystemID, /GENERAL, DEPTH=2
  self->Log, '  LineNumber: ' + STRTRIM(STRING(LineNumber),2), /GENERAL, DEPTH=2
  self->Log, 'ColumnNumber: ' + STRTRIM(STRING(ColumnNumber),2), /GENERAL, DEPTH=2
  self->Log, '     Message: ' + Message, /GENERAL, DEPTH=2

	;pipelineConfig.continueAfterDRFParsing = 0
END

;------------------------------------------------------------
;
;


PRO gpidrfparser::fatalerror, SystemID, LineNumber, ColumnNumber, Message
  ;COMMON APP_CONSTANTS

  ; Any fatal error parsing the input file is certainly too much error for you.

  ; Log the error info
  self->Log, 'DRP parsing fatal error', /GENERAL, DEPTH=1
  self->Log, '    Filename: ' + SystemID, /GENERAL, DEPTH=2
  self->Log, '  LineNumber: ' + STRTRIM(STRING(LineNumber),2), /GENERAL, DEPTH=2
  self->Log, 'ColumnNumber: ' + STRTRIM(STRING(ColumnNumber),2), /GENERAL, DEPTH=2
  self->Log, '     Message: ' + Message, /GENERAL, DEPTH=2

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
	;COMMON APP_CONSTANTS

	Self.Data = PTR_NEW(/ALLOCATE_HEAP)
	Self.Modules = PTR_NEW(/ALLOCATE_HEAP)
	Self.UpdateLists = PTR_NEW(/ALLOCATE_HEAP)

	; ----------------- TO DO: Validate the document ----------------------------
	self->Log, 'DRF file is currently unvalidated and is assumed to be valid', /GENERAL, DEPTH=1

END

;-----------------------------------------------------------------------------------------------------
; Procedure EndDocument
;
; DESCRIPTION:
; 	This procedure is inherited from the IDLffxMLSAX parent class.  EndDocument is
;	called automatically when the parser finishes parsing an XML document.  We use
;	this routine to update any selected frame headers from the UpdateLists, if any
;	exist.  NOTE: There is a DataSetNumber parameter that is required in an UpdateList
;	but in general, for data management reasons, DRFs do not have multiple datasets.
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO gpidrfparser::enddocument


	; Correct reference for the array of pointers to Headers is (*(Self.Data)[i]).Headers where
	; i is the index of the DataSet in the (possible) list of datasets, e.g.,
	;HELP, (*(Self.Data)[0]).Headers, /FULL
	; Correct reference for a single Header is *(*(Self.Data)[n]).Headers[i] which dereferences
	; pointer i (which may be 0 to (MAXFRAMESINDATASETS-1)) in the Nth array of Header pointers, e.g.,
	;PRINT, *(*(Self.Data)[0]).Headers[1]

	;FOR i = 0, DataSet.ValidFrameCount-1 DO BEGIN
	;	PRINT, (*(*Self.Data)[0]).Headers[i]
	;ENDFOR

	; Correct reference for DataSet attribute is (*Self.Data)[i].<attribute>, e.g.,
	;PRINT, "(*Self.Data)[0].ValidFrameCount = ", (*Self.Data)[0].ValidFrameCount

	nUpdateLists = N_ELEMENTS(*Self.UpdateLists)

	; For every defined UpdateList, fix the Header arrays indicated by the datasetNumber and
	; headerNumber parameters.  An attribute value of -1 indicates that all available arrays
	; either datasets and/or headers are to be updated.
	FOR indexUpdateLists = 0, nUpdateLists-1 DO BEGIN
		; Get attributes for the current UpdateList
		datasetNumber = (*Self.UpdateLists)[indexUpdateLists].datasetNumber
		headerNumber = (*Self.UpdateLists)[indexUpdateLists].headerNumber
		; Derive start and stop dataset numbers from the attributes
		IF datasetNumber LT 0 THEN BEGIN	; Actually, should be -1
			; Do all datasets
			startDataset = 0
			stopDataset = N_ELEMENTS(*Self.Data) - 1
		ENDIF ELSE BEGIN
			startDataset = datasetNumber
			stopDataset = datasetNumber
		ENDELSE
		FOR indexDataSet = startDataset, stopDataset DO BEGIN	; For all datasets
			; Derive start and stop header numbers from the attributes
			IF headerNumber LT 0 THEN BEGIN		; Actually, should be -1
				; Do all headers
				startHeader = 0
				stopHeader = (*Self.Data)[indexDataSet].ValidFrameCount - 1
			ENDIF ELSE BEGIN
				startHeader = headerNumber
				stopHeader = headerNumber
			ENDELSE
			FOR indexHeader = startHeader, stopHeader DO BEGIN	; For all headers
				;PRINT, "DataSet Number ", indexDataSet
				;PRINT, "Header  Number ", indexHeader
				; Correct reference for UpdateList attribute is (*Self.UpdateLists)[i].<attribute>, e.g.,
				;PRINT, (*Self.UpdateLists)[i].datasetNumber
				;PRINT, (*Self.UpdateLists)[i].headerNumber
				; Correct reference for an UpdateList parameter array is *(*Self.UpdateLists)[i].parameters, e.g.,
				;IF N_ELEMENTS(*(*Self.UpdateLists)[indexUpdateLists].parameters) GT 0 THEN BEGIN
				;	PRINT, *(*Self.UpdateLists)[indexUpdateLists].parameters
				;ENDIF
				; All parameters must be of correct type for call to program unit sxaddpar
				; Valid types are integer, float, double and string.  If type is string and
				; the value is 'T' or 'F' (upper or lower case) then the value is stored as
				; a logical.
				IF N_ELEMENTS(*(*Self.UpdateLists)[indexUpdateLists].parameters) GT 0 THEN BEGIN
          maxIndex = (SIZE(*(*Self.UpdateLists)[indexUpdateLists].parameters, /N_ELEMENTS)/4)-1
					FOR indexParameter = 0, maxIndex DO BEGIN	; For all parameters
						;PRINT, "indexParameter = ", indexParameter
						name    = (*(*Self.UpdateLists)[indexUpdateLists].parameters)[0, indexParameter]
						value   = (*(*Self.UpdateLists)[indexUpdateLists].parameters)[1, indexParameter]
						comment = (*(*Self.UpdateLists)[indexUpdateLists].parameters)[2, indexParameter]
						vtype   = (*(*Self.UpdateLists)[indexUpdateLists].parameters)[3, indexParameter]
						;PRINT, name + " " + value + " " + comment + " " + vtype
						; Set the value type correctly with a cast
						CASE vtype OF
							'integer':	value = FIX(value)
							'float':	value = FLOAT(value)
							'double':	value = DOUBLE(value)
							ELSE:
						ENDCASE
						;HELP, *(*Self.Data)[indexDataSet].Headers[indexHeader]
						SXADDPAR, *(*Self.Data)[indexDataSet].HeadersPHU[indexHeader], name, value, comment, BEFORE='COMMENT'
					ENDFOR
				ENDIF
			ENDFOR
		ENDFOR
	ENDFOR

  ; Now place a copy of the current DRF into each available header
  ; First, get the file name of the file we are parsing
  Self -> IDLffXMLSAX::GetProperty, FILENAME=myOwnFileName

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


  ; Get the number of datasets to do
	startDataset = 0
	stopDataset = N_ELEMENTS(*Self.Data) - 1
  ; Get the number of headers to do
	FOR indexDataSet = startDataset, stopDataset DO BEGIN	; For all datasets
    ; Get the number of headers to do
    startHeader = 0
    stopHeader = (*Self.Data)[indexDataSet].ValidFrameCount - 1
    FOR indexHeader = startHeader, stopHeader DO BEGIN	; For all headers
      SXADDPAR, *(*Self.Data)[indexDataSet].HeadersPHU[indexHeader], 'COMMENT', '////////////////////////////////////////////////////////////////////////'
      ; Save the file name as one or more comments
      ; Figure out how many 68 character strings there are in the file name string
      clen = STRLEN(myOwnFileName)
      n = (clen/68) + 1
      FOR j=0, n-1 DO BEGIN
        newsubstring = STRMID(myOwnFileName, j*68, 68)
        SXADDPAR, *(*Self.Data)[indexDataSet].HeadersPHU[indexHeader], 'COMMENT', 'DRFN' + newsubstring
      ENDFOR
      FOR i=0, N_ELEMENTS(fileAsStringArray)-1 DO BEGIN
        IF STRLEN(fileAsStringArray[i]) LT 68 THEN BEGIN
          SXADDPAR, *(*Self.Data)[indexDataSet].HeadersPHU[indexHeader], 'COMMENT', 'DRF ' + fileAsStringArray[i]
        ENDIF ELSE BEGIN
          ; Figure out how many 68 character strings there are in the current string
          clen = STRLEN(fileAsStringArray[i])
          n = (clen/68) + 1
          FOR j=0, n-1 DO BEGIN
            newsubstring = STRMID(fileAsStringArray[i], j*68, 68)
            SXADDPAR, *(*Self.Data)[indexDataSet].HeadersPHU[indexHeader], 'COMMENT', 'DRFC' + newsubstring
          ENDFOR
        ENDELSE
      ENDFOR

	  if obj_valid(self.backbone) then if keyword_set(var_record) then begin	; record environment variables into header
		  for j=0L,n_elements(var_record)-1 do SXADDPAR,  *(*Self.Data)[indexDataSet].HeadersPHU[indexHeader], 'COMMENT', 'DRFV'+ var_record[j]
	  endif

      SXADDPAR, *(*Self.Data)[indexDataSet].HeadersPHU[indexHeader], 'COMMENT', '\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\'
    ENDFOR
  ENDFOR


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

	;COMMON APP_CONSTANTS


	CASE strupcase(qName) OF
		'DRF': BEGIN
			; This FOR statement allows the attributes to be in any order in the XML file
			FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values in the
				CASE strupcase(AttNames[i]) OF			; variable fields.
					'LOGPATH':	        Self.LogPath = AttValues[i]
					'REDUCTIONTYPE':   	Self.ReductionType = AttValues[i]
					'MODULENAMEFORMAT': Self.DRFFormat= AttValues[i]
					'NAME':			    Self.DRFName = AttValues[i]
					ELSE:
				ENDCASE
			END
		END
		'DATASET': Self -> NewDataSet, AttNames, AttValues	; Add a new data set
		'FITS':	BEGIN
			N = N_ELEMENTS(*Self.Data) - 1
			DataFileName = ''
     		; FileControl = READWHOLEFRAME
			FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values in the
				CASE strupcase(AttNames[i]) OF			; variable fields.
					'FILENAME':	   DataFileName = AttValues[i]
					; FileControl is an OSIRIS pipeline option for only reading in a specific one
					; of the multiple FITS extensions. Probably do not use for GPI
					'FILECONTROL': FileControl = FIX(AttValues[i])  ; Overwrite the default if alternative is provided
					ELSE: self->Log, 'Error in gpiDRFParser::StartElement - Illegal/Unnecessary attribute ' + AttNames[i], /GENERAL, Depth=1
				ENDCASE
			END
			IF DataFileName NE '' THEN BEGIN
			; TODO: Read in files here? For now just parse the XML.
				full_input_filename = gpi_expand_path((*self.data).inputdir + path_sep() + DataFileName)
				if obj_valid(self.backbone) then begin
					;self->drpFITSToDataSet, (*Self.Data)[N], (*Self.Data)[N].ValidFrameCount, DataFileName
					(*self.data).Frames[(*self.data).ValidFrameCount] = ptr_new( full_input_filename )
					if ~(keyword_set(self.silent)) then PRINT, FORMAT='(".",$)'
				endif


				IF (self->do_continueAfterDRFParsing() EQ 1) or ~obj_valid(self.backbone)  THEN BEGIN
					; FIXME check the file exists and is a valid GPI fits file 

					if not file_test(full_input_filename,/read) then begin
						  self->Log, 'ERROR: The file "'+ full_input_filename+'" does not appear to exist on disk. Skipping this file and trying to continue anyway...', /GENERAL, DEPTH=2
					endif else begin


	        	    fits_info, full_input_filename, n_ext = numext, /silent
	            	validtelescop=self->validkeyword( full_input_filename, 1,'TELESCOP','Gemini')
		            validinstrum= self->validkeyword( full_input_filename, 1,'INSTRUME','GPI')
		            validinstrsub=self->validkeyword( full_input_filename, 1,'INSTRSUB','IFS') 
		            if (validtelescop* validinstrum*validinstrsub eq 1) then begin   
		              (*Self.Data)[N].Filenames[(*Self.Data)[N].ValidFrameCount] = DataFileName
		              (*Self.Data)[N].ValidFrameCount = (*Self.Data)[N].ValidFrameCount + 1
		              self->Log, DataFileName +' is a valid GEMINI-GPI-IFS image.', /GENERAL, DEPTH=2
		            endif else begin
		              self->Log, 'ERROR:'+ DataFileName +' is NOT a GEMINI-GPI-IFS image. File ignored!', /GENERAL, DEPTH=2
		            endelse
		          endelse
    				 
				ENDIF
			ENDIF ELSE BEGIN
				self->Log, 'ERROR: <fits/> element is incomplete, Probably no filename', /GENERAL, DEPTH=2
				;stop
   			    ;pipelineconfig.continueAfterDRFParsing = 0
			ENDELSE
		END
		'MODULE': Self -> NewModule, AttNames, AttValues	; Add a new module
		'UPDATE': BEGIN
			Self -> NewUpdateList, AttNames, AttValues	; Start a new update list
		END
		'UPDATEPARAMETER':  BEGIN
			Self -> AddUpdateParameter, AttNames, AttValues	; Add parms to latest list
		END
	ENDCASE


END

FUNCTION gpidrfparser::datasetnameisunique, Name
  if N_ELEMENTS(*Self.Data) EQ 0 THEN RETURN, 1
	FOR i = 0, N_ELEMENTS(*Self.Data)-1 DO BEGIN
    IF Name EQ (*Self.Data)[i].Name THEN RETURN, 0  ; We found a duplicate
  ENDFOR
  RETURN, 1
END

;-----------------------------------------
; Verify a keyword is present? 
; Given a list of filenames and keywords,
; Check that values are present for all of them.
function gpidrfparser::validkeyword, file, cindex, keyw, requiredvalue,needalertdialog=needalertdialog
    value=strarr(cindex)
    matchedvalue=intarr(cindex)
    ok=1
	for i=0, cindex-1 do begin
		;fits_info, file[i],/silent, N_ext 
	    catch, Error_status
	    if strmatch(!ERROR_STATE.MSG, '*Unit: 101*'+file[i]) then wait,1

	    fits_info, file[i], n_ext=next, /silent
      	if next eq 0 then begin
  			head=headfits( file[i]) ;will scan PHU
  		  	value[i]=strcompress(sxpar( Head, keyw,  COUNT=cc),/rem)
		endif else begin
		    head=headfits( file[i], exten=0) ;First try PHU
        	value[i]=strcompress(sxpar( Head, keyw,  COUNT=cc),/rem)
        	if cc eq 0 then begin
        		headext=headfits( file[i], exten=1) ;else try extension header
	        	value[i]=strcompress(sxpar( Headext, keyw,  COUNT=cc),/rem)
    	    endif  
		endelse

		if cc eq 0 then begin
			self->log,'Absent '+keyw+' keyword for data: '+file(i)
			ok=0
		endif
		if cc eq 1 then begin
			matchedvalue=stregex(value[i],requiredvalue,/boolean,/fold_case)
			if matchedvalue ne 1 then begin 
			  self->log,'Invalid '+keyw+' keyword for data: '+file(i)
			  self->log,keyw+' keyword found: '+value(i)
			  if keyword_set(needalertdialog) then void=dialog_message('Invalid '+keyw+' keyword for data: '+file(i)+' keyword found: '+value(i))
			  ok=0
			endif
		endif
		  ;if ok ne 1 then self->log, 'File '+file[i]+' is missing required '+keyw+' keyword!'
	endfor  
 
      
  return, ok
end

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

	;COMMON APP_CONSTANTS
    ;MAXFRAMESINDATASETS =150;pipelineConfig.MAXFRAMESINDATASETS
	DataSet = {structDataSet}			; Create a new structDataSet variable

	MAXFRAMESINDATASETS = n_elements(DataSet.Frames)
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
		'Name': BEGIN
			IF Self -> DataSetNameIsUnique(AttValues[i]) THEN BEGIN
			  DataSet.Name = AttValues[i]
			ENDIF ELSE BEGIN
				self->Log, 'DataSet Name ' + AttValues[i] + ' attribute is duplicated.', /GENERAL, DEPTH=2
				self->Log, 'DRF will be aborted', /GENERAL, DEPTH = 2
				continueAfterDRFParsing = 0
			ENDELSE
	    END
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

	;COMMON APP_CONSTANTS


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

	IF N_ELEMENTS(*Self.Modules) EQ 0 THEN *Self.Modules = [Module] $	; Add to the array
	ELSE *Self.Modules = struct_merge(*Self.Modules, Module)

    if ~(keyword_set(self.silent)) then 	print,module.name



END


;-----------------------------------------------------------------------------------------------------
; Procedure Log
;
; DESCRIPTION:
; 	Pass a log message back up to the parent backbone object
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
		message,"Log facility not available!",/info
		message, "Can't log: "+text
	endelse

end




;-----------------------------------------------------------------------------------------------------
; Procedure getParameters
;
; DESCRIPTION:
; 	This procedure receives a reference to a backbone object
;	and transfers the configuration parameter information to
;	the backbone ParmList.
;
; ARGUMENTS:
;	Backbone	The backbone object to be updated
;
; KEYWORDS:
;	Inherited from parent class.  See documentation.
;-----------------------------------------------------------------------------------------------------
PRO gpidrfparser::getparameters, Backbone


	Backbone.ParmList = Self.Parms


END


PRO gpidrfparser::printinfo


;	drpIOLock
	OPENW, unit, "temp.tmp", /get_lun
	FOR j = 0, N_ELEMENTS(*Self.Modules)/3-1 DO BEGIN
		PRINTF, unit, (*Self.Modules)[0, j] , "  ", (*Self.Modules)[1, j], "  ", (*Self.Modules)[2,j]
	ENDFOR

	FOR j = 0, 31 DO BEGIN
		PRINTF, unit, PARAMETERS[j, 0] , "  ", PARAMETERS[j, 1]
	ENDFOR
	FLUSH, unit
	CLOSE, unit
	FREE_LUN, unit
;	drpIOUnlock


END




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
			LogPath:'', $
			ReductionType:'', $  ; CAL, ASTR, SPECTRAL, POL, etc
			DRFFormat:'', $  ; can be null for basic format or string "Long Description" for long format
			DRFName: '', $   ; a descriptive name for the DRF. Used by Template DRFs.
			most_recent_filename: '', $ ; remember this for get_summary
			no_log: 0, $     ; flag for not logging actions if ran in some other mode
			silent: 0, $	 ; suppress printed output?
			Data:PTR_NEW(), $
			Modules:PTR_NEW(), $
			UpdateLists:PTR_NEW(), $
			backbone: obj_new() }

END



