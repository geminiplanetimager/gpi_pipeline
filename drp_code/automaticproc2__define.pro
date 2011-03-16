;---------------------------------------------------------------------
;automaticproc__define.PRO
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
;Jerome Maire - Universite de Montreal - 15.01.2011
;---------------------------------------------------------------------

pro automaticproc2::run
    self.launcher = obj_new('launcher',/pipeline)
dir=self.dirinit
;ii=0
;while self.listcontent(ii) ne '' do ii+=1
;listfile=self.listcontent[0:ii-1]


    ;; old file list
         folder=dir
         filetypes = '*.{fts,fits}'
        string3 = folder + path_sep() + filetypes
        oldlistfile =FILE_SEARCH(string3,/FOLD_CASE)
    
        dateold=dblarr(n_elements(oldlistfile))
        for j=0,n_elements(oldlistfile)-1 do begin
        Result = FILE_INFO(oldlistfile[j] )
        dateold[j]=Result.ctime
        endfor
               list3=oldlistfile[REVERSE(sort(dateold))]
              widget_control, self.listfile_id, SET_VALUE= list3[0:(n_elements(list3)-1)<(self.maxnewfile-1)] ;display the list
              ;stop
              

;stop
while self.continue_scanning eq 1 do begin
chang=''
   ; ii=n_elements(dir)
    
    ;nn=0
    ;for i=0,ii-1 do begin ;find nb files to consider in order
;      folder=dir ;to create the fitsfileslist array
;      filetypes = '*.{fts,fits}'
;        string3 = folder + path_sep() + filetypes
;        fitsfiles =FILE_SEARCH(string3,/FOLD_CASE)
;        nn=nn+(n_elements(fitsfiles))
;    ;endfor
;    fitsfileslist =STRARR(nn)
    
   ; n=0 ;list of files in fitsfileslist
   ; for i=0,ii-1 do begin
      folder=dir
      filetypes = '*.{fts,fits}'
        string3 = folder + path_sep() + filetypes
        fitsfileslist =FILE_SEARCH(string3,/FOLD_CASE)
      ;  fitsfileslist(n:n+n_elements(fitsfiles)-1) =fitsfiles
      ;  n=n+ n_elements(fitsfiles)
    ;endfor
    
    ; retrieve creation date
      datefile=dblarr(n_elements(fitsfileslist))
        for j=0,n_elements(datefile)-1 do begin
        Result = FILE_INFO(fitsfileslist[j] )
        datefile[j]=Result.ctime
        endfor
    ;sort files with creation date
        list2=fitsfileslist[REVERSE(sort(datefile))]
       ; list3=list2(0:n_elements(list2)-1)
    

    ;;compare old and new file list
    if (max(datefile) gt max(dateold)) || (n_elements(datefile) gt n_elements(dateold)) then begin
      ;chang=1
      ;oldlistfile=list2
      lastdate= max(datefile,maxind)
      chang=fitsfileslist[maxind]
      dateold=datefile
    endif
 
    if chang ne '' then begin
          widget_control, self.listfile_id, SET_VALUE= list2[0:(n_elements(list2)-1)<(self.maxnewfile-1)] ;display the list
          ;check if the file has been totally copied
          self.parserobj=gpiparsergui( chang,  mode=self.parsemode)
    endif
    ;print, chang
    for i=0,9 do begin
    wait,0.1
          ;if obj_valid(self.progressbar) then begin
        self->checkEvents
        if ~(self->checkQuit()) then begin
          message,/info, "User pressed QUIT on the progress bar!"

          break
          ;exit
        endif
    endfor    
endwhile
;return, chang
;obj_destroy,self
end

PRO automaticproc2::checkevents
; this routine is used to MANUALLY process events
; to avoid having to use the whole XMANAGER etc code,
; that doesn't play well with a main() loop in the backbone code 
; that runs forever 

res = widget_event(self.wtFITS,/nowait)
if xregistered ('drfgui')   then res = widget_event((self.parserobj).drfbase,/nowait, bad_id=badid)

end
function automaticproc2::checkquit
 
  return, self.continue_scanning
end

;;-------------------------------------------------
;pro callback_searchnewfits2, status, error, $
;   oBridge, userdata
;
;;common filestateF
;
;listcontent=userdata.lc
;killi=userdata.ki
;listfile_id=userdata.lfid
;button_id=userdata.bid
;
;;;check if fidget still exist
;if killi eq 1 then return
;;stop
;;;change the list if new files detected
;change = oBridge->GetVar("chang")
;if change eq 1 then begin
;print, 'new file detected'
;listfile = oBridge->GetVar("listfile")
;widget_control, listfile_id, SET_VALUE= listfile ;display the list
;;;start commande if desired:
;exec = oBridge->GetVar("exec")
;commande = oBridge->GetVar("commande")
;mode = oBridge->GetVar("mode")
;if exec eq 1 then CALL_PROCEDURE, commande,listfile[0], mode=mode
;endif
;
;;check if user ended the detection
;
;if widget_info(button_id, /valid_id) eq 1 then begin
;widget_control,button_id,GET_VALUE=val
;    if where(strcmp(val,'Search most-recent fits files')) eq -1 then begin
;      ;check if no user change in directories
;      ii=0
;      while listcontent(ii) ne '' do ii+=1
;      oBridge->SetVar,"dir",listcontent(0:ii-1)
;    
;      ;go for new detection
;      comm2="chang=detectnewfits(dir,listfile,list_id,button_value)"
;      oBridge->Execute, comm2, /NOWAIT
;    
;    endif else begin
;    OBJ_DESTROY, oBridge
;    print, 'end bridge'
;    
;       ;iStatus =oBridge->Status(ERROR=estr)
;       ;print, estr
;    endelse
;endif else begin
;OBJ_DESTROY, oBridge
;print, 'end bridge'
;
;   ;iStatus =oBridge->Status(ERROR=estr)
;   ;print, estr
;endelse
;
;end

;pro FITS_LIST, event
;
;;common filestateF
;
;
;END
;-------------------------------------------
;pro FITS_NODE, event
;;if where(strmatch(TAG_NAMES(event),'clicks',/FOLD_CASE)) ne -1 then $
;;print, 'clicks=', event.clicks
;;common filestateF
;
;end

;-------------------------------------------
;pro NEW_LIST, event
;;common filestateF
;;what to do when click on a fits file (right panel):
;if tag_names(event, /structure_name) ne 'WIDGET_TRACKING' then begin
;  
;endif
;
; end


;-------------------------------------------

;pro up_event, event
;;common filestateF
;; Pointer and structure for folder and filename.
;  
;end

;;-------------------------------------------
;pro button_event, event
;;common filestateF
;
;end



; simple wrapper to call object routine
PRO automaticprocess_event, ev
    widget_control,ev.top,get_uvalue=storage
   
    if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
end

;-------------------------------------------------------------------
pro automaticproc2::event, ev

;common filestateF

widget_control,ev.id,get_uvalue=uval
case tag_names(ev, /structure_name) of
 ; Mouse-over help text display:
      'WIDGET_TRACKING': begin 
        if (ev.ENTER EQ 1) then begin 
              case uval of 
                  'wtTree':textinfo='Browse directories. Double-click to add directory for automatic fits detection.'+ $
                                    'Double-click on Fits file for parsing it.'
                  'Up':textinfo='Click to add the parent directory of the tree root directory.'
                  'listdir':textinfo='Double-click on a repertory to remove it from the list.'  
                  'search':textinfo='Start the looping search of new FITS placed in the right-top panel directories. Restart the detection for changing search parameters.'
                  'newlist':textinfo='List of detected most-recent Fits files in the repertories. '
                  'alwaysexec':textinfo='Automatic launch of the parser for every new detected FITS file.' 
                  'one':textinfo='Parse and process new file in a one-by-one mode.'
                  'new':textinfo='Change parser queue to process when new type detected.'
                  'keep':textinfo='keep all detected files in parser queue.'
                  'flush':textinfo='Delete all files in the parser queue.'
                  "QUIT":textinfo='Click to close this window.'
              else:textinfo=' '
              endcase
              widget_control,self.information_id,set_value=textinfo
          ;widget_control, event.ID, SET_VALUE='Press to Quit'   
        endif else begin 
              widget_control,self.information_id,set_value=''
          ;widget_control, event.id, set_value='what does this button do?'   
        endelse 
        return
    end
      
  'WIDGET_BUTTON':begin
  
      if (uval eq 'one') || (uval eq 'new') || (uval eq 'keep') then begin
          if widget_info(self.parseone_id,/button_set) then self.parsemode=1
          if widget_info(self.parsenew_id,/button_set) then self.parsemode=2
          if widget_info(self.parseall_id,/button_set) then self.parsemode=3
      endif
      if uval eq 'flush' then begin
      ;stop
       ;if obj_valid('parsergui') then parsergui->cleanfilelist
        self.parserobj=gpiparsergui(/cleanlist)
      endif
      
     if uval eq 'alwaysexec' then begin
    ;if (tag_names(ev, /str) ne 'WIDGET_TREE_SEL') then begin
     self.alwaysexecute=widget_info(self.alwaysexecute_id,/button_set)
    endif
    
              if uval eq 'QUIT'    then begin
                  if confirm(group=ev.top,message='Are you sure you want to close the Parser GUI?',$
                      label0='Cancel',label1='Close', title='Confirm close') then begin
                              self.continue_scanning=0
                              ;wait, 1.5
                              ;obj_destroy, self
                   endif           
                 endif
 end ;widget_button

'WIDGET_LIST':begin
      if uval eq 'listdir' then begin

         ;remove double-clicked directory in list of directories checked
        if  ev.clicks eq 2 then begin
          select=widget_INFO(self.listdir_id,/LIST_SELECT)
          for ii=select, n_elements(self.listcontent)-2 do self.listcontent(ii)=self.listcontent(ii+1)
        self.listcontent(n_elements(self.listcontent)-1) = ''
        widget_control, self.listdir_id, SET_VALUE= self.listcontent
        endif
    
      endif
     if uval eq 'newlist' then begin
            if event.clicks eq 2 then begin
              ind=widget_INFO(self.listfile_id,/LIST_SELECT)
            
              print, self.newlist(ind)
              CALL_PROCEDURE, self.commande,self.newlist(ind),mode=self.parsemode
            endif
     endif
  end
  
    else:   
endcase
end

;--------------------------------------
;pro FITSGET_shutdown, windowid
PRO automaticproc2::cleanup
; routine to kill the FITSGET window and clear variables to conserve
; memory when quitting FITSGET.  The windowid parameter is used when
; GPItv_shutdown is called automatically by the xmanager, if FITSGET is
; killed by the window manager.

;common filestateF
;stop
;trick to end the bridge detect loop when quitting FITSGET
;self.kill=1

; Kill top-level base if it still exists
if (xregistered ('automaticprocess')) then widget_control, self.wtFITS, /destroy
if (xregistered ('drfgui') gt 0) then    widget_control,(self.parserobj).drfbase,/destroy
  self->parsergui::cleanup ; will destroy all widgets

  ;heap_gc


if obj_valid(self.launcher) then begin
    self.launcher->queue, 'quit' ; kill the other side of the link, too
    obj_destroy, self.launcher ; kill this side.
  endif
  
  
  obj_destroy, self

end

;----------------------------------------------
function automaticproc2::init_widgets, _extra=_Extra, session=session
self.wtFITS = widget_base(title = 'Simple automatic processing', $
                   /column,  $
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
;self.wtFITS2 = WIDGET_BASE( self.wtFITS,/row)
;but = WIDGET_BASE( self.wtFITS2,/COLUMN)
;self.button_id = WIDGET_BUTTON(but,Value='Up',Uvalue='Up', /tracking_events);,EVENT_PRO='Up_event')

; Pointer and structure for folder and filename.
;    folder = ""
;    filename = ""
;
;    ptr = PTR_NEW ( { folder:file_search(self.dirinit, /mark_directory), filename:"" } )
;    comstr = { ptr:ptr }
;    self.ptr2=ptr
;
;    WIDGET_CONTROL, self.wtFITS, SET_UVALUE=comstr
;
;; Create a widget tree of folders and FITS files.
;
;    WIDGET_CONTROL, self.wtFITS, GET_UVALUE = comstr
;    folder = (*comstr.ptr).folder
;
;; The first tree widget has the top-level base as its parent.
;; The visible tree widget branches and leaves will all be
;; descendants of this tree widget.
;
;    self.wtTree = WIDGET_TREE(self.wtFITS2, $
;                         UVALUE = 'wtTree', $
;                         SCR_XSIZE = 420, $
;                         SCR_YSIZE = 440, /tracking_events)
;
;; Tree crown.
;    self.wtCrown = WIDGET_TREE(self.wtTree, $
;                          VALUE = folder, $
;                          /FOLDER, $
;                          ;/EXPANDED, $
;                          UVALUE = comstr);, $
;                          ;EVENT_PRO = FITS_LIST )
;

;
;wtFITSr = WIDGET_BASE( self.wtFITS2, $
;                          /COLUMN)
                          wtFITSr =self.wtFITS
; void = WIDGET_LABEL(wtfitsr,Value='Directories to search for new fits file detection:')
;  void = WIDGET_LABEL(wtfitsr,Value='(Add directories from the tree left-panel)')
;  void = WIDGET_LABEL(wtfitsr,Value='(double-click to remove directory)')
;self.listdir_id = WIDGET_LIST(wtFITSr,YSIZE=8,Uvalue='listdir', /tracking_events)

void = WIDGET_LABEL(wtfitsr,Value='Scanned directory: '+self.dirinit, /align_left)
if self.alwaysexecute then void = WIDGET_LABEL(wtfitsr,Value='Parser mode: Parse every new fits file.' , /align_left) else $
void = WIDGET_LABEL(wtfitsr,Value='Parser mode: Do not parse new fits file.' , /align_left)
case self.parsemode of 
 1:parmode='Parse and process new file in a one-by-one mode.'
 2:parmode='Change parser queue to process when new type detected.'
 3:parmode='keep all detected files in parser queue.'
endcase 
void = WIDGET_LABEL(wtfitsr,Value='Parser mode: '+parmode , /align_left)

void = WIDGET_LABEL(wtfitsr,Value='Most-recent fits files:')
;void = WIDGET_LABEL(wtfitsr,Value='(double-click to start:'+self.commande+')')
;self.button_id = WIDGET_BUTTON(wtFITSr,Value='Search most-recent fits files',Uvalue='search', /tracking_events)

self.listfile_id = WIDGET_LIST(wtFITSr,YSIZE=20 , /tracking_events,uvalue='newlist')
;  alwaysexebase = Widget_Base(wtFITSr, UNAME='alwaysexebase' ,COLUMN=1 ,/NONEXCLUSIVE, frame=0)
;self.alwaysexecute_id =    Widget_Button(alwaysexebase, UNAME='alwaysexecute'  $
;      ,/ALIGN_LEFT ,VALUE='Automatically execute '+self.commande,uvalue='alwaysexec' , /tracking_events)
;  if self.alwaysexecute eq 1 then widget_control, self.alwaysexecute_id, /set_button   
;  
;   
;  void = WIDGET_LABEL(wtfitsr,Value='Parser mode:')    
;parsebase = Widget_Base(wtFITSr, UNAME='parsebase' ,COLUMN=1 ,/EXCLUSIVE, frame=0)
;self.parseone_id =    Widget_Button(parsebase, UNAME='one'  $
;      ,/ALIGN_LEFT ,VALUE='Parse one-by-one',uvalue='one' , /tracking_events)
;self.parsenew_id =    Widget_Button(parsebase, UNAME='new'  $
;      ,/ALIGN_LEFT ,VALUE='Flush filenames when new filetype',uvalue='new' , /tracking_events)
;self.parseall_id =    Widget_Button(parsebase, UNAME='keep'  $
;      ,/ALIGN_LEFT ,VALUE='Keep all files',uvalue='keep' , /tracking_events) 
;       case self.parsemode of
;        1:  widget_control, self.parseone_id, /set_button 
;        2:  widget_control, self.parsenew_id, /set_button  
;        3:  widget_control, self.parseall_id, /set_button  
;       endcase              
button_id = WIDGET_BUTTON(wtFITSr,Value='Flush parser filenames',Uvalue='flush', /tracking_events)

    button3=widget_button(wtFITSr,value="Close GUI",uvalue="QUIT", /tracking_events)
    
     self.information_id=widget_label(self.wtFITS,uvalue="textinfo",xsize=800,value='  ')

   group=''
    proj=''
    storage={$;info:info,fname:fname,$
    ;    rb:rb,$
       ; splitptr:splitptr,$
        group:group,proj:proj, $
        self: self}
  ;self.widget_log = info
    widget_control,self.wtFITS ,set_uvalue=storage,/no_copy
 
 return, self.wtFITS  
end
; simple wrapper to call object routine
PRO blocking_example_event, ev
    widget_control,ev.top,get_uvalue=storage

    if size(storage,/tname) eq 'STRUCT' then storage.self->blocking_example_event2, ev else storage->blocking_example_event2, ev
end
PRO AUTOMATICPROC2::blocking_example_event2, event 
   ; The following call blocks only if the NO_BLOCK keyword to 
   ; XMANAGER is set: 
   widget_control,event.id,get_uvalue=uval
   
    if uval eq 'changedir' then begin
                    dir = DIALOG_PICKFILE(PATH=self.dirinit, Title='Choose directory to scan...',/must_exist , /directory)
                    if dir ne '' then widget_control, self.scandir_id, set_value=dir
                    if dir ne '' then self.dirinit=dir
    endif
   
   if uval eq 'Start' then begin
        self.alwaysexecute=widget_info(self.alwaysexecute_id,/button_set)
          if widget_info(self.parseone_id,/button_set) then self.parsemode=1
          if widget_info(self.parsenew_id,/button_set) then self.parsemode=2
          if widget_info(self.parseall_id,/button_set) then self.parsemode=3
          widget_control,event.top,/destroy
   endif
;    if uval eq 'Quit'    then begin
;                  if confirm(group=event.top,message='Are you sure you want to close the Parser GUI?',$
;                      label0='Cancel',label1='Close', title='Confirm close') then obj_destroy, self
;    endif
   
   
END 

;--------------------------------------------------
pro automaticproc2::init_data, _extra=_Extra
dirini=getenv('GPI_RAW_DATA_DIR')
if dirini eq '' then cd, current=dirini
self.dirinit=dirini
self.maxnewfile=60
self.commande='gpiparsergui'
;self.newlist=strarr(300)
self.alwaysexecute=1
self.parsemode=2
 self.continue_scanning=1

base = widget_base(title = 'Parameters for automatic processing',/column)

void= widget_label(base,Value='Scanned directory:')
self.scandir_id = WIDGET_TEXT(base,Value=self.dirinit,Uvalue='scandir',XSIZE=50)
button_id = WIDGET_BUTTON(base,Value='Change scanned directory...',Uvalue='changedir')

alwaysexebase = Widget_Base(base, UNAME='alwaysexebase' ,COLUMN=1 ,/NONEXCLUSIVE, frame=0)
self.alwaysexecute_id =    Widget_Button(alwaysexebase, UNAME='alwaysexecute'  $
      ,/ALIGN_LEFT ,VALUE='Automatically execute '+self.commande,uvalue='alwaysexec' )
  if self.alwaysexecute eq 1 then widget_control, self.alwaysexecute_id, /set_button   
  
   
  void = WIDGET_LABEL(base,Value='Parser mode:')    
parsebase = Widget_Base(base, UNAME='parsebase' ,COLUMN=1 ,/EXCLUSIVE, frame=0)
self.parseone_id =    Widget_Button(parsebase, UNAME='one'  $
      ,/ALIGN_LEFT ,VALUE='Parse one-by-one',uvalue='one' )
self.parsenew_id =    Widget_Button(parsebase, UNAME='new'  $
      ,/ALIGN_LEFT ,VALUE='Flush filenames when new filetype',uvalue='new' )
self.parseall_id =    Widget_Button(parsebase, UNAME='keep'  $
      ,/ALIGN_LEFT ,VALUE='Keep all files',uvalue='keep' ) 
       case self.parsemode of
        1:  widget_control, self.parseone_id, /set_button 
        2:  widget_control, self.parsenew_id, /set_button  
        3:  widget_control, self.parseall_id, /set_button  
       endcase              
;button_id = WIDGET_BUTTON(wtFITSr,Value='Flush parser filenames',Uvalue='flush', /tracking_events)

    button3=widget_button(base,value="Start",uvalue="Start")
   ;  button3=widget_button(base,value="Quit",uvalue="Quit")
WIDGET_CONTROL,base, /REALIZE 



 storage={self: self}
  ;self.widget_log = info
    widget_control,base ,set_uvalue=storage,/no_copy
 
XMANAGER,'blocking_example', base;, /NO_BLOCK 

end
;-------------------------------------------------
function automaticproc2::init, groupleader, _extra=_extra
; Retrieve a FITS filename.
;setenv_gpi
while gpi_is_setenv() eq 0 do begin
      obj=obj_new('setenvir')
      obj_destroy, obj
endwhile

;common filestateF
;FITSGETinit
;if n_params() eq 1 then stateF.commande=command
self->init_data, _extra=_extra
   ; WIDGET_CONTROL, /HOURGLASS
  
  fitsbase = self->init_widgets(_extra=_Extra)

; Realize the widgets and run XMANAGER to manage them.
; Register the widget with xmanager if it's not already registered
if (not(xregistered('automaticprocess', /noshow))) then begin
    WIDGET_CONTROL, fitsbase, /REALIZE
    XMANAGER, 'automaticprocess', fitsbase, /NO_BLOCK ;, cleanup = 'FITSGET_shutdown'
endif


   ; filename = (*ptr).filename
    ;WIDGET_CONTROL, stateF.wtFITS, /DESTROY
    RETURN, 1;filename

END


;-----------------------
pro automaticproc2__define
  ;Common filestateF, stateF



stateF={  automaticproc2, $
    dirinit:'',$ ;initial root  directory for the tree
    commande:'',$   ;command to execute when fits file double clicked
    scandir_id:0L,$ 
    launcher: obj_new(), $
    continue_scanning:0, $
   ; wtTree:0L,$   ;wid id tree
    wtFITS:0L,$   ;wid id  main base
    parserobj:obj_new(),$
;     wtFITS2:0L,$
;    wtCrown:0L,$  ;wid id root
;    wtFolder:0L,$ ;;wid id sub-directories
;    wtNode:0L,$   ;wid id fits file
    listfile_id:0L,$;wid id for list of fits file
    listdir_id:0L,$ ;wid id for list of dir (right top panel)
    alwaysexecute_id:0L,$ ;wid id for automatically execute commande 
    alwaysexecute:0,$
    parseone_id :0L,$
    parsenew_id :0L,$
    parseall_id :0L,$
    parsemode:0L,$
    information_id:0L,$
    currdir:'',$  ;current directory in the tree
    ptr2:PTR_NEW(),$  ;; Pointer and structure for folder and filename (left pan).
    listcontent:STRARR(10),$  ;list of directories chosen for fits detection
    maxnewfile:0L,$
    newlist:STRARR(300),$ ;list of new files (Pan RightDown)
  ;  kill:0,$ ;flag to stop bridge detec loop when quitting with search 'on'
    isnewdirroot:0,$ ;flag for  root dir
    button_id:0L,$
    INHERITS parsergui} ;wid for detect-new-files button

end