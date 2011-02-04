;---------------------------------------------------------------------
;
;Jerome Maire - Universite de Montreal - 13.01.2011
;---------------------------------------------------------------------

;--------------------------------------
PRO makedatalogfile::cleanup
; Kill top-level base if it still exists
if (xregistered ('makedatalogfile')) then widget_control, self.base_id, /destroy
end

; simple wrapper to call object routine
PRO makedatalogfile_event, ev
    widget_control,ev.top,get_uvalue=storage
   
    if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
end

;-------------------------------------------------------------------
pro makedatalogfile::event, ev

;common filestateF

widget_control,ev.id,get_uvalue=uval
case tag_names(ev, /structure_name) of
  'WIDGET_BUTTON':begin
        case uval of 
                'changedir':begin
                    dir = DIALOG_PICKFILE(PATH=self.scandir, Title='Choose directory to scan...',/must_exist , /directory)
                    if dir ne '' then widget_control, self.scan_id, set_value=dir
                    if dir ne '' then self.scandir=dir
                end
                'changeoutdir':begin
                    dir = DIALOG_PICKFILE(PATH=self.outdir, Title='Choose directory to deposit logfile...',/must_exist , /directory)
                    if dir ne '' then widget_control, self.out_id, set_value=dir
                    if dir ne '' then self.outdir=dir
                end
                'filespec':begin
                    widget_control, self.spec_id, get_value=spec
                    self.filespec=spec
                end
                'gpiexclusive':begin                  
                  self.gpiexclu=widget_info(self.gpiexclusive_id,/button_set)
                end
                'scan':begin                
                  directory=self.scandir
                   outdir=self.outdir
                  
                  ; Find all FITS files
                   filespec=self.filespec
                  filenames = file_search(directory+filespec)
                  maxlen = max(strlen(filenames))
                
                tlb = widget_base(/col,/tlb_frame_attr)
            
                 label='Scanning '+directory+' ...'
                 id = CW_PROGRESS(    self.base_id,                 $
                       LABEL = LABEL,          $
                       ;BG_COLOR = bg_color,    $
                       ;UNAME = uname,          $
                       VALUE = 0.,          $
                       UVALUE = 'progr',        $
                       ;RED = RED,              $
                       ;GREEN = GREEN,          $
                       BLUE = 1 ,            $
                       ;YELLOW = YELLOW,        $
                       ;PURPLE = purple,        $
                       ;XSIZE = xsize,          $
                       ;YSIZE = ysize,          $
                       ;FRAME = frame,          $
                       ;XOFFSET = 40,      $
                       ;YOFFSET = 40,      $
                       OBJ_REF = o      )
                       
                       widget_control,tlb,/realize
                      widget_control,id,set_uvalue = o
                      xmanager,'test_progress',tlb,/no_block
                       
                       nf=n_elements(filenames)
                  ; load all headers into an array
                  for i=0l,n_elements(filenames)-1 do begin
                    if ~(keyword_set(silent)) then print,filenames[i]
                    h = headfits(filenames[i])
                    if self.gpiexclu eq 0 then hdrconcat,hdrs,h
                    if self.gpiexclu eq 1 then begin
                        if strmatch(sxpar(h, 'INSTRUME'), '*GPI*') then hdrconcat,hdrs,h
                    endif
                    WIDGET_CONTROL,id,set_value =float(i+1)/float(nf)
                  endfor 
                
                  
                  keys = ['INSTRUME','OBJECT', 'DISPERSR', 'FILTER', 'LYOTMASK', 'APODIZ', 'EXPTIME', 'TIME-OBS', 'FILETYPE']
                  formats=['A-20', 'A-20',  'A-8',     'A-4',    'A-5',      'A-8',    'F-8.2',   'A-12'    , 'A-20']
                
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
                  forprint2, textout=outdir+"gpi_log.txt", filenames, *vals[0], *vals[1], *vals[2], *vals[3], *vals[4], *vals[5], *vals[6], *vals[7], $
                    format=formatstr, $
                    comment= headerstr
                 
                  o->set_property,label = 'Output is being directed to a file '+outdir+"gpi_log.txt"
                  WIDGET_CONTROL, id, /DESTROY 
                
                end
                'quit':begin
                widget_control, self.base_id, /destroy
                end
                else:
          endcase  
          end    
   else:    
endcase
end



;----------------------------------------------
function makedatalogfile::init_widgets, _extra=_Extra
self.base_id  = widget_base(title = 'Make Data Log File', $
                   /row,  $
                   ;app_mbar = top_menu, $
                   ;uvalue = 'GPItv_base', $
                   /tlb_size_events)

but = WIDGET_BASE( self.base_id,/COLUMN)
text=WIDGET_label(but, value='This widget will create a data log file (gpi_log.txt).')
;;directory to scan
scanbase = Widget_Base(but, UNAME='specbase' ,row=1 , frame=0)
button_id = WIDGET_label(scanbase,Value='Choose directory to scan:',XSIZE=200,frame=0)
self.dirinit=getenv('GPI_RAW_DATA_DIR')
self.scan_id = WIDGET_TEXT(scanbase,Value=self.dirinit,Uvalue='scandir',XSIZE=50)
button_id = WIDGET_BUTTON(scanbase,Value='Change...',Uvalue='changedir')
;;directory for output
outbase = Widget_Base(but, UNAME='outbase' ,row=1 , frame=0)
button_id = WIDGET_label(outbase,Value='Where to put the logfile:',frame=0,XSIZE=200)
self.out_id = WIDGET_TEXT(outbase,Value=self.dirinit,Uvalue='outdir',XSIZE=50)
button_id = WIDGET_BUTTON(outbase,Value='Change...',Uvalue='changeoutdir')
;;Wildcard file specification to include:
specbase = Widget_Base(but, UNAME='specbase' ,row=1 , frame=0)
button_id = WIDGET_label(specbase,Value='Wildcard file specification to include:',frame=0,XSIZE=250)
self.spec_id = WIDGET_TEXT(specbase,Value=self.filespec, /editable,Uvalue='filespec',XSIZE=20)
;;Exclude non-GPI data:
gpiexclusivebase = Widget_Base(but, UNAME='exclubase' ,COLUMN=1 ,/NONEXCLUSIVE, frame=0)
self.gpiexclusive_id =    Widget_Button(gpiexclusivebase, UNAME='gpiexclusive'  $
      ,/ALIGN_LEFT ,VALUE='Exclude non-GPI data',uvalue='gpiexclusive' )
      widget_control, self.gpiexclusive_id, /set_button 
      self.gpiexclu=1
;;scan
button_id = WIDGET_BUTTON(but,Value='Scan',Uvalue='scan')
button_id = WIDGET_BUTTON(but,Value='Quit',Uvalue='quit')


   group=''
    proj=''
    storage={$;info:info,fname:fname,$
    ;    rb:rb,$
       ; splitptr:splitptr,$
        group:group,proj:proj, $
        self: self}
  ;self.widget_log = info
    widget_control,self.base_id  ,set_uvalue=storage,/no_copy
 
 return, self.base_id 
end

;--------------------------------------------------
pro makedatalogfile::init_data, _extra=_Extra
;cd, current=dirini
;self.dirinit=dirini
self.scandir=getenv('GPI_RAW_DATA_DIR')
self.outdir=getenv('GPI_RAW_DATA_DIR')
self.filespec='*.{fts,fits}*'

end
;-------------------------------------------------
function makedatalogfile::init, groupleader, _extra=_extra

self->init_data, _extra=_extra
   ; WIDGET_CONTROL, /HOURGLASS
  logbase = self->init_widgets(_extra=_Extra)

; Realize the widgets and run XMANAGER to manage them.
; Register the widget with xmanager if it's not already registered
if (not(xregistered('makedatalogfile', /noshow))) then begin
    WIDGET_CONTROL, logbase, /REALIZE
    XMANAGER, 'makedatalogfile', logbase, /NO_BLOCK ;, cleanup = 'FITSGET_shutdown'
endif
   ; filename = (*ptr).filename
    ;WIDGET_CONTROL, stateF.wtFITS, /DESTROY
    RETURN, 1;filename

END


;-----------------------
pro makedatalogfile__define
  
stateF={  makedatalogfile, $
    dirinit:'',$ ;initial root  directory 
    scandir:'',$ 
    outdir:'',$ 
    filespec:'',$ 
    gpiexclu:0L,$
    gpiexclusive_id :0L,$ 
    scan_id:0L,$ 
    out_id:0L,$ 
    spec_id:0L,$ 
    base_id:0L $;,$   ;wid id tree
          } ;

end