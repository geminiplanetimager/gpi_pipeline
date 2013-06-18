;;  **********   DRP compiler   **************
;; Here are the commands that will compile the DRP code 
;; and produce executables.
;;
;;   This is not meant to be used be end-users of the pipeline;
;;   it is a tool for GPI instrument team and Gemini staff who are
;;   making public releases of the pipeline.
;;
;; Execute gpi_compiler command directly within the IDL command line. 
;; Set execoutputdir to define where the executables will be produced.
;;
;; HISTORY:
;; 2012-11-19: JM
;; 2012-12-10 MP: Some minor debugging to work on a Mac; more efficient
;;				  recompilation after error handling; print informative
;;				  messages to the user. Mac OS output is 64-bit. 
;;				  Output directory now has pipeline version number in it.
;; 2012-12-10 MP: Also, always compile gpitv. Look up gpitv path automatically,
;;				  too.
;; 2013-06-17 MP: Compress output into convenient zip automatically.
;;				  More specific output options per platform.
pro gpi_compiler, compile_dir, drpdirectory=drpdirectory, gpitvdir=gpitvdir

	compile_opt defint32, strictarr, logical_predicate

	if N_params() EQ 0 then begin ;Prompt for directory of produced executables?
  		compile_dir = ' ' 
        read,'Enter name of the directory where to create executables: ',compile_dir    
  	endif


;======== Ensure the primitives config file is up to date for inclusion in the distribution files
make_primitives_config


;======== Compile all routines found inside the GPI_DRP_DIR =======
;  This will implicitly end up compiling a bunch of stuff inside the
;  external dependencies directory as needed. 
;
	; first find all the .pro files inside the gpi_drp_dir
	if keyword_set(drpdirectory) then directory=drpdirectory else $
	directory=gpi_get_directory('GPI_DRP_DIR')


	list = FILE_SEARCH(directory,'[A-Za-z]*.pro',count=cc, FULLY_QUALIFY_PATH =0 )

	if (directory eq "") OR (cc eq 0) then begin
	  print,"You need to properly define the DRP directory. Use the drpdirectory keyword or set the GPI_DRP_DIR environment variable. "
	  return
  	endif else begin
		print, "Found routines for GPI DRP"
	endelse



	; Also include gpitv, which lives in its own directory
	if ~keyword_set(gpitvdir) then begin
		which, gpitv__define, output=gpitvpath,/quiet
		gpitvdir = file_dirname(gpitvpath)
	endif
	gpitvroutine=FILE_SEARCH(gpitvdir,'[A-Za-z]*.pro',count=cg) 
	if (cg eq 0) then begin
		print,"You need to properly define the DRP directory (and GPItv dir). Use the drpdirectory and gpitvdir keywords or set the GPI_DRP_DIR environment variable. "
		return
	endif else begin
		print, "Found routines for gpitv"
		totlist = [list, gpitvroutine]
	endelse


	print, totlist
	print, "Number of routines found:", n_elements(totlist)
	nelem=n_elements(totlist)


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
    if (~strmatch(totlist[i], "*deprecated*",/fold)) and (i lt nelem+50) then $
    RESOLVE_ROUTINE, FILE_BASENAME(totlist[i],".pro"), /COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE
endfor
print, " n_elements(totlist)=", n_elements(totlist), "  last function compiled i=",i

resolve_all, /continue

CATCH,/CANCEL




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


endfor


;======== Prepare Output Directory Structure =====
; Now, clean up the separate executables into one nicely organized set
; including various additional directories as needed by the DRP

message,/info, "Now cleaning up and organizing the output files..."


output_dir = compile_dir+'gpi_pipeline-'+gpi_pipeline_version()

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
endif

file_copy, directory+path_sep()+'gpi.bmp',output_dir+path_sep(),/overwrite

;;remove non-necessary txt files 
Result = FILE_SEARCH(output_dir+path_sep()+'*script_source.txt', count=ct) 
if ct gt 0 then file_delete, Result

message,/info, ""
message,/info, 'Compilation done.'   
message,/info, "   Output is in "+output_dir
message,/info, ""


;======== Package output into zip files =======================================================


if !version.os_family eq 'unix' then begin

	message,/info,'Creating ZIP file archive'
	cd, compile_dir, current=old_dir

	; create a version with the included runtime
	zipfilename =  'gpi_pipeline-'+gpi_pipeline_version()+'_runtime_'+platform+'.zip'
	zipcmd=  'zip -r '+zipfilename+' gpi_pipeline-'+gpi_pipeline_version()
	message,/info, zipcmd
	spawn, zipcmd

	; now create a version that is OS independent
	; just leave out the runtime.
	idl_rt_dir = 'idl'+ strmid(!version.release, 0,1) +  strmid(!version.release, 2,1)
	zipfilename_no_idl =  'gpi_pipeline-'+gpi_pipeline_version()+'.zip'
	zipcmd = 'zip -r '+zipfilename_no_idl+' gpi_pipeline-'+gpi_pipeline_version()+' -x "*/'+idl_rt_dir+'/*" '
	message,/info, zipcmd
	spawn, zipcmd



	cd, old_dir

	message,/info, 'The ZIP files ready for distribution are:'
	message,/info, "      "+output_dir+path_sep()+zipfilename
	message,/info, "      "+output_dir+path_sep()+zipfilename_no_idl

endif else begin
	message,/info, 'You are running on Windows, therefore you need'
	message,/info, 'to zip up the output directories by yourself.'
	message,/info, ''
	message,/info, '(And if you know how, please modify gpi_compiler to call zip automatically on Windows...)'

endelse








end
