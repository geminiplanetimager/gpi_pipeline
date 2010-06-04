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
;          SaveHeader=	 Header for writing along with the SaveData data.
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
;
;-


function save_currdata, DataSet,  s_OutputDir, s_Ext, display=display, savedata=savedata, saveheader=saveheader, filenm=filenm, $
		output_filename=c_File1, level2=level2

    COMMON APP_CONSTANTS
    COMMON PIP

	getmyname, functionname
	version = gpi_pipeline_version()

    ;for i=0, nFrames-1 do begin
    if keyword_set(level2) then i=level2-1 else $
    i=numfile


       ;c_File = make_filename ( DataSet.Headers[i], s_OutputDir, s_Ext )
       filnm=sxpar(*(DataSet.Headers[i]),'DATAFILE')
       slash=strpos(filnm,path_sep(),/reverse_search)

		; test output dir
		if ~file_test(s_OutputDir,/directory, /write) then return, error("FAILURE: Directory "+s_OutputDir+" does not exist or is not writeable.",/alert)

		c_File = s_OutputDir+strmid(filnm, slash,strlen(filnm)-5-slash)+s_Ext+'.fits'

       if ( NOT bool_is_string(c_File) ) then $
          return, error('FAILURE ('+functionName+'): Output filename creation failed.')

       if ( strpos(c_File ,'.fits' ) ne -1 ) then $
;          c_File1 = strmid(c_File,0,strlen(c_File)-5)+'_'+strg(i)+'.fits' $
          c_File1 = strmid(c_File,0,strlen(c_File)-5)+'.fits' $
       else begin
          warning, 'WARNING('+functionName+'): Filename is not fits compatible. Adding .fits.'
          c_File1 = c_File+'_'+strg(i)+'.fits'
       end

       if ( keyword_set( filenm ) ) then  c_File1=filenm
       ;writefits, c_File1, float(*DataSet.Frames(i)), *DataSet.Headers[i]
       ;writefits, c_File1, float(*DataSet.IntFrames(i)), /APPEND
       ;writefits, c_File1, byte(*DataSet.IntAuxFrames(i)), /APPEND
    	if ( keyword_set( savedata ) ) then begin 
			sxaddpar, saveheader, 'DRPVER', version, 'Version number of GPI data reduction pipeline software'
		   writefits, c_File1, savedata, saveheader
		   curr_hdr = saveheader
		endif else begin
			sxaddpar, *DataSet.Headers[i], 'DRPVER', version, 'Version number of GPI data reduction pipeline software'
			writefits, c_File1, *DataSet.currFrame, *DataSet.Headers[i]
			DataSet.OutputFilenames[i] = c_File1
			curr_hdr = *DataSet.Headers[i]
		endelse

		if keyword_set(debug) then print, "  Data output ===>>> "+c_File1
		Backbone_comm->Log, "File output to: "+c_File1,/general,/DRF, depth=1
 
		;--- GPI Calibrations DB ----
		is_calib = sxpar(curr_hdr, "ISCALIB")
		if strc(strupcase(is_calib)) eq "YES" then begin
			gpicaldb = Backbone_comm->Getgpicaldb()
			if obj_valid(gpicaldb) then begin
				message,/info, "Adding file to GPI Calibrations DB."
				status = gpicaldb->Add_new_Cal( c_File1, header=curr_hdr)
			endif else begin
				message,/info, "*** ERROR: No Cal DB Object Loaded - cannot add file to DB ***"
			endelse
		endif

		;--- Update progress bara
		(Backbone_comm->Getprogressbar() )->set_suffix, s_Ext

      
  		if ( keyword_set( display ) ) && (display ne 0) then Backbone_comm->gpitv, c_File1, ses=display


    return, OK

end
