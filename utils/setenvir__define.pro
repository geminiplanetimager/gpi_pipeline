;+
;  setenvir
;
;  Utility GUI for setting GPI environment variables
;
; HISTORY:
;    Originally by Jerome Maire. 
;    2011-07-29 MP: Minor cleanup and usability enhancements, buttons rearranged
;    & renamed, added validation of variables before setting, added this doc
;    header. 
;
;-


PRO setenvwid_event, ev
    widget_control,ev.top,get_uvalue=storage
    if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
end

;-------------------------------------------------------------------
pro setenvir::event, ev

compile_opt defint32, strictarr, logical_predicate

;common filestateF

widget_control,ev.id,get_uvalue=uval
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
				  'Exit': textinfo='Exit without applying changes'

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
            'changeGID':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_IFS_DIR'), Title='Choose directory for GPI_IFS_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GIDdir_id, set_value=dir
                 setenv,'GPI_IFS_DIR='+dir
              end
            'changeGPD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_DRP_DIR'), Title='Choose directory for GPI_DRP_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GPDdir_id, set_value=dir
                 setenv,'GPI_DRP_DIR='+dir
              end
            'changeGPLD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_DRP_LOG_DIR'), Title='Choose directory for GPI_DRP_LOG_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GPLDdir_id, set_value=dir
                 setenv,'GPI_DRP_LOG_DIR='+dir
              end
            'changeGDTD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_DRP_TEMPLATES_DIR'), Title='Choose directory for GPI_DRP_TEMPLATES_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GDTDdir_id, set_value=dir
                 setenv,'GPI_DRP_TEMPLATES_DIR='+dir
              end
            'changeGQD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_DRP_QUEUE_DIR'), Title='Choose directory for GPI_DRP_QUEUE_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GQDdir_id, set_value=dir
                 setenv,'GPI_DRP_QUEUE_DIR='+dir
              end
            'changeGCF':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_DRP_CONFIG_DIR'), Title='Choose gpi_pipeline_primitives.xml',/must_exist, /directory) ;FILTER = ['gpi_pipeline_primitives.xml'] )
                 if dir ne '' then widget_control, self.GCF_id, set_value=dir
                 setenv,'GPI_DRP_CONFIG_DIR='+dir
              end
            'changeGRDD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_RAW_DATA_DIR'), Title='Choose directory for GPI_RAW_DATA_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GRDDdir_id, set_value=dir
                 setenv,'GPI_RAW_DATA_DIR='+dir
              end
            'changeGDOD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_REDUCED_DATA_DIR'), Title='Choose directory for GPI_REDUCED_DATA_DIR',/must_exist , /directory)
                 if ~(file_test(dir,/dir,/write)) then begin
                  widget_control,self.information_id,set_value='Repertory inexistent or without writing permission.'
                  dir=''
                 endif 
                 if dir ne '' then widget_control, self.GDODdir_id, set_value=dir
                 setenv,'GPI_REDUCED_DATA_DIR='+dir
              end
              'Save envir. var.':begin
                  GID=getenv('GPI_IFS_DIR')
                  GPD=getenv('GPI_DRP_DIR')
                  GPLD= getenv('GPI_DRP_LOG_DIR')
                  GDTD=getenv('GPI_DRP_TEMPLATES_DIR')
                  GQD=getenv('GPI_DRP_QUEUE_DIR')
                  GCF= getenv('GPI_DRP_CONFIG_DIR')
                  GRDD=getenv('GPI_RAW_DATA_DIR')
                  GDOD=getenv('GPI_REDUCED_DATA_DIR')
                    ;select GPI_IFS_DIR directory for saving (need to be writable). PIPELINE_DIR could be non-writable
                    save, GID,GPD,GPLD,GDTD,GQD,GCF,GRDD,GDOD,FILENAME = getenv('GPI_IFS_DIR')+path_sep()+'environment_variables.sav'
              end
              'Restore envir. var.':begin
               dir = DIALOG_PICKFILE(PATH=getenv('GPI_IFS_DIR'), Title='Choose environment_variables*.sav',/must_exist,FILTER = ['environment_variables*.sav'] )

               if dir ne '' then begin
                 restore, dir
                 setenv,'GPI_IFS_DIR='+GID
                 widget_control, self.GIDdir_id, set_value=GID
                 setenv,'GPI_DRP_DIR='+GPD
                 widget_control, self.GPDdir_id, set_value=GPD
                 setenv,'GPI_DRP_LOG_DIR='+GPLD
                 widget_control, self.GPLDdir_id, set_value=GPLD
                 setenv,'GPI_DRP_TEMPLATES_DIR='+GDTD
                 widget_control, self.GDTDdir_id, set_value=GDTD
                 setenv,'GPI_DRP_QUEUE_DIR='+GQD
                 widget_control, self.GQDdir_id, set_value=GQD
                 setenv,'GPI_DRP_CONFIG_DIR='+GCF
                 widget_control, self.GCF_id, set_value=GCF
                 setenv,'GPI_RAW_DATA_DIR='+GRDD
                 widget_control, self.GRDDdir_id, set_value=GRDD
                 setenv,'GPI_REDUCED_DATA_DIR='+GDOD
                 widget_control, self.GDODdir_id, set_value=GDOD
               endif
              end
              'Ok':begin

					is_valid = gpi_is_setenv()
					if is_valid then begin
	                  WIDGET_CONTROL,self.base, /DESTROY
    	              self.quit=0
					endif
                  end
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
function setenvir::act
  return, self.quit
end
;--------------------------
function setenvir::init

compile_opt defint32, strictarr, logical_predicate

self.base = widget_base(title='Environment variables', /column)
base=self.base
void = widget_label(base, value='Please verify or define environment variables hereafter.')
void = widget_label(base, value='Writable directories:')
;base2 = widget_base(base, /row)
;basedesc = widget_base(base2, /column)
;basefilename = widget_base(base2, /column)
;basebutt = widget_base(base2, /column)

;is there a saved environment variable file?
;getenv('GPI_DRP_DIR')
cd, current=cur_rep
 Result = FILE_TEST( cur_rep+path_sep()+'environment_variables.sav' ,/READ)
 if Result eq 1 then begin
                restore, cur_rep+path_sep()+'environment_variables.sav'
               if getenv('GPI_IFS_DIR') eq '' then  setenv,'GPI_IFS_DIR='+GID
               if getenv('GPI_DRP_DIR') eq '' then setenv,'GPI_DRP_DIR='+GPD
               if getenv('GPI_DRP_LOG_DIR') eq '' then setenv,'GPI_DRP_LOG_DIR='+GPLD
               if getenv('GPI_DRP_TEMPLATES_DIR') eq '' then setenv,'GPI_DRP_TEMPLATES_DIR='+GDTD
               if getenv('GPI_DRP_QUEUE_DIR') eq '' then setenv,'GPI_DRP_QUEUE_DIR='+GQD
               if getenv('GPI_DRP_CONFIG_DIR') eq '' then setenv,'GPI_DRP_CONFIG_DIR='+GCF
               if getenv('GPI_RAW_DATA_DIR') eq '' then setenv,'GPI_RAW_DATA_DIR='+GRDD
               if getenv('GPI_REDUCED_DATA_DIR') eq '' then setenv,'GPI_REDUCED_DATA_DIR='+GDOD 
               textinfo=cur_rep+path_sep()+'environment_variables.sav has been restored for non-existent variables.'
 endif else begin
       textinfo= 'No file environment_variables.sav found in '+ cur_rep
       ;try to give a first guess of environment variables
       ;we suppose that gpipiperun.* is located in the 'pipeline\/drp_code' repertory
       if FILE_TEST( cur_rep+path_sep()+'drf_queue' ,/DIR) then begin
           reppipeline=cur_rep 
           cd, '..' 
           cd, current=parentdir
           cd, cur_rep        
          if FILE_TEST( reppipeline ,/directory) then begin
              if getenv('GPI_IFS_DIR') eq '' then setenv,'GPI_IFS_DIR='+parentdir+path_sep()
              if getenv('GPI_DRP_DIR') eq '' then setenv,'GPI_DRP_DIR='+reppipeline+path_sep()
              if getenv('GPI_DRP_LOG_DIR') eq '' then setenv,'GPI_DRP_LOG_DIR='+reppipeline+path_sep()+'log'+path_sep()
              if getenv('GPI_DRP_TEMPLATES_DIR') eq '' then  setenv,'GPI_DRP_TEMPLATES_DIR='+reppipeline+path_sep()+'drf_templates'+path_sep()
              if getenv('GPI_DRP_QUEUE_DIR') eq '' then setenv,'GPI_DRP_QUEUE_DIR='+reppipeline+path_sep()+'drf_queue'+path_sep()
              if getenv('GPI_DRP_CONFIG_DIR') eq '' then setenv,'GPI_DRP_CONFIG_DIR='+reppipeline+path_sep()+'config'+path_sep();+'gpi_pipeline_primitives.xml'
          endif
       endif
       
 endelse     

xs=180
xs0=210
ys=30
base2=widget_base(base, /row)
if file_test(getenv('GPI_IFS_DIR'),/dir) then val=getenv('GPI_IFS_DIR') else val=''
void= widget_label(base2,Value='Working directory:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GID')
void= widget_label(base2,Value='GPI_IFS_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GID')
self.GIDdir_id = WIDGET_TEXT(base2,Value=val,Uvalue='IFS_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base2,Value='Change dir...',Uvalue='changeGID',ysize=ys)

base4=widget_base(base, /row)
if file_test(getenv('GPI_DRP_LOG_DIR'),/dir) then val=getenv('GPI_DRP_LOG_DIR') else val=''
void= widget_label(base4,Value='Dir. for produced log file:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GPLD')
void= widget_label(base4,Value='GPI_DRP_LOG_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GPLD')
self.GPLDdir_id = WIDGET_TEXT(base4,Value=val,Uvalue='PIPELINE_LOG_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base4,Value='Change dir...',Uvalue='changeGPLD',ysize=ys)


base6=widget_base(base, /row)
if file_test(getenv('GPI_DRP_QUEUE_DIR'),/dir) then val=getenv('GPI_DRP_QUEUE_DIR') else val=''
void= widget_label(base6,Value='DRF queue directory:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GQD')
void= widget_label(base6,Value='GPI_DRP_QUEUE_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GQD')
self.GQDdir_id = WIDGET_TEXT(base6,Value=val,Uvalue='GPI_DRP_QUEUE_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base6,Value='Change dir...',Uvalue='changeGQD',ysize=ys)


base9=widget_base(base, /row)
if (file_test(getenv('GPI_REDUCED_DATA_DIR'),/dir,/write)) then val=getenv('GPI_REDUCED_DATA_DIR') else val=''
void= widget_label(base9,Value='Reduced data dir.:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GDOD')
void= widget_label(base9,Value='GPI_REDUCED_DATA_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GDOD')
self.GDODdir_id = WIDGET_TEXT(base9,Value=val,Uvalue='GPI_REDUCED_DATA_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base9,Value='Change dir...',Uvalue='changeGDOD',ysize=ys)

void = widget_label(base, value='')
void = widget_label(base, value='The following directories need to be writable only for advanced customized reduction:')

base5=widget_base(base, /row)
if file_test(getenv('GPI_DRP_TEMPLATES_DIR'),/dir) then val=getenv('GPI_DRP_TEMPLATES_DIR') else val=''
void= widget_label(base5,Value='Dir. of pre-defined recipes:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GDTD')
void= widget_label(base5,Value='GPI_DRP_TEMPLATES_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GDTD')
self.GDTDdir_id = WIDGET_TEXT(base5,Value=val,Uvalue='GPI_DRP_TEMPLATES_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base5,Value='Change dir...',Uvalue='changeGDTD',ysize=ys)


base7=widget_base(base, /row)
if file_test(getenv('GPI_DRP_CONFIG_DIR'),/dir) then val=getenv('GPI_DRP_CONFIG_DIR') else val=''
void= widget_label(base7,Value='Config file of reduction modules:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GCF')
void= widget_label(base7,Value='GPI_DRP_CONFIG_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GCF')
self.GCF_id = WIDGET_TEXT(base7,Value=val,Uvalue='GPI_DRP_CONFIG_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base7,Value='Change dir...',Uvalue='changeGCF',ysize=ys)


void = widget_label(base, value='')
void = widget_label(base, value='The following directories can be non-writable:')
base3=widget_base(base, /row)
if file_test(getenv('GPI_DRP_DIR'),/dir) then val=getenv('GPI_DRP_DIR') else val=''
void= widget_label(base3,Value='Dir. of the pipeline (code or exec.):',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GPD')
void= widget_label(base3,Value='GPI_DRP_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GPD')
self.GPDdir_id = WIDGET_TEXT(base3,Value=val,Uvalue='PIPELINE_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base3,Value='Change dir...',Uvalue='changeGPD',ysize=ys)


base8=widget_base(base, /row)
if file_test(getenv('GPI_RAW_DATA_DIR'),/dir) then val=getenv('GPI_RAW_DATA_DIR') else val=''
void= widget_label(base8,Value='Dir. of your data:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GRDD')
void= widget_label(base8,Value='GPI_RAW_DATA_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GRDD')
self.GRDDdir_id = WIDGET_TEXT(base8,Value=val,Uvalue='GPI_RAW_DATA_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base8,Value='Change dir...',Uvalue='changeGRDD',ysize=ys)

buttonbar = widget_base(base,column=4,/grid)
button_id = WIDGET_BUTTON(buttonbar,Value='Set Variables',Uvalue='Ok',/tracking_events)
button_id = WIDGET_BUTTON(buttonbar,Value='Save to File',Uvalue='Save envir. var.',/tracking_events)
button_id = WIDGET_BUTTON(buttonbar,Value='Restore from File',Uvalue='Restore envir. var.',/tracking_events)
button_id = WIDGET_BUTTON(buttonbar,Value='Quit',Uvalue='Exit',/tracking_events)
self.information_id= widget_label(base,Value=textinfo, xsize=600, /align_left, /sunken)
WIDGET_CONTROL,base, /REALIZE 
    storage={self:self}
    widget_control,base,set_uvalue=storage,/no_copy
;widget_control,base ,/no_copy
xmanager,'setenvwid',base

  return, 1
end

pro setenvir__define
state={ setenvir,$
      base:0L,$
      quit:0L,$
      GIDdir_id:0L,$  
      GPDdir_id:0L,$  
      GPLDdir_id:0L,$   
      GDTDdir_id:0L,$  
      GQDdir_id:0L,$   
      GCF_id:0L,$  
      information_id:0L,$
      GRDDdir_id:0L,$  
      GDODdir_id:0L$
      }
      
      
end
