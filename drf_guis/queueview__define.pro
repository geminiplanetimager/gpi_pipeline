;+-----------------------------------------
; queueview__define.pro 
;
; A recipe queue viewer for gpi
;
;
;--------------------------------------------------------------------------------


;+--------------------------------------------------------------------------------
; queueview::scan_one_file
;    Scan one file and update displayed status
;-
pro queueview::scan_one_file, filename
	if ~file_test(filename) then return ; watch out for the DRP moving things around..
	drf = obj_new('drf',filename,/quick)

	drf_summary = drf->get_summary()

	new_drf_properties = [filename, drf_summary.name, drf_summary.reductiontype, strc( drf_summary.nfiles) ] ;fix( total(drf_contents.fitsfilenames ne '') )) ]
	if self.num_recipes_in_table eq 0 then (*self.recipes_table)= new_drf_properties else $
		(*self.recipes_table)=[[(*self.recipes_table)],[new_drf_properties]]
	self.num_recipes_in_table+=1

	obj_destroy,drf 

end


;+--------------------------------------------------------------------------------
; queueview::rescan
;     Rescan the queue directory from scratch, discarding any prior knowledge of
;     its contents. 
;-

PRO queueview::rescan, initialize=initialize

	self.num_recipes_in_table=0
	(*self.recipes_table) = ''

	files  = file_search(self.queuedir+path_sep()+"*xml")
	if (keyword_set(initialize)) then begin
		self->Log, "Scanning all waiting/working Recipes in queue"
		wongoing = where(strmatch(files,"*.waiting.xml",/fold) or strmatch(files,"*.working.xml",/fold), gct)
		if gct ge 1 then files=files[wongoing] else files =''
	endif else self->Log, "Scanning all available Recipes in queue"

	if n_elements(files) eq 0 then return
	if files[0] eq '' then begin
		self->Log, "No files present in queue"
		self->clearall
	endif else begin

		files = files[sort(files)]

		for i=0L,n_elements(files)-1 do begin
			self->scan_one_file, files[i]
		endfor 

		void=where(files ne '',cnz)
		self->Log,strtrim(cnz,2)+' files added.'
	 
	endelse

	widget_control, self.tableSelected, ysize=((size(*self.recipes_table))[2] > 20 )

    widget_control, self.tableSelected, set_value=(*self.recipes_table)[*,*]
	widget_control, self.tableSelected, set_table_select=[-1,-1,-1,-1]
	self.selection=''
	self->colortable

end



;+----------------------------------------
; queueview::colortable
;    Color the table based on recipe status waiting/done/failed/working
;-
pro queueview::colortable
	if self.num_recipes_in_table eq 0 then begin
		widget_control, self.tableSelected, background_color=[255,255,255] ; all white
		return
	endif

	files = (*self.recipes_table)[0,*]
	bkgcolors = fltarr(3,4,n_elements(files) > 20) + 255

	for i=0L,n_elements(files)-1 do begin

		if strmatch(files[i], '*waiting.xml') then mycol = [255,255,255]
		if strmatch(files[i], '*done.xml') then mycol = [205,255,205]
		if strmatch(files[i], '*failed.xml') then mycol = [255,205,205]
		if strmatch(files[i], '*working.xml') then mycol = [205,205,255]
		;if i mod 2 then mycol -= [15, 15,0] ; darken alternating rows
		bkgcolors[*,*,i] = rebin(mycol, 3,4,/sample)

	endfor

	widget_control, self.tableSelected, background_color=bkgcolors


end
;+-----------------------------------------
;queueview::clearall
;   Clear selection
;-

PRO queueview::clearall
	(*self.recipes_table)[*,*] = ''
	self.num_recipes_in_table=0
	widget_control, self.tableSelected, set_table_select=[-1,-1,-1,-1]
	self->colortable
end

;------------------------------------------
; queueview::refresh
;    Refresh queue display by checking list of files on disk
;-

PRO queueview::refresh

	curr_file_list = (*self.recipes_table)[0,*]

	wgood = where(curr_file_list ne '', goodct)
	disk_files  = file_search(self.queuedir+path_sep()+"*xml", count=ct)
	
	if ct eq 0 then begin
		self->clearall
		return
	endif

	displayed = intarr(ct) ; flag - is each DRF displayed or not?

	highest_updated = -1 ; where to set the viewport? 

	; For each file already in the list, update it
	for i=0L,goodct-1 do begin
		wm =  where(strmatch(file_basename(disk_files), file_basename(curr_file_list[i]),/fold), mct) ;file_basename for Windows syst (strmatch bug)
		if mct gt 0 then begin
			; file is still on disk - OK, no change
			displayed[wm] = 1
		endif else begin
			; file missing - see if extension has changed.
			basepart = file_basename(curr_file_list[i], 'xml',/fold_case)
			basepart2 = (strsplit(basepart,".",/extract))[0] ; drop middle part: waiting, done etc
			wm2 = where(strmatch(disk_files, "*"+path_sep()+basepart2+".*.xml"), mct2)
			if mct2 gt 0 then begin
				; extension has changed - update it!
				displayed[wm2] = 1
				(*self.recipes_table)[0,i] = disk_files[wm2[0]] 
				highest_updated = wm2[0] ; force scalar.
			endif else begin	
				; file vanished entirely
				(*self.recipes_table)[0,i]  = "" 
			endelse
		endelse

		; check for duplicates
		wdup = where(curr_file_list eq curr_file_list[i], dupcount)
		if dupcount gt 1 then begin
			message,/info, "Duplicate record found - deleting the extra one"
			curr_file_list[wdup[1:*]] = ''
			(*self.recipes_table)[0,wdup[1:*]]  = ""
		endif
	endfor 

	; clear out any files that totally vanished.
	wgood = where((*self.recipes_table)[0,*] ne '' , goodct)
	if goodct ne 0 then begin
		(*self.recipes_table) = (*self.recipes_table)[*,wgood]
		self.num_recipes_in_table=goodct
	endif else begin
		self->clearall
		return
	endelse

	; see if there are any new files to add too.
	wnew = where(displayed eq 0 and (strmatch(disk_files, "*.waiting.xml") or strmatch(disk_files, "*.working.xml")), nct)
	if nct gt 0 then begin
		for i=0,nct-1 do begin
			self->scan_one_file, disk_files[wnew[i]]
			highest_updated = self.num_recipes_in_table
		endfor
	endif

	ys=((size(*self.recipes_table))[2] > 20 )
	widget_control, self.tableSelected, ysize=ys
    widget_control, self.tableSelected, set_value=(*self.recipes_table)[*,*]

    if highest_updated gt -1 then widget_control, self.tableSelected, set_table_view=[0, (highest_updated - (ys-1)) >0] 

	self->colortable
 
end

;+-----------------------------------------
; queueview::event
;    GUI event handler
;
;-
pro queueview::event,ev

    ;get type of event

    widget_control,ev.id,get_uvalue=uval
    
	case tag_names(ev, /structure_name) of

	'WIDGET_TIMER' : begin
        self->refresh
        widget_control, ev.top, timer=1
        return
    end

	'WIDGET_KILL_REQUEST': begin ; kill request
		if dialog_message('Are you sure you want to close QueueView?', title="Confirm close", dialog_parent=ev.top, /question) eq 'Yes' then obj_destroy, self
		;if confirm(group=ev.top,message='Are you sure you want to quit QueueView?',$
			;label0='Cancel',label1='Quit') 
		return
	end
	'WIDGET_BASE': begin ; resize event
		print, "RESIZE only partially supported - will be debugged eventually, pending demand "
		geomb = widget_info(ev.top,/geom)
		geomt = widget_info(self.tableselected,/geom)
		geomlog = widget_info(self.widget_log,/geom) ; sets minimum width

		
		new_geom = [ev.x > geomlog.scr_xsize , ev.y  > self.geom_controls[1] ]

		new_table_geom = (new_geom-self.geom_controls)*[1.0, 0.75]
		new_log_geom = [geomlog.scr_xsize, (new_geom-self.geom_controls)[1]*0.25]


		widget_control, self.tableselected, scr_xsize= new_table_geom[0], scr_ysize= new_table_geom[1] ;, ysize=new_table_geom[1]/20
		widget_control, self.widget_log, scr_xsize= new_log_geom[0], scr_ysize= new_log_geom[1]


		return
	end
	'WIDGET_TRACKING': begin ; Mouse-over help text display:
		if (ev.ENTER EQ 1) then begin 
			  case uval of 
			  'tableselec':textinfo='Click to select a Recipe, then use action buttons below.'
			  'text_status':textinfo='Status log message display window.'
			  'ADDFILE': textinfo='Click to add files to current input list'
			  'WILDCARD': textinfo='Click to add files to input list using a wildcard (*.fits etc)'
			  'REMOVE': textinfo='Click to remove currently highlighted file from the input list'
			  'REMOVEALL': textinfo='Click to remove all files from the input list'
			  'Rescan': textinfo='Click to redisplay ALL Recipes in the queue directory'
			  'cleardone': textinfo='Click to redisplay only waiting/working DRFS in the queue directory'
			  'requeue': textinfo='Click to re-queue selected Recipe (by setting state="waiting").'
			  'DRFGUI': textinfo='Click to load currently selected recipe into the Recipe Editor'
			  'Delete': textinfo='Click to delete the currently selected DRF from the queue. (Cannot be undone!)'
			  'DeleteAll': textinfo='Click to delete ALL RECIPES from the queue. (Cannot be undone!)'
			  'QUIT': textinfo='Click to close this window.'
			  else:
			  endcase
			  widget_control,self.textinfoid,set_value=textinfo
		  ;widget_control, event.ID, SET_VALUE='Press to Quit'   
		endif else begin 
			  widget_control,self.textinfoid,set_value=''
		  ;widget_control, event.id, set_value='what does this button do?'   
		endelse 
		return
	end
	else: ;print, tag_names(ev, /structure_name)

	endcase
      
    ; Menu and button events: 
    case uval of 

    'tableselec':begin      
            IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CELL_SEL') && (ev.sel_top ne -1) THEN BEGIN  ;LEFT CLICK
                selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
				if n_elements((*self.recipes_table)) eq 0 then return
                self.num_recipes_in_table=n_elements((*self.recipes_table)[0,*])
                indselected=selection[1]
                if indselected lt self.num_recipes_in_table then self.selection = (*self.recipes_table)[0,indselected]
                     
            ENDIF 
    end      
    'Rescan': self->Rescan
    'cleardone': self->Rescan,/initialize
	'DRFGUI': begin
		if self.selection eq '' then return
            rec_editor = obj_new('gpi_recipe_editor', drfname=self.selection, self.top_base)
	end


	'Delete': begin
		if self.selection eq '' then return
		if confirm(group=self.top_base,message=['Are you sure you want to delete the file ',self.selection+"?"], label0='Cancel',label1='Delete', title="Confirm Delete") then begin
			file_delete, self.selection,/ALLOW_NONEXISTENT
			self->refresh
			self.selection=''

		endif
	end
	'DeleteAll': begin
		if confirm(group=self.top_base,message='Are you sure you want to delete ALL DRFs from the queue?', label0='Cancel',label1='Delete', title="Confirm Delete ALL Recipes") then begin
		if confirm(group=self.top_base,message='Really really sure you want to delete them all?', label0='Cancel',label1='Delete', title="Confirm Delete ALL Recipes") then begin
			files = file_search( self.queuedir+path_sep()+"*.xml", count=ct)
			if ct gt 0 then file_delete, files, /ALLOW_NONEXISTENT
			self->rescan,/init
			self.selection=''

		endif
		endif

	end
	'requeue': begin
		if self.selection eq '' then return
		if strmatch(self.selection, "*.waiting.xml") then begin
			self->Log, 'File is already in the queue (state="waiting"), so no need to re-queue.'
			return
		endif
		;if strmatch(self.selection, "*.working.xml") then begin
			;self->Log, 'File is currently being executed (state="working"), so no need to re-queue.'
			;return
		;endif
	
		basepart = file_basename(self.selection, 'xml',/fold_case)
		path = file_dirname(self.selection)
		basepart2 = (strsplit(basepart,".",/extract))[0] ; drop middle part: waiting, done etc
		newname = path+path_sep()+basepart2+".waiting.xml"
		file_move, self.selection, newname,/overwrite,/allow_same
		self->refresh
		self.selection=newname
		
	end

    'QUIT'    : begin
        if confirm(group=ev.top,message='Are you sure you want to close QueueView?',$
            label0='Cancel',label1='Close', title='Confirm close') then obj_destroy, self
    end
  
    else: begin
        self->Log, 'Unknown event in event handler - ignoring it!'
        message,/info, 'Unknown event in event handler - ignoring it!'

    end
endcase

end

;+------------------------------------------------
; queueview::cleanup
;    Free pointers and exit
;
;-
pro queueview::cleanup

	ptr_free, self.recipes_table
	ptr_free, self.table_background_colors
	
	self->gpi_gui_base::cleanup ; will destroy all widgets
end

;+------------------------------------------------
; queueview::init_data
;    initialize some variables and a blank string pointer.
;-
pro queueview::init_data, _extra=_Extra
	self->gpi_gui_base::init_data, _extra=_extra

	self.name= 'GPI Queue Viewer'
	self.xname='queueview'
	self.recipes_table= ptr_new([''])

end


;+------------------------------------------------
; queueview::init_widgets
;    Initialize GUI widgets
;-
function queueview::init_widgets, testdata=testdata, _extra=_Extra  ;drfname=drfname,  ;,groupleader,group,proj

    ;create base widget. 
    ;   Resize to be large on desktop monitors, or shrink to fit on laptops.
    ;-----------------------------------------
    screensize=get_screen_size()

    if screensize[1] lt 900 then begin
      nlines_modules=10
    endif else begin
      nlines_modules=20
    endelse
	title=self.name+": "+self.queuedir
    CASE !VERSION.OS_FAMILY OF  
        ; **NOTE** Mac OS X reports an OS family of 'unix' not 'MacOS'
       'unix': begin 
        self.top_base=widget_base(title=title, $
        /BASE_ALIGN_LEFT,/column, /tlb_size_events, /tlb_kill_request_events, resource_name='GPI_DRP')
         end
       'Windows'   :begin
       self.top_base=widget_base(title=title, $
        /BASE_ALIGN_LEFT,/column, bitmap=self.dirpro+path_sep()+'gpi.bmp',/tlb_size_events, /tlb_kill_request_events)
         end

    ENDCASE

    guibase=self.top_base

    ;create file selector
    ;-----------------------------------------
	DEBUG_SHOWFRAMES=0
        

    ; what colors to use for cell backgrounds? Alternate rows between
    ; white and off-white pale blue
    self.table_BACKground_colors = ptr_new([[255,255,255],[240,240,255]])

	COLUMN_LABELS=['Recipe Name','Recipe','Type','# FITS']
	ncols=n_elements(column_labels)
	self.tableSelected = WIDGET_TABLE(guibase, $; VALUE=data, $ ;/COLUMN_MAJOR, $ 
			COLUMN_LABELS=COLUMN_LABELS,/resizeable_columns, $
			xsize=ncols,ysize=20,uvalue='tableselec',value=(*self.recipes_table), /TRACKING_EVENTS,$
			/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =nlines_modules,COLUMN_WIDTHS=[500,150,70,70],frame=1,/ALL_EVENTS,/CONTEXT_EVENTS, $
				background_color=rebin(*self.table_BACKground_colors,3,2*ncols,/sample)  ,resource_name="Table"  ) ;,/COLUMN_MAJOR                

	; Create the status log window 
	tmp = widget_label(guibase, value="   " )
	tmp = widget_label(guibase, value="History: ")
	info=widget_text(guibase,/scroll, xsize=120, scr_xsize=800,ysize=6, /ALIGN_LEFT, uval="text_status",/tracking_events);xoffset=5,yoffset=5)
	self.widget_log = info

    ;;create execute and quit button
    ;-----------------------------------------
    top_baseexec=widget_base(guibase,/BASE_ALIGN_LEFT,/row)
    button2b=widget_button(top_baseexec,value="Rescan",uvalue="Rescan", /tracking_events)
    button2b=widget_button(top_baseexec,value="Clear Completed",uvalue="cleardone", /tracking_events)
    button2b=widget_button(top_baseexec,value="Re-queue selected",uvalue="requeue", /tracking_events)
    button2b=widget_button(top_baseexec,value="Open in Recipe Editor",uvalue="DRFGUI", /tracking_events)
    button2b=widget_button(top_baseexec,value="Delete selected",uvalue="Delete", /tracking_events)
    button2b=widget_button(top_baseexec,value="Delete All",uvalue="DeleteAll", /tracking_events)


    space = widget_label(top_baseexec,uvalue=" ",xsize=200,value='  ')
    button3=widget_button(top_baseexec,value="Close queueview",uvalue="QUIT", /tracking_events, resource_name='red_button');, $
    self.textinfoid=widget_label(guibase,uvalue="textinfo",xsize=800,value='  ')
    ;-----------------------------------------

	storage = {self: self}
    widget_control,guibase,set_uvalue=storage,/no_copy
    return, guibase
end

;+------------------------------------------------------------------
; queueview::post_init
;    Rescan queue and then start the timer for watching the queue
;-
pro queueview::post_init, _extra=_extra

	self->rescan;,/initialize
    widget_control, self.top_base, timer=1  ; Start off the timer events for updating at 1 Hz

	geomb = widget_info(self.top_base,/geom)
	geomt = widget_info(self.tableselected,/geom)
	geomlog = widget_info(self.widget_log,/geom) ; sets minimum width


	widget_control, self.tableSelected, set_table_select=[-1,-1,-1,-1]
	self.geom_controls = [ geomb.scr_xsize-geomt.scr_xsize, geomb.scr_ysize-geomt.scr_ysize-geomlog.scr_ysize]

end


;+-----------------------
; queueview__define
;    Object definition routine for queueview
;-
PRO queueview__define


    state = {  queueview,                 $
              selectype:0,$
              currtype:0,$
              currseq:0,$
              num_recipes_in_table:0,$
			  selection: '', $
			  geom_controls: [0,0], $ ; for use in resize events
			  ; from drfgui:
              table_background_colors: ptr_new(), $ ; ptr to RGB triplets for table cell colors
              tableSelected: 0L,$
              textinfoid: 0L,$
			  ;configparser: obj_new(), $
			  ;parser: obj_new(), $
              recipes_table: ptr_new() , $
           INHERITS gpi_gui_base}


end
