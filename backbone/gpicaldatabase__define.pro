;+
; NAME: gpicaldatabase__define
;
; 	A database to track calibration code for GPI, and automatically find
; 	the best calibrations for a given file if requested.
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; 	Creates and updates calibration files in the directory of choice. 
; 	By default it keeps duplicates in both TXT and FITS formats.
; 	The FITS file is what is really used; the TXT is just for ease of 
; 	reading by humans. 
;
; HISTORY:
; 	Began 2010-01-26 17:11:04 by Marshall Perrin 
; 	... many updated not recorded here ...
; 	2012-10-10 MP: Added restriction based on IFS cooldown start/stop dates
;-

;+
; gpicaldatabase::new_calfile_struct
;    Create blank structure variable for storing calibration file info
;-
function gpicaldatabase::new_calfile_struct
; what info about a given calibration file do we want?
calfile = { $
			path: "", $
			filename: "", $
			type: "", $
			prism: "", $
			filter: "", $
			lyot: "", $
			apodizer: "", $
			itime: 0.0, $
			JD: 0.0d, $
			inport: "", $
			readoutmode: "", $
			other: "", $
			drpversion: "", $
			nfiles: 0, $
			valid: 1b}

	return, calfile
end

;+
; gpicaldatabase::log
;   Send log message to backbone
;-
pro gpicaldatabase::log, messagestr, _extra=_Extra
     if obj_valid(self.backbone) then self.backbone->Log, "GPICALDB: "+messagestr, _extra=_extra else message,/info, messagestr
end

FUNCTIOn gpicaldatabase::get_calibdir
	return, self.caldir
end

function gpicaldatabase::get_data
     return, self.data
end

;+----------
; gpicaldatabase::init
;    Initialization
;
;-
FUNCTION gpicaldatabase::init, directory=directory, dbfilename=dbfilename, backbone=backbone
	; Open and scan the directory of calibration data
	
	if ~(keyword_set(dbfilename)) then dbfilename="GPI_Calibs_DB.fits"

	; Determine where calibration files live
	if ~(keyword_set(directory)) then begin
		directory = gpi_get_directory('calibrations_DIR') 
	endif
	print, ""
	print, "  Calibration Files Directory is "+directory
	print, ""

	self.caldir = directory
	self.dbfilename = dbfilename
	if arg_present(backbone) then self.backbone=backbone ; Main GPI pipeline code?


	;--- Read in calibrations database
	caldbfile = self.caldir+path_sep()+self.dbfilename
	if ~file_test(caldbfile) then begin
		self->Log,"Nonexistent calibrations DB filename requested! "
		self->Log,"no such file: "+self.caldir+path_sep()+self.dbfilename
		self->Log,"Creating blank calibrations DB"
		self.data = ptr_new() ;self->new_calfile_struct)
		self.nfiles=0
	endif else begin

		; TODO add file locking to prevent multiple copies from fighting over the
		; DB?
		
		data = mrdfits(caldbfile,1,/silent)
		; TODO error checking that this is in fact a calib DB struct?
		;
		; FIXME MRDFITS does not remove trailing whitespace added to every field
		; by how MWRFITS writes out the table. So we have to trim every field
		; here?
		for i=0,n_tags(data)-1 do if size(data.(i),/TNAME) eq "STRING" then data.(i) = strtrim(data.(i),2)
		self.data = ptr_new(data,/no_copy)
		self.nfiles = n_elements(*self.data)
		self->Log, "Loaded Calibrations DB from "+caldbfile,depth=1
		self->Log, "Found "+strc(self.nfiles)+ " entries", depth=1
	


		self->verify


	endelse 

	;--- read in list of cooldown dates for the IFS
	;    This is used to restrict which sets of calibration files are
	;    worth looking at when matching. 
	readcol, gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'ifs_cooldown_history.txt', year, month, date, count=count,/silent
	if count gt 0 then begin
		jds = dblarr(n_elements(year))
		for i=0,n_elements(year)-1 do jds[i] = julday(month[i], date[i], year[i]) 
		self.ifs_cooldown_jds = ptr_new(jds)
	endif else begin
		self.ifs_cooldown_jds = ptr_new([1])
	endelse





	return, 1

end

;+----------
; gpicaldatabase::verify
;    Scan through each file in the DB and make sure it
;    exists (checks against user deleting a cal file after it was created)
;
;-
pro gpicaldatabase::verify
	; Right now this just verifies the file still exists, without doing any
	; actual checking against its contents. TBD?

	if self.nfiles eq 0 then return
	
	n = n_elements(*self.data)
	any_invalid = 0
	for i=0L,n-1 do begin

		;calfile = strtrim((*self.data)[i].path +path_sep()+ (*self.data)[i].filename,2)
		calfile = (*self.data)[i].path +path_sep()+ (*self.data)[i].filename
		if ~file_test( calfile) then begin
			message,/info,"Missing Cal File: "+calfile
			(*self.data)[i].valid=0b
			any_invalid=1
		endif

	endfor 

	if any_invalid then begin
		self->Log, "There were one or more calibration files in the DB which could not be found",depth=0
		self->Log, "Those files have been marked as invalid for now. But you should probably ",depth=1
		self->Log, "re-scan the database to re-create the index file!",depth=1
	endif else begin
		self->Log, "  All "+strc(n)+" files in Cal DB verified OK.",depth=1
	endelse


end

;+----------
; gpicaldatabase::write
;    write out updated calibration DB index to disk
;-
PRO gpicaldatabase::write

	if self.nfiles eq 0 then return

	; write a version in FITS for computers to read
	calfile = self.caldir+path_sep()+self.dbfilename
	mwrfits, *self.data, calfile, /create ; overwrite!
	message,/info, " Writing to "+calfile

	; write a version in TXT for humans to read
	calfile_txt = strepex(calfile, ".fits", ".txt")
	d = (*self.data)
	; TODO sort??
	mlen_p = max(strlen(d.path))+3
	mlen_f = max(strlen(d.filename))+3

	firstline = string("#PATH", "FILENAME", "TYPE", "DISPERSR", "IFSFILT", "APODIZER", "LYOTMASK", "INPORT", "ITIME", "READMODE", "JD", "NFILES",  "DRPVERSION", "OTHER", $
			format="(A-"+strc(mlen_p)+", A-"+strc(mlen_f)+", A-30,  A-10,     A-5     , A-8,         A-8,       A-6,     A-15,    A-15,   A-15, A-7, A-10,  A-10)")
	forprint2, textout=calfile_txt, d.path, d.filename,  d.type, d.prism, d.filter, d.apodizer, d.lyot, d.inport, d.itime, d.readoutmode, d.jd, d.nfiles, d.drpversion, d.other, $
			format="(A-"+strc(mlen_p)+", A-"+strc(mlen_f)+", A-30,  A-10,     A-5     , A-8,         A-8,       A-6,     D-15.5,  D-15.5, A-15, A-7, A-10,  A-10 )", /silent, $
			comment=firstline
	message,/info, " Writing to "+calfile_txt

	self.modified=0 ; Calibration database on disk now matches the one in memory

end

;----------
PRO gpicaldatabase::rescan ; an alias
	self->rescan_directory 
end

;+
; gpicaldatabase::rescan_directory
;    Create a new calibrations DB by reading all files in a given directory
;    This lets you pick up any new files that were added e.g. manually by users
;    copying in files outside of the pipeline.
;-
PRO gpicaldatabase::rescan_directory

	files = file_search(self.caldir,"*.fits")

	; annoyingly, IDL's file_search always ignores symlinks and there is not even an
	; option to tell it to follow them. So let's manually do so here.
	; the following code will follow through one layer of symlinks, for any symlinks 
	; found in the caldir. It won't recursively follow any additional symlinks.
	; That's probably good enough for >99% of use cases.
	symlinks = file_search(self.caldir, '*', /test_symlink, count=count_symlinks)
	if count_symlinks gt 0 then begin
		for j=0L,count_symlinks-1 do begin
			files = [files,file_search(symlinks[j],"*.fits")]
		endfor
	endif

	; simple version - just look in the main calibrations directory
	;files = file_search(self.caldir+path_sep()+"*.fits")
	nf = n_elements(files)
	self->Log, "Rescanning all FITS files in directory "+self.caldir
	ptr_free,self.data
	self.nfiles=0
	if obj_valid(self.backbone) then statusconsole = self.backbone->getstatusconsole()
	for i=0L,nf-1 do begin
		;self->Log, "Attempting to add file "+files[i]

		; purely cosmetic: make the status console recipe completion bar animate
		if obj_valid(statusconsole) then statusconsole->update, [{name:'Rescanning Calibration DB'}], 0, nf, i, "Rescanning"

		catch, error_Status
		if error_Status eq 0 then begin
			status = self->add_new_cal( strtrim(files[i],2), /delaywrite)
		endif else  begin
			self->Log, "An error occurred while trying to add to the calibration DB this file: "+strtrim(files[i],2)
		endelse
		catch,/cancel
	endfor 
	if self.modified then self->write ; save updated cal DB to disk.
  self->Log, "Database rescanning completed! "
  print, "Database rescanning completed! "
  if obj_valid(statusconsole) then statusconsole->update, [{name:'Calibration DB rescan completed. '+strc(self.nfiles)+" cal files present."}], 0, nf, 0, ""

end



;+----------
; gpicaldatabase::add_new_cal
;     add a new calibration file to the database. 
;
;-
Function gpicaldatabase::add_new_cal, filename, delaywrite=delaywrite ;, header=header
	; HISTORY:
	; 2012-01-27: Updated for MEF files -MP
	; 2012-06-12: Added /delaywrite for improved performance in rescan. -MP
	;
		
	OK = 0
	NOT_OK = -1

	; Check the file exists
	if ~file_test(filename) then begin
		message,/info, "Supplied file name does not exist: "+filename
		return, Not_OK
	endif

	Catch, Error_status
	IF Error_status NE 0 THEN BEGIN
		self->Log,"File "+filename+" cannot be read from disk."
		self->Log, "   Ignoring that file!"
		return, 0
	endif
	fits_data = gpi_load_fits(filename,/nodata) ; only read in headers, not data.
	CATCH, /CANCEL

	; 	if not a valid cal then return...
	if strupcase(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header,"ISCALIB")) ne "YES" then begin
		self->Log, "File "+filename+" does not appear to be a valid GPI calibration file."
		self->Log, "   Ignoring that file!"
		return, 0
	endif

	filename = strtrim(filename,2)

	; Read in the relevant information from the header
	;
	
	newcal = self->cal_info_from_header(fits_data)
	newcal.path= file_dirname(filename)
    newcal.filename = file_basename(filename)
	; add info to archive
	; 	overwrite if already present, otherwise add new
	if self.nfiles eq 0 then begin
		self.data = ptr_new(newcal)
		self->Log, "New entry added to cal DB for "+newcal.filename
	endif else begin
		; test if this file already exists in the cal DB?	
		wmatch = where( ((*self.data).path eq newcal.path ) and ((*self.data).filename eq newcal.filename), matchct)
		if matchct gt 0 then begin ; Update existing entry
			(*self.data)[wmatch] = newcal
			self->Log, "Updated entry in cal DB for "+newcal.filename
		endif else begin			; add new entry
			*self.data = [*self.data, newcal]
			self->Log, "New entry added to cal DB for "+newcal.filename
		endelse
	endelse
	self.nfiles += 1

	self.modified=1

	; force write right away
	if keyword_set(self.modified) and not keyword_set(delaywrite) then begin
		self->write
		self.modified=0
	endif

	Return, OK

end

;+--------
; gpicaldatabase::cal_info_from_header
;    Parse out the relevant header information that is useful for matching a given
;    file to its calibration data. This gets a large set of keywords, since it has
;    to be the union of values that are relevant for all files. 
;-
function gpicaldatabase::cal_info_from_header, fits_data
	; 	Note that the fits_data argument should be a structure as returned by
	; 	gpi_load_fits.
	;
	;
	; Read in the relevant information from the header
	thisfile = self->new_calfile_struct()

	; check what kind of file it is
	thisfile.type = gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "FILETYPE", count=count,/silent)
	; Don't print any alert for missing FILETYPE - this is not present in raw
	; data
	;if count ne 1 then message,/info, "Missing keyword: FILETYPE"

	filtkeys =['IFSFILT','FILTER1','FILTER']
	for i=0,n_elements(filtkeys)-1 do begin
		thisfile.filter = gpi_simplify_keyword_value(strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, filtkeys[i], count=count)))
		if count eq 1 then break
	endfor
	if count ne 1 then begin 
	    message,/info, "Missing keyword: IFSFILT"
        endif

	thisfile.prism= gpi_simplify_keyword_value(strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "DISPERSR", count=count3)))
        if count3 ne 1 then message,/info, "Missing keyword: DISPERSR"

	thisfile.apodizer= strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "APODIZER", count=count))
	if count ne 1 then message,/info, "Missing keyword: APODIZER"

	thisfile.itime = (gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "ITIME", count=count3))
        if count3 ne 1 then message,/info, "Missing keyword: ITIME"

	thisfile.lyot= strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "LYOTMASK", count=count))
	if count ne 1 then message,/info, "Missing keyword: LYOTMASK"  ; Missing in all DST files pre 2010-01-28!
	
	thisfile.inport = strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "INPORT", count=count))
	; no INPORT in I&T data yet. 
	;if count ne 1 then message,/info, "Missing keyword: INPORT"

	; this one's complicated enough to be a function. 
	thisfile.readoutmode = self->get_readoutmode_as_string(fits_data)

	; possibly modify this to use the MJD keywords? (once present from
	; Gemini GDS)
	; No - DATE-OBS and UTSTART are written by the IFS, thus are the original &
	; most accurate time stamp
	dateobs =  strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "DATE-OBS"))+$
		   "T"+strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header,"UTSTART"))
	thisfile.jd = date_conv(dateobs, "J")

	thisfile.drpversion = strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "DRPVER", /silent))
	thisfile.nfiles = strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "DRPNFILE", /silent))

	return, thisfile
end




;+----------
; gpicaldatabase::get_best_cal
;    Find which calibration file in the DB best matches
;    the need for a given routine.
;
;    This routine is where all the intelligence in the Cal DB resides.
;
;    The rules are a bit complicated and the logic tries to catch several
;    special cases. 
;    See http://docs.planetimager.org/pipeline/developers/caldb.html#caldb-devel
;-
function gpicaldatabase::get_best_cal, type, fits_data, date, filter, prism, itime=itime, $
	verbose=verbose, ignore_cooldown_cycles=ignore_cooldown_cycles
	; 
	; Keywords
	; verbose : print more display
	; ignore_cooldown_cycles : by default, will restrict based on IFS thermal
	; 							history. This lets you optionally disable that
	; 							check from the calling primitive.



	OK = 0
	NOT_OK=-1

	if self.nfiles eq 0 then message, "ERROR: --NO CAL FILES IN DB--"

	;---- Organize a catalog of different types of calibration files ----	
	; Build a structure defining all the potential calibrator types, specifying
	;  a) a name (short and used in code)
	;  b) a long description for human consumption (and which is used in the Cals DB
	;  c) how do we identify the best match?
	
	; 2010-01-10 MDP: why does the code try to match dark files using itimeFilt?
	; For dark images, the filter does not matter. I'm going to change this to
	; just 'itime' unless someone has another opinion?

                                ; FIXME perhaps this should be a configuration file instead?
        types_str =[['dark', 'Dark', 'ApproxItimeReadmode'], $  ;  dark with scaling of inttime allows 
					['dark_exact', 'Dark', 'itimeReadmode'],  $ ;  dark with exact match required
                    ['wavecal', 'Wavelength Solution Cal File', 'FiltPrism'], $
                    ['flat', 'Flat Field', 'FiltPrism'], $
                                ;['flat', 'Flat field', 'FiltPrism'], $
                    ['badpix', 'Bad Pixel Map', 'typeonly'], $
                    ['hotbadpix', 'Hot Pixel Map', 'typeonly'], $
                    ['coldbadpix', 'Cold Bad Pixel Map', 'typeonly'], $
                    ['nonlinearbadpix', 'Nonlinear Bad Pixel Map', 'typeonly'], $
                    ['plate', 'Plate scale & orientation', 'typeonly'], $
                    ['spotloc', 'Spot Location Measurement', 'FiltOnly'], $
                    ['Gridratio', 'Grid Ratio', 'FiltOnly'], $
                    ['mlenspsf', 'mlens psf', 'FiltPrism'], $
                    ['Fluxconv', 'Fluxconv', 'FiltPrism'], $
                    ['telluric', 'Telluric Transmission', 'FiltPrism'], $
                    ['polcal', 'Polarimetry Spots Cal File', 'FiltPrism'], $
                    ['instpol', 'Instrumental Polarization', 'FiltPrism'], $
                    ['distor', 'Distortion Measurement', 'typeonly'], $
                    ['background', 'Thermal/Sky Background', 'FiltPrism'], $
                    ['shifts', 'Flexure shift Cal File', 'typeonly'], $
                    ['micro', 'Micro Model', 'typeonly'], $
                    ['persis', 'Persistence Parameters', 'typeonly'], $
                   ['', '', '']]
	; reformat the above into a struct array.
	aa = {type_struct, name: 'dark', description:'Dark', match_on:"itimeReadmode"}
	types = replicate(aa, (size(types_str))[2])
	types.name=reform(types_str[0,*])
	types.description=reform(types_str[1,*])
	types.match_on=reform(types_str[2,*])



	itype = where(strmatch(types.name, type,/fold_case), matchct)
	if matchct ne 1 then begin
		message, "Unknown or invalid type of calibration file requested: '"+type+"'.",/info
		return, NOT_OK
	end

	if keyword_set(verbose) then self->Log, "Finding Calibration File for "+ types[itype].description +" using selection on "+types[itype].match_on

	wm= where(strmatch((*self.data).type, types[itype].description+"*",/fold),cc)
	if cc eq 0 then begin
		self->Log, "CALIBS DB ERROR: --NO FILES FOR "+types[itype].description+" IN DB--",depth=1
		return, NOT_OK
	endif 


	;---- Get the info from the current file we're going to be matching on
	newfile = self->cal_info_from_header(fits_data)
	date=newfile.jd
	filter=newfile.filter
	prism=newfile.prism
	itime=newfile.itime
	readoutmode=newfile.readoutmode ;self->get_readoutmode_as_string(fits_data)

	;---- optional: restrict based on dates of IFS cooldown runs (so 
	if (gpi_get_setting('caldb_restricts_by_cooldown', /bool, default=0,/silent) $
	    and not keyword_set(ignore_cooldown_cycles)) then begin
		calfiles_table = (*self.data)
		
		; find the JD range corresponding to the IFS cooldown run for that data
		wstart = where(*self.ifs_cooldown_jds lt newfile.jd, countstart)
		wstop  = where(*self.ifs_cooldown_jds gt newfile.jd, countstop)

		if countstart gt 0 then cooldown_start = max( (*self.ifs_cooldown_jds)[wstart]) else cooldown_start=1
		if countstop gt 0  then cooldown_stop  = min( (*self.ifs_cooldown_jds)[wstop]) else cooldown_stop=1e7

		if keyword_set(verbose) then self->Log, "Restricting to files between JD="+strc(cooldown_start)+" to "+strc(cooldown_stop)

		startday_str = strmid(date_conv(cooldown_start,'FITS'), 0, 10)
		stopday_str = strmid(date_conv(cooldown_stop,'FITS'), 0, 10)
		if cooldown_stop eq 1e7 then stopday_str = "present"

		wCorrectCooldown = where((calfiles_table.JD ge cooldown_start) and (calfiles_table.JD le cooldown_stop), correctcount)
		if keyword_set(verbose) then self->Log, "  Found "+strc(correctcount)+" files total in that date range."
		if correctcount eq 0 then begin
			self->Log, "CALIBS DB ERROR: --NO FILES AVAILABLE IN DB for IFS cooldown between "+startday_str+" to "+stopday_str+" --",depth=1
			return, NOT_OK
		endif 

		; restrict based on that range
		calfiles_table = (*self.data)[wCorrectCooldown]

		wm= where(strmatch(calfiles_table.type, types[itype].description+"*",/fold),cc)
		if cc eq 0 then begin
			self->Log, "CALIBS DB ERROR: --NO FILES FOR "+types[itype].description+" IN DB for the IFS cooldown between "+startday_str+" to "+stopday_str+"--",depth=1
			return, NOT_OK
		endif 


	endif else begin
		; Use all calibration files, no restriction by IFS cooldown.
		calfiles_table = (*self.data)
	endelse



	case types[itype].match_on of 
	'typeonly': begin
		 imatches= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold), cc)
		 errdesc = 'of the correct type'
	end

	'itime': begin
	    imatches= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold) and $
	   		(calfiles_table.itime) eq itime,cc)
		errdesc = 'with same ITIME'

		; NOTE: we are no longer going to hand back approximate matches, since
		; that would involve rescaling in darks that we do not do. Instead, you
		; must always have the appropriate ITIME darks. 
		;		; FIXME if no exact match found for itime, fall back to closest match
		;		if cc eq 0 then begin
		;			self->Log, "No exact match found for ITIME, thus looking for closesd approximate mathc instead",depth=3
		;	    	imatches_typeonly= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold))
		;			deltatimes = calfiles_table[imatches_typeonly].itime - itime
		;
		;			mindelta = min( abs(deltatimes), wmin)
		;			imatches= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold) and $
		;				            (calfiles_table.itime) eq calfiles_table[wmin[0]].itime,cc)
		;			self->Log, "Found "+strc(cc)+" approx matches with ITIME="+strc(calfiles_table[wmin[0]].itime)
		;
		;
		;		endif

	end
	'itimeReadmode': begin
	    imatches= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold) and $
	   		((calfiles_table.readoutmode) eq readoutmode ) and $
	   		(calfiles_table.itime) eq itime,cc)
		errdesc = 'with same ITIME and Detector Readout Mode'
		; NOTE: we are no longer going to hand back approximate matches, since
		; that would involve rescaling in darks that we do not do. Instead, you
		; must always have the appropriate ITIME darks. 
		;
	
		; FIXME if no exact match found for itime, fall back to closest match
		;		if cc eq 0 then begin
		;			self->Log, "No exact match found for ITIME, thus looking for closesd approximate match instead",depth=3
		;	    	imatches_typeonly= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold))
		;			deltatimes = calfiles_table[imatches_typeonly].itime - itime
		;
		;			mindelta = min( abs(deltatimes), wmin)
		;			imatches= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold) and $
		;				            (calfiles_table.itime) eq calfiles_table[wmin[0]].itime,cc)
		;            self->Log, " Found "+strc(cc)+" approx matches with ITIME="+strc(calfiles_table[wmin[0]].itime)
		;
		;
		;		endif
		;
	end
	'ApproxItimeReadmode': begin
	    imatches= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold) and $
	   		((calfiles_table.readoutmode) eq readoutmode ) and $
	   		(calfiles_table.itime) eq itime,cc)
		errdesc = 'with same ITIME and Detector Readout Mode'
		; NOTE: we are no longer going to hand back approximate matches, since
		; that would involve rescaling in darks that we do not do. Instead, you
		; must always have the appropriate ITIME darks. 

		max_allowed_rescale = 3.0	
	
		; FIXME if no exact match found for itime, fall back to closest in time match
		; which has approximately the right time within the allowed rescaling
		; factor
		if cc eq 0 then begin
			self->Log, "No exact match found for ITIME, thus looking for closest approximate match instead",depth=3
		   	imatches= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold) and $
				( (calfiles_table.itime gt itime/max_allowed_rescale) or (calfiles_table.itime lt itime*max_allowed_rescale)) , cc)
			errdesc = 'with approximatedly same ITIME and Detector Readout Mode'
			;deltatimes = calfiles_table[imatches_typeonly].itime - itime

			;mindelta = min( abs(deltatimes), wmin)
			;imatches= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold) and $
				            ;(calfiles_table.itime) eq calfiles_table[wmin[0]].itime,cc)

	        self->Log, " Found "+strc(cc)+" approx matches with ITIME within a factor of "+sigfig(max_allowed_rescale,3)+" of ITIME="+strc(itime)


		endif
	end
	'FiltPrism': begin
		 imatches= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold) and $
	   		((calfiles_table.filter) eq filter ) and $
	   		((calfiles_table.prism) eq prism) ,cc)
		 errdesc = 'with same DISPERSR and FILTER'
	end
	'FiltOnly': begin
     	imatches= where( strmatch(calfiles_table.type, types[itype].description+"*",/fold) and $
        ((calfiles_table.filter) eq filter )  ,cc)
     	errdesc = 'with same FILTER'
  	end
	endcase

    
	if cc eq 0 then begin
		message, "ERROR: --No matching cal files "+errdesc+" as requested in DB--",/info
		void=error('ERROR: --No matching cal files '+errdesc+' as requested in DB--')
		return, NOT_OK
	endif
	if keyword_set(verbose) then self->Log, "Found "+strc(cc)+" possible cal files for "+type+"; selecting best based on closest date."

	; Find the single closest in time calibration file.
	timediff=min(abs( (calfiles_table.JD)[imatches] - date ),minind)
	if keyword_set(verbose) then self->Log, "Closest date offset is "+strc(timediff)


	; If we are matching a wavecal, always return the closest in time without
	; any other considerations. This is because we may be trying to match
	; multiple wavecals taken during the night to measure the IFS internal flexure.
	if strlowcase(type) eq 'wavecal' then begin
  		ibest = imatches[minind]
		bestcalib=(calfiles_table.PATH)[ibest]+path_sep()+(calfiles_table.FILENAME)[ibest]
		;print, bestcalib
		self->Log, "Returning best cal file= "+bestcalib,depth=3
		
		return, bestcalib
	endif

	; The logic is more complicated for other types of calibration files.

	; If you have multiple calibration files of the same
	; type within +-12 hrs of one another, use the one with the maximum
	; integration time. The logic here is that combined data products used as calibration
	; files will have higher exp time than their individual components. 
	within1day = where(abs( (calfiles_table.JD)[imatches] - ((calfiles_table.JD)[imatches])[minind] ) le 0.5, datecount)
	

	if datecount eq 1 then begin
		; only one plausible calibration file within 1 day. Just use that file.
  		ibest = imatches[minind]
		if keyword_set(verbose) then self->Log, ' There is only 1 possible cal file on that date. Selecting it.'
  	endif else begin
		; multiple plausible files found within 1 day. Use the highest exposure
		; time. If there are several with identical exposure time, use the 
		; closest in time.
		
		if keyword_set(verbose) then self->Log, ' There are '+strc(datecount)+' possible cal files at that date +- 12 hrs.'
		itimes =  ((calfiles_table[imatches])[within1day]).itime
		maxitime = max(itimes, maxitimeind)
		wmaxitime = where(itimes eq maxitime, maxct)
		if maxct eq 1 then begin ; use the highest exposure time
			ibest = (imatches[within1day])[maxitimeind]
			if keyword_set(verbose) then self->Log, ' Selected the file with the greatest total integration time. '
		endif else begin
			; If there are several with identical exposure time, use the
			; very closest in time.

			imaxitime = (imatches[within1day])[wmaxitime]
			maxitime_jds = (calfiles_table.JD)[imaxitime]
			closest_at_maxitime = min( maxitime_jds - date, iclosest)
			ibest = imaxitime[iclosest]
			if keyword_set(verbose) then self->Log, ' Found '+strc(maxct)+' files with same max itime. Chose closest in time. '
			
		endelse

	endelse

	
    bestcalib=(calfiles_table.PATH)[ibest]+path_sep()+(calfiles_table.FILENAME)[ibest]
	print, bestcalib
    self->Log, "Returning best cal file= "+bestcalib,depth=3
	
	return, bestcalib


end

;+----------
; gpicaldatabase::get_best_cal_from_header
;    This routine is just a wrapper providing API back compatibility
;    It calls get_best_cal to do the actual matching.
;-
function gpicaldatabase::get_best_cal_from_header, type, priheader, extheader, _extra=_extra
	; Parameters:
	; 	type		what kind of a dark is requested? String name. 
	; 	priheader, extheader	like the names imply


	fits_data = {pri_header: ptr_new(priheader), ext_header: ptr_new(extheader)}
	return, self->get_best_cal( type, fits_data, _extra=_extra)


end

;+----------
; gpicaldatabase::get_readoutmode_as_string
;     Return a string uniquely identifying the readout mode:
;       SAMPMODE, READS< NGROUP, DATASEC
;-

function gpicaldatabase::get_readoutmode_as_string, fits_data
     if gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, 'INSTRSUB') eq 'GPI IFS Pupil' then begin
         readoutmode = "Pupil_Viewer:"
     endif else begin
         samplingMode = strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, 'SAMPMODE', count=count))
         if count ne 1 then begin message,/info, "Missing keyword: SAMPMODE" & samplingMode = '0' & endif
         totReads = strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, 'READS', count=count))
         if count ne 1 then begin message,/info, "Missing keyword: READS" & totreads = '0' & endif
         numGroups = strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, 'NGROUP', count=count))
         if count ne 1 then begin message,/info, "Missing keyword: NGROUP" & numGroups = '0' & endif
         datasec = strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, 'DATASEC', count=count))
         if count ne 1 then begin message,/info, "Missing keyword: DATASEC" & datasec = '[0:0,0:0]' & endif

         readoutmode = samplingMode+"_"+totReads+"_"+numGroups+"_"+datasec
     endelse
     
     return, readoutmode
end

;+----------
; gpicaldatabase::get_readoutmode_from_string
;    Inverse of get_readoutmode_as_string
;    This parses out the different mode settings from a supplied string
;- 

pro gpicaldatabase::get_readoutmode_from_string, readoutmode, samplingMode=samplingMode,$
                  numReads=numReads,numGroups=numGroups,startX=startX, startY=startY, endX=endX, endY=endY

	regex = '([[:digit:]])_([[:digit:]]+)_([[:digit:]])_\[([[:digit:]]+):([[:digit:]]+),([[:digit:]]+):([[:digit:]]+)\]'
	res = stregex(readoutmode,regex,/subexpr,/extract)

	samplingMode = long(res[1,*])
	totReads = float(res[2,*])
	numGroups = float(res[3,*])
	startX = float(res[4,*]) - 1.
	endX = float(res[5,*]) - 1.
	startY = float(res[6,*]) - 1.
	endY = float(res[7,*]) - 1.

	nchan = fltarr(n_elements(readoutmode)) + 32.
	inds = where((startX ne 0) or (endX ne 2047) or (startY ne 0) or (endY ne 2047),cc)
	if cc gt 0 then nchan[inds] = 1.

	tframe = ((endX-startX+1)/nchan+7)*(endY-startY+2)*10e-6

	;;determine different modes (assume single unless proven otherwise)
	cdss = where((samplingMode eq 2) or (samplingMode eq 3),ccds)
	utrs = where(samplingMode eq 4,cutr)

	;;numReads - for single, this is 1, for CDS & MCDS it's half the total
	;;           number of reads, for UTR its the total number of reads/numGroups
	numReads = totReads
	if ccds gt 0 then numReads[cdss] /= 2.
	if cutr gt 0 then numReads[utrs] = numReads[utrs]/numGroups[utrs]

end

;+----------
; gpicaldatabase__define
;    Defines the cal database object itself.
;    Must go last in the source file.
;
;-
PRO gpicaldatabase__define

void = {gpicaldatabase, $
		backbone: obj_new(), $
		caldir: "", $
		dbfilename: "",$
		data: ptr_new(), $
		ifs_cooldown_jds: ptr_new(), $
		nfiles: 0, $
		modified: 0 $
	}


end
