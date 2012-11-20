;;  **********   DRP compiler   **************
;; Here are the commands that will compile the DRP code 
;; and produce executables.
;; Execute gpi_compiler command directly within the IDL command line. 
;; Set the gpitvdir keyword to compile also GPITV.
;; Set execoutputdir to define where the executables will be produced.
;; 2012-11-19: JM
pro gpi_compiler, compildir, drpdirectory=drpdirectory, gpitvdir=gpitvdir

  if N_params() EQ 0 then begin ;Prompt for directory of produced executables?
  compildir = ' ' 
        read,'Enter name of procedure you want a copy of: ',compildir    
  
  endif
if keyword_set(drpdirectory) then directory=drpdirectory else $
directory=getenv('GPI_DRP_DIR')

list = FILE_SEARCH(directory,'[A-Za-z]*.pro',count=cc, FULLY_QUALIFY_PATH =0 )

cg=0 & gpitvroutine=""
if keyword_set(gpitvdir) then gpitvroutine=FILE_SEARCH(gpitvdir,'[A-Za-z]*.pro',count=cg) else $
  print," *****  GPITV will NOT be compiled."

if (directory eq "") OR (cc eq 0) OR (cg eq 0) then begin
  print,"You need to properly define the DRP directory (and GPItv dir). Use the drpdirectory and gpitvdir keywords or set the GPI_DRP_DIR environment variable. "
  return
end

totlist = [list, gpitvroutine]
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
          i+=1 ;do not compile this guy
      endif else begin   ; need to order routines (for common block definition)
          routine=totlist[i]
          totlist=[totlist, routine]
          totlist[i]=totlist[i-1] ;just put an already compiled function so no problem occurs
      endelse 
   ENDIF 
 
print, " n_elements(totlist)=", n_elements(totlist)

for i=0, n_elements(totlist)-1 do begin
    if (~strmatch(totlist[i], "*deprecated*",/fold)) and (i lt nelem+50) then $
    RESOLVE_ROUTINE, FILE_BASENAME(totlist[i],".pro"), /COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE
endfor
print, " n_elements(totlist)=", n_elements(totlist), "  last function compiled i=",i

resolve_all, /continue

CATCH,/CANCEL

compildir += path_sep()
if file_test(compildir,/dir) eq 0 then spawn, 'mkdir ' + compildir

SAVE, /ROUTINES, FILENAME = compildir+'launch_drp.sav' 
; create the executables
MAKE_RT, 'launch_drp', compildir, savefile=compildir+'launch_drp.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32

SAVE, /ROUTINES, FILENAME = compildir+'gpipiperun.sav' 
MAKE_RT, 'gpipiperun', compildir, savefile=compildir+'gpipiperun.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32

SAVE, /ROUTINES, FILENAME = compildir+'automaticreducer.sav' 
MAKE_RT, 'automaticreducer', compildir, savefile=compildir+'automaticreducer.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32

SAVE, /ROUTINES, FILENAME = compildir+'gpitv.sav' 
MAKE_RT, 'gpitv', compildir, savefile=compildir+'gpitv.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32




file_mkdir, compildir+'pipeline'
;;put all files in the same dir
file_copy, compildir+'launch_drp'+path_sep()+'*', compildir+'pipeline'+path_sep()+'', /recursive, /overwrite
file_copy, compildir+'gpipiperun'+path_sep()+'*', compildir+'pipeline'+path_sep()+'', /recursive, /overwrite
file_copy, compildir+'gpitv'+path_sep()+'*', compildir+'pipeline'+path_sep()+'', /recursive, /overwrite
file_copy, compildir+'automaticreducer'+path_sep()+'*', compildir+'pipeline'+path_sep()+'', /recursive, /overwrite

file_delete, compildir+'launch_drp', /recursive
file_delete, compildir+'gpipiperun', /recursive
file_delete, compildir+'gpitv', /recursive
file_delete, compildir+'automaticreducer', /recursive
file_delete, compildir+'launch_drp.sav'
file_delete, compildir+'gpipiperun.sav'
file_delete, compildir+'gpitv.sav'
file_delete, compildir+'automaticreducer.sav'
;;create directories structure for the DRP
file_mkdir, compildir+'pipeline'+path_sep()+'log',$
            compildir+'pipeline'+path_sep()+'dst',$
            compildir+'pipeline'+path_sep()+'dst'+path_sep()+'pickles',$
            compildir+'pipeline'+path_sep()+'recipe_templates',$
            compildir+'pipeline'+path_sep()+'drfqueue',$
            compildir+'pipeline'+path_sep()+'log',$
            compildir+'pipeline'+path_sep()+'config',$
            compildir+'pipeline'+path_sep()+'config'+path_sep()+'filters'
;;copy DRF templates, etc...            
file_copy, drpdirectory+path_sep()+'recipe_templates'+path_sep()+'*.xml', compildir+'pipeline'+path_sep()+'recipe_templates'+path_sep(),/overwrite         
file_copy, drpdirectory+path_sep()+'config'+path_sep()+'*.xml', compildir+'pipeline'+path_sep()+'config'+path_sep(),/overwrite   
file_copy, drpdirectory+path_sep()+'config'+path_sep()+'*.txt', compildir+'pipeline'+path_sep()+'config'+path_sep(),/overwrite           
file_copy, drpdirectory+path_sep()+'config'+path_sep()+'*.dat', compildir+'pipeline'+path_sep()+'config'+path_sep(),/overwrite              
file_copy, drpdirectory+path_sep()+'config'+path_sep()+'filters'+path_sep()+'*.fits', compildir+'pipeline'+path_sep()+'config'+path_sep()+'filters'+path_sep(),/overwrite
if file_test(drpdirectory+path_sep()+'dst'+path_sep()+'pickles',/dir) eq 1 then $ 
file_copy, drpdirectory+path_sep()+'dst'+path_sep()+'pickles'+path_sep()+'*.*t', compildir+'pipeline'+path_sep()+'dst'+path_sep()+'pickles'+path_sep(),/overwrite else $
 print, "**** WARNING Pickles library from the DST is missing..."
file_copy, drpdirectory+path_sep()+'gpi.bmp',compildir+'pipeline'+path_sep(),/overwrite

;;remove non-necessary txt file
Result = FILE_SEARCH(compildir+'pipeline'+path_sep()+'*script_source.txt') 
file_delete, Result

print, 'Compilation done.'   




end