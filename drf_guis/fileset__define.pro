;+
; NAME: fileset 
;
;	This is a container for one or more FITS files, meant as a wrapper for use
;	in the data parser infrastructure refactoring.
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;	Began 2014-10-30 by Marshall Perrin, based on parsergui code by Maire, Perrin, Wolff et al.
;-


;+ --------------------------------------------------------------------- 
; fileset::add_files
; Add one or more files to the fileset. 
;
;    Return parameters:
;		count_added : float, number of files actually added.
;-
pro fileset::add_files, filenames, count_added=count_added, silent=silent


	; Check for duplicate
	if ptr_valid(self.filenames) then $
    for i=0,n_elements(filenames)-1 do begin   
        if (total(*self.filenames eq filenames[i]) ne 0) then begin
			self->Log, "File is already present in the list: "+filenames[i]
			filenames[i] = ''
		endif
    endfor


	; check for nonexistent files
	for i=0,n_elements(filenames)-1 do begin   
		if filenames[i] eq '' then continue
		if ~file_test(filenames[i]) then begin
			self->Log, "File does not exist: "+filenames[i]
			filenames[i] = ''
		endif
    endfor



	; avoid blanks (including any duplicates or nonexistent files we just found)
    w = where(filenames ne '', wcount) 
    if wcount eq 0 then begin 
		if ~(keyword_set(silent)) then $
			void=dialog_message('No new files found. Please add new files that were not already in the list.' , $
				title='No new files found', dialog_parent=self.gui_parent_wid )
		count_added = 0
		return
	endif

    filenames = filenames[w]
	count_added = wcount

	if self.debug then for ff=0,wcount-1 do self->Log, 'Adding file: '+filenames[ff]

	if ~ptr_valid(self.filenames) then begin
		self.filenames = ptr_new(filenames)
		self.validated = ptr_new( bytarr(n_elements(filenames)) )
		self.finfo = ptr_new( replicate( {struct_obs_keywords}, n_elements(filenames) ) )
	endif else begin
		*self.filenames = [*self.filenames, filenames]
		*self.validated = [*self.validated, bytarr(n_elements(filenames))]
		*self.finfo =      [*self.finfo,     replicate( {struct_obs_keywords}, n_elements(filenames) ) ] 
	endelse

	;  THis would work on IDL 8 in place of all of the above, if we use ptr_new(/alloc),
	;  but alas we are still supporting 7...
    ;*self.filenames = [*self.filenames, filenames]
	;*self.validated = [*self.validated, bytarr(n_elements(filenames))]

end

;+ --------------------------------------------------------------------- 
; fileset::add_files_from_wildcard
; Add one or more files to the fileset, based on a wildcard spec (regular
; expression)
;-
pro fileset::add_files_from_wildcard, wildcard_spec, count_added=count_added, silent=silent

	
	if strc(wildcard_spec) eq '' then begin
		self->Log, "Error - invalid wildcard spec"
		return
	endif

	if self.debug then self->Log, "Searching based on wildcard "+wildcard_spec
	result=file_search(wildcard_spec)
	wcount= n_elements(result)
	result = strtrim(result,2) 

	if self.debug then for ff=0,wcount-1 do self->Log, 'Found file: '+result[ff]

	self->add_files, result, count_added=count_added, silent=silent

end





;+ --------------------------------------------------------------------- 
; fileset::remove_files
; Remove one or more files from the fileset
;-
pro fileset::remove_files, filenames_to_remove, all=all, count_removed=count_removed

	if ~ptr_valid(self.filenames) then return ; nothing to do.

	if keyword_set(all) then begin
		count_removed = n_elements( *self.filenames)
		ptr_free, self.filenames, self.validated,self.finfo
		self->Log,"Removed all: "+strc(count_removed)+" files"
		return
	endif
		

	n_to_remove =n_elements(filenames_to_remove)
	if n_to_remove eq 0 then return ; nothing to do
	if ~ptr_valid(self.filenames) then return ; nothing to do

	count_removed = 0	
	for i=0,n_to_remove-1 do begin
		if strc(filenames_to_remove[i]) eq '' then continue
		wm = where( *self.filenames ne filenames_to_remove[i], keepcount)

		*self.filenames = (*self.filenames)[wm]
		if ptr_valid(self.validated) then *self.validated     = (*self.validated)[wm]
		if ptr_valid(self.finfo) then *self.finfo     = (*self.finfo)[wm]

		self->Log, "Removed "+filenames_to_remove[i]
		count_removed += 1
	endfor
	

end


;+ --------------------------------------------------------------------- 
; fileset::scan_headers
;  Read in FITS keywords information from all files
;-
pro fileset::scan_headers
	if ~ptr_valid(self.filenames) then return ; nothing to do

    self->Log, "Loading and parsing file headers..."


	filenames = *self.filenames

    ;;Test Validity of the data (are these GPI files and is it OK to proceed?)
	;; TODO not sure we need this branch anymore if we're not deleting files from the array, just flaggin them as invalid.
    if gpi_get_setting('strict_validation',/bool, default=1,/silent)  then begin

		nfiles = n_elements(*self.filenames)

        for ff=0, nfiles-1 do begin
			if (*self.validated)[ff] then continue
			if self.debug then message,/info, 'Verifying keywords for file '+filenames[ff]
            (*self.validated)[ff]=gpi_validate_file( filenames[ff] ) 
        endfor  

        indnonvalid=where((*self.validated) eq 0, cnv, complement=wvalid, ncomplement=countvalid)
        if cnv gt 0 then begin
            self->Log, 'WARNING: invalid files (based on FITS keywords) have been detected and will be ignored in future steps: ' 
			self->Log, "      "+strjoin(filenames[indnonvalid],", ")
        endif else begin
			self->Log, "All "+strc(n_elements(filenames))+" files pass basic FITS keyword validity check."
		endelse
      
    endif else begin ;if strict_validation is disabled (ie. data are test data) don't remove them but inform a bit if anything is invalid

		nfiles = n_elements(filenames) 

        for ff=0, nfiles-1 do begin
			if self.debug then message,/info, 'Checking for valid headers: '+filenames[ff]
			(*self.validated)[ff] = gpi_validate_file(filenames[ff])
		endfor
    endelse


	nvalid = total(*self.validated)
	if nvalid le 0 then begin
		self->Log, "No valid files to read keywords from. Exiting."
		return
	endif

	self->Log,'Now reading in keywords for all files...'

	;tmp = gpi_get_obs_keywords((*self.filenames)[min(where(*self.validated))])
	;*self.finfo = replicate(tmp,nfiles)

	for jj=0,nfiles-1 do begin
		if (*self.validated)[jj] then (*self.finfo)[jj] = gpi_get_obs_keywords((*self.filenames)[jj])
	endfor


	wvalid = where((*self.finfo).valid, nvalid, complement=winvalid, ncomplement=ninvalid)
	if ninvalid gt 0 then begin
		self->Log, "Some files are lacking valid required FITS keywords: "
		self->Log, strjoin((*self.filenames)[winvalid], ", ")
		self->Log, "These will be ignored in all further parsing steps."
		(*self.validated)[winvalid] = 0

		if wvalid[0] eq -1 then begin
			self->Log, "ERROR: All files rejected"
			return
		endif
	endif



end


;+ --------------------------------------------------------------------- 
; fileset::sort
;	Re-sort all internal data structures to list filenames
;
;	You can either hand in an explicit list of indices, or else if you call 
;	this without that argument, then it will sort alphabetically by filenames.
;-

pro fileset::sort, sort_indices

	if ~ptr_valid(self.filenames) then return ; nothing to do

	if ~(keyword_set(sort_indices)) then begin
		if self.debug then self->Log, "Sorting alphabetically by filenames."
		sort_indices = sort(*self.filenames)
	endif 

	*self.filenames = (*self.filenames)[sort_indices]
	*self.validated = (*self.validated)[sort_indices]
	*self.finfo = (*self.finfo)[sort_indices]

	if self.debug then self->Log, "Re-sorted fileset"

end




;+ --------------------------------------------------------------------- 
; fileset::get_filenames
;	Return the filenames to the calling function
;-

function fileset::get_filenames
	if ptr_valid(self.filenames) then return, *self.filenames else return, -1
end

;+ --------------------------------------------------------------------- 
; fileset::get_validated
;	Return the validated flag for each file to the calling function
;-

function fileset::get_validated
	if ptr_valid(self.validated) then return, *self.validated else return, -1
end


;+ --------------------------------------------------------------------- 
; fileset::get_info
;   Return a variety of information to the calling function, 
;   including filename, display name, and date
;-
function fileset::get_info, nfiles=nfiles
	if ptr_valid(self.finfo) then begin
		nfiles = n_elements(*self.finfo)
		return, *self.finfo 
	endif else begin
		nfiles=0
		return, ''
	endelse
end


;+ --------------------------------------------------------------------- 
; fileset::log
;    Pass-through logging function
;-
pro fileset::log, logtext
	if obj_valid(self.where_to_log) then (self.where_to_log)->log, logtext else print, "LOG: "+logtext

end



;+ --------------------------------------------------------------------- 
; fileset::init
;   Class initialization function
;-
function fileset::init, filenames=filenames, debug=debug, $
		where_to_log=where_to_log, gui_parent_wid=gui_parent_wid

	self.filenames = ptr_new();/alloc)
	self.validated = ptr_new();/alloc)
	self.finfo 	   = ptr_new();/alloc)

	self.debug = keyword_set(debug)
	if obj_valid(where_to_log) then self.where_to_log = where_to_log
	if keyword_set(gui_parent_wid) then self.gui_parent_wid=gui_parent_wid

	if keyword_set(filenames) then self->add_files, filenames

	return, 1
end



;+ --------------------------------------------------------------------- 
; fileset__define
;	Object variable definition
;-

pro fileset__define

	state = { fileset,              	$
			filenames: ptr_new(),		$ ; Pointer to strarray of filenames
			validated: ptr_new(),		$ ; Pointer to bytarray of record of previous validations
			debug: 0,					$ ; Flag for extra verbose output
			finfo: ptr_new(),			$ ; File info, i.e. as returned by get_obs_keywords()
			where_to_log: obj_new(),	$ ; object handle to something with a Log function we can use.
			gui_parent_wid: 0,			$ ; optional, GUI widget ID of parent window
			tmp: 0 }

end
