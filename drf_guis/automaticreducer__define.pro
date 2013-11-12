;---------------------------------------------------------------------
;automaticreducer__define.PRO
;
;	Automatic detection and parsing of GPI files. 
;
;	This inherits the Parser GUI, and internally makes use of Parser GUI
;	functionality for parsing the files, but does not display the parser GUI
;	widgets in any form. 
;
; HISTORY:
;
; Jerome Maire - 15.01.2011
; 2012-02-06 MDP: Various updated to path handling
; 			Also updated to use WIDGET_TIMER events for monitoring the directory
; 			so this works properly with the event loop
; 2012-02-06 MDP: Pretty much complete rewrite.
; 2013-03-28 JM: added manual shifts of the wavecal
;---------------------------------------------------------------------

;+-------------------------
; automaticreducer::set_default_filespec
;    Set default wildcard for files to watch for
;-------------------------
pro automaticreducer::set_default_filespec
	if keyword_set(gpi_get_setting('at_gemini', default=0,/silent)) then begin
		self.watch_filespec = 'S20'+gpi_datestr(/current)+'S*.fits'
	endif else begin
		self.watch_filespec = '*.fits'
	endelse
end

;+-----------------------------------------------------------------------
; Do an initial check of the files that are already in that directory. 
;
; Determine the files that are there already
; If there are new files:
; 	Display the list sorted by file access time
;
; KEYWORDS:
;    count	returns the # of files found
;------------------------------------------------------------------------

function automaticreducer::refresh_file_list, count=count, init=init, _extra=_extra

    searchpattern = self.watch_directory + path_sep() + self.watch_filespec
	current_files =FILE_SEARCH(searchpattern,/FOLD_CASE, count=count)
	
	if count gt 0 and keyword_set(self.ignore_indiv_reads) then begin
		; Ignore any CDS/UTR individual reads, which are saved as
		; basename_001.fits, basename_002.fits, etc. 
		mask_real_files = ~strmatch(current_files, '*_[0-9][0-9][0-9].fits')
		wreal = where(mask_real_files, count)
		if count eq 0 then current_files='' else current_files = current_files[wreal]
	endif


	dateold=dblarr(n_elements(current_files))
	for j=0L,long(n_elements(current_files)-1) do begin
		Result = FILE_INFO(current_files[j] )
		dateold[j]=Result.ctime
	endfor
	list3=current_files[(sort(dateold))]  ; descending

	if keyword_set(init) then begin
		if count gt 0 then $
			self->Log, 'Found '+strc(count) +" files on startup of automatic processing. Skipping those..." $
		else $
			self->Log, 'No FITS files found in that directory yet...' 
		widget_control, self.listfile_id, SET_VALUE= list3 
		widget_control, self.listfile_id, set_uvalue = list3  ; because oh my god IDL is stupid and doesn't provide any way to retrieve
															  ; values from a  list widget!   Argh. See
															  ; http://www.idlcoyote.com/widget_tips/listselection.html 
		widget_control, self.listfile_id, set_list_top = 0>(n_elements(list3) -8) ; update the scroll position in the list
		self.previous_file_list = ptr_new(current_files) ; update list for next invocation
		count=0
		return, ''

	endif

	new_files = cmset_op( current_files, 'AND' ,/NOT2, *self.previous_file_list, count=count)

	if count gt 0 then begin
		widget_control, self.listfile_id, SET_VALUE= list3 
		widget_control, self.listfile_id, set_uvalue = list3  ; because oh my god IDL is stupid and doesn't provide any way to retrieve this later
		widget_control, self.listfile_id, set_list_top = 0>(n_elements(list3) -8) ; update the scroll position in the list
		*self.previous_file_list = current_files ; update list for next invocation
		return, new_files
	endif else begin
		return, ''
	endelse



end

;--------------------------------------------------------------------------------



pro automaticreducer::run
	; This is what runs every 1 second to check the contents of that directory

	if ~ptr_valid( self.previous_file_list) then begin
		ignore_these = self->refresh_file_list(/init) 
		return
	endif

	new_files = self->refresh_file_list(count=count)
	
	if count eq 0 then return  ; no new files found

	message,/info, 'Found '+strc(count)+" new files to process!"
	for i=0,n_elements(new_files)-1 do self->log, "New file: "+new_files[i]

	self->handle_new_files, new_files

end

;-------------------------------------------------------------------

pro automaticreducer::handle_new_files, new_filenames ;, nowait=nowait
	; Handle one or more new files that were either
	;   1) detected by the run loop, or
	;   2) manually selected and commanded to be reprocessed by the user.
	
	   
	; process the file right away
	for i=0L,n_elements(new_filenames)-1 do begin
		if strc(new_filenames[i]) eq  '' then begin
			message,/info, ' Received an empty string as a filename; ignoring it.'
			continue
		endif
		finfo = file_info(new_filenames[i])
		if (finfo.size ne 20998080) and (finfo.size ne 21000960) and (finfo.size ne 16790400) then begin
			message,/info, "File size is not an expected value: "+strc(finfo.size)+" bytes. Waiting 0.5 s for file write to complete?"
			wait, 0.5
		endif

		if keyword_set(self.view_in_gpitv) then self->view_file, new_filenames[i]
		self->reduce_one, new_filenames[i];,wait=~(keyword_set(nowait))
	endfor


end

;-------------------------------------------------------------------

pro automaticreducer::reduce_one, filenames, wait=wait
	; Reduce one single file at a time

    if strc(filenames[0]) eq '' then begin
        message,/info, ' Received an empty string as a filename; ignoring it.'
        return
    endif

    if keyword_set(wait) then  begin
        message,/info, "Waiting 0.5 s to ensure FITS header gets updated first?"
        wait, 0.5
    endif

	if self.user_template eq '' then begin
		; Determine default template based on file type

		info = gpi_load_fits(filenames[0], /nodata)
		prism = strupcase(gpi_simplify_keyword_value(gpi_get_keyword( *info.pri_header, *info.ext_header, 'DISPERSR', count=dispct) ))
		obsclass = strupcase(gpi_simplify_keyword_value(gpi_get_keyword( *info.pri_header, *info.ext_header, 'OBSCLASS', count=obsclassct) ))
		gcallamp = strupcase(gpi_simplify_keyword_value(gpi_get_keyword( *info.pri_header, *info.ext_header, 'GCALLAMP', count=gcallampct) ))

		if (dispct eq 0) or (strc(prism) eq '') then begin
			message,/info, 'Missing or blank DISPERSR keyword! '
		    prism = 'PRISM' ; this used to be user selectable but the keywords are now robust,
							    ; so there is no need to clutter up the GUI with
								; this option any more. 

			;if widget_info(self.b_spectral_id,/button_set) then prism = 'PRISM'
			;if widget_info(self.b_undispersed_id,/button_set) then prism='WOLLASTON'
			;if widget_info(self.b_polarization_id,/button_set) then prism = 'OPEN'
		endif

		if ((prism ne 'PRISM') and (prism ne 'WOLLASTON') and (prism ne 'OPEN')) then begin
			message,/info, 'Unknown DISPERSR: '+prism+". Must be one of {PRISM, WOLLASTON, OPEN} or their Gemini-style equivalents."
			;if widget_info(self.b_spectral_id,/button_set) then prism = 'PRISM'
			;if widget_info(self.b_undispersed_id,/button_set) then prism='WOLLASTON'
			;if widget_info(self.b_polarization_id,/button_set) then prism = 'OPEN'
		    prism = 'PRISM' ; this used to be user selectable but see above note.
			message,/info, 'Applying default setting instead: '+prism
		endif

		case prism of
		'PRISM': begin
			if obsclass eq 'ARC' and gcallamp eq 'XE' then begin
				templatename='Quick Wavelength Solution'
			endif else begin
				templatename='Quicklook Automatic Datacube Extraction'
			endelse
		end
		'WOLLASTON': templatename='Quicklook Automatic Polarimetry Extraction'
		'OPEN':templatename='Quicklook Automatic Undispersed Extraction'
		endcase
	endif else begin
		templatename = self.user_template
	endelse
		

	
	self->Log, "Using template: "+templatename
	templatefile= self->lookup_template_filename(templatename) ; gpi_get_directory('GPI_DRP_TEMPLATES_DIR')+path_sep()+templatename
	if templatefile eq '' then return ; couldn't find requested template therefore do nothing.

	drf = obj_new('DRF', templatefile, parent=self,/silent)
	drf->set_datafiles, filenames
	drf->set_outputdir,'AUTOMATIC' ;/autodir

	wupdate =  drf->find_module_by_name('Update Spot Shifts for Flexure', count)
	if count ne 1 then begin
		message,/info, "Can't find 'Update Spot Shifts for Flexure' primitive; can't apply settings. Continuing anyway."
	endif else begin

		drf->set_module_args, wupdate, method=self.flexure_mode
		if self.flexure_mode eq 'Manual' then begin
			widget_control, self.shiftx_id, get_value=shiftx
			widget_control, self.shifty_id, get_value=shifty
			drf->set_module_args, wupdate, method=self.flexure_mode, manual_dx=shiftx,  manual_dy=shifty
		endif

	endelse



	; generate a nice descriptive filename
	first_file_basename = (strsplit(file_basename(filenames[0]),'.',/extract))[0]

	drf->save, 'auto_'+first_file_basename+'_'+drf->get_datestr()+'.waiting.xml',/autodir
	drf->queue

	obj_destroy, drf

end


;-------------------------------------------------------------------
PRO automaticreducer_event, ev
	; simple wrapper to call object routine
    widget_control,ev.top,get_uvalue=storage
   
    if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
end

;-------------------------------------------------------------------
pro automaticreducer::event, ev
	; Event handler for automatic parser GUI


	uname = widget_info(ev.id,/uname)


	if uname eq 'top_menu' then begin
		; for some reason these events don't have a named structure?? I hate IDL
		; sometimes.
		case ev.value of
		'Change Directory...': self->change_directory
		'Change Filename Wildcard...': self->change_wildcard
		'Quit Autoreducer': self->confirm_close
		'View new files in GPITV': begin
			self.view_in_gpitv = ~ self.view_in_gpitv
			self.menubar->set_check_state, 'View new files in GPITV', self.view_in_gpitv
		end
		'Ignore individual UTR/CDS readout files': begin
			self.ignore_indiv_reads = ~ self.ignore_indiv_reads
			self.menubar->set_check_state, 'Ignore individual UTR/CDS readout files', self.ignore_indiv_reads
	
		end
		; Flexure compensation: 
		'None': self->set_flexure_mode, 'None'
		'Lookup': self->set_flexure_mode, 'Lookup'
		'Manual': self->set_flexure_mode, 'Manual'
		'Autoreducer Help...': gpi_open_help, 'usage/autoreducer.html',/dev
		'GPI DRP Help...': gpi_open_help, '',/dev
		endcase
		return

	endif

	case tag_names(ev, /structure_name) of
		'WIDGET_TIMER' : begin
			self->run
			widget_control, ev.top, timer=1 ; check again at 1 Hz
			return
		end

      'WIDGET_TRACKING': begin ; Mouse-over help text display:
        if (ev.ENTER EQ 1) then begin 
              case uname of 
                  'changedir':textinfo='Click to select a different directory to watch for new files.'
                  'changewildcard':textinfo='Click to enter a new filename specification to watch for new files.'
				  'one': textinfo='Each new file will be reduced on its own right away.'
				  'keep': textinfo='All new files will be reduced in a batch whenever you command.'
                  'search':textinfo='Start the looping search of new FITS placed in the right-top panel directories. Restart the detection for changing search parameters.'
                  'filelist':textinfo='List of most recent detected FITS files in the watched directory. '
				  'view_in_gpitv': textinfo='Automatically display new files in GPITV.'
				  'ignore_raw_reads': textinfo='Ignore any extra files for the CDS/UTR reads, if present.'
                  'one':textinfo='Parse and process new file in a one-by-one mode.'
                  'new':textinfo='Change parser queue to process when new type detected.'
                  'keep':textinfo='keep all detected files in parser queue.'
                  'flush':textinfo='Delete all files in the parser queue.'
				  'Start': textinfo='Press to start scanning that directory for new files'
				  'Reprocess': textinfo='Select one or more existing files, then press this to re-reduce them.'
				  'View_one': textinfo='Select one existing file, then press this to view in GPItv.'
                  "QUIT":textinfo='Click to close this window.'
              else:textinfo=' '
              endcase
              widget_control,self.information_id,set_value=textinfo
          ;widget_control, event.ID, SET_VALUE='Press to Quit'   
        endif else begin 
              widget_control,self.information_id,set_value=''
          ;widget_control, event.id, set_value='what does this button do?'   
        endelse 
        return
    end
      
	'WIDGET_BUTTON':begin
		case uname of 
	    'changedir': self->change_directory
	    'changewildcard': self->change_wildcard
		'flush': self.parserobj=gpiparsergui(/cleanlist)
		;'alwaysexec': self.alwaysexecute=widget_info(self.alwaysexecute_id,/button_set)
		'changeshift': begin
			directory = gpi_get_directory('calibrations_DIR') 
			widget_control, self.shiftx_id, get_value=shiftx
			widget_control, self.shifty_id, get_value=shifty
			writefits, directory+path_sep()+"shifts.fits", [float(shiftx),float(shifty)]
		end
		'QUIT': self->confirm_close
		'Start': begin
			message,/info,'Starting watching directory '+self.watch_directory
			self->Log, 'Starting watching directory '+self.watch_directory
			widget_control, self.top_base, timer=1  ; Start off the timer events for updating at 1 Hz
		end
        'Reprocess': begin
                   widget_control, self.listfile_id, get_uvalue=list_contents
                   ind=widget_INFO(self.listfile_id,/LIST_SELECT)
                   
                   if ind[0] eq -1 then begin
                                ;error handling to prevent crash if someone selects 'reprocess
								;selection' prior to pressing start.
                      message,/info, 'No files to reprocess. Press Start to load files in the directory being watched.'
                      ind=0
                   endif
                   
                   if list_contents[ind[0]] ne '' then begin
                      
                      self->Log,'User requested reprocessing of: '+strjoin(list_contents[ind], ", ")
                      self->handle_new_files, list_contents[ind] ;, /nowait
                   endif
	
		end
		'View_one' : begin
			widget_control, self.listfile_id, get_uvalue=list_contents

			ind=widget_INFO(self.listfile_id,/LIST_SELECT)
			ind = ind[0] ; only keep first

			if ind eq -1 then begin
					;error handling to prevent
					;crash if someone selects 'View File' prior to pressing start.
				  message,/info, 'No file selected. Press Start to load files in the directory being watched.'
				  ind=0
			endif

			if list_contents[ind] ne '' then self->view_file, list_contents[ind], /log
	
		end
		'default_recipe' : begin
			widget_control, self.seqid, sensitive=0
			self.user_template = ''
		end
		'select_recipe' : begin
			widget_control, self.seqid, sensitive=1
        	ind=widget_info(self.seqid,/DROPLIST_SELECT)
			self.user_template=((*self.templates).name)[ind]
		end
		else: begin
			message,/info, 'Unknown button event: '+uname
			stop
		endelse
		endcase

	end 

	'WIDGET_LIST':begin ; double click on file list to view file
		if uname eq 'filelist' then begin
            if ev.clicks eq 2 then begin
              	ind=widget_INFO(self.listfile_id,/LIST_SELECT)
                widget_control, self.listfile_id, get_uvalue=list_contents
            
				if list_contents[ind] ne '' then self->view_file, list_contents[ind], /log
            endif
		endif
	end
  	'WIDGET_KILL_REQUEST': self->confirm_close
  	'WIDGET_DROPLIST': begin 
		if uname eq 'select_template' then begin
			print, self.templates[ind]
        	ind=widget_info(self.seqid,/DROPLIST_SELECT)
			self.user_template=self.templates[ind]
		endif
	end
	
	'WIDGET_TEXT_CH':begin
		; text entry events are expected for the WID_DX and WID_DY fields. We do
		; nothing with them now and instead just read in the values of those
		; fields in ::reduceone whenever creating a new DRF

		if uname ne 'WID_DX' and uname ne 'WID_DY' then message,/info, 'Got an unexpected text entry event for widget with uname='+uname
	
	end
	'WIDGET_MENU': begin
		stop
	end
    else:   begin
		print, "No handler defined for event of type "+tag_names(ev, /structure_name)+" in automaticreducer"
		;stop
	endelse
endcase
end
;--------------------------------------
; Display one file
pro automaticreducer::view_file, filename, log=log
	if keyword_set(log) then self->Log,'User requested to view: '+filename

	if obj_valid(self.launcher_handle) then $
		self.launcher_handle->launch, 'gpitv', filename=filename, session=45 ; arbitrary session number picked to be 1 more than this launcher

end

;--------------------------------------
; Ask for new path then change directory
pro automaticreducer::change_directory
	dir = DIALOG_PICKFILE(PATH=self.watch_directory, Title='Choose directory to watch for new raw GPI files...',/must_exist , /directory)
	if dir ne '' then begin
		self->Log, 'Directory changed to '+dir
		self.watch_directory=dir
		widget_control, self.watchdir_id, set_value=dir
		ptr_free, self.previous_file_list ; we have lost info on our previous files so start over
	endif

end
;--------------------------------------
; Ask for new filename spec then change 
pro automaticreducer::change_wildcard


	new_wildcard = TextBox(Title='Provide New Filename Wildcard...', Group_Leader=self.top_base, $
      Label='Filename Wildcard (can use * and ?): ', Cancel=cancelled, XSize=200, Value=self.watch_filespec)
   	IF NOT cancelled THEN BEGIN
		self.watch_filespec= new_wildcard
		widget_control, self.wildcard_id, set_value=new_wildcard
		; let's not forget previous files here, this just updates what matches happen in the future
		;ptr_free, self.previous_file_list ; we have lost info on our previous files so start over
   	ENDIF

end

;--------------------------------------
; Set flexure mode, and toggle manual entry field visibility appropriately
PRO automaticreducer::set_flexure_mode, modestr
	self.flexure_mode = modestr

	widget_control, self.flex_base_id, map=self.flexure_mode eq 'Manual'

	modes = ['None','Manual','Lookup']
	for i=0,2 do self.menubar->set_check_state, modes[i], self.flexure_mode eq modes[i]
	print, "Flexure handling mode is now "+self.flexure_mode
end

;--------------------------------------
; kill the window and clear variables to conserve
; memory when quitting.  
PRO automaticreducer::cleanup

		;self.continue_scanning=0
	; Kill top-level base if it still exists
	if (xregistered ('automaticreducer')) then widget_control, self.top_base, /destroy

	;self->parsergui::cleanup ; will destroy all widgets
	;reprocess_id = WIDGET_BUTTON(buttonbar,Value='Reprocess Selection',Uname='Reprocess', /tracking_events)

	heap_gc

	obj_destroy, self

end


;-------------------------------------------------
function automaticreducer::init, groupleader, _extra=_extra
	; Initialization code for automatic processing GUI

	self.name='GPI Automatic Reducer'
	self.watch_directory=self->get_input_dir()
    self.view_in_gpitv = 1
    self.ignore_indiv_reads = 1


	; should we include any flexure compensation in the recipes? 
	; By default turn this on ONLY if there is at least one flexure cal
	; file present in the Calibrations DB
	cdb= obj_new('gpicaldatabase')
	caltable = cdb->get_data()
	availtypes =  uniqvals( (*caltable).type)
	wflexurefile = where(availtypes eq 'Flexure shift Cal File', flexurect)
	if flexurect eq 0 then self.flexure_mode = 'None' else self.flexure_mode = 'Lookup'

	self->set_default_filespec

	self.top_base = widget_base(title = self.name, $
				   /column,  $
				   resource_name='GPI_DRP', $
				   MBAR=bar, $ 
				   /tlb_size_events,  /tlb_kill_request_events)

	tmp_struct = {cw_pdmenu_s, flags:0, name:''}
	top_menu_desc = [ $
                  {cw_pdmenu_s, 1, 'File'}, $ ; file menu;
                  {cw_pdmenu_s, 0, 'Change Directory...'}, $
                  {cw_pdmenu_s, 0, 'Change Filename Wildcard...'}, $
                  {cw_pdmenu_s, 2, 'Quit Autoreducer'}, $
                  {cw_pdmenu_s, 1, 'Options'}, $
                  {cw_pdmenu_s, 8, 'View new files in GPITV'},$
                  {cw_pdmenu_s, 8, 'Ignore individual UTR/CDS readout files'}, $
                  {cw_pdmenu_s, 3, 'Flexure Compensation'}, $
                  {cw_pdmenu_s, 8, 'None'},$
                  {cw_pdmenu_s, 8, 'Lookup'},$
                  {cw_pdmenu_s, 10, 'Manual'},$
                  {cw_pdmenu_s, 1, 'Help'}, $         ; help menu
                  {cw_pdmenu_s, 0, 'Autoreducer Help...'}, $
                  {cw_pdmenu_s, 2, 'GPI DRP Help...'} $
                ]


	self.menubar = obj_new('checkable_menu',  $
	 				 bar, top_menu_desc, $
                     ids = menu_ids, $
                     /mbar, $
                     /help, $
                     /return_name, $
                     uvalue = 'top_menu', $
					 uname='top_menu')


	base_dir = widget_base(self.top_base, /row)
	void = WIDGET_LABEL(base_dir,Value='Directory being watched: ', xsize=140, /align_left)
	self.watchdir_id =  WIDGET_LABEL(base_dir,Value=self.watch_directory, xsize=250, /align_left)
	button_id = WIDGET_BUTTON(base_dir,Value='Change...',Uname='changedir',/align_right,/tracking_events)

	base_dir = widget_base(self.top_base, /row)
	void = WIDGET_LABEL(base_dir,Value='Filename wildcard spec: ', xsize=140, /align_left)
	self.wildcard_id =  WIDGET_LABEL(base_dir,Value=self.watch_filespec, xsize=250,  /align_left)
	button_id = WIDGET_BUTTON(base_dir,Value='Change...',Uname='changewildcard',/align_right,/tracking_events)

	   
;	base_dir = widget_base(self.top_base, /row)
;	void = WIDGET_LABEL(base_dir,Value='Reduce new files:')    
;	parsebase = Widget_Base(base_dir, UNAME='parsebase' ,ROW=1 ,/EXCLUSIVE, frame=0)
;	self.parseone_id =    Widget_Button(parsebase, UNAME='one'  $
;		  ,/ALIGN_LEFT ,VALUE='Automatically as each file arrives', /tracking_events)
;	;self.parsenew_id =    Widget_Button(parsebase, UNAME='new'  $
;		  ;,/ALIGN_LEFT ,VALUE='Flush filenames when new filetype',uvalue='new' )
;	self.parseall_id =    Widget_Button(parsebase, UNAME='keep'  $
;		  ,/ALIGN_LEFT ,VALUE='When user requests', /tracking_events ,sensitive=0) 
;	widget_control, self.parseone_id, /set_button 
;
	self->scan_templates


	base_dir = widget_base(self.top_base, /row)
	void = WIDGET_LABEL(base_dir,Value='Reduce using:')
	parsebase = Widget_Base(base_dir, UNAME='kindbase' ,ROW=1 ,/EXCLUSIVE, frame=0)
	self.b_default_rec_id =    Widget_Button(parsebase, UNAME='default_recipe'  $
	        ,/ALIGN_LEFT ,VALUE='Default automatic recipes',/tracking_events)
	self.b_specific_rec_id =    Widget_Button(parsebase, UNAME='select_recipe'  $
	        ,/ALIGN_LEFT ,VALUE='Specific recipe',/tracking_events, sensitive=1)
	widget_control, self.b_default_rec_id, /set_button 

	base_dir = widget_base(self.top_base, /row)
	self.seqid = WIDGET_DROPLIST(base_dir , title='Select template:', frame=0, Value=(*self.templates).name, $
		uvalue='select_template',resource_name='XmDroplistButton', sensitive=0)


;	base_dir = widget_base(self.top_base, /row)
;	void = WIDGET_LABEL(base_dir,Value='Default disperser if missing keyword:')
;	parsebase = Widget_Base(base_dir, ROW=1 ,/EXCLUSIVE, frame=0)
;	self.b_spectral_id =    Widget_Button(parsebase, UNAME='Spectral'  $
;	        ,/ALIGN_LEFT ,VALUE='Spectral',/tracking_events)
;	self.b_undispersed_id =    Widget_Button(parsebase, UNAME='Undispersed'  $
;	        ,/ALIGN_LEFT ,VALUE='Undispersed',/tracking_events, sensitive=1)
;	self.b_polarization_id =    Widget_Button(parsebase, UNAME='Polarization'  $
;	        ,/ALIGN_LEFT ,VALUE='Polarization',/tracking_events, sensitive=1)
;	
;	widget_control, self.b_undispersed_id, /set_button 
  
    ;directory = gpi_get_directory('calibrations_DIR') 
  
	self.flex_base_id = widget_base(self.top_base, /row, map=0)

	if !version.os eq 'darwin' then ysize=30 else ysize=24

	tmp = widget_label(self.flex_base_id ,/ALIGN_LEFT , value="IFS Internal Flexure     ")

	self.label_dx_id = Widget_Label(self.flex_base_id ,/ALIGN_LEFT ,VALUE='DX: ')
	self.shiftx_id = Widget_Text(self.flex_base_id, UNAME='WID_DX'  $
							  ,SCR_XSIZE=56 ,SCR_YSIZE=ysize  $
							  ,SENSITIVE=1 ,XSIZE=20 ,YSIZE=1, value=shiftx, EDITABLE=1)
	self.label_dy_id = Widget_Label(self.flex_base_id ,/ALIGN_LEFT ,VALUE=' DY: ')
	self.shifty_id = Widget_Text(self.flex_base_id, UNAME='WID_DY'  $
                                ,SCR_XSIZE=56 ,SCR_YSIZE=ysize  $
                                ,SENSITIVE=1 ,XSIZE=20 ,YSIZE=1, value=shifty, EDITABLE=1)

	widget_control, self.flex_base_id, map= (self.flexure_mode eq 'Manual')


	self.menubar->set_check_state, 'View new files in GPITV', self.view_in_gpitv
	self.menubar->set_check_state, 'Ignore individual UTR/CDS readout files', self.ignore_indiv_reads
	self->set_flexure_mode, self.flexure_mode ; null op but sets the checkboxes appropriately

	;----	

	void = WIDGET_LABEL(self.top_base,Value='Detected FITS files:')
	self.listfile_id = WIDGET_LIST(self.top_base,YSIZE=10,  /tracking_events,uname='filelist',/multiple, uvalue='')
	widget_control, self.listfile_id, SET_VALUE= ['','','     ** not scanning anything yet; press the Start button below to begin **']


	lab = widget_label(self.top_base, value="History:")
	self.widget_log=widget_text(self.top_base,/scroll, ysize=8, xsize=60, /ALIGN_LEFT, uname="text_status",/tracking_events)

	buttonbar = widget_base(self.top_base, row=1)

	self.start_id = WIDGET_BUTTON(buttonbar,Value='Start',Uname='Start', /tracking_events)
	reprocess_id = WIDGET_BUTTON(buttonbar,Value='View File',Uname='View_one', /tracking_events)
	reprocess_id = WIDGET_BUTTON(buttonbar,Value='Reprocess Selection',Uname='Reprocess', /tracking_events)

	button3=widget_button(buttonbar,value="Close",uname="QUIT", /tracking_events)

	self.information_id=widget_label(self.top_base,uvalue="textinfo",xsize=450,value='                                                                                ')

	storage={ group:'', self: self} ; used to get handle to self in widget callbacks
	widget_control,self.top_base ,set_uvalue=storage,/no_copy


	; Realize the widgets and run XMANAGER to manage them.
	; Register the widget with xmanager if it's not already registered
	if (not(xregistered('automaticreducer', /noshow))) then begin
		WIDGET_CONTROL, self.top_base, /REALIZE
		XMANAGER, 'automaticreducer', self.top_base, /NO_BLOCK
	endif

	
	RETURN, 1

END
;-----------------------
pro automaticreducer::set_launcher_handle, launcher
	self.launcher_handle = launcher
end


;-----------------------
pro automaticreducer__define



stateF={  automaticreducer, $
    parserobj:obj_new(),$
	launcher_handle: obj_new(), $	; handle to the launcher, *if* we were invoked that way.
    watch_directory:'',$			; initial root  directory for the tree
	watch_filespec: '*.fits', $		; file windcard spec
    user_template:'',$				; user-specified template to execute when fits file double clicked
	flexure_mode: '', $				; how to handle flexure in recipes?
    listfile_id:0L,$;wid id for list of fits file
	b_default_rec_id :0L,$			; widget ID for default recipe button
	b_specific_rec_id :0L,$			; widget ID for specific chosen recipe button
	flex_base_id:0L,$				; widget ID for flexure widgets base
	label_dx_id:0L,$				; widget ID for flexure delta X label
	label_dy_id:0L,$				; widget ID for flexure delta Y label
	shiftx_id:0L,$					; widget ID for flexure delta X
	shifty_id:0L,$					; widget ID for flexure delta Y
	watchdir_id: 0L, $				; widget ID for directory label display
	wildcard_id: 0L, $				; widget ID for file wildcard spec display
	start_id: 0L, $					; widget ID for start parsing button
    information_id:0L,$				; widget ID for info status bar
    maxnewfile:0L,$
    isnewdirroot:0,$ ;flag for  root dir
    button_id:0L,$ 
	previous_file_list: ptr_new(), $ ; List of files that have previously been encountered
	view_in_gpitv: 0L, $		; Setting: View in GPITv? 
	ignore_indiv_reads: 0L, $	; Setting: Ignore individual reads?
    INHERITS parsergui} ;wid for detect-new-files button

end
