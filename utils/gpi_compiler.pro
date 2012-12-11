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
pro gpi_compiler, compildir, drpdirectory=drpdirectory, gpitvdir=gpitvdir

	if N_params() EQ 0 then begin ;Prompt for directory of produced executables?
  		compildir = ' ' 
        read,'Enter name of the directory where to create executables: ',compildir    
  	endif
	if keyword_set(drpdirectory) then directory=drpdirectory else $
	directory=gpi_get_directory('GPI_DRP_DIR')

	list = FILE_SEARCH(directory,'[A-Za-z]*.pro',count=cc, FULLY_QUALIFY_PATH =0 )

	if (directory eq "") OR (cc eq 0) then begin
	  print,"You need to properly define the DRP directory. Use the drpdirectory keyword or set the GPI_DRP_DIR environment variable. "
	  return
  	endif else begin
		print, "Found routines for GPI DRP"
	endelse



	;if keyword_set(gpitv) then begin
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
	;endif else begin
		;print," *****  GPITV will NOT be compiled."
		;totlist=list
	;endelse


	print, totlist
	print, "Number of routines found:", n_elements(totlist)
	nelem=n_elements(totlist)


   ; Establish error handler. When errors occur, the index of the 
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




;==== by the time we've gotten here, we've compiled everything successfully
; Now make the executables. 
;
compildir += path_sep()
if file_test(compildir,/dir) eq 0 then spawn, 'mkdir ' + compildir


launcher_names = ['launch_drp', 'gpipiperun', 'automaticreducer', 'gpitv']

for i=0,n_elements(launcher_names)-1 do begin
	message,/info, "Now creating " + launcher_names[i]+".sav"
	SAVE, /ROUTINES, FILENAME = compildir+launcher_names[i]+'.sav' 
	; create the executables
	MAKE_RT, launcher_names[i], compildir, savefile=compildir+launcher_names[i]+'.sav', /vm, /MACINT64, /LIN32, /WIN32,/overwrite


endfor

;SAVE, /ROUTINES, FILENAME = compildir+'launch_drp.sav' 
;; create the executables
;MAKE_RT, 'launch_drp', compildir, savefile=compildir+'launch_drp.sav', /vm, /MACINT64, /LIN32, /WIN32,/overwrite
;
;SAVE, /ROUTINES, FILENAME = compildir+'gpipiperun.sav' 
;MAKE_RT, 'gpipiperun', compildir, savefile=compildir+'gpipiperun.sav', /vm, /MACINT64, /LIN32, /WIN32,/overwrite
;
;SAVE, /ROUTINES, FILENAME = compildir+'automaticreducer.sav' 
;MAKE_RT, 'automaticreducer', compildir, savefile=compildir+'automaticreducer.sav', /vm, /MACINT64, /LIN32, /WIN32,/overwrite
;
;SAVE, /ROUTINES, FILENAME = compildir+'gpitv.sav' 
;MAKE_RT, 'gpitv', compildir, savefile=compildir+'gpitv.sav', /vm, /MACINT64, /LIN32, /WIN32,/overwrite

;==============
; Now, clean up the separate executables into one nicely organized set
; including various additional directories as needed by the DRP

message,/info, "Now cleaning up and organizing the output files..."


output_dir = compildir+'pipeline-'+gpi_pipeline_version()

file_mkdir, output_dir
;;put all files in the same dir
file_copy, compildir+'launch_drp'+path_sep()+'*', output_dir+path_sep()+'', /recursive, /overwrite
file_copy, compildir+'gpipiperun'+path_sep()+'*', output_dir+path_sep()+'', /recursive, /overwrite
file_copy, compildir+'gpitv'+path_sep()+'*', output_dir+path_sep()+'', /recursive, /overwrite
file_copy, compildir+'automaticreducer'+path_sep()+'*', output_dir+path_sep()+'', /recursive, /overwrite

file_delete, compildir+'launch_drp', /recursive
file_delete, compildir+'gpipiperun', /recursive
file_delete, compildir+'gpitv', /recursive
file_delete, compildir+'automaticreducer', /recursive
file_delete, compildir+'launch_drp.sav'
file_delete, compildir+'gpipiperun.sav'
file_delete, compildir+'gpitv.sav'
file_delete, compildir+'automaticreducer.sav'
;;create directories structure for the DRP
file_mkdir, output_dir+path_sep()+'log',$
            output_dir+path_sep()+'dst',$
            output_dir+path_sep()+'dst'+path_sep()+'pickles',$
            output_dir+path_sep()+'recipe_templates',$
            output_dir+path_sep()+'queue',$
            output_dir+path_sep()+'log',$
            output_dir+path_sep()+'config',$
            output_dir+path_sep()+'config'+path_sep()+'filters'
;;copy DRF templates, etc...            
file_copy, directory+path_sep()+'recipe_templates'+path_sep()+'*.xml', output_dir+path_sep()+'recipe_templates'+path_sep(),/overwrite         
file_copy, directory+path_sep()+'config'+path_sep()+'*.xml', output_dir+path_sep()+'config'+path_sep(),/overwrite   
file_copy, directory+path_sep()+'config'+path_sep()+'*.txt', output_dir+path_sep()+'config'+path_sep(),/overwrite           
file_copy, directory+path_sep()+'config'+path_sep()+'*.dat', output_dir+path_sep()+'config'+path_sep(),/overwrite              
file_copy, directory+path_sep()+'config'+path_sep()+'filters'+path_sep()+'*.fits', output_dir+path_sep()+'config'+path_sep()+'filters'+path_sep(),/overwrite
if file_test(directory+path_sep()+'dst'+path_sep()+'pickles',/dir) eq 1 then $ 
file_copy, directory+path_sep()+'dst'+path_sep()+'pickles'+path_sep()+'*.*t', output_dir+path_sep()+'dst'+path_sep()+'pickles'+path_sep(),/overwrite else $
 print, "**** WARNING Pickles library from the DST is missing..."
file_copy, directory+path_sep()+'gpi.bmp',output_dir+path_sep(),/overwrite

;;remove non-necessary txt file
Result = FILE_SEARCH(output_dir+path_sep()+'*script_source.txt') 
file_delete, Result

message,/info, 'Compilation done.'   
message,/info, "   Output is in "+output_dir




end
