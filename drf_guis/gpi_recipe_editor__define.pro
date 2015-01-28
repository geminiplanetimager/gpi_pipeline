;+----------------------------------------
; gpi_recipe_editor__define.pro 
;
; Recipe Editor GUI
;
; NOTES
;   This is a rather complicated program, with lots of overlapping data
;   structures. Be careful and read closely when editing!
;
;   Ideally this should be refactored to separate the GUI code from the
;   recipe manipulation code (i.e. it should be closer to a
;   model-view-controller architecture which it currently is not at all like.)
;
;   Module arguments are stored in the PrimitiveInfo structure in memory. 
;
;
;   MORE NOTES TO BE ADDED LATER!
;
;
;    self.PrimitiveInfo            a parsed DRSConfig.xml file, produced by
;                            the ConfigParser. This contains knowledge of
;                            all the primitives and their arguments, stored as
;                            a bunch of flat lists. It's not a particularly
;                            elegant data structure, but it's too late to change
;                            now!  Much of the complexity with indices is a
;                            result of indexing into this in various ways.
;
;    self.num_primitives       number of modules in current DRF list
;    self.currModSelec        list of modules in current DRF list
;
;    self.curr_mod_indsort    indices into curr_mod_avai in alphabetical order?
;                            in other words, matching the displayed order in the
;                            Avail Table
;
;--------------------------------------------------------------------------------
;
; author : 2009-09-14 J.Maire created
;            2010-04 M. Perrin: Restructured into an object-oriented widget
;            program.
;
;			2013-10-14 M. Perrin: revamp from drfgui__define to
;			gpi_recipe_editor__define, and substantial internal code
;			reorganization. 
;
;

compile_opt DEFINT32, STRICTARR


;================================================================================
; Helper and utility functions
;
;

;+--------------------------------------------------------------------------------
; gpi_recipe_editor::get_obs_keywords
;     determine the relevant keywords to find out the observation mode of a file. 
;     return as a structure.
;-
function gpi_recipe_editor::get_obs_keywords, filename

	return, gpi_get_obs_keywords(gpi_expand_path(filename), where_to_log=self)

;	if ~file_test(filename) then begin
;		self->Log, "ERROR can't find file: "+filename
;		return, -1
;	endif
;
;
;	; Load FITS file
;	fits_data = gpi_load_fits(filename,/nodata,/silent,/fast)
;	head = *fits_data.pri_header
;	ext_head = *fits_data.ext_header
;	ptr_free, fits_data.pri_header, fits_data.ext_header
;
;	obsstruct = {gpi_obs, $
;				FILENAME: filename,$
;				ASTROMTC: strc(  gpi_get_keyword(head, ext_head,  'ASTROMTC', count=ct0)), $
;				OBSCLASS: strc(  gpi_get_keyword(head, ext_head,  'OBSCLASS', count=ct1)), $
;				obstype:  strc(  gpi_get_keyword(head, ext_head,  'OBSTYPE',  count=ct2)), $
;				obsmode:  strc(  gpi_get_keyword(head, ext_head,  'OBSMODE',  count=ctobsmode)), $
;				OBSID:    strc(  gpi_get_keyword(head, ext_head,  'OBSID',    count=ct3)), $
;				filter:   strc(gpi_simplify_keyword_value(strc(   gpi_get_keyword(head, ext_head,  'IFSFILT',   count=ct4)))), $
;				dispersr: strc(gpi_simplify_keyword_value(gpi_get_keyword(head, ext_head,  'DISPERSR', count=ct5))), $
;				OCCULTER: strc(gpi_simplify_keyword_value(gpi_get_keyword(head, ext_head,  'OCCULTER', count=ct6))), $
;				LYOTMASK: strc(  gpi_get_keyword(head, ext_head,  'LYOTMASK',     count=ct7)), $
;				APODIZER: strc(  gpi_get_keyword(head, ext_head,  'APODIZER',     count=ct8)), $
;				DATALAB:  strc(  gpi_get_keyword(head, ext_head,  'DATALAB',     count=ct11)), $
;				ITIME:    float( gpi_get_keyword(head, ext_head,  'ITIME',    count=ct9)), $
;				COADDS:   fix( gpi_get_keyword(head, ext_head,  'COADDS',    count=ctcoadd)), $
;				OBJECT:   string(  gpi_get_keyword(head, ext_head,  'OBJECT',   count=ct10)), $
;      				ELEVATIO: float(  gpi_get_keyword(head, ext_head,  'ELEVATIO',   count=ct12)), $
;				summary: '',$
;				valid: 0}
;
;	; some are OK to be missing without making it impossible to parse
;	if ct11 eq 0 then obsstruct.datalab = 'no DATALAB'
;	if ct10 eq 0 then obsstruct.object = 'no OBJECT'
;	if ct3 eq 0 then obsstruct.obsid = 'no OBSID'
;	if ct0 eq 0 then obsstruct.astromtc= 'F'
;        if ct12 eq 0 then obsstruct.elevatio = 'no elevation'
;;        if ct13 eq 0 then obsstruct.gcalfilt = 'no gcalfilt'
;;print,'counts',ct1,ct2,ct4,ct5,ct6,ct7,ct8,ct9,ctobsmode
;	; some we need to have in order to be able to parse.
;	vec=[ct1,ct2,ct4,ct5,ct6,ct7,ct8,ct9,  ctobsmode]
;	if total(vec) lt n_elements(vec) then begin
;		obsstruct.valid=0
;		;give some info on missing keyw:
;		keytab=['OBSCLASS','OBSTYPE', 'IFSFILT','DISPERSR','OCCULTER','LYOTMASK','APODIZER', 'ITIME', 'OBSMODE']
;		indzero=where(vec eq 0, cc)
;		;print, "Invalid/missing keywords for file "+filename
;		logmsg = 'Missing keyword(s): '+strjoin(keytab[indzero]," ")+" for "+filename
;		if cc gt 0 then self->Log, logmsg
;		;message,/info, logmsg
;
;		if ct1 eq 0 then obsstruct.obsclass = 'no OBSCLASS'
;		if ct2 eq 0 then obsstruct.obstype = 'no OBSTYPE'
;		if ctobsmode eq 0 then obsstruct.obsmode = 'no OBSMODE'
;
;	endif else begin
;		obsstruct.valid=1
;	endelse
;
;	if obsstruct.dispersr eq 'PRISM' then obsstruct.dispersr='Spectral'	 ; preferred display nomenclature is as Spectral/Wollaston. Both are prisms!
;	if obsstruct.object eq 'GCALflat' then obsstruct.object+= " "+gpi_get_keyword(head, ext_head,  'GCALLAMP')
;
;	if obsstruct.coadds eq 1 then coaddstr = "     " else coaddstr = "*"+string(obsstruct.coadds,format='(I-4)')
;    obsstruct.summary = file_basename(filename)+"     "+string(obsstruct.obsmode,format='(A-10)')+" "+string(obsstruct.dispersr,format='(A-10)') +" "+string(obsstruct.obstype, format='(A-10)')+$
;				" "+string(obsstruct.itime,format='(F5.1)')+coaddstr+"  "+string(obsstruct.object,format='(A-15)')+"       "+obsstruct.datalab+" "+string(obsstruct.elevatio,format='(F3.5)')
; 
;	
;	return, obsstruct
;
end


;+-----------------------------------------
; gpi_recipe_editor::get_default_input_dir
;    Return the name of the directory we should look in for new files
;    after startup of the recipe editor. 
;
;    This is by default the current IFS raw data directory
;
;    See also the last_used_input_dir variable, which we use to keep
;    track of whether the user has manually selected another directory, and
;    then use it on subsequent invokations
;-
function gpi_recipe_editor::get_default_input_dir

	if gpi_get_setting('organize_raw_data_by_dates',/bool,/silent) then begin
		; Input data organized by dates
		inputdir = gpi_get_directory('RAW_DATA') + path_sep() + gpi_datestr(/current)
	
		; if there isn't a directory for today's date, then just look in the
		; data root by default
		if not file_test(inputdir) then inputdir = gpi_get_directory('RAW_DATA')

		self->Log,"Looking for new data based on date in "+inputdir

	endif else begin
		; input data in one huge directory
		inputdir = gpi_get_directory('GPI_RAW_DATA_DIR') 
		self->Log,"Looking for new data in "+inputdir
	endelse 

    return, inputdir

end


;================================================================================
; Functions for dealing with templates and DRFs

;+-------------------------------------
; gpi_recipe_editor::load_configParser
;    Parse the DRS Config XML file 
;    and update knowledge of available modules/primitives
;
;    This function sets a pointer to info on the object structures. 
;    Be sure to free it when you're done. 
;
;-
pro gpi_recipe_editor::load_configParser

    config_file=gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+"gpi_pipeline_primitives.xml" 
    if ~file_test(config_file) then res=dialog_message ('ERROR: Cannot find DRP Primitives Config File! Check for '+config_file+" and check pipeline configuration.")

    ConfigParser = OBJ_NEW('gpiDRSConfigParser')
    ConfigParser->ParseFile, config_file 

    if ~ptr_valid(self.PrimitiveInfo) then self.PrimitiveInfo = ptr_new(ConfigParser->getidlfunc())

    obj_destroy, ConfigParser

end


;+--------------------------------------------------------------------------------
; gpi_recipe_editor::change_current_template
;     Change the current template
;     - look up the filename corresponding to the requested Type and Sequence
;     - load the DRF at that filename
;
; Arguments:
;	typestring		a recipe type string
;	seqnum			index into that list of recipes (i.e. find the 3rd recipe of
;					type X)
;
;	/notemplate		Don't actually load the template. This is used when
;					switching menu options and you don't actually want to overwrite
;					the current recipe completely.
;	/cleardata		Clear the data files from the recipe editor instead of preserving them
;-
pro gpi_recipe_editor::change_current_template, typestring,seqnum, notemplate=notemplate, cleardata=cleardata


  ;; check if the current recipe has been modified
  if obj_valid(self.drf) then begin
     if self.drf->is_modified() then begin
        res =  dialog_message('The currently opened recipe file has been modified. Loading a new template will discard your modifications. Are you sure you want to change templates?', $
                              title="Discard changes?", dialog_parent=self.top_base, /question) 
        if res ne 'Yes' then return
     endif
     
  endif
  
  ;; check that the requested reduction type is valid and retrieve its
  ;; template filenames
  wm = where((*self.templates).reductiontype eq typestring, mct)
  if mct eq 0 then begin
     message, 'Requested reduction type "'+typestring+'" is invalid/unknown. Cannot load any Recipes!',/info
     widget_control, self.template_name_id,SET_DROPLIST_SELECT=0
     return
  endif
  
  
  ;; Now we can switch to that template
  if ~(keyword_set(notemplate)) then begin
    chosen_template = wm[seqnum]
    widget_control, self.template_name_id,SET_DROPLIST_SELECT=seqnum
    print, "Chosen template filename:"+((*self.templates)[chosen_template]).filename
     
    ;; Load the new template, preserving the data files of the current recipe
    if obj_valid(self.drf) then datafiles = self.drf->get_datafiles()
    
    self->open, ((*self.templates)[chosen_template]).filename,  /template

	if ~(keyword_set(cleardata)) then begin
		if n_elements(datafiles) gt 0 then begin
			self.drf->set_datafiles, datafiles
		endif
	endif else begin
		;clear all loaded files
		self.drf->clear_datafiles
	endelse
	
    self->refresh_filenames_display
     
  endif
  
end


;+--------------------------------------------------------------------------------
; gpi_recipe_editor::update_available_primitives
;    Change the list of Available primitives to match the currently selected
;    Reduction Type
;
;    ARGUMENTS:
;        typestr       string, name of the mode type to use
;        /all			 Display all primitives, no matter what.
;-
pro gpi_recipe_editor::update_available_primitives, requested_type,  all=all

    type=(*self.PrimitiveInfo).reductiontype ; list of type for each module

	indmatch = where(strmatch(type, '*'+requested_type+"*",/fold_case),cm)
	indall   = where(strmatch(type, '*all*',/fold_case),cm)

	new_modules = cmset_op(indmatch,'or', indall) 

	if ~keyword_set(self.showhidden) then begin
		; now let's ignore any which were hidden (i.e. only show the visible ones)
		ind_visible= where( ~strmatch(type, "*HIDDEN*",/fold_case), cvisible)
		new_modules = intersect(new_modules , ind_visible)
	endif


	if keyword_set(all) then new_modules = indgen(n_elements(type))

    *self.indmodtot2avail=new_modules
    *self.indmodtot2avail=(*self.indmodtot2avail)[where(*self.indmodtot2avail ne -1)]
    cm=n_elements(*self.indmodtot2avail)

    if cm ne 0 then begin
        ;self.nbcurrmod=cm
        *self.curr_mod_avai=strarr(cm)

        for i=0,cm-1 do begin
            (*self.curr_mod_avai)[i]=((*self.PrimitiveInfo).names)[(*self.indmodtot2avail)[i]]
            ;*self.indarg=where(   ((*self.PrimitiveInfo).argmodnum) eq ([(*self.indmodtot2avail)[i]]+1)[0], carg)
        endfor    

    endif

    ;;sort in alphabetical order, ignoring case
    *self.curr_mod_indsort=sort(strlowcase(*self.curr_mod_avai))

    (*self.curr_mod_avai)=(*self.curr_mod_avai)[*self.curr_mod_indsort]


    ;; Update the actual table widget.
    if self.tableAvailable_id ne 0 then begin
        widget_control,   self.tableAvailable_id, set_value=transpose(*self.curr_mod_avai);, SET_TABLE_SELECT =[-1,self.num_primitives-1,-1,self.num_primitives-1]
        widget_control,   self.tableAvailable_id, table_ysize=n_elements(*self.curr_mod_avai)
        widget_control,   self.tableAvailable_id, background_color=*self.table_BACKground_colors ; have to reset this when changing table size
        widget_control,   self.tableAvailable_id, SET_TABLE_VIEW=[0,0]
    endif

end    

;+--------------------------------------------------------------------------------
; gpi_recipe_editor::refresh_arguments_table
;    Update the list of parameters/arguments for the current primitive of the
;    current Recipe. 
;    
;    Incidentally this also toggles the state of the 'Choose Calibration
;    File...' button.
;
;	arguments:
;		primitive_index		which primitive's arguments to display in the table?
;		
;
;-
pro gpi_recipe_editor::refresh_arguments_table, primitive_index 

    self.num_primitives = n_elements( self.drf->list_primitives() )

    if n_elements(primitive_index) eq 0 then primitive_index=self.selected_primitive_index
    if primitive_index lt 0 then primitive_index=0
    ;if primitive_index gt self.num_primitives-1 then primitive_index= self.num_primitives-1

	if primitive_index gt self.num_primitives-1 then return

	self.selected_primitive_index = primitive_index
	arg_info = self.drf->get_primitive_args(primitive_index)

	arg_table_text = strarr( n_elements(arg_info.names) ,4)
	arg_table_text[*,0] = arg_info.names
	arg_table_text[*,1] = arg_info.values
	arg_table_text[*,2] = arg_info.ranges
	arg_table_text[*,3] = arg_info.descriptions

    widget_control,   self.tableArgs_id, set_value= arg_table_text 
    widget_control,   self.tableArgs_id, set_table_view= [0,0]


	has_calibration_file = total(strmatch(arg_info.names, 'CalibrationFile')) gt 0
	if has_calibration_file then begin
		wcalfile = where(strupcase(arg_info.names) eq "CALIBRATIONFILE", mct)
		current_value = arg_info.values[wcalfile]
		label = (current_value eq 'AUTOMATIC') ? 'Choose Calibration File...' : 'Automatic Calibration File'


		widget_control, self.button_calfile_id, sensitive=1, set_value=label
	endif else begin
		widget_control, self.button_calfile_id, sensitive=0, set_value='Choose Calibration File...'
	endelse

end

;+--------------------------------------------------------------------------------
; gpi_recipe_editor::refresh_filenames_display
;	Update the displayed list of FITS filenames
;
;-
pro gpi_recipe_editor::refresh_filenames_display, new_selected=new_selected  
    widget_control,self.top_base,get_uvalue=storage  
	filenames = self.drf->get_datafiles(nfiles=nfiles)
	if nfiles gt 0 then begin
		descriptions = strarr(n_elements(filenames))
		for i=0,n_elements(filenames)-1 do descriptions[i] = (self->get_obs_keywords(filenames[i])).summary
	endif else descriptions=['']

    widget_control,storage.fname,set_value= descriptions

end

;+--------------------------------------------------------------------------------
; gpi_recipe_editor::refresh_primitives_table
;	Update the displayed table of primitives in this recipe
;
;-
pro gpi_recipe_editor::refresh_primitives_table, new_selected=new_selected

    self.num_primitives = n_elements( self.drf->list_primitives() )

	primitives_args = (self.drf->get_contents()).primitives

	primitives_table_values = strarr( 3, self.num_primitives)
	primitives_table_values[0, *] = primitives_args.name

	wcalfile = where( tag_names(primitives_args) eq 'CALIBRATIONFILE', mct)
	if mct gt 0 then begin
		primitives_table_values[2, *] = primitives_args.CALIBRATIONFILE
		wauto = where( primitives_args.CALIBRATIONFILE eq 'AUTOMATIC', autoct)
		wmanual = where( primitives_args.CALIBRATIONFILE ne '' and primitives_args.CALIBRATIONFILE ne 'AUTOMATIC',manualct)
		if autoct gt 0 then primitives_table_values[1, wauto] = 'Auto' 
		if manualct gt 0 then primitives_table_values[1, wmanual] = 'Manual' 
	endif

	tableview = widget_info(self.RecipePrimitivesTable_id,/table_view) ; coordinates of top left view corner
    widget_control,   self.RecipePrimitivesTable_id,   set_value=primitives_table_values
	
	if n_elements(new_selected) gt 0 then begin
		widget_control,   self.RecipePrimitivesTable_id,  SET_TABLE_SELECT = [0,new_selected,0,new_selected]
	endif
    widget_control,   self.RecipePrimitivesTable_id,   set_table_view=tableview


end




;+-------------------------------------------------------------------------------
; gpi_recipe_editor::Scan_Templates
;    Read in the available templates from the GPI_DRP_TEMPLATE_DIR directory
;-

PRO  gpi_recipe_editor::Scan_Templates
    compile_opt DEFINT32, STRICTARR

	common GPI_TEMPLATES, templates, templatetype

    ptr_free, self.templates
    ptr_free, self.template_types

	tmp = gpi_lookup_template_filename(/scanonly,/verbose)


 ; 	templatedir = 	gpi_get_directory('GPI_DRP_TEMPLATES_DIR')
 ; 
 ;     message,/info, "Scanning for templates in "+ templatedir
 ;     template_file_list = file_search(templatedir + path_sep() + "*.xml")
 ; 
 ; 
 ;     first_drf = obj_new('drf', template_file_list[0],/quick,/silent)
 ;     templates = replicate(first_drf->get_summary(), n_elements(template_file_list))
 ; 
 ;     for i=0,n_elements(template_file_list)-1 do begin
 ;         message,/info, 'scanning '+template_file_list[i]
 ; 		template = obj_new('drf', template_file_list[i],/quick,/silent)
 ;         templates[i] = template->get_summary()
 ;     endfor
 ; 
 ;     types = uniqvals(templates.reductiontype)
 ; 
 ;     ; What order should the template types be listed in, in the GUI?
 ; 	type_order  = ['SpectralScience','PolarimetricScience','Calibration','Testing']
 ;     
 ;     ; FIXME check if there are any new types not specified in the above list but
 ;     ; present in the templates?
 ;     
 ;     ; conveniently, these filenames will already be in alphabetical order from
 ;     ; the above.
 ;     print, "----- Templates located: ----- "
 ;     for it=0, n_elements(type_order)-1 do begin
 ;         print, " -- "+type_order[it]+" -- "
 ;         wm = where(templates.reductiontype eq type_order[it], mct)
 ;         for im=0,mct-1 do begin
 ;             print, "    "+templates[wm[im]].name+"     "+ templates[wm[im]].filename
 ;         endfor
 ;     endfor
 ; 
    self.templates = ptr_new(templates)
    self.template_types = ptr_new(templatetype)

    print, "----- Above templates added to catalog ----- "
	msg = "List of "+strc(n_elements(*self.templates))+" available templates reloaded"
	if self.textinfo_id ne 0 then widget_control,self.textinfo_id,set_value=msg
	message,/info, msg
end


;+-------------------------------------------------------------------------------
; gpi_recipe_editor::Reload_Primitives_List
;	Reload the list of available primitives
;-

PRO  gpi_recipe_editor::Reload_Primitives_List
    compile_opt DEFINT32, STRICTARR

	msg = "Reloading list of available primitives and arguments..."
	widget_control,self.textinfo_id,set_value=msg
    message,/info, msg
    ptr_free, self.PrimitiveInfo
	self->load_configParser

	msg = "Loaded "+strc(n_elements((*self.primitiveinfo).names))+" available primitives."
	message,/info, msg
	widget_control,self.textinfo_id,set_value=msg

    self->update_available_primitives, self.reductiontype

end



;+--------------------------------------------------------------------------------
; gpi_recipe_editor::changetype
;    Select a new Reduction Type (called in response to the Reduction Type
;    dropdown)
;
;	 type_num	        number of new type
;	 /force_update		by default, this routine does nothing if the type is
;						unchanged. Set /force_update to make it refresh the list
;						anyway no matter what. 
;-
pro gpi_recipe_editor::changetype, type_num, notemplate=notemplate, force_update=force_update

    if ~(keyword_set(force_update)) then if self.reductiontype eq (*self.template_types)[type_num] then return ; do nothing if no change
    
    ; set the reduction type as requested
    self.reductiontype = (*self.template_types)[type_num]         

    wm = where(strmatch((*self.templates).reductiontype, self.reductiontype, /fold_case), mct)
    if mct eq 0 then begin
		message, "Invalid template type, or no known templates for that type: "+self.reductiontype,/info
	    widget_control, self.template_name_id, set_value= ['                ']
	endif else begin
	    widget_control, self.template_name_id, set_value= ((*self.templates)[wm]).name
	endelse

    self->update_available_primitives, self.reductiontype

    self->change_current_template, self.reductiontype, 0, notemplate=notemplate

  
end

; OBSOLETE - merged into 'REMOVE' menu action item.
;    ;+ -----------------------------------------
;    ; gpi_recipe_editor::removefile
;    ;    Remove a file from the input files list. 
;    ;
;    ; Keywords:
;    ;   /norefresh		useful if you might be removing multiple files at once, to
;    ;					save multiple repeats of this.
;    ;
;    ;-
;    pro gpi_recipe_editor::removefile, file, norefresh=norefresh
;    
;    
;    	self.drf->remove_datafile, file
;    
;    	if ~keyword_set(norefresh) then begin
;    		self->refresh_filenames_display ; update the filenames display
;    		self->update_available_primitives, self.reductiontype ; why do we do this after removing a file?
;    	endif
;    
;    end
    
;+-----------------------------------------
; gpi_recipe_editor::queue
;    Add a file to the queue
;-
pro gpi_recipe_editor::queue, filename; , storage=storage

    if ~file_test(filename) then begin
    	widget_control,self.top_base,get_uvalue=storage  
        message, /info, "File "+filename+" does not exist!"
      	self->log,"File "+filename+" does not exist!"
      	self->log,"Use Save Recipe button"
      	return
    endif 

	self.drf->queue, filename=filename, queued_filename=outputfn

    self->log,'Queued '+outputfn

end


;+-----------------------------------------
; gpi_recipe_editor::event
;    actual event handler
;
;    Very complicated, does the bulk of the work for the GUI.
;    Long and complex function.
;-
pro gpi_recipe_editor::event,ev

	OK = 0
	NOT_OK = -1
	
    ;get type of event
    widget_control,ev.id,get_uvalue=uval

    ;get storage
    widget_control,ev.top,get_uvalue=storage

    if size(uval,/TNAME) eq 'STRUCT' then begin
        ; TLB event, either resize or kill_request
        ;print, 'Recipe Editor TLB event'
        case tag_names(ev, /structure_name) of

        'WIDGET_KILL_REQUEST': begin ; kill request
            if confirm(group=ev.top,message='Are you sure you want to close the Recipe Editor?',$
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
              'available_primitives': textinfo='Left-click for Primitve Desciption | Right-click to add the selected primitive to the current Recipe.'
              'RecipePrimitivesTable_id':textinfo='Left-click to see argument parameters of the module | Right-click to remove the selected module from the current Recipe.'
              'arguments_table':textinfo='Left-click on Value cell to change the value. Press Enter to validate.'
              'mod_desc':textinfo='Click on a module in the Available Primitives list to display its description here.'
              'text_status':textinfo='Status log message display window.'
              'ADDFILE': textinfo='Click to add files to current input list'
              'WILDCARD': textinfo='Click to add files to input list using a wildcard ("*.fits" etc)'
              'REMOVE': textinfo='Click to remove currently highlighted file from the input list'
              'REMOVEALL': textinfo='Click to remove all files from the input list'
              'Remove primitive': textinfo='Remove the selected module from the execution list'
              'Add primitive': textinfo='Add the selected module from "Available Primitives" into the execution list'
              'Choose Calibration File...': textinfo='Toggle Auto/Manual calibration file selection, and select specific file if Manual.'
              "Save Recipe as...": textinfo='Save Recipe to a filename of your choosing'
              "Drop": textinfo="Queue & execute the last saved Recipe"
              'Save&Drop': textinfo="Save the file, then queue it"
              'Close Recipe Editor': textinfo="Close and exit this program"
              "Move primitive up": textinfo='Move the currently-selected module one position earlier in the execution list'
              "Move primitive down": textinfo='Move the currently-selected module one position later in the execution list'
              else:
              endcase
              widget_control,self.textinfo_id,set_value=textinfo
        endif else begin 
              widget_control,self.textinfo_id,set_value=''
        endelse 
        return
    endif 
	
	; Double clicks in the list widget should launch a gpitv for that file.
	if (tag_names(ev, /structure_name) EQ 'WIDGET_LIST') then begin
		if ev.clicks eq 2 then begin
			filename = (self.drf->get_datafiles(/absolute))[ev.index]
			gpitv, ses=self.session,  filename
			message, 'Opening in GPITV #'+strc(self.session)+" : "+filename,/info
		endif
	endif
  

	if uval eq 'top_menu' then uval=ev.value ; respond to menu selections from event, not uval

    ; Menu and button events: 
    case uval of 
	'reduction_type_dropdown':begin
        selectype=widget_info(self.reduction_type_id,/DROPLIST_SELECT)
        self->changetype, selectype
    end
   
	'template_name_dropdown':begin
        selecseq=widget_info(self.template_name_id,/DROPLIST_SELECT)
        self->change_current_template, self.reductiontype, selecseq
	end

    'available_primitives':begin
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CELL_SEL') THEN BEGIN  ;LEFT CLICK
            ; Update displayed module comment
               selection = WIDGET_INFO(self.tableAvailable_id, /TABLE_SELECT) 
               ; get all descriptions for modules currently displayed:
               currdescs = ((*self.PrimitiveInfo).comment)[(*self.indmodtot2avail)[(*self.curr_mod_indsort)]]
               ; and get the one description corresponding to the selected
               ; module:
               indselected=selection[1] < (n_elements(currdescs)-1)
               comment=currdescs[indselected]
               if comment eq '' then comment=(*self.curr_mod_avai)[indselected]
               comment = $
                  '('+((*self.PrimitiveInfo).idlfuncs)[(*self.indmodtot2avail)[(*self.curr_mod_indsort)[indselected]]]+$
                  '.pro) '+comment

               widget_control,   self.descr_id,  set_value=comment
        ENDIF 
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_CONTEXT') THEN BEGIN  ;RIGHT CLICK
           self->AddPrimitive
     	ENDIF 

    end
    'RecipePrimitivesTable_id':begin     ; Table of currently selected modules (i.e. those in the recipe) 
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CELL_SEL') THEN BEGIN  ;LEFT CLICK
				selection = WIDGET_INFO((self.RecipePrimitivesTable_id), /TABLE_SELECT) 

				if gpi_get_setting('enable_editor_debug', default=0,/bool,/silent) then $
					print, "prim. table selection: ", selection

				;update arguments table
				indselected=selection[1]

				self->refresh_arguments_table, indselected
        ENDIF ; end of left click
    	IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_CONTEXT') THEN BEGIN  ;RIGHT CLICK
           self->RemovePrimitive
     	ENDIF  
    end      
    'arguments_table': begin
      IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CH') THEN BEGIN 
        selected_cell = WIDGET_INFO(self.tableArgs_id, /TABLE_SELECT)

		priminfo = self.drf->get_primitive_args(self.selected_primitive_index)
		n_args = n_elements(priminfo.names)
	
		priminfo = self.drf->get_primitive_args(self.selected_primitive_index)
		n_args=N_ELEMENTS(priminfo.names)
		if selected_cell[0] ne 1 then return ; user has tried to edit something other than the Value field
		if selected_cell[1] gt n_args -1 then return ; user has tried to select an empty cell
			WIDGET_CONTROL, self.tableArgs_id, GET_VALUE=selection_value,USE_TABLE_SELECT= selected_cell

		; figure out what type, range, etc is allowed for this primitive argument
		argname=  priminfo.names[selected_cell[1]]
		required_type=  priminfo.types[selected_cell[1]]
		range= priminfo.ranges[selected_cell[1]]

		; figure out what type of value the user has tried to enter
		;leave the possib. to enter a blank string:
		if (selection_value[0] eq '') then begin
			typeName='STRING'
		endif else begin
			isnum=str2num(selection_value[0],type=typenum)
			case typenum of
			  1:typeName ='INT'
			  2:typeName ='INT'
			  3:typeName ='INT'
			  4:typeName ='FLOAT'
			  5:typeName ='FLOAT'
			  7:typeName ='STRING'
			  12:typeName ='INT'
				else:typeName ='INVALID'
			endcase    
		endelse

		;compare required type and user's new value type 
		type_ok = 1 & range_ok = 1
		; Check to ensure the argument has the proper type. 
		  ; Special case: it is acceptable to enter an INT type into an
		  ; argument expecting a FLOAT, because of course the set of
		  ; integers is a subset of the set of floats. 
		  ; And of course we also allow numeric types as a subset of STRING
		if (strcmp(typeName,required_type,/fold))  $
		  or (strlowcase(required_type) eq 'float' and strlowcase(typename) eq 'int')  $
		  or (strlowcase(required_type) eq 'enum' and strlowcase(typename) eq 'string')  $
			or (strlowcase(required_type) eq 'string' and strlowcase(typename) eq 'float')  $
			or (strlowcase(required_type) eq 'string' and strlowcase(typename) eq 'int')  $
		  then $
		  type_ok=1 $
		else type_ok=0

		if ~type_ok then begin
			errormessage = ["Sorry, you tried to enter a value for "+argname+", but it had the wrong type ("+strupcase(typename)+").", "Please enter a value of type "+strupcase(required_type)+". The value was NOT updated; please try again.", "NOTE: If you are trying to edit the CalibrationFile keyword,", "please use the 'Choose Calibration File...' button in the lower right corner."]
			self->log,errormessage[0]+"  "+errormessage[1] ; merge 2 lines into 1
			res = dialog_message(errormessage,/error, title='Unable to set value')
			self->refresh_arguments_table
			return
		endif
	

		;;verify user-value: range 
		if (strcmp('string',required_type,/fold) ne 1) && (strcmp('string',typeName,/fold) ne 1) && (required_type ne '') then begin
			; if not a string, check min and max
			ranges=strsplit(range,'[,]',/extract)
			if (float(ranges[0]) le float(selection_value[0])) && (float(ranges[1]) ge float(selection_value[0])) then range_ok=1 else range_ok=0
		endif
		if ((strcmp('enum',required_type,/fold) eq 1) && (strcmp('string',typeName,/fold) eq 1)) || $
		   ((strcmp('string', required_type,/fold) eq 1) && (range ne "")) then begin
			; if an ENUM, or a STRING with a non-null range, then check value
			ranges=strsplit(range,'[,|]',/extract)
			matches = strmatch(ranges,selection_value[0],/fold)
			wm = where(matches, mct)
			if mct gt 0 then range_ok=1 else range_ok=0
		endif

		;print, required_type
		;print, "range:|"+range+"|"

		if ~range_ok then begin
			errormessage = ["Sorry, you tried to enter a value for "+argname+", "+selection_value[0]+", but it wasn't within the allowable range.", "Please enter a value within "+range+ ".  The value was NOT updated; please try again."]
			self->log,errormessage[0]+"  "+errormessage[1] ; merge 2 lines into 1
			res = dialog_message(errormessage,/error, title='Unable to set value')
			self->refresh_arguments_table
			return
		endif
	
		; if we get here, the type and range are OK, so set the value
		  
		new_arg_info = create_struct(argname,selection_value[0])
		self.drf->set_primitive_args, self.selected_primitive_index, _extra=new_arg_info
		self->refresh_arguments_table
		if argname eq 'CalibrationFile' then self->refresh_primitives_table
	ENDIF
  end
  'ADDFILE' : begin
     	
		if keyword_set(gpi_get_setting('at_gemini', /bool, default=0,/silent)) eq 1 then $
			result=dialog_pickfile(path=self.last_used_input_dir,/multiple,/must_exist,$
								   title='Select Raw Data File(s)', $
								  	filter=['S20'+gpi_datestr(/current)+'*.fits;'+'S20'+gpi_datestr(/current)+'*.fits.gz',$
											'S20'+gpi_datestr(/current)+'*.fits'],get_path=getpath) $
		else result=dialog_pickfile(path=self.last_used_input_dir,/multiple,/must_exist,$
								   title='Select Raw Data File(s)', filter=filter,get_path=getpath)
				
		if n_elements(result) eq 1 then if strc(result) eq '' then return ; user cancelled in the dialog box. 

		self.drf->add_datafiles, result
		self->refresh_filenames_display ; update the filenames display
		self.last_used_input_dir = file_dirname(result[0]) ; for use next time we open files


		self->log,strtrim(n_elements(result),2)+' files added.'
		widget_control, self.outputdir_id, set_value=self.drf->get_outputdir()

  end

  'WILDCARD' : begin
		datestr= gpi_datestr(/current)

		command=textbox(title='Input a Wildcard-listing Command (*,?,[..-..])',$
			group_leader=ev.top,label='',cancel=cancelled,xsize=500,$
			value=self.last_used_input_dir+path_sep()+'*'+datestr+'*')
        if cancelled then return

        self->log,' Performing wildcard match using regular expression: '+command
		
        result=file_search(command, count=count)

		if count eq 0 then begin
			self->log,' No files matched.'
			return
		endif else self->log,strc(count)+' files added.'

		self.drf->add_datafiles, result
		self->refresh_filenames_display ; update the filenames display
		widget_control, self.outputdir_id, set_value=self.drf->get_outputdir()

    end
    'REMOVE' : begin
		widget_control,self.top_base,get_uvalue=storage  
		selected_index = widget_info(storage.fname,/list_select) ; 
		n_selected_index = n_elements(selected_index)
		if (n_selected_index eq 1 ) then if (selected_index eq -1) then begin
			ret=dialog_message("ERROR: You have to click to select one or more files before you can remove anything.",/error,/center,dialog_parent=self.top_base)
			self->Log, 'You have to click to select a file before you can remove anything.'
			return ; nothing is selected so do nothing
		endif

		filelist = self.drf->get_datafiles() ; Note: must save this prior to starting the for loop since that will
											; confuse the list indices, and make us have to bookkeep things as the
											; list changes during a deletion of multiple files. 
		;if n_selected_index gt n_elements(filelist)-1 then n_selected_index = n_elements(filelist)-1
		for i=0,n_selected_index-1 do begin
			; sanity check indices:
			if selected_index[i] lt 0 or selected_index[i] gt n_elements(filelist)-1 then continue
			;self->removefile, filelist[selected_index[i]]
		    self.drf->remove_datafile, filelist[selected_index[i]]
			self->Log, "Removed "+filelist[selected_index[i]]

		endfor

		self->refresh_filenames_display ; update the filenames display
		;self->update_available_primitives, self.reductiontype ; why do we do this after removing a file?
		; I don't remember why we do the following here after removing files? -MP
		; I suppose because the default behavior is organize by date and that
		; depends on the files present.
		widget_control, self.outputdir_id, set_value=self.drf->get_outputdir()
    end
    'REMOVEALL' : begin
        if confirm(group=ev.top,message='Remove all filenames from the list?',$
            label0='Cancel',label1='Proceed') then begin

			self.drf->clear_datafiles
			self->refresh_filenames_display ; update the filenames display
			self->log,'All filenames removed.'
        endif
    end
    
    'outputdir': begin
       widget_control, self.outputdir_id, get_value=tmp
       if gpi_check_dir_exists(tmp) eq OK then begin
          self.drf->set_outputdir, tmp
          self->log,'Output Directory changed to:'+self.drf->get_outputdir()
          self.drf->set_outputoverride
          widget_control, self.outputdir_id, set_value=self.drf->get_outputdir()
       endif 
       
       if strcmp(tmp,'AUTO',4,/fold_case) then begin
          self.drf->clear_outputoverride
          self.drf->update_outputdir
          widget_control, self.outputdir_id, set_value=self.drf->get_outputdir()
       endif 
    end
   
    'outputdir_browse': begin
       result = DIALOG_PICKFILE(TITLE='Select an Output Directory', /DIRECTORY,/MUST_EXIST, path=gpi_expand_path(self.drf->get_outputdir()))
       if result ne '' then begin
          self.drf->set_outputdir, result
          self.drf->set_outputoverride
          widget_control, self.outputdir_id, set_value=self.drf->get_outputdir()
          self->log,'Output Directory changed to:'+self.drf->get_outputdir()
       endif
    end
    'Save Recipe': begin
        self->save, /nopickfile
    end
    'Save Recipe as...': begin
        self->save  
    end
    'Create Recipe Template and Save as...'    : begin
        self->save, /template
    end
    'Queue'  : begin
        if self.drffilename ne '' then begin
              self->queue, self.drfpath+path_sep()+self.drffilename
        endif else begin
              self->log,'Sorry, save Recipe before queueing or use "Save & Queue" button.'
        endelse
    end
    'Save&Queue'  : begin
        ;file = (*storage.splitptr).filename
        self->save, /nopickfile
        self->queue, self.drfpath+path_sep()+self.drffilename
     end
    'New Recipe':begin
       selecseq=widget_info(self.template_name_id,/DROPLIST_SELECT)
       self->change_current_template, self.reductiontype, selecseq, /cleardata
	   self.customdrffilename = 0
    end
    'Open Recipe...':begin
        newDRF =  DIALOG_PICKFILE(TITLE='Select a Recipe File', filter='*.xml',/MUST_EXIST,path=self.drfpath)
        if newDRF ne '' then self->open, newDRF
    end
    'Open Recipe as Template...':begin
        newDRF =  DIALOG_PICKFILE(TITLE='Select a Recipe File', filter='*.xml',/MUST_EXIST,path=self.drfpath)
        if newDRF ne '' then self->open, newDRF,  /template
    end

    'Close Recipe Editor'    : begin
        if confirm(group=ev.top,message='Are you sure you want to close the Recipe Editor?',$
            label0='Cancel',label1='Close') then obj_destroy, self
    end
	'Add primitive': self->AddPrimitive
	'Remove primitive': self->RemovePrimitive
	'Choose Calibration File': self->ChooseCalibrationFile
    'Reload Available Primitives':	self->reload_primitives_list
    'Reload Templates':	self->scan_templates
	'Basic View':			self->set_view_mode, 1
	'Normal View':			self->set_view_mode, 2
	'Advanced View':		self->set_view_mode, 3 
    'Move primitive up': begin
          selection = WIDGET_INFO((self.RecipePrimitivesTable_id), /TABLE_SELECT) 
          ind_selected=selection[1]
          if ind_selected ne 0 then begin ; can't move up
              new_indices = indgen(self.num_primitives)
              new_indices[ind_selected-1:ind_selected] = reverse(new_indices[ind_selected-1:ind_selected])
			  self.drf->reorder_primitives, new_indices
              self->refresh_primitives_table, new_selected=ind_selected-1
          endif
    end
    'Move primitive down': begin
          selection = WIDGET_INFO((self.RecipePrimitivesTable_id), /TABLE_SELECT) 
          ind_selected=selection[1]
          if ind_selected ne self.num_primitives-1 then begin ; can't move up
              new_indices = indgen(self.num_primitives)
              new_indices[ind_selected:ind_selected+1] = reverse(new_indices[ind_selected:ind_selected+1])
			  self.drf->reorder_primitives, new_indices
              self->refresh_primitives_table, new_selected=ind_selected+1
          endif
    end
	'Show default Primitives': begin
		self.showhidden = 0
    	self->update_available_primitives, self.reductiontype
	end

	'Show default + hidden Primitives': begin
		self.showhidden = 1
    	self->update_available_primitives, self.reductiontype
	end
 	'Show all Primitives': begin
    	self->update_available_primitives, self.reductiontype, /all
        end
       'Dump DRF to Main': begin
          (scope_varfetch('drf',  level=1, /enter)) = self.drf
       end 
 
    'About': begin
		tmpstr=gpi_drp_about_message()
		ret=dialog_message(tmpstr,/information,/center,dialog_parent=ev.top)
    end
	'FNAME': begin
		; user has clicked on filename display text widget
		; this should launch a gpitv, which is handled elsewhere so nothing
		; needs to happen here
	end
	'Recipe Editor Help...':  gpi_open_help,'usage/recipe_editor.html'
	'Recipe Templates Help...': gpi_open_help, 'usage/templates.html'
	'GPI DRP Help...': gpi_open_help, ''
    
    else: begin
		print, 'Unknown event: '+uval
		if gpi_get_setting('enable_editor_debug', default=0,/bool,/silent) then stop
	endelse
endcase

end
;+--------------------------------------
; gpi_recipe_editor::removePrimitive
;     Remove a primitive from the current recipe
;-
PRO gpi_recipe_editor::removePrimitive

	selection = WIDGET_INFO((self.RecipePrimitivesTable_id), /TABLE_SELECT) 
	indselected=selection[1]

	if (indselected ge 0) AND  (indselected lt self.num_primitives) AND (self.num_primitives gt 1) then begin
		self.drf->remove_primitive, indselected
	endif     
	self->refresh_primitives_table

	; if we've just removed the last primitive, move the selection up one...
	new_prims = self.drf->list_primitives()
	if indselected gt n_elements(new_prims)-1 then begin
		indselected = n_elements(new_prims)-1
		tableview = widget_info(self.RecipePrimitivesTable_id,/table_view) ; coordinates of top left view corner, because setting selection trashes this
		widget_control,   self.RecipePrimitivesTable_id,  SET_TABLE_SELECT = [0,indselected,0,indselected]
		widget_control,   self.RecipePrimitivesTable_id,   set_table_view=tableview ; restore coordinates of top left view corner
	endif

	self->refresh_arguments_table, indselected

end



;+--------------------------------------
; gpi_recipe_editor::addPrimitive
;     Add a primitive to the current recipe
;-

PRO gpi_recipe_editor::addPrimitive
	; Add new module to the list.
	selection = WIDGET_INFO((self.tableAvailable_id), /TABLE_SELECT) 


	indselected=selection[1]
	if indselected eq -1 then return ; nothing selected

	self->Log, "Inserting primitive '"+(*self.curr_mod_avai)[indselected]+"'" ; into position "+strc(insertorder)

	self.drf->add_primitive, (*self.curr_mod_avai)[indselected], index=index, status=status
	if status eq -1 then begin
		self->Log, 'Failure to insert primitive'
		return
	endif

  ;;if table is too small, double it in size
  tmp = widget_info(self.RecipePrimitivesTable_id,/row_heights)
  if index ge n_elements(tmp) then begin
     widget_control,  self.RecipePrimitivesTable_id, ysize = index*2, background_color=rebin(*self.table_BACKground_colors,3,2*3,/sample) 
  endif

	tableview = widget_info(self.RecipePrimitivesTable_id,/table_view) ; coordinates of top left view corner, because setting selection trashes this
	self->refresh_primitives_table
	widget_control,   self.RecipePrimitivesTable_id,  SET_TABLE_SELECT = [0,index,0,index]
	widget_control,   self.RecipePrimitivesTable_id,   set_table_view=tableview ; restore coordinates of top left view corner

	self->refresh_arguments_table, index
 
end


;+--------------------------------------
; gpi_recipe_editor::chooseCalibrationFile
;	Select a calibration file for the current primitive, if appropriate. 
;-

PRO gpi_recipe_editor::chooseCalibrationFile

	primitive_index=self.selected_primitive_index 
	arg_info = self.drf->get_primitive_args(primitive_index)
	wcalfile = where(strupcase(arg_info.names) eq "CALIBRATIONFILE", mct)
	if mct ne 1 then return ; something has gone wrong

	current_value = arg_info.values[wcalfile]

	if current_value eq 'AUTOMATIC' then begin
		; toggle from automatic to manual
		; what type of cal file do we want? 
		desired_cal_type = arg_info.calfiletypes[wcalfile]
		if desired_cal_type ne '' then filespec = '*'+desired_cal_type+'*.fits' else filespec = '*.fits'
        resolvedcalibfile = DIALOG_PICKFILE(TITLE='Select Calibration File for that primitive: ' , PATH=gpi_get_directory('GPI_CALIBRATIONS_DIR') ,/MUST_EXIST,FILTER = filespec)
		if resolvedcalibfile ne '' then begin ; if user cancels we get a null string back, in which case do nothing.
			newcalfile = resolvedcalibfile
			message,/info, 'Toggled from automatic to manual calibration file. Press again to return to automatic mode.'
		endif else begin
			message,/info, 'User cancelled selecting new calibration file'
			return
		endelse 
	endif else begin
		; toggle from manual to automatic
		newcalfile = 'AUTOMATIC'
		message,/info, 'Toggled from manual to automatic calibration file. Press again to return to manual mode.'
	endelse
	self.drf->set_primitive_args, self.selected_primitive_index, CalibrationFile=newcalfile


	self->refresh_primitives_table
	self->refresh_arguments_table, index
 
end


;+--------------------------------------
; gpi_recipe_editor::check_output_path_exists
;    does what the name suggests.
;-
function gpi_recipe_editor::check_output_path_exists, path
	if file_test(path,/dir,/write) then begin
		return, 1 
	endif else  begin

		if gpi_get_setting('prompt_user_for_outputdir_creation',/bool,default=0,/silent) then $
			res =  dialog_message('The requested output directory '+path+' does not exist. Should it be created now?', $
			title="Nonexistent Output Directory", dialog_parent=self.top_base, /question) else res='Yes' 
		if res eq 'Yes' then begin
			file_mkdir, path
			return, 1
		endif else return, 0

	endelse
	return, 0


end


;+--------------------------------------
; gpi_recipe_editor::save
;    Save a Recipe  to an XML file on disk.
;
;    ARGUMENTS:
;     file          string array of FITS filenames in the DRF
; 	  storage       (unused, kept for back compatibility)
; 	  /template     save this DRF as a template
; 	  /nopickfile   Automatically use the current input filename as the output file name
;
;-
pro gpi_recipe_editor::save, template=template, nopickfile=nopickfile
  
  OK = 0
  NOT_OK = -1
  
  selectype=widget_info(self.reduction_type_id,/DROPLIST_SELECT)
  
  if keyword_set(template) then begin
     templatesflag=1 
     drfpath=gpi_get_directory('GPI_DRP_TEMPLATES_DIR')
  endif else begin
     templatesflag=0
     drfpath=self.drfpath
  endelse  
  

  ;; Generate a default output filename
  files= self.drf->get_datafiles()
  wg = where(files ne '', goodct)
  if goodct eq 0 and ~(keyword_set(template))then begin
     res = dialog_message('You have no data files loaded. Either load some files, or else you can only save this recipe as a template',/error, title='No FITS files selected')
     return
  endif
  
  if ~self.customdrffilename then begin
     if templatesflag then begin
        outputfilename = self.loadedRecipeFile ;to check
     endif else begin     
        ;caldat,systime(/julian),month,day,year, hour,minute,second
        ;datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
        ;hourstr = string(hour,minute,second,format='(i2.2,i2.2,i2.2)') 
        
        ;;get rid of any leading paths on the first and last files
        first_file = file_basename(gpi_expand_path(files[0]))
        last_file = file_basename(gpi_expand_path(files[size(files,/n_elements)-1]))
        
        first_file=strsplit(first_file,'.',/extract)
        last_file=strsplit(last_file,'.',/extract)
        
        drf_summary = self.drf->get_summary()
        
        if first_file[0] eq last_file[0] then outputfilename = first_file[0]+'_'+drf_summary.shortname+'_recipe.waiting.xml' else $
           outputfilename = first_file[0]+'-'+last_file[0]+'_'+drf_summary.shortname+'_recipe.waiting.xml'
     endelse
  endif else outputfilename = self.drffilename

  ;;get drf filename and set drfpath:
  if ~keyword_set(nopickfile) then begin
     output_recipe_filename = DIALOG_PICKFILE(TITLE='Save Data Reduction Recipe File as', /write,/overwrite, filter='*.xml',file=outputfilename,path=drfpath, get_path=newdrfpath)
     if output_recipe_filename eq "" then begin
        self->Log, "User cancelled save; doing nothing."
        return                  ; user cancelled the save as dialog, so don't save anything.
     endif
     if file_basename(output_recipe_filename) ne outputfilename then self.customdrffilename = 1
     if ~templatesflag then self.drfpath  = newdrfpath ; MDP change - update the default directory to now match whatever the user selected in the dialog box. but only if not 
  endif else output_recipe_filename = outputfilename

  if gpi_check_dir_exists(self.drfpath) eq NOT_OK then return 
  
  prims = self.drf->list_primitives( count=num_primitives)
  
  if (num_primitives eq 0) then begin
     res=dialog_message ("ERROR: no primitives selected. Can't save until you fix that.")
     self->log, "ERROR: no primitives selected. Can't save until you fix that."
     return 
  endif
  if (output_recipe_filename eq '') then begin
     res=dialog_message ("ERROR: no output filename provided. Can't save until you fix that.")
     self->log, "ERROR: no output filename provided. Can't save until you fix that."
     return 
  endif 
  
  self.drffilename = file_basename(output_recipe_filename)
  self->log,'Now writing Recipe to '+self.drfpath+path_sep()+self.drffilename 
  self.drf->save, self.drfpath+path_sep()+self.drffilename, outputfilename=outputfilename, template=template, $
	  comment="created with the Recipe Editor GUI"
  
  self->update_title_bar, outputfilename
  
end


;+-------------------------------------
; gpi_recipe_editor::open
;     Open a recipe file (DRF). 
;
;     If /nodata is set, then just load the primitives list. 
;     Otherwise, load modules list AND input fits files. 
;-
pro gpi_recipe_editor::open, filename, template=template, silent=silent, log=log

    if ~(keyword_set(filename)) then return

    filename = gpi_expand_path(filename)
    if ~file_test(filename) then begin
       self->Log, "Requested Recipe file does not exist: "+filename
       return
    endif

    self.loadedRecipeFile = filename

    widget_control,self.top_base,get_uvalue=storage  
    
    ; now parse the requested DRF.
    self->log, "Opening: "+gpi_shorten_path(self.loadedRecipeFile)
    self.drf = obj_new('drf', self.loadedRecipeFile, parent_object=self, /silent, /quick, as_template=keyword_set(nodata))
    drf_summary = self.drf->get_summary()
    drf_contents = self.drf->get_contents()
    drf_module_names = self.drf->list_primitives() 

    ;; if requested, load the filenames in that DRF
    ;; (for Template use, don't load the data)
    if keyword_set(template) then  begin
       self.drf->clear_datafiles
       self->update_title_bar, 'Template from '+file_basename(filename) ; don't update title bar if this is a template
    endif else begin
       datafiles = self.drf->get_datafiles(/absolute)
       self.last_used_input_dir = file_dirname(datafiles[0])
       self->update_title_bar, filename ; don't update title bar if this is a template
    endelse
	
    ;;if necessary, update reduction type to match whatever is in that DRF (and update available modules list too)
    if self.reductiontype ne drf_summary.reductiontype then begin
       selectype=where(strmatch(*self.template_types, strc(drf_summary.reductiontype),/fold_case), matchct)
       if matchct ne 1 then message,"ERROR: no match for "+self.reductiontype
       if self.reduction_type_id ne 0 then  widget_control, self.reduction_type_id, SET_DROPLIST_SELECT=selectype
       self->changetype, selectype[0], /notemplate
    endif
    
    if ~(keyword_set(template)) then begin
       self->refresh_filenames_display ; update the filenames display
       self.drffilename = file_basename(self.loadedRecipeFile)
       self.drfpath = file_dirname(self.loadedRecipeFile,/mark_directory)
       self.customdrffilename = 1      ; use this filename
    end
    self->refresh_primitives_table 
    self->refresh_arguments_table
    
    widget_control,   self.outputdir_id, set_value=self.drf->get_outputdir()
    widget_control,   self.RecipePrimitivesTable_id,   SET_TABLE_VIEW=[0,0] ; set cursor to upper left corner
    
    self->log,'Recipe:'+self.loadedRecipeFile+' has been succesfully loaded.'

end
;+------------------------------------------------
;  gpi_recipe_editor::update_title_bar
pro gpi_recipe_editor::update_title_bar, filename
  if ~(keyword_set(filename)) then filename=self.loadedrecipefile
  
  ;;update title bar of window:
  title  = "Recipe Editor"

  ; Hide this - it's not useful to have a session # in the title of the
  ; recipe editor window since there's not really anything one can do with that
  ; information.
  ;if keyword_set(self.session) then title += " #"+strc(self.session)

  widget_control, self.top_base, tlb_set_title=title+": "+filename
end

;+------------------------------------------------
; gpi_recipe_editor::cleanup
;   Free pointers, garbage collect, destroy widgets, 
;   and get ready to exit.
;
;-
pro gpi_recipe_editor::cleanup
	
	ptr_free, self.table_background_colors, self.PrimitiveInfo, self.curr_mod_avai
	ptr_free, self.curr_mod_indsort, self.currModSelec
	ptr_free, self.indmodtot2avail, self.templates, self.template_types

	if (xregistered (self.xname) gt 0) then    widget_control,self.top_base,/destroy
	
	heap_gc
end

;+------------------------------------------------
; gpi_recipe_editor::init_data
;    Initialize data structures
;-
pro gpi_recipe_editor::init_data, _extra=_Extra

	compile_opt idl2
	;--- init object member variables
	self->load_configparser

	self.curr_mod_avai=     ptr_new(/ALLOCATE_HEAP)         ; list of available module names (strings) in current mode
	self.curr_mod_indsort=  ptr_new(/ALLOCATE_HEAP)
	self.currModSelec=      ptr_new(/ALLOCATE_HEAP)
	;self.order=             ptr_new(/ALLOCATE_HEAP)
	;self.indarg=            ptr_new(/ALLOCATE_HEAP)                ; ???
	;self.currModSelecParamTab=  ptr_new(/ALLOCATE_HEAP)
	self.indmodtot2avail=   ptr_new(/ALLOCATE_HEAP)



	;self.templatedir = 	gpi_get_directory('GPI_DRP_TEMPLATES_DIR')
	;self.outputdir = 	gpi_get_directory('GPI_REDUCED_DATA_DIR')
	;self.logdir = 		gpi_get_directory('GPI_DRP_LOG_DIR')
	;self.queuedir =		gpi_get_directory('GPI_DRP_QUEUE_DIR')
	;self.inputcaldir =	gpi_get_directory('GPI_calibrations_dir')
	;self.dirpro = 		gpi_get_directory('GPI_DRP_DIR') ;+path_sep();+'gpigpi_recipe_editor'+path_sep();dirlist[0]

	; how do we organize DRFs? 
	if gpi_get_setting('organize_recipes_by_dates',/bool) then begin
		self.drfpath = gpi_get_directory('RECIPE_OUTPUT_DIR') + path_sep() + gpi_datestr(/current)
		self->Log,"Outputting recipes based on date to "+self.drfpath
	endif else begin
		self.drfpath = gpi_get_directory('RECIPE_OUTPUT_DIR') 
		self->Log, "Outputting recipes to current working directory: "+self.drfpath
	endelse

	self->scan_templates
	self->update_available_primitives, self.reductiontypes[0] ; needed before widget creation

	self.loadedRecipeFile = 'none' 

end

;+------------------------------------------------
; gpi_recipe_editor::set_view_mode
;    set which widgets are currently displayed
;
;-

pro gpi_recipe_editor::set_view_mode, mode
	wids = *self.widgets_for_modes

	; basic mode widgets are always shown. 
	; normal mode widgets
	for i=0,n_elements(wids.normal)-1 do widget_control, (wids.normal)[i], map=mode gt 1
	; advanced mode widgets
	for i=0,n_elements(wids.advanced)-1 do widget_control, (wids.advanced)[i], map=mode gt 2

end

;+------------------------------------------------
; gpi_recipe_editor::init_widgets
;
;    create the widgets
;-
function gpi_recipe_editor::init_widgets, _extra=_Extra, session=session
    ;create base widget. 
    ;   Resize to be large on desktop monitors, or shrink to fit on laptops.
    ;-----------------------------------------
	DEBUG_SHOWFRAMES= gpi_get_setting('recipeeditor_enable_framedebug', default=0,/silent)
    
    screensize=get_screen_size()

    if screensize[1] lt 900 then begin
      nlines_status=5
      nlines_fname=12
	  if screensize[1] lt 800 then nlines_fname=8
      self.nlines_modules=5
      nlines_args=6
    endif else begin
      nlines_status=5
      nlines_fname=12
      self.nlines_modules=10
      nlines_args=6
    endelse

	self.xname='gpi_recipe_editor'
	title  = "GPI Recipe Editor"
	if keyword_set(session) then begin
           self.session=session
           title += " #"+strc(self.session)
    endif
    curr_sc = get_screen_size()
    title += ': Create Data Reduction Files'
    CASE !VERSION.OS_FAMILY OF  
           ;; **NOTE** Mac OS X reports an OS family of 'unix' not 'MacOS'
           'unix': begin 
              if curr_sc[0] gt 1300 then $
                 top_base=widget_base(title=title, group_leader=groupleader,/BASE_ALIGN_LEFT,/column,$
                                      MBAR=bar,/tlb_size_events, /tlb_kill_request_events, resource_name='GPI_DRP_RecipeEditor') $
              else top_base=widget_base(title=title, group_leader=groupleader,/BASE_ALIGN_LEFT,/column,$
                                        MBAR=bar,/tlb_size_events, /tlb_kill_request_events, resource_name='GPI_DRP_RecipeEditor',$
                                        /scroll,x_scroll_size=curr_sc[0]-50,y_scroll_size=curr_sc[1]-100)
           end
           'Windows'   :begin
              top_base=widget_base(title=title, $
                                   group_leader=groupleader,/BASE_ALIGN_LEFT,/column, MBAR=bar,bitmap=gpi_get_directory('GPI_DRP_DIR')+path_sep()+'gpi.bmp',$
                                   /tlb_size_events, /tlb_kill_request_events)
              
           end
        ENDCASE
   
	
	self.top_base=top_base
	;create Menu
	tmp_struct = {cw_pdmenu_s, flags:0, name:''}
	top_menu_desc = [ $
                  {cw_pdmenu_s, 1, 'File'}, $ ; file menu;
                  {cw_pdmenu_s, 0, 'New Recipe'}, $
                  {cw_pdmenu_s, 0, 'Open Recipe...'}, $
                  {cw_pdmenu_s, 0, 'Save Recipe'}, $
                  {cw_pdmenu_s, 0, 'Save Recipe as...'}, $
                  {cw_pdmenu_s, 4, 'Open Recipe as Template...'}, $
                  {cw_pdmenu_s, 0, 'Create Recipe Template and Save as...'}, $
                  {cw_pdmenu_s, 6, 'Close Recipe Editor'}, $
                  {cw_pdmenu_s, 1, 'Edit'}, $ 
                  {cw_pdmenu_s, 0, 'Add primitive'}, $
                  {cw_pdmenu_s, 0, 'Remove primitive'}, $
                  {cw_pdmenu_s, 4, 'Move primitive up'}, $
                  {cw_pdmenu_s, 0, 'Move primitive down'}, $
                  {cw_pdmenu_s, 6, 'Choose Calibration File...'}, $
                  {cw_pdmenu_s, 1, 'Options'}, $
                  {cw_pdmenu_s, 0, 'Reload Available Primitives'}, $
                  {cw_pdmenu_s, 0, 'Reload Templates'}, $
                  {cw_pdmenu_s, 12, 'Basic View'}, $
                  {cw_pdmenu_s, 8, 'Normal View'}, $
                  {cw_pdmenu_s, 8, 'Advanced View'}, $
                  {cw_pdmenu_s, 12, 'Show default Primitives'}, $
                  {cw_pdmenu_s, 8, 'Show default + hidden Primitives'}, $
                  {cw_pdmenu_s, 8, 'Show all Primitives'}, $
                  {cw_pdmenu_s, 10, 'Dump DRF to Main'}, $
                  {cw_pdmenu_s, 1, 'Help'}, $         ; help menu
                  {cw_pdmenu_s, 0, 'Recipe Editor Help...'}, $
                  {cw_pdmenu_s, 0, 'Recipe Templates Help...'}, $
                  {cw_pdmenu_s, 0, 'GPI DRP Help...'}, $
                  {cw_pdmenu_s, 4, 'About'} $
                ]

	top_menu = cw_pdmenu_checkable(bar, top_menu_desc, $
                     ids = menu_ids, $
                     /mbar, $
                     /help, $
                     /return_name, $
                     uvalue = 'top_menu')


	;create file selector
	;-----------------------------------------
	top_base_filebutt=widget_base(top_base,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES, /base_align_center)

	label = widget_label(top_base_filebutt, value="Input FITS Files:")
	button=widget_button(top_base_filebutt,value="Add File(s)",uvalue="ADDFILE", $
		xsize=90,ysize=30, /tracking_events);,xoffset=10,yoffset=115)
	button=widget_button(top_base_filebutt,value="Wildcard",uvalue="WILDCARD", $
		xsize=90,ysize=30, /tracking_events);,xoffset=110,yoffset=115)
	button=widget_button(top_base_filebutt,value="Remove",uvalue="REMOVE", $
		xsize=90,ysize=30, /tracking_events);,xoffset=210,yoffset=115)
	button=widget_button(top_base_filebutt,value="Remove All",uvalue="REMOVEALL", $
		xsize=90,ysize=30, /tracking_events);,xoffset=310,yoffset=115)

	top_base_filebutt_advanced=widget_base(top_base_filebutt, row=1,frame=DEBUG_SHOWFRAMES, /BASE_ALIGN_LEFT, /base_align_center)
	;sorttab=['obs. date/time','OBSID','alphabetic filename','file creation date']
	;self.sortfileid = WIDGET_DROPLIST( top_base_filebutt_advanced, title='Sort data by:',  Value=sorttab,uvalue='sortmethod',resource_name='XmDroplistButton')
	drfbrowse = widget_button(top_base_filebutt_advanced,  $
							XOFFSET=174 ,SCR_XSIZE=80, ysize= 30 $; ,SCR_YSIZE=23  $
							,/ALIGN_CENTER ,VALUE='Sort data',uvalue='sortdata')                          
		
	top_baseident=widget_base(top_base,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES)
	; file name list widget
	fname=widget_list(top_baseident,xsize=106,scr_xsize=680, ysize=nlines_fname,$
			xoffset=10,yoffset=150,uvalue="FNAME", /TRACKING_EVENTS,resource_name='XmText',/multiple)

	; add 5 pixel space between the filename list and controls
	top_baseident_spacer=widget_base(top_baseident,xsize=5,units=0, frame=DEBUG_SHOWFRAMES)

	; add the options controls
	top_baseidentseq=widget_base(top_baseident,/BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
	top_right_advanced_base = widget_base(top_baseidentseq, /BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
	top_baseborder1=widget_base(top_right_advanced_base, /BASE_ALIGN_LEFT,/row)
	drflabel=widget_label(top_baseborder1,Value='Output Dir=         ')
	self.outputdir_id = WIDGET_TEXT(top_baseborder1, $
				xsize=34,ysize=1,$
				/editable,units=0,value=self.outputdir, uvalue='outputdir' )    

	drfbrowse = widget_button(top_baseborder1,  $
						XOFFSET=174 ,SCR_XSIZE=75 ,SCR_YSIZE=23  $
						,/ALIGN_CENTER ,VALUE='Change...',uvalue='outputdir_browse')
	top_baseborder3=widget_base(top_right_advanced_base, /BASE_ALIGN_LEFT,/row)


	base_radio = Widget_Base(top_right_advanced_base, UNAME='WID_BASE_diskc', COLUMN=1 ,/NONEXCLUSIVE, frame=0)
						
	;self.resolvetypeseq_id = Widget_Button(base_radio, UNAME='RESOLVETYPESEQBUTTON' ,/ALIGN_LEFT ,VALUE='Resolve type/seq. when adding file(s)',UVALUE='autoresolvetypeseq')

	rowbase_template = widget_base(top_baseidentseq,row=1)
	self.reduction_type_id = WIDGET_DROPLIST( rowbase_template, title= 'Reduction category: ', frame=0, Value=*self.template_types,uvalue='reduction_type_dropdown',resource_name='XmDroplistButton')
	rowbase_template2 = widget_base(top_baseidentseq,row=1)
    self.template_name_id  = WIDGET_DROPLIST( rowbase_template2, title='Recipe Template:    ', frame=0, Value=['Simple Data-cube extraction','Calibrated Data-cube extraction','Calibrated Data-cube extraction, ADI reduction'],uvalue='template_name_dropdown',resource_name='XmDroplistButton')

	;one nice logo 
	button_image = READ_BMP(gpi_get_directory('GPI_DRP_DIR')+path_sep()+'gpi.bmp', /RGB) 
	button_image = TRANSPOSE(button_image, [1,2,0]) 
	button = WIDGET_BUTTON(top_baseident, VALUE=button_image,  $
			SCR_XSIZE=100 ,SCR_YSIZE=95, sensitive=1, uvalue='About') 
	 
	 
	;create merge selector
	;-----------------------------------------
	top_basemodule=widget_base(top_base,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES)
	top_basemoduleleft=widget_base(top_basemodule,/BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
	top_basemoduleavailable=widget_base(top_basemoduleleft,/BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
	data=transpose(*self.curr_mod_avai)


	; what colors to use for cell backgrounds? Alternate rows between
	; white and off-white pale blue
	self.table_BACKground_colors = ptr_new([[255,255,255],[240,240,255]])

 
	self.tableAvailable_id = WIDGET_TABLE(top_basemoduleavailable, VALUE=data,$;  $ ;/COLUMN_MAJOR, $ 
			COLUMN_LABELS=['Available Primitives'], /TRACKING_EVENTS,$
			xsize=1,ysize=50,scr_xsize=400,$  ;JM: ToDo: ysize as a function of #mod avail.
			/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =self.nlines_modules,COLUMN_WIDTHS=380,frame=1,uvalue='available_primitives',/ALL_EVENTS,/CONTEXT_EVENTS , $
			background_color=rebin(*self.table_BACKground_colors,3,2,1)) ;/COLUMN_MAJOR,
	
	lab = widget_label(top_basemoduleavailable, value="Primitive Description:")
	self.descr_id = WIDGET_TEXT(top_basemoduleavailable, $
		xsize=58,scr_xsize=400, ysize=3,/scroll, $; nlines_args,$
		value=(*self.curr_mod_avai)[0],units=0 ,/wrap, uval='mod_desc',/tracking_events)

	; Create the status log window 
	; widget ID gets stored into 'storage'
	lab = widget_label(top_basemoduleleft, value="History:")
	info=widget_text(top_basemoduleleft,/scroll, xsize=58,scr_xsize=400,ysize=nlines_status, /ALIGN_LEFT, uval="text_status",/tracking_events);xoffset=5,yoffset=5)


	top_basemoduleselected=widget_base(top_basemodule,/BASE_ALIGN_LEFT,/column)
	lab = widget_label(top_basemoduleselected, value="This recipe contains the following primitives:")
	self.RecipePrimitivesTable_id = WIDGET_TABLE(top_basemoduleselected, $; VALUE=data, $ ;/COLUMN_MAJOR, $ 
			COLUMN_LABELS=['Primitive Name','Calib. File Method','Resolved Filename'],/resizeable_columns, $
			xsize=3,ysize=20,uvalue='RecipePrimitivesTable_id',value=(*self.currModSelec), /TRACKING_EVENTS,$
			/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =self.nlines_modules,scr_xsize=800,COLUMN_WIDTHS=[240,140,420],frame=1,/ALL_EVENTS,/CONTEXT_EVENTS, $
			background_color=rebin(*self.table_BACKground_colors,3,2*3,/sample)    ) ;,/COLUMN_MAJOR   
	base_primitive_args = widget_base(top_basemoduleselected,/BASE_ALIGN_LEFT,/column)
	lab = widget_label(base_primitive_args, value="Change values of parameters of the selected primitive [press Enter after each change. Validate new values with ENTER]:")             
        self.tableArgs_id = WIDGET_TABLE(base_primitive_args, $ ; VALUE=data, $ ;/COLUMN_MAJOR, $ 
                                      COLUMN_LABELS=['Parameter', 'Value','Range','Description'], /resizeable_columns, $
                                      xsize=4,ysize=20, /TRACKING_EVENTS,$
                                      /NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =nlines_args,scr_xsize=800,/COLUMN_MAJOR,$
                                      COLUMN_WIDTHS=[120,120,120,440],frame=1,EDITABLE=[0,1,0,0],uvalue='arguments_table' , $
                                      background_color=rebin(*self.table_BACKground_colors,3,2*4,/sample)    ) ;,/COLUMN_MAJOR                
		

	;;create execute and quit button
	;-----------------------------------------
	top_baseexec=widget_base(top_base,/BASE_ALIGN_LEFT,row=1, frame=DEBUG_SHOWFRAMES)
	button2=widget_button(top_baseexec,value="Save Recipe as...",uvalue="Save Recipe as...", /tracking_events)
	button2b=widget_button(top_baseexec,value="Queue last saved Recipe",uvalue="Queue", /tracking_events)
	button2c=widget_button(top_baseexec,value="Save Recipe and Queue",uvalue="Save&Queue", /tracking_events)
	spacer = widget_label(top_baseexec, value=' ', xsize=150)

	button3=widget_button(top_baseexec,value="Add primitive",uvalue="Add primitive", /tracking_events)
	button3=widget_button(top_baseexec,value="Move primitive up",uvalue="Move primitive up", /tracking_events)
	button3=widget_button(top_baseexec,value="Move primitive down",uvalue="Move primitive down", /tracking_events)
	button3=widget_button(top_baseexec,value="Remove primitive",uvalue="Remove primitive", /tracking_events)
	spacer = widget_label(top_baseexec, value=' ', xsize=15)
	self.button_calfile_id=widget_button(top_baseexec,value="Choose Calibration File...",uvalue="Choose Calibration File", /tracking_events)
	       
        bot_baseexec=widget_base(top_base,/BASE_ALIGN_CENTER,row=1, frame=DEBUG_SHOWFRAMES)
	self.textinfo_id=widget_label(bot_baseexec,uvalue="textinfo",xsize=900,ysize=10,value='  ')
    spacer = widget_label(bot_baseexec, value=' ', xsize=126)
	button3=widget_button(bot_baseexec,value="Close Recipe Editor",uvalue="Close Recipe Editor", /tracking_events, resource_name='red_button')

	;filename array and index
	;-----------------------------------------
	maxfilen=gpi_get_setting('max_files_per_recipe',default=1000,/silent)
	filename=strarr(maxfilen)
	printname=strarr(maxfilen)
	datefile=lonarr(maxfilen)
	findex=0
	;selindex=0
	splitptr=ptr_new({filename:filename,printname:printname,$
	  findex:findex,datefile:datefile, maxfilen:maxfilen})

	;make and store data storage
	;-----------------------------------------
	; info        : widget ID for information text box
	; fname        : widget ID for filename text box
	; rb        : widget ID for merge selector
	; splitptr  ; structure (pointer)
	;   filename  : array for filename
	;   printname : array for printname
	;   findex    : current index to write filename
	;   selindex  : index for selected file
	; group,proj    : group and project name(given parameter)
	;-----------------------------------------
    group=''
    proj=''
    storage={info:info,fname:fname,$
    ;    rb:rb,$
        splitptr:splitptr,$
        group:group,proj:proj, $
        self: self}
	self.widget_log = info
    widget_control,top_base,set_uvalue=storage,/no_copy
    
;    self->log, "This GUI helps you to create a customized Recipe."
;    self->log, "Add files to be processed and create a recipe"
;    self->log, " with primitives to reduce data."

    self->changetype, 0 ; set to ASTR-SPEC type by default.

	self.widgets_for_modes = ptr_new( {normal: [base_primitive_args, top_basemoduleavailable], advanced: [top_base_filebutt_advanced, top_right_advanced_base]})


    return, top_base

end

;+------------------------------------------------
; gpi_recipe_editor::post_init
;    Set view mode and optionally load a recipe
;-
PRO gpi_recipe_editor::post_init, drfname=drfname, _extra=_extra
  
  if keyword_set(drfname) then begin
     self->open, drfname, /log
  end
  self->set_view_mode, 2
  
  if self.last_used_input_dir eq '' then self.last_used_input_dir = self->get_default_input_dir()
  
end

;+-----------------------
; gpi_recipe_editor__define
;   Create the actual structure object.
;
;-
pro gpi_recipe_editor__define
    struct = {gpi_recipe_editor,   $
              drf: obj_new(), $          ; DRF object holding the contents of the current recipe
              drfpath : '',$              ; default directory for saving DRFs
              drffilename :'',$          ; name of current recipe file
              customdrffilename : 0,$    ; if user has overwritten the filename
              loadedRecipeFile:'',$      ; file read from disk
              last_used_input_dir: '', $ ; save the most recently used directory. Start there again on subsequent file additions
              reductiontype:'',$         ; currently selected reduction type name string
              outputdir_id:0L,$					; widget ID of output dir selection field
              tableAvailable_id: 0L,$			; widget ID for available primitves table
              descr_id: 0L,$					; widget ID for primitive description
              textinfo_id: 0L,$					; widget ID for status bar for mouseover text
              RecipePrimitivesTable_id: 0L,$	; widget ID for primitives list table
              tableArgs_id: 0L,$				; widget ID for paramters/arguments table
              reduction_type_id: 0L,$			; widget ID for reduction type dropdown
              template_name_id: 0L,$			; widget ID for template name dropdown
              button_calfile_id: 0L,$			; widget ID for Choose Calibration File button
              widgets_for_modes: ptr_new(), $	; widget IDs for basic/normal/advanced modes. see set_view_mode.
			  selected_primitive_index: 0L, $	; index of current primitive whose arguments are shown in the args table
              showhidden: 0, $					; should primitives marked 'hidden' be displayed?
              reductiontypes: ['SpectralScience','PolarimetricScience','Calibration','Testing'], $
              table_background_colors: ptr_new(), $	; ptr to RGB triplets for table cell colors
              nlines_modules: 0, $                  ; how many lines to display modules on screen? (used in resize)
              PrimitiveInfo: ptr_new(), $			; Available primitives from pipeline_config.xml, as structure array
              curr_mod_avai: ptr_new(), $			; list of available primitive names (strings) in current mode
              curr_mod_indsort: ptr_new(), $		; indices to alphabetize current available primitives
              currModSelec: ptr_new(), $			; ??? Current selected primitives
              num_primitives:  0L,$					; Number of primitives in the current recipe
              ;currModSelecParamTab: ptr_new(), $	; 
              indmodtot2avail: ptr_new(), $
              templates: ptr_new(), $			; pointer to struct containing template info. See Scan_templates
              template_types: ptr_new(), $		; pointer to list of available template types
              INHERITS gpi_gui_base }

end
