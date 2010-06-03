;+
; NAME:  make_gpi_log
;
;  make_gpi_logfile,directory, outdir=outdir, filespec=filespec
;
;	Given a bunch of GPI-created FITS files, produce a nice human-readable log
;	file table. 
;
; INPUTS:
; 	directory	name of an input directory containing FITS files. 
; 				Default is the current directory
;
; KEYWORDS:
; 	outdir=		Output path for the gpi_log.txt file 
; 				Default is the current directory
; 	filespec=	Wildcard file specification to include. 
; 				Default is '*.fits*'
;
; 	/silent		Don't show any output on screen
; 			
; OUTPUTS:
; 	Creates 'gpi_log.txt' in the output directory. 
; 	Also displays the same text as output on screen. 
;
; REQUIRES:
; 	hdrconcat, sxpararr, checkdir
; 	forprint from Goddard library.
;
; HISTORY:
; 	Began 2010-02-09 15:37:09 by Marshall Perrin 
; 	Based directly on various log-file creating scripts for OSIRIS, GMOS, etc. 
;-



PRO make_gpi_logfile,directory, outdir=outdir, filespec=filespec, silent=silent

	if ~(keyword_set(directory)) then directory='' else  checkdir, directory
	if ~(keyword_set(outdir)) then outdir="./"
	checkdir,outdir
	
	; Find all FITS files
	if ~(keyword_set(filespec)) then filespec="*.fits*" 
	filenames = file_search(directory+filespec)
	maxlen = max(strlen(filenames))

	; load all headers into an array
	for i=0l,n_elements(filenames)-1 do begin
		if ~(keyword_set(silent)) then print,filenames[i]
		h = headfits(filenames[i])
		hdrconcat,hdrs,h
	endfor 

	keys = ['OBJECT', 'DISPERSR', 'FILTER', 'LYOTMASK', 'APODIZ', 'EXPTIME', 'TIME-OBS', 'FILETYPE']
	formats=['A-20',  'A-8',     'A-4',    'A-5',      'A-8',    'F-8.2',   'A-12'    , 'A-20']

	nk = n_elements(keys)
	vals = ptrarr(nk)
	formatstr=""
	headerstr = string("FILENAME", format="(A-"+strc(maxlen+3)+")")
	for i=0,nk-1 do begin
		vals[i] = ptr_new(sxpararr(hdrs, keys[i]) )
		; The following complicated code takes the above format string,
		; reformats it to print an string (type A) output no matter what the
		; format code above is, with one character narrower width of actual text
		; plus one space. This produces a nice-looking header line with at least one
		; space between each key.  - MP
		headerstr+= string(keys[i], format="(A-"+strc(floor(float(strmid(formats[i], 2)))-1)+")" )+" "	

	endfor

	formatstr = '(A-'+strc(maxlen+3)+', '+strjoin(formats,", ")+')'


	; print out to DISK
	forprint, textout=outdir+"gpi_log.txt", filenames, *vals[0], *vals[1], *vals[2], *vals[3], *vals[4], *vals[5], *vals[6], *vals[7], $
		format=formatstr, $
		comment= headerstr

	; and to SCREEN
	if ~(keyword_set(silent)) then begin
		forprint, textout=2, filenames, *vals[0], *vals[1], *vals[2], *vals[3], *vals[4], *vals[5], *vals[6], *vals[7], $
			format=formatstr, $
			comment= headerstr

		print, ""
		print, "  ==>> "+outdir+'gpi_log.txt'
		print, ""
	endif



end
