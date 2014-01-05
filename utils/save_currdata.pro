;+
; NAME:  save_currdata
;
; PURPOSE: save the dataset. Generates a Gemini-compatible filename and does
;	various header keyword updates in addition to saving the file.
;
; INPUT :  DataSet     : the DataSet pointer.
;          s_OutputDir : the output directory
;          s_Ext       : output filename extension (suffix)
;          /DEBUG      : initializes debugging mode
;          level2=	   : offset for file index, used in saving ADI sequences.
;
;          SaveData=     Save this data INSTEAD of the current DataSet pointer
;          SaveHeader=	 Extension Header for writing along with the SaveData data.
;          SavePHU=		 Primary header for writing along with the SaveData data.
;
; OUTPUT : Saves the dataset to disk
; 	output_filename=	optional return keyword argument giving the filename
; 						used to save the data, including path
;
; STATUS : 
;
; HISTORY : 
;   2005-01-23, created by  Christof Iserlohe (iserlohe@ph1.uni-koeln.de) 
;   			as save_dataset.pro
;   2009-02 JM: Added Display keyword to call GPITVMS. 
;   2009-05 MDP: Documentation updated. 
; 	2010-01-27: Added code for GPI Calibrations DB. M. Perrin
; 	2011-03-16: Improved file name generation code. Split DATAFILE into
; 				DATAFILE and DATAPATH and switched to fxpar to support very
; 				long path names using the FITS CONTINUE convention.
; 	2011-08-01 MP: Revised for multi-extension FITS. save_currdata will now 
; 				always write its output as a primary header plus image
; 				extension. This is different from previous versions of the DRP!
; 				Switched to mwrfits instead of writefits because it better
; 				handles the EXTENT/XTENSION keywords needed for multi-ext FITS.
;   2012-06-06 MP: Added fallback safety checks for DATAFILE= missing or NONE 
;   2012-08-07 MP: Added explicit casts to float data type for output files.
;   2012-10-10 MP: Code cleanup. Removed filenm keyword, not used anywhere. 
;   2013-04-26 MP: Minor formatting improvements to time stamps and DRPVER
;				   Also fixed fatal error when trying to write bintables with
;				   a vestigial NAXIS3 keyword left in the header. 
;	2013-10-17 MP: Switch suffixes to _ instead of -; add Gemini DATALAB
;				   handling using the same suffixes as the filenames
;-


function save_currdata, DataSet,  s_OutputDir, s_Ext, display=display, savedata=savedata, saveheader=saveheader, savePHU=savePHU,  $
		output_filename=c_File, level2=level2

    COMMON APP_CONSTANTS
    COMMON PIP

	getmyname, functionname
	version = gpi_pipeline_version()

    if keyword_set(level2) then i=level2-1 else i=numfile ;; Huh?  Used in some of the ADI/LOCI infrastructure? Cryptic, needs explanatory comment please.

	;=== Generate output filename, starting from the input one.
	filenm=fxpar(*(DataSet.HeadersPHU[i]),'DATAFILE',count=cdf)
    if (cdf eq 0) or (strc(filenm) eq 'NONE') or (strc(filenm) eq '')  then begin 
		; if DATAFILE keyword not present or not valid, then 
        ; fallback to input filename
        filenm = dataset.filenames[i]
    endif

	;Check both primary and extension headers for an ISCALIB keyword. If set to 'YES', then output should go to the calibrations file directory.
	; we have to do this check of both extensions manually here instead of using
	; gpi_get_keyword because of the case where the calling routine has passed
	; in its own headers to be written out instead of the ones in the backbone
	is_calib_pri=0 & is_calib_ext=0
    if keyword_set(savePHU) then is_calib_pri = strc(strupcase(fxpar(savePHU, "ISCALIB"))) eq 'YES' else $
      is_calib_pri = strc(strupcase(fxpar(*(dataset.headersPHU[numfile]), "ISCALIB"))) eq 'YES'
    if keyword_set(saveheader) then is_calib_ext = strc(strupcase(fxpar(saveheader, "ISCALIB"))) eq 'YES' else $
      is_calib_ext = strc(strupcase(fxpar(*(dataset.headersExt[numfile]), "ISCALIB"))) eq 'YES' 

    if is_calib_pri or is_calib_ext then begin
      gpicaldb = Backbone_comm->Getgpicaldb()
      s_OutputDir = gpicaldb->get_calibdir()
	  message,/info, ' Output file is calibration data; therefore writing to calibration dir.'
    endif


	
	; Verify output dir is valid
	s_OutputDir = gpi_expand_path(s_OutputDir) 
	if strc(s_OutputDir) eq "" then begin
		return, error('FAILURE ('+functionName+'): supplied output directory is a blank string.')
	endif

	dir_ok = gpi_check_dir_exists(s_Outputdir)
	if dir_ok eq NOT_OK then return, error('FAILURE ('+functionName+'): Nonexistent or unwriteable output directory') 

	; ensure we have a directory separator, if it's not there already
	if strmid(s_OutputDir, strlen(s_OutputDir)-1,1) ne path_sep() then s_OutputDir+= path_sep()


	; Generate output filename
	; remove extension if need be
	base_filename = file_basename(gpi_expand_path(filenm))
	extloc = strpos(base_filename,'.', /reverse_search)

	; suffix must be separated by a dash
	if strmid(s_Ext,0,1) eq '-' then strreplace, s_Ext,'-','_' ; swap dashes to underscores!
	if strmid(s_Ext,0,1) ne '_' then s_Ext = '_'+s_Ext

	c_File = s_OutputDir + strmid(base_filename,0,extloc)+ s_Ext+'.fits'

	if ( NOT bool_is_string(c_File) ) then $
	   return, error('FAILURE ('+functionName+'): Output filename creation failed.')

    ;====  File name collision handling  ====
	; Check if the requested output filename already exists. 

	if file_test(c_File) then begin
		collision_handling = gpi_get_setting('file_overwrite_handling', default='ask_user',/silent)

		if strmatch(collision_handling, '*overwrite*', /fold) then  begin
			; we just overwrite it, bull in a china shop style
			backbone_comm->Log, 'Overwriting existing output filename: '+c_File
		endif else if strmatch(collision_handling, '*ask*', /fold) then begin
			; If so, ask the user if it should be overwritten or not
			;
			; Iterate if necessary. Foolish users, always trying to overwrite things...
			
			while file_test(c_File) do  begin
				statuswindow = backbone_comm->getstatusconsole()

				if obj_valid(statuswindow) then begin
					status_top_widget = statuswindow->get_top_base() 
				endif else begin
					backbone_comm->Log, 'Output Filename: '+c_File
					backbone_comm->Log, 'File already exists, and prompt_user_for_overwrite is set. However, GUI is not currently available.'
					return, error( 'FAILURE ('+functionName+"): File overwrite handling is set to 'ask user' but cannot prompt user for a new filename since GUI is disabled.")
				endelse

				if keyword_set(confirm(message=['The file '+c_File+' already exists on disk. ','',  'Are you sure you want to overwrite this file?'], $
						label0='Change Filename',label1='Overwrite', title="Confirm Overwrite File", group_leader=status_top_widget)) then begin
							; user has chosen to overwrite
							backbone_comm->Log, 'The user confirmed overwriting the existing file on disk of that same filename.'
							break
				endif else begin
					c_File = dialog_pickfile(/write, default_extension='fits', file=c_File, filter='*.fits', $
						path=s_OutputDir, title='Select New Filename' )
					backbone_comm->Log, 'The user requested a new filename:'+c_File
				endelse

			endwhile
		endif else if strmatch(collision_handling,'*append*', /fold) then begin
			; Append an extension number to the filename to avoid overwriting.
			basefn = fsc_base_filename(c_File, extension=extfn, directory=directory)
			counter=0
			while file_test(c_File) do begin
				counter += 1
				c_File = directory + basefn + "_"+strc(counter)+"."+extfn
			endwhile
			backbone_comm->Log, 'Appended _'+strc(counter)+" to output filename to avoid overwriting."
		endif else begin
			backbone_comm->Log, 'Invalid setting for file_overwrite_handling. Must be one of [overwrite, ask_user, append_number]'
			return, error('FAILURE ('+functionName+'): Invalid setting for file_overwrite_handling. Must be one of [overwrite, ask_user, append_number]')
		endelse

	endif	



	; Now we can proceed to actually writing out the file. 
    caldat,systime(/julian,/utc),month,day,year, hour,minute,second
    datestr = string(year,month,day,format='(i4.4,"-",i2.2,"-",i2.2)')
    hourstr = string(hour,minute,second,format='(i2.2,":",i2.2,":",i2.2)')  


	;--- write out either some user-supplied data (if explicitly provided), or the current data frame
	if ( keyword_set( savedata ) ) then begin  ; The calling function has specified some special data to save, in place of the currFrame data
		; First update the header if we're writing out VAR or DQ extensions.
		FXADDPAR,  *(dataset.headersPHU[numfile]),'NEXTEND',1+keyword_set(addexten_var)+keyword_set(addexten_qa)

	  	if ~( keyword_set( saveheader ) ) then saveheader = *(dataset.headersExt[numfile])
		if ~( keyword_set( savePHU ) ) then savePHU = *(dataset.headersPHU[numfile])
		fxaddpar, savePHU, 'DRPVER', version, ' Version number of GPI DRP software', after='TLCVER'
		fxaddpar, savePHU, 'DRPDATE', datestr+' '+hourstr, ' UT creation time of this reduced data file', after='UTEND'
		; update Gemini DATALABel keyword if present
		datalab = sxpar(savePHU, 'DATALAB', count=ctdatalab)
		if ctdatalab gt 0 then fxaddpar, savePHU, 'DATALAB', datalab+s_Ext

		mwrfits, 0, c_File, savePHU, /create,/silent
		writefits, c_File, float(savedata), saveheader, /append

		;curr_hdr = savePHU
		;curr_ext_hdr = saveheader
	endif else begin
      	fxaddpar, *DataSet.HeadersPHU[i], 'DRPVER', version, ' Version number of GPI DRP software', after='TLCVER'
      	fxaddpar, *DataSet.HeadersPHU[i], 'DRPDATE', datestr+'T'+hourstr, ' UT creation time of this reduced data file', after='UTEND'
		; update the header if we're writing out VAR or DQ extensions.
		FXADDPAR,  *(dataset.headersPHU[numfile]),'NEXTEND',1+ptr_valid(dataSet.CurrDQ)+ptr_valid(dataset.CurrUncert)


		; update Gemini DATALABel keyword if present
		datalab = sxpar(*DataSet.HeadersPHU[i], 'DATALAB', count=ctdatalab)
		if ctdatalab gt 0 then fxaddpar, *DataSet.HeadersPHU[i], 'DATALAB', datalab+s_Ext

		mwrfits, 0, c_File, *DataSet.HeadersPHU[i], /create,/silent
		; check whether we are writing a FITS bintable or a image array. If an
		; image array, cast to float (since we never want to write doubles)
		if size(*DataSet.currFrame,/tname) eq 'STRUCT' then begin
			; save a struct as a FITS bintable extension
			;   special note: we must be sure to not have a NAXIS3 keyword in
			;   the extension header, as this will break fxaddpar annoyingly.
			sxdelpar, *DataSet.HeadersExt[i], 'NAXIS3'
			mwrfits, *DataSet.currFrame, c_File, *DataSet.HeadersExt[i],/silent
		endif else begin
			; There are no cases in which we need to save data as double rather
			; than single precision floats; astronomical S/N simply doesn't
			; support it. So save some disk space here if possible. 
			; Note: don't just cast everything to float automatically since we
			; want to preserve the ability to write BYTE or INT types as well.
			if size(*DataSet.currFrame,/TNAME) eq 'DOUBLE' then *DataSet.currFrame = float(*DataSet.currFrame)

			mwrfits, *DataSet.currFrame, c_File, *DataSet.HeadersExt[i],/silent
		endelse

		if ptr_valid(dataset.currDQ) then mwrfits, byte(*dataset.currDQ), c_File, *DataSet.HeadersDQ[i], /silent
		if ptr_valid(dataset.currUncert) then mwrfits, float(*dataset.currUncert), c_File, *DataSet.HeadersUncert[i], /silent

      	DataSet.OutputFilenames[i] = c_File  
	endelse

	if keyword_set(debug) then print, "  Data output ===>>> "+c_File
	Backbone_comm->Log, "File output to: "+c_File, depth=1

	;--- If a calibrations file, update the GPI Calibrations DB index ----
	; Is this a calibration file? 
	;   (check both pri + ext headers just to be sure...)
	if is_calib_pri or is_calib_ext then begin
		if obj_valid(gpicaldb) then begin
			message,/info, "Adding file to GPI Calibrations DB."
			status = gpicaldb->Add_new_Cal( c_File)
		endif else begin
			message,/info, "*** ERROR: No Cal DB Object Loaded - cannot add file to DB ***"
		endelse

	endif

	;--- Update progress bar
	if obj_valid(backbone_comm) then backbone_comm->set_last_saved_file, c_File
  
	;--- Display image, if requested
	if ( keyword_set( display ) ) && (display ne 0) then Backbone_comm->gpitv, c_File, ses=display

    return, OK

end
