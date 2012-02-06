;-----------------------------------------
; addmsg.pro 2007/04/23
;
; add line(s) to info field
;
; usage : addmsg,infowid,msg
;   infowid = text widget
;   msg = string or array of strings
;
; author : sawada
;
; history: 2007-04-23 add '/update' to avoid blinking
;-----------------------------------------

pro addmsg,infowid,msg

	compile_opt hidden

	geo = widget_info(infowid,/geometry)
	ysz = round(geo.ysize)
	widget_control,infowid,get_value=msg0
	widget_control,infowid,set_value=[msg0,msg],$
		set_text_top_line=max([n_elements([msg0,msg]),ysz])-ysz+1,/update
end

