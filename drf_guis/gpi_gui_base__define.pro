;-----------------------------------------
; gpi_gui_base.pro 
;
;	Base utility class for GPI GUI windows
;
;	Any such windows should implement the following procedures:
;
;		init_data
;		init_widgets
;
;		post_init
;
;		event
;
;
;	The top window should have a uvalue that contains a struct, which in turn
;	has a reference to self inside it.
;
; HISTORY:
;   2012-08-17  Started by Marshall Perrin, forked from drfgui__define.
;------------------------------------------------

compile_opt DEFINT32, STRICTARR


pro gpi_gui_base::log, logtext
	addmsg, self.widget_log, logtext
	print, "LOG: "+logtext

end

;------------------------------------------------


; simple wrapper to call object routine for events
PRO gpi_gui_base_event, ev
    widget_control,ev.top,get_uvalue=storage
	if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
end
;------------------------------------------------

; simple wrapper to ensure the GUI cleanup is called when you close the window
PRO gpi_gui_base_cleanup, tlb
	; Based on DFanning's example at
	; http://www.idlcoyote.com/tip_examples/owindow.pro
	Widget_Control, tlb, Get_UValue=info, /No_Copy
	if obj_valid(info.self) then obj_destroy, info.self
	heap_gc
end


;-----------------------------------------
PRO gpi_gui_base::Cleanup
	; cleanup routine called when the object is destroyed.
	;
	; Invokes window cleanup by destroying the TLB

	if (xregistered (self.xname) gt 0) then widget_control,self.top_base,/destroy
	heap_gc
END 



;-----------------------------------------
; actual event handler: 
pro gpi_gui_base::event,ev

    ;get type of event
    widget_control,ev.id,get_uvalue=uval

    ;get overall window's data storage
    widget_control,ev.top,get_uvalue=storage

	;print, 'event'

    if size(uval,/TNAME) eq 'STRUCT' then begin
        ; TLB event, either resize or kill_request
        ;print, 'Recipe Editor TLB event'
        case tag_names(ev, /structure_name) of

        'WIDGET_KILL_REQUEST': begin ; kill request
            if confirm(group=ev.top,message='Are you sure you want to close the '+self.name+'?',$
                label0='Cancel',label1='Close') then begin
				obj_destroy, self
            endif
        end
        'WIDGET_BASE': begin ; resize event
            print, "RESIZE not yet supported - will be eventually "

        end
        else: print, tag_names(ev, /structure_name)


        endcase
        return
    endif

    ; Mouse-over help text display:
    if (tag_names(ev, /structure_name) EQ 'WIDGET_TRACKING') then begin 
        if (ev.ENTER EQ 1) then begin 
              case uval of 
              'FNAME':textinfo='Press "Add Files" or "Wildcard" buttons to add FITS files to process.'
              'moduavai':textinfo='Left-click for Primitve Desciption | Right-click to add the selected primitive to the current Recipe.'
              'tableselected':textinfo='Left-click to see argument parameters of the module | Right-click to remove the selected module from the current Recipe.'
              'tableargs':textinfo='Left-click on Value cell to change the value. Press Enter to validate.'
              'mod_desc':textinfo='Click on a module in the Available Primitives list to display its description here.'
              'text_status':textinfo='Status log message display window.'
              'ADDFILE': textinfo='Click to add files to current input list'
              'WILDCARD': textinfo='Click to add files to input list using a wildcard ("*.fits" etc)'
              'REMOVE': textinfo='Click to remove currently highlighted file from the input list'
              'REMOVEALL': textinfo='Click to remove all files from the input list'
              'Remove module': textinfo='Remove the selected module from the execution list'
              'Add primitive': textinfo='Add the selected module from "Available Primitives" into the execution list'
              "Create": textinfo='Save Recipe to a filename of your choosing'
              "Drop": textinfo="Queue & execute the last saved Recipe"
              'Save&Drop': textinfo="Save the file, then queue it"
              'QUIT': textinfo="Close and exit this program"
              "Move primitive up": textinfo='Move the currently-selected module one position earlier in the execution list'
              "Move primitive down": textinfo='Move the currently-selected module one position later in the execution list'
              else:
              endcase
              widget_control,self.textinfoid,set_value=textinfo
          ;widget_control, event.ID, SET_VALUE='Press to Quit'   
        endif else begin 
              widget_control,self.textinfoid,set_value=''
          ;widget_control, event.id, set_value='what does this button do?'   
        endelse 
        return
      endif
  

;	if uval eq 'top_menu' then uval=ev.value ; respond to menu selections from event, not uval
;
;    ; Menu and button events: 
;    case uval of 
;    
;    else: begin
;		self->log, 'Unknown event: '+uval
;		if gpi_get_setting('enable_editor_debug', default=0,/bool) then stop
;	endelse
;	endcase

end
;--------------------------------------


function gpi_gui_base::check_output_path_exists, path
	if file_test(path,/dir,/write) then begin
		return, 1 
	endif else  begin

		if gpi_get_setting('prompt_user_for_outputdir_creation',/bool) then res =  dialog_message('The requested output directory '+path+' does not exist. Should it be created now?', title="Nonexistent Output Directory", dialog_parent=self.top_base, /question) else res='Yes'
		if res eq 'Yes' then begin
			file_mkdir, path
			return, 1
		endif else return, 0

	endelse
	return, 0


end


;------------------------------------------------
pro gpi_gui_base::init_data, _extra=_Extra
      ;--- init object member variables
        self.version=gpi_pipeline_version()
		self.name='GPI GUI base'
		self.xname='gpi_gui_base'

        self.templatedir = 	gpi_get_directory('GPI_DRP_TEMPLATES_DIR')
        self.outputdir = 	gpi_get_directory('GPI_REDUCED_DATA_DIR')
        self.logdir = 		gpi_get_directory('GPI_DRP_LOG_DIR')
        self.queuedir =		gpi_get_directory('GPI_DRP_QUEUE_DIR')
		self.inputcaldir =	gpi_get_directory('GPI_calibrations_dir')
        self.dirpro = 		gpi_get_directory('GPI_DRP_DIR') ;+path_sep();+'gpidrfgui'+path_sep();dirlist[0]

end

;------------------------------------------------
; create the widgets (can be overridden by subclasses)
;
function gpi_gui_base::init_widgets, _extra=_Extra, session=session
      ;create base widget. 
        ;   Resize to be large on desktop monitors, or shrink to fit on laptops.
        ;-----------------------------------------
    ;DEBUG_SHOWFRAMES=0
	DEBUG_SHOWFRAMES= gpi_get_setting(strlowcase(strc(self.name))+'_enable_framedebug', default=0)
    
    screensize=get_screen_size()


	title  = self.name
	if keyword_set(session) then begin
           self.session=session
           title += " #"+strc(session)
    endif
    curr_sc = get_screen_size()
    CASE !VERSION.OS_FAMILY OF  
           ;; **NOTE** Mac OS X reports an OS family of 'unix' not 'MacOS'
           'unix': begin 
              if curr_sc[0] gt 1300 then $
                 top_base=widget_base(title=title, group_leader=groupleader,/BASE_ALIGN_LEFT,/column,$
                                      MBAR=bar,/tlb_size_events, /tlb_kill_request_events, resource_name='GPI_DRP_DRFGUI') $
              else top_base=widget_base(title=title, group_leader=groupleader,/BASE_ALIGN_LEFT,/column,$
                                        MBAR=bar,/tlb_size_events, /tlb_kill_request_events, resource_name='GPI_DRP_DRFGUI',$
                                        /scroll,x_scroll_size=curr_sc[0]-50,y_scroll_size=curr_sc[1]-100)
           end
           'Windows'   :begin
              top_base=widget_base(title=title, $
                                   group_leader=groupleader,/BASE_ALIGN_LEFT,/column, MBAR=bar,bitmap=self.dirpro+path_sep()+'gpi.bmp',/tlb_size_events, /tlb_kill_request_events)
              
           end
        ENDCASE
   
	self.top_base=top_base

	widget_control, top_base, set_uvalue={self: self, other:0}
	;create Menu

    return, top_base

end

;------------------------------------------------
PRO gpi_gui_base::post_init, _extra=_extra

end

;------------------------------------------------

; Initialize and create widgets
function gpi_gui_base::init, groupleader, _extra=_extra ;,group,proj

    ;;for possible usage later (not really necessary now)
    ;if n_params() lt 1 then  groupleader=''

	self->init_data, _extra=_extra

	self.top_base = self->init_widgets(_extra=_Extra)

	;show base widget
	;-----------------------------------------
	widget_control,self.top_base,/realize

	;event loop
	;-----------------------------------------

	xmanager,self.xname,self.top_base,/no_block,group_leader=groupleader, event='gpi_gui_base_event', cleanup = 'gpi_gui_base_cleanup'

	self->post_init, _extra=_extra

    return, 1
end



;-----------------------
pro gpi_gui_base__define
    struct = {gpi_gui_base,   $
			  name: 'gpi_gui_base', $	; Name displayed to humans
			  xname: '', $				; Name used for IDL xmanager calls
              top_base:0L,$				; widget ID of TLB
			  session: 0L, $			; numeric session indicator for GPI tools that can be invoked multiple times.
			  widget_log: 0L, $
              dirpro:'',$
              queuedir:'',$
              inputdir:'',$
              outputdir:'',$
              inputcaldir:'',$
              logdir:'',$
              templatedir:'',$     
              version: gpi_pipeline_version() }              ; version # of this release


end
