;-----------------------------------------
; confirm.pro 2007/05/14
;
; usage : variable = confirm(parent,message,label0,label1)
;
; create pop-up confirmation dialog with 'message' and 
; return 0 or 1 corresponding to button named 'label0' or 'label1'.
;
; author : N.Ikeda & sawada
;
; history : 2007-04-02 window & button sizes enlarged
;           2007-05-14 enlarged window size again
;-----------------------------------------

;event handler for pop-up confirmation dialog
;-----------------------------------------
pro confirm_event,ev
	compile_opt hidden

	;get type of event
	;-----------------------------------------
	widget_control,ev.id,get_uvalue=uval

	widget_control,ev.top,get_uvalue=storage

	;event handler
	;-----------------------------------------
	case uval of
		0	: begin
			(*storage.ptr).flag=0
		end
		1	: begin
			(*storage.ptr).flag=1
		end
	endcase

	widget_control,ev.top,/destroy

end

function confirm,group_leader=groupleader,message=msg,label0=label0,label1=label1, title=title
	compile_opt hidden

	;create pop-up dialog
	;-----------------------------------------

	if ~(keyword_set(title)) then title="Confirmation"
	dialog=widget_base(title=title, $
		Group_leader=groupleader,/modal,/column)

	;create confirmation message and button
	;-----------------------------------------
	label=widget_label(dialog, value="")
	for i=0,n_elements(msg)-1 do label=widget_label(dialog,value=msg[i])
	label=widget_label(dialog, value="")


	buttons = widget_base(dialog, /grid_layout,/row)
	space = widget_label(buttons,value=" ")
	confcancel=widget_button(buttons,value=label0,uvalue=0, $
		xsize=80,ysize=30,xoffset=65)
	space = widget_label(buttons,value=" ")
	confexit=widget_button(buttons,value=label1,uvalue=1, $
		xsize=80,ysize=30,xoffset=230)
	space = widget_label(buttons,value=" ")

	;show pop-up confirmation 
	;-----------------------------------------w
	widget_control,dialog,/realize

	;make data storage to send data to event handler
	;-----------------------------------------
	ptr=ptr_new({flag:1})
	storage={ptr:ptr}

	;store storage
	;-----------------------------------------
	widget_control,dialog,set_uvalue=storage,/no_copy

	;event loop
	;-----------------------------------------
	xmanager,'confirm',dialog

	result=(*ptr).flag
	ptr_free,ptr

	return,result

end
