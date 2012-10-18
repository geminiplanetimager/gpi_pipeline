;+
;  gpi_showpaths
;
;  Utility GUI for showing GPI environment variables
;
; HISTORY:
;    2012-10-10 MP: Major fork and rework, from setenvir__define.pro
;
;-


PRO gpi_showpaths_event, ev
    widget_control,ev.top,get_uvalue=storage
    if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
end

;-------------------------------------------------------------------
pro gpi_showpaths::event, ev

widget_control,ev.id,get_uvalue=uval
if ~(keyword_set(uval)) then uval = '  '
case tag_names(ev, /structure_name) of
 ; Mouse-over help text display:
      'WIDGET_TRACKING': begin 
        if (ev.ENTER EQ 1) then begin 
              case uval of              
                  'GID':textinfo='Working directory.'
                  'GPD':textinfo='Directory of the Data Reduction Pipeline (DRP).'
                  'GPLD':textinfo='Directory where the DRP will place reduction log file.'  
                  'GDTD':textinfo='Directory of templates reduction sequences (usually in the DRP directory, \drf_templates)'
                  'GQD':textinfo='Directory of DRF queue. The DRP will scan this directory'
                  'GCF' :textinfo='Directory of user-config files (usually in the DRP directory, \config).' 
                  'GRDD' :textinfo='Directory of raw data'
                  'GDOD':textinfo='Directory of DRP processed output data.'
                  'Save envir. var.':textinfo='Save these environment variables to an IDL .sav file for future use.'
                  'Restore envir. var.':textinfo='Restore saved environment variables from an IDL .sav file.'
                  'Ok':textinfo='Set environment variables to these values.'
				  'Exit': textinfo='Exit this dialog.'

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
			  case uval of
              'Exit':begin
                    WIDGET_CONTROL,self.base, /DESTROY
                    self.quit=1
                    end 
               else:
          endcase
      end
      endcase


end
;--------------------------
function gpi_showpaths::act
  return, self.quit
end
;--------------------------
function gpi_showpaths::init

self.base = widget_base(title='Directory Paths for GPI Data Pipeline', /column)
base=self.base
void = widget_label(base, value='The following directories appear to be configured properly:')
base_valid = widget_base(base, /column)
invalid_label = widget_label(base, value='The following directories are NOT configured properly:')
base_invalid = widget_base(base, /column)



path_info = gpi_validate_paths(/get_path_info)

npaths = n_elements(path_info)

all_valid = 1

for i=0L,npaths-1 do begin
	dirname = path_info[i].name
    dirpath = gpi_get_directory(path_info[i].name,method=method)
    exists = file_test(dirpath, dir = path_info[i].isdir)
    writeable = file_test(dirpath, dir = path_info[i].isdir, write=1)
	valid = (exists and (writeable or (path_info[i].writeable eq 0))) ; a directory is valid if it exists, and is writeable if it's supposed to be.

	if valid then mybase = base_valid else mybase = base_invalid
	rowbase = widget_base(mybase, /row)

	void= widget_label(rowbase,Value=path_info[i].description,XSIZE=210, /tracking_events, /align_left)
	void= widget_label(rowbase,Value=path_info[i].name,XSIZE=150, /tracking_events, /align_left)
	void= widget_label(rowbase,Value="from " +method,XSIZE=160, /tracking_events, /align_left)

	text_id = WIDGET_TEXT(rowbase,Value=dirpath, XSIZE=50)


	if valid then begin
		void= widget_label(rowbase,Value=" -ok- ")
	endif else begin
		all_valid = 0
		if not exists then begin
			void= widget_label(rowbase,Value=" Path does not exist ")

		endif else begin
			void= widget_label(rowbase,Value=" Path must be writeable, but is not.")
		endelse 

	endelse


endfor 


	if all_valid then widget_control, invalid_label, set_value ='All paths are configured validly. Nice job!' $ 
	else begin 
		void = widget_label(base, value='You must fix your pipeline setup (by editing environment variables and/or config files)')
		void = widget_label(base, value='before you can run the GPI data pipeline.')
		void = widget_label(base, value='Please see the GPI Data Reduction Pipeline Installation & Configuration Manual')
	endelse


	buttonbar = widget_base(base,column=4,/grid)
	button_id = WIDGET_BUTTON(buttonbar,Value='Quit',Uvalue='Exit',/tracking_events)
	self.information_id= widget_label(base,Value= "   ", xsize=800, /align_left, /sunken)
	WIDGET_CONTROL,base, /REALIZE 
    storage={self:self}
    widget_control,base,set_uvalue=storage,/no_copy


xmanager,'gpi_showpaths',base

  return, 1
end

pro gpi_showpaths__define
state={ gpi_showpaths,$
      base:0L,$
      quit:0L,$
      information_id:0L$
      }
      
      
end
