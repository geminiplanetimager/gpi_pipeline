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
;
;-----------------------------------------------------------------------------------------------------


;-----------------------------------------------------------
; gpiPipelineBackbone::Init
;
;  Create new objects
;  Open log files
;


FUNCTION gpipipelinebackbone::Init, config_file=config_file
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
		backbone_comm, $				; Object pointer for main backbone (for access in subroutines & modules) 
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
    
    if ~(keyword_set(config_file)) then config_file="DRSConfig.xml"

    print, "                                                    "
    PRINT, "*****************************************************"
    print, "*                                                   *"
    PRINT, "*          GPI DATA REDUCTION PIPELINE              *"
    print, "*                                                   *"
    print, "*                   VERSION 0.15                    *"
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

		self.GPICalDB = obj_new('gpicaldatabase', backbone=self)

		self.progressbar->set_calibdir, self.GPICalDB->get_calibdir()

		self.launcher = obj_new('launcher',/pipeline)
		
		; This is stored in a common block variable so that it is accessible
		; inside the Save_currdata function (which otherwise does not have
		; access to the backbone object). Yes, this is inelegant and ought to
		; be fixed probably. - MP

		backbone_comm = self ; stick into common block for global access

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

    IF PTR_VALID(Self.Data) THEN $
        FOR i = 0, N_ELEMENTS(*Self.Data)-1 DO BEGIN
            PTR_FREE, (*Self.Data)[i].Frames[*]
            PTR_FREE, (*Self.Data)[i].Headers[*]
            PTR_FREE, (*Self.Data)[i].UncertFrames[*]
            PTR_FREE, (*Self.Data)[i].FlagFrames[*]
        END

    PTR_FREE, Self.Data
    PTR_FREE, Self.Modules

    if keyword_set(LOG_GENERAL) then begin
        CLOSE, LOG_GENERAL
        FREE_LUN, LOG_GENERAL
    endif

END


;-----------------------------------------------------------------------------------------------------
; Procedure drpDefineStructs
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
			tempfile = tmppath+path_sep()+'temp.fits'

			; check for the error case where some other user already owns
			; /tmp/temp.fits on a multiuser machine. If necessary, fall back to
			; another filename with an appended number. 
			if file_test(tempfile,/write) then begin
				for i=0,100 do begin
					tempfile = tmppath+path_sep()+'temp'+strc(i)+'.fits'
					if not file_test(tempfile,/write) then break
				endfor
				if i eq 100 then begin
					self->Log, "Could not open **any** filename for writing in "+getenv('IDL_TMPDIR')+" after 100 attempts. Cannot send file to GPItv."
					return
				endif
			endif
			writefits, tempfile, filename_or_data, header
			self.launcher->queue, 'gpitv', filename=tempfile, session=session, _extra=_extra

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
    WHILE DRPCONTINUE EQ 1 DO BEGIN
        if ~(keyword_set(DEBUG)) then CATCH, Error else ERROR=0    ; Catch errors inside the pipeline. In debug mode, just let the code crash and stop
          IF Error EQ 1 THEN BEGIN
            PRINT, "Calling Self -> ErrorHandler..."
            Self -> ErrorHandler, CurrentDRF, QueueDir
            CLOSE, LOG_DRF
            FREE_LUN, LOG_DRF
        ENDIF

        CurrentDRF = self->GetNextDRF(Queuedir, found=nfound)
        ;IF CurrentDRF.Name NE '' THEN BEGIN
        IF nfound gt 0 THEN BEGIN
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
                
                Self -> OpenLog, CurrentDRF.Name + '.log', /DRF
                if ~strmatch(self.reductiontype,'On-Line Reduction') then $
                    Result = Self->Reduce() else $
                    Result = Self->ReduceOnLine()

                IF Result EQ OK THEN BEGIN
                    PRINT, "Success"
                    self->SetDRFStatus, CurrentDRF, 'done'
					self.progressbar->set_status, "Last DRF done OK! Watching for new DRFs but idle."
					self.progressbar->Set_action, '--'
                ENDIF ELSE BEGIN
                    PRINT, "Failure"
                    self->SetDRFStatus, CurrentDRF, 'failed'
                ENDELSE
                ; Free any remaining memory here
                IF PTR_VALID(Self.Data) THEN BEGIN
                    FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
                        ;PTR_FREE, (*Self.Data)[i].FlagFrames[*]
                        ;PTR_FREE, (*Self.Data)[i].UncertFrames[*]
                        PTR_FREE, (*Self.Data)[i].currFrame[*]
                        PTR_FREE, (*Self.Data)[i].Headers[*]
                        PTR_FREE, (*Self.Data)[i].Frames[*]
                    ENDFOR
                ENDIF ; PTR_VALID(Self.Data)

                ; We are done with the DRF, so close its log file
                CLOSE, LOG_DRF
                FREE_LUN, LOG_DRF
            ENDIF ELSE BEGIN  ; ENDIF continueAfterDRFParsing EQ 1
              ; This code if continueAfterDRFParsing == 0
              self->log, 'gpiPipelineBackbone::Run: Reduction failed due to parsing error in file ' + DRFFileName, /GENERAL
              drpSetStatus, CurrentDRF, QueueDir, 'failed'
              ; If we failed with outstanding data, then clean it up.
              IF PTR_VALID(Self.Data) THEN BEGIN
                FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
                  PTR_FREE, (*Self.Data)[i].FlagFrames[*]
                  PTR_FREE, (*Self.Data)[i].UncertFrames[*]
                  PTR_FREE, (*Self.Data)[i].Headers[*]
                  PTR_FREE, (*Self.Data)[i].Frames[*]
                ENDFOR
              ENDIF
            ENDELSE
        ;    drpMemoryMarkSimple, 'xh'
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
					;obj_destroy(self)
					DRPCONTINUE=0
					break
					;exit
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
    common PIP, lambda0, filename,wavcal,tilt, badpixmap, filter, dim, CommonWavVect, gpidisplay, meddec,suffix, header, heade,oBridge,listfilenames, numfile, painit,dir_sc, Dtel

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

        ;(*self.data).currframe        = ptr_new(READFITS(*((*self.data).frames[IndexFrame]), Header, /SILENT))
        filename= *((*self.Data).frames[IndexFrame])
        ;inputname = (*self.Data).inputdir+path_sep()+(*self.Data).fileNames[IndexFrame]
        ;print, (*self.Data).inputdir+path_sep()+filename
        ;(*self.data).currframe        = ptr_new(READFITS((*self.Data).inputdir+path_sep()+filename , Header, /SILENT))
		self.progressbar->set_action, "Reading FITS file "+filename
		if ~file_test(filename,/read) then begin
	    	self->Log, "ERROR: Unable to read file "+filename, /GENERAL, /DRF
            self->Log, 'Reduction failed: ' + filename, /GENERAL, /DRF
            return,NOT_OK
		endif

		fits_info, filename, n_ext = numext, /silent
        if (numext EQ 0) then (*self.data).currframe        = ptr_new(READFITS(filename , Header, /SILENT))
        if (numext ge 1) then begin
            (*self.data).currframe        = ptr_new(mrdfits(filename , 1, Header, /SILENT))
            headPHU = headfits(filename, exten=0)
            
        endif
        if n_elements( *((*self.data).currframe) ) eq 1 then if *((*self.data).currframe) eq -1 then begin
            self->Log, "ERROR: Unable to read file "+filename, /GENERAL, /DRF
            self->Log, 'Reduction failed: ' + filename, /GENERAL, /DRF
            return,NOT_OK 
        endif

        ; NOTE: there are two redundant ways to get the current filename in the code right now:
        ;print, *((*self.data).frames[IndexFrame])
        ;print,  (*self.Data).inputdir+path_sep()+(*self.Data).fileNames[IndexFrame]

        numfile=IndexFrame ; store the index in the common block


        ; update the headers - 
        ;  At this point the *(*self.data).Headers[IndexFrame] variable contains
        ;  ONLY the DRF appended in FITS header COMMENT form. 
        ;  Append this onto the REAL fits header we just read in from disk.
        ;
        if (numext GT 1) then begin
          header=[headPHU,header]
        endif
        SXADDPAR, *(*self.data).Headers[IndexFrame], "DATAFILE", filename

        SXDELPAR, header, 'END'
        *(*self.data).Headers[IndexFrame]=[header,*(*self.data).Headers[IndexFrame]]
        SXADDPAR, *(*self.data).Headers[IndexFrame], "END",''
        
        suffix=''

        ; FIXME this ought to be read in from a configuration file somewhere,
        ; not be hard-coded here in the software. 
;        filter = strcompress(sxpar( header ,'FILTER1', count=fcount),/REMOVE_ALL)
;        if fcount eq 0 then filter = strcompress(sxpar( header ,'FILTER'),/REMOVE_ALL)

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
	self->Log, "DRF Complete!",/general,/DRF
    if debug ge 1 then print, "########### end of reduction for that DRF  ################"
    PRINT, ''
    PRINT, SYSTIME(/UTC)
    PRINT, ''
    ;self.progressbar->Update,*self.Modules,indexModules, (*self.data).validframecount, IndexFrame,' Done'
    self.progressbar->Update, *self.Modules,indexModules, (*self.data).validframecount, IndexFrame,' Done.'

    RETURN, status

END

;-----------------------------------------------------------
;  gpiPipelineBackbone::SetupProgressBar
;
;	make sure the progress bar is (still) launched and valid.
pro  gpiPipelineBackbone::SetupProgressBar
  ;if (not(xregistered('procstatus', /noshow))) then create_progressbar2
  if not(xregistered('gpiprogressbar',/noshow)) then begin
		obj_destroy, self.progressbar
		self.progressbar = OBJ_NEW('gpiprogressbar')
		self.progressbar->set_GenLogF, self.generallogfilename

  endif
end



;-----------------------------------------------------------
; gpiPipelineBackbone::ReduceOnLine
;
; Run the specified commands in sequence to reduce the data online. 
;     This is for the realtime reduction.
;


FUNCTION gpiPipelineBackbone::ReduceOnLine

  COMMON APP_CONSTANTS
  common PIP, lambda0, filename,wavcal,tilt, badpixmap, filter, dim, CommonWavVect, gpidisplay, meddec,suffix, header, heade,oBridge,listfilenames, numfile, painit,dir_sc, Dtel

  PRINT, ''
  PRINT, SYSTIME(/UTC)
  PRINT, ''

  self->SetupProgressBar
  ;#############################################################
  ;loop for detection of  new data then apply modules
  temploop=1 ; TODO:implement a little GUI for stopping this loop and change OnLine parameters
  while temploop eq 1 do begin  
    ;nn=0
    ;for i=0,ii-1 do begin ;find nb files to consider in order
    ;  folder=stateF.listcontent(i)  ;to create the fitsfileslist array
    ;  filetypes = '*.{fts,fits}'
    ;    string3 = folder + filetypes
    ;    fitsfiles =FILE_SEARCH(string3,/FOLD_CASE)
    ;    nn=nn+(n_elements(fitsfiles))
    ;endfor
    ;fitsfileslist =STRARR(nn)

    ;n=0 ;list of files in fitsfileslist
    ;for i=0,ii-1 do begin
    folder=(*self.data).inputdir ;stateF.listcontent(i)
    filetypes = '*.{fts,fits}'
    fitsfiles =FILE_SEARCH(folder + path_sep() + filetypes,/FOLD_CASE)
    ;    fitsfileslist(n:n+n_elements(fitsfiles)-1) =fitsfiles
    n= n_elements(fitsfiles)
    ;endfor

    ; retrieve creation date
    date=dblarr(n_elements(fitsfiles))
    for j=0,n_elements(date)-1 do begin
        Result = FILE_INFO(fitsfiles[j] )
        date(j)=Result.ctime
    endfor
    ;sort files with creation date
    list2=fitsfiles(REVERSE(sort(date)))
    list3=list2(0:n_elements(list2)-1)
    ;widget_control, stateF.listfile_id, SET_VALUE= list3 ;display the list
    ;stop
    ;stateF.newlist=list3
    ;;loop for detection of new files
    ;  oBridge = OBJ_NEW('IDL_IDLBridge');, CALLBACK='callback_searchnewfits')
    ;  oBridge->SetVar,"chang",0
    ;  oBridge->SetVar,"dir",folder;stateF.listcontent(0:ii-1)
    ;  oBridge->SetVar,"listfile",list3
    ;  oBridge->SetVar,"list_id",0;stateF.listfile_id
    ;  ;widget_control,stateF.button_id,GET_VALUE=val
    ; ; widget_control,stateF.button_id,GET_VALUE=val
    ;  oBridge->SetVar,"button_value",'void'
    ;
    ;comm2="chang=detectnewfits(dir,listfile,list_id,button_value)"
    ;oBridge->Execute, comm2, /NOWAIT

    chang=''
    while chang eq '' do begin
      chang=gpidetectnewfits(folder,list3,0,'void')
      wait,1
    endwhile
 
    (*self.Data).validframecount=1
    (*self.Data).fileNames[0]=chang
    *((*self.Data).frames[0])=chang
    ;;;;;;;;;;;;;;;;;;;;;
    self->Log, 'Reducing data set.', /GENERAL, /DRF, depth=1
    FOR IndexFrame = 0, (*self.Data).validframecount-1 DO BEGIN
        if debug ge 1 then print, "########### start of file "+strc(indexFrame+1)+" ################"
        self->Log, 'Reducing file: ' + (*self.Data).fileNames[IndexFrame], /GENERAL, /DRF, depth=1

        ;(*self.data).currframe        = ptr_new(READFITS(*((*self.data).frames[IndexFrame]), Header, /SILENT))
        filename= *((*self.Data).frames[IndexFrame])
        ;inputname = (*self.Data).inputdir+path_sep()+(*self.Data).fileNames[IndexFrame]
        ;print, (*self.Data).inputdir+path_sep()+filename
         ;(*self.data).currframe        = ptr_new(READFITS((*self.Data).inputdir+path_sep()+filename , Header, /SILENT))
         (*self.data).currframe        = ptr_new(READFITS(filename , Header, /SILENT))
        if n_elements( *((*self.data).currframe) ) eq 1 then if *((*self.data).currframe) eq -1 then begin
              self->Log, "ERROR: Unable to read file "+filename, /GENERAL, /DRF
              self->Log, 'Reduction failed: ' + filename, /GENERAL, /DRF
              continue
        endif

        ; NOTE: there are two redundant ways to get the current filename in the code right now:
        ;print, *((*self.data).frames[IndexFrame])
        ;print,  (*self.Data).inputdir+path_sep()+(*self.Data).fileNames[IndexFrame]

        numfile=IndexFrame ; store the index in the common block


        ; update the headers - 
        ;  At this point the *(*self.data).Headers[IndexFrame] variable contains
        ;  ONLY the DRF appended in FITS header COMMENT form. 
        ;  Append this onto the REAL fits header we just read in from disk.
        ;
        SXADDPAR, *(*self.data).Headers[IndexFrame], "DATAFILE", filename
        SXDELPAR, header, 'END'
        *(*self.data).Headers[IndexFrame]=[header,*(*self.data).Headers[IndexFrame]]
        SXADDPAR, *(*self.data).Headers[IndexFrame], "END",''
        suffix=''

        ; FIXME this ought to be read in from a configuration file somewhere,
        ; not be hard-coded here in the software. 
        filter = strcompress(sxpar( header ,'FILTER1', count=fcount),/REMOVE_ALL)
        if fcount eq 0 then filter = strcompress(sxpar( header ,'FILTER'),/REMOVE_ALL)

        tabband=[['Z'],['Y'],['J'],['H'],['K'],['K1'],['K2']]
        parseband=WHERE(STRCMP( tabband, filter, /FOLD_CASE) EQ 1)
        case parseband of
            -1: CommonWavVect=-1
            0:  CommonWavVect=[0.95, 1.14, 37]
            1:  CommonWavVect=[0.95, 1.14, 37]
            2:  CommonWavVect=[1.12, 1.35, 37]
            3: CommonWavVect=[1.5, 1.8, 37]
            4:  ;CommonWavVect=[1.5, 1.8, 37]
            5:  CommonWavVect=[1.9, 2.19, 40]
            6: CommonWavVect=[2.13, 2.4, 40]
        endcase
        ;;detect type
        ;type = strcompress(sxpar( header ,'FILTER2', count=fcount),/REMOVE_ALL)
        ; if fcount eq 0 then type = strcompress(sxpar( header ,'DISPERSR'),/REMOVE_ALL)
        ;case type of
        ;            'Spectro': begin
        ;                   FindPro, 'gpidrfgui', dirlist=dirlist
                      
        caldat,systime(/julian),month,day,year, hour,minute,second
        datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
        hourstr = string(hour,minute,second,format='(i2.2,i2.2,i2.2)')  
        drffilename=datestr+'_'+hourstr+'_drf.waiting.xml'
        FILE_COPY, getenv('GPI_DRF_TEMPLATES_DIR')+'template_drf_online_1.xml', (*self.data).queuedir+path_sep()+drffilename
                        
        ;                      end
        ;        endcase
        ; Iterate over the modules in the 'Modules' array and run each.
        status = OK
        FOR indexModules = 0, N_ELEMENTS(*self.Modules)-1 DO BEGIN
            ; Continue if the current module's skip field equals 0 and no previous module
            ; has failed (Result = 1).
            IF ((*self.Modules)[indexModules].Skip EQ 0) AND (status EQ OK) THEN BEGIN
                ;Result = Self -> RunModule(Modules, indexModules, Data[IndexFrame], Backbone)
                status = Self -> RunModule(*self.Modules, indexModules)
            ENDIF
        ENDFOR

        ; Log the result.
    if status eq GOTO_NEXT_FILE then self->Log, 'Continuing on to next file...', /GENERAL, /DRF, depth=2
        IF status EQ OK or status eq GOTO_NEXT_FILE THEN self->Log, 'Reduction successful: ' + filename, /GENERAL, /DRF $
        ELSE self->Log, 'Reduction failed: ' + filename, /GENERAL, /DRF

    if debug ge 1 then print, "########### end of file "+strc(indexframe+1)+" ################"
    ENDFOR

    if debug ge 1 then print, "########### end of reduction for that DRF  ################"
    PRINT, ''
    PRINT, SYSTIME(/UTC)
    PRINT, ''
    self.progressbar->Update,*self.Modules,indexModules, (*self.data).validframecount, IndexFrame,' Done'
  endwhile
  RETURN, status

END

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
	status = call_function( Modules[ModNum].IDLCommand, *self.data, Modules, self )


    IF status EQ NOT_OK THEN BEGIN            ;  The module failed
        IF (STRCMP(!ERR_STRING, "Variable", 8, /FOLD_CASE) EQ 1) THEN BEGIN
            drpIOLock
            PRINT, "drpPipeline::RunModule: " + !ERROR_STATE.MSG
            PRINT, "drpPipeline::RunModule: " + !ERR_STRING
            PRINT, "drpPipeline::RunModule: " + CALL_STACK
            PRINT, "drpPipeline::RunModule: " + Modules[ModNum].CallSequence
            PRINT, "drpPipeline::RunModule: " + Modules[ModNum].Name
            drpIOUnlock
        ENDIF
        self->Log, 'ERROR: ' + !ERR_STRING, /GENERAL, /DRF
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
      PRINTF, LOG_GENERAL, 'Data Reduction Pipeline'
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
    PRINTF, LUN, Time + ' ' + localText    ; Log to General file
    FLUSH, LUN

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
            IF PTR_VALID(Self.Data) THEN BEGIN
                FOR i = N_ELEMENTS(*Self.Data)-1, 0, -1 DO BEGIN
                    PTR_FREE, (*Self.Data)[i].FlagFrames[*]
                    PTR_FREE, (*Self.Data)[i].UncertFrames[*]
                    PTR_FREE, (*Self.Data)[i].Headers[*]
                    PTR_FREE, (*Self.Data)[i].Frames[*]
                ENDFOR
            ENDIF
        ENDIF
    ENDIF ELSE BEGIN
    ; Will this cause a recursion error?
        MESSAGE, 'ERROR in gpiPipelineBackbone::ErrorHandler - ' + STRTRIM(STRING(!ERR),2) + ': ' + !ERR_STRING, /INFO
    ENDELSE

    CATCH, /CANCEL
END

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
			progressbar: obj_new(), $
			launcher: obj_new(), $
			gpicaldb: obj_new(), $
            ReductionType:'', $
            CurrentlyExecutingModuleNumber:0, $
			generallogfilename: '', $
            LogPath:''}

END


