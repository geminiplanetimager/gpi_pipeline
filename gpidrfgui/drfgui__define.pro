;-----------------------------------------
; drfgui__define.pro 
;
; select file to process, define modules & parameters to be executed and create DRF
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
;   Module arguments are stored in the ConfigDRS structure in memory. 
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
;================================================================================
; Helper and utility functions
;
;--------------------------------------------------------------------------------
;  Resolve a Calibration File name
function drfgui::resolvecalibfile, filter, extfile, timeobs, calibfieldind
    ;get list of file in inputcaldir
    ;TODO:compare with a pre-reduced list
    ;stop
    ;TODO:extract keyword if new calib file and put in the pre-reduced list (&check absent calib file)
    if (timeobs eq 0)|| (self.filter eq '') then begin
              file = DIALOG_PICKFILE(TITLE='Select CALIBRATION file: '+extfile , PATH=self.inputcaldir,/MUST_EXIST,FILTER = '*'+extfile+'*.*')
              return,file
    endif
    listextfilttimeobs=''
    listext = FILE_SEARCH(self.inputcaldir+path_sep()+'*'+extfile+'*', count=cc) 

     ;keep only current filter in calib file list:
    value=0;strarr(cc)
      for i=0, cc-1 do begin
      head=headfits( listext[i])
      valuef=strcompress(sxpar( Head, 'FILTER1',  COUNT=ck),/rem)
      if (ck gt 0)&&(valuef eq filter) then value=[value, i]
      endfor
      if n_elements(value) gt 1 then listextfilt=listext[value[1:n_elements(value)-1]]

    ;keep only current filter in calib file list:
    if (timeobs ne '') && (n_elements(listextfilt) gt 0) then begin
        value=fltarr(n_elements(listextfilt))
        for i=0, n_elements(listextfilt)-1 do begin
            head=headfits( listextfilt[i])
            if calibfieldind ne 1 then $
            value[i]=strcompress(sxpar( Head, 'TIMEOBS',  COUNT=ck),/rem) $;put in JD
            else value[i]=(file_info(listextfilt[i])).mtime
        endfor
        if calibfieldind ne 1 then $
           indsorttimeobs= sort(abs(timeobs-value)) $
        else indsorttimeobs= reverse(sort(value)) 
        listextfilttimeobs=listextfilt[indsorttimeobs[0]]
    endif
    
    return,listextfilttimeobs
end

;-----------------------------------
; Look up a keyword value
function drfgui::resolvekeyword, filenames, cindex, keyw, date=date, time=time
    ; Given a list of filenames and a FITS header keyword, 
    ; return the list of UNIQUE VALUES of that keyword in those files' headers.
    ;
    ; Does **not** return all instances of the keywords if there are repeats. 


    value=strarr(cindex)
    for i=0, cindex-1 do begin ; get requested keyword for all N files
        head=headfits( filenames[i])
        value[i]=strcompress(sxpar( Head, keyw,  COUNT=cc),/rem)
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
function drfgui::validkeyword, file, cindex, keyw, requiredvalue,storage,needalertdialog=needalertdialog
      value=strarr(cindex)
      matchedvalue=intarr(cindex)
      ok=1
	  for i=0, cindex-1 do begin
		  head=headfits( file[i])
		  value[i]=strcompress(sxpar( Head, keyw,  COUNT=cc),/rem)
		  if cc eq 0 then begin
			self->log,'Absent '+keyw+' keyword for data: '+file(i)
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
		  ;if ok ne 1 then self->log, 'File '+file[i]+' is missing required '+keyw+' keyword!'
	  endfor  
 
    ;if (ok eq 1) then self->log,'Validity of '+keyw+' keywords: VALID'
	
      
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
    head=headfits( filename)
	; FIXME check for invalid or missing keywords here!
	obsstruct = {gpi_obs, $
				OBSCLASS: strc(sxpar(head, 'OBSCLASS', count=ct0)), $
				obstype:  strc(sxpar(head, 'obstype',  count=ct1)), $
				OBSID:    strc(sxpar(head, 'OBSID',    count=ct2)), $
				filter:   strc(sxpar(head, 'FILTER',   count=ct3)), $
				DISPERSR: strc(sxpar(head, 'DISPERSR', count=ct4)), $
				OCCULTER: strc(sxpar(head, 'OCCULTER', count=ct5)), $
				LYOT:     strc(sxpar(head, 'LYOTMASK',     count=ct6)), $
				ITIME:    sxpar(head, 'ITIME',    count=ct7), $
				EXPTIME:    sxpar(head, 'EXPTIME',    count=ct7b), $
				OBJECT:   strc(sxpar(head, 'OBJECT',   count=ct8)), $
				valid: 0}
	if ct0+ct1+ct2+ct3+ct4+ct5+ct6+ct7+ct8 lt 9 then self.missingkeyw=1 else obsstruct.valid=1
	;give some info on missing keyw:
	vec=[ct0,ct1,ct2,ct3,ct4,ct5,ct6,ct7,ct8]
	keytab=['OBSCLASS','obstype','OBSID', 'FILTER','DISPERSR','OCCULTER','LYOT','ITIME', 'OBJECT']
	indzero=where(vec eq 0, cc)
	if cc gt 0 then self->Log, 'Missing keyword(s):'+keytab[indzero]
	
	
	return, obsstruct



end

;--------------------------------------------------------------------------------
pro drfgui::extractparam, modnum 

    *self.indarg=where(   ((*self.ConfigDRS).argmodnum) eq ([(*self.indmodtot2avail)[(*self.curr_mod_indsort)[modnum]]]+1)[0], carg)
end

;-----------------------------------------
function drfgui::get_input_dir
    case getenv('GPI_RAW_DATA_DIR') of
;            'GEM': $
;                defdir = '/gpidata/rawfile/'+storage.group+path_sep()+storage.proj
;            'HOME': $
;                defdir = gpirootdir(storage.group,storage.proj)+'/gpidata/raw'
    '': $
        defdir = self.inputdir ;gpirootdir(storage.group,storage.proj)+'/gpidata/raw'
    else: $
            defdir = getenv('GPI_RAW_DATA_DIR') ;gpirootdir(storage.group,storage.proj)+'/gpidata/raw'
    endcase

    return, defdir

end

;------------------------------------------------
pro drfgui::log, logtext
	addmsg, self.widget_log, logtext

end


;================================================================================
; Functions for dealing with templates and DRFs

;-------------------------------------
; Parse the DRS Config XML file 
; and update my knowledge of available modules
;
; This function returns an object reference; be sure to destroy it when you're
; done
function drfgui::get_configParser

    if self.config_file eq '' then begin
        FindPro, 'make_drsconfigxml', dirlist=dirlist
        if getenv('GPI_CONFIG_FILE') ne '' then self.config_file=getenv('GPI_CONFIG_FILE') $
        else self.config_file=dirlist[0]+"DRSConfig.xml"

    endif
    if ~file_test(self.config_file) then message, 'ERROR: Cannot find DRS Config File! Check $GPI_CONFIG_FILE environment variable'

    ConfigParser = OBJ_NEW('gpiDRSConfigParser')
    ConfigParser -> ParseFile, self.config_file 

    if ~ptr_valid(self.ConfigDRS) then self.ConfigDRS = ptr_new(ConfigParser->getidlfunc())

    return, ConfigParser

end


;--------------------------------------------------------------------------------
; Change the current template
;     - look up the filename corresponding to the requested Type and Sequence
;     - load the DRF at that filename
pro drfgui::change_current_template, typestring,seqnum, notemplate=notemplate

    if self.selecseq eq seqnum then return ; do nothing for no change
    self.selecseq=seqnum
    
    wm = where((*self.templates).type eq typestring, mct)
    if mct eq 0 then message, 'Requested reduction type "'+typestring+'" is invalid/unknown. Cannot load any DRFs!'

    chosen_template = wm[seqnum]

    widget_control, self.seqid,SET_DROPLIST_SELECT=seqnum

    print, "Chosen template filename:"+((*self.templates)[chosen_template]).filename

    if ~(keyword_set(notemplate)) then begin
        ;self.loadedDRF = ((*self.templates)[chosen_template]).filename
        self->loadDRF, ((*self.templates)[chosen_template]).filename,   /nodata
    endif

end


;--------------------------------------------------------------------------------
;  Change the list of Available Modules to match the currently selected
;  Reduction Type
;
;  ARGUMENTS:
;          typestr       string, name of the mode type to use
;          seqval        integer, which sequence in that type to use.
;
pro drfgui::update_available_modules, typestr, seqval

    type=(*self.ConfigDRS).type ; list of type for each module

    if strmatch(typestr, 'On-Line Reduction') then begin
        if seqval eq 1 then typetab=['ASTR','SPEC']
        if seqval eq 2 then typetab=['ASTR','POL']
        if seqval eq 3 then typetab=['CAL','SPEC']
    endif else begin
        typetab = strcompress(STRSPLIT( typestr ,'-' , /EXTRACT ),/rem)
    endelse 

    ; build a list of all available modules
    ; the logic here is somewhat tricky and unclear.
    indall=where(strmatch(type,'*ALL*',/fold_case),cm)          ; find ones that are 'all'
    indastr=where(strmatch(type,'*'+typetab[0]+'*',/fold_case),cm)  ; find ones that match the first typestr
    indspec=where(strmatch(type,'*'+typetab[1]+'*',/fold_case),cm)  ; find ones that match the second typestr
    if typetab[1] eq 'SPEC' then comp='POL' else comp='SPEC'
    indpol=indall[where(strmatch(type[indall],'*'+comp+'*',/fold_case),cm)] ; find ones in ALL that are also in the complementary set

	new_modules = [intersect(indall,indpol,/xor_flag),intersect(indastr,indspec)]

	if ~keyword_set(self.showhidden) then begin
		; now let's ignore any which were hidden (i.e. only show the visible ones)
		ind_visible= where( ~strmatch(type, "*HIDDEN*",/fold_case), cvisible)
		new_modules = intersect(new_modules , ind_visible)
	endif

    *self.indmodtot2avail=new_modules
    *self.indmodtot2avail=(*self.indmodtot2avail)[where(*self.indmodtot2avail ne -1)]
    cm=n_elements(*self.indmodtot2avail)

    if cm ne 0 then begin
        self.nbcurrmod=cm
        *self.curr_mod_avai=strarr(cm)

        for i=0,cm-1 do begin
            (*self.curr_mod_avai)[i]=((*self.ConfigDRS).names)[(*self.indmodtot2avail)[i]]
            *self.indarg=where(   ((*self.ConfigDRS).argmodnum) eq ([(*self.indmodtot2avail)[i]]+1)[0], carg)
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


    ;;standard recipes
    ;if (self.typeid eq 0)||(strmatch(typeval, 'On-Line Reduction')) then selectype=0 else selectype=widget_info(self.typeid,/DROPLIST_SELECT)

    (*self.currModSelec)=strarr(5)
end    

;--------------------------------------------------------------------------------
; Update the list of modules selected for the current DRF. 
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
      (*self.currModSelecParamTab)[*,0]=((*self.ConfigDRS).argname)[[*self.indarg]]
      (*self.currModSelecParamTab)[*,1]=((*self.ConfigDRS).argdefault)[[*self.indarg]]
      (*self.currModSelecParamTab)[*,2]=((*self.ConfigDRS).argdesc)[[*self.indarg]]
      endif
       widget_control,   self.tableArgs,  set_value=(*self.currModSelecParamTab)
              
end



;--------------------------------------------------------------------------------
; Read in the available templates from the GPI_TEMPLATE_DRFS directory

PRO  drfgui::Scan_Templates


    ptr_free, self.templates


    message,/info, "Scanning for templates in "+self.tempdrfdir
    template_file_list = file_search(self.tempdrfdir + path_sep() + "*.xml")
    


    tmp = {filename:'', type: '', name: ''}
    templates = replicate(tmp, n_elements(template_file_list))

    ConfigParser = self->get_configParser()
    Parser = OBJ_NEW('gpiDRFParser')
    for i=0,n_elements(template_file_list)-1 do begin
        message,/info, 'scanning '+template_file_list[i]
        Parser ->ParseFile, template_file_list[i],  ConfigParser,/silent
        templates[i] = Parser->get_summary()
    endfor
    obj_destroy, Parser
    obj_destroy, configParser

    types = uniqvals(templates.type)

    ; What order should the template types be listed in, in the GUI?
    type_order = [ "ASTR - SPEC", "ASTR - POL", "CAL - SPEC", "CAL - POL", "On-Line Reduction" ]
    
    ; FIXME check if there are any new types not specified in the above list but
    ; present in the templates?
    

    ; conveniently, these filenames will already be in alphabetical order from
    ; the above.
    print, "----- Templates located: ----- "
    for it=0, n_elements(type_order)-1 do begin
        print, " -- "+type_order[it]+" -- "
        wm = where(templates.type eq type_order[it], mct)
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

    wm = where((*self.templates).type eq self.reductiontype, mct)
    if mct eq 0 then message, "Invalid template type, or no known templates for that type: "+self.reductiontype

    widget_control, self.seqid, set_value= ((*self.templates)[wm]).name

    self->update_available_modules, self.reductiontype, 1

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
    	widget_control,self.drfbase,get_uvalue=storage  
        message, /info, "File "+filename+" does not exist!"
      	self->log,"File "+filename+" does not exist!"
      	self->log,"Use Save DRF button"
      	return
    endif 

    ; Make sure the filename ends with '.waiting.xml'
    if strpos(filename,".waiting.xml") eq -1 then begin
        newfilename = file_basename(filename,".xml")+".waiting.xml"
    endif else begin
        newfilename = file_basename(filename)
    endelse

    FILE_COPY, filename, self.queuepath+path_sep()+newfilename,/overwrite
    self->log,'Queued '+newfilename

end



; simple wrapper to call object routine
PRO drfgui_event, ev
    widget_control,ev.top,get_uvalue=storage
	if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
end
;-----------------------------------------
; actual event handler: 
pro drfgui::event,ev

    ;get type of event
    widget_control,ev.id,get_uvalue=uval

    ;get storage
    widget_control,ev.top,get_uvalue=storage

    if size(uval,/TNAME) eq 'STRUCT' then begin
        ; TLB event, either resize or kill_request
        print, 'DRF GUI TLB event'
        case tag_names(ev, /structure_name) of

        'WIDGET_KILL_REQUEST': begin ; kill request
            if confirm(group=ev.top,message='Are you sure you want to close the DRF GUI?',$
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
              'moduavai':textinfo='Left-click for Module Desciption | Right-click to add the selected module to the current DRF.'
              'tableselected':textinfo='Left-click to see argument parameters of the module | Right-click to remove the selected module from the current DRF.'
              'tableargs':textinfo='Left-click on Value cell to change the value. Press Enter to validate.'
              'mod_desc':textinfo='Click on a module in the Available Modules list to display its description here.'
              'text_status':textinfo='Status log message display window.'
              'ADDFILE': textinfo='Click to add files to current input list'
              'WILDCARD': textinfo='Click to add files to input list using a wildcard ("*.fits" etc)'
              'REMOVE': textinfo='Click to remove currently highlighted file from the input list'
              'REMOVEALL': textinfo='Click to remove all files from the input list'
              'Remove module': textinfo='Remove the selected module from the execution list'
              'Add module': textinfo='Add the selected module from "Available Modules" into the execution list'
              "Create": textinfo='Save DRF to a filename of your choosing'
              "Drop": textinfo="Queue & execute the last saved DRF"
              'Save&Drop': textinfo="Save the file, then queue it"
              'QUIT': textinfo="Close and exit this program"
              "Move module up": textinfo='Move the currently-selected module one position earlier in the execution list'
              "Move module down": textinfo='Move the currently-selected module one position later in the execution list'
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
                indcalib=where(((*self.ConfigDRS).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)
                if ccf ne 0 then (*self.currModSelec)[2,ii]=((*self.ConfigDRS).argdefault)[[(*self.indarg)[indcalib]]]
                if (ccf ne 0)  then begin ;&& (self.filter ne '')
                    resolvedcalibfile=self->resolvecalibfile( self.filter, ((*self.ConfigDRS).argtype)[[(*self.indarg)[indcalib]]],time,calibfieldind)
                    argtab=((*self.ConfigDRS).argdefault)
                    argtab[(*self.indarg)[indcalib]]=resolvedcalibfile
                    ((*self.ConfigDRS).argdefault)=argtab
                    ;((*self.ConfigDRS).argdefault)[[(*self.indarg)[indcalib]]]=resolvedcalibfile
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
               currdescs = ((*self.ConfigDRS).comment)[(*self.indmodtot2avail)[(*self.curr_mod_indsort)]]
               ; and get the one description corresponding to the selected
               ; module:
               indselected=selection[1] < (n_elements(currdescs)-1)
               comment=currdescs[indselected]
               if comment eq '' then comment=(*self.curr_mod_avai)[indselected]

               widget_control,   self.descr,  set_value=comment
        ENDIF 
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_CONTEXT') THEN BEGIN  ;RIGHT CLICK
			self->addmodule
     	ENDIF 

    end
	'Add module': self->AddModule
	'Remove module': self->RemoveModule
    'tableselected':begin     ; Table of currently selected modules (i.e. those in the DRF) 
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CELL_SEL') THEN BEGIN  ;LEFT CLICK
               selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 

               ;update arguments table
               indselected=selection[1]
               if indselected lt self.nbmoduleSelec then begin
                   self->extractparam, float((*self.currModSelec)[4,indselected])
    
                  *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
                  if (*self.indarg)[0] ne -1 then begin
                      (*self.currModSelecParamTab)[*,0]=((*self.ConfigDRS).argname)[[*self.indarg]]
                      (*self.currModSelecParamTab)[*,1]=((*self.ConfigDRS).argdefault)[[*self.indarg]]
                      (*self.currModSelecParamTab)[*,2]=((*self.ConfigDRS).argdesc)[[*self.indarg]]
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
                        indcalib=where(((*self.ConfigDRS).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)
                        argtab=((*self.ConfigDRS).argdefault)
                        argtab[(*self.indarg)[indcalib]]=resolvedcalibfile
                        ((*self.ConfigDRS).argdefault)=argtab
                        (*self.currModSelecParamTab)[indcal,1]=resolvedcalibfile
                    endif else begin
                    if (*self.currModSelec)[1,selection[1]] eq 'Auto' then begin
                       (*self.currModSelec)[1,selection[1]]='Manual'
                       (*self.currModSelec)[2,selection[1]]='Click here to select a calibration file'
                       resolvedcalibfile=''
                        indcal=where((*self.currModSelecParamTab)[*,0] eq 'CalibrationFile',cf)
                        indcalib=where(((*self.ConfigDRS).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)
                        argtab=((*self.ConfigDRS).argdefault)
                        argtab[(*self.indarg)[indcalib]]=resolvedcalibfile
                        ((*self.ConfigDRS).argdefault)=argtab
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
                     indcalib=where(((*self.ConfigDRS).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)
                     if (ccf ne 0)  then begin ;&& (self.filter ne '')
                        extfile=((*self.ConfigDRS).argtype)[[(*self.indarg)[indcalib]]]
                        resolvedcalibfile = DIALOG_PICKFILE(TITLE='Select CALIBRATION file: '+extfile , PATH=self.inputcaldir,/MUST_EXIST,FILTER = '*'+extfile+'*.*')
                                      argtab=((*self.ConfigDRS).argdefault)
                                      argtab[(*self.indarg)[indcalib]]=resolvedcalibfile
                                      ((*self.ConfigDRS).argdefault)=argtab
                        (*self.currModSelecParamTab)[indcal,1]=resolvedcalibfile
                        ;((*self.ConfigDRS).argdefault)[[(*self.indarg)[indcalib]]]=resolvedcalibfile
                        (*self.currModSelec)[2,selection[1]]=resolvedcalibfile
                        (*self.currModSelec)[1,selection[1]] = 'Manual'
                     endif
                  endif
                  widget_control,   self.tableSelected,  set_value=(*self.currModSelec)[0:2,*]
                  widget_control,   self.tableArgs,  set_value=(*self.currModSelecParamTab)
                 endif
               endif               
        ENDIF 
        IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_CONTEXT') THEN BEGIN  ;RIGHT CLICK. delete currently selected module from list
			self->RemoveModule              
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
            argtabtype=((*self.ConfigDRS).argtype)
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
            if (strcmp(typeName,type,/fold)) then typeflag=1 else typeflag=0

            ;;verify user-value: range 
            if (strcmp('string',type,/fold) ne 1) && (strcmp('string',typeName,/fold) ne 1) && (type ne '') then begin
              argtabrange=((*self.ConfigDRS).argrange)
              range=argtabrange[(*self.indarg)[selected_cell[1]]]
              ranges=strsplit(range,'[,]',/extract)
              if (float(ranges[0]) le float(selection_value[0])) && (float(ranges[0]) le float(selection_value[0])) then rangeflag=1 else rangeflag=0
            endif
            if (typeflag eq 0) || (rangeflag eq 0) then begin
              err=''
              if (typeflag eq 0) then err+='type '
              if (rangeflag eq 0) then err+='range '
              self->log,'Sorry, you entered a value with wrong: '+err
              ;stop
            endif else begin 
              ;;
              argtab=((*self.ConfigDRS).argdefault)
              argtab[(*self.indarg)[selected_cell[1]]]=selection_value[0]
              ((*self.ConfigDRS).argdefault)=argtab
              ;is it a change of the calibrationfile?
              argname=((*self.ConfigDRS).argname)
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

		defdir = self->get_input_dir()

        ;name=fileselectm(group_leader=ev.top,path=defdir,/fullpath)
        if (file[n_elements(file)-1] eq '') then begin
            result=dialog_pickfile(path=defdir,/multiple,/must_exist,$
                title='Select Raw Data File(s)', filter=['*.fits','*.fits.gz'])
        endif else begin
            self->log,'Sorry, maximum number of files reached. You cannot add any additional files/directories.'
            result = ''
        endelse

        result = strtrim(result,2)
        for i=0,n_elements(result)-1 do begin   ; Check for duplicate
            if (total(file eq result[i]) ne 0) then result[i] = ''
        endfor
        for i=0,n_elements(result)-1 do begin
            tmp = strsplit(result[i],'.',/extract)
            ;if (n_elements(tmp) lt 5) then result[i] = ''
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
                tmp = strsplit(result[i],path_sep(),/extract)
                pfile[cindex+i] = tmp[n_elements(tmp)-1]+'    '
            endfor

            self.inputdir=strjoin(tmp[0:n_elements(tmp)-2],path_sep())
            if !VERSION.OS_FAMILY ne 'Windows' then self.inputdir = "/"+self.inputdir 
          
            

            cindex = cindex+n_elements(result)
            (*storage.splitptr).selindex = max([0,cindex-1])
            (*storage.splitptr).findex = cindex
            (*storage.splitptr).filename = file
            (*storage.splitptr).printname = pfile
            (*storage.splitptr).datefile = datefile 

            ;;TEST DATA SANITY
            ;;ARE THEY VALID  GEMINI-GPI-IFS DATA?
            validtelescop=self->validkeyword( file, cindex,'TELESCOP','Gemini',storage)
            validinstrum=self->validkeyword( file, cindex,'INSTRUME','GPI',storage)
            validinstrsub=self->validkeyword( file, cindex,'INSTRSUB','IFS',storage)     
            ;;DATA HEALTH
            validhealth=self->validkeyword( file, cindex,'GPIHEALTH','good',storage)
            validstate=self->validkeyword( file, cindex,'GPISTATE','good',storage)
            validrawgemqa=self->validkeyword( file, cindex,'RAWGEMQA','good',storage)


            ;; RESOLVE FILTER
            ;stop  
            self.filter=self->resolvekeyword( file, cindex,'filter1')

            ;TODO DISPLAY RESOLVED FILTER
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
            ;self.ftype=self->resolvekeyword( file, cindex,'FILTER2')
            self.fmod=self->resolvekeyword( file, cindex,'DISPERSR')
            ;;RESOLVE TYPE
            self.ftype=self->resolvekeyword( file, cindex,'OBSTYPE')
            ;;RESOLVE CLASS
            ;self.fseq=resolvekeyword( file, cindex,'OBSCLASS')

            isresolvebuttonset=widget_info(self.resolvetypeseq_id,/button_set)
            if isresolvebuttonset then begin
                detectype=0
                if strmatch(self.fmod,'pol*',/fold) && strmatch(self.ftype,'obj*',/fold) then detectype=2
                if strmatch(self.fmod,'pol*',/fold) && ~strmatch(self.ftype,'obj*',/fold) then detectype=4
                if strmatch(self.fmod,'spec*',/fold) && strmatch(self.ftype,'obj*',/fold) then detectype=1
                if strmatch(self.fmod,'spec*',/fold) && ~strmatch(self.ftype,'obj*',/fold) then detectype=3
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
                    self->changetype, detectype-1;,/notemplate
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
		result = DIALOG_PICKFILE(TITLE='Select a OUTPUT Directory', /DIRECTORY,/MUST_EXIST)
		if result ne '' then begin
			self.outputdir = result
			widget_control, self.outputdir_id, set_value=self.outputdir
			self->log,'Output Directory changed to:'+self.outputdir
		endif
    end
    'logpath': begin
		result= DIALOG_PICKFILE(TITLE='Select a LOG Path', /DIRECTORY,/MUST_EXIST)
		if result ne '' then begin
			self.logpath =result
			widget_control, self.logpath_id, set_value=self.logpath
			self->log,'Log path changed to: '+self.logpath
		endif
    end
    'Create'    : begin
        file = (*storage.splitptr).filename
        self->savedrf, file,storage
    end
    'CreateTemplate'  : begin
        file = (*storage.splitptr).filename
        self->savedrf,file,storage, /template
    end
    'Drop'  : begin
        if self.drffilename ne '' then begin
              self->queue, self.drfpath+path_sep()+self.drffilename
        endif else begin
              self->log,'Sorry, save DRF before dropping or use "Save & Drop" button.'
        endelse
    end
    'Save&Drop'  : begin
        file = (*storage.splitptr).filename
        void = where(file ne '',count)
        if count ne 0 then begin
            self->savedrf,file,storage,/nopickfile
            self->queue, self.drfpath+self.drffilename
        endif else begin
            self->log,'Fits list empty'
        endelse
    end
    'QUIT'    : begin
        if confirm(group=ev.top,message='Are you sure you want to close the DRF GUI?',$
            label0='Cancel',label1='Close') then obj_destroy, self
    end
    'LOADDRF':begin
        ;self.loadedDRF = DIALOG_PICKFILE(TITLE='Select a Data Reduction File (DRF)', filter='*.xml',/MUST_EXIST,path=self.drfpath)
        newDRF =  DIALOG_PICKFILE(TITLE='Select a Data Reduction File (DRF)', filter='*.xml',/MUST_EXIST,path=self.drfpath)
        if newDRF ne '' then begin
            self->loaddrf, newDRF,  /nodata, /log
        endif
    end
    'LOADDRFWITHDATA':begin
       ;self.loadedDRF = DIALOG_PICKFILE(TITLE='Select a Data Reduction File (DRF)', filter='*.xml',/MUST_EXIST,path=self.drfpath)
        newDRF =  DIALOG_PICKFILE(TITLE='Select a Data Reduction File (DRF)', filter='*.xml',/MUST_EXIST,path=self.drfpath)
        if newDRF ne '' then begin
            self->loaddrf, newDRF
            self->log,'Output Directory :'+self.outputdir
            self->log,'Log path : '+self.logpath
            self->log,'DRF:'+self.loadedDRF+' has been succesfully loaded.'
        endif
    end
    'rescan': begin
        self->scan_templates
        self->update_available_modules, self.reductiontype, 1 ; needed before widget creation
    end
    'Move module up': begin
          selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
          ind_selected=selection[1]
          if ind_selected ne 0 then begin ; can't move up
              new_indices = indgen(self.nbmoduleSelec)
              new_indices[ind_selected-1:ind_selected] = reverse(new_indices[ind_selected-1:ind_selected])
              self->update_selected_modules, new_indices, new_selected=ind_selected-1
          endif
    end
    'Move module down': begin
          selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
          ind_selected=selection[1]
          if ind_selected ne self.nbmoduleSelec-1 then begin ; can't move up
              new_indices = indgen(self.nbmoduleSelec)
              new_indices[ind_selected:ind_selected+1] = reverse(new_indices[ind_selected:ind_selected+1])
              self->update_selected_modules, new_indices, new_selected=ind_selected+1
          endif
    
    end
	'showhidden': begin
		self.showhidden = ~ self.showhidden
		;self->changetype, where(*self.template_types eq self.reductiontype),/force_update

    	self->update_available_modules, self.reductiontype, 1

	end
 
    'about': begin
      tmpstr=['GPI DRF-GUI $Revision: 1.22 $ - GPI 3d data-reduction package', $
              '', $
              'Copyright _,_ by the University of Montreal ' + $
               '(UdeM), Canada', $
              '', $
              'Programming (report bugs to):', $
              '  Jerome Maire (UdeM, maire@astro.umontreal.ca)', $
              '  Marshall Perrin (UCLA)', $
              '', $
              'Documentation:', $
              '  Marshall Perrin (UCLA)', $
              '  Jerome Maire (UdeM)', $
              '', $
              'This software has been tested by:', $
              '  Jeff Chilcote, Quinn Konopacky ', $
              '', $
              'Acknowledgements:', $
              '  ', $
              '    which have helped improve GPI DRF-GUI', $
              '  ', $
              ' ', $
              '', $
              'The project web site is:', $
              '  ', $
              '', $
              'When using this code, please cite the following paper:', $
              '  Maire J., Perrin M. D., et al SPIE 2010' + $
              '', $
              '']

        ret=dialog_message(tmpstr,/information,/center,dialog_parent=ev.top)
    end ;; case: 'about'
    
    
    else: print, 'Unknown event: '+uval
endcase

end
;--------------------------------------

PRO drfgui::removemodule
              selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
              indselected=selection[1]
			  if indselected eq -1 then return
              if (indselected ge 0) AND  (indselected lt self.nbmoduleSelec) AND (self.nbmoduleSelec gt 1) then begin
                  indices = indgen(self.nbmoduleSelec)
                  new_indices = indices[where(indices ne indselected)]
					self->log, "Removed module "+(*self.currModSelec)[0,indselected] ; print this out -before- updating the list

                  ;stop
                  self->update_selected_modules, new_indices, new_selected=indselected

                   
              endif     

end



;--------------------------------------


PRO drfgui::addmodule
            ; Add new module to the list.
              selection = WIDGET_INFO((self.tableAvailable), /TABLE_SELECT) 
              indselected=selection(1)
			  if indselected eq -1 then return ; nothing selected

              ; Figure out where to insert the new module into the list, based
              ; on comparing the 'order' parameters.
              order=((*self.ConfigDRS).order)[(*self.indmodtot2avail)[(*self.curr_mod_indsort)[indselected]]]
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
                    if insertorder eq 0 then (*self.currModSelec)=([[[(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)]],[(*self.currModSelec)]])
                    if insertorder eq self.nbmoduleSelec then (*self.currModSelec)=([[(*self.currModSelec)],[[(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)]]])
                    if (insertorder ne 0) AND (insertorder ne self.nbmoduleSelec) then (*self.currModSelec)=([[(*self.currModSelec)[*,0:insertorder-1]],[[(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)]],[(*self.currModSelec)[*,insertorder:self.nbmoduleSelec-1]]])
                endelse
				self->Log, "Inserted module '"+(*self.curr_mod_avai)[indselected]+"' into position "+strc(insertorder)
                self.nbmoduleSelec+=1
                (*self.order)=(*self.currModSelec)[3,*]
                ;does this module need calibration file?
                self->extractparam, indselected
                *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
              if *self.indarg ne [-1] then begin
                   indcalib=where(((*self.ConfigDRS).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)
                     if ccf ne 0 then (*self.currModSelec)[2,insertorder]=((*self.ConfigDRS).argdefault)[[(*self.indarg)[indcalib]]]
                     if ccf ne 0 then begin
                        if strmatch((*self.currModSelec)[2,insertorder], 'AUTOMATIC') then $
                        (*self.currModSelec)[1,insertorder]='Auto' else $
                        (*self.currModSelec)[1,insertorder]='Manual'
                     endif
                    
              (*self.currModSelecParamTab)[*,0]=((*self.ConfigDRS).argname)[[*self.indarg]]
              (*self.currModSelecParamTab)[*,1]=((*self.ConfigDRS).argdefault)[[*self.indarg]]
              (*self.currModSelecParamTab)[*,2]=((*self.ConfigDRS).argdesc)[[*self.indarg]]
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
                        if (insertorder ne 0) AND (insertorder ne self.nbmoduleSelec) then (*self.currModSelec)=([[(*self.currModSelec)[*,0:insertorder-1]],[[(*self.curr_mod_avai)[indselected],'','',order,strc(indselected)]],[(*self.currModSelec)[*,insertorder:self.nbmoduleSelec-1]]])
                        self.nbmoduleSelec+=1
                        (*self.order)=(*self.currModSelec)[3,*]                        
                    endif
                endif
              
              
            widget_control,   self.tableSelected,  set_value=(*self.currModSelec)[0:2,*], SET_TABLE_SELECT =[-1,insertorder,-1,insertorder]
            widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,0]
            widget_control,   self.tableArgs,  set_value=(*self.currModSelecParamTab)
 
end


;--------------------------------------
; Save a DRF to a file on disk.
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
      drfpath=self.tempdrfdir
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
      self.drffilename = self.loadedDRF ;to check
    endif else begin     
      caldat,systime(/julian),month,day,year, hour,minute,second
      datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
      hourstr = string(hour,minute,second,format='(i2.2,i2.2,i2.2)')  
      self.drffilename=datestr+'_'+hourstr+'_drf.waiting.xml'
    endelse

    ;get drf filename and set drfpath:
    if ~keyword_set(nopickfile) then begin
        newdrffilename = DIALOG_PICKFILE(TITLE='Save Data Reduction File (DRF) as', /write,/overwrite, filter='*.xml',file=self.drffilename,path=drfpath, get_path=newdrfpath)
        if newdrffilename eq "" then begin
			self->Log, "User cancelled save; doing nothing."
			return ; user cancelled the save as dialog, so don't save anything.
		endif
        self.drfpath  = newdrfpath ; MDP change - update the default directory to now match whatever the user selected in the dialog box.
    endif else newdrffilename = self.drffilename
    
    if (self.nbmoduleSelec ne '') && (newdrffilename ne '') then begin
          self.drffilename = file_basename(newdrffilename)

        self->log,'Now writing DRF...';+ self.drfpath+path_sep()+self.drffilename
        
        message,/info, "Writing to "+self.drfpath+path_sep()+self.drffilename 
        OpenW, lun, self.drfpath+path_sep()+self.drffilename, /Get_Lun
        PrintF, lun, '<?xml version="1.0" encoding="UTF-8"?>' 
     
           
        if selectype eq 4 then begin
            PrintF, lun, '<DRF LogPath="'+self.logpath+'" ReductionType="OnLine">'
        endif else begin
            PrintF, lun, '<DRF LogPath="'+self.logpath+'" ReductionType="'+(*self.template_types)[selectype] +'">'
        endelse

         PrintF, lun, '<dataset InputDir="'+self.inputdir+'" Name="" OutputDir="'+self.outputdir+'">' 
         ;PrintF, lun, '<dataset InputDir="'+''+'" Name="" OutputDir="'+self.outputdir+'">'
     
        FOR j=0,N_Elements(file)-1 DO BEGIN
            tmp = strsplit(file[j],path_sep(),/extract)
            PrintF, lun, '   <fits FileName="' + tmp[n_elements(tmp)-1] + '" />'
            ;PrintF, lun, '   <fits FileName="' + file[j] + '" />'
        ENDFOR
    
        PrintF, lun, '</dataset>'
        FOR j=0,self.nbmoduleSelec-1 DO BEGIN
            self->extractparam, float((*self.currModSelec)[4,j])
            strarg=''
            if (*self.indarg)[0] ne -1 then begin
                  argn=((*self.ConfigDRS).argname)[[*self.indarg]]
                  argd=((*self.ConfigDRS).argdefault)[[*self.indarg]]
                  for i=0,n_elements(argn)-1 do begin
                      strarg+=argn[i]+'="'+argd[i]+'" '
                  endfor
            endif
              
        
            PrintF, lun, '<module name="' + (*self.currModSelec)[0,j] + '" '+ strarg +'/>'
        ENDFOR
        PrintF, lun, '</DRF>'
        Free_Lun, lun
        self->log,'Saved  '+self.drffilename
        
        ;display last paramtab
        indselected=self.nbmoduleSelec-1
        self->extractparam, float((*self.currModSelec)[4,indselected])    
        *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
        if (*self.indarg)[0] ne -1 then begin
                      (*self.currModSelecParamTab)[*,0]=((*self.ConfigDRS).argname)[[*self.indarg]]
                      (*self.currModSelecParamTab)[*,1]=((*self.ConfigDRS).argdefault)[[*self.indarg]]
                     (*self.currModSelecParamTab)[*,2]=((*self.ConfigDRS).argdesc)[[*self.indarg]]
        endif
              
        widget_control,   self.tableArgs,  set_value=(*self.currModSelecParamTab), SET_TABLE_VIEW=[0,0]
  
        widget_control,   self.tableSelected,  set_value=(*self.currModSelec)[0:2,*], SET_TABLE_SELECT =[-1,self.nbmoduleSelec-1,-1,self.nbmoduleSelec-1]
        widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,0]
        widget_control,   self.tableAvailable,  set_value=transpose(*self.curr_mod_avai);, SET_TABLE_SELECT =[-1,self.nbmoduleSelec-1,-1,self.nbmoduleSelec-1]
		widget_control,   self.tableAvailable, SET_TABLE_VIEW=[0,0]
        
    endif else begin
		self->log, "ERROR: either no modules selected or no output filename. Can't save till you fix that."
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

    if ~file_test(filename) then begin
		message, "Requested DRF file does not exist: "+filename,/info
		self->Log, "Requested DRF file does not exist: "+filename
		return
	endif

    self.loadedDRF = filename


    widget_control,self.drfbase,get_uvalue=storage  

    
    ; now parse the requested DRF.
    ; First re-parse the config file (so we know about all the available modules
    ; and their arguments)
    ConfigParser = self->get_configParser()
    Parser = OBJ_NEW('gpiDRFParser')
    self->log, "Parsing: "+self.loadedDRF

    ; then parse the DRF and get its contents
    Parser ->ParseFile, self.loadedDRF,  ConfigParser, gui=self, silent=silent
    drf_summary = Parser->get_summary()
    drf_contents = Parser->get_drf_contents()

    drf_module_names = drf_contents.modules.name

    


    ; if requested, load the filenames in that DRF
    ; (for Template use, don't load the data)
    if ~keyword_set(nodata) then  begin
        self.inputdir=drf_contents.inputdir
         ;;get list of files in the drf
         if strcmp((drf_contents.fitsfilenames)[0],'') ne 1  then begin
             (*storage.splitptr).filename = drf_contents.fitsfilenames
            (*storage.splitptr).printname = drf_contents.fitsfilenames
            (*storage.splitptr).findex = n_elements(where( strtrim(drf_contents.fitsfilenames,2) ne ''))
            widget_control,storage.fname,set_value=(*storage.splitptr).printname
        endif

		;update title bar of window:
	
		title  = "GPI DRF-GUI"
		if keyword_set(session) then title += " #"+strc(session)
		widget_control, self.drfbase, tlb_set_title=title+": "+filename

    endif


    ;if necessary, update reduction type to match whatever is in that DRF (and update available modules list too)
    if self.reductiontype ne drf_summary.type then begin
        selectype=where(*self.template_types eq drf_summary.type, matchct)
        if matchct eq 0 then message,"ERROR: no match for "+self.reductiontype
        if self.typeid ne 0 then  widget_control, self.typeid, SET_DROPLIST_SELECT=selectype
        self->changetype, selectype[0], /notemplate
    endif
    

    ; Now load the modules of the selected DRF:
    self.nbmoduleSelec=0
    indseqini=intarr(n_elements(drf_module_names))
    seq=((*self.ConfigDRS).names)[(*self.indmodtot2avail)[*self.curr_mod_indsort]]
    for ii=0,n_elements(drf_module_names)-1 do begin
         indseqini[ii]=where(strmatch(seq,(drf_module_names)[ii],/fold_case), matchct)
		 message,/info, "Module "+strc(ii)+": "+ (drf_module_names)[ii]+", seq="+strc(indseqini[ii])
         if matchct eq 0 then message,/info,"ERROR: no match for module="+ (drf_module_names)[ii]
    endfor

    
    for ii=0,n_elements(drf_module_names)-1 do begin
        if self.nbmoduleSelec eq 0 then (*self.currModSelec)=([(drf_module_names)[0],'','','','']) $  
        else  (*self.currModSelec)=([[(*self.currModSelec)],[[(drf_module_names)[ii],'','','','']]])
        self.nbmoduleSelec+=1

        ;does this module need calibration file?
        ind=where(strmatch(tag_names((drf_contents.modules)[ii]),'CALIBRATIONFILE'), matchct)
        ; if *self.indarg ne [-1] then begin
        if (ind ne [-1]) && (((drf_contents.modules)[ii]).calibrationfile ne '') then begin
                   ; indcalib=where(((*self.ConfigDRS).argname)[[*self.indarg]] eq 'CalibrationFile', ccf)

                   ; if ccf ne 0 then (*self.currModSelec)[2,self.nbmoduleSelec-1]=((*self.ConfigDRS).argdefault)[[(*self.indarg)[indcalib]]]
                   (*self.currModSelec)[2,self.nbmoduleSelec-1]=((drf_contents.modules)[ii]).calibrationfile
                   if strmatch((*self.currModSelec)[2,self.nbmoduleSelec-1], 'AUTOMATIC') then $
                   (*self.currModSelec)[1,self.nbmoduleSelec-1]='Auto' else $
                   (*self.currModSelec)[1,self.nbmoduleSelec-1]='Manual'
        endif
        (*self.currModSelec)[3,self.nbmoduleSelec-1]=((*self.ConfigDRS).order)[(*self.indmodtot2avail)[(*self.curr_mod_indsort)[indseqini[ii]]]] 

 
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
            (*self.currModSelecParamTab)[*,0]=((*self.ConfigDRS).argname)[[*self.indarg]]
            (*self.currModSelecParamTab)[*,1]=((*self.ConfigDRS).argdefault)[[*self.indarg]]
            (*self.currModSelecParamTab)[*,2]=((*self.ConfigDRS).argdesc)[[*self.indarg]]
        endif
        tag=tag_names((drf_contents.modules)[ii])
        for jj=0,n_elements(*self.indarg)-1 do begin
            indtag=where(strmatch( tag ,(*self.currModSelecParamTab)[jj,0],/fold), matchct)
                        if matchct eq 0 then begin
                            message,"ERROR: no match in DRF for module parameter='"+(*self.currModSelecParamTab)[jj,0]+"'",/info
                            message,"of module='"+(drf_module_names)[ii]+"'",/info
                            message,"Check whether the parameter list in the DRF file '"+self.loadeddrf+"' has the correct parameters for that module! ",/info
                        endif
            argtab=((*self.ConfigDRS).argdefault)
            argtab[(*self.indarg)[jj]]=((drf_contents.modules)[ii]).(indtag[0]) ;use parentheses as Facilities exist to process structures in a general way using tag numbers rather than tag names
            ((*self.ConfigDRS).argdefault)=argtab
        ;    (*self.currModSelecParamTab)[jj,1]=
        endfor
    endfor

    ;display parameters for last module
    indselected=self.nbmoduleSelec-1
    self->extractparam, float((*self.currModSelec)[4,indselected])    
    *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
    if (*self.indarg)[0] ne -1 then begin
        (*self.currModSelecParamTab)[*,0]=((*self.ConfigDRS).argname)[[*self.indarg]]
        (*self.currModSelecParamTab)[*,1]=((*self.ConfigDRS).argdefault)[[*self.indarg]]
        (*self.currModSelecParamTab)[*,2]=((*self.ConfigDRS).argdesc)[[*self.indarg]]
    endif
  
    widget_control,   self.tableArgs,     set_value=(*self.currModSelecParamTab)
    widget_control,   self.tableSelected,   set_value=(*self.currModSelec)[0:2,*], SET_TABLE_SELECT =[-1,self.nbmoduleSelec-1,-1,self.nbmoduleSelec-1]
    widget_control,   self.tableSelected,   SET_TABLE_VIEW=[0,0]
    widget_control,   self.outputdir_id, set_value=self.outputdir
    widget_control,   self.logpath_id,   set_value=self.logpath

    obj_destroy, ConfigParser
    obj_destroy, Parser
	if keyword_set(log) then begin
            self->log,'Output Directory :'+self.outputdir
            self->log,'Log path : '+self.logpath
            self->log,'DRF:'+self.loadedDRF+' has been succesfully loaded.'
	endif

end

;------------------------------------------------
pro drfgui::cleanup
	
	ptr_free, self.table_background_colors, self.ConfigDRS, self.curr_mod_avai
	ptr_free, self.curr_mod_indsort, self.currModSelec, self.order, self.indarg
	ptr_free, self.currModSelecParamTab, self.indmodtot2avail, self.templates, self.template_types, self.drf_summary

    widget_control,self.drfbase,/destroy
	
	heap_gc
end

;------------------------------------------------
pro drfgui::init_data, _extra=_Extra
      ;--- init object member variables
        self.ConfigDRS=         ptr_new()                        ; allocate this one in get_configparser
        self.curr_mod_avai=     ptr_new(/ALLOCATE_HEAP)         ; list of available module names (strings) in current mode
        self.curr_mod_indsort=  ptr_new(/ALLOCATE_HEAP)
        self.currModSelec=      ptr_new(/ALLOCATE_HEAP)
        self.order=             ptr_new(/ALLOCATE_HEAP)
        self.indarg=            ptr_new(/ALLOCATE_HEAP)                ; ???
        self.currModSelecParamTab=  ptr_new(/ALLOCATE_HEAP)
        self.indmodtot2avail=   ptr_new(/ALLOCATE_HEAP)
        self.version=2.0

    
        if getenv('GPI_PIPELINE_LOG_DIR') eq '' then initgpi_default_paths


        ; if no configuration file, choose reasonable defaults.
        self.tempdrfdir = getenv('GPI_DRF_TEMPLATES_DIR')
        self.inputcaldir = getenv('GPI_DRP_OUTPUT_DIR')
        self.outputdir = getenv('GPI_DRP_OUTPUT_DIR')
        self.logpath = getenv('GPI_PIPELINE_LOG_DIR')
        self.queuepath =getenv('GPI_QUEUE_DIR')

        cd, current=current
        self.drfpath = current

        self->scan_templates
        self->update_available_modules, 'ASTR - SPEC', 1 ; needed before widget creation




        self.loadedDRF = 'none' ;self.tempdrfdir+'templates_drf_'+typename+'1.xml'
        FindPro, 'drfgui__define', dirlist=dirlist,/noprint
        self.dirpro=dirlist[0]



end

;------------------------------------------------
; create the widgets (can be overridden by subclasses)
;
function drfgui::init_widgets, _extra=_Extra, session=session
      ;create base widget. 
        ;   Resize to be large on desktop monitors, or shrink to fit on laptops.
        ;-----------------------------------------
    DEBUG_SHOWFRAMES=0
    
    screensize=get_screen_size()

    if screensize[1] lt 900 then begin
      nlines_status=5
      nlines_fname=12
      self.nlines_modules=7
      nlines_args=6
    endif else begin
      nlines_status=5
      nlines_fname=12
      self.nlines_modules=10
      nlines_args=6
    endelse

	title  = "GPI DRF-GUI"
	if keyword_set(session) then begin
		self.session=session
		title += " #"+strc(session)
	endif
	title += ': Create Data Reduction Files'
			 CASE !VERSION.OS_FAMILY OF  
		; **NOTE** Mac OS X reports an OS family of 'unix' not 'MacOS'
	   'unix': begin 
		drfbase=widget_base(title=title, $
		group_leader=groupleader,/BASE_ALIGN_LEFT,/column, MBAR=bar,/tlb_size_events, /tlb_kill_request_events, resource_name='GPI_DRP_DRFGUI')
		
		 end
	   'Windows'   :begin
		drfbase=widget_base(title=title, $
		group_leader=groupleader,/BASE_ALIGN_LEFT,/column, MBAR=bar,bitmap=self.dirpro+path_sep()+'gpi.bmp',/tlb_size_events, /tlb_kill_request_events)
		
		 end

	ENDCASE
   
	; MDP change 2010-01-25: let the X and Y size be set by default, based on
	; the nlines settings above
	;xsize=1200,ysize=920,group_leader=groupleader,/BASE_ALIGN_LEFT,/column, MBAR=bar)
	;xsize=1200<screensize[0],ysize=920<(screensize[1]-100),group_leader=groupleader,/BASE_ALIGN_LEFT,/column, MBAR=bar,bitmap=self.dirpro+path_sep()+'gpi.bmp',/tlb_size_events, /tlb_kill_request_events)
		
	self.drfbase=drfbase
	;create Menu

	file_menu = WIDGET_BUTTON(bar, VALUE='File', /MENU) 
	;file_bttn1=WIDGET_BUTTON(file_menu, VALUE='Save Configuration..',   UVALUE='FILE1') 
	file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Open DRF...', UVALUE='LOADDRF') 
	file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Open DRF with Data...', UVALUE='LOADDRFWITHDATA') 
	file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Save DRF as...', UVALUE='Create')
	file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Create DRF Template and Save as...', UVALUE='CreateTemplate')
	file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Quit DRFGUI', UVALUE='QUIT')
	file_menu2 = WIDGET_BUTTON(bar, VALUE='Options', /MENU) 
	file_bttn3=WIDGET_BUTTON(file_menu2, VALUE='Set default directories...', UVALUE='defaultdir') 
	file_bttn3=WIDGET_BUTTON(file_menu2, VALUE='Rescan DRF Templates', UVALUE='rescan') 
	file_bttn3=WIDGET_BUTTON(file_menu2, VALUE='Show/hide extra debugging/development modules', UVALUE='showhidden') 
	file_menu3 = WIDGET_BUTTON(bar, VALUE='Help', /MENU) 
	file_bttn3=WIDGET_BUTTON(file_menu3, VALUE='About...', UVALUE='about') 

	;create message box
	;-----------------------------------------
	;info=widget_text(drfbase,/scroll, $
	;    xsize=58,ysize=5, /ALIGN_LEFT);xoffset=5,yoffset=5)
	;OLD info=widget_text(drfbase,/scroll, xsize=58,ysize=nlines_status, /ALIGN_LEFT);xoffset=5,yoffset=5)

	;create file selector
	;-----------------------------------------
	drfbasefilebutt=widget_base(drfbase,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES, /base_align_center)
	label = widget_label(drfbasefilebutt, value="Input FITS Files:")
	button=widget_button(drfbasefilebutt,value="Add File(s)",uvalue="ADDFILE", $
		xsize=90,ysize=30, /tracking_events);,xoffset=10,yoffset=115)
	button=widget_button(drfbasefilebutt,value="Wildcard",uvalue="WILDCARD", $
		xsize=90,ysize=30, /tracking_events);,xoffset=110,yoffset=115)
	button=widget_button(drfbasefilebutt,value="Remove",uvalue="REMOVE", $
		xsize=90,ysize=30, /tracking_events);,xoffset=210,yoffset=115)
	button=widget_button(drfbasefilebutt,value="Remove All",uvalue="REMOVEALL", $
		xsize=90,ysize=30, /tracking_events);,xoffset=310,yoffset=115)

	drfbasefilebutt2=drfbasefilebutt
	sorttab=['obs. date/time','OBSID','alphabetic filename','file creation date']
	self.sortfileid = WIDGET_DROPLIST( drfbasefilebutt2, title='Sort data by:',  Value=sorttab,uvalue='sortmethod',resource_name='XmDroplistButton')
	drfbrowse = widget_button(drfbasefilebutt2,  $
							XOFFSET=174 ,SCR_XSIZE=80, ysize= 30 $; ,SCR_YSIZE=23  $
							,/ALIGN_CENTER ,VALUE='Sort data',uvalue='sortdata')                          
		
	drfbaseident=widget_base(drfbase,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES)
	; file name list widget
	fname=widget_list(drfbaseident,xsize=106,scr_xsize=580, ysize=nlines_fname,$
			xoffset=10,yoffset=150,uvalue="FNAME", /TRACKING_EVENTS,resource_name='XmText')

	; add 5 pixel space between the filename list and controls
	drfbaseborder=widget_base(drfbaseident,xsize=5,units=0, frame=DEBUG_SHOWFRAMES)

	; add the options controls
	drfbaseidentseq=widget_base(drfbaseident,/BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
	drfbaseborder=widget_base(drfbaseidentseq,ysize=1,units=0)          
	drfbaseborder2=widget_base(drfbaseidentseq,/BASE_ALIGN_LEFT,/row)
	drflabel=widget_label(drfbaseborder2,Value='Output Dir=         ')
	self.outputdir_id = WIDGET_TEXT(drfbaseborder2, $
				xsize=34,ysize=1,$
				/editable,units=0,value=self.outputdir )    

	drfbrowse = widget_button(drfbaseborder2,  $
						XOFFSET=174 ,SCR_XSIZE=75 ,SCR_YSIZE=23  $
						,/ALIGN_CENTER ,VALUE='Change...',uvalue='outputdir')
	drfbaseborder3=widget_base(drfbaseidentseq,/BASE_ALIGN_LEFT,/row)
	drflabel=widget_label(drfbaseborder3,Value='Log Path=           ')
	self.logpath_id = WIDGET_TEXT(drfbaseborder3, $
				xsize=34,ysize=1,$
				/editable,units=0 ,value=self.logpath)
	drfbrowse = widget_button(drfbaseborder3,  $
						XOFFSET=174 ,SCR_XSIZE=75 ,SCR_YSIZE=23  $
						,/ALIGN_CENTER ,VALUE='Change...',uvalue='logpath') 
	drfbaseborder=widget_base(drfbaseidentseq,ysize=7,units=0)
	drfbaseborder4=widget_base(drfbaseidentseq,/BASE_ALIGN_LEFT,/row) 
	self.calibfiletab=['data closest date/time','most-recent','manual']
	self.calibfileid = WIDGET_DROPLIST( drfbaseborder4, title='Find Calib. file:  ', frame=0, Value=self.calibfiletab,uvalue='calibfield',resource_name='XmDroplistButton')
	drfbrowse = widget_button(drfbaseborder4,  $
						XOFFSET=174 ,SCR_XSIZE=155 $;,SCR_YSIZE=23  $
						,/ALIGN_CENTER ,VALUE='Resolve calib. filename',uvalue='resolvecalibfilename')                          
	;drfbaseborder=widget_base(drfbaseidentseq,ysize=7,units=0) ; MDP removed - this is not used anywhere.
	base_radio = Widget_Base(drfbaseidentseq, UNAME='WID_BASE_diskb', COLUMN=1 ,/NONEXCLUSIVE, frame=0)
	self.resolvetypeseq_id = Widget_Button(base_radio, UNAME='RESOLVETYPESEQBUTTON' ,/ALIGN_LEFT ,VALUE='Resolve type/seq. when adding file(s)',UVALUE='autoresolvetypeseq')
	widget_control, self.resolvetypeseq_id, /set_button
	;*self.template_types=['ASTR - SPEC','ASTR - POL','CAL - SPEC','CAL - POL'] ;, 'On-Line Reduction'
	;drfbaseborderz=widget_base(drfbaseidentseq,/BASE_ALIGN_LEFT,/row)
	self.typeid = WIDGET_DROPLIST( drfbaseidentseq, title='Reduction type:    ', frame=0, Value=*self.template_types,uvalue='typefield',resource_name='XmDroplistButton')
	 self.seqid = WIDGET_DROPLIST( drfbaseidentseq, title='Reduction Sequence:', frame=0, Value=['Simple Data-cube extraction','Calibrated Data-cube extraction','Calibrated Data-cube extraction, ADI reduction'],uvalue='seqfield',resource_name='XmDroplistButton')

	;one nice logo 
	button_image = READ_BMP(self.dirpro+path_sep()+'gpi.bmp', /RGB) 
	button_image = TRANSPOSE(button_image, [1,2,0]) 
	button = WIDGET_BUTTON(drfbaseident, VALUE=button_image,  $
			SCR_XSIZE=100 ,SCR_YSIZE=95, sensitive=1 $
			 ,uvalue='about') 
	 
	 
	;create merge selector
	;-----------------------------------------
	drfbasemodule=widget_base(drfbase,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES)
	drfbasemoduleavailable=widget_base(drfbasemodule,/BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
	;data = ['Prim1', 'Prim2', 'Prim3', 'Prim4'] 
	data=transpose(*self.curr_mod_avai)


	; what colors to use for cell backgrounds? Alternate rows between
	; white and off-white pale blue
	self.table_BACKground_colors = ptr_new([[255,255,255],[240,240,255]])

 
	self.tableAvailable = WIDGET_TABLE(drfbasemoduleavailable, VALUE=data,$;  $ ;/COLUMN_MAJOR, $ 
			COLUMN_LABELS=['Available Modules'], /TRACKING_EVENTS,$
			xsize=1,ysize=50,scr_xsize=400,$  ;JM: ToDo: ysize as a function of #mod avail.
			/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =self.nlines_modules,COLUMN_WIDTHS=380,frame=1,uvalue='moduavai',/ALL_EVENTS,/CONTEXT_EVENTS , $
			background_color=rebin(*self.table_BACKground_colors,3,2,1)) ;/COLUMN_MAJOR,
	
	;drfbaseborder=widget_base(drfbasemoduleavailable,units=0,xsize=280,ysize=250,frame=1)
		lab = widget_label(drfbasemoduleavailable, value="Module Description:")
		self.descr = WIDGET_TEXT(drfbasemoduleavailable, $
			xsize=58,scr_xsize=400, ysize=3,/scroll, $; nlines_args,$
			;xsize=34,ysize=nlines_args,$
		   ; value='Module Description:                                 '+((*self.ConfigDRS).names)[(*self.indmodtot2avail)[0]],units=0 ,/wrap)
		   value=(*self.curr_mod_avai)[0],units=0 ,/wrap, uval='mod_desc',/tracking_events)
		   ;value='Module Description:'+string(10b)+(*self.curr_mod_avai)[0],units=0 ,/wrap)

	; Create the status log window 
	; widget ID gets stored into 'storage'
	info=widget_text(drfbasemoduleavailable,/scroll, xsize=58,scr_xsize=400,ysize=nlines_status, /ALIGN_LEFT, uval="text_status",/tracking_events);xoffset=5,yoffset=5)


	drfbasemoduleselected=widget_base(drfbasemodule,/BASE_ALIGN_LEFT,/column)
	self.tableSelected = WIDGET_TABLE(drfbasemoduleselected, $; VALUE=data, $ ;/COLUMN_MAJOR, $ 
			COLUMN_LABELS=['Module Name','Find Calibration File','Resolved Filename'],/resizeable_columns, $
			xsize=3,ysize=20,uvalue='tableselected',value=(*self.currModSelec), /TRACKING_EVENTS,$
			/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =self.nlines_modules,scr_xsize=800,COLUMN_WIDTHS=[240,140,420],frame=1,/ALL_EVENTS,/CONTEXT_EVENTS, $
			background_color=rebin(*self.table_BACKground_colors,3,2*3,/sample)    ) ;,/COLUMN_MAJOR                
	self.tableArgs = WIDGET_TABLE(drfbasemoduleselected, $; VALUE=data, $ ;/COLUMN_MAJOR, $ 
			COLUMN_LABELS=['Argument', 'Value','Description'], /resizeable_columns, $
			xsize=3,ysize=20, /TRACKING_EVENTS,$
			/NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =nlines_args,scr_xsize=800,/COLUMN_MAJOR,COLUMN_WIDTHS=[180,180,440],frame=1,/EDITABLE,uvalue='tableargs' , $
			background_color=rebin(*self.table_BACKground_colors,3,2*3,/sample)    ) ;,/COLUMN_MAJOR                
		

	;;create execute and quit button
	;-----------------------------------------
	drfbaseexec=widget_base(drfbase,/BASE_ALIGN_LEFT,/row)
	button2=widget_button(drfbaseexec,value="Save DRF as...",uvalue="Create", /tracking_events)
	button2b=widget_button(drfbaseexec,value="Drop last saved DRF in Queue",uvalue="Drop", /tracking_events)
	utton2c=widget_button(drfbaseexec,value="Save and drop DRF in Queue",uvalue="Save&Drop", /tracking_events)
	spacer = widget_label(drfbaseexec, value=' ', xsize=250)

	button3=widget_button(drfbaseexec,value="Add module",uvalue="Add module", /tracking_events);, $
	button3=widget_button(drfbaseexec,value="Move module up",uvalue="Move module up", /tracking_events);, $
	button3=widget_button(drfbaseexec,value="Move module down",uvalue="Move module down", /tracking_events);, $
	button3=widget_button(drfbaseexec,value="Remove module",uvalue="Remove module", /tracking_events);, $
	spacer = widget_label(drfbaseexec, value=' ', xsize=50)
	button3=widget_button(drfbaseexec,value="Close DRFGUI",uvalue="QUIT", /tracking_events, resource_name='red_button')

	self.textinfoid=widget_label(drfbase,uvalue="textinfo",xsize=900,ysize=20,value='  ')
	;filename array and index
	;-----------------------------------------
	maxfilen=550
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
    widget_control,drfbase,set_uvalue=storage,/no_copy


    self->changetype, 0 ; set to ASTR-SPEC type by default.

    return, drfbase

end

;------------------------------------------------
PRO drfgui::post_init, drfname=drfname, _extra=_extra
    if keyword_set(drfname) then begin
        self->loaddrf, drfname, /log
    end

end

;------------------------------------------------

; Initialize and create widgets
function drfgui::init, groupleader, _extra=_extra ;,group,proj

    ;;for possible usage later (not really necessary now)
    if n_params() lt 1 then  groupleader=''

	self->init_data, _extra=_extra

	drfbase = self->init_widgets(_extra=_Extra)

	;show base widget
	;-----------------------------------------
	widget_control,drfbase,/realize

	;event loop
	;-----------------------------------------

	xmanager,'drfgui',drfbase,/no_block,group_leader=groupleader


	self->post_init, _extra=_extra

    return, 1
end



;-----------------------
pro drfgui__define
    struct = {drfgui,   $
              drfbase:0L,$
			  session: 0L, $
              dirpro:strarr(1),$
              ;typetab:strarr(5),$
              defoutputdir_id:0L,$
              deflogpath_id:0L,$
              defdrfpath_id:0L,$
              defqueuepath_id:0L,$ 
			  widget_log: 0L, $
              drfpath :'',$ 
              drffilename :'',$  
              queuepath :'',$  
              sortfileid :0L,$       
              inputdir:'',$
              outputdir:'',$
              definputcaldir_id:0L,$
              inputcaldir:'',$
              outputdir_id:0L,$
              logpath:'',$
              logpath_id:0L,$
              calibfileid:0L,$
              calibfiletab:strarr(3), $
              resolvetypeseq_id:0L,$
              config_file:'',$
              loadedDRF:'',$
              deftempdrfdir_id:0L,$
              tempdrfdir:'',$     
              filter:'',$ ;from data keywords
              ftimeobs:0.,$ ;from data keywords
              fmod:'',$ ;from data keywords
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
              selecseq:0,$
			  showhidden: 0, $
              table_background_colors: ptr_new(), $ ; ptr to RGB triplets for table cell colors
              nlines_modules: 0, $                    ; how many lines to display modules on screen? (used in resize)
              ConfigDRS: ptr_new(), $
              curr_mod_avai: ptr_new(), $         ; list of available module names (strings) in current mode
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
              version: '2.0'}              ; version # of this release


end
