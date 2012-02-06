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
			issport: "", $
			other: "", $
			valid: 1b}

	return, calfile
end

pro gpicaldatabase::log, messagestr
	if obj_valid(self.backbone) then self.backbone->Log, messagestr else message,/info, messagestr
end

FUNCTIOn gpicaldatabase::get_calibdir
	return, self.caldir
end

;----------
; Initialization
FUNCTION gpicaldatabase::init, directory=directory, dbfilename=dbfilename, backbone=backbone
	if ~(keyword_set(dbfilename)) then dbfilename="GPI_Calibs_DB.fits"
	if ~(keyword_set(directory)) then directory=getenv("GPI_DRP_OUTPUT_DIR")

	self.caldir = directory
	self.dbfilename = dbfilename
	if arg_present(backbone) then self.backbone=backbone ; Main GPI pipeline code?

	calfile = self.caldir+path_sep()+self.dbfilename
	if ~file_test(calfile) then begin
		self->Log,"Nonexistent calibrations DB filename requested! "
		self->Log,"no such file: "+self.caldir+path_sep()+self.dbfilename
		self->Log,"Creating blank calibrations DB"
		self.data = ptr_new() ;self->new_calfile_struct)
		self.nfiles=0
	endif else begin

		; TODO add file locking to prevent multiple copies from fighting over the
		; DB?
		
		data = mrdfits(calfile,1)
		; TODO error checking that this is in fact a calib DB struct?
		;
		; FIXME MRDFITS does not remove trailing whitespace added to every field
		; by how MWRFITS writes out the table. So we have to trim every field
		; here?
		for i=0,n_tags(data)-1 do if size(data.(i),/TNAME) eq "STRING" then data.(i) = strtrim(data.(i),2)
		self.data = ptr_new(data,/no_copy)
		self.nfiles = n_elements(*self.data)
		self->Log, "Loaded Calibrations DB from "+calfile
		self->Log, "  Found "+strc(self.nfiles)+ " entries"
	


		self->verify


	endelse 

	return, 1

end

;----------
; Scan through each file in the DB and make sure it
; exists (checks against user deleting a cal file after it was created)
pro gpicaldatabase::verify

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
		self->Log, "There were one or more calibration files in the DB which could not be found"
		self->Log, "Those files have been marked as invalid for now. But you should probably "
		self->Log, "re-scan the database to re-create the index file!"
	endif else begin
		self->Log, "  All "+strc(n)+" files in Cal DB verified OK."
	endelse


end





;----------
; write out update calibration DB
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

	firstline = string("#PATH", "FILENAME", "TYPE", "DISPERSR", "FILT", "APODIZE", "LYOT", "PORT", "ITIME", "JD", "OTHER", $
			format="(A-"+strc(mlen_p)+", A-"+strc(mlen_f)+", A-30,  A-10,     A-5     , A-8,         A-8,       A-6,     A-15,    A-15,   A-10)")
	forprint2, textout=calfile_txt, d.path, d.filename,  d.type, d.prism, d.filter, d.apodizer, d.lyot, d.issport, d.itime,  d.jd, d.other, $
			format="(A-"+strc(mlen_p)+", A-"+strc(mlen_f)+", A-30,  A-10,     A-5     , A-8,         A-8,       A-6,     D-15.5,  D-15.5, A-10)", /silent, $
			comment=firstline
	message,/info, " Writing to "+calfile_txt

end

;----------
PRO gpicaldatabase::rescan ; an alias
	self->rescan_directory 
end
; Create a new calibrations DB by reading all files in a given directory
PRO gpicaldatabase::rescan_directory
	files = file_search(self.caldir+path_sep()+"*.fits")
	nf = n_elements(files)
	self->Log, "Rescanning all FITS files in directory "+self.caldir
	ptr_free,self.data
	self.nfiles=0
	for i=0L,nf-1 do begin
		;self->Log, "Attempting to add file "+files[i]
		status = self->add_new_cal( strtrim(files[i],2) )
	endfor 
  self->Log, "Database rescanning completed! "
  print, "Database rescanning completed! "

end



;----------
; add a new calibration file
Function gpicaldatabase::add_new_cal, filename ;, header=header
	; HISTORY:
	; 2012-01-27: Updated for MEF files -MP
	;
	COMMON APP_CONSTANTS
		

	; Check the file exists
	if ~file_test(filename) then begin
		message,/info, "Supplied file name does not exist: "+filename
		return, Not_OK
	endif

	fits_data = gpi_load_and_preprocess_fits_file(filename)

;	; Read in the FITS header
;	fits_info,filename,N_ext=n_ext,/silent
;	if n_ext eq 0 then  begin
;		priheader = headfits(filename, /silent)
;		extheader = priheader
;	endif else begin
;		priheader = headfits(filename,exten=0, /silent)
;		extheader = headfits(filename,exten=1, /silent)
;	endelse
;
	; 	if not a valid cal then return...
	if strupcase(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header,"ISCALIB")) ne "YES" then begin
		self->Log, "File "+filename+" does not appear to be a valid GPI calibration file."
		self->Log, "   Ignoring that file!"
		return, 0
	endif

	filename = strtrim(filename,2)

	; Read in the relevant information from the header
	newcal = self->new_calfile_struct()
	newcal.path= file_dirname(filename)
	newcal.filename = file_basename(filename)
	; check what kind of cal it is
	newcal.type = gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "FILETYPE", count=count)
	if count ne 1 then message,/info, "Missing keyword: FILETYPE"
	newcal.filter = gpi_simplify_keyword_value(strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "FILTER1", count=count)))
	if count ne 1 then begin 
	    message,/info, "Missing keyword: FILTER1"
        newcal.filter = gpi_simplify_keyword_value(strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "FILTER", count=count)))
    endif

	newcal.prism= gpi_simplify_keyword_value(strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "DISPERSR", count=count3)))
	if count3 ne 1 then message,/info, "Missing keyword: DISPERSR"

	newcal.apodizer= strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "APODIZER", count=count))
	if count ne 1 then message,/info, "Missing keyword: APODIZER"

	newcal.itime = (gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "ITIME", count=count3))
    if count3 ne 1 then message,/info, "Missing keyword: ITIME"

	newcal.lyot= strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "LYOTMASK", count=count))
	if count ne 1 then message,/info, "Missing keyword: LYOT"  ; Missing in all DST files pre 2010-01-28!
	
	newcal.issport = strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "INPORT", count=count))
	if count ne 1 then message,/info, "Missing keyword: INPORT"

	; FIXME possibly modify this to use the MJD keywords? 
	dateobs =  strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header, "DATE-OBS"))+$
		   "T"+strc(gpi_get_keyword(*fits_data.pri_header, *fits_data.ext_header,"TIME-OBS"))
	newcal.jd = string(date_conv(dateobs, "J"),f='(f15.5)')

	
	; add info to archive
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
	; 	overwrite if already present, otherwise add new

	self.modified=1


	if keyword_set(self.modified) then begin
		self->write
		self.modified=0
	endif

	Return, OK

end

;----------
; Find which calibration file in the DB best matches
; the need for a given routine
; 
; This routine extracts the relevant parameters from a supplied FITS header and
; tehen calls get_best_cal to do the actual matching.
function gpicaldatabase::get_best_cal_from_header, type, header, _extra=_extra


   dateobs2 =  strc(sxpar(header, "DATE-OBS"))+" "+strc(sxpar(header,"TIME-OBS"))
   dateobs3 = date_conv(dateobs2, "J")

   filt=strcompress(gpi_simplify_keyword_value(sxpar( header, 'FILTER1',  COUNT=cc3)),/rem)
  ; if cc3 eq 0 then filt=strcompress(sxpar( header, 'FILTER1',  COUNT=cc3),/rem)

   prism=strcompress(gpi_simplify_keyword_value(sxpar( header, 'DISPERSR',  COUNT=cc4)),/rem)
   ;if cc4 eq 0 then prism=strcompress(sxpar( header, 'DISPERSR',  COUNT=cc4),/rem)

   itime=sxpar(header, "ITIME", count=ci)
   if ci eq 0 then itime=sxpar(header, "TRUITIME", count=ci)
   ;if ci eq 0 then itime=sxpar(header, "ITIME", count=ci)
   ;if ci eq 0 then itime=sxpar(header, "INTIME", count=ci)
	return, self->get_best_cal( type, dateobs3, filt, prism, itime=itime, _extra=_extra)


end

;----------
; Find which calibration file in the DB best matches
; the need for a given routine
function gpicaldatabase::get_best_cal, type, date, filter, prism, itime=itime, $
	verbose=verbose

	common APP_CONSTANTS
	; Do we describe the required needs by giving keywords explicitly
	; in the call, or just providing the FITS header and letting this
	; routine pull out what it needs? 

	if self.nfiles eq 0 then message, "ERROR: --NO CAL FILES IN DB--"

		
	; Build a structure defining all the potential calibrator types, specifying
	;  a) a name (short and used in code)
	;  b) a long description for human consumption (and which is used in the Cals DB
	;  c) how do we identify the best match?
	
	; 2010-01-10 MDP: why does the code try to match dark files using itimeFilt?
	; For dark images, the filter does not matter. I'm going to change this to
	; just 'itime' unless someone has another opinion?

	types_str =[['dark', 'Dark', 'itime'], $
			  	['wavecal', 'Wavelength Solution Cal File', 'FiltPrism'], $
				['flat', 'Flat field', 'FiltPrism'], $
				;['flat', 'Flat field', 'FiltPrism'], $
				['badpix', 'Bad Pixel Map', 'typeonly'], $
				['plate', 'Plate scale & orientation', 'typeonly'], $
				['spotloc', 'Spot Location Measurement', 'FiltOnly'], $
				['Gridratio', 'Grid Ratio', 'FiltOnly'], $
				['Fluxconv', 'Fluxconv', 'FiltPrism'], $
				['telluric', 'Telluric Transmission', 'FiltPrism'], $
				['polcal', 'Polarimetry Spots Cal File', 'FiltPrism'], $
				['instpol', 'Instrumental Polarization', 'FiltPrism'], $
				['distor', 'Distortion Measurement', 'typeonly'], $
				['', '', 'FiltPrism'], $
				['', '', ''], $
				['', '', '']]
	; reformat the above into a struct array.
	aa = {type_struct, name: 'dark', description:'Dark', match_on:"itimeFilt"}
	types = replicate(aa, (size(types_str))[2])
	types.name=reform(types_str[0,*])
	types.description=reform(types_str[1,*])
	types.match_on=reform(types_str[2,*])



	itype = where(types.name eq type, matchct)
	if matchct ne 1 then begin
		message, "Unknown or invalid type of calibration file requested: '"+type+"'.",/info
		return, NOT_OK
	end

	if keyword_set(verbose) then message,/info, "Finding Calibration File for "+ types[itype].description +" using selection on "+types[itype].match_on

	wm= where(strmatch((*self.data).type, types[itype].description+"*",/fold),cc)
	if cc eq 0 then begin
		message, "ERROR: --NO FILES FOR "+types[itype].description+" IN DB--",/info
		return, NOT_OK
	endif 


	case types[itype].match_on of 
	'typeonly': begin
		 imatches= where( strmatch((*self.data).type, types[itype].description+"*",/fold), cc)
		 errdesc = 'of the correct type'
	end

	'itime': begin
	    imatches= where( strmatch((*self.data).type, types[itype].description+"*",/fold) and $
	   		((*self.data).itime) eq itime,cc)
		errdesc = 'with same ITIME'
		; FIXME if no exact match found for itime, fall back to closest match
		if cc eq 0 then begin
			if obj_valid(self.backbone) then self.backbone->Log, "GPICALDB: No exact match found for ITIME, thus looking for closesd approximate mathc instead",/DRF,depth=2
	    	imatches_typeonly= where( strmatch((*self.data).type, types[itype].description+"*",/fold))
			deltatimes = (*self.data)[imatches_typeonly].itime - itime

			mindelta = min( abs(deltatimes), wmin)
			imatches= where( strmatch((*self.data).type, types[itype].description+"*",/fold) and $
				            ((*self.data).itime) eq (*self.data)[wmin[0]].itime,cc)
			if obj_valid(self.backbone) then self.backbone->Log, "GPICALDB: Found "+strc(cc)+" approx matches with ITIME="+strc((*self.data)[wmin[0]].itime)


		endif

	end
	 'itimeFilt': begin
      	imatches= where( strmatch((*self.data).type, types[itype].description+"*",/fold) and $
        (((*self.data).itime) eq itime) and $
        (((*self.data).filter) eq filter) ,cc) 
    	errdesc = 'with same ITIME and FILTER'
  	end
	'FiltPrism': begin
		 imatches= where( strmatch((*self.data).type, types[itype].description+"*",/fold) and $
	   		(((*self.data).filter) eq filter ) and $
	   		(((*self.data).prism) eq prism) ,cc)
		 errdesc = 'with same DISPERSR and FILTER'
	end
	'FiltOnly': begin
     	imatches= where( strmatch((*self.data).type, types[itype].description+"*",/fold) and $
        (((*self.data).filter) eq filter )  ,cc)
     	errdesc = 'with same FILTER'
  	end
	endcase
    
	if cc eq 0 then begin
		message, "ERROR: --No matching cal files "+errdesc+" as requested in DB--",/info
		void=error('ERROR: --No matching cal files '+errdesc+' as requested in DB--')
		return, NOT_OK
	endif
	if keyword_set(verbose) then message,/info, "Found "+strc(cc)+" possible cal files; selecting best based on closest date."


	timediff=min(abs( ((*self.data).JD)[imatches] - date ),minind)
	if keyword_set(verbose) then message,/info, "Closest date offset is "+strc(timediff)
	;combinaison of wav.cal. has same timediff than the most recent wav.cal of the combinaison
	;so, keep only the combinaison (TO DO: use keyword DATAFILE instead of suffix filename?)
	ibests=where(abs( ((*self.data).JD)[imatches] - date ) eq timediff,cc)

	if cc gt 1 then begin
  		ibest = imatches[minind]
  	endif else begin
	  	ibest = imatches[minind]
	endelse
	
    bestcalib=((*self.data).PATH)[ibest]+path_sep()+((*self.data).FILENAME)[ibest]
	if keyword_set(verbose) then message,/info, "Returning best calib= "+bestcalib

	if obj_valid(self.backbone) then self.backbone->Log, "GPICALDB: Returning best cal file= "+bestcalib,/DRF,depth=2
	
	return, bestcalib


end


;----------
PRO gpicaldatabase__define

;calfile = self->new_calfile_struct() ; define this too...

; overall structure
void = {gpicaldatabase, $
		backbone: obj_new(), $
		caldir: "", $
		dbfilename: "",$
		data: ptr_new(), $
		nfiles: 0, $
		modified: 0 $
	}


end
