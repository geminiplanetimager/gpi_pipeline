;+
; NAME: gpi_compiler
;
;
;  **********   GPI DRP compiler   **************
;
; This utility function will compile the DRP code 
; and produce executables for use with the IDL Runtime.
;
;   This is not meant to be used be end-users of the pipeline;
;   it is a tool for GPI instrument team and Gemini staff who are
;   making public releases of the pipeline.
;
;   Execute gpi_compiler command directly within the IDL command line.
;   Example:
;   IDL>   gpi_compiler, '~/my_output_dir/'
;
;
; INPUTS 
; compile_dir		Path to output files
;
; KEYWORDS
; drpdirectory=	Set this to override GPI_DRP_DIR path
; /stop			Set this to 1 to stop on compile errors
; /nodocs		Don't try to compile the Sphinx HTML docs to include.
; /svnonly      Only compile files that are in the SVN, and check that
;				there are not any local modifications. 
;
;
; HISTORY:
; 2012-11-19: JM
; 2012-12-10 MP: Some minor debugging to work on a Mac; more efficient
;			     recompilation after error handling; print informative
;				 messages to the user. Mac OS output is 64-bit. 
;				 Output directory now has pipeline version number in it.
; 2012-12-10 MP: Also, always compile gpitv. Look up gpitv path automatically,
;				 too.
; 2013-06-17 MP: Compress output into convenient zip automatically.
;				 More specific output options per platform.
;
; 2013-07-15 MP: Some more robustness, better docs. Added finder helper
; 				 function to remove dependency on which.
; 2013-08-05 MP: Add HTML documentation to the compilation.
; 2013-08-05 ds: Added /svnonly option
; 2013-08-05 MP: Updated to accomodate relocated gpitv (which simplifies this)
; 2014-01-07 MP: Updated to catch up with the svn reorganization in September
;				 2013 and the creation of a public branch.
; 2014-02-04 MP: Removed deprecated docdir option
; 2014-02-06 MP: Debugged /nodocs option
;
;-

;----------------------------------------------

; first a helper function to find a routine
; This will ignore any directories tagged as a pipeline release, even if
; they are also in your $IDL_PATH
function gpi_compiler_finder, proname
	findpro, proname, dirlist=dirlist,/noprint
	wnr = where(~ strmatch(dirlist,'*Releases*'))
	dirlist = dirlist[wnr]

	if n_elements(dirlist) eq 1 then begin
		return, dirlist[0] 
	endif else begin
		message,'Multiple copies of '+proname+' were found in your $IDL_PATH.',/info
		print, dirlist
		stop
	endelse
	


end

;----------------------------------------------

pro gpi_compiler, compile_dir, drpdirectory=drpdirectory, svnonly=svnonly, nodocs=nodocs

	compile_opt defint32, strictarr, logical_predicate




	print, ""
	print, "Requirements for compiling GPI pipeline: "
	print, "   1) Working copies of pipeline and external"
	print, "   2) Sphinx plus numpydoc and several other extensions "
	print, "      (unless /nodocs is set) "
	print, ""


	if N_params() EQ 0 then begin ;Prompt for directory of produced executables?
  		compile_dir = ' ' 
        read,'Enter desired output directory to save executables in: ',compile_dir    
  	endif

	result = gpi_check_dir_exists( compile_dir)
	if result eq -1 then begin
		print, "ERROR: Desired output directory does not exist."
		return
	endif


;======== Ensure the primitives config file is up to date for inclusion in the distribution files
gpi_make_primitives_config


;======== Compile all routines found inside the GPI_DRP_DIR =======
;  This will implicitly end up compiling a bunch of stuff inside the
;  external dependencies directory as needed. 
;
	; first find all the .pro files inside the gpi_drp_dir
	if keyword_set(drpdirectory) then directory=drpdirectory else $
	directory=gpi_get_directory('GPI_DRP_DIR')
	checkdir, directory


	list = FILE_SEARCH(directory,'[A-Za-z]*.pro',count=cc, FULLY_QUALIFY_PATH =0 )

	if (directory eq "") OR (cc eq 0) then begin
	  print,"You need to properly define the DRP directory. Use the drpdirectory keyword or set the GPI_DRP_DIR environment variable. "
	  return
  	endif else begin
		print, "Found routines for GPI DRP"
	endelse


	;----- Exclude certain files from the compilation ----
	; remove 'Releases' versions if found (this will be uncessary with revised
	; svn repository organization
	
	wnr = where(~ strmatch(list,'*Releases*'))
	list = list[wnr]

	; Also do not include data simulator, even if present in the source code
	; directory
	wnr = where(~ strmatch(list,'*/dst/*'))
	list = list[wnr]



;	;--- Also include gpitv, which lives in its own directory
;	if ~keyword_set(gpitvdir) then begin
;		;which, gpitv__define, output=gpitvpath,/quiet
;		gpitvdir = gpi_compiler_finder('gpitv__define')
;		;gpitvdir = file_dirname(gpitvpath)
;	endif
;	gpitvroutine=FILE_SEARCH(gpitvdir,'[A-Za-z]*.pro',count=cg) 
;	if (cg eq 0) then begin
;		print,"You need to properly define the DRP directory (and GPItv dir). Use the drpdirectory and gpitvdir keywords or set the GPI_DRP_DIR environment variable. "
;		return
;	endif else begin
;		print, "Found routines for gpitv"
;		totlist = [list, gpitvroutine]
;	endelse
;
	totlist = list
	;---- Some more exclusions

	explicit_excludes = ['gpi-pipeline__launchdrp',$
						 'gpi-pipeline__launchguis', $
						 'gpi-pipeline__launchguis', $
					 	 'test_pol_combine_test', $
					 	 'gpitv_err']
	for i=0,n_elements(explicit_excludes)-1 do begin
		print, "Excluding: "+explicit_excludes[i]
		wnm = where(~strmatch(totlist,'*'+explicit_excludes[i]+'.pro'))
		totlist=totlist[wnm]
	endfor

        if keyword_set(svnonly) then begin
           print,'Checking against SVN...'
           ares = strarr(n_elements(totlist))
           aerrs = strarr(n_elements(totlist))
           for j=0,n_elements(totlist)-1 do begin &$
              spawn,'svn status '+totlist[j],res,err &$
              ares[j] = res &$
              aerrs[j] = err &$
           endfor 
           
           ;;check for any errors
           tmp = where(aerrs ne '',ct)
           if ct ne 0 then message,'Error detected in checking svn status.'

           ;;first kill the ones that are not version controlled
           bad = where(strcmp(ares,'?',1),complement=good,ct)
           if ct gt 0 then begin
              totlist = totlist[good]
              ares = ares[good]
           endif 
           
           maybebad = where(ares ne '', ct)
           if ct ne 0 then begin
              print,'The following files differ from their checked-in version:'
              print,ares[maybebad]
              in = ''
              read,'Continue anyway? ([No]/Yes) ',in
              if in eq '' then in =  'No'
              if strcmp(in,'n',1,/fold) then return 
           endif 
        endif  

	print, totlist
	print, "Number of routines found:", n_elements(totlist)
	nelem=n_elements(totlist)

	forprint, text='gpi_compiler_log.txt',totlist

   ; Establish error handler.
   ; Just print out informative messages for compilation failures, don't abort
   ; the whole thing.
   ;
   ; When errors occur, the index of the 
   ; error is returned in the variable Error_status: 
   CATCH, Error_status 
 ;This statement begins the error handler: 
   IF Error_status NE 0 THEN BEGIN 
      PRINT, 'Error index: ', Error_status 
      PRINT, 'Error message: ', !ERROR_STATE.MSG 
      print, "routine #",i
	  stop
      ; Handle the error by changing order of routines: 
      if strmatch(!ERROR_STATE.MSG ,"End of file encountered before end of program.",/fold) then begin
          loop_start=i+1 ;do not compile this guy. Continue with next entry in list.
      endif else begin   ; need to order routines (for common block definition)
          routine=totlist[i]
          totlist=[totlist, routine]
          totlist[i]=totlist[i-1] ;just put an already compiled function so no problem occurs
		  loop_start=1   ; keep going with list processing...
      endelse 
   ENDIF else begin 
		loop_start = 0
   endelse
 
print, " n_elements(totlist)=", n_elements(totlist)

for i=loop_start, n_elements(totlist)-1 do begin
    if (~strmatch(totlist[i], "*deprecated*",/fold)) and (i lt nelem+50) then begin
		print, totlist[i]
    	RESOLVE_ROUTINE, FILE_BASENAME(totlist[i],".pro"), /COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE
	endif
endfor
print, " n_elements(totlist)=", n_elements(totlist), "  last function compiled i=",i

resolve_all, /continue

CATCH,/CANCEL


;======== Compile the Sphinx documentation ========
; the user can disable/skip this by setting /nodocs if they don't have sphinx.
if ~(keyword_set(nodocs)) then begin

	; the documentation lives in a subdirectory of the pipeline.
	docdir = gpi_get_directory('GPI_DRP_DIR')+path_sep()+"documentation"

	if ~ file_test(docdir+path_sep()+"index.rst") then begin
		message, "Cannot find Sphinx documentation root. Please set docdir to the path to the Sphinx documentation, or set /nodocs to skip compiling the docs."
	endif

	cd, docdir, current=curdir

	message,/info, '----------------------------------------------------------'
	message,/info, 'Now trying to compile Sphinx documentation to HTML in '+docdir

	spawn, 'make html'
	message,/info, '----------------------------------------------------------'


	doc_out_path = docdir+path_sep()+'doc_output/html'
	if ~ file_test(doc_out_path+path_sep() + 'index.html') then begin
		message, "Could not find output HTML documentation in "+doc_out_path+". Please check that Sphinx can compile the documentation on your system."
	endif else message,/info, 'Sphinx documentation compiled successfully to HTML.'

	cd, curdir

endif


;======== Create executables ========
; by the time we've gotten here, we've compiled everything successfully
; Now make the executables. 
;
compile_dir += path_sep()
if file_test(compile_dir,/dir) eq 0 then spawn, 'mkdir ' + compile_dir


launcher_names = ['gpi_launch_guis', 'gpi_launch_pipeline',  'gpitv']

for i=0,n_elements(launcher_names)-1 do begin
	message,/info, "Now creating " + launcher_names[i]+".sav"
	SAVE, /ROUTINES, FILENAME = compile_dir+launcher_names[i]+'.sav' 
	; create the executables
	
	case !version.os of
	'darwin': begin
		platform = 'macosx'
		macint64 = 1
	end
	'linux': begin
		platform = 'linux'
		lin64=1
	end
	'Win32': begin
		platform ='win32'
		win32=1
	end
	endcase

	
	MAKE_RT, launcher_names[i], compile_dir, savefile=compile_dir+launcher_names[i]+'.sav', /vm,  $
		MACINT64=macint64, LIN64=lin64, WIN32=win32, /overwrite

	;delete *.app files which dont load properly due to not having access to
	; environment variables
	if (macint64 eq 1) then begin
		FILE_DELETE, compile_dir+launcher_names[i]+path_sep()+launcher_names[i]+'.app',/recursive
	endif

endfor


;======== Prepare Output Directory Structure =====
; Now, clean up the separate executables into one nicely organized set
; including various additional directories as needed by the DRP

message,/info, "Now cleaning up and organizing the output files..."

; compute version string including major+minor version number and svn revision
; ID if possible.
version_parts = strsplit(gpi_pipeline_version(/svn),', :',/extract)
if n_elements(version_parts) eq 1 then version_string = version_parts[0] else version_string =  version_parts[0]+"_r"+version_parts[2]


output_dir = compile_dir+'gpi_pipeline_'+version_string

file_mkdir, output_dir
file_mkdir, output_dir+path_sep()+'executables'
;;put all files in the same dir
for i=0,n_elements(launcher_names)-1 do begin
	message,/info, "Now cleaning up from compiling " + launcher_names[i]
	file_copy, compile_dir+ launcher_names[i]  +path_sep()+'*', output_dir+path_sep()+'executables', /recursive, /overwrite
	file_delete, compile_dir+launcher_names[i], /recursive
	file_delete, compile_dir+launcher_names[i]+'.sav'
endfor

file_mkdir, output_dir+path_sep()+'log',$
            output_dir+path_sep()+'recipe_templates',$
            output_dir+path_sep()+'queue',$
            output_dir+path_sep()+'log',$
            output_dir+path_sep()+'scripts',$
            output_dir+path_sep()+'config',$
            output_dir+path_sep()+'config'+path_sep()+'filters'
;;copy DRF templates, etc...            
file_copy, directory+path_sep()+'recipe_templates'+path_sep()+'*.xml', output_dir+path_sep()+'recipe_templates'+path_sep(),/overwrite         
file_copy, directory+path_sep()+'config'+path_sep()+'*.xml', output_dir+path_sep()+'config'+path_sep(),/overwrite   
file_copy, directory+path_sep()+'config'+path_sep()+'*.txt', output_dir+path_sep()+'config'+path_sep(),/overwrite           
file_copy, directory+path_sep()+'config'+path_sep()+'*.dat', output_dir+path_sep()+'config'+path_sep(),/overwrite              
file_copy, directory+path_sep()+'config'+path_sep()+'filters'+path_sep()+'*.fits', output_dir+path_sep()+'config'+path_sep()+'filters'+path_sep(),/overwrite


if !version.os_family eq 'unix' then begin

	; Special case: copy the 'gpi-pipeline-compiled version of the startup script,
	; but drop the '-compiled' extension while doing so
	file_copy, directory+path_sep()+'scripts'+path_sep()+'gpi-pipeline-compiled', output_dir+path_sep()+'scripts'+path_sep()+"gpi-pipeline",/overwrite   
	file_copy, directory+path_sep()+'scripts'+path_sep()+'gpi-setup-nix', output_dir+path_sep()+'scripts'+path_sep()+"gpi-setup-nix",/overwrite   
endif else begin
	;For windows also need to grab some scripts
	file_copy, directory+path_sep()+'scripts'+path_sep()+'gpi-pipeline-compiled-windows.bat', output_dir+path_sep()+'scripts'+path_sep()+"gpi-pipeline-windows.bat",/overwrite   
	file_copy, directory+path_sep()+'scripts'+path_sep()+'gpi-setup-windows.bat', output_dir+path_sep()+'scripts'+path_sep()+"gpi-setup-windows.bat",/overwrite   
endelse

file_copy, directory+path_sep()+'gpi.bmp',output_dir+path_sep(),/overwrite

;;remove non-necessary txt files 
Result = FILE_SEARCH(output_dir+path_sep()+'*script_source.txt', count=ct) 
if ct gt 0 then file_delete, Result


;; Copy in the HTML documentation
if ~(keyword_set(nodocs)) then file_copy, doc_out_path, output_dir, /overwrite,/recursive


;; Create a copy of the source including dependencies
message,/info, ''
message,/info, 'Creating a source ZIP file'
output_source_dir = output_dir+"_source"
file_mkdir, output_source_dir
file_copy, gpi_get_directory('GPI_DRP_DIR'), output_source_dir+"/pipeline", /overwrite,/recursive
message,/info, '    including pipeline code from '+gpi_get_directory('GPI_DRP_DIR')

findpro, 'nchoosek', dirlist=externdirs ; find a file we expect to be in our external directory.
externdir = externdirs[0]
message,/info, '    including external code from '+externdir

file_copy, externdir, output_source_dir+"/external", /overwrite,/recursive
;file_copy, gpi_get_directory('GPI_DRP_DIR')+"/../gpitv", output_source_dir, /overwrite,/recursive
;file_copy, gpi_get_directory('GPI_DRP_DIR')+"/../documentation", output_source_dir, /overwrite,/recursive


message,/info, ""
message,/info, 'Compilation done.'   
message,/info, "   Output is in "+output_dir
message,/info, ""


;======== Package output into zip files =======================================================

 

if !version.os_family eq 'unix' then begin

	message,/info,'Creating ZIP file archives'
	cd, compile_dir, current=old_dir

	; Create zip of the compiled code.
	; create a version with the included runtime
	zipfilename =  'gpi_pipeline_'+version_string+'_runtime_'+platform+'.zip'
	zipcmd=  'zip -r '+zipfilename+' gpi_pipeline_'+version_string
	message,/info, zipcmd
	spawn, zipcmd

	; now create a version that is OS independent
	; just leave out the runtime.
	idl_rt_dir = 'idl'+ strmid(!version.release, 0,1) +  strmid(!version.release, 2,1)
	zipfilename_no_idl =  'gpi_pipeline_'+version_string+'_compiled.zip'
	zipcmd = 'zip -r '+zipfilename_no_idl+' gpi_pipeline_'+version_string+' -x "*/'+idl_rt_dir+'/*" '
	message,/info, zipcmd
	spawn, zipcmd


	; Create zip of the source code directories
	zipfilename_source =  'gpi_pipeline_'+version_string+'_source.zip'
	zipcmd = 'zip -r '+zipfilename_source+' gpi_pipeline_'+version_string+'_source '
	message,/info, zipcmd
	spawn, zipcmd

	cd, old_dir

	message,/info, 'The ZIP files ready for distribution are:'
	message,/info, "      "+compile_dir+zipfilename
	message,/info, "      "+compile_dir+zipfilename_no_idl
	message,/info, "      "+compile_dir+zipfilename_source

endif else begin
	message,/info, 'You are running on Windows, therefore you need'
	message,/info, 'to zip up the output directories by yourself.'
	message,/info, ''
	message,/info, '(And if you know how, please modify gpi_compiler to call zip automatically on Windows...)'

endelse








end
