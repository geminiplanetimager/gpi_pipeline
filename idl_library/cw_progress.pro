; $Id: cw_progress.pro,v 1.1 2005/05/26 19:22:43 rdimeo Exp $
; +
; NAME:
;  CW_PROGRESS
;
; PURPOSE:
;  Compound widget progress bar.
;
; CALLING SEQUENCE:
;  id = CW_PROGRESS(    PARENT,                 $
;                       LABEL = LABEL,          $
;                       BG_COLOR = bg_color,    $
;                       UNAME = uname,          $
;                       VALUE = value,          $
;                       UVALUE = uvalue,        $
;                       RED = RED,              $
;                       GREEN = GREEN,          $
;                       BLUE = BLUE,            $
;                       YELLOW = YELLOW,        $
;                       PURPLE = purple,        $
;                       XSIZE = xsize,          $
;                       YSIZE = ysize,          $
;                       FRAME = frame,          $
;                       XOFFSET = xoffset,      $
;                       YOFFSET = yoffset,      $
;                       OBJ_REF = obj_ref       )
;
;  Note that the value of the widget, i.e. the current progress (0.0 <progress < 1.0),
;  can be obtained using WIDGET_CONTROL:
;     WIDGET_CONTROL,id,get_value = progress_value
;  The resulting variable named prgress_value here would be a float
;  value between 0.0 and 1.0 depending on the setting.
;
;  The value of the widget can be modified using WIDGET_CONTROL
;  as follows:
;     WIDGET_CONTROL,id,set_value = new_progress_value
;  where new_progress_value is a float value like progress_value.
;
; PARAMETERS: (Required)
;  PARENT:     widget ID of the parent widget
;
; KEYWORDS: (Optional)
;  XOFFSET:    The horizontal offset of the widget in units in pixels
;              relative to its parent.
;  YOFFSET:    The vertical offset of the widget in units in pixels
;              relative to its parent.
;  BG_COLOR:   Set this to 'white', 'black', or 'gray' to specify the
;              color of the progress bar in the region where there is
;              no color-bar.  Default is white.
;  UVALUE:     A user value to assign to the progress_bar.  This value
;              can be of any type.
;  FRAME:      The value of this keyword specifies the width of a frame
;              (in pixels) to be drawn around the borders of the progress bar.
;              Note that this keyword is only a hint to the toolkit,
;              and may be ignored in some instances.
;  LABEL:      Label (string) for the progress_bar.
;  UNAME:      Set this keyword to a string that can be used to identify
;              the widget in your code. You can associate a name with
;              each widget in a specific hierarchy, and then use that
;              name to query the widget hierarchy and get the correct
;              widget ID
;  VALUE:      Float value between 0.0 and 1.0 that tells the compound
;              widget how much progress has been made.
;  RED:        Set this keyword to create a red progress_bar.
;  BLUE:       Set this keyword to create a blue progress_bar.
;  GREEN:      Set this keyword to create a green progress_bar.
;  YELLOW:     Set this keyword to create a yellow progress_bar.
;  PURPLE:     Set this keyword to create a purple progress_bar.
;  XSIZE:      Horizontal size of the progress bar in pixels.
;  YSIZE:      Vertical size of the progress bar in pixels.
;  OBJ_REF:    Reference to the compound widget object to provide more
;              flexibility to the programmer than a conventional
;              compound widget.
;
; COMMON BLOCKS:
;  None
;
; REQUIRED PROGRAMS:
;  None
;
; EXAMPLE:
;  An example implementation is contained at the end of this source code
;  listing and is titled TEST_PROGRESS.  It illustrates how you can
;  incorporate this compound widget into an application.
;
; AUTHOR:
;  Robert M. Dimeo, Ph.D.
;  NIST Center for Neutron Research
;  100 Bureau Drive
;  Gaithersburg, MD 20899
;  Phone: (301) 975-8135
;  E-mail: robert.dimeo@nist.gov
;  http://www.ncnr.nist.gov/staff/dimeo
;
; MODIFICATION HISTORY:
;  Written by RMD 05/24/05
;
; LICENSE:
;  The software in this file is written by an employee of
;  National Institute of Standards and Technology
;  as part of the DAVE software project.
;
;  The DAVE software package is not subject to copyright
;  protection and is in the public domain. It should be
;  considered as an experimental neutron scattering data
;  reduction, visualization, and analysis system. As such,
;  the authors assume no responsibility whatsoever for its
;  use, and make no guarantees, expressed or implied,
;  about its quality, reliability, or any other
;  characteristic. The use of certain trade names or commercial
;  products does not imply any endorsement of a particular
;  product, nor does it imply that the named product is
;  necessarily the best product for the stated purpose.
;  We would appreciate acknowledgment if the DAVE software
;  is used or if the code in this file is included in another
;  product.
; -
; ********************************************* ;
pro cw_progress::cleanup
wdelete,self.winpix
ptr_free,self.storage
end
; ********************************************* ;
pro cw_progress::set_property,   winpix = winpix,     $
                                 winvis = winvis,     $
                                 value = value,       $
                                 label = label,       $
                                 color = color
if n_elements(winpix) ne 0 then self.winpix = winpix
if n_elements(winvis) ne 0 then self.winvis = winvis
if n_elements(color) ne 0 then begin
   self.color = color
   ret = self->init_colors()
   ret = self->update_progress()
endif
if n_elements(value) ne 0 then begin
   self.value = value
   ret = self->update_progress()
endif
if n_elements(label) ne 0 then begin
   self.label_txt = label
   if widget_info(self.label_id,/valid_id) then begin
      widget_control,self.label_id,set_value = self.label_txt
   endif else begin
      ; Rebuild the widgets
      widget_control,self.base_id,map = 0
      widget_control,self.win_id,/destroy
      if self.label_txt ne '' then begin
         self.label_id = widget_label(self.base_id,               $
            value = self.label_txt,/dynamic_resize                )
      endif else begin
         self.label_id = 0L
      endelse
      wdelete,self.winpix
      self.win_id = widget_draw(self.base_id,xsize = self.xsize,     $
         ysize = self.ysize,/align_center)
      widget_control,self.win_id,get_value = winvis
      self.winvis = winvis
      window,/free,/pixmap,xsize = self.xsize,ysize = self.ysize
      self.winpix = !d.window
      widget_control,self.base_id,map = 1
      ret = self->update_progress()
   endelse
endif
end
; ********************************************* ;
pro cw_progress::get_property,   tlb = tlb,              $
                                 winpix = winpix,        $
                                 winvis = winvis,        $
                                 win_id = win_id,        $
                                 label = label,          $
                                 xsize = xsize,          $
                                 ysize = ysize,          $
                                 label_id = label_id,    $
                                 value = value,          $
                                 color = color

color = self.color
label_id = self.label_id
value = self.value
tlb = self.tlb
winpix = self.winpix
winvis = self.winvis
win_id = self.win_id
label = self.label_txt
xsize = self.xsize
ysize = self.ysize
end
; ********************************************* ;
function cw_progress_get_value,id
stash = widget_info(id,/child)
widget_control,stash,get_uvalue = o
o->get_property,value = value
return,value
end
; ********************************************* ;
function cw_progress::update_progress
wset,self.winpix
case self.bg_color of
'white':    color = [255B,255B,255B]
'black':    color = [0B,0B,0B]
'gray':     color = (widget_info(self.tlb,/system_colors)).face_3d
else:       color = [255B,255B,255B]
endcase

im = bytarr(3,self.xsize,self.ysize)
for i = 0,2 do im[i,*,*] = color[i]
progress = fix(self.value*self.xsize) < self.xsize
width = 5
xlo = fix(0.5*(self.ysize-1)-1)
xhi = xlo+3
if progress gt 0 then begin
   for i = 0,2 do begin
      im[i,0:(progress-1),0:(self.ysize-1)] = self.triplet[i]
      im[i,0:(progress-1),xlo:xhi] = 255B
      tmp_im = im[i,0:(progress-1),0:(self.ysize-1)]
      if progress gt 5 then begin
         tmp_im = smooth(tmp_im,width,/edge_truncate)
         im[i,0:(progress-1),0:(self.ysize-1)] = tmp_im
      endif
   endfor
endif
tv,im,/true
wset,self.winvis
device,copy = [0,0,self.xsize,self.ysize,0,0,self.winpix]
return,1B
end
; ********************************************* ;
pro cw_progress_set_value,id,value
stash = widget_info(id,/child)
widget_control,stash,get_uvalue = o
o->set_property,value = value
end
; ********************************************* ;
function cw_progress_event,event
return,event
end
; ********************************************* ;
pro cw_progress_kill_notify,id
widget_control,id,get_uvalue = o
obj_destroy,o
end
; ********************************************* ;
pro cw_progress_notify_realize,id
stash = widget_info(id,/parent)
widget_control,stash,get_uvalue = o
o->get_property,xsize = xsize,ysize = ysize
widget_control,id,get_value = winvis
o->set_property,winvis = winvis
window,/free,/pixmap,xsize = xsize,ysize = ysize
winpix = !d.window
o->set_property,winvis = winvis,winpix = winpix
ret = o->update_progress()
; Set the cursor to the standard arrow (on Windows) so that
; the user doesn't know that he/she's using a draw widget here
; (where it would ordinarily turn into a cross-hairs).
device,/cursor_original
end
; ********************************************* ;
function cw_progress::build_widget
tlb = widget_base(self.parent,/col,uvalue = *self.storage,  $
      uname = self.uname,event_func = 'cw_progress_event',  $
      pro_set_value = 'cw_progress_set_value',              $
      func_get_value = 'cw_progress_get_value',             $
      xoffset = self.xoffset,yoffset = self.yoffset,        $
      /base_align_center                                    )
; The base named "BASE" is the STASH
base = widget_base(tlb,/col,uvalue = self,frame = self.frame,  $
       kill_notify = 'cw_progress_kill_notify'                 )
self.base_id = base
self.tlb = tlb
if self.label_txt ne '' then begin
   self.label_id = widget_label(base,value = self.label_txt,      $
      /dynamic_resize                                             )
endif else begin
   self.label_id = 0L
endelse
self.win_id = widget_draw(base,xsize = self.xsize,             $
   ysize = self.ysize,/align_center,                           $
   notify_realize = 'cw_progress_notify_realize'               )
return,1B
end
; ********************************************* ;
function cw_progress::init_colors
case self.color of
'red':      self.triplet = [255B,0B,0B]
'green':    self.triplet = [0B,200B,0B]
'blue':     self.triplet = [0B,0B,255B]
'purple':   self.triplet = [160B,32B,240B]
'yellow':   self.triplet = [248B,221B,0B]
endcase
return,1B
end
; ********************************************* ;
function cw_progress::init,   parent,              $
                              uvalue = uvalue,     $
                              uname = uname,       $
                              label = label,       $
                              red = red,           $
                              green = green,       $
                              blue = blue,         $
                              purple = purple,     $
                              yellow = yellow,     $
                              frame = frame,       $
                              value = value,       $
                              bg_color = bg_color, $
                              xoffset = xoffset,   $
                              yoffset = yoffset,   $
                              xsize = xsize,       $
                              ysize = ysize

if n_params() eq 0 then return,0B
if n_elements(xoffset) eq 0 then xoffset = 0L
if n_elements(yoffset) eq 0 then yoffset = 0L
self.xoffset = xoffset & self.yoffset = yoffset
if n_elements(bg_color) eq 0 then bg_color = 'white'
if (bg_color ne 'gray') and (bg_color ne 'white') and $
   (bg_color ne 'black') then bg_color = 'white'
self.bg_color = bg_color
if n_elements(frame) eq 0 then frame = 0
self.frame = frame
if n_elements(value) eq 0 then value = 0.0
self.value = value
if n_elements(uvalue) eq 0 then uvalue = ''
self.storage = ptr_new(uvalue)
if n_elements(uname) eq 0 then uname = ''
self.uname = uname
if n_elements(label) eq 0 then label = ''
self.label_txt = label
if keyword_set(purple) then color = 'purple'
if keyword_set(red) then color = 'red'
if keyword_set(blue) then color = 'blue'
if keyword_set(green) then color = 'green'
if keyword_set(yellow) then color = 'yellow'
if ~keyword_set(red) and ~keyword_set(blue) and ~keyword_set(red) and $
   ~keyword_set(purple) and ~keyword_set(yellow) then color = 'green'
self.color = color
if n_elements(xsize) eq 0 then xsize = 75
if n_elements(ysize) eq 0 then ysize = 12
self.xsize = xsize & self.ysize = ysize
ret = self->init_colors()
self.parent = parent
return,1B
end
; ********************************************* ;
pro cw_progress__define
void =   {  cw_progress,                        $
            storage:ptr_new(),                  $
            uname:'',                           $
            bg_color:'',                        $
            frame:0B,                           $
            base_id:0L,                         $
            parent:0L,                          $
            winvis:0L,                          $
            winpix:0L,                          $
            win_id:0L,                          $
            xsize:0L,                           $
            ysize:0L,                           $
            color:'',                           $
            label_id:0L,                        $
            label_txt:'',                       $
            value:0.0,                          $
            xoffset:0L,                         $
            yoffset:0L,                         $
            triplet:bytarr(3),                  $
            tlb:0L                              }

end
; ********************************************* ;
function cw_progress,   parent,                 $
                        _Extra = extra,         $
                        obj_ref = obj_ref

obj_ref = obj_new('cw_progress',parent,_Extra = extra)
ret = obj_ref->build_widget()
obj_ref->get_property,tlb = tlb
return,tlb
end
; ********************************************* ;
; ********************************************* ;
pro test_progress_event,event
uname = widget_info(event.id,/uname)
if uname eq 'QUIT' then widget_control,event.top,/destroy
if uname eq 'START' then begin
   xlo = 0.0 & xhi = 1.0 & nx = 1000 & dx = (xhi-xlo)/(nx-1.0)
   x = xlo+dx*findgen(nx)
   progress_id = widget_info(event.top,find_by_uname = 'PROGRESS')
   widget_control,progress_id,get_uvalue = o
   o->set_property,label = 'Performing some lengthy calculation...'
   for i = 0,nx-1 do begin
      widget_control,progress_id,set_value = x[i]
   endfor
   o->set_property,label = 'Calculation is finally complete!'
endif
end
; ********************************************* ;
pro test_progress
tlb = widget_base(/col,/tlb_frame_attr)
op =  cw_progress(tlb,value = 0.0,/blue,uname = 'PROGRESS',    $
      xsize = 150,label = 'DAVE progress',/frame,obj_ref = o,  $
      bg_color = 'white')
void = widget_button(tlb,value = 'Start',uname = 'START')
void = widget_button(tlb,value = 'Quit',uname = 'QUIT')

widget_control,tlb,/realize
widget_control,op,set_uvalue = o
xmanager,'test_progress',tlb,/no_block
end