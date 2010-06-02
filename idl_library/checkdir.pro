;+
; NAME: checkdir
;
; PURPOSE: Check whether a given directory exists
;
; NOTES:
;   Given a string supposedly naming a directory, checks whether it
;       (a) corresponds to a valid directory
;       (b) has a trailing slash present
;	If (a) fails, the routine stops and gives an error. 
;	if (b) fails, the routine silently adds a slash.
;
;	If called with /expand, it will expand any ~usernames in the
;	given string to the full directory path needed by IDL.
;
;	If called with /make, it will create the directory if needed. 
;
; USAGE:
; 	checkdir, dir
;
; INPUTS: dir	String containing a directory
; KEYWORDS:
; 	expand		expand ~'s in the path.
; 	fallback	if dir doesn't exist, try using this one instead
;
; HISTORY:
;	Aug 21, 2001	MDP
;	2003 June 25	Added fallback option. MDP
;	2005 Sept 21	Added /make   MDP
;	2009 Oct 15     Switched to path_sep() instead of just /. MDP
;-

PRO checkdir,dir,expand=expand,fallback=fallback,make=make
	if keyword_set(expand) then dir=expand_path(dir)

	if not(keyword_set(dir) )then $
		message,"No directory variable passed, or dir undefined!"
	if ( strmid(dir, strlen(dir)-1,1) ne path_sep()) then dir=dir+path_sep()
	if file_test(dir,/DIRECTORY) then return

	if keyword_set(fallback) then begin
		fbdir = fallback
		if keyword_set(expand) then fbdir=expand_path(fallback)
		if ( strmid(fbdir, strlen(fbdir)-1,1) ne path_sep()) then fbdir=fbdir+path_sep()
		if file_test(fbdir,/DIRECTORY) then begin
			message,/info,"Directory "+dir+" does not exist. Using "+fbdir+" instead."
			dir = fbdir
			return
		endif
	endif
			

	if keyword_set(make) then begin
		print,"Directory "+dir+" does not exist. Creating it!"
		file_mkdir,dir
		return
	endif
			
	message,"Directory "+dir+" does not exist!"
	
end
