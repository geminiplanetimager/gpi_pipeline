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
;          filenm=		 Filename for writing (to override default file name)
;
;          SaveData=     Save this data INSTEAD of the current DataSet pointer
;          SaveHeader=	 Extension Header for writing along with the SaveData data.
;          SavePHU=		 Primary header for writing along with the SaveData data.
;
; OUTPUT : Saves the dataset to disk
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
;-


function save_currdata, DataSet,  s_OutputDir, s_Ext, display=display, savedata=savedata, saveheader=saveheader, savePHU=savePHU, filenm=filenm, $
		output_filename=c_File1, level2=level2, addexten_var=addexten_var, addexten_qa=addexten_qa

    COMMON APP_CONSTANTS
    COMMON PIP

	getmyname, functionname
	version = gpi_pipeline_version()

    if keyword_set(level2) then i=level2-1 else i=numfile

	;-- Generate output filename, starting from the input one.
	;   Also determine output directory
	filnm=fxpar(*(DataSet.HeadersPHU[i]),'DATAFILE',count=cdf)
    if cdf eq 0 then begin 
        message,/info, 'No DATAFILE keyword supplied'
        ; fallback to input filename
        filnm = dataset.filenames[i]
    endif else if (strc(filnm) eq 'NONE') or (strc(filnm) eq '')  then begin
        ; for GDS produced output files that don't have valid DATAFILE keywds yet 
        ; fall back on the input filename
        filnm = dataset.filenames[i]
    endif

	;Check both primary and extension headers for an ISCALIB keyword. If set to 'YES', then output should go to the calibrations file directory.
	is_calib_pri=0 & is_calib_ext=0
    if keyword_set(savePHU) then is_calib_pri = strc(strupcase(fxpar(savePHU, "ISCALIB"))) eq 'YES' else $
      is_calib_pri = strc(strupcase(fxpar(*(dataset.headersPHU[numfile]), "ISCALIB"))) eq 'YES'
    if keyword_set(saveheader) then is_calib_ext = strc(strupcase(fxpar(saveheader, "ISCALIB"))) eq 'YES' else $
      is_calib_ext = strc(strupcase(fxpar(*(dataset.headersExt[numfile]), "ISCALIB"))) eq 'YES' 

    if is_calib_pri or is_calib_ext then begin
      gpicaldb = Backbone_comm->Getgpicaldb()
      s_OutputDir = gpicaldb->get_calibdir()
    endif
	
	s_OutputDir = gpi_expand_path(s_OutputDir) ; expand environment variables and ~s
	; test output dir
	if ~file_test(s_OutputDir,/directory, /write) then begin
		if gpi_get_setting('organize_reduced_data_by_dates') then begin
			; check that at least the parent dir exists
			if ~file_test(file_dirname(s_OutputDir),/directory, /write) then return, error("FAILURE: Directory "+s_OutputDir+" does not exist or is not writeable.",/alert) $
			else file_mkdir, s_OutputDir
		endif else begin
			return, error("FAILURE: Directory "+s_OutputDir+" does not exist or is not writeable.",/alert)
		endelse
	endif

	; If an extra path separator is present at the end, drop it:
	slash=strpos(filnm,path_sep(),/reverse_search)
	if slash ge 0 then begin
		c_File = s_OutputDir+strmid(filnm, slash,strlen(filnm)-5-slash)+s_Ext+'.fits'
	endif else begin
		dot = strpos(filnm,".",/reverse_search)
		c_file = s_OutputDir + path_sep() + strmid(filnm, 0, dot) + s_Ext+'.fits'
	endelse

    caldat,systime(/julian),month,day,year, hour,minute,second
    datestr = string(year,month,day,format='(i4.4,i2.2,i2.2)')
    hourstr = string(hour,minute,second,format='(i2.2,i2.2,i2.2)')  


	if ( NOT bool_is_string(c_File) ) then $
	   return, error('FAILURE ('+functionName+'): Output filename creation failed.')
	   	
	if ( strpos(c_File ,'.fits' ) ne -1 ) then $
	   c_File1 = strmid(c_File,0,strlen(c_File)-5)+'.fits' $
	else begin
	   warning, 'WARNING('+functionName+'): Filename is not fits compatible. Adding .fits.'
	   c_File1 = c_File+'_'+strg(i)+'.fits'
	end

	if ( keyword_set( filenm ) ) then  c_File1=filenm
	
	;if keyword_set(addexten_qa) || keyword_set(addexten_var) then 
	FXADDPAR,  *(dataset.headersPHU[numfile]),'NEXTEND',1+keyword_set(addexten_var)+keyword_set(addexten_qa)


	;--- write out either some user-supplied data (if explicitly provided), or the current data frame
	if ( keyword_set( savedata ) ) then begin  ; The calling function has specified some special data to save, in place of the currFrame data
	  	if ~( keyword_set( saveheader ) ) then saveheader = *(dataset.headersExt[numfile])
		if ~( keyword_set( savePHU ) ) then savePHU = *(dataset.headersPHU[numfile])
		fxaddpar, savePHU, 'DRPVER', version, 'Version number of GPI data reduction pipeline software'
		fxaddpar, savePHU, 'DRPDATE', datestr+'-'+hourstr, 'Date and time of creation of the DRP reduced data [yyyymmdd-hhmmss]'
		mwrfits, 0, c_File1, savePHU, /create,/silent
		writefits, c_File1, float(savedata), saveheader, /append

		curr_hdr = savePHU
		curr_ext_hdr = saveheader
	endif else begin
      	fxaddpar, *DataSet.HeadersPHU[i], 'DRPVER', version, 'Version number of GPI data reduction pipeline software'
      	fxaddpar, *DataSet.HeadersPHU[i], 'DRPDATE', datestr+'-'+hourstr, 'Date and time of creation of the DRP reduced data [yyyymmdd-hhmmss]'
		mwrfits, 0, c_File1, *DataSet.HeadersPHU[i], /create,/silent
		mwrfits, float(*DataSet.currFrame), c_File1, *DataSet.HeadersExt[i],/silent
      	curr_hdr = *DataSet.HeadersPHU[i]
      	curr_ext_hdr = *DataSet.HeadersExt[i]
      	DataSet.OutputFilenames[i] = c_File1  
	endelse

	if keyword_set(addexten_qa) then mwrfits, byte(addexten_qa), c_File1,/silent
	if keyword_set(addexten_var) then mwrfits, float(addexten_var), c_File1,/silent
  
	if keyword_set(debug) then print, "  Data output ===>>> "+c_File1
	Backbone_comm->Log, "File output to: "+c_File1,/general,/DRF, depth=1

	;--- If a calibrations file, update the GPI Calibrations DB index ----
	; Is this a calibration file? 
	;   (check both pri + ext headers just to be sure...)
	if is_calib_pri or is_calib_ext then begin
		if obj_valid(gpicaldb) then begin
			message,/info, "Adding file to GPI Calibrations DB."
			status = gpicaldb->Add_new_Cal( c_File1)
		endif else begin
			message,/info, "*** ERROR: No Cal DB Object Loaded - cannot add file to DB ***"
		endelse

	endif

	;--- Update progress bar
	statuswindow = (Backbone_comm->Getprogressbar() )
	if obj_valid(statuswindow) then statuswindow->set_suffix, s_Ext
  
	;--- Display image, if requested
	if ( keyword_set( display ) ) && (display ne 0) then Backbone_comm->gpitv, c_File1, ses=display

    return, OK

end
