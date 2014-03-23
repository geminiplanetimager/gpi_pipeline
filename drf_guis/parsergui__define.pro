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
; parsergui::extractparam
;   Extract parameters from a given primitive in a recipe
;-
pro parsergui::extractparam, modnum 
;   modnum is the index of the selected module in the CURRENTLY ACTIVE LIST for
;   this mode
    *self.indarg=where(   ((*self.PrimitiveInfo).argmodnum) eq ([(*self.indmodtot2avail)[(*self.curr_mod_indsort)[modnum]]]+1)[0], carg)
end


;+-----------------------------------------
; parsergui::addfile
;
;     This adds a list of files to the current list
;
;     Add one or more new file(a) to the Input FITS files list, validate them
;     and check keywords, and then apply the parsing rules to generate recipes.
;
;-
pro parsergui::addfile, filenames


    widget_control,self.top_base,get_uvalue=storage  
    index = (*storage.splitptr).selindex
    cindex = (*storage.splitptr).findex
    file = (*storage.splitptr).filename
    pfile = (*storage.splitptr).printname
    datefile = (*storage.splitptr).datefile

	t0 = systime(/seconds)

    ;-- can we add more files now?
    if (file[n_elements(file)-1] ne '') then begin
		msgtext='Sorry, maximum number of files reached. You cannot add any additional files/directories. Edit max_files_per_recipe in pipeline config if you want to add more.'
        self->Log, msgtext
        res = dialog_message(msgtxt,/error,dialog_parent=self.top_base)
        return
    endif

    for i=0,n_elements(filenames)-1 do begin   ; Check for duplicate
        if (total(file eq filenames[i]) ne 0) then filenames[i] = ''
    endfor


    w = where(filenames ne '', wcount) ; avoid blanks
    if wcount eq 0 then void=dialog_message('No new files. Please add new files before parsing.')
    if wcount eq 0 then return
    filenames = filenames[w]

    if ((cindex+n_elements(filenames)) gt n_elements(file)) then begin
        nover = cindex+n_elements(filenames)-n_elements(file)
        self->Log,'WARNING: You tried to add more files than the file number limit, currently '+strc(n_elements(file))+". Adjust pipeline setting 'max_files_per_recipe' in your config file if you want to load larger datasets at once." +$
            strtrim(nover,2)+' files ignored.'
        filenames = filenames[0:n_elements(filenames)-1-nover]
    endif

    file[cindex:cindex+n_elements(filenames)-1] = filenames

    ;for i=0,n_elements(filenames)-1 do begin
        ;tmp = strsplit(filenames[i],path_sep(),/extract)
        ;pfile[cindex+i] = tmp[n_elements(tmp)-1]+'    '
    ;endfor

    ;self.inputdir=strjoin(tmp[0:n_elements(tmp)-2],path_sep())
    ;if !VERSION.OS_FAMILY ne 'Windows' then self.inputdir = "/"+self.inputdir 
    cindex = cindex+n_elements(filenames)
    (*storage.splitptr).selindex = max([0,cindex-1])
    (*storage.splitptr).findex = cindex
    (*storage.splitptr).filename = file
    (*storage.splitptr).printname = pfile
    (*storage.splitptr).datefile = datefile 




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
pro parsergui::removefile, filenames


    widget_control,self.top_base,get_uvalue=storage  
    index = (*storage.splitptr).selindex
    cindex = (*storage.splitptr).findex
    file = (*storage.splitptr).filename
    pfile = (*storage.splitptr).printname
    datefile = (*storage.splitptr).datefile

	t0 = systime(/seconds)

    self->Log, "Removing files from data parser needs to be implemented"

	stop
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

    widget_control,self.top_base,get_uvalue=storage  
    index = (*storage.splitptr).selindex
    cindex = (*storage.splitptr).findex
    file = (*storage.splitptr).filename
    pfile = (*storage.splitptr).printname
    datefile = (*storage.splitptr).datefile

	t0 = systime(/seconds)


	; discard any blanks. 
	wnotblank = where(file ne '')
	file=file[wnotblank]


    ;self.inputdir=strjoin(tmp[0:n_elements(tmp)-2],path_sep())
    ;if !VERSION.OS_FAMILY ne 'Windows' then self.inputdir = "/"+self.inputdir 


    self->Log, "Loading and parsing files..."
    ;-- Update information in the structs
    ;cindex = cindex+n_elements(filenames)
    (*storage.splitptr).selindex = max([0,cindex-1])
    (*storage.splitptr).findex = cindex
    (*storage.splitptr).filename = file
    (*storage.splitptr).printname = pfile
    (*storage.splitptr).datefile = datefile 

    ;;TEST DATA SANITY
    ;;ARE THEY VALID  GEMINI & GPI & IFS DATA?
	
    if gpi_get_setting('strict_validation',/bool, default=1,/silent)  then begin

		nfiles = n_elements(file)
        valid=bytarr(nfiles)

        for ff=0, nfiles-1 do begin
			;print, "time 2, file "+strc(ff)+": ", systime(/seconds) - t0
			if self.debug then message,/info, 'Verifying keywords for file '+file[ff]
			if self.debug then message,/info, '  This code needs to be made more efficient...'
              widget_control,self.textinfo_id,set_value='Verifying keywords for file '+file[ff]

            valid[ff]=gpi_validate_file( file[ff] ) 
        endfor  

        indnonvalid=where(valid eq 0, cnv, complement=wvalid, ncomplement=countvalid)
        if cnv gt 0 then begin
            self->Log,'WARNING: invalid files (based on FITS keywords) have been detected and removed:' + strjoin(file[indnonvalid],",")

            if countvalid eq 0 then file=''
            if countvalid gt 0 then file=file[wvalid]
			nfiles = n_elements(file)

			(*storage.splitptr).selindex = max([0,countvalid-1])
			(*storage.splitptr).findex = countvalid
			(*storage.splitptr).filename = file
			(*storage.splitptr).printname = file
			(*storage.splitptr).datefile = datefile 
        endif else begin
			self->Log, "All "+strc(n_elements(file))+" files pass basic FITS keyword validity check."
		endelse
      
    endif else begin ;if data are test data don't remove them but inform a bit

		nfiles = n_elements(file) ;edited by SGW 

                for ff=0, nfiles-1 do begin
			if self.debug then message,/info, 'Checking for valid headers: '+file[ff]
			valid = gpi_validate_file(file[ff]) ;Changed index from i to ff, SGW
		endfor
    endelse
    ;(*self.currModSelec)=strarr(5)
    (*self.recipes_table)=strarr(10)

    for i=0,nfiles-1 do pfile[i] = file_basename(file[i]) 
    widget_control,storage.fname,set_value=pfile ; update displayed filename information - temporary, just show filenames

    if nfiles gt 0 then begin ;assure that data are selected
		self->Log,'Now reading in keywords for all files...'

        self.num_recipes_in_table=0
        tmp = self->get_obs_keywords(file[0])
        finfo = replicate(tmp,nfiles)

        for jj=0,nfiles-1 do begin
            finfo[jj] = self->get_obs_keywords(file[jj])
            ;;we want Xenon&Argon considered as the same 'lamp' object for Y,K1,K2bands (for H&J, better to do separately to keep only meas. from Xenon)
            ;if (~strmatch(finfo[jj].filter,'[HJ]')) && (strmatch(finfo[jj].object,'Xenon') || strmatch(finfo[jj].object,'Argon')) then $
                    ;finfo[jj].object='Lamp'
            pfile[jj] = finfo[jj].summary
        endfor
		wnz = where(pfile ne '')
        widget_control,storage.fname,set_value=pfile[wnz] ; update displayed filename information - filenames plus parsed keywords

		wvalid = where(finfo.valid, nvalid, complement=winvalid, ncomplement=ninvalid)
		if ninvalid gt 0 then begin
			self->Log, "Some files are lacking valid required FITS keywords: "
			self->Log, strjoin(file[winvalid], ", ")
			self->Log, "These will be ignored in all further parsing steps."
			if wvalid[0] eq -1 then begin
        ret=dialog_message("ERROR: All files rejected",/error,/center,dialog_parent=self.top_base)
				return
			endif
			finfo = finfo[wvalid]
		endif


		self->Log,'Now analyzing data based on keywords...'


		; Mark filter as irrelevant for Dark exposures
		wdark = where(strlowcase(finfo.obstype) eq 'dark', dct)
		if dct gt 0 then finfo[wdark].filter='-'

        if (n_elements(file) gt 0) && (strlen(file[0]) gt 0) then begin

            ; save starting date and time for use in DRF filenames
            ;caldat,systime(/julian),month,day,year, hour,minute,second
            ;datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
            ;hourstr = string(hour,minute,format='(i2.2,i2.2)')  
          
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
                  if strmatch((finfo.dispersr)[itmp],'*POL*',/fold) or strmatch((finfo.dispersr)[itmp],'*WOLL*',/fold)  then $
					(finfo[itmp].obsclass) = 'POLARSTD'
              endif
              if strmatch((finfo.astromtc)[itmp],'*TRUE*',/fold) then (finfo[itmp].obsclass) = 'Astromstd'
            endfor
            uniqobsclass = uniqvals(finfo.obsclass, /sort)
            uniqitimes = uniqvals(finfo.itime, /sort)
            uniqobjects = uniqvals(finfo.object, /sort)
            ;uniqelevation = uniqvals(finfo.elevatio, /sort)
;            uniqgcalfilt = uniqvals(finfo.gcalfilt,/sort)

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
                ;void=where(strmatch(uniqsortedobstype,'*arc*',/fold),cwv)
                ;void=where(strmatch(uniqsortedobstype,'flat*',/fold),cflat)
                ;if ( cwv eq 0) && (cflat eq 1) && (self.flatreduc eq 1) then begin
                    ;indfobstypeflat =  where(strmatch((finfo.obstype)[indffilter],'flat*',/fold)) 
                    ;uniqsortedobstype = [uniqsortedobstype ,'wavecal']
                ;endif
                   
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

                    ;categorize by PRISM
                    for fd=0,n_elements(uniqprisms)-1 do begin
                        current.dispersr = uniqprisms[fd]
                     
                        for fo=0,n_elements(uniqocculters)-1 do begin
                            current.occulter=uniqocculters[fo]
                            
                            for fobs=0,n_elements(uniqobsclass)-1 do begin
                                current.obsclass=uniqobsclass[fobs]
 
                                for fitime=0,n_elements(uniqitimes)-1 do begin

                                    current.itime = uniqitimes[fitime]    ; in seconds, now
                                ;current.exptime =
                                ;uniqitimes[fitime] ; in seconds
                                    
                                   ;for ffilt=0,n_elements(uniqgcalfilt)-1 do begin
                                   ;    current.gcalfilt=uniqgcalfilt[ffilt]
                                   ;    print,'TEST:', current.gcalfilt,n_elements(uniqgcalfilt)
                                    
                                    for fobj=0,n_elements(uniqobjects)-1 do begin
                                        current.object = uniqobjects[fobj]
                                        ;these following 2 lines for adding Y-band flat-field in wav.solution measurement
                                        currobstype=current.obstype
                                        ;if (self.flatreduc eq 1)  && (current.filter eq 'Y') &&$
                                        ;(current.obstype eq 'Wavecal')  then currobstype='[WF][al][va][et]*'
                          
                                        indfobject = where(finfo.filter eq current.filter and $
                                                    ;finfo.obstype eq current.obstype and $
                                                    strmatch(finfo.obstype, currobstype,/fold) and $  
                                                    strmatch(finfo.dispersr,current.dispersr+"*",/fold) and $
                                                    strmatch(finfo.occulter,current.occulter+"*",/fold) and $
                                                    finfo.obsclass eq current.obsclass and $
                                                    finfo.itime eq current.itime and $
                                                    finfo.object eq current.object, cobj)
                                                    
										if self.debug then begin
											message,/info, 'Now testing the following parameters: ('+strc(cobj)+' files help) '
										;	match, current,/str
										endif

                      
    
                                        if cobj eq 0 then continue ; this particular combination of filter, obstype, dispersr, occulter, class, time, object has no files. 

										; otherwise, try to match it:
                                        file_filt_obst_disp_occ_obs_itime_object = finfo[indfobject].filename
                         

										current.obsmode = finfo[indfobject[0]].obsmode
										current.lyotmask= finfo[indfobject[0]].lyotmask
                                                             
                                        ;identify which templates to use
                                        print,  current.obstype ; uniqsortedobstype[indsortseq[fc]]
                                        self->Log, "Found sequence of OBSTYPE="+current.obstype+", OBSMODE="+current.obsmode+", DISPERSR="+current.dispersr+", IFSFILT="+current.filter+ " with "+strc(cobj)+" files targeting "+current.object

                                        case strupcase(current.obstype) of
                                        'DARK':begin
											templatename='Dark'
                                        end
                                        'ARC': begin 
                                            if  current.dispersr eq 'WOLLASTON' then begin 
												templatename='Create Polarized Flat-field'
                                            endif else begin 
												objelevation = finfo[indfobject[0]].elevatio
                                                if (objelevation lt 91.0) AND (objelevation gt 89.0) then begin 
													templatename='Wavelength Solution 2D'
                                                endif else begin
                                                    templatename='Quick Wavelength Solution'
                                                endelse
                                            endelse                     
                                        end
                                        'FLAT': begin

                                           	fits_data = gpi_load_fits(finfo[indfobject[0]].filename,/nodata,/silent)
                                                head = *fits_data.pri_header
                                                ext_head = *fits_data.ext_header
                                                ptr_free, fits_data.pri_header, fits_data.ext_header
                                                gcalfilter =  strc(  gpi_get_keyword(head, ext_head,  'GCALFILT',   count=ct13))

                                            if  current.dispersr eq 'WOLLASTON' then begin 
                                                ; handle polarization flats
                                                ; differently: compute **both**
                                                ; extraction files and flat
                                                ; fields from these data, in two
                                                ; passes
                                               
                                               ;gcalfilter = finfo[indfobject[0]].gcalfilt
                                                if gcalfilter EQ 'ND4-5' then begin
                                                   templatename='Add set of missing keywords'
                                               endif else begin
												templatename1 = self->lookup_template_filename("Calibrate Polarization Spots Locations")
												templatename2 = self->lookup_template_filename('Create Polarized Flat-field')
                                                self->create_recipe_from_template, templatename1, file_filt_obst_disp_occ_obs_itime_object, current 
                                                self->create_recipe_from_template, templatename2, file_filt_obst_disp_occ_obs_itime_object, current 
                                             endelse

                                                ;continue        aaargh can't continue inside a case. stupid IDL
                                                continue_after_case=1
                                            endif else begin              
                                               
                                          
                                               ;gcalfilter = finfo[indfobject[0]].gcalfilt
                                                if gcalfilter EQ 'ND4-5' then begin            
                                                   templatename='Add set of missing keywords'
                                               endif else begin
						   templatename='Flat-field Extraction'
                                             endelse


                                            endelse                             
                                        end
                                        'OBJECT': begin
                                           case strupcase(current.dispersr) of 
						'WOLLASTON': begin 
							templatename='Basic Polarization Sequence'
                                                     end 
                                                'SPECTRAL': begin 
                                                if  current.occulter eq 'SCIENCE'  then begin ;'Science fold' means no occulter
                                                    ;if binaries:
                                                    if strmatch(current.obsclass, 'AstromSTD',/fold) then begin
													   templatename="Lenslet scale and orientation"
                                                    endif
                                                    if strmatch(current.obsclass, 'Science',/fold) then begin
													   templatename="Create Datacubes, Rotate, and Combine unocculted sequence"
                                                    endif
                                                    if ~strmatch(current.obsclass, 'AstromSTD',/fold) && ~strmatch(current.obsclass, 'Science',/fold) then begin
													   templatename='Satellite Flux Ratios'
                                                    endif
                                                endif else begin 
                                                    if n_elements(file_filt_obst_disp_occ_obs_itime_object) GE 5 then begin
														templatename='Basic ADI + Simple SDI reduction (From Raw Data)'
                                                    endif else begin
														templatename="Simple Datacube Extraction"
                                                    endelse
                                                endelse
                                            end 
											'OPEN': begin
 												templatename="Simple Undispersed Image Extraction"
											end
                                            endcase
                                        end     
                                        else: begin 
											; Unknown or nonstandard OBSTYPE if you get here to this else statement...
                                            if strmatch(uniqsortedobstype[indsortseq[fc]], '*laser*') then begin
												templatename="Simple Datacube Extraction"
                                            endif else begin
                                               self->Log, "Not sure what to do about obstype '"+uniqsortedobstype[indsortseq[fc]]+"'. Going to try the 'Fix Keywords' recipe but that's just a guess."
											  templatename='Add set of missing keywords'
                                            endelse
                                        end
                                        endcase

                                        if keyword_set(continue_after_case) then continue

										; Now create the actual DRF based on a
										; template:
										templatename = self->lookup_template_filename(templatename)
										self->create_recipe_from_template, templatename, file_filt_obst_disp_occ_obs_itime_object, current


                                    endfor ;loop on object
                                endfor ;loop on itime
                            endfor ;loop on obsclass
                        endfor ;loop on fo occulteur    
                    endfor  ;loop on fd disperser
                endfor ;loop on fc obstype
            endfor ;loop on ff filter
        endif ;cond on n_elements(file) 

		if self.num_recipes_in_table gt 0 then begin
				; ******  Second stage of parsing: *****
				; Generate additional recipes for various special
				; cases such as bad pixel map generation.
				
				; 1. Generate hot bad pixel map recipe if we have any > 60 s darks. 
				;    Insert this at the end of the darks

				; First retrieve the names, itimes, and nfiles from the current list of recipes
				DRFnames = (*self.recipes_table)[1,*]
				ITimes= (*self.recipes_table)[8,*]
				Nfiles= (*self.recipes_table)[10,*]
				wdark = where(DRFnames eq 'Dark' and (itimes gt 60) and (nfiles ge 10), darkcount)
				if darkcount gt 0 then begin
					; take the DRF of the longest available dark sequence and read all of
					; the FITS files in it
					longestdarktime = max(itimes[wdark], wlongestdark)
					ilongdark = wdark[wlongestdark]
					self->clone_recipe_and_swap_template, ilongdark,  'Generate Hot Bad Pixel Map from Darks',   insert_index=insertindex
				endif

				; 2. If we have added some (how many? At least 3? ) different flat field
				; recipes, then combine those all together to generate cold pixel maps
				
				DRFnames = (*self.recipes_table)[1,*]
				wflat = where(DRFnames eq 'Flat-field Extraction', flatcount)
				; do we need to check distinct filters here? 
				if flatcount ge 4 then begin
					; generate a list of all the files
					; merge them into one list
					; edit clone_recipe routine to allow you to pass in a list of filenames
					; clone a new instance of 'Generate Cold Bad Pixel Map from Flats'
					; recipe using those. Add at the end of all the flats. 

				endif

				
				; 3. If we have added either the Hot bad pixel or cold bad pixel update
				; recipes, we should update the overall bad pixel map too. 
				DRFnames = (*self.recipes_table)[1,*]
				wbp = where(DRFnames eq 'Generate Hot Bad Pixel Map from Darks' or DRFnames eq 'Generate Cold Bad Pixel Map from Flats' , bpcount)
				if bpcount gt 0 then begin
					ilastbp = max(wbp)
					self->clone_recipe_and_swap_template, ilastbp,  'Combine Bad Pixel Maps',   insert_index=ilastbp+1, /lastfileonly

				endif
		endif
		

    endif ;condition on cindex>0, assure there are data to process

    void=where(file ne '',cnz)
    self->Log,'Data Parsed: '+strtrim(cnz,2)+' FITS files.'
    self->Log,'             '+strtrim(self.num_recipes_in_table,2)+' recipe files created.'
    ;self->Log,'resolved FILTER band: '+self.filter


end

;+-----------------------------------------
; parsergui::lookup_template_filename
;   Given a template descriptive name, return the filename that matches.
;-
function parsergui::lookup_template_filename, requestedname
    if not ptr_valid(self.templates) then self->scan_templates

	wm = where(  strmatch( (*self.templates).name, requestedname,/fold_case), ct)

	if ct eq 0 then begin
        ret=dialog_message("ERROR: Could not find any matching template file for name='"+requestedname+"'. Cannot load template.",/error,/center,dialog_parent=self.top_base)
		return, ""
	endif else if ct gt 1 then begin
        ret=dialog_message("WARNING: Found multiple matching template files for name='"+requestedname+"'. Going to load the first one, from file="+((*self.templates)[wm[0]]).filename,/information,/center,dialog_parent=self.top_base)
	endif
	wm = wm[0]

	return, ((*self.templates)[wm[0]]).filename



end


;+-----------------------------------------
; parsergui::create_recipe_from_template
; 	Creates a recipe from a template and a list of FITS files. 
;
; 	KEYWORDS:
; 	index=		index to use when inserting this into the GUI table for display
;
;
;-
pro parsergui::create_recipe_from_template, templatename, fitsfiles, current,  index=index

	; load the DRF, save with new filenames

    if keyword_set(templatename) then self.LoadedRecipeFile=templatename
    if self.LoadedRecipeFile eq '' then return


	if ~file_test(self.LoadedRecipeFile, /read) then begin
        message, "Requested recipe file does not exist: "+self.LoadedRecipeFile,/info
		return
	endif

	;catch, parse_error
	parse_error=0
	if parse_error eq 0 then begin
		drf = obj_new('drf', self.LoadedRecipeFile,/silent)
	endif else begin
        message, "Could not parse Recipe File: "+self.LoadedRecipeFile,/info
		;stop
        return
	endelse
	catch,/cancel


	; set the data files in that recipe to the requested ones
	drf->set_datafiles, fitsfiles 

	drf->set_outputdir, self.outputdir


	; Generate output file name
	recipe=drf->get_summary() 
	first_file=strsplit(fitsfiles[0],'S.',/extract) ; split on letter S or period
	last_file=strsplit(fitsfiles[size(fitsfiles,/n_elements)-1],'S.',/extract)
	prefixname=string(self.num_recipes_in_table+1, format="(I03)")

	if n_elements(first_file) gt 2 then begin
		; normal Gemini style filename
        outputfilename='S'+first_file[1]+'S'+first_file[2]+'-'+last_file[2]+'_'+recipe.shortname+'_drf.waiting.xml'
	endif else begin
		; something else? e.g. temporary workaround for engineering or other
		; data with nonstandard filenames
        outputfilename=file_basename(first_file[0])+'-'+file_basename(last_file[0])+'_'+recipe.shortname+'_drf.waiting.xml'
	endelse



	outputfilename = self.drfpath + path_sep() + outputfilename
	message,/info, 'Writing recipe file to :' + outputfilename

	drf->save, outputfilename, comment=" Created by the Data Parser GUI"

	if widget_info(self.autoqueue_id ,/button_set)  then begin
		message,/info, 'Automatically Queueing recipes is enabled.'
		drf->queue , queued_filename=queued_filename, comment=" Created by the Data Parser GUI"
		message,/info, ' Therefore also wrote file to :' + queued_filename
	endif

	self->add_recipe_to_table, outputfilename, drf, current, index=index

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

    drf_summary = drf->get_summary()

    new_recipe_row = [gpi_shorten_path(filename), drf_summary.name,   drf_summary.reductiontype, $
        current.filter, current.obstype, current.dispersr, current.obsmode, current.obsclass, string(current.itime,format='(F7.1)'), current.object, strc(drf_summary.nfiles)] 

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
              'QueueOne': textinfo='Click to add the currently selected Recipe to the execution queue.'
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
			gpitv, ses=self.session+1,  (*storage.splitptr).filename[ev.index]
			message, 'Opening in GPITV #'+strc(self.session+1)+" : "+(*storage.splitptr).filename[ev.index],/info
		endif
	endif
 
    ; Menu and button events: 
    case uval of 

    'tableselec':begin      
            IF (TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_TABLE_CELL_SEL') && (ev.sel_top ne -1) THEN BEGIN  ;LEFT CLICK
                selection = WIDGET_INFO((self.table_recipes_id), /TABLE_SELECT) 
                ;;uptade arguments tab
                if n_elements((*self.recipes_table)) eq 0 then return
                self.num_recipes_in_table=n_elements((*self.recipes_table)[0,*])
                ;print, self.num_recipes_in_table
                ; FIXME check error condition for nothing selected here. 
                indselected=selection[1]
                if indselected lt self.num_recipes_in_table then self.selection =(*self.recipes_table)[0,indselected]
                ;if indselected lt self.num_recipes_in_table then begin 
                    ;print, "Starting DRFGUI with "+ (*self.recipes_table)[0,indselected]
                    ;gpidrfgui, drfname=(*self.recipes_table)[0,indselected], self.top_base
                ;endif  
                     
            ENDIF 
    end      
    'ADDFILE' : self->ask_add_files
    ;'flatreduction':begin
         ;self.flatreduc=widget_info(self.calibflatid,/DROPLIST_SELECT)
    ;end
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

        w = where(result ne '')
        if (w[0] ne -1) then begin
            result = result[w]
        endif else begin
            self->Log,'search failed (no match).'
        endelse
        
        self->AddFile, result
		self->parse_current_files
        
    end
    'FNAME' : begin
        (*storage.splitptr).selindex = ev.index
    end
    'REMOVE' : begin
        self->removefile, file
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
	'REPARSE': begin
        self->Log,'User requested re-parsing all files.'
		self->parse_current_files
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
    'Delete': begin
        selection = WIDGET_INFO((self.table_recipes_id), /TABLE_SELECT) 
        indselected=selection[1] ; FIXME allow multiple selections here?
        if indselected lt 0 or indselected ge self.num_recipes_in_table then return ; nothing selected
        self.selection=(*self.recipes_table)[0,indselected]


        if confirm(group=self.top_base,message=['Are you sure you want to delete the file ',self.selection+"?"], label0='Cancel',label1='Delete', title="Confirm Delete") then begin
            self->Log, 'Deleted file '+self.selection
            file_delete, self.selection,/allow_nonexist

            if self.num_recipes_in_table gt 1 then begin
                indices = indgen(self.num_recipes_in_table)
                new_indices = indices[where(indices ne indselected)]
                (*self.recipes_table) = (*self.recipes_table)[*, new_indices]
                self.num_recipes_in_table-=1
            endif else begin
                self.num_recipes_in_table=0
                (*self.recipes_table)[*] = ''
            endelse
                  
            widget_control,   self.table_recipes_id,  set_value=(*self.recipes_table)[*,*] 
			; no - don't set the selection to zero and reset the view, keep
			; those the same if possible. 
			;, SET_TABLE_SELECT =[-1,-1,-1,-1] ; no selection
            ;widget_control,   self.table_recipes_id, SET_TABLE_VIEW=[0,0]

        endif
    end
    'DRFGUI': begin
        if self.selection eq '' then return
            rec_editor = obj_new('gpi_recipe_editor', drfname=self.selection, self.top_base)
    end


    'QueueAll'  : begin
                self->Log, "Adding all DRFs to queue in "+gpi_get_directory('GPI_DRP_QUEUE_DIR')
                for ii=0,self.num_recipes_in_table-1 do begin
                    if (*self.recipes_table)[0,ii] ne '' then begin
                          self->queue, (*self.recipes_table)[0,ii]
                      endif
                endfor      
                self->Log,'All DRFs have been succesfully added to the queue.'
    end
    'QueueOne'  : begin
        if self.selection eq '' then begin
              self->Log, "Nothing is currently selected!"
              return ; nothing selected
        endif else begin
            self->queue, self.selection
            self->Log,'Queued '+self.selection
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
		'Quit Data Parser': self->confirm_close
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
; Ask the user what new files to add, then add them.
pro parsergui::ask_add_files
	;-- Ask the user to select more input files:
	if self.last_used_input_dir eq '' then self.last_used_input_dir = self->get_default_input_dir()

	if keyword_set(gpi_get_setting('at_gemini', default=0,/silent)) then begin
		filespec = 'S20'+gpi_datestr(/current)+'*.fits'
	endif else begin
		filespec = ['*.fits','*.fits.gz']
	endelse

	result=dialog_pickfile(path=self.last_used_input_dir,/multiple,/must_exist,$
			title='Select Raw Data File(s)', filter=filespec)
	result = strtrim(result,2)

	if result[0] ne '' then begin
		self.last_used_input_dir = file_dirname(result[0])
		self->AddFile, result
		self->parse_current_files
	endif

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
      nlines_fname=10
      nlines_modules=7
      nlines_args=6
    endif else begin
      nlines_status=12
      nlines_fname=10
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
    button=widget_button(top_basefilebutt,value="Wildcard",uvalue="WILDCARD", $
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
    fname=widget_list(top_baseident,xsize=106,scr_xsize=780, ysize=nlines_fname,$
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
		xsize=xsize,ysize=20,uvalue='tableselec',value=(*self.recipes_table), /TRACKING_EVENTS,$
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
    button2b=widget_button(top_baseexec,value="Queue selected Recipes only",uvalue="QueueOne", /tracking_events)
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
    datefile=lonarr(maxfilen)
    findex=0
    selindex=0
    splitptr=ptr_new({filename:filename,$ ; array for FITS filenames loaded
		printname:printname,$	; array for printname
		findex:findex,$			; current index to write filename
		selindex:selindex,$		; 
		datefile:datefile, $	; date of each FITS file (for sort-by-date)
		maxfilen:maxfilen})		; max allowed number of files

    storage={info:info,$	; widget ID for information text box
		fname:fname,$		; widget ID for filename text box
        splitptr:splitptr,$	; structure (pointer)
        self:self}			; Object handle to self (for access from widgets)
    widget_control,parserbase,set_uvalue=storage,/no_copy

    self->log, "This GUI helps you to parse a set of FITS data files to generate useful reduction recipes."
    self->log, "Add files to be processed, and recipes will be automatically created based on FITS keywords."
    return, parserbase

end


;-----------------------
; parsergui::post_init
;    nothing needed here - null routine to override the parent class' routine
;-
pro parsergui::post_init, _extra=_extra
	; pass
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
              selection: '', $			; current selection in recipes table
              recipes_table: ptr_new(), $   ; pointer to resizeable string array, the data for the recipes table
			  DEBUG:0, $				; debug flag, set by pipeline setting enable_parser_debug
              sorttab:strarr(3),$       ; table for sort options 
           INHERITS gpi_recipe_editor}


end
