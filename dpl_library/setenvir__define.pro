

;cont=gpi_is_setenv()
;while gpi_is_setenv() eq 0 then setenv_widget


PRO setenvwid_event, ev
    widget_control,ev.top,get_uvalue=storage
    if size(storage,/tname) eq 'STRUCT' then storage.self->event, ev else storage->event, ev
end

;-------------------------------------------------------------------
pro setenvir::event, ev

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
                  'GDTD':textinfo='Directory of templates reduction sequences.'
                  'GQD':textinfo='Directory of DRF queue. The DRP will scan this directory'
                  'GCF' :textinfo='Config file of data reduction sequences (DRSConfig.xml).' 
                  'GRDD' :textinfo='Directory of raw data'
                  'GDOD':textinfo='Directory of DRP processed output data.'
                  'Save':textinfo='It will save these environment variables for future use.'
                  'Restore envir. var.':textinfo='Restore saved environment variables.'
                  'Ok':textinfo='Start.'
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
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_PIPELINE_DIR'), Title='Choose directory for GPI_PIPELINE_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GPDdir_id, set_value=dir
                 setenv,'GPI_PIPELINE_DIR='+dir
              end
            'changeGPLD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_PIPELINE_LOG_DIR'), Title='Choose directory for GPI_PIPELINE_LOG_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GPLDdir_id, set_value=dir
                 setenv,'GPI_PIPELINE_LOG_DIR='+dir
              end
            'changeGDTD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_DRF_TEMPLATES_DIR'), Title='Choose directory for GPI_DRF_TEMPLATES_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GDTDdir_id, set_value=dir
                 setenv,'GPI_DRF_TEMPLATES_DIR='+dir
              end
            'changeGQD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_QUEUE_DIR'), Title='Choose directory for GPI_QUEUE_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GQDdir_id, set_value=dir
                 setenv,'GPI_QUEUE_DIR='+dir
              end
            'changeGCF':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_CONFIG_FILE'), Title='Choose drsconfig.xml',/must_exist,FILTER = ['drsconfig.xml'] )
                 if dir ne '' then widget_control, self.GCF_id, set_value=dir
                 setenv,'GPI_CONFIG_FILE='+dir
              end
            'changeGRDD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_RAW_DATA_DIR'), Title='Choose directory for GPI_RAW_DATA_DIR',/must_exist , /directory)
                 if dir ne '' then widget_control, self.GRDDdir_id, set_value=dir
                 setenv,'GPI_RAW_DATA_DIR='+dir
              end
            'changeGDOD':begin
                 dir = DIALOG_PICKFILE(PATH=getenv('GPI_DRP_OUTPUT_DIR'), Title='Choose directory for GPI_DRP_OUTPUT_DIR',/must_exist , /directory)
                 if ~(file_test(dir,/dir,/write)) then begin
                  widget_control,self.information_id,set_value='Repertory inexistent or without writing permission.'
                  dir=''
                 endif 
                 if dir ne '' then widget_control, self.GDODdir_id, set_value=dir
                 setenv,'GPI_DRP_OUTPUT_DIR='+dir
              end
              'Save envir. var.':begin
                  GID=getenv('GPI_IFS_DIR')
                  GPD=getenv('GPI_PIPELINE_DIR')
                  GPLD= getenv('GPI_PIPELINE_LOG_DIR')
                  GDTD=getenv('GPI_DRF_TEMPLATES_DIR')
                  GQD=getenv('GPI_QUEUE_DIR')
                  GCF= getenv('GPI_CONFIG_FILE')
                  GRDD=getenv('GPI_RAW_DATA_DIR')
                  GDOD=getenv('GPI_DRP_OUTPUT_DIR')
                    save, GID,GPD,GPLD,GDTD,GQD,GCF,GRDD,GDOD,FILENAME = 'environment_variables.sav'
              end
              'Restore envir. var.':begin
               dir = DIALOG_PICKFILE(PATH=getenv('GPI_PIPELINE_DIR'), Title='Choose environment_variables*.sav',/must_exist,FILTER = ['environment_variables*.sav'] )
               if dir ne -1 then begin
                 restore, dir
                 setenv,'GPI_IFS_DIR='+GID
                 setenv,'GPI_PIPELINE_DIR='+GPD
                 setenv,'GPI_PIPELINE_LOG_DIR='+GPLD
                 setenv,'GPI_DRF_TEMPLATES_DIR='+GDTD
                 setenv,'GPI_QUEUE_DIR='+GQD
                 setenv,'GPI_CONFIG_FILE='+GCF
                 setenv,'GPI_RAW_DATA_DIR='+GRDD
                 setenv,'GPI_DRP_OUTPUT_DIR='+GDOD
               endif
              end
              'Ok':begin
                  WIDGET_CONTROL,self.base, /DESTROY
                  self.quit=0
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
function setenvir::act
  return, self.quit
end
function setenvir::init
self.base = widget_base(title='Environment variables', /column)
base=self.base
void = widget_label(base, value='Please verify or define environment variables hereafter.')
void = widget_label(base, value='Writable directories:')
;base2 = widget_base(base, /row)
;basedesc = widget_base(base2, /column)
;basefilename = widget_base(base2, /column)
;basebutt = widget_base(base2, /column)

;is there a saved environment variable file?
;getenv('GPI_PIPELINE_DIR')
cd, current=cur_rep
 Result = FILE_TEST( cur_rep+path_sep()+'environment_variables.sav' ,/READ)
 if Result eq 1 then begin
                restore, cur_rep+path_sep()+'environment_variables.sav'
               if getenv('GPI_IFS_DIR') eq '' then  setenv,'GPI_IFS_DIR='+GID
               if getenv('GPI_PIPELINE_DIR') eq '' then setenv,'GPI_PIPELINE_DIR='+GPD
               if getenv('GPI_PIPELINE_LOG_DIR') eq '' then setenv,'GPI_PIPELINE_LOG_DIR='+GPLD
               if getenv('GPI_DRF_TEMPLATES_DIR') eq '' then setenv,'GPI_DRF_TEMPLATES_DIR='+GDTD
               if getenv('GPI_QUEUE_DIR') eq '' then setenv,'GPI_QUEUE_DIR='+GQD
               if getenv('GPI_CONFIG_FILE') eq '' then setenv,'GPI_CONFIG_FILE='+GCF
               if getenv('GPI_RAW_DATA_DIR') eq '' then setenv,'GPI_RAW_DATA_DIR='+GRDD
               if getenv('GPI_DRP_OUTPUT_DIR') eq '' then setenv,'GPI_DRP_OUTPUT_DIR='+GDOD 
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
              if getenv('GPI_PIPELINE_DIR') eq '' then setenv,'GPI_PIPELINE_DIR='+reppipeline+path_sep()
              if getenv('GPI_PIPELINE_LOG_DIR') eq '' then setenv,'GPI_PIPELINE_LOG_DIR='+reppipeline+path_sep()+'log'+path_sep()
              if getenv('GPI_DRF_TEMPLATES_DIR') eq '' then  setenv,'GPI_DRF_TEMPLATES_DIR='+reppipeline+path_sep()+'drf_templates'+path_sep()
              if getenv('GPI_QUEUE_DIR') eq '' then setenv,'GPI_QUEUE_DIR='+reppipeline+path_sep()+'drf_queue'+path_sep()
              if getenv('GPI_CONFIG_FILE') eq '' then setenv,'GPI_CONFIG_FILE='+reppipeline+path_sep()+'dpl_library'+path_sep()+'drsconfig.xml'
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
if file_test(getenv('GPI_PIPELINE_LOG_DIR'),/dir) then val=getenv('GPI_PIPELINE_LOG_DIR') else val=''
void= widget_label(base4,Value='Dir. for produced log file:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GPLD')
void= widget_label(base4,Value='GPI_PIPELINE_LOG_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GPLD')
self.GPLDdir_id = WIDGET_TEXT(base4,Value=val,Uvalue='PIPELINE_LOG_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base4,Value='Change dir...',Uvalue='changeGPLD',ysize=ys)


base6=widget_base(base, /row)
if file_test(getenv('GPI_QUEUE_DIR'),/dir) then val=getenv('GPI_QUEUE_DIR') else val=''
void= widget_label(base6,Value='DRF queue directory:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GQD')
void= widget_label(base6,Value='GPI_QUEUE_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GQD')
self.GQDdir_id = WIDGET_TEXT(base6,Value=val,Uvalue='GPI_QUEUE_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base6,Value='Change dir...',Uvalue='changeGQD',ysize=ys)


base9=widget_base(base, /row)
if (file_test(getenv('GPI_DRP_OUTPUT_DIR'),/dir,/write)) then val=getenv('GPI_DRP_OUTPUT_DIR') else val=''
void= widget_label(base9,Value='Reduced data dir.:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GDOD')
void= widget_label(base9,Value='GPI_DRP_OUTPUT_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GDOD')
self.GDODdir_id = WIDGET_TEXT(base9,Value=val,Uvalue='GPI_DRP_OUTPUT_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base9,Value='Change dir...',Uvalue='changeGDOD',ysize=ys)

void = widget_label(base, value='')
void = widget_label(base, value='The following need to be writable only for avanced customized reduction:')

base5=widget_base(base, /row)
if file_test(getenv('GPI_DRF_TEMPLATES_DIR'),/dir) then val=getenv('GPI_DRF_TEMPLATES_DIR') else val=''
void= widget_label(base5,Value='Dir. of pre-defined recipes:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GDTD')
void= widget_label(base5,Value='GPI_DRF_TEMPLATES_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GDTD')
self.GDTDdir_id = WIDGET_TEXT(base5,Value=val,Uvalue='GPI_DRF_TEMPLATES_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base5,Value='Change dir...',Uvalue='changeGDTD',ysize=ys)


base7=widget_base(base, /row)
if file_test(getenv('GPI_CONFIG_FILE'),/read) then val=getenv('GPI_CONFIG_FILE') else val=''
void= widget_label(base7,Value='Config file of reduction modules:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GCF')
void= widget_label(base7,Value='GPI_CONFIG_FILE :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GCF')
self.GCF_id = WIDGET_TEXT(base7,Value=val,Uvalue='GPI_CONFIG_FILE',XSIZE=50)
button_id = WIDGET_BUTTON(base7,Value='Change dir...',Uvalue='changeGCF',ysize=ys)


void = widget_label(base, value='')
void = widget_label(base, value='The following directories can be non-writable:')
base3=widget_base(base, /row)
if file_test(getenv('GPI_PIPELINE_DIR'),/dir) then val=getenv('GPI_PIPELINE_DIR') else val=''
void= widget_label(base3,Value='Dir. of the pipeline (code or exec.):',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GPD')
void= widget_label(base3,Value='GPI_PIPELINE_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GPD')
self.GPDdir_id = WIDGET_TEXT(base3,Value=val,Uvalue='PIPELINE_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base3,Value='Change dir...',Uvalue='changeGPD',ysize=ys)


base8=widget_base(base, /row)
if file_test(getenv('GPI_RAW_DATA_DIR'),/dir) then val=getenv('GPI_RAW_DATA_DIR') else val=''
void= widget_label(base8,Value='Dir. of your data:',ysize=ys,XSIZE=xs0, /tracking_events,Uvalue='GRDD')
void= widget_label(base8,Value='GPI_RAW_DATA_DIR :',ysize=ys,XSIZE=xs, /tracking_events,Uvalue='GRDD')
self.GRDDdir_id = WIDGET_TEXT(base8,Value=val,Uvalue='GPI_RAW_DATA_DIR',XSIZE=50)
button_id = WIDGET_BUTTON(base8,Value='Change dir...',Uvalue='changeGRDD',ysize=ys)

button_id = WIDGET_BUTTON(base,Value='Save',Uvalue='Save envir. var.')
button_id = WIDGET_BUTTON(base,Value='Restore environment variables',Uvalue='Restore envir. var.')
button_id = WIDGET_BUTTON(base,Value='Ok',Uvalue='Ok')
button_id = WIDGET_BUTTON(base,Value='Quit',Uvalue='Exit')
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