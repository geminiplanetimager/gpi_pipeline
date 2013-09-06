;+
; NAME: cfitshedit__define
;
; PURPOSE:   CFITSHEdit is an object class which implements a
; 	widget viewer window for viewing, and optionally editing,
; 	a FITS header.
;
; 	This code was originally developed as part of OSIRIS QL2 by
; 	Mike McElwain (MWM), subsequently updated by Marshall Perrin
; 	(MDP) and abruptly ripped from its stable existence in QL2 to
; 	become part of GPItv by MDP as well.
;
;
; CALLING SEQUENCE:
;
; 		cfh = obj_new('cfitshedit')
; 		cfh->ViewHeader(filename='SomeFitsFits.fits')
; 		cfh->EditHeader(filename='SomeFitsFits.fits')
; 		 ** or **
; 		cfh->viewHeader(base_id)    where base_id is the ID of a CIMWin window
; 									(a la QL2)
;
;
;
; INPUTS:
;
; OUTPUTS:
;
; EXAMPLE:
;
; NOTES:
; 		The 'save file' code is not FITS extension safe, doesn't even work
; 		well in QL2, and probably won't work at all anywhere else.
;
;
; REVISION HISTORY: 30APR2004 - MWM: wrote class
; 	2007-07-03	MDP: Fix multiple pointer leaks.
; 	2008-10-17  MDP: Made usable in GPItv.
;-



; This file begins with a bunch of event handler routines.
; The actual object class starts way down below about
; four hundred lines or so.
;


pro cfitshedit_base_event, event
; base resize event handler.  adjust size of list

if (tag_names(event, /structure_name) eq 'WIDGET_BASE') then begin
    widget_control, event.top, get_uval=uval
    message,/info, 'resizing header viewer window'

  geom = widget_info(uval.wids.list, /geom)
  ratio_x = (geom.scr_xsize)/geom.xsize*1.5
  ratio_y = (geom.scr_ysize)/geom.ysize*1.5 ;I don't understand this. EMpirical hack alert!

      ; need to convert pixels to lines (for y) and chars for (x)
       widget_control, uval.wids.list, xsize=(event.x-uval.wids.padding[0])/ratio_x
       widget_control, uval.wids.list, ysize=(event.y-uval.wids.padding[1])/ratio_y
	   print, (event.x-uval.wids.padding[0])/ratio_x, (event.y-uval.wids.padding[1])/ratio_y

endif

if tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST' then begin
	cfitshedit_quit_button_event, event, self
;    widget_control, event.top, get_uval=uval
;	if uval.base_id gt 0 then begin ; tell parent window the header window is no longer available.
;	    widget_control, uval.base_id, get_uval=cimwin_uval
;	    cimwin_uval.exist.fitshedit=0L
;	    widget_control, uval.base_id, set_uval=cimwin_uval
;	endif
;    widget_control, event.top, /destroy
endif


end
pro cfitshedit_find_button_event, event

; get uval struct
widget_control, event.top, get_uval=uval
CFitsHedit=*uval.cfitshedit_ptr

; get value in Name field
widget_control, uval.wids.find_field, get_value=find_keyword

; make sure the current name is in capitals
up_find_keyword=strtrim(STRUPCASE(find_keyword),2)

; find where the keyword exists in the header
keyword_exist=CFitsHedit->CheckKeyword(event.top, up_find_keyword)

case keyword_exist of
    1: begin
        widget_control, event.top, get_uval=uval
        index=LONG(uval.keyword_exist_index)
        CFitsHedit->SetSelected, event.top, uval.keyword_exist_index
        CFitsHedit->UpdateList, event.top
    end
    2: begin
        widget_control, event.top, get_uval=uval
        index=LONG(uval.keyword_exist_index)
        CFitsHedit->SetSelected, event.top, uval.keyword_exist_index
        CFitsHedit->UpdateList, event.top
    end
    3: begin
        widget_control, event.top, get_uval=uval
        index=LONG(uval.keyword_exist_index)
        CFitsHedit->SetSelected, event.top, uval.keyword_exist_index
        CFitsHedit->UpdateList, event.top
    end
    else: begin
        message=['The keyword '+up_find_keyword+' does not exist in this header.']
        answer=dialog_message(message, dialog_parent=event.top, /error)
    end
endcase


;if (keyword_exist eq 3) then begin
;    widget_control, event.top, get_uval=uval
;    index=LONG(uval.keyword_exist_index)
;    CFitsHedit->SetSelected, event.top, uval.keyword_exist_index
;    CFitsHedit->UpdateList, event.top
;endif else begin
;    message=['The keyword '+up_find_keyword+' does not exist in this header.']
;    answer=dialog_message(message, dialog_parent=event.top, /error)
;endelse

end
; Header keyword List events.
; History: By MWM.
; 		Coding simplified by MDP 2008-10-13
pro cfitshedit_header_list_event, event

	widget_control, event.top, get_uval=uval
	;widget_control, uval.base_id, get_uval=cimwin_uval
	;
	;CImWin_Obj=*(cimwin_uval.self_ptr)
	;CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())
	CFitsHedit=*uval.cfitshedit_ptr

	; for a click in the list, set new selected item, and update
	; corresponding fields

	; set selected item in uval
	CFitsHedit->SetSelected, event.top, event.index

	; update the fields in view with info from selected item
	CFitsHedit->UpdateFields, event.top

end
pro cfitshedit_line_set_button_event, event

; event handler for when set button is hit.  must get values from
; fields and update header

  ; get uval struct
  widget_control, event.top, get_uval=uval
  ; get value in Name field
  widget_control, uval.wids.name, get_value=newname
  ; get value in value field
  widget_control, uval.wids.value, get_value=newvalue
  ; get value in comment field
  widget_control, uval.wids.comment, get_value=newcomment

  widget_control, uval.base_id, get_uval=cimwin_uval

  CImWin_Obj=*(cimwin_uval.self_ptr)
  CFitsHedit=*(CImWin_Obj->GetFitsHeditObj())

  ; make sure the current name is in capitals
  up_newname=strtrim(STRUPCASE(newname),2)

  ; set new values in uval
  uval.curname=up_newname
  uval.curvalue=newvalue
  uval.curcomment=newcomment
  ; get desired datatype
  uval.curdatatype=widget_info(uval.wids.datatype, /droplist_select)

  ; set uval
  widget_control, event.top, set_uval=uval

  ; if the keyword already exists in the header and is not equal
  ; to 'COMMENT' or 'HISTORY', then just edit the keyword values
  keyword_exist=CFitsHedit->CheckKeyword(event.top, up_newname)

  case keyword_exist of
      0: begin
          ; otherwise, update the line in the fits header
          ; update selected line in header with new values (stored in uval)
          CFitsHedit->UpdateLine, event.top
      end
      1: begin
          ; add a history line
          CFitsHedit->UpdateCommentLine, event.top, 'HISTORY'
      end
      2: begin
          ; add a comment line
          CFitsHedit->UpdateCommentLine, event.top, 'COMMENT'
      end
      3: begin
          print, 'editing existing line'
          ; edit existing line
          CFitsHedit->UpdateLine, event.top, keyword_exist=1
      end
      else:
  endcase

end
pro cfitshedit_modify_button_event, event
; inserts a new line into header with a "blank" template
;
;

	widget_control, event.id, get_value=action
	widget_control, event.top, get_uval=uval
	CFitsHedit=*uval.cfitshedit_ptr



  ; get header
  hd=*(uval.hd_ptr)

case action of
	'Move up': begin
	  ; get selected line
	  line=hd[uval.selected]
	  ; move line above it to current position
	  hd[uval.selected]=hd[uval.selected-1]
	  ; move selected line to one position above
	  hd[uval.selected-1]=line
	  new_hd = hd
	  newselected = uval.selected -1
	end

	'Move down': begin
	  ; get selected line
	  line=hd[uval.selected]
	  ; move line below it to current position
	  hd[uval.selected]=hd[uval.selected+1]
	  ; move selected line to one position below
	  hd[uval.selected+1]=line
	  new_hd = hd
	  newselected = uval.selected +1
	end
	'Move to top': begin
	  ; copy selected line
	  line=hd[uval.selected]
	  ; form a new header, with line moved to top, after reserved keywords.
	  ; remember to remove line from its original position
	  new_hd=[hd[0:uval.num_reserved-1], line, $
			  hd[uval.num_reserved:uval.selected-1], hd[uval.selected+1:*]]
	  newselected = uval.num_reserved
	 end
	'Move to bottom': begin
	  ; copy the selected line
	  line=hd[uval.selected]
	  ; make a new header, with line moved to bottom, just above END
	  ; remember to remove line from original position
	  new_hd=[hd[0:uval.selected-1], hd[uval.selected+1:n_elements(hd)-2], $
										line, hd[n_elements(hd)-1]]
	  newselected = n_elements(hd)-2
	end
	'Insert New': begin
	  ; make a new line template
	  newline="KEYWORD = '                  ' /                               "
	  ; add to header at selected location
	  new_hd=[hd[0:uval.selected-1], newline, hd[uval.selected:*]]
	  newselected = uval.selected
	end
	'Remove': begin
	  ; remove line from list
	  new_hd=[hd[0:uval.selected-1], hd[uval.selected+1:*]]
	  newselected = uval.selected

	end

endcase

  ; update header in uval
  *(uval.hd_ptr)=new_hd
  ;ptr_free,uval.hd_ptr
  ;uval.hd_ptr=ptr_new(new_hd)

  ; set that header has been modified
  uval.modified=1

  ; set uval
  widget_control, event.top, set_uval=uval

  ; update selected position.
  CFitsHedit->SetSelected, event.top, newselected

  ; update list in view
  CFitsHedit->UpdateList, event.top

end


;==============================================================


; 2007-07-03  MDP: 'Cancel' option now works. Fixed pointer leak.
pro cfitshedit_quit_button_event, event, parent_object
; ends program

  ; get uval struct
  widget_control, event.top, get_uval=uval

  if (uval.modified eq 1) then begin
      answer=dialog_message("File has been modified.  Do you wish to save before exiting?", dialog_parent=event.top, /question, /cancel)
	  if (answer eq "Cancel") then return
      if (answer eq "Yes") then begin
          ; save file
          cfitshedit_saveas_button_event, event
	  endif
  endif

  ; if NOT modified **OR** answer eq "No" then we get here:
  	; free pointers for CFitsHedit struct.
  	ptr_free,uval.reserved_ptr,uval.hd_ptr, uval.im_ptr

    ; destroy widget
	
	; The following is now obsolete for gpi - since the gpitv window uses
	; an object handle instead
	;if uval.base_id gt 0 then begin ; tell parent window the header window is no longer available.
	    ;widget_control, uval.base_id, get_uval=cimwin_uval
	    ;cimwin_uval.exist.fitshedit=0L
	    ;widget_control, uval.base_id, set_uval=cimwin_uval
	;endif

    widget_control, event.top, /destroy
	; destroying the window will invoke cfitshedit_cleanup which will
	; destroy the actual cfitshedit object. 




end

;==============================================================

pro cfitshedit_switchhdu_button_event, event

	widget_control, event.id, get_uval=which_hdu
	;print, "Switch to HDU "+strc(which_hdu)

	widget_control, event.top, get_uval=uval

	(*uval.cfitshedit_ptr)->OpenFile, filename = (uval.filename), ext=which_hdu
	


end


;==============================================================


pro cfitshedit_save_button_event, event

; get uval struct
widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=cimwin_uval

CImWin_Obj=*(cimwin_uval.self_ptr)

; get image object
ImObj_ptr=CImWin_Obj->GetImObj()
ImObj=*ImObj_ptr

; get the image and header
filename=ImObj->GetPathFilename()
im_ptr=ImObj->GetData()
im=*im_ptr
hd=*(uval.hd_ptr)

; check the permissions on the path
path=ql_getpath(filename)
permission=ql_check_permission(path)
if (permission eq 1) then begin
    ; write the image to disk
    writefits, filename, im, hd
    ; update the header in the ImObj
    ImObj->SetHeader, uval.hd_ptr
    ; set file not modified
    uval.modified=0
    ; set uval
    widget_control, event.top, set_uval=uval
endif else begin
                err=dialog_message(['Error writing .fits header.', 'Please check path permissions.'], dialog_parent=event.top, /error)
endelse

end
pro cfitshedit_saveas_button_event, event

; get uval struct
widget_control, event.top, get_uval=uval
widget_control, uval.base_id, get_uval=cimwin_uval

CImWin_Obj=*(cimwin_uval.self_ptr)

; get image object
ImObj_ptr=CImWin_Obj->GetImObj()
ImObj=*ImObj_ptr

; get the image and header
filename=ImObj->GetPathFilename()
im_ptr=ImObj->GetData()
im=*im_ptr
hd=*(uval.hd_ptr)

; get new filename
file=dialog_pickfile(/write, group=event.top, filter='*.fits', file=filename)

; if cancel was not hit
if file ne '' then begin
    ; check the permissions on the path
    path=ql_getpath(file)
    permission=ql_check_permission(path)
    if (permission eq 1) then begin
        ; write the image to disk
        writefits, file, im, hd
        ; reset image filename
        ImObj->SetFilename, file
        ; update window title
        widget_control, uval.base_id, tlb_set_title=uval.title_base+": "+file
        ; set file not modified
        uval.modified=0
        ; set uval
        widget_control, event.top, set_uval=uval
        if (file eq filename) then begin
            print, 'file is equal to filename'
            ; update the header in the ImObj
            ImObj->SetHeader, uval.hd_ptr
        endif
    endif else begin
                err=dialog_message(['Error writing .fits header.', 'Please check path permissions.'], $
                                   dialog_parent=event.top, /error)
    endelse
endif

end
;+
; NAME: cfitshedit__define
;
; PURPOSE:
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; OPTIONAL KEYWORD INPUTS:
;
; OUTPUTS:
;
; OPTIONAL OUTPUTS;
;
; EXAMPLE:
;
; NOTES:
;
; PROCEDURES USED:
;
; REVISION HISTORY: 30APR2004 - MWM: wrote class
; 	2007-07-03	MDP: Fix multiple pointer leaks.
;-

function CFitsHedit::Init, winbase_id=cimwin_id, conbase_id=conbase_id

	message,/info, 'initializing fits header viewer/editor'

	; set values of members of object
	if keyword_set(cimwin_id) then self.cimwin_id=cimwin_id
	if keyword_set(conbase_id) then self.conbase_id=conbase_id

	return, 1

end

;--------------------------------------------------------------------------------
pro CFitsHedit::Cleanup
	;print, 'cfitshedit object cleanup'
	; cleanup routine called when the object is destroyed.
	;
	; Invokes window cleanup by destroying the TLB
	if widget_info(self.cfitshedit_id, /valid_id) then widget_control,self.cfitshedit_id,/destroy

	heap_gc
end

pro cfitshedit_cleanup, tlb
	;print, 'cfitshedit window cleanup'
	; this is the cleanup routine called when the TLB is closed
	; Based on DFanning's example at
	; http://www.idlcoyote.com/tip_examples/owindow.pro
	
	Widget_Control, tlb, Get_UValue=uval, /No_Copy
    ptr_free,uval.reserved_ptr,uval.hd_ptr, uval.im_ptr, uval.cfitshedit_ptr
	if obj_valid(uval.self) then obj_destroy, uval.self
	heap_gc

end

;--------------------------------------------------------------------------------

PRO CFitsHedit::ViewHeader,  base_id, _extra=_extra
	; Open a header in read-only mode

	self->EditHeader,  base_id, _extra=_extra, /readonly

end

;--------------------------------------------------------------------------------
pro CFitsHedit::EditHeader, base_id, filename=filename, header=header, extheader=extheader, readonly=readonly, title=title_base
	; create all widgets 
	; open a header (in edir or read only mode)

	if keyword_set(base_id) then widget_control, base_id, get_uval=cimwin_uval else base_id=0L;

  ; create new pointer to image
  im_ptr=ptr_new()
  ; create new pointer to header
  hd_ptr=ptr_new()

  ; create array for possible datatypes (for droplist)
  datatypes=["Boolean", "Integer", "Long", "Float", "Double", "String"]

  ; create widgets
  ; main base widget
  if ~(keyword_set(title_base )) then if keyword_set(readonly) then title_base='FITS Header Viewer' else title_base='FITS Header Editor'

  if keyword_set(filename) then title = title_base+ ": "+file_basename(filename) else title=title_base
  base=widget_base(title=title, /col, xs=850, $
                   /tlb_size_events, group_leader=base_id, $
                   /tlb_kill_request_events)

  ; button base for file control
  file_base=widget_base(base, /row)
  if ~(keyword_set(readonly)) then save_button=widget_button(file_base, value="Save") else save_button=0l
  if ~(keyword_set(readonly)) then saveas_button=widget_button(file_base, value="Save As") else saveas_button=0l
  ; print_button=widget_button(file_base, value="Print")
  quit_button=widget_button(file_base, value="Close")


	; Check if there are multiple HDUs, and if so, set up buttons to switch
	; between them
	if keyword_set(filename) then if  file_test(filename) then begin
		fits_info, filename, n_ext = numext, extname=extnames, /silent
		if (numext EQ 0) then begin
			label_text = widget_label(file_base, value='This FITS file contains only one header in the Primary HDU')
		endif else begin
			hdu_buttons = ptrarr(numext+1)
			label_text = widget_label(file_base, value='View header for:')
			phdu_button=widget_button(file_base, value="Primary HDU", uvalue=0)
			hdu_buttons[0] = ptr_new(phdu_button)
			for i=1L,numext do begin

				hdu_button = widget_button(file_base, value="Ext "+strc(i)+": "+strtrim(extnames[i],2), uvalue=i)
				hdu_buttons[i] = ptr_new(hdu_button)
			endfor 
		endelse



	endif

  ; field to display filename
  if ~(keyword_set(readonly)) then filename_field=widget_text(base) else filename_field=0l

  ; list of keywords
  header_list=widget_list(base, ys=20, xs=80)

  ; base for line editing controls
  line_edit_base=widget_base(base, /col, frame=2)
  line_edit_top_base=widget_base(line_edit_base, /row)
  line_edit_bottom_base=widget_base(line_edit_base, /row)
  ; fields for editing line
  line_name_field=cw_field(line_edit_top_base, title="NAME:", value="", xs=8)
  line_value_field=cw_field(line_edit_top_base, title="VALUE:", value="")
  line_datatype_menu=widget_droplist(line_edit_top_base, title="DATATYPE:", value=datatypes)
  line_comment_field=cw_field(line_edit_bottom_base, title="COMMENT:", value="", xs=50)
  ; set button to update line in list
  tmp_base = widget_base(line_edit_bottom_base, map=~(keyword_set(readonly)),/base_align_center, row=1); ~(keyword_set(readonly)) )
	line_set_button=widget_button(tmp_base, value="SET" )
  find_keyword_field=cw_field(line_edit_bottom_base, title="FIND KEYWORD:", value="", xs=8)
  find_button=widget_button(line_edit_bottom_base, value="FIND")


  ; button base for moving, adding, removing lines
  button_base=widget_base(base, /row, frame=2, map=~(keyword_set(readonly)))
  movetotop_button=widget_button(button_base, value="Move to top")
  moveup_button=widget_button(button_base, value="Move up")
  movedown_button=widget_button(button_base, value="Move down")
  movetobottom_button=widget_button(button_base, value="Move to bottom")
  insert_button=widget_button(button_base, value="Insert New")
  remove_button=widget_button(button_base, value="Remove")


  ; store widget id's in a structure
  wids={name:line_name_field, $
        value:line_value_field, $
        comment:line_comment_field, $
        datatype:line_datatype_menu, $
        set:line_set_button, $
        find_field:find_keyword_field, $
        find:find_button, $
        insert:insert_button, $
        remove:remove_button, $
        movetotop:movetotop_button, $
        movetobottom:movetobottom_button, $
        moveup:moveup_button, $
        movedown:movedown_button, $
        save:save_button, $
        saveas:saveas_button, $
        quit:quit_button, $
        filename:filename_field, $
		padding: [0.0,0.0], $
        list:header_list}


  ; put all accessible info in uval
  uval={self: self, $
	    base_id:base_id, $
  		cfitshedit_ptr: ptr_new(self), $
        im_ptr:im_ptr, $
        hd_ptr:hd_ptr, $
        reserved_ptr:ptr_new(), $
        newpath:'', $
		title_base: title_base, $
        filename:'', $
        savefilename:'', $
        modified:0, $
        fileopen:0, $
        wids:wids, $
        num_reserved:1, $
        bscale:0, $
        bzero:0, $
        selected:0, $
        keyword_exist_index:0, $
        curname:'', $
        curvalue:'', $
        curcomment:'', $
        curdatatype:0}

  ; realize gui and set uval
  widget_control, base, /realize, set_uval=uval

	; set padding around list widget
  geom = widget_info(uval.wids.list, /geom)
  geom2 = widget_info(base, /geom)
  uval.wids.padding = [geom2.xsize-geom.scr_xsize, geom2.ysize- geom.scr_ysize]
  widget_control, base,  set_uval=uval


  ; register events with xmanager
  xmanager, 'cfitshedit_base', base, /no_block, /just_reg, cleanup='cfitshedit_cleanup'
  xmanager, 'cfitshedit_header_list', header_list, /no_block, /just_reg
  xmanager, 'cfitshedit_find_button', find_button, /no_block, /just_reg
  if ~(keyword_set(readonly)) then begin
  xmanager, 'cfitshedit_line_set_button', line_set_button, /no_block, /just_reg
  xmanager, 'cfitshedit_modify_button', button_base, /no_block, /just_reg
  xmanager, 'cfitshedit_save_button', save_button, /no_bloc, /just_reg
  xmanager, 'cfitshedit_saveas_button', saveas_button, /no_bloc, /just_reg
  endif
  xmanager, 'cfitshedit_quit_button', quit_button, /no_bloc, /just_reg
  for i=0L,n_elements(hdu_buttons)-1 do begin
	xmanager, 'cfitshedit_switchhdu_button', *(hdu_buttons[i]), /no_bloc, /just_reg
	ptr_free, hdu_buttons[i]
  endfor 

	;if keyword_set(base_id) then begin
	  	; set that the fitshedit widget has been created
	  	;cimwin_uval.exist.fitshedit=base
  		; set the base uval

  		;widget_control, base_id, set_uval=cimwin_uval
	;endif

	self.cfitshedit_id=base
	; open the header to the image file displayed in the cimwin
	self->OpenFile, filename=filename, header=header

end

;--------------------------------------------------------------------------------
pro CFitsHedit::OpenFile, filename=filename, header=hd, ext=extension

;; get uval struct
widget_control, self.cfitshedit_id, get_uval=uval

if ~(keyword_set(filename)) and ~(keyword_set(hd)) then begin
    ;; OSIRIS QL code - get info from the CIMWin   - MDP mods 2008-10-13
    ;; open a file, make sure it's valid, and update list
    
    widget_control, uval.base_id, get_uval=cimwin_uval
    
    CImWin_Obj=*(cimwin_uval.self_ptr)
    
    ;; get image object
    ImObj_ptr=CImWin_Obj->GetImObj()
    ImObj=*ImObj_ptr
    
    ;; get the image header
    uval.filename=ImObj->GetPathFilename()
    hd=*(ImObj->GetHeader())
endif else if keyword_set(filename) then begin
    if ~file_test(filename) then message, "File "+filename+" does not exist!"
    hd = headfits(filename, ext=extension)
    uval.filename=filename
endif else uval.filename=''
if ~(keyword_set(hd)) then message, "FITS header not loaded!!"

;; get number of keywords in header
num_keywords=n_elements(hd)
;; initialize number of reserved keywords.  variable
;; because of NAXIS1, NAXIS2, ..., NAXISN,
;; where N is number of image axis (value of NAXIS keyword)
num_reserved=4      ; SIMPLE, BITPIX, BSCALE, BZERO... NAXIS to follow
num_reserved=num_reserved+sxpar(hd, "NAXIS")

;; determine where the reserved keywords exist
reserved_elements=-1

for i=0,num_keywords-1 do begin
    ;; extract the keyword from the header
    keyword=strmid(hd[i],0,8)
    case keyword of
        'SIMPLE  ': begin
            if (reserved_elements[0] eq -1) then begin
                reserved_elements[0]=i
            endif else begin
                reserved_elements=[[reserved_elements], [i]]
            endelse
        end
        'XTENSION': begin
            if (reserved_elements[0] eq -1) then begin
                reserved_elements[0]=i
            endif else begin
                reserved_elements=[[reserved_elements], [i]]
            endelse
        end
        'BITPIX  ': begin
            if (reserved_elements[0] eq -1) then begin
                reserved_elements[0]=i
            endif else begin
                reserved_elements=[[reserved_elements], [i]]
            endelse
        end
        'NAXIS   ': begin
            num_axes=sxpar(hd, "NAXIS")
            if (reserved_elements[0] eq -1) then begin
                reserved_elements[0]=i
                for j=0,num_axes-1 do begin
                    reserved_elements=[[reserved_elements], [i+j+1]]
                endfor
            endif else begin
                reserved_elements=[[reserved_elements], [i]]
                for j=0,num_axes-1 do begin
                    reserved_elements=[[reserved_elements], [i+j+1]]
                endfor
            endelse
        end
        'BSCALE  ': begin
            uval.bscale=i
            if (reserved_elements[0] eq -1) then begin
                reserved_elements[0]=i
            endif else begin
                reserved_elements=[[reserved_elements], [i]]
            endelse
        end
        'BZERO   ': begin
            uval.bzero=i
            if (reserved_elements[0] eq -1) then begin
                reserved_elements[0]=i
            endif else begin
                reserved_elements=[[reserved_elements], [i]]
            endelse
        end
        else:
    endcase
endfor

;; set these values in uval
ptr_free, uval.hd_ptr, uval.im_ptr, uval.reserved_ptr
uval.hd_ptr=ptr_new(hd)
uval.im_ptr=ptr_new(im)
uval.reserved_ptr=ptr_new(reserved_elements)
uval.num_reserved=n_elements(reserved_elements)
uval.selected=0
uval.fileopen=1
uval.modified=0

if uval.wids.filename gt 0 then widget_control, uval.wids.filename, set_value=uval.filename
if keyword_set(uval.filename) then begin
    tmp = strpos(uval.filename,path_sep(),/reverse_search)
    if tmp ne -1 then fname = strmid(uval.filename,tmp+1) else fname = uval.filename
    widget_control, self.cfitshedit_id, tlb_set_title=uval.title_base+": "+fname
endif else widget_control, self.cfitshedit_id, tlb_set_title=uval.title_base

;; set uval
widget_control, self.cfitshedit_id, set_uval=uval

;; set selected item in uval
self->SetSelected, self.cfitshedit_id, uval.selected

;; update list
self->UpdateList, self.cfitshedit_id

end

pro CFitsHedit::SetSelected, base_id, index
; set new selected index in uval, and update accessibility on buttons
; accordingly.
; rules imposed:
;   - Reserved keywords cannot be moved
;   - Reserved keywords are not modifyable, except for the value
;       only for BSCALE and BZERO
;   - END keyword cannot be moved (must always be last)
;   - END keyword cannot be modified
;   - Keywords cannot be moved into reserved space
;   - Keywords cannot be moved below END

  ; get uval
  widget_control, base_id, get_uval=uval
  ; get header
  hd=*(uval.hd_ptr)
  ; set index of selected row in uval
  uval.selected=index
  ; set uval
  widget_control, base_id, set_uval=uval

  ; check to see what was selected, and enforce appropiate
  ; control accessibility

  match=where(*(uval.reserved_ptr) eq uval.selected)

  if (match[0] ne -1) then begin
      ; if selected item is one of reserved keywords, disallow all options
      widget_control, uval.wids.insert, sensitive=0
      widget_control, uval.wids.remove, sensitive=0
      widget_control, uval.wids.movetotop, sensitive=0
      widget_control, uval.wids.movetobottom, sensitive=0
      widget_control, uval.wids.moveup, sensitive=0
      widget_control, uval.wids.movedown, sensitive=0
      widget_control, uval.wids.name, sensitive=0
      widget_control, uval.wids.comment, sensitive=0
      widget_control, uval.wids.value, sensitive=0
      widget_control, uval.wids.datatype, sensitive=0
      widget_control, uval.wids.set, sensitive=0
  endif else if (uval.selected eq n_elements(hd)-1) then begin
      ; if selected item is END, disallow all but insert
      widget_control, uval.wids.insert, sensitive=1
      widget_control, uval.wids.remove, sensitive=0
      widget_control, uval.wids.movetotop, sensitive=0
      widget_control, uval.wids.movetobottom, sensitive=0
      widget_control, uval.wids.moveup, sensitive=0
      widget_control, uval.wids.movedown, sensitive=0
      widget_control, uval.wids.name, sensitive=0
      widget_control, uval.wids.value, sensitive=0
      widget_control, uval.wids.comment, sensitive=0
      widget_control, uval.wids.datatype, sensitive=0
      widget_control, uval.wids.set, sensitive=0
  endif else begin
      ; for all others, allow everything else, with some more
      ; restrictions below
      widget_control, uval.wids.insert, sensitive=1
      widget_control, uval.wids.remove, sensitive=1
      widget_control, uval.wids.movetotop, sensitive=1
      widget_control, uval.wids.movetobottom, sensitive=1
      widget_control, uval.wids.moveup, sensitive=1
      widget_control, uval.wids.movedown, sensitive=1
      widget_control, uval.wids.name, sensitive=1
      widget_control, uval.wids.value, sensitive=1
      widget_control, uval.wids.comment, sensitive=1
      widget_control, uval.wids.datatype, sensitive=1
      widget_control, uval.wids.set, sensitive=1
  endelse

  ; enable value editing for bscale and bzero
  if ((uval.selected eq uval.bscale) or $
      (uval.selected eq uval.bzero)) then begin
      widget_control, uval.wids.value, sensitive=1
      widget_control, uval.wids.set, sensitive=1
  endif

  ; don't allow keywords to be moved into reserved space
  if (uval.selected eq uval.num_reserved) then begin
      widget_control, uval.wids.moveup, sensitive=0
      widget_control, uval.wids.movetotop, sensitive=0
  endif

  ; don't allow keywords to be moved below END keyword
  if (uval.selected eq n_elements(hd)-2) then begin
      widget_control, uval.wids.movedown, sensitive=0
      widget_control, uval.wids.movetobottom, sensitive=0
  endif

end

pro CFitsHedit::UpdateFields, base_id

	; updates the line fields (Name, value, comment, datatype) for the
	; selected line

	; get uval struct
	widget_control, base_id, get_uval=uval
	; get header
	hd=*(uval.hd_ptr)

	; initialize comments.  though not supported in this program,
	; comments may be an array, so make this one
	comments=strarr(1)

	;   - COMMENT AND HISTORY keywords are read in without values

	; get current name (always first 8 chars of line)
	uval.curname=strmid(hd[uval.selected], 0, 8)
	; get value using FITS I/O (astron library)
	case strtrim(uval.curname,2) of
		'HISTORY': begin
			value='UNDEFINED'
			comments=sxpar(hd,'HISTORY')
			; find out which history this is
			history_indicies=where(strtrim(strmid(hd[*],0,8),2) eq 'HISTORY')
			index=where(uval.selected eq history_indicies[*])
			comment=comments[index]

		end
		'COMMENT': begin
			value='UNDEFINED'
			comments=sxpar(hd,'COMMENT')
			; find out which comment this is
			comment_indicies=where(strtrim(strmid(hd[*],0,8),2) eq 'COMMENT')
			index=where(uval.selected eq comment_indicies[*])
			comment=comments[index]
		end
		else: begin
			value=sxpar(hd, uval.curname, comment=comments)
			comment=comments[0]
		end
	endcase

	; value is of datatype determined by sxpar. we need to find
	; out what it is.  use idl size() function to do this.
	; the datatype is the second to last item returned from size.
	size_value=size(value)
	datatype=size_value[n_elements(size_value)-2]

	; set the datatype in the uval corresponding to our
	; own mapping of integers to datatypes
	case datatype of
		1: begin                    ; byte / boolean
			uval.curdatatype=0
		end
		2: begin                    ; integer
			uval.curdatatype=1
		end
		3: begin                    ; long
			uval.curdatatype=2
		end
		4: begin                    ; float
			uval.curdatatype=3
		end
		5: begin                    ; double
			uval.curdatatype=4
		end
		else: begin                 ; string
			uval.curdatatype=5
		end
	endcase

	; set new value in uval
	uval.curvalue=string(value)
	; set new comments in uval
	uval.curcomment=comment

	; update values in fields
	widget_control, uval.wids.name, set_value=uval.curname
	widget_control, uval.wids.value, set_value=uval.curvalue
	widget_control, uval.wids.comment, set_value=uval.curcomment
	; set datatype droplist
	widget_control, uval.wids.datatype, set_droplist_select=uval.curdatatype

	; set uval
	widget_control, base_id, set_uval=uval

end

pro CFitsHedit::UpdateLine, base_id, keyword_exist=keyword_exist
; update an entire line in the list

  ; get uval struct
  widget_control, base_id, get_uval=uval
  ; get header
  hd=*(uval.hd_ptr)

  ; make a line template
  newline="        ='                  ' /                               "
  ; put name in line
  strput, newline, uval.curname, 0
  ; put comment in line
  strput, newline, uval.curcomment, 33

  answer='Yes'

  new_keyword=0

  if keyword_set(keyword_exist) then begin
      ; if the keyword is the same as the line that you're on, then
      ; don't remove that keyword
      new_keyword=(uval.selected ne uval.keyword_exist_index)
  endif

  if (new_keyword) then begin

      ; remove the new line that was added to the header
      new_hd=[hd[0:uval.selected-1], hd[uval.selected+1:*]]
      ; update header in uval
	  ptr_free, uval.hd_ptr
      uval.hd_ptr=ptr_new(new_hd)
      widget_control, base_id, set_uval=uval
      ; re-get header
      hd=*(uval.hd_ptr)

      ; find out where the new keyword exist index is
      if (uval.selected lt uval.keyword_exist_index) then begin
          uval.keyword_exist_index=uval.keyword_exist_index-1
      endif

      ; go to the line where this keyword exists
      self->SetSelected, base_id, uval.keyword_exist_index
      self->UpdateList, self.cfitshedit_id
      uval.selected=uval.keyword_exist_index

      ; see if the user intentionally tried to change this value
      message=['This keyword already exists.', $
               'Do you want to update the fields in that record?']
      answer=dialog_message(message, dialog_parent=base_id, /question)
  endif else begin
      ; update selected line in header with new line
      hd[uval.selected]=newline
  endelse

  ; cast new value to appropiate datatype
  case uval.curdatatype of
      0: begin  ; byte / boolean
          value=(byte(uval.curvalue))[0]
      end
      1: begin  ; integer
          value=fix(uval.curvalue)
      end
      2: begin  ; long
          value=long(fix(uval.curvalue))
      end
      3: begin  ; float
          value=float(uval.curvalue)
      end
      4: begin  ; double
          value=double(uval.curvalue)
      end
      else: begin ; string
          value=uval.curvalue
      end
  endcase

  if (answer eq 'Yes') then begin
  ; update line using FITS I/O tools (astron library)
  ; this makes sure the value is properly formatted
      sxaddpar, hd, uval.curname, value, uval.curcomment
  endif

  ; set header in uval
  *(uval.hd_ptr)=hd

  ; set that header has been modified
  uval.modified=1

  ; set uval
  widget_control, base_id, set_uval=uval

  ; update list in view
  self->UpdateList, base_id

end


pro CFitsHedit::UpdateCommentLine, base_id, value
	; update a comment line in the list

	  ; get uval struct
	widget_control, base_id, get_uval=uval
	  ; get header
	hd=*(uval.hd_ptr)

	case strtrim(value,2) of
		'HISTORY': begin
			; add the history line to the header
			; make a line template
			newline="                                                              "
			; put name in line
			strput, newline, uval.curname, 0
			; put comment in line
			strput, newline, uval.curcomment, 9
			; update selected line in header with new line
			hd[uval.selected]=newline
		end
		'COMMENT': begin
			; add the comment line to the header
			; make a line template
			newline="                                                              "
			; put name in line
			strput, newline, uval.curname, 0
			; put comment in line
			strput, newline, uval.curcomment, 9
			; update selected line in header with new line
			hd[uval.selected]=newline
		end
		else: begin
		end
	endcase

	; set header in uval
	*(uval.hd_ptr)=hd

	; set that header has been modified
	uval.modified=1

	; set uval
	widget_control, base_id, set_uval=uval

	; update list in view
	self->UpdateList, base_id

end


pro CFitsHedit::UpdateList, base_id
	; updates the list in the widget_list

	; get uval struct
	widget_control, base_id, get_uval=uval
	; get header
	hd=*(uval.hd_ptr)

	; save the current top of the list in view
	list_top=widget_info(uval.wids.list, /list_top)

	; set list in view
	widget_control, uval.wids.list, set_value=hd
	; reset the top of the list
	widget_control, uval.wids.list, set_list_top=list_top
	; reset the selected item
	widget_control, uval.wids.list, set_list_select=uval.selected

	; update the line fields, since selected may have changed
	self->UpdateFields, base_id

end

function CFitsHedit::CheckKeyword, base_id, up_newname
; updates the list in the widget_list
  ; get uval struct
  widget_control, base_id, get_uval=uval
  ; get header
  hd=*(uval.hd_ptr)

  case (up_newname[0]) of
      'HISTORY': begin
          ; check the fits header to see if this keyword already exists, and
          ; start at the current header line
          nheader=n_elements(hd)
          if (uval.keyword_exist_index+1 le nheader-1) then start=uval.keyword_exist_index+1
          for i=start,nheader-1 do begin
              keyword=strtrim(strmid(hd[i],0,8),2)
              if (keyword eq up_newname[0]) then begin
                  uval.keyword_exist_index=i
                  widget_control, base_id, set_uval=uval
                  return, 1
              endif
          endfor
          for i=0,uval.keyword_exist_index do begin
              keyword=strtrim(strmid(hd[i],0,8),2)
              if (keyword eq up_newname[0]) then begin
                  uval.keyword_exist_index=i
                  widget_control, base_id, set_uval=uval
                  return, 1
              endif
          endfor
      end
      'COMMENT': begin
          ; check the fits header to see if this keyword already exists, and
          ; start at the current header line
          nheader=n_elements(hd)
          if (uval.keyword_exist_index+1 le nheader-1) then start=uval.keyword_exist_index+1
          for i=start,nheader-1 do begin
              keyword=strtrim(strmid(hd[i],0,8),2)
              if (keyword eq up_newname[0]) then begin
                  uval.keyword_exist_index=i
                  widget_control, base_id, set_uval=uval
                  return, 2
              endif
          endfor
          for i=0,uval.keyword_exist_index do begin
              keyword=strtrim(strmid(hd[i],0,8),2)
              if (keyword eq up_newname[0]) then begin
                  uval.keyword_exist_index=i
                  widget_control, base_id, set_uval=uval
                  return, 2
              endif
          endfor
      end
      else: begin
          ; check the fits header to see if this keyword already exists
          nheader=n_elements(hd)
          for i=0,nheader-1 do begin
              keyword=strtrim(strmid(hd[i],0,8),2)
              if (keyword eq up_newname[0]) then begin
                  uval.keyword_exist_index=i
                  widget_control, base_id, set_uval=uval
                  return, 3
              endif
          endfor
      endelse
  endcase

  return, 0

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  BEGIN CIMAGE WINDOW ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function CImWin::GetFitsHeditId
	return, self.cfitshedit_id
end

pro CImWin::SetFitsHeditId, newFitsHeditId
	self.cfitshedit_id=newFitsHeditId
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  END CIMAGE WINDOW ACCESSOR/MUTATOR FUNCTIONS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro CFitsHedit__define

; create a structure that holds an instance's information
struct={cfitshedit, $
        cimwin_id:0L, $
        conbase_id:0L, $
        cfitshedit_id:0L $
       }

end
