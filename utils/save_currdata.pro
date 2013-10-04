;+
; NAME:  save_currdata
;
; PURPOSE: save the dataset
;
; INPUT :  DataSet     : the DataSet pointer.
;          nFrames     : number of datasets
;          s_OutputDir : the output directory
;          s_Ext       : output filename extension (suffix)
;          /DEBUG      : initializes debugging mode
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
;-


function save_currdata, DataSet,  s_OutputDir, s_Ext, display=display, savedata=savedata, saveheader=saveheader, savePHU=savePHU,  $
		output_filename=c_File, level2=level2, addexten_var=addexten_var, addexten_qa=addexten_qa

    COMMON APP_CONSTANTS
    COMMON PIP

	getmyname, functionname
	version = gpi_pipeline_version()

    if keyword_set(level2) then i=level2-1 else i=numfile ;; WTF??

	;-- Generate output filename, starting from the input one.
	;   Also determine output directory
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
		return, error('FAILURE: supplied output directory is a blank string.')
	endif

	if ~file_test(s_OutputDir,/directory, /write) then begin

		if gpi_get_setting('prompt_user_for_outputdir_creation',/bool, default=1) then $
            res =  dialog_message('The requested output directory '+s_OutputDir+' does not exist. Should it be created now?', $
            title="Nonexistent Output Directory", /question) else res='Yes'

        if res eq 'Yes' then begin
            file_mkdir, s_OutputDir
        endif else begin
			return, error("FAILURE: Directory "+s_OutputDir+" does not exist or is not writeable.",/alert)
		endelse
	endif

	; ensure we have a directory separator, if it's not there already
	if strmid(s_OutputDir, strlen(s_OutputDir)-1,1) ne path_sep() then s_OutputDir+= path_sep()


	; If an extra path separator is present at the end, drop it:
	;slash=strpos(filnm,path_sep(),/reverse_search)
	;if slash ge 0 then begin
		;c_File = s_OutputDir+strmid(filnm, slash,strlen(filnm)-5-slash)+s_Ext+'.fits'
	;endif else begin
		;dot = strpos(filnm,".",/reverse_search)
		;c_file = s_OutputDir + path_sep() + strmid(filnm, 0, dot) + s_Ext+'.fits'
	;endelse


	; Generate output filename
	; remove extension if need be
	base_filename = file_basename(filenm)
	extloc = strpos(base_filename,'.', /reverse_search)

	; suffix must be separated by a dash
	if strmid(s_Ext,0,1) ne '-' then s_Ext = '-'+s_Ext

	c_File = s_OutputDir + strmid(filenm,0,extloc)+ s_Ext+'.fits'


	if ( NOT bool_is_string(c_File) ) then $
	   return, error('FAILURE ('+functionName+'): Output filename creation failed.')


    ;============  File name collision handling ======
	; Check if the requested output filename already exists. 

	if file_test(c_File) then begin
		collision_handling = gpi_get_setting('file_overwrite_handling', default='ask_user',/silent)

		if strmatch(collision_handling, '*overwrite*', /fold) then  begin
;		case gpi_get_setting('file_overwrite_handling', default='ask_user',/silent) of
;		'overwrite': begin  
			; we just overwrite it, bull in a china shop style
			backbone_comm->Log, 'Overwriting existing output filename: '+c_File
		endif else if strmatch(collision_handling, '*ask*', /fold) then begin
		;'ask_user': begin
			; If so, ask the user if it should be overwritten or not
			;
			; Iterate if necessary. Foolish users, always trying to overwrite things...
			
			while file_test(c_File) do  begin
			;and gpi_get_setting('prompt_user_for_overwrite', default=1,/silent)) 
				statuswindow = backbone_comm->getstatusconsole()

				if obj_valid(statuswindow) then begin
					status_top_widget = statuswindow->get_top_base() 
				endif else begin
					backbone_comm->Log, 'Output Filename: '+c_File
					backbone_comm->Log, 'File already exists, and prompt_user_for_overwrite is set. However, GUI is not currently available.'
					return, error( " Won't overwrite automatically but cannot prompt user for a new filename!")
				endelse

				if confirm(message=['The file '+c_File+' already exists on disk. ','',  'Are you sure you want to overwrite this file?'], $
						label0='Change Filename',label1='Overwrite', title="Confirm Overwrite File", group_leader=status_top_widget) then begin
							; user has chosen to overwrite
							break
				endif else begin
					c_File = dialog_pickfile(/write, default_extension='fits', file=c_File, filter='*.fits', $
						path=s_OutputDir, title='Select New Filename' )
				endelse

			endwhile
		;end
		endif else if strmatch(collision_handling,'*append*', /fold) then begin
		;'ask_user': begin
		;'append_number': begin
			; Append an extension number to the filename to avoid overwriting.
			basefn = fsc_base_filename(c_File, extension=extfn)
			counter=0
			while file_test(c_File) do begin
				counter += 1
				c_File = basefn + "_"+strc(counter)+"."+extfn
			endwhile
			backbone_comm->Log, 'Appended _'+strc(counter)+" to output filename to avoid overwriting."
		endif else begin
			stop
			backbone_comm->Log, 'Invalid setting for file_overwrite_handling. Must be one of [overwrite, ask_user, append_number]'
			return, error('Invalid setting for file_overwrite_handling. Must be one of [overwrite, ask_user, append_number]')
		endelse

		;endcase
	endif	



	; Now we can proceed to actually writing out the file. 
	; First update the header if we're writing out VAR or DQ extensions.
	FXADDPAR,  *(dataset.headersPHU[numfile]),'NEXTEND',1+keyword_set(addexten_var)+keyword_set(addexten_qa)


    caldat,systime(/julian,/utc),month,day,year, hour,minute,second
    datestr = string(year,month,day,format='(i4.4,"-",i2.2,"-",i2.2)')
    hourstr = string(hour,minute,second,format='(i2.2,":",i2.2,":",i2.2)')  

	;--- write out either some user-supplied data (if explicitly provided), or the current data frame
	if ( keyword_set( savedata ) ) then begin  ; The calling function has specified some special data to save, in place of the currFrame data
	  	if ~( keyword_set( saveheader ) ) then saveheader = *(dataset.headersExt[numfile])
		if ~( keyword_set( savePHU ) ) then savePHU = *(dataset.headersPHU[numfile])
		fxaddpar, savePHU, 'DRPVER', version, ' Version number of GPI DRP software', after='TLCVER'
		fxaddpar, savePHU, 'DRPDATE', datestr+' '+hourstr, ' UT creation time of this reduced data file', after='UTEND'
		mwrfits, 0, c_File, savePHU, /create,/silent
		writefits, c_File, float(savedata), saveheader, /append

		curr_hdr = savePHU
		curr_ext_hdr = saveheader
	endif else begin
      	fxaddpar, *DataSet.HeadersPHU[i], 'DRPVER', version, ' Version number of GPI DRP software', after='TLCVER'
      	fxaddpar, *DataSet.HeadersPHU[i], 'DRPDATE', datestr+'T'+hourstr, ' UT creation time of this reduced data file', after='UTEND'
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
			mwrfits, float(*DataSet.currFrame), c_File, *DataSet.HeadersExt[i],/silent
		endelse
      	curr_hdr = *DataSet.HeadersPHU[i]
      	curr_ext_hdr = *DataSet.HeadersExt[i]
      	DataSet.OutputFilenames[i] = c_File  
	endelse

	if keyword_set(addexten_qa) then mwrfits, byte(addexten_qa), c_File,/silent
	if keyword_set(addexten_var) then mwrfits, float(addexten_var), c_File,/silent
  
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
	statuswindow = (Backbone_comm->Getprogressbar() )
	if obj_valid(statuswindow) then statuswindow->set_last_saved_file, c_File
  
	;--- Display image, if requested
	if ( keyword_set( display ) ) && (display ne 0) then Backbone_comm->gpitv, c_File, ses=display

    return, OK

end
