;+
; NAME:  gpi_load_and_preprocess_fits_file
;
;  **DEPRECATED, DO NOT USE**
;  Intended for use only with early lab testing data.
;
;
;	This loads an arbitrary GPI file from any point in time during I&T, and 
;	performs the necessary header manipulations to turn it into a
;	Gemini-GPI-standard-compliant file, with 2 headers. 
;
;   This preprocessing can be needed because of variations in the GPI
;   data format as the instrument and pipeline are developing. This
;   routine provides a convenient place to perform whatever actions
;   are needed to read disparate input files into a common format in memory.
;
;
;	Note that this does **Not** modify the FITS file on disk, it just
;	modifies the header in memory.
;
;
;	It should eventually be unnecessary to ever use this routine, once
;	we have data with good FITS headers. 
;
;	NOTE: Don't call this directly. Call gpi_load_fits instead, and it will
;	preprocess if that is enabled in the config files.
;
; INPUTS:
; KEYWORDS:
; 	/nodata		Don't return (or update) the data, just give the headers
; OUTPUTS:
;
; HISTORY:
;	Began 2012-01-30 19:15:23 by Marshall Perrin 
;	2012-08-22 MP: gpi_load_fits now calls this if preprocess_fits is set in the
;					config. Essentially all code should now call gpi_load_fits
;					instead of calling this directly.
;	2012-12-08 MP: Added support for reading in DQ and Uncert extensions, if
;					present
;-
;--------------------------------------------------------------------------------


; simple utility function for a common task
pro gpi_set_keyword_if_missing, pri_header, ext_header, keyword, value, comment, _extra=_extra
	val = gpi_get_keyword(pri_header, ext_header, keyword, count=count,/silent)
	if count eq 0 then gpi_set_keyword, keyword, value, pri_header, ext_header, comment=comment, _extra=_extra,/silent
end


;--------------------------------------------------------------------------------
FUNCTION gpi_load_and_preprocess_FITS_file, filename, orient=orient,nodata=nodata, silent=silent, $
	filter=defaultfilter, apodizer=defaultapodizer, occulter=defaultocculter

	compile_opt defint32, strictarr, logical_predicate

	if ~(keyword_set(orient)) then orient='vertical' ; desired spectral orientation is vertical
	desired_orient='vertical'

	; This loads the files into the local variables:
	;	currframe
	;	pri_header
	;	ext_header
	; It then returns an anonymous struct containing pointers to those three
	; items. 

	NOT_OK =  -1

    if ~file_test(filename,/read) then begin
        message,/info, "ERROR: File does not exist: "+filename
        return,NOT_OK
    endif

	; Read in the file, and check whether it is a single image or has
	; extensions.
    fits_info, filename, n_ext = numext, /silent
    if (numext EQ 0) then begin
		; No extension present: Read primary image into the data array
		;  and copy the only header into both the primary and extension headers
		;  (see below where we append the DRF onto the primary header)
		if keyword_set(nodata) then begin
			header = headfits(filename,/silent)
		endif else begin
			currframe = (READFITS(filename , Header, /SILENT))
		endelse

		pri_header=header
		*(*self.data).HeadersExt[IndexFrame] = header
		fxaddpar,  *(*self.data).HeadersExt[IndexFrame],'HISTORY', 'Input image has no extensions, so primary header copied to 1st extension'
		mkhdr,ext_header,currframe
		sxaddpar,ext_header,"XTENSION","IMAGE","Image extension",before="SIMPLE"
		sxaddpar,ext_header,"EXTNAME","SCI","Image extension contains science data";,before="SIMPLE"
		sxaddpar,ext_header,"EXTVER",1,"Number assigned to FITS extension";,before="SIMPLE"
		sxdelpar, ext_header, "SIMPLE"
		;add blank wcs keyword in extension (mandatory for all gemini data)
		wcskeytab=["CTYPE1","CD1_1","CD1_2","CD2_1","CD2_2","CDELT1","CDELT2",$
		  "CRPIX1","CRPIX2","CRVAL1","CRVAL2","CRVAL3","CTYPE1","CTYPE2"]
		for iwcs=0,n_elements(wcskeytab)-1 do $
		sxaddpar,ext_header,wcskeytab[iwcs],'','',before="END"
		;*(*self.data).HeadersExt[IndexFrame] = ext_header
    endif
    if (numext ge 1) then begin
		; at least one extension is present:  Read the 1st extention image into
		; the data array, and read in the primary and extension headers. 
		;  (see below where we append the DRF onto the primary header)
		if keyword_set(nodata) then begin
			pri_header = headfits(filename, exten=0, /silent)
			ext_header = headfits(filename, exten=1, /silent)
		endif else begin
			currframe        = (mrdfits(filename , 1, ext_Header, /SILENT))
			pri_header = headfits(filename, exten=0, /silent)
		endelse

	endif 
		
    if n_elements( currframe ) eq 1 then if currframe eq -1 then begin
        message,/info, "ERROR: Unable to read file "+filename
        return,NOT_OK 
    endif


	;if ~(keyword_set(silent)) then message,/info, '** Updating header to match Gemini standard ** '
	sxaddpar, pri_header, 'HISTORY', 'FITS headers updated for GPI standard compliance.'	

	;Gemini requirement: test and add extname 'SCI' if not present
	val_extname = sxpar(ext_header,"EXTNAME",count=cextname,/silent)
	if (cextname eq 0) || (strlen(strcompress(val_extname,/rem)) eq 0) then sxaddpar,ext_header,"EXTNAME","SCI","Image extension contains science data"
	if (cextname eq 1) AND ~(stregex(val_extname,'SCI',/bool)) AND ~(strlen(strcompress(val_extname,/rem)) eq 0) then begin
		self->Log, "ERROR:  found"+val_extname+"in the first extension"+filename
		self->Log, "ERROR:  first extension need SCI Extname"+filename
		self->Log, 'Reduction failed: ' + filename
		return,NOT_OK 
	endif
  

	;---- update the headers: FITS standard compliance
	; Check and if necessary update required FITS keywords for extensions
	val_extend = sxpar(pri_header, 'EXTEND',count=cextend)
	if cextend eq 0 or byte(val_extend) eq 0 then fxaddpar, pri_header, 'EXTEND', 'T', 'FITS file contains extensions'
	val_nextend = sxpar(pri_header, 'nextend',count=cnextend)
	if cnextend eq 0 or val_nextend lt 1 then fxaddpar, pri_header, 'NEXTEND', 1, 'FITS file contains extensions'
	val_naxis1 = sxpar(pri_header, 'naxis1',count=cnaxis1) ;remove NAXIS1 & NAXIS2 in PHU
	if cnaxis1 gt 0 then sxdelpar, pri_header, 'NAXIS1'
	val_naxis2 = sxpar(pri_header, 'naxis2',count=cnaxis2)
	if cnaxis2 gt 0 then sxdelpar, pri_header, 'NAXIS2'
	
 
	;--- update the headers: fix obsolete keywords by changing them
	;  to official standardized values. 
	
	obsolete_keywords = ['PRISM',   'FILTER3',  'FILTER4', 'FILTER', 'FILTER1', 'LYOT', 'GAIN']
	approved_keywords = ['DISPERSR','DISPERSR',  'ADC',    'IFSFILT' ,'IFSFILT', 'LYOTMASK', 'SYSGAIN']
	default_values = ['Spectral','Spectral','OUT','H','H', 'CLASSIC','1.0']

	for i=0L, n_elements(approved_keywords)-1 do begin
		val_approved = gpi_get_keyword(pri_header, ext_header, approved_keywords[i], count=count,/silent)
		if count eq 0 then begin ; only try to update if we are missing the approved keyword.
			; in that case, see if we have an obsolete keyword and then try to
			; use it.
			val_obsolete = gpi_get_keyword(pri_header, ext_header, obsolete_keywords[i], count=count_obs, comment=comment,/silent)
			if count_obs eq 0 then begin
				val_obsolete = default_values[i]
				comment = ' KEYWORD WAS MISSING - Default value'
			endif
			;if count_obs gt 0 then begin 
				gpi_set_keyword, approved_keywords[i], val_obsolete, pri_header, ext_header, comment=comment,/silent
				if ~(keyword_set(silent)) then message,/info, 'Converted obsolete keyword '+obsolete_keywords[i]+' into '+approved_keywords[i]+" with value="+strc(val_obsolete)
			;endif
		endif
		sxdelpar, pri_header, obsolete_keywords[i]
	endfor 


    ;;change DISPERSR value according to GPI new conventions
    val_disp = gpi_get_keyword(pri_header, ext_header, 'DISPERSR', count=count,/silent)
    newval_disp=val_disp
    if strmatch(val_disp, '*Spectr*') then newval_disp='DISP_PRISM_G6262' 
    if strmatch(val_disp, '*Pol*') then newval_disp='DISP_WOLLASTON_G6261'
    if strmatch(val_disp, '*Und*') then newval_disp='DISP_OPEN_G6263'
    if strmatch(strc(val_disp), '0') then newval_disp='DISP_OPEN_G6263'
    if strmatch(strc(val_disp), '1') then newval_disp='DISP_WOLLASTON_G6261'
    if strmatch(strc(val_disp), '2') then newval_disp='DISP_PRISM_G6262' 
    if strmatch(strc(val_disp), '3') then newval_disp='DISP_OPEN_G6263'



    ;if strlen(newval_disp) eq 0 then message, "Unknown/invalid value for DISPERSR keyword: "+strc(val_disp)
	if newval_disp ne val_disp then gpi_set_keyword, 'DISPERSR', newval_disp,  pri_header, ext_header, silent=silent

    ;;add POLARIZ & WPSTATE keywords, if they are missing
	;val_polariz = gpi_get_keyword(pri_header, ext_header, 'POLARIZ', count=count)
	;default_polariz =   strmatch(val_disp, '*Pol*')  ? 'DEPLOYED' : 'EXTRACTED'
	;gpi_set_keyword_if_missing, pri_header, ext_header, 'POLARIZ', default_polariz 

	default_WPSTATE =   strmatch(val_disp, '*Pol*')  ? 'IN' : 'OUT'
	gpi_set_keyword_if_missing, pri_header, ext_header, 'WPSTATE', default_WPSTATE, comment="KEYWORD WAS MISSING - Default value"

    ;;change FILTER1 value according to GPI new conventions
    val_old = gpi_get_keyword(pri_header, ext_header, 'IFSFILT', count=count,/silent)
    newval=''
    tabfiltold=['Y','J','H','K1','K2']
    newtabfilt=['IFSFILT_Y_G1211','IFSFILT_J_G1212','IFSFILT_H_G1213','IFSFILT_K1_G1214','IFSFILT_K2_G1215']
    indc=where(strmatch(tabfiltold,strcompress(val_old,/rem)))
    if indc ge 0 then newval=(newtabfilt[indc])[0]
    if strlen(newval) gt 0 then gpi_set_keyword, 'IFSFILT', newval, pri_header, ext_header, silent=silent


	gpi_set_keyword_if_missing, pri_header, ext_header, 'TELESCOP', 'Gemini South', comment="KEYWORD WAS MISSING - Default value"
	gpi_set_keyword_if_missing, pri_header, ext_header, 'INSTRUME', 'GPI', comment="KEYWORD WAS MISSING - Default value"


	; Are we looking at pupil camera data or real IFS data? 
	if sxpar(ext_header, 'NAXIS1') eq 320 and sxpar(ext_header, 'NAXIS2') eq 240 then instrsub = 'GPI IFS Pupil' else instrsub ='GPI IFS'
	gpi_set_keyword_if_missing, pri_header, ext_header, 'INSTRSUB', instrsub, comment='KEYWORD WAS MISSING - Guessed value'


	; Default OBSTYPE should be Dark if the blank is in
	lyotmask = gpi_get_keyword(pri_header, ext_header, 'LYOTMASK', count=ct_lyot,/silent)
	if strmatch(lyotmask, "*blank*",/fold_case) then default_obstype='DARK' else default_obstype='OBJECT'
	gpi_set_keyword_if_missing, pri_header, ext_header, 'OBSTYPE', default_obstype, comment='KEYWORD WAS MISSING - unknown'
	gpi_set_keyword_if_missing, pri_header, ext_header, 'OBSID', 'GS-1', comment='KEYWORD WAS MISSING - unknown'
	gpi_set_keyword_if_missing, pri_header, ext_header, 'OCCULTER', 'FPM_BLANK_G6221', comment='KEYWORD WAS MISSING - unknown'
	gpi_set_keyword_if_missing, pri_header, ext_header, 'OBJECT', 'Unknown', comment='KEYWORD WAS MISSING - unknown'

	;if OBSTYPE is blank, it ought to be SCIENCE instead (unless the blank is in, in which case we just set the default to dark) 
	obstypeval =gpi_get_keyword(pri_header, ext_header, 'OBSTYPE')
	if strc(obstypeval)  eq '' then gpi_set_keyword, 'OBSTYPE', default_obstype, pri_header, ext_header, comment='KEYWORD WAS BLANK - setting to default'

    ;add OBSMODE keyword
	gpi_set_keyword_if_missing, pri_header, ext_header , 'OBSMODE', val_old, comment='KEYWORD WAS MISSING - unknown' ; set mode to base filter name
	;add ABORTED keyword
	gpi_set_keyword_if_missing, pri_header, ext_header, 'ABORTED', 'F' , comment='KEYWORD WAS MISSING - unknown'

    ;change BUNIT value
	gpi_set_keyword_if_missing, pri_header, ext_header, 'BUNIT', 'Counts/second/coadd' , comment='KEYWORD WAS MISSING - unknown?'

    ;gpi_set_keyword, 'BUNIT', 'Counts/seconds/coadd',  indexFrame=indexFrame,ext_num=1, silent=silent
    ;sxdelpar, *(*self.data).HeadersPHU[IndexFrame], 'BUNIT'
    ;add DATASEC keyword

	val = gpi_get_keyword(pri_header, ext_header, 'ITIME', count=count_itime,/silent)
	; to be standards compliant, the ITIME *must* be in the extension header
	val = sxpar( ext_header, 'ITIME', count=count_itime,/silent)
	
	; Update time keywords if needed - but NOT for pupil viewer images
	if count_itime eq 0 and gpi_get_keyword(pri_header, ext_header, 'INSTRSUB') ne 'GPI IFS Pupil' then begin
		if ~(keyword_set(silent)) then message,/info, 'Updating exposure time keywords.'
		;change ITIME,EXPTIME,ITIME0,TRUITIME: 
		;BE EXTREMLY CAREFUL with change of units
		;;old itime[millisec], old exptime[in sec]
		;; new itime [seconds per coadd],  new itime0 [microsec per coadd]
		

		; find the old requested ITIME0, which should be in microsec.
		val_old_itime0 = gpi_get_keyword(pri_header, ext_header, 'ITIME0', count=count,/silent)
		if count eq 0 then begin
			if ~(keyword_set(silent)) then message,/info,'No ITIME0 keyword found; assuming ITIME *1e3'
			val_old_itime = gpi_get_keyword(pri_header, ext_header, 'itime', count=count,/silent)
			val_old_itime0 = 1e3*val_old_itime
		endif

		; find the old actual ITIME / TRUITIME, which should be in seconds.
		val_old_itime = float(gpi_get_keyword(pri_header, ext_header, 'TRUITIME', count=count,/silent))  ; TRUITIME is in seconds in Jason's new data
		if count eq 0 then begin
			if ~(keyword_set(silent)) then message,/info,'No TRUITIME keyword found; assuming ITIME instead'
			val_old_itime = gpi_get_keyword(pri_header, ext_header, 'ITIME', count=count,/silent)
		endif
		if count eq 0 then begin
			if ~(keyword_set(silent)) then message,/info,'No ITIME keyword found; assuming EXPTIME instead'
			val_old_itime = gpi_get_keyword(pri_header, ext_header, 'EXPTIME', count=count,/silent)
		endif

		sxdelpar, pri_header, 'ITIME'
		sxdelpar, pri_header, 'ITIME0'
		sxdelpar, pri_header, 'EXPTIME'
		sxdelpar, pri_header, 'TRUITIME'
		gpi_set_keyword, 'ITIME', float(val_old_itime),  comment='Exposure integration time in seconds per coadd', pri_header, ext_header, silent=silent
		gpi_set_keyword, 'ITIME0', long(val_old_itime0),  comment='Requested integration time in microsec per coadd', pri_header, ext_header, silent=silent
		;gpi_set_keyword, 'EXPTIME', float(val_old_itime),  comment='Exposure integration time in seconds per coadd', pri_header, ext_header, silent=silent
	endif

	; sanity check the value for units (assumes no exposures will be taken over
	; >1000 s in duration
	val_itime = gpi_get_keyword(pri_header, ext_header, 'ITIME')
	if val_itime gt 1000 then begin
		if ~(keyword_set(silent)) then message,/info, 'ITIME value is very large ('+strc(val_itime)+"); therefore assuming it's in milliseconds and converting."
		gpi_set_keyword, 'ITIME', float(val_itime)/1000, pri_header, ext_header, silent=silent
	endif

	gpi_set_keyword_if_missing, pri_header, ext_header, 'COADDS', 1, 'Number of coadded reads.'

    ;;add UTSTART
    val_timeobs = gpi_get_keyword(pri_header, ext_header, 'TIME-OBS', count=count,/silent)
    gpi_set_keyword_if_missing, pri_header, ext_header, 'UTSTART', val_timeobs,  'UT at observation start'

    ;;change GCALLAMP values      
    val_lamp = gpi_get_keyword(pri_header, ext_header, 'GCALLAMP', count=count,/silent)
    val_object = gpi_get_keyword(pri_header, ext_header, 'OBJECT', count=count,/silent) ; keyword used in UCLA tests
    newlamp=''
    if strmatch(val_lamp,'*Xenon*',/fold) or strmatch(val_object, '*Xenon*',/fold)then newlamp='Xe'
    if strmatch(val_lamp,'*Argon*',/fold) or strmatch(val_object, '*Argon*',/fold)then newlamp='Ar'
    if strlen(newlamp) gt 0 and newlamp ne strc(val_lamp) then gpi_set_keyword, 'GCALLAMP', newlamp, pri_header, ext_header, silent=silent

    ;;change OBSTYPE ("wavecal" to "ARC" value)
    val_obs = gpi_get_keyword(pri_header, ext_header, 'OBSTYPE', count=count,/silent)
    newobs=val_obs
    if strmatch(val_obs,'*Wavecal*',/fold) then newobs='ARC'
    if newobs ne val_obs then gpi_set_keyword, 'OBSTYPE', newobs, pri_header, ext_header, silent=silent

    ;add ASTROMTC keyword
    val_old = gpi_get_keyword(pri_header, ext_header, 'OBSCLASS', count=count,/silent)
    if strmatch(val_old, '*AstromSTD*',/fold) then astromvalue='T' else astromvalue='F'
    gpi_set_keyword_if_missing, pri_header, ext_header, 'ASTROMTC', astromvalue, comment='KEYWORD WAS MISSING - Guessed value' ,/silent
    
    ;;set the reserved OBSCLASS keyword
    gpi_set_keyword_if_missing, pri_header, ext_header, 'OBSCLASS', 'acq' , comment='KEYWORD WAS MISSING - Default value'

    ;;add the INPORT keyword
	val_port = sxpar(pri_header, 'INPORT', count=count)
	if count eq 0 then begin
		val_port = gpi_get_keyword(pri_header, ext_header, 'ISS_PORT', count=count,/silent)
		newport=0
		if count eq 0 then newport=1
		if strmatch(val_port,'*bottom*') then newport=1
		if strmatch(val_port,'*side*') then newport=2
		if strmatch(val_port,'*perfect*') then newport=6
		if newport ne val_port then gpi_set_keyword, 'INPORT', newport, pri_header, ext_header, comment=' Which ISS instrument port?', /silent
		sxdelpar, pri_header, 'ISS_PORT'
	endif 


    ;;check for previous and invalid multi-occurences DATAFILE keyword
    filnm=fxpar(pri_header,'DATAFILE',count=cdf)
    if cdf gt 1 then  sxdelpar, pri_header, "DATAFILE"

	gpi_set_keyword_if_missing, pri_header, ext_header, "DATAFILE", file_basename(filename), " Original DRP input file name", before="END"
	gpi_set_keyword_if_missing, pri_header, ext_header, "DATAPATH", file_dirname(filename), " Original DRP input file path", before="END"
   

    ;---- is the frame from the entire detector or just a subarray?
	;if numext eq 0 then datasec=SXPAR( header, 'DATASEC',count=cds) else instrum=SXPAR( headPHU, 'DATASEC',count=cds)
	datasec=gpi_get_keyword(pri_header, ext_header, 'DATASEC',count=cds)
	if cds eq 1 then begin
	  ; DATASSEC format is "[DETSTRTX:DETENDX,DETSTRTY:DETENDY]"
		DETSTRTX=fix(strmid(datasec, 1, stregex(datasec,':')-1))
		DETENDX=fix(strmid(datasec, stregex(datasec,':')+1, stregex(datasec,',')-stregex(datasec,':')-1))
		datasecy=strmid(datasec,stregex(datasec,','),strlen(datasec)-stregex(datasec,','))
		DETSTRTY=fix(strmid(datasecy, 1, stregex(datasecy,':')-1))
		DETENDY=fix(strmid(datasecy, stregex(datasecy,':')+1, stregex(datasecy,']')-stregex(datasecy,':')-1))
		;;DRP will always consider [1:2048,1,2048] frames:
		if ((DETSTRTX ne 1) || (DETENDX ne 2048) || (DETSTRTY ne 1) || (DETENDY ne 2048)) and ~keyword_set(nodata) then begin
		  tmpframe=dblarr(2048,2048)
		  tmpframe[(DETSTRTX-1):(DETENDX-1),(DETSTRTY-1):(DETENDY-1)]=currframe
		  currframe=tmpframe
		endif
	endif else gpi_set_keyword_if_missing, pri_header, ext_header, 'DATASEC', '[1:2048,1:2048]'
	
	; If user just wants the headers, then we're done and can return that here:
	if keyword_set(nodata) then return, { pri_header: ptr_new(pri_header,/no_copy), ext_header: ptr_new(ext_header,/no_copy)} 
	
	; Save headers and image as a structure:
    mydata = {image: ptr_new(currframe,/no_copy), pri_header: ptr_new(pri_header,/no_copy), ext_header: ptr_new(ext_header,/no_copy)}

	; Now, check for the presence of additional extensions
	for iext=2,numext do begin
		ext2data  = (mrdfits(filename , iext, ext2_Header, /SILENT))
		extname = strc(sxpar(ext2_Header, 'EXTNAME'))
	if extname eq '0' then extname='unnamed_extension'
		mydata = create_struct(mydata, extname, ptr_new(ext2data,/no_copy))
		mydata = create_struct(mydata, extname+"_HEADER", ptr_new(ext2_header,/no_copy))
	endfor
	


	return, mydata

	;if keyword_set(nodata) then return, { pri_header: ptr_new(pri_header), ext_header: ptr_new(ext_header)} else $
    ;return, {image: ptr_new(currframe), pri_header: ptr_new(pri_header), ext_header: ptr_new(ext_header)}
end


