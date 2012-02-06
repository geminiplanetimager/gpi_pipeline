;---------------------------------------------------------------------
;automaticproc2__define.PRO
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
;---------------------------------------------------------------------

; First, we will open a configuration GUI to let the user determine how the
; automatic reduction should run.

;--------------------------------------------------
pro automaticproc2::config_dialog, _extra=_Extra

	self.dirinit=self->get_input_dir()
	self.maxnewfile=60
	self.commande='gpiparsergui'
	self.alwaysexecute=1
	self.parsemode=2
	self.continue_scanning=1

	base = widget_base(title = 'Parameters for automatic processing',/column)

	void= widget_label(base,Value='This program will watch a given directory for new GPI IFS')
	void= widget_label(base,Value='data files, and will automatically create DRFs to reduce them.') 
	void= widget_label(base,Value=' ')
	void= widget_label(base,Value='Directory to watch:')
	self.scandir_id = WIDGET_TEXT(base,Value=self.dirinit,Uvalue='scandir',XSIZE=50)
	button_id = WIDGET_BUTTON(base,Value='Change directory...',Uvalue='changedir')

	alwaysexebase = Widget_Base(base, UNAME='alwaysexebase' ,COLUMN=1 ,/NONEXCLUSIVE, frame=0)
	self.alwaysexecute_id =    Widget_Button(alwaysexebase, UNAME='alwaysexecute'  $
		  ,/ALIGN_LEFT ,VALUE='Automatically execute '+self.commande,uvalue='alwaysexec' )
	if self.alwaysexecute eq 1 then widget_control, self.alwaysexecute_id, /set_button   
	  
	   
	void = WIDGET_LABEL(base,Value='Parser mode:')    
	parsebase = Widget_Base(base, UNAME='parsebase' ,COLUMN=1 ,/EXCLUSIVE, frame=0)
	self.parseone_id =    Widget_Button(parsebase, UNAME='one'  $
		  ,/ALIGN_LEFT ,VALUE='Parse one-by-one',uvalue='one' )
	self.parsenew_id =    Widget_Button(parsebase, UNAME='new'  $
		  ,/ALIGN_LEFT ,VALUE='Flush filenames when new filetype',uvalue='new' )
	self.parseall_id =    Widget_Button(parsebase, UNAME='keep'  $
		  ,/ALIGN_LEFT ,VALUE='Keep all files',uvalue='keep' ) 
		   case self.parsemode of
			1:  widget_control, self.parseone_id, /set_button 
			2:  widget_control, self.parsenew_id, /set_button  
			3:  widget_control, self.parseall_id, /set_button  
		   endcase              

	button3=widget_button(base,value="Start",uvalue="Start")
	button3=widget_button(base,value="Cancel",uvalue="Cancel")
	WIDGET_CONTROL,base, /REALIZE 



	storage={self: self}
	widget_control,base ,set_uvalue=storage,/no_copy
	 
	XMANAGER,'automaticproc2_config', base;, /NO_BLOCK 

end
;----------------------------------------------
; simple wrapper to call object routine
PRO automaticproc2_config_event, ev
    widget_control,ev.top,get_uvalue=storage

    if size(storage,/tname) eq 'STRUCT' then storage.self->config_dialog_event, ev else storage->config_dialog_event, ev
end

;----------------------------------------------
PRO AUTOMATICPROC2::config_dialog_event, event 
   ; The following call blocks only if the NO_BLOCK keyword to 
   ; XMANAGER is set: 
   widget_control,event.id,get_uvalue=uval
   
    if uval eq 'changedir' then begin
		dir = DIALOG_PICKFILE(PATH=self.dirinit, Title='Choose directory to scan...',/must_exist , /directory)
		if dir ne '' then widget_control, self.scandir_id, set_value=dir
		if dir ne '' then self.dirinit=dir
    endif
   
   if uval eq 'Start' then begin
		self.continue_scanning  =1
        self.alwaysexecute=widget_info(self.alwaysexecute_id,/button_set)
          if widget_info(self.parseone_id,/button_set) then self.parsemode=1
          if widget_info(self.parsenew_id,/button_set) then self.parsemode=2
          if widget_info(self.parseall_id,/button_set) then self.parsemode=3
          widget_control,event.top,/destroy
   endif

	if uval eq 'Cancel' then begin
		self.continue_scanning  =0
		widget_control,event.top,/destroy

	endif
	
;    if uval eq 'Quit'    then begin
;                  if confirm(group=event.top,message='Are you sure you want to close the Parser GUI?',$
;                      label0='Cancel',label1='Close', title='Confirm close') then obj_destroy, self
;    endif
   
   
END 




;================================================================================
; Following this we have the code for the actual automatic handler

pro automaticproc2::run
	dir=self.dirinit
	folder=dir
    filetypes = '*.{fts,fits}'
    string3 = folder + path_sep() + filetypes
	oldlistfile =FILE_SEARCH(string3,/FOLD_CASE)

	dateold=dblarr(n_elements(oldlistfile))
	for j=0L,long(n_elements(oldlistfile)-1) do begin
		Result = FILE_INFO(oldlistfile[j] )
		dateold[j]=Result.ctime
	endfor
	list3=oldlistfile[REVERSE(sort(dateold))]
	widget_control, self.listfile_id, SET_VALUE= list3[0:(n_elements(list3)-1)<(self.maxnewfile-1)] ;display the list


	while self.continue_scanning eq 1 do begin
		chang=''
		folder=dir
		filetypes = '*.{fts,fits}'
		string3 = folder + path_sep() + filetypes
		fitsfileslist =FILE_SEARCH(string3,/FOLD_CASE)
		widget_control,self.information_id,set_value='Scanning...'
		datefile=dblarr(n_elements(fitsfileslist))
		for j=0L,long(n_elements(datefile)-1) do begin
			Result = FILE_INFO(fitsfileslist[j] )
			datefile[j]=Result.ctime
		endfor
		list2=fitsfileslist[REVERSE(sort(datefile))]
		
		
		;;compare old and new file list
		if (max(datefile) gt max(dateold)) || (n_elements(datefile) gt n_elements(dateold)) then begin
		  ;chang=1
		  ;oldlistfile=list2
		  lastdate= max(datefile,maxind)
		  chang=fitsfileslist[maxind]
		  dateold=datefile
		endif
		widget_control,self.information_id,set_value='IDLE'
		if chang ne '' then begin
			  widget_control, self.listfile_id, SET_VALUE= list2[0:(n_elements(list2)-1)<(self.maxnewfile-1)] ;display the list
			  ;check if the file has been totally copied
			  self.parserobj=gpiparsergui( chang,  mode=self.parsemode)
		endif
		;print, chang
		for i=0,9 do begin
			wait,0.1
			self->checkEvents
			if ~(self->checkQuit()) then begin
				message,/info, "User pressed QUIT on the progress bar!"
				break
			endif
		endfor    
	endwhile
end

;;-------------------------------------------------
;PRO automaticproc2::checkevents
; this routine is used to MANUALLY process events
; to avoid having to use the whole XMANAGER etc code,
; that doesn't play well with a main() loop in the backbone code 
; that runs forever 

; MP: this seems like a bad idea. Better to restructure the main() loop in the
; backbone to also be an XMANAGER event loop perhaps, with a callback once per
; second or something like that?  FIXME

;if (xregistered ('automaticproc2')) then res = widget_event(self.top_base,/nowait)
;if xregistered ('drfgui')   then res = widget_event((self.parserobj).drfbase,/nowait, bad_id=badid)

;end

;;-------------------------------------------------
function automaticproc2::checkquit
; Check whether this routine should keep running or should quit now
; RETURNS:
; 	1 to continue running, 
; 	0 to quit?
;
  return, self.continue_scanning
end



;-------------------------------------------------------------------
PRO automaticproc2_event, ev
; simple wrapper to call object routine
    widget_control,ev.top,get_uvalue=storage
   
    if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
end

;-------------------------------------------------------------------
pro automaticproc2::event, ev
; Event handler for automatic parser GUI


	widget_control,ev.id,get_uvalue=uval
	case tag_names(ev, /structure_name) of
		'WIDGET_TIMER' : begin
			self->run
			widget_control, ev.top, timer=1 ; check again at 1 Hz
			return
		end

      'WIDGET_TRACKING': begin ; Mouse-over help text display:
        if (ev.ENTER EQ 1) then begin 
              case uval of 
                  'wtTree':textinfo='Browse directories. Double-click to add directory for automatic fits detection.'+ $
                                    'Double-click on Fits file for parsing it.'
                  'Up':textinfo='Click to add the parent directory of the tree root directory.'
                  'listdir':textinfo='Double-click on a repertory to remove it from the list.'  
                  'search':textinfo='Start the looping search of new FITS placed in the right-top panel directories. Restart the detection for changing search parameters.'
                  'newlist':textinfo='List of detected most-recent Fits files in the repertories. '
                  'alwaysexec':textinfo='Automatic launch of the parser for every new detected FITS file.' 
                  'one':textinfo='Parse and process new file in a one-by-one mode.'
                  'new':textinfo='Change parser queue to process when new type detected.'
                  'keep':textinfo='keep all detected files in parser queue.'
                  'flush':textinfo='Delete all files in the parser queue.'
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
		if (uval eq 'one') || (uval eq 'new') || (uval eq 'keep') then begin
		  if widget_info(self.parseone_id,/button_set) then self.parsemode=1
		  if widget_info(self.parsenew_id,/button_set) then self.parsemode=2
		  if widget_info(self.parseall_id,/button_set) then self.parsemode=3
		endif
		if uval eq 'flush' then begin
			self.parserobj=gpiparsergui(/cleanlist)
		endif
		  
		if uval eq 'alwaysexec' then begin
			self.alwaysexecute=widget_info(self.alwaysexecute_id,/button_set)
		endif
		
		if uval eq 'QUIT'    then begin
			if confirm(group=ev.top,message='Are you sure you want to close the Parser GUI?',$
			  label0='Cancel',label1='Close', title='Confirm close') then begin
					  self.continue_scanning=0
					  ;wait, 1.5
					  ;obj_destroy, self
			endif           
		endif
	end 

	'WIDGET_LIST':begin
      if uval eq 'listdir' then begin
			 ;remove double-clicked directory in list of directories checked
			if  ev.clicks eq 2 then begin
			  select=widget_INFO(self.listdir_id,/LIST_SELECT)
			  for ii=select, n_elements(self.listcontent)-2 do self.listcontent(ii)=self.listcontent(ii+1)
			self.listcontent(n_elements(self.listcontent)-1) = ''
			widget_control, self.listdir_id, SET_VALUE= self.listcontent
			endif
		
		endif
		if uval eq 'newlist' then begin
            if event.clicks eq 2 then begin
              ind=widget_INFO(self.listfile_id,/LIST_SELECT)
            
              print, self.newlist(ind)
              CALL_PROCEDURE, self.commande,self.newlist(ind),mode=self.parsemode
            endif
		endif
	end
  
    else:   
endcase
end

;--------------------------------------
PRO automaticproc2::cleanup
	; kill the window and clear variables to conserve
	; memory when quitting.  The windowid parameter is used when
	; GPItv_shutdown is called automatically by the xmanager, if FITSGET is
	; killed by the window manager.


	; Kill top-level base if it still exists
	if (xregistered ('automaticproc2')) then widget_control, self.top_base, /destroy
	if (xregistered ('drfgui') gt 0) then    widget_control,(self.parserobj).drfbase,/destroy

	self->parsergui::cleanup ; will destroy all widgets

	heap_gc

	obj_destroy, self

end

;----------------------------------------------
function automaticproc2::init_widgets, _extra=_Extra, session=session
	; Create widgets routine for the Automatic Processing GUI


	self.top_base = widget_base(title = 'Simple automatic GPI IFS processing', $
				   /column,  $
				   ;app_mbar = top_menu, $
				   ;uvalue = 'GPItv_base', $
				   /tlb_size_events)


	void = WIDGET_LABEL(self.top_base,Value='Scanned directory: '+self.dirinit, /align_left)
	if self.alwaysexecute then void = WIDGET_LABEL(self.top_base,Value='Parser mode: Parse every new fits file.' , /align_left) else $
	void = WIDGET_LABEL(self.top_base,Value='Parser mode: Do not parse new fits file.' , /align_left)
	case self.parsemode of 
	   1:parmode='Parse and process new file in a one-by-one mode.'
	   2:parmode='Change parser queue to process when new type detected.'
	   3:parmode='keep all detected files in parser queue.'
	endcase 
	void = WIDGET_LABEL(self.top_base,Value='Parser mode: '+parmode , /align_left)

	void = WIDGET_LABEL(self.top_base,Value='Most-recent fits files:')

	self.listfile_id = WIDGET_LIST(self.top_base,YSIZE=20 , /tracking_events,uvalue='newlist')
	button_id = WIDGET_BUTTON(self.top_base,Value='Flush parser filenames',Uvalue='flush', /tracking_events)

	button3=widget_button(self.top_base,value="Close GUI",uvalue="QUIT", /tracking_events)

	self.information_id=widget_label(self.top_base,uvalue="textinfo",xsize=800,value='  ')

	storage={$;info:info,fname:fname,$
		group:'',$
		proj:'', $
		self: self}
	widget_control,self.top_base ,set_uvalue=storage,/no_copy
	return, self.top_base  
end

;-------------------------------------------------
function automaticproc2::init, groupleader, _extra=_extra
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

	self->config_dialog, _extra=_extra
	if self.continue_scanning eq 0 then begin
		message,/info, "User cancelled execution"
		return, 0
	endif
	
	; WIDGET_CONTROL, /HOURGLASS
	  
	fitsbase = self->init_widgets(_extra=_Extra)

	; Realize the widgets and run XMANAGER to manage them.
	; Register the widget with xmanager if it's not already registered
	if (not(xregistered('automaticproc2', /noshow))) then begin
		WIDGET_CONTROL, fitsbase, /REALIZE
		XMANAGER, 'automaticproc2', fitsbase, /NO_BLOCK
	endif

	RETURN, 1;filename

END

;---------------------------------------------------------------------
pro queueview::post_init, _extra=_extra

	widget_control, self.top_base, timer=1  ; Start off the timer events for updating at 1 Hz
	
end


;-----------------------
pro automaticproc2__define



stateF={  automaticproc2, $
    dirinit:'',$ ;initial root  directory for the tree
    commande:'',$   ;command to execute when fits file double clicked
    scandir_id:0L,$ 
    launcher: obj_new(), $
    continue_scanning:0, $
    parserobj:obj_new(),$
    listfile_id:0L,$;wid id for list of fits file
    listdir_id:0L,$ ;wid id for list of dir (right top panel)
    alwaysexecute_id:0L,$ ;wid id for automatically execute commande 
    alwaysexecute:0,$
    parseone_id :0L,$
    parsenew_id :0L,$
    parseall_id :0L,$
    parsemode:0L,$
    information_id:0L,$
    currdir:'',$  ;current directory in the tree
    ptr2:PTR_NEW(),$  ;; Pointer and structure for folder and filename (left pan).
    listcontent:STRARR(10),$  ;list of directories chosen for fits detection
    maxnewfile:0L,$
    newlist:STRARR(300),$ ;list of new files (Pan RightDown)
  ;  kill:0,$ ;flag to stop bridge detec loop when quitting with search 'on'
    isnewdirroot:0,$ ;flag for  root dir
    button_id:0L,$
    INHERITS parsergui} ;wid for detect-new-files button

end
