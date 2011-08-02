;-----------------------------------------------------------------------------------------------------
; Procedure gpiPipelineBackbone__define
;
; DESCRIPTION:
;     DRP Backbone object definition module.
;
; ARGUMENTS:
;    None.
;
; KEYWORDS:
;    None.
;
; Modified:
;         2009-02-01    Split from OSIRIS' drpBackbone__define and heavily trimmed
;                     by Marshall Perrin
;    2009-08 minor changes in Reduce function - JM 
;    2009-10-05 added ReduceOnLine function - JM
;    2010-08-19 JM memory bug corrected (image pointer created even if already exist)
;
;-----------------------------------------------------------------------------------------------------


;-----------------------------------------------------------
; gpiPipelineBackbone::Init
;
;  Create new objects
;  Open log files
;


FUNCTION gpipipelinebackbone::Init, config_file=config_file, session=session, verbose=verbose
    ; Application constants
    COMMON APP_CONSTANTS, $
        LOG_GENERAL,  $       ; File unit number of the general log file
        LOG_DRF,      $       ; File unit number of the DRF log file
        pipelineConfig, $
        CALL_STACK,    $        ; String to hold the call stack at run time
        OK, NOT_OK, ERR_UNKNOWN, GOTO_NEXT_FILE,        $        ; Indicates success
        ;READDATA,    $            ; Read primary data mask for drpFITSToDataSet
        ;READNOISE,    $          ; Read noise data mask for drpFITSToDataSet
        ;READQUALITY,    $        ; Read quality data mask for drpFITSToDataSet
        ;CumulativeMemoryUsedByFITSData,    $        ; Stores current allocation of <fits/> files memory
        ;MaxMemorySizeOfFITSData,    $        ; Max allowed allocation of <fits/> files memory
        ;READWHOLEFRAME,    $ ; Read primary data mask for drpFITSToDataSet
        backbone_comm, $                ; Object pointer for main backbone (for access in subroutines & modules) 
        loadedcalfiles, $        ; object holding loaded calibration files (as pointers)
        DEBUG                    ; is DEBUG mode enabled?
    


        DEBUG=1

        LOG_GENERAL = 1       ; LUNs for logfiles
        LOG_DRF = 2
        CALL_STACK = ''
        OK = 0
        NOT_OK = -1
        ERR_UNKNOWN = -3
        GOTO_NEXT_FILE = -2
        ; Eventually this will be a configuration structure.
        pipelineConfig = {$
            ;default_log_dir : ".",         $LINUX sys    ; Default directory for output log files
      default_log_dir : getenv("GPI_PIPELINE_LOG_DIR"),     $ ; Default directory for output log files
            continueAfterDRFParsing:0,        $    ; Should program actually run the pipeline or just parse?
            MaxFramesInDataSets: 64,        $    ; OSIRIS legacy code. Not totally sure what this is for.
            MaxMemoryUsage: 0L                 $   ; this will eventually be used for array size limits on what
                                                ; gets done in memory versus
                                                ; swapped to disk.
        }

    if ~(keyword_set(config_file)) then config_file=GETENV('GPI_CONFIG_FILE') ;"DRSConfig.xml"
    self.verbose = keyword_set(verbose)
    ver = gpi_pipeline_version()

    print, "                                                    "
    PRINT, "*****************************************************"
    print, "*                                                   *"
    PRINT, "*          GPI DATA REDUCTION PIPELINE              *"
    print, "*                                                   *"
    print, "*                   VERSION "+ver+"                    *"
    print, "*                                                   *"
    print, "*          Jerome Maire, Marshall Perrin et al.     *"
    print, "*                                                   *"
    print, "*          In part based on OSIRIS pipeline by      *"
    print, "*          James Larkin et al.                      *"
    print, "*                                                   *"
    print, "*****************************************************"
    print, "                                                    "

    error=0
    ;CATCH, Error       ; Catch errors before the pipeline
    IF Error EQ 0 THEN BEGIN
        ;        drpSetAppConstants        ; Set the application constants
        Self->OpenLog, pipelineConfig.default_log_dir + path_sep() + self->generalLogName(), /GENERAL
        self->Log, 'Backbone Initialized', /GENERAL

        self->DefineStructs        ; Define the DRP structures

        Self.Parser = OBJ_NEW('gpiDRFParser', backbone=self) ; Init DRF parser

        ; Read in the XML Config File with the module name translations.
        Self.ConfigParser = OBJ_NEW('gpiDRSConfigParser',/verbose)
        if file_test(config_file) then  Self.ConfigParser -> ParseFile, config_file

        self->SetupProgressBar
        self.progressbar->log,"* GPI DATA REDUCTION PIPELINE  *"
        self.progressbar->log,"* VERSION "+ver+"  *"
        self.GPICalDB = obj_new('gpicaldatabase', backbone=self)
    
        self.progressbar->set_calibdir, self.GPICalDB->get_calibdir()
    
        self.launcher = obj_new('launcher',/pipeline)
        
        ; This is stored in a common block variable so that it is accessible
        ; inside the Save_currdata function (which otherwise does not have
        ; access to the backbone object). Yes, this is inelegant and ought to
        ; be fixed probably. - MP

        backbone_comm = self ; stick into common block for global access

        loadedcalfiles = obj_new('gpiloadedcalfiles') ; in common block for access inside the primitives

    ENDIF ELSE BEGIN
        Self -> ErrorHandler
        CLOSE, LOG_GENERAL
        FREE_LUN, LOG_GENERAL
        CLOSE, LOG_DRF
        FREE_LUN, LOG_DRF
           RETURN, -1
    ENDELSE


    return ,1 ; valid object created 

END

;----------------------------------------------------------
; gpiPipelineBackbone::free_dataset_pointers
;		free all pointers from the dataset.
;

pro gpiPipelineBackbone::free_dataset_pointers
    IF PTR_VALID(Self.Data) THEN $
        FOR i = 0, N_ELEMENTS(*Self.Data)-1 DO BEGIN
            PTR_FREE, (*Self.Data)[i].Frames[*]
            PTR_FREE, (*Self.Data)[i].HeadersPHU[*]
            PTR_FREE, (*Self.Data)[i].HeadersExt[*]
            PTR_FREE, (*Self.Data)[i].UncertFrames[*]
            PTR_FREE, (*Self.Data)[i].QualFrames[*]
        END
end



;-----------------------------------------------------------
; gpiPipelineBackbone::Cleanup
;
;  Cleanup routine for object destruction
;  Free allocated memory and close log files
;

PRO gpiPipelineBackbone::Cleanup
    COMMON APP_CONSTANTS

    OBJ_DESTROY, Self.Parser
    OBJ_DESTROY, Self.ConfigParser
    OBJ_DESTROY, Self.ProgressBar


    if obj_valid(self.launcher) then begin
        self.launcher->queue, 'quit' ; kill the other side of the link, too
        obj_destroy, self.launcher ; kill this side.
    endif

	self->free_dataset_pointers
;    IF PTR_VALID(Self.Data) THEN $
;        FOR i = 0, N_ELEMENTS(*Self.Data)-1 DO BEGIN
;            PTR_FREE, (*Self.Data)[i].Frames[*]
;            PTR_FREE, (*Self.Data)[i].Headers[*]
;            PTR_FREE, (*Self.Data)[i].HeadersPHU[*]
;            PTR_FREE, (*Self.Data)[i].UncertFrames[*]
;            PTR_FREE, (*Self.Data)[i].QualFrames[*]
;        END
;
    PTR_FREE, Self.Data
    PTR_FREE, Self.Modules

    if keyword_set(LOG_GENERAL) then begin
        CLOSE, LOG_GENERAL
        FREE_LUN, LOG_GENERAL
    endif

END


;-----------------------------------------------------------------------------------------------------
; Procedure DefineStructs
;
; DESCRIPTION:
;     drpDefineStructs defines the user defined structures used by the program
;
; ARGUMENTS:
;    None.
;
; KEYWORDS:
;    None.
; HISTORY:
;     Lifted from OSIRIS code.
;     Definitions moved to separate routines; MDP 2010-04-15
;-----------------------------------------------------------------------------------------------------
PRO gpipipelinebackbone::DefineStructs

    COMMON APP_CONSTANTS

    ; Dataset structure containing the specified input files
    ;   both filenames and data.
    void = {structDataSet}

    ; Module (Primitive)
    void = {structModule}

    ; Queue for DRF XML files on disk
    void = {structQueueEntry, $
            index:'', $
            name:'', $
            status: '', $
            error:''}


END


 
;-----------------------------------------------------------
; gpiPipelineBackbone::GetNextDRF
;	Looks in the queue dir for any *.waiting.xml files.
;	If one or more are found, return the first one alphabetically
;	If none are found, return ""
;
function gpiPipelineBackbone::GetNextDRF, queuedir, found=count

    queueDirName = QueueDir + '*.waiting.xml'
    FileNameArray = FILE_SEARCH(queueDirName, count=count)
    if count gt 0 then begin
        self->Log, "Found "+strc(count)+" XML files to parse",/debug
        queue = REPLICATE({structQueueEntry}, count)
        queue.name = filenamearray
        for i=0L, count-1 do begin
            parts = stregex(filenamearray[i], "(.*)\.(.*)\.xml",/extrac,/sub)
            ;parts = stregex(filenamearray, ".+"+path_sep()+"(.*)\.(.*)\.xml",/extrac,/sub) ;linux?
            queue[i].index=parts[1]
            queue[i].status=parts[2]
            print, queue[i].index, queue[i].status, queue[i].name, format='(A40, A20, A80)'
        endfor
        ; sort here? This lets you set the order of multiple files if you drop
        ; them at once.
        queue = queue[sort(queue.index)]
        return, queue[0] ; can only handle one at a time now
    endif
    return, ""

end

;-----------------------------------------------------------
; gpiPipelineBackbone::SetDRFStatus
;
;    Update the status of a given file
;    by renaming the DRF xml file appropriately
;


PRO gpiPipelineBackbone::SetDRFStatus, drfstruct, newstatus

    oldfilename = drfstruct.name
    filebase = stregex(oldfilename, "(.+)\."+drfstruct.status+".xml",/extract,/subexpr)
    newfilename = filebase[1]+"."+newstatus+".xml"

    ; TODO debugging / error checking on the file move?
    file_move, oldfilename, newfilename,/overwrite
    drfstruct.status=newstatus
    drfstruct.name = newfilename


	; display status in the console window
	self.progressbar->set_status, newstatus
	; if this is a new file (newstatus is working) then append this to the DRF
	; log in the progressbar
	; otherwise just update the latest entry in the DRF log in progressbar 
	self.progressbar->DRFlog, newfilename, replace=(newstatus ne "working")

end

;-----------------------------------------------------------
; gpiPipelineBackbone::Flush_Queue
;
; Delete any DRFs present in the queue directory (dangerous, mostly for
; debugging use!)

PRO gpiPipelineBackbone::flushqueue, QueueDir


    COMMON APP_CONSTANTS
    if strmid(queuedir, strlen(queuedir)-1,1) ne path_sep() then queuedir+=path_sep() ; append slash if needed

	message,/info, 'Clearing all DRFs from the queue'
	
    CurrentDRF = self->GetNextDRF(Queuedir, found=nfound)
	while (nfound ge 1) do begin
		print, "DELETING "+CurrentDRF.name
		file_Delete, CurrentDRF.name
    	CurrentDRF = self->GetNextDRF(Queuedir, found=nfound)
	endwhile


end

;-----------------------------------------------------------
; gpiPipelineBackbone::gpitv
;
;  Display a file in GPITV. Called from save_currdata in __end_primitive
;
;  Uses the launcher mechanism to communicate between IDL sessions

PRO gpiPipelineBackbone::gpitv, filename_or_data, session=session, header=header, _extra=_extra

    if obj_valid(self.launcher) then begin

        if size(filename_or_data,/TNAME) ne 'STRING' then begin
            ; user provided an array - need to write it to a temp file on disk
            tmppath = getenv('IDL_TMPDIR')
			if file_test(tmppath, /write) then begin
				if strmid(tmppath, strlen(tmppath)-1) ne path_sep() then tmppath +=path_sep()  ; be careful if path sep char is on the end already or not
				tempfile = tmppath+'temp.fits'

				; check for the error case where some other user already owns
				; /tmp/temp.fits on a multiuser machine. If necessary, fall back to
				; another filename with an appended number. 
				;
				i=self.TempFileNumber
				i=(i+1) mod 100
				tempfile = tmppath+'temp'+strc(i)+'.fits'
		
				catch, gpitv_send_error
				if gpitv_send_error then begin
					; try the next filename, except if we are at 100 tries already then
					; give up 
					i=(i+1) mod 100
					tempfile = tmppath+'temp'+strc(i)+'.fits'
					if i eq self.TempFileNumber-1 or (self.TempFileNumber eq 0 and i eq 99) then begin
						self->Log, "Could not open **any** filename for writing in "+getenv('IDL_TMPDIR')+" after 100 attempts. Cannot send file to GPItv."
						stop
						return
					endif
				endif 

				writefits, tempfile, filename_or_data, header
				CATCH, /CANCEL
				self.TempFileNumber=i ; save last used temp file # for starting point next time this gets called
				self.launcher->queue, 'gpitv', filename=tempfile, session=session, _extra=_extra
			endif else begin
				self->Log, "User does not have permissions to write in the IDL temp file dir "+getenv('IDL_TMPDIR')+ ". Output data cannot be displayed in gpitv."
			endelse
        endif else begin
            self.launcher->queue, 'gpitv', filename=filename_or_data, session=session, _extra=_extra
        endelse

    endif else begin
        gpitvms, filename_or_data, ses=session, _extra=_extra
    endelse

end


;-----------------------------------------------------------
; gpiPipelineBackbone::Run
;
;    Loop forever checking for new files in the queue directory.
;    When one is found, 
;        - parse it
;        - call DRFpipeline->Reduce
;
;

PRO gpiPipelineBackbone::Run, QueueDir

    COMMON APP_CONSTANTS
    ;  Poll the 'queue' directory continuously.  If a DRF is encountered, reduce it.
    DRPCONTINUE = 1  ; Start off with a continuous loop

    if strmid(queuedir, strlen(queuedir)-1,1) ne path_sep() then queuedir+=path_sep() ; append slash if needed

    print, "    "
    print, "   Now polling for DRF files in "+queueDir
    print, "    "
    self.progressbar->log,"   Now polling and waiting for DRF files in "+queueDir
    WHILE DRPCONTINUE EQ 1 DO BEGIN
        if ~(keyword_set(DEBUG)) then CATCH, Error else ERROR=0    ; Catch errors inside the pipeline. In debug mode, just let the code crash and stop
          IF Error EQ 1 THEN BEGIN
            PRINT, "Calling Self -> ErrorHandler..."
            Self -> ErrorHandler, CurrentDRF, QueueDir
            CLOSE, LOG_DRF
            FREE_LUN, LOG_DRF
        ENDIF

        CurrentDRF = self->GetNextDRF(Queuedir, found=nfound)
        IF nfound gt 0 THEN BEGIN
            self.CurrentDRFname = CurrentDRF.name
            self->log, 'Found file: ' + CurrentDRF.Name, /GENERAL
                    wait, 1.0   ; Wait 1 seconds to make sure file is fully written.
                    self.progressbar->set_DRF, CurrentDRF
            self->SetDRFStatus, CurrentDRF, 'working'
            ; Re-parse the configuration file, in case it has been changed.
            ;OPENR, lun, CONFIG_FILENAME_FILE, /GET_LUN
            ;READF, lun, CONFIG_FILENAME
            ;FREE_LUN, lun
            ;Self.ConfigParser -> ParseFile, drpXlateFileName(CONFIG_FILENAME)
            ;Self.ConfigParser -> getParameters, Self
        
            if ~(keyword_set(debug)) then CATCH, parserError else parserError=0 ; only catch if DEBUG is not set.
            IF parserError EQ 0 THEN BEGIN
                self.progressbar->set_action, "Parsing DRF"
                PipelineConfig.continueAfterDRFParsing = 1    ; Assume it will be Ok to continue
                Self.Parser -> ParseFile, CurrentDRF.name,  Self.ConfigParser, backbone=self
                ; ParseFile updates the self.Data and self.modules structure
                ; arrays in accordance with what is stated in the DRF
                CATCH, /CANCEL
            ENDIF ELSE BEGIN
                ; Legacy OSIRIS code
                self->Log, "ERROR in parsing the DRF "+currentDRF.name,/general
                ; Call the local error handler
                Self -> ErrorHandler, CurrentDRF, QueueDir
                ; Destroy the current DRF parser and punt the DRF
                OBJ_DESTROY, Self.Parser
                ; Recreate a parser object for the next DRF in the pipeline
                Self.Parser = OBJ_NEW('gpiDRFParser', backbone=self)
                PipelineConfig.continueAfterDRFParsing = 0
                CATCH, /CANCEL
            ENDELSE

            IF PipelineConfig.continueAfterDRFParsing EQ 1 THEN BEGIN
				if (*(self.data)).validframecount eq 0 then begin
					self->Log, 'ERROR: That DRF was parsed OK, but no files could be loaded.'
					result=NOT_OK
				endif else begin

					Self -> OpenLog, CurrentDRF.Name + '.log', /DRF
					if ~strmatch(self.reductiontype,'On-Line Reduction') then $
						Result = Self->Reduce() else $
						Result = Self->ReduceOnLine()
				endelse

				IF Result EQ OK THEN BEGIN
					PRINT, "Success"
					self->SetDRFStatus, CurrentDRF, 'done'
							  self.progressbar->set_status, "Last DRF done OK! Watching for new DRFs but idle."
							  self.progressbar->Set_action, '--'
				ENDIF ELSE BEGIN
					PRINT, "Failure"
					self->SetDRFStatus, CurrentDRF, 'failed'
					self.progressbar->set_status, "Last DRF **failed**!    Watching for new DRFs but idle."
					self.progressbar->Set_action, '--'
			 
				ENDELSE
                ; Free any remaining memory here
           
				self->free_dataset_pointers
;                IF PTR_VALID(Self.Data) THEN BEGIN
;                    FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
;                        PTR_FREE, (*Self.Data)[i].UncertFrames[*]
;                        PTR_FREE, (*Self.Data)[i].QualFrames[*]
;                        PTR_FREE, (*Self.Data)[i].currFrame[*]
;                        PTR_FREE, (*Self.Data)[i].HeadersExt[*]
;                        PTR_FREE, (*Self.Data)[i].HeadersPHU[*]
;                        PTR_FREE, (*Self.Data)[i].Frames[*]
;                    ENDFOR
;                ENDIF ; PTR_VALID(Self.Data)


                ; We are done with the DRF, so close its log file
                CLOSE, LOG_DRF
                FREE_LUN, LOG_DRF
            ENDIF ELSE BEGIN  ; ENDIF continueAfterDRFParsing EQ 1
              ; This code if continueAfterDRFParsing == 0
              self->log, 'gpiPipelineBackbone::Run: Reduction failed due to parsing error in file ' + DRFFileName, /GENERAL
              self->SetDRFStatus, CurrentDRF, 'failed'
              ; If we failed with outstanding data, then clean it up.
			  self->free_dataset_pointers
;              IF PTR_VALID(Self.Data) THEN BEGIN
;                FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
;                  PTR_FREE, (*Self.Data)[i].QualFrames[*]
;                  PTR_FREE, (*Self.Data)[i].UncertFrames[*]
;                  PTR_FREE, (*Self.Data)[i].Headers[*]
;                  PTR_FREE, (*Self.Data)[i].HeadersPHU[*]
;                  PTR_FREE, (*Self.Data)[i].Frames[*]
;                ENDFOR
;              ENDIF
            ENDELSE
        ENDIF

        ;wait, 1 ; Only check for new files at most once per second
        for iw = 0,9 do begin
            wait, 0.1 ; Only check for new files at most once per second
                ; break the wait up into smaller parts to allow event loop
                ; handling

            if obj_valid(self.progressbar) then begin
                self.progressbar->checkEvents
                if self.progressbar->checkQuit() then begin
                    message,/info, "User pressed QUIT on the progress bar!"
                    self->Log, "User pressed QUIT on the progress bar.  Exiting DRP."
                    ;stop
                    self.progressbar->Quit
                     
                    obj_destroy,self
                    DRPCONTINUE=0
                    break
                    ;exit
                endif
                if self.progressbar->flushqueue() then begin
                    self->flushqueue, queuedir
                    self.progressbar->flushqueue_end
                endif    
                if self.progressbar->rescandb() then begin
                    self->rescan
                    self.progressbar->rescandb_end
                endif    
            endif
        endfor
    ENDWHILE

END
;-----------------------------------------------------------
; gpiPipelineBackbone::Reduce
;
;    Run the specified commands in sequence to reduce the data. 
;    This is for the regular, non-realtime reduction
;


FUNCTION gpiPipelineBackbone::Reduce

    COMMON APP_CONSTANTS
    common PIP, lambda0, filename,wavcal,tilt, badpixmap, filter, dim, CommonWavVect, gpidisplay, meddec,suffix, header, heade,oBridge,listfilenames, numfile, painit,dir_sc, Dtel,numext

    PRINT, ''
    PRINT, SYSTIME(/UTC)
    PRINT, ''

    self->SetupProgressBar
    ;if (not(xregistered('procstatus', /noshow))) then create_progressbar2
    ;if (not(xregistered('procstatus', /noshow))) then stop

    ;#############################################################
    ; Iterate over the datasets in the 'Data' array and run the sequence of modules for each dataset.
    ;
    ; MDP note: The OSIRIS pipeline, on which this was based, had a vague notion
    ; of being able to operate on multiple datasets, each of which contained
    ; multiple files. This was never actually implemented. 
    ; For GPI, we declare that there can only be one dataset in a DRF, which
    ; can in turn contain some number of data files, which get stored in the
    ; 'frame' arrays etc. 
    self->Log, 'Reducing data set.', /GENERAL, /DRF, depth=1

    FOR IndexFrame = 0, (*self.Data).validframecount-1 DO BEGIN
        if debug ge 1 then print, "########### start of file "+strc(indexFrame+1)+" ################"
        self->Log, 'Reducing file: ' + (*self.Data).fileNames[IndexFrame], /GENERAL, /DRF, depth=2
        self.progressbar->Set_FITS, (*self.Data).fileNames[IndexFrame], number=indexframe,nbtot=(*self.Data).validframecount



        load_status = self->load_and_preprocess_FITS_file(indexFrame)
        if load_status eq NOT_OK then begin
            self->Log, "ERROR: Unable to load file "+strc(indexFrame),/GENERAL,/DRF
            return, NOT_OK
        endif
        ;--- Read in the file 
        ;filename= *((*self.Data).frames[IndexFrame])

        ;fits_info, filename, n_ext = numext, /silent
        ;numext=0 ;just for polcaltest!!!
;        if ~ptr_valid((*self.data).currframe) then begin
;            if (numext EQ 0) then (*self.data).currframe        = ptr_new(READFITS(filename , Header, /SILENT))
;            if (numext ge 1) then begin
;                (*self.data).currframe        = ptr_new(mrdfits(filename , 1, Header, /SILENT))
;                headPHU = headfits(filename, exten=0)            
;            endif
;        endif else begin
;            if (numext EQ 0) then *((*self.data).currframe)        = (READFITS(filename , Header, /SILENT))
;            if (numext ge 1) then begin
;                *((*self.data).currframe)        = (mrdfits(filename , 1, Header, /SILENT))
;                headPHU = headfits(filename, exten=0)            
;            endif        
;        endelse    
;
;        if n_elements( *((*self.data).currframe) ) eq 1 then if *((*self.data).currframe) eq -1 then begin
;            self->Log, "ERROR: Unable to read file "+filename, /GENERAL, /DRF
;            self->Log, 'Reduction failed: ' + filename, /GENERAL, /DRF
;            return,NOT_OK 
;        endif
;
        ; NOTE: there are two redundant ways to get the current filename in the code right now:
        ;print, *((*self.data).frames[IndexFrame])
        ;print,  (*self.Data).inputdir+path_sep()+(*self.Data).fileNames[IndexFrame]

        numfile=IndexFrame ; store the index in the common block

;<<<<<<< .mine
;=======
;
;        ;--- update the headers - append the DRF onto the actual FITS header
;        ;  At this point the *(*self.data).HeadersExt[IndexFrame] variable contains
;        ;  ONLY the DRF appended in FITS header COMMENT form. 
;        ;  Append this onto the REAL fits header we just read in from disk.
;        ;
;        if (numext GT 0) then begin
;           ; header=[headPHU,header]
;            *(*self.data).HeadersPHU[IndexFrame]=[headPHU]
;        endif
;
;        FXADDPAR, *(*self.data).HeadersExt[IndexFrame], "DATAFILE", file_basename(filename), "Original file name of DRP input", before="END"
;        FXADDPAR, *(*self.data).HeadersExt[IndexFrame], "DATAPATH", file_dirname(filename), "Original path of DRP input", before="END"
;
;        SXDELPAR, header, 'END'
;        *(*self.data).HeadersExt[IndexFrame]=[header,*(*self.data).HeadersExt[IndexFrame], 'END            ']
;        ; ***WARNING***   don't use SXADDPAR for 'END', it gets the syntax wrong
;        ; and breaks pyfits. i.e. do not try this following line. The above one
;        ; is required. 
;        
;        ;SXADDPAR, *(*self.data).HeadersExt[IndexFrame], "END",''		; don't use SXADDPAR for 'END', it gets the syntax wrong and breaks pyfits.
;        
;        ;;is the frame from the entire detector or just just a section?
;        ;if numext eq 0 then datasec=SXPAR( header, 'DATASEC',count=cds) else instrum=SXPAR( headPHU, 'DATASEC',count=cds)
;        datasec=SXPAR(*(*self.data).HeadersExt[IndexFrame], 'DATASEC',count=cds)
;        if cds eq 1 then begin
;          ; DATASSEC format is "[DETSTRTX:DETENDX,DETSTRTY:DETENDY]" from gpiheaders_20110425.xls (S. Goodsell)
;            DETSTRTX=strmid(datasec, 1, stregex(datasec,':')-1)
;            DETENDX=strmid(datasec, stregex(datasec,':')+1, stregex(datasec,',')-stregex(datasec,':')-1)
;            datasecy=strmid(datasec,stregex(datasec,','),strlen(datasec)-stregex(datasec,','))
;            DETSTRTY=strmid(datasecy, 1, stregex(datasecy,':')-1)
;            DETENDY=strmid(datasecy, stregex(datasecy,':')+1, stregex(datasecy,']')-stregex(datasecy,':')-1)
;            ;;DRP will always consider [0:2047,0,2047] frames:
;            if (DETSTRTX ne 0) || (DETENDX ne 2047) || (DETSTRTY ne 0) || (DETENDY ne 2047) then begin
;              tmpframe=dblarr(2048,2048)
;              tmpframe[DETSTRTX:DETENDX,DETSTRTY:DETENDY]=*((*self.data).currframe)
;              *((*self.data).currframe)=tmpframe
;            endif
;        endif
;		;---- Rotate the image, if necessary -------
;            ;!!!!TEMPORARY will need modifs: use it for real ifs data, not DST!!!
;                  if numext eq 0 then instrum=SXPAR( header, 'INSTRUME',count=c1) else instrum=SXPAR( headPHU, 'INSTRUME',count=c1)
;                  if ~strmatch(instrum,'*DST*') && (  sxpar( *(*self.data).HeadersExt[IndexFrame], 'DRPVER' ) eq '' ) then begin
;                  if self.verbose then self->Log, "Image detected as IFS raw file, assumed vertical spectrum orientation. Must be reoriented to horizontal spectrum direction."             
;                    *((*self.data).currframe)=rotate(transpose(*((*self.data).currframe)),2)
;                    message,/info, 'Image rotated to match DST convention!'
;                  endif
;                
;>>>>>>> .r430
;        suffix=''
suffix=''

        ; Iterate over the modules in the 'Modules' array and run each.
        status = OK
        FOR indexModules = 0, N_ELEMENTS(*self.Modules)-1 DO BEGIN
            ; Continue if the current module's skip field equals 0 and no previous module
            ; has failed (Result = 1).
            IF ((*self.Modules)[indexModules].Skip EQ 0) AND (status EQ OK) THEN BEGIN
                ;Result = Self -> RunModule(Modules, indexModules, Data[IndexFrame], Backbone)
                self.progressbar->Update, *self.Modules, indexModules, (*self.data).validframecount, IndexFrame,   ' Working...'
                status = Self -> RunModule(*self.Modules, indexModules)

            ENDIF
            if self.progressbar->checkabort() then begin
                self->Log, "User pressed ABORT button! Aborting DRF",/general, /drf
                status = NOT_OK
                break
            endif
        ENDFOR

        ; Log the result.
        if status eq GOTO_NEXT_FILE then self->Log, 'Continuing on to next file...',  /DRF,depth=2
        IF status EQ OK or status eq GOTO_NEXT_FILE THEN self->Log, 'Reduction successful: ' + filename, /GENERAL, /DRF, depth=2 $
        ELSE begin
            self->Log, 'Reduction failed: ' + filename, /GENERAL, /DRF
            break ; no sense continuing if one of the files has failed.
        endelse

        if debug ge 1 then print, "########### end of file "+strc(indexframe+1)+" ################"
    ENDFOR
    if (*self.Data).validframecount eq 0 then begin    
      self.progressbar->Update, *self.Modules,N_ELEMENTS(*self.Modules)-1, (*self.data).validframecount, 1,' No file processed.'
      self->log, 'No file processed. ' , /GENERAL,/DRF
      status=OK
    endif
    if status eq OK then self->Log, "DRF Complete!",/general,/DRF

    if debug ge 1 then print, "########### end of reduction for that DRF  ################"
    PRINT, ''
    PRINT, SYSTIME(/UTC)
    PRINT, ''
    if ((*self.data).validframecount gt 0) then $
    self.progressbar->Update, *self.Modules,indexModules, (*self.data).validframecount, IndexFrame,' Done.'


    RETURN, status

END
;-----------------------------------------------------------
; gpiPipelineBackbone::Load_and_preprocess_FITS_file
;
;     This routine loads an input file from disk, and optionally performs
;     one or more transformations on it (such as updating FITS keywords or
;     rotating the image)
;
;     This preprocessing is needed because of variations in the GPI
;     data format as the instrument and pipeline are developing. This
;     routine provides a convenient place to perform whatever actions
;     are needed to read disparate input files into a common format in memory.
;        -MP

FUNCTION gpiPipelineBackbone::load_and_preprocess_FITS_file, indexFrame
    COMMON APP_CONSTANTS
    common PIP
	filename= *((*self.Data).frames[IndexFrame])

    self.progressbar->set_action, "Reading FITS file "+filename
    if ~file_test(filename,/read) then begin
        self->Log, "ERROR: Unable to read file "+filename, /GENERAL, /DRF
        self->Log, 'Reduction failed: ' + filename, /GENERAL, /DRF
        return,NOT_OK
    endif

    if ~ptr_valid((*self.data).currframe) then (*self.data).currframe = ptr_new(/allocate_heap)

	; Read in the file, and check whether it is a single image or has
	; extensions.
    fits_info, filename, n_ext = numext, /silent
    if (numext EQ 0) then begin
		; No extension present: Read primary image into the data array
		;  and copy the only header into both the primary and extension headers
		;  (see below where we append the DRF onto the primary header)
		*((*self.data).currframe)        = (READFITS(filename , Header, /SILENT))
		pri_header=header
		;*(*self.data).HeadersExt[IndexFrame] = header
		;fxaddpar,  *(*self.data).HeadersExt[IndexFrame],'HISTORY', 'Input image has no extensions, so primary header copied to 1st extension'
		mkhdr,hdrext,*((*self.data).currframe)
		sxaddpar,hdrext,"XTENSION","SCI","Image extension",before="SIMPLE"
    sxaddpar,hdrext,"EXTNAME","SCI","Image extension",before="SIMPLE"
    sxaddpar,hdrext,"EXTVER",1,"Number assigned to FITS extension",before="SIMPLE"
    ;add blank wcs keyword in extension (mandatory for all gemini data)
    wcskeytab=["CTYPE1","CD1_1","CD1_2","CD2_1","CD2_2","CDELT1","CDELT2",$
      "CRPIX1","CRPIX2","CRVAL1","CRVAL2","CRVAL3","CTYPE1","CTYPE2"]
    for iwcs=0,n_elements(wcskeytab)-1 do $
    sxaddpar,hdrext,wcskeytab[iwcs],'','',before="END"
    *(*self.data).HeadersExt[IndexFrame] = hdrext
    endif
    if (numext ge 1) then begin
		; at least one extension is present:  Read the 1st extention image into
		; the data array, and read in the primary and extension headers. 
		;  (see below where we append the DRF onto the primary header)
        *((*self.data).currframe)        = (mrdfits(filename , 1, ext_Header, /SILENT))
		pri_header = headfits(filename, exten=0)
		*(*self.data).HeadersExt[IndexFrame] = ext_header
    endif        
    
        SXDELPAR, *(*self.data).HeadersPHU[IndexFrame], 'END'
    *(*self.data).HeadersPHU[IndexFrame]=[pri_header,*(*self.data).HeadersPHU[IndexFrame], 'END            ']
    
    if n_elements( *((*self.data).currframe) ) eq 1 then if *((*self.data).currframe) eq -1 then begin
        self->Log, "ERROR: Unable to read file "+filename, /GENERAL, /DRF
        self->Log, 'Reduction failed: ' + filename, /GENERAL, /DRF
        return,NOT_OK 
    endif
    
    if (numext EQ 0) then begin
          fxaddpar, *(*self.data).HeadersPHU[IndexFrame], 'EXTEND', 'T', 'FITS file contains extensions' ; these are required in any FITS with extensions
          fxaddpar, *(*self.data).HeadersPHU[IndexFrame], 'NEXTEND', 1, 'FITS file contains extensions'  ; so make sure they are present.
      
    
    	;--- update the headers: fix obsolete keywords by changing them
    	;  to official standardized values. 
    	
    	obsolete_keywords = ['PRISM',   'FILTER3', 'FILTER2', 'FILTER4', 'FILTER', 'LYOT', 'GAIN']
    	approved_keywords = ['DISPERSR','DISPERSR', 'CALFILT', 'ADC',    'FILTER1' , 'LYOTMASK', 'SYSGAIN']
    
    	for i=0L, n_elements(approved_keywords)-1 do begin
    		val_approved = self->get_keyword(approved_keywords[i], count=count, indexFrame=indexFrame,/silent)
    		if count eq 0 then begin ; only try to update if we are missing the approved keyword.
    			; in that case, see if we have an obsolete keyword and then try to
    			; use it.
    			val_obsolete = self->get_keyword(obsolete_keywords[i], count=count, comment=comment, indexFrame=indexFrame,/silent)
    			if count gt 0 then self->set_keyword, approved_keywords[i], val_obsolete, comment=comment, indexFrame=indexFrame
    			message,/info, 'Converted obsolete keyword '+obsolete_keywords[i]+' into '+approved_keywords[i]
    		endif
        sxdelpar, *(*self.data).HeadersPHU[IndexFrame], obsolete_keywords[i]
    	endfor 
   endif
    ;--- update the headers: append the DRF onto the actual FITS header
    ;  At this point the *(*self.data).HeadersPHU[IndexFrame] variable contains
    ;  ONLY the DRF appended in FITS header COMMENT form. 
    ;  Append this onto the REAL fits header we just read in from disk.
    ;
	;
	;
    ;if (numext GT 0) then begin
        ;header=[headPHU,header]
        ;*(*self.data).HeadersPHU[IndexFrame]=[headPHU]
    ;endif
    if (numext EQ 0) then begin
      ;remove NAXIS1 & NAXIS2 in PHU
      sxdelpar, *(*self.data).HeadersPHU[IndexFrame], ['NAXIS1','NAXIS2']
      ;;change DISPERSR value according to GPI new conventions
      val_disp = self->get_keyword('DISPERSR', count=count, indexFrame=indexFrame,/silent)
      newval_disp=''
      if strmatch(val_disp, '*Spectr*') then newval_disp='DISP_PRISM_G6262' 
      if strmatch(val_disp, '*Pol*') then newval_disp='DISP_WOLLASTON_G6261'
      if strlen(newval_disp) gt 0 then self->set_keyword, 'DISPERSR', newval_disp,  indexFrame=indexFrame,extnum=0
      ;;add POLARIZ & WPSTATE keywords
      if strmatch(val_disp, '*Pol*') then self->set_keyword, 'POLARIZ', 'DEPLOYED',  indexFrame=indexFrame,extnum=0 $
                                    else self->set_keyword, 'POLARIZ', 'EXTRACTED',  indexFrame=indexFrame,extnum=0 
      if strmatch(val_disp, '*Pol*') then self->set_keyword, 'WPSTATE', 'IN',  indexFrame=indexFrame,extnum=0 $
                                    else self->set_keyword, 'WPSTATE', 'OUT',  indexFrame=indexFrame,extnum=0       
      ;;change FILTER1 value according to GPI new conventions
      val_old = self->get_keyword('FILTER1', count=count, indexFrame=indexFrame,/silent)
      newval=''
      tabfiltold=['Y','J','H','K1','K2']
      newtabfilt=['IFSFILT_Y_G1211','IFSFILT_J_G1212','IFSFILT_H_G1213','IFSFILT_K1_G1214','IFSFILT_K2_G1215']
      indc=where(strmatch(tabfiltold,strcompress(val_old,/rem)))
      if indc ge 0 then newval=(newtabfilt[indc])[0]
      if strlen(newval) gt 0 then self->set_keyword, 'FILTER1', newval,  indexFrame=indexFrame,extnum=0
      ;add OBSMODE keyword
      if strlen(val_old) gt 0 then self->set_keyword, 'OBSMODE', val_old,  indexFrame=indexFrame,extnum=0
      ;add ABORTED keyword
      self->set_keyword, 'ABORTED', 'F',  indexFrame=indexFrame,extnum=1
      ;change BUNIT value
      self->set_keyword, 'BUNIT', 'Counts/seconds/coadd',  indexFrame=indexFrame,extnum=1
      sxdelpar, *(*self.data).HeadersPHU[IndexFrame], 'BUNIT'
      ;add DATASEC keyword
      self->set_keyword, 'DATASEC', '[1:2048,1:2048]',  indexFrame=indexFrame,extnum=1
      ;change ITIME,EXPTIME,ITIME0,TRUITIME: 
      ;BE EXTREMLY CAREFUL with change of units
      ;;old itime[millisec], old exptime[in sec]
      ;; new itime [seconds per coadd],  new itime0[microsec per coadd]
      val_old_itime = self->get_keyword('itime', count=count, indexFrame=indexFrame,/silent)
      val_old_exptime = self->get_keyword('exptime', count=count, indexFrame=indexFrame,/silent)
      sxdelpar, *(*self.data).HeadersPHU[IndexFrame], 'ITIME'
      sxdelpar, *(*self.data).HeadersPHU[IndexFrame], 'EXPTIME'
      sxdelpar, *(*self.data).HeadersPHU[IndexFrame], 'TRUITIME'
      self->set_keyword, 'ITIME', val_old_exptime,  indexFrame=indexFrame,comment='Exposure integration time in seconds per coadd',extnum=1
      self->set_keyword, 'ITIME0', long(1.e3*val_old_itime),  indexFrame=indexFrame,comment='Requested integration time in microseconds per coadd',extnum=1
      ;;add UTSTART
      val_timeobs = self->get_keyword('TIME-OBS', count=count, indexFrame=indexFrame,/silent)
      self->set_keyword, 'UTSTART', val_timeobs,  indexFrame=indexFrame,comment='UT at observation start',extnum=0
      ;;change GCALLAMP values      
      val_lamp = self->get_keyword('GCALLAMP', count=count, indexFrame=indexFrame,/silent)
      newlamp=''
      if strmatch(val_lamp,'*Xenon*') then newlamp='Xe'
      if strmatch(val_lamp,'*Argon*') then newlamp='Ar'
      if strlen(newlamp) gt 0 then self->set_keyword, 'GCALLAMP', newlamp,  indexFrame=indexFrame,extnum=0
      ;;change OBSTYPE ("wavecal" to "ARC" value)
      val_obs = self->get_keyword('OBSTYPE', count=count, indexFrame=indexFrame,/silent)
      newobs=''
      if strmatch(val_obs,'*Wavecal*') then newobs='ARC'
      if strlen(newlamp) gt 0 then self->set_keyword, 'OBSTYPE', newobs,  indexFrame=indexFrame,extnum=0
      ;add ASTROMTC keyword
      val_old = self->get_keyword('OBSCLASS', count=count, indexFrame=indexFrame,/silent)
      if strmatch(val_old, '*AstromSTD*') then astromvalue='TRUE' else astromvalue='FALSE'
      self->set_keyword, 'ASTROMTC', astromvalue, comment='Is it a Astrometric standard?', indexFrame=indexFrame,extnum=0
      
      ;;set the reserved OBSCLASS keyword
       self->set_keyword, 'OBSCLASS', 'acq',  indexFrame=indexFrame,extnum=0
       ;;add the INPORT keyword
       val_port = self->get_keyword('ISS_PORT', count=count, indexFrame=indexFrame,/silent)
       newport=0
      if strmatch(val_port,'*bottom*') then newport=1
      if strmatch(val_port,'*side*') then newport=2
      if newport gt 0 then self->set_keyword, 'INPORT', newport,  indexFrame=indexFrame,extnum=0
      sxdelpar, *(*self.data).HeadersPHU[IndexFrame], 'ISS_PORT'
    endif
    FXADDPAR, *(*self.data).HeadersPHU[IndexFrame], "DATAFILE", file_basename(filename), "File name", before="END"
    FXADDPAR, *(*self.data).HeadersPHU[IndexFrame], "DATAPATH", file_dirname(filename), "Original path of DRP input", before="END"

   ; SXDELPAR, pri_header, 'END'
   ; *(*self.data).HeadersPHU[IndexFrame]=[pri_header,*(*self.data).HeadersPHU[IndexFrame], 'END            ']
        SXDELPAR, *(*self.data).HeadersPHU[IndexFrame], 'END'
    *(*self.data).HeadersPHU[IndexFrame]=[*(*self.data).HeadersPHU[IndexFrame], 'END            ']
    ; ***WARNING***   don't use SXADDPAR for 'END', it gets the syntax wrong
    ; and breaks pyfits. i.e. do not try this following line. The above one
    ; is required. 
    ;SXADDPAR, *(*self.data).HeadersExt[IndexFrame], "END",''        
    

    ;---- is the frame from the entire detector or just a subarray?
	;if numext eq 0 then datasec=SXPAR( header, 'DATASEC',count=cds) else instrum=SXPAR( headPHU, 'DATASEC',count=cds)
	datasec=SXPAR(*(*self.data).HeadersExt[IndexFrame], 'DATASEC',count=cds)
	if cds eq 1 then begin
	  ; DATASSEC format is "[DETSTRTX:DETENDX,DETSTRTY:DETENDY]" from gpiheaders_20110425.xls (S. Goodsell)
		DETSTRTX=fix(strmid(datasec, 1, stregex(datasec,':')-1))
		DETENDX=fix(strmid(datasec, stregex(datasec,':')+1, stregex(datasec,',')-stregex(datasec,':')-1))
		datasecy=strmid(datasec,stregex(datasec,','),strlen(datasec)-stregex(datasec,','))
		DETSTRTY=fix(strmid(datasecy, 1, stregex(datasecy,':')-1))
		DETENDY=fix(strmid(datasecy, stregex(datasecy,':')+1, stregex(datasecy,']')-stregex(datasecy,':')-1))
		;;DRP will always consider [1:2048,1,2048] frames:
		if (DETSTRTX ne 1) || (DETENDX ne 2048) || (DETSTRTY ne 1) || (DETENDY ne 2048) then begin
		  tmpframe=dblarr(2048,2048)
		  tmpframe[(DETSTRTX-1):(DETENDX-1),(DETSTRTY-1):(DETENDY-1)]=*((*self.data).currframe)
		  *((*self.data).currframe)=tmpframe
		endif
	endif


    ;---- Rotate the image, if necessary -------
    ;!!!!TEMPORARY will need modifs: use it for real ifs data, not DST!!!
      instrum=SXPAR( *(*self.data).HeadersPHU[IndexFrame], 'INSTRUME',count=c1)
	if ~strmatch(instrum,'*DST*') && (  sxpar( *(*self.data).HeadersPHU[IndexFrame], 'DRPVER' ) eq '' ) then begin
    	if self.verbose then self->Log, "Image detected as IFS raw file, assumed vertical spectrum orientation. Must be reoriented to horizontal spectrum direction."
        *((*self.data).currframe)=rotate(transpose(*((*self.data).currframe)),2)
		fxaddpar, *(*self.data).HeadersPHU[IndexFrame],  'HISTORY', 'Raw image rotated by 90 degrees'
    	message,/info, 'Image rotated to match DST convention!'
    endif

    return, OK
end


;-----------------------------------------------------------
;  gpiPipelineBackbone::SetupProgressBar
;
;    make sure the progress bar is (still) launched and valid.
pro  gpiPipelineBackbone::SetupProgressBar
  ;if (not(xregistered('procstatus', /noshow))) then create_progressbar2
  if not(xregistered('gpiprogressbar',/noshow)) then begin
        obj_destroy, self.progressbar
        self.progressbar = OBJ_NEW('gpiprogressbar')
        self.progressbar->set_GenLogF, self.generallogfilename

  endif else begin
	  message,/info, ' progress bar window already initialized and running.'
  endelse
end



;-----------------------------------------------------------
; gpiPipelineBackbone::ReduceOnLine
;
; Run the specified commands in sequence to reduce the data online. 
;     This is for the realtime reduction.
;
;
;
;FUNCTION gpiPipelineBackbone::ReduceOnLine
;
;  COMMON APP_CONSTANTS
;  common PIP, lambda0, filename,wavcal,tilt, badpixmap, filter, dim, CommonWavVect, gpidisplay, meddec,suffix, header, heade,oBridge,listfilenames, numfile, painit,dir_sc, Dtel
;
;  PRINT, ''
;  PRINT, SYSTIME(/UTC)
;  PRINT, ''
;
;  self->SetupProgressBar
;  ;#############################################################
;  ;loop for detection of  new data then apply modules
;  temploop=1 ; TODO:implement a little GUI for stopping this loop and change OnLine parameters
;  while temploop eq 1 do begin  
;    ;nn=0
;    ;for i=0,ii-1 do begin ;find nb files to consider in order
;    ;  folder=stateF.listcontent(i)  ;to create the fitsfileslist array
;    ;  filetypes = '*.{fts,fits}'
;    ;    string3 = folder + filetypes
;    ;    fitsfiles =FILE_SEARCH(string3,/FOLD_CASE)
;    ;    nn=nn+(n_elements(fitsfiles))
;    ;endfor
;    ;fitsfileslist =STRARR(nn)
;
;    ;n=0 ;list of files in fitsfileslist
;    ;for i=0,ii-1 do begin
;    folder=(*self.data).inputdir ;stateF.listcontent(i)
;    filetypes = '*.{fts,fits}'
;    fitsfiles =FILE_SEARCH(folder + path_sep() + filetypes,/FOLD_CASE)
;    ;    fitsfileslist(n:n+n_elements(fitsfiles)-1) =fitsfiles
;    n= n_elements(fitsfiles)
;    ;endfor
;
;    ; retrieve creation date
;    date=dblarr(n_elements(fitsfiles))
;    for j=0,n_elements(date)-1 do begin
;        Result = FILE_INFO(fitsfiles[j] )
;        date(j)=Result.ctime
;    endfor
;    ;sort files with creation date
;    list2=fitsfiles(REVERSE(sort(date)))
;    list3=list2(0:n_elements(list2)-1)
;    ;widget_control, stateF.listfile_id, SET_VALUE= list3 ;display the list
;    ;stop
;    ;stateF.newlist=list3
;    ;;loop for detection of new files
;    ;  oBridge = OBJ_NEW('IDL_IDLBridge');, CALLBACK='callback_searchnewfits')
;    ;  oBridge->SetVar,"chang",0
;    ;  oBridge->SetVar,"dir",folder;stateF.listcontent(0:ii-1)
;    ;  oBridge->SetVar,"listfile",list3
;    ;  oBridge->SetVar,"list_id",0;stateF.listfile_id
;    ;  ;widget_control,stateF.button_id,GET_VALUE=val
;    ; ; widget_control,stateF.button_id,GET_VALUE=val
;    ;  oBridge->SetVar,"button_value",'void'
;    ;
;    ;comm2="chang=detectnewfits(dir,listfile,list_id,button_value)"
;    ;oBridge->Execute, comm2, /NOWAIT
;
;    chang=''
;    while chang eq '' do begin
;      chang=gpidetectnewfits(folder,list3,0,'void')
;      wait,1
;    endwhile
; 
;    (*self.Data).validframecount=1
;    (*self.Data).fileNames[0]=chang
;    *((*self.Data).frames[0])=chang
;    ;;;;;;;;;;;;;;;;;;;;;
;    self->Log, 'Reducing data set.', /GENERAL, /DRF, depth=1
;    FOR IndexFrame = 0, (*self.Data).validframecount-1 DO BEGIN
;        if debug ge 1 then print, "########### start of file "+strc(indexFrame+1)+" ################"
;        self->Log, 'Reducing file: ' + (*self.Data).fileNames[IndexFrame], /GENERAL, /DRF, depth=1
;
;        ;(*self.data).currframe        = ptr_new(READFITS(*((*self.data).frames[IndexFrame]), Header, /SILENT))
;        filename= *((*self.Data).frames[IndexFrame])
;        ;inputname = (*self.Data).inputdir+path_sep()+(*self.Data).fileNames[IndexFrame]
;        ;print, (*self.Data).inputdir+path_sep()+filename
;         ;(*self.data).currframe        = ptr_new(READFITS((*self.Data).inputdir+path_sep()+filename , Header, /SILENT))
;         (*self.data).currframe        = ptr_new(READFITS(filename , Header, /SILENT))
;        if n_elements( *((*self.data).currframe) ) eq 1 then if *((*self.data).currframe) eq -1 then begin
;              self->Log, "ERROR: Unable to read file "+filename, /GENERAL, /DRF
;              self->Log, 'Reduction failed: ' + filename, /GENERAL, /DRF
;              continue
;        endif
;
;        ; NOTE: there are two redundant ways to get the current filename in the code right now:
;        ;print, *((*self.data).frames[IndexFrame])
;        ;print,  (*self.Data).inputdir+path_sep()+(*self.Data).fileNames[IndexFrame]
;
;        numfile=IndexFrame ; store the index in the common block
;
;
;        ; update the headers - 
;        ;  At this point the *(*self.data).HeadersExt[IndexFrame] variable contains
;        ;  ONLY the DRF appended in FITS header COMMENT form. 
;        ;  Append this onto the REAL fits header we just read in from disk.
;        ;
;        SXADDPAR, *(*self.data).HeadersExt[IndexFrame], "DATAFILE", filename
;        SXDELPAR, header, 'END'
;        *(*self.data).HeadersExt[IndexFrame]=[header,*(*self.data).HeadersExt[IndexFrame]]
;        SXADDPAR, *(*self.data).HeadersExt[IndexFrame], "END",''
;        suffix=''
;
;        ; FIXME this ought to be read in from a configuration file somewhere,
;        ; not be hard-coded here in the software. 
;        filter = strcompress(sxpar( header ,'FILTER1', count=fcount),/REMOVE_ALL)
;        if fcount eq 0 then filter = strcompress(sxpar( header ,'FILTER'),/REMOVE_ALL)
;
;        tabband=[['Z'],['Y'],['J'],['H'],['K'],['K1'],['K2']]
;        parseband=WHERE(STRCMP( tabband, filter, /FOLD_CASE) EQ 1)
;        case parseband of
;            -1: CommonWavVect=-1
;            0:  CommonWavVect=[0.95, 1.14, 37]
;            1:  CommonWavVect=[0.95, 1.14, 37]
;            2:  CommonWavVect=[1.12, 1.35, 37]
;            3: CommonWavVect=[1.5, 1.8, 37]
;            4:  ;CommonWavVect=[1.5, 1.8, 37]
;            5:  CommonWavVect=[1.9, 2.19, 40]
;            6: CommonWavVect=[2.13, 2.4, 40]
;        endcase
;        ;;detect type
;        ;type = strcompress(sxpar( header ,'FILTER2', count=fcount),/REMOVE_ALL)
;        ; if fcount eq 0 then type = strcompress(sxpar( header ,'DISPERSR'),/REMOVE_ALL)
;        ;case type of
;        ;            'Spectro': begin
;        ;                   FindPro, 'gpidrfgui', dirlist=dirlist
;                      
;        caldat,systime(/julian),month,day,year, hour,minute,second
;        datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
;        hourstr = string(hour,minute,second,format='(i2.2,i2.2,i2.2)')  
;        drffilename=datestr+'_'+hourstr+'_drf.waiting.xml'
;        FILE_COPY, getenv('GPI_DRF_TEMPLATES_DIR')+'template_drf_online_1.xml', (*self.data).queuedir+path_sep()+drffilename
;                        
;        ;                      end
;        ;        endcase
;        ; Iterate over the modules in the 'Modules' array and run each.
;        status = OK
;        FOR indexModules = 0, N_ELEMENTS(*self.Modules)-1 DO BEGIN
;            ; Continue if the current module's skip field equals 0 and no previous module
;            ; has failed (Result = 1).
;            IF ((*self.Modules)[indexModules].Skip EQ 0) AND (status EQ OK) THEN BEGIN
;                ;Result = Self -> RunModule(Modules, indexModules, Data[IndexFrame], Backbone)
;                status = Self -> RunModule(*self.Modules, indexModules)
;            ENDIF
;        ENDFOR
;
;        ; Log the result.
;    if status eq GOTO_NEXT_FILE then self->Log, 'Continuing on to next file...', /GENERAL, /DRF, depth=2
;        IF status EQ OK or status eq GOTO_NEXT_FILE THEN self->Log, 'Reduction successful: ' + filename, /GENERAL, /DRF $
;        ELSE self->Log, 'Reduction failed: ' + filename, /GENERAL, /DRF
;
;    if debug ge 1 then print, "########### end of file "+strc(indexframe+1)+" ################"
;    ENDFOR
;
;    if debug ge 1 then print, "########### end of reduction for that DRF  ################"
;    PRINT, ''
;    PRINT, SYSTIME(/UTC)
;    PRINT, ''
;    self.progressbar->Update,*self.Modules,indexModules, (*self.data).validframecount, IndexFrame,' Done'
;  endwhile
;  RETURN, status
;
;END
;
;;-----------------------------------------------------------
;; gpiPipelineBackbone::RunModule
;;
;
;FUNCTION gpiPipelineBackbone::RunModule, Modules, ModNum
;
;    COMMON APP_CONSTANTS
;    common PIP
;
;    if debug ge 2 then message,/info, " Now running module "+Modules[ModNum].Name+', '+ Modules[ModNum].IDLCommand
;    self->Log, "Running module "+string(Modules[ModNum].Name, format='(A30)')+" for frame "+strc(numfile), depth=2
;    ; Execute the call sequence and pass the return value to DRP_EVALUATE
;
;      ; Add the currently executing module number to the Backbone structure
;    self.CurrentlyExecutingModuleNumber = ModNum
;
;    ; if we use call_function to run the module, then the IDL code will STOP at the location
;    ; of any error, instead of returning here... This is way better for
;    ; debugging (and perhaps should just always be how it works now. -MDP)
;    status = call_function( Modules[ModNum].IDLCommand, *self.data, Modules, self )
;
;
;    IF status EQ NOT_OK THEN BEGIN            ;  The module failed
;        IF (STRCMP(!ERR_STRING, "Variable", 8, /FOLD_CASE) EQ 1) THEN BEGIN
;            drpIOLock
;            PRINT, "drpPipeline::RunModule: " + !ERROR_STATE.MSG
;            PRINT, "drpPipeline::RunModule: " + !ERR_STRING
;            PRINT, "drpPipeline::RunModule: " + CALL_STACK
;            PRINT, "drpPipeline::RunModule: " + Modules[ModNum].CallSequence
;            PRINT, "drpPipeline::RunModule: " + Modules[ModNum].Name
;            drpIOUnlock
;        ENDIF
;        self->Log, 'ERROR: ' + !ERR_STRING, /GENERAL, /DRF
;        self->Log, 'Module failed: ' + Modules[ModNum].Name, /GENERAL, /DRF
;    ENDIF ELSE BEGIN                ;  The module succeeded
;        self->Log, 'Module completed: ' + Modules[ModNum].Name,  /GENERAL, /DRF, DEPTH = 3
;    ENDELSE
;    self.CurrentlyExecutingModuleNumber = -1
;
;    RETURN, status
;
;END
;


;-----------------------------------------------------------
; gpiPipelineBackbone::RunModule
;

FUNCTION gpiPipelineBackbone::RunModule, Modules, ModNum

    COMMON APP_CONSTANTS
    common PIP

    if debug ge 2 then message,/info, " Now running module "+Modules[ModNum].Name+', '+ Modules[ModNum].IDLCommand
    self->Log, "Running module "+string(Modules[ModNum].Name, format='(A30)')+" for frame "+strc(numfile), depth=2
    ; Execute the call sequence and pass the return value to DRP_EVALUATE

    ; Add the currently executing module number to the Backbone structure
    self.CurrentlyExecutingModuleNumber = ModNum

  ; if we use call_function to run the module, then the IDL code will STOP at the location
  ; of any error, instead of returning here... This is way better for
  ; debugging (and perhaps should just always be how it works now. -MDP)

    if self.verbose then  self->Log,"        idl command: "+Modules[ModNum].IDLCommand
	status = call_function( Modules[ModNum].IDLCommand, *self.data, Modules, self ) 

    IF status EQ NOT_OK THEN BEGIN            ;  The module failed
;        IF (STRCMP(!ERR_STRING, "Variable", 8, /FOLD_CASE) EQ 1) THEN BEGIN
;           
;            PRINT, "drpPipeline::RunModule: " + !ERROR_STATE.MSG
;            PRINT, "drpPipeline::RunModule: " + !ERR_STRING
;            PRINT, "drpPipeline::RunModule: " + CALL_STACK
;            PRINT, "drpPipeline::RunModule: " + Modules[ModNum].CallSequence
;            PRINT, "drpPipeline::RunModule: " + Modules[ModNum].Name
;            
;        ENDIF
;        self->Log, 'ERROR: ' + !ERR_STRING, /GENERAL, /DRF
        self->Log, 'Module failed: ' + Modules[ModNum].Name, /GENERAL, /DRF
    ENDIF ELSE BEGIN                ;  The module succeeded
        self->Log, 'Module completed: ' + Modules[ModNum].Name,  /GENERAL, /DRF, DEPTH = 3
    ENDELSE
    self.CurrentlyExecutingModuleNumber = -1

    RETURN, status

END



;-----------------------------------------------------------
; gpiPipelineBackbone::GeneralLogName
;
;    Create a log file name

FUNCTION gpiPipelineBackbone::GeneralLogName
    t = BIN_DATE()
    r = STRING(FORMAT='(%"%04d%02d%02d_%02d%02d")', t[0], t[1], t[2], t[3], t[4])
      r = STRMID(r,2) + "_drp.log"
      RETURN, r
end


;-----------------------------------------------------------
; gpiPipelineBackbone::OpenLog
;
;    Create a log file
;
;    OSIRIS legacy code: not sure what the point of 2 different log files is
;         Aha: The general log file is for the overall pipeline invocation, and
;         then a separate individual file is created for each specific DRF sent
;         through the pipeline.
;


PRO gpiPipelineBackbone::OpenLog, LogFile, GENERAL = LogGeneral, DRF = LogDRF

    COMMON APP_CONSTANTS

  catch, error_status

  if error_status ne 0 then begin
    print, "ERROR in OPENLOG: "
    print, "could not open file "+LogFile
  endif else begin

    IF KEYWORD_SET(LogGeneral) THEN BEGIN
      CLOSE, LOG_GENERAL
      FREE_LUN, LOG_GENERAL
      OPENW, LOG_GENERAL, LogFile, /GET_LUN
      PRINTF, LOG_GENERAL, 'Data Reduction Pipeline, version '+gpi_pipeline_version()
      PRINTF, LOG_GENERAL, 'Run On ' + SYSTIME(0)
      PRINTF, LOG_GENERAL, ''
      print, ""
      print, " Opened log file for writing: "+logFile
      print, ""
      if obj_valid(self.progressbar) then self.progressbar->set_GenLogF, logfile
      self.generallogfilename = logfile
    ENDIF

    IF KEYWORD_SET(LogDRF) THEN BEGIN
      CLOSE, LOG_DRF
      FREE_LUN, LOG_DRF
      OPENW, LOG_DRF, LogFile, /GET_LUN
      PRINTF, LOG_DRF, 'Data Reduction Pipeline'
      PRINTF, LOG_DRF, 'Run On ' + SYSTIME(0)
      PRINTF, LOG_DRF, ''
      PRINTF, LOG_GENERAL, 'DRF log opened on LUN = ' + STRING(LOG_DRF)
      if obj_valid(self.progressbar) then self.progressbar->set_DRFLogF, logfile
    ENDIF
  endelse
  catch,/cancel


END

;-----------------------------------------------------------
; gpiPipelineBackbone::Log, text
;
;     Log makes log entries in the general and DRF log files.  Each entry is given a time stamp
;     and for entries to the general log file the current procedure is specified
;
;
; ARGUMENTS:
;    Text        String to be logged
;
; KEYWORDS:
;    GENERAL        If this keyword is set, an entry is made in the general log file
;    DRF            If this keyword is set, and entry is made in the DRF log file
;    DEPTH        The level of indentation of the log entry.  The default is 0
;    /DEBUG        flag for debug-mode log commands (which will be ignored unless
;                DEBUG is set in the application configuration)
;-----------------------------------------------------------------------------------------------------
PRO gpiPipelineBackbone::Log, Text, GENERAL=LogGeneral, DRF=LogDRF, DEPTH = TextDepth, debug=debugflag


    COMMON APP_CONSTANTS


    ; If this is a DEBUG log message, then ignore it if DEBUG mode is
    ; not enabled.
    if keyword_set(debugflag) then if DEBUG eq 0 then return


    Time = STRMID(SYSTIME(), 11, 9)                ; Get time stamp

    IF KEYWORD_SET(TextDepth) NE 1 THEN TextDepth = 0    ; Default indentation
    TDstring = strjoin(replicate(' ',textdepth*3+1))
    localText = TDString + Text                 ; Create indented log string

    ; Print it to the chosen file
    IF KEYWORD_SET(LogGeneral) THEN LUN = LOG_GENERAL
    IF KEYWORD_SET(LogDRF) THEN LUN = LOG_DRF
    if ~(keyword_set(logGeneral)) and ~(keyword_set(logDRF)) then LUN=LOG_GENERAL ; default.

    ; for General log items, write to the DRP GUI
    IF KEYWORD_SET(LogGeneral) and obj_valid(self.progressbar) then self.progressbar->Log, Time + ' ' + localText

    ;PRINTF, LUN, Time + ' ' + Routine + localText    ; Log to General file
    catch, error_writing
    if error_writing eq 0 then begin
        PRINTF, LUN, Time + ' ' + localText    ; Log to General file
        FLUSH, LUN
    endif

    ; Print it to the screen
    print, Time + ' ' + localText

END



;-----------------------------------------------------------
; gpiPipelineBackbone::ErrorHandler
;
;    Handle errors
;    Free pointers of the erroneous data set
;



PRO gpiPipelineBackbone::ErrorHandler, CurrentDRF, QueueDir

    COMMON APP_CONSTANTS

    CATCH, Error


    IF Error EQ 0 THEN BEGIN
        self->log, 'ERROR: ' + !ERROR_STATE.MSG + '    ' + $
            !ERROR_STATE.SYS_MSG, /GENERAL, DEPTH = 1
        self->log, 'Reduction failed', /GENERAL
        IF N_PARAMS() EQ 2 THEN BEGIN
            drpSetStatus, CurrentDRF, QueueDir, 'failed'
            ; If we failed with outstanding data, then clean it up.
			self->free_dataset_pointers
;            IF PTR_VALID(Self.Data) THEN BEGIN
;                FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
;                    PTR_FREE, (*Self.Data)[i].QualFrames[*]
;                    PTR_FREE, (*Self.Data)[i].UncertFrames[*]
;                    PTR_FREE, (*Self.Data)[i].Headers[*]
;                    PTR_FREE, (*Self.Data)[i].HeadersPHU[*]
;                    PTR_FREE, (*Self.Data)[i].Frames[*]
;                ENDFOR
;            ENDIF
        ENDIF
    ENDIF ELSE BEGIN
    ; Will this cause a recursion error?
        MESSAGE, 'ERROR in gpiPipelineBackbone::ErrorHandler - ' + STRTRIM(STRING(!ERR),2) + ': ' + !ERR_STRING, /INFO
    ENDELSE

    CATCH, /CANCEL
END
;-----------------------------------------------------------
; Functions for dealing with FITS header keywords
;
;	The goal here is that pipeline primitives should not have to care
;	whether a given keyword is in the primary HDU or an extension HDU;
;	these functions take care of that appropriately. 

PRO gpiPipelineBackbone::load_keyword_table

	if ptr_valid(self.keyword_info) then ptr_free, self.keyword_info

	; this file will be in the same directory as drsconfig.xml
	mod_config_file=GETENV('GPI_CONFIG_FILE')
	keyword_config_file = file_dirname(mod_config_file) + path_sep() + 'keywordconfig.txt'
	readcol, keyword_config_file, keywords, extensions,  format='A,A',SKIPLINE=2,silent=1 ; tab separated
	; TODO: error checking!
	;JM: I removed the "delimiter=string(09b)," keyword in call to readcol (is it system dependent?)
	self.keyword_info = ptr_new({keyword: strupcase(keywords), extension: strlowcase(extensions)} )

end


FUNCTION gpiPipelineBackbone::get_keyword, keyword, count=count, comment=comment, indexFrame=indexFrame, ext_num=ext_num, silent=silent
	; get a keyword, either from primary or extension HDU
	;	
	; KEYWORDS:
	; 	indexFrame 	which frame's header to read from? Default is the current
	; 				frame as specified in the 'numframe' variable in PIP common block, but
	;	 			you can select another header with this keyword. 
	;	ext_num		This allows you to override the keyword config file if you
	;				really know what you're doing. Set ext_num=0 to read from the PHU or
	;				ext_num=1 to read from the image extension.
	;	silent		suppress printed output to the screen.
	;
	
	common PIP

	if ~ptr_valid(self.keyword_info) then self->load_keyword_table
	if n_elements(indexFrame) eq 0 then indexFrame=numfile ; use value from common block if not explicitly provided.
		; don't use if keyword_set in the above line - will fail for the case of
		; indexframe=0. 


	; which header to try first?
	if n_elements(ext_num) eq 0 then begin 
		; we should use the config file to determine where the keyword goes. 
		wmatch = where( strmatch( (*self.keyword_info).keyword, keyword, /fold), matchct)
		if matchct gt 0 then begin
			; if we have a match try that extension
			ext_num = ( (*self.keyword_info).extension[wmatch[0]] eq 'extension' ) ? 1 : 0  ; try Pri if either PHU or Both
		endif else begin
			; if we have no match, then try PHU first and if that fails try the
			; extension
			if ~(keyword_set(silent)) then message,/info, 'Keyword '+keyword+' not found in keywords config file; trying Primary header...'
			ext_num=0
			;value = sxpar(  *(*self.data).headersPHU[indexFrame], keyword, count=count) 
			;if count eq 0 then value =  sxpar(  *(*self.data).headersExt[indexFrame], keyword, count=count, comment=comment)
			;return, value
		endelse
	endif else begin
		; the user has explicitly told us where to get it - check that the value
		; supplied makes sense.
		if ext_num gt 1 or ext_num lt 0 then begin
			if ~(keyword_set(silent)) then message,/info, 'Invalid extension number - can only be 0 or 1. Checking for keyword in primary header.'
			ext_num=0
		endif
	endelse



	; try the preferred header
	if ext_num eq 0 then value= sxpar(  *(*self.data).headersPHU[indexFrame], keyword, count=count, comment=comment)  $
	else  				 value= sxpar(  *(*self.data).headersExt[indexFrame], keyword, count=count, comment=comment)  

	;if that failed, try the other header
	if count eq 0 then begin
		if ~(keyword_set(silent)) then message,/info,'Keyword not found in preferred header; trying the other HDU'
		if ext_num eq 0 then value= sxpar(  *(*self.data).headersExt[indexFrame], keyword, count=count, comment=comment)  $
		else  				 value= sxpar(  *(*self.data).headersPHU[indexFrame], keyword, count=count, comment=comment)  
	endif
	
	return, value
	



end



PRO gpiPipelineBackbone::set_keyword, keyword, value, comment, indexFrame=indexFrame, ext_num=ext_num, _Extra=_extra, silent=silent
	; set a keyword in either the primary or extension header depending on what
	; the keywords table says. 
	;
	; KEYWORDS:
	; 	indexFrame 	which frame's header to write to? Default is the current
	; 				frame as specified in the 'numframe' variable in PIP common block, but
	;	 			you can select another header with this keyword. 
	;	ext_num		This allows you to override the keyword config file if you
	;				really know what you're doing. Set ext_num=0 to write to the PHU or
	;				ext_num=1 to write to the image extension.
	;	silent		suppress printed output to the screen.
	;
	common PIP

	if ~ptr_valid(self.keyword_info) then self->load_keyword_table
	if n_elements(indexFrame) eq 0 then indexFrame=numfile ; use value from common block if not explicitly provided.
		; don't use if keyword_set in the above line - will fail for the case of
		; indexframe=0. 



	if ~(keyword_set(comment)) then comment='' 
	wmatch = where( strmatch( (*self.keyword_info).keyword, keyword, /fold), matchct)


	if n_elements(ext_num) eq 0 then begin 
		; we should use the config file to determine where the keyword goes. 
		if matchct gt 0 then begin
			; if we have a match write to that extension
			ext_num = ( (*self.keyword_info).extension[wmatch[0]] eq 'extension' ) ? 1 : 0  ; try Pri if either PHU or Both
		endif else begin
			if ~(keyword_set(silent)) then message,/info, 'Keyword '+keyword+' not found in keywords config file; writing to Primary header...'
			ext_num = 0
		endelse
	endif else begin
		; the user has explicitly told us where to put it - check that the value
		; supplied makes sense.
		if ext_num gt 1 or ext_num lt 0 then begin
			if ~(keyword_set(silent)) then message,/info, 'Invalid extension number - can only be 0 or 1. Writing keyword to primary header.'
			ext_num=0
		endif
	endelse


	if ext_num eq 0 then fxaddpar,  *(*self.data).headersPHU[indexFrame], keyword, value, comment $
	else  				 fxaddpar,  *(*self.data).headersExt[indexFrame], keyword, value, comment 
	


end


;-----------------------------------------------------------
; gpiPipelineBackbone::getContinueAfterDRFParsing
;        accessor function 

function gpiPipelineBackbone::getContinueAfterDRFParsing
    COMMON APP_CONSTANTS
    return, pipelineConfig.ContinueAfterDRFParsing
end
;
;-----------------------------------------------------------
; gpiPipelineBackbone::getCurrentModuleIndex
;        accessor function for current module number.
;        This gets called a lot by the various modules
;        so they can index into the modules structure for keyword arguments.
;

function gpiPipelineBackbone::getCurrentModuleIndex
    return, self.CurrentlyExecutingModuleNumber
end
;-----------------------------------------------------------
; gpiPipelineBackbone::getgpicaldb
;        accessor function for calibrations DB object.
function gpiPipelineBackbone::getgpicaldb
    return, self.gpicaldb
end
pro gpiPipelineBackbone::rescan
  self.GPICalDB->rescan_directory    
end
;-----------------------------------------------------------
; gpiPipelineBackbone::getprogressbar
;        accessor function for progress bar object.
function gpiPipelineBackbone::getprogressbar
    return, self.progressbar
end

;-----------------------------------------------------------
; gpiPipelineBackbone__define
;
;     create the object itself.
;     Must go LAST in this file to auto-compile properly
;
PRO gpiPipelineBackbone__define

    void = {gpiPipelineBackbone, $
            Parser:OBJ_NEW(), $
            ConfigParser:OBJ_NEW(), $
            ;DRFPipeline:OBJ_NEW(), $
            ;ParmList:PTR_NEW(), $
            Data:PTR_NEW(), $
            Modules:PTR_NEW(), $
			keyword_info: ptr_new(), $ ; info for auto-handling of MEF keywords
            progressbar: obj_new(), $
            launcher: obj_new(), $
            gpicaldb: obj_new(), $
            ReductionType:'', $
            CurrentDRFname: '', $
            CurrentlyExecutingModuleNumber:0, $
            TempFileNumber: 0, $ ; Used for passing multiple files to multiple gpitv sessions. See self->gpitv pro above
            generallogfilename: '', $
            verbose: 0, $
            LogPath:''}

END


