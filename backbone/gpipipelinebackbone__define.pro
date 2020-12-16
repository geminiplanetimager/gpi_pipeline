;-----------------------------------------------------------------------------------------------------
; Procedure gpiPipelineBackbone__define
;
; DESCRIPTION:
;     DRP Backbone: the main object that oversees and conducts pipeline execution
;
;  Modified:
;    2009-02-01    Split from OSIRIS' drpBackbone__define and heavily trimmed
;                     by Marshall Perrin
;    2009-08 minor changes in Reduce function - JM 
;    2009-10-05 added ReduceOnLine function - JM
;    2010-08-19 JM memory bug corrected (image pointer created even if already exist)
;    ...See changelog in svn in preference to here...
;
;-----------------------------------------------------------------------------------------------------


;+-----------------------------------------------------------
; gpiPipelineBackbone::AboutMessage
;		Utility function to print the about pipeline message
;
;------------------------------------------------------------

pro gpipipelinebackbone::aboutmessage
    ver = gpi_pipeline_version()
	nspaces = 30 - strlen(ver)
	spaces = strmid('                            ',0,nspaces) ; is there a better way to do this?

    print, "                                                         "
    PRINT, "     *****************************************************"
    print, "     *                                                   *"
    PRINT, "     *          GPI DATA REDUCTION PIPELINE              *"
    print, "     *                                                   *"
    print, "     *             VERSION "+ver+spaces+"*"
    print, "     *                                                   *"
    print, "     *         By the GPI Data Analysis Team             *"
    print, "     *                                                   *"
    print, "     *   Perrin, Maire, Ingraham, Savransky, De Rosa     *"
    print, "     *   Doyon, Chilcote, Draper, Fitzgerald, Greenbaum  *"
    print, "     *   Hibon, Konopacky, Long, Marois, Marchis         *"
    print, "     *   Millar-Blanchaer, Nielsen, Pueyo,               *"
    print, "     *   Ruffio, Sadakuni, Wang, Wolff, & Wiktorowicz    *"
    print, "     *                                                   *"
    print, "     *      For documentation & full credits, see        *"
    print, "     *      http://docs.planetimager.org/pipeline/       *"
    print, "     *                                                   *"
    print, "     *****************************************************"
    print, "                                                         "

end

;+-----------------------------------------------------------
; gpiPipelineBackbone::Init
;
;    Initialize backbone: Create internal data stores and objects,
;    Open log files, optionally rescan calDB & config files
;-_


FUNCTION gpipipelinebackbone::Init,  session=session, verbose=verbose, nogui=nogui
    ; Application constants
    COMMON APP_CONSTANTS, $
        ;LOG_GENERAL,  $       	 ; File unit number of the general log file
        OK, NOT_OK, ERR_UNKNOWN, GOTO_NEXT_FILE,        $        ; Indicates success
        backbone_comm, $         ; Object pointer for main backbone (for access in subroutines & primitives) 
        loadedcalfiles, $        ; object holding loaded calibration files (as pointers)
        DEBUG                    ; is DEBUG mode enabled?
    

	DEBUG= gpi_get_setting('enable_primitive_debug',default=0,/silent)

	;LOG_GENERAL = 1       ; LUNs for logfiles
	self.LOG_GENERAL = 1
	OK = 0
	NOT_OK = -1
	ERR_UNKNOWN = -3
	GOTO_NEXT_FILE = -2


	; Set up a configuration structure for additional pipeline internals
	pipelineConfig = {$
		logdir : gpi_get_directory("GPI_DRP_LOG_DIR"),     $ ; directory for output log files
		continueAfterRecipeXMLParsing:0,        $    				; Should program actually run the pipeline or just parse?
		MaxFramesInDataSets: gpi_get_setting('max_files_per_recipe', default=1000, /silent)        $    ; Max # of files in one dataset in a Recipe XML file
		;MaxMemoryUsage: 0L,                 $   			; this will eventually be used for array size limits on what gets done in memory versus swapped to disk.
		;desired_dispersion: 'vertical' $					; do we want horizontal or vertical spectra?
	}
	self.pipelineconfig=ptr_new(pipelineConfig)
	self.nogui = keyword_set(nogui)	 						; disable GUI windows when running over an ssh link without X11?
	self.verbose = keyword_set(verbose)						; Enable extra verbosity in some logging

	self->AboutMessage

    !quiet=0 ; always print out any output from "message" command, etc.

	config_file=gpi_get_directory('GPI_DRP_CONFIG_DIR') +path_sep()+"gpi_pipeline_primitives.xml"

    error=0
    ;CATCH, Error       ; Catch errors before the pipeline
    IF Error EQ 0 THEN BEGIN
        Self->OpenLog
        self->Log, 'Backbone Initialized'

        self->DefineStructs        ; Define the DRP structures

        Self.Parser = OBJ_NEW('gpiDRFParser', backbone=self) ; Init DRF parser

        ; Read in the XML Config File with the primitive name translations.
        Self.ConfigParser = OBJ_NEW('gpiDRSConfigParser',verbose=self.verbose)
        if file_test(config_file) then  Self.ConfigParser -> ParseFile, config_file

        self.GPICalDB = obj_new('gpicaldatabase', backbone=self)

		if ~(keyword_set(self.nogui)) then begin
			self->SetupStatusConsole
			self.statuswindow->display_log,"* GPI DATA REDUCTION PIPELINE  *"
			self.statuswindow->display_log,"* VERSION "+gpi_pipeline_version()+"  *"
			self.statuswindow->set_calibdir, self.GPICalDB->get_calibdir()
		endif
    
        self.launcher = obj_new('launcher',/pipeline)
        
        ; This is stored in a common block variable so that it is accessible
        ; inside the Save_currdata function (which otherwise does not have
        ; access to the backbone object). Yes, this is inelegant and ought to
        ; be fixed probably. - MP

        backbone_comm = self ; stick into common block for global access

        loadedcalfiles = obj_new('gpiloadedcalfiles') ; in common block for access inside the primitives


		if gpi_get_setting('force_rescan_config_on_startup',default=0,/silent) then begin
            self->rescan_Config
		endif
		if gpi_get_setting('force_rescan_caldb_on_startup',default=0,/silent) then begin
            self->rescan_CalDB
		endif



    ENDIF ELSE BEGIN
        Self -> ErrorHandler
        CLOSE, self.LOG_GENERAL
        FREE_LUN, self.LOG_GENERAL
    ENDELSE


    return ,1 ; valid object created 

END

;+---------------------------------------------------------
; gpiPipelineBackbone::free_dataset_pointers
;    free all pointers from the dataset.
;-

pro gpiPipelineBackbone::free_dataset_pointers
    IF PTR_VALID(Self.Data) THEN $
        FOR i = 0, N_ELEMENTS(*Self.Data)-1 DO BEGIN
            PTR_FREE, (*Self.Data)[i].Frames[*]
            PTR_FREE, (*Self.Data)[i].HeadersPHU[*]
            PTR_FREE, (*Self.Data)[i].HeadersExt[*]
            PTR_FREE, (*Self.Data)[i].UncertFrames[*]
            PTR_FREE, (*Self.Data)[i].QualFrames[*]
        END
	heap_gc ; for good measure
end



;+-----------------------------------------------------------
; gpiPipelineBackbone::Cleanup
;    Cleanup routine for object destruction
;    Free allocated memory and close log files
;-

PRO gpiPipelineBackbone::Cleanup
    COMMON APP_CONSTANTS

    OBJ_DESTROY, Self.Parser
    OBJ_DESTROY, Self.ConfigParser
    OBJ_DESTROY, self.statuswindow

	if obj_valid(self.launcher) then begin
		; Let's no longer automatically shutdown the GUIs session. 
		; Requested by users to keep the other session up.
		; See issue https://rm.planetimager.org/issues/453
		;    self.launcher->queue, 'quit' ; kill the other side of the link, too
        obj_destroy, self.launcher ; kill this side.
    endif

	self->free_dataset_pointers
    PTR_FREE, Self.Data
    PTR_FREE, Self.Primitives

    if keyword_set(self.LOG_GENERAL) then begin
        CLOSE, self.LOG_GENERAL
        FREE_LUN, self.LOG_GENERAL
    endif

END


;+-----------------------------------------------------------------------------------------------------
; gpiPipelineBackbone::DefineStructs
;    defines some named data structures used by the pipeline
;-
; HISTORY:
;     Lifted from OSIRIS code.
;     Definitions moved to separate routines; MDP 2010-04-15
;
PRO gpipipelinebackbone::DefineStructs

    COMMON APP_CONSTANTS

    ; Dataset structure containing the specified input files
    ;   both filenames and data.
    void = {structDataSet}

    ; Primitive (formerly "module" in the OSIRIS pipeline)
    void = {structModule}

    ; Queue for DRF XML files on disk
    void = {structQueueEntry, $
            index:'', $
            name:'', $
            status: '', $
            error:''}


END


 
;+ -----------------------------------------------------------
; gpiPipelineBackbone::GetNextRecipe
;    Looks in the queue dir for any *.waiting.xml files.
;	 If one or more are found, return the first one alphabetically
;	 If none are found, return ""
;-
function gpiPipelineBackbone::GetNextRecipe, queuedir, found=count

    queueDirName = QueueDir + '*.waiting.xml'
    FileNameArray = FILE_SEARCH(queueDirName, count=count)
    if count gt 0 then begin
        self->Log, "Found "+strc(count)+" XML files in the queue"
        queue = REPLICATE({structQueueEntry}, count)
        queue.name = filenamearray
        for i=0L, count-1 do begin
            queue[i] = self->Recipe2Struct(filenamearray[i])
        endfor
        ; sort here? This lets you set the order of multiple files if you drop
        ; them at once.
        queue = queue[sort(queue.index)]
        return, queue[0] ; can only handle one at a time now
    endif
    return, ""

end

;+ -----------------------------------------------------------
; gpiPipelineBackbone::Recipe2Struct
;    given a recipe filename, return a structQueueEntry
; 	 for that recipe
;-
function gpiPipelineBackbone::Recipe2Struct, filename
    s = {structQueueEntry}
    parts = stregex(file_basename(filename), "(.*)\.(.*)\.xml",/extrac,/sub)
	;parts = stregex(filenamearray, ".+"+path_sep()+"(.*)\.(.*)\.xml",/extrac,/sub) ;linux?
	s.name = filename
	s.index=parts[1]
	s.status=parts[2]
	print, s.index, s.status, s.name, format='(A40, A20, A80)'
	return,s
end

;+ -----------------------------------------------------------
; gpiPipelineBackbone::SetRecipeQueueStatus
;
;    Update the status of a given file
;    by renaming the DRF xml file appropriately
;-
PRO gpiPipelineBackbone::SetRecipeQueueStatus, drfstruct, newstatus

    oldfilename = drfstruct.name
	; issue that if drfstruct.status is not set the expression is not parsed correctly
	; this is primarily an issue only in single recipe mode
    if drfstruct.status ne '' then filebase = stregex(oldfilename, "(.+)\."+drfstruct.status+".xml",/extract,/subexpr)$
			else  filebase=stregex(oldfilename, "(.+)\.xml",/extract,/subexpr) 
    newfilename = filebase[1]+"."+newstatus+".xml"

    ; TODO debugging / error checking on the file move?
    file_move, oldfilename, newfilename,/overwrite
	; check to see if file has been written
	if file_test(newfilename) eq 0 then wait,0.1

	drfstruct.status=newstatus
    drfstruct.name = newfilename


	if obj_valid(self.statuswindow) then begin
		; display status in the console window
		self.statuswindow->set_status, newstatus
		; if this is a new file (newstatus is working) then append this to the DRF
		; log in the progressbar
		; otherwise just update the latest entry in the DRF log in progressbar 
		self.statuswindow->display_recipe_log, newfilename, replace=(newstatus ne "working")
	endif

end

;+ -----------------------------------------------------------
; gpiPipelineBackbone::Flush_Queue
;
;   Clear all queue contents, and delete any recipe files present in the queue directory 
;   (dangerous, mostly for debugging use!)
;-

PRO gpiPipelineBackbone::flushqueue, QueueDir


    COMMON APP_CONSTANTS
    if strmid(queuedir, strlen(queuedir)-1,1) ne path_sep() then queuedir+=path_sep() ; append slash if needed

	message,/info, 'Clearing all Recipes from the Queue - this cannot be undone!'
	
    CurrentRecipe = self->GetNextRecipe(Queuedir, found=nfound)
	while (nfound ge 1) do begin
		print, "DELETING "+CurrentRecipe.name
		file_Delete, CurrentRecipe.name
    	CurrentRecipe = self->GetNextRecipe(Queuedir, found=nfound)
	endwhile


end

;+ -----------------------------------------------------------
; gpiPipelineBackbone::gpitv
;
;  Display a file in GPITV. Called from save_currdata in __end_primitive
;  Uses the launcher mechanism to communicate between IDL sessions
;
;-

PRO gpiPipelineBackbone::gpitv, filename_or_data, session=session, header=header, extheader=extheader, _extra=_extra

    if obj_valid(self.launcher) then begin

        if size(filename_or_data,/TNAME) ne 'STRING' then begin
            ; user provided an array - need to write it to a temp file on disk
			data = filename_or_data
            tmppath = getenv('IDL_TMPDIR')
			if file_test(tmppath, /write) then begin
				if strmid(tmppath, strlen(tmppath)-1) ne path_sep() then tmppath +=path_sep()  ; be careful if path sep char is on the end already or not
                if strmatch(!VERSION.OS_FAMILY , 'Windows',/fold) then begin
                    uid_str = strmid(getenv('USERNAME'),0,8) ; use username for windows
                endif else begin
                    spawn,'id -u',uid_str ; use uid for unix
                    uid_str = uid_str[0]
                endelse
                tempfile = tmppath+'temp-'+uid_str+'.fits'

				; check for the error case where some other user already owns
				; /tmp/temp.fits on a multiuser machine. If necessary, fall back to
				; another filename with an appended number. 
				;
				i=self.TempFileNumber
				i=(i+1) mod 100
				tempfile = tmppath+'temp-'+uid_str+'-'+strc(i)+'.fits'
		
				catch, gpitv_send_error
				if gpitv_send_error then begin
					; try the next filename, except if we are at 100 tries already then
					; give up 
					i=(i+1) mod 100
					tempfile = tmppath+'temp-'+uid_str+'-'+strc(i)+'.fits'
					if i eq self.TempFileNumber-1 or (self.TempFileNumber eq 0 and i eq 99) then begin
						self->Log, "Could not open **any** filename for writing in "+getenv('IDL_TMPDIR')+" after 100 attempts. Cannot send file to GPItv."
						stop
						return
					endif
				endif 

				FXADDPAR, header, 'NEXTEND', 1
				mwrfits, 0, tempfile, header, /create, /silent
				writefits, tempfile, data, extheader,/append

				self->Log, "Sending data to be displayed in GPITV via temp file= "+tempfile
				CATCH, /CANCEL
				self.TempFileNumber=i ; save last used temp file # for starting point next time this gets called
				self.launcher->queue, 'gpitv', filename=tempfile, session=session, _extra=_extra
			endif else begin
				self->Log, "User does not have permissions to write in the IDL temp file dir "+getenv('IDL_TMPDIR')+ ". Output data cannot be displayed in gpitv."
			endelse
        endif else begin
            self.launcher->queue, 'gpitv', filename=filename_or_data, session=session, _extra=_extra
        endelse

    endif 

end


;+ -----------------------------------------------------------
; gpiPipelineBackbone::Run_queue
;
;    Main pipeline processing routine!
;
;    Loop forever checking for new files in the queue directory.
;    When one is found, 
;        - parse it
;        - reduce it
;    Also check for user inputs and process those as well.
;
;-

PRO gpiPipelineBackbone::Run_queue, QueueDir

    COMMON APP_CONSTANTS
    ;  Poll the 'queue' directory continuously.  If a DRF is encountered, reduce it.
    DRPCONTINUE = 1  ; Start off with a continuous loop

    if strmid(queuedir, strlen(queuedir)-1,1) ne path_sep() then queuedir+=path_sep() ; append slash if needed

    self->log,"Now polling and waiting for Recipe files in "+queueDir,/flush

	; Figure out how fast to poll, with different cadences for GUI and disk access
	drp_disk_poll_freq = gpi_get_setting('drp_queue_poll_freq', /silent,default=1) ; poll for new files frequency in Hz
	drp_gui_poll_freq = gpi_get_setting('drp_gui_poll_freq', /silent,default=10) ; GUI events check frequency in Hz for status window

	disk_poll_wait_time = 1./drp_disk_poll_freq
	gui_wait_time = 1./drp_gui_poll_freq
	disk_to_gui_ratio =  fix(disk_poll_wait_time/gui_wait_time) > 1 ; check for disk actions at some multiple of the GUI check time step

	self->AboutMessage
    print, "    "
    print, "   Now polling for Recipe files in "+queueDir+" at "+strc(drp_disk_poll_freq) +" Hz"
    print, "    "
	

    WHILE DRPCONTINUE EQ 1 DO BEGIN

        if ~(keyword_set(DEBUG)) then CATCH, Error else ERROR=0    ; Catch errors inside the pipeline. In debug mode, just let the code crash and stop
        IF Error EQ 1 THEN BEGIN
            PRINT, "Calling Self -> ErrorHandler..."
            Self -> ErrorHandler, CurrentRecipe
        ENDIF

        CurrentRecipe = self->GetNextRecipe(Queuedir, found=nfound)
        IF nfound gt 0 THEN begin
            self->checkLogDate
            result = self->Run_One_Recipe(CurrentRecipe)
        endif

        ;wait, 1 ; Only check for new files at most once per second
        for iw = 0,disk_to_gui_ratio-1 do begin
			; break the wait up into smaller parts to allow event loop
			; handling

            wait, gui_wait_time

            if obj_valid(self.statuswindow) then begin
                self.statuswindow->checkEvents
                if self.statuswindow->checkQuit() then begin
                    message,/info, "User pressed QUIT on the progress bar!"
                    self->Log, "User pressed QUIT on the progress bar.  Exiting DRP."
                    ;stop
                    self.statuswindow->Quit
                     
                    obj_destroy,self
                    DRPCONTINUE=0
                    break
                    ;exit
                endif
                if self.statuswindow->flushqueue() then begin
		            self->log, '**User request**:  flushing the queue.'
					
					;; if any errors occur, make sure rescanning ends to prevent infintie loops
					catch, Error_status
					
					if Error_status ne 0 then begin
						message,/info, 'Error while clearing recipe queue: ' + !ERROR_STATE.MSG
						self->log, 'Error while clearing recipe queue: ' + !ERROR_STATE.MSG
						self.statuswindow->flushqueue_end
					endif else begin
						self->flushqueue, queuedir
						self.statuswindow->flushqueue_end
					endelse
					
					catch, /cancel
                endif    
                if self.statuswindow->rescandb() then begin
		            self->log, '**User request**:  Rescan Calibrations DB.'
					
					;; if any errors occur, make sure rescanning ends to prevent infintie loops
					catch, Error_status
					
					if Error_status ne 0 then begin
						message,/info, 'Error while rescanning CalDB: ' + !ERROR_STATE.MSG
						self->log, 'Error while rescanning CalDB: ' + !ERROR_STATE.MSG
						self.statuswindow->rescandb_end					
					endif else begin
						self->rescan_CalDB
						self.statuswindow->rescandb_end
					endelse
					
					catch, /cancel
                endif    
                if self.statuswindow->rescanConfig() then begin
		            self->log, '**User request**:  Rescan GPI data pipeline configuration.'
					
					;; if any errors occur, make sure rescanning ends to prevent infintie loops
					catch, Error_status
					
					if Error_status ne 0 then begin
						message,/info, 'Error while rescanning DRP Config: ' + !ERROR_STATE.MSG
						self->log, 'Error while rescanning DRP Config: ' + !ERROR_STATE.MSG
						self.statuswindow->rescanconfig_end					
					endif else begin
						self->rescan_Config
						self.statuswindow->rescanconfig_end
					endelse
					
					catch, /cancel
                endif    
 
            endif
        endfor
    ENDWHILE

END
;+ -----------------------------------------------------------
; gpiPipelineBackbone::Run_One_Recipe
;
; Handle a single recipe: 
;   - mark its status
;   - parse it
;   - run the primitives (in ::reduce)
;   - check the output
;
; This routine mostly handles the I/O for loading data, error checking, etc.
; The actual processing happens in the ::reduce method.
;
; Input:  CurrentRecipe, struct. a StructQueueEntry for the recipe to process
;-

function gpiPipelineBackbone::Run_One_Recipe, CurrentRecipe
    COMMON APP_CONSTANTS

	; if needed, convert from a filename string to an info structure
	if size(/tname, CurrentRecipe) ne 'STRUCT' then CurrentRecipe = self->Recipe2Struct(CurrentRecipe)

	self->Log, "------------------------------ Starting Recipe Processing ------------------------------"
	self->log, 'Reading file: ' + CurrentRecipe.name

	if obj_valid(self.statuswindow) then self.statuswindow->set_DRF, CurrentRecipe
	self->SetRecipeQueueStatus, CurrentRecipe, 'working'
	wait, 0.1   ; Wait 0.1 seconds to make sure file rename is fully completed.

	if ~(keyword_set(debug)) then CATCH, parserError else parserError=0 ; only catch if DEBUG is not set.
	message,/reset_error_state ; clear any prior errors before parsing
	IF parserError EQ 0 THEN BEGIN
		if obj_valid(self.statuswindow) then self.statuswindow->set_action, "Parsing Recipe"
		(*self.PipelineConfig).continueAfterRecipeXMLParsing = 1    ; Assume it will be Ok to continue

		Self.Parser = OBJ_NEW('gpiDRFParser', backbone=self)
		Self.Parser -> ParseFile, CurrentRecipe.name,  Self.ConfigParser, backbone=self, status=status
        if status ne OK then begin
			; technically it may have parsed, in the sense of reading the XML, but
			; there was something bogus about the file, like nonexistent data
			; So throw an error even though it's syntactically valid.
			parsererror =1
			!error_state.msg =  "ERROR in parsing the Recipe file "+CurrentRecipe.name
		endif else begin
	        self.Parser -> load_data_to_pipeline, backbone=self, status=status
			; this updates the self.Data and self.primitives structure
			; arrays in accordance with what is stated in the recipe

			if status ne OK then begin
				parsererror =1
				!error_state.msg =  "Could not load data files specified in recipe "+CurrentRecipe.name
			endif
		endelse
		CATCH, /CANCEL
	ENDIF

	if parserError NE 0 then  BEGIN
		; Call the local error handler
		Self -> ErrorHandler, CurrentRecipe
		; Destroy the current Recipe parser and punt the DRF
		OBJ_DESTROY, Self.Parser
		; Recreate a parser object for the next DRF in the pipeline
		(*self.PipelineConfig).continueAfterRecipeXMLParsing = 0

		; save the most recent error message to the log.
		Help, /Last_Message, Output=theErrorMessage
	    FOR j=0,N_Elements(theErrorMessage)-1 DO BEGIN
			self->log,theErrorMessage[j]
		ENDFOR

	    ; This code if continueAfterRecipeXMLParsing == 0
	    self->log, 'Reduction failed due to error in file ' + CurrentRecipe.name,/flush


	    self->SetRecipeQueueStatus, CurrentRecipe, 'failed'
	    self->free_dataset_pointers 		 ; If we failed with outstanding data, then clean it up.
		return, NOT_OK

	ENDIF

	;IF (*self.PipelineConfig).continueAfterRecipeXMLParsing EQ 1 THEN BEGIN

	if (*(self.data)).validframecount eq 0 then begin
		self->Log, 'ERROR: That Recipe was parsed OK, but it does not contain any data files.'
	    self->SetRecipeQueueStatus, CurrentRecipe, 'failed'
	    self->free_dataset_pointers 		 ; If we failed with outstanding data, then clean it up.
		result=NOT_OK
		return, NOT_OK
	endif

	Result = Self->Reduce() 

	IF Result EQ OK THEN BEGIN
		PRINT, "Success"
		self->SetRecipeQueueStatus, CurrentRecipe, 'done'
		self->Log, 'Done with '+CurrentRecipe.name+" : Success",/flush
		status_message = "Last recipe done OK! Watching for new recipes but idle."
	ENDIF ELSE BEGIN
		PRINT, "Failure"
		self->SetRecipeQueueStatus, CurrentRecipe, 'failed'
		self->Log, 'ERROR with '+CurrentRecipe.name+". Reduction failed.",/flush
		status_message = "Last Recipe **Failed**!    Watching for new recipes but idle."
	ENDELSE

	if obj_valid(self.statuswindow) then begin
		  self.statuswindow->set_status, status_message
		  self.statuswindow->Set_action, '--'
					  self.statuswindow->set_percent,0,0
	endif

	; Free any remaining memory here
	self->free_dataset_pointers


	return, OK

end

;+ -----------------------------------------------------------
; gpiPipelineBackbone::Reduce
;	 Reduce one recipe. 
;    Run the specified commands in sequence to reduce the data. 
;    This function has no explicit inputs; its assumes the necessary
;    data structures are already loaded by Run_one_recipe
;-


FUNCTION gpiPipelineBackbone::Reduce

    COMMON APP_CONSTANTS
    common PIP, $
		lambda0, $
		filename, $
		wavcal, $
		mlens_file,$		; microlens psf calibration variables
		mlens,$			;
		polcal, $
		tilt, $
		badpixmap, $
		filter, $
		dim, $
		CommonWavVect, $
		suffix, $
		header, $
		numfile, $		; index of current file in the dataset
		numext			; number of extensions in the current file

    PRINT, ''
    PRINT, SYSTIME(/UTC)
    PRINT, ''

    if ~(keyword_set(self.nogui)) then self->SetupStatusConsole

    ;#############################################################
    ; Iterate over the datasets in the 'Data' array and run the sequence of
	; primitives for each dataset.
    ;
    ; MDP note: The OSIRIS pipeline, on which this was based, had a vague notion
    ; of being able to operate on multiple datasets, each of which contained
    ; multiple files. This was never actually implemented. 
    ; For GPI, we declare that there can only be one dataset in a DRF, which
    ; can in turn contain some number of data files, which get stored in the
    ; 'frame' arrays etc. 
    self->Log, 'Reducing data set containing '+strc((*self.Data).validframecount)+" file(s).",  depth=0
	self.currentReductionLevel = 1 ; we always expect level 1 primitives first

    FOR IndexFrame = 0, (*self.Data).validframecount-1 DO BEGIN
        if debug ge 1 then print, "########### start of file "+strc(indexFrame+1)+" ################"
        self->Log, 'Reducing file: ' + (*self.Data).fileNames[IndexFrame], depth=1,/flush
        if obj_valid(self.statuswindow) then self.statuswindow->Set_FITS, (*self.Data).fileNames[IndexFrame], number=indexframe,nbtot=(*self.Data).validframecount

        numfile=IndexFrame ; store the index in the common block


        ;--- Read in the file 
        load_status = self->load_FITS_file(indexFrame)
        ; determine if the file was aborted mid exposure
        abort_flag=sxpar(*(*self.data).HeadersExt[IndexFrame],'ABORTED')
        if abort_flag eq 1 then begin
            self->Log, "ERROR: The following file was aborted during the exposure and should be removed from the dataset:"+strc(filename)
            return, NOT_OK
        endif

        if load_status eq NOT_OK then begin
            self->Log, "ERROR: Unable to load file "+strc(indexFrame)
            return, NOT_OK
        endif

        suffix=''

        ;-- Iterate over the primitives and run each.
        status = OK
        tmp = where((*self.primitives).skip eq 0,totmodstorun) ;;figure out exactly how many primitives are going to get executed
        FOR indexPrimitives = 0, N_ELEMENTS(*self.Primitives)-1 DO BEGIN
           ;; Continue if the current primitive's skip field equals 0 and no
		   ;; previous primitive has failed (Result = 1).
           IF ((*self.Primitives)[indexPrimitives].Skip EQ 0) AND (status EQ OK) THEN BEGIN
              if obj_valid(self.statuswindow) then self.statuswindow->Update, *self.Primitives, indexPrimitives, (*self.data).validframecount, IndexFrame,   ' Working...'
              status = Self -> RunModule(*self.Primitives, indexPrimitives)              
           ENDIF
           if obj_valid(self.statuswindow) then begin
              self.statuswindow->checkevents
              if self.statuswindow->checkabort() then begin
                 conf = dialog_message("Are you sure you want to abort the current recipe?",/question,title="Confirm abort",/default_no,/center)
                 if conf eq "Yes" then begin
                    self->Log, "User pressed ABORT button! Aborting Recipe",/flush
                    status = NOT_OK
                    break
                 endif else begin
                    self.statuswindow->clear_abort
                 endelse
              endif 
           endif 
        ENDFOR

        ;-- Log the result.
        if status eq GOTO_NEXT_FILE then self->Log, 'Continuing on to next file...', depth=2
        IF status EQ OK or status eq GOTO_NEXT_FILE THEN self->Log, 'Reduction successful: ' + filename, depth=2 $
        ELSE begin
            self->Log, 'Reduction failed: ' + filename, /flush
            break ; no sense continuing if one of the files has failed.
        endelse

        if debug ge 1 then print, "########### end of file "+strc(indexframe+1)+" ################"
    ENDFOR

    if (*self.Data).validframecount eq 0 then begin    
      if obj_valid(self.statuswindow) then self.statuswindow->Update, *self.Primitives,N_ELEMENTS(*self.Primitives)-1, (*self.data).validframecount, 1,' No file processed.'
      self->log, 'No file processed. ' 
      status=OK
    endif
    if status eq GOTO_NEXT_FILE then status = OK ; handle the corner case of a recipe ending with 'Accumulate Images' with nothing after it
    if status eq OK then self->Log, "Recipe Complete!",/flush

	self.currentReductionLevel = 0 ; not reducing anything now
    if debug ge 1 then print, "########### end of reduction for that recipe ################"
    PRINT, ''
    PRINT, CMSYSTIME(/ext)
    PRINT, ''
    if obj_valid(self.statuswindow) and ((*self.data).validframecount gt 0) then $
	    self.statuswindow->Update, *self.Primitives,indexPrimitives, (*self.data).validframecount, IndexFrame,' Done.'


    RETURN, status

END
;+ -----------------------------------------------------------
; gpiPipelineBackbone::Load_FITS_file
;
;    This routine loads an input file from disk, by calling
;    gpi_load_fits and storing the results in the appropriate 
;    pipeline data structures.
;
;    This also merges the recipe XML text into the header history for 
;    posterity.
;
;	 Note that gpi_load_fits can optionally perform preprocessing to
;	 update FITS keywords (See gpi_load_and_preprocess_fits_file ).
;	 This should not be needed on sky since it is mostly heritage of
;	 GPI development stages when keywords were not yet mature. 
;-

FUNCTION gpiPipelineBackbone::load_FITS_file, indexFrame
    COMMON APP_CONSTANTS
    common PIP
	filename= *((*self.Data).frames[IndexFrame])
	if obj_valid(self.statuswindow) then self.statuswindow->set_action, "Reading FITS file "+filename
    if ~file_test(filename,/read) then begin
        self->Log, "ERROR: Unable to read file "+filename
        self->Log, 'Reduction failed: ' + filename
        return,NOT_OK
    endif

	; free previously allocated arrays
	ptr_free, (*self.data).currFrame, (*self.data).currDQ, (*self.data).currUncert

	; Do all the actual loading work in a separate function: 
	file_data = gpi_load_fits(filename)

	;	The returned image is already a pointer, so we can just copy over the
	;	pointer. Likewise for the header.
	(*self.data).currframe = file_data.image
	(*self.data).HeadersExt[IndexFrame] = file_data.ext_header


	if tag_exist(file_data, 'DQ') then begin
		(*self.data).currDQ = file_data.DQ
		(*self.data).HeadersDQ[IndexFrame] = file_data.DQ_header
	endif
	if tag_exist(file_data, 'UNCERT') then begin
		(*self.data).currUncert = file_data.UNCERT
		(*self.data).HeadersUncert[IndexFrame] = file_data.Uncert_header
	endif


	; we deal with the primary header in a special way below, so just save it
	; here. 
	pri_header = *file_data.pri_header

	ptr_free, file_data.pri_header ; avoid memory leaks!
	; Don't free the image pointer or ext_header here since that will lose it from the (*self.data).currframe

    ;--- update the headers: append the DRF onto the actual FITS header
    ;  At this point the *(*self.data).HeadersPHU[IndexFrame] variable contains
    ;  ONLY the DRF appended in FITS header COMMENT form. (from gpidrfparser)
    ;  Append this onto the REAL fits header we just read in from disk.
    ;
	
    SXDELPAR, *(*self.data).HeadersPHU[IndexFrame], '' ;remove blanks
    SXDELPAR, pri_header, '' ;remove blanks
    SXDELPAR, *(*self.data).HeadersPHU[IndexFrame], 'END'
    SXDELPAR, pri_header, 'END'
    *(*self.data).HeadersPHU[IndexFrame]=[pri_header,*(*self.data).HeadersPHU[IndexFrame], 'END            ']
    ; ***WARNING***   don't use SXADDPAR for 'END', it gets the syntax wrong
    ; and breaks pyfits. i.e. do not try this following line. The above one
    ; is required. 
    ;SXADDPAR, *(*self.data).HeadersExt[IndexFrame], "END",''        
    
	self->set_keyword, "HISTORY", "Reduction with GPI Data Pipeline version "+gpi_pipeline_version()
	self->set_keyword, "HISTORY", "  Started On " + SYSTIME(0)
	self->set_keyword, "HISTORY", "  User: "+getenv('USER')+ "      Hostname: "+getenv('HOST')
    return, OK
end


;+-----------------------------------------------------------
;  gpiPipelineBackbone::SetupStatusConsole
;
;	 Launch the Status Console / progress bar window. 
;	 Can call this multiple times, in which case it will
;    make sure the progress bar is (still) launched and valid.
;-
pro  gpiPipelineBackbone::SetupStatusConsole
  if not(xregistered('gpistatusconsole',/noshow)) then begin
        obj_destroy, self.statuswindow
        self.statuswindow = OBJ_NEW('gpistatusconsole', self)
        self.statuswindow->set_GenLogF, self.generallogfilename
  endif else begin
	  message,/info, ' progress bar window already initialized and running.'
  endelse
end



;+ -----------------------------------------------------------
; gpiPipelineBackbone::RunModule
;
;    Run one single primitive (module) for the current dataset. 
;-

FUNCTION gpiPipelineBackbone::RunModule, Primitives, ModNum

    COMMON APP_CONSTANTS
    common PIP

    if debug ge 2 then message,/info, " Now running primitive "+Primitives[ModNum].Name+', '+ Primitives[ModNum].IDLCommand
    self->Log, "Running primitive "+string(Primitives[ModNum].Name, format='(A30)')+"  for frame "+strc(numfile), depth=2,/flush
    ; Execute the call sequence and pass the return value to DRP_EVALUATE

    ; Add the currently executing primitive number to the Backbone structure
    self.CurrentlyExecutingPrimitiveNumber = ModNum

    ; since we use call_function to run the primitive, then the IDL code will STOP at the location
    ; of any error, instead of returning here... This is desirable for
    ; debugging. On the other hand, for production use, we don't want it to stop
	; the program on errors, so use a catch block so that it will 
    ; gracefully handle any failures without stopping overall pipeline execution.

    ; Users can switch between these two modes using the 'enable_primitive_debug' pipeline configuration setting

    if self.verbose then  self->Log,"        idl command: "+Primitives[ModNum].IDLCommand
    if gpi_get_setting('enable_primitive_debug',default=0,/silent) then begin
        call_function_error=0 ; don't use catch when debugging, stop on errors
    endif else begin
    	catch, call_function_error
    endelse

	if call_function_error eq 0 then begin
		status = call_function( Primitives[ModNum].IDLCommand, *self.data, Primitives, self ) 
	endif else begin
		self->Log, "  ERROR in calling primitive '"+Primitives[ModNum].Name+"'. Check primitive name and arguments? Or set enable_primitive_debug to stop IDL at a breakpoint."
		self->Log,"        idl command attempted: "+Primitives[ModNum].IDLCommand

		status=NOT_OK
	endelse

    IF status EQ NOT_OK THEN BEGIN            ;  The primitive failed
        self->Log, 'Primitive failed: ' + Primitives[ModNum].Name
    ENDIF ELSE BEGIN                ;  The primitive succeeded
        self->Log, 'Primitive completed: ' + Primitives[ModNum].Name, DEPTH = 3
    ENDELSE
    self.CurrentlyExecutingPrimitiveNumber = -1

    RETURN, status

END




;+-----------------------------------------------------------
; gpiPipelineBackbone::CheckLogDate
;
;    Switch the log file to the next date if necessary
;-

pro gpiPipelineBackbone::CheckLogDate
    COMMON APP_CONSTANTS
    if self.log_date ne gpi_datestr(/current) then begin
        newdate = gpi_datestr(/current)
        self->log, "Date has changed to "+newdate+"; switching to next log file."
        self->openLog
        self->Log, "New date, hence new log file for already-running pipeline: "+newdate 
    endif


end

;+-----------------------------------------------------------
; gpiPipelineBackbone::OpenLog
;
;    Create a log file
;-
PRO gpiPipelineBackbone::OpenLog 

    COMMON APP_CONSTANTS

    self.log_date = gpi_datestr(/current)

	logdir =  (*self.pipelineConfig).logdir
	; ensure it ends in trailing path sep
	if ( strmid(logdir, strlen(logdir)-1,1) ne path_sep()) then logdir=logdir+path_sep()

	dir_ok = gpi_check_dir_exists(logdir)	; will potentially prompt user to create it
	if dir_ok eq NOT_OK then return


	gpi_get_user_info, user, computer
	if gpi_get_setting('username_in_log_filename',default=0) then begin
		logfile = logdir +'gpi_drp_'+self.log_date+"_"+user+"_"+computer+".log"
	endif else begin
		logfile = logdir +'gpi_drp_'+self.log_date+"_"+computer+".log"
	endelse
	catch, error_status

	if error_status ne 0 then begin
		; don't use message here or you get a circular error infinite loop
    	print, "ERROR in OPENLOG: "
   		print, "could not open file "+LogFile
		print, "Please check your path settings and try restarting the pipeline."
		; stop
  	endif else begin
		  CLOSE, self.LOG_GENERAL
		  FREE_LUN, self.LOG_GENERAL
		  OPENW, new_LUN, LogFile, /GET_LUN,/APPEND
		  self.LOG_GENERAL = new_LUN
		  PRINTF, self.LOG_GENERAL, '--------------------------------------------------------------'
		  PRINTF, self.LOG_GENERAL, '   GPI Data Reduction Pipeline, version '+gpi_pipeline_version()
		  PRINTF, self.LOG_GENERAL, '   Started On ' + SYSTIME(0)
		  PRINTF, self.LOG_GENERAL, '   User: '+user+ "      Hostname: "+computer
		  PRINTF, self.LOG_GENERAL, ''
		  print, ""
		  print, " Opened log file for writing: "+logFile
		  print, ""
		  if obj_valid(self.statuswindow) then self.statuswindow->set_GenLogF, logfile
		  self.generallogfilename = logfile

  	endelse
  	catch,/cancel


END
;+------------------------------------------------------------------------------
; gpiPipelineBackbone::Log, text
;
;    Writes log entries in the log file.  Each entry is given a time stamp
;
; ARGUMENTS:
;    Text        String to be logged
;
; KEYWORDS:
;    DEPTH=       The level of indentation of the log entry.  The default is 0
;    /FLUSH       Force writing the log to disk (will happen periodically on its
;    			  own, but we can use this to force writes at the end of each
;    			  recipe.
;    /DEBUG       flag for debug-mode log commands (which will be ignored unless
;                 DEBUG is set in the application configuration)
;-------------------------------------------------------------------------------
PRO gpiPipelineBackbone::Log, Text, DEPTH = TextDepth, flush=flush, debug=debugflag


    COMMON APP_CONSTANTS

    ; If this is a DEBUG log message, then ignore it if DEBUG mode is
    ; not enabled.
    if keyword_set(debugflag) then if DEBUG eq 0 then return


    ;Time = STRMID(SYSTIME(), 11, 9)                ; Get time stamp
    time = strmid(cmsystime(/ext),16,12)            ; now updated to have sub-second precision


    IF KEYWORD_SET(TextDepth) NE 1 THEN TextDepth = 0    ; Default indentation
    TDstring = strjoin(replicate(' ',textdepth*3+1))
    localText = TDString + Text                 ; Create indented log string

    ; Print it to the chosen file
    annotated_log = Time + ' ' + localText

    ; also display logs to the DRP status console GUI
    IF obj_valid(self.statuswindow) then self.statuswindow->display_Log, annotated_log

    catch, error_writing
    if error_writing eq 0 then begin
        PRINTF, self.LOG_GENERAL, annotated_log
    endif
    if keyword_set(flush) then flush,self.LOG_GENERAL

    ; Print it to the screen
    print, annotated_log

END



;+-----------------------------------------------------------
; gpiPipelineBackbone::ErrorHandler
;
;    Handle errors by failing a recipe. 
;    Mark it as failed, alert the user, and 
;    Free pointers of the erroneous data set
;-



PRO gpiPipelineBackbone::ErrorHandler, CurrentRecipe

    COMMON APP_CONSTANTS

    CATCH, Error


    IF Error EQ 0 THEN BEGIN
        self->log, 'ERROR: ' + !ERROR_STATE.MSG + '    ' + $
            !ERROR_STATE.SYS_MSG, DEPTH = 1
		if keyword_set(current_recipe) then begin
			self->log, 'Reduction failed for recipe '+CurrentRecipe.name
			IF N_PARAMS() EQ 2 THEN BEGIN
				self->SetRecipeQueueStatus, CurrentRecipe, 'failed'
				; If we failed with outstanding data, then clean it up.
				self->free_dataset_pointers
			ENDIF
		endif

		status_message = "Last Recipe **Failed**!    Watching for new recipes but idle."
		if obj_valid(self.statuswindow) then begin
			  self.statuswindow->set_status, status_message
			  self.statuswindow->Set_action, '--'
		endif


    ENDIF ELSE BEGIN
    ; Will this cause a recursion error?
        MESSAGE, 'ERROR in gpiPipelineBackbone::ErrorHandler - ' + STRTRIM(STRING(!ERR),2) + ': ' + !ERR_STRING, /INFO
    ENDELSE

    CATCH, /CANCEL
END


;+-------------------------------------------------------------------------------
; gpiPipelineBackbone::get_keyword
;    return a header keyword value, automatically retreiving from either primary or extension HDU
;    as appropriate.
;
; INPUT:
;   keyword		Name of keyword you want to retrieve
;
; KEYWORDS:
; 	indexFrame= which frame's header to read from? Default is the current
; 				frame as specified in the 'numframe' variable in PIP common block, but
;	 			you can select another header with this keyword. 
;	ext_num=	This allows you to override the keyword config file if you
;				really know what you're doing. Set ext_num=0 to read from the PHU or
;				ext_num=1 to read from the image extension.
;	/silent		suppress printed output to the screen.
;
;	/simplify	Remove "Gemini-ish" cruft around the keyword values: e.g.
;				turn IFSFILT_K2_G1215 into just K2.
;
; OPTIONAL RETURNS:
;   count=		Number of matching keyword values found, or 0 if not found
;   comment=	return FITS keyword comment.
;
;-
FUNCTION gpiPipelineBackbone::get_keyword, keyword, count=count, comment=comment, indexFrame=indexFrame, ext_num=ext_num, silent=silent, simplify=simplify


	common PIP
	if n_elements(indexFrame) eq 0 then indexFrame=numfile ; use value from common block if not explicitly provided.
		; don't use if keyword_set in the above line - will fail for the case of
		; indexframe=0. 


	val = gpi_get_keyword( *(*self.data).headersPHU[indexFrame], *(*self.data).headersEXT[indexFrame], $
		keyword,count=count, comment=comment, ext_num=ext_num, silent=silent )
	if keyword_set(simplify) then val = gpi_simplify_keyword_value(val)
	return, val


end


;+--------------------------------------------------------------------------------
; gpiPipelineBackbone::set_keyword
;    set a keyword, in either the primary or extension header automatically
;
; KEYWORDS:
; 	indexFrame 	which frame's header to write to? Default is the current
; 				frame as specified in the 'numframe' variable in PIP common block, but
;	 			you can select another header with this keyword. 
;	ext_num		This allows you to override the keyword config file if you
;				really know what you're doing. Set ext_num=0 to write to the PHU or
;				ext_num=1 to write to the image extension.
;	silent		suppress printed output to the screen.
;-----------------

PRO gpiPipelineBackbone::set_keyword, keyword, value, comment, indexFrame=indexFrame, ext_num=ext_num, _Extra=_extra, silent=silent
	common PIP
	if n_elements(indexFrame) eq 0 then indexFrame=numfile ; use value from common block if not explicitly provided.

	gpi_set_keyword, keyword, value, *(*self.data).headersPHU[indexFrame], *(*self.data).headersEXT[indexFrame], $
		comment=comment, ext_num=ext_num, _Extra=_extra, silent=silent
	
end
;+--------------------------------------------------------------------------------
; gpiPipelineBackbone::del_keyword
;     Delete a keyword entirely from a specified header
;-

PRO gpiPipelineBackbone::del_keyword, keyword, ext_num=ext_num, indexFrame=indexFrame
	
	common PIP
	if n_elements(indexFrame) eq 0 then indexFrame=numfile ; use value from common block if not explicitly provided.


	if ~(keyword_set(ext_num)) then ext_num=0
	if ext_num eq 0 then begin
		sxdelpar, *(*self.data).headersPHU[indexFrame], keyword
	endif else begin
		sxdelpar, *(*self.data).headersEXT[indexFrame], keyword
	endelse
	
end

;-----------------------------------------------------------
; gpiPipelineBackbone::getContinueAfterRecipeXMLParsing
;    accessor function for internal variable
function gpiPipelineBackbone::getContinueAfterRecipeXMLParsing
    return, (*self.pipelineConfig).ContinueAfterRecipeXMLParsing
end

;+-----------------------------------------------------------
; gpiPipelineBackbone::getCurrentModuleIndex
;    accessor function for current primitive number.
;    This gets called a lot by the various primitives
;    so they can index into the primitives structure for keyword arguments.
;-

function gpiPipelineBackbone::getCurrentModuleIndex
    return, self.CurrentlyExecutingPrimitiveNumber
end
function gpiPipelineBackbone::getCurrentPrimitiveIndex
    return, self.CurrentlyExecutingPrimitiveNumber
end
;
;+-----------------------------------------------------------
; gpiPipelineBackbone::getgpicaldb
;    accessor function for calibrations DB object.
;-
function gpiPipelineBackbone::getgpicaldb
    return, self.gpicaldb
end
;+-----------------------------------------------------------
;gpiPipelineBackbone::rescan_CalDB
;    Invoke rescan of the calDB object
;-
pro gpiPipelineBackbone::rescan_CalDB
	self->Log, 'User requested rescan of calibrations database'
  self.GPICalDB->rescan_directory    
end

;+-----------------------------------------------------------
; gpiPipelineBackbone::rescan_Config
;     Rescan primitives, regenerate primitives configuration file
;     Rescan pipeline config settings files
;-
pro gpiPipelineBackbone::rescan_Config
	self->Log, 'User requested rescan of data pipeline configuration files'


	; rescan stuff on the other side of the link, too
	; Do this first so they proceed in parallel.
    if obj_valid(self.launcher) then self.launcher->queue, 'recompile'

	; rescan config files
	dummy = gpi_get_setting('max_files_per_recipe',/rescan) ; can get any arbitrary setting here, just need to force the rescan

	config_file=gpi_get_directory('GPI_DRP_CONFIG_DIR') +path_sep()+"gpi_pipeline_primitives.xml"
	; regenerate primitives config file (if in real IDL, not runtime version)
	; This will pick up any new routines that have been added to the pipeline.
	; (Can't do this in runtime version since there's no way to compile new
	; routines if added)
	if not lmgr(/runtime) then begin
		self->log, "Rescanning for new primitives, and regenerating primitives config file."
		if obj_valid(self.statuswindow) then self.statuswindow->update, [{name:'Rescanning primitives headers and regenerating config file'}], 0, 2, 1, ""
		gpi_make_primitives_config 
		self->log, "Generated new primitives config file OK."
	endif
	; rescan primitives configuration file
	Self.ConfigParser -> ParseFile, config_file
	self->Log, "Rescanned "+config_file
	config = Self.ConfigParser->getidlfunc()
	for i=0,n_elements(config.idlfuncs)-1 do begin
		print, "Recompiling for "+config.names[i]

		if obj_valid(self.statuswindow) then self.statuswindow->update, [{name:'Recompiling primitives'}], 0, n_elements(config.idlfuncs), i, ""
		catch, compile_error
		if compile_error eq 0 then begin
			resolve_routine, config.idlfuncs[i], /is_func 
		endif else begin
			self->Log, "Compilation error encountered for "+config.names[i]+" in file "+config.idlfuncs[i]
		endelse
		catch,/cancel
	endfor
	statusmessage = 'Refreshed all '+strc(n_elements(config.idlfuncs))+' available pipeline primitive procedures.'
	self->Log, statusmessage

	tmp = gpi_lookup_template_filename('placeholder',/scanonly,/verbose)
	self->Log, "Rescanned available recipe templates"

	if obj_valid(self.statuswindow) then self.statuswindow->update, [{name:statusmessage}], 0, n_elements(config.idlfuncs), 0, ""


end

;+-----------------------------------------------------------
; gpiPipelineBackbone::getprogressbar
;     accessor function for progress bar / status window object.
;     used in save_currdata
;-
function gpiPipelineBackbone::getprogressbar
    return, self.statuswindow
end


function gpiPipelineBackbone::getstatusconsole
    return, self.statuswindow
end

pro gpipipelinebackbone::set_last_saved_file, filename
	self.last_saved_filename = filename
    statuswindow = self->Getprogressbar() 
	if obj_valid(statuswindow) then statuswindow->set_last_saved_file, filename

end
function gpipipelinebackbone::get_last_saved_file
	return, self.last_saved_filename 
end

; Getter/Setting functions for the reduction level
;  See docs/usage/recipesqueue.html
;
pro gpipipelinebackbone::set_reduction_level, newlevel
	newlevel = fix(newlevel)
	if newlevel lt 0 or newlevel gt 2 then self->Log, 'WARNING: invalid reduction level: '+strc(newlevel)+'. Must be in {0, 1, 2}.'
	self.CurrentReductionLevel = newlevel
end

function gpipipelinebackbone::get_current_reduction_level
	return, self.CurrentReductionLevel 
end



;+-----------------------------------------------------------
; gpiPipelineBackbone__define
;
;     create the object itself.
;     Must go LAST in this file to auto-compile properly
;-
PRO gpiPipelineBackbone__define

    void = {gpiPipelineBackbone, $
			pipelineconfig: ptr_new(), $		; Pipeline backbone additional internal state and config. See ::init
            Primitives:PTR_NEW(), $				; Parsed index of primitives
            Data:PTR_NEW(), $					; Pointer to the dataset structure
            Parser:OBJ_NEW(), $					; Recipe parser object
            ConfigParser:OBJ_NEW(), $			; Pipeline Config parser object
            statuswindow: obj_new(), $			; Status window object
            launcher: obj_new(), $				; launcher object (used to connect to other IDL session)
            gpicaldb: obj_new(), $				; Calibrations Database object
			LOG_GENERAL: 0L, $					; LUN (file handle) to the pipeline log file
            CurrentlyExecutingPrimitiveNumber:0, $	; index of currently executing primitive
			CurrentReductionLevel: 0, $			; 0 = not reducing anything, 1 = Level 1 actions on individual files, 2 = Level 2 actions on entire datasets
            TempFileNumber: 0, $				; Used for passing multiple files to multiple gpitv sessions. See self->gpitv pro above
			last_saved_filename: '', $			; remember the last filename saved
            generallogfilename: '', $			; Filename of log file we are currently writing
            log_date: '',            $			; date string of current log file, used to check when we must advance to next date
			nogui: 0, $							; Should we disable GUIs because we're running over an ssh connection without X11? 
			verbose: 0, $						; Should we print some more verbose debug output? 
            LogPath:''}

END


