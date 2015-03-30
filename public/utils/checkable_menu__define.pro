;+
; NAME:  checkable_menu
;
;	Class to provide a nicer interface to a menu with checkable items.
;
;	This is a wrapper for cw_pdmenu_checkable to provide higher level
;	functionality
;
; INPUTS:
;	parent		Parent object (see cw_pdmenu) 
;	menu_desc	Menu description (see cw_pdmenu)
;				bit flag 3 (value 8) indicates an item should be checkable.
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;	Began 2013-08-05 11:38:58 by Marshall Perrin 
;-


function checkable_menu::init, parent, menu_desc, _extra=_extra

	top_menu = cw_pdmenu_checkable(parent, menu_desc, $
                     ids = menu_ids, $
					 _extra=_extra)

	; save menu ids and associated labels for use later for checkboxes.
	; As usual, IDL makes this much harder than it ought to be. Argh.
	self.menu_ids = ptr_new(menu_ids)

	menu_labels = strarr(n_elements(*self.menu_ids))
	for i=0L,n_elements(menu_ids)-1 do begin
	  if widget_info(menu_ids[i],/valid) then begin
		widget_control, menu_ids[i],get_uvalue=label
		menu_labels[i] = label
	  endif
	endfor 
	self.menu_labels = ptr_new(menu_labels)

	return, 1
end

;-----------------------------------
;  checkable_menu::set_check_state
;
;  Check or uncheck an item on the menu
;
pro checkable_menu::set_check_state, name, checkstate

wid = where(*self.menu_labels eq name, count)
if count eq 0 then message,/info, 'Invalid/unknown menu item name: '+name
widget_control,  (*self.menu_ids)[ wid[0] ], set_button=keyword_set(checkstate)

end

;-----------------------------------

pro checkable_menu__define

	self = {checkable_menu,  $
		menu_ids:  ptr_new(),$
		menu_labels:  ptr_new() $
		}


end
