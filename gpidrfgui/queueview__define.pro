;-----------------------------------------
; queueview__define.pro 
;
; PARSER: select files to process and create a list of DRFs to be executed by the pipeline.
;
;
;
; author : 2010-02 J.Maire created




;;--------------------------------------------------------------------------------
; NOTES
;   This is a rather complicated program, with lots of overlapping data
;   structures. Be careful and read closely when editing!
;
;   Module arguments are stored in the ConfigDRS structure in memory. 
;   Right now this gets overwritten frequently (whenever you change a template),
;   which is annoying, and should probably be fixed.
;
;
;   MORE NOTES TO BE ADDED LATER!
;
;
;    self.configDRS            a parsed DRSConfig.xml file, produced by
;                            the ConfigParser. This contains knowledge of
;                            all the modules and their arguments, stored as
;                            a bunch of flat lists. It's not a particularly
;                            elegant data structure, but it's too late to change
;                            now!  Much of the complexity with indices is a
;                            result of indexing into this in various ways.
;
;    self.nbModuleSelec        number of modules in current DRF list
;    self.currModSelec        list of modules in current DRF list
;    self.order                list of PIPELINE ORDER values for those modules
;
;    self.curr_mod_indsort    indices into curr_mod_avai in alphabetical order?
;                            in other words, matching the displayed order in the
;                            Avail Table
;
;    self.indmodtot2avail    indices for
;
;
;
;--------------------------------------------------------------------------------
;
;--------------------------------------------------------------------------------


pro queueview::startup

        self.ConfigDRS=         ptr_new(/ALLOCATE_HEAP)
        self.curr_mod_avai=     ptr_new(/ALLOCATE_HEAP)         ; list of available module names (strings) in current mode
        self.curr_mod_indsort=  ptr_new(/ALLOCATE_HEAP)
        self.currModSelec=      ptr_new(/ALLOCATE_HEAP)
        self.currDRFSelec=      ptr_new(/ALLOCATE_HEAP)
        self.order=             ptr_new(/ALLOCATE_HEAP)
        self.indarg=            ptr_new(/ALLOCATE_HEAP)                ; ???
        self.currModSelecParamTab=  ptr_new(/ALLOCATE_HEAP)
        self.indmodtot2avail=   ptr_new(/ALLOCATE_HEAP)
        self.drf_summary=       ptr_new(/ALLOCATE_HEAP)
        self.version=2.0
 
        FindPro, 'make_drsconfigxml', dirlist=dirlist,/noprint
        if getenv('GPI_CONFIG_FILE') ne '' then self.config_file=getenv('GPI_CONFIG_FILE') $
        else self.config_file=dirlist[0]+"DRSConfig.xml"
        self.ConfigParser = OBJ_NEW('gpiDRSConfigParser',/silent)
    	self.Parser = OBJ_NEW('gpiDRFParser')

        if file_test(self.config_file) then begin
            self.ConfigParser -> ParseFile, self.config_file ;drpXlateFileName(CONFIG_FILENAME)
            *self.ConfigDRS = self.ConfigParser->getidlfunc() 
        endif

        if getenv('GPI_PIPELINE_LOG_DIR') eq '' then initgpi_default_paths
        ; if no configuration file, choose reasonable defaults.
        cd, current=current
        self.tempdrfdir = getenv('GPI_DRF_TEMPLATES_DIR')
        self.inputcaldir = getenv('GPI_DRP_OUTPUT_DIR')
        self.outputdir = getenv('GPI_DRP_OUTPUT_DIR')
        self.logpath = getenv('GPI_PIPELINE_LOG_DIR')
        self.drfpath = current
        self.queuepath =getenv('GPI_QUEUE_DIR')


end

;--------------------------------------------------------------------------------



;-----------------------------------------

PRO queueview::rescan, initialize=initialize

	self.nbdrfSelec=0
	(*self.currDRFSelec) = ''

	files  = file_search(self.queuepath+path_sep()+"*xml")
	if (keyword_set(initialize)) then begin
		self->Log, "Scanning all waiting/working DRFs in queue"
		wongoing = where(strmatch(files,"*.waiting.xml",/fold) or strmatch(files,"*.working.xml",/fold), gct)
		if gct ge 1 then files=files[wongoing] else files =''
	endif else self->Log, "Scanning all available DRFs in queue"

	if n_elements(files) eq 0 then return
	if files[0] eq '' then begin
		self->Log, "No files present in queue"
		self->clearall
	endif else begin


		files = files[sort(files)]


		for i=0L,n_elements(files)-1 do begin
			if ~file_test(files[i]) then continue ; watch out for the DRP moving things around..
			self.Parser ->ParseFile, files[i],  self.ConfigParser, gui=self, /silent
			drf_summary = self.Parser->get_summary()
			drf_contents = self.Parser->get_drf_contents()

			new_drf_properties = [files[i], drf_summary.name, drf_summary.type, strc(fix( total(drf_contents.fitsfilenames ne '') )) ]

			if self.nbdrfSelec eq 0 then (*self.currDRFSelec)= new_drf_properties else $
				(*self.currDRFSelec)=[[(*self.currDRFSelec)],[new_drf_properties]]
			self.nbdrfSelec+=1


		endfor 

		void=where(files ne '',cnz)
		self->Log,strtrim(cnz,2)+' files added.'
	 
	endelse

	widget_control, self.tableSelected, ysize=((size(*self.currDRFSelec))[2] > 20 )

    widget_control, self.tableSelected, set_value=(*self.currDRFSelec)[*,*]
	widget_control, self.tableSelected, set_table_select=[-1,-1,-1,-1]
	self.selection=''
	self->colortable

end



;-----------------------------------------
pro queueview::colortable
	if self.nbdrfSelec eq 0 then begin
		widget_control, self.tableSelected, background_color=[255,255,255] ; all white
		return
	endif

	files = (*self.currDRFSelec)[0,*]
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
;-----------------------------------------

PRO queueview::clearall
	(*self.currDRFSelec)[*,*] = ''
	self.nbdrfSelec=0
	widget_control, self.tableSelected, set_table_select=[-1,-1,-1,-1]
	self->colortable
end

;-----------------------------------------

PRO queueview::refresh

	curr_file_list = (*self.currDRFSelec)[0,*]

	wgood = where(curr_file_list ne '', goodct)
	disk_files  = file_search(self.queuepath+path_sep()+"*xml", count=ct)
	
	if ct eq 0 then begin
		self->clearall
		return
	endif

	displayed = intarr(ct) ; flag - is each DRF displayed or not?

	highest_updated = -1 ; where to set the viewport? 

	; For each file already in the list, update it
	for i=0L,goodct-1 do begin
		wm =  where(strmatch(disk_files, curr_file_list[i],/fold), mct)
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
				(*self.currDRFSelec)[0,i] = disk_files[wm2[0]] 
				highest_updated = wm2
			endif else begin	
				; file vanished entirely
				(*self.currDRFSelec)[0,i]  = "" 
			endelse
		endelse

		; check for duplicates
		wdup = where(curr_file_list eq curr_file_list[i], dupcount)
		if dupcount gt 1 then begin
			print, "Duplicate record found - deleting the extra one"
			curr_file_list[wdup[1:*]] = ''
			(*self.currDRFSelec)[0,wdup[1:*]]  = ""
		endif
	endfor 

	; clear out any files that totally vanished.
	wgood = where((*self.currDRFSelec)[0,*] ne '' , goodct)
	if goodct ne 0 then begin
		(*self.currDRFSelec) = (*self.currDRFSelec)[*,wgood]
		self.nbdrfSelec=goodct
	endif else begin
		self->clearall
		return
	endelse

	; see if there are any new files to add too.
	wnew = where(displayed eq 0 and (strmatch(disk_files, "*.waiting.xml") or strmatch(disk_files, "*.working.xml")), nct)
	if nct gt 0 then begin
		for i=0,nct-1 do begin
			if ~file_test( disk_files[wnew[i]]) then continue ; in case it has changed...
			self.Parser ->ParseFile, disk_files[wnew[i]],  self.ConfigParser, gui=self, /silent
			drf_summary = self.Parser->get_summary()
			drf_contents = self.Parser->get_drf_contents()

			new_drf_properties = [disk_files[wnew[i]], drf_summary.name, drf_summary.type, strc(fix( total(drf_contents.fitsfilenames ne '') )) ]

			if self.nbdrfSelec eq 0 then (*self.currDRFSelec)= new_drf_properties else $
				(*self.currDRFSelec)=[[(*self.currDRFSelec)],[new_drf_properties]]
			self.nbdrfSelec+=1
			highest_updated = self.nbdrfSelec
		endfor
	endif

	ys=((size(*self.currDRFSelec))[2] > 20 )
	widget_control, self.tableSelected, ysize=ys
    widget_control, self.tableSelected, set_value=(*self.currDRFSelec)[*,*]
    if highest_updated gt -1 then widget_control, self.tableSelected, set_table_view=[0, (highest_updated - (ys-1)) >0] 

	self->colortable
 
end

;-----------------------------------------
; actual event handler: 
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

		;print, "window: ", new_geom
		;print, "diff:   ", new_geom-self.geom_controls
		;print, "table:  ", new_table_geom


		widget_control, self.tableselected, scr_xsize= new_table_geom[0], scr_ysize= new_table_geom[1] ;, ysize=new_table_geom[1]/20
		widget_control, self.widget_log, scr_xsize= new_log_geom[0], scr_ysize= new_log_geom[1]


		return
	end
	'WIDGET_TRACKING': begin ; Mouse-over help text display:
		if (ev.ENTER EQ 1) then begin 
			  case uval of 
			  'tableselec':textinfo='Click to select a DRF, then use action buttons below.'
			  'text_status':textinfo='Status log message display window.'
			  'ADDFILE': textinfo='Click to add files to current input list'
			  'WILDCARD': textinfo='Click to add files to input list using a wildcard (*.fits etc)'
			  'REMOVE': textinfo='Click to remove currently highlighted file from the input list'
			  'REMOVEALL': textinfo='Click to remove all files from the input list'
			  'Rescan': textinfo='Click to redisplay ALL DRFS in the queue directory'
			  'cleardone': textinfo='Click to redisplay only waiting/working DRFS in the queue directory'
			  'requeue': textinfo='Click to re-queue selected DRF (by setting state="waiting").'
			  'DRFGUI': textinfo='Click to load currently selected DRF into the DRFGUI editor'
			  'Delete': textinfo='Click to delete the currently selected DRF from the queue. (Cannot be undone!)'
			  'DeleteAll': textinfo='Click to delete ALL DRFs from the queue. (Cannot be undone!)'
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
				if n_elements((*self.currDRFSelec)) eq 0 then return
                self.nbDRFSelec=n_elements((*self.currDRFSelec)[0,*])
                indselected=selection[1]
                if indselected lt self.nbDRFSelec then self.selection = (*self.currDRFSelec)[0,indselected]
                     
            ENDIF 
    end      
    'Rescan': self->Rescan
    'cleardone': self->Rescan,/initialize
	'DRFGUI': begin
		if self.selection eq '' then return
            gpidrfgui, drfname=self.selection, self.drfbase
	end


	'Delete': begin
		if self.selection eq '' then return
		if confirm(group=self.drfbase,message=['Are you sure you want to delete the file ',self.selection+"?"], label0='Cancel',label1='Delete', title="Confirm Delete") then begin
			file_delete, self.selection,/ALLOW_NONEXISTENT
			self->refresh
			self.selection=''

		endif
	end
	'DeleteAll': begin
		if confirm(group=self.drfbase,message='Are you sure you want to delete ALL DRFs from the queue?', label0='Cancel',label1='Delete', title="Confirm Delete ALL DRFs") then begin
		if confirm(group=self.drfbase,message='Really really sure you want to delete them all?', label0='Cancel',label1='Delete', title="Confirm Delete ALL DRFs") then begin
			files = file_search( self.queuepath+path_sep()+"*.xml", count=ct)
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

;------------------------------------------------
pro queueview::cleanup

	ptr_free, self.currDRFselec
	obj_destroy, self.parser
	obj_destroy, self.configparser

	
	self->drfgui::cleanup ; will destroy all widgets
end



;------------------------------------------------
function queueview::init_widgets, testdata=testdata, _extra=_Extra  ;drfname=drfname,  ;,groupleader,group,proj

    self->startup

    ;create base widget. 
    ;   Resize to be large on desktop monitors, or shrink to fit on laptops.
    ;-----------------------------------------
    screensize=get_screen_size()

    if screensize[1] lt 900 then begin
      nlines_modules=10
    endif else begin
      nlines_modules=20
    endelse
	title="GPI QUEUE Viewer: "+self.queuepath
    CASE !VERSION.OS_FAMILY OF  
        ; **NOTE** Mac OS X reports an OS family of 'unix' not 'MacOS'
       'unix': begin 
        self.drfbase=widget_base(title=title, $
        /BASE_ALIGN_LEFT,/column, /tlb_size_events, /tlb_kill_request_events, resource_name='GPI_DRP')
         end
       'Windows'   :begin
       self.drfbase=widget_base(title=title, $
        /BASE_ALIGN_LEFT,/column, bitmap=self.dirpro+path_sep()+'gpi.bmp',/tlb_size_events, /tlb_kill_request_events)
         end

    ENDCASE

    guibase=self.drfbase

    ;create file selector
    ;-----------------------------------------
	DEBUG_SHOWFRAMES=0
        

	  ; what colors to use for cell backgrounds? Alternate rows between
	  ; white and off-white pale blue
	  self.table_BACKground_colors = ptr_new([[255,255,255],[240,240,255]])

	COLUMN_LABELS=['DRF Name','Recipe','Type','# FITS']
	ncols=n_elements(column_labels)
	self.tableSelected = WIDGET_TABLE(guibase, $; VALUE=data, $ ;/COLUMN_MAJOR, $ 
			COLUMN_LABELS=COLUMN_LABELS,/resizeable_columns, $
			xsize=ncols,ysize=20,uvalue='tableselec',value=(*self.currDRFSelec), /TRACKING_EVENTS,$
			/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =nlines_modules,COLUMN_WIDTHS=[500,150,70,70],frame=1,/ALL_EVENTS,/CONTEXT_EVENTS, $
				background_color=rebin(*self.table_BACKground_colors,3,2*ncols,/sample)  ,resource_name="Table"  ) ;,/COLUMN_MAJOR                

	; Create the status log window 
	tmp = widget_label(guibase, value="   " )
	tmp = widget_label(guibase, value="History: ")
	info=widget_text(guibase,/scroll, xsize=120, scr_xsize=800,ysize=6, /ALIGN_LEFT, uval="text_status",/tracking_events);xoffset=5,yoffset=5)
	self.widget_log = info

    ;;create execute and quit button
    ;-----------------------------------------
    drfbaseexec=widget_base(guibase,/BASE_ALIGN_LEFT,/row)
    button2b=widget_button(drfbaseexec,value="Rescan",uvalue="Rescan", /tracking_events)
    button2b=widget_button(drfbaseexec,value="Clear Completed",uvalue="cleardone", /tracking_events)
    button2b=widget_button(drfbaseexec,value="Re-queue selected",uvalue="requeue", /tracking_events)
    button2b=widget_button(drfbaseexec,value="View/Edit in DRFGUI",uvalue="DRFGUI", /tracking_events)
    button2b=widget_button(drfbaseexec,value="Delete selected",uvalue="Delete", /tracking_events)
    button2b=widget_button(drfbaseexec,value="Delete All",uvalue="DeleteAll", /tracking_events)


    space = widget_label(drfbaseexec,uvalue=" ",xsize=200,value='  ')
    button3=widget_button(drfbaseexec,value="Close queueview",uvalue="QUIT", /tracking_events, resource_name='red_button');, $
    self.textinfoid=widget_label(guibase,uvalue="textinfo",xsize=800,value='  ')
    ;-----------------------------------------

	storage = {self: self}
    widget_control,guibase,set_uvalue=storage,/no_copy
    return, guibase
end

pro queueview::post_init, _extra=_extra

	self->rescan;,/initialize
    widget_control, self.drfbase, timer=1

		geomb = widget_info(self.drfbase,/geom)
		geomt = widget_info(self.tableselected,/geom)
		geomlog = widget_info(self.widget_log,/geom) ; sets minimum width


	widget_control, self.tableSelected, set_table_select=[-1,-1,-1,-1]
	self.geom_controls = [ geomb.scr_xsize-geomt.scr_xsize, geomb.scr_ysize-geomt.scr_ysize-geomlog.scr_ysize]

end


;-----------------------
PRO queueview__define


    state = {  queueview,                 $
              selectype:0,$
              currtype:0,$
              currseq:0,$
              nbdrfSelec:0,$
			  selection: '', $
			  geom_controls: [0,0], $ ; for use in resize events
			  configparser: obj_new(), $
			  parser: obj_new(), $
              currDRFSelec: ptr_new(), $
           INHERITS drfgui}


end
