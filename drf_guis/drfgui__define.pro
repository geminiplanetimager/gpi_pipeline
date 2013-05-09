;-----------------------------------------
; drfgui__define.pro 
;
; select file to process, define primitives & parameters to be executed and create DRF
;
;
;
; author : 2009-09-14 J.Maire created
;            2010-04 M. Perrin: Restructured into an object-oriented widget
;            program.
;
;
;--------------------------------------------------------------------------------
; NOTES
;   This is a rather complicated program, with lots of overlapping data
;   structures. Be careful and read closely when editing!
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
;    self.nbModuleSelec       number of modules in current DRF list
;    self.currModSelec        list of modules in current DRF list
;    self.order               list of PIPELINE ORDER values for those modules
;
;    self.curr_mod_indsort    indices into curr_mod_avai in alphabetical order?
;                            in other words, matching the displayed order in the
;                            Avail Table
;
;    self.indmodtot2avail    indices for
;
;
;

compile_opt DEFINT32, STRICTARR


;================================================================================
; Helper and utility functions
;
;--------------------------------------------------------------------------------
;  Resolve a Calibration File name
;function drfgui::resolvecalibfile, filter, extfile, timeobs, calibfieldind
;    ;get list of file in inputcaldir
;    ;TODO:compare with a pre-reduced list
;    ;stop
;    ;TODO:extract keyword if new calib file and put in the pre-reduced list (&check absent calib file)
;    if (timeobs eq 0)|| (self.filter eq '') then begin
;              file = DIALOG_PICKFILE(TITLE='Select CALIBRATION file: '+extfile , PATH=self.inputcaldir,/MUST_EXIST,FILTER = '*'+extfile+'*.*')
;              return,file
;    endif
;    listextfilttimeobs=''
;    listext = FILE_SEARCH(self.inputcaldir+path_sep()+'*'+extfile+'*', count=cc) 
;
;     ;keep only current filter in calib file list:
;    value=0;strarr(cc)
;      for i=0, cc-1 do begin
;      head=headfits( listext[i])
;      valuef=strcompress(sxpar( Head, 'FILTER1',  COUNT=ck),/rem)
;      if (ck gt 0)&&(valuef eq filter) then value=[value, i]
;      endfor
;      if n_elements(value) gt 1 then listextfilt=listext[value[1:n_elements(value)-1]]
;
;    ;keep only current filter in calib file list:
;    if (timeobs ne '') && (n_elements(listextfilt) gt 0) then begin
;        value=fltarr(n_elements(listextfilt))
;        for i=0, n_elements(listextfilt)-1 do begin
;            head=headfits( listextfilt[i])
;            if calibfieldind ne 1 then $
;            value[i]=strcompress(sxpar( Head, 'TIME-OBS',  COUNT=ck),/rem) $;put in JD
;            else value[i]=(file_info(listextfilt[i])).mtime
;        endfor
;        if calibfieldind ne 1 then $
;           indsorttimeobs= sort(abs(timeobs-value)) $
;        else indsorttimeobs= reverse(sort(value)) 
;        listextfilttimeobs=listextfilt[indsorttimeobs[0]]
;    endif
;    
;    return,listextfilttimeobs
;end
;
;-----------------------------------
; Look up a keyword value
function drfgui::resolvekeyword, filenames, cindex, keyw, date=date, time=time
    ; Given a list of filenames and a FITS header keyword, 
    ; return the list of UNIQUE VALUES of that keyword in those files' headers.
    ;
    ; Does **not** return all instances of the keywords if there are repeats. 


    value=strarr(cindex)
    for i=0, cindex-1 do begin ; get requested keyword for all N files
        prihead=headfits( filenames[i])
        exthead=headfits( filenames[i], ext=1)
		value = gpi_get_keyword(prihead, exthead, keyw, count=cc)
;
;        fits_info, filenames[i], n_ext=next, /silent
;        if next eq 0 then begin
;          head=headfits( filenames[i])
;          value[i]=strcompress(sxpar( Head, keyw,  COUNT=cc),/rem)
;        endif else begin
;          head=headfits( filenames[i],exten=0)
;          value[i]=strcompress(sxpar( Head, keyw,  COUNT=cc),/rem)
;          if cc ne 1 then begin
;                    headext=headfits( filenames[i],exten=1)
;                    value[i]=strcompress(sxpar( Headext, keyw,  COUNT=cc),/rem)
;          endif
;         endelse 
        if cc ne 1 then self.missingkeyw=1
    endfor
    ; sort the values:
    indsortedvalue=sort(value)
    sortedvalue=value[indsortedvalue]
    ; if /date then return only the filenames that match the first sorted
    ; value?? Thie doesn't make much sense
    if keyword_set(date) then return, filenames[indsortedvalue[where(sortedvalue eq sortedvalue[0])]]

    ; get unique values
    induniqsortedvalue=uniq(sortedvalue)
    uniqsortedvalue=sortedvalue[induniqsortedvalue]
    key=where(uniqsortedvalue ne '',ck)
    if ck ne 0 then uniqsortedvalue_noblank=uniqsortedvalue[key]
    result=''
  
    if (n_elements(uniqsortedvalue_noblank) eq 1) && (~keyword_set(date)) then result=uniqsortedvalue_noblank 
    
        
    return, result
end
;-----------------------------------------
; Verify a keyword is present? 
; Given a list of filenames and keywords,
; Check that values are present for all of them.
;
;
; Parameters:
; 	file	input filename
; 	cindex	?
; 	keyw	List of keywords to test
; 	requiredvalue	test this value FIXME make this a list or range?
; 	storage	?
; 	/needalertdialog 	flag to display dialog if keyword not found
;
;
function drfgui::validkeyword, file, cindex, keyw, requiredvalue,storage,needalertdialog=needalertdialog
    common GPI_DRP_VALIDKEYWORD, last_filename, last_pri_header, last_ext_header

	if ~(keyword_set(last_filename)) then last_filename=""
    value=strarr(cindex)
    matchedvalue=intarr(cindex)
    ok=1
	for i=0, cindex-1 do begin
		;fits_info, file[i],/silent, N_ext 
	    ;catch, Error_status
	    if strmatch(!ERROR_STATE.MSG, '*Unit: 101*'+file[i]) then wait,1

		if file[i] eq last_filename then begin
			print, "Revalidating same file. Using last file read header"
			pri_header = last_pri_header
			ext_header = last_ext_header
		endif else begin
			print, "Reading from disk: "+file[i]
			file_data = gpi_load_fits(file[i],/nodata,/silent)
			pri_header = *file_data.pri_header
			ext_header = *file_data.ext_header
		endelse

		value[i] = gpi_get_keyword(pri_header, ext_header, keyw,count=cc)

;	    fits_info, file[i], n_ext=next, /silent
;      	if next eq 0 then begin
;  			head=headfits( file[i]) ;will scan PHU
;  		  	value[i]=strcompress(sxpar( Head, keyw,  COUNT=cc),/rem)
;		endif else begin
;		    head=headfits( file[i], exten=0) ;First try PHU
;        	value[i]=strcompress(sxpar( Head, keyw,  COUNT=cc),/rem)
;        	if cc eq 0 then begin
;        		headext=headfits( file[i], exten=1) ;else try extension header
;	        	value[i]=strcompress(sxpar( Headext, keyw,  COUNT=cc),/rem)
;    	    endif  
;		endelse

		if cc eq 0 then begin
			self->log,'Absent '+keyw+' keyword for data: '+file(i)
			stop
			ok=0
		endif
		if cc eq 1 then begin
			matchedvalue=stregex(value[i],requiredvalue,/boolean,/fold_case)
			if matchedvalue ne 1 then begin 
			  self->log,'Invalid '+keyw+' keyword for data: '+file(i)
			  self->log,keyw+' keyword found: '+value(i)
			  if keyword_set(needalertdialog) then void=dialog_message('Invalid '+keyw+' keyword for data: '+file(i)+' keyword found: '+value(i))
			  ok=0
			endif
		endif

		last_filename = file[i]	
		last_pri_header = temporary(pri_header)
		last_ext_header = temporary(ext_header)

		  ;if ok ne 1 then self->log, 'File '+file[i]+' is missing required '+keyw+' keyword!'
	endfor  
 
      
  return, ok
end

;--------------------------------------------------------------------------------
; determine the relevant keywords to find out the observation mode of a file. 
; return as a structure.

function drfgui::get_obs_keywords, filename
	if ~file_test(filename) then begin
		self->Log, "ERROR can't find file: "+filename
		return, -1
	endif


	; Load FITS file, preprocessing as needed for I&T lack of keywords
	fits_data = gpi_load_fits(filename,/nodata,/silent)
	head = *fits_data.pri_header
	ext_head = *fits_data.ext_header
	ptr_free, fits_data.pri_header, fits_data.ext_header

	obsstruct = {gpi_obs, $
				ASTROMTC: strc(  gpi_get_keyword(head, ext_head,  'ASTROMTC', count=ct0)), $
				OBSCLASS: strc(  gpi_get_keyword(head, ext_head,  'OBSCLASS', count=ct1)), $
				obstype:  strc(  gpi_get_keyword(head, ext_head,  'OBSTYPE',  count=ct2)), $
				OBSID:    strc(  gpi_get_keyword(head, ext_head,  'OBSID',    count=ct3)), $
				filter:   strc(gpi_simplify_keyword_value(strc(   gpi_get_keyword(head, ext_head,  'IFSFILT',   count=ct4)))), $
				dispersr: strc(gpi_simplify_keyword_value(gpi_get_keyword(head, ext_head,  'DISPERSR', count=ct5))), $
				OCCULTER: strc(gpi_simplify_keyword_value(gpi_get_keyword(head, ext_head,  'OCCULTER', count=ct6))), $
				LYOTMASK: strc(  gpi_get_keyword(head, ext_head,  'LYOTMASK',     count=ct7)), $
				ITIME:    float( gpi_get_keyword(head, ext_head,  'ITIME',    count=ct8)), $
				OBJECT:   strc(  gpi_get_keyword(head, ext_head,  'OBJECT',   count=ct10)), $
				valid: 0}
	vec=[ct0,ct1,ct2,ct3,ct4,ct5,ct6,ct7,ct8, ct10]
	if total(vec) lt n_elements(vec) then begin
		self.missingkeyw=1 
		;give some info on missing keyw:
		keytab=['ASTROMTC','OBSCLASS','OBSTYPE','OBSID', 'IFSFILT','DISPERSR','OCCULTER','LYOTMASK','ITIME', 'OBJECT']
		indzero=where(vec eq 0, cc)
		print, "Invalid/missing keywords for file "+filename
		if cc gt 0 then self->Log, 'Missing keyword(s): '+strjoin(keytab[indzero]," ")

		stop
	endif else begin
		self.missingkeyw=0 ; added by Marshall for cleanup & consistency
		obsstruct.valid=1
	endelse

	
	
	return, obsstruct



end

;--------------------------------------------------------------------------------
pro drfgui::extractparam, modnum 
	; oh my god this code is incomprehensible now.

    *self.indarg=where(   ((*self.PrimitiveInfo).argmodnum) eq ([(*self.indmodtot2avail)[(*self.curr_mod_indsort)[modnum]]]+1)[0], carg)
end

;-----------------------------------------
function drfgui::get_input_dir
	; Return the name of the directory we should look in for new files
	; This is by default the current IFS raw data directory
	;
	; See also the last_used_input_dir variable, which we use to keep
	; track of whether the user has manually selected another directory
	;
	; FIXME: last_used_input_dir is only in parsergui, should be merged into
	; parser adn drfgui both for consistency
	;

	if gpi_get_setting('organize_raw_data_by_dates',/bool) then begin
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

;-------------------------------------
; Parse the DRS Config XML file 
; and update my knowledge of available modules/primitives
;
; This function sets a pointer to info on the object structure, be sure to free
; it when you're done. 
pro drfgui::load_configParser

    config_file=gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+"gpi_pipeline_primitives.xml" 
    if ~file_test(config_file) then res=dialog_message ('ERROR: Cannot find DRP Primitives Config File! Check for '+config_file+" and check pipeline configuration.")

    ConfigParser = OBJ_NEW('gpiDRSConfigParser')
    ConfigParser->ParseFile, config_file 

    if ~ptr_valid(self.PrimitiveInfo) then self.PrimitiveInfo = ptr_new(ConfigParser->getidlfunc())

    obj_destroy, ConfigParser

end


;--------------------------------------------------------------------------------
; Change the current template
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
pro drfgui::change_current_template, typestring,seqnum, notemplate=notemplate

    ;if self.selecseq eq seqnum then return ; do nothing for no change
    self.selecseq=seqnum
    
    wm = where((*self.templates).reductiontype eq typestring, mct)
    if mct eq 0 then begin
		message, 'Requested reduction type "'+typestring+'" is invalid/unknown. Cannot load any Recipes!',/info
		widget_control, self.seqid,SET_DROPLIST_SELECT=0
		return
	endif


    chosen_template = wm[seqnum]

    widget_control, self.seqid,SET_DROPLIST_SELECT=seqnum

    print, "Chosen template filename:"+((*self.templates)[chosen_template]).filename

    if ~(keyword_set(notemplate)) then begin
        self->loadDRF, ((*self.templates)[chosen_template]).filename,   /nodata
    endif

end


;--------------------------------------------------------------------------------
;  Change the list of Available primitives to match the currently selected
;  Reduction Type
;
;  ARGUMENTS:
;          typestr       string, name of the mode type to use
;          seqval        integer, which sequence in that type to use.
;          /all			 Display all primitives, no matter what.
;
pro drfgui::update_available_primitives, requested_type, seqval, all=all

    type=(*self.PrimitiveInfo).reductiontype ; list of type for each module

	indmatch = where(strmatch(type, '*'+requested_type+"*",/fold_case),cm)
	indall   = where(strmatch(type, '*all*',/fold_case),cm)

;    if strmatch(typestr, 'On-Line Reduction') then begin
;        if seqval eq 1 then typetab=['ASTR','SPEC']
;        if seqval eq 2 then typetab=['ASTR','POL']
;        if seqval eq 3 then typetab=['CAL','SPEC']
;    endif else begin
;        typetab = strcompress(STRSPLIT( typestr ,'-' , /EXTRACT ),/rem)
;    endelse 
;
;    ; build a list of all available modules
;    ; the logic here is somewhat tricky and unclear.
;    indall=where(strmatch(type,'*ALL*',/fold_case),cm)          ; find ones that are 'all'
;    indastr=where(strmatch(type,'*'+typetab[0]+'*',/fold_case),cm)  ; find ones that match the first typestr
;    indspec=where(strmatch(type,'*'+typetab[1]+'*',/fold_case),cm)  ; find ones that match the second typestr
;    if typetab[1] eq 'SPEC' then comp='POL' else comp='SPEC'
;    indpol=indall[where(strmatch(type[indall],'*'+comp+'*',/fold_case),cm)] ; find ones in ALL that are also in the complementary set
;
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
        self.nbcurrmod=cm
        *self.curr_mod_avai=strarr(cm)

        for i=0,cm-1 do begin
            (*self.curr_mod_avai)[i]=((*self.PrimitiveInfo).names)[(*self.indmodtot2avail)[i]]
            *self.indarg=where(   ((*self.PrimitiveInfo).argmodnum) eq ([(*self.indmodtot2avail)[i]]+1)[0], carg)
        endfor    

    endif

    ;;sort in alphabetical order, ignoring case
    *self.curr_mod_indsort=sort(strlowcase(*self.curr_mod_avai))

    (*self.curr_mod_avai)=(*self.curr_mod_avai)[*self.curr_mod_indsort]


    ;; Update the actual table widget.
    if self.tableAvailable ne 0 then begin
        widget_control,   self.tableAvailable, set_value=transpose(*self.curr_mod_avai);, SET_TABLE_SELECT =[-1,self.nbmoduleSelec-1,-1,self.nbmoduleSelec-1]
        widget_control,   self.tableAvailable, table_ysize=n_elements(*self.curr_mod_avai)
        widget_control,   self.tableAvailable, background_color=*self.table_BACKground_colors ; have to reset this when changing table size
        widget_control,   self.tableAvailable, SET_TABLE_VIEW=[0,0]
    endif



                                ;(*self.currModSelec)=strarr(5) ;;this
                                ;makes no sense - commented out to fix
                                ;                 bug #191.
end    

;--------------------------------------------------------------------------------
; Update the list of modules selected for the current Recipe/DRF. 
;    Sets both the variables in memory and the display in the GUI
pro drfgui::update_selected_modules, new_module_indices, new_selected=new_selected
    ; update list of used modules in memory
    *self.currModSelec = (*self.currModSelec)[*,new_module_indices]
    self.nbmoduleSelec = n_elements(new_module_indices)
    (*self.order)=(*self.currModSelec)[3,*]

    ; update table widget
    if n_elements(new_selected) eq 0 then new_selected = self.nbmoduleSelec-1
    widget_control,   self.tableSelected,  set_value=(*self.currModSelec)[0:2,*], SET_TABLE_SELECT =[-1,new_selected,-1,new_selected]


    ;if new_selected gt self.nlines_modules then 
    ;print, new_selected, self.nlines_modules, (new_selected-self.nlines_modules+1)>0
    widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,(new_selected-self.nlines_modules+1)>0]
                      
       ;update param table with last selected modules of the list
       indselected=self.nbmoduleSelec-1
       self->extractparam, float((*self.currModSelec)[4,indselected])

      *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
      if (*self.indarg)[0] ne -1 then begin
      (*self.currModSelecParamTab)[*,0]=((*self.PrimitiveInfo).argname)[[*self.indarg]]
      (*self.currModSelecParamTab)[*,1]=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
      (*self.currModSelecParamTab)[*,2]=((*self.PrimitiveInfo).argdesc)[[*self.indarg]]
      endif
       widget_control,   self.tableArgs,  set_value=(*self.currModSelecParamTab)
              
end



;--------------------------------------------------------------------------------
; Read in the available templates from the GPI_TEMPLATE_DRFS directory

PRO  drfgui::Scan_Templates
	compile_opt DEFINT32, STRICTARR


    ptr_free, self.templates

    if self.templatedir eq '' then self.templatedir = 	gpi_get_directory('GPI_DRP_TEMPLATES_DIR')

    message,/info, "Scanning for templates in "+self.templatedir
    template_file_list = file_search(self.templatedir + path_sep() + "*.xml")
    


    tmp = {filename:'', type: '', name: ''}

	first_drf = obj_new('drf', template_file_list[0],/quick,/silent)

    templates = replicate(first_drf->get_summary(), n_elements(template_file_list))

    ;ConfigParser = self->get_configParser()
    ;RecipeParser = OBJ_NEW('gpiDRFParser')
    for i=0,n_elements(template_file_list)-1 do begin
        message,/info, 'scanning '+template_file_list[i]
        ;RecipeParser ->ParseFile, template_file_list[i],  ConfigParser,/silent
		template = obj_new('drf', template_file_list[i],/quick,/silent)
        templates[i] = template->get_summary()
    endfor
    ;obj_destroy, RecipeParser
    ;obj_destroy, configParser

    types = uniqvals(templates.reductiontype)

    ; What order should the template types be listed in, in the GUI?
    ;type_order = [ "ASTR - SPEC", "ASTR - POL", "CAL - SPEC", "CAL - POL"] ;, "On-Line Reduction" 
	type_order  = ['SpectralScience','PolarimetricScience','Calibration','Testing']
    
    ; FIXME check if there are any new types not specified in the above list but
    ; present in the templates?
    

    ; conveniently, these filenames will already be in alphabetical order from
    ; the above.
    print, "----- Templates located: ----- "
    for it=0, n_elements(type_order)-1 do begin
        print, " -- "+type_order[it]+" -- "
        wm = where(templates.reductiontype eq type_order[it], mct)
        for im=0,mct-1 do begin
            print, "    "+templates[wm[im]].name+"     "+ templates[wm[im]].filename
        endfor
    endfor

    self.templates = ptr_new(templates)
    self.template_types = ptr_new(type_order)

    print, "----- Above templates added to catalog ----- "


end



;--------------------------------------------------------------------------------
; Select a new Reduction Type (called in response to the Reduction Type
; dropdown)
;
;	type_num	number of new type
;	/force_update		by default, this routine does nothing if the type is
;						unchanged. Set /force_update to make it refresh the list
;						anyway no matter what. 
;
pro drfgui::changetype, type_num, notemplate=notemplate, force_update=force_update

    if ~(keyword_set(force_update)) then if self.reductiontype eq (*self.template_types)[type_num] then return ; do nothing if no change
    
    ; set the reduction type as requested
    self.reductiontype = (*self.template_types)[type_num]         

    wm = where(strmatch((*self.templates).reductiontype, self.reductiontype, /fold_case), mct)
    if mct eq 0 then begin
		message, "Invalid template type, or no known templates for that type: "+self.reductiontype,/info
	    widget_control, self.seqid, set_value= ['                ']
	endif else begin
	    widget_control, self.seqid, set_value= ((*self.templates)[wm]).name
	endelse

    self->update_available_primitives, self.reductiontype, 1

    self->change_current_template, self.reductiontype, 0, notemplate=notemplate

  
end
;-----------------------------------------
pro drfgui::removefile,storage, file
    ; Remove a file from the input files list. 

    index =     (*storage.splitptr).selindex
    file =      (*storage.splitptr).filename
    printfile = (*storage.splitptr).printname
    datefile =  (*storage.splitptr).datefile

    ; shift filelist
    nlist = n_elements((*storage.splitptr).filename)
    file[index:nlist-2] = file[index+1:nlist-1]
    file[nlist-1] = ''
    printfile[index:nlist-2] = printfile[index+1:nlist-1]
    printfile[nlist-1] = ''

    widget_control,storage.fname,set_value=printfile
    (*storage.splitptr).filename = file
    (*storage.splitptr).printname = printfile
    (*storage.splitptr).datefile = datefile
    (*storage.splitptr).findex = (*storage.splitptr).findex - 1
    (*storage.splitptr).selindex = (*storage.splitptr).selindex - 1

    if ((*storage.splitptr).findex lt 0) then $
        (*storage.splitptr).findex = 0
    if ((*storage.splitptr).selindex lt 0) then $
        (*storage.splitptr).selindex = 0
    
    self->log,'Item removed.'
  
end

;-----------------------------------------
; Add a file to the queue
pro drfgui::queue, filename; , storage=storage

    if ~file_test(filename) then begin
    	widget_control,self.top_base,get_uvalue=storage  
        message, /info, "File "+filename+" does not exist!"
      	self->log,"File "+filename+" does not exist!"
      	self->log,"Use Save Recipe button"
      	return
    endif 

    ; Make sure the filename ends with '.waiting.xml'
    if strpos(filename,".waiting.xml") eq -1 then begin
        newfilename = file_basename(filename,".xml")+".waiting.xml"
    endif else begin
        newfilename = file_basename(filename)
    endelse


	newfn = self.queuedir+path_sep()+newfilename
    isalreadypresent=file_test(newfn)
    if isalreadypresent ne 1 then begin
      FILE_COPY, filename, newfn,/overwrite
      self->log,'Queued '+newfilename+" to "+newfn
    endif else begin
      self->log,'Recipe already queued.'
    endelse

end



;; simple wrapper to call object routine
;PRO drfgui_event, ev
;    widget_control,ev.top,get_uvalue=storage
;	if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
;end
;-----------------------------------------
; actual event handler: 
pro drfgui::event,ev

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
              'moduavai':textinfo='Left-click for Primitve Desciption | Right-click to add the selected primitive to the current Recipe.'
              'tableselected':textinfo='Left-click to see argument parameters of the module | Right-click to remove the selected module from the current Recipe.'
              'tableargs':textinfo='Left-click on Value cell to change the value. Press Enter to validate.'
              'mod_desc':textinfo='Click on a module in the Available Primitives list to display its description here.'
              'text_status':textinfo='Status log message display window.'
              'ADDFILE': textinfo='Click to add files to current input list'
              'WILDCARD': textinfo='Click to add files to input list using a wildcard ("*.fits" etc)'
              'REMOVE': textinfo='Click to remove currently highlighted file from the input list'
              'REMOVEALL': textinfo='Click to remove all files from the input list'
              'Remove primitive': textinfo='Remove the selected module from the execution list'
              'Add primitive': textinfo='Add the selected module from "Available Primitives" into the execution list'
              "Save Recipe as...": textinfo='Save Recipe to a filename of your choosing'
              "Drop": textinfo="Queue & execute the last saved Recipe"
              'Save&Drop': textinfo="Save the file, then queue it"
              'Quit Recipe Editor': textinfo="Close and exit this program"
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
  

	if uval eq 'top_menu' then uval=ev.value ; respond to menu selections from event, not uval

    ; Menu and button events: 
    case uval of 
   'typefield':begin
        selectype=widget_info(self.typeid,/DROPLIST_SELECT)
        self->changetype, selectype
    end
   
   'seqfield':begin
        selecseq=widget_info(self.seqid,/DROPLIST_SELECT)
        self->change_current_template, self.reductiontype, selecseq
   end

   'resolvecalibfilename':begin
        calibfieldind=widget_info(self.calibfileid,/DROPLIST_SELECT)
        case calibfieldind of 
            0: begin
              time=self.ftimeobs
              end
            1: time=SYSTIME( /JULIAN)
            2: time=0
        endcase
        for ii=0,self.nbmoduleSelec-1 do begin
            ; calibration file?
            self->extractparam,  float((*self.currModSelec)[4,ii])
            if *self.indarg ne [-1] then begin
                indcalib=where(((*self.PrimitiveInfo).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)
                if ccf ne 0 then (*self.currModSelec)[2,ii]=((*self.PrimitiveInfo).argdefault)[[(*self.indarg)[indcalib]]]
                if (ccf ne 0)  then begin ;&& (self.filter ne '')
                    resolvedcalibfile=self->resolvecalibfile( self.filter, ((*self.PrimitiveInfo).argtype)[[(*self.indarg)[indcalib]]],time,calibfieldind)
                    argtab=((*self.PrimitiveInfo).argdefault)
                    argtab[(*self.indarg)[indcalib]]=resolvedcalibfile
                    ((*self.PrimitiveInfo).argdefault)=argtab
                    ;((*self.PrimitiveInfo).argdefault)[[(*self.indarg)[indcalib]]]=resolvedcalibfile
                    (*self.currModSelec)[2,ii]=resolvedcalibfile
                endif
            endif
        endfor
        widget_control,   self.tableSelected,  set_value=(*self.currModSelec)[0:2,*], SET_TABLE_SELECT =[-1,0,-1,0]
        widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,0]
    end              
    'moduavai':begin
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CELL_SEL') THEN BEGIN  ;LEFT CLICK
            ; Update displayed module comment
               selection = WIDGET_INFO(self.tableAvailable, /TABLE_SELECT) 
               ; get all descriptions for modules currently displayed:
               currdescs = ((*self.PrimitiveInfo).comment)[(*self.indmodtot2avail)[(*self.curr_mod_indsort)]]
               ; and get the one description corresponding to the selected
               ; module:
               indselected=selection[1] < (n_elements(currdescs)-1)
               comment=currdescs[indselected]
               if comment eq '' then comment=(*self.curr_mod_avai)[indselected]

               widget_control,   self.descr,  set_value=comment
        ENDIF 
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_CONTEXT') THEN BEGIN  ;RIGHT CLICK
        ;check if addmodule method already exist
;        help, self, /obj,output=meth
;        if total(strmatch(meth[*], '*addmodule*',/fold)) eq 1 then $
           self->AddPrimitive
                                ;else self->log,'Define your reduction sequence first. '
     	ENDIF 

    end
	'Add primitive': self->AddPrimitive
	'Remove primitive': self->RemovePrimitive
    'tableselected':begin     ; Table of currently selected modules (i.e. those in the recipe) 
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CELL_SEL') THEN BEGIN  ;LEFT CLICK
               selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 

               ;update arguments table
               indselected=selection[1]
               if indselected lt self.nbmoduleSelec then begin
                   self->extractparam, float((*self.currModSelec)[4,indselected])
    
                  *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
                  if (*self.indarg)[0] ne -1 then begin
                      (*self.currModSelecParamTab)[*,0]=((*self.PrimitiveInfo).argname)[[*self.indarg]]
                      (*self.currModSelecParamTab)[*,1]=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
                      (*self.currModSelecParamTab)[*,2]=((*self.PrimitiveInfo).argdesc)[[*self.indarg]]
                  endif
                  widget_control,   self.tableArgs,  set_value=(*self.currModSelecParamTab)
               endif  
               ;;if click on FindCalibration File mode
               if (selection[0] eq 1) && (selection[2] eq 1) && (n_elements((*self.currModSelecParamTab)) gt 0)  && (ev.sel_bottom ne -1) then begin
                    if (*self.currModSelec)[1,selection[1]] eq 'Manual' then begin
                       (*self.currModSelec)[1,selection[1]]='Auto'
                       resolvedcalibfile='AUTOMATIC'
                       (*self.currModSelec)[2,selection[1]]=resolvedcalibfile
                        indcal=where((*self.currModSelecParamTab)[*,0] eq 'CalibrationFile',cf)
                        indcalib=where(((*self.PrimitiveInfo).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)
                        argtab=((*self.PrimitiveInfo).argdefault)
                        argtab[(*self.indarg)[indcalib]]=resolvedcalibfile
                        ((*self.PrimitiveInfo).argdefault)=argtab
                        (*self.currModSelecParamTab)[indcal,1]=resolvedcalibfile
                    endif else begin
                    if (*self.currModSelec)[1,selection[1]] eq 'Auto' then begin
                       (*self.currModSelec)[1,selection[1]]='Manual'
                       (*self.currModSelec)[2,selection[1]]='Click here to select a calibration file'
                       resolvedcalibfile=''
                        indcal=where((*self.currModSelecParamTab)[*,0] eq 'CalibrationFile',cf)
                        indcalib=where(((*self.PrimitiveInfo).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)
                        argtab=((*self.PrimitiveInfo).argdefault)
                        argtab[(*self.indarg)[indcalib]]=resolvedcalibfile
                        ((*self.PrimitiveInfo).argdefault)=argtab
                        (*self.currModSelecParamTab)[indcal,1]=resolvedcalibfile
                       
                    endif    
                    endelse                
                  widget_control,   self.tableSelected,  set_value=(*self.currModSelec)[0:2,*]
                  widget_control,   self.tableArgs,  set_value=(*self.currModSelecParamTab)
               endif
               
               ;;if click on calib file, open a dialogpickfile
               if (selection[0] eq 2) && (selection[2] eq 2) && (n_elements((*self.currModSelecParamTab)) gt 0) then begin
                 indcal=where((*self.currModSelecParamTab)[*,0] eq 'CalibrationFile',cf)
                 if cf eq 1 then begin                     
                     ;extractparam,  float((*self.currModSelec)[4,selection[1]])
                  if *self.indarg ne [-1] then begin
                     indcalib=where(((*self.PrimitiveInfo).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)
                     if (ccf ne 0)  then begin ;&& (self.filter ne '')
                        extfile=((*self.PrimitiveInfo).argtype)[[(*self.indarg)[indcalib]]]
                        resolvedcalibfile = DIALOG_PICKFILE(TITLE='Select Calibration File of type: '+extfile , PATH=self.inputcaldir,/MUST_EXIST,FILTER = '*'+extfile+'*.*')
						if resolvedcalibfile ne '' then begin ; if user cancels we get a null string back, in which case do nothing.
							argtab=((*self.PrimitiveInfo).argdefault)
							argtab[(*self.indarg)[indcalib]]=resolvedcalibfile
							((*self.PrimitiveInfo).argdefault)=argtab
							(*self.currModSelecParamTab)[indcal,1]=resolvedcalibfile
							;((*self.PrimitiveInfo).argdefault)[[(*self.indarg)[indcalib]]]=resolvedcalibfile
							(*self.currModSelec)[2,selection[1]]=resolvedcalibfile
							(*self.currModSelec)[1,selection[1]] = 'Manual'
						endif
                     endif
                  endif
                  widget_control,   self.tableSelected,  set_value=(*self.currModSelec)[0:2,*]
                  widget_control,   self.tableArgs,  set_value=(*self.currModSelecParamTab)
                 endif
               endif               
        ENDIF 
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_CONTEXT') THEN BEGIN  ;RIGHT CLICK. delete currently selected module from list
			self->RemovePrimitive              
        ENDIF
    end      
    'tableargs': begin
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CH') THEN BEGIN 
        selected_cell = WIDGET_INFO(self.tableArgs, /TABLE_SELECT)

		n_args = (size(*self.currModSelecParamTab))[1]
		if selected_cell[1]  gt n_args -1 then return ; user has tried to select an empty cell

        if selected_cell[0] eq 1 then begin
            WIDGET_CONTROL, self.tableArgs, GET_VALUE=selection_value,USE_TABLE_SELECT= selected_cell

            ;;verify user-value: type 
            argtabtype=((*self.PrimitiveInfo).argtype)
            type=argtabtype[(*self.indarg)[selected_cell[1]]]
            val=0.
            isnum=str2num(selection_value[0],type=typenum)
            case typenum of
              1:typeName ='INT'
              2:typeName ='INT'
              3:typeName ='INT'
              4:typeName ='FLOAT'
              5:typeName ='FLOAT'
              7:typeName ='STRING'
              12:typeName ='INT'
            endcase    
            ;leave the possib. to enter a blank string:
            if (selection_value[0] eq '') then typeName='STRING'
            ;compare default type and user value type 
            typeflag = 1 & rangeflag = 1
            if type ne '' then $;keep the possibility to have no type control if default type has been set to ''
            ; Check to ensure the argument has the proper type. 
              ; Special case: it is acceptable to enter an INT type into an
              ; argument expecting a FLOAT, because of course the set of
              ; integers is a subset of the set of floats. 
            if (strcmp(typeName,type,/fold))  $
              or (strlowcase(type) eq 'float' and strlowcase(typename) eq 'int')  $
              or (strlowcase(type) eq 'enum' and strlowcase(typename) eq 'string')  $
              then $
              typeflag=1 $
            else typeflag=0


            ;;verify user-value: range 
            if (strcmp('string',type,/fold) ne 1) && (strcmp('string',typeName,/fold) ne 1) && (type ne '') then begin
              argtabrange=((*self.PrimitiveInfo).argrange)
              range=argtabrange[(*self.indarg)[selected_cell[1]]]
              ranges=strsplit(range,'[,]',/extract)
              if (float(ranges[0]) le float(selection_value[0])) && (float(ranges[0]) le float(selection_value[0])) then rangeflag=1 else rangeflag=0
            endif
             if (strcmp('enum',type,/fold) eq 1) && (strcmp('string',typeName,/fold) eq 1) && (type ne '') then begin
              argtabrange=((*self.PrimitiveInfo).argrange)
              range=argtabrange[(*self.indarg)[selected_cell[1]]]
              ranges=strsplit(range,'[,]',/extract)
              if strmatch(ranges[0],"*"+selection_value[0]+"*",/fold)  then rangeflag=1 else rangeflag=0
            endif
            if (typeflag eq 0) || (rangeflag eq 0) then begin
              err=''
              if (typeflag eq 0) then err+='type '
              if (rangeflag eq 0) then err+='range '
              self->log,'Sorry, you entered a value with wrong: '+err
              res = dialog_message('Sorry, you tried to enter a value but it had the wrong '+err+". The value was NOT updated; please try again.",/error, title='Unable to set value')
              
              ;stop
            endif else begin 
              ;;
              argtab=((*self.PrimitiveInfo).argdefault)
              argtab[(*self.indarg)[selected_cell[1]]]=selection_value[0]
              ((*self.PrimitiveInfo).argdefault)=argtab
              ;is it a change of the calibrationfile?
              argname=((*self.PrimitiveInfo).argname)
              if argname[(*self.indarg)[selected_cell[1]]] eq 'CalibrationFile' then begin
                 selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
                 indselected=selection[1]
                 (*self.currModSelec)[2,indselected]=selection_value[0] ;change curModSelec tab for display
                 widget_control,   self.tableSelected,  set_value=(*self.currModSelec)[0:2,*]
                 widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,0]
              endif
            endelse
        endif else begin
          self->log,'Sorry, you can only change the Value field. Edit the IDL source of the module to change or add Arguments. '
          res = dialog_message( 'Sorry, you can only change the Value field. Edit the IDL source of the module to change or add Arguments. ',/error, title='Unable to add new argument')
          
        endelse
      ENDIF
  end
  'autoresolvetypeseq':begin
        isresolvebuttonset=widget_info(self.resolvetypeseq_id,/button_set)
        if isresolvebuttonset then begin
        self->log,'Type and sequence will be set automatically when new files are added.'
        endif else begin
        self->log,'Type and sequence will NOT be changed when new files are added.'
        endelse
  end
  'ADDFILE' : begin
     index = (*storage.splitptr).selindex
     cindex = (*storage.splitptr).findex
     file = (*storage.splitptr).filename
     pfile = (*storage.splitptr).printname
     datefile = (*storage.splitptr).datefile
     
     if self.last_used_input_dir eq '' then self.last_used_input_dir = self->get_input_dir()
     
     if (file[n_elements(file)-1] eq '') then begin
        result=dialog_pickfile(path=self.last_used_input_dir,/multiple,/must_exist,$
                               title='Select Raw Data File(s)', filter=['*.fits','*.fits.gz'],get_path=getpath)
     endif else begin
        msgtext = 'Sorry, maximum number of files reached. You cannot add any additional files/directories.'
        self->log, msgtext
        res= dialog_message(msgtxt,/error,dialog_parent=self.top_base)
        result = ''
     endelse
     
     result = strtrim(result,2)
     for i=0,n_elements(result)-1 do begin ; Check for duplicate
        if (total(file eq result[i]) ne 0) then result[i] = ''
     endfor
     for i=0,n_elements(result)-1 do begin
        tmp = strsplit(result[i],'.',/extract)
     endfor
     
     w = where(result ne '')
     if (w[0] ne -1) then begin
        result = result(w)
        
        if ((cindex+n_elements(result)) gt n_elements(file)) then begin
           nover = cindex+n_elements(result)-n_elements(file)
           self->log,'WARNING: You tried to add more files than the file number limit. '+$
                     strtrim(nover,2)+' files ignored.'
           result = result[0:n_elements(result)-1-nover]
        endif
        file[cindex:cindex+n_elements(result)-1] = result
        
        for i=0,n_elements(result)-1 do begin
                                ;tmp = strsplit(result[i],path_sep(),/extract)
                                ;pfile[cindex+i] = tmp[n_elements(tmp)-1]+'    '
           pfile[cindex+i] = file_basename(result[i])+'    '
        endfor
        
        self.inputdir = file_dirname(result[0])
        self.last_used_input_dir = self.inputdir ; for use next time we open files
                                ;self.inputdir=strjoin(tmp[0:n_elements(tmp)-2],path_sep())
                                ;if !VERSION.OS_FAMILY ne 'Windows' then self.inputdir = "/"+self.inputdir 
        
        
        
        cindex = cindex+n_elements(result)
        (*storage.splitptr).selindex = max([0,cindex-1])
        (*storage.splitptr).findex = cindex
        (*storage.splitptr).filename = file
        (*storage.splitptr).printname = pfile
        (*storage.splitptr).datefile = datefile 
        
        
        message,/info, 'Skipping validation for now - besides these vars were not used anywhere'
        if 0 then begin
           ;;TEST DATA SANITY
           ;;ARE THEY VALID  GEMINI-GPI-IFS DATA?
           validtelescop=self->validkeyword( file, cindex,'TELESCOP','Gemini',storage)
           validinstrum=self->validkeyword( file, cindex,'INSTRUME','GPI',storage)
           validinstrsub=self->validkeyword( file, cindex,'INSTRSUB','IFS',storage)     
           ;;DATA HEALTH
           validhealth=self->validkeyword( file, cindex,'GPIHEALT','good',storage)
           validstate=self->validkeyword( file, cindex,'GPISTATE','good',storage)
           validrawgemqa=self->validkeyword( file, cindex,'RAWGEMQA','good',storage)
        endif
        
        
        ;; RESOLVE FILTER
        self.filter=self->resolvekeyword( file, cindex,'filter1')
        
        ;;RESOLVE TIMEOBS
        
        dateobsfile=self->resolvekeyword( file, cindex,'DATE-OBS',/date)
        timeobsfile=self->resolvekeyword( dateobsfile, n_elements(dateobsfile),'TIME-OBS',/date)
        if (dateobsfile[0] ne '') &&  (timeobsfile[0] ne '') then begin
           head=headfits( timeobsfile[0])
           date=strsplit(strcompress(sxpar( Head, 'DATE-OBS',  COUNT=cc),/rem),'-',/EXTRACT)
           timeobs=strsplit(strcompress(sxpar( Head, 'TIME-OBS',  COUNT=cc),/rem),':',/EXTRACT)
           if (n_elements(date) eq 3) && (n_elements(timeobs) eq 3) then $
              self.ftimeobs = JULDAY(date[1], date[2], date[0], timeobs[0], timeobs[1], timeobs[2]) 
        endif
        ;;RESOLVE MOD
        self.dispersr=self->resolvekeyword( file, cindex,'PRISM') ; FIXME
        
        ;;RESOLVE TYPE
        self.ftype=self->resolvekeyword( file, cindex,'OBSTYPE')
        ;;RESOLVE CLASS
                                ;self.fseq=resolvekeyword( file, cindex,'OBSCLASS')
        
        
        isresolvebuttonset=widget_info(self.resolvetypeseq_id,/button_set)
        if isresolvebuttonset then begin
           detectype=0
           if strmatch(self.dispersr,'pol*',/fold) && strmatch(self.ftype,'obj*',/fold) then detectype=2
           if strmatch(self.dispersr,'pol*',/fold) && ~strmatch(self.ftype,'obj*',/fold) then detectype=4
           if strmatch(self.dispersr,'spec*',/fold) && strmatch(self.ftype,'obj*',/fold) then detectype=1
           if strmatch(self.dispersr,'spec*',/fold) && ~strmatch(self.ftype,'obj*',/fold) then detectype=3
           detecseq=1
           if strmatch(self.ftype,'flat*',/fold) then begin 
              detecseq=1 & detectype=3 
           endif
           if strmatch(self.ftype,'dark*',/fold) then begin 
              detecseq=2 & detectype=3 
           endif
           if strmatch(self.ftype,'lamp*',/fold)||strmatch(self.ftype,'Ar*',/fold)||strmatch(self.ftype,'Xe*',/fold)||strmatch(self.ftype,'wavecal*',/fold) then begin 
              detecseq=3 & detectype=3 
           endif
           
           if detectype ne 0 then begin
              ;;set type & seq widgets
              widget_control, self.typeid, get_value=typetab
              self->log,'resolved TYPE: '+typetab[detectype-1]+", id="+strc(detectype-1)
              widget_control, self.typeid,SET_DROPLIST_SELECT=detectype-1
              self->changetype, detectype-1 ;,/notemplate
              self->log,'resolved SEQUENCE: '+self.ftype
              widget_control, self.seqid,SET_DROPLIST_SELECT=detecseq-1
              self->change_current_template, typetab[detectype-1],detecseq-1
           endif else begin
              self->log,'Sorry, no resolved TYPE or SEQUENCE.'
           endelse
        endif
        
        widget_control,storage.fname,set_value=pfile
        self->log,strtrim(n_elements(result),2)+' files added.'
        self->log,'resolved FILTER band: '+self.filter
     endif
  end

  'WILDCARD' : begin
        index = (*storage.splitptr).selindex
        cindex = (*storage.splitptr).findex
        file = (*storage.splitptr).filename
        pfile = (*storage.splitptr).printname
        datefile = (*storage.splitptr).datefile
    
        defdir=self->get_input_dir()

        caldat,systime(/julian),month,day,year
        datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
        
        if (file[n_elements(file)-1] eq '') then begin
            command=textbox(title='Input a Wildcard-listing Command (*,?,[..-..])',$
                group_leader=ev.top,label='',cancel=cancelled,xsize=500,$
                value=defdir+'*'+datestr+'*')
        endif else begin
            self->log,'Sorry, you cannot add files/directories any more.'
            cancelled = 1
        endelse

        if cancelled then begin
            result = ''
        endif else begin
            result=file_search(command)
        endelse
        result = strtrim(result,2)
        for i=0,n_elements(result)-1 do $
            if (total(file eq result[i]) ne 0) then result[i] = ''
;        for i=0,n_elements(result)-1 do begin
;            tmp = strsplit(result[i],'.',/extract)
;            if (n_elements(tmp) lt 5) then result[i] = ''
;        endfor
        w = where(result ne '')
        if (w[0] ne -1) then begin
            result = result[w]

            if ((cindex+n_elements(result)) gt n_elements(file)) then begin
                nover = cindex+n_elements(result)-n_elements(file)
                self->log,'WAR: exceeding file number limit. '+$
                    strtrim(nover,2)+' files ignored.'
                result = result[0:n_elements(result)-1-nover]
            endif
            file[cindex:cindex+n_elements(result)-1] = result

            for i=0,n_elements(result)-1 do begin
                tmp = strsplit(result[i],path_sep(),/extract)
                pfile[cindex+i] = tmp[n_elements(tmp)-1]+'    '
            endfor

            widget_control,storage.fname,set_value=pfile

            cindex = cindex+n_elements(result)
            (*storage.splitptr).selindex = max([0,cindex-1])
            (*storage.splitptr).findex = cindex
            (*storage.splitptr).filename = file
            (*storage.splitptr).printname = pfile
            (*storage.splitptr).datefile = datefile 

            self->log,strtrim(n_elements(result),2)+' files added.'
        endif else begin
            self->log,'search failed (no match).'
        endelse
    end
    'FNAME' : begin
        (*storage.splitptr).selindex = ev.index
    end
    'REMOVE' : begin
        self->removefile, storage, file
    end
    'REMOVEALL' : begin
        if confirm(group=ev.top,message='Remove all items from the list?',$
            label0='Cancel',label1='Proceed') then begin
            (*storage.splitptr).findex = 0
            (*storage.splitptr).selindex = 0
            (*storage.splitptr).filename[*] = ''
            (*storage.splitptr).printname[*] = '' 
            (*storage.splitptr).datefile[*] = '' 
            widget_control,storage.fname,set_value=(*storage.splitptr).printname
            self->log,'All items removed.'
        endif
    end
    'RB'    : begin
    end
	'sortmethod': begin
        sortfieldind=widget_info(self.sortfileid,/DROPLIST_SELECT)
	end
    'sortdata': begin
        sortfieldind=widget_info(self.sortfileid,/DROPLIST_SELECT)
        file = (*storage.splitptr).filename
        pfile = (*storage.splitptr).printname
        cindex = (*storage.splitptr).findex 
        datefile = (*storage.splitptr).datefile 

		wgood = where(strc(file) ne '',goodct)
		if goodct eq 0 then begin
			self->Log, "No file have been selected - nothing to sort!"
			return

		endif

        case sortfieldind of 
                0: begin
                    juldattab=findgen(cindex)
                    for i=0,cindex-1 do begin
                      dateobs=self->resolvekeyword( file[i], 1,'DATE-OBS')
                      timeobs=self->resolvekeyword( file[i], 1,'TIME-OBS')
                      if (dateobs[0] ne 0) &&  (timeobs[0] ne 0) then begin
                        ;head=headfits( timeobsfile[0])
                        date=strsplit(dateobs,'-',/EXTRACT)
                        time=strsplit(timeobs,':',/EXTRACT)
                        juldattab[i] = JULDAY(date[1], date[2], date[0], time[0], time[1], time[2]) 
                      endif
                    endfor
                    indsort=sort(juldattab)

                  end
                1: begin
                     obsid=strarr(cindex)
                    for i=0,cindex-1 do begin
                      obsid[i]=self->resolvekeyword( file[i], 1,'OBSID')
                    endfor
                    indsort=sort(obsid)
                end
                2:  begin
                     alpha=strarr(cindex)
                    for i=0,cindex-1 do begin
                      alpha[i]= file[i]
                    endfor
                    indsort=sort(alpha)
                end
                3:begin
                     ctime=findgen(cindex)
                    for i=0,cindex-1 do begin
                      ctime[i]= (file_info(file[i])).ctime
                    endfor
                    indsort=sort(ctime)
                end
        endcase
        file[0:n_elements(indsort)-1]= file[indsort]
        pfile[0:n_elements(indsort)-1]= pfile[indsort]
        datefile[0:n_elements(indsort)-1]= datefile[indsort]
        (*storage.splitptr).filename = file
        (*storage.splitptr).printname = pfile
        (*storage.splitptr).datefile = datefile
        widget_control,storage.fname,set_value=pfile
    end
     'outputdir': begin
		widget_control, self.outputdir_id, get_value=tmp
		if self->check_output_path_exists(tmp) then begin
			self.outputdir = tmp
			self->log,'Output Directory changed to:'+self.outputdir
		endif else begin
			; reset screen display to prior value
			widget_control, self.outputdir_id, set_value=self.outputdir
		endelse
    end
   
    'outputdir_browse': begin
		result = DIALOG_PICKFILE(TITLE='Select a OUTPUT Directory', /DIRECTORY,/MUST_EXIST)
		if result ne '' then begin
			self.outputdir = result
			widget_control, self.outputdir_id, set_value=self.outputdir
			self->log,'Output Directory changed to:'+self.outputdir
		endif
    end
;    'logdir': begin
;		result= DIALOG_PICKFILE(TITLE='Select a LOG Path', /DIRECTORY,/MUST_EXIST)
;		if result ne '' then begin
;			self.logdir =result
;			widget_control, self.logdir_id, set_value=self.logdir
;			self->log,'Log path changed to: '+self.logdir
;		endif
;    end
    'Save Recipe as...': begin
        file = (*storage.splitptr).filename
        self->savedrf, file,storage
    end
    'Create Recipe Template and Save as...'    : begin
        file = (*storage.splitptr).filename
        self->savedrf,file,storage, /template
    end
    'Queue'  : begin
        if self.drffilename ne '' then begin
              self->queue, self.drfpath+path_sep()+self.drffilename
        endif else begin
              self->log,'Sorry, save Recipe before queueing or use "Save & Queue" button.'
        endelse
    end
    'Save&Queue'  : begin
        file = (*storage.splitptr).filename
        self->savedrf, file,storage,/nopickfile
        self->queue, self.drfpath+path_sep()+self.drffilename
    end
    'Open Recipe discarding data...':begin
        newDRF =  DIALOG_PICKFILE(TITLE='Select a Recipe File', filter='*.xml',/MUST_EXIST,path=self.drfpath)
        if newDRF ne '' then begin
            self->loaddrf, newDRF,  /nodata, /log
        endif
    end
    'Open Recipe including Data...':begin
       ;self.loadedRecipeFile = DIALOG_PICKFILE(TITLE='Select a Data Reduction File (DRF)', filter='*.xml',/MUST_EXIST,path=self.drfpath)
        newDRF =  DIALOG_PICKFILE(TITLE='Select a Recipe File', filter='*.xml',/MUST_EXIST,path=self.drfpath)
        if newDRF ne '' then begin
            self->loaddrf, newDRF
            self->log,'Output Directory :'+self.outputdir
            ;self->log,'Log path : '+self.logdir
            self->log,'Recipe:'+self.loadedRecipeFile+' has been succesfully loaded.'
        endif
    end
    'Quit Recipe Editor'    : begin
        if confirm(group=ev.top,message='Are you sure you want to close the Recipe Editor?',$
            label0='Cancel',label1='Close') then obj_destroy, self
    end

    'Rescan Templates...': begin
        self->scan_templates
    end
	'Basic View': self->set_view_mode, 1
	'Normal View': self->set_view_mode, 2
	'Advanced View': self->set_view_mode, 3 
    'Move primitive up': begin
          selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
          ind_selected=selection[1]
          if ind_selected ne 0 then begin ; can't move up
              new_indices = indgen(self.nbmoduleSelec)
              new_indices[ind_selected-1:ind_selected] = reverse(new_indices[ind_selected-1:ind_selected])
              self->update_selected_modules, new_indices, new_selected=ind_selected-1
          endif
    end
    'Move primitive down': begin
          selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
          ind_selected=selection[1]
          if ind_selected ne self.nbmoduleSelec-1 then begin ; can't move up
              new_indices = indgen(self.nbmoduleSelec)
              new_indices[ind_selected:ind_selected+1] = reverse(new_indices[ind_selected:ind_selected+1])
              self->update_selected_modules, new_indices, new_selected=ind_selected+1
          endif
    
    end
	'Show default Primitives': begin
		self.showhidden = 0

    	self->update_available_primitives, self.reductiontype, 1

	end

	'Show default + hidden Primitives': begin
		self.showhidden = 1
		;self->changetype, where(*self.template_types eq self.reductiontype),/force_update

    	self->update_available_primitives, self.reductiontype, 1

	end
 	'Show all Primitives': begin

    	self->update_available_primitives, self.reductiontype, 1,/all

	end
 
    'About': begin
              tmpstr=about_message()
              ret=dialog_message(tmpstr,/information,/center,dialog_parent=ev.top)
    end ;; case: 'about'

    
    
    else: begin
		print, 'Unknown event: '+uval
		if gpi_get_setting('enable_editor_debug', default=0,/bool,/silent) then stop
	endelse
endcase

end
;--------------------------------------

PRO drfgui::removePrimitive
	; Remove a primitive from the current recipe

	selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
	indselected=selection[1]
	if indselected eq -1 then return

	if (indselected ge 0) AND  (indselected lt self.nbmoduleSelec) AND (self.nbmoduleSelec gt 1) then begin
		indices = indgen(self.nbmoduleSelec)
		new_indices = indices[where(indices ne indselected)]
		self->log, "Removed primitive "+(*self.currModSelec)[0,indselected] ; print this out -before- updating the list

		self->update_selected_modules, new_indices, new_selected=indselected
	endif     

end



;--------------------------------------


PRO drfgui::addPrimitive
	; Add new module to the list.
	selection = WIDGET_INFO((self.tableAvailable), /TABLE_SELECT) 
	indselected=selection(1)
	if indselected eq -1 then return ; nothing selected

	; Figure out where to insert the new module into the list, based
	; on comparing the 'order' parameters.
	order=((*self.PrimitiveInfo).order)[(*self.indmodtot2avail)[(*self.curr_mod_indsort)[indselected]]]
	if n_elements(*self.order) eq 0 then begin   
		insertorder = 0
	endif else begin  
			  if n_elements(*self.order) eq 1 then begin
				  if float(order) gt float(*self.order) then insertorder =1 else insertorder=0
			  endif else begin
					insertorder = VALUE_LOCATE(float((*self.order)[sort(float(*self.order))]), float(order) ) +1
			  endelse
	endelse   

	if self.nbmoduleSelec eq 0 then begin
		  (*self.currModSelec)=([(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)])  
	endif else begin
           case insertorder of
              0:  (*self.currModSelec)=([[[(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)]],[(*self.currModSelec)]])
              self.nbmoduleSelec: (*self.currModSelec)=([[(*self.currModSelec)],[[(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)]]])
              else: begin
                 if  ((self.nbmoduleSelec) le (size(*self.currModSelec))[2]) AND ((size(*self.currModSelec))[0] gt 1) then $
                    (*self.currModSelec)=([[(*self.currModSelec)[*,0:insertorder-1]],[[(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)]],[(*self.currModSelec)[*,insertorder:self.nbmoduleSelec-1]]])
              end
           endcase
 
		;print, (size(*self.currModSelec))
	endelse

	self->Log, "Inserted module '"+(*self.curr_mod_avai)[indselected]+"' into position "+strc(insertorder)
	self.nbmoduleSelec+=1
	(*self.order)=(*self.currModSelec)[3,*]
	;does this module need calibration file?
	self->extractparam, indselected
	*self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
	if *self.indarg ne [-1] then begin
		indcalib=where(((*self.PrimitiveInfo).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)
		if ccf ne 0 then (*self.currModSelec)[2,insertorder]=((*self.PrimitiveInfo).argdefault)[[(*self.indarg)[indcalib]]]
		if ccf ne 0 then begin
			if strmatch((*self.currModSelec)[2,insertorder], 'AUTOMATIC') then $
				(*self.currModSelec)[1,insertorder]='Auto' else $
				(*self.currModSelec)[1,insertorder]='Manual'
		 endif
			
		  (*self.currModSelecParamTab)[*,0]=((*self.PrimitiveInfo).argname)[[*self.indarg]]
		  (*self.currModSelecParamTab)[*,1]=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
		  (*self.currModSelecParamTab)[*,2]=((*self.PrimitiveInfo).argdesc)[[*self.indarg]]
		endif
	  
		;;Automatic addition of Accumulate Images for combination (level II) modules.
		;;modules with order GT 2. ? 
		greatestorder= float((*self.currModSelec)[3,self.nbmoduleSelec-1])
		if greatestorder gt 4. then begin
		;;'Accumulate Images' already present? 
		isaccu=where((*self.currModSelec)[0,*] eq 'Accumulate Images',cac) 
		if cac eq 0 then begin ;Accumulate Image needed 
			self->log,'Automatic addition of "Accumulate Images" due to the addition of a level-2 module'
			widget_control, (self.tableAvailable), get_value=gettableavaila
			indselected=where(gettableavaila eq 'Accumulate Images')
			if n_elements(*self.order) eq 1 then begin
				if float(order) gt float(*self.order) then insertorder =1 else insertorder=0
			endif else begin
			  insertorder = VALUE_LOCATE(float((*self.order)[sort(float(*self.order))]), float(order) ) 
			endelse
			if insertorder eq 0 then (*self.currModSelec)=([[[(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)]],[(*self.currModSelec)]])
			if insertorder eq self.nbmoduleSelec then (*self.currModSelec)=([[(*self.currModSelec)],[[(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)]]])
			if (insertorder ne 0) AND (insertorder ne self.nbmoduleSelec) then $
				(*self.currModSelec)=([[(*self.currModSelec)[*,0:insertorder-1]],[[(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)]],[(*self.currModSelec)[*,insertorder:self.nbmoduleSelec-1]]])
			self.nbmoduleSelec+=1
			(*self.order)=(*self.currModSelec)[3,*]                        
		endif
	endif
	  
	  
	widget_control,   self.tableSelected,  set_value=(*self.currModSelec)[0:2,*], SET_TABLE_SELECT =[-1,insertorder,-1,insertorder]
	widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,0]
	widget_control,   self.tableArgs,  set_value=(*self.currModSelecParamTab)
 
end


;--------------------------------------
function drfgui::check_output_path_exists, path
	if file_test(path,/dir,/write) then begin
		return, 1 
	endif else  begin

		if gpi_get_setting('prompt_user_for_outputdir_creation',/bool) then $
			res =  dialog_message('The requested output directory '+path+' does not exist. Should it be created now?', $
			title="Nonexistent Output Directory", dialog_parent=self.top_base, /question) else res='Yes' 
		if res eq 'Yes' then begin
			file_mkdir, path
			return, 1
		endif else return, 0

	endelse
	return, 0


end


;--------------------------------------
; Save a Receipe (DRF) to a file on disk.
;
; ARGUMENTS:
; 	file	string array of FITS filenames in the DRF
; 	storage		(unused, kept for back compatibility)
; 	/template	save this DRF as a template
; 	/nopickfile	Automatically use the self.drffilename as the output file name
;
pro drfgui::savedrf, file, storage,template=template, nopickfile=nopickfile
  flag = 1
  
  index = where(file ne '',count)
  
  selectype=widget_info(self.typeid,/DROPLIST_SELECT)
  
  if keyword_set(template) then begin
     templatesflag=1 
     index=0
     file=''
     drfpath=self.templatedir
  endif else begin
     templatesflag=0
     drfpath=self.drfpath
  endelse  
  
  if (count eq 0) && (templatesflag eq 0) then begin
     self->log,'file list is empty.'
     if (selectype eq 4) then self->log,'Please select any file in the data input directory.'
     return
  endif
  
  file = file[index]
  
  if templatesflag then begin
     self.drffilename = self.loadedRecipeFile ;to check
  endif else begin     
     caldat,systime(/julian),month,day,year, hour,minute,second
     datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
     hourstr = string(hour,minute,second,format='(i2.2,i2.2,i2.2)')  
     self.drffilename=datestr+'_'+hourstr+'_drf.waiting.xml'
  endelse
  
  ;;get drf filename and set drfpath:
  if ~keyword_set(nopickfile) then begin
     newdrffilename = DIALOG_PICKFILE(TITLE='Save Data Reduction File (Recipe) as', /write,/overwrite, filter='*.xml',file=self.drffilename,path=drfpath, get_path=newdrfpath)
     if newdrffilename eq "" then begin
        self->Log, "User cancelled save; doing nothing."
        return                  ; user cancelled the save as dialog, so don't save anything.
     endif
     self.drfpath  = newdrfpath ; MDP change - update the default directory to now match whatever the user selected in the dialog box.
  endif else begin
     newdrffilename = self.drffilename
     self.drfpath = file_dirname(newdrffilename) ; update the default output directory to match whatever the user selected this time
  endelse
  
  valid = self->check_output_path_exists(self.drfpath)
  if ~valid then return
    
  if (self.nbmoduleSelec ne '') && (newdrffilename ne '') then begin
     self.drffilename = file_basename(newdrffilename)
     
     self->log,'Now writing Recipe...' ;+ self.drfpath+path_sep()+self.drffilename
     
     message,/info, "Writing to "+self.drfpath+path_sep()+self.drffilename 
     OpenW, lun, self.drfpath+path_sep()+self.drffilename, /Get_Lun
     PrintF, lun, '<?xml version="1.0" encoding="UTF-8"?>' 
     
     ;;figure out if there are multiple input directories
     ind = strpos(file,path_sep(),/reverse_search)
     indirs = strarr(n_elements(file))
     infiles = strarr(n_elements(file))
     for j = 0,n_elements(file)-1 do begin indirs[j] = strmid(file[j],0,ind[j]) & infiles[j] = strmid(file[j],ind[j]+1) & endfor
     indirsu = UNIQ(indirs, SORT(indirs))

     ;;for multiple input directories, place symoblic links in
     ;;output_dir/tmp
     if n_elements(indirsu) gt 1 then begin
        inputdirtmp = self.outputdir+path_sep()+'inputtmp'
        if ~file_test(/dir,inputdirtmp) then begin
           file_mkdir,inputdirtmp
           if ~file_test(/dir,inputdirtmp) then begin
              self->log, "ERROR: could not create tmp directory for input files."
              return
           endif
        endif
        self->log,'Creating symbolic links to input files in '+inputdirtmp
        for j = 0,n_elements(file)-1 do if ~file_test(inputdirtmp+path_sep()+infiles[j]) then file_link,file[j],inputdirtmp
     endif else inputdirtmp = self.inputdir

     ;;shorten or expand input/output paths as requested        
     isrelativebuttonset=widget_info(self.relativepath_id,/button_set)
     if isrelativebuttonset then begin
        ;;logdirtmp=gpi_shorten_path(self.logdir) 
        inputdirtmp=gpi_shorten_path(inputdirtmp) 
        outputdirtmp=gpi_shorten_path(self.outputdir) 
     endif else begin
        ;;logdirtmp=gpi_expand_path(self.logdir)
        inputdirtmp=gpi_expand_path(inputdirtmp)
        outputdirtmp=gpi_expand_path(self.outputdir)
     endelse  
     
     if selectype eq 4 then begin
        PrintF, lun, '<DRF ReductionType="OnLine">'
     endif else begin
        PrintF, lun, '<DRF ReductionType="'+(*self.template_types)[selectype] +'">'
     endelse
     
     PrintF, lun, '<dataset InputDir="'+inputdirtmp+'" OutputDir="'+outputdirtmp+'">'
     
     FOR j=0,N_Elements(file)-1 DO PrintF, lun, '   <fits FileName="' + infiles[j] + '" />'

     PrintF, lun, '</dataset>'
     FOR j=0,self.nbmoduleSelec-1 DO BEGIN
        self->extractparam, float((*self.currModSelec)[4,j])
        strarg=''
        if (*self.indarg)[0] ne -1 then begin
           argn=((*self.PrimitiveInfo).argname)[[*self.indarg]]
           argd=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
           for i=0,n_elements(argn)-1 do begin
              strarg+=argn[i]+'="'+argd[i]+'" '
           endfor
        endif
        
        PrintF, lun, '<module name="' + (*self.currModSelec)[0,j] + '" '+ strarg +'/>'
     ENDFOR
     PrintF, lun, '</DRF>'
     Free_Lun, lun
     self->log,'Saved  '+self.drffilename
     
     ;;display last paramtab
     indselected=self.nbmoduleSelec-1
     self->extractparam, float((*self.currModSelec)[4,indselected])    
     *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
     if (*self.indarg)[0] ne -1 then begin
        (*self.currModSelecParamTab)[*,0]=((*self.PrimitiveInfo).argname)[[*self.indarg]]
        (*self.currModSelecParamTab)[*,1]=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
        (*self.currModSelecParamTab)[*,2]=((*self.PrimitiveInfo).argdesc)[[*self.indarg]]
     endif
     
     widget_control,   self.tableArgs,  set_value=(*self.currModSelecParamTab), SET_TABLE_VIEW=[0,0]
     
     widget_control,   self.tableSelected,  set_value=(*self.currModSelec)[0:2,*], SET_TABLE_SELECT =[-1,self.nbmoduleSelec-1,-1,self.nbmoduleSelec-1]
     widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,0]
     widget_control,   self.tableAvailable,  set_value=transpose(*self.curr_mod_avai) ;, SET_TABLE_SELECT =[-1,self.nbmoduleSelec-1,-1,self.nbmoduleSelec-1]
     widget_control,   self.tableAvailable, SET_TABLE_VIEW=[0,0]
     
  endif else begin
     self->log, "ERROR: either no primitives selected or no output filename. Can't save until you fix that."
  endelse
end

;-------------------------------------
; load a DRF. 
;
; If /nodata is set, then just load the modules list. 
; Otherwise, load modules list AND input fits files. 
;
pro drfgui::loaddrf, filename, nodata=nodata, silent=silent, log=log

    if ~(keyword_set(filename)) then return

	filename = gpi_expand_path(filename)
    if ~file_test(filename) then begin
		message, "Requested DRF file does not exist: "+filename,/info
		self->Log, "Requested DRF file does not exist: "+filename
		return
	endif

    self.loadedRecipeFile = filename


    widget_control,self.top_base,get_uvalue=storage  

    
    ; now parse the requested DRF.
    ; First re-parse the config file (so we know about all the available modules
    ; and their arguments)
    ;ConfigParser = self->get_configParser()
    ;DRFParser = OBJ_NEW('gpiDRFParser')
    self->log, "Parsing: "+gpi_shorten_path(self.loadedRecipeFile)

    ; then parse the DRF and get its contents
    ;DRFParser ->ParseFile, self.loadedRecipeFile,  ConfigParser, gui=self, silent=silent
	drf = obj_new('drf', self.loadedRecipeFile,/silent, /quick)
    drf_summary = drf->get_summary()
    drf_contents = drf->get_contents()

    drf_module_names = drf_contents.modules.name

    


    ; if requested, load the filenames in that DRF
    ; (for Template use, don't load the data)
    if ~keyword_set(nodata) then  begin
        self.inputdir=drf_contents.inputdir
         ;;get list of files in the drf
         if strcmp((drf_contents.fitsfilenames)[0],'') ne 1  then begin
             (*storage.splitptr).filename =  drf_contents.fitsfilenames
            (*storage.splitptr).printname = drf_contents.fitsfilenames
            (*storage.splitptr).findex = n_elements(where( strtrim(drf_contents.fitsfilenames,2) ne ''))
            widget_control,storage.fname,set_value=(*storage.splitptr).printname
        endif

        for zz=0,n_elements((*storage.splitptr).filename)-1 do begin
          if strcmp(((*storage.splitptr).filename)[zz],'') ne 1  then (*storage.splitptr).filename[zz]=self.inputdir+path_sep()+(*storage.splitptr).filename[zz]
        endfor

		;update title bar of window:
	
		title  = "Recipe Editor"
		if keyword_set(session) then title += " #"+strc(session)
		widget_control, self.top_base, tlb_set_title=title+": "+filename

    endif


    ;if necessary, update reduction type to match whatever is in that DRF (and update available modules list too)
    if self.reductiontype ne drf_summary.reductiontype then begin
        selectype=where(strmatch(*self.template_types, strc(drf_summary.reductiontype),/fold_case), matchct)
        if matchct ne 1 then message,"ERROR: no match for "+self.reductiontype
        if self.typeid ne 0 then  widget_control, self.typeid, SET_DROPLIST_SELECT=selectype
        self->changetype, selectype[0], /notemplate
    endif
    

    ; Now load the modules of the selected DRF:
    self.nbmoduleSelec=0
    indseqini=intarr(n_elements(drf_module_names))
    seq=((*self.PrimitiveInfo).names)[(*self.indmodtot2avail)[*self.curr_mod_indsort]]
    for ii=0,n_elements(drf_module_names)-1 do begin
         indseqini[ii]=where(strmatch(seq,(drf_module_names)[ii],/fold_case), matchct)
		 message,/info, "Primitive "+strc(ii)+": "+ (drf_module_names)[ii]+", seq="+strc(indseqini[ii])
         if matchct eq 0 then message,/info,"ERROR: no match for primitive="+ (drf_module_names)[ii]
    endfor

    
    for ii=0,n_elements(drf_module_names)-1 do begin
        if self.nbmoduleSelec eq 0 then (*self.currModSelec)=([(drf_module_names)[0],'','','','']) $  
        else  (*self.currModSelec)=([[(*self.currModSelec)],[[(drf_module_names)[ii],'','','','']]])
        self.nbmoduleSelec+=1

        ;does this module need calibration file?
        ind=where(strmatch(tag_names((drf_contents.modules)[ii]),'CALIBRATIONFILE'), matchct)
        ; if *self.indarg ne [-1] then begin
        if (ind ne [-1]) && (((drf_contents.modules)[ii]).calibrationfile ne '') then begin
                   ; indcalib=where(((*self.PrimitiveInfo).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)

                   ; if ccf ne 0 then (*self.currModSelec)[2,self.nbmoduleSelec-1]=((*self.PrimitiveInfo).argdefault)[[(*self.indarg)[indcalib]]]
                   (*self.currModSelec)[2,self.nbmoduleSelec-1]=((drf_contents.modules)[ii]).calibrationfile
                   if strmatch((*self.currModSelec)[2,self.nbmoduleSelec-1], 'AUTOMATIC') then $
                   (*self.currModSelec)[1,self.nbmoduleSelec-1]='Auto' else $
                   (*self.currModSelec)[1,self.nbmoduleSelec-1]='Manual'
        endif
        (*self.currModSelec)[3,self.nbmoduleSelec-1]=((*self.PrimitiveInfo).order)[(*self.indmodtot2avail)[(*self.curr_mod_indsort)[indseqini[ii]]]] 

 
    endfor

    ;sort *self.currModSelec with ORDER 
    (*self.order)=float((*self.currModSelec)[3,*])

	;-- now do not re-sort based on order! This allows for the case where the DRF we are loading has been re-ordered by the user
;    ;;todo:check out there are no duplicate order (sinon la table d argument va se meler) 
;;uncomment these 3 following lies if you want DRF loaded with modules reordered (and comment the forth line)
;    (*self.currModSelec)=(*self.currModSelec)[*,sort(*self.order)]  
;    (*self.currModSelec)[4,*]=strc(indseqini[sort(*self.order)])
;    (*self.order)=(*self.currModSelec)[3,*]
    (*self.currModSelec)[4,*]=strc(indseqini[*])

    for ii=0,n_elements(drf_module_names)-1 do begin
        self->extractparam, float((*self.currModSelec)[4,ii])

        *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
        if (*self.indarg)[0] ne -1 then begin
            (*self.currModSelecParamTab)[*,0]=((*self.PrimitiveInfo).argname)[[*self.indarg]]
            (*self.currModSelecParamTab)[*,1]=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
            (*self.currModSelecParamTab)[*,2]=((*self.PrimitiveInfo).argdesc)[[*self.indarg]]
        endif
        tag=tag_names((drf_contents.modules)[ii])
        for jj=0,n_elements(*self.indarg)-1 do begin
            indtag=where(strmatch( tag ,(*self.currModSelecParamTab)[jj,0],/fold), matchct)
                        if matchct eq 0 then begin
                            message,"WARNING: no match in Recipe file for primitive parameter='"+(*self.currModSelecParamTab)[jj,0]+"'",/info
                            message,"of primitive='"+(drf_module_names)[ii]+"'",/info
                            message,"Check whether the parameter list in the Recipe file '"+self.loadedrecipefile+"' has the correct parameters for that primitive! ",/info
                        endif
            argtab=((*self.PrimitiveInfo).argdefault)
            if matchct gt 0 then argtab[(*self.indarg)[jj]]=((drf_contents.modules)[ii]).(indtag[0]) ;use parentheses as Facilities exist to process structures in a general way using tag numbers rather than tag names
            ((*self.PrimitiveInfo).argdefault)=argtab
        ;    (*self.currModSelecParamTab)[jj,1]=
        endfor
    endfor

    ;display parameters for last module
    indselected=self.nbmoduleSelec-1
    self->extractparam, float((*self.currModSelec)[4,indselected])    
    *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
    if (*self.indarg)[0] ne -1 then begin
        (*self.currModSelecParamTab)[*,0]=((*self.PrimitiveInfo).argname)[[*self.indarg]]
        (*self.currModSelecParamTab)[*,1]=((*self.PrimitiveInfo).argdefault)[[*self.indarg]]
        (*self.currModSelecParamTab)[*,2]=((*self.PrimitiveInfo).argdesc)[[*self.indarg]]
    endif
  
    widget_control,   self.tableArgs,     set_value=(*self.currModSelecParamTab)
    widget_control,   self.tableSelected,   set_value=(*self.currModSelec)[0:2,*], SET_TABLE_SELECT =[-1,self.nbmoduleSelec-1,-1,self.nbmoduleSelec-1]
    widget_control,   self.tableSelected,   SET_TABLE_VIEW=[0,0]
    widget_control,   self.outputdir_id, set_value=self.outputdir
    ;widget_control,   self.logdir_id,   set_value=self.logdir

    ;obj_destroy, ConfigParser
    ;obj_destroy, DRFParser
	if keyword_set(log) then begin
            self->log,'Output Directory :'+self.outputdir
            ;self->log,'Log path : '+self.logdir
            self->log,'Recipe:'+self.loadedRecipeFile+' has been succesfully loaded.'
	endif

end

;------------------------------------------------
pro drfgui::cleanup
	
	ptr_free, self.table_background_colors, self.PrimitiveInfo, self.curr_mod_avai
	ptr_free, self.curr_mod_indsort, self.currModSelec, self.order, self.indarg
	ptr_free, self.currModSelecParamTab, self.indmodtot2avail, self.templates, self.template_types, self.drf_summary

	if (xregistered (self.xname) gt 0) then    widget_control,self.top_base,/destroy
	
	heap_gc
end

;------------------------------------------------
pro drfgui::init_data, _extra=_Extra

	message,/info, 'DRFGUI init data'
	compile_opt idl2
	;--- init object member variables
	self->load_configparser

	self.curr_mod_avai=     ptr_new(/ALLOCATE_HEAP)         ; list of available module names (strings) in current mode
	self.curr_mod_indsort=  ptr_new(/ALLOCATE_HEAP)
	self.currModSelec=      ptr_new(/ALLOCATE_HEAP)
	self.order=             ptr_new(/ALLOCATE_HEAP)
	self.indarg=            ptr_new(/ALLOCATE_HEAP)                ; ???
	self.currModSelecParamTab=  ptr_new(/ALLOCATE_HEAP)
	self.indmodtot2avail=   ptr_new(/ALLOCATE_HEAP)
	self.version=2.0



	self.templatedir = 	gpi_get_directory('GPI_DRP_TEMPLATES_DIR')
	self.outputdir = 	gpi_get_directory('GPI_REDUCED_DATA_DIR')
	;self.logdir = 		gpi_get_directory('GPI_DRP_LOG_DIR')
	self.queuedir =		gpi_get_directory('GPI_DRP_QUEUE_DIR')
	self.inputcaldir =	gpi_get_directory('GPI_calibrations_dir')
	self.dirpro = 		gpi_get_directory('GPI_DRP_DIR') ;+path_sep();+'gpidrfgui'+path_sep();dirlist[0]

	; how do we organize DRFs? 
	if gpi_get_setting('organize_DRFs_by_dates',/bool) then begin
		self.drfpath = gpi_get_directory('RECIPE_OUTPUT_DIR') + path_sep() + gpi_datestr(/current)
		self->Log,"Outputting DRFs based on date to "+self.drfpath
	endif else begin
		self.drfpath = gpi_get_directory('RECIPE_OUTPUT_DIR') 
		self->Log, "Outputting DRFs to current working directory: "+self.drfpath
	endelse

	self->scan_templates
	self->update_available_primitives, self.reductiontypes[0], 1 ; needed before widget creation


	self.loadedRecipeFile = 'none' 

end

;------------------------------------------------
; set which widgets are currently displayed

pro drfgui::set_view_mode, mode
	wids = *self.widgets_for_modes

	; basic mode widgets are always shown. 
	; normal mode widgets
	for i=0,n_elements(wids.normal)-1 do widget_control, (wids.normal)[i], map=mode gt 1
	; advanced mode widgets
	for i=0,n_elements(wids.advanced)-1 do widget_control, (wids.advanced)[i], map=mode gt 2

end

;------------------------------------------------
; create the widgets
;
function drfgui::init_widgets, _extra=_Extra, session=session
    ;create base widget. 
    ;   Resize to be large on desktop monitors, or shrink to fit on laptops.
    ;-----------------------------------------
	DEBUG_SHOWFRAMES= gpi_get_setting('recipeeditor_enable_framedebug', default=0)
    
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

	self.xname='drfgui'
	title  = "GPI Recipe Editor"
	if keyword_set(session) then begin
           self.session=session
           title += " #"+strc(session)
    endif
    curr_sc = get_screen_size()
    title += ': Create Data Reduction Files'
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
   
	; MDP change 2010-01-25: let the X and Y size be set by default, based on
	; the nlines settings above
	;xsize=1200,ysize=920,group_leader=groupleader,/BASE_ALIGN_LEFT,/column, MBAR=bar)
	;xsize=1200<screensize[0],ysize=920<(screensize[1]-100),group_leader=groupleader,/BASE_ALIGN_LEFT,/column, MBAR=bar,bitmap=self.dirpro+path_sep()+'gpi.bmp',/tlb_size_events, /tlb_kill_request_events)
		
	self.top_base=top_base
	;create Menu

	tmp_struct = {cw_pdmenu_s, flags:0, name:''}
	top_menu_desc = [ $
                  {cw_pdmenu_s, 1, 'File'}, $ ; file menu;
                  {cw_pdmenu_s, 0, 'Open Recipe including Data...'}, $
                  {cw_pdmenu_s, 0, 'Open Recipe discarding data...'}, $
                  {cw_pdmenu_s, 0, 'Save Recipe as...'}, $
                  {cw_pdmenu_s, 0, 'Create Recipe Template and Save as...'}, $
                  {cw_pdmenu_s, 2, 'Quit Recipe Editor'}, $
                  {cw_pdmenu_s, 1, 'Options'}, $
                  {cw_pdmenu_s, 0, 'Rescan Templates...'}, $
                  {cw_pdmenu_s, 12, 'Basic View'}, $
                  {cw_pdmenu_s, 8, 'Normal View'}, $
                  {cw_pdmenu_s, 8, 'Advanced View'}, $
                  {cw_pdmenu_s, 12, 'Show default Primitives'}, $
                  {cw_pdmenu_s, 8, 'Show default + hidden Primitives'}, $
                  {cw_pdmenu_s, 10, 'Show all Primitives'}, $
                  {cw_pdmenu_s, 1, 'Help'}, $         ; help menu
                  {cw_pdmenu_s, 0, 'Help...'}, $
                  {cw_pdmenu_s, 2, 'About'} $
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
	sorttab=['obs. date/time','OBSID','alphabetic filename','file creation date']
	self.sortfileid = WIDGET_DROPLIST( top_base_filebutt_advanced, title='Sort data by:',  Value=sorttab,uvalue='sortmethod',resource_name='XmDroplistButton')
	drfbrowse = widget_button(top_base_filebutt_advanced,  $
							XOFFSET=174 ,SCR_XSIZE=80, ysize= 30 $; ,SCR_YSIZE=23  $
							,/ALIGN_CENTER ,VALUE='Sort data',uvalue='sortdata')                          
		
	top_baseident=widget_base(top_base,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES)
	; file name list widget
	fname=widget_list(top_baseident,xsize=106,scr_xsize=580, ysize=nlines_fname,$
			xoffset=10,yoffset=150,uvalue="FNAME", /TRACKING_EVENTS,resource_name='XmText')

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
;	drflabel=widget_label(top_baseborder3,Value='Log Path=           ')
;	self.logdir_id = WIDGET_TEXT(top_baseborder3, $
;				xsize=34,ysize=1,$
;				/editable,units=0 ,value=self.logdir)
;	drfbrowse = widget_button(top_baseborder3,  $
;						XOFFSET=174 ,SCR_XSIZE=75 ,SCR_YSIZE=23  $
;						,/ALIGN_CENTER ,VALUE='Change...',uvalue='logdir') 
;						
	base_radio = Widget_Base(top_right_advanced_base, UNAME='WID_BASE_diskc', COLUMN=1 ,/NONEXCLUSIVE, frame=0)
    self.relativepath_id = Widget_Button(base_radio, UNAME='RELATIVEPATH' ,/ALIGN_LEFT ,VALUE='Input/output directories written with relative environment variables',UVALUE='relativepath')
    widget_control, self.relativepath_id, /set_button
						
	top_baseborder=widget_base(top_right_advanced_base,ysize=7,units=0)
	top_baseborder4=widget_base(top_right_advanced_base,/BASE_ALIGN_LEFT,/row) 
	self.calibfiletab=['data closest date/time','most-recent','manual']
	self.calibfileid = WIDGET_DROPLIST( top_baseborder4, title='Find Calib. file:  ', frame=0, Value=self.calibfiletab,uvalue='calibfield',resource_name='XmDroplistButton')
	drfbrowse = widget_button(top_baseborder4,  $
						XOFFSET=174 ,SCR_XSIZE=155 $;,SCR_YSIZE=23  $
						,/ALIGN_CENTER ,VALUE='Resolve calib. filename',uvalue='resolvecalibfilename')                          
	;top_baseborder=widget_base(top_baseidentseq,ysize=7,units=0) ; MDP removed - this is not used anywhere.
	base_radio = Widget_Base(top_right_advanced_base, UNAME='WID_BASE_diskb', COLUMN=1 ,/NONEXCLUSIVE, frame=0)
	self.resolvetypeseq_id = Widget_Button(base_radio, UNAME='RESOLVETYPESEQBUTTON' ,/ALIGN_LEFT ,VALUE='Resolve type/seq. when adding file(s)',UVALUE='autoresolvetypeseq')
	;widget_control, self.resolvetypeseq_id, /set_button
	;*self.template_types=['ASTR - SPEC','ASTR - POL','CAL - SPEC','CAL - POL'] ;, 'On-Line Reduction'
	;top_baseborderz=widget_base(top_baseidentseq,/BASE_ALIGN_LEFT,/row)
	rowbase_template = widget_base(top_baseidentseq,row=1)
	self.typeid = WIDGET_DROPLIST( rowbase_template, title='Reduction type:    ', frame=0, Value=*self.template_types,uvalue='typefield',resource_name='XmDroplistButton')
	 self.seqid = WIDGET_DROPLIST( rowbase_template, title='Recipe Template:', frame=0, Value=['Simple Data-cube extraction','Calibrated Data-cube extraction','Calibrated Data-cube extraction, ADI reduction'],uvalue='seqfield',resource_name='XmDroplistButton')

	;one nice logo 
	button_image = READ_BMP(self.dirpro+path_sep()+'gpi.bmp', /RGB) 
	button_image = TRANSPOSE(button_image, [1,2,0]) 
	button = WIDGET_BUTTON(top_baseident, VALUE=button_image,  $
			SCR_XSIZE=100 ,SCR_YSIZE=95, sensitive=1 $
			 ,uvalue='About') 
	 
	 
	;create merge selector
	;-----------------------------------------
	top_basemodule=widget_base(top_base,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES)
	top_basemoduleleft=widget_base(top_basemodule,/BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
	top_basemoduleavailable=widget_base(top_basemoduleleft,/BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
	;data = ['Prim1', 'Prim2', 'Prim3', 'Prim4'] 
	data=transpose(*self.curr_mod_avai)


	; what colors to use for cell backgrounds? Alternate rows between
	; white and off-white pale blue
	self.table_BACKground_colors = ptr_new([[255,255,255],[240,240,255]])

 
	self.tableAvailable = WIDGET_TABLE(top_basemoduleavailable, VALUE=data,$;  $ ;/COLUMN_MAJOR, $ 
			COLUMN_LABELS=['Available Primitives'], /TRACKING_EVENTS,$
			xsize=1,ysize=50,scr_xsize=400,$  ;JM: ToDo: ysize as a function of #mod avail.
			/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =self.nlines_modules,COLUMN_WIDTHS=380,frame=1,uvalue='moduavai',/ALL_EVENTS,/CONTEXT_EVENTS , $
			background_color=rebin(*self.table_BACKground_colors,3,2,1)) ;/COLUMN_MAJOR,
	
	;top_baseborder=widget_base(top_basemoduleavailable,units=0,xsize=280,ysize=250,frame=1)
	lab = widget_label(top_basemoduleavailable, value="Primitive Description:")
	self.descr = WIDGET_TEXT(top_basemoduleavailable, $
		xsize=58,scr_xsize=400, ysize=3,/scroll, $; nlines_args,$
		value=(*self.curr_mod_avai)[0],units=0 ,/wrap, uval='mod_desc',/tracking_events)

	; Create the status log window 
	; widget ID gets stored into 'storage'
	lab = widget_label(top_basemoduleleft, value="History:")
	info=widget_text(top_basemoduleleft,/scroll, xsize=58,scr_xsize=400,ysize=nlines_status, /ALIGN_LEFT, uval="text_status",/tracking_events);xoffset=5,yoffset=5)


	top_basemoduleselected=widget_base(top_basemodule,/BASE_ALIGN_LEFT,/column)
	lab = widget_label(top_basemoduleselected, value="Define your recipe with available primitives:")
	self.tableSelected = WIDGET_TABLE(top_basemoduleselected, $; VALUE=data, $ ;/COLUMN_MAJOR, $ 
			COLUMN_LABELS=['Primitive Name','Calib. File Method','Resolved Filename'],/resizeable_columns, $
			xsize=3,ysize=20,uvalue='tableselected',value=(*self.currModSelec), /TRACKING_EVENTS,$
			/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =self.nlines_modules,scr_xsize=800,COLUMN_WIDTHS=[240,140,420],frame=1,/ALL_EVENTS,/CONTEXT_EVENTS, $
			background_color=rebin(*self.table_BACKground_colors,3,2*3,/sample)    ) ;,/COLUMN_MAJOR   
	base_primitive_args = widget_base(top_basemoduleselected,/BASE_ALIGN_LEFT,/column)
	lab = widget_label(base_primitive_args, value="Change values of parameters of the selected primitive [press Enter after each change. Validate new values with ENTER]:")             
	self.tableArgs = WIDGET_TABLE(base_primitive_args, $; VALUE=data, $ ;/COLUMN_MAJOR, $ 
			COLUMN_LABELS=['Parameter', 'Value','Description'], /resizeable_columns, $
			xsize=3,ysize=20, /TRACKING_EVENTS,$
			/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =nlines_args,scr_xsize=800,/COLUMN_MAJOR,COLUMN_WIDTHS=[180,180,440],frame=1,/EDITABLE,uvalue='tableargs' , $
			background_color=rebin(*self.table_BACKground_colors,3,2*3,/sample)    ) ;,/COLUMN_MAJOR                
		

	;;create execute and quit button
	;-----------------------------------------
	top_baseexec=widget_base(top_base,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES)
	button2=widget_button(top_baseexec,value="Save Recipe as...",uvalue="Save Recipe as...", /tracking_events)
	button2b=widget_button(top_baseexec,value="Queue last saved Recipe",uvalue="Queue", /tracking_events)
	button2c=widget_button(top_baseexec,value="Save Recipe and Drop in Queue",uvalue="Save&Queue", /tracking_events)
	spacer = widget_label(top_baseexec, value=' ', xsize=250)

	wid_bar_primitive_buttons = widget_base(top_baseexec,row=1, frame=DEBUG_SHOWFRAMES)
	button3=widget_button(wid_bar_primitive_buttons,value="Add primitive",uvalue="Add primitive", /tracking_events);, $
	button3=widget_button(wid_bar_primitive_buttons,value="Move primitive up",uvalue="Move primitive up", /tracking_events);, $
	button3=widget_button(wid_bar_primitive_buttons,value="Move primitive down",uvalue="Move primitive down", /tracking_events);, $
	button3=widget_button(wid_bar_primitive_buttons,value="Remove primitive",uvalue="Remove primitive", /tracking_events);, $
	spacer = widget_label(top_baseexec, value=' ', xsize=50)
	button3=widget_button(top_baseexec,value="Close Recipe Editor",uvalue="Quit Recipe Editor", /tracking_events, resource_name='red_button')

	self.textinfoid=widget_label(top_base,uvalue="textinfo",xsize=900,ysize=20,value='  ')
	;filename array and index
	;-----------------------------------------
	maxfilen=gpi_get_setting('max_files_per_recipe',default=200)
	filename=strarr(maxfilen)
	printname=strarr(maxfilen)
	datefile=lonarr(maxfilen)
	findex=0
	selindex=0
	splitptr=ptr_new({filename:filename,printname:printname,$
	  findex:findex,selindex:selindex,datefile:datefile, maxfilen:maxfilen})

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
    
    self->log, "This GUI helps you to create a customized DRF."
    self->log, "Add files to be processed and create a recipe"
    self->log, " with primitives to reduce data."

    self->changetype, 0 ; set to ASTR-SPEC type by default.

	self.widgets_for_modes = ptr_new( {normal: [base_primitive_args, wid_bar_primitive_buttons, top_basemoduleavailable], advanced: [top_base_filebutt_advanced, top_right_advanced_base]})


    return, top_base

end

;------------------------------------------------
PRO drfgui::post_init, drfname=drfname, _extra=_extra
    if keyword_set(drfname) then begin
        self->loaddrf, drfname, /log
    end
	self->set_view_mode, 2

end

;-----------------------
pro drfgui__define
    struct = {drfgui,   $
              ;typetab:strarr(5),$
              defoutputdir_id:0L,$
              deflogdir_id:0L,$
              defdrfpath_id:0L,$
              defqueuedir_id:0L,$ 
              drfpath :'',$ 
              drffilename :'',$  
              sortfileid :0L,$  
              sorttab:strarr(3),$       
              relativepath_id:0L,$
              definputcaldir_id:0L,$
              outputdir_id:0L,$
              calibfileid:0L,$
              calibfiletab:strarr(3), $
              resolvetypeseq_id:0L,$
              loadedRecipeFile:'',$
              deftemplatedir_id:0L,$
              filter:'',$ ;from data keywords
              ftimeobs:0.,$ ;from data keywords
              dispersr:'',$ ;from data keywords
              ftype:'',$ ;from data keywords
              fseq:'',$ ;from data keywords
              reductiontype:'',$
              tableAvailable: 0L,$
              descr: 0L,$
              tableSelected: 0L,$
              tableArgs: 0L,$
              nbcurrmod: 0L,$
              typeid: 0L,$
              seqid: 0L,$
              selecseq:-1,$
			  showhidden: 0, $
			  reductiontypes: ['SpectralScience','PolarimetricScience','Calibration','Testing'], $
              table_background_colors: ptr_new(), $ ; ptr to RGB triplets for table cell colors
              nlines_modules: 0, $                    ; how many lines to display modules on screen? (used in resize)
              PrimitiveInfo: ptr_new(), $
              curr_mod_avai: ptr_new(), $         ; list of available primitive names (strings) in current mode
              curr_mod_indsort: ptr_new(), $
              currModSelec: ptr_new(), $
              order: ptr_new(), $
              indarg: ptr_new(), $                ; ???
              nbmoduleSelec:  0L,$
              currModSelecParamTab: ptr_new(), $
              indmodtot2avail: ptr_new(), $
              textinfoid: 0L,$
              missingkeyw:0,$
              templates: ptr_new(), $       ; pointer to struct containing template info. See Scan_templates
              template_types: ptr_new(), $ ; pointer to list of available template types
			  drf_summary: ptr_new(), $		; name and filename etc for current DRF
			  widgets_for_modes: ptr_new(), $ ; widget IDs for basic/normal/advanced modes. see set_view_mode.
			  last_used_input_dir: '', $ ; save the most recently used directory. Start there again on subsequent file additions
			  INHERITS gpi_gui_base }


end
