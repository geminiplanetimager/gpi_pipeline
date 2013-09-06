;---------------------------------------------------------------------
;FITSGET.PRO
;
;A pseudo DIALOG_PICKFILE using a simpler search method for unix&windows.
;Searches for files with extension .fts, .fits, .FTS, .FITS.
;Detect new fits file in chosen folder
;Can execute a command passed in parameter when click on fits file
;
;
;Procedure is based on a method from David Fanning's
;http://www.dfanning.com/programs/textbox.pro
;contribution:Jon Aymon University of California Berkeley August 2005
;
;Jerome Maire - Universit� de Montr�al - 28.10.2008
;---------------------------------------------------------------------
PRO FITSGETinit

Common filestateF, stateF

cd, current=dirini
maxnewfiles=300
stateF={  dirinit:dirini,$ ;initial root  directory for the tree
		commande:'gpitve',$  	;command to execute when fits file double clicked
		wtTree:0L,$  	;wid id tree
		wtFITS:0L,$		;wid id  main base
		wtCrown:0L,$	;wid id root
		wtFolder:0L,$	;;wid id sub-directories
		wtNode:0L,$		;wid id fits file
		listfile_id:0L,$;wid id for list of fits file
		listdir_id:0L,$ ;wid id for list of dir (right top panel)
		alwaysexecute_id:0L,$ ;wid id for automatically execute commande 
		alwaysexecute:0,$
		currdir:'',$	;current directory in the tree
		ptr2:PTR_NEW(),$	;; Pointer and structure for folder and filename (left pan).
		listcontent:STRARR(10),$  ;list of directories chosen for fits detection
		maxnewfile:maxnewfiles,$
		newlist:STRARR(maxnewfiles),$	;list of new files (Pan RightDown)
		kill:0,$ ;flag to stop bridge detec loop when quitting with search 'on'
		isnewdirroot:0,$ ;flag for  root dir
		button_id:0L}	;wid for detect-new-files button

end


PRO FITS_NODE, event

; Event handler for node (FITS file) in the folder and FITS file tree.

  WIDGET_CONTROL, event.ID, GET_VALUE=Value
  WIDGET_CONTROL, event.ID, GET_UVALUE=comstr
; Person has selected this FITS file. Check for double-click.

  IF event.CLICKS EQ 2 THEN BEGIN

; Get directory containing FITS file
       folder = ''
       folder = (*comstr.ptr).folder
       fitsfile = ''
       fitsfile = Value
       (*comstr.ptr).filename = folder + fitsfile
       WIDGET_CONTROL, event.Top, /DESTROY
  ENDIF

END



;-------------------------------------------------


pro FITS_LIST, event

common filestateF

;Double-clik: send direcctory in right-top panel
 IF (where(strmatch(TAG_NAMES(event),'clicks',/FOLD_CASE)) ne -1) && (event.CLICKS EQ 2) && (strlen(stateF.currdir) ne 0) THEN BEGIN

ii=0 ;number of directories in panel Right top
while stateF.listcontent(ii) ne '' do ii+=1

;check if current dir in tree is not already chosen in Right top panel
ind=where(strcmp(stateF.listcontent,stateF.currdir))
if ind eq -1 then begin
stateF.listcontent(ii) = stateF.currdir
widget_control, stateF.listdir_id, SET_VALUE= stateF.listcontent
endif
 ENDIF ELSE BEGIN
 ; Find folders and FITS files in parent directory.
; Return if there are already children of this widget.

    children = 0
    children = WIDGET_INFO (event.ID, /CHILD )

    IF children GT 0 THEN RETURN

    result=''
    result = WIDGET_INFO (event.ID, /TREE_EXPANDED)
    ;IF Result EQ 1 THEN RETURN

; Stop the flashing.
   ; WIDGET_CONTROL, event.ID, UPDATE=0

    WIDGET_CONTROL, event.ID, GET_UVALUE = comstr
    WIDGET_CONTROL, event.ID, GET_VALUE = folder
    thisfolder = folder

if stateF.isnewdirroot ge 1 then begin
CASE !VERSION.OS_FAMILY OF  ;exit
   'Windows'   : begin
					folders = GET_DRIVE_LIST()
   				end
  	ELSE     :
ENDCASE

	stateF.isnewdirroot=0
endif else begin
; Search for folders in 'folder'.
    folder = thisfolder
    string2 = folder + '*'
    folders = FILE_SEARCH (string2, /TEST_DIRECTORY, /MARK_DIRECTORY)

endelse
    testf = SIZE ( folders, /DIMENSIONS )
    IF ( testf GT 0 ) THEN BEGIN
        nfolders = SIZE (folders, /N_ELEMENTS)

;  Loop over folders
;stop
        FOR ifolder = 0, nfolders - 1 DO BEGIN
            folder = folders [ifolder]
            (*comstr.ptr).folder = folder
            stateF.wtFolder = WIDGET_TREE (event.ID, $
                                    VALUE = folder, $
                                    UVALUE = comstr, $
                                    /FOLDER, $
                                    ;/EXPANDED, $
                                    EVENT_PRO = 'FITS_LIST'$
                                    ;DRAGGABLE = 1,$
                                    ;DRAG_NOTIFY='Callback_drag',$
                                     ;/DROP_EVENTS
                                     )
        ENDFOR
        WIDGET_CONTROL, event.ID, SET_TREE_EXPANDED = 1

    ENDIF

; Search for FITS files in this directory.
    folder = thisfolder
    stateF.currdir=folder
    (*comstr.ptr).folder = folder
    filetypes = '*.{fts,fits}'
    string3 = folder + filetypes
    fitsfiles = FILE_SEARCH (string3,/FOLD_CASE)
    testf = SIZE ( fitsfiles, /DIMENSIONS)
    IF ( testF GT 0 ) THEN BEGIN
        nfitsfiles = SIZE (fitsfiles, /N_ELEMENTS)
; Loop over fits files
        FOR ifitsfile = 0, nfitsfiles - 1 DO BEGIN
            fitsfile = fitsfiles [ifitsfile]
; Strip off directories.
            result = STRPOS ( fitsfile, PATH_SEP(), /REVERSE_SEARCH )
            fitsname = STRMID ( fitsfile, result + 1 )
            stateF.wtNode = WIDGET_TREE (event.ID, $
                                  VALUE = fitsname, $
                                  UVALUE = comstr, $
                                  EVENT_PRO = 'FITS_NODE')
        ENDFOR
        WIDGET_CONTROL, event.ID, SET_TREE_EXPANDED = 1
    ENDIF

ENDELSE
END
;-------------------------------------------
pro FITS_NODE, event
;if where(strmatch(TAG_NAMES(event),'clicks',/FOLD_CASE)) ne -1 then $
;print, 'clicks=', event.clicks
common filestateF

;what to do when click on a fits file (left panel):
if event.clicks eq 2 then begin

 widget_CONTROL, widget_INFO(stateF.wtTree,/TREE_SELECT), GET_VALUE=valgpitv
 widget_CONTROL, widget_INFO(widget_INFO(stateF.wtTree,/TREE_SELECT),/PARENT), GET_VALUE=ind
 CALL_PROCEDURE, stateF.commande,ind+valgpitv
endif

end

;-------------------------------------------
pro NEW_LIST, event
common filestateF
;what to do when click on a fits file (right panel):
if event.clicks eq 2 then begin
	ind=widget_INFO(stateF.listfile_id,/LIST_SELECT)

	print, stateF.newlist(ind)
	CALL_PROCEDURE, stateF.commande,stateF.newlist(ind)
endif


 end


;-------------------------------------------

pro up_event, event
common filestateF
; Pointer and structure for folder and filename.
    folder = ""
    filename = ""
    newdir=stateF.dirinit
;check if not windows root dir.
stateF.isnewdirroot=0
CASE !VERSION.OS_FAMILY OF  ;exit

   'Windows'   : begin
   					Drive_list = GET_DRIVE_LIST()
   					for i=0,n_elements(Drive_list)-1 do begin
						 if (strcmp(Drive_list(i),newdir)) || (strcmp('',newdir)) then  stateF.isnewdirroot=stateF.isnewdirroot+1
   					endfor
   				end
   	   ELSE      : begin
						 if (strcmp(path_sep(),newdir))  then  stateF.isnewdirroot=stateF.isnewdirroot+1

   					end
ENDCASE

;create the pointer related to the tree root
PTR_FREE, stateF.ptr2

if stateF.isnewdirroot eq 0 then begin
;remove the last folder from the current dir.name
    result = STRPOS ( STRMID(newdir,0,STRLEN(newdir)-2), PATH_SEP(), /REVERSE_SEARCH )
            newdir = STRMID ( newdir,0, result+1  )
            ptr = PTR_NEW ( { folder:file_search(newdir, /mark_directory), filename:"" } )
endif else begin
CASE !VERSION.OS_FAMILY OF  ;exit
   'Windows'   : begin
   						newdir=''
						ptr = PTR_NEW ( { folder:"", filename:"" } )
   				end
   	ELSE:		begin
						 	newdir=''
						ptr = PTR_NEW ( { folder:path_sep(), filename:"" } )
   				end
ENDCASE

endelse


    comstr = { ptr:ptr }

    WIDGET_CONTROL, stateF.wtFITS, SET_UVALUE=comstr
folder = (*comstr.ptr).folder

WIDGET_CONTROL,stateF.wtCrown,/DESTROY
  stateF.wtCrown = WIDGET_TREE(stateF.wtTree, $
                          VALUE = folder, $
                          /FOLDER, $
                          ;/EXPANDED, $
                          UVALUE = comstr, $
                          EVENT_PRO = 'FITS_LIST' )
;widget_control,stateF.wtCrown,SET_VALUE=folder,SET_TREE_EXPANDED=0
stateF.dirinit=folder
stateF.ptr2=ptr

end

;-------------------------------------------
pro button_event, event
common filestateF
val=''
widget_control,stateF.button_id,GET_VALUE=val

	ii=0
	while stateF.listcontent(ii) ne '' do ii+=1

if ii eq 0 then begin
	void=dialog_message('No directory selected for fits searching. Add directories from the tree left-panel.')
	return
endif else begin
	if where(strcmp(val,'Search most-recent fits files')) eq -1 then begin
	widget_control,stateF.button_id,SET_VALUE='Search most-recent fits files'
	endif ELSE begin
	widget_control,stateF.button_id,SET_VALUE='Stop search'


nn=0
for i=0,ii-1 do begin ;find nb files to consider in order
	folder=stateF.listcontent(i)  ;to create the fitsfileslist array
	filetypes = '*.{fts,fits}'
    string3 = folder + filetypes
    fitsfiles =FILE_SEARCH (string3,/FOLD_CASE)
    nn=nn+(n_elements(fitsfiles))
endfor
fitsfileslist =STRARR(nn)

n=0	;list of files in fitsfileslist
for i=0,ii-1 do begin
	folder=stateF.listcontent(i)
	filetypes = '*.{fts,fits}'
    string3 = folder + filetypes
    fitsfiles =FILE_SEARCH (string3,/FOLD_CASE)
    fitsfileslist(n:n+n_elements(fitsfiles)-1) =fitsfiles
    n=n+ n_elements(fitsfiles)
endfor

; retrieve creation date
date=dblarr(n_elements(fitsfileslist))
    for j=0,n_elements(date)-1 do begin
    Result = FILE_INFO(fitsfileslist(j) )
    date(j)=Result.ctime
    endfor
;sort files with creation date
    list2=fitsfileslist(REVERSE(sort(date)))
    list3=list2(0:n_elements(list2)-1)
widget_control, stateF.listfile_id, SET_VALUE= list3 ;display the list
;stop
stateF.newlist=list3[0:(n_elements(list3)-1)<(stateF.maxnewfile-1)]
;;loop for detection of new files
  oBridge = OBJ_NEW('IDL_IDLBridge', CALLBACK='callback_searchnewfits')
  oBridge->SetVar,"chang",0
  oBridge->SetVar,"dir",stateF.listcontent(0:ii-1)
  oBridge->SetVar,"listfile",list3
  oBridge->SetVar,"list_id",stateF.listfile_id
  oBridge->SetVar,"exec",stateF.alwaysexecute
  oBridge->SetVar,"commande",stateF.commande
  ;widget_control,stateF.button_id,GET_VALUE=val
  widget_control,stateF.button_id,GET_VALUE=val
  oBridge->SetVar,"button_value",val

comm2="chang=detectnewfits(dir,listfile,list_id,button_value)"
oBridge->Execute, comm2, /NOWAIT

	endelse
endelse
end
;-------------------------------------------------------------------
pro FITSFILE_EVENT, event

common filestateF

widget_control,event.id,get_uvalue=uval
if (size(uval,/tname) ne 'UNDEFINED') && (uval eq 'alwaysexec') then begin
 stateF.alwaysexecute=widget_info(stateF.alwaysexecute_id,/button_set)
endif else begin
   ;remove double-clicked directory in list of directories checked
  if  event.clicks eq 2 then begin
  	select=widget_INFO(stateF.listdir_id,/LIST_SELECT)
  	for ii=select, n_elements(stateF.listcontent)-2 do stateF.listcontent(ii)=stateF.listcontent(ii+1)
  stateF.listcontent(n_elements(stateF.listcontent)-1) = ''
  widget_control, stateF.listdir_id, SET_VALUE= stateF.listcontent
  endif

endelse
end

;--------------------------------------
pro FITSGET_shutdown, windowid

; routine to kill the FITSGET window and clear variables to conserve
; memory when quitting FITSGET.  The windowid parameter is used when
; GPItv_shutdown is called automatically by the xmanager, if FITSGET is
; killed by the window manager.

common filestateF
;stop
;trick to end the bridge detect loop when quitting FITSGET
stateF.kill=1

; Kill top-level base if it still exists
if (xregistered ('FITSFILE')) then widget_control, stateF.wtFITS, /destroy




return
end

;----------------------------------------------
;-------------------------------------------------
PRO FITSGET, command
; Retrieve a FITS filename.

common filestateF
FITSGETinit
if n_params() eq 1 then stateF.commande=command

    WIDGET_CONTROL, /HOURGLASS

stateF.wtFITS = widget_base(title = 'FITSGET', $
                   /row,  $
                   ;app_mbar = top_menu, $
                   ;uvalue = 'GPItv_base', $
                   /tlb_size_events)
;; Create a group leader.
;    groupleader = WIDGET_BASE( MAP = 0 )
;    WIDGET_CONTROL, groupleader, /REALIZE
;
;; Create a modal base widget.
;    stateF.wtFITS = WIDGET_BASE( GROUP_LEADER=groupleader, $
;                          ;/MODAL, $
;                          /ROW, $
;                          TITLE="Select a fits file to view ")

but = WIDGET_BASE( stateF.wtFITS,/COLUMN)
stateF.button_id = WIDGET_BUTTON(but,Value='Up',EVENT_PRO='Up_event')

; Pointer and structure for folder and filename.
    folder = ""
    filename = ""

    ptr = PTR_NEW ( { folder:file_search(stateF.dirinit, /mark_directory), filename:"" } )
    comstr = { ptr:ptr }
    stateF.ptr2=ptr

    WIDGET_CONTROL, stateF.wtFITS, SET_UVALUE=comstr

; Create a widget tree of folders and FITS files.

    WIDGET_CONTROL, stateF.wtFITS, GET_UVALUE = comstr
    folder = (*comstr.ptr).folder

; The first tree widget has the top-level base as its parent.
; The visible tree widget branches and leaves will all be
; descendants of this tree widget.

    stateF.wtTree = WIDGET_TREE(stateF.wtFITS, $
                         UVALUE = 'wtTree', $
                         SCR_XSIZE = 420, $
                         SCR_YSIZE = 640)

; Tree crown.
    stateF.wtCrown = WIDGET_TREE(stateF.wtTree, $
                          VALUE = folder, $
                          /FOLDER, $
                          ;/EXPANDED, $
                          UVALUE = comstr, $
                          EVENT_PRO = 'FITS_LIST' )


;
wtFITSr = WIDGET_BASE( stateF.wtFITS, $
                          /COLUMN)
 void = WIDGET_LABEL(wtfitsr,Value='Directories to search for new fits file detection:')
  void = WIDGET_LABEL(wtfitsr,Value='(Add and drag directories from the tree left-panel)')
  void = WIDGET_LABEL(wtfitsr,Value='(double-click to remove directory)')
stateF.listdir_id = WIDGET_LIST(wtFITSr,YSIZE=8)

stateF.button_id = WIDGET_BUTTON(wtFITSr,Value='Search most-recent fits files',EVENT_PRO='button_event')
void = WIDGET_LABEL(wtfitsr,Value='Most-recent fits files:')
void = WIDGET_LABEL(wtfitsr,Value='(double-click to start:'+stateF.commande+')')

stateF.listfile_id = WIDGET_LIST(wtFITSr,YSIZE=30,EVENT_PRO = 'NEW_LIST')
  alwaysexebase = Widget_Base(wtFITSr, UNAME='alwaysexebase' ,COLUMN=1 ,/NONEXCLUSIVE, frame=0)
stateF.alwaysexecute_id =    Widget_Button(alwaysexebase, UNAME='alwaysexecute'  $
      ,/ALIGN_LEFT ,VALUE='Automatically execute '+stateF.commande,uvalue='alwaysexec' )

 if stateF.alwaysexecute eq 1 then widget_control, stateF.alwaysexecute_id, /set_button     
; Realize the widgets and run XMANAGER to manage them.
; Register the widget with xmanager if it's not already registered
if (not(xregistered('FITSFILE', /noshow))) then begin
    WIDGET_CONTROL, stateF.wtFITS, /REALIZE
    XMANAGER, 'FITSFILE', stateF.wtFITS, /NO_BLOCK, cleanup = 'FITSGET_shutdown'
endif
   ; filename = (*ptr).filename
    ;WIDGET_CONTROL, stateF.wtFITS, /DESTROY
    ;RETURN, 0;filename

END

;--------------
;END FITSGET.PRO
;--------------
