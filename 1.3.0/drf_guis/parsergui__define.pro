;+-----------------------------------------
; parsergui__define.pro
;
; DATA PARSER: select files to process and create a list of DRFs to be executed by the pipeline.
;
; This is actually implemented as a subclass of the drfgui. The widgets
; displayed on screen are very different but this allows the use of the same
; recipe manipulation and writing routines already defined in drfgui.
;
;
; NOTES
;   This is a rather complicated program, with lots of overlapping data
;   structures. Be careful and read closely when editing!
;
;   Module arguments are stored in the PrimitiveInfo structure in memory.
;   Right now this gets overwritten frequently (whenever you change a template),
;   which is annoying, and should probably be fixed.
;
;
;   MORE NOTES TO BE ADDED LATER!
;
;
;    self.PrimitiveInfo            a parsed DRSConfig.xml file, produced by
;                            the ConfigParser. This contains knowledge of
;                            all the modules and their arguments, stored as
;                            a bunch of flat lists. It's not a particularly
;                            elegant data structure, but it's too late to change
;                            now!  Much of the complexity with indices is a
;                            result of indexing into this in various ways.
;
;    self.nbModuleSelec        number of modules in current DRF list
;    self.currModSelec        list of modules in current DRF list
;    self.curr_mod_indsort    indices into curr_mod_avai in alphabetical order?
;                            in other words, matching the displayed order in the
;                            Avail Table
;
;
;
;
;--------------------------------------------------------------------------------

; author : 2010-02 J.Maire created
; 2010-08-19 : JM added parsing of arclamp images



;+--------------------------------------------------------------------------------
; parsergui::init
;    object initialization routine for parsergui. Just calls the parent one, and sets
;    the debug flag as needed.
;
;    See also the ::init_data and ::post_init procedures below.
;
;    KEYWORDS:
;		parse_contents_of=		Provide a directory path and it will parse all
;								the contents of that directory.
;-
function  parsergui::init, groupleader, parse_contents_of=parse_contents_of, _extra=_extra
  self.DEBUG = gpi_get_setting('enable_parser_debug', /bool, default=0,/silent) ; print extra stuff?
  self.xname='parsergui'
  self.name = 'GPI Data Parser'
  if self.debug then message,/info, 'Parser init'
  drfgui_retval = self->gpi_recipe_editor::init(groupleader, _extra=_extra)
  self.selection = ptr_new([''])

  if keyword_set(parse_contents_of) then message,"Not yet implemented"
  return, drfgui_retval
end

;+--------------------------------------------------------------------------------
; parsergui::init_data
;    initialize object data. Is called from the parent object class' init method
;-
pro parsergui::init_data, _extra=_extra

  if self.debug then message,/info, 'Parser init data'
  ;self->gpi_recipe_editor::init_data ; inherited from DRFGUI class


  self.outputdir= "AUTOMATIC" ; implies to use $GPI_REDUCED_DATA_DIR or a subdirectory depending on value of gpi_get_setting('organize_reduced_data_by_dates',/bool)
  self.recipes_table=      ptr_new(/ALLOCATE_HEAP)

  if gpi_get_setting('organize_recipes_by_dates',/bool) then begin
    self.drfpath = gpi_get_directory('RECIPE_OUTPUT_DIR') + path_sep() + gpi_datestr(/current)
    self->Log,"Outputting recipes based on date to "+self.drfpath
  endif else begin
    self.drfpath = gpi_get_directory('RECIPE_OUTPUT_DIR')
    self->Log, "Outputting recipes to current working directory: "+self.drfpath
  endelse



end


;+--------------------------------------------------------------------------------
; parsergui::refresh_filenames_display
;	Refresh display of loaded files
;-
pro parsergui::refresh_filenames_display

  ; TODO - option to just display filenames if called before the headers are
  ; read in?
  widget_control,self.top_base,get_uvalue=storage
  info = self.fileset->get_info()
  if  size(info,/tname) eq 'STRING' then summary=info else summary=info.summary
  widget_control,storage.file_table_id, set_value=summary
end


;+-----------------------------------------
; parsergui::addfile
;
;     This adds a list of files to the current list
;     See ::ask_add_file for the GUI code that interacts with users for this.
;
;     Add one or more new file(a) to the Input FITS files list, validate them
;     and check keywords, and then apply the parsing rules to generate recipes.
;
;-
pro parsergui::addfile, filenames, n_added = n_added
  self->Log, "Loading files and reading headers..."

  self.fileset->add_files, filenames, count_added=n_added
  self.fileset->scan_headers
  self->refresh_filenames_display
end

;+-----------------------------------------
; parsergui::removefile
;
;     This removed a list of files to the current list
;
;     Add one or more new file(a) to the Input FITS files list, validate them
;     and check keywords, and then apply the parsing rules to generate recipes.
;
;-
pro parsergui::removefiles, filenames_to_remove, n_removed=n_removed
  self->Log, "Removing files..."

  n_to_remove =n_elements(filenames_to_remove)
  if n_to_remove eq 0 then return ; nothing to do

  self.fileset->remove_files, filenames_to_remove, count_removed=n_removed
  self->refresh_filenames_display
end



;+-----------------------------------------
; parsergui::parse_current_files
;
;     This is actually the main logic routine for parsergui.
;
;     Add one or more new file(a) to the Input FITS files list, validate them
;     and check keywords, and then apply the parsing rules to generate recipes.
;
;
;
;-
pro parsergui::parse_current_files


pc = obj_new('parsercore', where_to_log=self)
results = pc.parse_fileset_to_recipes(self.fileset)

nr  = pc.num_recipes()

for i=0,nr-1 do begin
	drf = results[i]
	self->add_recipe_to_table, drf->get_last_saved_filename(), drf, 0
endfor






end

;+-----------------------------------------
; parsergui::lookup_template_filename
;   Given a template descriptive name, return the filename that matches.
;-
function parsergui::lookup_template_filename, requestedname
  if not ptr_valid(self.templates) then self->scan_templates

  return, gpi_lookup_template_filename( requestedname, parent_window=self.top_base)

end


;+-----------------------------------------
; parsergui::create_recipe_from_template
; 	Creates a recipe from a template and a list of FITS files.
;
; INPUTS:
;   templatename :	filename of template
;   fitsfiles :		str array of filenames
;   current :		structure with current settings from file parsing for the
;					files in this recipe (filter, obstype, disperser etc)
;
; KEYWORDS:
; 	index=		index to use when inserting this into the GUI table for display
;
;-
pro parsergui::create_recipe_from_template, templatename, fitsfiles, current,  index=index


  drf = gpi_create_recipe_from_template( templatename, fitsfiles,  $
    recipedir=self.drfpath, outputdir=self.outputdir, $
    filename_counter=self.num_recipes_in_table+1, $
    outputfilename=outputfilename)

  self->add_recipe_to_table, outputfilename, drf, current, index=index

  if widget_info(self.autoqueue_id ,/button_set)  then begin
  	message,/info, 'Automatically Queueing recipes is enabled.'
  	drf->queue , queued_filename=queued_filename, comment=" Created by the Data Parser GUI"
  	message,/info, ' Therefore also wrote file to :' + queued_filename
  endif

end


;+--------------------------------------------
; parsergui::clone_recipe_and_swap_template
;     starting from an existing recipe, create a new recipe using a different
;     template but otherwise the same files and metadata
;
;     This is used for some of the templates, for instance creating bad pixel
;     maps is cloned from a recipe used to reduce darks.
;
;
;   KEYWORDS:
;		insert_index	index to use when creating recipe filename to add it
;						into the table in the parser GUI display
;-

pro parsergui::clone_recipe_and_swap_template, existing_recipe_index, newtemplatename,  insert_index=insert_index, $
  lastfileonly=lastfileonly

  existingdrf = (*self.recipes_table)[0, existing_recipe_index]
  drf = obj_new('drf', existingdrf)

  ;existingdrffiles =drf->get_inputdir() + path_sep() + drf->get_datafiles()
  existingdrffiles = drf->get_datafiles(/absolute)

  if keyword_set(lastfileonly) then existingdrffiles = existingdrffiles[n_elements(existingdrffiles)-1]
  ; copy over the descriptive info settings from the prior recipe
  existing_metadata= {filter: (*self.recipes_table)[3,existing_recipe_index], $
    obstype:(*self.recipes_table)[4,existing_recipe_index], $
    dispersr: (*self.recipes_table)[5,existing_recipe_index], $
    obsmode: (*self.recipes_table)[6,existing_recipe_index], $
    lyotmask: (*self.recipes_table)[7,existing_recipe_index], $
    obsclass: (*self.recipes_table)[8,existing_recipe_index], $
    itime:(*self.recipes_table)[9,existing_recipe_index], $
    object:(*self.recipes_table)[10,existing_recipe_index]}

  newtemplatefilename = self->lookup_template_filename(newtemplatename)
  self->create_recipe_from_template, newtemplatefilename, existingdrffiles, existing_metadata,  index=insert_index
end

;+
; parsergui::add_recipe_to_table
;    append into table for display on screen and user manipulation
;
;    PARAMETERS:
;        filename :   string, name of DRF file on disk
;        drf :        DRF object corresponding to that file
;        current :    structure with current settings from file parsing for the
;                     files in this recipe (filter, obstype, disperser etc)
;-

pro parsergui::add_recipe_to_table, filename, drf, current, index=index

  short_filename = gpi_shorten_path(filename)
  ; First let's find out if this recipe is already present in the table, in
  ; which case we don't need to add anything. 
  if self.num_recipes_in_table ge 1 then begin
	current_recipes = (*self.recipes_table)[0,*]
	wm = where(current_recipes eq short_filename, mct)
	if mct gt 0 then begin
		self->Log, "Recipe already in table: "+gpi_shorten_path(filename)
		return
	endif
  endif

  ; Otherwise we need to go ahead and add the relevant info to the table. 

  drf_summary = drf->get_summary()
  current=drf->retrieve_extra_metadata()

  new_recipe_row = [short_filename, drf_summary.name,   drf_summary.reductiontype, current.filter, $
	current.obstype, current.dispersr, current.obsmode, current.obsclass, $
	string(current.itime,format='(F7.1)'), current.object, strc(drf_summary.nfiles)]

  ; what I wouldn't give here to be able to use a Python List, or even just to
  ; use IDL 8.0 with its list function and null lists... argh!
  ;
  if self.num_recipes_in_table eq 0 then begin
    ; THis is the first recipe, just create the table with 1 row
    (*self.recipes_table)= new_recipe_row
  endif else begin
    nrecords =  (size(*self.recipes_table))[2]
    if ~(keyword_set(index)) then index = nrecords ; insert at end by default

    index = (0 > index) < nrecords ; limit insertion indices to plausible values

    if index eq 0 then begin
      ; insert at front of table
      (*self.recipes_table)=[[new_recipe_row], [(*self.recipes_table)]]
    endif else if index eq nrecords then begin
      ; Append to end of table
      (*self.recipes_table)=[[(*self.recipes_table)],[new_recipe_row]]
    endif else begin
      ; insert this recipe in a specific position earlier in the table
      (*self.recipes_table) = [ [(*self.recipes_table)[*, 0:index-1]], [new_recipe_row], [(*self.recipes_table)[*,index:*]]]
    endelse
  endelse


  self.num_recipes_in_table+=1

  widget_control, self.table_recipes_id, ysize=((size(*self.recipes_table))[2] > 20 )
  widget_control, self.table_recipes_id, set_value=(*self.recipes_table)[0:10,*]
  widget_control, self.table_recipes_id, background_color=rebin(*self.table_BACKground_colors,3,2*11,/sample)

end



;+-----------------------------------------
; parsergui::AskReparseAll
;-
pro parsergui::AskReparseAll, extramessage=extramessage
	
	messagetext = ["Please confirm whether you want to re-parse the current list of input FITS files,", $
		"and generate all new recipes? ", "This will discard and/or overwrite all recipes currently present in the recipe list.", "", "Re-parse all files now?"]

	if keyword_set(extramessage) then messagetext = [extramessage, messagetext]
	
    res =  dialog_message(messagetext , $
      title="Re-parse the updated list of files?", dialog_parent=self.top_base, /question)

    if res eq 'Yes' then begin
      self->Log,'User requested re-parsing all files.'
	  self->DeleteAllRecipes,/noconfirm
      self->parse_current_files
    endif

end





;+-----------------------------------------
; parsergui::QueueAll
;
;-
pro parsergui::QueueAll
  self->Log, "Adding all Recipes to queue in "+gpi_get_directory('GPI_DRP_QUEUE_DIR')
  for ii=0,self.num_recipes_in_table-1 do begin
    if (*self.recipes_table)[0,ii] ne '' then begin
      self->queue, (*self.recipes_table)[0,ii]
    endif
  endfor
  self->Log,'All Recipes have been succesfully added to the queue.'
end


;+-----------------------------------------
; parsergui::DeleteSelectedRecipe
;
;-
pro parsergui::DeleteSelectedRecipe
  ; we can assume the self.selection array already contains the selected
  ; recipe(s)

  if n_elements(*self.selection) eq 1 then begin
    query = ['Are you sure you want to delete the recipe','', *self.selection+"?"]
  endif else begin
    query = ['Are you sure you want to delete the following recipes?','', *self.selection]
  endelse


  if confirm(group=self.top_base,message=query, label0='Cancel',label1='Delete', title="Confirm Delete") then begin

    keep_rows = bytarr(self.num_recipes_in_table)+1
    for i=0,n_elements(*self.selection)-1 do begin
      file_delete, (*self.selection)[i],/allow_nonexist
      self->Log, 'Deleted file '+(*self.selection)[i]
      wm = where((*self.recipes_table)[0,*] eq (*self.selection)[i])
      keep_rows[wm]=0
    endfor

    if total(keep_rows) gt 0 then begin
      ;indices = indgen(self.num_recipes_in_table)
      new_indices = where(keep_rows)
      (*self.recipes_table) = (*self.recipes_table)[*, new_indices]
      self.num_recipes_in_table= total(keep_rows)
    endif else begin
      self.num_recipes_in_table=0
      (*self.recipes_table)[*] = ''
    endelse

    *self.selection= ['']

    widget_control,   self.table_recipes_id,  set_value=(*self.recipes_table)[*,*]
    ; no - don't set the selection to zero and reset the view, keep
    ; those the same if possible.
    ;, SET_TABLE_SELECT =[-1,-1,-1,-1] ; no selection
    ;widget_control,   self.table_recipes_id, SET_TABLE_VIEW=[0,0]

  endif



end



;+-----------------------------------------
; parsergui::DeleteAllRecipes
;    Deletes all recipes, like the name says
;    The /noconfirm option should only be used as part of reparsing the files
;    after the user has already confirmed that the reparsing is desired. 
;-
pro parsergui::DeleteAllRecipes, noconfirm=noconfirm


  if keyword_set(noconfirm) || $
	  confirm(group=self.top_base,message="Are you sure you want to delete ALL the recipes?", label0='Cancel',label1='Delete', title="Confirm Delete") then begin

    for i=0,self.num_recipes_in_table-1 do begin
      file_delete, (*self.recipes_table)[0,i],/allow_nonexist
      self->Log, 'Deleted file '+ (*self.recipes_table)[0,i]
    endfor

    self.num_recipes_in_table=0
    (*self.recipes_table)[*] = ''

    *self.selection= ['']

    widget_control,   self.table_recipes_id,  set_value=(*self.recipes_table)[*,*], set_table_view=[0,0]

  endif


end






;+-----------------------------------------
; parsergui::event
;   actual event handler for all GUI events
;
;-
pro parsergui::event,ev

  ;get type of event
  widget_control,ev.id,get_uvalue=uval

  ;get storage
  widget_control,ev.top,get_uvalue=storage

  if size(uval,/TNAME) eq 'STRUCT' then begin
    ; TLB event, either resize or kill_request
    case tag_names(ev, /structure_name) of

      'WIDGET_KILL_REQUEST': begin ; kill request
        if confirm(group=ev.top,message='Are you sure you want to close the Data Parser GUI?',$
          label0='Cancel',label1='Close') then obj_destroy, self
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
        'tableselec':textinfo='Select a Recipe file and click Queue, Open, or Delete below to act on that recipe.' ; Left-click to see or change the DRF | Right-click to remove the selected DRF from the current DRF list.'
        'text_status':textinfo='Status log message display window.'
        'ADDFILE': textinfo='Click to add files to current input list.'
        'WILDCARD': textinfo='Click to add files to input list using a wildcard (*.fits etc)'
        'REMOVE': textinfo='Click to highlight a file, then press this button to remove that currently highlighted file from the input list.'
        'REMOVEALL': textinfo='Click to remove all files from the input list'
        'REPARSE': textinfo='Click to reprocess all the currently selected FITS files to generate recipes.'
        'DRFGUI': textinfo='Click to load currently selected Recipe into the Recipe Editor'
        'Delete': textinfo='Click to delete the currently selected Recipe. (Cannot be undone!)'
        'QueueAll': textinfo='Click to add all DRFs to the execution queue.'
        'QueueSelected': textinfo='Click to add the currently selected Recipe to the execution queue.'
        'QUIT': textinfo='Click to close this window.'
        else:
      endcase
      widget_control,self.textinfo_id,set_value=textinfo
      ;widget_control, event.ID, SET_VALUE='Press to Quit'
    endif else begin
      widget_control,self.textinfo_id,set_value=''
      ;widget_control, event.id, set_value='what does this button do?'
    endelse
    return
  endif


  ; Double clicks in the list widget should launch a gpitv for that file.
  if (tag_names(ev, /structure_name) EQ 'WIDGET_LIST') then begin
    if ev.clicks eq 2 then begin
      fn = (self.fileset->get_filenames())[ev.index]
      gpitv, ses=self.session+1,  fn
      message, 'Opening in GPITV #'+strc(self.session+1)+" : "+fn, /info
    endif
  endif

  ; Menu and button events:
  case uval of

    'tableselec':begin
    IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CELL_SEL') && (ev.sel_top ne -1) THEN BEGIN  ;LEFT CLICK
      selection = WIDGET_INFO((self.table_recipes_id), /TABLE_SELECT)  ; returns [LEFT, TOP, RIGHT, BOTTOM]

      ;;uptade arguments tab
      if n_elements((*self.recipes_table)) eq 0 then return
      self.num_recipes_in_table=n_elements((*self.recipes_table)[0,*])
      ;print, self.num_recipes_in_table
      ; FIXME check error condition for nothing selected here.
      startselected=selection[1]
      endselected=selection[3] < self.num_recipes_in_table
      if startselected lt self.num_recipes_in_table then *self.selection =reform((*self.recipes_table)[0,startselected:endselected])
      ;if indselected lt self.num_recipes_in_table then begin
      ;print, "Starting DRFGUI with "+ (*self.recipes_table)[0,indselected]
      ;gpidrfgui, drfname=(*self.recipes_table)[0,indselected], self.top_base
      ;endif

    ENDIF
  end
  'ADDFILE' : self->ask_add_files
  'WILDCARD' : self->ask_add_files_wildcard
  'FNAME' : begin
    ;(*storage.splitptr).selindex = ev.index
  end
  'REMOVE' : begin

    widget_control,self.top_base,get_uvalue=storage
    selected_index = widget_info(storage.file_table_id,/list_select) ;
    n_selected_index = n_elements(selected_index)
    if (n_selected_index eq 1 ) then if (selected_index eq -1) then begin
      ret=dialog_message("ERROR: You have to click to select one or more files before you can remove anything.",/error,/center,dialog_parent=self.top_base)
      self->Log, 'You have to click to select one or more files before you can remove anything.'
      return ; nothing is selected so do nothing
    endif

    filelist = self.fileset->get_filenames() 
	; Note: must save this prior to starting the for loop since that will
    ; confuse the list indices, and make us have to bookkeep things as the
    ; list changes during a deletion of multiple files.
    ; not sure this next section is needed?
    if n_selected_index gt n_elements(filelist)-1 then begin
      self->Log, "WARNING: more items selected than total files in the list, somehow. Truncating selection."
      n_selected_index = n_elements(filelist)-1
    endif

    if n_selected_index gt 0 then begin
      filenames_to_remove = filelist[selected_index]
      self->removefiles, filenames_to_remove, n_removed=n_removed

      if n_removed gt 0 then begin
		  self->AskReparseAll, extramessage = "Files have been removed from the list ("+strc(n_removed)+" in total)."
      endif

    endif

  end
  'REMOVEALL' : begin
    if confirm(group=ev.top,message='Remove all FITS files from the list of files to parse?',$
      label0='Cancel',label1='Proceed') then begin
      self.fileset->remove_files,/all
      self->refresh_filenames_display
      self->Log,'All items removed.'
    endif
  end
  'REPARSE': begin
    self->AskReparseAll
  end
  'sortmethod': begin
    sortfieldind=widget_info(self.sortfileid,/DROPLIST_SELECT)
  end

  'sortdata': begin
    sortfieldind=widget_info(self.sortfileid,/DROPLIST_SELECT)
    file = (*storage.splitptr).filename
    printname = (*storage.splitptr).printname
    findex = (*storage.splitptr).findex
    ;datefile = (*storage.splitptr).datefile
    datefile=(self.fileset->get_info() ).mjdobs

    wgood = where(strc(file) ne '',goodct)
    if goodct eq 0 then begin
      self->Log, "No file have been selected - nothing to sort!"
      return

    endif

    case (self.sorttab)[sortfieldind] of
      'obs. date/time': begin
        juldattab=dblarr(findex)
        for i=0,findex-1 do begin
          dateobs=self->resolvekeyword( file[i], 1,'DATE-OBS')
          timeobs=self->resolvekeyword( file[i], 1,'TIME-OBS')
          if (dateobs[0] ne 0) &&  (timeobs[0] ne 0) then begin
            ;head=headfits( timeobsfile[0])
            dateo=strsplit(dateobs,'-',/EXTRACT)
            timeo=strsplit(timeobs,':',/EXTRACT)
            ;juldattab[i] = JULDAY(date[1], date[2], date[0], time[0], time[1], time[2])
            JULDATE, [float(dateo),float(timeo)], tmpjul
            juldattab[i]=tmpjul
          endif else begin
            self->Log, "DATE-OBS and TIME-OBS not found."
          endelse
        endfor

        indsort=sort(juldattab)
      end
      'OBSID': begin
        obsid=strarr(findex)
        for i=0,findex-1 do begin
          obsid[i]=self->resolvekeyword( file[i], 1,'OBSID')
        endfor
        indsort=sort(obsid)
      end
      'alphabetic filename':  begin
        alpha=strarr(findex)
        for i=0,findex-1 do begin
          alpha[i]= file[i]
        endfor
        indsort=sort(alpha)
      end
      'file creation date':begin
      ctime=findgen(findex)
      for i=0,findex-1 do begin
        ctime[i]= (file_info(file[i])).ctime
      endfor
      indsort=sort(ctime)
    end
  endcase

  self.fileset->sort, indsort

  file[0:n_elements(indsort)-1]= file[indsort]
  printname[0:n_elements(indsort)-1]= printname[indsort]
  ;datefile[0:n_elements(indsort)-1]= datefile[indsort]
  (*storage.splitptr).filename = file
  (*storage.splitptr).printname = printname
  (*storage.splitptr).datefile = datefile
  widget_control,storage.file_table_id,set_value=pfile
end

'outputdir': begin
  widget_control, self.outputdir_id, get_value=result
  self.outputdir = result
  self->log,'Output Directory changed to: '+self.outputdir
  if result eq 'AUTOMATIC' then begin
    self->Log, '   Actual output directory will be determined automatically based on data'
  endif else begin
    if ~file_test(result,/dir) then self->Log, "Please note that that output directory does not exist."
    if ~file_test(result,/write) then self->Log, "Please note that that output directory is not writeable."
  endelse

end

'outputdir_browse': begin
  result = DIALOG_PICKFILE(TITLE='Select a OUTPUT Directory', /DIRECTORY,/MUST_EXIST)
  if result ne '' then begin
    self.outputdir = result
    widget_control, self.outputdir_id, set_value=self.outputdir
    self->log,'Output Directory changed to: '+self.outputdir
  endif
end
'logdir': begin
  result= DIALOG_PICKFILE(TITLE='Select a LOG Path', /DIRECTORY,/MUST_EXIST)
  if result ne '' then begin
    self.logdir =result
    widget_control, self.logdir_id, set_value=self.logdir
    self->log,'Log path changed to: '+self.logdir
  endif
end
'Delete': self->DeleteSelectedRecipe
'DRFGUI': begin ; Open the recipe editor for the FIRST selected recipe only
  if (*self.selection)[0] eq '' then return else rec_editor = obj_new('gpi_recipe_editor', drfname=(*self.selection)[0], self.top_base)
end

'QueueAll'  : self->QueueAll

'QueueSelected'  : begin
  if (*self.selection)[0] eq '' then begin
    self->Log, "Nothing is currently selected!"
    return ; nothing selected
  endif else begin
    nselected = n_elements(*self.selection)
    for i=0,nselected-1 do begin
      self->queue, (*self.selection)[i]
      self->Log,'Queued '+(*self.selection)[i]
    endfor
  endelse
end
'QUIT'    : self->confirm_close
;begin
;if confirm(group=ev.top,message='Are you sure you want to close the Data Parser GUI?',$
;label0='Cancel',label1='Close', title='Confirm close') then obj_destroy, self
;end
'direct':begin
if widget_info(self.autoqueue_id ,/button_set)  then chosenpath=gpi_get_directory('GPI_DRP_QUEUE_DIR') else chosenpath=self.drfpath
self->Log,'All DRFs will be created in '+chosenpath
end
'about': begin
  tmpstr=gpi_drp_about_message()
  ret=dialog_message(tmpstr,/information,/center,dialog_parent=ev.top)
end
'top_menu': begin
  case ev.value of
    'Add Files...': self->ask_add_files
    'Add Files via Wildcard...': self->ask_add_files_wildcard
    'Open in Recipe Editor': if (*self.selection)[0] eq '' then return else rec_editor = obj_new('gpi_recipe_editor', drfname=(*self.selection)[0], self.top_base)
    'Queue all Recipes': self->QueueAll
    'Quit Data Parser': self->confirm_close
    'Delete selected Recipe': self->DeleteSelectedRecipe
    'Delete All Recipes': self->DeleteAllRecipes
    'Data Parser Help...': gpi_open_help, 'usage/data_parser.html'
    'Recipe Templates Help...': gpi_open_help, 'usage/templates.html'
    'GPI DRP Help...': gpi_open_help, ''
    'About': begin
      tmpstr=gpi_drp_about_message()
      ret=dialog_message(tmpstr,/information,/center,dialog_parent=ev.top)
    end
  endcase


end
else: begin
  addmsg, storage.info, 'Unknown event in event handler - ignoring it!'+uval
  message,/info, 'Unknown event in event handler - ignoring it!'+uval

end
endcase

end

;+------------------------------------------------
; parsergui::ask_add_files
;
;	Ask the user what new files to add, then add them.
;	See ::addfile for the code that actually adds the files
;
pro parsergui::ask_add_files
  ;-- Ask the user to select more input files:
  if self.last_used_input_dir eq '' then self.last_used_input_dir = self->get_default_input_dir()

  if keyword_set(gpi_get_setting('at_gemini', default=0,/silent)) then begin
    filespec = 'S20'+gpi_datestr(/current)+'*.fits'
  endif else begin
    filespec = '*.fits;*.fits.gz'
  endelse

  result=dialog_pickfile(path=self.last_used_input_dir,/multiple,/must_exist,$
    title='Select Raw Data File(s)', filter=filespec)
  result = strtrim(result,2)

  if result[0] ne '' then begin
    self.last_used_input_dir = file_dirname(result[0])
    self->AddFile, result, n_added=n_added
    if n_added gt 0 then self->parse_current_files
  endif

end

;+------------------------------------------------
; parsergui::ask_add_files_wildcard
;
;	Ask the user what filname wildcard to add, then add them.
;
;	See ::addfile for the code that actually adds the files
;
pro parsergui::ask_add_files_wildcard

  if self.last_used_input_dir eq '' then self.last_used_input_dir = self->get_default_input_dir()

  caldat,systime(/julian),month,day,year
  datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')

  command=textbox(title='Input a Wildcard-listing Command (*,?,[..-..])',$
    group_leader=self.top_base,label='',cancel=cancelled,xsize=500,$
    value=self.last_used_input_dir+path_sep()+'*'+datestr+'*')

  if cancelled then begin
    self->log, "User cancelled adding files"
    return
  endif else begin
    self->Log, "Adding files using: "+command
    self.fileset->add_files_from_wildcard, command, count_added=count_added
    self->Log, "Added "+strc(count_added)+" files."
    self.fileset->scan_headers
    self->refresh_filenames_display
  endelse

  self->parse_current_files

end


;+-----------------------------------------
; parsergui::queue
;    Add a file to the queue
;    (from a filename, assuming that file already exists on disk.)
;-
pro parsergui::queue, filename

  if ~file_test(filename) then begin
    widget_control,self.top_base,get_uvalue=storage
    self->log,"File "+filename+" does not exist!"
    return
  endif

  ; Make sure the filename ends with '.waiting.xml'
  if strpos(filename,".waiting.xml") eq -1 then begin
    newfilename = file_basename(filename,".xml")+".waiting.xml"
  endif else begin
    newfilename = file_basename(filename)
  endelse

  newfn = gpi_get_directory('GPI_DRP_QUEUE_DIR')+path_sep()+newfilename
  FILE_COPY, filename, newfn,/overwrite
  self->log,'Queued '+newfilename+" to "+newfn

end


;+------------------------------------------------
; parsergui::cleanup
;    Free pointers, clean up memory, and exit.
;-
pro parsergui::cleanup

  ptr_free, self.recipes_table

  self->gpi_recipe_editor::cleanup ; will destroy all widgets
end


;+------------------------------------------------
; parsergui::init_widgets
;    Create all GUI widgets
;-
function parsergui::init_widgets,  _extra=_Extra


  ;create base widget.
  ;   Resize to be large on desktop monitors, or shrink to fit on laptops.
  ;-----------------------------------------
  screensize=get_screen_size()

  if screensize[1] lt 900 then begin
    nlines_status=12
    nlines_file_table=10
    nlines_modules=7
    nlines_args=6
  endif else begin
    nlines_status=12
    nlines_file_table=10
    nlines_modules=10
    nlines_args=6
  endelse

  if screensize[0] lt 1200 then begin
    table_xsize=1150
  endif else begin
    table_xsize=1350
  endelse

  CASE !VERSION.OS_FAMILY OF
    ; **NOTE** Mac OS X reports an OS family of 'unix' not 'MacOS'
    'unix': begin
      resource_name='GPI_DRP_Parser'

    end
    'Windows'   :begin
    bitmap=gpi_get_directory('GPI_DRP_DIR')+path_sep()+'gpi.bmp'
  end

ENDCASE
self.top_base=widget_base(title='Data Parser: Create a Set of GPI Data Reduction Recipes', /BASE_ALIGN_LEFT,/column, MBAR=bar,/tlb_size_events, /tlb_kill_request_events, resource_name=resource_name, bitmap=bitmap )

parserbase=self.top_base
;create Menu

tmp_struct = {cw_pdmenu_s, flags:0, name:''}
top_menu_desc = [ $
  {cw_pdmenu_s, 1, 'File'}, $ ; file menu;
  {cw_pdmenu_s, 0, 'Add Files...'}, $
  {cw_pdmenu_s, 0, 'Add Files via Wildcard...'}, $
  {cw_pdmenu_s, 4, 'Open in Recipe Editor'}, $
  {cw_pdmenu_s, 0, 'Queue all Recipes'}, $
  {cw_pdmenu_s, 0, 'Queue selected Recipe only'}, $
  {cw_pdmenu_s, 4, 'Delete selected Recipe'}, $
  {cw_pdmenu_s, 0, 'Delete All Recipes'}, $
  {cw_pdmenu_s, 6, 'Quit Data Parser'}, $
  {cw_pdmenu_s, 1, 'Help'}, $         ; help menu
  {cw_pdmenu_s, 0, 'Data Parser Help...'}, $
  {cw_pdmenu_s, 0, 'Recipe Templates Help...'}, $
  {cw_pdmenu_s, 0, 'GPI DRP Help...'}, $
  {cw_pdmenu_s, 6, 'About...'} $
  ]

self.menubar = obj_new('checkable_menu',  $
  bar, top_menu_desc, $
  ids = menu_ids, $
  /mbar, $
  /help, $
  /return_name, $
  uvalue = 'top_menu', $
  uname='top_menu')



;create file selector
;-----------------------------------------
DEBUG_SHOWFRAMES=0
top_basefilebutt=widget_base(parserbase,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES, /base_align_center)
label = widget_label(top_basefilebutt, value="Input FITS Files:")
button=widget_button(top_basefilebutt,value="Add File(s)",uvalue="ADDFILE", $
  xsize=90,ysize=30, /tracking_events);,xoffset=10,yoffset=115)
button=widget_button(top_basefilebutt,value="Wildcard...",uvalue="WILDCARD", $
  xsize=90,ysize=30, /tracking_events);,xoffset=110,yoffset=115)
button=widget_button(top_basefilebutt,value="Remove",uvalue="REMOVE", $
  xsize=90,ysize=30, /tracking_events);,xoffset=210,yoffset=115)
button=widget_button(top_basefilebutt,value="Remove All",uvalue="REMOVEALL", $
  xsize=90,ysize=30, /tracking_events)
label = widget_label(top_basefilebutt, value="    ")
button=widget_button(top_basefilebutt,value="Re-Parse All Files",uvalue="REPARSE", $
  xsize=180,ysize=30, /tracking_events)


top_basefilebutt2=top_basefilebutt
self.sorttab=['obs. date/time','alphabetic filename','file creation date']
self.sortfileid = WIDGET_DROPLIST( top_basefilebutt2, title='   Sort data by:',  Value=self.sorttab,uvalue='sortmethod')
drfbrowse = widget_button(top_basefilebutt2,  $
  XOFFSET=174 ,SCR_XSIZE=80, ysize= 30 $; ,SCR_YSIZE=23  $
  ,/ALIGN_CENTER ,VALUE='Sort data',uvalue='sortdata')

top_baseident=widget_base(parserbase,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES)
; file name list widget
file_table=widget_list(top_baseident,xsize=106,scr_xsize=780, ysize=nlines_file_table,$
  xoffset=10,yoffset=150,uvalue="FNAME", /TRACKING_EVENTS,resource_name='XmText',/multiple)

; add 5 pixel space between the filename list and controls
top_baseborder=widget_base(top_baseident,xsize=5,units=0, frame=DEBUG_SHOWFRAMES)

; add the options controls
top_baseidentseq=widget_base(top_baseident,/BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
top_baseborder=widget_base(top_baseidentseq,ysize=1,units=0)
top_baseborder2=widget_base(top_baseidentseq,/BASE_ALIGN_LEFT,/row)
drflabel=widget_label(top_baseborder2,Value='Output Dir=         ')
self.outputdir_id = WIDGET_TEXT(top_baseborder2, $
  xsize=34,ysize=1,$
  /editable,units=0,value=self.outputdir,uvalue='outputdir'  )

drfbrowse = widget_button(top_baseborder2,  $
  XOFFSET=174 ,SCR_XSIZE=75 ,SCR_YSIZE=23  $
  ,/ALIGN_CENTER ,VALUE='Change...',uvalue='outputdir_browse')
;    top_baseborder3=widget_base(top_baseidentseq,/BASE_ALIGN_LEFT,/row)
;    drflabel=widget_label(top_baseborder3,Value='Log Path=           ')
;    self.logdir_id = WIDGET_TEXT(top_baseborder3, $
;                xsize=34,ysize=1,$
;                /editable,units=0 ,value=self.logdir)
;    drfbrowse = widget_button(top_baseborder3,  $
;                        XOFFSET=174 ,SCR_XSIZE=75 ,SCR_YSIZE=23  $
;                        ,/ALIGN_CENTER ,VALUE='Change...',uvalue='logdir')
;
;calibflattab=['Flat-field extraction','Flat-field & Wav. solution extraction']
;the following line commented as it will not be used (uncomment line in post_init if you absolutely want it)
; self.calibflatid = WIDGET_DROPLIST( top_baseidentseq, title='Reduction of flat-fields:  ', frame=0, Value=calibflattab, uvalue='flatreduction')
;one nice logo
button_image = READ_BMP(gpi_get_directory('GPI_DRP_DIR')+path_sep()+'gpi.bmp', /RGB)
button_image = TRANSPOSE(button_image, [1,2,0])
button = WIDGET_BUTTON(top_baseident, VALUE=button_image,  $
  SCR_XSIZE=100 ,SCR_YSIZE=95, sensitive=1 ,uvalue='about')


; what colors to use for cell backgrounds? Alternate rows between
; white and off-white pale blue
self.table_BACKground_colors = ptr_new([[255,255,255],[240,240,255]])

;col_labels = ['Recipe File','Recipe Name','Recipe Type','IFSFILT','OBSTYPE','DISPERSR','OCCULTER','OBSCLASS','ITIME','OBJECT', '# FITS']
col_labels = ['Recipe File','Recipe Name','Recipe Type','IFSFILT','OBSTYPE','DISPERSR','OBSMODE', 'OBSCLASS','ITIME','OBJECT', '# FITS']
xsize=n_elements(col_labels)
self.table_recipes_id = WIDGET_TABLE(parserbase, $; VALUE=data, $ ;/COLUMN_MAJOR, $
  COLUMN_LABELS=col_labels,/resizeable_columns, $
  xsize=xsize,ysize=100,uvalue='tableselec',value=(*self.recipes_table), /TRACKING_EVENTS,$
  /NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =nlines_modules,scr_xsize=table_xsize, $
  COLUMN_WIDTHS=[520,200,100,50,62,62,72,72,62,82, 50],frame=1,/ALL_EVENTS,/CONTEXT_EVENTS, $
  background_color=rebin(*self.table_BACKground_colors,3,2*11,/sample)    ) ;,/COLUMN_MAJOR

; Create the status log window
tmp = widget_label(parserbase, value="   " )
tmp = widget_label(parserbase, value="History: ")
info=widget_text(parserbase,/scroll, xsize=160,scr_xsize=800,ysize=nlines_status, /ALIGN_LEFT, uval="text_status",/tracking_events);xoffset=5,yoffset=5)
self.widget_log = info

;;create execute and quit button
;-----------------------------------------
top_baseexec=widget_base(parserbase,/BASE_ALIGN_LEFT,/row)
button2b=widget_button(top_baseexec,value="Queue all Recipes",uvalue="QueueAll", /tracking_events)
button2b=widget_button(top_baseexec,value="Queue selected Recipes only",uvalue="QueueSelected", /tracking_events)
directbase = Widget_Base(top_baseexec, UNAME='directbase' ,COLUMN=1 ,/NONEXCLUSIVE, frame=0)
self.autoqueue_id =    Widget_Button(directbase, UNAME='direct'  $
  ,/ALIGN_LEFT ,VALUE='Queue all generated recipes automatically',uvalue='direct' )

if gpi_get_setting('parsergui_auto_queue',/bool, default=0,/silent) then widget_control,self.autoqueue_id, /set_button

space = widget_label(top_baseexec,uvalue=" ",xsize=100,value='  ')
button2b=widget_button(top_baseexec,value="Open in Recipe Editor",uvalue="DRFGUI", /tracking_events)
button2b=widget_button(top_baseexec,value="Delete selected Recipe",uvalue="Delete", /tracking_events)

space = widget_label(top_baseexec,uvalue=" ",xsize=100,value='  ')
button3=widget_button(top_baseexec,value="Close Data Parser GUI",uvalue="QUIT", /tracking_events, resource_name='red_button')

self.textinfo_id=widget_label(parserbase,uvalue="textinfo",xsize=900,value='  ')
;-----------------------------------------
maxfilen=gpi_get_setting('parsergui_max_files',/int, default=1000,/silent)
filename=strarr(maxfilen)
printname=strarr(maxfilen)
;datefile=lonarr(maxfilen)
splitptr=ptr_new({filename:filename,$ ; array for FITS filenames loaded
  printname:printname,$	; array for printname
  findex:0,$				; current index to write filename
  ;selindex:0,$			;
  ;datefile:datefile, $	; date of each FITS file (for sort-by-date)
  maxfilen:maxfilen})		; max allowed number of files

storage={info:info,$	; widget ID for information text box
  file_table_id:file_table,$		; widget ID for filename text box
  splitptr:splitptr,$	; structure (pointer)
  self:self}			; Object handle to self (for access from widgets)
widget_control,parserbase,set_uvalue=storage,/no_copy

self->log, "This GUI helps you to parse a set of FITS data files to generate useful reduction recipes."
self->log, "Add files to be processed, and recipes will be automatically created based on FITS keywords."
return, parserbase

end


;-----------------------
; parsergui::post_init
;	Last stage of initialization, runs after GUI widgets are created
;-
pro parsergui::post_init, _extra=_extra
  ; create this in post_init so the GUI widgets are already instantiated
  self.fileset = obj_new('fileset',where_to_log=self, gui_parent_wid=self.top_base)
end
;-----------------------
; parsergui::log
;-
pro parsergui::log, logtext
  if self.textinfo_id ne 0 then $
    widget_control, self.textinfo_id, set_value = logtext
  self->gpi_gui_base::log, logtext

end


;+-----------------------
; parsergui__define
;    Object variable definition for parsergui
;-
PRO parsergui__define


  state = {  parsergui,                 $
    autoqueue_id:0L,$			; widget ID for auto queue button
    table_recipes_id: 0, $	; widget ID for recipes table
    sortfileid :0L,$		    ; widget ID for file list sort options
    num_recipes_in_table:0,$	; # of recipes listed in the table
    selection: ptr_new(), $			; current selection in recipes table
    recipes_table: ptr_new(), $   ; pointer to resizeable string array, the data for the recipes table
    fileset: obj_new(),$      ; Set of loaded files to parse
    DEBUG:0, $				; debug flag, set by pipeline setting enable_parser_debug
    sorttab:strarr(3),$       ; table for sort options
    INHERITS gpi_recipe_editor}


end
