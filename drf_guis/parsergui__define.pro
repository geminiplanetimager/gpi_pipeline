;-----------------------------------------
; parsergui__define.pro 
;
; PARSER: select files to process and create a list of DRFs to be executed by the pipeline.
;
;
;
; author : 2010-02 J.Maire created
; 2010-08-19 : JM added parsing of arclamp images



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


pro parsergui::startup

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
 
        if getenv('GPI_CONFIG_FILE') ne '' then self.config_file=getenv('GPI_CONFIG_FILE') $
        else begin
        	dirlist=getenv('GPI_PIPELINE_DIR')+path_sep()+'utils'+path_sep()
			self.config_file=dirlist[0]+"drsconfig.xml"
		endelse
        ConfigParser = OBJ_NEW('gpiDRSConfigParser')
  
        if file_test(self.config_file) then begin
            ConfigParser -> ParseFile, self.config_file ;drpXlateFileName(CONFIG_FILENAME)
            *self.ConfigDRS = ConfigParser->getidlfunc() 
        endif

        if getenv('GPI_PIPELINE_LOG_DIR') eq '' then initgpi_default_paths
        ; if no configuration file, choose reasonable defaults.
        cd, current=current
        self.tempdrfdir = getenv('GPI_DRF_TEMPLATES_DIR')
        self.inputcaldir = getenv('GPI_DRP_OUTPUT_DIR')
        self.outputdir = getenv('GPI_DRP_OUTPUT_DIR')
        self.logpath = getenv('GPI_PIPELINE_LOG_DIR')

		if gpi_get_setting('organize_DRFs_by_dates',/bool) then begin
			self.drfpath = gpi_get_setting('DRF_root_dir',/expand_path) + path_sep() + gpi_datestr(/current)
			self->Log,"Outputting DRFs based on date to "+self.drfpath
		endif else begin
			;due to directory Gemini writing permissions, write temporary DRF in the working directory
			self.drfpath =getenv('GPI_IFS_DIR')
			self->Log, "Outputting DRFs to working directory: "+self.drfpath
		endelse

        self.queuepath =getenv('GPI_QUEUE_DIR')

end

;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
;  Change the list of Available Modules to match the currently selected
;  Reduction Type
;
;  ARGUMENTS:
;          typestr       string, name of the mode type to use
;          seqval        integer, which sequence in that type to use.
;
pro parsergui::changemodsetting, typestr,seqval

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
    *self.indmodtot2avail=[intersect(indall,indpol,/xor_flag),intersect(indastr,indspec)]
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

    ;;sort in alphabetical order
    *self.curr_mod_indsort=sort(*self.curr_mod_avai)
    (*self.curr_mod_avai)=(*self.curr_mod_avai)[*self.curr_mod_indsort]

    ;;standard recipes
    selectype= self.currtype;widget_info(self.typeid,/DROPLIST_SELECT)

;;standard recipes
(*self.currModSelec)=strarr(5);(['','','','',''])


end    

;--------------------------------------------------------------------------------
pro parsergui::extractparam, modnum 
;   modnum is the index of the selected module in the CURRENTLY ACTIVE LIST for
;   this mode
    *self.indarg=where(   ((*self.ConfigDRS).argmodnum) eq ([(*self.indmodtot2avail)[(*self.curr_mod_indsort)[modnum]]]+1)[0], carg)
end

;--------------------------------------------------------------------------------
pro defaultpath_event,ev

    ;get type of event
    ;-----------------------------------------
    widget_control,ev.id,get_uvalue=uval

    ;get storage
    ;-----------------------------------------
    widget_control,ev.top,get_uvalue=storage

    ;routine for event
    ;-----------------------------------------
    case uval of 
       'definputcaldir':begin
               ; TODO - fix all other directory selection commands to be like this:
            newdir = (DIALOG_PICKFILE(TITLE='Select CALIBRATION input Directory', /DIRECTORY,/MUST_EXIST)) 
            if newdir eq '' then return ; user cancelled, so change nothing.
            self.inputcaldir = newdir +  path_sep()
            widget_control, self.definputcaldir_id, set_value=self.inputcaldir
       end
        'defoutputdir':begin
            self.outputdir = (DIALOG_PICKFILE(TITLE='Select an OUTPUT Directory', /DIRECTORY,/MUST_EXIST)) + path_sep()
            widget_control, self.defoutputdir_id, set_value=self.outputdir
       end
       'deftempdrfdir':begin   
            self.tempdrfdir = (DIALOG_PICKFILE(TITLE='Select TEMPLATES DRF Directory', /DIRECTORY,/MUST_EXIST)) + path_sep()
            widget_control, self.deftempdrfdir_id, set_value=self.tempdrfdir
       end
        'deflogpath':begin 
            self.logpath = (DIALOG_PICKFILE(TITLE='Select a LOG path Directory', /DIRECTORY,/MUST_EXIST)) + path_sep()
            widget_control, self.deflogpath_id, set_value=self.logpath
       end
        'drfpath':begin
            self.drfpath = (DIALOG_PICKFILE(TITLE='Select dir where to save drf', /DIRECTORY,/MUST_EXIST)) + path_sep()
            widget_control, self.defdrfpath_id, set_value=self.drfpath
       end
        'queuepath':begin
            self.queuepath = (DIALOG_PICKFILE(TITLE='Select Queue Directory', /DIRECTORY,/MUST_EXIST)) + path_sep()
            setenv, 'GPI_QUEUE_DIR='+ self.queuepath 
            widget_control, self.defqueuepath_id, set_value=self.queuepath
       end
       'SAVE'  : begin
					configdir = file_dirname(gpi_expand_path('$GPI_CONFIG_FILE'))
                    OpenW, lun, configdir+path_sep()+'drfgui_config.txt', /Get_Lun
                    PrintF, lun, 'INPUTCAL: ', self.inputcaldir
                    PrintF, lun, 'OUTPUT: ', self.outputdir
                    PrintF, lun, 'TEMPDRF: ', self.tempdrfdir
                    PrintF, lun, 'LOG: ', self.logpath
                    PrintF, lun, 'DRF: ', self.drfpath
                    PrintF, lun, 'QUEUE: ', self.queuepath
                    Free_Lun, lun
           end
    end
end   
   
;event handler
;-----------------------------------------
pro parsergui::changetype, selectype, storage,notemplate=notemplate

    typefield=*self.template_types

	self.reductiontype = (*self.template_types)[selectype]         
	selecseq=0
	self.currseq=selecseq
	(*self.currModSelec)=''
	self.nbmoduleSelec=0
	self->changemodsetting, typefield[selectype],selecseq+1

	self.selectype=selectype
	self.selecseq=selecseq


	case selectype of 
		0:typename='astr_spec_'
		1:typename='astr_pol_'
		2:typename='cal_spec_'
		3:typename='cal_pol_'
		4:typename='online_'
	endcase
	if ~keyword_set(notemplate) then begin
		self.loadedDRF = self.tempdrfdir+'templates_drf_'+typename+'1.xml'
		;self->loaddrf, /nodata
	endif
  
end


;-----------------------------------------
pro parsergui::addfile, filenames, mode=mode
    ; Add a new file to the Input FITS files list. 

    widget_control,self.top_base,get_uvalue=storage  
    index = (*storage.splitptr).selindex
    cindex = (*storage.splitptr).findex
    file = (*storage.splitptr).filename
    pfile = (*storage.splitptr).printname
    datefile = (*storage.splitptr).datefile

    ;-- can we add more files now?
    if (file[n_elements(file)-1] ne '') then begin
        self->Log,'Sorry, maximum number of files reached. You cannot add any additional files/directories.'
        return
    endif

    for i=0,n_elements(filenames)-1 do begin   ; Check for duplicate
        if (total(file eq filenames[i]) ne 0) then filenames[i] = ''
    endfor
    ;for i=0,n_elements(filenames)-1 do begin
        ;tmp = strsplit(filenames[i],'.',/extract)
        ;if (n_elements(tmp) lt 5) then filenames[i] = ''
    ;endfor


    w = where(filenames ne '', wcount) ; avoid blanks
    if wcount eq 0 then void=dialog_message('No new files. Please add new files before parsing.')
    if wcount eq 0 then return
    filenames = filenames[w]

    if ((cindex+n_elements(filenames)) gt n_elements(file)) then begin
        nover = cindex+n_elements(filenames)-n_elements(file)
        self->Log,'WARNING: You tried to add more files than the file number limit. '+$
            strtrim(nover,2)+' files ignored.'
        filenames = filenames[0:n_elements(filenames)-1-nover]
    endif

    ;-- Add input files to the list. 
    file[cindex:cindex+n_elements(filenames)-1] = filenames

    for i=0,n_elements(filenames)-1 do begin
        tmp = strsplit(filenames[i],path_sep(),/extract)
        pfile[cindex+i] = tmp[n_elements(tmp)-1]+'    '
    endfor

    self.inputdir=strjoin(tmp[0:n_elements(tmp)-2],path_sep())
    if !VERSION.OS_FAMILY ne 'Windows' then self.inputdir = "/"+self.inputdir 


    self->Log, "Loading and parsing files..."
    ;-- Update information in the structs
    cindex = cindex+n_elements(filenames)
    (*storage.splitptr).selindex = max([0,cindex-1])
    (*storage.splitptr).findex = cindex
    (*storage.splitptr).filename = file
    (*storage.splitptr).printname = pfile
    (*storage.splitptr).datefile = datefile 

    ;;TEST DATA SANITY
    ;;ARE THEY VALID  GEMINI & GPI & IFS DATA?
    if self.testdata eq 0 then begin

        validtelescop=bytarr(cindex)
        validinstrum=bytarr(cindex)
        validinstrsub=bytarr(cindex)

        for ff=0, cindex-1 do begin
			message,/info, 'Verifying keywords for file '+file[ff]
			message,/info, '  This code needs to be made more efficient...'
            validtelescop[ff]=self->validkeyword( file[ff], 1,'TELESCOP','Gemini*',storage) 
            validinstrum[ff]= self->validkeyword( file[ff], 1,'INSTRUME','GPI',storage)
            validinstrsub[ff]=self->validkeyword( file[ff], 1,'INSTRSUB','IFS',storage)            
        endfor  

        indnonvaliddata0=[where(validtelescop eq 0),where(validinstrum eq 0),where(validinstrsub eq 0)]
        indnonvaliddata=indnonvaliddata0[uniq(indnonvaliddata0,sort( indnonvaliddata0 ))]
        indnonvaliddata2=where(indnonvaliddata ne -1, cnv)
        if cnv gt 0 then begin
            indnonvaliddata3=indnonvaliddata[indnonvaliddata2]
            nonvaliddata=file[indnonvaliddata3]
            self->Log,'WARNING: non-valid data have been detected and removed:'+nonvaliddata
            indvaliddata=intersect(indnonvaliddata3,indgen(cindex),countvalid,/xor)
             ;correct for a strange side effect with the intersect function above : test for instance: print, intersect([0],[0],ac,/xor)
            if n_elements(indnonvaliddata3) eq cindex then countvalid = 0
            if countvalid eq 0 then file=''
            if countvalid gt 0 then file=file[indvaliddata]

                cindex = countvalid
                (*storage.splitptr).selindex = max([0,cindex-1])
                (*storage.splitptr).findex = cindex
                (*storage.splitptr).filename = file
                pfile=file
                (*storage.splitptr).printname = pfile
                (*storage.splitptr).datefile = datefile 
            endif
      
    endif else begin ;if data are test data don't remove them but inform a bit
        validtelescop=self->validkeyword( file, cindex,'TELESCOP','Gemini',storage)
        validinstrum =self->validkeyword( file, cindex,'INSTRUME','GPI',storage)
        validinstrsub=self->validkeyword( file, cindex,'INSTRSUB','IFS',storage)
    endelse
    (*self.currModSelec)=strarr(5)
    (*self.currDRFSelec)=strarr(10)


	message,/info, 'Now analyzing data based on keywords'
    widget_control,storage.fname,set_value=pfile ; update displayed filename information - temporary, just show filename

    if cindex gt 0 then begin ;assure that data are selected

        self.nbdrfSelec=0
        ;; RESOLVE FILTER(S) AND OBSTYPE(S)
        tmp = self->get_obs_keywords(file[0])
        finfo = replicate(tmp,cindex)

        for jj=0,cindex-1 do begin
            finfo[jj] = self->get_obs_keywords(file[jj])
              ;;we want Xenon&Argon considered as the same 'lamp' object for Y,K1,K2bands (for H&J, better to do separately to keep only meas. from Xenon)
                if (~strmatch(finfo[jj].filter,'[HJ]')) && (strmatch(finfo[jj].object,'Xenon') || strmatch(finfo[jj].object,'Argon')) then $
                    finfo[jj].object='Lamp'
            ;; we also want Flat considered for wavelength solution in Y band
                 if strmatch(finfo[jj].object,'Flat*')  &&  strmatch(finfo[jj].filter,'Y') then $
                    finfo[jj].object='Lamp'
            pfile[jj] = pfile[jj]+"     "+finfo[jj].dispersr +" "+finfo[jj].filter+" "+finfo[jj].obstype+" "+string(finfo[jj].itime,format='(F5.1)')+"  "+finfo[jj].object
        endfor
        widget_control,storage.fname,set_value=pfile ; update displayed filename information - filenames plus parsed keywords


      (*storage.splitptr).printfname=pfile
        ;-- propose to correct invalid keywords, if necessary
        ; Do this by writing a DRF implementing the 'Add Gemini and GPI
        ; Keywords' module, and then putting it in the queue. 
        indnonvaliddatakeyw=where(finfo.valid eq 0, cinv)
;        if cinv gt 0 then begin
;            self->Log, "Missing keywords detected for "+strc(cinv)+" files. Creating DRF to fix them"
;			print, "*** debug why missing keywords here ***"
;			stop
;            for i=0,cinv-1 do self->Log, "   file: "+file[indnonvaliddatakeyw[i]]
;            nonvaliddata=file[indnonvaliddatakeyw]
;            indvaliddata=intersect(indnonvaliddatakeyw,indgen(cindex),countvalid,/xor)
;            if n_elements(indnonvaliddatakeyw) eq cindex then countvalid = 0
;            if countvalid eq 0 then file=''
;            if countvalid gt 0 then begin
;                file=file[indvaliddata]
;                ; update keyword list
;                finfo  =finfo[indvaliddata]
;            endif  
;            cindex = countvalid
;            ;add missing keywords
;            detectype=3
;            detecseq=5
;            ;seqtab=self.seqtab3
;            typename='cal_spec_'         
;            self.loadedDRF = self.tempdrfdir+'templates_drf_'+typename+strc(detecseq)+'.xml'
;            self->loaddrf, /nodata, /silent
;            self->savedrf, nonvaliddata, prefix=self.nbdrfSelec+1 
;            if widget_info(self.direct_id ,/button_set)  then chosenpath=self.queuepath else chosenpath=self.drfpath           
;            newdrf = ([chosenpath+path_sep()+(*self.drf_summary).filename,(*self.drf_summary).name,(*self.template_types)[detectype-1] ,'','', '', '', '' ,'','']) 
;
;            if self.nbdrfSelec eq 0 then (*self.currDRFSelec)= newdrf else (*self.currDRFSelec)=([[(*self.currDRFSelec)],[newdrf]])
;            self.nbdrfSelec+=1
;            print, (*self.currDRFSelec)
;              widget_control, self.tableSelected, ysize=((size(*self.currDRFSelec))[2] > 20 )
;              widget_control, self.tableSelected, set_value=(*self.currDRFSelec)[0:9,*]
;              widget_control, self.tableSelected, background_color=rebin(*self.table_BACKground_colors,3,2*10,/sample)    
;            
;            self->Log, "Those files will be ignored from further analysis until after the keywords are fixed. "
;        endif


		; Mark filter as irrelevant for Dark exposures
		wdark = where(strlowcase(finfo.obstype) eq 'dark', dct)
		if dct gt 0 then finfo[wdark].filter='-'


        if (n_elements(file) gt 0) && (strlen(file[0]) gt 0) then begin

            ; save starting date and time for use in DRF filenames
            caldat,systime(/julian),month,day,year, hour,minute,second
            datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
            hourstr = string(hour,minute,format='(i2.2,i2.2)')  
            datetimestr=datestr+'-'+hourstr
          
            current = {gpi_obs}

            ;categorize by filter
            uniqfilter  = uniqvals(finfo.filter, /sort)
            ;uniqfilter = ['H', 'Y', 'J', "K1", "K2"] ; H first since it's primary science wvl?
            uniqobstype = uniqvals(strlowcase(finfo.obstype), /sort)
                ; TODO - sort right order for obstype 
           ; uniqobstype = uniqvals(finfo.obstype, /sort)

		    uniqprisms = uniqvals(finfo.dispersr)
            ;uniqprisms = ['Spectral', 'Wollaston', 'Open']
            ;uniqocculters = ['blank','fpm']
            uniqocculters = uniqvals(finfo.occulter)
            ;update for new keyword conventions:
            tmpobsclass=finfo.obsclass
            for itmp=0,n_elements(tmpobsclass)-1 do begin
              if strmatch((finfo.obstype)[itmp],'*Object*',/fold) then (finfo[itmp].obsclass) = 'Science'
              if strmatch((finfo.obstype)[itmp],'*Standard*',/fold) then begin
                if strmatch((finfo.dispersr)[itmp],'*SPEC*',/fold) then (finfo[itmp].obsclass) = 'SPECSTD'
                if strmatch((finfo.dispersr)[itmp],'*POL*',/fold) then (finfo[itmp].obsclass) = 'POLARSTD'
              endif
              if strmatch((finfo.astromtc)[itmp],'*TRUE*',/fold) then (finfo[itmp].obsclass) = 'Astromstd'
            endfor
            uniqobsclass = uniqvals(finfo.obsclass, /sort)
            uniqitimes = uniqvals(finfo.itime, /sort)
            uniqobjects = uniqvals(finfo.object, /sort)



            nbfilter=n_elements(uniqfilter)
            message,/info, "Now adding "+strc(n_elements(finfo))+" files. "
            message,/info, "Input files include data from these FILTERS: "+strjoin(uniqfilter, ", ")
            
			

            ;for each filter category, categorize by obstype
            for ff=0,nbfilter-1 do begin
                current.filter = uniqfilter[ff]
                indffilter =  where(finfo.filter eq current.filter)
                filefilt = file[indffilter]
                
                ;categorize by obstype
                uniqsortedobstype = uniqvals(strlowcase((finfo.obstype)[indffilter]))

                ;add  wav solution if not present and if flat-field should be reduced as wav sol
                void=where(strmatch(uniqsortedobstype,'*arc*',/fold),cwv)
                void=where(strmatch(uniqsortedobstype,'flat*',/fold),cflat)
                if ( cwv eq 0) && (cflat eq 1) && (self.flatreduc eq 1) then begin
                    indfobstypeflat =  where(strmatch((finfo.obstype)[indffilter],'flat*',/fold)) 
                    uniqsortedobstype = [uniqsortedobstype ,'wavecal']
                endif
                   
                nbobstype=n_elements(uniqsortedobstype)
                    
                ;;here we have to sequence the drf queue: 
                ;; assign to each obstype an order:
                sequenceorder=intarr(nbobstype)
                sortedsequencetab=['Dark', 'Arc', 'Flat','Object']

                for fc=0,nbobstype-1 do begin
                   wm = where(strmatch(sortedsequencetab, uniqsortedobstype[fc]+'*',/fold),mct)
                   ;if mct eq 1 then sequenceorder[fc]= mct[0]
                   if mct eq 1 then sequenceorder[fc]= wm[0]
                endfor
                indnotdefined=where(sequenceorder eq -1,cnd)
                if cnd ge 1  then sequenceorder[indnotdefined]=nbobstype-1
                indsortseq=sort(sequenceorder)

                
                ;;for each filter and each obstype, create a drf
                for fc=0,nbobstype-1 do begin
                    ;get files corresponding to one filt and one obstype
                    current.obstype = uniqsortedobstype[indsortseq[fc]]
;                    
                    ;categorize by PRISM
                    for fd=0,n_elements(uniqprisms)-1 do begin
                        current.dispersr = uniqprisms[fd]
                     
                        for fo=0,n_elements(uniqocculters)-1 do begin
                            current.occulter=uniqocculters[fo]
                            
                            for fobs=0,n_elements(uniqobsclass)-1 do begin
                                current.obsclass=uniqobsclass[fobs]
                                
                                for fitime=0,n_elements(uniqitimes)-1 do begin

                                    current.itime = uniqitimes[fitime]    ; in seconds, now
                                    ;current.exptime = uniqitimes[fitime] ; in seconds
                                    
                                    for fobj=0,n_elements(uniqobjects)-1 do begin
                                        current.object = uniqobjects[fobj]
                                        ;these following 2 lines for adding Y-band flat-field in wav.solution measurement
                                        currobstype=current.obstype
                                        if (self.flatreduc eq 1)  && (current.filter eq 'Y') &&$
                                        (current.obstype eq 'Wavecal')  then currobstype='[WF][al][va][et]*'
                          
                                        indfobject = where(finfo.filter eq current.filter and $
                                                    ;finfo.obstype eq current.obstype and $
                                                    strmatch(finfo.obstype, currobstype,/fold) and $                                                    
                                                    strmatch(finfo.dispersr,current.dispersr+"*",/fold) and $
                                                    strmatch(finfo.occulter,current.occulter+"*",/fold) and $
                                                    finfo.obsclass eq current.obsclass and $
                                                    finfo.itime eq current.itime and $
                                                    finfo.object eq current.object, cobj)
                                                    
										if self.debug then begin
											message,/info, 'Now testing the following parameters: ('+strc(cobj)+' files match) '
											help, current,/str
										endif

										;if cobj gt 0 then stop
                      
    
                                        if cobj eq 0 then continue ; this particular combination of filter, obstype, dispersr, occulter, class, time, object has no files. 

										; otherwise, try to match it:
                                        file_filt_obst_disp_occ_obs_itime_object = file[indfobject]
                         
                                        ;identify which templates to use
                                        print,  current.obstype ; uniqsortedobstype[indsortseq[fc]]
                                        self->Log, "found sequence of type="+current.obstype+", prism="+current.dispersr+", filter="+current.filter
                                        ;stop
                                         case strupcase(current.obstype) of
                                        'DARK':begin
                                            detectype=3
                                            detecseq=2                        
                                        end
                                        'ARC': begin 
                                            if  current.dispersr eq 'POLAR' then begin 
                                                detectype=4
                                                detecseq=2  
                                            endif else begin                                                          
                                                detectype=3
                                                ;if current.filter eq 'Y' then  detecseq=9 else $
                                                detecseq=3                  
                                            endelse                     
                                        end
                                        'FLAT': begin
                                            if  current.dispersr eq 'POLAR' then begin 
                                                ; handle polarization flats
                                                ; differently: compute **both**
                                                ; extraction files and flat
                                                ; fields from these data, in two
                                                ; passes
                                                self->create_drf_from_template, self.tempdrfdir+path_sep()+"templates_drf_cal_pol_1.xml", file_filt_obst_disp_occ_obs_itime_object, current, datetimestr=datetimestr
                                                self->create_drf_from_template, self.tempdrfdir+path_sep()+"templates_drf_cal_pol_2.xml", file_filt_obst_disp_occ_obs_itime_object, current, datetimestr=datetimestr, mode=mode
                                                ;continue        aaargh can't continue inside a case. stupid IDL
                                                detectype = -1
                                                ;detectype=4
                                                ;detecseq=1  
                                            endif else begin              
                                                detectype=3
                                                detecseq=1   
                                            endelse                             
                                        end
                                        'OBJECT': begin
                                            if  current.dispersr eq 'POLAR' then begin 
                                                detectype=2
                                                detecseq=1  
                                            endif else begin 
                                                if  current.occulter eq 'blank'  then begin ;means no occulter
                                                    ;if binaries:
                                                    if strmatch(current.obsclass, 'AstromSTD',/fold) then begin
                                                       detectype=3
                                                       detecseq=8  
                                                    endif
                                                    if strmatch(current.obsclass, 'Science',/fold) then begin
                                                       detectype=1
                                                       detecseq=4  
                                                    endif
                                                    if ~strmatch(current.obsclass, 'AstromSTD',/fold) && ~strmatch(current.obsclass, 'Science',/fold) then begin
                                                       detectype=3
                                                       detecseq=7  
                                                    endif
                                                endif else begin 
                                                    if n_elements(file_filt_obst_disp_occ_obs_itime_object) GE 5 then begin
                                                        detectype=1
                                                        detecseq=3 
                                                    endif else begin
                                                        detectype=1
                                                        detecseq=1 
                                                    endelse
                                                endelse
                                            endelse                       
                                        end     
                                        else: begin 
                                            ;if strmatch(uniqsortedobstype[fc], '*laser*') then begin
                                            if strmatch(uniqsortedobstype[indsortseq[fc]], '*laser*') then begin
                                                                    detectype=1
                                                                    detecseq=1 
                                            endif else begin
                                               self->Log, "Not sure what to do about obstype '"+uniqsortedobstype[indsortseq[fc]]+"'. Going to try the 'Fix Keywords' recipe but that's just a guess."
                                              ;add missing keywords
                                              detectype=3
                                              detecseq=5
                                            endelse
                                        end
                                        endcase

                                        if detectype eq -1 then continue
                                        typetab=['astr_spec_','astr_pol_','cal_spec_','cal_pol_','online_']
                                        typename=typetab[detectype-1]           
                                        drf_to_load = self.tempdrfdir+'templates_drf_'+typename+strc(detecseq)+'.xml'
                    if keyword_set(mode) && (mode eq 2) then if (total(strmatch(remcharf(file_filt_obst_disp_occ_obs_itime_object,path_sep()),remcharf(file[cindex-1]+'*',path_sep()))) eq 0) then continue
                                        self->create_drf_from_template, drf_to_load, file_filt_obst_disp_occ_obs_itime_object, current, datetimestr=datetimestr, mode=mode

                                    endfor ;loop on object
                                endfor ;loop on itime
                            endfor ;loop on obsclass
                        endfor ;loop on fo occulteur    
                    endfor  ;loop on fd disperser
                endfor ;loop on fc obstype
            endfor ;loop on ff filter
        endif ;cond on n_elements(file) 
    endif ;condition on cindex>0, assure there are data to process

    

    void=where(file ne '',cnz)
    self->Log,strtrim(cnz,2)+' files added.'
    ;self->Log,'resolved FILTER band: '+self.filter


end
;-----------------------------------------
pro parsergui::cleanfilelist, fitsfiles=fitsfiles
    widget_control,self.top_base,get_uvalue=storage
      if ~keyword_set(fitsfiles) then begin
          
            (*storage.splitptr).findex = 0
            (*storage.splitptr).selindex = 0
            (*storage.splitptr).filename[*] = ''
            (*storage.splitptr).printname[*] = '' 
            (*storage.splitptr).printfname[*] = '' 
            (*storage.splitptr).datefile[*] = ''  
             widget_control,storage.fname,set_value=(*storage.splitptr).printname          
            self->Log,'All items removed.'
       endif else begin
             oldind=(*storage.splitptr).findex
            (*storage.splitptr).findex = n_elements(fitsfiles)
            (*storage.splitptr).selindex = 0            
            (*storage.splitptr).filename[0:n_elements(fitsfiles)-1] = fitsfiles

            if n_elements(where((*storage.splitptr).printname) ne '') gt n_elements(fitsfiles) then begin
              pn=(*storage.splitptr).printfname
            (*storage.splitptr).printname[*] = '' 
            (*storage.splitptr).printfname[*] = '' 
              (*storage.splitptr).printname[0:n_elements(fitsfiles)-1]= pn[oldind-n_elements(fitsfiles):oldind-1]
               (*storage.splitptr).printfname[0:n_elements(fitsfiles)-1]= pn[oldind-n_elements(fitsfiles):oldind-1]
                widget_control,storage.fname,set_value=(*storage.splitptr).printfname
            endif
            (*storage.splitptr).datefile[*] = '' 
            self->Log,'All items corresponding to old sequences removed.'
       endelse     


end
;-----------------------------------------
pro parsergui::create_drf_from_template, templatename, fitsfiles, current, datetimestr=datetimestr, mode=mode

    self->loaddrf, templatename ,  /nodata
    self->savedrf, fitsfiles, prefix=self.nbdrfSelec+1, datetimestr=datetimestr


    if widget_info(self.direct_id ,/button_set)  then chosenpath=self.queuepath else chosenpath=self.drfpath
    new_drf_properties = [chosenpath+path_sep()+(*self.drf_summary).filename, (*self.drf_summary).name,   (*self.drf_summary).type, $
        current.filter, current.obstype, current.dispersr, current.occulter, current.obsclass, string(current.itime,format='(F7.1)'), current.object] 

    if self.nbdrfSelec eq 0 then (*self.currDRFSelec)= new_drf_properties else $
        (*self.currDRFSelec)=[[(*self.currDRFSelec)],[new_drf_properties]]


    self.nbdrfSelec+=1

    widget_control, self.tableSelected, ysize=((size(*self.currDRFSelec))[2] > 20 )
    widget_control, self.tableSelected, set_value=(*self.currDRFSelec)[0:9,*]
    widget_control, self.tableSelected, background_color=rebin(*self.table_BACKground_colors,3,2*10,/sample)    

   if keyword_set(mode) && (mode eq 2) then self->cleanfilelist, fitsfiles=fitsfiles
end


;-----------------------------------------
; actual event handler: 
pro parsergui::event,ev

    ;get type of event
    widget_control,ev.id,get_uvalue=uval

    ;get storage
    widget_control,ev.top,get_uvalue=storage

    if size(uval,/TNAME) eq 'STRUCT' then begin
        ; TLB event, either resize or kill_request
        print, 'DRF GUI TLB event'
        case tag_names(ev, /structure_name) of

        'WIDGET_KILL_REQUEST': begin ; kill request
            if confirm(group=ev.top,message='Are you sure you want to close the Parser GUI?',$
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
              'tableselec':textinfo='Select a DRF and click View/Edit or Delete below to see or change that DRF.' ; Left-click to see or change the DRF | Right-click to remove the selected DRF from the current DRF list.'
              'text_status':textinfo='Status log message display window.'
              'ADDFILE': textinfo='Click to add files to current input list'
              'WILDCARD': textinfo='Click to add files to input list using a wildcard (*.fits etc)'
              'REMOVE': textinfo='Click to remove currently highlighted file from the input list'
              'REMOVEALL': textinfo='Click to remove all files from the input list'
              'DRFGUI': textinfo='Click to load currently selected DRF into the DRFGUI editor'
              'Delete': textinfo='Click to delete the currently selected DRF. (Cannot be undone!)'
              'DropAll': textinfo='Click to add all DRFs to the execution queue.'
              'DropOne': textinfo='Click to add the currently selected DRF to the execution queue.'
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
    endif
      
    ; Menu and button events: 
    case uval of 

    'tableselec':begin      
            IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CELL_SEL') && (ev.sel_top ne -1) THEN BEGIN  ;LEFT CLICK
                selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
                ;;uptade arguments tab
                if n_elements((*self.currDRFSelec)) eq 0 then return
                self.nbDRFSelec=n_elements((*self.currDRFSelec)[0,*])
                ;print, self.nbDRFSelec
                ; FIXME check error condition for nothing selected here. 
                indselected=selection[1]
                if indselected lt self.nbDRFSelec then self.selection =(*self.currDRFSelec)[0,indselected]
                ;if indselected lt self.nbDRFSelec then begin 
                    ;print, "Starting DRFGUI with "+ (*self.currDRFSelec)[0,indselected]
                    ;gpidrfgui, drfname=(*self.currDRFSelec)[0,indselected], self.top_base
                ;endif  
                     
            ENDIF 
;            IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_CONTEXT') THEN BEGIN  ;RIGHT CLICK
;                  selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
;                  indselected=selection[1]
;                  if (indselected ge 0) AND  (indselected lt self.nbDRFSelec) AND (self.nbDRFSelec gt 1) then begin
;                      if indselected eq 0 then (*self.currDRFSelec)=(*self.currDRFSelec)[*,indselected+1:self.nbDRFSelec-1]
;                      if indselected eq (self.nbDRFSelec-1) then (*self.currDRFSelec)=(*self.currDRFSelec)[*,0:indselected-1]
;                      if (indselected ne 0) AND (indselected ne self.nbDRFSelec-1) then (*self.currDRFSelec)=[[(*self.currDRFSelec)[*,0:indselected-1]],[(*self.currDRFSelec)[*,indselected+1:self.nbDRFSelec-1]]]
;                      self.nbDRFSelec-=1
;                     
;                      (*self.order)=(*self.currDRFSelec)[3,*]
;                      
;                       widget_control,   self.tableSelected,  set_value=(*self.currDRFSelec)[0:2,*], SET_TABLE_SELECT =[-1,self.nbDRFSelec-1,-1,self.nbDRFSelec-1]
;                       widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,0]
;                  endif     
;            ENDIF
    end      
    'ADDFILE' : begin
        ;-- Ask the user to select more input files:
		if self.last_used_input_dir eq '' then self.last_used_input_dir = self->get_input_dir()

        result=dialog_pickfile(path=self.last_used_input_dir,/multiple,/must_exist,$
                title='Select Raw Data File(s)', filter=['*.fits','*.fits.gz'])
        result = strtrim(result,2)

        if result[0] ne '' then begin
			self.last_used_input_dir = file_dirname(result[0])
			self->AddFile, result
		endif

    end
    'flatreduction':begin
         self.flatreduc=widget_info(self.calibflatid,/DROPLIST_SELECT)
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
            self->Log,'Sorry, you cannot add files/directories any more.'
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

;            if ((cindex+n_elements(result)) gt n_elements(file)) then begin
;                nover = cindex+n_elements(result)-n_elements(file)
;                self->Log,'WAR: exceeding file number limit. '+$
;                    strtrim(nover,2)+' files ignored.'
;                result = result[0:n_elements(result)-1-nover]
;            endif
;            file[cindex:cindex+n_elements(result)-1] = result
;
;            for i=0,n_elements(result)-1 do begin
;                tmp = strsplit(result[i],path_sep(),/extract)
;                pfile[cindex+i] = tmp[n_elements(tmp)-1]+'    '
;            endfor
;
;            widget_control,storage.fname,set_value=pfile
;
;            cindex = cindex+n_elements(result)
;            (*storage.splitptr).selindex = max([0,cindex-1])
;            (*storage.splitptr).findex = cindex
;            (*storage.splitptr).filename = file
;            (*storage.splitptr).printname = pfile
;            (*storage.splitptr).datefile = datefile 
;
;            self->Log,strtrim(n_elements(result),2)+' files added.'
        endif else begin
            self->Log,'search failed (no match).'
        endelse
        
        ;give the possibility to add other files:
        ;resdiag=DIALOG_MESSAGE('Do you want to add other files before parsing? Answering No will start to parse selected data.', /QUESTION)
        ;case resdiag of 
        ;  'No':begin
        ;      if result[0] ne '' then begin
                self->AddFile, result
         ;     endif
        ;      end  
        ;  'Yes':
        ;  'Cancel':
        ;endcase
        
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
            self->Log,'All items removed.'
        endif
    end
    ;'RB'    : begin
    ;end
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

        case (self.sorttab)[sortfieldind] of 
                'obs. date/time': begin
                    juldattab=dblarr(cindex)
                    for i=0,cindex-1 do begin
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
                     obsid=strarr(cindex)
                    for i=0,cindex-1 do begin
                      obsid[i]=self->resolvekeyword( file[i], 1,'OBSID')
                    endfor
                    indsort=sort(obsid)
                end
                'alphabetic filename':  begin
                     alpha=strarr(cindex)
                    for i=0,cindex-1 do begin
                      alpha[i]= file[i]
                    endfor
                    indsort=sort(alpha)
                end
                'file creation date':begin
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
    'Delete': begin
        selection = WIDGET_INFO((self.tableSelected), /TABLE_SELECT) 
        indselected=selection[1]
        if indselected lt 0 or indselected ge self.nbDRFselec then return ; nothing selected
        self.selection=(*self.currDRFSelec)[0,indselected]


        if confirm(group=self.top_base,message=['Are you sure you want to delete the file ',self.selection+"?"], label0='Cancel',label1='Delete', title="Confirm Delete") then begin
            self->Log, 'Deleted file '+self.selection
            file_delete, self.selection,/allow_nonexist

            if self.nbDRFSelec gt 1 then begin
                indices = indgen(self.nbDRFSelec)
                new_indices = indices[where(indices ne indselected)]
                (*self.currDRFSelec) = (*self.currDRFSelec)[*, new_indices]
                (*self.order)=(*self.currDRFSelec)[3,*]
                self.nbDRFSelec-=1
            endif else begin
                self.nbDRFSelec=0
                (*self.currDRFSelec)[*] = ''
                (*self.order)=0
            endelse
    
            ;if (indselected ge 0) AND  (indselected lt self.nbDRFSelec) AND (self.nbDRFSelec ge 1) then begin
                  ;if indselected eq 0 then (*self.currDRFSelec)=(*self.currDRFSelec)[*,indselected+1:self.nbDRFSelec-1]
                  ;if indselected eq (self.nbDRFSelec-1) then (*self.currDRFSelec)=(*self.currDRFSelec)[*,0:indselected-1]
                  ;if (indselected ne 0) AND (indselected ne self.nbDRFSelec-1) then (*self.currDRFSelec)=[[(*self.currDRFSelec)[*,0:indselected-1]],[(*self.currDRFSelec)[*,indselected+1:self.nbDRFSelec-1]]]
                 
                  
            widget_control,   self.tableSelected,  set_value=(*self.currDRFSelec)[*,*], SET_TABLE_SELECT =[-1,-1,-1,-1] ; no selection
            widget_control,   self.tableSelected, SET_TABLE_VIEW=[0,0]
              ;endif     

        endif
    end
    'DRFGUI': begin
        if self.selection eq '' then return
            gpidrfgui, drfname=self.selection, self.top_base
    end


    'DropAll'  : begin
                self->Log, "Adding all DRFs to queue in "+self.queuepath
                for ii=0,self.nbdrfSelec-1 do begin
                    if (*self.currDRFSelec)[0,ii] ne '' then begin
                          self->queue, (*self.currDRFSelec)[0,ii]
                      endif
                endfor      
                self->Log,'All DRFs have been succesfully added to the queue.'
              end
    'DropOne'  : begin
        if self.selection eq '' then begin
              self->Log, "Nothing is currently selected!"
              return ; nothing selected
        endif else begin
            self->queue, self.selection
            self->Log,'Queued '+self.selection
        endelse
    end
    'QUIT'    : begin
        if confirm(group=ev.top,message='Are you sure you want to close the Parser GUI?',$
            label0='Cancel',label1='Close', title='Confirm close') then obj_destroy, self
    end
    'direct':begin
        if widget_info(self.direct_id ,/button_set)  then chosenpath=self.queuepath else chosenpath=self.drfpath
        self->Log,'All DRFs will be created in '+chosenpath
    end
      'about': begin
              tmpstr=about_message()
              ret=dialog_message(tmpstr,/information,/center,dialog_parent=ev.top)
    end ;; case: 'about'
    else: begin
        addmsg, storage.info, 'Unknown event in event handler - ignoring it!'+uval
        message,/info, 'Unknown event in event handler - ignoring it!'+uval

    end
endcase

end
;--------------------------------------
; Save a DRF to a file on disk.
;   
;   file        string array of FITS files for input to this DRF
;
;   prefix=        prefix for filename
;   datetimestr=    middle part of filename
;                   (supplied so all parsed DRFs match in timestamp)
;
;   /template    save this as a template
;
pro parsergui::savedrf, file, template=template, prefix=prefix, datetimestr=datetimestr

    ; Determine input FITS files
    index = where(file ne '',count)
    selectype=self.currtype

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
      self->Log,'file list is empty.'
      if (selectype eq 4) then self->Log,'Please select any file in the data input directory.'
      return
    endif

    file = file[index]

    ; Determine filename to use for output
    if templatesflag then begin
      (*self.drf_summary).filename = self.loadedDRF ;to check
    endif else begin     
      if ~keyword_set(datetimestr) then begin
            caldat,systime(/julian),month,day,year, hour,minute,second
          datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
          hourstr = string(hour,minute,format='(i2.2,i2.2)')  
          datetimestr=datestr+'-'+hourstr
      endif
      if keyword_set(prefix) then prefixname=string(prefix, format="(I03)") else prefixname=''
      (*self.drf_summary).filename=datetimestr+"_"+prefixname+'_drf.waiting.xml'
    endelse

    ;get drf filename and set drfpath:
    ;if ~keyword_set(nopickfile) then begin
        ;newdrffilename = DIALOG_PICKFILE(TITLE='Save Data Reduction File (DRF) as', /write,/overwrite, filter='*.xml',file=(*self.drf_summary).filename,path=drfpath, get_path=newdrfpath)
        ;if newdrffilename eq "" then return ; user cancelled the save as dialog, so don't save anything.
        ;self.drfpath  = newdrfpath ; MDP change - update the default directory to now match whatever the user selected in the dialog box.
    ;endif else newdrffilename = (*self.drf_summary).filename
    ;newdrffilename = (*self.drf_summary).filename
    
    if (self.nbmoduleSelec ne '') && ( (*self.drf_summary).filename ne '') then begin
        if widget_info(self.direct_id ,/button_set)  then chosenpath=self.queuepath else chosenpath=self.drfpath

		if ~self->check_output_path_exists(chosenpath) then return

        message,/info, "Writing to "+chosenpath+path_sep()+(*self.drf_summary).filename 
        OpenW, lun, chosenpath+path_sep()+(*self.drf_summary).filename, /Get_Lun
        PrintF, lun, '<?xml version="1.0" encoding="UTF-8"?>' 
     
           
        if selectype eq 4 then begin
            PrintF, lun, '<DRF LogPath="'+self.logpath+'" ReductionType="OnLine">'
        endif else begin
            PrintF, lun, '<DRF LogPath="'+self.logpath+'" ReductionType="'+(*self.template_types)[selectype] +'" Name="'+(*self.drf_summary).name+'" >'
        endelse

        PrintF, lun, '<dataset InputDir="'+self.inputdir+'" Name="" OutputDir="'+self.outputdir+'">' 
     
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
        self->Log,'Saved  '+(*self.drf_summary).filename+ " in "+chosenpath
        
        ;display last paramtab
                    indselected=self.nbmoduleSelec-1
                   self->extractparam, float((*self.currModSelec)[4,indselected])    
                  *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
                  if (*self.indarg)[0] ne -1 then begin
                      (*self.currModSelecParamTab)[*,0]=((*self.ConfigDRS).argname)[[*self.indarg]]
                      (*self.currModSelecParamTab)[*,1]=((*self.ConfigDRS).argdefault)[[*self.indarg]]
                      (*self.currModSelecParamTab)[*,2]=((*self.ConfigDRS).argdesc)[[*self.indarg]]
                  endif
              
        
    endif
end
;-------------------------------------
pro parsergui::loaddrf, filename, storage, nodata=nodata, silent=silent

    if keyword_set(filename) then self.loadedDRF=filename

    if self.loadedDRF eq '' then return

    debug=0


    widget_control,self.top_base,get_uvalue=storage  

    
    ; now parse the requested DRF.
    ; First re-parse the config file (so we know about all the available modules
    ; and their arguments)
    ConfigParser = self->get_configParser()
    Parser = OBJ_NEW('gpiDRFParser')
    if ~(keyword_set(silent)) then self->Log, "Parsing: "+self.loadedDRF

    ; then parse the DRF and get its contents
    Parser ->ParseFile, self.loadedDRF,  ConfigParser, silent=silent, status=status

    if status eq -1 then begin
        message, "Could not parse DRF: "+self.loadedDRF,/info
        return
    endif


    drf_summary = Parser->get_summary()
    drf_contents = Parser->get_drf_contents()

    drf_module_names = drf_contents.modules.name

    
    *self.drf_summary = drf_summary


    ; if requested, load the filenames in that DRF
    ; (for Template use, don't load the data)
    if ~keyword_set(nodata) then  begin
        self.inputdir=drf_contents.inputdir
         ;;get list of files in the drf
         if strcmp((drfmodules.fitsfilenames)[0],'') ne 1  then begin
            (*storage.splitptr).filename = drf_contents.fitsfilenames
            (*storage.splitptr).printname = drf_contents.fitsfilenames
            widget_control,storage.fname,set_value=(*storage.splitptr).printname
        endif
    endif


    ;if necessary, update reduction type to match whatever is in that DRF (and update available modules list too)
    if self.reductiontype ne drf_summary.type then begin
        selectype=where(*self.template_types eq drf_summary.type, matchct)
        if matchct eq 0 then message,"ERROR: no match for "+self.reductiontype
        self.currtype=selectype
        self->changetype, selectype[0], /notemplate
    endif
    

    ; Now load the modules of the selected DRF:
    self.nbmoduleSelec=0
    indseqini=intarr(n_elements(drf_module_names))
    seq=((*self.ConfigDRS).names)[(*self.indmodtot2avail)[*self.curr_mod_indsort]] 
    ; seq is list of currently available modules, in alphabetical order
    
    for ii=0,n_elements(drf_module_names)-1 do begin
         indseqini[ii]=where(strmatch(seq,(drf_module_names)[ii],/fold_case), matchct)
         ; indseqini is indices of the DRF's modules into the seq array.
         if matchct eq 0 then message,/info,"ERROR: no match for module="+ (drf_module_names)[ii]
    endfor

    
    for ii=0,n_elements(drf_module_names)-1 do begin
        if self.nbmoduleSelec eq 0 then (*self.currModSelec)=([(drf_module_names)[0],'','','','']) $  
        else  (*self.currModSelec)=([[(*self.currModSelec)],[[(drf_module_names)[ii],'','','','']]])
        self.nbmoduleSelec+=1

        ;does this module need calibration file?
        ind=where(strmatch(tag_names((drf_contents.modules)[ii]),'CALIBRATIONFILE'), matchct)
        if ind ne [-1] then begin
                   (*self.currModSelec)[2,self.nbmoduleSelec-1]=((drf_contents.modules)[ii]).calibrationfile
        endif
        (*self.currModSelec)[3,self.nbmoduleSelec-1]=((*self.ConfigDRS).order)[(*self.indmodtot2avail)[(*self.curr_mod_indsort)[indseqini[ii]]]] 

 
    endfor

    ;sort *self.currModSelec with ORDER 
    (*self.order)=float((*self.currModSelec)[3,*])

; MDP edit: Do not re-sort loaded DRFs - just use exactly what is in the
; template.     
    (*self.currModSelec)[4,*]=strc(indseqini)
;        ;;todo:check out there are no duplicate order (sinon la table d argument va se meler) 
;        (*self.currModSelec)=(*self.currModSelec)[*,sort(*self.order)]  
;        (*self.currModSelec)[4,*]=strc(indseqini[sort(*self.order)])
;        (*self.order)=(*self.currModSelec)[3,*]


    if debug then if not array_equal(seq[indseqini], (*self.currModSelec)[0,*]) then message, "Module arrays appear confused"
    
    for ii=0,n_elements(drf_module_names)-1 do begin
        if debug then print, "-----"
        if debug then print, drf_module_names[ii]," / ",  (*self.currModSelec)[0,ii]
        if drf_module_names[ii] ne (*self.currModSelec)[0,ii] then message,"Module names don't match..."
        self->extractparam, float((*self.currModSelec)[4,ii])  ; loads indarg

        if debug then print, "   has argument(s): "+ strjoin(((*self.ConfigDRS).argname)[[*self.indarg]], ", " )

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
                endif else begin
	        	    argtab=((*self.ConfigDRS).argdefault)
	    	        argtab[(*self.indarg)[jj]]=((drf_contents.modules)[ii]).(indtag[0]) ;use parentheses as Facilities exist to process structures in a general way using tag numbers rather than tag names
		            ((*self.ConfigDRS).argdefault)=argtab
				endelse
        ;    (*self.currModSelecParamTab)[jj,1]=
        endfor
        if debug then print, "   has value(s): "+ strjoin(((*self.ConfigDRS).argdefault)[[*self.indarg]], ", " )
    endfor

    ;display last paramtab
    indselected=self.nbmoduleSelec-1
    *self.currModSelecParamTab=strarr(n_elements(*self.indarg),3)
    if (*self.indarg)[0] ne -1 then begin
        (*self.currModSelecParamTab)[*,0]=((*self.ConfigDRS).argname)[[*self.indarg]]
        (*self.currModSelecParamTab)[*,1]=((*self.ConfigDRS).argdefault)[[*self.indarg]]
        (*self.currModSelecParamTab)[*,2]=((*self.ConfigDRS).argdesc)[[*self.indarg]]
    endif
    obj_destroy, ConfigParser
    obj_destroy, Parser

end

;------------------------------------------------
pro parsergui::cleanup

    ptr_free, self.currDRFselec

    
    self->drfgui::cleanup ; will destroy all widgets
end


;------------------------------------------------
function parsergui::init_widgets, testdata=testdata, _extra=_Extra  ;drfname=drfname,  ;,groupleader,group,proj

	self.DEBUG = 0 ; print extra stuff?

    self->startup

    ;create base widget. 
    ;   Resize to be large on desktop monitors, or shrink to fit on laptops.
    ;-----------------------------------------
    screensize=get_screen_size()

    if screensize[1] lt 900 then begin
      nlines_status=12
      nlines_fname=10
      nlines_modules=7
      nlines_args=6
    endif else begin
      nlines_status=12
      nlines_fname=10
      nlines_modules=10
      nlines_args=6
    endelse
    CASE !VERSION.OS_FAMILY OF  
        ; **NOTE** Mac OS X reports an OS family of 'unix' not 'MacOS'
       'unix': begin 
        self.top_base=widget_base(title='GPI Parser: Create a Set of Data Reduction Files', $
        /BASE_ALIGN_LEFT,/column, MBAR=bar,/tlb_size_events, /tlb_kill_request_events, resource_name='GPI_DRP_Parser' )
        
         end
       'Windows'   :begin
       self.top_base=widget_base(title='GPI Parser: Create a Set of Data Reduction Files', $
        /BASE_ALIGN_LEFT,/column, MBAR=bar,bitmap=self.dirpro+path_sep()+'gpi.bmp',/tlb_size_events, /tlb_kill_request_events)
       
         end

    ENDCASE

    parserbase=self.top_base
    ;create Menu
    file_menu = WIDGET_BUTTON(bar, VALUE='File', /MENU) 
    file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Quit Parser', UVALUE='QUIT')
;    ;file_bttn1=WIDGET_BUTTON(file_menu, VALUE='Save Configuration..',   UVALUE='FILE1') 
;    file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Open DRF...', UVALUE='LOADDRF') 
;    file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Open DRF with Data...', UVALUE='LOADDRFWITHDATA') 
;    file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Save DRF as...', UVALUE='Create')
;    file_bttn2=WIDGET_BUTTON(file_menu, VALUE='Save templates-DRF as...', UVALUE='CreateTemplate')
;    file_bttn3=WIDGET_BUTTON(file_menu, VALUE='Set default directories...', UVALUE='defaultdir') 


    ;create file selector
    ;-----------------------------------------
    DEBUG_SHOWFRAMES=0
    top_basefilebutt=widget_base(parserbase,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES, /base_align_center)
    label = widget_label(top_basefilebutt, value="Input FITS Files:")
    button=widget_button(top_basefilebutt,value="Add File(s)",uvalue="ADDFILE", $
        xsize=90,ysize=30, /tracking_events);,xoffset=10,yoffset=115)
    button=widget_button(top_basefilebutt,value="Wildcard",uvalue="WILDCARD", $
        xsize=90,ysize=30, /tracking_events);,xoffset=110,yoffset=115)
    button=widget_button(top_basefilebutt,value="Remove",uvalue="REMOVE", $
        xsize=90,ysize=30, /tracking_events);,xoffset=210,yoffset=115)
    button=widget_button(top_basefilebutt,value="Remove All",uvalue="REMOVEALL", $
        xsize=90,ysize=30, /tracking_events);,xoffset=310,yoffset=115)
    ;top_basefilebutt2=widget_base(top_basefilebutt,/BASE_ALIGN_LEFT,/row,frame=DEBUG_SHOWFRAMES)
    top_basefilebutt2=top_basefilebutt
    self.sorttab=['obs. date/time','alphabetic filename','file creation date']
    self.sortfileid = WIDGET_DROPLIST( top_basefilebutt2, title='Sort data by:',  Value=self.sorttab,uvalue='sortmethod')
    drfbrowse = widget_button(top_basefilebutt2,  $
                            XOFFSET=174 ,SCR_XSIZE=80, ysize= 30 $; ,SCR_YSIZE=23  $
                            ,/ALIGN_CENTER ,VALUE='Sort data',uvalue='sortdata')                          
        
    top_baseident=widget_base(parserbase,/BASE_ALIGN_LEFT,/row, frame=DEBUG_SHOWFRAMES)
    ; file name list widget
    fname=widget_list(top_baseident,xsize=106,scr_xsize=580, ysize=nlines_fname,$
            xoffset=10,yoffset=150,uvalue="FNAME", /TRACKING_EVENTS,resource_name='XmText')

    ; add 5 pixel space between the filename list and controls
    top_baseborder=widget_base(top_baseident,xsize=5,units=0, frame=DEBUG_SHOWFRAMES)

    ; add the options controls
    top_baseidentseq=widget_base(top_baseident,/BASE_ALIGN_LEFT,/column,  frame=DEBUG_SHOWFRAMES)
    top_baseborder=widget_base(top_baseidentseq,ysize=1,units=0)          
    top_baseborder2=widget_base(top_baseidentseq,/BASE_ALIGN_LEFT,/row)
    drflabel=widget_label(top_baseborder2,Value='Output Dir=         ')
    self.outputdir_id = WIDGET_TEXT(top_baseborder2, $
                xsize=34,ysize=1,$
                /editable,units=0,value=self.outputdir )    

    drfbrowse = widget_button(top_baseborder2,  $
                        XOFFSET=174 ,SCR_XSIZE=75 ,SCR_YSIZE=23  $
                        ,/ALIGN_CENTER ,VALUE='Change...',uvalue='outputdir')
    top_baseborder3=widget_base(top_baseidentseq,/BASE_ALIGN_LEFT,/row)
    drflabel=widget_label(top_baseborder3,Value='Log Path=           ')
    self.logpath_id = WIDGET_TEXT(top_baseborder3, $
                xsize=34,ysize=1,$
                /editable,units=0 ,value=self.logpath)
    drfbrowse = widget_button(top_baseborder3,  $
                        XOFFSET=174 ,SCR_XSIZE=75 ,SCR_YSIZE=23  $
                        ,/ALIGN_CENTER ,VALUE='Change...',uvalue='logpath') 
                        
    calibflattab=['Flat-field extraction','Flat-field & Wav. solution extraction']
    ;the following line commented as it will not be used (uncomment line in post_init if you absolutely want it)
   ; self.calibflatid = WIDGET_DROPLIST( top_baseidentseq, title='Reduction of flat-fields:  ', frame=0, Value=calibflattab, uvalue='flatreduction')
        ;one nice logo 
  button_image = READ_BMP(self.dirpro+path_sep()+'gpi.bmp', /RGB) 
  button_image = TRANSPOSE(button_image, [1,2,0]) 
  button = WIDGET_BUTTON(top_baseident, VALUE=button_image,  $
      SCR_XSIZE=100 ,SCR_YSIZE=95, sensitive=1 $
       ,uvalue='about')                  
    ;top_baseborderz=widget_base(top_baseidentseq,/BASE_ALIGN_LEFT,/row)
    

        ; what colors to use for cell backgrounds? Alternate rows between
        ; white and off-white pale blue
        self.table_BACKground_colors = ptr_new([[255,255,255],[240,240,255]])


        xsize=10
        self.tableSelected = WIDGET_TABLE(parserbase, $; VALUE=data, $ ;/COLUMN_MAJOR, $ 
                COLUMN_LABELS=['DRF Name','Recipe','Type','FILTER','OBSTYPE','DISPERSR','OCCULTER','OBSCLASS','ITIME','OBJECT'],/resizeable_columns, $
                xsize=xsize,ysize=20,uvalue='tableselec',value=(*self.currDRFSelec), /TRACKING_EVENTS,$
                /NO_ROW_HEADERS, /SCROLL,y_SCROLL_SIZE =nlines_modules,scr_xsize=1150, COLUMN_WIDTHS=[340,200,100,70,70,70,70,70,70,70],frame=1,/ALL_EVENTS,/CONTEXT_EVENTS, $
                    background_color=rebin(*self.table_BACKground_colors,3,2*10,/sample)    ) ;,/COLUMN_MAJOR                

        ; Create the status log window 
        tmp = widget_label(parserbase, value="   " )
        tmp = widget_label(parserbase, value="History: ")
        info=widget_text(parserbase,/scroll, xsize=160,scr_xsize=800,ysize=nlines_status, /ALIGN_LEFT, uval="text_status",/tracking_events);xoffset=5,yoffset=5)
        self.widget_log = info

    ;;create execute and quit button
    ;-----------------------------------------
    top_baseexec=widget_base(parserbase,/BASE_ALIGN_LEFT,/row)
    button2b=widget_button(top_baseexec,value="Drop all DRFs in Queue",uvalue="DropAll", /tracking_events)
    button2b=widget_button(top_baseexec,value="Drop selected DRF only",uvalue="DropOne", /tracking_events)
     directbase = Widget_Base(top_baseexec, UNAME='directbase' ,COLUMN=1 ,/NONEXCLUSIVE, frame=0)
     self.direct_id =    Widget_Button(directbase, UNAME='direct'  $
      ,/ALIGN_LEFT ,VALUE='Drop all DRFs in Queue by default',uvalue='direct' )
	
	if gpi_get_setting('parsergui_auto_queue',/bool) then widget_control,self.direct_id, /set_button   

    space = widget_label(top_baseexec,uvalue=" ",xsize=100,value='  ')
    button2b=widget_button(top_baseexec,value="View/Edit in DRFGUI",uvalue="DRFGUI", /tracking_events)
    button2b=widget_button(top_baseexec,value="Delete selected DRF",uvalue="Delete", /tracking_events)

    space = widget_label(top_baseexec,uvalue=" ",xsize=200,value='  ')
    button3=widget_button(top_baseexec,value="Close Parser GUI",uvalue="QUIT", /tracking_events, resource_name='red_button')

    self.textinfoid=widget_label(parserbase,uvalue="textinfo",xsize=900,value='  ')
    ;-----------------------------------------
    maxfilen=550
    filename=strarr(maxfilen)
    printname=strarr(maxfilen)
     printfname=strarr(maxfilen)
    datefile=lonarr(maxfilen)
    findex=0
    selindex=0
    splitptr=ptr_new({filename:filename,printname:printname,printfname:printfname,$
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
        self:self}
    widget_control,parserbase,set_uvalue=storage,/no_copy
;if (not(xregistered('parsergui', /noshow))) then begin
;    widget_control,top_base,/realize
;
    self->log, "This GUI helps you to parse a set of data."
    self->log, "Add files to be processed and control created DRFs."
;  ;event loop
;  ;-----------------------------------------
;
;  xmanager,'drfgui',top_base,/no_block,group_leader=groupleader
;    
;endif
    return, parserbase

end


;-----------------------
pro parsergui::post_init, _extra=_extra
            	;widget_control, self.calibflatid, set_droplist_select= 0;1 ;0
end

;-----------------------
PRO parsergui__define


    state = {  parsergui,                 $
              testdata:0L,$
              typetab:strarr(5),$
              ;seqtab1:strarr(3),$
              ;seqtab2:strarr(1),$
              ;seqtab3:strarr(8),$
              ;seqtab4:strarr(2),$
              ;seqtab5:strarr(5),$    
              loadedinputdir:'',$
              calibflatid:0L,$
              flatreduc:0,$
              direct_id:0L,$
              ;loadedfilenames:ptr_new(/ALLOCATE_HEAP), $
              ;loadedmodules:ptr_new(/ALLOCATE_HEAP), $
              ;loadedmodulesstruc:ptr_new(/ALLOCATE_HEAP), $
              selectype:0,$
              currtype:0,$
              currseq:0,$
              nbdrfSelec:0,$
              selection: '', $
			  DEBUG:0, $
			  last_used_input_dir: '', $ ; save the most recently used directory. Start there again on subsequent file additions
              currDRFSelec: ptr_new(), $
           INHERITS drfgui}


end
