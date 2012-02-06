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
;
; 	2012-02-06 MDP: Added print to screen and error checking on widget id
;-----------------------------------------

pro addmsg,infowid,msg

	compile_opt hidden

	; Always print to screen too?
	print, msg

	; Watch out for invalid widgets? 
	if infowid eq 0 then return

	geo = widget_info(infowid,/geometry)
	ysz = round(geo.ysize)
	widget_control,infowid,get_value=msg0
	widget_control,infowid,set_value=[msg0,msg],$
		set_text_top_line=max([n_elements([msg0,msg]),ysz])-ysz+1,/update
end

