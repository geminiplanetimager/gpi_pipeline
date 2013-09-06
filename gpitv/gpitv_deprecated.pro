pro GPItv::spotlocations

	; Calculate spots locations


	(*self.state).cursorpos = (*self.state).coord

	if (not (xregistered(self.xname+'_spotlocations', /noshow))) then begin
		(*self.state).spotslocations=dblarr((*self.state).nbrsatspot,2)
		spotlocations_base = $
		  widget_base(/base_align_center, $
					  group_leader = (*self.state).base_id, $
					  /column, $
					  title = 'GPItv locations of sat-spots', $
					  uvalue = 'spotlocations_base')

		spotlocations_top_base = widget_base(spotlocations_base, /column, /base_align_center)

		spotlocations_data_base1 = widget_base( $
				spotlocations_top_base, /column, frame=0)

		(*self.state).satradius_id = $
		  cw_field(spotlocations_data_base1, $
				   /long, $
				   /return_events, $
				   title = 'Half-side of square area for centroid (pix):', $
				   uvalue = 'radius', $
				   value = (*self.state).r, $
				   xsize = 5)
		(*self.state).satmethlist = ['Barycent. centroid', 'Gauss2Dfit']
		(*self.state).satmeth_id = widget_droplist(spotlocations_data_base1, $
									   frame = 0, $
									   title = 'Method:', $
									   uvalue = 'meth', $
									   value = (*self.state).satmethlist)
		spotlocations_data_base2 = widget_base( $
				spotlocations_top_base, /column, frame=0)

	  spotlocationszoom_widget_id = widget_draw( $
			 spotlocations_data_base2, $
			 scr_xsize=1.5*(*self.state).photzoom_size, scr_ysize=1.5*(*self.state).photzoom_size)

	;    anguprof_draw_base = widget_base( $
	;            anguprof_base, /row, /base_align_center, frame=0)
		  (*self.state).spotloclabel=widget_label(spotlocations_data_base1, $
				 value = '*** LEFT-CLICK ON ONE SAT/SPOT. ***', $
				  /align_left,xsize=400)

		spotlocations_data_base1a = widget_base(spotlocations_data_base1, /column, frame=1)
	  ;spotlocations_data_base1a0 = widget_base(spotlocations_data_base1a, /row)
		tmp_string = $
		  string(1000, 1000, $
				 format = '("Cursor position:  x=",i4,"  y=",i4)' )
		tmp_string2 = $
		  string(1000, 1000, $
				 format = '("Sat centroid location:  x=",g6.4,"  y=",g6.4)' )

		;(*self.state).spotlocationscursorpos_id = $
			(*self.state).spotlocationscursorpos_id = $
		  widget_label(spotlocations_data_base1a, $
					   value = tmp_string, $
					   uvalue = 'cursorpos1', /align_left)
			 (*self.state).satloc1_id = $
		  widget_label(spotlocations_data_base1a, $
					   value = tmp_string2, $
					   uvalue = 'cursorpos1', /align_left)  
		  espace =  widget_label(spotlocations_data_base1a, value = '')
						  
			(*self.state).spotlocationscursorpos_id2 = $
		  widget_label(spotlocations_data_base1a, $
					   value = tmp_string, $
					   uvalue = 'cursorpos2', /align_left)
	   (*self.state).satloc2_id = $
	   		widget_label(spotlocations_data_base1a, $
					   value = tmp_string2, $
					   uvalue = 'cursorpos2', /align_left)
	   espace =  widget_label(spotlocations_data_base1a, value = '')                         
	   if (*self.state).nbrsatspot gt 2 then begin
			(*self.state).spotlocationscursorpos_id3 = $
		  widget_label(spotlocations_data_base1a, $
					   value = tmp_string, $
					   uvalue = 'cursorpos3', /align_left)
			(*self.state).satloc3_id = $
		  widget_label(spotlocations_data_base1a, $
					   value = tmp_string2, $
					   uvalue = 'cursorpos3', /align_left) 
		  espace =  widget_label(spotlocations_data_base1a, value = '')
								  
			(*self.state).spotlocationscursorpos_id4 = $
		  widget_label(spotlocations_data_base1a, $
					   value = tmp_string, $
					   uvalue = 'cursorpos4', /align_left) 
		   (*self.state).satloc4_id = $
		  widget_label(spotlocations_data_base1a, $
					   value = tmp_string2, $
					   uvalue = 'cursorpos1', /align_left)                                                                     
	  endif
	  (*self.state).spotwarning_id=widget_label(spotlocations_data_base1, $
				 value = '',  /align_left,xsize=300)
	  
	  basecenter = Widget_Base(spotlocations_data_base1a,    COLUMN=1 ,/NONEXCLUSIVE)

	  (*self.state).spotlocations_save_id = $
		  widget_button(spotlocations_data_base2, $
						value = 'Save Calibration File', $
						uvalue = 'spotlocations_save', sensitive=0)
	  spotlocations_done = $
		  widget_button(spotlocations_data_base2, $
						value = 'Done', $
						uvalue = 'spotlocations_done')

	  widget_control, spotlocations_base, /realize

	  widget_control, spotlocationszoom_widget_id, get_value=tmp_value
	  (*self.state).spotlocationszoom_window_id = tmp_value


	  xmanager, 'self->spotlocations', spotlocations_base, /no_block

	  self->resetwindow
	endif

	self->spotlocations_refresh
end

;--------------------------------------------------------------------
pro GPItv::draw_spotlocations_event, event

; Event handler for anguprof mode


if (!d.name NE (*self.state).graphicsdevice) then return

if (event.type EQ 0) then begin
    case event.press of
        1: self->spotlocations
        2: self->spotlocations
        4: self->spotlocations
        else:
    endcase
endif

if (event.type EQ 2) then self->draw_motion_event, event

widget_control, (*self.state).draw_widget_id, /clear_events
widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;----------------------------------------------------------------------
pro GPItv::spotlocations_event, event

	widget_control, event.id, get_uvalue = uvalue

	case uvalue of
		'Barycent. centroid': begin
		  (*self.state).spotcurrmeth=(*self.state).methlist(event.index)
		end
		'Gauss2Dfit': begin
		  (*self.state).spotcurrmeth=(*self.state).methlist(event.index)
		end
		'spotlocations_save':begin
		  writefits, (*self.state).satspotcalibfile,(*self.state).spotslocations[0:(*self.state).nbrsatspot-1,*]
		end
		'spotlocations_done': widget_control, event.top, /destroy
		else:
	endcase

     end

;--------------------------------------------------------------------

pro GPItv::spotlocations_refresh, ps=ps,  sav=sav

  ;(*self.state).photwarning = 'Warnings: None.'

	self->tvspot, sat=0
    x = (*self.state).cursorpos[0]
    y = (*self.state).cursorpos[1]
    ;stop
    ;print,'x&y=',x,y
    tmp_string = $
      string(x, y, $
             format = '("Cursor position:  x=",i4,"  y=",i4)' ) 
          ;stop 
    case (*self.state).spotorder of
     1:  begin         
          widget_control,(*self.state).spotlocationscursorpos_id, set_value = tmp_string            
          cen1=self->calc_centroid(x,y,*self.images.main_image)
          if (*self.state).spotmisdetection eq 0 then begin
              (*self.state).spotslocations[(*self.state).spotorder-1,*]=cen1[*]
              self->tvspot, sat=1
              (*self.state).spotorder+=1
          endif    
             tmp_string = $
                  string(cen1(0), cen1(1), $
                  format = '("Sat centroid location:  x=",g6.4,"  y=",g6.4)' )
                  widget_control,(*self.state).satloc1_id,set_value=tmp_string
          widget_control,(*self.state).spotloclabel, set_value= '*** LEFT-CLICK ON OPPOSITE SECOND SAT/SPOT. ***'
        end   
     2: begin         
          widget_control,(*self.state).spotlocationscursorpos_id2, set_value = tmp_string 
                    cen1=self->calc_centroid(x,y,*self.images.main_image)
             tmp_string = $
                  string(cen1(0), cen1(1), $
                  format = '("Sat centroid location:  x=",g6.4,"  y=",g6.4)' )
                  widget_control,(*self.state).satloc2_id,set_value=tmp_string
         if (*self.state).spotmisdetection eq 0 then begin
              (*self.state).spotslocations[(*self.state).spotorder-1,*]=cen1[*]
              self->tvspot, sat=2
         endif 
          if (*self.state).nbrsatspot gt 2 then begin (*self.state).spotorder+=1 
            widget_control,(*self.state).spotloclabel, set_value= '*** LEFT-CLICK ON THIRD SAT/SPOT. ***'
          endif else begin 
            (*self.state).spotorder=0
            widget_control,(*self.state).spotloclabel, set_value= '*** LEFT-CLICK ON ONE SAT/SPOT. ***'
          endelse

          
        end       
   
      3:  begin         
          widget_control,(*self.state).spotlocationscursorpos_id3, set_value = tmp_string 
                    cen1=self->calc_centroid(x,y,*self.images.main_image)
             tmp_string = $
                  string(cen1(0), cen1(1), $
                  format = '("Sat centroid location:  x=",g6.4,"  y=",g6.4)' )
                  widget_control,(*self.state).satloc3_id,set_value=tmp_string
           
          if (*self.state).nbrsatspot gt 2 then begin 

              widget_control,(*self.state).spotloclabel, set_value= '*** LEFT-CLICK ON OPPOSITE FOURTH SAT/SPOT. ***'
              if (*self.state).spotmisdetection eq 0 then begin
                  (*self.state).spotslocations[(*self.state).spotorder-1,*]=cen1[*]
                  self->tvspot, sat=3
                  (*self.state).spotorder+=1 
              endif
          endif else begin 
            (*self.state).spotorder=0
          endelse

          end
       4: begin         
          widget_control,(*self.state).spotlocationscursorpos_id4, set_value = tmp_string 
                    cen1=self->calc_centroid(x,y,*self.images.main_image)
             tmp_string = $
                  string(cen1[0], cen1[1], $
                  format = '("Sat centroid location:  x=",g6.4,"  y=",g6.4)' )
                  widget_control,(*self.state).satloc4_id,set_value=tmp_string
                     if (*self.state).spotmisdetection eq 0 then begin
                     (*self.state).spotslocations[(*self.state).spotorder-1,*]=cen1[*]
                     self->tvspot, sat=4
                     endif
           (*self.state).spotorder=0
          end
       else:          (*self.state).spotorder+=1
   endcase   

	if ((*self.state).spotmisdetection eq 0) && ((*self.state).spotorder eq (*self.state).nbrsatspot) then $
	widget_control,(*self.state).spotlocations_save_id, sensitive=1
		  
	self->resetwindow
end

;----------------------------------------------------------------------

pro GPItv::tvspot,  sat=sat

  ; Routine to display the zoomed region around radial profil center,
  ; with circles showing the radius.


  ;stop
  ;print,'numla',(*self.state).lambzoom_window_id
  self->setwindow, (*self.state).spotlocationszoom_window_id
  erase

      x=((size(*self.images.main_image))(1))/2
      y=((size(*self.images.main_image))(2))/2

  ;boxsize = round((*self.state).outersky * 1.2)
  radi=((size(*self.images.main_image))(1))/2
  ;print, 'x=',x,'y=',y,'r',radi
  boxsize = radi
  if radi eq 0 then boxsize=1
  xsize = (2 * boxsize) + 1
  ysize = (2 * boxsize) + 1
  image = bytarr(xsize,ysize)

  xmin = (0 > (x - boxsize))
  xmax = ((x + boxsize) < ((*self.state).image_size[0] - 1) )
  ymin = (0 > (y - boxsize) )
  ymax = ((y + boxsize) < ((*self.state).image_size[1] - 1))

  startx = abs( (x - boxsize) < 0 )
  starty = abs( (y - boxsize) < 0 )

  image[startx, starty] = (*self.images.scaled_image)[xmin:xmax, ymin:ymax]

  xs = indgen(xsize) + xmin - startx
  ys = indgen(ysize) + ymin - starty

  xs_delta = (xs[xsize-1] - xs[0]) / float(xsize - 1.0)
  ys_delta = (ys[ysize-1] - ys[0]) / float(ysize - 1.0)
  x_ran = [xs[0]-xs_delta/2.0,xs[xsize-1]+xs_delta/2.0]
  y_ran = [ys[0]-ys_delta/2.0,ys[ysize-1]+ys_delta/2.0]

  dev_width = 1.5*0.8 * (*self.state).photzoom_size
  dev_pos = 1.5*[0.15 * (*self.state).photzoom_size, $
         0.15 * (*self.state).photzoom_size, $
         0.95 * (*self.state).photzoom_size, $
         0.95 * (*self.state).photzoom_size]

  x_factor = dev_width / xsize
  y_factor = dev_width / ysize
  x_offset = (x_factor - 1.0) / x_factor / 2.0
  y_offset = (y_factor - 1.0) / y_factor / 2.0
  xi = findgen(dev_width) / x_factor - x_offset ;x interp index
  yi = findgen(dev_width) / y_factor - y_offset ;y interp index

  image = Poly_2D(image, [[0,0],[1.0/x_factor,0]], $
         [[0,1.0/y_factor],[0,0]], $
         0, dev_width, dev_width)

  xsize = (size(image))[1]
  ysize = (size(image))[2]
  out_xs = xi * xs_delta + xs[0]
  out_ys = yi * ys_delta + ys[0]

  sz = size(image)
  ;stop
  xsize = Float(sz[1])       ;image width
  ysize = Float(sz[2])       ;image height
  dev_width = dev_pos[2] - dev_pos[0] + 1
  dev_width = dev_pos[3] - dev_pos[1] + 1

  tv, image, /device, dev_pos[0], dev_pos[1], $
    xsize=dev_pos[2]-dev_pos[0], $
    ysize=dev_pos[3]-dev_pos[1]

  plot, [0, 1], /noerase, /nodata, xstyle = 1, ystyle = 1, $
    /device, position = dev_pos, color=7, $
    xrange = x_ran, yrange = y_ran
     widget_control, (*self.state).satradius_id, get_value=valrad
     hh=double(valrad)
     print, 'sat',sat
     print, 'satloc',(*self.state).spotslocations
    if  (sat gt 0)  then begin
      ;;self->load8colors
       for ii=1,sat do begin
          tvbox, /data, 2.*hh, (*self.state).spotslocations[ii-1,0], (*self.state).spotslocations[ii-1,1], $
          color=2, thick=2, psym=0
       endfor
  ;    self->getct, 0
    endif
  ;if ((*self.state).skytype NE 2) then begin
  ;    tvcircle, /data, (*self.state).innersky, (*self.state).centerpos[0], (*self.state).centerpos[1], $
  ;      color=4, thick=2, psym=0
  ;    tvcircle, /data, (*self.state).outersky, (*self.state).centerpos[0], (*self.state).centerpos[1], $
  ;      color=5, thick=2, psym=0
  ;endif

  self->resetwindow
end

;-------------------------------------------------

function gpitv::calc_centroid,  x,y,image
;define first sat. box
  x1=0>x-(*self.state).contrwinap
  x2=x+(*self.state).contrwinap<((size(image))(1)-1)
  y1=0>y-(*self.state).contrwinap
  y2=y+(*self.state).contrwinap<((size(image))(1)-1)


 
  badind=where(~FINITE(  image),cc)
  if cc ne 0 then  image(badind )=0 ;TODO:median value

  ;windowing 1 & max
  array= image(x1:x2,y1:y2)
  max1=max(array,location)
  ind1 = ARRAY_INDICES(array, location)
  ind1(0)=ind1(0)+x1
  ind1(1)=ind1(1)+y1
 
      
 widget_control, (*self.state).satradius_id, get_value=valrad
  hh=double(valrad) ; box for fit   'Barycent. centroid', 
  if STRMATCH((*self.state).spotcurrmeth,'Gauss2Dfit') then begin
  yfit = GAUSS2DFIT( image[ind1[0]-hh:ind1[0]+hh,ind1[1]-hh:ind1[1]+hh], paramgauss1)
  endif else begin
  centro=centroid(image[ind1[0]-hh:ind1[0]+hh,ind1[1]-hh:ind1[1]+hh])
  paramgauss1=[0.,0.,0.,0.,centro[0],centro[1]]
  endelse
    ; centroid coord:
  cen1=double(ind1) 
  ; cent coord in initial image coord
  cen1(0)=double(ind1(0))-hh+paramgauss1(4)
  cen1(1)=double(ind1(1))-hh+paramgauss1(5)
  
    if (~finite(cen1(0))) || (~finite(cen1(1))) || $
    (cen1(0) lt 0) || (cen1(0) gt (size(*self.images.main_image))(1)) || $
    (cen1(1) lt 0) || (cen1(1) gt (size(*self.images.main_image))(1))  then begin
       widget_control,(*self.state).spotwarning_id,set_value='Warnings: **** Satellite PSFs not well detected ****'
       (*self.state).spotmisdetection=1
       ;return
   endif
return, cen1

end


;----------------------------------------------------------------------
pro gpitv::load8colors,colors=colors, ps2=ps2

	if not(keyword_set(ps2)) then device,decomposed=0
	colors=strarr(13)
	tvlct,   0,   0,   0, 0 & colors[0]='BACKGROUND'
	tvlct,   0,   0,   0, 1 & colors[1]='BLACK'
	if (!d.name eq 'X' or !d.name eq 'WIN') then tvlct, 255, 255, 255, 1 & colors[1]='WHITE'
	tvlct, 255,   0,   0, 2 & colors[2]='RED'
	tvlct,   0,   0, 255, 3 & colors[3]='BLUE'
	tvlct,   0, 255,   0, 4 & colors[4]='GREEN'
	tvlct, 255, 255,   0, 5 & colors[5]='YELLOW'
	tvlct,   0, 255, 255, 6 & colors[6]='TURQUOISE'
	tvlct,  80,   0, 100, 7 & colors[7]='PURPLE'
	tvlct, 255, 127,   0, 8 & colors[8]='ORANGE'
	tvlct, 200, 100, 100, 9 & colors[9]='SALMON'
	tvlct,  10, 255, 150, 10 & colors[10]='AZUR'
	tvlct, 255,  65, 130, 11 & colors[11]='PINK'
	tvlct, 200, 195, 135, 12 & colors[12]='BEIGE'

end

;----------------------------------------------------------------------

;;old event handlers:
pro GPItvo_draw_color_event, event
	WIDGET_CONTROL, event.top, get_Uvalue = self
	self->draw_color_event, event
end
pro GPItvo_regionlabel_event, event
	WIDGET_CONTROL, event.top, get_Uvalue = self
	self->regionlabel_event, event
end

pro GPItvo_help_event, event
	WIDGET_CONTROL, event.top, get_Uvalue = self
	self->help_event, event
end

pro GPItvo_stats_event, event
  WIDGET_CONTROL, event.top, get_Uvalue = self
  self->stats_event, event
end

pro GPItvo_showstats3d_event, event
	WIDGET_CONTROL, event.top, get_Uvalue = self
	self->showstats3d_event, event
end

pro GPItvo_lineplot_event, event
	WIDGET_CONTROL, event.top, get_Uvalue = self
	self->lineplot_event, event
end
pro GPItvo_pixtable_event, event
	WIDGET_CONTROL, event.top, get_Uvalue = self
	self->pixtable_event, event
end

pro GPItvo_XXX_event, event
	WIDGET_CONTROL, event.top, get_Uvalue = self
	self->XXX_event, event
end
pro GPItvo_contrprof_event, event
	WIDGET_CONTROL, event.top, get_Uvalue = self
	self->contrprof_event, event
end
pro GPItvo_anguprof_event, event
  WIDGET_CONTROL, event.top, get_Uvalue = self
  self->anguprof_event, event
end
pro GPItvo_writeimage_event, event
  WIDGET_CONTROL, event.top, get_Uvalue = self
  self->writeimage_event, event
end
pro GPItvo_makemovie_event, event
  WIDGET_CONTROL, event.top, get_Uvalue = self
  self->makemovie_event, event
end



;;items removed from state:
spotlocationszoom_window_id:0L ,$
   spotlocationscursorpos_id:0L ,$
   spotlocationscursorpos_id2:0L ,$
   spotlocationscursorpos_id3:0L ,$
   spotlocationscursorpos_id4:0L ,$
   satloc1_id:0L ,$
   satloc2_id:0L ,$
   satloc3_id:0L ,$
   satloc4_id:0L ,$
   spotloclabel:0L ,$
   spotorder:0 ,$
spotlocations_save_id:0L ,$  
spotslocations:dblarr(4,2),$


;------------------------------------------------
pro oGPItv, image, $
         min = minimum, $
         max = maximum, $
         autoscale = autoscale,  $
         linear = linear, $
         log = log, $
         histeq = histeq, $
         block = block, $
         alignp = alignp, $
         alignwav = alignwav, $
         stretch = stretch, $
         header = header, $
         imname = imname, $
         smart = smart, $
         bmask = bmask, $
         exit = exit, $
         nbrsatspot=nbrsatspot, $
         satspotcalibfile=satspotcalibfile, $
         dispwavcalgrid=dispwavcalgrid,  $
         opt=opt, $
         multises=multises
	 
	 
	 
; Check for existence of array
if ( (n_params() NE 0) AND (size(image, /tname) NE 'STRING') AND $
   (size(image, /tname) EQ 'UNDEFINED')) then begin
    self->message, msgtype='error', 'Data array does not exist!'
    return
endif


G = obj_new('GPITV', image, $
         min = minimum, $
         max = maximum, $
         autoscale = autoscale,  $
         linear = linear, $
         log = log, $
         histeq = histeq, $
         block = block, $
         alignp = alignp, $
         alignwav = alignwav, $
         stretch = stretch, $
         header = header, $
         imname = imname, $
         smart = smart, $
         bmask = bmask, $
         exit = exit, $
         nbrsatspot=nbrsatspot, $
         satspotcalibfile=satspotcalibfile, $
         dispwavcalgrid=dispwavcalgrid,  $
         opt=opt, $
         multises=multises)



end

