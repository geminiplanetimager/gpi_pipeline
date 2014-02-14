;+
; NAME:  gpi_pipeline_version
;
; OUTPUTS: Return the current pipeline version number
;
; KEYWORDS:
;   /svn	Set to append current svn version ID to the
;   		version number string. This will *attempt* to 
;   		look this up from the pipeline directory, if
;   		it is a svn working directory, and should 
;   		gracefully and silently fail if not - in which
;   		case just the major pipeline version number is returned.
;
;
; HISTORY:
;   < 0.5:			Early development circa 2007-2008a
;					GPI data simulator tool (DST) by Maire and Perrin
;					Initial development of gpitv and stand-alone primitives by Maire
;	2008-06			Release	0.5 for GPI CDR
;	2010-05-26		Release 0.6 for GPI team science meeting
;					First implementation of backbone and other infrastructure by Perrin
;					and recipe editor GUI by Maire
;	0.65:			most of 2010 development? Version # not often updated.
;
;	2011-08-01:		version 0.70
;			 		multi-extension FITS format adopted for consistency with Gemini.
;	2012-02-01:		verion 0.8
;					Improved MEF file support, Gemini style keywords, major code
;					reorganization and cleanup. - MP
;	2012-08-08		The large number of improvements in the last few months
;					clearly justify a bump to at least 0.8.1...
;	2013-02-11		Release 0.9.0 for GPI Acceptance Testing
;	2013-06-17      Release 0.9.1 at end of GPI Acceptance Testing
;	2013-09-03		Release 0.9.2 for GPI integration at Gemini South
;	2013-11-12		Release 0.9.3 for GPI first light observing run.
;	2014-01-07		Release 0.9.4 for AAS Meeting 
;	2014-02-11		Release candidate 1.0rc1
;	2014-02-14		Milestone: Release version 1.0!
;-

function gpi_pipeline_version, svn=svn

version = '1.0'

if keyword_set(svn) then begin
	; append svn version ID also
	codepath = gpi_get_directory('GPI_DRP_DIR')
	cd, curr=curr
	catch, myerror
	if myerror eq 0 then begin
		cd, codepath
		spawn, 'svnversion', results,/noshell
		svnid = results[n_elements(results)-1] ; take the last line of the result
			; this is in case we get multi-line output because e.g. the user
		version += ", rev "+strc(svnid)
	endif
	cd, curr

endif



return, version
end
