;+
; NAME:
;   dirviewer
;
;	Derived from on "SELECTFITS" by Marshall Perrin
;	Based in turn on 'SELECTIMAGE' by David Fanning
;
; PURPOSE:
;
;   The purpose of this program is to allow the user to select
;   a FITS image file for reading. The image data is returned as the
;   result of the function. The best feature of this program is
;   the opportunity to browse the image before reading it.
;
; AUTHOR:
;
;   SELECTFITS is by Marshall Perrin  but is based heavily
;   upon SELECTIMAGE.PRO by David Fanning. See 
;   Coyote's Guide to IDL Programming: http://www.dfanning.com/
;
;
; CALLING SEQUENCE:
;
;   image = SelectFITS()
;
; INPUT PARAMETERS:
;
;   None. All input is via keywords.
;
; INPUT KEYWORDS:
;
;   DIRECTORY -- The initial input directory name. The current directory by default.
;
;   FILENAME -- The initial filename. If the initial directory has image files of the
;               correct type, the default is to display the first of these files. Otherwise, blank.
;
;
;   _EXTRA -- This keyword is used to collect and pass keywords on to the FSC_FILESELECT object. See
;             the code for FSC_FILESELECT for details.
;
;   GROUP_LEADER -- Set this keyword to a widget identifier group leader. This keyword MUST be
;                   set when calling this program from another widget program to guarantee modal operation.
;
;
;
;   PREVIEWSIZE -- Set this keyword to the maximum size (in pixels) of the preview window. Default is 150.
;
;   TITLE -- Set this keyword to the text to display as the title of the main image selection window.
;
; OUTPUT KEYWORDS:
;
;   CANCEL -- This keyword is set to 1 if the user exits the program in any way except hitting the ACCEPT button.
;             The ACCEPT button will set this keyword to 0.
;
;   FILEINFO -- This keyword returns information about the selected file. Obtained from the QUERY_**** functions.
;
;   OUTDIRECTORY -- The directory where the selected file is found.
;
;   OUTFILENAME -- The short filename of the selected file.
;
;   PALETTE -- The current color table palette returned as a 256-by-3 byte array.
;
;
; OTHER COYOTE LIBRARY FILES REQUIRED:
;
;  http://www.dfanning.com/programs/error_message.pro
;  http://www.dfanning.com/programs/fsc_fileselect.pro
;  http://www.dfanning.com/programs/cgimage.pro
;
;
; MODIFICATION HISTORY:
;
;	2004-05-01 	Split from David Fanning's SELECTIMAGE.PRO function. See
;	that file for modification history prior to this date.
;	2011-2012   Modifications and customizations for use with gpitv.
;
;-

;-------------------------------------------------------------------
PRO dirviewer_event, ev
	; simple wrapper to call object routine
    widget_control,ev.top,get_uvalue=storage
   
    if size(storage,/tname) eq 'STRUCT' then begin
		if obj_valid(storage.self) then storage.self->event, ev
	endif else storage->event, ev
end

;-------------------------------------------------------------------
PRO dirviewer_filename_event, ev
	; simple wrapper to call object routine
    widget_control,ev.top,get_uvalue=storage
   
    if size(storage,/tname) eq 'STRUCT' then storage.self->filename_event, ev else storage->filename_event, ev
end
;-------------------------------------------------------------------
PRO dirviewer_list_event, ev
	; simple wrapper to call object routine
    widget_control,ev.top,get_uvalue=storage
   
    if size(storage,/tname) eq 'STRUCT' then storage.self->list_event, ev else storage->list_event, ev
end

;-------------------------------------------------------------------

pro dirviewer::changedir,dir

  if dir ne '' then if file_test(dir,/dir) then begin
     (*self.state).directory=dir
     Widget_Control, self.top_base, Get_UValue=info
     Widget_Control, info.directoryID, Set_Value=(*self.state).directory
     self->refresh
  endif

end

;-------------------------------------------------------------------

pro dirviewer::show

;;bring to object to front
res = xregistered(self.xname)

end 

;-------------------------------------------------------------------

pro dirviewer::event, ev
	; main event handler routine

	uname = widget_info(ev.id,/uname)


	event_type = tag_names(ev, /structure_name)
	if event_type eq '' then event_type='CW_BGROUP' ; oddly doesn't get set itself?
	case event_type of
		'WIDGET_TIMER' : begin
			self->check_for_new
			if self.auto_load_new or self.auto_refresh then widget_control, ev.top, timer=self.check_period ; check again at 0.2 Hz
			return
		end


      'WIDGET_TRACKING': begin ; Mouse-over help text display:
        if (ev.ENTER EQ 1) then begin 
              case uname of 
                  'dir_name':textinfo='Current directory path.'
                  'changedir':textinfo='Click to select a different directory to view files in.'
                  'changedir_today':textinfo="Click to cd to today's IFS raw data dir"
                  'changedir_today_red':textinfo="Click to cd to today's IFS reduced data dir"
                  "Close":textinfo='Click to close this window.'
				  'ignore_indiv': textinfo="Ignore files for the individual reads of a CDS or UTR sequence."
				  'time_sort': textinfo='Sort files by modification time instead of alphabetically'
				  'auto_load_new': textinfo='Always automatically view the latest file in the directory.'
				  'auto_refresh': textinfo='Automatically refresh the files list every 5 s.'
				  'refresh': textinfo='Refresh the list of FITS filenames'
              else:textinfo=' '
              endcase
			  if keyword_set((*self.state).information_id) then widget_control,(*self.state).information_id,set_value=textinfo
        endif else begin 
			  if keyword_set((*self.state).information_id) then widget_control,(*self.state).information_id,set_value=''
        endelse 
        return
    end
	'WIDGET_BUTTON':begin
	   	if uname eq 'view_in_gpitv' then self->view_in_gpitv
	   	if uname eq 'refresh' then begin
            self->refresh
            self->highlight_selected
        endif
	   	if uname eq 'changedir' then begin
			dir = DIALOG_PICKFILE(PATH=(*self.state).directory, Title='Choose directory to scan...',/must_exist , /directory)
			self->changedir,dir
	   endif
 	   	if uname eq 'changedir_today' then begin
            dir = gpi_get_directory('GPI_RAW_DATA_DIR')+path_sep() + gpi_datestr(/current)
			if dir ne '' then if file_test(dir,/dir) then begin
				(*self.state).directory=dir
				Widget_Control, self.top_base, Get_UValue=info
	   			Widget_Control, info.directoryID, Set_Value=(*self.state).directory
				self->refresh
			endif
	   endif
  	   	if uname eq 'changedir_today_red' then begin
            dir = gpi_get_directory('GPI_REDUCED_DATA_DIR')+path_sep() + gpi_datestr(/current)
			if dir ne '' then if file_test(dir,/dir) then begin
				(*self.state).directory=dir
				Widget_Control, self.top_base, Get_UValue=info
	   			Widget_Control, info.directoryID, Set_Value=(*self.state).directory
				self->refresh
			endif
	   endif
 

		if (uname eq 'one') || (uname eq 'new') || (uname eq 'keep') then begin
		  if widget_info(self.parseone_id,/button_set) then self.parsemode=1
		  if widget_info(self.parseall_id,/button_set) then self.parsemode=3
		endif
		if uname eq 'flush' then begin
			self.parserobj=gpiparsergui(/cleanlist)
		endif
		  
		if uname eq 'alwaysexec' then begin
			self.alwaysexecute=widget_info(self.alwaysexecute_id,/button_set)
		endif
		
		if uname eq 'Close'    then begin
			  ;label0='Cancel',label1='Close', title='Confirm close') then begin
					  ;self.continue_scanning=0
					  ;wait, 1.5
					  obj_destroy, self
			;endif           
		endif
	end

	'CW_BGROUP':begin
		if uname eq 'ignore_indiv' then begin
			wid = Widget_Info(ev.top, Find_by_UName='ignore_indiv')
			widget_control, wid, get_value=val
			self.ignore_indiv = val
			print, "Ignore Individual reads set to "+strc(self.ignore_indiv)
			self->refresh
		endif
;		if uname eq 'live_view' then begin
;			wid = Widget_Info(ev.top, Find_by_UName='live_view')
;			widget_control, wid, get_value=val
;			self.live_view= val
;			print, "Auto GPItv view mode set to "+strc(self.live_view)
;		endif
		if uname eq 'time_sort' then begin
			wid = Widget_Info(ev.top, Find_by_UName='time_sort')
			widget_control, wid, get_value=val
			self.time_sort= val
			print, "Sort by time set to "+strc(self.time_sort)
			self->refresh
		endif
		if uname eq 'auto_refresh' then begin
			wid = Widget_Info(ev.top, Find_by_UName='auto_refresh')
			widget_control, wid, get_value=val
			self.auto_refresh= val
			print, "Automatic refresh File mode set to "+strc(self.auto_refresh)
			if self.auto_refresh then begin
				self->check_for_new
				widget_control, ev.top, timer=self.check_period ; check again at 1 Hz
			endif
		endif
	
		if uname eq 'auto_load_new' then begin
			wid = Widget_Info(ev.top, Find_by_UName='auto_load_new')
			widget_control, wid, get_value=val
			self.auto_load_new= val
			print, "Automatic New File Loading mode set to "+strc(self.auto_load_new)
			if self.auto_load_new then begin
				self->check_for_new
				widget_control, ev.top, timer=self.check_period ; check again at 1 Hz
			endif
		endif
		if uname eq 'fix_scales' then begin
			wid = Widget_Info(ev.top, Find_by_UName='fix_scales')
			widget_control, wid, get_value=val
			self.fix_scales= val
			print, "Fix display scale mode set to "+strc(self.fix_scales)
		endif
		if uname eq 'dir_name' then begin
			;wid = Widget_Info(ev.top, Find_by_UName='fix_scales')
			;widget_control, wid, get_value=val
			Widget_Control, self.top_base, Get_UValue=info
			if file_test(ev.value,/dir) then begin
				(*self.state).directory = ev.value
				self->refresh
			endif else begin
				message,/info, 'Invalid directory entered; staying in current directory.'
			endelse
	   		Widget_Control, info.directoryID, Set_Value=(*self.state).directory
		endif
		if uname eq 'file_pattern' then begin

			Widget_Control, self.top_base, Get_UValue=info
			;Widget_Control, ev.id, Get_UValue=theFilter
			*info.filter = ev.value
			;print, 'file_pattern', *info.filter
			Widget_Control, self.top_base, set_UValue=info
			self->Refresh
		endif



	end 

	'WIDGET_LIST':begin
		if uname eq 'filelist' then begin
            if ev.clicks eq 2 then begin
              	ind=widget_INFO(self.listfile_id,/LIST_SELECT)
            
			  	if self.filelist[ind] ne '' then begin
					message,/info,'You double clicked on '+self.filelist[ind]
              		;print, self.filelist[ind]
	              	;CALL_PROCEDURE, self.commande,self.filelist(ind),mode=self.parsemode
				endif
            endif
		endif
	end
	'WIDGET_BASE': begin ; base resize event handler
		widget_control, event.top, get_uval=uval


	  geom = widget_info(uval.wids.list, /geom)
	  ratio_x = (geom.scr_xsize)/geom.xsize*1.5
	  ratio_y = (geom.scr_ysize)/geom.ysize*1.5 ;I don't understand this. EMpirical hack alert!

		  ; need to convert pixels to lines (for y) and chars for (x)
		   widget_control, uval.wids.list, xsize=(event.x-uval.wids.padding[0])/ratio_x
		   widget_control, uval.wids.list, ysize=(event.y-uval.wids.padding[1])/ratio_y
		   print, (event.x-uval.wids.padding[0])/ratio_x, (event.y-uval.wids.padding[1])/ratio_y
	end
  	'WIDGET_KILL_REQUEST': begin ; kill request
		if dialog_message('Are you sure you want to close the Browse Directory viewer?', title="Confirm close", dialog_parent=ev.top, /question) eq 'Yes' then $
			obj_destroy, self
		return
	end
	
    else:   stop
endcase
end

;================================================================================



;-------------------------------------------------------------------

PRO dirviewer::CenterTLB, tlb, x, y, NoCenter=nocenter 
	; put window in center of screen?

	IF N_Elements(x) EQ 0 THEN xc = 0.5 ELSE xc = Float(x[0])
	IF N_Elements(y) EQ 0 THEN yc = 0.5 ELSE yc = 1.0 - Float(y[0])
	center = 1 - Keyword_Set(nocenter)

	screenSize = Get_Screen_Size()
	IF screenSize[0] GT 2000 THEN screenSize[0] = screenSize[0]/2 ; Dual monitors.
	xCenter = screenSize[0] * xc
	yCenter = screenSize[1] * yc

	geom = Widget_Info(tlb, /Geometry)
	xHalfSize = geom.Scr_XSize / 2 * center
	yHalfSize = geom.Scr_YSize / 2 * center

	XOffset = 0 > (xCenter - xHalfSize) < (screenSize[0] - geom.Scr_Xsize)
	YOffset = 0 > (yCenter - yHalfSize) < (screenSize[1] - geom.Scr_Ysize)
	Widget_Control, tlb, XOffset=XOffset, YOffset=YOffset

END


FUNCTION dirviewer::BSort, Array, Asort, INFO=info, REVERSE = rev
;
; NAME:
;       self->BSort
; PURPOSE:
;       Function to sort data into ascending order, like a simple bubble sort.
; EXPLANATION:
;       Original subscript order is maintained when values are equal (FIFO).
;       (This differs from the IDL SORT routine alone, which may rearrange
;       order for equal values)
;
; CALLING SEQUENCE:
;       result = self->BSort( array, [ asort, /INFO, /REVERSE ] )
;
; INPUT:
;       Array - array to be sorted
;
; OUTPUT:
;       result - sort subscripts are returned as function value
;
; OPTIONAL OUTPUT:
;       Asort - sorted array
;
; OPTIONAL KEYWORD INPUTS:
;       /REVERSE - if this keyword is set, and non-zero, then data is sorted
;                 in descending order instead of ascending order.
;       /INFO = optional keyword to cause brief message about # equal values.
;
; HISTORY
;       written by F. Varosi Oct.90:
;       uses WHERE to find equal clumps, instead of looping with IF ( EQ ).
;       compatible with string arrays, test for degenerate array
;       20-MAY-1991     JKF/ACC via T AKE- return indexes if the array to
;                       be sorted has all equal values.
;       Aug - 91  Added  REVERSE keyword   W. Landsman
;       Always return type LONG    W. Landsman     August 1994
;       Converted to IDL V5.0   W. Landsman   September 1997
;
        N = N_elements( Array )
        if N lt 1 then begin
                print,'Input to self->BSort must be an array'
                return, [0L]
           endif

        if N lt 2 then begin
            asort = array       ;MDM added 24-Sep-91
            return,[0L]    ;Only 1 element
        end
;
; sort array (in descending order if REVERSE keyword specified )
;
        subs = sort( Array )
        if keyword_set( REV ) then subs = rotate(subs,5)
        Asort = Array[subs]
;
; now sort subscripts into ascending order
; when more than one Asort has same value
;
             weq = where( (shift( Asort, -1 ) eq Asort) , Neq )

        if keyword_set( info ) then $
                message, strtrim( Neq, 2 ) + " equal values Located",/CON,/INF

        if (Neq EQ n) then return,lindgen(n) ;Array is degenerate equal values

        if (Neq GT 0) then begin

                if (Neq GT 1) then begin              ;find clumps of equality

                        wclump = where( (shift( weq, -1 ) - weq) GT 1, Nclump )
                        Nclump = Nclump + 1

                  endif else Nclump = 1

                if (Nclump LE 1) then begin
                        Clump_Beg = 0
                        Clump_End = Neq-1
                  endif else begin
                        Clump_Beg = [0,wclump+1]
                        Clump_End = [wclump,Neq-1]
                   endelse

                weq_Beg = weq[ Clump_Beg ]              ;subscript ranges
                weq_End = weq[ Clump_End ] + 1          ; of Asort equalities.

                if keyword_set( info ) then message, strtrim( Nclump, 2 ) + $
                                " clumps of equal values Located",/CON,/INF

                for ic = 0L, Nclump-1 do begin          ;sort each clump.

                        subic = subs[ weq_Beg[ic] : weq_End[ic] ]
                        subs[ weq_Beg[ic] ] = subic[ sort( subic ) ]
                  endfor

                if N_params() GE 2 then Asort = Array[subs]     ;resort array.
           endif

return, subs
end





FUNCTION dirviewer::Dimensions, image, $
	XSize=xsize, $         ; Output keyword. The X size of the image.
	YSize=ysize, $         ; Output keyword. The Y size of the image.
	TrueIndex=trueindex, $ ; Output keyword. The position of the "true color" index. -1 for 2D images.
	XIndex=xindex, $       ; Output keyword. The position or index of the X image size.
	YIndex=yindex          ; Output keyword. The position or index of the Y image size.

	; This function returns the dimensions of the image, and also
	; extracts relevant information via output keywords. Works only
	; with 2D and 3D images.

	; bail out if no image
	if n_elements(image) lt 2 then return,0

	; Get the number of dimensions and the size of those dimensions.

	ndims = Size(image, /N_Dimensions)
	dims =  Size(image, /Dimensions)

	; Is this a 2D or 3D image?

	xsize = dims[0]
	if ndims gt 1 then ysize = dims[1]
	trueindex = -1
	xindex = 0
	yindex = 1
	RETURN, dims
END; ----------------------------------------------------------------------------------------




PRO dirviewer::SetFilter, event

   ; Error handling.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = Error_Message(/Traceback)
   IF N_Elements(info) NE 0 THEN Widget_Control, event.top, Set_UValue=info, /No_Copy
   RETURN
ENDIF

; This event handler sets the filter for image data files.
Widget_Control, event.top, Get_UValue=info

   ; The filter is in the User Value of the button. Store it.

Widget_Control, event.id, Get_UValue=theFilter
*info.filter = theFilter

   ; Get the current filename.

Widget_Control, info.filenameID, Get_Value=filename

   ; Set the new filter in the Filename compound widget.

;info.filenameObj->SetProperty, Filter=theFilter

   ; Look in the data directory for the files.

CD, info.dataDirectory, Current=thisDirectory

   ; Locate appropriate files.

FOR j=0, N_Elements(*info.filter)-1 DO BEGIN

   specificFiles = Findfile((*info.filter)[j], Count=fileCount)
   IF fileCount GT 0 THEN IF N_Elements(theFiles) EQ 0 THEN $
      theFiles = specificFiles[self->BSort(StrLowCase(specificFiles))] ELSE $
      theFiles = [theFiles, specificFiles[self->BSort(StrLowCase(specificFiles))]]
ENDFOR
fileCount = N_Elements(theFiles)
IF fileCount EQ 0 THEN BEGIN
   theFiles = ""
   filename = ""
ENDIF ELSE BEGIN
   filename = theFiles[0]
ENDELSE

   ; Update the widget interface according to what you found.

;Widget_Control, info.filenameID, Set_Value=filename

Widget_Control, info.fileListID, Set_Value=theFiles
IF fileCount GT 0 THEN Widget_Control, info.fileListID, Set_List_Select=0
*info.theFiles = theFiles

   ; Is this a valid image file name. If so, go get the image.
	self->Update,filename,fileInfo,r,g,b,info.previewsize,image,info
; clean up
CD, thisDirectory
Widget_Control, event.top, Set_UValue=info, /No_Copy

END; ----------------------------------------------------------------------------------------



PRO dirviewer::Filename_Event, event

   ; Error handling.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = Error_Message(/Traceback)
   IF N_Elements(info) NE 0 THEN Widget_Control, event.top, Set_UValue=info, /No_Copy
   RETURN
ENDIF

if not dir_exist(event.directory) then return

Widget_Control, event.top, Get_UValue=info

   ; Get the name of the file.

filename = event.basename
CD, event.directory, Current=thisDirectory

   ; Locate appropriate files.

Ptr_Free, info.theFiles
info.theFiles = Ptr_New(/Allocate_Heap)

FOR j=0, N_Elements(*info.filter)-1 DO BEGIN

   specificFiles = Findfile((*info.filter)[j], Count=fileCount)
   IF fileCount GT 0 THEN IF N_Elements(*(info.theFiles)) EQ 0 THEN $
      *info.theFiles = specificFiles[self->BSort(specificFiles)] ELSE $
      *info.theFiles = [*info.theFiles, specificFiles[self->BSort(specificFiles)]]
ENDFOR
fileCount = N_Elements(*info.theFiles)
IF fileCount EQ 0 THEN *info.theFiles = "" ELSE BEGIN
   IF filename EQ "" THEN filename = (*info.theFiles)[0]
ENDELSE
info.dataDirectory = event.directory

   ; Is the filename amoung the list of files? If not,
   ; chose another filename.

index = Where(StrLowCase(*info.theFiles) EQ StrLowCase(filename), count)
IF count EQ 0 THEN BEGIN
   filename = (*info.theFiles)[0]
   Widget_Control, info.filenameID, Set_Value=filename
ENDIF

Widget_Control, info.fileListID, Set_Value=*info.theFiles

   ; Can you find the filename in the list of files? If so,
   ; highlight it in the list.

i = Where(StrUpCase(*info.theFiles) EQ StrUpCase(filename), count)
IF count GT 0 THEN Widget_Control, info.filelistID, Set_List_Select=i


   ; Is this a valid image file name. If so, go get the image.

self->Update,filename,fileInfo,r,g,b,info.previewsize,image,info
; clean up
CD, thisDirectory
Widget_Control, event.top, Set_UValue=info, /No_Copy

END 

;---------------------------------------------------------------------------------

pro dirviewer::refresh

	Widget_Control, self.top_base, Get_UValue=info

	Ptr_Free, info.theFiles
	info.theFiles = Ptr_New(/Allocate_Heap)

	dir = (*self.state).directory;+path_sep()

	FOR j=0, N_Elements(*info.filter)-1 DO BEGIN

		; do it this way to get just the filenames w/out paths:
		cd, dir, current=current_dir
	   	specificFiles = Findfile((*info.filter)[j], Count=fileCount)
		cd, current_dir

	   	if self.ignore_indiv then begin
			is_indiv = stregex(specificFiles, '_[0-9][0-9][0-9].fits$',/boolean)
			wgood = where(~ is_indiv)
			specificFiles=specificFiles[wgood]
		endif
        ; Always ignore .writing files as well
			is_writing = stregex(specificFiles, '.fits.writing$',/boolean)
			wgood = where(~ is_writing)
			specificFiles=specificFiles[wgood]

	   IF fileCount GT 0 THEN IF N_Elements(*(info.theFiles)) EQ 0 THEN $
		  *info.theFiles = specificFiles[self->BSort(specificFiles)] ELSE $
		  *info.theFiles = [*info.theFiles, specificFiles[self->BSort(specificFiles)]]
	ENDFOR

	if keyword_set(self.time_sort) and n_elements(*info.theFiles) gt 0 then begin
		specificfiles = *info.theFiles	
		fileinfo = file_info(specificfiles[0])
		fileinfos = replicate(fileinfo, n_elements(specificfiles))
		for j=0,n_elements(specificfiles)-1 do fileinfos[j] = file_info(specificfiles[j])

		sorter = sort(fileinfos.mtime)
		*info.theFiles = (*info.theFiles)[sorter]

	endif



	fileCount = N_Elements(*info.theFiles)
	IF fileCount EQ 0 THEN *info.theFiles = "" ELSE BEGIN
	   IF (*self.state).filename EQ "" THEN (*self.state).filename = (*info.theFiles)[0]
	ENDELSE
	info.dataDirectory = (*self.state).directory

	Widget_Control, info.fileListID, Set_Value=*info.theFiles

	Widget_Control, self.top_base, Set_UValue=info, /No_Copy

	self->highlight_selected

   	; Is the previously selected filename amoung the list of files? If not,
   	; chose another filename.

	;index = Where(StrLowCase(*info.theFiles) EQ StrLowCase( file_basename((*self.state).filename)), count)
	;IF count EQ 0 THEN BEGIN
	   ;(*self.state).filename = (*info.theFiles)[0]
	   ;Widget_Control, info.filenameID, Set_Value=(*self.state).filename
	;ENDIF


	   ; Can you find the filename in the list of files? If so,
	   ; highlight it in the list.

	;i = Where(StrLowCase(*info.theFiles) EQ StrLowCase( (*self.state).filename), count)
	;IF count GT 0 THEN Widget_Control, info.filelistID, Set_List_Select=i

	; Is this a valid image file name. If so, go get the image.

	;self->Update,file_basename((*self.state).filename),fileInfo,r,g,b,info.previewsize,image,info


end

;---------------------------------------------------------------------------------

pro dirviewer::highlight_selected, filename
	if keyword_set(filename) then (*self.state).filename = filename

	Widget_Control, self.top_base, Get_UValue=info
	
   	; Is the selected filename actually a valid filename amoung the list of files? 
	; If not, chose another filename.
	; If so, highlight it in the list

	index = Where(StrLowCase(*info.theFiles) EQ StrLowCase( file_basename((*self.state).filename)), count)
	IF count EQ 0 THEN BEGIN
	   (*self.state).filename = (*info.theFiles)[0]
	   Widget_Control, info.filenameID, Set_Value=(*self.state).filename
	ENDIF else begin
		Widget_Control, info.filelistID, Set_List_Select=index
	endelse

	; Set it in the Filename widget.
	Widget_Control, info.filenameID, Set_Value=filename

	; Is this a valid image file name. If so, go get the image.

	self->Update,file_basename((*self.state).filename),fileInfo,r,g,b,info.previewsize,image,info

	Widget_Control, self.top_base, Set_UValue=info, /No_Copy


end

;---------------------------------------------------------------------------------

pro dirviewer::check_for_new

	; save current file names 
	Widget_Control, self.top_base, Get_UValue=info,/no_copy
	old_filelist =*info.theFiles
	Widget_Control, self.top_base, Set_UValue=info, /No_Copy

	; Refresh
	self->refresh

	; get new file names
	Widget_Control, self.top_base, Get_UValue=info,/no_copy
	new_filelist =*info.theFiles
	Widget_Control, self.top_base, Set_UValue=info, /No_Copy

	; see if there are any new ones
	newfiles = cmset_op(new_filelist, 'and',/not2, old_filelist, count=count)
	if count gt 0 and keyword_set(self.auto_load_new) then begin
		;print, "New files detected:"
		;print, newfiles
		; just use the first
		newfile = newfiles[0]

		;(*self.state).filename = newfile
		self->highlight_selected, newfile


	endif
	
	

end


;---------------------------------------------------------------------------------


PRO dirviewer::List_Event, event

   ; Only handle single click events.

   ; Error handling.

   if 0 then begin
	Catch, theError
	IF theError NE 0 THEN BEGIN
	   Catch, /Cancel
	   ok = Error_Message(/Traceback)
	   IF N_Elements(info) NE 0 THEN Widget_Control, event.top, Set_UValue=info, /No_Copy
	   RETURN
	ENDIF
   endif

	IF event.clicks NE 1 AND event.clicks NE 2 THEN RETURN

	Widget_Control, event.top, Get_UValue=info

	; Get the name of the file.
	if not ptr_valid(info.thefiles) then begin
		message,/info, 'No valid files available'
		return
	endif

	filename = (*info.theFiles)[event.index]

	; Set it in the Filename widget.
	Widget_Control, info.filenameID, Set_Value=filename

	; Is this a valid image file name. If so, go get the image.
	self->Update,filename,fileInfo,r,g,b,info.previewsize,image,info, directory=info.dataDirectory+"/"

	Widget_Control, event.top, Set_UValue=info, /No_Copy

END ;---------------------------------------------------------------------------------


PRO dirviewer::Update,file,fileInfo,r,g,b,previewsize,image,info, directory=directory

	if ~(keyword_set(directory)) then directory = (*self.state).directory+path_sep()
        ; Is this a valid image file name. If so, go get the image.

	image = BytArr(previewsize, previewsize)
	fileInfo = {channels:2, dimensions:[previewsize, previewsize], naxes: 2, naxis: ''}

	IF file NE "" THEN BEGIN
		(*self.state).filename = directory+file
		 ;ok = Query_FITS(file, fileInfo)
		 ;IF ok THEN 
		 image = Readfits(directory+file,/silent, header) 

		 if n_elements(image) eq 1 then begin
			 ; try extension?
			image = Readfits(directory+file,/silent, ext=1, header) 
			 
		endif
		sz = size(image)
		fileinfo.naxes = sz[0]
		if fileinfo.naxes eq 2 then begin
			fileinfo.naxis = aprint([sxpar(header,"NAXIS1"),sxpar(header,"NAXIS2")])
		endif else begin
			fileinfo.naxis = aprint([sxpar(header,"NAXIS1"),sxpar(header,"NAXIS2"),sxpar(header,"NAXIS3")])
		endelse

		 if fileinfo.naxes gt 2 then image = image[*,*,0]

	ENDIF else begin
		; no files found - filename is blank?
		return
	endelse

	; What kind of image is this?
	xsize = fileInfo.dimensions[0]
	ysize = fileInfo.dimensions[1] 

	; Get the file sizes.
	dimensions = self->Dimensions(image, XSize=xsize, YSize=ysize, YIndex=yindex)

	if n_elements(dimensions) lt 1 then begin
		message,/info, "ERROR: "+file+ " is not a 2 or 3D image. Can't display"
		image = fltarr(10,10)
		xsize=10 & ysize=10
		return
	endif

	xten = strcompress(sxpar(header, 'XTENSION'), /remove_all)
	if (xten EQ 'BINTABLE') then begin
		message, /info, "ERROR: File"+file+ " appears to be a FITS table, not an image. Can't display."
		image = fltarr(10,10)
		xsize=10 & ysize=10
		return
	endif

	; Calculate a window size for the image preview.
	aspect = Float(xsize) / ysize
	IF aspect GT 1 THEN BEGIN
	   wxsize = Fix(info.previewSize)
	   wysize = Fix(info.previewSize / aspect) < info.previewSize
	ENDIF ELSE BEGIN
	   wysize = Fix(info.previewSize)
	   wxsize = Fix(info.previewSize / aspect) < info.previewSize
	ENDELSE


	; Update the display with what you have.
	Widget_Control, info.labelnaxesID, Set_Value="NAXES: " + strcompress(string(fileinfo.naxes),/remove_all) +"        NAXIS: " + (fileinfo.naxis)
	;Widget_Control, info.labelnaxisID, Set_Value="NAXIS: " + (fileinfo.naxis)
	(*self.state).min_value = Min(image,/NAN)
	(*self.state).max_value = Max(image,/NAN)

	;Widget_Control, info.labelminvalID, Set_Value="Min Value: " + (string((*self.state).min_value,format="(G9.4)"))
	;Widget_Control, info.labelmaxvalID, Set_Value="Max Value: " + (string((*self.state).max_value ,format="(G9.4)"))

	; Draw the preview image.

	WSet, info.previewWID

	; TODO: resize image down before scaling here? 

	scaled_image = self->scaleimage( image[*,*,0] )
	loadct,0,/silent
	cgImage, scaled_image, /Keep_Aspect, /NoInterpolation


	;if keyword_set(self.live_view) then 
	self->view_in_gpitv

end


;---------------------------------------------------------------------------------


PRO dirviewer::Cleanup
	; cleanup routine called when the object is destroyed.
	;
	; Invokes window cleanup by destroying the TLB

	if (xregistered (self.xname) gt 0) then widget_control,self.top_base,/destroy
	if ptr_valid(self.parent_gpitv) then ptr_free, self.parent_gpitv
	ptr_free, self.state
	heap_gc

END 

pro dirviewer_cleanup, tlb
	;print, "dirviewer window cleanup"
	; this is the cleanup routine called when the TLB is closed
	; Based on DFanning's example at
	; http://www.idlcoyote.com/tip_examples/owindow.pro
	Widget_Control, tlb, Get_UValue=info, /No_Copy
	IF N_Elements(info) gt 0 THEN begin
		Ptr_Free, info.theFiles
		Ptr_Free, info.filter
		ptr_free, (*info.storageptr).image
		ptr_free, (*info.storageptr).fileinfo
		ptr_free, info.storageptr
	endif
	if obj_valid(info.self) then obj_destroy, info.self
	heap_gc

end

;---------------------------------------------------------------------------------
PRO dirviewer::setscaling,scaling
	; copied from gpitv (with mods)

  scalings = [ 'Linear', 'Log',  'HistEq', 'Square Root', 'Asinh']
	(*self.state).scaling = scaling

end
;---------------------------------------------------------------------------------
function dirviewer::scaleimage, main_image
	; copied from gpitv (with mods)

	; Create a byte-scaled copy of the image, scaled according to
	; the (*self.state).scaling parameter.  
	;
	; We add 8 to the value returned from bytscl to get above the 8 primary
	; colors which are used for overplots and annotations. We use a mask to
	; only do this for non NAN pixels, so all NANs will always remain black,
	; no matter what color the bottom of the color map is.


	; Since this can take some time for a big image, set the cursor
	; to an hourglass until control returns to the event loop.

    ; MP disable since is annoying when auto refresh is set
    ;	widget_control, /hourglass

	;print, size(main_image)
	
	; ignore floating underflow in this routine
	except = !except
	!except=0


	nan_mask = main_image eq main_image ; mask out NAN pixels
	case (*self.state).scaling of
    0: scaled_image = $                 ; linear stretch
      bytscl(main_image, $
             /nan, $
             min=(*self.state).min_value, $
             max=(*self.state).max_value, $
             top = !D.Table_Size-1) ; (*self.state).ncolors - 1) + 8*nan_mask

    1: begin                            ; log stretch
		; M Perrin  - quick hack, force the bottom to 0 for all log scale
		; images
		real_min = (*self.state).min_value
		(*self.state).min_value = 0

		; avoid floating underflow
		ma = machar()
        offset = (*self.state).min_value - $
          ((*self.state).max_value - (*self.state).min_value) * 0.01

        scaled_image = $
          bytscl( alog10((main_image - offset)>ma.xmin ), $
                  min=alog10(0- offset), /nan, $
                  ;min=alog10((*self.state).min_value - offset), /nan, $
                  max=alog10((*self.state).max_value - offset),  $
             	top = !D.Table_Size-1) ; (*self.state).ncolors - 1) + 8*nan_mask
                  ;top=(*self.state).ncolors - 1) + 8*nan_mask
		(*self.state).min_value = real_min
    end


    2: scaled_image = $                 ; histogram equalization
      bytscl(hist_equal(main_image, $
                        minv = (*self.state).min_value, $
                        maxv = (*self.state).max_value), $
             /nan, $
             	top = !D.Table_Size-1) ; (*self.state).ncolors - 1) + 8*nan_mask

    3: begin                            ; square root stretch
        scaled_image = $
          bytscl( sqrt(main_image), $
                  min=sqrt((*self.state).min_value), /nan, $
                  max=sqrt((*self.state).max_value),  $
             	top = !D.Table_Size-1) ; (*self.state).ncolors - 1) + 8*nan_mask
                  ;top=(*self.state).ncolors - 1) + 8*nan_mask
    end
	4: begin				; asinh stretch. requires Dave Fanning's ASINHSCL.PRO
							; this is a hybrid of the DFanning code with Barth's
							; ATV version. UNTESTED - 2008-10 20 MDP
		scaled_image = asinhscl( main_image, $
				min = (*self.state).min_value, $
				max = (*self.state).max_value,$
				omax = (*self.state).ncolors - 1,$
				beta = (*self.state).asinh_beta  $
			;	,nonlinearity = nonlinearity_value ;JM removed, it gave me the error Keyword NONLINEARITY not allowed in call to: ASINHSCL
			) + 8*nan_mask


	end

	endcase

        ; discard any floating point underflows that may have just happened
        !except=0
        res = check_math()
        ; go back to saved exception-handling state
        !except=except

	return, scaled_image
end

;----------------------------------------------------------------------


FUNCTION dirviewer::init, $
   parent_gpitv=parent_gpitv, $	; handle of parent GPITV sessions
   Directory=directory, $       ; Initial directory to search for files.
   FileInfo=fileInfo, $         ; An output keyword containing file information from the Query_*** routine.
   Filename=filename, $         ; Initial file name of image file.
   _Extra=extra, $              ; This is used to pass keywords on to FSC_FILESELECT. See that documentation for details.
   Group_Leader=group_leader, $ ; The group leader ID of this widget program.
   Palette=palette, $           ; The color palette associated with the file.
   TITLE=title, $               ; The title of the main image selection window.
   PreviewSize=previewsize      ; The maximum size of the image preview window. 150 pixels by default.
  
  print, 'initializing GPItv directory viewer'
  self.ignore_indiv=1
  ;self.live_view = 1
  ; if we're at Gemini, new files may be arriving at any time, and the filenames
  ; may not be strictly increasing alphabetically if we're toggling between
  ; Engineering and Science readouts
  self.time_sort= gpi_get_setting('at_gemini', default=0,/silent)
  self.auto_refresh=gpi_get_setting('at_gemini', default=0,/silent)
  self.auto_load_new=0
  self.check_period=5
  
  if ~ keyword_set(parent_gpitv) then begin
     message,/info, 'invoked without any gpitv yet - starting new session'
     parent_gpitv = obj_new()
     session = -1
  endif else session=parent_gpitv->get_Session()
  self.parent_gpitv = parent_gpitv


  ;; Set up the filter.

  at_gemini = keyword_set(gpi_get_setting('at_gemini', /bool,default=0,/silent))
  if keyword_set(at_gemini) then default_filter = ['S20'+gpi_datestr(/current)+"*.fits"] else default_filter=['*.fits']
  IF N_Elements(filter) EQ 0 THEN filter = default_filter

  only2D = Keyword_Set(only2d)
  only3D = Keyword_Set(only3d)
  IF N_Elements(title) EQ 0 THEN title = 'Browse Images in Directory'

  ;; Get the current directory. Some processing involved.

  CD, Current=startDirectory
  IF N_Elements(directory) EQ 0 THEN directory = startDirectory ELSE BEGIN
     IF StrMid(directory, 0, 2) EQ ".." THEN BEGIN
        CD, '..'
        CD, Current=basename
        directory = basename + StrMid(directory, 2)
     ENDIF
     IF StrMid(directory, 0, 1) EQ "." THEN BEGIN
        CD, Current=basename
        directory = basename + StrMid(directory, 1)
     ENDIF
  ENDELSE
  CD, directory

  ;; Check other keyword values.

  IF N_Elements(filename) EQ 0 THEN file = "" ELSE BEGIN
     dir=StrMid(filename, 0, StrPos(filename, Path_Sep(), /REVERSE_SEARCH))
     IF dir NE "" THEN BEGIN
        directory = dir
        CD, directory
        file = StrMid(filename, StrLen(directory)+1)
     ENDIF ELSE file = filename
  ENDELSE
  IF N_Elements(previewSize) EQ 0 THEN previewSize = 270

  theFiles = ""
  filename = ""

  ;; Get the file sizes.

  ;; Create the widgets.

  tlb = Widget_Base(Title=title, Column=1, /Base_Align_Center, Group_Leader=group_leader,/tlb_kill_request_events)

  fileSelectBase = Widget_Base(tlb, Column=1, Frame=0)
  information_id= Widget_label(tlb, value="                                                                ") ; status bar
  buttonBase = Widget_Base(tlb, Row=1)
  buttonBase2 = Widget_Base(tlb, Row=1)

  ;; Define file selection widgets.

  rowbase = widget_base(fileSelectBase, /row, frame=0)
  directoryID = cw_field(rowbase,title='Directory:', value=directory, uname='dir_name', xsize=50,/return_events)
  button = Widget_Button(rowBase, Value='Change...', uname='changedir',/tracking_events)
  button = Widget_Button(rowBase, Value="Today's raw", uname='changedir_today',/tracking_events)
  rowbase = widget_base(fileSelectBase, /row, frame=0)
  filenameID = cw_field(rowbase,title= 'Filename: ', value='', xsize=50)
  button = Widget_Button(rowBase, Value="Today's reduced", uname='changedir_today_red',/tracking_events)

  fsrowbaseID = Widget_Base(fileSelectBase, /Row, XPad=10, frame=1)
  xsize = Max(StrLen(theFiles)) + 0.1*Max(StrLen(theFiles)) > 20

  colbase1 = widget_base(fsrowbaseID, /col)
  f2 = cw_field(colbase1,title='Pattern:', value = filter, xsize=15, uname='file_pattern', /all_events)

  filelistID = Widget_List(colbase1, Value=theFiles, YSize = 15, XSize=xsize, event_pro='dirviewer_list_event')


  spacer = Widget_Label(fsrowbaseID, Value="  ")

  colbase2 = widget_base(fsrowbaseID, /col)
  previewID = Widget_Draw(colbase2, XSize=previewSize, YSize=previewSize)
                                ;spacer = Widget_Label(fsrowbaseID, Value="  ")

  labelBaseID = Widget_Base(fileSelectBase, Column=1, /Base_Align_Left, frame=0)
  imageType = '2D Image'
  xsize = 0
  ysize = 0
  imageDataType = Size(image, /TNAME)
  labelNAXESID = Widget_Label(labelBaseID, Value="NAXES: " + StrTrim(0,2), /Dynamic_Resize)
  ;labelNAXISID = Widget_Label(labelBaseID, Value="NAXIS: " + StrTrim(0,2), /Dynamic_Resize)
  ;labelminvalID = Widget_Label(labelBaseID, Value="Min Value: " + StrTrim(0,2), /Dynamic_Resize)
  ;labelmaxvalID = Widget_Label(labelBaseID, Value="Max Value: " + StrTrim(0,2), /Dynamic_Resize)


  ;; Size the draw widget appropriately.
  ;; Calculate a window size for the image preview.

  IF xsize NE ysize THEN BEGIN
     aspect = Float(ysize) / xsize
     IF aspect LT 1 THEN BEGIN
        wxsize = previewSize
        wysize = (previewSize * aspect) < previewSize
     ENDIF ELSE BEGIN
        wysize = previewSize
        wxsize = (previewSize / aspect) < previewSize
     ENDELSE
  ENDIF

  ;; Can you find the filename in the list of files? If so,
  ;; highlight it in the list.

  index = Where(StrUpCase(theFiles) EQ StrUpCase(file), count)
  IF count GT 0 THEN Widget_Control, filelistID, Set_List_Select=index

  ;; Define buttons widgets.
;  button = cw_bgroup(buttonBase, " ", label_left='Ignore indiv reads?', /nonexclusive, uvalue="ignore_indiv",uname='ignore_indiv', set=self.ignore_indiv)
;  button = cw_bgroup(buttonBase, " ", label_left='Auto GPItv?', /nonexclusive, uvalue="live_view", uname='live_view', set=self.live_view)
  button = cw_bgroup(buttonBase, " ", label_left='Auto refresh?', /nonexclusive, uvalue="auto_refresh", uname='auto_refresh', set=self.auto_refresh)
  button = cw_bgroup(buttonBase, " ", label_left='Auto load new files?', /nonexclusive, uvalue="auto_load_new", uname='auto_load_new', set=self.auto_load_new)
  button = cw_bgroup(buttonBase, " ", label_left='Sort by time?', /nonexclusive, uvalue="time_sort", uname='time_sort', set=self.time_sort)
  ;button = cw_bgroup(buttonBase, " ", label_left='Fixed scale?', /nonexclusive, uvalue="fix_scales", uname='fix_scales', set=self.fix_scales)
  button = Widget_Button(buttonBase2, Value='View in GPItv', uname='view_in_gpitv',/tracking_events)
  button = Widget_Button(buttonBase2, Value='Refresh', uname='refresh',/tracking_events)
  button = Widget_Button(buttonBase2, Value='Close', uname='Close',/tracking_events)


  ;;self->CenterTLB, tlb
  Widget_Control, tlb, /Realize
  Widget_Control, previewID, Get_Value=previewWID

  ;; Set up RGB color vectors.

  IF N_Elements(r) EQ 0 THEN r = Bindgen(!D.Table_Size)
  IF N_Elements(g) EQ 0 THEN g = Bindgen(!D.Table_Size)
  IF N_Elements(b) EQ 0 THEN b = Bindgen(!D.Table_Size)
  WSet, previewWID
  TVLCT, r, g, b

  ;; In some old bitmap files, the RGB vectors can be
  ;; less than 256 in length. That will cause problems,
  ;; as I have learned today. :-(

  IF N_Elements(r) LT 256 THEN BEGIN
     rr = BIndgen(256)
     gg = rr
     bb = rr
     rr[0] = r
     gg[0] = g
     bb[0] = b
     r = rr
     g = gg
     b = bb
  ENDIF

  ;; Set up information to run the program.

  storagePtr = Ptr_New({cancel:1, image:Ptr_New(image), fileInfo:Ptr_New(fileInfo), $
                        outdirectory:"", outfilename:"", r:r, g:g, b:b})

  info = {self: obj_new(), $              ; an object handle for itself, for use in widget routines
          storagePtr: storagePtr, $       ; The "outside the program" storage pointer.
          previewID: previewID, $         ; The ID of the preview draw widget.
          previewWID: previewWID, $       ; The window index number of the preview draw widget.
          theFiles: Ptr_New(theFiles), $  ; The current list of files in the directory.
                                ;filenameID: filenameID, $           ; The identifier of the FileSelect compound widget.
          filenameID: filenameID, $      ; The identifier of the filename entry widget.
          directoryID: directoryID, $    ; The identifier of the directory entry widget.
          fileListID: fileListID, $      ; The identifier of the file list widget.
          previewSize: previewSize, $    ; The default size of the preview window.
          filter: Ptr_New(filter), $     ; The file filter.
                                ;filenameObj: filenameObj, $         ; The FileSelect compound widget object reference.
          dataDirectory: directory, $    ; The current data directory.
          labelNAXESID: labelNAXESID $  ; The ID of the NAXES label
          ;labelNAXISID: labelNAXISID, $  ; The ID of the NAXIS label
          ;labelmaxvalID: labelmaxvalID, $ ; The ID of the Max Value label.
          ;labelminvalID: labelminvalID $  ; The ID of the Max Value label.
         }

  state = {scaling: 1, $        ; coded this way for compatibilty with gpitv code
           min_value: 0.0, $
           max_value: 0.0, $
           ncolors: !d.table_size, $
           asinh_beta: 500.0, $
           directory: '', $                 ; Directory currently being watched
           filename: '', $                  ; currently selected filename
           information_id: information_id,$ ; widget ID for status bar
           dummy: 0}

  self.state = ptr_new(state,/no_copy)
  (*self.state).directory=directory
  info.self = self

  self->Update,file,fileInfo,r,g,b,previewsize,image,info

  Widget_Control, tlb, Set_UValue=info, /No_Copy
  self.top_base = tlb
  
  ;; Blocking or modal widget mode, depending upon presence of GROUP_LEADER.


  self.xname = 'gpitv_dirviewer_'+strc(session)

  ;; Realize the widgets and run XMANAGER to manage them.
  ;; Register the widget with xmanager if it's not already registered
  if (not(xregistered(self.xname, /noshow))) then begin
     WIDGET_CONTROL, self.top_base, /REALIZE
     XMANAGER, self.xname, self.top_base, /NO_BLOCK, event_handler = 'dirviewer_event', cleanup='dirviewer_cleanup'
  endif


  self->refresh                 ; get list of files

  if self.auto_load_new or self.auto_refresh then widget_control, self.top_base, timer=self.check_period ; check again at 0.2 Hz

  return, 1

END


;================================================================================

pro dirviewer::view_in_gpitv
  ;; View the current file in GPITV

  if keyword_set((*self.state).filename) and obj_valid(self.parent_gpitv) then begin

     ;; If nothing has changed, don't needlessly redisplay
     if (*self.state).filename eq self.last_filename then return 

     self.parent_gpitv->message, msgtype = 'information', "Opening in GPItv: "+(*self.state).filename
                                ;print, "Scan Dir opening in GPItv: "+(*self.state).filename
                                ;message,/cont, "opening in GPItv: "+(*self.state).filename
     self.parent_gpitv->open, (*self.state).filename, /noresize, keepstretch=keyword_set(self.fix_scales)
     self.last_filename = (*self.state).filename 
  endif
end



;================================================================================

pro dirviewer__define

; create a structure that holds an instance's information
struct={dirviewer, $
		top_base: 0, $				; widget ID of top level base
		xname: '', $				; X session name
		parent_gpitv: obj_new(), $ ; handle of the parent gpitv object
		ignore_indiv: 1, $			; Ignore individual read files
		time_sort: 1, $				; Sort by time rather than by alphabetical filename
		auto_refresh: 0, $			; Auto refresh files list at 1 Hz
		auto_load_new: 0, $			; Auto view latest file
        last_filename: '' , $          ; last filename sent to gpitv
		check_period: 5, $			; how often to check for new files if auto_load_new?
		fix_scales: 0, $			; Keep display scale stretch fixed? 
		state: ptr_new() $
       }

end
