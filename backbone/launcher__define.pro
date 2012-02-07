;+
; NAME:  Launcher
;
; 	A simple class for inter-IDL communication and GUI launching. 
;
; 	This implements both sides of a shared memory queue capable of passing 
; 	commands and arguments between two running IDL sessions. 
; 	It's not a general-purpose message-passing library, but instead has some
; 	bits hard-coded for GPI (names of allowable commands, etc), but it could
; 	easily be abstracted out. 
;
; 	The listening side needs to have a GUI of some sort to enable the use of
; 	widget_timer events, so this implements one. 
;
; 	This almost certainly counts as reinventing the wheel, yet again.
;
;
; IMPORTANT NOTE:
;     This same program can be called in two very different ways: 
;      1) with the /guis keyword, in which case it generates the little pop up
;         launcher window for starting the guis. 
;      2) without /guis (or equivalently, with /pipeline set) in which case it
;        just provides an object interface to the messaging system that lets you
;        *talk to* a running instance of the launcher GUI. 
;
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2010-04-26 18:56:08 by Marshall Perrin 
;      2011-06-06, debugging, startup, etc.. -JM
;-

;------------------
PRO launcher_event, ev
	widget_control, ev.top, get_uvalue=self
	if obj_valid(self) then self->event, ev ; avoid null object on close
end


;------------------
; Handle GUI events and Timer events. 
;   Not directly invoked for queue events - see check_queue for those.
PRO launcher::event, ev

     ; Mouse-over help text display:
      if (tag_names(ev, /structure_name) EQ 'WIDGET_TRACKING') then begin 
        if (ev.ENTER EQ 1) then begin 
        widget_control, ev.id, get_uvalue=uval
              case uval of 
                'Control':   begin
                              textinfo='Start the reduction, controler ' & textinfo2='and administration console.'
                              end
                'GPItv':    begin
                       textinfo='Start one or several GPItv ' & textinfo2='viewers.'
                       end
                'DRFGUI':     begin
                     textinfo='Click to create your own DRF and ' & textinfo2='recipes.'
                     end
                'ParserGUI':   begin   
                    textinfo='Click to launch the GPI parser ' & textinfo2='GUI.'
                    end
                'QueueView':    begin
                      textinfo='Click to start the DRF queue ' & textinfo2='viewer.'
                      end
                'dst':         begin
                        textinfo='Click to start the Data Simulation ' & textinfo2='Tool.'
                        end
                'AutomaticProcGUI':begin
                      textinfo='Click to start simple automatic ' & textinfo2='reduction of incoming data files.'
                      end 
                'makedatalogfile': begin
                      textinfo='Click to create a text logfile of' & textinfo2='FITS files in a chosen directory.' 
                      end
                'quit':         begin
                   textinfo='Click to close this window.'
                   end
              else:
              endcase
              widget_control,self.info1_id,set_value=textinfo
              widget_control,self.info2_id,set_value=textinfo2
          ;widget_control, event.ID, SET_VALUE='Press to Quit'   
        endif else begin 
              widget_control,self.info1_id,set_value='  '
              widget_control,self.info2_id,set_value='  '
          ;widget_control, event.id, set_value='what does this button do?'   
        endelse 
        return
    endif
      
	; timer events
	if tag_names(ev,/struct) eq 'WIDGET_TIMER' THEN begin
		widget_control, self.baseid, timer=1 ; request another event (do this *before* checking queue for reliability)
		self->check_queue
		return
	endif
	if tag_names(ev,/struct) eq 'WIDGET_KILL_REQUEST' then begin
        conf = dialog_message("Are you sure you want to exit the GPI Data Reduction Pipeline?",/question,title="Confirm Close",/default_no,/center)
        if conf eq "Yes" then obj_destroy, self
		return
	endif
 

	; all other events
	widget_control, ev.id, get_uvalue=action

	if size(action,/TNAME) ne 'STRING' then begin
		message,/info, "Got unknown non-string action. Ignoring it!"
		return
	endif

	case action of
;  'Control':begin
;              ;self->launch,'gpipipelinebackbone', session=46
;                oBridge = OBJ_NEW('IDL_IDLBridge')
;                comm="gpipiperun"
;                oBridge->Execute, comm, /NOWAIT
;            end
  'Setup':begin
              objenv=obj_new('setenvir')
              obj_destroy, objenv
          end
  'About':begin
              tmpstr=about_message()
              ret=dialog_message(tmpstr,/information,/center,dialog_parent=ev.top)
          end
	'GPItv': self->launch, 'gpitv'
	'DRFGUI': self->launch, 'drfgui', session=40
	'ParserGUI': self->launch, 'parsergui', session=41
	'QueueView': self->launch, 'queueview', session=42
    'dst': begin
		if not self.enable_dst then begin
	            void=dialog_message('The Data Simulation Tool is not an official part of the Gemini DRP. Please contact J. Maire or M. Perrin to make the DST available.')
		endif else begin
			self->launch, 'dst', session=43
		endelse
	end
    'AutomaticProcGUI':self->launch, 'automaticproc3', session=44
    'makedatalogfile':self->launch, 'makedatalogfile', session=45
    'quit': begin
        conf = dialog_message("Are you sure you want to exit the GPI Data Reduction Pipeline?",/question,title="Confirm Close",/default_no,/center)
        if conf eq "Yes" then obj_destroy, self
    end
    else: message,/info, "Unknown event: "+action
    endcase
    



end

;------------------
PRO launcher::queue, cmdstr, _extra=_extra

	
	for i=0,9 do begin
		status = SEM_LOCK(self.semaphore_name) 
		if status eq 1 then break ; successful lock!
		wait, 0.1
	endfor

	if status eq 0 then begin
		message,/info, "ERROR: could not get a lock on the inter-IDL queue semaphore after 10 tries"
		message,/info, "       Failed to queue command "+cmdstr
		return
	endif

    wq = where(*self.cmd_queue_flags, qct, comp=wopen)
	if qct lt self.queuelen  then begin
		message,/info, 'adding "'+strc(cmdstr)+ '" to the gui queue'

		(*self.cmd_queue_flags)[wopen[0]] = 1

		; deal with args
		if keyword_set(_extra) then begin
			; convert the args into a list of strings, and then into a bunch of
			; bytes
			tags = tag_names(_Extra)
			args = [tags[0], string(_extra.(0))] 
			for itag = 1,n_elements(tags)-1 do args = [args,tags[itag],string(_extra.(itag))]
			
			arg_bytes = byte(args)
			szb = size(arg_bytes)
			; prepend the size of the byte array axes for use in unpacking 
			arg_bytes = [byte(szb[1]), byte(szb[2]), reform(arg_bytes, szb[1]*szb[2],1)]
		endif else begin
			arg_bytes = bytarr(3) ; null out at least the first 2
		endelse

        ; stick into queue
		cmd_bytes = [byte(cmdstr),0] ; be sure to null terminate the string!
		l = n_elements(cmd_bytes)
		la = n_elements(arg_bytes)
		if l gt (size( *self.cmd_queue))[1] or la gt (size( *self.cmd_queue_args))[1]then begin
			message,/info, "supplied command or argument list is TOO LONG"
		endif else begin
			(*self.cmd_queue)[0:l-1,wopen[0]] = cmd_bytes
			(*self.cmd_queue_args)[0:la-1,wopen[0]] = arg_bytes

		endelse

	endif

	SEM_RELEASE, self.semaphore_name  
end



;;------------------
PRO launcher::clear_queue


	message,/info, 'Clearing inter-IDL message queue'
	;wait, 1 ; wait for other side to process any messages first

	catch, lock_error
	if lock_error ne 0 then begin
		message,/info, 'Some kind of error when clearing the queue! Skipping for now.'
		return
	endif


    for i=0,9 do begin
        status = SEM_LOCK(self.semaphore_name)
        if status eq 1 then break ; successful lock!
        wait, 0.1
    endfor


    if status eq 0 then begin
        message,/info, "ERROR: could not get a lock on the inter-IDL queue semaphore after 10 tries"
        message,/info, "       Unable to clear the queue."
        return
    endif

	(*self.cmd_queue_flags)[*] = 0b
	(*self.cmd_queue)[*] = 0b
	(*self.cmd_queue_args)[*]=0b

    SEM_RELEASE, self.semaphore_name

	catch,/cancel

end

;------------------
PRO launcher::check_queue, ev

	;catch, lock_error
	lock_error=0
	if lock_error ne 0 then begin
		message,/info, 'Some kind of error when checking the queue! Skipping for now, will retry.'
		return
	endif

    status = SEM_LOCK(self.semaphore_name) 
    if status eq 0 then return


    wq = where(*self.cmd_queue_flags, qct)
    if qct gt 0  then begin

        message,/info, 'found '+strc(qct)+ ' command(s) in the gui queue'
        cmds = string(*self.cmd_queue)
        

        for i=0L,qct-1 do begin
            command = (string(*self.cmd_queue))[wq[i]]
            _extra=0 ; clear any previous _extra's from earlier iterations of the for loop

            queue_arg_bytes = (*self.cmd_queue_args)[*,wq[i]]
            ; check if args are present
            arg_sz1 = fix(queue_arg_bytes[0])

            if arg_sz1 ge 1 then begin
                ; if so, undo the byte-packing that was done in the ::queue
                ; procedure, back into an _extra struct
                arg_sz2 = fix(queue_arg_bytes[1])
                arg_bytes = queue_arg_bytes[2:2+arg_sz1*arg_sz2-1]
                arg_bytes = reform(arg_bytes, arg_sz1, arg_sz2)
                arg_strings = string(arg_bytes)
                nargs = arg_sz2/2
                for iarg=0,arg_sz2/2-1 do begin
					; apply environment variable substitution to any filenames:
					if strupcase(arg_strings[2*iarg]) eq 'FILENAME' then arg_strings[2*iarg+1] = gpi_expand_path(arg_strings[2*iarg+1])


                    if keyword_set(_extra) then _extra = create_struct(arg_strings[2*iarg],  arg_strings[2*iarg+1], _extra) $
                        else _extra = create_struct(arg_strings[2*iarg],  arg_strings[2*iarg+1])
                endfor
            endif else nargs=0
            message,/info, "Command is "+command+", with "+strc(nargs)+" argument(s)."
            if nargs gt 0 then for iarg=0,nargs-1 do message,/info, "    "+arg_strings[2*iarg]+" = "+arg_strings[2*iarg+1]



            (*self.cmd_queue_flags)[wq[i]] =0 ; mark it as done
            ; have to be extra careful with _extra here, because of the
            ; possibility that it could be set to 0, above, which causes a crash
            ; if you try setting _extra=0.
            if keyword_set(_extra) then self->launch, cmds[wq[i]], _extra=_extra else self->launch, cmds[wq[i]]
        endfor 

    endif

    SEM_RELEASE, self.semaphore_name  
	catch,/cancel
end


;------------------
; A generic launcher.
;  If supplied with an object name and no other arguments, will create one of
;  that object. 
;
;  If supplied with an object name and a filename argument, will create one of
;  that object with the filename as an argument.
;
;  If the requested object already exists, then if the filename is presented it
;  will be loaded into that object.
pro launcher::launch, objname, filename=filename, session=session, _extra=_extra

	if ~(keyword_set(objname)) then return

	if objname eq 'quit'  then obj_destroy, self

	if ~obj_valid(self) then return ; avoid weird error case ??
	if n_elements(session) eq 0 then begin
		valid = obj_valid(self.sessions)

		mnv = min(where(valid eq 0, nvct))
		if nvct eq 0 then begin
			message,/info, "Unable to launch new window - max # sessions hit!"
			return
		endif else begin
			session=mnv[0]
		endelse
	endif
    if obj_valid(self.sessions[session]) then begin
		; object already exists, so re-use it if some new filename is supplied
			if keyword_set(filename) then self.sessions[session]->open, filename,_extra=_extra else $
				message,/info, "Unable to launch new window in session "+strc(session)+", since that session is already in use."
				return
	endif else begin
		; need to create a new object

		valid_cmds = ['gpitv', 'drfgui', 'parsergui', 'queueview', 'dst', 'automaticproc3','makedatalogfile']
		provide_launcher_handle = [0,0,0,0,0,1,0]

		if total(strmatch(valid_cmds, objname,/fold_case)) eq 0 then begin
			message,/info, 'Invalid command name: '+objname
		endif else begin
		
			if keyword_set(filename) then self.sessions[session] = obj_new(objname, filename, session=session, _extra=_extra) $
									 else self.sessions[session] = obj_new(objname, session=session, _extra=_extra)
			; some objects may want a handle to this launcher object to launch
			; other things
			if provide_launcher_handle[(where(objname eq valid_cmds))[0]] then  self.sessions[session]->set_launcher_handle, self
;					if strmatch('gpipipelinebackbone', objname,/fold_case) eq 1 then begin
;					    (self.sessions[session])->Run, GETENV('GPI_QUEUE_DIR')
;					endif				 
		endelse
	endelse

end


;------------------
PRO launcher::cleanup
	if self.baseid ne 0 then widget_control, self.baseid,/destroy

	;self->clear_queue

	for i=0,self.max_sess-1 do if obj_valid(self.sessions[i]) then obj_destroy, self.sessions[i]
  ptr_free, self.cmd_queue_flags
  ptr_free, self.cmd_queue
  ptr_free, self.cmd_queue_args
  
	varnames = ['gpi_gui_queue_flags', 'gpi_gui_queue', 'gpi_gui_queue_args']+self.username
	for i=0,n_elements(varnames)-1 do begin
		shmunmap, varnames[i]
	endfor


	SEM_DELETE, self.semaphore_name  
	if keyword_set(self.exit_on_close) then exit


end


;------------------
FUNCTION launcher::init, pipeline=pipeline, guis=guis, exit=exit, test=test, clear_shm=clear_shm, _extra=_extra

 
; Ensure environment variables are set properly & to valid values. If not, ask the user to fix them.
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
endif else if issetenvok eq -1 then return,0
  if issetenvok eq -1 then return,0
  
	self.max_sess = n_elements(self.sessions)
	self.queuelen=10
	self.username=strmid(getenv('USER'),0,8) ;JM fixed bug with long name (shmmap do not support them)
	self.semaphore_name='GPI_DRP_'+self.username ; unique for each user in a multi-user system!

	if keyword_set(clear_shm) then begin
		message,/info, "Clearing all shared memory..."
		varnames = ['gpi_gui_queue_flags', 'gpi_gui_queue', 'gpi_gui_queue_args']+self.username
		for i=0,n_elements(varnames)-1 do begin
			shmmap, varnames[i], template=bytarr(1),/destroy
			shmunmap, varnames[i]
		endfor

		status = SEM_CREATE(self.semaphore_name,/destroy)  
		SEM_delete, self.semaphore_name


		message,/info, "Memory cleared OK."

	endif

	if ~(keyword_set(pipeline)) and ~(keyword_set(guis)) then guis=1


	; workaround for bug in creating semaphores on Mac OS X: 
	; see IDL 7 release notes at
	; http://download.ittvis.com/idl_7.0/linux/relnotes.html
	if !version.OS_Name eq 'Mac OS X' then PREF_SET, 'IDL_TMPDIR', '/tmp', /COMMIT
 


	status = SEM_CREATE(self.semaphore_name)  
	;print, "Semaphore creation status: ", status
	if status eq 0 then begin
		message,/info , "Unable to create semaphore in memory!"
		return, 0
	endif

    shmmap, 'gpi_gui_queue_flags'+self.username, template=bytarr(self.queuelen)
	self.cmd_queue_flags = ptr_new(shmvar('gpi_gui_queue_flags'+self.username))
	shmmap, 'gpi_gui_queue'+self.username, template=bytarr(80,self.queuelen)
	self.cmd_queue = ptr_new(shmvar('gpi_gui_queue'+self.username))
	shmmap, 'gpi_gui_queue_args'+self.username, template=bytarr(2048,self.queuelen) ;512->2048 for long arg (for instance gpitv, disp_grid...)
	self.cmd_queue_args = ptr_new(shmvar('gpi_gui_queue_args'+self.username))

	self->clear_queue

	if keyword_set(guis) then begin


		; create a GUI so we can generate Timer events
		self.baseid = WIDGET_BASE(TITLE='GPI-DPL Launcher',/tlb_size_events,  /tlb_kill_request_events,/row, /base_align_center, xoffset=100, RESOURCE_NAME='GPI_DRP',MBAR=bar)
		basecol_id=WIDGET_BASE(self.baseid ,/column)
		baseid2=WIDGET_BASE(basecol_id,/row,/BASE_ALIGN_CENTER )
        ;FindPro, 'drfgui__define', dirlist=dirlist,/noprint
        dirpro= getenv('GPI_PIPELINE_DIR');dirlist[0]

    if file_test(dirpro+path_sep()+'gpi.bmp') then begin
  		button_image = READ_BMP(dirpro+path_sep()+'gpi.bmp', /RGB) 
  		button_image = TRANSPOSE(button_image, [1,2,0]) 
  		sz = size(button_image)
  		logo = WIDGET_draw( baseid2,   $
  			SCR_XSIZE=sz[1] ,SCR_YSIZE=sz[2])
		endif	
	
		tmp = widget_label(baseid2, value=' ')
		frame = widget_base(baseid2,/column)

        menu = WIDGET_BUTTON(bar, VALUE='Setup',/MENU) 
        file_bttn2=WIDGET_BUTTON(menu, VALUE='Setup environ. var.', UVALUE='Setup')
        menu2 = WIDGET_BUTTON(bar, VALUE='About',/MENU) 
        file_bttn2=WIDGET_BUTTON(menu2, VALUE='About', UVALUE='About')
        bclose = widget_button(frame,VALUE='Parser GUI',UVALUE='ParserGUI', resource_name='button', /tracking_events)
        bclose = widget_button(frame,VALUE='DRF GUI',UVALUE='DRFGUI', resource_name='button', /tracking_events)
        bclose = widget_button(frame,VALUE='DRF QueueView',UVALUE='QueueView', resource_name='button', /tracking_events)
		bclose = widget_button(frame,VALUE='GPItv',UVALUE='GPItv', resource_name='button', /tracking_events)
		bclose = widget_button(frame,VALUE='Auto-Reducer',UVALUE='AutomaticProcGUI', resource_name='button', /tracking_events)
        bclose = widget_button(frame,VALUE='Data log-file',UVALUE='makedatalogfile', resource_name='button', /tracking_events)
		if self.enable_dst then bclose = widget_button(frame,VALUE='DST',UVALUE='dst', resource_name='button', /tracking_events)
		tmp = widget_label(frame, value=' ')
		bclose = widget_button(frame,VALUE='Quit ',UVALUE='quit', resource_name='red_button',/tracking_events)

		tmp = widget_label(baseid2, value=' ')
		
        self.info1_id= widget_label(basecol_id, value=' ',xsize=200)
        self.info2_id= widget_label(basecol_id, value=' ',xsize=200)
    
		widget_control, self.baseid,/realize
		xmanager, 'launcher', self.baseid,/no_block
		widget_control, self.baseid, set_uvalue=self

		widget_control, logo, get_value=draw_id
		wset, draw_id
		tv, button_image, true=3

		self.sessions[0] = self ; just fill up the first slot so that GPItvs start with #1.

		; init timer events to check:
		widget_control, self.baseid, timer=1
	endif


	;if keyword_set(pipeline) then self->queue, "test"
	if keyword_set(test) then self->queue, 'gpitv', filename='/GPI/gpitv/temp.fits', session=1

	if keyword_set(exit) then self.exit_on_close=1 ; exit IDL on close?


	return, 1


end


;------------------
PRO launcher__define

	s = {launcher, $
		semaphore_name: '', $
		username: '', $
		baseid: 0L, $
		info1_id: 0L, $
		info2_id: 0L, $
		queuelen: 0L, $
		exit_on_close: 0L, $
		enable_dst: 0L, $
		cmd_queue_flags: ptr_new(), $
		cmd_queue: ptr_new(), $
		cmd_queue_args: ptr_new(), $
		sessions: objarr(50), $
		max_sess: 0L}

end
