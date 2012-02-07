;---------------------------------------------------------------------
;automaticproc3__define.PRO
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
;---------------------------------------------------------------------





function automaticproc3::refresh_file_list, count=count, init=init, _extra=_extra
	; Do the initial check of the files that are already in that directory. 
	;
	; Determine the files that are there already
	; If there are new files:
	; 	Display the list sorted by file access time
	;
	; KEYWORDS:
	;    count	returns the # of files found

    filetypes = '*.{fts,fits}'
    searchpattern = self.dirinit + path_sep() + filetypes
	current_files =FILE_SEARCH(searchpattern,/FOLD_CASE, count=count)
	dateold=dblarr(n_elements(current_files))
	for j=0L,long(n_elements(current_files)-1) do begin
		Result = FILE_INFO(current_files[j] )
		dateold[j]=Result.ctime
	endfor
	;list3=current_files[REVERSE(sort(dateold))] ; ascending
	list3=current_files[(sort(dateold))]  ; descending

	if keyword_set(init) then begin
		if count gt 0 then $
			self->Log, 'Found '+strc(count) +" files on startup of automatic processing. Skipping those..." $
		else $
			self->Log, 'No FITS files found in that directory yet...' 
		widget_control, self.listfile_id, SET_VALUE= list3 ;[0:(n_elements(list3)-1)<(self.maxnewfile-1)] ;display the list
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
		widget_control, self.listfile_id, SET_VALUE= list3 ;[0:(n_elements(list3)-1)<(self.maxnewfile-1)] ;display the list
		widget_control, self.listfile_id, set_uvalue = list3  ; because oh my god IDL is stupid and doesn't provide any way to retrieve this later
		widget_control, self.listfile_id, set_list_top = 0>(n_elements(list3) -8) ; update the scroll position in the list
		*self.previous_file_list = current_files ; update list for next invocation
		return, new_files
	endif else begin
		return, ''
	endelse



end

;--------------------------------------------------------------------------------



pro automaticproc3::run
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


;	if chang ne '' then begin
;		  widget_control, self.listfile_id, SET_VALUE= list2[0:(n_elements(list2)-1)<(self.maxnewfile-1)] ;display the list
;		  ;check if the file has been totally copied
;		  self.parserobj=gpiparsergui( chang,  mode=self.parsemode)
;	endif
end

;-------------------------------------------------------------------

pro automaticproc3::handle_new_files, new_filenames
	; Handle one or more new files that were either
	;   1) detected by the run loop, or
	;   2) manually selected and commanded to be reprocessed by the user.
	;
	
	
	   
	if self.parsemode eq 1 then begin
		; process the file right away
		for i=0L,n_elements(new_filenames)-1 do begin
			if widget_info(self.view_in_gpitv_id,/button_set) then if obj_valid(self.launcher_handle) then $
				self.launcher_handle->launch, 'gpitv', filename=new_filenames[i], session=45 ; arbitrary session number picked to be 1 more than this launcher
			self->reduce_one, new_filenames[i]
		endfor

	endif else begin
		; save the files to process later
		if ptr_valid(self.awaiting_parsing) then *self.awaiting_parsing = [*self.awaiting_parsing, new_filenames] else self.awaiting_parsing = ptr_new(new_filenames)
	endelse

end

;-------------------------------------------------------------------

pro automaticproc3::reduce_one, filenames
	; Reduce one single file at a time
	
	templatename=gpi_expand_path('$GPI_DRF_TEMPLATES_DIR')+path_sep()+'templates_drf_simple_cube.xml'

	drf = obj_new('DRF', templatename, parent=self)
	drf->set_datafiles, filenames
	drf->set_outputdir,/autodir

	; generate a nice descriptive filename
	first_file_basename = (strsplit(file_basename(filenames[0]),'.',/extract))[0]

	drf->savedrf, 'auto_'+first_file_basename+'_'+drf->get_datestr()+'.waiting.xml',/autodir
	drf->queue

	obj_destroy, drf

end


;-------------------------------------------------------------------
PRO automaticproc3_event, ev
	; simple wrapper to call object routine
    widget_control,ev.top,get_uvalue=storage
   
    if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
end

;-------------------------------------------------------------------
pro automaticproc3::event, ev
	; Event handler for automatic parser GUI


	uname = widget_info(ev.id,/uname)
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
				  'one': textinfo='Each new file will be reduced on its own right away.'
				  'keep': textinfo='All new files will be reduced in a batch whenever you command.'
                  'listdir':textinfo='Double-click on a repertory to remove it from the list.'  
                  'search':textinfo='Start the looping search of new FITS placed in the right-top panel directories. Restart the detection for changing search parameters.'
                  'filelist':textinfo='List of detected most-recent Fits files in the repertories. '
				  'view_in_gpitv': textinfo='Automatically display new files in GPITV.'
                  'one':textinfo='Parse and process new file in a one-by-one mode.'
                  'new':textinfo='Change parser queue to process when new type detected.'
                  'keep':textinfo='keep all detected files in parser queue.'
                  'flush':textinfo='Delete all files in the parser queue.'
				  'Start': textinfo='Press to start scanning that directory for new files'
				  'Reprocess': textinfo='Select one or more existing files, then press this to re-reduce them.'
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
	   if uname eq 'changedir' then begin
			dir = DIALOG_PICKFILE(PATH=self.dirinit, Title='Choose directory to scan...',/must_exist , /directory)
			if dir ne '' then begin
				self->Log, 'Directory changed to '+dir
				self.dirinit=dir
				widget_control, self.watchdir_id, set_value=dir
				ptr_free, self.previous_file_list ; we have lost info on our previous files so start over
			endif
			
	   endif
 
		if (uname eq 'one') || (uname eq 'new') || (uname eq 'keep') then begin
		  if widget_info(self.parseone_id,/button_set) then self.parsemode=1
		  if widget_info(self.parseall_id,/button_set) then self.parsemode=3
		endif
		if uname eq 'flush' then begin
			self.parserobj=gpiparsergui(/cleanlist)
		endif
		  
		if uname eq 'alwaysexec' then begin
			self.alwaysexecute=widget_info(self.alwaysexecute_id,/button_set)
		endif
		
		if uname eq 'QUIT'    then begin
			if confirm(group=ev.top,message='Are you sure you want to close the Automatic Reducer Parser GUI?',$
			  label0='Cancel',label1='Close', title='Confirm close') then begin
					  self.continue_scanning=0
					  ;wait, 1.5
					  obj_destroy, self
			endif           
		endif
		if uname eq 'Start'    then begin
			message,/info,'Starting watching directory '+self.dirinit
			widget_control, self.top_base, timer=1  ; Start off the timer events for updating at 1 Hz
		endif
		if uname eq 'Reprocess'    then begin
			widget_control, self.listfile_id, get_uvalue=list_contents

            ind=widget_INFO(self.listfile_id,/LIST_SELECT)
            
			if list_contents[ind[0]] ne '' then begin

				self->Log,'User requested reprocessing of: '+strjoin(list_contents[ind], ", ")
				self->handle_new_files, list_contents[ind]
			endif
	
		endif
		

	end 

	'WIDGET_LIST':begin
		if uname eq 'filelist' then begin
            if ev.clicks eq 2 then begin
              	ind=widget_INFO(self.listfile_id,/LIST_SELECT)
            
			  	if self.filelist[ind] ne '' then begin
					message,/info,'You double clicked on '+self.filelist[ind]
              		;print, self.filelist[ind]
	              	;CALL_PROCEDURE, self.commande,self.filelist(ind),mode=self.parsemode
				endif
            endif
		endif
	end
  	'WIDGET_KILL_REQUEST': begin ; kill request
		if dialog_message('Are you sure you want to close AutoReducer?', title="Confirm close", dialog_parent=ev.top, /question) eq 'Yes' then $
			obj_destroy, self
		return
	end
	
    else:   
endcase
end

;--------------------------------------
PRO automaticproc3::cleanup
	; kill the window and clear variables to conserve
	; memory when quitting.  The windowid parameter is used when
	; GPItv_shutdown is called automatically by the xmanager, if FITSGET is
	; killed by the window manager.


	; Kill top-level base if it still exists
	if (xregistered ('automaticproc3')) then widget_control, self.top_base, /destroy
	if (xregistered ('drfgui') gt 0) then    widget_control,(self.parserobj).drfbase,/destroy

	self->parsergui::cleanup ; will destroy all widgets

	heap_gc

	obj_destroy, self

end


;-------------------------------------------------
function automaticproc3::init, groupleader, _extra=_extra
	; Initialization code for automatic processing GUI

	; Check validity of GPI environment
	issetenvok=gpi_is_setenv(/first)
	if issetenvok eq 0 then begin
			obj=obj_new('setenvir')
			if obj.quit eq 1 then issetenvok=-1
			obj_destroy, obj
		  while (issetenvok ne -1) && (gpi_is_setenv() eq 0)  do begin
				obj=obj_new('setenvir')
				if obj.quit eq 1 then issetenvok=-1
				obj_destroy, obj
		  endwhile
	endif
	if issetenvok eq -1 then return,0


	self.dirinit=self->get_input_dir()
	self.maxnewfile=60
	self.alwaysexecute=1
	self.parsemode=1
	self.continue_scanning=1
	self.awaiting_parsing = ptr_new(/alloc)


	self.top_base = widget_base(title = 'GPI IFS Automatic Reducer', $
				   /column,  $
				   /tlb_size_events)


	base_dir = widget_base(self.top_base, /row)
	void = WIDGET_LABEL(base_dir,Value='Directory being watched: ', /align_left)
	self.watchdir_id =  WIDGET_LABEL(base_dir,Value=self.dirinit+"     ", /align_left)
	button_id = WIDGET_BUTTON(base_dir,Value='Change...',Uname='changedir',/align_right,/tracking_events)

	   
	base_dir = widget_base(self.top_base, /row)
	void = WIDGET_LABEL(base_dir,Value='Reduce new files:')    
	parsebase = Widget_Base(base_dir, UNAME='parsebase' ,ROW=1 ,/EXCLUSIVE, frame=0)
	self.parseone_id =    Widget_Button(parsebase, UNAME='one'  $
		  ,/ALIGN_LEFT ,VALUE='Automatically as each file arrives', /tracking_events)
	;self.parsenew_id =    Widget_Button(parsebase, UNAME='new'  $
		  ;,/ALIGN_LEFT ,VALUE='Flush filenames when new filetype',uvalue='new' )
	self.parseall_id =    Widget_Button(parsebase, UNAME='keep'  $
		  ,/ALIGN_LEFT ,VALUE='When user requests', /tracking_events ,sensitive=0) 
	widget_control, self.parseone_id, /set_button 


	base_dir = widget_base(self.top_base, /row)
	void = WIDGET_LABEL(base_dir,Value='What kind of reduction:')
	parsebase = Widget_Base(base_dir, UNAME='kindbase' ,ROW=1 ,/EXCLUSIVE, frame=0)
	self.b_simple_id =    Widget_Button(parsebase, UNAME='simple'  $
	        ,/ALIGN_LEFT ,VALUE='Simple datacube extraction',/tracking_events)
	self.b_full_id =    Widget_Button(parsebase, UNAME='full'  $
	        ,/ALIGN_LEFT ,VALUE='Run full parser',/tracking_events, sensitive=0)
	widget_control, self.b_simple_id, /set_button 

	gpitvbase = Widget_Base(self.top_base, UNAME='alwaysexebase' ,COLUMN=1 ,/NONEXCLUSIVE, frame=0)
	self.view_in_gpitv_id =    Widget_Button(gpitvbase, UNAME='view_in_gpitv'  $
		  ,/ALIGN_LEFT ,VALUE='View new files in GPITV' )
	widget_control, self.view_in_gpitv_id, /set_button   
	

	void = WIDGET_LABEL(self.top_base,Value='Detected FITS files:')
	self.listfile_id = WIDGET_LIST(self.top_base,YSIZE=10,  /tracking_events,uname='filelist',/multiple, uvalue='')
	widget_control, self.listfile_id, SET_VALUE= ['','','     ** not scanning anything yet; press the Start button below to begin **']


	lab = widget_label(self.top_base, value="History:")
	self.widget_log=widget_text(self.top_base,/scroll, ysize=8, xsize=80, /ALIGN_LEFT, uname="text_status",/tracking_events)

	self.start_id = WIDGET_BUTTON(self.top_base,Value='Start',Uname='Start', /tracking_events)
	reprocess_id = WIDGET_BUTTON(self.top_base,Value='Reprocess Selection',Uname='Reprocess', /tracking_events)

	button3=widget_button(self.top_base,value="Close Automatic Reducer",uname="QUIT", /tracking_events)

	self.information_id=widget_label(self.top_base,uvalue="textinfo",xsize=450,value='                                                                                ')

	storage={$;info:info,fname:fname,$
		group:'',$
		self: self}
	widget_control,self.top_base ,set_uvalue=storage,/no_copy

	; Realize the widgets and run XMANAGER to manage them.
	; Register the widget with xmanager if it's not already registered
	if (not(xregistered('automaticproc3', /noshow))) then begin
		WIDGET_CONTROL, self.top_base, /REALIZE
		XMANAGER, 'automaticproc3', self.top_base, /NO_BLOCK
	endif

	
	RETURN, 1;filename

END
;-----------------------
pro automaticproc3::set_launcher_handle, launcher
	self.launcher_handle = launcher
end


;-----------------------
pro automaticproc3__define



stateF={  automaticproc3, $
    dirinit:'',$ ;initial root  directory for the tree
    commande:'',$   ;command to execute when fits file double clicked
    scandir_id:0L,$ 
    continue_scanning:0, $
    parserobj:obj_new(),$
	launcher_handle: obj_new(), $	; handle to the launcher, *if* we were invoked that way.
    listfile_id:0L,$;wid id for list of fits file
    alwaysexecute_id:0L,$ ;wid id for automatically execute commande 
    alwaysexecute:0,$
    parseone_id :0L,$
    parsenew_id :0L,$
    parseall_id :0L,$
	b_simple_id :0L,$
	b_full_id :0L,$
	watchdir_id: 0L, $   ; widget ID for directory label display
	start_id: 0L, $		; widget ID for start parsing button
	view_in_gpitv_id: 0L, $
    parsemode:0L,$
    information_id:0L,$
    maxnewfile:0L,$
    awaiting_parsing: ptr_new(),$ ;list of detected files 
    isnewdirroot:0,$ ;flag for  root dir
    button_id:0L,$ 
	previous_file_list: ptr_new(), $ ; List of files that have previously been encountered
    INHERITS parsergui} ;wid for detect-new-files button

end
