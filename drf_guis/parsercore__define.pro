;+
; NAME: parsercore__define
;
;    This is the core logic of the Data Parser
;
;    formerly part of parsergui__define, moved here for refactoring and
;    increased flexibility
;
; USAGE:
;	Create an object of class Fileset, and add some number of FITS files to it.
;	Then pass that fileset object to this object's parse_fileset_to_recipes()
;	function. The returned value will be an array of Recipe (DRF) objects,
;	which are the result of parsing that set of FITS files. 
;
;   If you are interested in only a subset of the output recipes, for instance
;   only calibrations or only H band science, then you can call the 
;   get_recipe_subset() function to get only the desired subset of recipes. 
;
;   If you want to clean up afterwards just call the ::delete_all_recipes()
;   function.
;
; EXAMPLE CODE: 
;
;        
;        ; first step is to build up a list of which files we care about
;        myfiles = obj_new('fileset')
;        myfiles.add_files, ['S20150202S0001.fits.gz''S20150202S0002.fits.gz']
;        myfiles.add_files_from_wildcard, '/some/path/GPIDATA-Readonly/Campaign/Raw/150202/S2015*S*.fits'
;        
;        ; then hand that list to the parser core
;        parser = obj_new('parsercore')
;        recipes = parser.parse_fileset_to_recipes(myfiles)
;        
;        ; optional: let's say we only want to run certain types of recipes so let’s get a subset
;        recipes = parser.get_recipe_subset(ifsfilt='H', recipetype='Calibration')
;        
;        ; now we can run those recipes
;        nr = n_elements(recipes)
;        for i=0,nr-1 do begin
;        	print, 'Recipe file:', recipes[i].get_last_saved_filename()  
;        	; we want the saved filename as opposed to the filename of the template it was created from
;        	recipes[i].queue  
;        endfor 
;
;
; OUTPUTS:
;
; HISTORY:
;    Began 2015-01-28 by Marshall Perrin, splitting code formerly in parsergui__define
;    into its own standalone class. 
;    2015-03-14 Added outputdir keyword to parse_fileset_to_recipe   
; 
;-

function parsercore::parse_fileset_to_recipes, fileset, recipedir=recipedir, outputdir=outputdir

    t0 = systime(/seconds)


    ; TODO check that fileset is indeed an instance of a Fileset object
    self.fileset = fileset
    self.fileset->scan_headers ; in case this has not already been done

    if keyword_set(recipedir) then self.recipedir=recipedir
    if keyword_set(outputdir) then self.outputdir=outputdir


    file = self.fileset->get_filenames()
    finfo = self.fileset->get_info(nfiles=nfiles_to_parse)


    timeit1=systime(/seconds)
    if nfiles_to_parse eq 0 then begin ;assure that data are selected
        return, -1
    endif


	wvalid = where(finfo.valid, nvalid, complement=winvalid, ncomplement=ninvalid)
      if ninvalid gt 0 then begin
        self->Log, "Some files are lacking valid required FITS keywords: "
        self->Log, strjoin(file[winvalid], ", ")
        self->Log, "These will be ignored in all further parsing steps."
        if wvalid[0] eq -1 then begin
          self->Log, "ERROR: All files are invalid. Cannot parse."
          if self.gui_parent_wid ne 0 then ret=dialog_message("ERROR: All files are invalid. Cannot parse.",/error,/center,dialog_parent=self.gui_parent_wid)
          return, -1
        endif
        finfo = finfo[wvalid]
      endif


      self->Log,'Now analyzing data based on keywords...'


      ; Mark filter as irrelevant for Dark exposures
      wdark = where(strlowcase(finfo.obstype) eq 'dark', dct)
      if dct gt 0 then finfo[wdark].filter='-'



      if (n_elements(file) gt 0) && (strlen(file[0]) gt 0) then begin


        current = {struct_obs_keywords}

        ;categorize by filter
        uniqfilter  = uniqvals(finfo.filter, /sort)
        uniqfilter = ['-', 'Y','J','H','K1','K2'] ; just always do this in wavelength order
        uniqobstype = uniqvals(strlowcase(finfo.obstype), /sort)

        ;categorize by Gemini datalabel
        tmpdatalabels = finfo.datalab
        numdatalabs = n_elements(tmpdatalabels)
        datalabels = tmpdatalabels
        for dlbls=0,numdatalabs-1 do begin
          datalabs = strsplit(tmpdatalabels[dlbls],'-',/EXTRACT)
          datalabels[dlbls] = strjoin(datalabs[0:-2],'-')
        endfor

        uniqdatalab = uniqvals(strlowcase(datalabels), /sort)
        if self.debug then print, 'number of uniqdatalabels', n_elements(uniqdatalab)
        if self.debug then print, uniqdatalab
        ; TODO - sort right order for obstype
        ; uniqobstype = uniqvals(finfo.obstype, /sort)

        uniqprisms = uniqvals(finfo.dispersr)
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

        nbfilter=n_elements(uniqfilter)
        self->Log, "Now adding "+strc(n_elements(finfo))+" files. "
        self->Log, "Input files include data from these FILTERS: "+strjoin(uniqfilter, ", ")

        ;for each filter, categorize by obstype, and so on
        for ff=0,nbfilter-1 do begin
          current.filter = uniqfilter[ff]
          indffilter =  where(finfo.filter eq current.filter)
          filefilt = file[indffilter]

          ;categorize by obstype
          uniqsortedobstype = uniqvals(strlowcase((finfo.obstype)[indffilter]))

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

          for fc=0,nbobstype-1 do begin
            ;get files corresponding to one filt and one obstype
            current.obstype = uniqsortedobstype[indsortseq[fc]]

            for fdl=0,n_elements(uniqdatalab)-1 do begin
              current.datalab = uniqdatalab[fdl]

              ;--- added for faster parsing of large datasets
              ; for efficiency's sake, before proceeding any further check
              ; if there exist files in this combination
              wmatch = where( finfo.filter eq current.filter and $
                strmatch(finfo.obstype, current.obstype,/fold) and $
                strmatch(finfo.datalab, current.datalab+"*",/fold), matchct)
              if matchct eq 0 then begin
                if self.debug then self->Log, "No match for current obstype/datalabel - skipping ahead"
                continue
              endif
              ;--- end of faster parsing efficiency code


              for fd=0,n_elements(uniqprisms)-1 do begin
                current.dispersr = uniqprisms[fd]

                for fo=0,n_elements(uniqocculters)-1 do begin
                  current.occulter=uniqocculters[fo]

                  for fobs=0,n_elements(uniqobsclass)-1 do begin
                    current.obsclass=uniqobsclass[fobs]

                    ;--- added for faster parsing of large datasets
                    ; for efficiency's sake, before proceeding any further check
                    ; if there exist files in this combination
                    wmatch = where( finfo.filter eq current.filter and $
                      strmatch(finfo.obstype, current.obstype,/fold) and $
                      strmatch(finfo.datalab, current.datalab+"-*",/fold) and $
                      strmatch(finfo.dispersr,current.dispersr+"*",/fold) and $
                      strmatch(finfo.occulter,current.occulter+"*",/fold) and $
                      finfo.obsclass eq current.obsclass, matchct)
                    if matchct eq 0 then begin
                      if self.debug then self->Log, "No match for current obstype/datalabel/disperser/occulter/obsclass - skipping ahead"
                      continue
                    endif
                    ;--- end of faster parsing efficiency code



                    for fitime=0,n_elements(uniqitimes)-1 do begin
                      current.itime = uniqitimes[fitime]    ; in seconds, now


                      for fobj=0,n_elements(uniqobjects)-1 do begin
                        continue_after_case = 0 ; reset if this was set before.
                        current.object = uniqobjects[fobj]

                        indfobject = where(finfo.filter eq current.filter and $
                          strmatch(finfo.obstype, current.obstype,/fold) and $
                          strmatch(finfo.datalab,current.datalab+"*",/fold) and $
                          strmatch(finfo.dispersr,current.dispersr+"*",/fold) and $
                          strmatch(finfo.occulter,current.occulter+"*",/fold) and $
                          finfo.obsclass eq current.obsclass and $
                          finfo.itime eq current.itime and $
                          finfo.object eq current.object, cobj)

                        if self.debug then self->Log, 'Now testing the following parameters: ('+strc(cobj)+' files match) '



                        if cobj eq 0 then continue ; this particular combination of filter, obstype, dispersr, occulter, class, time, object has no files.

                        ; otherwise, try to match it:
                        file_filt_obst_disp_occ_obs_itime_object = finfo[indfobject].filename


                        current.obsmode = finfo[indfobject[0]].obsmode
                        current.lyotmask= finfo[indfobject[0]].lyotmask

                        ;identify which templates to use
                        if self.debug then print,  current.obstype ; uniqsortedobstype[indsortseq[fc]]
                        self->Log, "Found sequence of OBSTYPE="+current.obstype+", OBSMODE="+current.obsmode+", DISPERSR="+current.dispersr+", IFSFILT="+current.filter+ " with "+strc(cobj)+" files targeting "+current.object

                        case strupcase(current.obstype) of
                        'DARK':begin
                          templatename='Dark'
						  if cobj eq 80 and abs(current.itime -60) lt 1 then begin
							  ; special case handling for the nightly dark monitor
							  ; at Gemini South. For these we take 80 x 60 s
							  ; exposures. The first 20 should be discarded to set
							  ; aside any persistence from the end of the night's
							  ; science observations. 
							  self->Log, "Found sequence of 80 x 60 s dark exposures. Skipping the first 20 (for persistence decay) and only reducing the last 60"
							  indfobject = indfobject[20:*]
							  cobj = n_elements(indfobject)
							  file_filt_obst_disp_occ_obs_itime_object = finfo[indfobject].filename

						  endif
                        end
                        'ARC': begin
                          if  current.dispersr eq 'WOLLASTON' then begin
                            templatename='Create Polarized Flat-field'
                          endif else begin
                            objelevation = finfo[indfobject[0]].elevatio
                            if (objelevation lt 91.0) AND (objelevation gt 89.0) then begin
                              templatename='Wavelength Solution 2D Developer'
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

                            if gcalfilter EQ 'ND4-5' then begin
                              self->Log, "    Those data have GCALFILT=ND4-5, which indicates they are throwaway exposures for persistence decay. Ignoring them."
                              continue_after_case=1
                            endif else begin
                              templatename1 = gpi_lookup_template_filename("Calibrate Polarization Spots Locations")
                              templatename2 = gpi_lookup_template_filename('Create Polarized Flat-field')
                              templatename3 = gpi_lookup_template_filename('Create Low Spatial Frequency Polarized Flat-field')
                              self->create_recipe_from_template, templatename1, file_filt_obst_disp_occ_obs_itime_object, current_metadata=current
                              self->create_recipe_from_template, templatename2, file_filt_obst_disp_occ_obs_itime_object, current_metadata=current
                              self->create_recipe_from_template, templatename3, file_filt_obst_disp_occ_obs_itime_object, current_metadata=current
                            endelse

                            ;continue        aaargh can't continue inside a case. stupid IDL
                            continue_after_case=1
                          endif else begin    ; Spectral mode
                            if gcalfilter EQ 'ND4-5' then begin
                               objexptime = finfo[indfobject[0]].itime
                               if objexptime GT 60.0 then begin
                                  templatename='Combine Thermal/Sky Background Images'
                               endif else begin
                                  continue_after_case=1
                                  self->Log, "    Those data have GCALFILT=ND4-5, which indicates they are throwaway exposures for persistence decay. Ignoring them."
                              endelse
                            endif else begin
                              templatename='Flat-field Extraction'
                            endelse
                          endelse
                        end
                        'OBJECT': begin
                          case strupcase(current.dispersr) of
                            'WOLLASTON': begin
                              templatename='Basic Polarization Sequence (From Raw Data)'
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

                      if keyword_set(continue_after_case) then begin
                        continue
                      endif

                      ; Now create the actual DRF based on a
                      ; template:
                      templatename = gpi_lookup_template_filename(templatename)
                      self->create_recipe_from_template, templatename, file_filt_obst_disp_occ_obs_itime_object, current=current

                    endfor ;loop on object
                  endfor ;loop on itime
                endfor ;loop on obsclass
              endfor ;loop on fo occulteur
            endfor  ;loop on fd disperser
          endfor   ;loop for datalab
        endfor ;loop on fc obstype
      endfor ;loop on ff filter
    endif ;cond on n_elements(file)

    if self->num_recipes() gt 0 then begin
      ; ******  Second stage of parsing: *****
      ; Generate additional recipes for various special
      ; cases such as bad pixel map generation.

      ; 1. Generate hot bad pixel map recipe if we have any > 60 s darks.
      ;    Insert this at the end of the darks

      ; First retrieve the names, itimes, and nfiles from the current list of recipes
      recipe_summary = self->get_recipe_summary()
      DRFnames= recipe_summary.names
      ITimes  = recipe_summary.itimes
      NFiles  = recipe_summary.nfiles
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
      recipe_summary = self->get_recipe_summary() ; do this again in case step 1 changes anything
      DRFnames= recipe_summary.names

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
      recipe_summary = self->get_recipe_summary() ; do this again in case step 1 or 2 changes anything
      DRFnames= recipe_summary.names

      wbp = where(DRFnames eq 'Generate Hot Bad Pixel Map from Darks' or DRFnames eq 'Generate Cold Bad Pixel Map from Flats' , bpcount)
      if bpcount gt 0 then begin
        ilastbp = max(wbp)
        self->clone_recipe_and_swap_template, ilastbp,  'Combine Bad Pixel Maps',   insert_index=ilastbp+1, /lastfileonly

      endif
    endif


    timeit2=systime(/seconds)

    self->Log,'Data Parsed: '+strtrim(nfiles_to_parse,2)+' FITS files.'
    self->Log,'             '+strtrim(self->num_recipes(),2)+' recipe files created.'
    self->Log,'             Complete in '+sigfig(timeit2-timeit1,3)+' seconds.'


    return, *self.recipes

end
;+--------------------------------------------
; parsercore::get_recipe_subset
;     Return a subset of available recipes based on some selection criteria.
;
;     
;-

function parsercore::get_recipe_subset, recipetype=recipetype, obstype=obstype, $
	ifsfilt=ifsfilt,dispersr=dispersr

  if self->num_recipes() eq 0 then begin
		self->Log,"No recipes are present! You probably need to parse some files first."
		return,-1
  endif

  recipetable = self->get_Recipe_summary()

  included = bytarr(self->num_recipes())

  ; Apply selection criteria, one by one, to exclude non-matching recipes
  if keyword_set(ifsfilt) then included[where(recipetable.ifsfilt ne ifsfilt)]=0
  if keyword_set(dispersr) then included[where(recipetable.dispersr ne dispersr)]=0
  if keyword_set(obstype) then included[where(recipetable.obstype ne obstype)]=0
  if keyword_set(recipetype) then included[where(recipetable.redtype ne recipetype)]=0

  ; return just the ones that match
  w_included = where(included, included_ct)
  if included_ct eq 0 then begin
		self->Log,"No recipes match the selected subset criteria."
		return,-1
  endif

  return, (*self.recipes)[w_included]


end


;+--------------------------------------------
; parsercore::clone_recipe_and_swap_template
;     starting from an existing recipe, create a new recipe using a different
;     template but otherwise the same files and metadata
;
;     This is used for some of the templates, for instance creating bad pixel
;     maps is cloned from a recipe used to reduce darks.
;
;
;   KEYWORDS:
;        insert_index    index to use when creating recipe filename to add it
;                        into the list of recipes
;-

pro parsergui::clone_recipe_and_swap_template, existing_recipe, newtemplatename,  insert_index=insert_index, $
    lastfileonly=lastfileonly

    drf = existing_recipe ; (*self.recipes_table)[0, existing_recipe_index]

    existingdrffiles = drf->get_datafiles(/absolute)

    if keyword_set(lastfileonly) then existingdrffiles = existingdrffiles[n_elements(existingdrffiles)-1]

    extra_metadata = drf->retrieve_extra_metadata()


    newtemplatefilename = gpi_lookup_template_filename(newtemplatename)
    self->create_recipe_from_template, newtemplatefilename, existingdrffiles, current_metadata=extra_metadata,  index=insert_index
end



;+ ---------------------------------------------------------------------
; parsercore::get_recipe_summary
;    return useful table of metadata for recipes, used in second stage of
;    parsing.
;-

function parsercore::get_recipe_summary
    nr = self->num_recipes()
    if nr eq 0 then return, ""

    names = strarr(nr)
    itimes = fltarr(nr)
    nfiles = lonarr(nr)
	ifsfilt = strarr(nr)
	dispersr=strarr(nr)
	obstype=strarr(nr)
	redtype=strarr(nr)

	; This is somewhat annoying to gather all this data, because
	; only some of the desired info is in the recipe itself, which can be
	; obtained from get_summary, but the rest such as file keywords for DISPERSR
	; or IFSFILT is not retained in the XML and you ahve to get that from the
	; retrieve_extra_metadata() hack/workaround. 
    for i=0,nr-1 do begin
        summary = ((*self.recipes)[i])->get_summary()
        metadata = ((*self.recipes)[i])->retrieve_extra_metadata()
        names[i] = summary.filename
        itimes[i] = metadata.itime
        nfiles[i] = summary.nfiles
		ifsfilt[i] = metadata.filter
		dispersr[i] = metadata.dispersr
		obstype[i] = metadata.obstype
		redtype[i] = summary.reductiontype
    endfor

    return, {names:names, itimes:itimes, nfiles:nfiles, $
		ifsfilt:ifsfilt, dispersr:dispersr, obstype:obstype, redtype:redtype}

end

;+ ---------------------------------------------------------------------
; parsercore::create_recipe_from_template
;   Create a recipe from a template, and store the resulting DRF object
;
;   templatename      string, self explanatory
;   fitsfiles         string array, self explanatory
;   current_metadata  Information about the FITS files, such as exposure
;                     time, Obsmode, etc.  This is attached to the
;                     recipe for later use elsewhere.
;    index            optional, integer index to insert this recipe
;                     somewhere other than the end of the list.
;-

pro parsercore::create_recipe_from_template, templatename, fitsfiles, current_metadata=current_metadata, $
    filename_counter=filename_counter, index=index

    if ~(keyword_set(filename_counter)) then filename_counter=self->num_recipes()+1
    ;Only default to reduced data dir if no outputdir has been defined
    if self.outputdir eq '' then self.outputdir=gpi_get_directory('REDUCED_DATA')
    ; create the recipe
    if self.outputdir NE '' then begin 
        drf = gpi_create_recipe_from_template( templatename, fitsfiles,  $
                                              recipedir=self.recipedir, $ 
                                              filename_counter=filename_counter, $
                                              outputfilename=outputfilename, $
                                              outputdir=self.outputdir)
    endif else begin
       drf = gpi_create_recipe_from_template( templatename, fitsfiles,  $
                                              recipedir=self.recipedir, $ 
                                              filename_counter=filename_counter, $
                                              outputfilename=outputfilename)
    endelse



    if keyword_set(current_metadata) then drf->attach_extra_metadata, current_metadata

    ; save it to our list of recipes
    if (n_elements(index) eq 0) || ~ptr_valid(self.recipes) || index gt n_elements(*self.recipes) || index lt 0 then begin
        ; just insert it at the end
        if ~ptr_valid(self.recipes) then self.recipes = ptr_new([drf]) else *self.recipes=[*self.recipes, drf]
    endif else begin
        ; insert at the specified index
        *self.recipes = [(*self.recipes)[0:index-1], drf, (*self.recipes)[index:n_elements(*self.recipes)-1] ]
        self->Log, "Inserted recipe into the list at index="+strc(index)
    endelse



end

;+ ---------------------------------------------------------------------
; parsercore::delete_all_recipes
;	Clean up by deleting all the recipes. 
;-

pro parsercore::delete_all_recipes
	self->Log, "User requested deleting all recipes"

	nr = self->num_recipes()
    if nr eq 0 then begin
		self->Log, "No recipes to delete!"
		return
	endif else begin
		self->Log, "Now deleting "+strc(nr)+" recipe files:"
		for i=0,nr-1 do begin
			fn = (*self.recipes)[i]->get_last_saved_filename()
			self->Log, "    "+fn
			file_delete, fn, /allow_nonexistent
			obj_destroy, (*self.recipes)[i]
		endfor
		ptr_free, self.recipes
		self->Log, "All recipes have been deleted."
	endelse
end




;+ ---------------------------------------------------------------------
; parsercore::num_recipes
;    Get number of recipes currently produced by parsing.
;-

function parsercore::num_recipes
    if ptr_valid(self.recipes) then return, n_elements(*self.recipes) else return, 0
end


;+ ---------------------------------------------------------------------
; parsercore::log
;    Pass-through logging function
;-
pro parsercore::log, logtext
    if obj_valid(self.where_to_log) then (self.where_to_log)->log, logtext else print, "LOG: "+logtext

end

;+ ---------------------------------------------------------------------
; parsercore::init
;   Class initialization function
;-
function parsercore::init, debug=debug, $
        where_to_log=where_to_log, gui_parent_wid=gui_parent_wid

    self.debug = keyword_set(debug)
    if obj_valid(where_to_log) then self.where_to_log = where_to_log
    if keyword_set(gui_parent_wid) then self.gui_parent_wid=gui_parent_wid

    self.recipedir = gpi_get_directory('RECIPE_OUTPUT_DIR')

    if gpi_get_setting('organize_recipes_by_dates',/bool) then begin
        self.recipedir +=  path_sep() + gpi_datestr(/current)
    endif
    self->Log,"Recipes will be output to "+self.recipedir


    return, 1
end

;+-----------------------
; parsercore__define
;    Object variable definition for parsercore
;-

PRO parsercore__define

    state = {  parsercore,                 $
              recipes: ptr_new(), $   ; pointer to resizeable string array, the data for the recipes table
              fileset: obj_new(),$      ; Set of loaded files to parse
              where_to_log: obj_new(), $ ; object handle to something with a Log function we can use.
              gui_parent_wid: 0,            $ ; optional, GUI widget ID of parent window for dialog boxes
              recipedir: '', $            ; Output dir for recipes
              outputdir: '' , $
              DEBUG:0}                 ; debug flag, set by pipeline setting enable_parser_debug

end

