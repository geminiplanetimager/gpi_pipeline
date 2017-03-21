;+
; GPITV: A modified version of ATV, written by Jerome Maire & Marshall Perrin.
;
; NAME:
;       GPItv
;
; PURPOSE:
;       Interactive display of 2-D or 3-D GPI images.
;
; CATEGORY:
;       Image display.
;
; CALLING SEQUENCE:
;       GPItv [,array_name OR fits_file] [header],[,min = min_value][,max=max_value]
;           [,/linear|/log|,/histeq|/asinh|/sqrt] [,/block] [,/exit]
;           [,header = header][extensionhead = extenshionhead]
;           [,nbrsatspot=nbrsatspot][/dispwavecalgrid]
;
; REQUIRED INPUTS:
;       None.  If GPItv is run with no inputs, the window widgets
;       are realized and images can subsequently be passed to GPItv
;       from the command line or from the pull-down file menu.
;
; OPTIONAL INPUTS:
;       array_name: a 2-D or 3-D data array to display
;          OR
;       fits_file:  a fits file name, enclosed in single quotes
;       header:     Primary FITS header (string array) or array of
;                   pointers to primary and extension headers
;
; KEYWORDS:
;       multises    gpitv session number
;       /block      block IDL command line until GPItv terminates
;       /exit       End gpitv session
;       nbrsatspot  Number of satspots (currently unused)
;       min:        minimum data value to be mapped to the color table
;       max:        maximum data value to be mapped to the color table
;       /linear:    use linear stretch
;       /log:       use log stretch
;       /histeq:    use histogram equalization
;       /asinh:     use asinh stretch
;       header:     FITS image header (string array) (overwritten by named input)
;       extensionhead: FITS extension header (string array) (overwritten by named input)
;       /dispwavecalgrid: Name of wavelength calibration to display
;
; OUTPUTS:
;       None.
;
; COMMON BLOCKS:
; 		NONE!
;
; RESTRICTIONS:
;       Requires IDL version 5.1 or greater.
;       Requires Craig Markwardt's cmps_form.pro routine.
;       Requires the GSFC IDL astronomy user's library routines.
;       Some features may not work under all operating systems.
;
; SIDE EFFECTS:
;       Modifies the color table.
;
; EXAMPLE:
;       To start GPItv running, just enter the command 'GPItv' at the idl
;       prompt, either with or without an array name or fits file name
;       as an input.  Only one GPItv window will be created at a time,
;       so if one already exists and another image is passed to GPItv
;       from the idl command line, the new image will be displayed in
;       the pre-existing GPItv window.
;
; MODIFICATION HISTORY:
;       ATV Written by Aaron J. Barth, with other contributions
;	GPITV written by Jerome Maire & Marshall Perrin including datacubes view, contrast plot,
;					multi-session mode (no ATV-freezing), units, "spaxel" mode,
;					angular profile, collapse,...
;----------------------------------------------------------------------
;        GPItv startup, initialization, and shutdown routines
;----------------------------------------------------------------------

pro GPItv::initcommon

  ; Routine to initialize the GPItv common blocks.  Use common blocks so
  ; that other IDL programs can access the GPItv internal data easily.

  self.images.main_image = ptr_new(/alloc)			; current active image, or slice if datacube
  self.images.main_image_stack = ptr_new(/alloc)	; full datacube stack
  self.images.main_image_backup = ptr_new(/alloc)	; full datacube (unmodified, in case we high pass filter etc)
  self.images.names_stack = ptr_new(/alloc)			; descriptive names for each slice of stack
  self.images.display_image = ptr_new(/alloc)		; the image which is actually displayed on screen (subarrayed and/or zoomed to the relevant piece from the scaled image)
  self.images.scaled_image = ptr_new(/alloc)		; byte scaled for display copy of the full main image.
  self.images.blink_image1 = ptr_new(/alloc)		; saved image 1 for blinking
  self.images.blink_image2 = ptr_new(/alloc)
  self.images.blink_image3 = ptr_new(/alloc)
  self.images.unblink_image = ptr_new(/alloc)
  self.images.dq_image_stack = ptr_new(/alloc)		; data quality cube extension, if present
  self.images.dq_image = ptr_new(/alloc)			; data quality image or slice of cube, if present
  self.images.pan_image = ptr_new(/alloc)			; the little mini image in the top corner
  self.images.klip_image = ptr_new(/alloc)			; the result of processing via KLIP

  ;;this replaces the state.contrcens var
  self.satspots.valid = 0
  self.satspots.attempted = 0
  self.satspots.cens = ptr_new(/alloc)
  self.satspots.warns = ptr_new(/alloc)
  self.satspots.good = ptr_new(/alloc)
  self.satspots.satflux = ptr_new(/alloc)
  self.satspots.mags = ptr_new(/alloc)      ;array of central star magnitudes calculated from each sat spot (4 x 1) -Naru

  ;; radial_profile will return a wavelength dependent number of values
  ;; (as the IWA is lambda dependent).  One option is to store all of
  ;; these is a big zero-padded array.  Instead, we'll store
  ;; individual channels in a pointer array to allow for differently
  ;; sized arrays.  This means we also need to store a specific asec
  ;; array for each slice - memory wasteful, but computationally efficient.
  self.satspots.contrprof = ptr_new(/alloc) ;contour profile (will be Z x 3 pointer array with second dimension being stdev,median,mean)
  self.satspots.asec = ptr_new(/alloc)      ;arrays of ang sep vals (will be Z x 1 pointer array)

  state = {                   $
    version: '2.0', $                  ; version # of this release
    head_ptr: ptr_new(), $             ; pointer to image header (PHDU if multi-extension)
    exthead_ptr: ptr_new(), $          ; pointer to extension header
    ; for currently loaded extension
    astr_ptr: ptr_new(), $             ; pointer to astrometry info structure
    main_image_astr_backup: ptr_new(), $ ; pointer to astrometry info structure as originally read from disk
    astr_from: 'None',$                ; is astrometry from PHDU or Extension HDU? (or not loaded)
    wcstype: 'none', $                 ; coord info type (none/angle/lambda)
    equinox: 'J2000', $                ; equinox of coord system
    display_coord_sys: 'RA--', $       ; coord system displayed
    display_equinox: 'J2000', $        ; equinox of displayed coords
    display_base60: 1B, $              ; Display RA,dec in base 60?
    imagename: '', $                   ; image file name
    imagename_id: 0L, $                ; window id of image file name
    collapse: 0L,$                     ; id of current collapse mode
    CWV_lmin: 0., $                    ; minimum wavelength (common wav vect)
    CWV_lmax: 0., $                    ; maximum wavelength (common wav vect)
    CWV_NLam: 0L, $                    ; # of spectral channels(common wav vect)
    CWV_ptr: ptr_new(), $              ; pointer to common wav vec
    bitdepth: 8, $                     ; 8 or 24 bit color mode?
    user_decomposed: 1, $              ; User's setting of device,/decomposed (outside ATV)
    screen_ysize: 1000, $              ; vertical size of screen
    base_id: 0L, $                     ; id of top-level base
    base_min_size: [312L, 300L], $     ; min size for top-level base
    draw_base_id: 0L, $                ; id of base holding draw window
    draw_window_id: 0L, $              ; window id of draw window
    draw_widget_id: 0L, $              ; widget id of draw widget
    mousemode: 1L, $                   ; color, blink, zoom, or imexam
    mousemode_count: 0L, $             ; number of available mouse modes
    mode_droplist_id: 0L, $            ; id of mode droplist widget
    track_window_id: 0L, $             ; widget id of tracking window
    pan_widget_id: 0L, $               ; widget id of pan window
    pan_window_id: 0L, $               ; window id of pan window
    active_window_id: 0L, $            ; user's active window outside GPItv
    active_window_pmulti: lonarr(5), $ ; user's active window p.multi
    info_base_id: 0L, $                ; id of base holding info bars
    info_head_id: 0L, $                ; id of head base
    location_bar_id: 0L, $             ; id of (x,y,value) label
    value_bar_id: 0L, $                ; id of (x,y,value) label
    wave_bar_id: 0L, $                 ; id of wavelength label
    coord_bar_id: 0L, $                ; id of coordinate label
    ;;woffset_bar_id: 0L, $            ; id of wavesamp offset label
    wcs_bar_id: 0L, $                  ; id of WCS label widget
    itime: 0.0,$                       ; exposure integration time (not including any coadding)
    coadds:0.0,$                       ; coadds
    current_units:'',$                 ; current unit of data displayed (i.e. BUNIT)
    current_unit_scaling: ptr_new(),$  ; multiplicative scaling factor for the current unit
    intrinsic_units:'',$               ; unit for the actual pixel values in the file itself,
    ; and hence also the main_image_backup stack
    unitslist:ptr_new(/alloc), $       ; tab of available units
    units_droplist_id:'',$             ; id of units droplist
    flux_calib_convfac:fltarr(100),$   ; flux calibration conversion factor from the image's intrinsic units to ph/s/nm/m^2
    min_text_id: 0L,  $                ; id of min= widget
    max_text_id: 0L, $                 ; id of max= widget
    menu_ids: lonarr(150), $           ; list of top menu items
    menu_labels: strarr(150), $        ; list of top menu items
    colorbar_base_id: 0L, $            ; id of colorbar base widget
    colorbar_widget_id: 0L, $          ; widget id of colorbar draw widget
    colorbar_window_id: 0L, $          ; window id of colorbar
    colorbar_height: 12L, $            ; height of colorbar in pixels
    ncolors: 0B, $                     ; image colors (!d.table_size - 9)
    box_color: 2, $                    ; color for pan box and zoom x
    brightness: 0.5, $                 ; initial brightness setting
    contrast: 0.5, $                   ; initial contrast setting
    keyboard_text_id: 0L, $            ; id of keyboard input widget
    image_min: 0.0, $                  ; min(*self.images.main_image)
    image_max: 0.0, $                  ; max(*self.images.main_image)
    minIma_id:0L,$                     ; widget id for displaying image_min
    maxIma_id:0L,$                     ; widget id for displaying image_max
    min_value: 0.0, $                  ; min data value mapped to colors
    max_value: 0.0, $                  ; max data value mapped to colors
    draw_window_size: [520L, 512L], $  ; size of main draw window
    track_window_size: 121L, $         ; size of tracking window
    pan_window_size: 121L, $           ; size of pan window
    pan_scale: 0.0, $                  ; magnification of pan image
    image_size: [0L,0L,0L], $          ; [0:1] gives size of *self.images.main_image
    ; [0:2] gives size of *self.images.main_image_stack
    prev_image_size: [0L,0L,0L], $     ; dimensions of previous image
    prev_image_2d: 1,$                 ; Boolean - whether previous image was 2D
    collapse_button: 0L,$              ; id of collapse button
    cur_image_num: 0L, $               ; gives current image number in
    ; *self.images.main_image_stack
    curimnum_base_id0: 0L, $           ; id of cur_image_num base widget
    curimnum_base_id: 0L, $            ; id of cur_image_num base widget
    curimnum_text_id: 0L, $            ; id of cur_image_num textbox widget
    curimnum_textLamb_id: 0L, $        ; id of cur_image_num textbox widget
    curimnum_lambLabel_id: 0L, $       ; id of cur_image_num textbox widget
    curimnum_slidebar_id: 0L, $        ; id of cur_image_num slider widget
    cube_mode: 	'', $				   ; {Unknown, WAVE, STOKES}
    scale_mode_droplist_id: 0L, $      ; id of scale droplist widget
    curimnum_minmaxmode: 'Constant', $ ; mode for determining min/max
    ; of display when changing curimnum
    invert_colormap: 0L, $             ; 0=normal, 1=inverted
    coord: [0L, 0L],  $                ; cursor position in image coords
    plot_coord: [0L, 0L], $            ; cursor position when a plot
    ; is initiated
    vector_coord1: [0L, 0L], $         ; 1st cursor position in vector plot
    vector_coord2: [0L, 0L], $         ; 2nd cursor position in vector plot
    vector_pixmap_id: 0L, $            ; id for vector pixmap
    vectorpress: 0L, $                 ; are we plotting a vector?
    vectorstart: [0L,0L], $            ; device x,y of vector start
    plot_type:'', $                    ; plot type for plot window
    scalings:[ 'Linear', 'Log',  'HistEq', 'Square Root', 'Asinh'],$ ; scaling options
    scaling: 'Log', $                  ; current scaling must be one of the above
    asinh_beta: 0.1, $                 ; asinh nonlinearity parameter
    offset: [0L, 0L], $                ; offset to viewport coords
    base_pad: [0L, 0L], $              ; padding around draw base
    zoom_level: 0L, $                  ; integer zoom level, 0=normal
    zoom_factor: 1.0, $                ; magnification factor = 2^zoom_level
    rot_angle: 0.0, $                  ; current image rotation angle
    invert_image: 'none', $            ; 'none', 'x', 'y', 'xy' image invert
    centerpix: [0L, 0L], $             ; pixel at center of viewport
    cstretch: 0B, $                    ; flag = 1 while stretching colors
    pan_offset: [0L, 0L], $            ; image offset in pan window
    frame: 1L, $                       ; put frame around ps output?
    framethick: 6, $                   ; thickness of frame
    lineplot_widget_id: 0L, $          ; id of lineplot widget
    lineplot_window_id: 0L, $          ; id of lineplot window
    lineplot_base_id: 0L, $            ; id of lineplot top-level base
    lineplot_size: [600L, 500L], $     ; size of lineplot window
    lineplot_min_size: [100L, 0L], $   ; min size of lineplot window
    lineplot_pad: [0L, 0L], $          ; padding around lineplot window
    lineplot_xmin_id: 0L, $            ; id of xmin for lineplot windows
    lineplot_xmax_id: 0L, $            ; id of xmax for lineplot windows
    lineplot_ymin_id: 0L, $            ; id of ymin for lineplot windows
    lineplot_ymax_id: 0L, $            ; id of ymax for lineplot windows
    lineplot_xmin: 0.0, $              ; xmin for lineplot windows
    lineplot_xmax: 0.0, $              ; xmax for lineplot windows
    lineplot_ymin: 0.0, $              ; ymin for lineplot windows
    lineplot_ymax: 0.0, $              ; ymax for lineplot windows
    lineplot_xmin_orig: 0.0, $         ; original xmin saved from histplot
    lineplot_xmax_orig: 0.0, $         ; original xmax saved from histplot
    holdrange_base_id: 0L, $           ; base id for 'Hold Range' button
    holdrange_butt_id: 0L, $           ; button id for 'Hold Range' button
    holdrange_value: 1., $             ; 0=HoldRange Off, 1=HoldRange On
    histbutton_base_id: 0L, $          ; id of histogram button base
    histplot_binsize_id: 0L, $         ; id of binsize for histogram plot
    x1_pix_id: 0L, $                   ; id of x1 pixel for histogram plot
    x2_pix_id: 0L, $                   ; id of x2 pixel for histogram plot
    y1_pix_id: 0L, $                   ; id of y1 pixel for histogram plot
    y2_pix_id: 0L, $                   ; id of y2 pixel for histogram plot
    binsize: 0.0, $                    ; binsize for histogram plots
    reg_ids_ptr: ptr_new(), $          ; ids for region form widget
    writeimage_ids_ptr: ptr_new(),$    ; ids for writeimage form widget
    makemovie_ids_ptr: ptr_new(),$     ; ids for makemovie form widget
    writeformat: 'PNG', $              ; format for WriteImage
    writewhat: 'view', $               ; write 'full' image or 'view' for WriteImage
    movieformat: 'GIF', $              ; format for makemovie
    moviefps: 5, $                     ; fps for makemovie
    cursorpos: lonarr(2), $            ; cursor x,y for photometry & stats
    centerpos: fltarr(2), $            ; centered x,y for photometry
    cursorpos_id: 0L, $                ; id of cursorpos widget
    cursorpos_id_apphot: 0L, $         ; id of cursorpos in apphot
    cursorpos_id_anguprof: 0L, $       ; id of cursorpos in anguprof
    cursorpos_id_lambprof: 0L, $       ; id of cursorpos is lambprof
    centerpos_id: 0L, $                ; id of centerpos widget
    centerpos_id_arc: 0L, $            ; id of centerpos widget in ra and dec
    centerbox_id: 0L, $                ; id of centeringboxsize widget
    radius_id: 0L, $                   ; id of radius widget
    innersky_id: 0L, $                 ; id of inner sky widget
    outersky_id: 0L, $                 ; id of outer sky widget
    magunits: 0, $                     ; 0=counts, 1=magnitudes
    skytype: 0, $                      ; 0=idlphot,1=median,2=no sky subtract
    photzpt: 25.0, $                   ; magnitude zeropoint
    skyresult_id: 0L, $                ; id of sky widget
    photresult_id: 0L, $               ; id of photometry result widget
    fwhm_id: 0L, $                     ; id of fwhm widget
    radplot_widget_id: 0L, $           ; id of radial profile widget
    ;;anguradplot_widget_id: 0L, $       ; id of radial profile widget
    ;;anguradplot_window_id: 0L, $       ; id of radial profile window
    graffer_window_id:0L, $
    anguzoom_window_id: 0L,$
    anguplot_window_id: 0L,$
    anguradius_id: 0L, $
    showanguplot_id: 0L, $
    anguplot_widget_id: 0L, $
    angur:30L,$
    anguprof_imacenter_button: 0L,$ ;
    anguprof_maxr_button: 0L,$
    basemaxr: 0L,$
    angureso: 1.0,$
    angureso_id: float(1.0),$
    contrzoom_window_id: 0L,$
    contrplot_window_id: 0L,$
    contrradius_id: 0L, $
    showcontrplot_id: 0L, $
    contrplot_widget_id: 0L, $
    contrr:30L,$
    contrprof_imacenter_button: 0L,$ ;
    contrprof_maxr_button: 0L,$
    ;;contrbasemaxr: 0L,$
    contrreso: 1.0,$
    contrgridfac_id: float(1.0),$
    gridfac: 1e-4,$
    contrsigma_id: float(1.0),$
    contrsigma: 5.,$
    satpos_ids: lonarr(4),$ ; labels for derived positions
    contrcen_base_ids: lonarr(4),$    ;fields for sat spot centers
    contrwarning_id:0L,$
    contrcen1x:168L,$       ; satellite spot default locations
    contrcen1y:192L,$
    contrcen2x:090L,$
    contrcen2y:160L,$
    contrcen3x:122L,$
    contrcen3y:085L,$
    contrcen4x:197L,$
    contrcen4y:115L,$
    contrcen_x: intarr(4), $   ; satellite spot default locations (array form)
    contrcen_y: intarr(4), $   ; satellite spot default locations (array form)
    contrcen1x_id:0L,$         ; satellite spot UI widget IDs
    contrcen1y_id:0L,$
    contrcen2x_id:0L,$
    contrcen2y_id:0L,$
    contrcen3x_id:0L,$
    contrcen3y_id:0L,$
    contrcen4x_id:0L,$
    contrcen4y_id:0L,$
    contrwinap_id:0L,$
    contrwinap:20L,$
    contrap_id:0L,$
    contrap:7L,$						; Contrast aperture size
    contr_yaxis_type: 1, $              ; 0=linear or 1=log axis
    contr_yaxis_mode: 1, $              ; 0=manual, 1= auto axis
    contr_yaxis_min: 1.e-6, $           ;  axis scale
    contr_yaxis_max: 1.e-3, $           ;  axis scale
    contr_font_size: 1.4, $             ;  for plot annotations
    contr_plotmult: 0, $                ; plot contrasts for single slice/all slices
    contr_autocent: 1, $                ; 0=manual, 1=auto, find sat centers
    contr_highpassspots: 1, $           ; pass /highpass
    contr_constspots: 1, $              ; pass /constrain
    contr_secondorder: 1, $             ; pass /secondorder
    contr_plotouter: 0, $               ; plot contrasts for region outside of dark hole
    contr_yunit:0, $                    ; 0 = sigma, 1 = median, 2 = mean
    contr_xunit:0, $                    ; 0 = as, 1 = l/D
    contr_prof_filetype:0, $            ; 0 = fits, 1 = txt
	fpmoffset_fpmpos: fltarr(2), $		; Measured center of focal plane mask
	fpmoffset_calfilename: '', $		; Filename for source of that FPM position
	fpmoffset_psfcentx_id: 0L, $		; widget id
	fpmoffset_psfcenty_id: 0L, $		; widget id
	fpmoffset_fpmcentx_id: 0L, $		; widget id
	fpmoffset_fpmcenty_id: 0L, $		; widget id
	fpmoffset_offsettip_id: 0L, $			; widget id
	fpmoffset_offsettilt_id: 0L, $			; widget id
	fpmoffset_statuslabel_id: 0L, $          ; widget id
    lambplot_widget_id: 0L, $           ; id of radial profile widget
    lambplot_window_id: 0L, $           ; id of radial profile window
    showlambplot_id: 0L, $              ;
    lambzoom_window_id: 0L,$
    spaxelmeth_id: 0L, $
    methlist: strarr(3),$
    currmeth: '',$
    radplot_window_id: 0L, $            ; id of radial profile window; JM
    photzoom_window_id: 0L, $           ; id of photometry zoom window
    photzoom_size: 190L, $              ; size in pixels of photzoom window
    showradplot_id: 0L, $               ; id of button to show/hide radplot
    showeeplot_id: 0L, $                ; id of button to show/hide radplot
    photwarning_id: 0L, $               ; id of photometry warning widget
    photwarning: ' ', $                 ; photometry warning text
    centerboxsize: 5L, $                ; centering box size
    r: 5L, $                            ; aperture photometry radius
    innersky: 10L, $                    ; inner sky radius
    outersky: 20L, $                    ; outer sky radius
    aborted_base_id: 0L, $              ; aborted base widget id
    headinfo_base_id: 0L, $             ; headinfo base widget id
    pixtable_base_id: 0L, $             ; pixel table base widget id
    pixtable_tbl_id: 0L, $              ; pixel table widget_table id
    stats_base_id: 0L, $                ; base widget for image stats
    stat_xyresize_button_id: 0L, $      ; widget id for stats resize checkbox
    stat_xyresize: 1, $                 ; 1=keep x&y sizes equal for box stats
    ; 0=allow rectangular box stats
    xstatboxsize: 11L, $    ; x box size for statistics
    ystatboxsize: 11L, $    ; y box size for statistics
    stat_npix_id: 0L, $     ; widget id for # pixels in stats box
    xstatbox_id: 0L, $      ; widget id for pix in x-dir stat box
    ystatbox_id: 0L, $      ; widget id for pix in y-dir stat box
    statxcenter_id: 0L, $   ; widget id for stat box x center
    statycenter_id: 0L, $   ; widget id for stat box y center
    statbox_min_id: 0L, $   ; widget id for stat min box
    statbox_max_id: 0L, $   ; widget id for stat max box
    statbox_mean_id: 0L, $  ; widget id for stat mean box
    statbox_median_id: 0L, $            ; widget id for stat median box
    statbox_stdev_id: 0L, $             ; widget id for stat stdev box
    statbox_nbnan_id: 0L, $             ; widget id for stat nbNan box
    statzoom_size: 300, $               ; size of statzoom window
    statzoom_widget_id: 0L, $           ; widget id for stat zoom window
    statzoom_window_id: 0L, $           ; window id for stat zoom window
    showstatzoom_id: 0L, $              ; widget id for show/hide button
    histplot_base_id: 0L, $             ; base widget for image stats
    histplot_widget_id: 0L, $           ; widget id for histogram plot
    histplot_window_id: 0L, $           ; window id for histogram plot
    pan_pixmap: 0L, $                   ; window id of pan pixmap
    current_dir: '', $                  ; current readfits directory
    output_dir: '', $                   ; write directory
    graphicsdevice: '', $               ; screen device
    newrefresh: 0, $                    ; refresh since last blink?
    window_title: 'GPItv:', $           ; string for top level title
    title_blink1: '', $                 ; window title for 1st blink image
    title_blink2: '', $                 ; window title for 2nd blink image
    title_blink3: '', $                 ; window title for 3rd blink image
    title_extras: '', $                 ; extras for image title
    blinks: 0B, $                       ; remembers which images are blinked
    polarim_plotindex: -1,$             ; Which plot structure is the polarimetry? -1 means no pol plot present
    polarim_display: 1, $               ; overplot polarimetry vectors?
    polarim_dialog_id: 0L, $            ; widget ID of polarimetry display flag
    stokesdc_im_mode: 0L, $             ; stokesdc display mode: 0: regular 1:radial 2:normalized 3:normalized radial
    radial_stokes_rot_angle: 0.0, $     ; the angle being used for the radial stokes calculation
    aborted_id: 0L, $                   ; widget ID for 'ABORTED'
    dateobs_id: 0L, $                   ; widget id for'DATE-OBS'
    timeobs_id: 0L, $                   ; widget id for 'TIME-OBS')
    filter1_id: 0L, $                   ; widget id for'FILTER1' - OBSFILT)
    filter2_id: 0L, $                   ; widget id for 'FILTER2')
    waveleng_id: 0L, $                  ; widget id for 'WAVELENG')
    exptime_id: 0L, $                   ; widget id for 'ITIME')
    readmode_id: 0L, $                  ; widget id for 'CO-ADDS')
    object_id: 0L, $                    ; widget id for 'OBJECT')
    obstype_id: 0L, $                   ; widget id for 'OBSTYPE')
    obsclass_id: 0L, $                  ; widget id for'OBSCLASS')
    aborted: '', $                      ; for 'ABORTED'
    dateobs: '', $                      ;  for'DATE-OBS'
    timeobs: '', $                      ;  for 'TIME-OBS')
    obsfilt:'', $                       ; IFS filter
    filter2: '', $                      ;  for 'FILTER2')
    waveleng: '', $                     ; for 'WAVELENG')
    exptime: '', $                      ;  for 'EXPTIME')
    object: '', $                       ;  for 'OBJECT')
    obstype: '', $                      ; for 'OBSTYPE')
    obsclass: '', $                     ; for'OBSCLASS')
    wavsamp: 0 ,$                       ; whether to draw wavsamp?
    oplot: 0, $                         ; whether to overplot
    wavsampfile: '', $                  ; location of wavsampfile
    has_dq_mask:0S, $                   ; If a DQ mask is present
    dq_bit_mask: 0b, $  ; (1b or 2 or 4 or 8 or 16 or 32), $       ; Binary bit mask of which bits in DQ count as 'bad'
    dq_display_color: 1b, $             ; color to display 'bad' pix from DQ
    mosaic: 0S, $                       ; whether the 3D stack is viewed as mosaic
    im_slider1: 0L, $                   ; widget id of image 1 slider
    im_slider2: 0L, $                   ; widget id of image 2 slider
    screen1: 0L, $                      ; widget id of 1st stat3d screen
    screen2: 0L, $                      ; widget id of 2nd stat3d screen
    screen3: 0L, $                      ; widget id of mosaic screen
    stat3dbox: [0L, 0L], $              ; box size of stat3d window
    stat3dcenter: [0L, 0L], $           ; box center of stat3d window
    stat3d_done: 0L, $                  ; widget id of done button
    stat3d_refresh: 0L, $               ; widget id of refresh button
    data_table: 0L, $                   ; data table for stat3d
    s3sel: [0L, 0L, 0L, 0L, 0L],$       ; draw box
    stat3dminmax: [0L, 0L, 0L, 0L],$    ; stat3d info for box
    lines_done: 0L, $                   ; widget id of done button
    lines_gauss: 0L, $                  ; widget id of gauss button
    lines_plot_screen: 0L, $            ; widget id of screen
    imin: 0L, $                         ; min control
    imax: 0L, $                         ; max control
    gaussmin: 0L, $                     ; widget id of min button
    gaussmax: 0L, $                     ; widget id of max button
    wcfilename: '', $
    multisess:-1, $
    confirm_before_quit: 1,$            ; should we ask before quitting?
    drawvectorpress:0,$                 ; for drawvector, to be sure button press has been done
    sdi_userdef: 0L, $                  ; user defined SDI band?
    sdi_userdef_id: 0L, $               ; user defined SDI button
    sdi_slices: [10,11,14,15], $        ; SDI slices to use (defaults to H methane)
    sdi_sliceids: lonarr(4), $          ; SDI slice text widgets
    sdi_wavids: lonarr(4), $            ; SDI wav labels
    sdik_id: 0L, $                      ; SDI sub. fac text widget
    sdik: -1. ,$                        ; SDI subtraction factor
    nbrsatspot: 0,$
    spotwarning_id:0L ,$
    satradius_id :0L ,$
    satmethlist:strarr(2) ,$
    satmeth_id:0L ,$
    spotcurrmeth:'Barycent. centroid' ,$
    spotmisdetection: 0,$
    linesbox: [0L, 0L, 0L, 0L, 0L], $ ; start & end of line
    specalign_mode: 0, $              ; boolean indicating whether you're in specalign mode
    klip_mode: 0, $                   ; boolean indicating whether you're in KLIP mode
    high_pass_mode: 0,$               ; boolean indicating whether you're in high pass filter mode
    high_pass_size: 15,$              ; high pass filter size of median box
    low_pass_mode: 0,$                ; boolean indicating whether you're in low pass filter mode
    snr_map_mode: 0,$		              ; boolean indicating whether you're in snr map mode
    specalign_to: 0L, $               ; index of slice you're aligned to
    klip_annuli: 5L, $                ; default # of KLIP annuli to use
    klip_movmt: 2.0, $                ; default minimum pixels to move for KLIP ref set
    klip_prop: 0.99999, $             ; default truncation for KLIP
    klip_arcsec: 0.4, $               ; Area of interest for single annulus
    subwindow_headerviewer: obj_new(), $        ; handle to FITS header viewer window, if open
    subwindow_dirviewer: obj_new(), $           ; handle to file directory viewer/scanner window, if open
    rgb_mode: 0, $					  ; are we displaying an RGB image made from collapsing a datacube?
    activator: 0, $                   ; is "activator" mode on?
	mark_sat_spots: 0, $			 ; should we overplot the location of GPI's satellite spots? 
    retain_current_slice: 1, $       ; toggles stickiness of current image when loading new file
    retain_current_view: 1, $  ; align next image by default?
    retain_collapse_mode: 0, $       ; keep collapse mode if possible
    retain_current_stretch: 0 ,$      ; use previous minmax for new image?
    flag_bad_pix_from_dq: 0 ,$        ; Display saturated pixels from DQ ext in contrasting color?
    isfirstimage: 1, $                ; is this the first image?
    ;default_autoscale: 1, $          ; autoscale images by default?
    ;autozoom: 1 ,$                      ; zoom images to fit window on open?
    autohandedness: 0 ,$                ; flip images if necessary to have East counterclockwise of North on open?
    showfullpaths: 0L, $                ;toggle to display full paths in headers
    noinfo: 0L, $                       ;toggle to supress informational messages
    nowarn: 0L, $                       ;toggle to supress warning messages
    cubehelix_start_id: 0L, $           ; cubehelix start color
    cubehelix_nrot_id: 0L, $            ; cubehelix # of rotations
    cubehelix_hue_id: 0L,   $           ; cubehelix hue strength
    cubehelix_gamma_id: 0L, $           ; cubehelix gamma parameter
    cubehelix_plot_id: 0L,  $           ; cubehelix color plot window id
    cubehelix_start: 0.5, $             ; cubehelix start color
    cubehelix_nrot: -1.5, $             ; cubehelix # of rotations
    cubehelix_hue: 1.0,   $             ; cubehelix hue strength
    cubehelix_gamma: 1.0,  $            ; cubehelix gamma parameter
    helptext_id: 0L, $                  ; id of textbase for help window
    filetype: '' $                      ; type of file currently loaded
  }

  curr = gpi_expand_path(gpi_get_setting('gpitv_startup_dir',/silent))
  ;;if ~file_test(curr,/dir) then curr = gpi_get_directory('GPI_DATA_ROOT')
  if ~file_test(curr,/dir) then cd, curr=curr
  state.current_dir=curr
  state.output_dir = curr

  self.state = ptr_new(state,/no_copy)
  self.pdata.nplot = 0

  ;self.pdata.plot_ptr = ptrarr(self.pdata.maxplot+1)  ; The 0th element isn't used.
  self.pdata.maxplot = n_elements(self.pdata.plot_ptr)-1

  *self.images.blink_image1 = 0
  *self.images.blink_image2 = 0
  *self.images.blink_image3 = 0

end

;---------------------------------------------------------------------
;;Generic event handlers (just pass-throughs to specific handlers)
pro GPItvo_generic_event_handler, ev
  ;; see http://michaelgalloy.com/2006/06/14/object-widgets.html
  WIDGET_CONTROL, ev.id, get_Uvalue = myInfo
  if ~obj_valid(myInfo.object) then return ; avoids error when object is closed
  CALL_METHOD, myInfo.method, myInfo.object, ev
end

pro GPItvo_subwindow_event_handler, ev
  ;; see http://michaelgalloy.com/2006/06/14/object-widgets.html
  WIDGET_CONTROL, ev.top, get_Uvalue = myInfo
  CALL_METHOD, myInfo.method, myInfo.object, ev
end

;;one-off event handlers not associated with stored objects
pro GPItvo_menu_event, event
  WIDGET_CONTROL, event.top, get_Uvalue = self
  self->topmenu_event, event
end

pro GPItvo_shutdown, windowid
  WIDGET_CONTROL, windowid, get_Uvalue = self
  self->shutdown,/nocheck ; doesn't make sense to check for confirmation since the window manager already closed the window...
end

pro GPItvo_event, event
  WIDGET_CONTROL, event.top, get_Uvalue = self
  self->event, event
end

;---------------------------------------------------------------------

pro GPItv::startup, nbrsatspot=nbrsatspot

  ; This routine initializes the GPItv internal variables, and creates and
  ; realizes the window widgets.  It is only called by the GPItv main
  ; program level, when there is no previously existing GPItv window.

  ; save the user color table and pmulti first
  tvlct, user_r, user_g, user_b, /get
  self.colors.user_r = user_r & self.colors.user_g = user_g  & self.colors.user_b = user_b

  ; Read in a color table to initialize !d.table_size
  ; As a bare minimum, we need the 8 basic colors used by GPItv_ICOLOR(),
  ; plus 2 more for a color map.

  if (!d.table_size LT 12) then begin
    self->message, msgtype = 'error', 'Too few colors available for color table'
    tvlct, self.colors.user_r, self.colors.user_g, self.colors.user_b
    self->shutdown
  endif

  ; Initialize the common blocks
  self->initcommon

  (*self.state).active_window_pmulti = !p.multi
  !p.multi = 0

  (*self.state).ncolors = !d.table_size - 9

  ; always do it for 24-bit color with retain & decomposed set.
  (*self.state).bitdepth = 24

  (*self.state).graphicsdevice = !d.name

  ;(*self.state).screen_xsize = (get_screen_size())[0] ; x size is not used.
  (*self.state).screen_ysize = (get_screen_size())[1]

  ; Get the current window id
  self->getwindow


  ; Define the widgets.  For the widgets that need to be modified later
  ; on, save their widget ids in state variables
  dirlist=gpi_get_directory('GPI_DRP_DIR')
  base = widget_base(title = 'GPItv', $
    /column, /base_align_right, $
    app_mbar = top_menu, $
    uvalue = 'GPItv_base', $
    /tlb_size_events,bitmap=dirlist[0]+path_sep()+'gpi.bmp')
  (*self.state).base_id = base

  tmp_struct = {cw_pdmenu_s, flags:0, name:''}

  top_menu_desc = [ $
    {cw_pdmenu_s, 1, 'File'}, $ ; file menu;
    {cw_pdmenu_s, 0, 'Open...'}, $
    {cw_pdmenu_s, 0, 'Browse Files...'}, $
    {cw_pdmenu_s, 0, 'Show gpidiagram...'}, $
    ;{cw_pdmenu_s, 0, 'DetectFits'}, $ ;removed because not 100% useful and may cause errors
    {cw_pdmenu_s, 1, 'Get Image from Catalog...'}, $
    {cw_pdmenu_s, 0, 'Archive Image'}, $
    {cw_pdmenu_s, 0, ' DSS'}, $
    {cw_pdmenu_s, 2, ' FIRST'}, $
    {cw_pdmenu_s, 4, 'View FITS Header...'}, $
    {cw_pdmenu_s, 0, 'Change FITS extension...'}, $
    {cw_pdmenu_s, 4, 'Write FITS...'}, $
    {cw_pdmenu_s, 0, 'Write PS...'},  $
    {cw_pdmenu_s, 0, 'Write Image...'}, $
    {cw_pdmenu_s, 0, 'Make Movie...'}, $
    {cw_pdmenu_s, 1, 'Save To IDL variable...'}, $
    {cw_pdmenu_s, 0, 'Save Image to IDL variable'}, $
    {cw_pdmenu_s, 0, 'Save Image Cube to IDL variable'}, $
    {cw_pdmenu_s, 2, 'Save FITS Header to IDL variable'}, $
    {cw_pdmenu_s, 6, 'Quit'}, $
    {cw_pdmenu_s, 1, 'ColorMap'}, $ ; color menu
    $               ; NOTE: if you update the menu here, you must also update the list in menu_colortable_checkbox_update!
    {cw_pdmenu_s, 8, 'Grayscale'}, $
    {cw_pdmenu_s, 8, 'Blue-White'}, $
    {cw_pdmenu_s, 8, 'Red-White'}, $
    {cw_pdmenu_s, 8, 'Green-White'}, $
    {cw_pdmenu_s, 12, 'Rainbow'}, $
    {cw_pdmenu_s, 8, 'Blue-Red (Jet)'}, $
    {cw_pdmenu_s, 8, 'Stern Special'}, $
    {cw_pdmenu_s, 8, 'GPItv Special'}, $
    {cw_pdmenu_s, 8, 'Velocity'}, $
    {cw_pdmenu_s, 8, 'Cubehelix'}, $
    {cw_pdmenu_s, 0, 'Cubehelix Settings...'}, $
    {cw_pdmenu_s, 12, 'Standard Gamma-II'}, $
    {cw_pdmenu_s, 8, 'Red-Purple'}, $
    ;{cw_pdmenu_s, 8, 'Cyan-Blue-Red'}, $
    {cw_pdmenu_s, 8, 'Rainbow18'}, $
    {cw_pdmenu_s, 8, 'BGRY'}, $
    {cw_pdmenu_s, 8, 'GRBW'}, $
    {cw_pdmenu_s, 8, 'Prism'}, $
    {cw_pdmenu_s, 8, '16 Level'}, $
    {cw_pdmenu_s, 8, 'Haze'}, $
    {cw_pdmenu_s, 10, 'Blue-Pastel-Red'}, $
    {cw_pdmenu_s, 1, 'Scale'}, $ ; scaling menu
    {cw_pdmenu_s, 8, 'Linear'}, $
    {cw_pdmenu_s, 8, 'Log'}, $
    {cw_pdmenu_s, 8, 'HistEq'}, $
    {cw_pdmenu_s, 8, 'Square Root'}, $
    {cw_pdmenu_s, 8, 'Asinh'}, $
    {cw_pdmenu_s, 4, 'Asinh Settings...'}, $
    {cw_pdmenu_s, 4, 'Auto Scale'}, $
    {cw_pdmenu_s, 0, 'Full Range'}, $
    {cw_pdmenu_s, 2, 'Zero to Max'}, $
    {cw_pdmenu_s, 1, 'Labels'}, $ ; labels menu
    {cw_pdmenu_s, 0, 'TextLabel'}, $
    {cw_pdmenu_s, 0, 'Arrow'}, $
    {cw_pdmenu_s, 0, 'Contour'}, $
    {cw_pdmenu_s, 0, 'Compass'}, $
    {cw_pdmenu_s, 0, 'ScaleBar'}, $
    {cw_pdmenu_s, 0, 'Draw Region'}, $
    ; This line commented out to remove "WCS Grid" menu option.
    ; Can be re-instated if "WCS Grid" required but will need modification.
    ;;{cw_pdmenu_s, 0, 'WCS Grid'}, $
    {cw_pdmenu_s, 4, 'Polarimetry'}, $
    {cw_pdmenu_s, 4, 'Select Wavecal/Polcal File'}, $
    {cw_pdmenu_s, 0, 'Get Wavecal/Polcal from CalDB'}, $
    {cw_pdmenu_s, 0, 'Plot Wavecal/Polcal Grid'}, $
    {cw_pdmenu_s, 4, 'EraseLast'}, $
    {cw_pdmenu_s, 0, 'EraseAll'}, $
    {cw_pdmenu_s, 4, 'Load Regions'}, $
    {cw_pdmenu_s, 2, 'Save Regions'}, $
    {cw_pdmenu_s, 1, 'Blink'}, $
    {cw_pdmenu_s, 8, 'SetBlink1'}, $
    {cw_pdmenu_s, 8, 'SetBlink2'}, $
    {cw_pdmenu_s, 8, 'SetBlink3'}, $
    {cw_pdmenu_s, 6, 'MakeRGB'}, $
    {cw_pdmenu_s, 1, 'Zoom'}, $
    {cw_pdmenu_s, 8, 'Zoom In'}, $
    {cw_pdmenu_s, 8, 'Zoom Out'}, $
    {cw_pdmenu_s, 8, 'Zoom to Fit'}, $
    {cw_pdmenu_s, 8, '1/16'}, $
    {cw_pdmenu_s, 8, '1/8'}, $
    {cw_pdmenu_s, 8, '1/4'}, $
    {cw_pdmenu_s, 8, '1/2'}, $
    {cw_pdmenu_s, 8, '1'}, $
    {cw_pdmenu_s, 8, '2'}, $
    {cw_pdmenu_s, 8, '4'}, $
    {cw_pdmenu_s, 8, '8'}, $
    {cw_pdmenu_s, 8, '16'}, $
    {cw_pdmenu_s, 4, 'Center'}, $
    {cw_pdmenu_s, 12, 'No Inversion'}, $
    {cw_pdmenu_s, 8, 'Invert X'}, $
    {cw_pdmenu_s, 8, 'Invert Y'}, $
    {cw_pdmenu_s, 8, 'Invert X && Y'}, $
    ;{cw_pdmenu_s, 4, 'Rotate:'}, $
    {cw_pdmenu_s, 12, 'Rotate 0 deg'}, $
    {cw_pdmenu_s, 8, 'Rotate 90 deg'}, $
    {cw_pdmenu_s, 8, 'Rotate 180 deg'}, $
    {cw_pdmenu_s, 8, 'Rotate 270 deg'}, $
    {cw_pdmenu_s, 8, 'Rotate GPI field square'}, $
    {cw_pdmenu_s, 8, 'Rotate north up'}, $
    {cw_pdmenu_s, 10, 'Rotate arbitrary angle'},$
    {cw_pdmenu_s, 1, 'ImageInfo'}, $ ;info menu
    {cw_pdmenu_s, 0, 'View FITS Header...'}, $
    {cw_pdmenu_s, 4, 'Contrast'}, $
    {cw_pdmenu_s, 0, 'Photometry'}, $
    {cw_pdmenu_s, 0, 'Statistics'}, $
    {cw_pdmenu_s, 0, 'Histogram / Exposure'}, $
    {cw_pdmenu_s, 0, 'Pixel Table'}, $
    {cw_pdmenu_s, 0, 'Star Position'},$
    {cw_pdmenu_s, 0, 'FPM Offset'}]

  ;;if gpitv_obsnotes.pro exists, create menu item for it
  obsnotes = 0
  tmp = file_which('gpitv_obsnotes.pro')
  if tmp ne '' then begin
     obsnotes = 1
  endif

  if obsnotes then $
    top_menu_desc = [top_menu_desc,$
    {cw_pdmenu_s, 1, 'Display Coordinate System'}] $
  else $
    top_menu_desc = [top_menu_desc,$
    {cw_pdmenu_s, 7, 'Display Coordinate System'}]
  top_menu_desc = [top_menu_desc,$
    {cw_pdmenu_s, 0, 'RA,dec (J2000)'}, $
    {cw_pdmenu_s, 0, 'RA,dec (B1950)'}, $
    {cw_pdmenu_s, 0, 'RA,dec (J2000) deg'}, $
    {cw_pdmenu_s, 0, 'Galactic'}, $
    {cw_pdmenu_s, 0, 'Ecliptic (J2000)'}, $
    {cw_pdmenu_s, 2, 'Native'} ]

  if obsnotes then $
    top_menu_desc = [ top_menu_desc,$
    {cw_pdmenu_s, 6, 'Mark File Status'}]

  top_menu_desc = [ top_menu_desc,$
    {cw_pdmenu_s, 1, 'Options'}, $ ;options menu
    {cw_pdmenu_s, 0, 'Contrast Settings...'}, $
    {cw_pdmenu_s, 0, 'High pass filter Settings...'}, $
    {cw_pdmenu_s, 0, 'SDI Settings...'}, $
    {cw_pdmenu_s, 0, 'KLIP Settings...'}, $
    {cw_pdmenu_s, 0, 'Clear KLIP Data'}, $
    {cw_pdmenu_s, 8, 'Mark Sat Spots'}, $
    {cw_pdmenu_s, 12, 'Retain Current Slice'}, $
    {cw_pdmenu_s, 8, 'Retain Current Stretch'}, $
    {cw_pdmenu_s, 8, 'Retain Current View'}, $
    {cw_pdmenu_s, 8, 'Retain Collapse Mode'}, $
    ;                {cw_pdmenu_s, 8, 'Auto Align'}, $
    {cw_pdmenu_s, 8, 'Auto Handedness'}, $
    {cw_pdmenu_s, 12, 'Flag Bad Pix from DQ'}, $
    {cw_pdmenu_s, 8, 'DQ bitmask Settings...'}, $
    {cw_pdmenu_s, 8, 'Suppress Information Messages'}, $
    {cw_pdmenu_s, 8, 'Suppress Warning Messages'}, $
    ;                {cw_pdmenu_s, 8, 'Always Autoscale'}, $
    {cw_pdmenu_s, 10, 'Display Full Paths'}, $
    {cw_pdmenu_s, 1, 'Help'}, $ ; help menu
    {cw_pdmenu_s, 0, 'Quick Help'}, $
    {cw_pdmenu_s, 0, 'Online Help'}, $
    {cw_pdmenu_s, 0, 'Developer Guide'}, $
    {cw_pdmenu_s, 6, 'About'}$
  ]

  top_menu = cw_pdmenu_checkable(top_menu, top_menu_desc, $
    ids = menu_ids, $
    /mbar, $
    /help, $
    /return_name, $
    uvalue = 'top_menu')

  ; save menu ids and associated labels for use later for checkboxes.
  ; As usual, IDL makes this much harder than it ought to be. Argh.
  (*self.state).menu_ids = menu_ids
  for i=0L,n_elements(menu_ids)-1 do begin
    if widget_info(menu_ids[i],/valid) then begin
      widget_control, menu_ids[i],get_uvalue=label
      (*self.state).menu_labels[i] = label
    endif
  endfor

  ; init checkboxes that should be set by default:
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "No Inversion")], /set_button
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Rotate 0 deg")], /set_button

  FR_DEBUG=0 ; set this to 1 to turn on many frames for debug mode...
  ONE_LINE_TOOLBAR = 1 ; set this to 1 to switch the toolbar to one line across the whole window

  ;;process options & defaults
  tmp = gpi_get_setting('gpitv_mark_sat_spots',/silent,/int)
  if (size(tmp,/type) eq 2) && ( (tmp eq 0) || (tmp eq 1) ) then (*self.state).mark_sat_spots = tmp
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Mark Sat Spots")],$
    set_button = (*self.state).mark_sat_spots

  tmp = gpi_get_setting('gpitv_retain_current_slice',/silent,/int)
  if (size(tmp,/type) eq 2) && ( (tmp eq 0) || (tmp eq 1) ) then (*self.state).retain_current_slice = tmp
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Retain Current Slice")],$
    set_button = (*self.state).retain_current_slice

  tmp = gpi_get_setting('gpitv_retain_current_stretch',/silent,/int)
  if (size(tmp,/type) eq 2) && ( (tmp eq 0) || (tmp eq 1) ) then (*self.state).retain_current_stretch = tmp
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Retain Current Stretch")],$
    set_button = (*self.state).retain_current_stretch

  tmp = gpi_get_setting('gpitv_retain_current_view',/silent,/int)
  if (size(tmp,/type) eq 2) && ( (tmp eq 0) || (tmp eq 1) ) then (*self.state).retain_current_view = tmp
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Retain Current View")],$
    set_button = (*self.state).retain_current_view

  tmp = gpi_get_setting('gpitv_retain_collapse_mode',/silent,/int)
  if (size(tmp,/type) eq 2) && ( (tmp eq 0) || (tmp eq 1) ) then (*self.state).retain_collapse_mode = tmp
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Retain Collapse Mode")],$
    set_button = (*self.state).retain_collapse_mode

  tmp = gpi_get_setting('gpitv_flag_bad_pix_from_dq',/silent,/int)
  if (size(tmp,/type) eq 2) && ( (tmp eq 0) || (tmp eq 1) ) then (*self.state).flag_bad_pix_from_dq = tmp
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Flag Bad Pix from DQ")],$
    set_button = (*self.state).flag_bad_pix_from_dq

  tmp = gpi_get_setting('gpitv_auto_handedness',/silent,/int)
  if (size(tmp,/type) eq 2) && ( (tmp eq 0) || (tmp eq 1) ) then (*self.state).autohandedness = tmp
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Auto Handedness")],$
    set_button = (*self.state).autohandedness

  tmp = gpi_get_setting('gpitv_showfullpaths',/silent,/int)
  if (size(tmp,/type) eq 2) && ( (tmp eq 0) || (tmp eq 1) ) then (*self.state).showfullpaths = tmp
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Display Full Paths")],$
    set_button = (*self.state).showfullpaths

  user_default_scale = gpi_get_setting('gpitv_default_scale', default='log',/silent)
  if strcmp(user_default_scale,'sqrt',/fold_case) then user_default_scale = 'square root'
  tmp = where(strcmp((*self.state).scalings,user_default_scale,/fold_case),cc)
  if cc eq 0 then user_default_scale = 'log'
  self->setscaling, user_default_scale, /nodisplay

  tmp = gpi_get_setting('gpitv_noinfo',/silent,/int)
  if (size(tmp,/type) eq 2) && ( (tmp eq 0) || (tmp eq 1) ) then (*self.state).noinfo = tmp
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Suppress Information Messages")],$
    set_button = (*self.state).noinfo

  tmp = gpi_get_setting('gpitv_nowarn',/silent,/int)
  if (size(tmp,/type) eq 2) && ( (tmp eq 0) || (tmp eq 1) ) then (*self.state).nowarn = tmp
  widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Suppress Warning Messages")],$
    set_button = (*self.state).nowarn

  ;----- Build the entire info area -----
  track_base = widget_base(base, /row, frame=FR_DEBUG, xpad=2,ypad=2)

  ;----- Build the left side info column -----
  ; just base widgets for now - the actual fields are added down below.
  (*self.state).info_base_id = widget_base(track_base, /column, /base_align_left, frame=FR_DEBUG, xpad=0,ypad=0)
  info_base2_id = widget_base((*self.state).info_base_id, /column, /base_align_left,frame=0, space=0, xpad=0, ypad=0)
  info_head0_id = widget_base(info_base2_id, /column, /base_align_left, frame=FR_DEBUG, space=0, xpad=0, ypad=0)
  info_head0f_id = widget_base(info_head0_id, /row, /base_align_left, frame=0, space=0, xpad=0, ypad=0)

  ; make overall information area
  (*self.state).info_head_id = widget_base(info_head0_id, row=6,/grid, /base_align_left, frame=FR_DEBUG, space=0, xpad=1, ypad=1)
  ;	info_headL_id = widget_base((*self.state).info_head_id, /column, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_headR_id = widget_base((*self.state).info_head_id, /column, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_head2_id = widget_base(info_headL_id, /row, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_head3_id = widget_base(info_headL_id, /row, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_head4_id = widget_base(info_headL_id, /row, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_head5_id = widget_base(info_headL_id, /row, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_head6_id = widget_base(info_headL_id, /row, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_head2R_id = widget_base(info_headR_id, /row, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_head3R_id = widget_base(info_headR_id, /row, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_head4R_id = widget_base(info_headR_id, /row, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_head5R_id = widget_base(info_headR_id, /row, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;	info_head6R_id = widget_base(info_headR_id, /row, /base_align_left, frame=0, space=0, xpad=1, ypad=1)
  ;

  ;info_base3_id = widget_base(info_base2_id, /column, /base_align_left,frame=1, space=0, xpad=0, ypad=0)
  ;info_base3a_id = widget_base(info_base3_id,/column, /base_align_left, frame=1, space=0, xpad=0, ypad=0 ); , row=4)
  ;info_base3b_id = widget_base(info_base3_id, /column, /base_align_left, frame=1, space=0, xpad=0, ypad=0)
  ;info_base3c_id = widget_base(info_base3_id, /column, /base_align_left, frame=1, space=0, xpad=0, ypad=0)


  (*self.state).colorbar_base_id = widget_base((*self.state).info_base_id, $
    uvalue = 'colorbar_base', $
    /row, /base_align_left, /base_align_center, $
    frame = 2)


  ;----- Build the right side info column -----
  track_baseR =    widget_base(track_base, /column, /base_align_right, frame=FR_DEBUG)
  track_baseR0 =    widget_base(track_baseR, /row, /base_align_right, frame=FR_DEBUG)
  (*self.state).pan_widget_id = widget_draw(track_baseR0, $
    xsize = (*self.state).pan_window_size, $
    ysize = (*self.state).pan_window_size, $
    frame = 2, uvalue = 'pan_window', $
    /button_events, /motion_events)

  track_window = widget_draw(track_baseR0, $
    xsize=(*self.state).track_window_size, $
    ysize=(*self.state).track_window_size, $
    frame=2, uvalue='track_window')

  ;----- build the toolbar area (buttons added elsewhere)

  if keyword_set(ONE_LINE_TOOLBAR) then button_base = widget_base(base, row=1, /base_align_right,frame=FR_DEBUG)
  ;----- Build the bottom datacube slider area -----
  (*self.state).curimnum_base_id0 = widget_base(base, $
    /base_align_right, /base_align_center, row=1, $
    frame = 1, space=0, xpad=0, ypad=0)  ;, xsize=1, ysize=1, map=0)

  (*self.state).curimnum_base_id = widget_base((*self.state).curimnum_base_id0, $
    /base_align_center, row=1, /align_center, $
    frame = FR_DEBUG)

  ;------ and now the actual draw window!
  (*self.state).draw_base_id = widget_base(base, $
    /column, /base_align_left, $
    uvalue = 'draw_base', $
    frame = 0, /tracking_events, xpad=1, ypad=1)


  ;------ now fill in all the actual fields in the info area.
  void = widget_label (info_head0f_id, $
    value = 'Filename: ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).imagename_id = widget_label (info_head0f_id, $
    value = (*self.state).imagename,  $
    uvalue = 'filename',  frame = 1,  /DYNAMIC_RESIZE, /ALIGN_LEFT)


  aborted_base_id = widget_base(info_head0f_id,/base_align_right,frame=FR_DEBUG, space=0, xpad=0, ypad=0)
  (*self.state).aborted_base_id = aborted_base_id
  (*self.state).aborted_id = widget_button(aborted_base_id,/align_right,/dynamic_resize, uvalue='Aborted',/pushbutton_events)


  void = widget_label ((*self.state).info_head_id, $
    value = 'Date Obs: ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).dateobs_id = widget_label ((*self.state).info_head_id, $
    value = (*self.state).dateobs,  $
    uvalue = 'dateobs',  frame = 1,  /DYNAMIC_RESIZE, /ALIGN_CENTER)
  void = widget_label ((*self.state).info_head_id, $
    value = '   Time Obs: ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).timeobs_id = widget_label ((*self.state).info_head_id, $
    value = (*self.state).timeobs,  $
    uvalue = 'timeobs',  frame = 1, /DYNAMIC_RESIZE, /ALIGN_CENTER)

  void = widget_label ((*self.state).info_head_id, $
    value = 'Filter: ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).filter1_id = widget_label ((*self.state).info_head_id, $
    value = (*self.state).obsfilt,  $
    uvalue = 'obsfilt',  frame = 1, /DYNAMIC_RESIZE, /ALIGN_CENTER)

  ;void = widget_label (info_head3_id, $
  ;                                      value = 'Centr. wav(um): ',  $
  ;                                      uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  ;(*self.state).waveleng_id = widget_label (info_head3_id, $
  ;                                      value = (*self.state).waveleng,  $
  ;                                      uvalue = 'waveleng',  frame = 1, /DYNAMIC_RESIZE, /ALIGN_LEFT)
  void = widget_label ((*self.state).info_head_id, $
    value = '   Disperser: ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).filter2_id = widget_label ((*self.state).info_head_id, $
    value = (*self.state).filter2,  $
    uvalue = 'filter2',  frame = 1, /DYNAMIC_RESIZE, /ALIGN_CENTER)


  void = widget_label ((*self.state).info_head_id, $
    value = 'Int Time [s]: ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).exptime_id = widget_label ((*self.state).info_head_id, $
    value = (*self.state).exptime,  $
    uvalue = 'exptime',  frame = 1, /DYNAMIC_RESIZE, /ALIGN_CENTER)
  void = widget_label ((*self.state).info_head_id, $
    value = '   Readmode: ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).readmode_id = widget_label ((*self.state).info_head_id, $
    value = strcompress(string((*self.state).coadds)),  $
    uvalue = 'coadds',  frame = 1, /DYNAMIC_RESIZE, /ALIGN_CENTER)

  void = widget_label ((*self.state).info_head_id, $
    value = 'Object: ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).object_id = widget_label ((*self.state).info_head_id, $
    value = (*self.state).object,  $
    uvalue = 'object',  frame = 1, /DYNAMIC_RESIZE, /ALIGN_CENTER)

  void = widget_label ((*self.state).info_head_id, $
    value = '   Obs Type: ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).obstype_id = widget_label ((*self.state).info_head_id, $
    value = (*self.state).obstype,  $
    uvalue = 'obstype',  frame = 1, /DYNAMIC_RESIZE, /ALIGN_CENTER)

  ;void = widget_label (info_head6R_id, $
  ;                                      value = 'ObsClass: ',  $
  ;                                      uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE)
  ;(*self.state).obsclass_id = widget_label (info_head6R_id, $
  ;                                      value = (*self.state).obsclass,  $
  ;                                      uvalue = 'obsclass',  frame = 1, /DYNAMIC_RESIZE)

  void = widget_label ((*self.state).info_head_id, $
    value = '(X,Y) : ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).location_bar_id = widget_label ((*self.state).info_head_id, $
    value = string(1,1, format='("(", i4,",",i4,") ")'),  $
    uvalue = 'location_bar',  frame = 0, /DYNAMIC_RESIZE, /ALIGN_CENTER)
  void = widget_label ((*self.state).info_head_id, $
    value = '   Value : ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).value_bar_id = widget_label ((*self.state).info_head_id, $
    ;value = string(1, format='(g14.5)'),  $
    value = '1234567890', $ ;string(1, format='(g14.5)'),  $
    uvalue = ' ',  frame = 0,  /ALIGN_CENTER)
  ;uvalue = ' ',  frame = 0, /DYNAMIC_RESIZE, /ALIGN_CENTER)

  ;tmp_string = string(1000, 1000, 1.0e-10, $
  ;;                     format = '("(",i5,",",i5,") ",g10.5)')
  ;format = '("Pixel Pos(x,y)/Mag: ", "(",i5,",",i5,") ",g14.7)')
  ;(*self.state).location_bar_id = widget_label (info_base3b_id, $
  ;value = tmp_string,  $
  ;uvalue = 'location_bar',  frame = 1)
  void = widget_label ((*self.state).info_head_id, $
    value = 'Min= ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)


  ;tmp_string = string(0.0, 0.0,format='("Min= ", g14.7,"  Max= ", g14.7)')
  tmp_string = string(0.0, format='(g14.7)')
  (*self.state).minIma_id=widget_label ((*self.state).info_head_id,value=tmp_string,  $
    uvalue = ' ',  frame = 0)


  void = widget_label ((*self.state).info_head_id, $
    value = '   Max= ',  $
    uvalue = 'text',  frame = 0,  /DYNAMIC_RESIZE, /ALIGN_LEFT)
  (*self.state).maxIma_id=widget_label ((*self.state).info_head_id ,value=tmp_string,  $
    uvalue = ' ',  frame = 0)

  ;widget_control, (*self.state).minimaIma_id,  xsize=250

  tmp_string = string(12, 12, 12.001, -60, 60, 60.01, ' J2000', $
    format = '("WCS coord: ", i2,":",i2,":",f6.3,"  ",i3,":",i2,":",f5.2," ",a6)' )

  (*self.state).wcs_bar_id = widget_label (info_base2_id, $
    value = tmp_string,  $
    uvalue = 'wcs_bar',  frame = 1)

  *(*self.state).unitslist = ['ADU per coadd', 'ADU/s','ph/s/nm/m^2', 'Jy', 'W/m^2/um','ergs/s/cm^2/A','ergs/s/cm^2/Hz']
  (*self.state).units_droplist_id = widget_droplist(track_baseR, $
    frame = FR_DEBUG, $			;MDP
    title = 'Units:', $
    uvalue = 'units', $
    value = *(*self.state).unitslist)



  ;modebase = widget_base(track_baseR, /row, /base_align_center,frame=1) ;MDP
  ;;for calculation of locations of sat-spots
  IF keyword_set(nbrsatspot) THEN (*self.state).nbrsatspot=nbrsatspot

  modelist = ['None', 'Recenter/Color', 'Zoom', 'Blink', 'Statistics 2D/3D','Plot Cut along Vector','Measure Distance', $
    'Photometry','Spectrum Plot','Draw Region','Row/Column Plot','Gauss Row/Column Plot',$
    'Histogram/Contour Plot','Surface Plot','Move Wavecal Grid']
  ;;if (*self.state).nbrsatspot ne 0 then modelist=[modelist,'SAT-SPOT LOCALIZE']
  ;;this isn't a valid mode is it? - ds 11/21/12

  (*self.state).mousemode_count = n_elements(modelist)

  mode_droplist_id = widget_droplist(track_baseR, $
    frame = 0, $
    title = 'Mouse Mode:', $
    uvalue = 'mode', $
    value = modelist)
  (*self.state).mode_droplist_id = mode_droplist_id
  widget_control, (*self.state).mode_droplist_id, set_droplist_select = (*self.state).mousemode


  ;------ add Buttons to the toolbar area

  if ~(keyword_set(ONE_LINE_TOOLBAR)) then begin
    buttonbar_base = widget_base(track_baseR, column=2,  /base_align_center, frame=FR_DEBUG)
    button_base = widget_base(buttonbar_base, row=2, /base_align_right,frame=FR_DEBUG)
  endif


  invert_button = widget_button(button_base, $
    value = 'Invert', $
    uvalue = 'invert')

  restretch_button = widget_button(button_base, $
    value = 'Restretch', $
    uvalue = 'restretch_button')

  autoscale_button = widget_button(button_base, $
    uvalue = 'autoscale_button', $
    value = 'AutoScale')

  fullrange_button = widget_button(button_base, $
    uvalue = 'full_range', $
    value = 'FullRange')

  (*self.state).keyboard_text_id = widget_text(button_base, $
    /all_events, $
    scr_xsize = 1, $
    scr_ysize = 1, $
    units = 0, $
    uvalue = 'keyboard_text', $
    value = '')
  zoomin_button = widget_button(button_base, $
    value = 'ZoomIn', $
    uvalue = 'zoom_in')

  zoomout_button = widget_button(button_base, $
    value = 'ZoomOut', $
    uvalue = 'zoom_out')

  zoomone_button = widget_button(button_base, $
    value = 'Zoom1', $
    uvalue = 'zoom_one')
  done_button = widget_button(button_base, $
    value = 'ZoomFit', $
    uvalue = 'zoomFit')

  center_button = widget_button(button_base, $
    value = 'Center', $
    uvalue = 'center')

  modelist = ['Show Cube Slices', 'Collapse by Mean', 'Collapse by Median', 'Collapse to RGB Color']
  (*self.state).collapse_button = widget_droplist((*self.state).curimnum_base_id0, $
    uvalue = 'collapse', $
    value = modelist, /align_center);, /base_align_center)


  (*self.state).curimnum_text_id = cw_field((*self.state).curimnum_base_id, $
    uvalue = 'curimnum_text', $
    /long,  $
    /row, $
    title = 'Image #:', $
    value = (*self.state).cur_image_num, $
    /return_events, $
    xsize = 3)

  (*self.state).curimnum_lamblabel_id = widget_label((*self.state).curimnum_base_id, value="Wavelen[um]:")

  (*self.state).curimnum_textlamb_id = widget_text((*self.state).curimnum_base_id, $
    uvalue = 'curimnum_textlamb', $
    ;/floating,  $
    ;title = 'wav(um)=', $
    /editable, $
    value = '-1.', $
    ;/return_events, $
    xsize = 5)
  (*self.state).curimnum_slidebar_id = widget_slider((*self.state).curimnum_base_id, $
    /drag, $
    max = 1, $
    min = 0, $
    scr_xsize = 125L, $
    sensitive = 1, $
    scroll = 1L, $
    /suppress_value, $
    uvalue = 'curimnum_slidebar', $
    value = 0, $
    vertical = 0)

  modelist = ['Constant', 'AutoScale', 'Min/Max']
  (*self.state).scale_mode_droplist_id = widget_droplist((*self.state).curimnum_base_id, $
    uvalue = 'curimnum_minmaxmode', $
    value = modelist)



  (*self.state).draw_window_size[1] = (*self.state).draw_window_size[1] < $
    ((*self.state).screen_ysize - 380) ; maximum height of draw window size must leave many pixels free for widgets
  ; this size of 380 pixels is based on
  ; measurements on a Macbook pro; should
  ; also check on windows. -MP

  (*self.state).draw_widget_id = widget_draw((*self.state).draw_base_id, $
    uvalue = 'draw_window', $
    /motion_events,  /button_events, $
    /keyboard_events, $ ; MDP edit to re-enable arrow keys??
    scr_xsize = (*self.state).draw_window_size[0], $
    scr_ysize = (*self.state).draw_window_size[1])

  (*self.state).min_text_id = cw_field((*self.state).colorbar_base_id, $
    uvalue = 'min_text', $
    ;/floating,  $
    title = 'Min=', $
    ;							 /align_center,$
    value = (*self.state).min_value,  $
    /return_events, $
    xsize = 8)



  (*self.state).colorbar_widget_id = widget_draw((*self.state).colorbar_base_id, $
    uvalue = 'colorbar', $
    ;scr_xsize = 0.6*(*self.state).draw_window_size[0], $
    scr_xsize = 150, $
    /align_center,$
    scr_ysize = (*self.state).colorbar_height)


  (*self.state).max_text_id = cw_field((*self.state).colorbar_base_id, $
    uvalue = 'max_text', $
    ;/floating,  $
    title = 'Max=', $
    value = (*self.state).max_value, $
    /return_events, $
    xsize = 8)

  ; Create the widgets on screen

  widget_control, base, /realize
  widget_control, (*self.state).pan_widget_id, draw_motion_events = 0

  ; Make the "Image # =" and Scale droplist widgets insensitive until
  ; image is loaded

  ;widget_control, (*self.state).scale_mode_droplist_id, sensitive = 0
  ;widget_control, (*self.state).curimnum_text_id, sensitive = 0

  ; get the window ids for the draw widgets

  widget_control, track_window, get_value = tmp_value
  (*self.state).track_window_id = tmp_value
  widget_control, (*self.state).draw_widget_id, get_value = tmp_value
  (*self.state).draw_window_id = tmp_value
  widget_control, (*self.state).pan_widget_id, get_value = tmp_value
  (*self.state).pan_window_id = tmp_value
  widget_control, (*self.state).colorbar_widget_id, get_value = tmp_value
  (*self.state).colorbar_window_id = tmp_value

  ; set the event handlers

  widget_control, top_menu, event_pro = 'GPItvo_menu_event'
  widget_control, (*self.state).draw_widget_id, event_pro = 'GPItvo_generic_event_handler'
  widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_color_event'}
  widget_control, (*self.state).draw_base_id, event_pro = 'GPItvo_generic_event_handler'
  widget_control, (*self.state).draw_base_id, set_uvalue = {object:self, method: 'draw_base_event'}
  widget_control, (*self.state).keyboard_text_id, event_pro = 'GPItvo_generic_event_handler'
  widget_control, (*self.state).keyboard_text_id, set_uvalue = {object:self, method: 'keyboard_event'}
  widget_control, (*self.state).pan_widget_id, event_pro = 'GPItvo_generic_event_handler'
  widget_control, (*self.state).pan_widget_id, set_uvalue = {object:self, method: 'pan_event'}

  ;	; Find window padding sizes needed for resizing routines.
  ;	; Add extra padding for menu bar, since this isn't included in
  ;	; the geometry returned by widget_info.
  ;	; Also add extra padding for margin (frame) in draw base.
  ;
  ;	basegeom = widget_info((*self.state).base_id, /geometry)
  ;	drawbasegeom = widget_info((*self.state).draw_base_id, /geometry)
  ;

  ; Initialize the vectors that hold the current color table.
  ; See the routine self->stretchct to see why we do it this way.

  self.colors.r_vector = bytarr((*self.state).ncolors)
  self.colors.g_vector = bytarr((*self.state).ncolors)
  self.colors.b_vector = bytarr((*self.state).ncolors)

  self->getct, 1, 'Blue-White'
  (*self.state).invert_colormap = 0

  ; Create a pixmap window to hold the pan image
  window, /free, xsize=(*self.state).pan_window_size, ysize=(*self.state).pan_window_size, $
    /pixmap
  (*self.state).pan_pixmap = !d.window
  self->resetwindow

  self->colorbar

  widget_control, (*self.state).base_id, tlb_get_size=tmp_event
  widget_control, (*self.state).base_id, set_uvalue=self


  (*self.state).base_pad = tmp_event - (*self.state).draw_window_size
  (*self.state).base_pad[0]=6
  (*self.state).base_min_size[0] = tmp_event[0] ; MDP

  self->resize

end

;--------------------------------------------------------------------

pro GPItv::colorbar

  ;; Routine to tv the colorbar at the bottom of the GPItv window

  self->setwindow, (*self.state).colorbar_window_id

  xsize = (widget_info((*self.state).colorbar_widget_id, /geometry)).xsize

  b = congrid( findgen((*self.state).ncolors), 1.5*xsize) + 8
  c = replicate(1, (*self.state).colorbar_height)
  a = b # c

  tv, a

  self->resetwindow

end

;-------------------------------------------------------------------

pro GPItv::clear

  ;; displays a small blank image, useful for clearing memory if GPItv is
  ;; displaying a huge image.

  GPItv, fltarr(10,10)

end

;--------------------------------------------------------------------

pro GPItv::shutdown, windowid,nocheck=nocheck
  ;; nocheck is only used when you really want to quit no matter what...

  if (*self.state).confirm_before_quit and ~(keyword_set(nocheck)) then begin
    if dialog_message('Are you sure you want to quit gpitv?',/question, dialog_parent = (*self.state).base_id) ne 'Yes' then return
  end

  ;; routine to kill the GPItv window(s) and clear variables to conserve
  ;; memory when quitting GPItv.  The windowid parameter is used when
  ;; GPItv_shutdown is called automatically by the xmanager, if GPItv is
  ;; killed by the window manager.


  ;; reset color table and pmulti to user values
  tvlct, self.colors.user_r, self.colors.user_g, self.colors.user_b
  !p.multi = (*self.state).active_window_pmulti


  ;; Kill top-level base if it still exists
  if (xregistered (self.xname)) then widget_control, (*self.state).base_id, /destroy
  ;; NOTE: THis call to widget_control will itself call this shutdown procedure!

  obj_destroy, self ; call the object cleanup routine immediately below...
end

pro gpitv::cleanup
  ; Destroy all pointers to plots and their heap variables: this runs
  ; ptr_free on any existing plot pointers
  if (self.pdata.nplot GT 0) then begin
    self->erase, /norefresh
  endif

  ; Only check the following if the state struct
  ; still exists. (The call to widget_control above will
  ; call shutdown and undefine the struct, so that this
  ; code only get called the first time through in that case.)
  ; - MDP 2009-02-01
  if (size(*self.state, /tname) EQ 'STRUCT') then begin
    ;for multi-session, shutdown idl
    ;if ((*self.state).multisess ge 0) then exitidl=(*self.state).multisess

    if (!d.name EQ (*self.state).graphicsdevice) then wdelete, (*self.state).pan_pixmap
    if (ptr_valid((*self.state).head_ptr)) then ptr_free, (*self.state).head_ptr
    if (ptr_valid((*self.state).exthead_ptr)) then ptr_free, (*self.state).exthead_ptr
    if (ptr_valid((*self.state).astr_ptr)) then ptr_free, (*self.state).astr_ptr
    if (ptr_valid((*self.state).CWV_ptr)) then ptr_free, (*self.state).CWV_ptr
    if (ptr_valid((*self.state).reg_ids_ptr)) then ptr_free, (*self.state).reg_ids_ptr
    if (ptr_valid((*self.state).writeimage_ids_ptr)) then ptr_free, (*self.state).writeimage_ids_ptr
    if (ptr_valid((*self.state).makemovie_ids_ptr)) then ptr_free, (*self.state).makemovie_ids_ptr
  endif

  for i=0,n_elements(self.pdata.plot_ptr)-1 do ptr_free, self.pdata.plot_ptr[i]
  self.pdata.maxplot=0
  ptr_free, self.images.main_image
  ptr_free, self.images.main_image_stack
  ptr_free, self.images.main_image_backup
  ptr_free, self.images.names_stack

  ptr_free, self.images.display_image
  ptr_free, self.images.scaled_image
  ptr_free, self.images.blink_image1
  ptr_free, self.images.blink_image2
  ptr_free, self.images.blink_image3
  ptr_free, self.images.unblink_image
  ptr_free, self.images.dq_image_stack
  ptr_free, self.images.dq_image
  ptr_free, self.images.pan_image
  ptr_free, self.images.klip_image
  ptr_free, self.state

  ptr_free, self.satspots.cens
  ptr_free, self.satspots.warns
  ptr_free, self.satspots.good
  ptr_free, self.satspots.satflux
  ;;need these two to be recursive as they are pointers to pointers
  heap_free, self.satspots.asec
  heap_free, self.satspots.contrprof

  heap_gc
end


;--------------------------------------------------------------------
;                  main GPItv event loops
;--------------------------------------------------------------------

pro GPItv::topmenu_event, event
  ;; Event handler for top menu

  @gpitv_err

  widget_control, event.id, get_uvalue = event_name

  if (!d.name NE (*self.state).graphicsdevice and event_name NE 'Quit') then return
  if ((*self.state).bitdepth EQ 24) then true = 1 else true = 0

  ; Need to get active window here in case mouse goes to menu from top
  ; of GPItv window without entering the main base
  self->getwindow

  case event_name of

    ;; File menu options:
    'Open...':			self->readfits
    'Browse Files...':	self->directory_viewer
    'Show gpidiagram...':	self->show_gpidiagram
    ;   'DetectFits':			fitsget,'gpitv'
    'Write FITS...':			self->writefits
    'Write PS...' :				self->writeps
    'Write Image...':			self->writeimage
    'Make Movie...':			self->makemovie
    'PNG':					self->writeimage, 'png'
    'JPEG':					self->writeimage, 'jpg'
    'TIFF':					self->writeimage, 'tiff'
    'Save Image to IDL variable': self->SaveToVariable, "Image"
    'Save Image Cube to IDL variable': self->SaveToVariable, "Cube"
    'Save FITS Header to IDL variable': self->SaveToVariable,  "Header"
    'Get Image from Catalog...':
    ' DSS':					self->getdss
    ' FIRST':				self->getfirst
    'Load Regions':			self->regionfilelabel
    'Save Regions':			self->saveregion
    'Quit':     if ((*self.state).activator EQ 0) then self->shutdown $
    else (*self.state).activator = 0

    ;; ColorMap menu options:
    'Grayscale': 		self->getct, 0 ,event_name
    'Blue-White': 		self->getct, 1,event_name
    'GRBW':				self->getct, 2,event_name
    'Red-White': 		self->getct, 3,event_name
    'BGRY':				self->getct, 4,event_name
    'Standard Gamma-II':self->getct, 5,event_name
    'Prism':			self->getct, 6,event_name
    'Red-Purple': 		self->getct, 7,event_name
    'Green-White': 		self->getct, 8,event_name
    'Blue-Red (Jet)': 	self->getct, 11,event_name
    '16 Level': 		self->getct, 12,event_name
    'Rainbow':			self->getct, 13,event_name
    'Stern Special': 	self->getct, 15,event_name
    'Haze' :			self->getct, 16,event_name
    'Blue-Pastel-Red': 	self->getct, 17,event_name
    'Mac':				self->getct, 25,event_name
    'Plasma':			self->getct, 32,event_name
    'Blue-Red 2': 		self->getct, 33,event_name
    'Rainbow18': 		self->getct, 38,event_name
    'GPItv Special': 	self->makect, event_name
    'Cubehelix': 		self->makect, event_name
    'Cubehelix Settings...': 		self->set_cubehelix
    'Velocity': 		self->makect, event_name

    ;; Scaling options:
    'Linear': self->setscaling, 'Linear'
    'Log': self->setscaling, 'Log'
    'HistEq': self->setscaling, 'HistEq'
    'Square Root': self->setscaling, 'Square Root'
    'Asinh': self->setscaling, 'Asinh'
    'Asinh Settings...': begin
      self->setasinh
    end
    'Auto Scale': self->setscalerange, 'autoscale'
    'Full Range': self->setscalerange, 'full_range'
    'Zero to Max': self->setscalerange, 'zero_to_max'

    ;; Label options:
    'TextLabel': self->textlabel
    'Arrow': self->arrowlabel
    'Contour': self->oplotcontour
    'Compass': self->setcompass
    'ScaleBar': self->setscalebar
    'Polarimetry': self->polarim_options_dialog
    'Draw Region': self->regionlabel
    'WCS Grid': self->wcsgridlabel
    'Select Wavecal/Polcal File': self->selectwavecal
    'Get Wavecal/Polcal from CalDB': self->getautowavecal
    'Plot Wavecal/Polcal Grid': self->wavecalgridlabel
    'EraseLast': self->erase, 1
    'EraseAll': begin
      self->erase
      (*self.state).wavsamp=0
      (*self.state).oplot=0
      self->refresh
    end
    'Load Regions': self->regionfilelabel
    'Save Regions': self->saveregion

    ;; Blink options:
    'SetBlink1': begin
      self->setwindow, (*self.state).draw_window_id
      *self.images.blink_image1 = tvrd(true = true)
      (*self.state).title_blink1 = (*self.state).window_title
      widget_control, (*self.state).menu_ids[where((*self.state).menu_labels eq 'SetBlink1')],/set_button

    end
    'SetBlink2': begin
      self->setwindow, (*self.state).draw_window_id
      *self.images.blink_image2 = tvrd(true = true)
      (*self.state).title_blink2 = (*self.state).window_title
      widget_control, (*self.state).menu_ids[where((*self.state).menu_labels eq 'SetBlink2')],/set_button
    end
    'SetBlink3': begin
      self->setwindow, (*self.state).draw_window_id
      *self.images.blink_image3 = tvrd(true = true)
      (*self.state).title_blink3 = (*self.state).window_title
      widget_control, (*self.state).menu_ids[where((*self.state).menu_labels eq 'SetBlink3')],/set_button
    end

    'MakeRGB' : self->makergb

    ;; Zoom options:
    'Zoom In': self->zoom, 'in'
    'Zoom Out': self->zoom, 'out'
    'Zoom to Fit': self->autozoom
    '1/16': self->zoom, 'onesixteenth'
    '1/8': self->zoom, 'oneeighth'
    '1/4': self->zoom, 'onefourth'
    '1/2': self->zoom, 'onehalf'
    '1': self->zoom, 'one'
    '2': self->zoom, 'two'
    '4': self->zoom, 'four'
    '8': self->zoom, 'eight'
    '16': self->zoom, 'sixteen'
    'Center': begin
      (*self.state).centerpix = round((*self.state).image_size[0:1] / 2.)
      self->refresh
    end
    'No Inversion': self->invert, 'none'
    'Invert X': self->invert, 'x'
    'Invert Y': self->invert, 'y'
    'Invert X && Y': self->invert, 'xy'
    ;'Rotate': self->rotate, '0', /get_angle
    'Rotate 0 deg': self->rotate, '0'
    'Rotate 90 deg': self->rotate, '90'
    'Rotate 180 deg': self->rotate, '180'
    'Rotate 270 deg': self->rotate, '270'
    'Rotate GPI field square': begin
      sz = size(*self.images.main_image)
      if sz[1] eq 2048 and sz[2] eq 2048 then begin
        self->message, "You're currently looking at a raw 2D image, which is already inherently square. No rotation needed"
      endif else begin
        self->rotate, (-1) * gpi_get_constant('ifs_rotation_angle', default=24.5)
      endelse
    end
    'Rotate north up': begin
      if ptr_valid( (*self.state).exthead_ptr) and (*self.state).wcstype ne 'none' then begin
        self->message, 'Rotating to north=up, east=left'

        ; Let's flip the handedness so we get the conventional "north up,
        ; east left" view.
        ; Always do inversions prior to rotation.
        self->autohandedness,/nodisplay

        ; compute which direction North is pointing, relative to the +Y axis
        ; of the image
        ;
        getrot, *(*self.state).exthead_ptr, npa, cdelt, /silent



        ; the gpitv::rotate function however doesn't take a relative
        ; rotation, it takes an absolute rotation relative to the image's
        ; native orientation. So we need to take the difference

        self->rotate,   (*self.state).rot_angle - npa


      endif else begin
        text_warn = 'The current image does not have a valid WCS header, and thus we cannot rotate it to have north up.'
        self->message, text_warn, msgtype='error', /window

      endelse
    end

    'Rotate arbitrary angle': self->rotate, /get_angle

    ;; Info options:
    'Contrast': self->contrast
    'Photometry': self->apphot
    '': self->apphot
    'View FITS Header...': self->headinfo,/show
    'Change FITS extension...': self->switchextension
    'Print Filename': print, (*self.state).imagename
    'Statistics': self->showstats
    'Histogram / Exposure': self->showhist
    'Pixel Table': self->pixtable
    'Star Position': self->centerplot
    'FPM Offset': self->show_fpmoffset

    'Archive Image': self->getimage

    ;; Coordinate system options:
    '--------------':
    'RA,dec (J2000)': BEGIN
      (*self.state).display_coord_sys = 'RA--'
      (*self.state).display_equinox = 'J2000'
      (*self.state).display_base60 = 1B
      self->gettrack            ; refresh coordinate window
    END
    'RA,dec (B1950)': BEGIN
      (*self.state).display_coord_sys = 'RA--'
      (*self.state).display_equinox = 'B1950'
      (*self.state).display_base60 = 1B
      self->gettrack            ; refresh coordinate window
    END
    'RA,dec (J2000) deg': BEGIN
      (*self.state).display_coord_sys = 'RA--'
      (*self.state).display_equinox = 'J2000'
      (*self.state).display_base60 = 0B
      self->gettrack            ; refresh coordinate window
    END
    'Galactic': BEGIN
      (*self.state).display_coord_sys = 'GLON'
      self->gettrack            ; refresh coordinate window
    END
    'Ecliptic (J2000)': BEGIN
      (*self.state).display_coord_sys = 'ELON'
      (*self.state).display_equinox = 'J2000'
      self->gettrack            ; refresh coordinate window
    END
    'Native': BEGIN
      IF ((*self.state).wcstype EQ 'angle') THEN BEGIN
        (*self.state).display_coord_sys = strmid((*(*self.state).astr_ptr).ctype[0], 0, 4)
        (*self.state).display_equinox = (*self.state).equinox
        self->gettrack         ; refresh coordinate window
      ENDIF
    END
    'Mark File Status':              self->obsnotes

    ;;Options options
    'Contrast Settings...':          self->contrast_settings
    'KLIP Settings...':              self->KLIP_settings
    'SDI Settings...':               self->SDI_settings
    'High pass filter Settings...':  self->high_pass_filter_settings
    'Clear KLIP Data': BEGIN
      ptr_free,self.images.klip_image
      self.images.klip_image = ptr_new(/allocate_heap)
    END

    'Mark Sat Spots': BEGIN
      (*self.state).mark_sat_spots = 1 - (*self.state).mark_sat_spots
      widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Mark Sat Spots")],$
        set_button = (*self.state).mark_sat_spots
	  self->refresh
    END

    'Retain Current Slice': BEGIN
      (*self.state).retain_current_slice = 1 - (*self.state).retain_current_slice
      widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Retain Current Slice")],$
        set_button = (*self.state).retain_current_slice
    END

    "Retain Current Stretch": begin
      (*self.state).retain_current_stretch = 1 - (*self.state).retain_current_stretch
      widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Retain Current Stretch")],$
        set_button = (*self.state).retain_current_stretch
    end
    "Retain Current View": begin
      (*self.state).retain_current_view = 1 - (*self.state).retain_current_view
      widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Retain Current View")],$
        set_button = (*self.state).retain_current_view
    end
    "Retain Collapse Mode": begin
      (*self.state).retain_collapse_mode = 1 - (*self.state).retain_collapse_mode
      widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Retain Collapse Mode")],$
        set_button = (*self.state).retain_collapse_mode
    end

    'Flag Bad Pix from DQ': BEGIN
      (*self.state).flag_bad_pix_from_dq = 1 - (*self.state).flag_bad_pix_from_dq
      widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Flag Bad Pix from DQ")],$
        set_button = (*self.state).flag_bad_pix_from_dq
      self->displayall
    END
    'DQ bitmask Settings...': self->dq_mask_settings

    "Auto Handedness": begin
      (*self.state).autohandedness = ~ (*self.state).autohandedness
      widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Auto Handedness")],$
        set_button = (*self.state).autohandedness
    end

    'Display Full Paths': begin
      (*self.state).showfullpaths = ~ (*self.state).showfullpaths
      widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Display Full Paths")],$
        set_button = (*self.state).showfullpaths
      self->settitle
    end

    'Suppress Information Messages': begin
      (*self.state).noinfo = ~ (*self.state).noinfo
      widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Suppress Information Messages")],$
        set_button = (*self.state).noinfo
    end

    'Suppress Warning Messages': begin
      (*self.state).nowarn = 1 - (*self.state).nowarn
      widget_control,  (*self.state).menu_ids[ where((*self.state).menu_labels eq "Suppress Warning Messages")],$
        set_button = (*self.state).nowarn
    end

    ;; Help options:
    'Quick Help': self->help

    'Online Help': gpi_open_help,'gpitv/index.html'

    'Developer Guide': gpi_open_help,'developers/gpitv_devel.html'

    'About': begin
      tmpstr=['GPItv Version: '+strc(gpi_pipeline_version(/svn)), $
        '', $
        'GPItv is a modified version of the package ATV written by Aaron Barth.',$
        'http://www.physics.uci.edu/~barth/atv/',$
        '',$
        '--------- Development: ---------', $
        '', $
        '  Marshall Perrin (mperrin@stsci.edu)', $
        '  Jerome Maire (maire@utoronto.ca)', $
        '', $
        '  Contributions from: (alphabetically)',$
        '    Patrick Ingraham', $
        '    Christian Marois', $
        '    Naru Sadakuni',$
        '    Dmitry Savransky',$
        '', $
        '--------- Documentation: ---------', $
        '', $
        '    Marshall Perrin', $
        '    Jerome Maire', $
        '    Dmitry Savransky',$
        '', $
        '-------- Acknowledgements: --------', $
        '', $
        '  Rene Doyon, Bruce Macintosh, Stephen Goodsell, and ',$
        '    all other Gemini and GPI team members', $
        '    who have helped to improve the GPI DRP', $
        '', $
        '------------------------------', $
        ' ', $
        'The project web site is:   http://planetimager.org/', $
        'GPItv documentation at:    http://docs.planetimager.org/pipeline/gpitv/',$
        'Developer guide at:  http://docs.planetimager.org/pipeline/developers/gpitv_devel.html',$
        '', $
        '']
      ret=dialog_message(tmpstr,/information,/center,dialog_parent=event.top)
    end

    else: self->message, msgtype='error', 'Unknown event in file menu!'
  endcase

  ; Need to test whether GPItv is still alive, since the quit option
  ; might have been selected.
  if obj_valid(self) then if (xregistered(self.xname, /noshow)) then self->resetwindow

end


;--------------------------------------------------------------------


pro GPItv::draw_color_event, event

  ; Event handler for color mode

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  case event.type of
    0: begin           ; button press
      if (event.press EQ 1) then begin
        self->zoom, 'none', /recenter
      endif else begin
        (*self.state).cstretch = 1
        self->stretchct, event.x, event.y, /getmouse
        self->colorbar

      endelse
    end
    1: begin
      (*self.state).cstretch = 0  ; button release
      if ((*self.state).bitdepth EQ 24) then self->refresh
      self->draw_motion_event, event
    end
    2: begin                ; motion event
      if ((*self.state).cstretch EQ 1) then begin
        self->setwindow,(*self.state).draw_window_id,/nostretch
        self->stretchct, event.x, event.y, /getmouse
        self->resetwindow
        if ((*self.state).bitdepth EQ 24) then self->refresh, fast=~((*self.state).rgb_mode)
      endif else begin
        self->draw_motion_event, event
      endelse
    end
    ; Starting with IDL 6.0, can generate events on arrow keys:
    6: begin
      case event.key of
        5: self->move_cursor, '4'
        6: self->move_cursor, '6'
        7: self->move_cursor, '8'
        8: self->move_cursor, '2'
        else:
      endcase
    end
    else: begin
      self->message, msgtype = 'error',  'unknown event, ignoring it'
    end
  endcase

  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro GPItv::draw_rowcol_event, event

  ;;event handler for row/col plot

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  if (event.type EQ 0) then begin
    case event.press of
      1: self->rowplot
      4: self->colplot
      else:
    endcase
  endif

  if (event.type EQ 2) then self->draw_motion_event, event

  widget_control, (*self.state).draw_widget_id, /clear_events
  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro GPItv::draw_gauss_rowcol_event, event

  ;;event handler for row/col plot

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  if (event.type EQ 0) then begin
    case event.press of
      1: self->gaussrowplot
      4: self->gausscolplot
      else:
    endcase
  endif

  if (event.type EQ 2) then self->draw_motion_event, event

  widget_control, (*self.state).draw_widget_id, /clear_events
  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro GPItv::draw_histcont_event, event

  ;;event handler for row/col plot

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  if (event.type EQ 0) then begin
    case event.press of
      1: self->histplot
      4: self->contourplot
      else:
    endcase
  endif

  if (event.type EQ 2) then self->draw_motion_event, event

  widget_control, (*self.state).draw_widget_id, /clear_events
  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro GPItv::draw_surf_event, event

  ;;event handler for row/col plot

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  if (event.type EQ 0) then begin
    case event.press of
      1: self->surfplot
      else:
    endcase
  endif

  if (event.type EQ 2) then self->draw_motion_event, event

  widget_control, (*self.state).draw_widget_id, /clear_events
  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro GPItv::keyboard_event, event

  ;; Event procedure for keyboard input when the cursor is in the
  ;; main draw window.
  ;; print, 'keybd'

  @gpitv_err

  if event.ch eq byte(4) then begin
    self->message, msgtype = 'information', 'Dumping state to Main.'
    (scope_varfetch('state',  level=1, /enter)) = *self.state
    return
  endif

  eventchar = string(event.ch)

  if (!d.name NE (*self.state).graphicsdevice and eventchar NE 'q') then return

  case eventchar of
    '1': self->move_cursor, eventchar
    '2': self->move_cursor, eventchar
    '3': self->move_cursor, eventchar
    '4': self->move_cursor, eventchar
    '6': self->move_cursor, eventchar
    '7': self->move_cursor, eventchar
    '8': self->move_cursor, eventchar
    '9': self->move_cursor, eventchar
    'y': self->centerplot
    'r': self->rowplot         ;, /newcoord
    'c': self->colplot         ;, /newcoord
    's': self->surfplot        ;, /newcoord
    't': self->contourplot     ;, /newcoord
    'g': self->regionlabel
    'h': self->histplot        ;, /newcoord
    'j': self->gaussrowplot
    'k': self->gausscolplot
    'l': if ((*self.state).image_size[2] gt 1) then begin
      self->slice3dplot
    endif else begin
      self->message, 'Image must be 3D for pixel slice', $
        msgtype='error', /window
      return
    endelse
    'p': self->apphot
    'i': self->showstats
    'm': self->changemode
    'b': self->changeimage,/previous
    'n': self->changeimage,/next
    'E': self->erase           ; Erase
    '-': self->zoom, 'out'
    '+': self->zoom, 'in'
    '=': self->zoom, 'in'
    'P': begin
      print,(*self.state).coord[0],(*self.state).coord[1]
      if (ptr_valid((*self.state).astr_ptr)) then if ((*self.state).wcstype EQ 'angle') then begin
        xy2ad, (*self.state).coord[0], (*self.state).coord[1], *((*self.state).astr_ptr), lon, lat

        wcsstring = self->wcsstring(lon, lat, (*(*self.state).astr_ptr).ctype,  $
          (*self.state).equinox, (*self.state).display_coord_sys, $
          (*self.state).display_equinox, (*self.state).display_base60)
        print, wcsstring
      endif

    end
    '!': begin
      self->setwindow, (*self.state).draw_window_id
      *self.images.blink_image1 = tvrd(true = true)
      self->resetwindow
    end
    '@': begin
      self->setwindow, (*self.state).draw_window_id
      *self.images.blink_image2 = tvrd(true = true)
      self->resetwindow
    end
    '#': begin
      self->setwindow, (*self.state).draw_window_id
      *self.images.blink_image3 = tvrd(true = true)
      self->resetwindow
    end
    'q': begin
      if ((*self.state).activator EQ 0) then self->shutdown else $
        (*self.state).activator = 0
    end
    'Q': begin
      if ((*self.state).activator EQ 0) then self->shutdown else $
        (*self.state).activator = 0
    end
    'a': begin                 ; autoscale
      self->autoscale
      self->displayall
    end
    'M': begin                 ; minmax
      (*self.state).max_value = (*self.state).image_max
      (*self.state).min_value = (*self.state).image_min
      self->set_minmax        ; update values on screen
      self->displayall

    end
    'z': self->pixtable
    'R': self->rotate, /get_angle
    else:                      ;any other key press does nothing
  endcase

  ;; Starting with IDL 6.0, can generate events on arrow keys:
  if (event.type EQ 6) then begin
    self->message, msgtype = 'information', "arrow"
    case event.key of
      5: self->move_cursor, '4'
      6: self->move_cursor, '6'
      7: self->move_cursor, '8'
      8: self->move_cursor, '2'
      else:
    endcase
  endif
  ;; Need to test whether GPItv is still alive, since the quit option
  ;; might have been selected.

  if obj_valid(self) then if (xregistered(self.xname, /noshow)) then $
    widget_control, (*self.state).keyboard_text_id, /clear_events

end

;-------------------------------------------------------------------

pro GPItv::activate

  ; This routine is a workaround to use when you hit an error message or
  ; a "stop" command in another program while running GPItv.  If you want
  ; GPItv to become active again without typing "retall" and losing your
  ; current session variables, type "GPItv_activate" to temporarily
  ; activate GPItv again.  This will de-activate the command line but
  ; allow GPItv to be used until you hit "q" or click "done" in GPItv.

  ; Also, if you need to call GPItv from a command-line idl program and
  ; have that program wait until you're done looking at an image in GPItv
  ; before moving on to its next step, you can call GPItv_activate after
  ; sending your image to GPItv.  This will make your external program
  ; stop until you quit out of GPItv_activate mode.

  if (not(xregistered(self.xname, /noshow))) then begin
    self->message, msgtype = 'error', 'No GPItv window currently exists.'
    return
  endif

  (*self.state).activator = 1
  activator = 1

  while (activator EQ 1) do begin

    wait, 0.01
    void = widget_event(/nowait)

    ; If GPItv is killed by the window manager, then by the time we get here
    ; the state structure has already been destroyed by GPItv_shutdown.
    if (size(state, /type) NE 8) then begin
      activator = 0
    endif else begin
      activator = (*self.state).activator
    endelse

  endwhile

  widget_control, /hourglass

end

;-------------------------------------------------------------------

pro GPItv::changemode, newmode
  ;; Default behavior is to advance one mode . For instance, this is called
  ;; that way by the keyboard event handler to
  ;; Use 'm' keypress to cycle through mouse modes


  if (N_params() eq 0) then newmode =  ((*self.state).mousemode+1) mod (*self.state).mousemode_count

  (*self.state).mousemode  = newmode
  widget_control, (*self.state).mode_droplist_id, set_droplist_select=(*self.state).mousemode

  ;; This does the actual work (used to be in gpitv_event)
  case newmode of
    0: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_none_event'}
    1: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_color_event'}
    2: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_zoom_event'}
    3: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_blink_event'}
    4: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_phot_event'}
    5: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_vector_event'}
    6: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_measure_event'}
    7: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_anguprof_event'}
    8: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_lambprof_event'}
    9: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_region_event'}
    10: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_rowcol_event'}
    11: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_gauss_rowcol_event'}
    12: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_histcont_event'}
    13: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_surf_event'}
    14: widget_control, (*self.state).draw_widget_id, set_uvalue = {object:self, method: 'draw_wavecal_event'}
    else: self->message, msgtype = 'error', 'Unknown mouse mode!'
  endcase

  return

end

;------------------------------------------------------------------

pro GPItv::draw_none_event, event

  ; Event handler for None mode

  @gpitv_err

  ;; if (!d.name NE (*self.state).graphicsdevice) then return

  ;; if (event.type EQ 0) then begin
  ;;     case event.press of
  ;;         else: event.press =  0
  ;;     endcase
  ;; endif

  ;; if (event.type EQ 2) then self->draw_motion_event, event

  ;; widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end


pro GPItv::draw_zoom_event, event

  ; Event handler for zoom mode

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  if (event.type EQ 0) then begin
    case event.press of
      1: self->zoom, 'in', /recenter
      2: self->zoom, 'none', /recenter
      4: self->zoom, 'out', /recenter
      else: event.press =  0
    endcase
  endif

  if (event.type EQ 2) then self->draw_motion_event, event

  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;---------------------------------------------------------------------

pro GPItv::draw_blink_event, event

  ; Event handler for blink mode

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return
  if ((*self.state).bitdepth EQ 24) then true = 1 else true = 0

  case event.type of
    0: begin                    ; button press
      self->setwindow, (*self.state).draw_window_id
      ; define the unblink image if needed
      if (((*self.state).newrefresh EQ 1) AND ((*self.state).blinks EQ 0)) then begin
        *self.images.unblink_image = tvrd(true = true)
        (*self.state).newrefresh = 0
      endif

      case event.press of
        1: if n_elements(*self.images.blink_image1) GT 1 then begin
          tv, *self.images.blink_image1, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).title_blink1
        endif
        2: if n_elements(*self.images.blink_image2) GT 1 then begin
          tv, *self.images.blink_image2, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).title_blink2
        endif
        4: if n_elements(*self.images.blink_image3) GT 1 then begin
          tv, *self.images.blink_image3, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).title_blink3
        endif
        else: event.press = 0 ; in case of errors
      endcase
      (*self.state).blinks = ((*self.state).blinks + event.press) < 7
    end

    1: begin                    ; button release
      if (n_elements(*self.images.unblink_image) EQ 0) then return ; just in case
      self->setwindow, (*self.state).draw_window_id
      (*self.state).blinks = ((*self.state).blinks - event.release) > 0
      case (*self.state).blinks of
        0: begin
          tv, *self.images.unblink_image, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).window_title
        end
        1: if n_elements(*self.images.blink_image1) GT 1 then begin
          tv, *self.images.blink_image1, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).title_blink1
        endif else begin
          tv, *self.images.unblink_image, true = true
        endelse
        2: if n_elements(*self.images.blink_image2) GT 1 then begin
          tv, *self.images.blink_image2, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).title_blink2
        endif else begin
          tv, *self.images.unblink_image, true = true
        endelse
        3: if n_elements(*self.images.blink_image1) GT 1 then begin
          tv, *self.images.blink_image1, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).title_blink1
        endif else if n_elements(*self.images.blink_image2) GT 1 then begin
          tv, *self.images.blink_image2, true = true
        endif else begin
          tv, *self.images.unblink_image, true = true
        endelse
        4: if n_elements(*self.images.blink_image3) GT 1 then begin
          tv, *self.images.blink_image3, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).window_title
        endif else begin
          tv, *self.images.unblink_image, true = true
        endelse
        5: if n_elements(*self.images.blink_image1) GT 1 then begin
          tv, *self.images.blink_image1, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).title_blink1
        endif else if n_elements(*self.images.blink_image3) GT 1 then begin
          tv, *self.images.blink_image3, true = true
        endif else begin
          tv, *self.images.unblink_image, true = true
        endelse
        6: if n_elements(*self.images.blink_image2) GT 1 then begin
          tv, *self.images.blink_image2, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).title_blink2
        endif else if n_elements(blink_image4) GT 1 then begin
          tv, blink_image4, true = true
          widget_control, (*self.state).base_id, $
            tlb_set_title = (*self.state).title_blink3
        endif else begin
          tv, *self.images.unblink_image, true = true
        endelse
        else: begin         ; check for errors
          (*self.state).blinks = 0
          tv, *self.images.unblink_image, true = true
        end
      endcase
    end
    2: self->draw_motion_event, event ; motion event
    else: message,/info, 'Unknown event type received in draw_blink_event; ignoring it.'
  endcase

  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus
  self->resetwindow

end

;-------------------------------------------------------------------

pro GPItv::draw_phot_event, event

  ; Event handler for ImExam mode

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  if (event.type EQ 0) then begin
    case event.press of
      1: self->showstats ;GPItv_apphot
      ; FIXME: why are middle and right clicks different here?
      ;    This is not documented anywhere & needs to be tested...
      2: begin
        (*self.state).stat3dcenter=(*self.state).cursorpos
        (*self.state).stat3dbox=[11,11]

        self->showstats3d
      end
      4: begin
        if (not (xregistered('self->showstats3d', /noshow)) and (*self.state).image_size[2] ge 2) then begin
          ;start new box
          if ((*self.state).s3sel[4] eq 0) then begin
            (*self.state).s3sel[4]=1

            (*self.state).s3sel[0]=(*self.state).coord[0]
            (*self.state).s3sel[1]=(*self.state).coord[1]
          endif else if ((*self.state).s3sel[4] eq 1) then begin
            (*self.state).s3sel[4]=2

            (*self.state).s3sel[2]=(*self.state).coord[0]
            (*self.state).s3sel[3]=(*self.state).coord[1]

            ;calculate box size
            xsize=abs((*self.state).s3sel[2]-(*self.state).s3sel[0])
            ysize=abs((*self.state).s3sel[3]-(*self.state).s3sel[1])

            if ((*self.state).s3sel[1] lt (*self.state).s3sel[3]) then begin
              tmp=(*self.state).s3sel[1]
              (*self.state).s3sel[1]=(*self.state).s3sel[3]
              (*self.state).s3sel[3]=tmp
            endif

            if ((*self.state).s3sel[0] gt (*self.state).s3sel[2]) then begin
              tmp=(*self.state).s3sel[0]
              (*self.state).s3sel[0]=(*self.state).s3sel[2]
              (*self.state).s3sel[2]=tmp
            endif

            ;get draw widget id, draw box
            self->setwindow, (*self.state).draw_window_id
            s=(*self.state).s3sel
            r=[0, 0, s[0], s[1], s[0]+xsize, s[1], s[2], s[3], s[0], s[1]-ysize]
            self->display_box, r

            if (xsize mod 2) eq 0 then xsize=xsize+1
            if (ysize mod 2) eq 0 then ysize=ysize+1

            (*self.state).stat3dbox[0]=xsize
            (*self.state).stat3dbox[1]=ysize

            ;calculate center
            (*self.state).stat3dcenter[0]=round(((*self.state).s3sel[0]+(*self.state).s3sel[2])/2)
            (*self.state).stat3dcenter[1]=round(((*self.state).s3sel[1]+(*self.state).s3sel[3])/2)

            ;launch stat3d
            self->showstats3d

            ;done, reset state
            (*self.state).s3sel[4]=0
          endif
        endif
      end


      else:
    endcase
  endif

  if (event.type EQ 2) then self->draw_motion_event, event

  widget_control, (*self.state).draw_widget_id, /clear_events
  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------


pro GPItv::draw_region_event, event

  ; Event handler for Region mode

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  if (event.type EQ 0) then begin
    case event.press of
      1: self->regionlabel
      2:
      4:
      else:
    endcase
  endif

  if (event.type EQ 2) then self->draw_motion_event, event

  widget_control, (*self.state).draw_widget_id, /clear_events
  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro GPItv::draw_print_event, event
  ;  Print out the pixel coords clicked on.

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  self->setwindow, (*self.state).draw_window_id

  if (event.type EQ 0) then begin
    print,(*self.state).coord[0],(*self.state).coord[1]
  endif

  if (event.type EQ 2) then self->draw_motion_event, event

  widget_control, (*self.state).draw_widget_id, /input_focus

  widget_control, (*self.state).draw_widget_id, /clear_events
  ;widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;--------------------------------------------------------------------

pro GPItv::draw_motion_event, event

  @gpitv_err

  ; Event handler for motion events in draw window

  if (!d.name NE (*self.state).graphicsdevice) then return

  tmp_event = [event.x, event.y]
  (*self.state).coord = $
    round( (0.5 >  ((tmp_event / (*self.state).zoom_factor) + (*self.state).offset) $
    < ((*self.state).image_size[0:1] - 0.5) ) - 0.5)
  self->gettrack
  ;TODO there seem to be subtle errors in this for GPItv??



  ;if GPItv_pixtable on, then create a 5x5 array of pixel values and the
  ;X & Y location strings that are fed to the pixel table

  if (xregistered(self.xname+'_pixtable', /noshow)) then self->pixtable_update

end

;--------------------------------------------------------------------
pro GPItv::draw_anguprof_event, event

  ; Event handler for anguprof mode

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  if (event.type EQ 0) then begin
    case event.press of
      1: self->apphot;GPItv_showstats
      2: self->zoom, 'none', /recenter
      4: self->anguprof
      else:
    endcase
  endif

  if (event.type EQ 2) then self->draw_motion_event, event

  widget_control, (*self.state).draw_widget_id, /clear_events
  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end
;--------------------------------------------------------------------

pro GPItv::draw_lambprof_event, event

  ; Event handler for anguprof mode

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  if (event.type EQ 0) then begin
    case event.press of
      1: self->lambprof
      2: self->zoom, 'none', /recenter
      4:begin
      if ((*self.state).image_size[2] gt 1) then begin
        self->slice3dplot
      endif else begin
        self->message, 'Image must be 3D for pixel slice', $
          msgtype='error', /window
        return
      endelse
    end
    else:
  endcase
endif

if (event.type EQ 2) then self->draw_motion_event, event

widget_control, (*self.state).draw_widget_id, /clear_events
widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end
;--------------------------------------------------------------------
; this is just a simple wrapper:
pro GPItv::draw_measure_event, event

  @gpitv_err
  self->draw_vector_event, event, /measure
end

;--------------------------------------------------------------------
; this is just a simple wrapper:
pro GPItv::draw_wavecal_event, event

  @gpitv_err
  self->draw_vector_event, event, /wavecal
end

;---------------------
function trnlog
  ;Dummy program so that RESOLVE_ALL will work with the ASTRON library
end
;---------------------
pro dellog
  ;Dummy program so that RESOLVE_ALL will work with the ASTRON library
end
;---------------------
pro setlog
  ;Dummy program so that RESOLVE_ALL will work with the ASTRON library
end
;--------------------------------------------------------------------

pro GPItv::draw_vector_event, event, measure=measure, wavecal=wavecal

  ; Check for left button press/depress, then get coords at point 1 and
  ; point 2.  Call GPItv_lineplot.  Calculate vector distance between
  ; endpoints and plot Vector Distance vs. Pixel Value with self->vectorplot
  ;
  ; Measure mode added. M. Perrin

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  ;self->setwindow, (*self.state).draw_window_id

  case event.type of
    0: begin           ; button press
      if (event.press EQ 1) then begin  ; left button press
        (*self.state).vector_coord1[0] = (*self.state).coord[0]
        (*self.state).vector_coord1[1] = (*self.state).coord[1]	; stores X and Y locations in DATA COORDINATE PIXELS
        (*self.state).vectorstart = [event.x, event.y] 	; stores X and Y locations in DISPLAY PIXELS
        self->drawvector, event, measure=measure, wavecal=wavecal
        (*self.state).vectorpress = 1
      endif else if ((event.press EQ 2) or (event.press EQ 4)) and keyword_set(measure) then begin
		; For middle or right click:
        ; Measure from star center location, if present
        ;; if not data cube, bail
        if (n_elements((*self.state).image_size) ne 3) || (((*self.state).image_size)[2] lt 2) then return
        ;;if no satspots in memory, calculate them
        if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
          self->update_sat_spots
          ;;if failed, need to return
		  if ~self.satspots.valid then return
          ;if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then return
        endif
        ;;calculate center locations
        ;  cents = mean(*self.satspots.cens,dim=2) ; not idl 7.0 compatible
        tmp=*self.satspots[*].cens
        cents=fltarr(2)
        for q=0, 1 do cents[q]=mean(tmp[q,*,*])
        (*self.state).vector_coord1[*] = cents

        ;center_coord = $
        ;round( (0.5 >  (([event.x, event.y]/ (*self.state).zoom_factor) + (*self.state).offset) $
        ;< ((*self.state).image_size[0:1] - 0.5) ) - 0.5)
        center_device_coord = (cents -  (*self.state).offset)* (*self.state).zoom_factor
        (*self.state).vectorstart = center_device_coord ; (convert_coord( [cents[0]], [cents[1]], /data, /to_device))[0:1]  	; stores X and Y locations in DISPLAY PIXELS
        self->drawvector, event, measure=measure, wavecal=wavecal
        (*self.state).vectorpress = 1
        ;stop

      endif
    end
    1: begin           ; button release
      if (event.release EQ 1) or (event.release EQ 2) or (event.release EQ 4) then begin  ; left button release
        (*self.state).vectorpress = 0
        (*self.state).vector_coord2[0] = (*self.state).coord[0] ; DATA COORDINATE PIXELS again.
        (*self.state).vector_coord2[1] = (*self.state).coord[1]
        self->drawvector, event, measure=measure, wavecal=wavecal
        ; for regular vector mode, on button release create a vector plot
        ; window.
        if (~(keyword_set(measure)) and ~(keyword_set(wavecal))) then self->vectorplot, /newcoord
      endif
    end
    2: begin  ; motion event
      self->draw_motion_event, event
      if ((*self.state).vectorpress EQ 1) then self->drawvector, event, measure=measure, wavecal=wavecal
    end

    5: self->keyboard_event, event     ; keyboard event
    6: self->keyboard_event, event     ; keyboard event
    else:
  endcase

  ;widget_control, (*self.state).draw_widget_id, /sensitive, /input_focus
  widget_control, (*self.state).draw_widget_id, /clear_events
  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus


end

;----------------------------------------------------------------------

pro GPItv::drawvector, event, measure=measure, wavecal=wavecal

  @gpitv_err

  ; button press: create initial pixmap and start drawing vector
  if (event.type EQ 0) then begin
    window, /free, xsize = (*self.state).draw_window_size[0], $
      ysize = (*self.state).draw_window_size[1], /pixmap
    (*self.state).vector_pixmap_id = !d.window
    device, copy=[0, 0, (*self.state).draw_window_size[0], $
      (*self.state).draw_window_size[1], 0, 0, (*self.state).draw_window_id]
    self->resetwindow
    (*self.state).drawvectorpress=1
  endif

  ; button release: redisplay initial image
  if (event.type EQ 1) then begin
    if (*self.state).drawvectorpress eq 1 then begin
      self->setwindow, (*self.state).draw_window_id
      ;print,  (*self.state).draw_window_id, (*self.state).vector_pixmap_id
      ;device, copy=[0, 0, (*self.state).draw_window_size[0], $
      ;              (*self.state).draw_window_size[1], 0, 0, (*self.state).vector_pixmap_id]

      if keyword_set(measure) then self->labelmeasure,event
      if keyword_set(wavecal) then self->shiftwavecalgrid,event
      self->resetwindow
      wdelete, (*self.state).vector_pixmap_id
      (*self.state).drawvectorpress=0
    endif
  endif

  ; motion event: redraw with new vector
  if (event.type EQ 2) then begin
    self->setwindow, (*self.state).draw_window_id

    device, copy=[0, 0, (*self.state).draw_window_size[0], $
      (*self.state).draw_window_size[1], 0, 0, (*self.state).vector_pixmap_id]
    xvector = [(*self.state).vectorstart[0], event.x]
    yvector = [(*self.state).vectorstart[1], event.y]

    plots, xvector, yvector, /device, color = (*self.state).box_color
    ;print, xvector, yvector
    if keyword_set(measure) then self->labelmeasure,event
    if keyword_set(wavecal) then self->shiftwavecalgrid,event

    self->resetwindow
  endif

end

;----------------------------------------------------------------------

pro GPItv::labelmeasure, event

  @gpitv_err

  ; for mouse button release events, write a permanent version of the
  ; measure vector. For other events, we let drawvector handle drawing the
  ; temporary version of the vector.
  if (event.type EQ 1) then begin
    self->resetwindow ; needed before GPItvplot to not stomp on device.decomposed
    ;print, [(*self.state).vector_coord1[0],(*self.state).coord[0]],[(*self.state).vector_coord1[1],(*self.state).coord[1]]
    self->plot,[(*self.state).vector_coord1[0],(*self.state).coord[0]],[(*self.state).vector_coord1[1],(*self.state).coord[1]],color = (*self.state).box_color
  endif

  self->resetwindow ; needed before GPItvxyouts to not stomp on device.decomposed
  if (*self.state).wcstype eq 'none' then begin
    distance =sqrt( (((*self.state).vector_coord1[0]-(*self.state).coord[0]))^2 $
      +(((*self.state).vector_coord1[1]-(*self.state).coord[1]))^2 )
    self->xyouts,((*self.state).vector_coord1[0]+(*self.state).coord[0])/2+3,((*self.state).vector_coord1[1]+(*self.state).coord[1])/2+3,$
      string(distance,format="(g5.4)")+" pixels",charsize=2
    ;print,"distance is "+string(distance)+" pixels"

  endif else begin


    ;;		distance =sqrt( (((*self.state).vector_coord1[0]-(*self.state).coord[0])* ((*((*self.state).astr_ptr)).cd[0,0]) * (*((*self.state).astr_ptr)).cdelt[0] )^2 $
    ;;		               +(((*self.state).vector_coord1[1]-(*self.state).coord[1])* ((*((*self.state).astr_ptr)).cd[1,1]) * (*((*self.state).astr_ptr)).cdelt[1] )^2 )
    ;;		distance = distance*60*60 ; convert from degrees to arcsec
    ;;		dx = (((*self.state).vector_coord1[0]-(*self.state).coord[0])* ((*((*self.state).astr_ptr)).cd[0,0]) * (*((*self.state).astr_ptr)).cdelt[0] )
    ;;		dy = (((*self.state).vector_coord1[1]-(*self.state).coord[1])* ((*((*self.state).astr_ptr)).cd[1,1]) * (*((*self.state).astr_ptr)).cdelt[1] )
    ;;		pa = !radeg* atan((*self.state).vector_coord1[0]-(*self.state).coord[0],$
    ;;			-((*self.state).vector_coord1[1]-(*self.state).coord[1]))

    pixel_distance =sqrt( (((*self.state).vector_coord1[0]-(*self.state).coord[0]))^2 $
      +(((*self.state).vector_coord1[1]-(*self.state).coord[1]))^2 )

    ; Compute rigorous great circle distance using gcirc etc
    ;  provides correct results for complicated projections.
    xy2ad, (*self.state).vector_coord1[0], (*self.state).vector_coord1[1],*((*self.state).astr_ptr) ,  startra, startdec
    xy2ad, (*self.state).coord[0], (*self.state).coord[1], *((*self.state).astr_ptr) ,  stopra, stopdec
    gcirc, 1, startra/15, startdec, stopra/15, stopdec, distance
    posang, 1, startra/15, startdec, stopra/15, stopdec, pa

    ;; reference PA to north
    ;getrot, *(*self.state).head_ptr, northangle
    ;;print, "raw pa", pa, "north", northangle
    ;pa -= northangle

    if pa lt 0 then pa += 360.0
    if distance lt 100.0 then formatstr = "(g7.4)" else formatstr= "(g6.5)"
    self->xyouts,((*self.state).vector_coord1[0]+(*self.state).coord[0])/2+3,((*self.state).vector_coord1[1]+(*self.state).coord[1])/2+3,$
      "    "+strc(string(pixel_distance, format=('(f8.1)')))+ " pixels!C"+ $
      "    "+sigfig(distance,3)+" arcsec!C       PA="+sigfig(pa,3)+" degr",charsize=2, color='white'
    ;string(distance,format=formatstr)+" arcsec!C   PA="+string(pa,format=formatstr)+" degr",charsize=2
    ;print,"distance is "+string(distance)+" arcseconds"
  endelse
  ; For Motion events, don't save annotation
  if (event.type EQ 2) then self->erase,1,/norefresh


end
;----------------------------------------------------------------------

pro GPItv::shiftwavecalgrid, event

  @gpitv_err

  xdistance = ((*self.state).vector_coord1[0]-(*self.state).coord[0])
  ydistance = ((*self.state).vector_coord1[1]-(*self.state).coord[1])
  ; for mouse button release events, write a permanent version of the
  ; measure vector. For other events, we let drawvector handle drawing the
  ; temporary version of the vector.
  if (event.type EQ 1) then begin
    self->resetwindow ; needed before GPItvplot to not stomp on device.decomposed
    ;print, [(*self.state).vector_coord1[0],(*self.state).coord[0]],[(*self.state).vector_coord1[1],(*self.state).coord[1]]
    self->erase,1,/norefresh
    ;shift wavecal grid

  endif

  self->erase,1
  self->resetwindow ; needed before GPItvxyouts to not stomp on device.decomposed

  self->xyouts,((*self.state).vector_coord1[0]+(*self.state).coord[0])/2+3,((*self.state).vector_coord1[1]+(*self.state).coord[1])/2+3,$
    '( '+sigfig(xdistance,5)+', '+sigfig(ydistance,5)+") pixels",charsize=2

  shiftx = xdistance
  shifty = ydistance

  ;include here the motion of the wavecal grid.
  sxaddpar,  *((*self.state).head_ptr), 'SPOT_DX', shiftx
  sxaddpar,  *((*self.state).head_ptr), 'SPOT_DY', shifty

  self->wavecalgrid, gridcolor=1, tiltcolor=2, labeldisp=0,  labelcolor=7, charsize=1.0, charthick=1


  ; For Motion events, don't save annotation
  if (event.type EQ 2) then self->erase,1,/norefresh




end

;----------------------------------------------------------------------

pro GPItv::draw_base_event, event

  ; event handler for exit events of main draw base.  There's no need to
  ; define enter events, since as soon as the pointer enters the draw
  ; window the motion event will make the text widget sensitive again.
  ; Enter/exit events are often generated incorrectly, anyway.

  @gpitv_err

  if (event.enter EQ 0) then begin
    widget_control, (*self.state).keyboard_text_id, sensitive = 0
  endif

end

;----------------------------------------------------------------------

pro GPItv::pan_event, event

  ; event procedure for moving the box around in the pan window
  ; and refreshing the main view when the user manipulates the position
  ; of the box in the pan window.

  @gpitv_err

  if (!d.name NE (*self.state).graphicsdevice) then return

  case event.type of
    0: begin                     ; button press
      widget_control, (*self.state).pan_widget_id, draw_motion_events = 1
      self->pantrack, event
    end
    1: begin                     ; button release
      widget_control, (*self.state).pan_widget_id, draw_motion_events = 0
      widget_control, (*self.state).pan_widget_id, /clear_events
      self->pantrack, event
      self->refresh
    end
    2: begin
      self->pantrack, event     ; motion event
      widget_control, (*self.state).pan_widget_id, /clear_events
    end
    else:
  endcase

end

;--------------------------------------------------------------------

pro GPItv::draw_linesplot_event, event

  @gpitv_err

  case event.press of

    1: begin
      case (*self.state).linesbox[4] of
        ;1st press, take down first point
        0: begin
          (*self.state).linesbox[0]=(*self.state).coord[0]
          (*self.state).linesbox[1]=(*self.state).coord[1]
          (*self.state).linesbox[4]=1
        end

        ;2nd press, take down second point, reset
        1: begin
          (*self.state).linesbox[2]=(*self.state).coord[0]
          (*self.state).linesbox[3]=(*self.state).coord[1]
          (*self.state).linesbox[4]=0

          ;plot line
          self->setwindow, (*self.state).draw_window_id
          self->display_box, [0., 0., (*self.state).linesbox[0], (*self.state).linesbox[1], $
            (*self.state).linesbox[0], (*self.state).linesbox[1], $
            (*self.state).linesbox[2], (*self.state).linesbox[3], $
            (*self.state).linesbox[0], (*self.state).linesbox[1]]

          ;run plot window
          self->linesplot
        end
      endcase

      if ((*self.state).oplot eq 1) then thick= zoom*0.02
    end
    else: begin
    end
  endcase

  if (event.type EQ 2) then self->draw_motion_event, event

  widget_control, (*self.state).draw_widget_id, /clear_events
  widget_control, (*self.state).keyboard_text_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro GPItv::event, event

  ;; Main event loop for GPItv top-level base, and for all the buttons.

  @gpitv_err

  widget_control, event.id, get_uvalue = uvalue
  if  size(uvalue,/tname) eq 'OBJREF' then uvalue='GPItv_base' ; base resize event

  if (!d.name NE (*self.state).graphicsdevice and uvalue NE 'done') then return

  ;; Get currently active window
  self->getwindow

  case uvalue of

    ;;resize event
    'GPItv_base': begin
      c = where(tag_names(event) EQ 'ENTER', count)
      if (count EQ 0) then begin ; resize event
        self->resize
        self->refresh
      endif
    end

    ;;mouse mode change
    'mode':begin
    self->changemode, event.index
  end

  ;;units change
  'units': begin
    new_requested_units = (*(*self.state).unitslist)[event.index]
    if (strc(new_requested_units) ne '') and (new_requested_units ne (*self.state).current_units) then self->change_image_units, new_requested_units
  end ;;end of units case

  ;; invert the color table
  'invert': begin
    (*self.state).invert_colormap = abs((*self.state).invert_colormap - 1)

    self.colors.r_vector = reverse(self.colors.r_vector)
    self.colors.g_vector = reverse(self.colors.g_vector)
    self.colors.b_vector = reverse(self.colors.b_vector)

    self->setwindow, (*self.state).draw_window_id
    self->stretchct, (*self.state).brightness, (*self.state).contrast
    self->resetwindow

    ;; For 24-bit color, need to refresh display after stretching color
    ;; map.  Can refresh in /fast mode if there are no overplots
    if ((*self.state).bitdepth EQ 24) then begin
      if ptr_valid(self.pdata.plot_ptr[1]) then begin
        self->refresh
      endif else begin
        self->refresh, /fast
      endelse
    endif
  end

  'restretch_button': self->restretch

  'min_text': begin          ; text entry in 'min = ' box
    self->get_minmax, uvalue, event.value
    self->displayall
  end

  'max_text': begin          ; text entry in 'max = ' box
    self->get_minmax, uvalue, event.value
    self->displayall
  end

  ;;collapse mode
  'collapse': begin
    (*self.state).collapse = event.index
    self->collapsecube

    ;;update everything
    self->getstats
    self->set_minmax
    self->displayall
    self->update_child_windows,/update
  end

  'curimnum_text':begin      ; text entry in 'Image #=' box
  self->changeimage, event.value
end

'curimnum_textlamb': begin ; text entry in 'wav(um)=' box
  ; TODO needs to switch behavior depending on STOKES or WAVE mode.
  ; the old code looked at event.value here,
  ; Now we should look at the actual widget value.
  widget_control, event.id, get_value=requestedvalue
  requestedvalue = (float(requestedvalue))[0]
  ;; Check event.value
  ;; If event.value < lmin then image=current image
  ;; If event.value > lmax then image=current image
  ;; Change value in "Image # =" box back to current image when outside limits
  ;; Issue warning popup to enter value between lmin and lmax

  case (*self.state).cube_mode of
    'WAVE': begin
      if (*self.state).CWV_NLam eq 0 then begin
        text_warn = 'No wavelength solution is present in the header for that image; thus cannot select slice based on wavelength!'
        self->message, text_warn, msgtype='error', /window
      endif

      IF (requestedvalue ge (*self.state).CWV_lmin AND  requestedvalue le (*self.state).CWV_lmax) THEN BEGIN
        mindiff = min(abs( *(*self.state).CWV_ptr - requestedvalue), wclosestwave)
        ;Result = VALUE_LOCATE ( *(*self.state).CWV_ptr, requestedvalue)
        ;result = 0> result < ((*self.state).CWV_nlam-1) ; handle the edge cases where
        ; we're within the spectral range of the
        ; channel but outside its central wavelength
        self->changeimage, wclosestwave
      ENDIF ELSE BEGIN
        self->changeimage, (*self.state).cur_image_num,/nocheck
        text_warn = 'Please enter a value between'+strcompress(string((*self.state).cwv_lmin))+' um and ' + $
          strcompress(string((*self.state).cwv_lmax))+ 'um'
        self->message, text_warn, msgtype='error', /window
      ENDELSE
    END
    'STOKES': begin
      self->message, msgtype = 'information', "REQUESTED NEW STOKES SLICE = "+requestedvalue
    end
    else: begin
      self->message, msgtype = 'information',  "Cube mode is unknown, don't know how to select a slice for "+newvalue
    end
  endcase
end

'curimnum_slidebar':begin  ; slidebar controlling cur_image_num
self->changeimage, event.value
end

'curimnum_minmaxmode': case event.index of
2: begin
  (*self.state).curimnum_minmaxmode = 'Min/Max'
  (*self.state).min_value = (*self.state).image_min
  (*self.state).max_value = (*self.state).image_max
  self->set_minmax
  self->displayall
end
1: begin
  (*self.state).curimnum_minmaxmode = 'AutoScale'
  self->autoscale
  self->set_minmax
  self->displayall
end
0: (*self.state).curimnum_minmaxmode = 'Constant'
else: self->message, msgtype = 'error', 'Unknown Min/Max mode for changing cur_image_num!'
endcase

'autoscale_button': self->setscalerange, 'autoscale'
'full_range':  self->setscalerange,'full_range'
'zoom_in':  self->zoom, 'in' ; zoom buttons
'zoom_out': self->zoom, 'out'
'zoom_one': self->zoom, 'one'
'zoomFit': self->autozoom

'center': begin            ; center image and preserve current zoom level
  (*self.state).centerpix = round((*self.state).image_size[0:1] / 2.)
  self->refresh
end

'done':  if ((*self.state).activator EQ 0) then self->shutdown else $
  (*self.state).activator = 0

'Aborted':

else:  self->message, msgtype = 'error', 'No match for uvalue....' ; bad news if this happens

endcase
end

;----------------------------------------------------------------------

pro GPItv::message, msg_txt, msgtype=msgtype, window=window

  ; Routine to display an error or warning message.  Message can be
  ; displayed either to the IDL command line or to a popup window,
  ; depending on whether /window is set.
  ; msgtype must be 'warning', 'error', or 'information'.


  ;;assume messages are information if type is not set
  if not keyword_set(msgtype) then msgtype = 'information'

  if strcmp(msgtype,'information',/fold_case) && (*self.state).noinfo then return
  if strcmp(msgtype,'warning',/fold_case) && (*self.state).nowarn then return

  ;;don't print anything if that message type has been silenced

  if keyword_set(window) then begin  ; print message to popup window
    case strlowcase(msgtype) of
      'warning': t = dialog_message(msg_txt, dialog_parent = (*self.state).base_id)
      'error': t = $
        dialog_message(msg_txt,/error,dialog_parent=(*self.state).base_id)
      'information': t = $
        dialog_message(msg_txt,/information,dialog_parent=(*self.state).base_id)
      else:
    endcase
  endif else begin           ;  print message to IDL console
    message = "GPITV:"+strcompress(strupcase(msgtype) + ': ' + msg_txt)
    print, message
  endelse

end

;-----------------------------------------------------------------------
;      main GPItv routines for scaling, displaying, cursor tracking...
;-----------------------------------------------------------------------

pro GPItv::displayall

  ; Call the routines to scale the image, make the pan image, and
  ; re-display everything.  Use this if the scaling changes (log/
  ; linear/ histeq), or if min or max are changed, or if a new image is
  ; passed to GPItv.  If the display image has just been moved around or
  ; zoomed without a change in scaling, then just call self->refresh
  ; rather than this routine.

  self->scaleimage
  self->makepan
  self->settitle
  self->refresh

end

;---------------------------------------------------------------------

pro GPItv::refresh, fast = fast

  ; Make the display image from the *self.images.scaled_image, and redisplay the pan
  ; image and tracking image.
  ; The /fast option skips the steps where the *self.images.display_image is
  ; recalculated from the *self.images.main_image.  The /fast option is used in 24
  ; bit color mode, when the color map has been stretched but everything
  ; else stays the same.

  self->getwindow
  if (not(keyword_set(fast))) then begin
    self->getoffset
    self->getdisplay
    self->displaymain
    self->plotall
  endif else begin
    self->displaymain
  endelse

  ; redisplay the pan image and plot the boundary box
  self->setwindow, (*self.state).pan_pixmap
  erase
  tv, *self.images.pan_image, (*self.state).pan_offset[0], (*self.state).pan_offset[1]
  self->resetwindow

  self->setwindow, (*self.state).pan_window_id
  if (not(keyword_set(fast))) then erase
  tv, *self.images.pan_image, (*self.state).pan_offset[0], (*self.state).pan_offset[1]
  self->resetwindow

  self->drawpanbox, /norefresh,/compass
  if ((*self.state).bitdepth EQ 24) then self->colorbar

  ; redisplay the tracking image
  if (not(keyword_set(fast))) then self->gettrack

  self->resetwindow

  (*self.state).newrefresh = 1


end

;--------------------------------------------------------------------

pro GPItv::getdisplay

  ; make the display image from the scaled image by applying the zoom
  ; factor and matching to the size of the draw window, and display the
  ; image.


  widget_control, /hourglass
  if (*self.state).rgb_mode then nz=3 else nz=1

  *self.images.display_image = bytarr((*self.state).draw_window_size[0], (*self.state).draw_window_size[1], nz)

  view_min = round((*self.state).centerpix - $
    (0.5 * (*self.state).draw_window_size / (*self.state).zoom_factor))
  view_max = round(view_min + (*self.state).draw_window_size / (*self.state).zoom_factor)

  view_min = (0 > view_min < ((*self.state).image_size[0:1] - 2))
  view_max = (1 > view_max < ((*self.state).image_size[0:1] - 1))

  newsize = round( (view_max - view_min + 1) * (*self.state).zoom_factor) > 1
  startpos = abs( round((*self.state).offset * (*self.state).zoom_factor) < 0)

  ; Use interp & center keywords to congrid for zoomfactor < 1 :
  ; improvement contributed by N. Cunningham, added 4/14/06
  tmp_image = congrid((*self.images.scaled_image)[view_min[0]:view_max[0], $
    view_min[1]:view_max[1], *], $
    newsize[0], newsize[1], nz, center=((*self.state).zoom_factor LT 1.0), interp=((*self.state).zoom_factor LT 1.0))

  if (*self.state).rgb_mode then begin
    ; for some reason IDL congrid AUTOMATICALLY INTERPOLATES for any 3D cube.
    ; So we have to treat each slice separately here to avoid weirdness:
    for i=0,2 do tmp_image[*,*,i] = congrid((*self.images.scaled_image)[view_min[0]:view_max[0], $
      view_min[1]:view_max[1], i], $
      newsize[0], newsize[1], nz, center=((*self.state).zoom_factor LT 1.0), interp=((*self.state).zoom_factor LT 1.0))


    ; color tables are not applied to true-color images.
    ; So we need to explicitly apply the brightness and contrast
    ; settings here to adjust the image display.
    x = (*self.state).brightness*((*self.state).ncolors-1)
    y = (*self.state).contrast*((*self.state).ncolors-1) > 2   ; Minor change by AJB
    high = x+y & low = x-y
    diff = (high-low) > 1

    slope = float((*self.state).ncolors-1)/diff ;Scale to range of 0 : nc-1
    intercept = -slope*low
    p = 0 > long(findgen(255)*slope+intercept)  < 255
    rgb_stretch = indgen((*self.state).ncolors)
    tmp_image0 = tmp_image
    tmp_image = p[tmp_image]
    ; tmp_image normally runs 8-254 (the state.ncolors range)
    ;print,minmax(p)
  endif ;else print, minmax(tmp_image)

  xmax = newsize[0] < ((*self.state).draw_window_size[0] - startpos[0])
  ymax = newsize[1] < ((*self.state).draw_window_size[1] - startpos[1])

  for i=0,nz-1 do (*self.images.display_image)[startpos[0], startpos[1], i] = tmp_image[0:xmax-1, 0:ymax-1, i]
  tmp_image = 0

end

;-----------------------------------------------------------------------

PRO GPItv::display_box, r

  ;Draws a box specified by array r, which contains the coordinates of
  ;the vertices


  pos  = round((*self.state).offset * (*self.state).zoom_factor)
  zoom = (*self.state).zoom_factor
  color= !P.COLOR

  thick = zoom*0.02
  ;if ((*self.state).oplot eq 1) then thick= zoom*0.02

  ;shifts in position
  dx   = -pos[0]
  dy   = -pos[1]

  ;rescaling rectangle
  r = r*zoom

  ;subtract 0.5 as wavesamp assumes 0 is lh corner of pixel and
  ;idl assumes 0 is centre of bottom pixel
  r=r-0.5

  ;plot the rectangle
  PLOTS, [r[2]+dx, r[4]+dx], [r[3]+dy, r[5]+dy], THICK=thick, COLOR=color, /DEVICE
  PLOTS, [r[4]+dx, r[6]+dx], [r[5]+dy, r[7]+dy], THICK=thick, COLOR=color, /DEVICE
  PLOTS, [r[6]+dx, r[8]+dx], [r[7]+dy, r[9]+dy], THICK=thick, COLOR=color, /DEVICE
  PLOTS, [r[8]+dx, r[2]+dx], [r[9]+dy, r[3]+dy], THICK=thick, COLOR=color, /DEVICE

END

;--------------------------------------------------------------------

pro GPItv::displaymain
  ; Display the main image

  self->setwindow, (*self.state).draw_window_id
  tv, *self.images.display_image, true=keyword_set( (*self.state).rgb_mode)*3
  self->resetwindow

end

;--------------------------------------------------------------------

pro GPItv::getoffset

  ; Routine to calculate the display offset for the current value of
  ; (*self.state).centerpix, which is the central pixel in the display window.

  (*self.state).offset = $
    round( (*self.state).centerpix - $
    (0.5 * (*self.state).draw_window_size / (*self.state).zoom_factor) )

end

;----------------------------------------------------------------------

pro GPItv::collapsecube
  ;; Collapse a 3D cube to 2D, somehow (also does calls speckle
  ;; align, unfortunately as this leaves the Cube 3D)

  ;; do nothing if we're only viewing a 2D image
  if (size(*self.images.main_image_stack))[0] eq 2 then return

  ;; default to non-RGB mode
  (*self.state).rgb_mode = 0

  ;; find the image pixels (and how many there are
  pixel_mask = total(finite(*self.images.main_image_stack),3,/NAN)
  wn = where(pixel_mask eq 0, bpct)

  ;; collapse as necessary
  widget_control, (*self.state).collapse_button, get_value=modelist
  ;print, modelist[(*self.state).collapse]
  case modelist[(*self.state).collapse] of
    'Show Cube Slices': begin  ; show slices

      ;;if you were previously klip aligned or high-pass filtered, kill the contrast profile
      if ((*self.state).klip_mode eq 1) || ((*self.state).high_pass_mode eq 1) $
        || ((*self.state).snr_map_mode eq 1) || ((*self.state).low_pass_mode eq 1) then begin
        heap_free,self.satspots.asec
        heap_free,self.satspots.contrprof
        self.satspots.contrprof = ptr_new(/alloc) ;contour profile (will be Z x 3 pointer array with first dimension being stdev,median,mean)
        self.satspots.asec = ptr_new(/alloc)      ;arrays of ang sep vals (will be Z x 1 pointer array)
        *self.satspots.contrprof = ptrarr((*self.state).image_size[2],3,/alloc) ;arrays of radial profile vals
        *self.satspots.asec = ptrarr((*self.state).image_size[2],/alloc)        ;arrays of ang sep vals
      endif

      ;; if you were previously speckle aligned, kliped or
      ;; high-passed, restore the backup cube before doing anything else
      if ((*self.state).specalign_mode eq 1) || ((*self.state).high_pass_mode eq 1) $
        || ((*self.state).klip_mode eq 1) || ((*self.state).stokesdc_im_mode ne 0) $
        || ((*self.state).low_pass_mode eq 1) || ((*self.state).snr_map_mode eq 1)  then begin
        (*self.images.main_image_stack)=(*self.images.main_image_backup)
        (*self.state).specalign_mode = 0
        (*self.state).klip_mode = 0
        (*self.state).high_pass_mode = 0
        (*self.state).low_pass_mode = 0
        (*self.state).snr_map_mode = 0
        (*self.state).stokesdc_im_mode = 0

        ;; restoring has just zeroed out the prior invert and rotation
        ;; transformations, if any. Update state to reflect this and
        ;; then restore the transformations.
        prior_invert_image = (*self.state).invert_image
        prior_rot_angle = (*self.state).rot_angle
        (*self.state).invert_image='none'
        (*self.state).rot_angle=0.0
        if prior_invert_image ne 'none' then  self->invert, prior_invert_image,/nodisplay
        if prior_rot_angle ne 0 then self->rotate, prior_rot_angle
      endif

      widget_control,(*self.state).curimnum_base_id,map=1

      ;; check for invalid cur_image_num and fix if necessary.
      ;; This fixes a bug encountered when switching between datacubes with different
      ;; numbers of slices.
      if (*self.state).cur_image_num gt (size(*self.images.main_image_stack))[3]-1 then begin
        message,/info, 'Trying to display a slice past the end of the image - showing last image slice instead'
        (*self.state).cur_image_num = (size(*self.images.main_image_stack))[3]-1
        self->setcubeslicelabel
      endif

      *self.images.main_image=(*self.images.main_image_stack)[*,*,(*self.state).cur_image_num]
      if (*self.state).has_dq_mask then $
        *self.images.dq_image=(*self.images.dq_image_stack)[*,*,(*self.state).cur_image_num]
    end

    'Collapse by Mean': begin
      ; warn if in SNR mode that incorrect results will occur
      if ((*self.state).snr_map_mode eq 1) then self->message,msgtype='warning',' Collapsing a cube of SNR maps results in untrustworthy results. Users should collapse the cube then create the SNR map.',/window

      widget_control,(*self.state).curimnum_base_id,map=0
      *self.images.main_image=total(*self.images.main_image_stack,3,/NAN) / (pixel_mask>1)
      if bpct gt 0 then (*self.images.main_image)[wn] = !values.f_nan

      ; Still to be implemented:
      ;if (*self.state).has_dq_mask then begin
      ;*self.images.dq_mask = *self.images.main_image_stack[*,*,0
      ; do something here with bitwise_and_collapse_cube, once implemented
      ; endif
    end

    'Collapse by Median': begin
      ; warn if in SNR mode that incorrect results will occur
      if ((*self.state).snr_map_mode eq 1) then self->message,msgtype='warning',' Collapsing a cube of SNR maps results in untrustworthy results. Users should collapse the cube then create the SNR map.',/window

      widget_control,(*self.state).curimnum_base_id,map=0
      *self.images.main_image=median(*self.images.main_image_stack,dim=3)
      if bpct gt 0 then (*self.images.main_image)[wn] = !values.f_nan
    end

    'Collapse by SDI': begin
      ; warn if in SNR mode that incorrect results will occur
      if ((*self.state).snr_map_mode eq 1) then self->message,msgtype='warning',' Collapsing a cube of SNR maps results in untrustworthy results. Users should collapse the cube then create the SNR map.',/window

      widget_control,(*self.state).curimnum_base_id,map=0
      self->sdi
    end

    'Align speckles':begin
    widget_control,(*self.state).curimnum_base_id,map=1
    self->alignspeckle
    *self.images.main_image=(*self.images.main_image_stack)[*,*,(*self.state).cur_image_num]
  end

  'High Pass Filter':begin
  ; image updating now goes on inside the function
  self->high_pass_filter
end

'Low Pass Filter':begin
; image updating now goes on inside the function
self->low_pass_filter
end

'Create SNR Map':begin
; image updating now goes on inside the function
self->create_snr_map
end

'Run KLIP':begin
widget_control,(*self.state).curimnum_base_id,map=1
self->runKLIP
*self.images.main_image=(*self.images.main_image_stack)[*,*,(*self.state).cur_image_num]
end

'Difference of Polarizations': begin
  ;; 2-slice difference for a Polarization Pair
  widget_control,(*self.state).curimnum_base_id,map=0
  *self.images.main_image=(*self.images.main_image_stack)[*,*,1] - (*self.images.main_image_stack)[*,*,0]
  if bpct gt 0 then (*self.images.main_image)[wn] = !values.f_nan
end

'Normalized Difference': begin
  ;; 2-slice difference for a Polarization Pair
  widget_control,(*self.state).curimnum_base_id,map=0
  *self.images.main_image=((*self.images.main_image_stack)[*,*,1] - (*self.images.main_image_stack)[*,*,0])/((*self.images.main_image_stack)[*,*,1] + (*self.images.main_image_stack)[*,*,0])
  if bpct gt 0 then (*self.images.main_image)[wn] = !values.f_nan
end

'Total Intensity': begin
  ;; 2-slice sum for a Polarization Pair
  widget_control,(*self.state).curimnum_base_id,map=0
  *self.images.main_image=(*self.images.main_image_stack)[*,*,1] + (*self.images.main_image_stack)[*,*,0]
  if bpct gt 0 then (*self.images.main_image)[wn] = !values.f_nan
end

'Linear Pol. Intensity': begin
  widget_control,(*self.state).curimnum_base_id,map=0
  *self.images.main_image=sqrt(((*self.images.main_image_stack)[*,*,1])^2 + ((*self.images.main_image_stack)[*,*,2]^2))
  if bpct gt 0 then (*self.images.main_image)[wn] = !values.f_nan
end

'Radial Pol. Intensity': begin
  ; Radial polarized intensity - see Schmid et al. 2006.
  widget_control,(*self.state).curimnum_base_id,map=1
  self->radial_stokes
end


'Divide by Total Intensity': begin
  widget_control,(*self.state).curimnum_base_id,map=1
  ; (*self.images.main_image_stack)[*,*,1] = (*self.images.main_image_stack)[*,*,1]/(*self.images.main_image_stack)[*,*,0]
  ; (*self.images.main_image_stack)[*,*,2] = (*self.images.main_image_stack)[*,*,2]/(*self.images.main_image_stack)[*,*,0]
  ; *self.images.main_image=(*self.images.main_image_stack)[*,*,(*self.state).cur_image_num]
  self->divide_by_stokesi
  if bpct gt 0 then (*self.images.main_image)[wn] = !values.f_nan
end

'Linear Pol. Fraction': begin
  widget_control,(*self.state).curimnum_base_id,map=0
  *self.images.main_image=sqrt(((*self.images.main_image_stack)[*,*,1])^2 + ((*self.images.main_image_stack)[*,*,2])^2) / (*self.images.main_image_stack)[*,*,0]
  if bpct gt 0 then (*self.images.main_image)[wn] = !values.f_nan
end
;'Pol. Fraction Cube': begin
;widget_control,(*self.state).curimnum_base_id,map=0
;*self.images.main_image=sqrt(((*self.images.main_image_stack)[*,*,1])^2 + ((*self.images.main_image_stack)[*,*,2])^2) / (*self.images.main_image_stack)[*,*,0]
;if bpct gt 0 then (*self.images.main_image)[wn] = !values.f_nan
;end

'Total Polarized Intensity': begin
  widget_control,(*self.state).curimnum_base_id,map=0
  *self.images.main_image=sqrt(((*self.images.main_image_stack)[*,*,1])^2 + ((*self.images.main_image_stack)[*,*,2])^2+((*self.images.main_image_stack)[*,*,3])^2  )
  if bpct gt 0 then (*self.images.main_image)[wn] = !values.f_nan
end

'Collapse to RGB Color': begin
  widget_control,(*self.state).curimnum_base_id,map=0
  sz = size(*self.images.main_image_stack)
  *self.images.main_image = fltarr(sz[1], sz[2], 3)
  overlap_len = 0.1
  for i=0,2 do begin
    imin = round( sz[3]* (1./3*i-overlap_len)) > 0
    imax = floor( sz[3]* (0.3333*(i+1)+overlap_len)) < (sz[3]-1)
    (*self.images.main_image)[*,*,2-i] = total((*self.images.main_image_stack)[*,*,imin:imax],3)/ (imax-imin+1)
  endfor

  (*self.state).rgb_mode=1

end

else: begin
  self->message, msgtype = 'error', 'Unknown cube collapse mode!'
  return
end
endcase
end

;----------------------------------------------------------------------


pro GPItv::makepan

  ; Make the 'pan' image that shows a miniature version of the full image.


  sizeratio = (*self.state).image_size[1] / (*self.state).image_size[0]

  if (sizeratio GE 1) then begin
    (*self.state).pan_scale = float((*self.state).pan_window_size) / float((*self.state).image_size[1])
  endif else begin
    (*self.state).pan_scale = float((*self.state).pan_window_size) / float((*self.state).image_size[0])
  endelse

  tmp_image = $
    (*self.images.scaled_image)[0:(*self.state).image_size[0]-1, 0:(*self.state).image_size[1]-1]

  *self.images.pan_image = $
    byte(congrid(tmp_image, round((*self.state).pan_scale * (*self.state).image_size[0])>1, $
    round((*self.state).pan_scale * (*self.state).image_size[1])>1, $
    /center))  ; , /interp) ) ; don't interpolate here, it can cause color table problems given the 4 colors for labels. ; MDP 2008-10-13

  (*self.state).pan_offset[0] = round(((*self.state).pan_window_size - (size(*self.images.pan_image))[1]) / 2)
  (*self.state).pan_offset[1] = round(((*self.state).pan_window_size - (size(*self.images.pan_image))[2]) / 2)

end

;----------------------------------------------------------------------


pro GPItv::move_cursor, direction

  ; Use keypad arrow keys to step cursor one pixel at a time.
  ; Get the new track image, and update the cursor position.


  i = 1L

  case direction of
    '2': (*self.state).coord[1] = max([(*self.state).coord[1] - i, 0])
    '4': (*self.state).coord[0] = max([(*self.state).coord[0] - i, 0])
    '8': (*self.state).coord[1] = min([(*self.state).coord[1] + i, (*self.state).image_size[1] - i])
    '6': (*self.state).coord[0] = min([(*self.state).coord[0] + i, (*self.state).image_size[0] - i])
    '7': begin
      (*self.state).coord[1] = min([(*self.state).coord[1] + i, (*self.state).image_size[1] - i])
      (*self.state).coord[0] = max([(*self.state).coord[0] - i, 0])
    end
    '9': begin
      (*self.state).coord[1] = min([(*self.state).coord[1] + i, (*self.state).image_size[1] - i])
      (*self.state).coord[0] = min([(*self.state).coord[0] + i, (*self.state).image_size[0] - i])
    end
    '3': begin
      (*self.state).coord[1] = max([(*self.state).coord[1] - i, 0])
      (*self.state).coord[0] = min([(*self.state).coord[0] + i, (*self.state).image_size[0] - i])
    end
    '1': begin
      (*self.state).coord[1] = max([(*self.state).coord[1] - i, 0])
      (*self.state).coord[0] = max([(*self.state).coord[0] - i, 0])
    end

  endcase

  newpos = ((*self.state).coord - (*self.state).offset + 0.5) * (*self.state).zoom_factor

  self->setwindow,  (*self.state).draw_window_id
  tvcrs, newpos[0], newpos[1], /device
  self->resetwindow

  self->gettrack

  ; If pixel table widget is open, update pixel values and cursor position
  if (xregistered(self.xname+'_pixtable', /noshow)) then self->pixtable_update

  ; Prevent the cursor move from causing a mouse event in the draw window
  widget_control, (*self.state).draw_widget_id, /clear_events

  self->resetwindow

end

;----------------------------------------------------------------------

pro GPItv::set_minmax

  ; Updates the min and max text boxes with new values.
  ; This is the display scale min and max, not the actual image counts min and max. 

  if (abs((*self.state).min_value) gt 1e6) || (abs((*self.state).min_value) lt 1e-4) then formi='(e10.2)'
  widget_control, (*self.state).min_text_id, set_value = string((*self.state).min_value,format=formi)
  if (abs((*self.state).max_value) gt 1e6) || (abs((*self.state).max_value) lt 1e-4) then forma='(e10.2)'
  widget_control, (*self.state).max_text_id, set_value = string((*self.state).max_value,format=forma)

end

;----------------------------------------------------------------------

pro GPItv::get_minmax, uvalue, newvalue

  ; Change the min and max state variables when user inputs new numbers
  ; in the text boxes.


  case uvalue of

    'min_text': begin
      if (newvalue LT (*self.state).max_value) then begin
        (*self.state).min_value = newvalue
      endif
    end

    'max_text': begin
      if (newvalue GT (*self.state).min_value) then begin
        (*self.state).max_value = newvalue
      endif
    end

  endcase

  self->set_minmax

end

;--------------------------------------------------------------------

pro GPItv::zoom, zchange, recenter = recenter

  ; Routine to do zoom in/out and recentering of image.  The /recenter
  ; option sets the new display center to the current cursor position.


  case zchange of
    'in':    (*self.state).zoom_level = ((*self.state).zoom_level + 1) < 6
    'out':   begin
      sizeratio = fix(min((*self.state).image_size[0:1]) / 16.) > 1
      minzoom = -1.*fix(alog(sizeratio)/alog(2.0))
      (*self.state).zoom_level = ((*self.state).zoom_level - 1) > minzoom
    end
    'onesixteenth': (*self.state).zoom_level =  -4
    'oneeighth': (*self.state).zoom_level =  -3
    'onefourth': (*self.state).zoom_level =  -2
    'onehalf': (*self.state).zoom_level =  -1
    'two':   (*self.state).zoom_level =  1
    'four':  (*self.state).zoom_level =  2
    'eight': (*self.state).zoom_level =  3
    'sixteen': (*self.state).zoom_level = 4
    'one':   (*self.state).zoom_level =  0
    'none':  ; no change to zoom level: recenter on current mouse position
    else:  self->message, msgtype = 'error', 'Unknown zoom command.'
  endcase

  (*self.state).zoom_factor = (2.0)^((*self.state).zoom_level)

  zf = (*self.state).zoom_factor
  zoom_factor_str = (zf lt 1) ? ('1/'+strc(round(1.0/zf))) :  strc(fix(zf))
  ;print, zoom_factor_str

  for menu_zoom_lev=-4,4 do begin
    zf = (2.0)^(menu_zoom_lev)
    zoom_factor_str = (zf lt 1) ? ('1/'+strc(round(1.0/zf))) :  strc(fix(zf))
    w = where((*self.state).menu_labels eq zoom_factor_str)
    if w lt 0 then continue
    button_id = (*self.state).menu_ids[w ]
    widget_control, button_id, set_button = zf eq (*self.state).zoom_factor
    ;print, "|"+zoom_factor_str,  zf eq (*self.state).zoom_factor

  endfor


  if (n_elements(recenter) GT 0) then begin
    (*self.state).centerpix = (*self.state).coord
    self->getoffset
  endif

  self->refresh

  if (n_elements(recenter) GT 0) then begin
    newpos = ((*self.state).coord - (*self.state).offset + 0.5) * (*self.state).zoom_factor
    self->setwindow,  (*self.state).draw_window_id
    tvcrs, newpos[0], newpos[1], /device
    self->resetwindow
    self->gettrack
  endif else self->resetwindow

end

;-----------------------------------------------------------------------

pro GPItv::fullview

  ; set the zoom level so that the full image fits in the display window


  sizeratio = float((*self.state).image_size) / float((*self.state).draw_window_size)
  maxratio = (max(sizeratio))

  (*self.state).zoom_level = floor((alog(maxratio) / alog(2.0)) * (-1))
  (*self.state).zoom_factor = (2.0)^((*self.state).zoom_level)

  ; recenter
  (*self.state).centerpix = round((*self.state).image_size / 2.)

  self->refresh

  self->resetwindow

end


;-----------------------------------------------------
pro GPItv::invert, ichange, nodisplay=nodisplay
  ; Wrapper routine to set up image axis-inversion (X,Y,X&Y)
  ;
  ; Inputs:
  ;  ichange			string, {'x', 'y', 'xy', 'none'}
  ;  					This is absolute, not relative. That is, if you
  ;  					have set invert, 'x' then another invert, 'x' does
  ;  					not toggle the inversion, it leaves it inverted.
  ;
  ; Keyword:
  ;   /nodisplay		Just update the arrays without calling redisplay
  ;					Useful if you are performing multiple transformations in a row.


  (*self.state).invert_image = ichange


  self->refresh_image_invert_rotate

  ; update the menu checkboxes
  self->update_menustate_rotate_invert

  ;Redisplay inverted image with current zoom, update pan, and refresh image
  if ~(keyword_set(nodisplay)) then begin
    self->displayall
    self->update_child_windows,/update
  endif

  self->resetwindow

end
;----------------------------------------------------------

pro gpitv::refresh_image_invert_rotate
  ;+
  ; This is a unified routine to apply image transformations such as rotation and
  ; inversion. These are noncommutative operations and so we have to specify a
  ; specific order of operations, which is hereby defined to be
  ;				INVERT and then ROTATE
  ; Of course either of those could be a null operation.
  ; For simplicity, we always restore from the main image stack at the start of
  ; such a transformation. This is less computationally efficient than
  ; doing only the minimal transformation, but the old "more efficient"
  ; way inherited from atv wasn't an unambiguous repeatable transformation
  ; that could be retained when switching between images in a non-buggy fashion.
  ;-


  ;----------  Setup for rotation and inversion --------
  ;; first, grab the backup image and restore it, along with its
  ;; astrometry header
  *self.images.main_image_stack = *self.images.main_image_backup
  *self.images.main_image = (*self.images.main_image_stack)[*, *, (*self.state).cur_image_num]
  *(*self.state).astr_ptr = *(*self.state).main_image_astr_backup

  has_astr = ptr_valid( (*self.state).astr_ptr )
  if has_astr then begin
    ; which header is the astrometry info from?
    if (*self.state).astr_from eq 'PHDU' then astr_header = *((*self.state).head_ptr) else astr_header = *((*self.state).exthead_ptr)
    ; put the restored backup astrometry into the header
    putast, astr_header, *(*self.state).astr_ptr
  endif

  ;;if there are sat spots in memory, they need to be updated as well
  if self.satspots.valid then update_sats = 1 else update_sats = 0

  ; do we have a 3D cube, in which case we will have to transform each slice?
  szmis=size(*self.images.main_image_stack)
  has_cube = szmis[0] eq 3

  ;----------  inversion  --------

  ; is X flip needed?
  if strpos((*self.state).invert_image, 'x') ge 0 then begin
    self->message, 'inverting in x'
    if has_astr then begin ; transformation with astrometry header updates
      hreverse2, *self.images.main_image,  astr_header , *self.images.main_image,  astr_header , 1, /silent
    endif else begin								; simple transformations without astrometry headers to worry about
      *self.images.main_image = reverse(*self.images.main_image)
    endelse
    ; if datacube, update all planes
    if has_cube  then $
      for i=0,szmis[3]-1 do (*self.images.main_image_stack)[*,*,i] = reverse(reform((*self.images.main_image_stack)[*,*,i],szmis[1],szmis[2]))

    if update_sats then (*self.satspots.cens)[0,*,*] = (*self.state).image_size[0] - (*self.satspots.cens)[0,*,*]
  endif

  ; is Y flip needed?
  if strpos((*self.state).invert_image, 'y') ge 0 then begin
    self->message, 'inverting in y'
    if has_astr then begin ; transformation with astrometry header updates
      hreverse2, *self.images.main_image,  astr_header , *self.images.main_image,  astr_header , 2, /silent
    endif else begin								; simple transformations without astrometry headers to worry about
      *self.images.main_image = reverse(*self.images.main_image, 2)
    endelse
    ; if datacube, update all planes
    if has_cube then $
      for i=0,szmis[3]-1 do (*self.images.main_image_stack)[*,*,i] = reverse(reform((*self.images.main_image_stack)[*,*,i],szmis[1],szmis[2]), 2)

    if update_sats then (*self.satspots.cens)[1,*,*] = (*self.state).image_size[1] - (*self.satspots.cens)[1,*,*]
  endif


  ;----------  rotation  --------

  ; Do we have to rotate?
  if (*self.state).rot_angle ne 0 then begin
    desired_angle = (*self.state).rot_angle  ; for back compatibility with prior implementation

    ;; Are we rotating by some multiple of 90 degrees? If so, we can do so
    ;; exactly.
    if (desired_angle/90. eq fix(desired_angle/90)) then begin

      desired_angle = desired_angle mod 360
      if desired_angle lt 0 then desired_angle +=360
      rchange = strc(fix(desired_angle)) ; how much do we need to change the image to get the new rotation?
      self->message, 'Rotating exactly to '+rchange

      case rchange of
        '0':  rot_dir=0           ;; do nothing
        '90': rot_dir=1
        '180': rot_dir=2
        '270': rot_dir=3
      endcase

      if has_astr then begin
        ;; do rotation with astrometry update
        ;;
        ;; If a cube is present, have to modify it to ignore wavelength axis or hrotate will crash
        if szmis[0] eq 3 then begin
          sxaddpar, astr_header, 'NAXIS', 2
          sxdelpar, astr_header, 'NAXIS3'
        endif

        hrotate, *self.images.main_image, astr_header, newim, new_astr_header, rot_dir
        astr_header = new_astr_header

        if szmis[0] eq 3 then begin
          sxaddpar, astr_header, 'NAXIS', 3
          sxaddpar, astr_header, 'NAXIS3', szmis[3]
        endif

        *self.images.main_image = newim
      endif else begin
        ;; no astrometry, just do the rotate
        *self.images.main_image = rotate(*self.images.main_image, rot_dir)
      endelse

      szmis=size(*self.images.main_image_stack)
      ;; if a datacube, rotate all the slices
      if has_cube then $
        for i=0,szmis[3]-1 do (*self.images.main_image_stack)[*,*,i] = rotate(reform((*self.images.main_image_stack)[*,*,i],szmis[1],szmis[2]), rot_dir)

    endif else begin
      ;; arbitrary rotation angle, requires interpolating rotation.
      ;;
      ;; Algorithm note: This is an inherently lossy process. We use cubic
      ;; interpolation where possible, nearest neighbor elsewhere (i.e. at the
      ;; edges of the array where cubic fails). This is a hack but this is just for rough
      ;; quick and dirty display work.
      ;;
      ;; Luckily in this new implementation we're always starting fresh
      ;; from a restored main_image_backup, possibly with some lossless
      ;; inversion step applied afterwards. So that's fine.

      self->Message, 'Rotating with interpolation to '+strc(desired_angle)

      if has_astr then begin
        ;; do rotation with astrometry update

        ;; WARNING: hrot2 expects angles **clockwise**, in contradiction of the
        ;; convention adopted by hrotate (and most astronomers) Aaaaargh. -MDP
        ;;
        ;; Perform one rotation with interpolation (for more accuracy) and
        ;; one with nearest neighbor (to get sharp edges of the valid region)
        hrot2, *self.images.main_image, astr_header, nearest , new_astr_header, (-1)*desired_angle, $
          -1, -1, 2,  interp=0,  missing=!values.f_nan

        hrot2, *self.images.main_image, astr_header, interpolated, discarded_new_astr_header, (-1)*desired_angle,$
          -1, -1, 2,  cubic=-0.5, missing=!values.f_nan

        astr_header = new_astr_header
        wnan = where(~finite(interpolated), nanct)
        if nanct gt 0 then interpolated[wnan] = nearest[wnan]
        *self.images.main_image = interpolated
      endif else begin
        ;; no astrometry, just do the rotate
        interpolated = rot(*self.images.main_image, desired_angle,  cubic=-0.5, missing=!values.f_nan)
        nearest = rot(*self.images.main_image, desired_angle,  interp =0,  missing=!values.f_nan)
        wnan = where(~finite(interpolated), nanct)
        if nanct gt 0 then interpolated[wnan] = nearest[wnan]
        *self.images.main_image = interpolated
      endelse

      ;; if a datacube, rotate all the slices
      if has_cube then for i=0,szmis[3]-1 do begin
        interpolated = rot(reform((*self.images.main_image_stack)[*,*,i],szmis[1],szmis[2]), (-1)*desired_angle,  cubic=-0.5, missing=!values.f_nan)
        nearest = rot(reform((*self.images.main_image_stack)[*,*,i],szmis[1],szmis[2]), (-1)*desired_angle, interp=0,  missing=!values.f_nan)
        wnan = where(~finite(interpolated), nanct)
        if nanct gt 0 then interpolated[wnan] = nearest[wnan]
        (*self.images.main_image_stack)[*,*,i] = interpolated
      endfor

    endelse


    ;;if there are sat spots in memory, they need to be updated as well
    if (n_elements(*self.satspots.cens) eq 8L * (*self.state).image_size[2]) then begin
      rotang = desired_angle*!dpi/180d0
      rotMat = [[cos(rotang),sin(rotang)],$
        [-sin(rotang),cos(rotang)]]
      c0 = (*self.state).image_size[0:1]/2 # (dblarr(4) + 1d0)
      for j = 0,(*self.state).image_size[2]-1 do (*self.satspots.cens)[*,*,j] = (rotMat # ((*self.satspots.cens)[*,*,j] - c0))+c0

    endif

  endif else self->message, "Rotating to 0 (no rotation)" ; end of rotation section

  ;--------- finish up the transformation and clean up --------------

  ; if we've transformed an astrometry header, store it back as appropriate.
  if keyword_set(astr_header) then begin
    if (*self.state).astr_from eq 'PHDU' then begin
      ; stick modified header back into the PHDU slot.
      *((*self.state).head_ptr) = astr_header
    endif else begin
      ; stick modified header back into the extension HDU slot
      *((*self.state).exthead_ptr) = astr_header
    endelse
    ; update astr_ptr for GPItv
    extast, astr_header, (*(*self.state).astr_ptr), noparams
  endif


  ;;if a collapse mode was previously applied, reapply it
  widget_control, (*self.state).collapse_button, get_value=modelist
  if  modelist[(*self.state).collapse] ne 'Show Cube Slices' then self->collapsecube



end


;----------------------------------------------------------


pro gpitv::update_menustate_rotate_invert

  ; update the menu checkboxes for rotation and inversion


  ichanges = ['none', 'x','y','xy']
  names = ['No Inversion', 'Invert X', 'Invert Y', 'Invert X && Y']
  for i=0L,n_elements(names)-1 do begin
    w = where((*self.state).menu_labels eq names[i])
    if w lt 0 then continue
    button_id = (*self.state).menu_ids[w ]
    widget_control, button_id, set_button = ichanges[i] eq ((*self.state).invert_image )
  endfor

  ; update menu checkboxes for rotation
  names = ['Rotate 0 deg', 'Rotate 90 deg', 'Rotate 180 deg', 'Rotate 270 deg', 'Rotate GPI field square']
  angles = [0,90, 180, 270, 24.5]
  for i=0L,n_elements(names)-1 do begin
    w = where((*self.state).menu_labels eq names[i])
    if w lt 0 then continue
    button_id = (*self.state).menu_ids[w ]
    widget_control, button_id, set_button = (abs( (*self.state).rot_angle - angles[i]) lt 1)
  endfor

end

;----------------------------------------------------------

pro GPItv::rotate, desired_angle, get_angle=get_angle, nodisplay=nodisplay
  ;+
  ; Routine to do image rotation
  ;
  ; This both rotates the displayed image AND updates the WCS header in memory
  ; to reflect the rotation.
  ;
  ; Rotation code reworked by MP to provide absolute rotations such that you can
  ; undo the rotation if you want by setting it back to 0.
  ;
  ;
  ; If /get_angle set, create widget to enter rotation angle
  ;
  ; INPUTS:
  ;	desired_angle		Desired rotation counterclockwise, from the unrotated
  ;						image's starting orientation (i.e. this is absolute
  ;						not relative rotation.)
  ;
  ;	/get_angle			Open a dialog box and ask the user what angle to rotate
  ;	/nodisplay			Don't refresh all displays after rotating. This is
  ;						useful if ::rotate is called in the middle of a series
  ;						of chained transformations, so you only update the
  ;						displays once at the end.
  ;
  ;-


  if (keyword_set(get_angle)) then begin

    formdesc = [ '0, LABEL, Enter Desired Rotation, CENTER', $
      '0, float,'+strtrim((*self.state).rot_angle,2)+', label_left=Rotation Angle: ', $
      '0, LABEL, Rotations are in degrees measured counterclockwise, LEFT', $
      '0, LABEL, in the image after any axes inversions are applied., LEFT', $
      '0, LABEL, Enter here the absolute rather than relative angle desired., LEFT', $
      '1, base, , row', $
      '0, button, Cancel, quit', $
      '0, button, Rotate, quit']

    textform = cw_form(formdesc, /column, title = 'Rotate')

    if (textform.tag6 EQ 1) then return ; cancel button
    if (textform.tag7 EQ 1) then desired_angle = float(textform.tag1)

  endif

  (*self.state).rot_angle  = desired_angle

  widget_control, /hourglass

  self->refresh_image_invert_rotate ; Do the actual rotation

  ; update the menu checkboxes
  self->update_menustate_rotate_invert

  ;Redisplay the rotated image with current zoom, update pan, and refresh image
  if ~(keyword_set(nodisplay)) then begin
    self->displayall
    self->update_child_windows,/update
  endif

  self->resetwindow

end

;------------------------------------------------------------------

pro GPItv::change_image_units, new_requested_units, silent=silent, loading_new_image=loading_new_image
  ; Update the currently displayed image to a new choice of display unit.
  ; This involves rescaling the actual pixel values of the main image stack,
  ; and applying the same transformation to the min/max display scaling.
  ;
  ; Parameters:
  ;  /silent		      don't display text output
  ;  /loading_new_image   needed to support retain_image_stretch and not adjust minmax - see issue #349 for motivation

  if n_elements(new_requested_units) eq 0 then return

  if ~(keyword_set(silent)) then $
    self->Message, "Unit conversion requested from "+(*self.state).current_units +" to "+new_requested_units,$
    msgtype = 'information'

  ;;ALL DISPLAY WILL BE PER COADD
  notGPIunits=0

  ;;can put in some better logic here to account for what nim
  ;;should be
  ;;for now, just base it on the 3rd image dim
  ;nim = n_elements(*(*self.state).CWV_ptr)
  if n_elements((*self.state).image_size) eq 3 then nim = ((*self.state).image_size)[2] else nim = 1

  if ((*self.state).current_units eq 'Contrast') and new_requested_units eq (*self.state).intrinsic_units then begin
    conversion_factor = 1./((1./(*self.state).gridfac)*mean((*self.satspots.satflux)[*, (*self.state).cur_image_num ]))
    (*self.state).max_value /= conversion_factor
    (*self.state).min_value /= conversion_factor
  endif
  if ((*self.state).current_units eq 'Contrast') and new_requested_units ne (*self.state).intrinsic_units then begin
    self->message,[ $
      'Not sure how to convert from "'+(*self.state).current_units+'" to "'+new_requested_units+'". Not supported yet!',$
      'Please convert from "'+(*self.state).current_units+'" to "'+(*self.state).intrinsic_units] ;,/window
    ;Ignoring Retain Current Stretch.',/window
    return
  endif
  if (new_requested_units eq 'Contrast') and (*self.state).current_units ne (*self.state).intrinsic_units then begin
    self->message,[ $
      'Not sure how to convert from "'+(*self.state).current_units+'" to "'+new_requested_units+'". Not supported yet!',$
      'Please convert from "'+(*self.state).intrinsic_units+'" to "'+new_requested_units] ;,/window
    ;Ignoring Retain Current Stretch.',/window
    return
  endif

  ;;if you're going from contrast, restore intrinsic units
  if ((*self.state).current_units eq 'Contrast') then begin
    *self.images.main_image_stack = *self.images.main_image_backup
    (*self.state).current_units = (*self.state).intrinsic_units

  endif


  ;;no need to do anything if requested is same as current
  if (*self.state).current_units ne new_requested_units then begin

    ;;treat contrast differently from others
    if new_requested_units eq 'Contrast' then begin

      proceed = 1
      ;;to avoid confusion, we only do this starting from cube slices
      if ((*self.state).collapse ne 0)  then begin
        self->message,msgtype='warning',/window, $
          'Change to contrast units not supported for a collapsed datacube (but you can collapse after changing the units first).'
        proceed = 0
      endif

      ;;only support WAVE cubes (shouldn't be able to get here
      ;;otherwise, but we'll check anyway)
      if ~strcmp((*self.state).cube_mode, 'WAVE') then begin
        self->message, msgtype='warning', /window, 'Contrast calculation currently only supported for spectral cubes.'
        proceed = 0
      endif

      ;;if gridfac is nan, bail out
      if ~finite((*self.state).gridfac) then begin
        self->message,msgtype='error', /window, $
          'The sat spot flux ratio is currently NaN, indicating that the apodizer for this image could not be matched.  To calculate the contrast, please enter the proper value in the contrast profile window.'
        proceed = 0
      endif

      ;;if no sat spots exist in memory (or are the wrong size), get the sat spot
      ;;locations and fluxes
      if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) && proceed then begin
        self->update_sat_spots,locs0=locs0
        ;;if failed, bail
        if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
          proceed = 0
        endif
      endif

      ;;get the contrast cube
      if proceed then begin ; apply transformation
        copsf = (*self.images.main_image_stack)
        ;;scale by sat spot mean
        for j = 0, (size(copsf,/dim))[2]-1 do $
          copsf[*,*,j] = copsf[*,*,j]/((1./(*self.state).gridfac)*mean((*self.satspots.satflux)[*,j]))
        *self.images.main_image_stack = copsf


        conversion_factor = 1./((1./(*self.state).gridfac)*mean((*self.satspots.satflux)[*, (*self.state).cur_image_num ]))
		if ~ (keyword_set(loading_new_image) and  (*self.state).retain_current_stretch) then begin
          (*self.state).max_value *= conversion_factor
          (*self.state).min_value *= conversion_factor
		endif

      endif else begin ; reset to prior requested units
        ind = where(STRCMP(  *(*self.state).unitslist,(*self.state).current_units))
        widget_control, (*self.state).units_droplist_id, set_droplist_select = ind, set_value=*(*self.state).unitslist
        return
	endelse

    endif else begin
	  ; All units other than contrast are handled here:

      ;; special cases: the easy conversions between ADU <-> ADU/s
      ;; that don't require any flux calibration knowledge
      if (*self.state).current_units eq 'ADU per coadd' and new_requested_units eq 'ADU/s' then begin
        conversion_factor = 1./(*self.state).itime
      endif else if (*self.state).current_units eq 'ADU/s' and new_requested_units eq 'ADU per coadd' then begin
        conversion_factor  = (*self.state).itime
      endif else begin
        ;; here, we deal with the nontrivial conversions that require flux calibration
        self->message,['Nontrivial units conversions not yet fully implemented... ', $
          'Not sure how to convert from "'+(*self.state).current_units+'" to "'+new_requested_units+'". Not supported yet!'] ,/window, msgtype='error'
        ;Ignoring Retain Current Stretch.',/window
        return

        ;;first, scale from current units to 'ph/s/nm/m^2'
        case (*self.state).current_units of
          'ADU per coadd':begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]*=double(((*self.state).flux_calib_convfac)[i])/((*self.state).itime)
            endfor
          end
          'ADU/s':begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]*=double(((*self.state).flux_calib_convfac)[i])
            endfor
          end
          'ph/s/nm/m^2':begin
          end
          'Jy':begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]/=(1e3*((*(*self.state).CWV_ptr)[i])/1.509e7)
            endfor
          end
          'W/m^2/um':begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]/=(1.988e-13/(1e3*((*(*self.state).CWV_ptr)[i])))
            endfor
          end
          'ergs/s/cm^2/A':begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]/=(1.988e-14/(1e3*((*(*self.state).CWV_ptr)[i])))
            endfor
          end
          'ergs/s/cm^2/Hz':begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]/=((1e3*((*(*self.state).CWV_ptr)[i]))/1.509e30)
            endfor
          end
          else:  begin
            UnsupportedUnits=1
          end
        endcase


        if keyword_set(unsupportedUnits) then begin
          self->message, 'The requested unit is not supported for conversions. Cannot rescale the image',/window, msgtype='error'
          return
        endif else begin

          ;;then scale to new units
          ;;from ph/s/nm/m^2 syst. to syst chosen
          case new_requested_units of
            'ADU per coadd': begin
              for i=0,nim-1 do begin
                (*self.images.main_image_stack)[*,*,i]/=(double(((*self.state).flux_calib_convfac)[i])/((*self.state).itime))
              endfor
            end
            'ADU/s':begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]/=double(((*self.state).flux_calib_convfac)[i])
            endfor
          end
          'ph/s/nm/m^2': begin
          end
          'Jy':  begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]*=(1e3*((*(*self.state).CWV_ptr)[i])/1.509e7)
            endfor
          end
          'W/m^2/um':  begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]*=(1.988e-13/(1e3*((*(*self.state).CWV_ptr)[i])))
            endfor
          end
          'ergs/s/cm^2/A':  begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]*=(1.988e-14/(1e3*((*(*self.state).CWV_ptr)[i])))
            endfor
          end
          'ergs/s/cm^2/Hz':  begin
            for i=0,nim-1 do begin
              (*self.images.main_image_stack)[*,*,i]*=((1e3*((*(*self.state).CWV_ptr)[i]))/1.509e30)
            endfor
          end
        endcase
      endelse ; else case from if keyword_set(unsupportedUnits)
    endelse ; else case of nontrivial flux conversions

    ;;do the actual conversion here
    *self.images.main_image *= conversion_factor
    *self.images.main_image_stack *= conversion_factor
    if ~ (keyword_set(loading_new_image) and  (*self.state).retain_current_stretch) then begin
    	(*self.state).max_value *= conversion_factor
    	(*self.state).min_value *= conversion_factor
    endif 
endelse ;;else case from if new_requested_units eq 'Contrast'

(*self.state).current_units= new_requested_units
endif ;;if new = current units

if (*self.state).CWV_NLam gt 0 then $
  *self.images.main_image = (*self.images.main_image_stack)[*, *, (*self.state).cur_image_num]

; update current unit displayed in the droplist
ind = where(STRCMP(  *(*self.state).unitslist,(*self.state).current_units))
widget_control, (*self.state).units_droplist_id, set_droplist_select = ind, set_value=*(*self.state).unitslist

self->getstats       ; updates image min/max stats displayed on screen
;self->autoscale
self->set_minmax
self->displayall
self->update_child_windows,/update
self->resetwindow

end

;------------------------------------------------------------------

pro GPItv::getimage

  ; Retrieve DSS, 2MASS, or IRAS image from STSCI/ESO/IRSA archives and
  ; load into GPItv.


  formdesc = ['0, text, , label_left=Object Name: , width=15', $
    '0, label, OR, CENTER', $
    '0, text, , label_left=RA (Deg J2000): , width=15', $
    '0, text, , label_left=DEC (Deg J2000): , width=15', $
    '0, float, 10.0, label_left=Imsize (Arcminutes): ', $
    '0, droplist, DSS-STSCI|DSS-ESO|2MASS-IRSA|IRAS-IRSA, label_left=Archive:, set_value=0 ', $
    '0, droplist, 1st Generation|2nd Generation Blue|2nd Generation Red|2nd Generation Near-IR|J|H|K_s|12um|25um|60um|100um, label_left=Band:, set_value=0 ', $
    '0, button, SIMBAD|NED, set_value=0, exclusive', $
    '1, base, , row', $
    '0, button, Cancel, quit', $
    '0, button, Retrieve, quit']

  archiveform = cw_form(formdesc, /column, title = 'Get Archive Image')

  if (archiveform.tag9 eq 1) then return

  if (archiveform.tag10 eq 1) then begin

    ; First do error checking so that archive and band match

    if (strcompress(archiveform.tag0,/remove_all) eq '' AND $
      strcompress(archiveform.tag2,/remove_all) eq '' AND $
      strcompress(archiveform.tag3,/remove_all) eq '') then begin
      self->message,'Enter Target or Coordinates', msgtype='error', /window
      return
    endif

    if (archiveform.tag5 eq 0 OR $
      archiveform.tag5 eq 1 AND $
      archiveform.tag6 ne 0 AND $
      archiveform.tag6 ne 1 AND $
      archiveform.tag6 ne 2 AND $
      archiveform.tag6 ne 3) then begin
      self->message,'Select Appropriate Band for DSS', msgtype='error',/window
      return
    endif

    if (archiveform.tag5 eq 2 AND $
      archiveform.tag6 ne 4 AND $
      archiveform.tag6 ne 5 AND $
      archiveform.tag6 ne 6)then begin
      self->message,'Select Appropriate Band for 2MASS', msgtype='error',/window
      return
    endif

    if (archiveform.tag5 eq 3 AND $
      archiveform.tag6 ne 7 AND $
      archiveform.tag6 ne 8 AND $
      archiveform.tag6 ne 9 AND $
      archiveform.tag6 ne 10) then begin
      self->message,'Select Appropriate Band for IRAS', msgtype='error',/window
      return
    endif

    if (archiveform.tag4 lt 0.0) then begin
      self->message, 'Image Size must be > 0', msgtype='error', /window
      return
    endif

    ; Set image size defaults.  For IRAS ISSA images, imsize must be 0.5,
    ; 1.0, 2.5, 5.0, or 12.5

    if (strcompress(archiveform.tag4, /remove_all) ne '') then $
      imsize = float(strcompress(archiveform.tag4, /remove_all)) $
    else $
      imsize = 10.0

    if (archiveform.tag5 eq 3) then begin
      if (strcompress(archiveform.tag4, /remove_all) ne '') then begin
        imsize = float(strcompress(archiveform.tag4, /remove_all))
        imsize = imsize / 60.
        diff_halfdeg = abs(0.5 - imsize)
        diff_deg = abs(1.0 - imsize)
        diff_2halfdeg = abs(2.5 - imsize)
        diff_5deg = abs(5.0 - imsize)
        diff_12halfdeg = abs(12.5 - imsize)

        diff_arr = [diff_halfdeg, diff_deg, diff_2halfdeg, diff_5deg, $
          diff_12halfdeg]

        imsize_iras = [0.5, 1.0, 2.5, 5.0, 12.5]
        index_min = where(diff_arr eq min(diff_arr))
        imsize = imsize_iras[index_min]
      endif else begin
        imsize = 1.0
      endelse
    endif

    if (archiveform.tag5 eq 0 OR archiveform.tag5 eq 1) then begin
      if (archiveform.tag4 gt 60.0) then begin
        self->message, 'DSS Image Size must be <= 60.0 Arcminutes', $
          msgtype='error', /window
        return
      endif
    endif

    widget_control, /hourglass
    image_str = ''

    if (strcompress(archiveform.tag0, /remove_all) ne '') then $
      image_str=strcompress(archiveform.tag0, /remove_all)

    if (strcompress(archiveform.tag2, /remove_all) ne '') then $
      ra_tmp=double(strcompress(archiveform.tag2, /remove_all))

    if (strcompress(archiveform.tag3, /remove_all) ne '') then $
      dec_tmp=double(strcompress(archiveform.tag3, /remove_all))

    if (strcompress(archiveform.tag0, /remove_all) ne '') then $
      target=image_str $
    else $
      target=[ra_tmp,dec_tmp]

    case archiveform.tag6 of

      0: band='1'
      1: band='2b'
      2: band='2r'
      3: band='2i'
      4: band='j'
      5: band='h'
      6: band='k'
      7: band='12'
      8: band='25'
      9: band='60'
      10: band='100'
    endcase

    case archiveform.tag5 of

      0: begin
        if (archiveform.tag7 eq 0) then $
          querydss, target, tmpim, hdr, imsize=imsize, survey=band, /stsci $
        else $
          querydss, target, tmpim, hdr, imsize=imsize, survey=band, /stsci, /ned
      end

      1: begin
        if (archiveform.tag7 eq 0) then $
          querydss, target, tmpim, hdr, imsize=imsize, survey=band, /eso $
        else $
          querydss, target, tmpim, hdr, imsize=imsize, survey=band, /eso, /ned
      end

      ;  2: begin
      ;    if (archiveform.tag7 eq 0) then $
      ;      query2mass, target, tmpim, hdr, imsize=imsize, band=band $
      ;    else $
      ;      query2mass, target, tmpim, hdr, imsize=imsize, band=band, /ned
      ;  end
      ;
      ;  3: begin
      ;    if (archiveform.tag7 eq 0) then $
      ;      queryiras, target, tmpim, hdr, imsize=imsize, band=band $
      ;    else $
      ;      queryiras, target, tmpim, hdr, imsize=imsize, band=band, /ned
      ;  end
    endcase

    GPItv,tmpim,head=hdr
  endif


  ;Reset image rotation angle to 0 and inversion to none
  (*self.state).rot_angle = 0.
  (*self.state).invert_image = 'none'

  ;Make pan image and set image to current zoom/stretch levels
  self->makepan
  self->refresh

  ;make sure that the image arrays are updated for line/column plots, etc.
  self->resetwindow

end

;------------------------------------------------------------------

pro GPItv::pixtable

  ; Create a table widget that will show a 5x5 array of pixel values
  ; around the current cursor position


  if (not(xregistered(self.xname+'_pixtable'))) then begin


    (*self.state).pixtable_base_id = $
      widget_base(/base_align_right, $
      group_leader = (*self.state).base_id, $
      /column, $
      title = 'GPItv pixel table')

    (*self.state).pixtable_tbl_id = widget_table((*self.state).pixtable_base_id,   $
      value=[0,0], xsize=5, ysize=5, row_labels='', $
      column_labels='', alignment=2, /resizeable_columns)

    pixtable_done = widget_button((*self.state).pixtable_base_id, $
      value = 'Done', $
      uvalue = 'pixtable_done')

    widget_control, (*self.state).pixtable_base_id, /realize
    xmanager, self.xname+'_pixtable', (*self.state).pixtable_base_id, /no_block
    widget_control, (*self.state).pixtable_base_id, set_uvalue={object: self, method: 'pixtable_event'}
    widget_control, (*self.state).pixtable_base_id,event_pro = 'GPItvo_subwindow_event_handler'

  endif

end

;---------------------------------------------------------------------

pro GPItv::pixtable_event, event


  widget_control, event.id, get_uvalue = uvalue

  case uvalue of
    'pixtable_done': widget_control, event.top, /destroy
    else:
  endcase

end

;--------------------------------------------------------------------

pro GPItv::pixtable_update


  zcenter = (0 > (*self.state).coord < (*self.state).image_size[0:1])

  ;Check and adjust the zcenter if the cursor is near the edges of the image

  if (zcenter[0] le 2) then zcenter[0] = 2
  if (zcenter[0] gt ((*self.state).image_size[0]-3)) then $
    zcenter[0] =  (*self.state).image_size[0] - 3

  if (zcenter[1] le 2) then zcenter[1] = 2
  if (zcenter[1] gt ((*self.state).image_size[1]-3)) then $
    zcenter[1] = (*self.state).image_size[1] - 3

  pix_values = dblarr(5,5)
  row_labels = strarr(5)
  column_labels = strarr(5)
  boxsize=2

  xmin = 0 > (zcenter[0] - boxsize)
  xmax = (zcenter[0] + boxsize) < ((*self.state).image_size[0] - 1)
  ymin = 0 > (zcenter[1] - boxsize)
  ymax = (zcenter[1] + boxsize) < ((*self.state).image_size[1] - 1)

  row_labels = [strcompress(string(ymax),/remove_all),   $
    strcompress(string(ymin+3),/remove_all), $
    strcompress(string(ymin+2),/remove_all), $
    strcompress(string(ymin+1),/remove_all), $
    strcompress(string(ymin),/remove_all)]

  column_labels = [strcompress(string(xmin),/remove_all),   $
    strcompress(string(xmin+1),/remove_all), $
    strcompress(string(xmin+2),/remove_all), $
    strcompress(string(xmin+3),/remove_all), $
    strcompress(string(xmax),/remove_all)]

  pix_values = (*self.images.main_image)[xmin:xmax, ymin:ymax]
  pix_values = reverse(pix_values, 2, /overwrite)

  widget_control, (*self.state).pixtable_tbl_id, set_value = pix_values, $
    column_labels=column_labels, row_labels=row_labels

end

;--------------------------------------------------------------------

pro GPItv::changeimage,imagenum,next=next,previous=previous, nocheck=nocheck,$
  nochildupdate=nochildupdate


  ; do nothing if we only have one image.
  if (*self.state).image_size[2] lt 2 then return

  ; do nothing if the cube is collapsed somehow
  if ((*self.state).collapse ne 0) && ((*self.state).specalign_mode ne 1)$
    && ((*self.state).high_pass_mode ne 1)  && ((*self.state).low_pass_mode ne 1) $
    && ((*self.state).klip_mode ne 1) && ((*self.state).stokesdc_im_mode eq 0) $
    && ((*self.state).snr_map_mode ne 1) then return


  ; if we've got a 3d image stack this lets us move between
  ; images of the stack. Check to make sure we don't exit the boundaries
  if keyword_set(next) then imagenum =  ((*self.state).cur_image_num +1) < ((*self.state).image_size[2]-1)
  if keyword_set(previous) then imagenum =  ((*self.state).cur_image_num -1) > 0

  ; don't do anything if the image number doesn't change.
  if (imagenum eq (*self.state).cur_image_num) and ~(keyword_set(nocheck)) then return

  ; check imagenum is withing bounds
  if (imagenum lt 0) or (imagenum gt ((*self.state).image_size[2]-1)) then begin
    ;(*self.state).cur_image_num = (*self.state).cur_image_num
    widget_control, (*self.state).curimnum_text_id, $
      set_value = string((*self.state).cur_image_num)
    text_warn = 'Please enter a value between 0 and ' + $
      strcompress(string((*self.state).image_size[2] -1))
    self->message, text_warn, msgtype='error', /window
    return
  endif

  ; Switch to the new image!
  (*self.state).cur_image_num = imagenum
  self->setcubeslicelabel

  if n_elements(image_names) gt 1 then begin
    ; a stack of multiple images loaded as a cube
    (*self.state).title_extras = image_names[(*self.state).cur_image_num]
  endif else begin
    ; one image loaded with a datacube.
    indpos=strpos((*self.state).title_extras,' Slice:' )
    if indpos ne -1 then (*self.state).title_extras=strmid((*self.state).title_extras,0,indpos)
    (*self.state).title_extras = (*self.state).title_extras+$
      strcompress(' Slice: ' + string((*self.state).cur_image_num))
  endelse

  self->settitle

  *self.images.main_image = (*self.images.main_image_stack)[*, *, (*self.state).cur_image_num]

  ; If we have a valid DQ extension stack, then we should update the
  ; DQ current image with the appropriate slice.

  if (*self.state).has_dq_mask then if (size(*self.images.dq_image_stack))[0] eq 3 then  $
    *self.images.dq_image = (*self.images.dq_image_stack)[*, *, (*self.state).cur_image_num<((size(*self.images.dq_image_stack))[3]-1)]

  self->getstats
  case (*self.state).curimnum_minmaxmode of
    'Min/Max': begin
      (*self.state).min_value = (*self.state).image_min
      (*self.state).max_value = (*self.state).image_max
    end
    'AutoScale': self->autoscale
    'Constant': donothingvariable = 0
    else: self->message, msgtype = 'error', 'Unknown Min/Max mode for changing cur_image_num!'
  endcase
  self->set_minmax
  self->displayall

  ;;when called from setup_new_image, no need to do this, as it'll be
  ;;called again at the end of that routine.
  if not keyword_set(nochildupdate) then $
    self->update_child_windows,/noheader,/update ; update plots but no need to refresh header window

end

;--------------------------------------------------------------------

pro GPItv::setcubeslicelabel
  ; If displaying a datacube, label the current slice properly

  ;; do nothing if we only have one image.
  if (*self.state).image_size[2] lt 2 then return

  ;; do nothing if the cube is collapsed somehow
  if  ((*self.state).collapse ne 0) && ((*self.state).specalign_mode ne 1) $
    && ((*self.state).high_pass_mode ne 1) && ((*self.state).klip_mode ne 1) $
    && ((*self.state).low_pass_mode ne 1) && ((*self.state).stokesdc_im_mode eq 0) $
    && ((*self.state).snr_map_mode ne 1) then return

  case (*self.state).cube_mode of
    'WAVE': begin
      if (*self.state).CWV_NLam gt 0 then begin
        currwav=(*(*self.state).CWV_ptr)[(*self.state).cur_image_num]
      endif else begin
        currwav=0
      endelse
      currlabel = strc(currwav,format='(f10.3)')
    end
    'STOKES': begin
      ; For specification of Stokes WCS axis, see
      ; Greisen & Calabretta 2002 A&A 395, 1061, section 5.4
      modelabels = ["YX", "XY", "YY", "XX", "LR", "RL", "LL", "RR", "INVALID", "I", "Q", "U", "V", "P"]
      crval3 = sxpar(*(*self.state).exthead_ptr,"CRVAL3")
      crpix3 = sxpar(*(*self.state).exthead_ptr,"CRPIX3")
      stokesindex = (*self.state).cur_image_num-crpix3+crval3
      currlabel = modelabels[stokesindex+8]
    end
	'KLMODES': begin
        ; for GPI we have the KL mode info in the ext header
        if (*self.state).exthead_ptr NE !NULL then begin
		    label = sxpar(*(*self.state).exthead_ptr,"KLMODE"+strc((*self.state).cur_image_num), ct)
        ; but other data could have it in the pri header
        endif else begin
		    label = sxpar(*(*self.state).head_ptr,"KLMODE"+strc((*self.state).cur_image_num), ct)
        endelse
		currlabel = "n="+strc(label)
	end
    else:begin
    currlabel="Unknown"
  end
endcase

widget_control, (*self.state).curimnum_textlamb_id,  set_value = currlabel
widget_control, (*self.state).curimnum_text_id,  set_value = string((*self.state).cur_image_num )
widget_control, (*self.state).curimnum_slidebar_id,  set_value = (*self.state).cur_image_num

end

;--------------------------------------------------------------------

pro GPItv::autoscale

  ; Routine to auto-scale the image.


  widget_control, /hourglass

  if (n_elements(*self.images.main_image) LT 5.e5) then begin
    med = median((*self.images.main_image),/DOUBLE)
    sz=size((*self.images.main_image))
    sig = stddev((double((*self.images.main_image)))[sz[1]/2-sz[1]/5:sz[1]/2+sz[1]/5,sz[2]/2-sz[2]/5:sz[2]/2+sz[2]/5],/NAN) ;limit area of stddev to remove edge effects occuring when flat-fielding
  endif else begin   ; resample big images before taking median, to save memory
    boxsize = 10
    rx = (*self.state).image_size[0] mod boxsize
    ry = (*self.state).image_size[1] mod boxsize
    nx = (*self.state).image_size[0] - rx
    ny = (*self.state).image_size[1] - ry
    tmp_img = rebin((*self.images.main_image)[0: nx-1, 0: ny-1], $
      nx/boxsize, ny/boxsize, /sample)
    med = median(tmp_img)
    sig = stddev(temporary(tmp_img),/NaN)
  endelse

  nhigh = 10
  nlow = 2

  (*self.state).max_value = (med + (nhigh * sig)) < (*self.state).image_max
  (*self.state).min_value = (med - (nlow * sig))  > (*self.state).image_min

  if (finite((*self.state).min_value) EQ 0) then (*self.state).min_value = (*self.state).image_min
  if (finite((*self.state).max_value) EQ 0) then (*self.state).max_value = (*self.state).image_max

  if ((*self.state).min_value GE (*self.state).max_value) then begin
    (*self.state).min_value = (*self.state).min_value - 1
    (*self.state).max_value = (*self.state).max_value + 1
  endif

  self->set_minmax

end

;--------------------------------------------------------------------
pro GPItv::autozoom
  ; Routine to auto-zoom the image to fit in the current draw window.
  ;  'fit' is defined as having the image be the largest possible zoom setting
  ;  such that the full image fits within the draw window.
  ;
  ;   2011-07-29 MP: Algorithm reworked to work more reliably.
  ;   2013-07-12 ds: Replaced iterative algorithm with direct
  ;                  calculation of zoom factor

  ;; always center the image when autozooming.
  (*self.state).centerpix = round((*self.state).image_size[0:1] / 2.)

  ;;figure out ratio of image to window
  imsize = ((*self.state).image_size)[0:1]
  wsize =  (*self.state).draw_window_size
  rat = float(wsize)/float(imsize)
  ;;take log_2 of ratio:
  fac = min(alog10(rat)/alog10(2d)) ;grab the minimum dimension change

  ;;if factor is within 15% of the next highest integer, allow a
  ;;little clipping
  if abs(ceil(fac)-fac) lt 0.15 then fac = ceil(fac) else fac = floor(fac)
  if fac gt 4 then fac = 4
  if fac lt -4 then fac = -4

  case fac of
    -4: self->zoom,'onesixteenth'
    -3: self->zoom,'oneeighth'
    -2: self->zoom,'onefourth'
    -1: self->zoom,'onehalf'
    0: self->zoom,'one'
    1: self->zoom,'two'
    2: self->zoom,'four'
    3: self->zoom,'eight'
    4: self->zoom,'sizteen'
  endcase

end

;--------------------------------------------------------------------

pro gpitv::autohandedness, nodisplay=nodisplay
  ;+
  ; Check image parity from the WCS header
  ; If the image is right-handed, flip the X dimension so that it becomes
  ; left handed. (i.e. East is counterclockwise of North)
  ;
  ; Keyword:
  ;   /nodisplay		Just update the arrays without calling redisplay
  ;					Useful if you are performing multiple transformations in a row.


  ;-


  if (not ptr_valid( (*self.state).exthead_ptr)) or (*self.state).wcstype eq 'none' then begin
    self->message, 'No valid WCS present; cannot set image handedness',msgtype='error', /window
    return
  endif

  extast, *(*self.state).exthead_ptr, astr

  if ~(keyword_set(astr)) then begin
    self->message, ["Image does not have valid WCS astrometry header", "Cannot determine handedness. Skipping autohandedness!"], msgtype='warning',/window
    return
  endif

  getrot, astr, npa, cdelt, /silent
  ; from getrot docs:
  ; 		CDELT[1] is always positive, whereas
  ;    	CDELT[0] is negative for a normal left-handed coordinate
  ; 		system, and positive for a right-handed system.

  if cdelt[0] gt 0 then begin
    self->message, 'Inverting X axis to get desired image handedness.'
    self->invert, 'x',/nodisplay
  endif

end


;--------------------------------------------------------------------

pro GPItv::restretch

  ; Routine to restretch the min and max to preserve the display
  ; visually but use the full color map linearly.  Written by DF, and
  ; tweaked and debugged by AJB.  It doesn't always work exactly the way
  ; you expect (especially in log-scaling mode), but mostly it works fine.


  sx = (*self.state).brightness
  sy = (*self.state).contrast

  case strlowcase((*self.state).scaling) of
    'square root': begin
      sfac = ((*self.state).max_value-(*self.state).min_value)
      (*self.state).max_value = sfac*(sx+sy)+(*self.state).min_value
      (*self.state).min_value = sfac*(sx-sy)+(*self.state).min_value
    end
    'histeq': begin
      sfac = ((*self.state).max_value-(*self.state).min_value)
      (*self.state).max_value = sfac*(sx+sy)+(*self.state).min_value
      (*self.state).min_value = sfac*(sx-sy)+(*self.state).min_value
    end
    'linear': begin
      sfac = ((*self.state).max_value-(*self.state).min_value)
      (*self.state).max_value = sfac*(sx+sy)+(*self.state).min_value
      (*self.state).min_value = sfac*(sx-sy)+(*self.state).min_value
    end
    'log': begin
      offset = (*self.state).min_value - $
        ((*self.state).max_value - (*self.state).min_value) * 0.01

      sfac = alog10(((*self.state).max_value - offset) / ((*self.state).min_value - offset))
      (*self.state).max_value = 10.^(sfac*(sx+sy)+alog10((*self.state).min_value - offset)) $
        + offset
      (*self.state).min_value = 10.^(sfac*(sx-sy)+alog10((*self.state).min_value - offset)) $
        + offset

    end
    'asinh': begin
      ;; Try different behavior in asinh mode: usually want to keep the min
      ;; value the same and just adjust the max value.  Seems to work ok.
      sfac = asinh((*self.state).max_value / (*self.state).asinh_beta) - $
        asinh((*self.state).min_value / (*self.state).asinh_beta)

      (*self.state).max_value = $
        sinh(sfac*(sx+sy) + asinh((*self.state).min_value/(*self.state).asinh_beta))*(*self.state).asinh_beta
    end
    else: begin
      self->message,msgtype='error','Unknown scaling mode.'
      return
    end
  endcase

  ;; do this differently for 8 or 24 bit color, to prevent flashing
  self->setwindow, (*self.state).draw_window_id
  if ((*self.state).bitdepth EQ 8) then begin
    self->set_minmax
    self->displayall
    (*self.state).brightness = 0.5 ; reset these
    (*self.state).contrast = 0.5
    self->stretchct, (*self.state).brightness, (*self.state).contrast
  endif else begin
    (*self.state).brightness = 0.5 ; reset these
    (*self.state).contrast = 0.5
    self->stretchct, (*self.state).brightness, (*self.state).contrast
    self->set_minmax
    self->displayall
  endelse
  self->resetwindow

end

;;---------------------------------------------------------------------

function GPItv::wcsstring, lon, lat, ctype, equinox, disp_type, disp_equinox, $
  disp_base60

  ; Routine to return a string which displays cursor coordinates.
  ; Allows choice of various coordinate systems.
  ; Contributed by D. Finkbeiner, April 2000.
  ; 29 Sep 2000 - added degree (RA,dec) option DPF
  ; Apr 2007: AJB added additional error checking to prevent crashes

  ; ctype - coord system in header
  ; disp_type - type of coords to display


  headtype = strmid(ctype[0], 0, 4)

  ; need numerical equinox values
  IF (equinox EQ 'J2000') THEN num_equinox = 2000.0 ELSE $
    IF (equinox EQ 'B1950') THEN num_equinox = 1950.0 ELSE $
    num_equinox = float(equinox)

  IF (disp_equinox EQ 'J2000') THEN num_disp_equinox = 2000.0 ELSE $
    IF (disp_equinox EQ 'B1950') THEN num_disp_equinox = 1950.0 ELSE $
    num_disp_equinox = float(equinox)

  ; first convert lon,lat to RA,dec (J2000)
  CASE headtype OF
    'GLON': euler, lon, lat, ra, dec, 2 ; J2000
    'ELON': BEGIN
      euler, lon, lat, ra, dec, 4 ; J2000
      IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END
    'RA--': BEGIN
      ra = lon
      dec = lat
      IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END
    'DEC-': BEGIN       ; for SDSS images
      ra = lon
      dec = lat
      IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END
    else: begin
      wcsstring = '---No WCS Info---'
      widget_control, (*self.state).wcs_bar_id, set_value = wcsstring
      (*self.state).wcstype = 'none'
      return, wcsstring
    end
  ENDCASE

  ; Now convert RA,dec (J2000) to desired display coordinates:

  IF (disp_type[0] EQ 'RA--' or disp_type[0] EQ 'DEC-') THEN BEGIN
    ; generate (RA,dec) string
    disp_ra  = ra
    disp_dec = dec
    IF num_disp_equinox NE 2000.0 THEN precess, disp_ra, disp_dec, $
      2000.0, num_disp_equinox

    IF disp_base60 THEN BEGIN ; (hh:mm:ss) format

      neg_dec  = disp_dec LT 0
      radec, disp_ra, abs(disp_dec), ihr, imin, xsec, ideg, imn, xsc
      wcsstring = string(ihr, imin, xsec, ideg, imn, xsc, disp_equinox, $
        format = '(i2.2,":",i2.2,":",f6.3,"   ",i2.2,":",i2.2,":",f5.2," ",a6)' )
      if (strmid(wcsstring, 6, 1) EQ ' ') then $
        strput, wcsstring, '0', 6
      if (strmid(wcsstring, 21, 1) EQ ' ') then $
        strput, wcsstring, '0', 21
      IF neg_dec THEN strput, wcsstring, '-', 14

    ENDIF ELSE BEGIN ; decimal degree format

      wcsstring = string(disp_ra, disp_dec, disp_equinox, $
        format='("Deg ",F9.5,",",F9.5,a6)')
    ENDELSE
  ENDIF


  IF disp_type[0] EQ 'GLON' THEN BEGIN ; generate (l,b) string
    euler, ra, dec, l, b, 1

    wcsstring = string(l, b, format='("Galactic (",F9.5,",",F9.5,")")')
  ENDIF

  IF disp_type[0] EQ 'ELON' THEN BEGIN ; generate (l,b) string

    disp_ra = ra
    disp_dec = dec
    IF num_disp_equinox NE 2000.0 THEN precess, disp_ra, disp_dec, $
      2000.0, num_disp_equinox
    euler, disp_ra, disp_dec, lam, bet, 3

    wcsstring = string(lam, bet, format='("Ecliptic (",F9.5,",",F9.5,")")')
  ENDIF

  return, wcsstring
END

;----------------------------------------------------------------------

function GPItv::wavestring

  ; function to return string with wavelength info for spectral images.
  ; Currently works for HST STIS 2-d images.


  cd = float(sxpar(*(*self.state).head_ptr,'CD1_1', /silent))
  crpix = float(sxpar(*(*self.state).head_ptr,'CRPIX1', /silent))
  crval = float(sxpar(*(*self.state).head_ptr,'CRVAL1', /silent))
  shifta = float(sxpar(*(*self.state).head_ptr, 'SHIFTA1', /silent))

  wavelength = crval + (((*self.state).coord[0] - crpix) * cd) + (shifta * cd)
  wstring = string(wavelength, format='(F8.2)')

  wavestring = strcompress('Wavelength:  ' + wstring + ' ' + (*self.state).cunit)

  return, wavestring

end

;--------------------------------------------------------------------


pro GPItv::gettrack


  ; Create the image to display in the track window that tracks
  ; cursor movements.  Also update the coordinate display and the
  ; (x,y) and pixel value.
  if ~(keyword_set(*self.images.scaled_image)) then return ; avoid a weird and infrequent error case?

  ; Get x and y for center of track window

  zcenter = (0 > (*self.state).coord < (*self.state).image_size)

  boxsize=10; 5
  track = bytarr(boxsize*2+1,boxsize*2+1)
  xmin = 0 > (zcenter[0] - boxsize)
  xmax = (zcenter[0] + boxsize) < ((*self.state).image_size[0] - 1)
  ymin = 0 > (zcenter[1] - boxsize)
  ymax = (zcenter[1] + boxsize) < ((*self.state).image_size[1] - 1)

  startx = abs( (zcenter[0] - boxsize) < 0 )
  starty = abs( (zcenter[1] - boxsize) < 0 )

  track[startx,starty] = (*self.images.scaled_image)[xmin:xmax,ymin:ymax]
  ;track_image = rebin(track, $
  ;(*self.state).track_window_size, (*self.state).track_window_size, $
  ;/sample)
  track_image = cmcongrid(track, $
    (*self.state).track_window_size, (*self.state).track_window_size,$
    /half_half)

  self->setwindow, (*self.state).track_window_id
  tv, track_image

  ; Overplot an X on the central pixel in the track window, to show the
  ; current mouse position

  ; Changed central x to be green always
  pmin = boxsize/(boxsize*2.+1)
  pmax = (boxsize+1)/(boxsize*2.+1)
  ;plots, [0.46, 0.54], [0.46, 0.54], /normal, color = (*self.state).box_color, psym=0
  ;plots, [0.46, 0.54], [0.54, 0.46], /normal, color = (*self.state).box_color, psym=0
  plots, [pmin,pmax], [pmin,pmax], /normal, color = (*self.state).box_color, psym=0
  plots, [pmin,pmax], [pmax,pmin], /normal, color = (*self.state).box_color, psym=0

  ; update location bar with x, y, and pixel value
  ;
  ;loc_string = $
  ;  string((*self.state).coord[0], $
  ;         (*self.state).coord[1], $
  ;         (*self.images.main_image)[(*self.state).coord[0], $
  ;                    (*self.state).coord[1]], $
  ;          format = '("Pix. Pos(x,y)/Mag: ", "(",i5,",",i5,") ",g14.7)')

  loc_string = $
    string((*self.state).coord[0], $
    (*self.state).coord[1], $
    format = '("(", i4,",",i4,") ")' )

  widget_control, (*self.state).location_bar_id, set_value = loc_string; , xsize=300

  widget_control, (*self.state).value_bar_id, $
    set_value = strc(string((*self.images.main_image)[(*self.state).coord[0],(*self.state).coord[1]], format='(g14.5)'))
  ;val = string((*self.images.main_image)[(*self.state).coord[0],(*self.state).coord[1]], format='(g14.5)')
  ;print, "|"+val+"|"
  ;print, (*self.images.main_image)[(*self.state).coord[0],(*self.state).coord[1]]
  ;widget_control, (*self.state).value_bar_id, set_value="TEST12345"


  ; Update coordinate display.
  if ((*self.state).wcstype EQ 'angle') then begin
    xy2ad, (*self.state).coord[0], (*self.state).coord[1], *((*self.state).astr_ptr), lon, lat

    wcsstring = self->wcsstring(lon, lat, (*(*self.state).astr_ptr).ctype,  $
      (*self.state).equinox, (*self.state).display_coord_sys, $
      (*self.state).display_equinox, (*self.state).display_base60)

    widget_control, (*self.state).wcs_bar_id, set_value = wcsstring, xsize=300

  endif

  if ((*self.state).wcstype EQ 'lambda') then begin
    wavestring = self->wavestring()
    widget_control, (*self.state).wcs_bar_id, set_value = wavestring, xsize=100
  endif

  self->resetwindow

end


;----------------------------------------------------------------------

pro GPItv::drawpanbox, norefresh=norefresh, compass=compass

  ; routine to draw the box on the pan window, given the current center
  ; of the display image.
  ;
  ; Will attempt to draw a compass too, if /compass is set.


  self->setwindow, (*self.state).pan_window_id

  view_min = round((*self.state).centerpix - $
    (0.5 * (*self.state).draw_window_size / (*self.state).zoom_factor))
  view_max = round(view_min + (*self.state).draw_window_size / (*self.state).zoom_factor) - 1

  ; Create the vectors which contain the box coordinates

  box_x = float((([view_min[0], $
    view_max[0], $
    view_max[0], $
    view_min[0], $
    view_min[0]]) * (*self.state).pan_scale) + (*self.state).pan_offset[0])

  box_y = float((([view_min[1], $
    view_min[1], $
    view_max[1], $
    view_max[1], $
    view_min[1]]) * (*self.state).pan_scale) + (*self.state).pan_offset[1])

  ; Redraw the pan image and overplot the box
  if (not(keyword_set(norefresh))) then $
    device, copy=[0,0,(*self.state).pan_window_size, (*self.state).pan_window_size, 0, 0, $
    (*self.state).pan_pixmap]

  plots, box_x, box_y, /device, color = (*self.state).box_color, psym=0

  if keyword_set(compass) and ptr_valid( (*self.state).exthead_ptr) and (*self.state).wcstype ne 'none' then begin
    catch, astrometry_error
    if astrometry_error eq 0 then begin

      ;;getrot spews obnoxious warnings so just shut it up temporarily
      quiet = !quiet
      !quiet = 1

      arrows, *((*self.state).exthead_ptr),  $
        (*self.state).pan_window_size/2, (*self.state).pan_window_size/2, $
        arrowlen=2,thick=1, color=fsc_color('yellow'), charsize=0.9

      !quiet = quiet

    endif
    ;; else the file probably just doesn't have astrometry info, so ignore the
    ;; error and proceed silently.
  endif


  self->resetwindow

end

;----------------------------------------------------------------------

pro GPItv::pantrack, event

  ; routine to recenter main view position when the user clicks or click-drags
  ; in the the pan window. The actual window refresh doesn't happen here, that
  ; happens upstream in ::pan_event.

  ; get the new box coords and calculate where the user just clicked in the main
  ; image. Make that the new center of the view.
  tmp_event = [event.x, event.y]

  newpos = (*self.state).pan_offset > tmp_event < $
    ((*self.state).pan_offset + ((*self.state).image_size[0:1] * (*self.state).pan_scale))

  (*self.state).centerpix = round( (newpos - (*self.state).pan_offset ) / (*self.state).pan_scale)

  self->drawpanbox  ; Update the box drawn in the pan window.
  self->getoffset	  ; Update the display offset based on new centerpix.


end

;----------------------------------------------------------------------

pro GPItv::resize

  ; Routine to resize the draw window when a top-level resize event
  ; occurs.  Completely overhauled by AB for v1.4.
  ;
  ; 2008-10-20   Code updated slightly for GPITV by MDP
  ; 2013-04-26   Fix resizing bug on Mac OS by MDP
  ;print, 'GPItv resizing'


  widget_control, (*self.state).base_id, tlb_get_size=tmp_event

  window = ((*self.state).base_min_size > tmp_event)

  newbase = window - (*self.state).base_pad

  (*self.state).base_pad[0] = 1

  newxsize = (tmp_event[0] - (*self.state).base_pad[0]) > $
    ((*self.state).base_min_size[0])  > 100
  newysize = (tmp_event[1] - (*self.state).base_pad[1]) > $
    ((*self.state).base_min_size[1] - (*self.state).base_pad[1]) > 100
  ; Note: the ATV code assumes that the color bar and viewer window should be the
  ; same size. This is no longer the case for GPItv.
  ; Some crazy stupid stuff is going on here!
  geo = widget_info((*self.state).base_id,/geom)
  geo2 = widget_info((*self.state).draw_base_id,/geom)

  ;;not extremly sure why (maybe due to the margin: IDL help say: the actual width of any widget is:
  ;;SCR_XSIZE + (2* MARGIN) ) but the size of the window increase everytime a new image is displayed

  case !version.os_family of
    'Windows': offset=6 ;could be platform dependent, works on Windows platform
    'unix': offset=0	; yes it is version dependent, don't want an offset on Mac
  endcase

  newxsize2 = (tmp_event[0]>(*self.state).base_min_size[0]) - geo.xpad*2-geo2.xpad*2-geo.margin*2-geo2.margin*2-offset

  widget_control, (*self.state).draw_widget_id, $
    scr_xsize = newxsize2, scr_ysize = newysize
  (*self.state).draw_window_size = [newxsize2, newysize]

  ; now resize the header area
  geo_1 = widget_info( (*self.state).info_head_id,/geom)
  geo_2 = widget_info( (*self.state).wcs_bar_id,/geom)
  geo_3 = widget_info( (*self.state).colorbar_base_id,/geom)
  maxx = max([geo_1.xsize, geo_2.xsize, geo_3.xsize])
  widget_control, (*self.state).info_head_id, xsize=maxx
  widget_control, (*self.state).wcs_bar_id, xsize=maxx
  widget_control, (*self.state).colorbar_base_id, xsize=maxx

  ; some final cleanup tasks
  self->colorbar

  widget_control, (*self.state).base_id, /clear_events


end

;----------------------------------------------------------------------
PRO GPItv::setscaling,scaling,nodisplay=nodisplay


  (*self.state).scaling = scaling

  ;; make sure the right menu item is checked
  for i=0L,n_elements((*self.state).scalings)-1 do begin
    button_id = (*self.state).menu_ids[ where((*self.state).menu_labels eq (*self.state).scalings[i])  ]
    widget_control, button_id, set_button = strcmp((*self.state).scalings[i],scaling,/fold_case)
  endfor

  if not keyword_set(nodisplay) then self->displayall

end

;-----------------------------------------------------------------------------------

PRO GPItv::setscalerange,rangename


  case strlowcase(rangename) of

    'autoscale':begin
    self->autoscale
  end
  'full_range': begin
    (*self.state).min_value = (*self.state).image_min
    (*self.state).max_value = (*self.state).image_max
    if (*self.state).min_value GE (*self.state).max_value then begin
      (*self.state).min_value = (*self.state).max_value - 1
      (*self.state).max_value = (*self.state).max_value + 1
    endif
    self->set_minmax
  end
  'zero_to_max': begin
    (*self.state).min_value = 0
    (*self.state).max_value = (*self.state).image_max
    if (*self.state).min_value GE (*self.state).max_value then begin
      (*self.state).min_value = (*self.state).max_value - 1
      (*self.state).max_value = (*self.state).max_value + 1
    endif
    self->set_minmax
  end
  else:  self->message,msgtype='error',"Unknown/incorrect scale range name: "+rangename
endcase


self->displayall

end

;----------------------------------------------------------------------

pro GPItv::scaleimage,imin=imin,imout=imout, use_full_255=use_full_255

  ; Create a byte-scaled copy of the image, scaled according to
  ; the (*self.state).scaling parameter.  Add a padding of 5 pixels around the
  ; image boundary, so that the tracking window can always remain
  ; centered on an image pixel even if that pixel is at the edge of the
  ; image.
  ;
  ; We add 8 to the value returned from bytscl to get above the 8 primary
  ; colors which are used for overplots and annotations. We use a mask to
  ; only do this for non NAN pixels, so all NANs will always remain black,
  ; no matter what color the bottom of the color map is.
  ;
  ; *if you want to disable the above functionality and use the full
  ; range of 0-255 for the scaling, set the /use_full_range flag. This
  ; can be useful in some contexts, such as when saving images or movies *
  ;
  ; Sometimes, we'll want to apply scaling to an image other than
  ; the main_image (like when we're exporting to an animation
  ; writer, etc.).  In these cases, the imin/imout keywords allow the
  ; calculation to be applied to the image in imin, rather than
  ; overwriting main_image, and returned via imout.
  ;


  ; Since this can take some time for a big image, set the cursor
  ; to an hourglass until control returns to the event loop.

  widget_control, /hourglass

  if keyword_set(use_full_255) then begin
    top_value=255
    nan_offset=1
  endif else begin
    top_value=(*self.state).ncolors - 1
    nan_offset=8
  endelse


  ;;if no image was passed in, we'll be using the main_image and
  ;;overwriting the scaled_image
  if not keyword_set(imin) then begin
    *self.images.scaled_image=0.
    im = *self.images.main_image
  endif else im = imin

  ; ignore floating underflow in this routine
  except = !except
  !except=0

  nan_mask = im eq im             ; mask out NAN pixels
  case strlowcase((*self.state).scaling) of
    ;; linear stretch
    'linear': imout = bytscl(im, /nan, $
      min=(*self.state).min_value, $
      max=(*self.state).max_value, $
      top = top_value) + nan_offset*nan_mask
    ;; log stretch
    'log': begin
      offset = (*self.state).min_value - $
        ((*self.state).max_value - (*self.state).min_value) * 0.01
      imout =  bytscl( alog10( (im - offset) ), $
        min=alog10((*self.state).min_value - offset), /nan, $
        max=alog10((*self.state).max_value - offset),  $
        top = top_value) + nan_offset*nan_mask
    end
    ;; histogram equalization
    'histeq': imout = bytscl(hist_equal(im, $
      minv = (*self.state).min_value, $
      maxv = (*self.state).max_value), $
      /nan, $
      top = top_value) + nan_offset*nan_mask
    ;; square root stretch
    'square root': begin
      imout = bytscl( sqrt((im)>0), $
        min=sqrt((*self.state).min_value), /nan, $
        max=sqrt((*self.state).max_value),  $
        top = top_value) + nan_offset*nan_mask
    end
    ;; asinh stretch. requires Dave Fanning's ASINHSCL.PRO
    ;; this is a hybrid of the DFanning code with Barth's
    ;; ATV version. UNTESTED - 2008-10 20 MDP
    'asinh': begin
      imout = asinhscl( im, $
        min = (*self.state).min_value, $
        max = (*self.state).max_value,$
        omax = top_value,$
        beta = (*self.state).asinh_beta) + nan_offset*nan_mask
    end
    else: begin
      self->message,msgtype='error','Unknown scaling mode.'
      return
    end
  endcase

  if (*self.state).has_dq_mask and (*self.state).flag_bad_pix_from_dq then begin
    ; FIXME - right now anything with nonzero DQ is marked as bad. This is
    ; probably oversimplifying and needs to be improved, a la JWST NIRCam
    ; quicklook tool.
    wbadpix = where(*self.images.dq_image and (*self.state).dq_bit_mask, badpixct)
    if badpixct gt 0 then imout[wbadpix] = (*self.state).dq_display_color

  endif

  if not keyword_set(imin) then *self.images.scaled_image = imout


  ; discard any floating point underflows that may have just happened
  !except=0
  res = check_math()
  ; go back to saved exception-handling state
  !except=except

end

;----------------------------------------------------------------------

pro gpitv::setasinh


  ; if the user is trying to adjust the asinh settings, we had better
  ; be in asinh display mode
  if ~strcmp((*self.state).scaling,'asinh',/fold_case) then self->setscaling, 'asinh'

  ; get the asinh beta parameter

  b = string((*self.state).asinh_beta)

  formline = strcompress('0,float,' + b + $
    ',label_left=Asinh beta parameter: ,width=10, TAG=BETAVALUE')

  formdesc = [formline, $
    ' 0, LABEL, The asinh scaling'+"'s nonlinearity may be adjusted, LEFT", $
    ' 0, LABEL, by changing this parameter beta between 0 and large positive numbers., LEFT', $
    ' 0, LABEL, Higher values make the curve more linear while lower values, LEFT', $
    ' 0, LABEL, closer to 0 make it more nonlinear., LEFT', $
    '1, BASE,,ROW', $
    '0, button, Set beta, quit, TAG=SETBUTTON', $
    '0, button, Cancel, quit, TAG=CANCELBUTTON']

  textform = cw_form(formdesc, ids=ids, /column, $
    title = 'gpitv asinh stretch settings')

  if (textform.CANCELBUTTON EQ 1) then return

  (*self.state).asinh_beta = float(textform.BETAVALUE)
  self->message, msgtype = 'information', "gpitv asinh beta parameter set to "+strc((*self.state).asinh_beta )

  self->displayall

end

;----------------------------------------------------------------------

pro GPItv::getstats ;, noerase=noerase

  ; Get basic image stats: min and max, and size.
  ;
  ; PREVIOUSLY also reset the alignment to center, but that has
  ; nothing to do with getstats so I took it out. -MDP
  ; /align keyword now deprecated
  ; this routine operates on *self.images.main_image
  ;
  ; Also previously erased plot annotations for some reason, unless you set /noerase.
  ; OK, this has nothing to do with statistics - moving it to a call in
  ; setup_new_image instead. -MP


  widget_control, /hourglass

  (*self.state).image_size[0:1] = [ (size(*self.images.main_image))[1], (size(*self.images.main_image))[2] ]

  (*self.state).image_min = min(*self.images.main_image, max=maxx, /nan)
  (*self.state).image_max = maxx
  ;print, "adjusting  image min and max in getstats: "+string((*self.state).image_min) +", "+string( maxx )

  ;tmp_string = string((*self.state).image_min, (*self.state).image_max,format='("Min=", g14.7,"  Max=", g14.7)')
  widget_control, (*self.state).minIma_id, set_value=string((*self.state).image_min, format='(g14.7)')
  widget_control, (*self.state).maxIma_id, set_value=string((*self.state).image_max, format='(g14.7)')

  if ((*self.state).min_value GE (*self.state).max_value) then begin
    (*self.state).min_value = (*self.state).min_value - 1
    (*self.state).max_value = (*self.state).max_value + 1
  endif


end

;-------------------------------------------------------------------

pro GPItv::recenter, align=align
  ; set /align keyword to keep alignment but update the offset anyway

  IF NOT keyword_set(align) THEN (*self.state).centerpix = round((*self.state).image_size[0:1] / 2.)
  self->getoffset

end

;-------------------------------------------------------------------

pro GPItv::setwindow, windowid, nostretch=nostretch

  ; replacement for wset.  Reads the current active window first.
  ; This should be used when the currently active window is an external
  ; (i.e. non-GPItv) idl window.  Use self->setwindow to set the window to
  ; one of the GPItv window, then display something to that window, then
  ; use self->resetwindow to set the current window back to the currently
  ; active external window.  Make sure that device is not set to
  ; postscript, because if it is we can't display anything.
  ;
  ; self->setwindow will now automatically re-stretch the GPItv color table
  ; in case the user has changed the color table elsewhere. Set
  ; /nostretch to disable this behavior. (This can be useful if you're
  ; about to call self->stretchct anyway with different brightness & contrast,
  ; as it prevents uselessly calling the function twice in a row.)
  ;
  ;
  ; 2004-05-05 This also now stores the user's !P.MULTI setting.
  ; 2005-12-09 And also the user's device,decomposed setting for 24-bit displays.


  (*self.state).active_window_pmulti = !p.multi
  !p.multi = 0

  tvlct, user_r, user_g, user_b, /get
  self.colors.user_r = user_r & self.colors.user_g = user_g & self.colors.user_b = user_b

  ; regenerate GPItv color table
  self->initcolors
  device,get_decomposed=decomp
  (*self.state).user_decomposed=decomp
  device,decomposed=0

  if ~(keyword_set(nostretch)) then self->stretchct

  if (!d.name NE 'PS') then begin
    (*self.state).active_window_id = !d.window
    wset, windowid
  endif

end

;---------------------------------------------------------------------

pro GPItv::resetwindow

  ; reset to current active window


  ; The empty command used below is put there to make sure that all
  ; graphics to the previous GPItv window actually get displayed to screen
  ; before we wset to a different window.  Without it, some line
  ; graphics would not actually appear on screen.

  if (!d.name NE 'PS') && ((*self.state).active_window_id ne -1) then begin
    empty ;;flush any buffered window output
    device, Window_State=winstate
    if (n_elements(winstate) ge (*self.state).active_window_id) && $
      winstate[(*self.state).active_window_id] then $
      wset, (*self.state).active_window_id
  endif

  ;!p.multi = (*self.state).active_window_pmulti
end

;------------------------------------------------------------------

pro GPItv::getwindow

  ; get currently active window id

  if (!d.name NE 'PS') then begin
    (*self.state).active_window_id = !d.window
  endif

end

;--------------------------------------------------------------------
;    Fits file reading routines
;--------------------------------------------------------------------
; Front end for loading a new file from either disk or memory
;
; input1     Filename or array
; input2     Optional header input - can be string array or pointer
;                                    array [*primary, *extension]

pro GPItv::open, input1, input2,  _extra=_extra

  ;;if you got a filename, read it in, if you got an array, load it
  if size(input1,/TNAME) eq 'STRING' then begin
    ;; user has given us a filename on disk

    ;; headers have to come from the file so strip them out of keywords
    if keyword_set(_extra) && (tag_exist(_extra,'header') || tag_exist(_extra,'extensionhead')) then begin
      tags = tag_names(_extra)
      inds = where(~strcmp(tags,'header',/fold_case) and ~strcmp(tags,'extensionhead',/fold_case),ct)

      ;;if this is the only thing there, then just kill _extra
      if ct eq 0 then tmp = temporary(_extra) else begin
        tmp = create_struct(tags[inds[0]],_extra.(inds[0]))
        for j = 1,n_elements(inds)-1 do tmp = create_struct(temporary(tmp),tags[inds[j]],_extra.(inds[j]))
        _extra = tmp
      endelse
    endif

    ;;read the fits file
    self->readfits, fitsfilename=input1,  _extra=_extra

    ;;update current directory as needed
    if keyword_set((*self.state).imagename) && file_test((*self.state).imagename) then $
      (*self.state).current_dir=file_dirname((*self.state).imagename)
  endif else begin
    ;; user has given us a variable:
    *self.images.main_image = input1

    ;;if user passsed input2 then it overrides any header or
    ;;extensionheader keywords
    if keyword_set(input2) then begin
      ;;if header is a pointer array then split it into primary and
      ;;extension header here
      if size(input2,/type) eq 10 then begin
        header = *input2[0]
        if n_elements(input2) gt 1 then extensionhead=*input2[1]
      endif else header = input2

      ;;assign header to _extra
      if keyword_set(_extra) then begin
        if tag_exist(_extra,'header') then _extra.header = header else $
          _extra = create_struct(_extra,'header',header)
      endif else _extra = create_struct('header',header)

      ;;if it exists assign extensionhead to _extra
      if keyword_set(extensionhead) then begin
        if tag_exist(_extra,'extensionhead') then _extra.extensionhead = extensionhead else $
          _extra = create_struct(_extra,'extensionhead',extensionhead)
      endif
    endif

    self->setup_new_image, _extra=_extra
  endelse

end

;--------------------------------------------------------------------

pro GPItv::readfits, fitsfilename=fitsfilename, imname=imname, _extra=_extra
  ;; Parameters
  ;; 	fitsfilename	optional name of FITS file to read
  ;; 	imname          optional name to use

  ;; make us look busy
  widget_control,/hourglass

  ;; Read in a new image when user goes to the File->Open menu.
  ;; Do a reasonable amount of error-checking first, to prevent unwanted
  ;; crashes.

  cancelled = 0
  if (n_elements(fitsfilename) EQ 0) then window = 1 else window = 0

  ;; If fitsfilename hasn't been passed to this routine, get filename
  ;; from dialog_pickfile.
  if (n_elements(fitsfilename) EQ 0) then begin
    at_gemini = gpi_get_setting('at_gemini', /bool,default=0,/silent)
    if keyword_set(at_gemini) then filter='S20'+gpi_datestr(/current)+"S*.fits" else filter ='*.fits;*.fits.gz'
    fitsfile = $
      dialog_pickfile(filter = filter, $
      dialog_parent = (*self.state).base_id, $
      /must_exist, $
      /read, $
      path = (*self.state).current_dir, $
      get_path = tmp_dir, $
      title = 'Select Fits Image')
    if (tmp_dir NE '') then (*self.state).current_dir = tmp_dir
    if (fitsfile EQ '') then return ; 'cancel' button returns empty string
  endif else begin
    fitsfile = fitsfilename
  endelse

  if ~file_test(fitsfile) then begin
    self->message,msgtype='error','File not found.'
    return
  endif

  ;; Find out if this is a fits extension file, and how many extensions
  fits_info, fitsfile, n_ext = numext, extname=extnames, /silent
  if numext eq 0 then $
    head = headfits(fitsfile)
  if numext gt 0 then begin
    head0 =  headfits(fitsfile,exten=0)
    ;;head = [head0,headfits(fitsfile,exten=1)]
    head = headfits(fitsfile,exten=1)
  endif

  ;; Check validity of fits file header
  if ((size(head))[0] eq 0) || (n_elements(strcompress(head, /remove_all)) LT 2) then begin
    self->message, 'File  '+fitsfile+' does not appear to be a valid FITS image!', $
      window = window, msgtype = 'error'

    return
  endif
  if (!ERR EQ -1) then begin
    self->message, $
      'Selected file '+fitsfile+' does not appear to be a valid FITS image!', $

      msgtype = 'error', window = window
    return
  endif

  ;;look for the INSTRUME keyword in all available headers
  instrume = strcompress(string(sxpar(head, 'INSTRUME', count=instr_count)), /remove_all)
  if (instr_count eq 0) && (numext gt 0) then $
    instrume = strcompress(string(sxpar(head0, 'INSTRUME', count=instr_count)), /remove_all)
  if (instr_count eq 0) then begin
    self->message,msgtype='information','No INSTRUME keyword found; assuming the input file is a GPI data file of some type.'
    instrume='GPI'
  endif

  ;;figure out geometry
  origin = strcompress(sxpar(head, 'ORIGIN'), /remove_all)
  naxis = sxpar(head, 'NAXIS', count=ct)
  if ct eq 0 and keyword_set(head0) then naxis = sxpar(head0, 'NAXIS', count=ct)

  ;; Make sure it's not a 1-d spectrum
  if (numext EQ 0 AND naxis LT 2) then begin

    self->message, 'Selected file '+fitsfile+' is not a 2-d or 3-d FITS image!', $
      window = window, msgtype = 'error'

    return
  endif

  (*self.state).title_extras = ''



  ;; Now call the subroutine that knows how to read in this particular
  ;; data format:
  if (numext eq 0) then begin   ;if instrume eq 'GPIIFSDST' then begin
    self->plainfits_read, fitsfile, head, cancelled
  endif else if ((numext GT 0) AND (instrume EQ 'GPI')) then begin
    self->fitsext_read_GPI, fitsfile, numext, head, cancelled, extensionhead=extensionhead, extname=extnames, DQext=DQext
  endif else if ((numext GT 0) AND (instrume NE 'GPI') ) then begin
    self->fitsext_read_ask_extension, fitsfile, numext, head, cancelled
  endif else if ((instrume EQ 'WFPC2') AND (naxis EQ 3)) then begin
    self->wfpc2_read, fitsfile, head, cancelled
  endif else if ((naxis EQ 3) AND (origin EQ '2MASS')) then begin
    self->twomass_read, fitsfile, head, cancelled
  endif else begin
    self->plainfits_read, fitsfile, head, cancelled
  endelse

  if (cancelled EQ 1) then return
  ;if ~(keyword_set(imname)) then imname=fitsfile else imname=imname+" ("+fitsfile+")"
  ;beceuase GPItv will actually use imname as a filename to try to open headers, we cant set it as some fancy string
  imname=fitsfile

  self->setup_new_image, header=head, imname=imname, extensionhead=extensionhead, DQext=DQext, _extra=_extra

end

;--------------------------------------------------------------------
pro GPItv::setup_new_image, header=header, imname=imname, $
  dispwavecalgrid=dispwavecalgrid, $
  min = minimum, max = maximum, $
  linear = linear, log = log, sqrt = sqrt, $
  histeq = histeq, asinh = asinh, $
  DQext=DQext, $
  _extra=_extra

  ; This routine, called right after a new image has been loaded into
  ; *self.images.main_image, now loads and applies all the metadata that is associated with that new
  ; image. I think.  Used to be called "load_new_image" but it wasn't really
  ; loading so I renamed it - MDP.
  ;
  ; Keywords
  ;  header - Primary header array
  ;  imname - Image name
  ;  dispwavecalgrid - Name of wavecal to display
  ;  min - Minimum value for stretch
  ;  max - Maximum value for stretch
  ;  /linear,/log,/sqrt,/histeq,/asinh - Set image scaling

  ;; make us look busy
  widget_control, /hourglass

  ;;set some defaults
  if ~(keyword_set(imname)) then imname = ''
  *self.images.main_image_stack = *self.images.main_image
  ;;the image backup is the main image stack
  *self.images.main_image_backup = *self.images.main_image_stack


  ;; if we got a DQ extension, save it to the appropriate place, otherwise zero out that part.
  if keyword_set(DQext) then begin
	; the dq frames for things such as wavecals sometimes have a dq mask that is not
	; the same size as an image - check for this then dump the dq frame if this is the case
	sz_dq=size(dqext)
	sz_im=size(*self.images.main_image)

	; check that the first three dimensions are the same
	if total(sz_dq[0:2]-sz_im[0:2]) eq 0 then begin	

	  (*self.state).has_dq_mask = 1
	  if (size(DQext))[0] eq 2 then *self.images.dq_image = DQext $
		                       else *self.images.dq_image_stack = DQext
	endif else begin; end dimension check
	; if dimensions are bad - kill the extension
	self->message,msgtype='information',"DQ extension has wrong dimensions and will be ignored"
	delvarx,dqext
	  (*self.state).has_dq_mask = 0
	  *self.images.dq_image_stack = 0 
	  *self.images.dq_image = 0 
	endelse

  endif else begin
	  (*self.state).has_dq_mask = 0
	  *self.images.dq_image_stack = 0 
	  *self.images.dq_image = 0 
  endelse

  ;;handle missing headers
  if ~(keyword_set(header)) then begin
    ; if we're loading a dummy header for a null image because the
    ; user started gpitv without specifying an image yet, then
    ; don't print any errors about a missing header here; that's obvious.
    silent = (imname eq "NO IMAGE LOADED   ") ; must match dummy image name assigned in ::init

    if ~silent then self->message,msgtype='information',"No header supplied! Creating a basic one with MKHDR"
    mkhdr,header,*self.images.main_image
  endif

  ;; set the main image and update gui appropriately
  thirddimchange = 0            ;track whether we're switching between a 2&3d image
  (*self.state).prev_image_size = (*self.state).image_size ;back up image size
  case (size(*self.images.main_image))[0] of
    2: begin                   ; 2D image
      (*self.state).image_size = [(size(*self.images.main_image_stack))[1:2], 1]
      tmp = where((*self.state).prev_image_size ne (*self.state).image_size,coordupdate)
      (*self.state).imagename = imname
      (*self.state).title_extras = ''

      ;; hide the image slicer & set image number to 0
      widget_control, (*self.state).curimnum_base_id0,map=0,xsize=1,ysize=1
      (*self.state).cur_image_num = 0
      if (*self.state).prev_image_2D eq 0 then thirddimchange = 1
      (*self.state).prev_image_2D = 1 ; set so that next image knows its coming from a 2D image
    end ;end 2d case

    3: begin                   ; case of 3-d imagecube
      (*self.state).image_size = (size(*self.images.main_image_stack))[1:3]
      tmp = where((*self.state).prev_image_size ne (*self.state).image_size,coordupdate)

      ;;if we didn't have an image before, or sticky is
      ;;unset, default display image to 1/4 of the cube to
      ;;avoid showing "bad first frame" otherwise, keep the current
      ;;slice
      if ((*self.state).prev_image_2D eq 1) || ((*self.state).retain_current_slice eq 0) || $
        (*self.state).isfirstimage || (coordupdate ne 0) then $
        (*self.state).cur_image_num=round((*self.state).image_size[2]/4.)

      ;; but update the current slice if necessary if it's out of range
      if (*self.state).cur_image_num ge (*self.state).image_size[2] then $
        (*self.state).cur_image_num = (*self.state).image_size[2]-1
      if (*self.state).cur_image_num lt 0 then (*self.state).cur_image_num = 0

      *self.images.main_image = (*self.images.main_image_stack)[*, *, (*self.state).cur_image_num]

      ; Select appropriate slice from DQ array, if present.
      if ((*self.state).has_dq_mask) then *self.images.dq_image = (*self.images.dq_image_stack)[*, *, (*self.state).cur_image_num]

      ;;draw the image slicer
      widget_control,(*self.state).curimnum_base_id0,map=1, xsize=(*self.state).draw_window_size[0], ysize=45
      (*self.state).imagename = ''
      (*self.state).title_extras = strcompress(' Slice: ' + string((*self.state).cur_image_num))

      ;; set image names, if we have them
      if keyword_set(imname) then begin
        *self.images.names_stack = imname
        (*self.state).imagename = imname[0]
      endif else begin
        (*self.state).imagename=''
        *self.images.names_stack=strarr(n_elements((*self.images.main_image)[0,0,*]))
      endelse

      ;; update the image slice control base, and especially the
      ;; slider range
      widget_control,(*self.state).curimnum_base_id0, map=1
      widget_control, (*self.state).curimnum_text_id, sensitive = 1
      widget_control, (*self.state).curimnum_slidebar_id, sensitive = 1, $
        set_slider_min = 0, $
        set_slider_max = (*self.state).image_size[2]-1
      widget_control, (*self.state).scale_mode_droplist_id, sensitive = 1
      if (*self.state).prev_image_2D eq 1 then thirddimchange = 1
      (*self.state).prev_image_2D = 0 ; set so that next image knows its coming from a 3D image
    end                        ;end 3d case

    else: begin
      ;; Catch-all case for non 2-d or 3-d images - alert the user
      self->message, 'Selected file is not a 2-D or 3-D FITS image!', $
        msgtype = 'error', window = window
      *self.images.main_image = fltarr(512, 512)
      return
    end
  endcase ;;dimensionality of main image

  ;; if image dimensionality has changed from previously loaded one,
  ;; set cursor coords to center
  if coordupdate ne 0 then (*self.state).coord = round((*self.state).image_size[0:1] / 2.)

  ;; we default to the zero collapse mode unless retain collapse mode
  ;; is set and the new image appears to be of the same type as the
  ;; previous one (image size matches)
  (*self.state).specalign_mode = 0
  (*self.state).klip_mode = 0
  if ~(*self.state).retain_collapse_mode || (coordupdate ne 0) then begin
    (*self.state).high_pass_mode = 0
    (*self.state).low_pass_mode = 0
    (*self.state).snr_map_mode = 0
    (*self.state).collapse = 0
  endif

  ;; clean up anything left from previous image
  ;; remove any existing satellite spots, and allocate proper size for
  ;; contrast profile pointers - has to be done before calling collapsecube
  self.satspots.valid = 0
  self.satspots.attempted = 0
  ptr_free,self.satspots.cens
  self.satspots.cens = ptr_new(/allocate_heap)
  (*self.state).fpmoffset_fpmpos = 0

  ;; kill everything associated with contrprofile
  heap_free,self.satspots.asec
  heap_free,self.satspots.contrprof
  self.satspots.contrprof = ptr_new(/alloc) ;contour profile (will be Z x 3 pointer array with first dimension being stdev,median,mean)
  self.satspots.asec = ptr_new(/alloc) ;arrays of ang sep vals (will be Z x 1 pointer array)
  *self.satspots.contrprof = ptrarr((*self.state).image_size[2],3,/alloc) ;arrays of radial profile vals
  *self.satspots.asec = ptrarr((*self.state).image_size[2],/alloc)        ;arrays of ang sep vals

  ;;kill any existing klip image
  ptr_free,self.images.klip_image
  self.images.klip_image = ptr_new(/allocate_heap)

  ;; remove any existing CWV_ptrs
  if (ptr_valid((*self.state).CWV_ptr)) then ptr_free, (*self.state).CWV_ptr

  ;; discard any previously loaded polcal or wavecal file for overplotting.
  (*self.state).wcfilename=''

  ;; set image header
  self->setheader, header, _extra=_extra
  self->setheadinfo

  ;; figure out padding
  widget_control, (*self.state).base_id, tlb_get_size=tmp_event
  (*self.state).base_pad = tmp_event - (*self.state).draw_window_size

  ; get statistics
  self->getstats
  ; Remove any plots or annotations left over from the previous image.
  self->erase, /norefresh

  if n_elements(minimum) GT 0 then (*self.state).min_value = minimum
  if n_elements(maximum) GT 0 then (*self.state).max_value = maximum

  ;; make sure user inputs were sane
  if (*self.state).min_value GE (*self.state).max_value then begin
    (*self.state).min_value = (*self.state).max_value - 1.
  endif

  ;; apply any requested scaling
  if (keyword_set(linear)) then self->setscaling, 'linear'
  if (keyword_set(log))    then self->setscaling, 'log'
  if (keyword_set(histeq)) then self->setscaling, 'histeq'
  if (keyword_set(asinh))  then self->setscaling, 'asinh'
  if (keyword_set(sqrt))   then self->setscaling, 'square root'

  ;; reset zoom and centering if not retaining current view or if this
  ;; is the first image
  if ~(*self.state).retain_current_view || (*self.state).isfirstimage || thirddimchange then begin
    (*self.state).zoom_level =  0
    (*self.state).zoom_factor = 1.0

    ;; need to generate a scaled image and pan image before calling
    ;; autozoom (which calls self->refresh)
    if (*self.state).isfirstimage || thirddimchange then begin
      self->scaleimage
      self->makepan
    endif

    self->autozoom

    ;; kill any state about having rotated or inverted the previous image
    (*self.state).rot_angle = 0
    (*self.state).invert_image = 'none'
    self->update_menustate_rotate_invert

    ;; if asked, check if we need to flip to get handedness to normal astronomical
    ;; left-handed sky
    ;; This doesn't happen if retain_current_view is set. by design
    if (*self.state).autohandedness then self->autohandedness

  endif

  ;; if retaining view, apply previous inversion to the new image
  if (*self.state).retain_current_view &&  ((*self.state).invert_image ne 'none') then begin
    prior_invert = (*self.state).invert_image
    (*self.state).invert_image = 'none'
    self->invert, prior_invert, /nodisplay
  endif

  ;; if retaining view, apply previous rotation to the new image
  if (*self.state).retain_current_view &&  ( (*self.state).rot_angle  ne 0) then begin
    prior_rotation = (*self.state).rot_angle
    (*self.state).rot_angle = 0.0
    self->rotate, prior_rotation, /nodisplay
  endif

  self->recenter, align=(*self.state).retain_current_view ; must call recenter whether keeping alignment or not, to update some state vars

  self->settitle
  self->set_minmax

  ;;if high_pass is flagged and current collapse mode is not high
  ;;pass, do a high pass before applying the mode
  widget_control, (*self.state).collapse_button, get_value=modelist
  if (*self.state).high_pass_mode && (modelist[(*self.state).collapse] ne 'High Pass Filter') then begin
    self->high_pass_filter,/forcestack
  endif
  ;;if low_pass is flagged and current collapse mode is not low
  ;;pass, do a low pass before applying the mode
  widget_control, (*self.state).collapse_button, get_value=modelist
  if (*self.state).low_pass_mode && (modelist[(*self.state).collapse] ne 'Low Pass Filter') then begin
    self->low_pass_filter,/forcestack
  endif

  widget_control, (*self.state).collapse_button, get_value=modelist
  if (*self.state).low_pass_mode && (modelist[(*self.state).collapse] ne 'Create SNR Map') then begin
    self->create_snr_map
  endif

  self->collapsecube
  tmp = widget_info((*self.state).collapse_button,/droplist_select)
  if tmp ne (*self.state).collapse then widget_control, (*self.state).collapse_button,set_droplist_select = (*self.state).collapse
  self->setcubeslicelabel

  ;; if asked, autoscale now
  if (~(*self.state).retain_current_stretch or (*self.state).isfirstimage) then self->autoscale
  self->displayall

  ;; display the wavecalgrid, optionally
  if keyword_set(dispwavecalgrid) && ((size(*self.images.main_image))[0] EQ 2) then begin
    (*self.state).wcfilename=dispwavecalgrid
    self->wavecalgrid, gridcolor=1, tiltcolor=2, labeldisp=0,  labelcolor=7, charsize=1.0, charthick=1
  endif

  ;; update all children
  self->update_child_windows,update = (coordupdate eq 0)

  ;;if you got here, you're no longer on the first image
  if ~strcmp(imname,"NO IMAGE LOADED   ") then (*self.state).isfirstimage = 0

end

;----------------------------------------------------------------------

pro GPItv::update_sat_spots,locs0=locs0
  ;calls get_sat_fluxes on current image stack and write results to
  ;appropriate heap vars.
  ;In the future, we may want a user controllable setting for
  ;gaussfit and refinefits
  ;
  ;locs0 - Starting locations to try


  ; if we already attempted to measure them but failed, don't
  ; mindlessly keep repeating that. We already know we can't make
  ; it work for this file...
  if ~self.satspots.valid and self.satspots.attempted then begin
	  self->message, "we already failed to find sat spots on this image; not trying again."
	  return 
  endif

  ;;if the info is in the header, just get it from there
  cens = -1
  if ptr_valid( (*self.state).exthead_ptr) then $
	  cens = gpi_satspots_from_header(*((*self.state).exthead_ptr),good=good,fluxes=sats,warns=warns)

  ;;otherwise, look for them
  self.satspots.attempted = 1
  if n_elements(cens) eq 1 then begin

    ;;always use the backup main image so that you know you're
    ;;operating on the orig image.
    sats = get_sat_fluxes(*self.images.main_image_backup,band=(*self.state).obsfilt,$
      good=good,cens=cens,warns=warns,highpass=(*self.state).contr_highpassspots,$
      constrain = (*self.state).contr_constspots,$
      winap=(*self.state).contrwinap,gaussap=(*self.state).contrap,$
      indx=(*self.state).cur_image_num,locs=locs0,gaussfit=1,refinefits=1,$
	    secondorder =  (*self.state).contr_secondorder)
    if n_elements(sats) eq 1 and sats[0] eq -1 then begin
      self->message,msgtype='error',['Failed to locate satellite spots in this image.',$
        'Check that it is a coronagraphic image with an occulted target.']
      return
    endif
  endif else begin
    ;;edge case where sat spot locations are in the header but
    ;;sat spot fluxes aren't. Use locations to measure fluxes
    if n_elements(sats) eq 0 then begin
      ;;always use the backup main image so that you know you're
      ;;operating on the orig image.
      sats = get_sat_fluxes(*self.images.main_image_backup,band=(*self.state).obsfilt,$
        good=good,cens=cens,warns=warns,highpass=(*self.state).contr_highpassspots,$
        constrain = (*self.state).contr_constspots,$
        winap=(*self.state).contrwinap,gaussap=(*self.state).contrap,$
        indx=(*self.state).cur_image_num,locs=locs0,gaussfit=1,refinefits=1,/usecens,$
	    secondorder =  (*self.state).contr_secondorder)
      if n_elements(sats) eq 1 and sats[0] eq -1 then begin
        self->message,msgtype='error',['Failed to locate satellite spots in this image.',$
          'Check that it is a coronagraphic image with an occulted target.']
        return
      endif
    endif
  endelse

  ;;Added by Naru 130709: Measuring sat spot total fluxes and
  ;;calculated central star brightness in magnitudes
  sat1flux = fltarr(n_elements(sats[0,*]))    ;;top left
  sat2flux = fltarr(n_elements(sats[0,*]))    ;;bottom left
  sat3flux = fltarr(n_elements(sats[0,*]))    ;;top right
  sat4flux = fltarr(n_elements(sats[0,*]))    ;;bottom right
  mean_sat_flux = fltarr(n_elements(sats[0,*]))

  cube =  *self.images.main_image_backup

  for s=0,n_elements(sats[0,*])-1 do begin
    ;;using aperature radius 3 pixels
    aper, cube[*,*,s],cens[0,0,s],cens[1,0,s],flux,eflux,sky,skyerr,1.,3.,[10.,20.],[-10.,2*max(sats)],/flux,/exact,/nan,/silent
    sat1flux[s]=flux
    aper, cube[*,*,s],cens[0,1,s],cens[1,1,s],flux,eflux,sky,skyerr,1.,3.,[10.,20.],[-10.,2*max(sats)],/flux,/exact,/nan,/silent
    sat2flux[s]=flux
    aper, cube[*,*,s],cens[0,2,s],cens[1,2,s],flux,eflux,sky,skyerr,1.,3.,[10.,20.],[-10.,2*max(sats)],/flux,/exact,/nan,/silent
    sat3flux[s]=flux
    aper, cube[*,*,s],cens[0,3,s],cens[1,3,s],flux,eflux,sky,skyerr,1.,3.,[10.,20.],[-10.,2*max(sats)],/flux,/exact,/nan,/silent
    sat4flux[s]=flux
    ;;calculate a mean satellite spectrum
    mean_sat_flux[s]=mean([sat1flux[s], sat2flux[s], sat3flux[s], sat4flux[s]]) ; counts/slice
  endfor

  ;;convert to photons per second - need the gain
  header=(*(*self.state).head_ptr)
  extheader=(*(*self.state).exthead_ptr)
  gain=sxpar(extheader,'sysgain') ;  electrons/ADU

  filter = (*self.state).obsfilt


  if (*self.state).cube_mode eq 'WAVE' then begin

	  ;;get wavelengths of cube
	  cube_waves = *((*self.state).CWV_ptr)

	  ;;get vega flux
	  ;; vega zero points and filter central wavelenghts stored in gpi_constants config file
	  filt_cen_wave=gpi_get_constant('cen_wave_'+filter)       ; in um
	  zero_vega=gpi_get_constant('zero_pt_flux_'+filter)       ; in erg/cm2/s/um

	  ;;#####
	  ;;must convert to photons
	  ;;#####
	  h=6.626068d-27                      ; erg / s
	  c=2.99792458d14                     ; um / s
	  zero_vega*=(filt_cen_wave/(h*c))    ; ph/cm2/s/um

	  ;; get the pupil area (cm^2)
	  primary_diam = gpi_get_constant('primary_diam',default=7.7701d0)*100d ; cm
	  secondary_diam = gpi_get_constant('secondary_diam',default=1.02375d0)*100d ; cm
	  area=(!pi*(primary_diam/2.0)^2.0 - !pi*(secondary_diam/2.0)^2.0 )
	  zero_vega*=area               ; ph/s/um
	  ;; multiply by instrument throughput (18.6%) in H-band
	  ;; assumes H-band PPM and 080m12_04  Lyot, and H-filter


	  ;; get instrument transmission (and resolution)
	  ;; corrections for lyot, PPM, and filter transmission
	  pupil_mask_string=gpi_simplify_keyword_value(sxpar(header,'APODIZER'))
	  lyot_mask_string=sxpar(header,'LYOTMASK')
	  transmission=calc_transmission(filter, pupil_mask_string, lyot_mask_string, resolution=resolution, without_filter=1)

	  if transmission[0] eq -1 then begin
		self->message,msgtype='error',['Failed to calculate transmission']
		return
	  endif

	  ;; no filter transmission included - instead we will integrate the vega spectrum over the filter profile
	  zero_vega*=transmission       ; ph/s/um

	  ;; multiply by the integration time
	  zero_vega*=sxpar(extheader,'ITIME')   ; ph/um
	  ;; now the unit wavelength
	  ; calculate the width of a wavelength slice
	  dlambda=cube_waves[1]-cube_waves[0]
	  zero_vega*=dlambda ; now in ph/slice
	  ;; load filters for integration
	  filt_prof0=mrdfits( gpi_get_directory('GPI_DRP_CONFIG')+'/filters/GPI-filter-'+filter+'.fits',1,/silent)
	  filt_prof=interpol(filt_prof0.transmission,filt_prof0.wavelength,cube_waves)

	  ;; note that Naru measured the photometry using a 3 pixel radius - he calculated later that the sum of the entire spot is equal to 0.57*3pixel photometry
	  ;; i did this in one slice and got 0.63 - not far off
	  sat_mag=-2.5*alog10(total( (gain*mean_sat_flux/0.57) )$
		/total(zero_vega*filt_prof))

	  ;; need to use satellite intensity flux calibration to get magnitude of star
	  ;;msat-mstar=-2.5log(Fsat/Fstar)
	  mags=sat_mag+2.5*alog10(((*self.state).gridfac))
	  ;;update sat spots to account for any inversion/rotation
  endif else begin
	  ; TODO - add photometric calibration support for pol mode
	  self->message,'sat spot photometry not supported in pol mode yet'
	  mags = dblarr(2)
  endelse

  ichange = (*self.state).invert_image
  if strmatch(ichange,'x*') then cens[0,*,*] = (*self.state).image_size[0] - cens[0,*,*]
  if strmatch(ichange,'*y') then cens[1,*,*] = (*self.state).image_size[1] - cens[1,*,*]

  if (*self.state).rot_angle ne 0. then begin
    rotang = (*self.state).rot_angle *!dpi/180d0
    rotMat = [[cos(rotang),sin(rotang)],$
      [-sin(rotang),cos(rotang)]]
    c0 = (*self.state).image_size[0:1]/2 # (dblarr(4) + 1d0)
    for j = 0,(*self.state).image_size[2]-1 do cens[*,*,j] = (rotMat # (cens[*,*,j] - c0))+c0
  endif

  *self.satspots.cens = cens       ;;2x4xZ array of sat spot locations
  *self.satspots.warns = warns     ;;Z x 1 array of warnings
  *self.satspots.good = good       ;;indices of slices where all spots were found
  *self.satspots.satflux = sats    ;;4 x Z array of satellite spot fluxes
  *self.satspots.mags = mags       ;;central star mag calculated via sat spots
  self.satspots.valid = 1
  self.satspots.attempted = 1

  ;;delete any existing contrast profiles. new spots means new
  ;;profile and reallocate (arrays of radial profile vals)
  heap_free, *self.satspots.contrprof
  *self.satspots.contrprof = ptrarr((*self.state).image_size[2],3,/alloc)

end


;----------------------------------------------------------
;  Subroutines for reading specific data formats
;---------------------------------------------------------------

pro GPItv::fitsext_read, fitsfile, numext, head, cancelled, extension=extension

  ; Fits reader for fits files, both simple and with extenions


  ;if ~(keyword_set(extension)) then begin
  if n_elements(extension) eq 0 then begin
    ; query the user to figure out which extension to load.
    ; This only executes if we do not already know the extension we want.

    numlist = ''
    for i = 1, numext do begin
      numlist = strcompress(numlist + string(i) + '|', /remove_all)
    endfor

    numlist = strmid(numlist, 0, strlen(numlist)-1)

    droptext = strcompress('0, droplist, ' + numlist + $
      ', label_left=Select Extension:, set_value=0')

    formdesc = ['0, button, Read Primary Image, quit', $
      '0, label, OR:', $
      droptext, $
      '0, button, Read Fits Extension, quit', $
      '0, button, Cancel, quit']

    textform = cw_form(formdesc, /column, $
      title = 'Fits Extension Selector')

    if (textform.tag4 EQ 1) then begin  ; cancelled
      cancelled = 1
      return
    endif

    if (textform.tag3 EQ 1) then begin   ;extension selected
      extension = long(textform.tag2) + 1
    endif else begin
      extension = 0               ; primary image selected
    endelse

    ; Make sure it's not a fits table: this would make mrdfits crash
    head = headfits(fitsfile, exten=extension)
    xten = strcompress(sxpar(head, 'XTENSION'), /remove_all)
    if (xten EQ 'BINTABLE') then begin
      self->message, 'File appears to be a FITS table, not an image.', $
        msgtype='error', /window
      cancelled = 1
      return
    endif

  endif

  if (extension GE 1) then begin
    (*self.state).title_extras = strcompress('Extension ' + string(extension))
  endif else begin
    (*self.state).title_extras = 'Primary Image'
  endelse

  ; Read in the image
  *self.images.main_image=0.
  *self.images.main_image = float(mrdfits(fitsfile, extension, head, /silent, /fscale))

end

;----------------------------------------------------------------
pro GPItv::fitsext_read_ask_extension, fitsfile, numext, head, cancelled

  ; Fits reader for fits extension files


  if numext gt 1 then begin ;if GPI data contains more than 1 ext
    numlist = ''
    for i = 1, numext do begin
      numlist = strcompress(numlist + string(i) + '|', /remove_all)
    endfor

    numlist = strmid(numlist, 0, strlen(numlist)-1)

    droptext = strcompress('0, droplist, ' + numlist + $
      ', label_left=Select Extension:, set_value=0')

    formdesc = ['0, label, Multi-Extension Fits, quit', $
      '0, label, (PHU will be append to ext header)', $
      droptext, $
      '0, button, Read Fits Extension, quit', $
      '0, button, Cancel, quit']

    textform = cw_form(formdesc, /column, $
      title = 'Fits Extension Selector')

    if (textform.tag4 EQ 1) then begin  ; cancelled
      cancelled = 1
      return
    endif

    if (textform.tag3 EQ 1) then begin   ;extension selected
      extension = long(textform.tag2) + 1
    endif else begin
      extension = 0               ; primary image selected
    endelse
  endif else begin
    extension = 1
  endelse
  ; Make sure it's not a fits table: this would make mrdfits crash
  headPHU = headfits(fitsfile, exten=0)
  head = headfits(fitsfile, exten=extension)
  xten = strcompress(sxpar(head, 'XTENSION'), /remove_all)
  if (xten EQ 'BINTABLE') then begin
    self->message, 'File appears to be a FITS table, not an image.', $
      msgtype='error', /window
    cancelled = 1
    return
  endif

  if (extension GE 1) then begin
    (*self.state).title_extras = strcompress('Extension ' + string(extension))
  endif else begin
    (*self.state).title_extras = 'Primary Image'
  endelse

  ; Read in the image
  *self.images.main_image=0.
  *self.images.main_image = float(mrdfits(fitsfile, extension, head, /silent, /fscale))
  head=[headPHU,head]
end

;----------------------------------------------------------------
pro GPItv::fitsext_read_GPI, fitsfile, numext, head, cancelled, extensionhead=extensionhead, extnames=extnames, DQext=DQext

  ; Fits reader for fits extension files - assumes extensions for GPI


  if numext ge 1 then begin
    ;if GPI data contains more than 1 ext
    ; assume the image data is in extension 1
    extension = 1
  endif else begin
    extension=0
  endelse

  ; Make sure it's not a fits table: this would make mrdfits crash
  headPHU = headfits(fitsfile, exten=0)
  head = headfits(fitsfile, exten=extension)
  xten = strcompress(sxpar(head, 'XTENSION'), /remove_all)
  if (xten EQ 'BINTABLE') then begin
    self->message, 'File appears to be a FITS table, not an image.', $
      msgtype='error', /window
    cancelled = 1
    return
  endif

  if (extension GE 1) then begin
    (*self.state).title_extras = strcompress('Extension ' + string(extension))
  endif else begin
    (*self.state).title_extras = 'Primary Image'
  endelse

  ; Read in the image
  *self.images.main_image=0.
  *self.images.main_image = float(mrdfits(fitsfile, extension, extensionhead, /silent, /fscale))
  ;head=[headPHU,head]
  head = headPHU

  ; Special functionality for GPI files only:
  ; Read in DQ extension if present!
  if n_elements(extnames) gt 1 then begin
    dq_extnum = where(strmatch(extnames, 'DQ*'), mct)
    if mct eq 1 then begin
      DQext = mrdfits(fitsfile, dq_extnum[0], dq_header, /silent)
      message,/info, 'Found and loaded DQ extension for that FITS file.'
    endif
  endif

end

;---------------------------------------------------------------
pro GPItv::plainfits_read, fitsfile, head, cancelled


  ; Fits reader for plain fits files, no extensions.

  *self.images.main_image=0.
  ;*self.images.main_image = mrdfits(fitsfile, 0, head, /silent, /fscale)
  *self.images.main_image = float(readfits(fitsfile, exten_no=0, head, /silent))

end

;------------------------------------------------------------------

pro GPItv::wfpc2_read, fitsfile, head, cancelled

  ; Fits reader for 4-panel HST WFPC2 images


  droptext = strcompress('0, droplist,PC|WF2|WF3|WF4|Mosaic,' + $
    'label_left = Select WFPC2 CCD:, set_value=0')

  formdesc = [droptext, $
    '0, button, Read WFPC2 Image, quit', $
    '0, button, Cancel, quit']

  textform = cw_form(formdesc, /column, title = 'WFPC2 Chip Selector')

  if (textform.tag2 EQ 1) then begin ; cancelled
    cancelled = 1
    return
  endif

  ccd = long(textform.tag0) + 1

  widget_control, /hourglass
  if (ccd LE 4) then begin
    *self.images.main_image=0.
    wfpc2_read, fitsfile, *self.images.main_image, head, num_chip = ccd
  endif

  if (ccd EQ 5) then begin
    *self.images.main_image=0.
    wfpc2_read, fitsfile, *self.images.main_image, head, /batwing
  endif

  case ccd of
    1: (*self.state).title_extras = 'PC1'
    2: (*self.state).title_extras = 'WF2'
    3: (*self.state).title_extras = 'WF3'
    4: (*self.state).title_extras = 'WF4'
    5: (*self.state).title_extras = 'Mosaic'
    else: (*self.state).title_extras = ''
  endcase

end

;----------------------------------------------------------------------

pro GPItv::twomass_read, fitsfile, head, cancelled

  ; Fits reader for 3-plane 2MASS Extended Source J/H/Ks data cube


  droptext = strcompress('0, droplist,J|H|Ks,' + $
    'label_left = Select 2MASS Band:, set_value=0')

  formdesc = [droptext, $
    '0, button, Read 2MASS Image, quit', $
    '0, button, Cancel, quit']

  textform = cw_form(formdesc, /column, title = '2MASS Band Selector')

  if (textform.tag2 EQ 1) then begin ; cancelled
    cancelled = 1
    return
  endif

  *self.images.main_image=0.
  *self.images.main_image = mrdfits(fitsfile, 0, head, /silent, /fscale)

  band = long(textform.tag0)
  *self.images.main_image = (*self.images.main_image)[*,*,band]    ; fixed 11/28/2000

  case textform.tag0 of
    0: (*self.state).title_extras = 'J Band'
    1: (*self.state).title_extras = 'H Band'
    2: (*self.state).title_extras = 'Ks Band'
    else: (*self.state).title_extras = ''
  endcase

  ; fix ctype2 in header to prevent crashes when running xy2ad routine:
  if (strcompress(sxpar(head, 'CTYPE2'), /remove_all) EQ 'DEC---SIN') then $
    sxaddpar, head, 'CTYPE2', 'DEC--SIN'

end
;----------------------------------------------------------------------

pro gpitv::getdss


  formdesc = ['0, text, , label_left=Object Name: , width=15, tag=objname', $
    '0, button, NED|SIMBAD, set_value=0, label_left=Object Lookup:, exclusive, tag=lookupsource', $
    '0, label, Or enter J2000 Coordinates:, CENTER', $
    '0, text, , label_left=RA   (hh:mm:ss.ss): , width=15, tag=ra', $
    '0, text, , label_left=Dec (+dd:mm:ss.ss): , width=15, tag=dec', $
    '0, droplist, 1st Generation|2nd Generation Blue|2nd Generation Red|2nd Generation Near-IR, label_left=Band:, set_value=0,tag=band ', $
    '0, float, 10.0, label_left=Image Size (arcmin; max=60): ,tag=imsize', $
  '1, base, , row', $
    '0, button, Get Image, tag=getimage, quit', $
    '0, button, Cancel, tag=cancel, quit']

  archiveform = cw_form(formdesc, /column, title = 'gpitv: Get DSS Image')

  if (archiveform.cancel EQ 1) then return

  if (archiveform.imsize LE 0.0 OR archiveform.imsize GT 60.0) then begin
    self->message, 'Image size must be between 0 and 60 arcmin.', $
      msgtype='error', /window
    return
  endif

  case archiveform.band of
    0: band = '1'
    1: band = '2b'
    2: band = '2r'
    3: band = '2i'
    else: self->message, msgtype = 'error', 'error in gpitv::getdss!'
  endcase

  case archiveform.lookupsource of
    0: ned = 1
    1: ned = 0  ; simbad lookup
  endcase

  widget_control, /hourglass
  if (archiveform.objname NE '') then begin
    ; user entered object name
    querysimbad, archiveform.objname, ra, dec, found=found, ned=ned, $
      errmsg=errmsg
    if (found EQ 0) then begin
      self->message, errmsg, msgtype='error', /window
      return
    endif
  endif else begin
    ;  user entered ra, dec
    rastring = archiveform.ra
    decstring = archiveform.dec
    self->getradec, rastring, decstring, ra, dec
  endelse

  ; as of nov 2006, stsci server doesn't seem to recognize '2i'
  ; band in the way it used to.  Use eso server for 2i.
  if (band NE '2i') then begin
    querydss, [ra, dec], tmpimg, tmphdr, imsize=archiveform.imsize, $
      survey=band
  endif else begin
    querydss, [ra, dec], tmpimg, tmphdr, imsize=archiveform.imsize, $
      survey=band, /eso
  endelse

  gpitv, temporary(tmpimg), header=temporary(tmphdr)

end

;-----------------------------------------------------------------

pro gpitv::getfirst


  formdesc = ['0, text, , label_left=Object Name: , width=15, tag=objname', $
    '0, button, NED|SIMBAD, set_value=0, label_left=Object Lookup:, exclusive, tag=lookupsource', $
    '0, label, Or enter J2000 Coordinates:, CENTER', $
    '0, text, , label_left=RA   (hh:mm:ss.ss): , width=15, tag=ra', $
    '0, text, , label_left=Dec (+dd:mm:ss.ss): , width=15, tag=dec', $
    '0, float, 10.0, label_left=Image Size (arcmin; max=30): ,tag=imsize', $
  '1, base, , row', $
    '0, button, Get Image, tag=getimage, quit', $
    '0, button, Cancel, tag=cancel, quit']

  archiveform = cw_form(formdesc, /column, title = 'gpitv: Get FIRST Image')

  if (archiveform.cancel EQ 1) then return

  if (archiveform.imsize LE 0.0 OR archiveform.imsize GT 30.0) then begin
    self->message, 'Image size must be between 0 and 30 arcmin.', $
      msgtype='error', /window
    return
  endif

  imsize = string(round(archiveform.imsize))

  case archiveform.lookupsource of
    0: ned = 1
    1: ned = 0  ; simbad lookup
  endcase

  widget_control, /hourglass
  if (archiveform.objname NE '') then begin
    ; user entered object name
    querysimbad, archiveform.objname, ra, dec, found=found, ned=ned, $
      errmsg=errmsg
    if (found EQ 0) then begin
      self->message, errmsg, msgtype='error', /window
      return
    endif

    ; convert decimal ra, dec to hms, dms
    sra = sixty(ra/15.0)
    rahour = string(round(sra[0]))
    ramin = string(round(sra[1]))
    rasec = string(sra[2])

    if (dec LT 0) then begin
      decsign = '-'
    endif else begin
      decsign = '+'
    endelse
    sdec = sixty(abs(dec))

    decdeg = strcompress(decsign + string(round(sdec[0])), /remove_all)
    decmin = string(round(sdec[1]))
    decsec = string(sdec[2])

  endif else begin
    ;  user entered ra, dec
    rastring = archiveform.ra
    decstring = archiveform.dec

    rtmp = rastring
    pos = strpos(rtmp, ':')
    if (pos EQ -1) then pos = strlen(rtmp)
    rahour = strmid(rtmp, 0, pos)
    rtmp = strmid(rtmp, pos+1)
    pos = strpos(rtmp, ':')
    if (pos EQ -1) then pos = strlen(rtmp)
    ramin = strmid(rtmp, 0, pos)
    rtmp = strmid(rtmp, pos+1)
    rasec = rtmp

    dtmp = decstring
    pos = strpos(dtmp, ':')
    if (pos EQ -1) then pos = strlen(dtmp)
    decdeg = strmid(dtmp, 0, pos)
    dtmp = strmid(dtmp, pos+1)
    pos = strpos(dtmp, ':')
    if (pos EQ -1) then pos = strlen(dtmp)
    decmin = strmid(dtmp, 0, pos)
    dtmp = strmid(dtmp, pos+1)
    decsec = dtmp

  endelse

  ; build the url to get image

  url = 'http://third.ucllnl.org/cgi-bin/firstimage'
  url = strcompress(url + '?RA=' + rahour + '%20' + ramin + '%20' + rasec, $
    /remove_all)
  url = strcompress(url + '&Dec=' + decdeg + '%20' + decmin + '%20' + $
    decsec, /remove_all)
  url = strcompress(url + '&Equinox=J2000&ImageSize=' + imsize + $
    '&MaxInt=10&FITS=1&Download=1', /remove_all)

  ; now use webget to get the image
  result = webget(url)


  if (n_elements(result.image) LE 1) then begin
    self->message, result.text, msgtype='error', /window
    return
  endif else begin  ; valid image
    gpitv, result.image, header=result.imageheader
    result.header = ''
    result.text =  ''
    result.imageheader = ''
    result.image = ''
  endelse

end

;-----------------------------------------------------------------
;-----------------------------------------------------------------

pro gpitv::getradec, rastring, decstring, ra, dec

  ; converts ra and dec strings in hh:mm:ss and dd:mm:ss to decimal degrees


  rtmp = rastring
  pos = strpos(rtmp, ':')
  if (pos EQ -1) then pos = strlen(rtmp)
  rahour = strmid(rtmp, 0, pos)
  rtmp = strmid(rtmp, pos+1)
  pos = strpos(rtmp, ':')
  if (pos EQ -1) then pos = strlen(rtmp)
  ramin = strmid(rtmp, 0, pos)
  rtmp = strmid(rtmp, pos+1)
  rasec = rtmp


  dtmp = decstring
  pos = strpos(dtmp, ':')
  if (pos EQ -1) then pos = strlen(dtmp)
  decdeg = strmid(dtmp, 0, pos)
  dtmp = strmid(dtmp, pos+1)
  pos = strpos(dtmp, ':')
  if (pos EQ -1) then pos = strlen(dtmp)
  decmin = strmid(dtmp, 0, pos)
  dtmp = strmid(dtmp, pos+1)
  decsec = dtmp

  ra = 15.0 * ten([rahour, ramin, rasec])
  dec = ten([decdeg, decmin, decsec])


end


;-----------------------------------------------------------------------
;     Routines for creating output graphics
;-----------------------------------------------------------------------

pro GPItv::writefits

  ; Writes image to a FITS file
  ; If a 3D image, the option to save either the current 2D display or
  ; the entire cube is possible


  ; Get filename to save image
  at_gemini = gpi_get_setting('at_gemini', /bool,default=0,/silent)
  if keyword_set(at_gemini) then filter='S20'+gpi_datestr(/current)+"S*.fits" else filter ='*.fits'
  filename = dialog_pickfile(filter = filter, $
    file = 'GPItv.fits', $
    dialog_parent =  (*self.state).base_id, $
    path = (*self.state).output_dir, $
    get_path = tmp_dir, $
    /write)

  IF (tmp_dir NE '') THEN (*self.state).output_dir = tmp_dir

  IF (strcompress(filename, /remove_all) EQ '') then RETURN   ; cancel

  IF (filename EQ (*self.state).output_dir) then BEGIN
    self->message, 'Must indicate filename to save.', msgtype = 'error', /window
    return
  ENDIF

  ;----------------------------------------DGW 29 August 2005
  ;Error trap code taken from GPItv_writePS
  tmp_result = findfile(filename, count = nfiles)

  result = ''
  if (nfiles GT 0) then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = strmid(filename, strpos(filename, '/') + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
      /default_no, $
      dialog_parent = (*self.state).base_id, $
      /question)
  endif

  if (strupcase(result) EQ 'NO') then return
  ;----------------------------------------DGW 29 August 2005

  header=(*(*self.state).head_ptr)

  IF ((*self.state).image_size[2] eq 1) THEN BEGIN
    writefits, filename, *self.images.main_image,header

  ENDIF ELSE BEGIN
    formdesc = ['0, button, Write Current Image Slice, quit', $
      '0, button, Write All Image Slices, quit', $
      '0, button, Cancel, quit']

    textform = cw_form(formdesc, /column, $
      title = 'Select Image to Write')

    IF (textform.tag0 eq 1) THEN writefits, filename, *self.images.main_image,header
    IF (textform.tag1 eq 1) THEN writefits, filename, *self.images.main_image_stack
    IF (textform.tag2 eq 1) THEN return

  ENDELSE

end

;-----------------------------------------------------------------------

pro GPItv::saveimage, file, $ ;;bmp=bmp, png=png, pict=pict, jpeg=jpeg, tiff=tiff, $
  quality=quality, dither=dither, cube=cube, quiet=quiet, output=output,$
  full_image=full_image


  ; This program is a copy of Liam E. Gumley's SAVEIMAGE program,
  ; modified for use with atv/GPItv.
  ;
  ; Keywords:
  ;
  ;   output = string for file output type. "JPEG",'PNG','BMP' etc.
  ;   /full_image		set to write out entire current image, not just current view


  ;------------------------------------------------------------------------
  ;- CHECK INPUT
  ;------------------------------------------------------------------------

  ;- Check arguments
  if (n_params() ne 1) then begin
    self->message, msgtype = 'error','Usage: GPItv->SAVEIMAGE, FILE'
    return
  endif
  if (n_elements(file) ne 1) then begin
    self->message, msgtype = 'error', 'Argument FILE must be a scalar string.'
    return
  endif

  ;- Check keywords
  if ~(keyword_set(output)) then output = 'PNG'
  ;if keyword_Set(png)  then output = 'PNG'
  ;if keyword_set(bmp)  then output = 'BMP'
  ;if keyword_set(pict) then output = 'PICT'
  ;if keyword_set(jpeg) then output = 'JPEG'
  ;if keyword_set(tiff) then output = 'TIFF'
  if (n_elements(quality) eq 0) then quality = 75





  ;- Check for TVRD capable device
  if ((!d.flags and 128)) eq 0 then begin
    self->message, msgtype = 'error', 'Unsupported graphics device'
    return
  endif

  ;- Check for open window
  if ((!d.flags and 256) ne 0) &&  (!d.window lt 0) then begin
    self->message, msgtype = 'error', 'No graphics windows are open'
  endif

  ;- Get display depth
  depth = 8
  if (!d.n_colors gt 256) then depth = 24


  ;-------------------------- MDP additions to use Z-buffer to output full image
  if keyword_set(full_image) then begin
    image = *self.images.scaled_image
  endif else begin
    ;-------------------------- end of MDP additions to use Z-buffer to output full image

    ;-------------------------------------------------------------------------
    ;- GET CONTENTS OF GRAPHICS WINDOW
    ;-------------------------------------------------------------------------

    ;- Handle window devices (other than the Z buffer)
    if (!d.flags and 256) ne 0 then begin

      ;- Copy the contents of the current display to a pixmap
      current_window = !d.window
      xsize = !d.x_size
      ysize = !d.y_size
      window, /free, /pixmap, xsize=xsize, ysize=ysize, retain=2
      device, copy=[0, 0, xsize, ysize, 0, 0, current_window]

      ;- Set decomposed color mode for 24-bit displays
      version = float(!version.release)
      if (depth gt 8) then begin
        if (version gt 5.1) then device, get_decomposed=entry_decomposed
        device, decomposed=1
      endif

    endif

    ;- Read the pixmap contents into an array
    if (depth gt 8) then begin
      image = tvrd(order=0, true=1)
    endif else begin
      image = tvrd(order=0)
    endelse

    ;- Handle window devices (other than the Z buffer)
    if (!d.flags and 256) ne 0 then begin

      ;- Restore decomposed color mode for 24-bit displays
      if (depth gt 8) then begin
        if (version gt 5.1) then begin
          device, decomposed=entry_decomposed
        endif else begin
          device, decomposed=0
          if (keyword_set(quiet) eq 0) then $
            self->message, msgtype = 'warning', 'Decomposed color was turned off'
        endelse
      endif

      ;- Delete the pixmap
      wdelete, !d.window
      wset, current_window

    endif

  endelse

  ;- Get the current color table
  tvlct, r, g, b, /get

  ;- If an 8-bit image was read, reduce the number of colors
  if (depth le 8) then begin
    reduce_colors, image, index
    r = r[index]
    g = g[index]
    b = b[index]
  endif

  ;-----------------------------------------------------------------------
  ;- WRITE OUTPUT FILE
  ;-----------------------------------------------------------------------

  case 1 of

    ;- Save the image in 8-bit output format
    (output eq 'BMP') or $
      (output eq 'PICT') or (output eq 'PNG') : begin

      if (depth gt 8) and (output ne 'PNG') then begin

        ;- Convert 24-bit image to 8-bit
        case keyword_set(cube) of
          0 : image = color_quan(image, 1, r, g, b, colors=256, $
            dither=keyword_set(dither))
          1 : image = color_quan(image, 1, r, g, b, cube=6)
        endcase

        ;- Sort the color table from darkest to brightest
        table_sum = total([[long(r)], [long(g)], [long(b)]], 2)
        table_index = sort(table_sum)
        image_index = sort(table_index)
        r = r[table_index]
        g = g[table_index]
        b = b[table_index]
        oldimage = image
        image[*] = image_index[temporary(oldimage)]

      endif

      ;- Save the image
      case output of
        'BMP'  : write_bmp,  file, image, r, g, b
        'PNG'  : write_png,  file, image, r, g, b
        'PICT' : write_pict, file, image, r, g, b
      endcase

    end

    ;- Save the image in 24-bit output format
    (output eq 'JPEG') or (output eq 'TIFF') : begin

      ;- Convert 8-bit image to 24-bit
      if (depth le 8) then begin
        info = size(image)
        nx = info[1]
        ny = info[2]
        true = bytarr(3, nx, ny)
        true[0, *, *] = r[image]
        true[1, *, *] = g[image]
        true[2, *, *] = b[image]
        image = temporary(true)
      endif

      ;- If TIFF format output, reverse image top to bottom
      if (output eq 'TIFF') then image = reverse(temporary(image), 3)

      ;- Write the image
      case output of
        'JPEG' : write_jpeg, file, image, true=1, quality=quality
        'TIFF' : write_tiff, file, image, 1
      endcase

    end

  endcase

  ;- Print information for the user
  if ~keyword_set(quiet) then $
    self->message, msgtype='information', string(file, output, format='("Created ",a," in ",a," format")')
end

;----------------------------------------------------------------------
pro GPItv::SaveToVariable, thingname
  ;; Added by Marshall Perrin, based on code from Dave Fanning's
  ;; XSTRETCH.PRO


  case thingname of
    "Image": thing= *self.images.main_image
    "Cube": thing =  *self.images.main_image_stack
    "Header": begin
      if ptr_valid((*self.state).head_ptr) then thing = *((*self.state).head_ptr) $
      else begin
        self->message,'No FITS header to save! There is no FITS header currently loaded in GPItv.', msgtype='error', /window
        return
      endelse
    end
  endcase

  varname = TextBox(Title='Provide Main-Level Variable Name...', Group_Leader=(*self.state).base_id, $
    Label=thingname+' Variable Name: ', Cancel=cancelled, XSize=200, Value=thingname)
  ;; Dave Fanning says:
  ;;
  ;; The ROUTINE_NAMES function is not documented in IDL,
  ;; so it may not always work. This capability has been
  ;; tested in IDL versions 5.3 through 5.6 and found to work.
  ;; People with IDL 6.1 and higher should use SCOPE_VARFETCH to
  ;; set main-level variables. I use the older, undocumented version
  ;; to stay compatible with more users.

  IF NOT cancelled THEN BEGIN
    dummy = Routine_Names(varname, thing, Store=1)
  ENDIF
  (SCOPE_VARFETCH(varname,  LEVEL=1)) = thing  ;;JM added

  save, thing, filename=thingname+'.sav'
end

;----------------------------------------------------------------------

pro GPItv::writeimage_event, event
  ;;
  ;; HISTORY:  Updated 2012-12-04 MP to add option to write out either
  ;;				image current view or full 2D image file with current stretch.
  ;;				Some simplifications to arcane and ancient saveimage code too,
  ;;				which is needlessly convoluted on modern systems.

  @gpitv_err

  CASE event.tag OF

    'FORMAT': BEGIN

      widget_control,(*(*self.state).writeimage_ids_ptr)[2], get_value=filename
      tagpos = strpos(filename, '.', /reverse_search)
      filename = strmid(filename,0,tagpos)

      CASE event.value OF

        '0': BEGIN
          filename = filename + '.jpg'
          widget_control,(*(*self.state).writeimage_ids_ptr)[2], set_value=filename
          (*self.state).writeformat = 'JPEG'
        END

        '1': BEGIN
          filename = filename + '.tiff'
          widget_control,(*(*self.state).writeimage_ids_ptr)[2], set_value=filename
          (*self.state).writeformat = 'TIFF'
        END

        '2': BEGIN
          filename = filename + '.bmp'
          widget_control,(*(*self.state).writeimage_ids_ptr)[2], set_value=filename
          (*self.state).writeformat = 'BMP'
        END

        '3': BEGIN
          filename = filename + '.pict'
          widget_control,(*(*self.state).writeimage_ids_ptr)[2], set_value=filename
          (*self.state).writeformat = 'PICT'
        END

        '4': BEGIN
          filename = filename + '.png'
          widget_control,(*(*self.state).writeimage_ids_ptr)[2], set_value=filename
          (*self.state).writeformat = 'PNG'
        END

      ENDCASE
    END

    'FILE': BEGIN
      widget_control,(*(*self.state).writeimage_ids_ptr)[2], get_value=filename
      slash_pos = strpos(filename, path_sep(), /reverse_search)
      if(slash_pos eq -1) then begin
        directory = (*self.state).output_dir
      endif else begin
        directory = strmid(filename, 0,slash_pos)
        filename = strmid(filename, slash_pos+1)
      endelse

      dext = strlowcase((*self.state).writeformat)
      fname = dialog_pickfile(/write, file=filename,path=directory,default_extension=dext)
      ;;if canceled then bail
      if fname eq '' then begin
        widget_control,(*(*self.state).writeimage_ids_ptr)[2], set_value=directory+path_sep()+filename
        return
      endif

      ;;if null
      slash_pos = strpos(fname, path_sep(), /reverse_search)
      final_pos = strpos(fname, '', /reverse_search)

      ;;if no filename then bail out
      if (slash_pos eq final_pos) then begin
        widget_control,(*(*self.state).writeimage_ids_ptr)[2], set_value=directory+path_sep()+filename
        return
      endif

      directory =  strmid(fname, 0,slash_pos+1)
      filename = strmid(fname, slash_pos+1)
      (*self.state).output_dir = directory

      widget_control,(*(*self.state).writeimage_ids_ptr)[2], set_value=directory+filename

    END

    'WHICHREGION': BEGIN
      CASE event.value OF
        '0': (*self.state).writewhat = 'view'
        '1': (*self.state).writewhat = 'full'
        else: self->message, msgtype='error', 'Unknown item to write:'+string(event.value)
      endcase
    END

    'FILETEXT': BEGIN ; PH 29 Aug. 2005
    END               ; PH 29 Aug. 2005

    'WRITE' : BEGIN

      self->setwindow, (*self.state).draw_window_id

      widget_control,(*(*self.state).writeimage_ids_ptr)[0]
      widget_control,(*(*self.state).writeimage_ids_ptr)[2], get_value=filename
      filename = filename[0]

      ;----------------------------------------DGW 29 August 2005
      ;Error trap code taken from GPItv_writePS
      tmp_result = findfile(filename, count = nfiles)

      result = ''
      if (nfiles GT 0) then begin
        mesg = strarr(2)
        mesg[0] = 'Overwrite existing file:'
        tmp_string = strmid(filename, strpos(filename, '/') + 1)
        mesg[1] = strcompress(tmp_string + '?', /remove_all)
        result =  dialog_message(mesg, $
          /default_no, $
          dialog_parent = (*self.state).base_id, $
          /question)
      endif

      if (strupcase(result) EQ 'NO') then return
      ;----------------------------------------DGW 29 August 2005

      self->saveimage, filename, output = (*self.state).writeformat, full_image = ((*self.state).writewhat eq 'full')
      ;CASE (*self.state).writeformat OF
      ;'JPEG': self->saveimage, filename, /jpeg
      ;'TIFF': self->saveimage, filename, /tiff
      ;'BMP':  self->saveimage, filename, /bmp
      ;'PICT': self->saveimage, filename, /pict
      ;'PNG':  self->saveimage, filename, /png
      ;ENDCASE

      self->resetwindow
      (*self.state).writeformat = 'PNG' ; go back to default for next invocation
      (*self.state).writewhat= 'view' ; go back to default for next invocation

      if ptr_valid((*self.state).writeimage_ids_ptr) then $
        ptr_free, (*self.state).writeimage_ids_ptr
      widget_control, event.top, /destroy
    END

    'QUIT': BEGIN
      (*self.state).writeformat = 'JPEG'
      if ptr_valid((*self.state).writeimage_ids_ptr) then $
        ptr_free, (*self.state).writeimage_ids_ptr
      widget_control, event.top, /destroy
    END
  ENDCASE

end

;------------------------------------------------------------------------------

pro GPItv::writeimage

  ; Front-end widget to write display image to output


  writeimagebase = widget_base(/row)

  fname = (*self.state).imagename
  fname = strmid(fname,strpos(fname,path_sep(),/reverse_search)+1,$
    strpos(fname,'.fits')-strpos(fname,path_sep(),/reverse_search)-1)
  if strcmp(fname,'') then fname = 'gpitv'
  fname=(*self.state).output_dir+path_sep()+fname+'-image.png'

  formdesc = ['0, droplist, JPEG|TIFF|BMP|PICT|PNG,label_left=FileFormat:,set_value=4, TAG=format ', $
    '1, base, , row', $
    '0, button, Choose..., TAG=file ', $
    '2, text, '+fname+', width=75, TAG=filetext', $
    '1, base, , row', $
    '2, droplist, Current View|Entire Image, label_left=What to write:,set_value=0, TAG=whichregion ',$
    '1, base, , row', $
    '0, button, WriteImage, quit, TAG=write', $
    '0, button, Cancel, quit, TAG=quit ']

  if (*self.state).multisess GT 0 then title = "GPItv #"+strc((*self.state).multisess)+" WriteImage" else title="GPItv WriteImage"

  writeimageform = cw_form(writeimagebase,formdesc,/column, $
    title=title, IDS=writeimage_ids_ptr)

  widget_control, writeimagebase, /realize

  writeimage_ids_ptr = $
    writeimage_ids_ptr[where(widget_info(writeimage_ids_ptr,/type) eq 3 OR $
    widget_info(writeimage_ids_ptr,/type) eq 8 OR $
    widget_info(writeimage_ids_ptr,/type) eq 1)]

  if ptr_valid((*self.state).writeimage_ids_ptr) then ptr_free,(*self.state).writeimage_ids_ptr
  (*self.state).writeimage_ids_ptr = ptr_new(writeimage_ids_ptr)

  xmanager, self.xname+'writeimage', writeimagebase, /no_block
  widget_control, writeimagebase, set_uvalue={object:self, method: 'writeimage_event'}
  widget_control, writeimagebase, event_pro = 'GPItvo_subwindow_event_handler'

end

;;----------------------------------------------------------------------

pro GPItv::makemovie_event, event

  @gpitv_err

  CASE event.tag OF

    'FORMAT': BEGIN
      widget_control,(*(*self.state).makemovie_ids_ptr)[2], get_value=filename
      tagpos = strpos(filename, '.', /reverse_search)
      filename = strmid(filename,0,tagpos)

      CASE event.value OF

        '0': BEGIN
          filename = filename + '.gif'
          widget_control,(*(*self.state).makemovie_ids_ptr)[2], set_value=filename
          (*self.state).movieformat = 'GIF'
        END

        '1': BEGIN
          filename = filename + '.mpg'
          widget_control,(*(*self.state).makemovie_ids_ptr)[2], set_value=filename
          (*self.state).movieformat = 'MPEG'
        END

        '2': BEGIN
          widget_control,(*(*self.state).makemovie_ids_ptr)[2], set_value=filename
          (*self.state).movieformat = 'PNG'
        END
      ENDCASE
    END ;;format case

    'FILE': BEGIN
      widget_control,(*(*self.state).makemovie_ids_ptr)[2], get_value=filename
      slash_pos = strpos(filename, path_sep(), /reverse_search)
      if(slash_pos eq -1) then begin
        directory = (*self.state).output_dir
      endif else begin
        directory = strmid(filename, 0,slash_pos)
        filename = strmid(filename, slash_pos+1)
      endelse

      dext = (['.gif','.mpg',''])[where(strcmp((*self.state).movieformat,['GIF','MPEG','PNG']))]
      fname = dialog_pickfile(/write, file=filename,path=directory,$
        default_extension=dext,filter='*'+dext,/fix_filter)

      ;;if canceled then bail
      if fname eq '' then begin
        widget_control,(*(*self.state).makemovie_ids_ptr)[2], set_value=directory+path_sep()+filename
        return
      endif

      slash_pos = strpos(fname, path_sep(), /reverse_search)
      final_pos = strpos(fname, '', /reverse_search)

      ;;if no filename then bail out
      if (slash_pos eq final_pos) then begin
        widget_control,(*(*self.state).makemovie_ids_ptr)[2], set_value=directory+path_sep()+filename
        return
      endif

      directory =  strmid(fname, 0,slash_pos+1)
      filename = strmid(fname, slash_pos+1)
      (*self.state).output_dir = directory

      widget_control,(*(*self.state).makemovie_ids_ptr)[2], set_value=directory+filename

    END ;;end of file case

    'FPS': BEGIN
      widget_control,(*(*self.state).makemovie_ids_ptr)[3], get_value=fps
      fps = double(fps)
      (*self.state).moviefps = fps
      widget_control,(*(*self.state).makemovie_ids_ptr)[4],$
        set_value=strtrim(fps*(*self.state).image_size[2]/30.,2)
    END

    'TOTTIME': BEGIN
      widget_control,(*(*self.state).makemovie_ids_ptr)[4], get_value=tottime
      fps = round(double(tottime)*30./(*self.state).image_size[2])
      (*self.state).moviefps = fps
      widget_control,(*(*self.state).makemovie_ids_ptr)[3],$
        set_value=strtrim(fps,2)
      widget_control,(*(*self.state).makemovie_ids_ptr)[4],$
        set_value=strtrim(fps*(*self.state).image_size[2]/30.,2)
    END

    'WRITE' : BEGIN
      widget_control,(*(*self.state).makemovie_ids_ptr)[2], get_value=filename
      filename = filename[0]
      pos = strpos(filename,'/',/reverse_search)
      if pos ne -1 then begin
        path = expand_path(strmid(filename,0,pos))
        if not file_test(path,/dir) then begin
          self->message, msgtype='error', 'Invalid path.'
          return
        endif
      endif

      ;;Error trap code taken from GPItv_writePS
      tmp_result = findfile(filename, count = nfiles)

      result = ''
      if (nfiles GT 0) then begin
        mesg = strarr(2)
        mesg[0] = 'Overwrite existing file:'
        tmp_string = strmid(filename, strpos(filename, '/') + 1)
        mesg[1] = strcompress(tmp_string + '?', /remove_all)
        result =  dialog_message(mesg, $
          /default_no, $
          dialog_parent = (*self.state).base_id, $
          /question)
      endif

      if (strupcase(result) EQ 'NO') then return

      ;;get the current colortable
      tvlct,r1,g1,b1,/get

      ;; ignore the channels we're using for gpitv overplotting colors
      r1[0:8] = 0
      g1[0:8] = 0
      b1[0:8] = 0

      ;;scale all of the image slices
      tmp = *self.images.main_image_stack
      for j=0,(*self.state).image_size[2]-1 do begin
        self->scaleimage,imin=tmp[*,*,j],imout=imout
        tmp[*,*,j] = imout
      endfor

      ;; imout should have all counts >8 for valid pixels.
      ;; This is because those 8 channels are reserved for overplot
      ;; colors, due to legacy code.


      ;; Catch any pixels that didn't get flagged here...
      ;;wlow = where((tmp gt 0) and (tmp lt 8),lowct)
      ;;if lowct gt 0 then tmp[wlow] = 0
      ;; FIXME this does not appear to be working right??

      if ptr_valid((*self.state).cwv_ptr) then lambdas=*(*self.state).cwv_ptr
      ;;do the writing here
      ifs_cube_movie,tmp,outname=filename,/prescaled,$
        r = r1, g = g1, b = b1,$
        fps=(*self.state).moviefps,$
        lambdas = lambdas, $
        mpeg=long(strcmp((*self.state).movieformat,'MPEG')),$
        png=long(strcmp((*self.state).movieformat,'PNG'))

      if ptr_valid((*self.state).makemovie_ids_ptr) then $
        ptr_free, (*self.state).makemovie_ids_ptr
      widget_control, event.top, /destroy
    END

    'QUIT': BEGIN
      if ptr_valid((*self.state).makemovie_ids_ptr) then $
        ptr_free, (*self.state).makemovie_ids_ptr
      widget_control, event.top, /destroy
    END
    ELSE:
  ENDCASE

end

;----------------------------------------------------------------------------
pro GPItv::makemovie
  ; Front-end widget to write cube animation


  makemoviebase = widget_base(/row)

  fname = (*self.state).imagename
  fname = strmid(fname,strpos(fname,path_sep(),/reverse_search)+1,$
    strpos(fname,'.fits')-strpos(fname,path_sep(),/reverse_search)-1)
  if strcmp(fname,'') then fname = 'gpitv'
  fname=(*self.state).output_dir+path_sep()+fname+'-movie.gif'

  formatdef = long(strcmp((*self.state).movieformat,'MPEG'))
  fpsdef = (*self.state).moviefps
  timedef = fpsdef*(*self.state).image_size[2]/30.


  formdesc = ['0, droplist, GIF|MPEG|PNG, label_left=FileFormat:,set_value='+strtrim(formatdef,2)+', TAG=format ', $
    '1, base, , row', $
    '0, button, Choose..., TAG=file ', $
    '2, text, '+fname+', width=75, TAG=filetext', $
    '1, base, , row', $
    '0, text, '+strtrim(fpsdef,2)+', width=10, label_left=Frames/Slice,TAG=fps', $
    '2, text, '+strtrim(timedef,2)+', width=15, label_left=Time,TAG=tottime', $
    '1, base, , row', $
    '0, button, MakeMovie, quit, TAG=write', $
    '0, button, Cancel, quit, TAG=quit ']

  makemovieform = cw_form(makemoviebase,formdesc,/column, title='GPItv MakeMovie',$
    IDS=makemovie_ids_ptr)

  widget_control, makemoviebase, /realize

  tmp = widget_info(makemovie_ids_ptr,/type)
  makemovie_ids_ptr = makemovie_ids_ptr[where(tmp eq 3 OR tmp eq 8 or tmp eq 1)]

  if ptr_valid((*self.state).makemovie_ids_ptr) then ptr_free,(*self.state).makemovie_ids_ptr
  (*self.state).makemovie_ids_ptr = ptr_new(makemovie_ids_ptr)

  xmanager, self.xname+'makemovie', makemoviebase, /no_block
  widget_control, makemoviebase, set_uvalue={object:self, method: 'makemovie_event'}
  widget_control, makemoviebase, event_pro = 'GPItvo_subwindow_event_handler'

end


;----------------------------------------------------------------------

pro GPItv::writeps

  ; Writes a postscript file of the current display.
  ; Calls cmps_form to get postscript file parameters.

  view_min = round((*self.state).centerpix - $
    (0.5 * (*self.state).draw_window_size / (*self.state).zoom_factor))
  view_max = round(view_min + (*self.state).draw_window_size / (*self.state).zoom_factor)

  xsize = ((*self.state).draw_window_size[0] / (*self.state).zoom_factor) > $
    (view_max[0] - view_min[0] + 1)
  ysize = ((*self.state).draw_window_size[1] / (*self.state).zoom_factor) > $
    (view_max[1] - view_min[1] + 1)

  aspect = float(ysize) / float(xsize)
  fname = strcompress((*self.state).current_dir + 'GPItv.ps', /remove_all)

  tvlct, rr, gg, bb, 8, /get
  forminfo = cmps_form(cancel = canceled, create = create, $
    aspect = aspect, parent = (*self.state).base_id, $
    /preserve_aspect, $
    xsize = 6.0, ysize = 6.0 * aspect, $
    /color, $
    /nocommon, papersize='Letter', $
    bits_per_pixel=8, $
    filename = fname, $
    button_names = ['Create PS File'])

  if (canceled) then return
  if (forminfo.filename EQ '') then return
  tvlct, rr, gg, bb, 8

  tmp_result = findfile(forminfo.filename, count = nfiles)

  ;----------------------------------------------DGW 29 August 2005
  ;This error trap prevents the user from attempting to write a file
  ;without including a filename
  final_pos = strpos(formInfo.filename, '', /reverse_search)
  slash_pos = strpos(formInfo.filename, '/', /reverse_search)
  if final_pos eq slash_pos then begin
    self->message, 'You did not include a file name', msgtype='error',/window
    return
  endif
  ;----------------------------------------------DGW 29 August 2005

  result = ''
  if (nfiles GT 0) then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = strmid(forminfo.filename, strpos(forminfo.filename, '/') + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
      /default_no, $
      dialog_parent = (*self.state).base_id, $
      /question)
  endif

  if (strupcase(result) EQ 'NO') then return

  widget_control, /hourglass

  ;;set to postscript device
  screen_device = !d.name
  set_plot, 'ps'

  ; In 8-bit mode, the screen color table will have fewer than 256
  ; colors.  Stretch out the existing color table to 256 colors for the
  ; postscript plot.

  device, _extra = forminfo

  tvlct, rr, gg, bb, 8, /get

  rn = congrid(rr, 248)
  gn = congrid(gg, 248)
  bn = congrid(bb, 248)

  tvlct, temporary(rn), temporary(gn), temporary(bn), 8

  ; Make a full-resolution version of the display image, accounting for
  ; scalable pixels in the postscript output

  newdisplay = bytarr(xsize, ysize)

  startpos = abs(round((*self.state).offset) < 0)

  view_min = (0 > view_min < ((*self.state).image_size[0:1] - 1))
  view_max = (0 > view_max < ((*self.state).image_size[0:1] - 1))

  dimage = bytscl((*self.images.scaled_image)[view_min[0]:view_max[0], $
    view_min[1]:view_max[1]], $
    top = 247, min=8, max=(!d.table_size-1)) + 8


  newdisplay[startpos[0], startpos[1]] = temporary(dimage)

  ; if there's blank space around the image border, keep it black
  tv, newdisplay
  self->plotall

  if ((*self.state).frame EQ 1) then begin    ; put frame around image
    plot, [0], [0], /nodata, position=[0,0,1,1], $
      xrange=[0,1], yrange=[0,1], xstyle=5, ystyle=5, /noerase
    boxx = [0,0,1,1,0,0]
    boxy = [0,1,1,0,0,1]
    oplot, boxx, boxy, color=0, thick=(*self.state).framethick
  endif

  tvlct, temporary(rr), temporary(gg), temporary(bb), 8


  device, /close
  set_plot, screen_device

  self->setwindow, (*self.state).draw_window_id
end


;----------------------------------------------------------------------


pro gpitv::makergb

  ; Makes an RGB truecolor png image from the 3 blink channels.
  ; Can be saved using file->writeimage.
  ; Note- untested for 8-bit displays.  May not work there.


  if (n_elements(*self.images.blink_image1) EQ 1 OR $
    n_elements(*self.images.blink_image2) EQ 1 OR $
    n_elements(*self.images.blink_image3) EQ 1) then begin

    self->message, $
      'You need to set the 3 blink channels first to make an RGB image.', $
      msgtype = 'error', /window
    return
  endif

  self->getwindow

  window, /free, xsize = (*self.state).draw_window_size[0], $
    ysize = (*self.state).draw_window_size[1], /pixmap
  tempwindow = !d.window

  tv, *self.images.blink_image1, /true
  rimage = tvrd()
  tv, *self.images.blink_image2, /true
  gimage = tvrd()
  tv, *self.images.blink_image3, /true
  bimage = tvrd()

  tcimage = [[[rimage]], [[gimage]], [[bimage]]]

  tv, tcimage, true=3

  tvlct, rmap, gmap, bmap, /get
  image = tvrd(/true)

  wdelete, tempwindow

  self->setwindow, (*self.state).draw_window_id
  tv, image, /true
  self->resetwindow


end

;----------------------------------------------------------------------

;----------------------------------------------------------------------
;       routines for defining the color maps
;----------------------------------------------------------------------

pro GPItv::stretchct, brightness, contrast,  getmouse = getmouse

  ; routine to change color stretch for given values of
  ; brightness and contrast.
  ; Complete rewrite 2000-Sep-21 - Doug Finkbeiner
  ; This routine is now shorter and easier to understand.

  ; if GETMOUSE then assume mouse position passed; otherwise ignore inputs


  if (keyword_set(getmouse)) then begin
    (*self.state).brightness = brightness/float((*self.state).draw_window_size[0])
    (*self.state).contrast = contrast/float((*self.state).draw_window_size[1])
  endif

  x = (*self.state).brightness*((*self.state).ncolors-1)
  y = (*self.state).contrast*((*self.state).ncolors-1) > 2   ; Minor change by AJB
  high = x+y & low = x-y
  diff = (high-low) > 1

  slope = float((*self.state).ncolors-1)/diff ;Scale to range of 0 : nc-1
  intercept = -slope*low
  p = long(findgen((*self.state).ncolors)*slope+intercept) ;subscripts to select

  tvlct, self.colors.r_vector[p], self.colors.g_vector[p], self.colors.b_vector[p], 8

end

;------------------------------------------------------------------

pro GPItv::initcolors

  ; Load a simple color table with the basic 8 colors in the lowest
  ; 8 entries of the color table.  Also set top color to white.


  rtiny = [0, 1, 0, 0, 0, 1, 1, 1]
  gtiny = [0, 0, 1, 0, 1, 0, 1, 1]
  btiny = [0, 0, 0, 1, 1, 1, 0, 1]
  tvlct, 255*rtiny, 255*gtiny, 255*btiny

  tvlct, [255],[255],[255], !d.table_size-1

end
;--------------------------------------------------------------------
pro GPItv::menu_colortable_checkbox_update, name
  ; update the color table checkboxes in the menu


  if ~(keyword_set(name)) then return ; can't do anything unless we're given a name

  ;  names = ['Grayscale', 'Blue-White', 'GRBW', 'Red-White', 'BGRY', 'Standard Gamma-II', 'Prism', 'Red-Purple',$
  ;  'Green-White', 'Cyan-Blue-Red', '16 Level', 'Rainbow', 'Stern Special', 'Haze' , 'Blue-Pastel-Red', $
  ;  'Blue-Red (Jet)', 'Rainbow18', 'GPItv Special', 'Velocity1', 'Velocity2']
  names = ['Grayscale', 'Blue-White',  'Red-White', 'Green-White', 'Rainbow', 'Blue-Red (Jet)','Stern Special',$
    'GPItv Special','Velocity', 'Cubehelix', '----', 'Standard Gamma-II',  'Red-Purple','Rainbow18','BGRY','GRBW','Prism',$
    '16 Level',   'Haze' , 'Blue-Pastel-Red']


  for i=0L,n_elements(names)-1 do begin
    w = where((*self.state).menu_labels eq names[i])
    if w lt 0 then continue
    button_id = (*self.state).menu_ids[w]
    widget_control, button_id, set_button = (names[i] eq name)
  endfor


end

;--------------------------------------------------------------------


pro GPItv::getct, tablenum, name

  ; Read in a pre-defined color table, and invert if necessary.


  loadct, tablenum, /silent,  bottom=8 ; an index of 8 loads this into 8:255 = 248 elements
  tvlct, r, g, b, 8, /get

  self->initcolors ; this replaces the bottom 8 and top 1 colors.

  r = r[0:(*self.state).ncolors-1]
  g = g[0:(*self.state).ncolors-1]
  b = b[0:(*self.state).ncolors-1]

  if ((*self.state).invert_colormap EQ 1) then begin
    r = reverse(r)
    g = reverse(g)
    b = reverse(b)
  endif

  self.colors.r_vector = r
  self.colors.g_vector = g
  self.colors.b_vector = b

  self->stretchct, (*self.state).brightness, (*self.state).contrast
  if ((*self.state).bitdepth EQ 24 AND (n_elements(*self.images.pan_image) GT 10) ) then $
    self->refresh
  self->menu_colortable_checkbox_update, name

end

;--------------------------------------------------------------------

function GPItv::polycolor, p

  ; Routine to return an vector of length !d.table_size-8,
  ; defined by a 5th order polynomial.   Called by GPItv::makect
  ; to define new color tables in terms of polynomial coefficients.


  x = findgen(256)

  y = p[0] + x * p[1] + x^2 * p[2] + x^3 * p[3] + x^4 * p[4] + x^5 * p[5]

  w = where(y GT 255, nw)
  if (nw GT 0) then y[w] = 255

  w =  where(y LT 0, nw)
  if (nw GT 0) then y[w] = 0

  z = congrid(y, (*self.state).ncolors)

  return, z
end

;----------------------------------------------------------------------

pro GPItv::makect, tablename

  ; Define new color tables here.  Invert if necessary.


  case tablename of
    'GPItv Special': begin
      r = self->polycolor([39.4609, $
        -5.19434, $
        0.128174, $
        -0.000857115, $
        2.23517e-06, $
        -1.87902e-09])

      g = self->polycolor([-15.3496, $
        1.76843, $
        -0.0418186, $
        0.000308216, $
        -6.07106e-07, $
        0.0000])

      b = self->polycolor([0.000, $
        12.2449, $
        -0.202679, $
        0.00108027, $
        -2.47709e-06, $
        2.66846e-09])

    end
    'Velocity': begin
      ; simple ROYGBIV color table useful for visualizing radial velocity maps
      w = findgen(256)

      sigma = 25.
      center = 170
      r = 255.* exp(-1.*(w - center)^2 / (2.*sigma^2))
      r[center:255] = 255.
      sigma = 30.
      center = 0.
      r = r + 100.* exp(-1.*(w - center)^2 / (2.*sigma^2))

      sigma = 30.
      center1 = 100.
      g = fltarr(256)
      g[0:center1] = 255. * exp(-1.*(w[0:center1] - center1)^2 / (2.*sigma^2))
      sigma = 60.
      center2 = 140.
      g[center1:center2] = 255.
      g[center2:255] = $
        255. * exp(-1.*(w[center2:255] - center2)^2 / (2.*sigma^2))

      sigma = 40.
      center = 70
      b = 255.* exp(-1.*(w - center)^2 / (2.*sigma^2))
      b[0:center] = 255.

    end
    'Cubehelix': begin
      ; based on D. A. Green algorithm, arXiv:1108.5083 and
      ; Bull. Astr. Soc. India 39, 289 (2011).

      lambda = findgen(256) / 255.0
      phi = 2.0 * !pi * $
        ((*self.state).cubehelix_start / 3.0 + (*self.state).cubehelix_nrot * lambda)
      a = (*self.state).cubehelix_hue * lambda^((*self.state).cubehelix_gamma) * $
        (1.0 - lambda^((*self.state).cubehelix_gamma)) / 2.0

      r = lambda^((*self.state).cubehelix_gamma) + $
        a * (-0.14861 * cos(phi) + 1.78277 * sin(phi))
      g = lambda^((*self.state).cubehelix_gamma) + $
        a * (-0.29227 * cos(phi) - 0.90649 * sin(phi))
      b = lambda^((*self.state).cubehelix_gamma) + $
        a * (1.97294 * cos(phi))

      r = 0 > (r * 255.0) < 255
      g = 0 > (g * 255.0) < 255
      b = 0 > (b * 255.0) < 255
    end


    ; add more color table definitions here as needed...
    else: BEgin
      self->message, msgtype='error',  "Unknown color table name: "+tablename
      return
    endelse

  endcase

  if ((*self.state).invert_colormap EQ 1) then begin
    r = reverse(r)
    g = reverse(g)
    b = reverse(b)
  endif

  if n_elements(self.colors.r_vector) ne n_elements(r) then begin
    r = cmcongrid(r, n_elements(self.colors.r_vector), /interp)
    g = cmcongrid(g, n_elements(self.colors.g_vector), /interp)
    b = cmcongrid(b, n_elements(self.colors.b_vector), /interp)
  endif

  self.colors.r_vector = temporary(r)
  self.colors.g_vector = temporary(g)
  self.colors.b_vector = temporary(b)

  self->stretchct, (*self.state).brightness, (*self.state).contrast
  self->refresh
  self->menu_colortable_checkbox_update, tablename

end

;--------------------------------------------------------------------

pro gpitv::set_cubehelix


  if (not (xregistered(self.xname+'_cubehelix', /noshow))) then begin

    cubehelix_base = $
      widget_base(/base_align_center, $
      group_leader = (*self.state).base_id, $
      /column, $
      title = 'GPItv cubehelix settings', $
      uvalue = 'cubehelix_base')

    tmp = widget_label(cubehelix_base,value="Dave Green's Cubehelix color scheme" )
    tmp = widget_label(cubehelix_base,value="see http://www.mrao.cam.ac.uk/~dag/CUBEHELIX/" )

    (*self.state).cubehelix_start_id = cw_field(cubehelix_base, $
      /floating, $
      /return_events, $
      value = (*self.state).cubehelix_start, $
      uvalue = 'cubehelix_start', $
      title = 'Start Color (0:3)  ')

    (*self.state).cubehelix_nrot_id = cw_field(cubehelix_base, $
      /floating, $
      /return_events, $
      value = (*self.state).cubehelix_nrot, $
      uvalue = 'cubehelix_nrot', $
      title = 'Rotations  (-3:3)  ')

    (*self.state).cubehelix_hue_id = cw_field(cubehelix_base, $
      /floating, $
      /return_events, $
      value = (*self.state).cubehelix_hue, $
      uvalue = 'cubehelix_hue', $
      title = 'Hue         (0:3)  ')

    (*self.state).cubehelix_gamma_id = cw_field(cubehelix_base, $
      /floating, $
      /return_events, $
      value = (*self.state).cubehelix_gamma, $
      uvalue = 'cubehelix_gamma', $
      title = 'Gamma:      (0:3)  ')

    cubehelix_plot = widget_draw(cubehelix_base, frame=2, $
      xsize = 300, ysize = 230)

    cubehelix_buttons = widget_base(cubehelix_base, /row, /base_align_center)

    cubehelix_reset = widget_button(cubehelix_buttons, $
      value = 'Reset to Defaults', $
      uvalue = 'cubehelix_defaults')

    cubehelix_done = widget_button(cubehelix_buttons, value = 'Done', $
      uvalue = 'cubehelix_done')

    widget_control, cubehelix_base, /realize
    xmanager, self.xname+'_cubehelix', cubehelix_base, /no_block
    widget_control, cubehelix_base, set_uvalue={object: self, method: 'cubehelix_event'}
    widget_control, cubehelix_base, event_pro = 'GPItvo_subwindow_event_handler'

    widget_control, cubehelix_plot, get_value = tmp_value
    (*self.state).cubehelix_plot_id = tmp_value

    self->resetwindow

  endif

  self->cubehelix_event

end

;-------------------------------------------------------------------

pro gpitv::cubehelix_event, event

  @gpitv_err

  if (n_elements(event) GT 0) then begin
    widget_control, event.id, get_uvalue = uvalue
  endif else begin
    uvalue = 'null_event'
  endelse

  case uvalue of

    'cubehelix_start': begin
      startval = 0 > event.value < 3
      widget_control, (*self.state).cubehelix_start_id, set_value = startval
      (*self.state).cubehelix_start = startval
    end

    'cubehelix_nrot': begin
      nrot = (-3) > event.value < 3
      widget_control, (*self.state).cubehelix_nrot_id, set_value = nrot
      (*self.state).cubehelix_nrot = nrot
    end

    'cubehelix_hue':  begin
      hue = 0 > event.value < 3
      widget_control, (*self.state).cubehelix_hue_id, set_value = hue
      (*self.state).cubehelix_hue = hue
    end

    'cubehelix_gamma': begin
      gamma = 0 > event.value < 3
      widget_control, (*self.state).cubehelix_gamma_id, set_value = gamma
      (*self.state).cubehelix_gamma = gamma
    end

    'cubehelix_defaults': begin
      (*self.state).cubehelix_start = 0.5
      (*self.state).cubehelix_nrot = -1.5
      (*self.state).cubehelix_hue = 1.0
      (*self.state).cubehelix_gamma = 1.0
      widget_control, (*self.state).cubehelix_start_id, $
        set_value = (*self.state).cubehelix_start
      widget_control, (*self.state).cubehelix_nrot_id, $
        set_value = (*self.state).cubehelix_nrot
      widget_control, (*self.state).cubehelix_hue_id, $
        set_value = (*self.state).cubehelix_hue
      widget_control, (*self.state).cubehelix_gamma_id, $
        set_value = (*self.state).cubehelix_gamma
      (*self.state).invert_colormap = 0
    end

    'cubehelix_done': widget_control, event.top, /destroy

    else:
  endcase

  if (xregistered(self.xname+'_cubehelix')) then begin

    self->makect, 'Cubehelix'

    self->setwindow, (*self.state).cubehelix_plot_id
    xvector = findgen(256)
    cgplot, [0], [0], /nodata, xrange = [0,255], yrange = [0,255], $
      xtitle = 'Colormap Level', ytitle = 'Intensity', charsize=1.0, $
      xstyle=1, ystyle=1, position = [40, 80, 290, 220], $
      /device
    cgplot, xvector, xvector, /overplot, color = 'black', thick=1
    cgplot, xvector, self.colors.r_vector, /overplot, color = 'red', thick=2
    cgplot, xvector, self.colors.g_vector, /overplot, color = 'green', thick=2
    cgplot, xvector, self.colors.b_vector, /overplot, color = 'blue', thick=2

    xsize = 256
    ysize = 30
    b = congrid( findgen((*self.state).ncolors), xsize)
    c = replicate(1, ysize)
    a = b # c

    tvlct, self.colors.r_vector, self.colors.g_vector, self.colors.b_vector

    ;cgimage, a, 40, 10, /tv, /noerase
    tv, a, 40, 10;, /tv;, /noerase
    cgplot, [0],[0], /nodata, /noerase, position = [40, 10, 290, 40], $
      /device, xticks=1, xminor=1, yticks=1, yminor=1, $
      xtickname = [' ',' '], ytickname = [' ',' ']

    self->resetwindow
  endif

end
;----------------------------------------------------------------------

function GPItv::icolor, color

  ; Routine to reserve the bottom 8 colors of the color table
  ; for plot overlays and line plots.


  if (n_elements(color) EQ 0) then return, 1

  ncolor = N_elements(color)

  ; If COLOR is a string or array of strings, then convert color names
  ; to integer values
  if (size(color,/tname) EQ 'STRING') then begin ; Test if COLOR is a string

    ; Detemine the default color for the current device
    if (!d.name EQ 'X') then defcolor = 7 $ ; white for X-windows
    else defcolor = 0           ; black otherwise

    icolor = 0 * (color EQ 'black') $
      + 1 * (color EQ 'red') $
      + 2 * (color EQ 'green') $
      + 3 * (color EQ 'blue') $
      + 4 * (color EQ 'cyan') $
      + 5 * (color EQ 'magenta') $
      + 6 * (color EQ 'yellow') $
      + 7 * (color EQ 'white') $
      + defcolor * (color EQ 'default')

  endif else begin
    icolor = long(color)
  endelse

  return, icolor
end

;---------------------------------------------------------------------
;    routines dealing with image header, title, and related info
;--------------------------------------------------------------------

pro GPItv::settitle

  ; Update title bar with the image file name


  (*self.state).window_title = 'GPItv'
  if (*self.state).multisess GT 0 then (*self.state).window_title += " #"+strc((*self.state).multisess)
  if (strlen((*self.state).imagename) GT 0) then begin
    (*self.state).window_title+= ":  "
    fname = (*self.state).imagename
    if ~(*self.state).showfullpaths then begin
      sysslash = path_sep()
      tmp = strpos((*self.state).imagename,sysslash,/reverse_search)
      if tmp ne -1 then fname = strmid((*self.state).imagename,tmp+1)
      if strcmp(strmid(fname,strlen(fname)-1),')') then fname = strmid(fname, 0,strlen(fname)-1)
    endif

    (*self.state).window_title += fname
  endif
  if (strlen((*self.state).title_extras) GT 0) then (*self.state).window_title += " - " + (*self.state).title_extras

  widget_control, (*self.state).base_id, tlb_set_title = (*self.state).window_title

end

;----------------------------------------------------------------------
pro GPItv::setheadinfo, noresize=noresize
  ;+
  ;  Update header info displayed at top of gpitv window
  ;  This routine should be called whenever a new image is loaded, and will update
  ;  the displayed information AND ALSO GPITV MODE SETTINGS.
  ;
  ; MDP note 2008-10-20: The following code will make the various text fields auto
  ; resize. Therefore, once they're done, call self->resize to update the draw
  ; window size accordingly.
  ;
  ; 2012-09-13 the head input is not used since we're relying on
  ; the head_ptr, so the input is deprecated. - ds
  ;-

  max_display_len = 12

  nodirpos=STRPOS((*self.state).imagename, PATH_SEP(), /REVERSE_SEARCH)
  nodir=STRMID((*self.state).imagename,nodirpos+1, STRLEN((*self.state).imagename))
  if strcmp(strmid(nodir,strlen(nodir)-1),')') then nodir = strmid(nodir, 0,strlen(nodir)-1)
  widget_control, (*self.state).imagename_id,set_value=nodir
  h = *((*self.state).head_ptr)
  if n_elements(h) lt 2 then begin
    self->message, msgtype='error', 'No info in header.'
    return
  endif
  if ptr_valid( (*self.state).exthead_ptr ) then e = *((*self.state).exthead_ptr) else e = ['']

  ; if we're loading a dummy header for a null image because the
  ; user started gpitv without specifying an image yet, then
  ; don't print any errors about missing keywords in the following.
  silent = ((*self.state).imagename eq "NO IMAGE LOADED   ") ; must match dummy image name assigned in ::init

  val = gpi_get_keyword(h, e, 'DATE-OBS',count=cc, silent=silent)
  if cc gt 0 then widget_control, (*self.state).dateobs_id, set_value = val else $
    widget_control, (*self.state).dateobs_id, set_value = 'No info'
  val = gpi_get_keyword(h, e, 'UTSTART',count=cc, silent=silent)
  if cc eq 0 then val = gpi_get_keyword(h, e,  'TIME-OBS',count=cc, silent=silent)
  if cc gt 0 then widget_control, (*self.state).timeobs_id, set_value = val else $
    widget_control, (*self.state).timeobs_id, set_value = 'No info'
  val = gpi_simplify_keyword_value(gpi_get_keyword(h, e, 'IFSFILT',count=cc, silent=silent))
  if cc gt 0 then widget_control, (*self.state).filter1_id, set_value = val else $
    widget_control, (*self.state).filter1_id, set_value = 'No info'
  if cc gt 0 then (*self.state).obsfilt=strcompress(val,/REMOVE_ALL) else (*self.state).obsfilt=''
  ;val = gpi_get_keyword(h, e, 'FILETYPE',count=cc)
  ;if cc gt 0 then (*self.state).filetype = val else (*self.state).filetype = ''



  val = gpi_get_keyword(h, e, 'DISPERSR',count=cc, silent=silent)
  ;; Make short prism names. Bizarre inexplicable bug where long Gemini style names make widgets get smaller?!?! WTF? -MP
  if cc gt 0 then begin
    if size(val,/TNAME) ne 'STRING' then val = strc(val)
    if strmid(val,0,4) eq 'DISP' then val = (strsplit(val,'_',/extract))[1]


    if val eq 'WOLLASTON' then begin
      ; add in WPANGLE too
      val += ", "+strc(string(gpi_get_keyword(h, e, 'WPANGLE', silent=silent), format='(F6.1)'))
    endif

    widget_control, (*self.state).filter2_id, set_value = strc(val)
  endif else widget_control, (*self.state).filter2_id, set_value = 'No info'

  ;; actual exposure time
  itime = gpi_get_keyword(h, e, 'ITIME',count=cce, silent=silent)
  if cce gt 0 then  (*self.state).itime = itime else  (*self.state).itime = 0
  widget_control, (*self.state).exptime_id, set_value = STRING(itime,format='(f10.2)')

  ;; coadds
  val=STRING(gpi_get_keyword(h, e, 'COADDS',count=cca, silent=silent),format='(I4)')
  if cca gt 0 then (*self.state).coadds=double(gpi_get_keyword(h, e, 'COADDS', silent=silent)) else (*self.state).coadds=0.

  ;; object name
  val=gpi_get_keyword(h, e, 'OBJECT',count=cc, silent=silent)
  val = strmid(val, 0, max_display_len)
  if val eq "" then val='No info'
  if cc gt 0 then widget_control, (*self.state).object_id, set_value = val else $
    widget_control, (*self.state).object_id, set_value = 'No info'

  val=gpi_get_keyword(h, e, 'OBSTYPE',count=cc,/silent)
  val = strmid(val, 0, max_display_len)
  ;; special case for arc lamps: append the GCAL lamp name
  if strc(val) eq 'ARC' then val='ARC - '+strc(gpi_get_keyword(h, e,'GCALLAMP'))
  if strc(val) eq 'FLAT' then begin
    gcallamp = gpi_get_keyword(h, e,'GCALLAMP')
    val='FLAT - '+strc(gpi_get_keyword(h, e,'GCALLAMP'))+ ","+strc(strmid(gpi_get_keyword(h, e,'GCALFILT'),0,3))
    ; special case the 'closed' IRlamp we use for GCAL backgrounds
    if gcallamp eq 'IRhigh' then if gpi_get_keyword(h, e,'GCALSHUT') eq 'CLOSED' then val='FLAT- CLOSED'
  endif

  if cc gt 0 then begin
    val = strmid(val,0,12)
    widget_control, (*self.state).obstype_id, set_value = val
  endif else  widget_control, (*self.state).obstype_id, set_value = 'No info'

  ;;val=gpi_get_keyword(h, e, 'OBSCLASS',count=cc)
  ;;if cc gt 0 then widget_control, (*self.state).obsclass_id, set_value = val else widget_control, (*self.state).obsclass_id, set_value = 'No info'

  val = gpi_get_keyword(h, e, 'SAMPMODE',count=cc, silent=silent)
  if cc gt 0 then begin
    if size(val,/TNAME) ne 'STRING' then begin
      ;; convert readout mode as a string
      readmodes = ['', 'Single', 'CDS','MCDS', 'UTR']
      readmodestr = readmodes[val]
    endif
    if val eq 3 then readmodestr += "-"+strc(gpi_get_keyword(h, e,'READS')/2) ; convert from total reads to read pairs for MCDS
    if val eq 4 then readmodestr += "-"+strc(gpi_get_keyword(h, e,'READS'))
    ncoadds = gpi_get_keyword(h, e, 'COADDS')
    if ncoadds gt 1 then readmodestr += " *"+strc(gpi_get_keyword(h, e,'COADDS'))
  endif else readmodestr = 'No info'
  widget_control, (*self.state).readmode_id, set_value = readmodestr


  ;;apodizer - which apodizer is selected is used to look up the
  ; satellite spot flux ratios
  val = gpi_get_keyword(h, e, 'APODIZER',count=cc, silent=silent)
  if cc eq 0 then (*self.state).gridfac = !values.f_nan else begin
    ;;hack to account for user defined apodizer
    if strcmp(val,'UNKNOWN',/fold_case) then begin
      val = gpi_get_keyword(h, e, 'OCCULTER',count=cc)
      if cc ne 0 then begin
        res = stregex(val,'FPM_([A-Za-z])',/extract,/subexpr)
        if res[1] ne '' then val = res[1]
      endif
    endif
    (*self.state).gridfac = gpi_get_gridfac(val)
  endelse

  if xregistered(self.xname+'_contrprof',/noshow) then $
    widget_control,(*self.state).contrgridfac_id,set_value=strtrim((*self.state).gridfac,2)

  ;;scl
  void=gpi_get_keyword(h, e, 'FSCALE0',COUNT=cc,/silent)
  nax3= uint(gpi_get_keyword(h, e, "NAXIS3", count=cw4,/silent))
  if cc gt 0 then begin
    for zz=0,nax3-1 do (*self.state).flux_calib_convfac[zz] =  $
      double(strcompress(gpi_get_keyword(h, e, 'FSCALE'+strc(zz)),/remove_all))/((*self.state).itime)
    ; reset units list to default values - in case it was set to 'unknown' by
    ; loading a file with no units defined or an unsupported unit.
    *(*self.state).unitslist = ['ADU per coadd', 'ADU/s','ph/s/nm/m^2', 'Jy', 'W/m^2/um','ergs/s/cm^2/A','ergs/s/cm^2/Hz']
  endif else begin
    (*self.state).flux_calib_convfac=1.
    ; we have no flux calibration information, so we can only support units in
    ; ADU and ADU/s
    *(*self.state).unitslist = ['ADU per coadd', 'ADU/s']
  endelse


  ;units of data are in the BUNIT keyword
  void=gpi_get_keyword(h, e, 'BUNIT',COUNT=cu, silent=silent)
  if cu eq 1 then begin
    (*self.state).intrinsic_units=strtrim(gpi_get_keyword(h, e, 'BUNIT'), 2)

    ;;special case: check for earlier GPI convention of 'counts' instead of 'ADU' in unit names, and convert
    if strcmp((*self.state).intrinsic_units,'Counts',/fold_case) then (*self.state).intrinsic_units='ADU per coadd'

    ; check if current unit is in the list of known units.
    if total(strmatch(*(*self.state).unitslist, (*self.state).intrinsic_units,/fold_case)) eq 0 then begin
      ; current unit is not in list of known units, so replace list.
      *(*self.state).unitslist = [(*self.state).intrinsic_units]
    endif

  endif else begin
    ;;no units found in header
    (*self.state).intrinsic_units='Unknown'
    *(*self.state).unitslist = ['Unknown']
  endelse

  ; update the drop list to the current list of known units, and update the
  ; selection accordingly
  if keyword_set((*self.state).retain_current_stretch) then if ((*self.state).current_units ne (*self.state).intrinsic_units) then prior_retained_units = (*self.state).current_units
  (*self.state).current_units = (*self.state).intrinsic_units

  ind = where(STRCMP(  *(*self.state).unitslist,(*self.state).current_units))
  widget_control, (*self.state).units_droplist_id, set_droplist_select = ind, set_value=*(*self.state).unitslist

  ;; -- Are we loading a data cube? If so, configure the
  ;; spectral/polarization/whatever axis.
  naxis = fix(gpi_get_keyword(h, e,'NAXIS',/silent))
  if naxis eq 3 then begin
    ;; --- Does this FITS header specify either a WAVELENGTH or a STOKES stack?
    mode = strc(gpi_get_keyword(h, e, "CTYPE3", count=mct) )

    ; In accordance with Gemini standard, preferentially look to CD3_3 for the
    ; wavelength axis step size, but fall back to CDELT3 for compatibility with
    ; earlier GPI data products.  - MP 2012-12-09
    cd3 = gpi_get_keyword(h, e, "CD3_3", count=cw1) ;wav increm
    if cw1 eq 0 then cd3 = gpi_get_keyword(h, e, "CDELT3", count=cw1) ;wav increm

    ; for pixel coordinates, recall these must be in the FITS convention where
    ; pixel indices start at 1, not 0.
    crpix3 = gpi_get_keyword(h, e, "CRPIX3", count=cw2) ;pix coord. of ref. point
    ctype3 = strc(gpi_get_keyword(h, e, "CTYPE3", count=mct))
    if (crpix3 eq 0) and (ctype3 ne 'STOKES') then begin
      message, 'Wavelength reference pixel CRPIX3 is 0, outside of the actual datacube',/info
      message, 'Assuming this is an older non-FITS-WCS compliant header and guessing that ',/info
      message, 'CRPIX=1 for the first spectral slice is what was actually meant.',/info
      crpix3=1
    endif

    crval3 = gpi_get_keyword(h, e, "CRVAL3", count=cw3) ;wav value at ref point
    nax3 = gpi_get_keyword(h, e, "NAXIS3", count=cw4) ;size of axis

    if (cw1+cw2+cw3+cw4) ne 4 then begin
      self->message, msgtype = 'error', 'At least one FITS keyword of CTYPE3, CD3_3/CDELT3, CRPIX3, CRVAL3, NAXIS3 appears to be missing. Wavelength solution may not be properly calculated.'
      ;;mode='WAVE'
      ;; NO! Do not assume that any valid AXIS3 is wavelength.
      ;; Stokes axes will have the above set as well - use the
      ;; CTYPE3 to decide.
    endif

    mode = string(mode)
    case mode of
      'WAVE': begin
        self->message, msgtype = 'information', "Configuring GPItv for SPECTRAL MODE"
        wavestep = cd3
        CWV = (findgen(nax3) - (CRPIX3-1)) * wavestep + CRVAL3
        ; min and max wavelengths are at the edges of the bins, not their
        ; centers:
        (*self.state).CWV_lmin = min(CWV) - 0.5*wavestep
        (*self.state).CWV_lmax = max(CWV) + 0.5*wavestep

        (*self.state).CWV_NLam=double(nax3)

        ;(*self.state).CWV_lmin=double(CRVAL3)-double(CRPIX3)*double(CD3)
        ;(*self.state).CWV_lmax=(*self.state).CWV_lmin + ((*self.state).CWV_NLam -1.) * double(CDELT3)

        ;CWV=(*self.state).CWV_lmin + double(indgen((*self.state).CWV_NLam)) * $
        ;(((*self.state).CWV_lmax-(*self.state).CWV_lmin)/((*self.state).CWV_NLam-1))[0]
        (*self.state).CWV_ptr=ptr_new(CWV)

        widget_control, (*self.state).curimnum_lambLabel_id, set_value="Wavelen[um]:"

        modelist = ['Show Cube Slices', 'Collapse by Mean', 'Collapse by Median', 'Collapse by SDI', 'Collapse to RGB Color','Align speckles','High Pass Filter','Low Pass Filter','Run KLIP', 'Create SNR Map']
        widget_control, (*self.state).collapse_button, set_value = modelist
        (*self.state).cube_mode='WAVE'

        ;;add contrast unit to unitslist
        if ~strcmp((*self.state).intrinsic_units,'Unknown',/fold_case) then begin
          *(*self.state).unitslist = [*(*self.state).unitslist,'Contrast']
          ind = where(STRCMP(  *(*self.state).unitslist,(*self.state).current_units))
          widget_control, (*self.state).units_droplist_id, set_droplist_select = ind, set_value=*(*self.state).unitslist
        endif
      end
      'STOKES': begin
        (*self.state).cube_mode='STOKES'
        ;; set display stuff
        self->message, msgtype = 'information', "Configuring GPItv for STOKES MODE"
        widget_control, (*self.state).curimnum_lambLabel_id, set_value="Polariz.:"

        modelist = ['Show Cube Slices', 'Collapse by Mean', 'Collapse by Median', 'High Pass Filter','Low Pass Filter']
        ;; do we have a 2-Slice pol stack, or a 4-slice cube?
        ;; set up to overplot polarization vectors
        naxis3 = gpi_get_keyword(h, e, "NAXIS3")
        if naxis3 eq 2 then modelist=[modelist, 'Total Intensity', 'Difference of Polarizations', "Normalized Difference"] $
        else modelist=[modelist,'Divide by Total Intensity', 'Linear Pol. Intensity', 'Linear Pol. Fraction', 'Radial Pol. Intensity']

        widget_control, (*self.state).collapse_button, set_value = modelist
      end
	  'KLMODES': begin
        (*self.state).cube_mode='KLMODES'
        ;; set display stuff
        self->message, msgtype = 'information', "Configuring GPItv for K-L PSF Subtraction Residuals Mode"
        modelist = ['Show Cube Slices', 'High Pass Filter','Low Pass Filter']
        widget_control, (*self.state).collapse_button, set_value = modelist
		widget_control, (*self.state).curimnum_lamblabel_id, set_value="K-L Modes:  "

	  end
      else:begin
        self->message, msgtype = 'warning', "Unknown file mode: "+mode
        (*self.state).cube_mode='UNKNOWN'
        modelist = ['Show Cube Slices', 'Collapse by Mean', 'Collapse by Median', 'Collapse to RGB Color']
        widget_control, (*self.state).collapse_button, set_value = modelist
      end
  endcase
endif else (*self.state).cube_mode='UNKNOWN'


self->update_DQ_warnings

if keyword_set(prior_retained_units) then begin
  if ((prior_retained_units ne 'Unknown') and ((*self.state).current_units ne 'Unknown')) then begin
    self->message, "Retaining prior units: "+prior_retained_units
    self->change_image_units,prior_retained_units,  /silent, /loading_new_image
  endif
endif
if ~keyword_set(noresize) then self->resize ; MDP addition 2008-10-20

end
;----------------------------------------------------------------------

pro GPITv::update_DQ_warnings
  ;; Display image warnings - for Aborted or overexposed images.
  ;;   This is called from setheadinfo, or if you adjust the DQ bitmask
  ;;   interactively

  h = *((*self.state).head_ptr)
  if ptr_valid( (*self.state).exthead_ptr ) then e = *((*self.state).exthead_ptr) else e = ['']

  ;; how many pixels are saturated, if we have a DQ extension?
  if (*self.state).has_dq_mask then begin
    tmp = where((*self.images.dq_image and (*self.state).dq_bit_mask) gt 0)
    if tmp[0] ne -1 then n_bad_from_dq = n_elements(tmp) else n_bad_from_dq = 0
  endif else n_bad_from_dq = 0

  ;; Display 'ABORTED IMAGE' in bold red letters on top of GPItv when
  ;; aborted flag eq true
  abort = gpi_get_keyword(h,e,'ABORTED',count=cc, silent=silent)
  if (cc eq 1) AND (abort eq 1) then begin
    thisdevice=!D.name
    set_plot,'Z'
    device, set_resolution=[165,20], z_buffer=0
    erase
    xyouts, 0.12,.2,'ABORTED IMAGE',color=fsc_color('red'),/normal,charthick=3,charsize=1.2
    snapshot=tvrd()
    tvlct,r,g,b,/get
    image=bytarr(165,20,3)
    tmp = bytarr(165,20)
    tmp[where(r[snapshot] eq 0)] = 255
    image[*,*,0]=255
    image[*,*,1]=tmp
    image[*,*,2]=tmp
    widget_control, (*self.state).aborted_base_id,map=1
    widget_control, (*self.state).aborted_id, set_value=image,/bitmap,pushbutton_events=0
    device, z_buffer=1
    set_plot, thisdevice
    message,/info, 'WARNING: Image is ABORTED'
    ; Or display '> 2k PIX SATURATED' if that is the case.
  endif else if n_bad_from_dq gt 2000 then  begin
    res_x = 165
    res_y = 18
    thisdevice=!D.name
    set_plot,'Z'
    device, set_resolution=[res_x,res_y], z_buffer=0
    erase
    xyouts, 0.03,.2,'> 2K PIX BAD DQ',color=fsc_color('red'),/normal,charthick=1.0,charsize=1.1
    snapshot=tvrd()
    tvlct,r,g,b,/get
    image=bytarr(res_x,res_y,3)
    tmp = bytarr(res_x,res_y)
    tmp[where(r[snapshot] eq 0)] = 255
    image[*,*,0]=255
    image[*,*,1]=tmp
    image[*,*,2]=tmp
    widget_control, (*self.state).aborted_base_id,map=1
    widget_control, (*self.state).aborted_id, set_value=image,/bitmap,pushbutton_events=0
    device, z_buffer=1
    set_plot, thisdevice
    message,/info, 'WARNING: Image has > 2000 pixels which FAIL THE DATA QUALITY CHECK'

  endif else begin
    widget_control, (*self.state).aborted_base_id,map=0
    widget_control, (*self.state).aborted_id, set_value=''
  endelse


end

;----------------------------------------------------------------------

pro GPItv::update_child_windows, noheader=noheader,update=update
  ;; refresh all available child windows if they are present
  ;; This is useful after e.g. reloading a new image from disk

  if xregistered(self.xname+'_apphot', /noshow) then self->apphot_refresh
  if xregistered(self.xname+'_anguprof', /noshow) then self->anguprof_refresh
  if xregistered(self.xname+'_contrprof',/noshow) then self->contrprof_refresh
  if xregistered(self.xname+'_fpmoffset',/noshow) then self->fpmoffset_refresh
  if xregistered(self.xname+'_pixtable', /noshow) then self->pixtable_update
  if xregistered(self.xname+'_lineplot', /noshow) then self->lineplot_update,update=update
  if xregistered(self.xname+'_stats', /noshow) then self->stats_refresh

  if xregistered(self.xname+'_sdi', /noshow) then self->sdi_refresh
  if xregistered(self.xname+'_hist', /noshow) then self->hist_refresh

  if ~(keyword_set(noheader)) then if obj_valid((*self.state).subwindow_headerviewer) then self->headinfo

end

;----------------------------------------------------------------------

pro GPItv::setheader, head, extensionhead=extensionhead

  ; Routine to keep the image header using a pointer to a
  ; heap variable.  If there is no header (i.e. if GPItv has just been
  ; passed a data array rather than a filename), then make the
  ; header pointer a null pointer.  Get astrometry info from the
  ; header if available.  If there's no astrometry information, set
  ; (*self.state).astr_ptr to be a null pointer.
  ;
  ; HISTORY:
  ;   2012-09-18: MDP added exthead to store extension header too.

  if (n_elements(head) LE 1) then begin
    ; If there's no image header...
    (*self.state).wcstype = 'none'
    ptr_free, (*self.state).head_ptr
    ptr_free, (*self.state).exthead_ptr
    (*self.state).head_ptr = ptr_new()
    ptr_free, (*self.state).astr_ptr
    (*self.state).astr_ptr = ptr_new()
    (*self.state).main_image_astr_backup = ptr_new()
    (*self.state).astr_from = 'None'
    widget_control, (*self.state).wcs_bar_id, set_value = '---No WCS Info---'
    return
  endif

  ptr_free, (*self.state).head_ptr
  (*self.state).head_ptr = ptr_new(head)

  ptr_free, (*self.state).exthead_ptr
  if keyword_set(extensionhead) then (*self.state).exthead_ptr = ptr_new(extensionhead)

  ; Get astrometry information from header, if it exists
  ptr_free, (*self.state).astr_ptr        ; kill previous astrometry info
  (*self.state).astr_ptr = ptr_new()

  if keyword_set(extensionhead) then begin
    extast, extensionhead, astr, noparams
    (*self.state).astr_from='Extension'
    widget_control, (*self.state).wcs_bar_id, set_value = '---WCS from extension---'
  endif else begin
    extast, head, astr, noparams
    (*self.state).astr_from='PHDU'
  endelse

  ; No valid astrometry in header
  if (noparams EQ -1) then begin
    widget_control, (*self.state).wcs_bar_id, set_value = '---No WCS Info---'
    (*self.state).wcstype = 'none'
    (*self.state).astr_from= 'None'
    return
  endif

  ; coordinate types that we can't use:
  if ( (strcompress(string(astr.ctype[0]), /remove_all) EQ 'PIXEL') $
    or (strcompress(string(astr.ctype[0]), /remove_all) EQ '') ) then begin
    widget_control, (*self.state).wcs_bar_id, set_value = '---No WCS Info---'
    (*self.state).wcstype = 'none'
    return
  endif

  ; Image is a 2-d calibrated spectrum (probably from stis):
  if (astr.ctype[0] EQ 'LAMBDA') then begin
    (*self.state).wcstype = 'lambda'
    (*self.state).astr_ptr = ptr_new(astr)
    widget_control, (*self.state).wcs_bar_id, set_value = '                 '
    return
  endif

  ; Good astrometry info in header:
  (*self.state).wcstype = 'angle'
  widget_control, (*self.state).wcs_bar_id, set_value = '                 '

  ; Create a pointer to the header info
  (*self.state).astr_ptr = ptr_new(astr)
  ; save another copy for restoring after transformations.
  ptr_free, (*self.state).main_image_astr_backup
  (*self.state).main_image_astr_backup  = ptr_new(astr)


  ; Get the equinox of the coordinate system
  ; GPI note - EQUINOX is in PHDU so this is OK
  equ = get_equinox(head, code)
  if strc(equ) eq '' then equ = 2000.0 ; default is J2000 if missing or blank
  if (code NE -1) then begin
    if (equ EQ 2000.0) then (*self.state).equinox = 'J2000'
    if (equ EQ 1950.0) then (*self.state).equinox = 'B1950'
    if (equ NE 2000.0 and equ NE 1950.0) then $
      (*self.state).equinox = string(equ, format = '(f6.1)')
  endif else begin
    IF strc(sxpar(head, 'INSTRUME')) eq 'GPI' then begin
      (*self.state).equinox = 'J2000' ; default for GPI -
      ; assume J2000 and don't hose the entire WCS just because
      ; the equinox keyword is missing
    endif else IF (strmid(astr.ctype[0], 0, 4) EQ 'GLON') THEN BEGIN
      (*self.state).equinox = 'J2000' ; (just so it is set)
    ENDIF ELSE BEGIN
      ptr_free, (*self.state).astr_ptr    ; clear pointer
      (*self.state).astr_ptr = ptr_new()
      (*self.state).equinox = 'J2000'
      (*self.state).wcstype = 'none'
      widget_control, (*self.state).wcs_bar_id, set_value = '---No WCS Info---'
    ENDELSE
  endelse

  ; Set default display to native system in header
  (*self.state).display_equinox = (*self.state).equinox
  (*self.state).display_coord_sys = strmid(astr.ctype[0], 0, 4)

end

;---------------------------------------------------------------------

pro GPItv::headinfo,show=show
  ;; View a FITS header
  ;; /show - If window exists, bring to front

  ;; If there's no header, exit this routine.
  if (not(ptr_valid((*self.state).head_ptr))) then begin
    self->message, 'No header information available for this image!', $
      msgtype = 'error', /window
    return
  endif

  ;; Are we going to try to view a file on disk, or one in memory?
  is_file_on_disk = 0
  if keyword_set((*self.state).imagename) then if file_test((*self.state).imagename) then is_file_on_disk=1

  ;; MDP addition - updated/improved FITS header viewer from OSIRIS QL
  ;;
  ;; MDP update 2012: If we are viewing an actual file on disk, invoke the header
  ;; viewer with that filename rather than just passing the header. This lets the
  ;; header viewer examine the file for multiple extensions and thus view them.

  ;; MP quick hack debug: avoid the reopening bit
  if not obj_valid((*self.state).subwindow_headerviewer) then begin
    ;; Create a new FITS header viewer window and load the data into it
    (*self.state).subwindow_headerviewer= obj_new('cfitshedit')
    cfh = (*self.state).subwindow_headerviewer

    if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
    title = title_base+" FITS Header Viewer"

    if is_file_on_disk then begin
      filename=(*self.state).imagename
      delvarx,header
    endif else begin
      header = *((*self.state).head_ptr)
      delvarx, filename
    endelse
    cfh->ViewHeader, (*self.state).base_id, filename=filename, header=header, title=title
    ;;cfh->ViewHeader, (*self.state).base_id, filename=(*self.state).imagename, title=title else
    ;;cfh->ViewHeader, header=*((*self.state).head_ptr), title=title
  endif else begin
    ;; re-use the existing window.
    cfh = (*self.state).subwindow_headerviewer
    if keyword_set(show) then widget_control,cfh.cfitshedit_id,/show
    if is_file_on_disk then cfh->OpenFile, filename=(*self.state).imagename  else cfh->OpenFile, header=*((*self.state).head_ptr)
  endelse

end

;--------------------------------------------------------------------------------------------
pro GPItv::switchextension
  ; Switch FITS extensions


  ; Are we going to try to view a file on disk, or one in memory?
  is_file_on_disk = 0
  if not keyword_set((*self.state).imagename) then begin
    self->message,'The image currently displayed in gpitv was loaded from an array, not a file on disk. There are no other extensions to switch to.', msgtype='error', /window
    return
  endif

  if not file_test((*self.state).imagename) then begin
    self->message,"The image currently displayed in gpitv was loaded from a file on disk, but that file no longer appears to exist. Can't switch to other extensions.", msgtype='error', /window
    return
  endif

  fits_open, (*self.state).imagename, fcb   ; ;n_ext = numext, extname=extnames, /silent
  wim = where(fcb.xtension eq 'IMAGE', imct)

  if imct eq 1 then begin
    self->message,"The image currently displayed in gpitv has only one image extension. Can't switch to other extensions.", msgtype='error', /window
    return
  endif

  extlist = ''
  for i = 0, imct-1 do begin
    extlist += strtrim('Ext '+ strc(wim[i])+": "+fcb.extname[wim[i]]+ '|', 2)
  endfor

  extlist = strmid(extlist, 0, strlen(extlist)-1) ; drop final trailing | char

  droptext = strcompress('0, droplist, ' + extlist + $
    ', label_left=Select Extension to View:, set_value=0')

  formdesc = ['0, label, Multi-Extension FITS File, quit', $
    '0, label, There are '+strc(imct)+' available image extensions for the current file:', $
    droptext, $
    '0, button, Switch to Extension, quit', $
    '0, button, Cancel, quit']

  textform = cw_form(formdesc, /column, $
    title = 'Select FITS Extension')
  if (textform.tag4 EQ 1) then begin  ; cancelled
    ;cancelled = 1
    return
  endif

  if (textform.tag3 EQ 1) then begin   ;extension selected
    extension = long(textform.tag2) + 1
  endif else begin
    extension = 0               ; primary image selected
  endelse

  self->message, msgtype='information', "User selected switching to extension "+strc(extension)

  ; this will load the array into memory
  self->fitsext_read, (*self.state).imagename, fcb.nextend, head, cancelled, extension=extension

  ; then read in the primary header also, which is required since the concatenated pair of headers
  ; must be handed to setup_new_image.
  headphu = headfits((*self.state).imagename)
  head = [headphu, head]

  ; this sets the various displayed keywords and other associated metadata
  self->setup_new_image, header=head, imname=(*self.state).imagename, _extra=_extra
  if extension gt 1 then begin
    (*self.state).title_extras = "extension "+strc(i)+": "+fcb.extname[i]
    self->settitle
  endif
  self->refresh

end


;--------------------------------------------------------------------------------
pro GPItv::directory_viewer
  ; Display a specialized tool for rapidly scanning through all the files in a
  ; directory.


  if not obj_valid((*self.state).subwindow_dirviewer) then begin
    self->message, msgtype='information', "Creating new dir browser"
    if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
    (*self.state).subwindow_dirviewer= obj_new('dirviewer', directory = (*self.state).current_dir, $
      title='Browse Images for '+title_base, parent_gpitv=self, group_leader=(*self.state).base_id )
  endif else begin
    ; re-use the existing window and bring to front
    self->message, msgtype='information', "Reusing dir browser"
    (*self.state).subwindow_dirviewer->show
  endelse

end

;--------------------------------------------------------------------------------
pro GPItv::show_gpidiagram
  ; Display the Python gpidiagram tool for the currently selected filename.
  ; Will only work meaningfully if you're actually viewing a real gpi image,
  ; of course.
  ; Depends on the presence of the gpidiagram file in the OS search path.


  ; Are we going to try to view a file on disk, or one in memory?
  is_file_on_disk = 0
  if not keyword_set((*self.state).imagename) then begin
    self->message,'The image currently displayed in gpitv was loaded from an array, not a file on disk. Cannot display the gpidiagram tool.', msgtype='error', /window
    return
  endif
  if not file_test((*self.state).imagename) then begin
    self->message,"The image currently displayed in gpitv was loaded from a file on disk, but that file no longer appears to exist. Cannot display the gpidiagram tool.", msgtype='error', /window
    return
  endif

  ; this is spawned in a sort of convoluted way since directly running
  ; gpidiagram does not seem to be working robustly for reasons I do not
  ; understand. -MP
  self->message, msgtype='information', "Now starting Python program gpidiagram for "+(*self.state).imagename
  self->message, msgtype='information', "    This may take several seconds to start..."
  spawn, 'python `which gpidiagram`  --file '+(*self.state).imagename+" &"


end

;----------------------------------------------------------------------
;             routines to do plot overlays
;----------------------------------------------------------------------

pro GPItv::plot1plot, iplot

  ; Plot a point or line overplot on the image

  self->setwindow, (*self.state).draw_window_id

  widget_control, /hourglass

  oplot, [(*(self.pdata.plot_ptr[iplot])).x], [(*(self.pdata.plot_ptr[iplot])).y], $
    _extra = (*(self.pdata.plot_ptr[iplot])).options

  self->resetwindow
  (*self.state).newrefresh=1
end

;----------------------------------------------------------------------

pro GPItv::plot1text, iplot

  ; Plot a text overlay on the image
  self->setwindow, (*self.state).draw_window_id

  widget_control, /hourglass

  xyouts, (*(self.pdata.plot_ptr[iplot])).x, (*(self.pdata.plot_ptr[iplot])).y, $
    (*(self.pdata.plot_ptr[iplot])).text, _extra = (*(self.pdata.plot_ptr[iplot])).options

  self->resetwindow
  (*self.state).newrefresh=1
end

;----------------------------------------------------------------------

pro GPItv::plot1arrow, iplot


  ; Plot a arrow overlay on the image
  self->setwindow, (*self.state).draw_window_id

  widget_control, /hourglass

  arrow, (*(self.pdata.plot_ptr[iplot])).x1, (*(self.pdata.plot_ptr[iplot])).y1, $
    (*(self.pdata.plot_ptr[iplot])).x2, (*(self.pdata.plot_ptr[iplot])).y2, $
    _extra = (*(self.pdata.plot_ptr[iplot])).options, /data

  self->resetwindow
  (*self.state).newrefresh=1
end

;---------------------------------------------
pro profrad,imt,res,med4q=med4q,p2d=p2d,p1d=p1d,rayon=rayon


  ;Calcule un profil radial median.
  ;Par defaut, calcule un profil radial 1d qui consiste en la mediane
  ;des valeurs de tous les pixels situes dans un interval de distance du
  ;centre de l'image. Cet interval de distance est determine par
  ;res. Utilise ensuite un spline cubique pour extrapoler le profil a la
  ;distance de chacun des pixels pour construire le profil 2D.
  ;
  ;res: resolution (en pixels) du profil radial 1d, optionnel, la valeur
  ;     par defaut est 1.
  ;p2d: profil 2d
  ;p1d: profil 1d
  ;rayon: rayon correspondant a p1d
  ;/med4q: calcule le profil 2d en prenant la mediane sur les 4 quadrants

  s=size(imt) & dimx=s[1] & dimy=s[2]
  im=double(imt)

  ;calcul de profil 1d
  if (arg_present(p1d) or (not keyword_set(med4q) and arg_present(p2d))) then begin
    if (n_params() eq 1) then res=1.
    distarr=shift(dist(dimx,dimy),dimx/2,dimy/2)
    if res ne 0 then rdistarr=round(distarr/res)*res else rdistarr=distarr
    rayon=rdistarr[0:dimx/2,0:dimy/2]
    sind=sort(rayon) & rayon=rayon[uniq(rayon,sind)]
    p1d=dblarr(n_elements(rayon))

    for r=0,n_elements(rayon)-1 do $
      p1d[r]=median(im[where(rdistarr eq rayon[r])],/even)
  endif

  ;calcul du profil 2d
  if (not keyword_set(med4q) and arg_present(p2d)) then begin
    ;interpole le profil sur l'image au complet d'un coup
    ;p2d=dblarr(dimx,dimy)
    ;sind=sort(distarr)
    ;p2d[sind]=spline(rayon,p1d,distarr[sind])

    ;fait un seul quadrant et copie sur les 3 autres quadrants
    ;cette methode est 3X plus rapide pour l'interpolation
    distarr=distarr[0:dimx/2,0:dimy/2]
    sind=sort(distarr)
    q1=dblarr(dimx/2+1,dimy/2+1)
    q1[sind]=spline(rayon,p1d,distarr[sind])

    if (dimx mod 2 eq 0) then i1x=1 else i1x=0
    if (dimy mod 2 eq 0) then i1y=1 else i1y=0
    ;pas besoin de prendres de transposes ici car les profils sont
    ;symmetriques aux transpose
    p2d=dblarr(dimx,dimy)
    p2d[0:dimx/2,0:dimy/2]=q1
    p2d[0:dimx/2,dimy/2:dimy-1]=reverse(q1[*,i1y:dimy/2],2)
    p2d[dimx/2:dimx-1,dimy/2:dimy-1]=$
      reverse(reverse(q1[i1x:dimx/2,i1y:dimy/2],2),1)
    p2d[dimx/2:dimx-1,0:dimy/2]=reverse(q1[i1x:dimx/2,*],1)
  endif

  if (keyword_set(med4q) and arg_present(p2d)) then begin
    ;place les 4 quadrants dans un cube, fait la mediane, et replace cette
    ;mediane dans les quadrants
    ;(equivalent a faire un cube avec 4 rotation et prendre la mediane)
    q=dblarr(dimx/2+1,dimy/2+1,4)
    if (dimx mod 2 eq 0) then i1x=1 else i1x=0
    if (dimy mod 2 eq 0) then i1y=1 else i1y=0
    q[*,*,0]=im[0:dimx/2,0:dimy/2]
    q[*,i1y:dimy/2,1]=reverse(im[0:dimx/2,dimy/2:dimy-1],2)
    q[*,*,1]=transpose(q[*,*,1])
    q[i1x:dimx/2,i1y:dimy/2,2]=reverse(reverse(im[dimx/2:dimx-1,dimy/2:dimy-1],2),1)
    q[i1x:dimx/2,*,3]=reverse(im[dimx/2:dimx-1,0:dimy/2],1)
    q[*,*,3]=transpose(q[*,*,3])
    q=median(q,dimension=3,/even)
    ;    q=min(q,dimension=3)
    qt=transpose(q)
    p2d=dblarr(dimx,dimy)
    p2d[0:dimx/2,0:dimy/2]=q
    p2d[0:dimx/2,dimy/2:dimy-1]=reverse(qt[*,i1y:dimy/2],2)
    p2d[dimx/2:dimx-1,dimy/2:dimy-1]=$
      reverse(reverse(q[i1x:dimx/2,i1y:dimy/2],2),1)
    p2d[dimx/2:dimx-1,0:dimy/2]=reverse(qt[i1x:dimx/2,*],1)

  endif

end

;---------------------------------------------------------
function GPItv::degperpix, hdr

  ; This program calculates the pixel scale (deg/pixel) and returns the value


  extast, hdr, bastr, noparams    ;extract astrom params in deg.

  a = bastr.crval[0]
  d = bastr.crval[1]

  factor = 60.0                   ;conversion factor from deg to arcmin
  d1 = d + (1/factor)             ;compute x,y of crval + 1 arcmin

  proj = strmid(bastr.ctype[0],5,3)

  case proj of
    'GSS': gsssadxy, bastr, [a,a], [d,d1], x, y
    else:  ad2xy, [a,a], [d,d1], bastr, x, y
  endcase

  dmin = sqrt( (x[1]-x[0])^2 + (y[1]-y[0])^2 ) ;det. size in pixels of 1 arcmin

  ; Convert to degrees per pixel and return scale
  degperpix = 1. / dmin / 60.

  return, degperpix
end

;----------------------------------------------------------------------

function GPItv::wcs2pix, coords, coord_sys=coord_sys, line=line


  ; check validity of (*self.state).astr_ptr and (*self.state).head_ptr before
  ; proceeding to grab wcs information

  if ptr_valid((*self.state).astr_ptr) then begin
    ctype = (*(*self.state).astr_ptr).ctype
    equinox = (*self.state).equinox
    disp_type = (*self.state).display_coord_sys
    disp_equinox = (*self.state).display_equinox
    disp_base60 = (*self.state).display_base60
    bastr = *((*self.state).astr_ptr)

    ; function to convert an GPItv region from wcs coordinates to pixel coordinates
    degperpix = self->degperpix(*((*self.state).exthead_ptr))

    ; need numerical equinox values
    IF (equinox EQ 'J2000') THEN num_equinox = 2000.0 ELSE $
      IF (equinox EQ 'B1950') THEN num_equinox = 1950.0 ELSE $
      num_equinox = float(equinox)

    headtype = strmid(ctype[0], 0, 4)
    n_coords = n_elements(coords)
  endif

  case coord_sys of

    'j2000': begin
      if (strpos(coords[0], ':')) ne -1 then begin
        ra_arr = strsplit(coords[0],':',/extract)
        dec_arr = strsplit(coords[1],':',/extract)
        ra = ten(float(ra_arr[0]), float(ra_arr[1]), float(ra_arr[2])) * 15.0
        dec = ten(float(dec_arr[0]), float(dec_arr[1]), float(dec_arr[2]))
        if (keyword_set(line)) then begin
          ra1_arr = strsplit(coords[2],':',/extract)
          dec1_arr = strsplit(coords[3],':',/extract)
          ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), float(ra1_arr[2])) * 15.0
          dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), float(dec1_arr[2]))
        endif
      endif else begin  ; coordinates in degrees
        ra=float(coords[0])
        dec=float(coords[1])
        if (keyword_set(line)) then begin
          ra1=float(coords[2])
          dec1=float(coords[3])
        endif
      endelse

      if (not keyword_set(line)) then begin
        if (n_coords ne 6) then $
          coords[2:n_coords-2] = strcompress(string(float(coords[2:n_coords-2]) / $
          (degperpix * 60.)),/remove_all) $
        else $
          coords[2:n_coords-3] = strcompress(string(float(coords[2:n_coords-3]) / $
          (degperpix * 60.)),/remove_all)
      endif

    end

    'b1950': begin
      if (strpos(coords[0], ':')) ne -1 then begin
        ra_arr = strsplit(coords[0],':',/extract)
        dec_arr = strsplit(coords[1],':',/extract)
        ra = ten(float(ra_arr[0]), float(ra_arr[1]), float(ra_arr[2])) * 15.0
        dec = ten(float(dec_arr[0]), float(dec_arr[1]), float(dec_arr[2]))
        precess, ra, dec, 1950.0, 2000.0
        if (keyword_set(line)) then begin
          ra1_arr = strsplit(coords[2],':',/extract)
          dec1_arr = strsplit(coords[3],':',/extract)
          ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), float(ra1_arr[2])) * 15.0
          dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), float(dec1_arr[2]))
          precess, ra1, dec1, 1950.0,2000.0
        endif
      endif else begin  ; convert B1950 degrees to J2000 degrees
        ra = float(coords[0])
        dec = float(coords[1])
        precess, ra, dec, 1950.0, 2000.0
        if (keyword_set(line)) then begin
          ra1=float(coords[2])
          dec1=float(coords[3])
          precess, ra1, dec1, 1950., 2000.0
        endif
      endelse

      if (not keyword_set(line)) then begin
        if (n_coords ne 6) then $
          coords[2:n_coords-2] = strcompress(string(float(coords[2:n_coords-2]) / $
          (degperpix * 60.)),/remove_all) $
        else $
          coords[2:n_coords-3] = strcompress(string(float(coords[2:n_coords-3]) / $
          (degperpix * 60.)),/remove_all)
      endif
    end

    'galactic': begin  ; convert galactic to J2000 degrees
      euler, float(coords[0]), float(coords[1]), ra, dec, 2
      if (not keyword_set(line)) then begin
        if (n_coords ne 6) then $
          coords[2:n_coords-2] = strcompress(string(float(coords[2:n_coords-2]) / $
          (degperpix * 60.)),/remove_all) $
        else $
          coords[2:n_coords-3] = strcompress(string(float(coords[2:n_coords-3]) / $
          (degperpix * 60.)),/remove_all)
      endif else begin
        euler, float(coords[2]), float(coords[3]), ra1, dec1, 2
      endelse
    end

    'ecliptic': begin  ; convert ecliptic to J2000 degrees
      euler, float(coords[0]), float(coords[1]), ra, dec, 4
      if (not keyword_set(line)) then begin
        if (n_coords ne 6) then $
          coords[2:n_coords-2] = strcompress(string(float(coords[2:n_coords-2]) / $
          (degperpix * 60.)),/remove_all) $
        else $
          coords[2:n_coords-3] = strcompress(string(float(coords[2:n_coords-3]) / $
          (degperpix * 60.)),/remove_all)
      endif else begin
        euler, float(coords[2]), float(coords[3]), ra1, dec1, 4
      endelse
    end

    'current': begin
      ra_arr = strsplit(coords[0],':',/extract)
      dec_arr = strsplit(coords[1],':',/extract)
      ra = ten(float(ra_arr[0]), float(ra_arr[1]), float(ra_arr[2])) * 15.0
      dec = ten(float(dec_arr[0]), float(dec_arr[1]), float(dec_arr[2]))
      if (not keyword_set(line)) then begin
        coords[2] = strcompress(string(float(coords[2]) / $
          (degperpix * 60.)),/remove_all)
        if (n_coords gt 3) then $
          coords[3] = strcompress(string(float(coords[3]) / $
          (degperpix * 60.)),/remove_all)
      endif else begin
        ra1_arr = strsplit(coords[2],':',/extract)
        dec1_arr = strsplit(coords[3],':',/extract)
        ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), float(ra1_arr[2])) * 15.0
        dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), float(dec1_arr[2]))
      endelse

      if (num_equinox ne 2000.) then begin
        precess, ra, dec, num_equinox, 2000.
        if (keyword_set(line)) then precess, ra1, dec1, num_equinox, 2000.
      endif

    end

    'pixel': begin
      ; Do nothing when pixel.  Will pass pixel coords array back.
    end

    else:

  endcase

  if (ptr_valid((*self.state).astr_ptr) AND coord_sys ne 'pixel') then begin

    if (num_equinox ne 2000) then begin
      precess, ra, dec, 2000., num_equinox
      if (keyword_set(line)) then precess, ra1, dec1, 2000., num_equinox
    endif

    proj = strmid(ctype[0],5,3)

    case proj of
      'GSS': begin
        gsssadxy, bastr, ra, dec, x, y
        if (keyword_set(line)) then gsssadxy, bastr, ra1, dec1, x1, y1
      end
      else: begin
        ad2xy, ra, dec, bastr, x, y
        if (keyword_set(line)) then ad2xy, ra1, dec1, bastr, x1, y1
      end
    endcase

    coords[0] = strcompress(string(x),/remove_all)
    coords[1] = strcompress(string(y),/remove_all)
    if (keyword_set(line)) then begin
      coords[2] = strcompress(string(x1),/remove_all)
      coords[3] = strcompress(string(y1),/remove_all)
    endif
  endif

  return, coords
END

;----------------------------------------------------------------------

pro GPItv::plot1region, iplot


  ; Plot a region overlay on the image
  self->setwindow, (*self.state).draw_window_id

  widget_control, /hourglass

  reg_array = (*(self.pdata.plot_ptr[iplot])).reg_array
  n_reg = n_elements(reg_array)

  for i=0, n_reg-1 do begin
    open_parenth_pos = strpos(reg_array[i],'(')
    close_parenth_pos = strpos(reg_array[i],')')
    reg_type = strcompress(strmid(reg_array[i],0,open_parenth_pos),/remove_all)
    length = close_parenth_pos - open_parenth_pos
    coords_str = strcompress(strmid(reg_array[i], open_parenth_pos+1, $
      length-1),/remove_all)
    coords_arr = strsplit(coords_str,',',/extract)
    n_coords = n_elements(coords_arr)
    color_begin_pos = strpos(strlowcase(reg_array[i]), 'color')
    text_pos = strpos(strlowcase(reg_array[i]), 'text')

    if (color_begin_pos ne -1) then begin
      color_equal_pos = strpos(reg_array[i], '=', color_begin_pos)
    endif

    text_begin_pos = strpos(reg_array[i], '{')

    ; Text for region
    if (text_begin_pos ne -1) then begin
      text_end_pos = strpos(reg_array[i], '}')
      text_len = (text_end_pos-1) - (text_begin_pos)
      text_str = strmid(reg_array[i], text_begin_pos+1, text_len)
      color_str = ''

      ; Color & Text for region
      if (color_begin_pos ne -1) then begin
        ; Compare color_begin_pos to text_begin_pos to tell which is first

        case (color_begin_pos lt text_begin_pos) of
          0: begin
            ;text before color
            color_str = strcompress(strmid(reg_array[i], color_equal_pos+1, $
              strlen(reg_array[i])), /remove_all)
          end
          1: begin
            ;color before text
            len_color = (text_pos-1) - color_equal_pos
            color_str = strcompress(strmid(reg_array[i], color_equal_pos+1, $
              len_color), /remove_all)
          end
        endcase
      endif

    endif else begin

      ; Color but no text for region
      if (color_begin_pos ne -1) then begin
        color_str = strcompress(strmid(reg_array[i], color_equal_pos+1, $
          strlen(reg_array[i])), /remove_all)

        ; Neither color nor text for region
      endif else begin
        color_str = ''
      endelse

      text_str = ''

    endelse

    index_j2000 = where(strlowcase(coords_arr) eq 'j2000')
    index_b1950 = where(strlowcase(coords_arr) eq 'b1950')
    index_galactic = where(strlowcase(coords_arr) eq 'galactic')
    index_ecliptic = where(strlowcase(coords_arr) eq 'ecliptic')

    index_coord_system = where(strlowcase(coords_arr) eq 'j2000') AND $
      where(strlowcase(coords_arr) eq 'b1950') AND $
      where(strlowcase(coords_arr) eq 'galactic') AND $
      where(strlowcase(coords_arr) eq 'ecliptic')

    index_coord_system = index_coord_system[0]

    if (index_coord_system ne -1) then begin

      ; Check that a WCS region is not overplotted on image with no WCS
      if (NOT ptr_valid((*self.state).astr_ptr)) then begin
        self->message, 'WCS Regions cannot be displayed on image without WCS', $
          msgtype='error', /window
        return
      endif

      case strlowcase(coords_arr[index_coord_system]) of
        'j2000': begin
          if (strlowcase(reg_type) ne 'line') then $
            coords_arr = self->wcs2pix(coords_arr, coord_sys='j2000') $
          else $
            coords_arr = self->wcs2pix(coords_arr, coord_sys='j2000', /line)
        end
        'b1950': begin
          if (strlowcase(reg_type) ne 'line') then $
            coords_arr = self->wcs2pix(coords_arr, coord_sys='b1950') $
          else $
            coords_arr = self->wcs2pix(coords_arr, coord_sys='b1950', /line)
        end
        'galactic': begin
          if (strlowcase(reg_type) ne 'line') then $
            coords_arr = self->wcs2pix(coords_arr, coord_sys='galactic') $
          else $
            coords_arr = self->wcs2pix(coords_arr, coord_sys='galactic', /line)
        end
        'ecliptic': begin
          if (strlowcase(reg_type) ne 'line') then $
            coords_arr = self->wcs2pix(coords_arr, coord_sys='ecliptic') $
          else $
            coords_arr = self->wcs2pix(coords_arr, coord_sys='ecliptic', /line)
        end
        else:
      endcase
    endif else begin

      if (strpos(coords_arr[0], ':')) ne -1 then begin

        ; Check that a WCS region is not overplotted on image with no WCS
        if (NOT ptr_valid((*self.state).astr_ptr)) then begin
          self->message, 'WCS Regions cannot be displayed on image without WCS', $
            msgtype='error', /window
          return
        endif

        if (strlowcase(reg_type) ne 'line') then $
          coords_arr = self->wcs2pix(coords_arr,coord_sys='current') $
        else $
          coords_arr = self->wcs2pix(coords_arr,coord_sys='current', /line)
      endif else begin
        if (strlowcase(reg_type) ne 'line') then $
          coords_arr = self->wcs2pix(coords_arr,coord_sys='pixel') $
        else $
          coords_arr = self->wcs2pix(coords_arr,coord_sys='pixel', /line)
      endelse

    endelse

    CASE strlowcase(color_str) OF

      'red':     (*(self.pdata.plot_ptr[iplot])).options.color = '1'
      'black':   (*(self.pdata.plot_ptr[iplot])).options.color = '0'
      'green':   (*(self.pdata.plot_ptr[iplot])).options.color = '2'
      'blue':    (*(self.pdata.plot_ptr[iplot])).options.color = '3'
      'cyan':    (*(self.pdata.plot_ptr[iplot])).options.color = '4'
      'magenta': (*(self.pdata.plot_ptr[iplot])).options.color = '5'
      'yellow':  (*(self.pdata.plot_ptr[iplot])).options.color = '6'
      'white':   (*(self.pdata.plot_ptr[iplot])).options.color = '7'
      ELSE:      (*(self.pdata.plot_ptr[iplot])).options.color = '1'

    ENDCASE

    self->setwindow,(*self.state).draw_window_id
    self->plotwindow

    case strlowcase(reg_type) of

      'circle': begin
        xcenter = (float(coords_arr[0]) - (*self.state).offset[0] + 0.5) * $
          (*self.state).zoom_factor
        ycenter = (float(coords_arr[1]) - (*self.state).offset[1] + 0.5) * $
          (*self.state).zoom_factor

        radius = float(coords_arr[2]) * (*self.state).zoom_factor
        tvcircle, radius, xcenter, ycenter, /device, $
          _extra = (*(self.pdata.plot_ptr[iplot])).options

        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(self.pdata.plot_ptr[iplot])).options, /device
      end
      'box': begin
        angle = 0 ; initialize angle to 0
        if (n_coords ge 4) then begin
          xcenter = (float(coords_arr[0]) - (*self.state).offset[0] + 0.5) * $
            (*self.state).zoom_factor
          ycenter = (float(coords_arr[1]) - (*self.state).offset[1] + 0.5) * $
            (*self.state).zoom_factor
          xwidth = float(coords_arr[2]) * (*self.state).zoom_factor
          ywidth = float(coords_arr[3]) * (*self.state).zoom_factor
          if (n_coords ge 5) then angle = float(coords_arr[4])
        endif
        width_arr = [xwidth,ywidth]
        ; angle = -angle because tvbox rotates clockwise
        tvbox, width_arr, xcenter, ycenter, angle=-angle, $
          _extra = (*(self.pdata.plot_ptr[iplot])).options

        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(self.pdata.plot_ptr[iplot])).options, /device
      end
      'ellipse': begin
        angle = 0 ; initialize angle to 0
        if (n_coords ge 4) then begin
          xcenter = (float(coords_arr[0]) - (*self.state).offset[0] + 0.5) * $
            (*self.state).zoom_factor
          ycenter = (float(coords_arr[1]) - (*self.state).offset[1] + 0.5) * $
            (*self.state).zoom_factor
          xradius = float(coords_arr[2]) * (*self.state).zoom_factor
          yradius = float(coords_arr[3]) * (*self.state).zoom_factor
          if (n_coords ge 5) then angle = float(coords_arr[4])
        endif

        ; Correct angle for default orientation used by tvellipse
        angle=angle+180.

        if (xcenter ge 0.0 and ycenter ge 0.0) then $
          tvellipse, xradius, yradius, xcenter, ycenter, angle, $
          _extra = (*(self.pdata.plot_ptr[iplot])).options

        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(self.pdata.plot_ptr[iplot])).options, /device
      end
      'polygon': begin
        n_vert = n_elements(coords_arr) / 2
        xpoints = fltarr(n_vert)
        ypoints = fltarr(n_vert)
        for vert_i = 0, n_vert - 1 do begin
          xpoints[vert_i] = coords_arr[vert_i*2]
          ypoints[vert_i] = coords_arr[vert_i*2+1]
        endfor

        if (xpoints[0] ne xpoints[n_vert-1] OR $
          ypoints[0] ne ypoints[n_vert-1]) then begin
          xpoints1 = fltarr(n_vert+1)
          ypoints1 = fltarr(n_vert+1)
          xpoints1[0:n_vert-1] = xpoints
          ypoints1[0:n_vert-1] = ypoints
          xpoints1[n_vert] = xpoints[0]
          ypoints1[n_vert] = ypoints[0]
          xpoints = xpoints1
          ypoints = ypoints1
        endif

        xcenter = total(xpoints) / n_elements(xpoints)
        ycenter = total(ypoints) / n_elements(ypoints)

        plots, xpoints, ypoints,  $
          _extra = (*(self.pdata.plot_ptr[iplot])).options

        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(self.pdata.plot_ptr[iplot])).options, /device
      end
      'line': begin
        x1 = (float(coords_arr[0]) - (*self.state).offset[0] + 0.5) * $
          (*self.state).zoom_factor
        y1 = (float(coords_arr[1]) - (*self.state).offset[1] + 0.5) * $
          (*self.state).zoom_factor
        x2 = (float(coords_arr[2]) - (*self.state).offset[0] + 0.5) * $
          (*self.state).zoom_factor
        y2 = (float(coords_arr[3]) - (*self.state).offset[1] + 0.5) * $
          (*self.state).zoom_factor

        xpoints = [x1,x2]
        ypoints = [y1,y2]
        xcenter = total(xpoints) / n_elements(xpoints)
        ycenter = total(ypoints) / n_elements(ypoints)

        plots, xpoints, ypoints, /device, $
          _extra = (*(self.pdata.plot_ptr[iplot])).options

        if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
          alignment=0.5, _extra = (*(self.pdata.plot_ptr[iplot])).options, /device
      end
      else: begin

      end

    endcase

  endfor

  self->resetwindow
  (*self.state).newrefresh=1
end

;----------------------------------------------------------------------

pro GPItv::plot1contour, iplot


  ; Overplot contours on the image

  self->setwindow, (*self.state).draw_window_id
  widget_control, /hourglass

  xrange = !x.crange
  yrange = !y.crange

  ; The following allows for 2 conditions, depending upon whether X and Y
  ; are set

  dims = size( (*(self.pdata.plot_ptr[iplot])).z,/dim )

  if (size( (*(self.pdata.plot_ptr[iplot])).x,/N_elements ) EQ dims[0] $
    AND size( (*(self.pdata.plot_ptr[iplot])).y,/N_elements) EQ dims[1] ) then begin

    contour, (*(self.pdata.plot_ptr[iplot])).z, (*(self.pdata.plot_ptr[iplot])).x, $
      (*(self.pdata.plot_ptr[iplot])).y, $
      position=[0,0,1,1], xrange=xrange, yrange=yrange, $
      xstyle=5, ystyle=5, /noerase, $
      _extra = (*(self.pdata.plot_ptr[iplot])).options, /follow

  endif else begin

    contour, (*(self.pdata.plot_ptr[iplot])).z, $
      position=[0,0,1,1], xrange=xrange, yrange=yrange, $
      xstyle=5, ystyle=5, /noerase, $
      _extra = (*(self.pdata.plot_ptr[iplot])).options, /follow

  endelse

  self->resetwindow
  (*self.state).newrefresh=1
end

;---------------------------------------------------------------------

pro GPItv::plot1compass, iplot


  ; Uses idlastro routine arrows to plot compass arrows.


  self->setwindow, (*self.state).draw_window_id

  widget_control, /hourglass

  arrows, *((*self.state).exthead_ptr), $
    (*(self.pdata.plot_ptr[iplot])).x, $
    (*(self.pdata.plot_ptr[iplot])).y, $
    thick = (*(self.pdata.plot_ptr[iplot])).thick, $
    charsize = (*(self.pdata.plot_ptr[iplot])).charsize, $
    arrowlen = (*(self.pdata.plot_ptr[iplot])).arrowlen, $
    color = (*(self.pdata.plot_ptr[iplot])).color, $
    notvertex = (*(self.pdata.plot_ptr[iplot])).notvertex, $
    /data

  self->resetwindow
  (*self.state).newrefresh=1
end

;---------------------------------------------------------------------

pro GPItv::plot1scalebar, iplot

  ; uses modified version of idlastro routine arcbar to plot a scalebar


  self->setwindow, (*self.state).draw_window_id
  widget_control, /hourglass

  ; routine arcbar doesn't recognize color=0, because it uses
  ; keyword_set to check the color.  So we need to set !p.color = 0
  ; to get black if the user wants color=0

  !p.color = 0

  self->arcbar, *((*self.state).head_ptr), $
    (*(self.pdata.plot_ptr[iplot])).arclen, $
    position = (*(self.pdata.plot_ptr[iplot])).position, $
    thick = (*(self.pdata.plot_ptr[iplot])).thick, $
    size = (*(self.pdata.plot_ptr[iplot])).size, $
    color = (*(self.pdata.plot_ptr[iplot])).color, $
    seconds = (*(self.pdata.plot_ptr[iplot])).seconds, $
    /data

  self->resetwindow
  (*self.state).newrefresh=1
end

;----------------------------------------------------------------------

pro GPItv::arcbar, hdr, arclen, LABEL = label, SIZE = size, THICK = thick, $
  DATA =data, COLOR = color, POSITION = position, $
  NORMAL = normal, SECONDS=SECONDS


  ; This is a copy of the IDL Astronomy User's Library routine 'arcbar',
  ; abbreviated for GPItv and modified to work with zoomed images.  For
  ; the revision history of the original arcbar routine, look at
  ; arcbar.pro in the pro/astro subdirectory of the IDL Astronomy User's
  ; Library.

  ; Modifications for GPItv:
  ; Modified to work with zoomed GPItv images, AJB Jan. 2000
  ; Moved text label upwards a bit for better results, AJB Jan. 2000

  extast, hdr, bastr, noparams    ;extract astrom params in deg.

  if N_params() LT 2 then arclen = 1 ;default size = 1 arcmin

  if not keyword_set( SIZE ) then size = 1.0
  if not keyword_set( THICK ) then thick = !P.THICK
  if not keyword_set( COLOR ) then color = !P.COLOR

  a = bastr.crval[0]
  d = bastr.crval[1]
  if keyword_set(seconds) then factor = 3600.0d else factor = 60.0
  d1 = d + (1/factor)             ;compute x,y of crval + 1 arcmin

  proj = strmid(bastr.ctype[0],5,3)

  case proj of
    'GSS': gsssadxy, bastr, [a,a], [d,d1], x, y
    else:  ad2xy, [a,a], [d,d1], bastr, x, y
  endcase

  dmin = sqrt( (x[1]-x[0])^2 + (y[1]-y[0])^2 ) ;det. size in pixels of 1 arcmin

  if (!D.FLAGS AND 1) EQ 1 then begin ;Device have scalable pixels?
    if !X.s[1] NE 0 then begin
      dmin = convert_coord( dmin, 0, /DATA, /TO_DEVICE) - $
        convert_coord(    0, 0, /DATA, /TO_DEVICE) ;Fixed Apr 97
      dmin = dmin[0]
    endif else dmin = dmin/gpi_get_keyword(h, e, 'NAXIS1' ) ;Fixed Oct. 96
  endif else  dmin = dmin * (*self.state).zoom_factor    ; added by AJB Jan. '00

  dmini2 = round(dmin * arclen)

  if keyword_set(NORMAL) then begin
    posn = convert_coord(position,/NORMAL, /TO_DEVICE)
    xi = posn[0] & yi = posn[1]
  endif else if keyword_set(DATA) then begin
    posn = convert_coord(position,/DATA, /TO_DEVICE)
    xi = posn[0] & yi = posn[1]
  endif else begin
    xi = position[0]   & yi = position[1]
  endelse


  xf = xi + dmini2
  dmini3 = dmini2/10       ;Height of vertical end bars = total length/10.

  plots,[xi,xf],[yi,yi], COLOR=color, /DEV, THICK=thick
  plots,[xf,xf],[ yi+dmini3, yi-dmini3 ], COLOR=color, /DEV, THICK=thick
  plots,[xi,xi],[ yi+dmini3, yi-dmini3 ], COLOR=color, /DEV, THICK=thick

  if not keyword_set(Seconds) then begin
    if (!D.NAME EQ 'PS') and (!P.FONT EQ 0) then $ ;Postscript Font?
      arcsym='!9'+string(162B)+'!X' else arcsym = "'"
  endif else begin
    if (!D.NAME EQ 'PS') and (!P.FONT EQ 0) then $ ;Postscript Font?
      arcsym = '!9'+string(178B)+'!X' else arcsym = "''"
  endelse
  if not keyword_set( LABEL) then begin
    if (arclen LT 1) then arcstr = string(arclen,format='(f4.2)') $
    else arcstr = string(arclen)
    label = strtrim(arcstr,2) + arcsym
  endif

  ; AJB modified this to move the numerical label upward a bit: 5/8/2000
  xyouts,(xi+xf)/2, (yi+(dmini2/10)), label, SIZE = size,COLOR=color,$
    /DEV, alignment=.5, CHARTHICK=thick

  return
end

;----------------------------------------------------------------------

pro GPItv::plotwindow
  ; Set up the plot window to have X and Y coordinates for overplotting.

  self->setwindow, (*self.state).draw_window_id

  xrange=[(*self.state).offset[0], $
    (*self.state).offset[0] + !d.x_size / (*self.state).zoom_factor] - 0.5
  yrange=[(*self.state).offset[1], $
    (*self.state).offset[1] + !d.y_size / (*self.state).zoom_factor] - 0.5

  plot, [0], [0], /nodata, position=[0,0,1,1], $
    xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, /noerase

  self->resetwindow
end

;----------------------------------------------------------------------

pro GPItv::plotall

  ; Routine to overplot all line, text, and contour plots

  if ((self.pdata.nplot + (*self.state).mark_sat_spots)  EQ 0) then return

  self->setwindow, (*self.state).draw_window_id

  self->plotwindow

  for iplot = 1, self.pdata.nplot do begin
    case (*(self.pdata.plot_ptr[iplot])).type of
      'points'  : self->plot1plot, iplot
      'text'    : self->plot1text, iplot
      'arrow'   : self->plot1arrow, iplot
      'contour' : self->plot1contour, iplot
      'compass' : self->plot1compass, iplot
      'scalebar': self->plot1scalebar, iplot
      'region'  : self->plot1region, iplot
      'wcsgrid' : self->plot1wcsgrid, iplot
      'polarization' : self->plot1pol, iplot
      'wavecalgrid' : self->plot1wavecalgrid, iplot
      'colorbar': self->plot1colorbar, iplot
      else      : self->message, msgtype='error','Problem in self->plotall!'
    endcase
  endfor

  ; special case: sat spots
  ; This is handled via a menu state toggle rather than an 
  ; annotation, because that's a nicer user interface, and
  ; lets the setting persist when switching cubes.
  if (*self.state).mark_sat_spots then self->plot1satspots

  self->resetwindow

end

;----------------------------------------------------------------------

pro GPItv::plot, x, y, _extra = options

  ; Routine to read in line plot data and options, store in a heap
  ; variable structure, and plot the line plot


  ;if (not(xregistered(self.xname,/noshow))) then begin
  ;    self->message, msgtype='error','You need to start GPItv first!'
  ;    return
  ;endif

  if (N_params() LT 1) then begin
    self->message, msgtype='error', 'Too few parameters for GPItvPLOT.'
    return
  endif

  if (n_elements(options) EQ 0) then options = {color: 'red'}

  if (self.pdata.nplot LT self.pdata.maxplot) then begin
    self.pdata.nplot = self.pdata.nplot + 1

    ;  convert color names to index numbers, and set default=red
    c = where(tag_names(options) EQ 'COLOR', count)
    if (count EQ 0) then options = create_struct(options, 'color', 'red')
    options.color = self->icolor(options.color)

    pstruct = {type: 'points',   $     ; points
      x: x,             $     ; x coordinate
      y: y,             $     ; y coordinate
      options: options  $     ; plot keyword options
    }

    self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)

    self->plotwindow
    self->plot1plot, self.pdata.nplot

  endif else begin
    self->message, msgtype='error', 'Too many calls to GPItvPLOT.'
  endelse

end

;----------------------------------------------------------------------

pro GPItv::xyouts, x, y, text, _extra = options

  ; Routine to read in text overplot string and options, store in a heap
  ; variable structure, and overplot the text


  ;if (not(xregistered(self.xname, /noshow))) then begin
  ;    self->message, msgtype='error', 'You need to start GPItv first!'
  ;    return
  ;endif

  if (N_params() LT 3) then begin
    self->message, msgtype='error', 'Too few parameters for GPItvXYOUTS'
    return
  endif

  if (n_elements(options) EQ 0) then options = {color: 'red'}

  if (self.pdata.nplot LT self.pdata.maxplot) then begin
    self.pdata.nplot = self.pdata.nplot + 1

    ;  convert color names to index numbers, and set default=red
    c = where(tag_names(options) EQ 'COLOR', count)
    if (count EQ 0) then options = create_struct(options, 'color', 'red')
    options.color = self->icolor(options.color)

    ;  set default font to 1
    c = where(tag_names(options) EQ 'FONT', count)
    if (count EQ 0) then options = create_struct(options, 'font', 1)

    pstruct = {type: 'text',   $       ; type of plot
      x: x,             $     ; x coordinate
      y: y,             $     ; y coordinate
      text: text,       $     ; text to plot
      options: options  $     ; plot keyword options
    }

    self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)

    self->plotwindow
    self->plot1text, self.pdata.nplot

  endif else begin
    self->message, msgtype='error', 'Too many calls to GPItvPLOT.'
  endelse

end

;----------------------------------------------------------------------

pro GPItv::arrow, x1, y1, x2, y2, _extra = options

  ; Routine to read in arrow overplot options, store in a heap
  ; variable structure, and overplot the arrow


  ;if (not(xregistered(self.xname, /noshow))) then begin
  ;    self->message, msgtype='error', 'You need to start GPItv first!'
  ;    return
  ;endif

  if (N_params() LT 4) then begin
    self->message, msgtype='error', 'Too few parameters for GPItvARROW'
    return
  endif

  if (n_elements(options) EQ 0) then options = {color: 'red'}

  if (self.pdata.nplot LT self.pdata.maxplot) then begin
    self.pdata.nplot = self.pdata.nplot + 1

    ;  convert color names to index numbers, and set default=red
    c = where(tag_names(options) EQ 'COLOR', count)
    if (count EQ 0) then options = create_struct(options, 'color', 'red')
    options.color = self->icolor(options.color)

    pstruct = {type: 'arrow',   $       ; type of plot
      x1: x1,             $     ; x1 coordinate
      y1: y1,             $     ; y1 coordinate
      x2: x2,             $     ; x2 coordinate
      y2: y2,             $     ; y2 coordinate
      options: options  $     ; plot keyword options
    }

    self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)

    self->plotwindow
    self->plot1arrow, self.pdata.nplot

  endif else begin
    self->message, msgtype='error', 'Too many calls to GPItvPLOT.'
  endelse

end

;----------------------------------------------------------------------

pro GPItv::regionfile, region_file

  ; Routine to read in region filename, store in a heap variable
  ; structure, and overplot the regions


  ;if (not(xregistered(self.xname, /noshow))) then begin
  ;    self->message, msgtype='error', 'You need to start GPItv first!'
  ;    return
  ;endif

  if (self.pdata.nplot LT self.pdata.maxplot) then begin
    self.pdata.nplot = self.pdata.nplot + 1

    options = {color: 'green'}
    options.color = self->icolor(options.color)

    readfmt, region_file, 'a200', reg_array, /silent

    pstruct = {type:'region', $            ; type of plot
      reg_array: reg_array, $     ; array of regions to plot
      options: options $          ; plot keyword options
    }

    self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)

    self->plotwindow
    self->plot1region, self.pdata.nplot

  endif else begin
    self->message, msgtype='error', 'Too many calls to GPItvPLOT.'
  endelse

end

;----------------------------------------------------------------------

pro GPItv::regionlabel_event, event

  ; Event handler for self->regionlabel.  Region plot structure created from
  ; information in form widget.  Plotting routine GPItv_plot1region is
  ; then called.

  @gpitv_err

  CASE event.tag OF

    'REG_OPT' : BEGIN
      CASE event.value OF
        '0' : BEGIN
          widget_control,(*(*self.state).reg_ids_ptr)[3],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[4],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[5],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[6],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[7],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[8],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[9],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[10],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[11],Sensitive=0
        END
        '1' : BEGIN
          widget_control,(*(*self.state).reg_ids_ptr)[3],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[4],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[5],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[6],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[7],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[8],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[9],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[10],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[11],Sensitive=1
        END
        '2' : BEGIN
          widget_control,(*(*self.state).reg_ids_ptr)[3],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[4],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[5],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[6],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[7],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[8],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[9],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[10],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[11],Sensitive=1
        END
        '3' : BEGIN
          widget_control,(*(*self.state).reg_ids_ptr)[3],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[4],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[5],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[6],Sensitive=0
          widget_control,(*(*self.state).reg_ids_ptr)[7],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[8],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[9],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[10],Sensitive=1
          widget_control,(*(*self.state).reg_ids_ptr)[11],Sensitive=0
        END
        ELSE:
      ENDCASE

    END

    'QUIT': BEGIN
      if ptr_valid((*self.state).reg_ids_ptr) then ptr_free, (*self.state).reg_ids_ptr
      widget_control, event.top, /destroy
    END

    'DRAW': BEGIN
      IF (self.pdata.nplot LT self.pdata.maxplot) then begin

        self.pdata.nplot = self.pdata.nplot + 1

        reg_type = ['circle','box','ellipse','line']
        reg_color = ['red','black','green','blue','cyan','magenta', $
          'yellow','white']
        coords_type = ['Pixel', 'J2000','B1950', $
          'Galactic','Ecliptic', 'Native']
        reg_index = widget_info((*(*self.state).reg_ids_ptr)[0], /droplist_select)
        color_index = widget_info((*(*self.state).reg_ids_ptr)[1], /droplist_select)
        coords_index = widget_info((*(*self.state).reg_ids_ptr)[2], /droplist_select)
        widget_control,(*(*self.state).reg_ids_ptr)[3],get_value=xcenter
        widget_control,(*(*self.state).reg_ids_ptr)[4],get_value=ycenter
        widget_control,(*(*self.state).reg_ids_ptr)[5],get_value=xwidth
        widget_control,(*(*self.state).reg_ids_ptr)[6],get_value=ywidth
        widget_control,(*(*self.state).reg_ids_ptr)[7],get_value=x1
        widget_control,(*(*self.state).reg_ids_ptr)[8],get_value=y1
        widget_control,(*(*self.state).reg_ids_ptr)[9],get_value=x2
        widget_control,(*(*self.state).reg_ids_ptr)[10],get_value=y2
        widget_control,(*(*self.state).reg_ids_ptr)[11],get_value=angle
        widget_control,(*(*self.state).reg_ids_ptr)[12],get_value=thick
        widget_control,(*(*self.state).reg_ids_ptr)[13],get_value=text_str
        text_str = strcompress(text_str[0],/remove_all)

        CASE reg_type[reg_index] OF

          'circle': BEGIN
            region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
              ycenter + ', ' + xwidth
            if (coords_index ne 0 and coords_index ne 5) then $
              region_str = region_str + ', ' + coords_type[coords_index]
            region_str = region_str + ') # color=' + reg_color[color_index]
          END

          'box': BEGIN
            region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
              ycenter + ', ' + xwidth + ', ' + ywidth + ', ' + angle
            if (coords_index ne 0 and coords_index ne 5) then $
              region_str = region_str + ', ' + coords_type[coords_index]
            region_str = region_str + ') # color=' + reg_color[color_index]
          END

          'ellipse': BEGIN
            region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
              ycenter + ', ' + xwidth + ', ' + ywidth + ', ' + angle
            if (coords_index ne 0 and coords_index ne 5) then $
              region_str = region_str + ', ' + coords_type[coords_index]
            region_str = region_str + ') # color=' + reg_color[color_index]
          END

          'line': BEGIN
            region_str = reg_type[reg_index] + '(' + x1 + ', ' + y1 + ', ' + $
              x2 + ', ' + y2
            if (coords_index ne 0 and coords_index ne 5) then $
              region_str = region_str + ', ' + coords_type[coords_index]
            region_str = region_str + ') # color=' + reg_color[color_index]
          END
        ENDCASE

        if (text_str ne '') then region_str = region_str + $
          'text={' + text_str + '}'

        options = {color: reg_color[color_index], $
          thick:thick}
        options.color = self->icolor(options.color)

        pstruct = {type:'region', $          ;type of plot
          reg_array:[region_str], $ ;region array to plot
          options: options $
        }

        self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)

        self->plotwindow
        self->plot1region, self.pdata.nplot

      ENDIF ELSE BEGIN
        self->message, msgtype='error', 'Too many calls to GPItvPLOT.'
      ENDELSE

      ;       if ptr_valid((*self.state).reg_ids_ptr) then ptr_free, (*self.state).reg_ids_ptr
      ;       widget_control, event.top, /destroy

    END

    ELSE:
  ENDCASE

end

;----------------------------------------------------------------------

pro GPItv::wcsgrid, _extra = options


  ; Routine to read in wcs overplot options, store in a heap variable
  ; structure, and overplot the grid

  ;if (not(xregistered(self.xname, /noshow))) then begin
  ;    self->message, msgtype='error', 'You need to start GPItv first!'
  ;    return
  ;endif

  if (self.pdata.nplot LT self.pdata.maxplot) then begin
    self.pdata.nplot = self.pdata.nplot + 1

    ; set default font to 1
    c = where(tag_names(options) EQ 'FONT', count)
    if (count EQ 0) then options = create_struct(options, 'font', 1)

    pstruct = {type:'wcsgrid', $            ; type of plot
      options: options $           ; plot keyword options
    }

    self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)

    self->plotwindow
    self->plot1wcsgrid, self.pdata.nplot

  endif else begin
    self->message, msgtype='error', 'Too many calls to GPItvPLOT.'
  endelse

end
;----------------------------------------------------------------------

pro GPItv::wavecalgrid, _extra = options

  ; Routine to read in wavecal overplot options, store in a heap variable
  ; structure, and overplot the grid


  ;if (not(xregistered(self.xname, /noshow))) then begin
  ;    self->message, msgtype='error', 'You need to start GPItv first!'
  ;    return
  ;endif


  if (self.pdata.nplot LT self.pdata.maxplot) then begin
    self.pdata.nplot = self.pdata.nplot + 1

    ; set default font to 1
    if ~(keyword_set(options)) then  options = create_struct(options, 'dummy', 1)
    c = where(tag_names(options) EQ 'FONT', count)
    if (count EQ 0) then options = create_struct(options, 'font', 1)

    pstruct = {type:'wavecalgrid', $            ; type of plot
      options: options $           ; plot keyword options
    }

    self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)

    self->plotwindow
    self->plot1wavecalgrid, self.pdata.nplot

  endif else begin
    self->message, msgtype='error', 'Too many calls to GPItvPLOT.'
  endelse

end
;----------------------------------------------------------------------

function gpitv::set_spaces, minval, spacing, number, extra, spaces
  ; Routine to set tick lines about image


  ; Actually set the number of tick marks to 4 more than what should be drawn to
  ; have marks at either edge

  number = number + extra
  if (minval eq -90.) then offset = 0 else if (extra lt 0.) then $
    offset = -extra else offset = float(extra/2.0)
  spaces = (indgen(number) - offset) * spacing + $
    round(minval/spacing) * spacing
  return, number
end

;----------------------------------------------------------------------

;----------------------------------------------------------------------
pro GPItv::find_spacing, range, number, coord_type, spacing


  ; range : coordinate range of image in degrees
  ; number : number of lines
  ; coord_type : 0= h m s
  ;              1= decimal degrees
  ;
  ; spacing : array containing coordinate spacing of lines

  ; Determine tick spacing in coordinate units
  ; Need not to round up if a coordinate range is complete, otherwise, there is
  ; an offset between coordinate lines which should overlap
  tx = range / number

  ; Need to find best spacing to use (in terms of some reasonable multiples
  ; of the coordinate units , this is assuming that the units are in degrees

  if (tx gt 50.0) then tx = round(tx/5.0) * 5.0 else $
    if (tx gt 10.0) then tx = round(tx) * 1.0 else $
    if (tx gt 1.0) then tx = round(tx/0.5) * 0.5 else $

    if (coord_type eq 0) then begin
    if (tx gt 0.5) then tx = round(tx/(10.0/60.0)) * (10.0/60.0) else $
      if (tx gt 10.0/60.0) then tx = round(tx/(2.0/60.0)) * (2.0/60.0) else $
      if (tx gt 5.0/60.0) then tx = round(tx/(1.0/60.0)) * (1.0/60.0) else $
      if (tx gt 1.0/60.0) then tx = round(tx/(0.5/60.0)) * (0.5/60.0) else $
      if (tx gt 0.5/60.0) then tx = round(tx/(10.0/3600.0)) * (10.0/3600.0) else $
      if (tx gt 10.0/3600.0) then tx = round(tx/(1.0/3600.0)) * (1.0/3600.0) $
    else tx = round(tx/(1.0/36000.0)) * (1.0/36000.0)
  endif else begin
    if (tx gt 0.5) then tx = round(tx/0.2) * 0.2 else $
      if (tx gt 0.1) then tx = round(tx/0.1) * 0.1 else $
      if (tx gt 0.05) then tx = round(tx/0.05) * 0.05 else $
      if (tx gt 0.01) then tx = round(tx/0.01) * 0.01 else $
      if (tx gt 0.005) then tx = round(tx/0.005) * 0.005 else $
      if (tx gt 0.001) then tx = round(tx/0.001) * 0.001 else $
      if (tx gt 0.0005) then tx = round(tx/0.0005) * 0.0005 $
    else tx = round(tx/0.0001) * 0.0001
  endelse

  spacing = tx
  return

end

;----------------------------------------------------------------------

pro GPItv::plot1wcsgrid, iplot


  wcslabelcolor = (*(self.pdata.plot_ptr[iplot])).options.wcslabelcolor
  gridcolor = (*(self.pdata.plot_ptr[iplot])).options.gridcolor
  charsize = (*(self.pdata.plot_ptr[iplot])).options.charsize
  charthick = (*(self.pdata.plot_ptr[iplot])).options.charthick

  if (NOT ptr_valid((*self.state).astr_ptr)) then begin
    self->erase, 1
    self->message, 'Cannot Display WCS Grid On Image Without WCS Coordinates.', $
      msgtype = 'error', /window
    return
  endif

  headtype = strmid((*(*self.state).astr_ptr).ctype[0], 0, 4)

  if ((*self.state).wcstype EQ 'angle') then begin

    ; Create local header variable to use for WCS grid.
    hdr = *((*self.state).head_ptr)

    ; need numerical equinox values
    IF ((*self.state).equinox EQ 'J2000') THEN num_equinox = 2000.0 ELSE $
      IF ((*self.state).equinox EQ 'B1950') THEN num_equinox = 1950.0 ELSE $
      num_equinox = float((*self.state).equinox)

    IF ((*self.state).display_equinox EQ 'J2000') THEN num_disp_equinox = 2000.0 ELSE $
      IF ((*self.state).display_equinox EQ 'B1950') THEN num_disp_equinox = 1950.0 ELSE $
      num_disp_equinox = float((*self.state).equinox)

    ; Add EQUINOX to hdr if it does not exist in order to precess to
    ; display equinox
    year = GET_EQUINOX(hdr, code)    ;YEAR of hdr equinox
    IF code EQ -1 THEN $
      sxaddpar, hdr, 'EQUINOX', num_equinox

    IF (num_equinox ne 2000.0) THEN $
      hprecess, hdr, 2000.0

    ; Now convert the hdr variable to the display coordinate system
    CASE (*self.state).display_coord_sys OF
      'RA--': heuler, hdr, /celestial
      'GLON': heuler, hdr, /galactic
      'ELON': heuler, hdr, /ecliptic
      ELSE:
    ENDCASE

    ; Now precess header to display equinox
    IF (num_equinox ne num_disp_equinox) THEN $
      hprecess, hdr, num_disp_equinox

    ; Extract an astrometry structure from hdr variable
    extast, hdr, astr

    ; Now operate on hdr variable to find grid coordinates, spacing, etc.

    x=findgen(n_elements((*self.images.main_image)[*,0]))
    nx = n_elements((*self.images.main_image)[*,0])
    y=findgen(n_elements((*self.images.main_image)[0,*]))
    ny = n_elements((*self.images.main_image)[0,*])

    x_bottom = x
    y_bottom = 0.
    x_top = x
    y_top = ny - 1
    x_left = 0.
    y_left = y
    x_right = nx - 1
    y_right = y

    xy2ad, x_bottom, y_bottom, astr, lon_bottom, lat_bottom
    xy2ad, x_top, y_top, astr, lon_top, lat_top
    xy2ad, x_left, y_left, astr, lon_left, lat_left
    xy2ad, x_right, y_right, astr, lon_right, lat_right

    ; Now create min/max lon/lat arrays
    lon_min = min([lon_bottom,lon_top,lon_left,lon_right])
    lon_max = max([lon_bottom,lon_top,lon_left,lon_right])
    lat_min = min([lat_bottom,lat_top,lat_left,lat_right])
    lat_max = max([lat_bottom,lat_top,lat_left,lat_right])

    ; Search for the poles for currently displayed coordinate system.
    ; Get positions of North and South Poles and check if in the image.
    ad2xy, 0., 90., astr, x_npole, y_npole
    ad2xy, 0., -90., astr, x_spole, y_spole

    north_diff = abs(90. - lat_max)
    south_diff = abs(-90. - lat_max)

    if (x_npole gt 0. and x_npole lt x_right and $
      y_npole gt 0. and y_npole lt y_top and $
      north_diff lt south_diff) then lat_max = 90.

    if (x_spole gt 0. and x_spole lt x_right and $
      y_spole gt 0. and y_spole lt y_top and $
      north_diff gt south_diff) then lat_min = -90.

    ; Adjust deltalon, lon_min, lon_max when Meridian in image.

    IF (round(lon_min) eq 0 AND round(lon_max) eq 360 AND $
      lat_min ne -90. AND lat_max ne 90.) THEN BEGIN

      ind_bottom = where(lon_bottom gt 180. AND lon_bottom lt 360.,count_bottom)
      ind_top = where(lon_top gt 180. AND lon_top lt 360.,count_top)
      ind_left = where(lon_left gt 180. AND lon_left lt 360.,count_left)
      ind_right = where(lon_right gt 180. AND lon_right lt 360.,count_right)
      if count_bottom ne 0 then $
        lon_bottom[ind_bottom] = lon_bottom[ind_bottom] - 360.
      if count_top ne 0 then $
        lon_top[ind_top] = lon_top[ind_top] - 360.
      if count_left ne 0 then $
        lon_left[ind_left] = lon_left[ind_left] - 360.
      if count_right ne 0 then $
        lon_right[ind_right] = lon_right[ind_right] - 360.
      lon_min = min([lon_bottom,lon_top,lon_left,lon_right])
      lon_max = max([lon_bottom,lon_top,lon_left,lon_right])

    ENDIF

    deltalon = lon_max - lon_min
    deltalat = lat_max - lat_min

    CASE ((*self.state).display_base60) OF
      0: BEGIN
        self->find_spacing, deltalat, 5, 1, lat_spacing
        lat_tics = self->set_spaces(lat_min, lat_spacing, 13, 0, lat_spaces)
        self->find_spacing, deltalon, 5, 5, lon_spacing
        lon_tics = self->set_spaces(lon_min, lon_spacing, 13, 0, lon_spaces)
      END
      1: BEGIN
        self->find_spacing, deltalat, 5, 0, lat_spacing
        lat_tics = self->set_spaces(lat_min, lat_spacing, 13, 0, lat_spaces)
        self->find_spacing, deltalon, 5, 1, lon_spacing
        lon_tics = self->set_spaces(lon_min, lon_spacing, 13, 0, lon_spaces)
      END
      ELSE:
    ENDCASE

    ; Make adjustments when Pole is in image
    if (lat_min eq -90. or lat_max eq 90.) then begin
      lon_spaces=[0.,30.,60.,90.,120.,150.,180.,210.,240.,270.,300.,330.,360.]

      tmp_index = where(lat_spaces gt 90., tmpcnt)
      if tmpcnt ne 0 then $
        lat_spaces[tmp_index] = ((90 - (lat_spaces[tmp_index] - 90.)))
    endif

    v0 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat0 = replicate(lat_spaces[0],n_elements((*self.images.main_image)[*,1]))

    v1 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat1 = replicate(lat_spaces[1],n_elements((*self.images.main_image)[*,1]))

    v2 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat2 = replicate(lat_spaces[2],n_elements((*self.images.main_image)[*,1]))

    v3 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat3 = replicate(lat_spaces[3],n_elements((*self.images.main_image)[*,1]))

    v4 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat4 = replicate(lat_spaces[4],n_elements((*self.images.main_image)[*,1]))

    v5 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat5 = replicate(lat_spaces[5],n_elements((*self.images.main_image)[*,1]))

    v6 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat6 = replicate(lat_spaces[6],n_elements((*self.images.main_image)[*,1]))

    v7 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat7 = replicate(lat_spaces[7],n_elements((*self.images.main_image)[*,1]))

    v8 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat8 = replicate(lat_spaces[8],n_elements((*self.images.main_image)[*,1]))

    v9 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat9 = replicate(lat_spaces[9],n_elements((*self.images.main_image)[*,1]))

    v10 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat10 = replicate(lat_spaces[10],n_elements((*self.images.main_image)[*,1]))

    v11 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat11 = replicate(lat_spaces[11],n_elements((*self.images.main_image)[*,1]))

    v12 = findgen(n_elements((*self.images.main_image)[*,1])) * deltalon / $
      (n_elements((*self.images.main_image)[*,1])-1) + lon_min
    vlat12 = replicate(lat_spaces[12],n_elements((*self.images.main_image)[*,1]))



    vv0 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon0 = replicate(lon_spaces[0],n_elements((*self.images.main_image)[1,*]))

    vv1 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon1 = replicate(lon_spaces[1],n_elements((*self.images.main_image)[1,*]))

    vv2 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon2 = replicate(lon_spaces[2],n_elements((*self.images.main_image)[1,*]))

    vv3 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon3 = replicate(lon_spaces[3],n_elements((*self.images.main_image)[1,*]))

    vv4 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon4 = replicate(lon_spaces[4],n_elements((*self.images.main_image)[1,*]))

    vv5 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon5 = replicate(lon_spaces[5],n_elements((*self.images.main_image)[1,*]))

    vv6 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon6 = replicate(lon_spaces[6],n_elements((*self.images.main_image)[1,*]))

    vv7 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon7 = replicate(lon_spaces[7],n_elements((*self.images.main_image)[1,*]))

    vv8 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon8 = replicate(lon_spaces[8],n_elements((*self.images.main_image)[1,*]))

    vv9 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon9 = replicate(lon_spaces[9],n_elements((*self.images.main_image)[1,*]))

    vv10 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon10 = replicate(lon_spaces[10],n_elements((*self.images.main_image)[1,*]))

    vv11 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon11 = replicate(lon_spaces[11],n_elements((*self.images.main_image)[1,*]))

    vv12 = findgen(n_elements((*self.images.main_image)[1,*])) * deltalat / $
      (n_elements((*self.images.main_image)[1,*])-1) + lat_min
    vlon12 = replicate(lon_spaces[12],n_elements((*self.images.main_image)[1,*]))


    ; When Meridian in image, negative lon_spaces exist--add 360
    tmp = where(lon_spaces lt 0., tmp_cnt)
    if tmp_cnt ne 0 then lon_spaces[tmp] = lon_spaces[tmp] + 360.

    ad2xy, v0, vlat0, astr, xlat0, ylat0
    ad2xy, v1, vlat1, astr, xlat1, ylat1
    ad2xy, v2, vlat2, astr, xlat2, ylat2
    ad2xy, v3, vlat3, astr, xlat3, ylat3
    ad2xy, v4, vlat4, astr, xlat4, ylat4
    ad2xy, v5, vlat5, astr, xlat5, ylat5
    ad2xy, v6, vlat6, astr, xlat6, ylat6
    ad2xy, v7, vlat7, astr, xlat7, ylat7
    ad2xy, v8, vlat8, astr, xlat8, ylat8
    ad2xy, v9, vlat9, astr, xlat9, ylat9
    ad2xy, v10, vlat10, astr, xlat10, ylat10
    ad2xy, v11, vlat11, astr, xlat11, ylat11
    ad2xy, v12, vlat12, astr, xlat12, ylat12

    ad2xy, vlon0, vv0, astr,  xlon0, ylon0
    ad2xy, vlon1, vv1, astr,  xlon1, ylon1
    ad2xy, vlon2, vv2, astr,  xlon2, ylon2
    ad2xy, vlon3, vv3, astr,  xlon3, ylon3
    ad2xy, vlon4, vv4, astr,  xlon4, ylon4
    ad2xy, vlon5, vv5, astr,  xlon5, ylon5
    ad2xy, vlon6, vv6, astr,  xlon6, ylon6
    ad2xy, vlon7, vv7, astr,  xlon7, ylon7
    ad2xy, vlon8, vv8, astr,  xlon8, ylon8
    ad2xy, vlon9, vv9, astr,  xlon9, ylon9
    ad2xy, vlon10, vv10, astr,  xlon10, ylon10
    ad2xy, vlon11, vv11, astr,  xlon11, ylon11
    ad2xy, vlon12, vv12, astr,  xlon12, ylon12

    ad2xy, lon_spaces[2], lat_spaces[0], astr, x_latline0, y_latline0
    ad2xy, lon_spaces[2], lat_spaces[1], astr, x_latline1, y_latline1
    ad2xy, lon_spaces[2], lat_spaces[2], astr, x_latline2, y_latline2
    ad2xy, lon_spaces[2], lat_spaces[3], astr, x_latline3, y_latline3
    ad2xy, lon_spaces[2], lat_spaces[4], astr, x_latline4, y_latline4
    ad2xy, lon_spaces[2], lat_spaces[5], astr, x_latline5, y_latline5
    ad2xy, lon_spaces[2], lat_spaces[6], astr, x_latline6, y_latline6
    ad2xy, lon_spaces[2], lat_spaces[7], astr, x_latline7, y_latline7
    ad2xy, lon_spaces[2], lat_spaces[8], astr, x_latline8, y_latline8
    ad2xy, lon_spaces[2], lat_spaces[9], astr, x_latline9, y_latline9
    ad2xy, lon_spaces[2], lat_spaces[10], astr, x_latline10, y_latline10
    ad2xy, lon_spaces[2], lat_spaces[11], astr, x_latline11, y_latline11
    ad2xy, lon_spaces[2], lat_spaces[12], astr, x_latline12, y_latline12

    ad2xy, lon_spaces[0], lat_spaces[2], astr, x_lonline0, y_lonline0
    ad2xy, lon_spaces[1], lat_spaces[2], astr, x_lonline1, y_lonline1
    ad2xy, lon_spaces[2], lat_spaces[2], astr, x_lonline2, y_lonline2
    ad2xy, lon_spaces[3], lat_spaces[2], astr, x_lonline3, y_lonline3
    ad2xy, lon_spaces[4], lat_spaces[2], astr, x_lonline4, y_lonline4
    ad2xy, lon_spaces[5], lat_spaces[2], astr, x_lonline5, y_lonline5
    ad2xy, lon_spaces[6], lat_spaces[2], astr, x_lonline6, y_lonline6
    ad2xy, lon_spaces[7], lat_spaces[2], astr, x_lonline7, y_lonline7
    ad2xy, lon_spaces[8], lat_spaces[2], astr, x_lonline8, y_lonline8
    ad2xy, lon_spaces[9], lat_spaces[2], astr, x_lonline9, y_lonline9
    ad2xy, lon_spaces[10], lat_spaces[2], astr, x_lonline10, y_lonline10
    ad2xy, lon_spaces[11], lat_spaces[2], astr, x_lonline11, y_lonline11
    ad2xy, lon_spaces[12], lat_spaces[2], astr, x_lonline12, y_lonline12

    ; Determine orientation for labels

    xlat2_diff = abs(xlat2 - x_latline2[0])
    ylat2_diff = abs(ylat2 - y_latline2[0])
    xlat2_diff_index = where(xlat2_diff eq min(xlat2_diff))
    ylat2_diff_index = where(ylat2_diff eq min(ylat2_diff))
    x1 = xlat2[xlat2_diff_index]
    y1 = ylat2[xlat2_diff_index]
    x2 = xlat2[xlat2_diff_index+2]
    y2 = ylat2[xlat2_diff_index+2]
    deltax = x1 - x2
    deltay = y1 - y2
    dy_dx = deltay / deltax
    latlabel_orientation = (180./!dpi * atan(dy_dx))

    xlon2_diff = abs(xlon2 - x_lonline2[0])
    ylon2_diff = abs(ylon2 - y_lonline2[0])
    xlon2_diff_index = where(xlon2_diff eq min(xlon2_diff))
    ylon2_diff_index = where(ylon2_diff eq min(ylon2_diff))
    x1 = xlon2[xlon2_diff_index]
    y1 = ylon2[xlon2_diff_index]
    x2 = xlon2[xlon2_diff_index+2]
    y2 = ylon2[xlon2_diff_index+2]
    deltax = x1 - x2
    deltay = y1 - y2
    dy_dx = deltay / deltax
    lonlabel_orientation = (180./!dpi * atan(dy_dx))

    ; Check for label orientations of -90. where divide by 0 occurs
    if (latlabel_orientation[0] eq 0.0) then lonlabel_orientation = -90.
    if (lonlabel_orientation[0] eq 0.0) then latlabel_orientation = -90.

    index_vlat0 = where(xlat0 ge 0.0 AND xlat0 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat0 ge 0.0 AND ylat0 le $
      (n_elements((*self.images.main_image)[0,*])-1),count_vlat0)

    index_vlat1 = where(xlat1 ge 0.0 AND xlat1 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat1 ge 0.0 AND ylat1 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat1)

    index_vlat2 = where(xlat2 ge 0.0 AND xlat2 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat2 ge 0.0 AND ylat2 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat2)

    index_vlat3 = where(xlat3 ge 0.0 AND xlat3 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat3 ge 0.0 AND ylat3 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat3)

    index_vlat4 = where(xlat4 ge 0.0 AND xlat4 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat4 ge 0.0 AND ylat4 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat4)

    index_vlat5 = where(xlat5 ge 0.0 AND xlat5 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat5 ge 0.0 AND ylat5 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat5)

    index_vlat6 = where(xlat6 ge 0.0 AND xlat6 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat6 ge 0.0 AND ylat6 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat6)

    index_vlat7 = where(xlat7 ge 0.0 AND xlat7 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat7 ge 0.0 AND ylat7 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat7)

    index_vlat8 = where(xlat8 ge 0.0 AND xlat8 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat8 ge 0.0 AND ylat8 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat8)

    index_vlat9 = where(xlat9 ge 0.0 AND xlat9 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat9 ge 0.0 AND ylat9 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat9)

    index_vlat10 = where(xlat10 ge 0.0 AND xlat10 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat10 ge 0.0 AND ylat10 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat10)

    index_vlat11 = where(xlat11 ge 0.0 AND xlat11 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat11 ge 0.0 AND ylat11 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat11)

    index_vlat12 = where(xlat12 ge 0.0 AND xlat12 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylat12 ge 0.0 AND ylat12 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlat12)


    count_vlat = [count_vlat0, count_vlat1, count_vlat2, count_vlat3, $
      count_vlat4, count_vlat5, count_vlat6, count_vlat7, $
      count_vlat8, count_vlat9, count_vlat10, count_vlat11, $
      count_vlat12]


    index_vlon0 = where(xlon0 ge 0.0 AND xlon0 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon0 ge 0.0 AND ylon0 le $
      (n_elements((*self.images.main_image)[0,*])-1),count_vlon0)

    index_vlon1 = where(xlon1 ge 0.0 AND xlon1 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon1 ge 0.0 AND ylon1 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon1)

    index_vlon2 = where(xlon2 ge 0.0 AND xlon2 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon2 ge 0.0 AND ylon2 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon2)

    index_vlon3 = where(xlon3 ge 0.0 AND xlon3 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon3 ge 0.0 AND ylon3 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon3)

    index_vlon4 = where(xlon4 ge 0.0 AND xlon4 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon4 ge 0.0 AND ylon4 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon4)

    index_vlon5 = where(xlon5 ge 0.0 AND xlon5 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon5 ge 0.0 AND ylon5 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon5)

    index_vlon6 = where(xlon6 ge 0.0 AND xlon6 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon6 ge 0.0 AND ylon6 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon6)

    index_vlon7 = where(xlon7 ge 0.0 AND xlon7 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon7 ge 0.0 AND ylon7 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon7)

    index_vlon8 = where(xlon8 ge 0.0 AND xlon8 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon8 ge 0.0 AND ylon8 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon8)

    index_vlon9 = where(xlon9 ge 0.0 AND xlon9 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon9 ge 0.0 AND ylon9 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon9)

    index_vlon10 = where(xlon10 ge 0.0 AND xlon10 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon10 ge 0.0 AND ylon10 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon10)

    index_vlon11 = where(xlon11 ge 0.0 AND xlon11 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon11 ge 0.0 AND ylon11 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon11)

    index_vlon12 = where(xlon12 ge 0.0 AND xlon12 le $
      (n_elements((*self.images.main_image)[*,0])-1) AND $
      ylon12 ge 0.0 AND ylon12 le $
      (n_elements((*self.images.main_image)[0,*])-1), count_vlon12)

    count_vlon = [count_vlon0, count_vlon1, count_vlon2, count_vlon3, $
      count_vlon4, count_vlon5, count_vlon6, count_vlon7, $
      count_vlon8, count_vlon9, count_vlon10, count_vlon11, $
      count_vlon12]


    self->setwindow, (*self.state).draw_window_id


    if count_vlat0 ne 0. then plots,xlat0[index_vlat0],ylat0[index_vlat0], $
      color=gridcolor
    if count_vlat1 ne 0. then plots,xlat1[index_vlat1],ylat1[index_vlat1], $
      color=gridcolor
    if count_vlat2 ne 0. then plots,xlat2[index_vlat2],ylat2[index_vlat2], $
      color=gridcolor
    if count_vlat3 ne 0. then plots,xlat3[index_vlat3],ylat3[index_vlat3], $
      color=gridcolor
    if count_vlat4 ne 0. then plots,xlat4[index_vlat4],ylat4[index_vlat4], $
      color=gridcolor
    if count_vlat5 ne 0. then plots,xlat5[index_vlat5],ylat5[index_vlat5], $
      color=gridcolor
    if count_vlat6 ne 0. then plots,xlat6[index_vlat6],ylat6[index_vlat6], $
      color=gridcolor
    if count_vlat7 ne 0. then plots,xlat7[index_vlat7],ylat7[index_vlat7], $
      color=gridcolor
    if count_vlat8 ne 0. then plots,xlat8[index_vlat8],ylat8[index_vlat8], $
      color=gridcolor
    if count_vlat9 ne 0. then plots,xlat9[index_vlat9],ylat9[index_vlat9], $
      color=gridcolor
    if count_vlat10 ne 0. then plots,xlat10[index_vlat10],ylat10[index_vlat10], $
      color=gridcolor
    if count_vlat11 ne 0. then plots,xlat11[index_vlat11],ylat11[index_vlat11], $
      color=gridcolor
    if count_vlat12 ne 0. then plots,xlat12[index_vlat12],ylat12[index_vlat12], $
      color=gridcolor

    if count_vlon0 ne 0. then plots,xlon0[index_vlon0],ylon0[index_vlon0], $
      color=gridcolor
    if count_vlon1 ne 0. then plots,xlon1[index_vlon1],ylon1[index_vlon1], $
      color=gridcolor
    if count_vlon2 ne 0. then plots,xlon2[index_vlon2],ylon2[index_vlon2], $
      color=gridcolor
    if count_vlon3 ne 0. then plots,xlon3[index_vlon3],ylon3[index_vlon3], $
      color=gridcolor
    if count_vlon4 ne 0. then plots,xlon4[index_vlon4],ylon4[index_vlon4], $
      color=gridcolor
    if count_vlon5 ne 0. then plots,xlon5[index_vlon5],ylon5[index_vlon5], $
      color=gridcolor
    if count_vlon6 ne 0. then plots,xlon6[index_vlon6],ylon6[index_vlon6], $
      color=gridcolor
    if count_vlon7 ne 0. then plots,xlon7[index_vlon7],ylon7[index_vlon7], $
      color=gridcolor
    if count_vlon8 ne 0. then plots,xlon8[index_vlon8],ylon8[index_vlon8], $
      color=gridcolor
    if count_vlon9 ne 0. then plots,xlon9[index_vlon9],ylon9[index_vlon9], $
      color=gridcolor
    if count_vlon10 ne 0. then plots,xlon10[index_vlon10],ylon10[index_vlon10], $
      color=gridcolor
    if count_vlon11 ne 0. then plots,xlon11[index_vlon11],ylon11[index_vlon11], $
      color=gridcolor
    if count_vlon12 ne 0. then plots,xlon12[index_vlon12],ylon12[index_vlon12], $
      color=gridcolor

    ; Create label strings for different coordinate systems

    CASE ((*self.state).display_coord_sys) OF

      'RA--': BEGIN

        IF ((*self.state).display_base60 eq 1) THEN BEGIN

          lon0_arr = sixty(lon_spaces[0]/15.)
          lon1_arr = sixty(lon_spaces[1]/15.)
          lon2_arr = sixty(lon_spaces[2]/15.)
          lon3_arr = sixty(lon_spaces[3]/15.)
          lon4_arr = sixty(lon_spaces[4]/15.)
          lon5_arr = sixty(lon_spaces[5]/15.)
          lon6_arr = sixty(lon_spaces[6]/15.)
          lon7_arr = sixty(lon_spaces[7]/15.)
          lon8_arr = sixty(lon_spaces[8]/15.)
          lon9_arr = sixty(lon_spaces[9]/15.)
          lon10_arr = sixty(lon_spaces[10]/15.)
          lon11_arr = sixty(lon_spaces[11]/15.)
          lon12_arr = sixty(lon_spaces[12]/15.)
          lat0_arr = sixty(lat_spaces[0])
          lat1_arr = sixty(lat_spaces[1])
          lat2_arr = sixty(lat_spaces[2])
          lat3_arr = sixty(lat_spaces[3])
          lat4_arr = sixty(lat_spaces[4])
          lat5_arr = sixty(lat_spaces[5])
          lat6_arr = sixty(lat_spaces[6])
          lat7_arr = sixty(lat_spaces[7])
          lat8_arr = sixty(lat_spaces[8])
          lat9_arr = sixty(lat_spaces[9])
          lat10_arr = sixty(lat_spaces[10])
          lat11_arr = sixty(lat_spaces[11])
          lat12_arr = sixty(lat_spaces[12])

          lon0_hh=strcompress(string(fix(lon0_arr[0])),/remove_all)
          lon0_mm=strcompress(string(fix(lon0_arr[1])),/remove_all)
          lon0_ss=strcompress(string(fix(lon0_arr[2])),/remove_all)
          if (strlen(lon0_hh) lt 2) then lon0_hh = '0' + lon0_hh
          if (strlen(lon0_mm) lt 2) then lon0_mm = '0' + lon0_mm
          if (strlen(lon0_ss) lt 2) then lon0_ss = '0' + lon0_ss
          lon0_str = lon0_hh + ':' + lon0_mm + ':' + lon0_ss

          lon1_hh=strcompress(string(fix(lon1_arr[0])),/remove_all)
          lon1_mm=strcompress(string(fix(lon1_arr[1])),/remove_all)
          lon1_ss=strcompress(string(fix(lon1_arr[2])),/remove_all)
          if (strlen(lon1_hh) lt 2) then lon1_hh = '0' + lon1_hh
          if (strlen(lon1_mm) lt 2) then lon1_mm = '0' + lon1_mm
          if (strlen(lon1_ss) lt 2) then lon1_ss = '0' + lon1_ss
          lon1_str = lon1_hh + ':' + lon1_mm + ':' + lon1_ss

          lon2_hh=strcompress(string(fix(lon2_arr[0])),/remove_all)
          lon2_mm=strcompress(string(fix(lon2_arr[1])),/remove_all)
          lon2_ss=strcompress(string(fix(lon2_arr[2])),/remove_all)
          if (strlen(lon2_hh) lt 2) then lon2_hh = '0' + lon2_hh
          if (strlen(lon2_mm) lt 2) then lon2_mm = '0' + lon2_mm
          if (strlen(lon2_ss) lt 2) then lon2_ss = '0' + lon2_ss
          lon2_str = lon2_hh + ':' + lon2_mm + ':' + lon2_ss

          lon3_hh=strcompress(string(fix(lon3_arr[0])),/remove_all)
          lon3_mm=strcompress(string(fix(lon3_arr[1])),/remove_all)
          lon3_ss=strcompress(string(fix(lon3_arr[2])),/remove_all)
          if (strlen(lon3_hh) lt 2) then lon3_hh = '0' + lon3_hh
          if (strlen(lon3_mm) lt 2) then lon3_mm = '0' + lon3_mm
          if (strlen(lon3_ss) lt 2) then lon3_ss = '0' + lon3_ss
          lon3_str = lon3_hh + ':' + lon3_mm + ':' + lon3_ss

          lon4_hh=strcompress(string(fix(lon4_arr[0])),/remove_all)
          lon4_mm=strcompress(string(fix(lon4_arr[1])),/remove_all)
          lon4_ss=strcompress(string(fix(lon4_arr[2])),/remove_all)
          if (strlen(lon4_hh) lt 2) then lon4_hh = '0' + lon4_hh
          if (strlen(lon4_mm) lt 2) then lon4_mm = '0' + lon4_mm
          if (strlen(lon4_ss) lt 2) then lon4_ss = '0' + lon4_ss
          lon4_str = lon4_hh + ':' + lon4_mm + ':' + lon4_ss

          lon5_hh=strcompress(string(fix(lon5_arr[0])),/remove_all)
          lon5_mm=strcompress(string(fix(lon5_arr[1])),/remove_all)
          lon5_ss=strcompress(string(fix(lon5_arr[2])),/remove_all)
          if (strlen(lon5_hh) lt 2) then lon5_hh = '0' + lon5_hh
          if (strlen(lon5_mm) lt 2) then lon5_mm = '0' + lon5_mm
          if (strlen(lon5_ss) lt 2) then lon5_ss = '0' + lon5_ss
          lon5_str = lon5_hh + ':' + lon5_mm + ':' + lon5_ss

          lon6_hh=strcompress(string(fix(lon6_arr[0])),/remove_all)
          lon6_mm=strcompress(string(fix(lon6_arr[1])),/remove_all)
          lon6_ss=strcompress(string(fix(lon6_arr[2])),/remove_all)
          if (strlen(lon6_hh) lt 2) then lon6_hh = '0' + lon6_hh
          if (strlen(lon6_mm) lt 2) then lon6_mm = '0' + lon6_mm
          if (strlen(lon6_ss) lt 2) then lon6_ss = '0' + lon6_ss
          lon6_str = lon6_hh + ':' + lon6_mm + ':' + lon6_ss

          lon7_hh=strcompress(string(fix(lon7_arr[0])),/remove_all)
          lon7_mm=strcompress(string(fix(lon7_arr[1])),/remove_all)
          lon7_ss=strcompress(string(fix(lon7_arr[2])),/remove_all)
          if (strlen(lon7_hh) lt 2) then lon7_hh = '0' + lon7_hh
          if (strlen(lon7_mm) lt 2) then lon7_mm = '0' + lon7_mm
          if (strlen(lon7_ss) lt 2) then lon7_ss = '0' + lon7_ss
          lon7_str = lon7_hh + ':' + lon7_mm + ':' + lon7_ss

          lon8_hh=strcompress(string(fix(lon8_arr[0])),/remove_all)
          lon8_mm=strcompress(string(fix(lon8_arr[1])),/remove_all)
          lon8_ss=strcompress(string(fix(lon8_arr[2])),/remove_all)
          if (strlen(lon8_hh) lt 2) then lon8_hh = '0' + lon8_hh
          if (strlen(lon8_mm) lt 2) then lon8_mm = '0' + lon8_mm
          if (strlen(lon8_ss) lt 2) then lon8_ss = '0' + lon8_ss
          lon8_str = lon8_hh + ':' + lon8_mm + ':' + lon8_ss

          lon9_hh=strcompress(string(fix(lon9_arr[0])),/remove_all)
          lon9_mm=strcompress(string(fix(lon9_arr[1])),/remove_all)
          lon9_ss=strcompress(string(fix(lon9_arr[2])),/remove_all)
          if (strlen(lon9_hh) lt 2) then lon9_hh = '0' + lon9_hh
          if (strlen(lon9_mm) lt 2) then lon9_mm = '0' + lon9_mm
          if (strlen(lon9_ss) lt 2) then lon9_ss = '0' + lon9_ss
          lon9_str = lon9_hh + ':' + lon9_mm + ':' + lon9_ss

          lon10_hh=strcompress(string(fix(lon10_arr[0])),/remove_all)
          lon10_mm=strcompress(string(fix(lon10_arr[1])),/remove_all)
          lon10_ss=strcompress(string(fix(lon10_arr[2])),/remove_all)
          if (strlen(lon10_hh) lt 2) then lon10_hh = '0' + lon10_hh
          if (strlen(lon10_mm) lt 2) then lon10_mm = '0' + lon10_mm
          if (strlen(lon10_ss) lt 2) then lon10_ss = '0' + lon10_ss
          lon10_str = lon10_hh + ':' + lon10_mm + ':' + lon10_ss

          lon11_hh=strcompress(string(fix(lon11_arr[0])),/remove_all)
          lon11_mm=strcompress(string(fix(lon11_arr[1])),/remove_all)
          lon11_ss=strcompress(string(fix(lon11_arr[2])),/remove_all)
          if (strlen(lon11_hh) lt 2) then lon11_hh = '0' + lon11_hh
          if (strlen(lon11_mm) lt 2) then lon11_mm = '0' + lon11_mm
          if (strlen(lon11_ss) lt 2) then lon11_ss = '0' + lon11_ss
          lon11_str = lon11_hh + ':' + lon11_mm + ':' + lon11_ss

          lon12_hh=strcompress(string(fix(lon12_arr[0])),/remove_all)
          lon12_mm=strcompress(string(fix(lon12_arr[1])),/remove_all)
          lon12_ss=strcompress(string(fix(lon12_arr[2])),/remove_all)
          if (strlen(lon12_hh) lt 2) then lon12_hh = '0' + lon12_hh
          if (strlen(lon12_mm) lt 2) then lon12_mm = '0' + lon12_mm
          if (strlen(lon12_ss) lt 2) then lon12_ss = '0' + lon12_ss
          lon12_str = lon12_hh + ':' + lon12_mm + ':' + lon12_ss


          lat0_dd=strcompress(string(fix(lat0_arr[0])),/remove_all)
          lat0_mm=strcompress(string(fix(lat0_arr[1])),/remove_all)
          lat0_ss=strcompress(string(fix(lat0_arr[2])),/remove_all)
          if (strlen(lat0_dd) lt 2) then lat0_dd = '0' + lat0_dd
          if (strmid(lat0_dd,0,1) eq '-' AND strlen(lat0_dd) lt 3) then begin
            strput, lat0_dd, '0', 0
            lat0_dd = '-' + lat0_dd
          endif
          if (strlen(lat0_mm) lt 2) then lat0_mm = '0' + lat0_mm
          if (strlen(lat0_ss) lt 2) then lat0_ss = '0' + lat0_ss
          lat0_str = lat0_dd + ':' + lat0_mm + ':' + lat0_ss

          lat1_dd=strcompress(string(fix(lat1_arr[0])),/remove_all)
          lat1_mm=strcompress(string(fix(lat1_arr[1])),/remove_all)
          lat1_ss=strcompress(string(fix(lat1_arr[2])),/remove_all)
          if (strlen(lat1_dd) lt 2) then lat1_dd = '0' + lat1_dd
          if (strmid(lat1_dd,0,1) eq '-' AND strlen(lat1_dd) lt 3) then begin
            strput, lat1_dd, '0', 0
            lat1_dd = '-' + lat1_dd
          endif
          if (strlen(lat1_mm) lt 2) then lat1_mm = '0' + lat1_mm
          if (strlen(lat1_ss) lt 2) then lat1_ss = '0' + lat1_ss
          lat1_str = lat1_dd + ':' + lat1_mm + ':' + lat1_ss

          lat2_dd=strcompress(string(fix(lat2_arr[0])),/remove_all)
          lat2_mm=strcompress(string(fix(lat2_arr[1])),/remove_all)
          lat2_ss=strcompress(string(fix(lat2_arr[2])),/remove_all)
          if (strlen(lat2_dd) lt 2) then lat2_dd = '0' + lat2_dd
          if (strmid(lat2_dd,0,1) eq '-' AND strlen(lat2_dd) lt 3) then begin
            strput, lat2_dd, '0', 0
            lat2_dd = '-' + lat2_dd
          endif
          if (strlen(lat2_mm) lt 2) then lat2_mm = '0' + lat2_mm
          if (strlen(lat2_ss) lt 2) then lat2_ss = '0' + lat2_ss
          lat2_str = lat2_dd + ':' + lat2_mm + ':' + lat2_ss

          lat3_dd=strcompress(string(fix(lat3_arr[0])),/remove_all)
          lat3_mm=strcompress(string(fix(lat3_arr[1])),/remove_all)
          lat3_ss=strcompress(string(fix(lat3_arr[2])),/remove_all)
          if (strlen(lat3_dd) lt 2) then lat3_dd = '0' + lat3_dd
          if (strmid(lat3_dd,0,1) eq '-' AND strlen(lat3_dd) lt 3) then begin
            strput, lat3_dd, '0', 0
            lat3_dd = '-' + lat3_dd
          endif
          if (strlen(lat3_mm) lt 2) then lat3_mm = '0' + lat3_mm
          if (strlen(lat3_ss) lt 2) then lat3_ss = '0' + lat3_ss
          lat3_str = lat3_dd + ':' + lat3_mm + ':' + lat3_ss

          lat4_dd=strcompress(string(fix(lat4_arr[0])),/remove_all)
          lat4_mm=strcompress(string(fix(lat4_arr[1])),/remove_all)
          lat4_ss=strcompress(string(fix(lat4_arr[2])),/remove_all)
          if (strlen(lat4_dd) lt 2) then lat4_dd = '0' + lat4_dd
          if (strmid(lat4_dd,0,1) eq '-' AND strlen(lat4_dd) lt 3) then begin
            strput, lat4_dd, '0', 0
            lat4_dd = '-' + lat4_dd
          endif
          if (strlen(lat4_mm) lt 2) then lat4_mm = '0' + lat4_mm
          if (strlen(lat4_ss) lt 2) then lat4_ss = '0' + lat4_ss
          lat4_str = lat4_dd + ':' + lat4_mm + ':' + lat4_ss

          lat5_dd=strcompress(string(fix(lat5_arr[0])),/remove_all)
          lat5_mm=strcompress(string(fix(lat5_arr[1])),/remove_all)
          lat5_ss=strcompress(string(fix(lat5_arr[2])),/remove_all)
          if (strlen(lat5_dd) lt 2) then lat5_dd = '0' + lat5_dd
          if (strmid(lat5_dd,0,1) eq '-' AND strlen(lat5_dd) lt 3) then begin
            strput, lat5_dd, '0', 0
            lat5_dd = '-' + lat5_dd
          endif
          if (strlen(lat5_mm) lt 2) then lat5_mm = '0' + lat5_mm
          if (strlen(lat5_ss) lt 2) then lat5_ss = '0' + lat5_ss
          lat5_str = lat5_dd + ':' + lat5_mm + ':' + lat5_ss

          lat6_dd=strcompress(string(fix(lat6_arr[0])),/remove_all)
          lat6_mm=strcompress(string(fix(lat6_arr[1])),/remove_all)
          lat6_ss=strcompress(string(fix(lat6_arr[2])),/remove_all)
          if (strlen(lat6_dd) lt 2) then lat6_dd = '0' + lat6_dd
          if (strmid(lat6_dd,0,1) eq '-' AND strlen(lat6_dd) lt 3) then begin
            strput, lat6_dd, '0', 0
            lat6_dd = '-' + lat6_dd
          endif
          if (strlen(lat6_mm) lt 2) then lat6_mm = '0' + lat6_mm
          if (strlen(lat6_ss) lt 2) then lat6_ss = '0' + lat6_ss
          lat6_str = lat6_dd + ':' + lat6_mm + ':' + lat6_ss

          lat7_dd=strcompress(string(fix(lat7_arr[0])),/remove_all)
          lat7_mm=strcompress(string(fix(lat7_arr[1])),/remove_all)
          lat7_ss=strcompress(string(fix(lat7_arr[2])),/remove_all)
          if (strlen(lat7_dd) lt 2) then lat7_dd = '0' + lat7_dd
          if (strmid(lat7_dd,0,1) eq '-' AND strlen(lat7_dd) lt 3) then begin
            strput, lat7_dd, '0', 0
            lat7_dd = '-' + lat7_dd
          endif
          if (strlen(lat7_mm) lt 2) then lat7_mm = '0' + lat7_mm
          if (strlen(lat7_ss) lt 2) then lat7_ss = '0' + lat7_ss
          lat7_str = lat7_dd + ':' + lat7_mm + ':' + lat7_ss

          lat8_dd=strcompress(string(fix(lat8_arr[0])),/remove_all)
          lat8_mm=strcompress(string(fix(lat8_arr[1])),/remove_all)
          lat8_ss=strcompress(string(fix(lat8_arr[2])),/remove_all)
          if (strlen(lat8_dd) lt 2) then lat8_dd = '0' + lat8_dd
          if (strmid(lat8_dd,0,1) eq '-' AND strlen(lat8_dd) lt 3) then begin
            strput, lat8_dd, '0', 0
            lat8_dd = '-' + lat8_dd
          endif
          if (strlen(lat8_mm) lt 2) then lat8_mm = '0' + lat8_mm
          if (strlen(lat8_ss) lt 2) then lat8_ss = '0' + lat8_ss
          lat8_str = lat8_dd + ':' + lat8_mm + ':' + lat8_ss

          lat9_dd=strcompress(string(fix(lat9_arr[0])),/remove_all)
          lat9_mm=strcompress(string(fix(lat9_arr[1])),/remove_all)
          lat9_ss=strcompress(string(fix(lat9_arr[2])),/remove_all)
          if (strlen(lat9_dd) lt 2) then lat9_dd = '0' + lat0_dd
          if (strmid(lat9_dd,0,1) eq '-' AND strlen(lat9_dd) lt 3) then begin
            strput, lat9_dd, '0', 0
            lat9_dd = '-' + lat9_dd
          endif
          if (strlen(lat9_mm) lt 2) then lat9_mm = '0' + lat9_mm
          if (strlen(lat9_ss) lt 2) then lat9_ss = '0' + lat9_ss
          lat9_str = lat9_dd + ':' + lat9_mm + ':' + lat9_ss

          lat10_dd=strcompress(string(fix(lat10_arr[0])),/remove_all)
          lat10_mm=strcompress(string(fix(lat10_arr[1])),/remove_all)
          lat10_ss=strcompress(string(fix(lat10_arr[2])),/remove_all)
          if (strlen(lat10_dd) lt 2) then lat10_dd = '0' + lat10_dd
          if (strmid(lat10_dd,0,1) eq '-' AND strlen(lat10_dd) lt 3) then begin
            strput, lat10_dd, '0', 0
            lat10_dd = '-' + lat10_dd
          endif
          if (strlen(lat10_mm) lt 2) then lat10_mm = '0' + lat10_mm
          if (strlen(lat10_ss) lt 2) then lat10_ss = '0' + lat10_ss
          lat10_str = lat10_dd + ':' + lat10_mm + ':' + lat10_ss

          lat11_dd=strcompress(string(fix(lat11_arr[0])),/remove_all)
          lat11_mm=strcompress(string(fix(lat11_arr[1])),/remove_all)
          lat11_ss=strcompress(string(fix(lat11_arr[2])),/remove_all)
          if (strlen(lat11_dd) lt 2) then lat11_dd = '0' + lat11_dd
          if (strmid(lat11_dd,0,1) eq '-' AND strlen(lat11_dd) lt 3) then begin
            strput, lat11_dd, '0', 0
            lat11_dd = '-' + lat11_dd
          endif
          if (strlen(lat11_mm) lt 2) then lat11_mm = '0' + lat11_mm
          if (strlen(lat11_ss) lt 2) then lat11_ss = '0' + lat11_ss
          lat11_str = lat11_dd + ':' + lat11_mm + ':' + lat11_ss

          lat12_dd=strcompress(string(fix(lat12_arr[0])),/remove_all)
          lat12_mm=strcompress(string(fix(lat12_arr[1])),/remove_all)
          lat12_ss=strcompress(string(fix(lat12_arr[2])),/remove_all)
          if (strlen(lat12_dd) lt 2) then lat12_dd = '0' + lat12_dd
          if (strmid(lat12_dd,0,1) eq '-' AND strlen(lat12_dd) lt 3) then begin
            strput, lat12_dd, '0', 0
            lat12_dd = '-' + lat12_dd
          endif
          if (strlen(lat12_mm) lt 2) then lat12_mm = '0' + lat12_mm
          if (strlen(lat12_ss) lt 2) then lat12_ss = '0' + lat12_ss
          lat12_str = lat12_dd + ':' + lat12_mm + ':' + lat12_ss

        ENDIF ELSE BEGIN

          lon0_str = strcompress(string(lon_spaces[0]),/remove_all)
          lon1_str = strcompress(string(lon_spaces[1]),/remove_all)
          lon2_str = strcompress(string(lon_spaces[2]),/remove_all)
          lon3_str = strcompress(string(lon_spaces[3]),/remove_all)
          lon4_str = strcompress(string(lon_spaces[4]),/remove_all)
          lon5_str = strcompress(string(lon_spaces[5]),/remove_all)
          lon6_str = strcompress(string(lon_spaces[6]),/remove_all)
          lon7_str = strcompress(string(lon_spaces[7]),/remove_all)
          lon8_str = strcompress(string(lon_spaces[8]),/remove_all)
          lon9_str = strcompress(string(lon_spaces[9]),/remove_all)
          lon10_str = strcompress(string(lon_spaces[10]),/remove_all)
          lon11_str = strcompress(string(lon_spaces[11]),/remove_all)
          lon12_str = strcompress(string(lon_spaces[12]),/remove_all)
          lat0_str = strcompress(string(lat_spaces[0]),/remove_all)
          lat1_str = strcompress(string(lat_spaces[1]),/remove_all)
          lat2_str = strcompress(string(lat_spaces[2]),/remove_all)
          lat3_str = strcompress(string(lat_spaces[3]),/remove_all)
          lat4_str = strcompress(string(lat_spaces[4]),/remove_all)
          lat5_str = strcompress(string(lat_spaces[5]),/remove_all)
          lat6_str = strcompress(string(lat_spaces[6]),/remove_all)
          lat7_str = strcompress(string(lat_spaces[7]),/remove_all)
          lat8_str = strcompress(string(lat_spaces[8]),/remove_all)
          lat9_str = strcompress(string(lat_spaces[9]),/remove_all)
          lat10_str = strcompress(string(lat_spaces[10]),/remove_all)
          lat11_str = strcompress(string(lat_spaces[11]),/remove_all)
          lat12_str = strcompress(string(lat_spaces[12]),/remove_all)

          pos_lon0 = strpos(lon0_str, '.')
          lon0_str = strmid(lon0_str, 0, pos_lon0+4)
          pos_lon1 = strpos(lon1_str, '.')
          lon1_str = strmid(lon1_str, 0, pos_lon1+4)
          pos_lon2 = strpos(lon2_str, '.')
          lon2_str = strmid(lon2_str, 0, pos_lon2+4)
          pos_lon3 = strpos(lon3_str, '.')
          lon3_str = strmid(lon3_str, 0, pos_lon3+4)
          pos_lon4 = strpos(lon4_str, '.')
          lon4_str = strmid(lon4_str, 0, pos_lon4+4)
          pos_lon5 = strpos(lon5_str, '.')
          lon5_str = strmid(lon5_str, 0, pos_lon5+4)
          pos_lon6 = strpos(lon6_str, '.')
          lon6_str = strmid(lon6_str, 0, pos_lon6+4)
          pos_lon7 = strpos(lon7_str, '.')
          lon7_str = strmid(lon7_str, 0, pos_lon7+4)
          pos_lon8 = strpos(lon8_str, '.')
          lon8_str = strmid(lon8_str, 0, pos_lon8+4)
          pos_lon9 = strpos(lon9_str, '.')
          lon9_str = strmid(lon9_str, 0, pos_lon9+4)
          pos_lon10 = strpos(lon10_str, '.')
          lon10_str = strmid(lon10_str, 0, pos_lon10+4)
          pos_lon11 = strpos(lon11_str, '.')
          lon11_str = strmid(lon11_str, 0, pos_lon11+4)
          pos_lon12 = strpos(lon12_str, '.')
          lon12_str = strmid(lon12_str, 0, pos_lon12+4)

          pos_lat0 = strpos(lat0_str, '.')
          lat0_str = strmid(lat0_str, 0, pos_lat0+4)
          pos_lat1 = strpos(lat1_str, '.')
          lat1_str = strmid(lat1_str, 0, pos_lat1+4)
          pos_lat2 = strpos(lat2_str, '.')
          lat2_str = strmid(lat2_str, 0, pos_lat2+4)
          pos_lat3 = strpos(lat3_str, '.')
          lat3_str = strmid(lat3_str, 0, pos_lat3+4)
          pos_lat4 = strpos(lat4_str, '.')
          lat4_str = strmid(lat4_str, 0, pos_lat4+4)
          pos_lat5 = strpos(lat5_str, '.')
          lat5_str = strmid(lat5_str, 0, pos_lat5+4)
          pos_lat6 = strpos(lat6_str, '.')
          lat6_str = strmid(lat6_str, 0, pos_lat6+4)
          pos_lat7 = strpos(lat7_str, '.')
          lat7_str = strmid(lat7_str, 0, pos_lat7+4)
          pos_lat8 = strpos(lat8_str, '.')
          lat8_str = strmid(lat8_str, 0, pos_lat8+4)
          pos_lat9 = strpos(lat9_str, '.')
          lat9_str = strmid(lat9_str, 0, pos_lat9+4)
          pos_lat10 = strpos(lat10_str, '.')
          lat10_str = strmid(lat10_str, 0, pos_lat10+4)
          pos_lat11 = strpos(lat11_str, '.')
          lat11_str = strmid(lat11_str, 0, pos_lat11+4)
          pos_lat12 = strpos(lat12_str, '.')
          lat12_str = strmid(lat12_str, 0, pos_lat12+4)

        ENDELSE

      END

      ELSE: BEGIN

        lon0_str = strcompress(string(lon_spaces[0]),/remove_all)
        lon1_str = strcompress(string(lon_spaces[1]),/remove_all)
        lon2_str = strcompress(string(lon_spaces[2]),/remove_all)
        lon3_str = strcompress(string(lon_spaces[3]),/remove_all)
        lon4_str = strcompress(string(lon_spaces[4]),/remove_all)
        lon5_str = strcompress(string(lon_spaces[5]),/remove_all)
        lon6_str = strcompress(string(lon_spaces[6]),/remove_all)
        lon7_str = strcompress(string(lon_spaces[7]),/remove_all)
        lon8_str = strcompress(string(lon_spaces[8]),/remove_all)
        lon9_str = strcompress(string(lon_spaces[9]),/remove_all)
        lon10_str = strcompress(string(lon_spaces[10]),/remove_all)
        lon11_str = strcompress(string(lon_spaces[11]),/remove_all)
        lon12_str = strcompress(string(lon_spaces[12]),/remove_all)
        lat0_str = strcompress(string(lat_spaces[0]),/remove_all)
        lat1_str = strcompress(string(lat_spaces[1]),/remove_all)
        lat2_str = strcompress(string(lat_spaces[2]),/remove_all)
        lat3_str = strcompress(string(lat_spaces[3]),/remove_all)
        lat4_str = strcompress(string(lat_spaces[4]),/remove_all)
        lat5_str = strcompress(string(lat_spaces[5]),/remove_all)
        lat6_str = strcompress(string(lat_spaces[6]),/remove_all)
        lat7_str = strcompress(string(lat_spaces[7]),/remove_all)
        lat8_str = strcompress(string(lat_spaces[8]),/remove_all)
        lat9_str = strcompress(string(lat_spaces[9]),/remove_all)
        lat10_str = strcompress(string(lat_spaces[10]),/remove_all)
        lat11_str = strcompress(string(lat_spaces[11]),/remove_all)
        lat12_str = strcompress(string(lat_spaces[12]),/remove_all)

        pos_lon0 = strpos(lon0_str, '.')
        lon0_str = strmid(lon0_str, 0, pos_lon0+4)
        pos_lon1 = strpos(lon1_str, '.')
        lon1_str = strmid(lon1_str, 0, pos_lon1+4)
        pos_lon2 = strpos(lon2_str, '.')
        lon2_str = strmid(lon2_str, 0, pos_lon2+4)
        pos_lon3 = strpos(lon3_str, '.')
        lon3_str = strmid(lon3_str, 0, pos_lon3+4)
        pos_lon4 = strpos(lon4_str, '.')
        lon4_str = strmid(lon4_str, 0, pos_lon4+4)
        pos_lon5 = strpos(lon5_str, '.')
        lon5_str = strmid(lon5_str, 0, pos_lon5+4)
        pos_lon6 = strpos(lon6_str, '.')
        lon6_str = strmid(lon6_str, 0, pos_lon6+4)
        pos_lon7 = strpos(lon7_str, '.')
        lon7_str = strmid(lon7_str, 0, pos_lon7+4)
        pos_lon8 = strpos(lon8_str, '.')
        lon8_str = strmid(lon8_str, 0, pos_lon8+4)
        pos_lon9 = strpos(lon9_str, '.')
        lon9_str = strmid(lon9_str, 0, pos_lon9+4)
        pos_lon10 = strpos(lon10_str, '.')
        lon10_str = strmid(lon10_str, 0, pos_lon10+4)
        pos_lon11 = strpos(lon11_str, '.')
        lon11_str = strmid(lon11_str, 0, pos_lon11+4)
        pos_lon12 = strpos(lon12_str, '.')
        lon12_str = strmid(lon12_str, 0, pos_lon12+4)

        pos_lat0 = strpos(lat0_str, '.')
        lat0_str = strmid(lat0_str, 0, pos_lat0+4)
        pos_lat1 = strpos(lat1_str, '.')
        lat1_str = strmid(lat1_str, 0, pos_lat1+4)
        pos_lat2 = strpos(lat2_str, '.')
        lat2_str = strmid(lat2_str, 0, pos_lat2+4)
        pos_lat3 = strpos(lat3_str, '.')
        lat3_str = strmid(lat3_str, 0, pos_lat3+4)
        pos_lat4 = strpos(lat4_str, '.')
        lat4_str = strmid(lat4_str, 0, pos_lat4+4)
        pos_lat5 = strpos(lat5_str, '.')
        lat5_str = strmid(lat5_str, 0, pos_lat5+4)
        pos_lat6 = strpos(lat6_str, '.')
        lat6_str = strmid(lat6_str, 0, pos_lat6+4)
        pos_lat7 = strpos(lat7_str, '.')
        lat7_str = strmid(lat7_str, 0, pos_lat7+4)
        pos_lat8 = strpos(lat8_str, '.')
        lat8_str = strmid(lat8_str, 0, pos_lat8+4)
        pos_lat9 = strpos(lat9_str, '.')
        lat9_str = strmid(lat9_str, 0, pos_lat9+4)
        pos_lat10 = strpos(lat10_str, '.')
        lat10_str = strmid(lat10_str, 0, pos_lat10+4)
        pos_lat11 = strpos(lat11_str, '.')
        lat11_str = strmid(lat11_str, 0, pos_lat11+4)
        pos_lat12 = strpos(lat12_str, '.')
        lat12_str = strmid(lat12_str, 0, pos_lat12+4)
      END

    ENDCASE


    x_lonline = [x_lonline0, x_lonline1, x_lonline2, x_lonline3, x_lonline4, $
      x_lonline5, x_lonline6, x_lonline7, x_lonline8, x_lonline9, $
      x_lonline10, x_lonline11, x_lonline12]
    y_lonline = [y_lonline0, y_lonline1, y_lonline2, y_lonline3, y_lonline4, $
      y_lonline5, y_lonline6, y_lonline7, y_lonline8, y_lonline9, $
      y_lonline10, y_lonline11, y_lonline12]
    lon_str = [lon0_str,lon1_str,lon2_str,lon3_str,lon4_str,lon5_str,lon6_str,$
      lon7_str,lon8_str,lon9_str,lon10_str,lon11_str,lon12_str]

    lon_str[2] = ''

    ; If pole in image, make last longitude string (360.000 or 24:00:00) blank
    IF (lat_min eq -90. OR lat_max eq 90.) THEN lon_str[12] = ''

    lonindex = where(count_vlon ne 0)

    xyouts, x_lonline[lonindex], y_lonline[lonindex], lon_str[lonindex], $
      charsize=charsize, orientation=lonlabel_orientation, alignment=0.5, $
      color=wcslabelcolor, charthick=charthick

    x_latline = [x_latline0, x_latline1, x_latline2, x_latline3, x_latline4, $
      x_latline5, x_latline6, x_latline7, x_latline8, x_latline9, $
      x_latline10, x_latline11, x_latline12]
    y_latline = [y_latline0, y_latline1, y_latline2, y_latline3, y_latline4, $
      y_latline5, y_latline6, y_latline7, y_latline8, y_latline9, $
      y_latline10, y_latline11, y_latline12]
    lat_str = [lat0_str,lat1_str,lat2_str,lat3_str,lat4_str,lat5_str,lat6_str,$
      lat7_str,lat8_str,lat9_str,lat10_str,lat11_str,lat12_str]

    latindex = where(count_vlat ne 0)

    xyouts, x_latline[latindex], y_latline[latindex], lat_str[latindex], $
      charsize=charsize, orientation=latlabel_orientation, alignment=0.5, $
      color=wcslabelcolor, charthick=charthick

  endif

  self->resetwindow
  (*self.state).newrefresh=1
end

;----------------------------------------------------------------------
pro GPItv::plot1wavecalgrid,iplot

  if (*self.state).wcfilename eq "" then begin
    self->message, msgtype = 'error', "You must select a wavelength/polarization calibration file first before you can plot!"
    return
  endif



  gridcolor = (*(self.pdata.plot_ptr[iplot])).options.gridcolor
  tiltcolor = (*(self.pdata.plot_ptr[iplot])).options.tiltcolor
  labeldisp = (*(self.pdata.plot_ptr[iplot])).options.labeldisp
  labelcolor = (*(self.pdata.plot_ptr[iplot])).options.labelcolor
  charsize = (*(self.pdata.plot_ptr[iplot])).options.charsize
  charthick = (*(self.pdata.plot_ptr[iplot])).options.charthick

  self->setwindow, (*self.state).draw_window_id

  nx = (*self.state).image_size[0]
  ny = (*self.state).image_size[1]

  ;;Get the drawing device coordinates
  lowerleft = round( (0.5 >  (([0,0] / (*self.state).zoom_factor) + (*self.state).offset)< ((*self.state).image_size[0:1] - 0.5) ) - 0.5)
  upperright = round( (0.5 >  (([(*self.state).draw_window_size] / (*self.state).zoom_factor) $
    + (*self.state).offset)< ((*self.state).image_size[0:1] - 0.5) ) - 0.5)
  ; x0 = lowerleft[0]+(0.1*(upperright[0]-lowerleft[0]))
  ; y0 = lowerleft[1]+(0.1*(upperright[1]-lowerleft[1]))
  xmax = lowerleft[0]+(0.95*(upperright[0]-lowerleft[0]))
  ymax = lowerleft[1]+(0.95*(upperright[1]-lowerleft[1]))
  ;wcfilename= DIALOG_PICKFILE( TITLE='GPI pipeline: Select files ', FILTER = 'specpos*.fits', FILE='*.fits',/MUST_EXIST )

  ; TODO catch this in memory to save speed on repeated drawings?

  if ~file_test((*self.state).wcfilename) then begin
    self->message, msgtype = 'error','The Wavelength/Polarization cal file '+(*self.state).wcfilename+" does not appear to exist.", /window
    return
  endif

  ; read from primary image if present, otherwise read from 1st extension
  ; always look at the primary header.
  fits_info, (*self.state).wcfilename, n_ext=n_ext,/silent
  wavecal=readfits((*self.state).wcfilename, ext=(1 < n_ext),/SILENT)
  wavecalheader=headfits((*self.state).wcfilename,/SILENT)

  filetype = sxpar(wavecalheader, "FILETYPE")

  if size(filetype,/tname) ne "STRING" then filetype=string(filetype)
  sz=size(wavecal)

  ; Check for applied shifts to account for flexure

  shiftx = sxpar( *((*self.state).head_ptr), 'SPOT_DX', count=ct)
  if ct eq 0 then shiftx=0
  shifty = sxpar( *((*self.state).head_ptr), 'SPOT_DY', count=ct)
  if ct eq 0 then shifty=0




  case filetype of
    "Polarimetry Spots Cal File": begin	; Plot polarimetry mode cal grid
      wavecal=readfits((*self.state).wcfilename, ext=1,/SILENT)
      wavecal[1,*,*,*,*]+=shifty
      wavecal[0,*,*,*,*]+=shiftx

      for jj=0,sz[2]-1 do begin
        X =fltarr(2,sz[2])+!VALUES.F_NAN
        X2=fltarr(2,sz[2])+!VALUES.F_NAN
        P =fltarr(2,sz[2])+!VALUES.F_NAN
        P2=fltarr(2,sz[2])+!VALUES.F_NAN

        DISP=fltarr(2,2)+!VALUES.F_NAN

        ; Polarization 1
        ; grab the X and Y locations of the columns
        X[0,*] = (float(wavecal[0,jj,*,0]) - (*self.state).offset[0] + 0.5) *  (*self.state).zoom_factor
        X[1,*] = (float(wavecal[1,jj,*,0]) - (*self.state).offset[1] + 0.5) *  (*self.state).zoom_factor
        ; and the rows
        X2[0,*] = (float(wavecal[0,*,jj,0]) - (*self.state).offset[0] + 0.5) *  (*self.state).zoom_factor
        X2[1,*] = (float(wavecal[1,*,jj,0]) - (*self.state).offset[1] + 0.5) *  (*self.state).zoom_factor

        ; Polarization 2
        ; grab the X and Y locations of the columns
        P[0,*] = (float(wavecal[0,jj,*,1]) - (*self.state).offset[0] + 0.5) *  (*self.state).zoom_factor
        P[1,*] = (float(wavecal[1,jj,*,1]) - (*self.state).offset[1] + 0.5) *  (*self.state).zoom_factor
        ; and the rows
        P2[0,*] = (float(wavecal[0,*,jj,1]) - (*self.state).offset[0] + 0.5) *  (*self.state).zoom_factor
        P2[1,*] = (float(wavecal[1,*,jj,1]) - (*self.state).offset[1] + 0.5) *  (*self.state).zoom_factor

        ; now draw the red lines
        plots,X,/DEVICE, color=gridcolor
        plots,X2,/DEVICE, color=gridcolor
        ;plots,P,/DEVICE, color=3
        ;plots,P2,/DEVICE, color=3



        ; draw the green lines connecting the spots
        for ii=0,sz[2]-1 do begin
          pts = [ [ X[*,ii]], [ P[*,ii]] ] & if total(finite(pts)) eq 4 then plots, pts ,/device, color=tiltcolor
          pts = [ [X2[*,ii]], [P2[*,ii]] ] & if total(finite(pts)) eq 4 then plots, pts ,/device, color=tiltcolor

          if labeldisp then $
            xyouts, X2[0,ii], X2[1,ii], $
            strc(ii)+';'+strc(jj),/DEVICE, color=labelcolor,charsize=charsize,charthick=charthick ;, _extra = (*(self.pdata.plot_ptr[iplot])).options

        endfor
      endfor
    end
    else: begin		; Plot spectral mode cal grid
      wavecal[*,*,0]+=shifty
      wavecal[*,*,1]+=shiftx


      waveinfo = get_cwv((*self.state).obsfilt)
      if size(waveinfo,/TNAME) ne 'STRUCT' then begin
        self->message, msgtype = 'warning', 'Invalid filter name or no filter found! Cannot overplot wavecal grid'
        return
      endif
      ; min and max wavelengths:
      lambdarange =[ waveinfo.commonwavvect[0], waveinfo.commonwavvect[1] ]

      ;	case (*self.state).obsfilt of
      ;	  'Y':lambc=1.16 ;TBverified
      ;		'J':lambc=1.33 ;1.35
      ;		'H':lambc=1.8
      ;		'K1':lambc=2.19
      ;		'K2':lambc=2.4
      ;		else: begin
      ;		        (*self.state).obsfilt='H' & lambc=1.8
      ;		        self->message, msgtype = 'warning', 'No filter found! Filter has been set to H band.'
      ;		      end
      ;	endcase

      if ((size(wavecal))[3] ne 5) and ((size(wavecal))[3] ne 6) then begin
        self->message, msgtype = 'warning', 'Selected wavecal file has invalid array axes lengths. Can not plot.'
        return
      endif

      X=fltarr(2,sz[1])+!VALUES.F_NAN
      X2=fltarr(2,sz[1])+!VALUES.F_NAN
      DISP=fltarr(2,2)+!VALUES.F_NAN
      for jj=0,sz[1]-1 do begin
        ; FIXME - recode for more speed by vectorizing the X & X2 assignments as above
        ;wnz = where( wavecal[*,jj,0]+wavecal[*,jj,1] ne 0 )
        X2[0,*]=(float(wavecal[*,jj,1]) - (*self.state).offset[0] + 0.5) *  (*self.state).zoom_factor
        X2[1,*]=(float(wavecal[*,jj,0]) - (*self.state).offset[1] + 0.5) *  (*self.state).zoom_factor
        X[0,*] =(float(wavecal[jj,*,1]) - (*self.state).offset[0] + 0.5) * (*self.state).zoom_factor
        X[1,*] =(float(wavecal[jj,*,0]) - (*self.state).offset[1] + 0.5) * (*self.state).zoom_factor
        for ii=0,sz[1]-1 do begin
          ;if (wavecal[ii,jj,0]+wavecal[ii,jj,1] ne 0) then begin ;&& (wavecal[ii+1,jj,0]+wavecal[ii+1,jj,0] ne 0) then begin
          ;X2[0,ii]=(float(wavecal[ii,jj,1]) - (*self.state).offset[0] + 0.5) *  (*self.state).zoom_factor
          ;X2[1,ii]=(float(wavecal[ii,jj,0]) - (*self.state).offset[1] + 0.5) *  (*self.state).zoom_factor
          ;endif
          ;if (wavecal[jj,ii,0]+wavecal[jj,ii,1] ne 0) then begin ;&& (wavecal[ii+1,jj,0]+wavecal[ii+1,jj,0] ne 0) then begin
          ;X[0,ii]=(float(wavecal[jj,ii,1]) - (*self.state).offset[0] + 0.5) * (*self.state).zoom_factor
          ;X[1,ii]=(float(wavecal[jj,ii,0]) - (*self.state).offset[1] + 0.5) * (*self.state).zoom_factor
          ;endif

          if  wavecal[ii,jj,3] ne 0 then begin
            ;				DISP[0,0]=X2[0,ii] & DISP[1,0]=X2[1,ii]
            ;				d2=(lambc-wavecal[ii,jj,2])/wavecal[ii,jj,3]
            ;
            ;				DISP[0,1]=d2*sin(wavecal[ii,jj,4])+wavecal[ii,jj,1]
            ;				DISP[1,1]=-d2*cos(wavecal[ii,jj,4])+wavecal[ii,jj,0]
            ;
            ;				DISP[0,1]=(DISP[0,1]- (*self.state).offset[0] + 0.5) * (*self.state).zoom_factor
            ;				DISP[1,1]=(DISP[1,1]- (*self.state).offset[1] + 0.5) * (*self.state).zoom_factor
            ;
            for kk=0,1 do begin
                if ((size(wavecal))[3] eq 5) then begin
                   ; find location of endpoints in detector coords
                   distance = (lambdarange[kk]-wavecal[ii,jj,2])/wavecal[ii,jj,3]
                   DISP[0,kk] = distance*sin(wavecal[ii,jj,4])+wavecal[ii,jj,1]
                   DISP[1,kk] = -distance*cos(wavecal[ii,jj,4])+wavecal[ii,jj,0]
                endif else begin
                   deltalam = (lambdarange[kk]-wavecal[ii,jj,2])
                   DISP[1,kk] = wavecal[ii,jj,0]-cos(wavecal[ii,jj,4])*(deltalam/wavecal[ii,jj,3]+deltalam^2.*wavecal[ii,jj,5])
                   DISP[0,kk] = wavecal[ii,jj,1]+sin(wavecal[ii,jj,4])*(deltalam/wavecal[ii,jj,3]+deltalam^2.*wavecal[ii,jj,5])
                endelse

              ; transform to display coords
              DISP[0,kk] = (DISP[0,kk]- (*self.state).offset[0] + 0.5) * (*self.state).zoom_factor
              DISP[1,kk] = (DISP[1,kk]- (*self.state).offset[1] + 0.5) * (*self.state).zoom_factor
            endfor


            plots,DISP,/DEVICE, color=tiltcolor;, thick=3
            ;print, 'd2=',d2
            ;print, 'dispx=',disp[0,*]
            ;print, 'dispy=',disp[1,*]
            if labeldisp then $
              xyouts, X2[0,ii], X2[1,ii], $
              strc(ii)+';'+strc(jj),/DEVICE, color=labelcolor,charsize=charsize,charthick=charthick;, _extra = (*(self.pdata.plot_ptr[iplot])).options

          endif
        endfor
        plots,X,/DEVICE, color=gridcolor;, thick=3
        plots,X2,/DEVICE, color=gridcolor;, thick=3
      endfor
    end
  endcase


  ;for ii=0,sz[1]-1 do begin
  ;X2=fltarr(2,sz[1])+!VALUES.F_NAN
  ;	for jj=0,sz[1]-1 do begin
  ;		if (wavecal(ii,jj,0)+wavecal(ii,jj,1) ne 0) then begin ;&& (wavecal(ii,jj+1,0)+wavecal(ii,jj+1,1) ne 0) then begin
  ;		X2(0,jj)=(float(wavecal(ii,jj,0)) - (*self.state).offset[0] + 0.5) * $
  ;                   (*self.state).zoom_factor
  ;		X2(1,jj)=(float(wavecal(ii,jj,1)) - (*self.state).offset[1] + 0.5) * $
  ;                   (*self.state).zoom_factor
  ;        endif
  ;	endfor
  ; plots,X2,/DEVICE
  ;endfor
  ;GPItvplot,[wavecal(95,6,0),wavecal(95,6+1,0)],[wavecal(95,6,1),wavecal(95,6+1,1)],color = 1

  ;  xticks=10
  ;  yticks=10
  ;   plot,[0,1],[0,1],/normal,/nodata,/noerase,position=[0.11,0.13,0.90,0.90],color=1, $
  ;     xticks = xticks,xminor=10, $
  ;     yticks = yticks,yminor=4, $
  ;     charsize=0.9
  ;
end
;----------------------------------------------------------------------
pro GPItv::contour, z, x, y, _extra = options

  ; Routine to read in contour plot data and options, store in a heap
  ; variable structure, and overplot the contours.  Data to be contoured
  ; need not be the same dataset displayed in the GPItv window, but it
  ; should have the same x and y dimensions in order to align the
  ; overplot correctly.


  ;if (not(xregistered(self.xname, /noshow))) then begin
  ;    self->message, msgtype='error', 'You need to start GPItv first!'
  ;    return
  ;endif

  if (N_params() LT 1) then begin
    self->message, msgtype='error', 'Too few parameters for GPItvCONTOUR.'
    return
  endif

  if (n_params() EQ 1 OR n_params() EQ 2) then begin
    x = 0
    y = 0
  endif

  if (n_elements(options) EQ 0) then options = {c_color: 'red'}

  if (self.pdata.nplot LT self.pdata.maxplot) then begin
    self.pdata.nplot = self.pdata.nplot + 1

    ;  convert color names to index numbers, and set default=red
    c = where(tag_names(options) EQ 'C_COLOR', count)
    if (count EQ 0) then options = create_struct(options, 'c_color', 'red')
    options.c_color = self->icolor(options.c_color)

    pstruct = {type: 'contour',  $     ; type of plot
      z: z,             $     ; z values
      x: x,             $     ; x coordinate
      y: y,             $     ; y coordinate
      options: options  $     ; plot keyword options
    }

    self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)

    self->plotwindow
    self->plot1contour, self.pdata.nplot

  endif else begin
    self->message, msgtype='error', 'Too many calls to GPItvCONTOUR.'
  endelse

end

;----------------------------------------------------------------------

pro GPItv::plotcolorbar,_extra=options


  ;	help, options
  ;   if (not(xregistered(self.xname, /noshow))) then begin
  ;      self->message, msgtype='error', 'You need to start GPItv first!'
  ;      return
  ;   endif

  if (self.pdata.nplot lt self.pdata.maxplot) then begin
    self.pdata.nplot=self.pdata.nplot+1;

    pstruct = {type:'colorbar', $
      options: options $
    };
    self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct);

    self->plotwindow
    self->plot1colorbar, self.pdata.nplot

  endif else begin
    self->message, msgtype='error', 'Too many calls to GPItvCOLORBAR'
  endelse
end

;----------------------------------------------------------------------

pro GPItv::plot1colorbar,iplot


  self->setwindow, (*self.state).draw_window_id
  wsize = (*self.state).draw_window_size
  widget_control, /hourglass

  position = (*(self.pdata.plot_ptr[iplot])).options.position
  range = (*(self.pdata.plot_ptr[iplot])).options.range
  minrange=range[0]
  maxrange=range[1]
  invertcolors = (*(self.pdata.plot_ptr[iplot])).options.invertcolors
  color = (*(self.pdata.plot_ptr[iplot])).options.color
  title = (*(self.pdata.plot_ptr[iplot])).options.title
  format = (*(self.pdata.plot_ptr[iplot])).options.format
  charsize=1
  ticklen=0.2
  font = !P.Font
  minor = 2
  divisions=(*(self.pdata.plot_ptr[iplot])).options.divisions

  xstart = position[0]
  ystart = position[1]

  xsize = (position[2] - position[0])
  ysize = (position[3] - position[1])

  csize = ceil((position[2]-position[0])*wsize[0])

  b = congrid( findgen((*self.state).ncolors), csize) + 8
  c = replicate(1,ceil(ysize*wsize[1]))
  a = b # c
  if invertcolors then a=reverse(a,1)
  tv, a,xstart,ystart,xsize=xsize,ysize=ysize,/normal

  PLOT, [minrange,maxrange], [minrange,maxrange], /NODATA, XTICKS=divisions, $
    YTICKS=1, XSTYLE=1, YSTYLE=1, TITLE=title, $
    POSITION=position, COLOR=color, CHARSIZE=charsize, /NOERASE, $
    YTICKFORMAT='(A1)', XTICKFORMAT=format, XTICKLEN=ticklen, $
    XRANGE=[minrange, maxrange], FONT=font, XMinor=minor, _EXTRA=extra

  self->resetwindow
  (*self.state).newrefresh=1

end

;----------------------------------------------------------------------

pro gpitv::erase, nerase, norefresh = norefresh

  ; Routine to erase line plots, e.g. from GPItvPLOT, text from GPItvXYOUTS,
  ; arrows from GPItvARROW and contours from GPItvCONTOUR.


  if (n_params() LT 1) then begin
    nerase = self.pdata.nplot
  endif else begin
    if (nerase GT self.pdata.nplot) then nerase = self.pdata.nplot
  endelse

  for iplot = self.pdata.nplot - nerase + 1, self.pdata.nplot do begin
    ; if we erase the polarization plots, clear the status flag.
    if (*(self.pdata.plot_ptr[iplot])).type eq 'polarization' then begin
      (*self.state).polarim_plotindex=-1
      ; close polarimetry options dialog, if present
      if (xregistered(self.xname+'_polarim')) then widget_control, (*self.state).polarim_dialog_id, /destroy
    endif
    ptr_free, self.pdata.plot_ptr[iplot]
    self.pdata.plot_ptr[iplot] = ptr_new()
  endfor

  self.pdata.nplot = self.pdata.nplot - nerase

  if (NOT keyword_set(norefresh)) then self->refresh

end

;----------------------------------------------------------------------

pro GPItv::textlabel

  ; widget front end for GPItvxyouts


  formdesc = ['0, text, , label_left=Text: , width=15, RIGHT ', $
    '0, integer, 0, label_left=x: , RIGHT', $
    '0, integer, 0, label_left=y: , RIGHT', $
    '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
    '0, float, 2.0, label_left=Charsize: ', $
    '0, integer, 1, label_left=Charthick: ', $
    '0, integer, 0, label_left=Orientation: ', $
    '1, base, , row', $
    '0, button, Cancel, quit', $
    '0, button, DrawText, quit']

  if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
  textform = cw_form(formdesc, /column, $
    title = title_base+' text label')

  if (textform.tag9 EQ 1) then begin
    ; switch red and black indices
    case textform.tag3 of
      0: labelcolor = 1
      1: labelcolor = 0
      else: labelcolor = textform.tag3
    endcase

    self->xyouts, textform.tag1, textform.tag2, textform.tag0, $
      color = labelcolor, charsize = textform.tag4, $
      charthick = textform.tag5, orientation = textform.tag6
  endif

end

;---------------------------------------------------------------------

pro GPItv::arrowlabel

  ; widget front end for GPItvarrow


  formdesc = ['0, integer, 0, label_left=x1: ', $
    '0, integer, 0, label_left=y1: ', $
    '0, integer, 0, label_left=x2: ', $
    '0, integer, 0, label_left=y2: ', $
    '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
    '0, float, 1.0, label_left=Arrowthick: ', $
    '0, float, 1.0, label_left=Arrowheadthick: ', $
    '1, base, , row', $
    '0, button, Cancel, quit', $
    '0, button, DrawArrow, quit']

  textform = cw_form(formdesc, /column, $
    title = 'GPItv arrow')

  if (textform.tag9 EQ 1) then begin
    ; switch red and black indices
    case textform.tag4 of
      0: labelcolor = 1
      1: labelcolor = 0
      else: labelcolor = textform.tag4
    endcase

    self->arrow, textform.tag0, textform.tag1, textform.tag2, textform.tag3, $
      color = labelcolor, thick = textform.tag5, $
      hthick = textform.tag6

  endif

end

;---------------------------------------------------------------------

pro GPItv::regionfilelabel

  ; Routine to load region files into GPItv

  region_file = dialog_pickfile(/read, filter='*.reg')

  ;set up an array of strings

  if (region_file ne '') then self->regionfile, region_file $
  else return

end

;---------------------------------------------------------------------

pro GPItv::regionlabel

  ; Widget front-end for plotting individual regions on image


  if (not(xregistered(self.xname+'regionlabel', /noshow))) then begin

    regionbase = widget_base(group_leader = (*self.state).base_id, $
      title = 'GPItv Region Label', $
      uvalue = 'regionlabel_base', $
      /row)

    formdesc = ['0, droplist, circle|box|ellipse|line,label_left=Region:, set_value=0, TAG=reg_opt ', $
      '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0, TAG=color_opt ', $
      '0, droplist, Pixel|RA Dec (J2000)|RA Dec (B1950)|Galactic|Ecliptic|Native,label_left=Coords:, set_value=0, TAG=coord_opt ', $
      '0, text, 0, label_left=xcenter: , width=15', $
      '0, text, 0, label_left=ycenter: , width=15', $
      '0, text, 1, label_left=xwidth: , width=15', $
      '0, text, 1, label_left=ywidth: , width=15', $
      '0, text, 0, label_left=x1: , width=15', $
      '0, text, 0, label_left=y1: , width=15', $
      '0, text, 0, label_left=x2: , width=15', $
      '0, text, 0, label_left=y2: , width=15', $
      '0, text, 0.0, label_left=Angle: ', $
      '0, integer, 1, label_left=Thick: ', $
      '0, text,  , label_left=Text: ', $
      '1, base, , row', $
      '0, button, Done, quit, TAG=quit ', $
      '0, button, DrawRegion, quit, TAG=draw']

    regionform = cw_form(regionbase,formdesc, /column,title = 'GPItv region',$
      IDS=reg_ids_ptr)



    reg_ids_ptr = reg_ids_ptr[where(widget_info(reg_ids_ptr,/type) eq 3 OR $
      widget_info(reg_ids_ptr,/type) eq 8)]

    if ptr_valid((*self.state).reg_ids_ptr) then ptr_free,(*self.state).reg_ids_ptr

    (*self.state).reg_ids_ptr = ptr_new(reg_ids_ptr)

    widget_control,(*(*self.state).reg_ids_ptr)[6],sensitive=0
    widget_control,(*(*self.state).reg_ids_ptr)[7],sensitive=0
    widget_control,(*(*self.state).reg_ids_ptr)[8],sensitive=0
    widget_control,(*(*self.state).reg_ids_ptr)[9],sensitive=0
    widget_control,(*(*self.state).reg_ids_ptr)[10],sensitive=0
    widget_control,(*(*self.state).reg_ids_ptr)[11],sensitive=0
    widget_control,(*(*self.state).reg_ids_ptr)[3], Set_Value = $
      strcompress(string((*self.state).coord[0]), /remove_all)
    widget_control,(*(*self.state).reg_ids_ptr)[4], Set_Value = $
      strcompress(string((*self.state).coord[1]), /remove_all)
    widget_control,(*(*self.state).reg_ids_ptr)[7], Set_Value = $
      strcompress(string((*self.state).coord[0]), /remove_all)
    widget_control,(*(*self.state).reg_ids_ptr)[8], Set_Value = $
      strcompress(string((*self.state).coord[1]), /remove_all)
    widget_control, regionbase, /REALIZE
    xmanager, self.xname+'regionlabel', regionbase, /no_block
    widget_control,regionbase, set_uvalue = {object:self, method: 'regionlabel_event'}
    widget_control,regionbase, event_pro = 'GPItvo_subwindow_event_handler'


  endif else begin
    widget_control,(*(*self.state).reg_ids_ptr)[3], Set_Value = $
      strcompress(string((*self.state).coord[0]), /remove_all)
    widget_control,(*(*self.state).reg_ids_ptr)[4], Set_Value = $
      strcompress(string((*self.state).coord[1]), /remove_all)
    widget_control,(*(*self.state).reg_ids_ptr)[7], Set_Value = $
      strcompress(string((*self.state).coord[0]), /remove_all)
    widget_control,(*(*self.state).reg_ids_ptr)[8], Set_Value = $
      strcompress(string((*self.state).coord[1]), /remove_all)
  endelse

  ;widget_control, regionbase, set_uvalue=self

end

;---------------------------------------------------------------------

pro GPItv::wcsgridlabel
  ; Front-end widget for WCS labels


  formdesc = ['0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Grid Color:, set_value=7 ', $
    '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Label Color:, set_value=2 ', $
    '0, float, 1.0, label_left=Charsize: ', $
    '0, integer, 1, label_left=Charthick: ', $
    '1, base, , row', $
    '0, button, Cancel, quit', $
    '0, button, DrawGrid, quit']

  if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
  gridform=cw_form(formdesc, /column, title = title_base+' WCS Grid')

  gridcolor = gridform.tag0
  wcslabelcolor = gridform.tag1

  if (gridform.tag6 eq 1) then begin
    ; switch red and black indices
    case gridform.tag0 of
      0: gridcolor = 1
      1: gridcolor = 0
      else: gridcolor = gridform.tag0
    endcase

    case gridform.tag1 of
      0: wcslabelcolor = 1
      1: wcslabelcolor = 0
      else: wcslabelcolor = gridform.tag1
    endcase


    self->wcsgrid, gridcolor=gridcolor, wcslabelcolor=wcslabelcolor, $
      charsize=gridform.tag2, charthick=gridform.tag3

  endif

end
;---------------------------------------------------------------------
pro GPItv::selectwavecal
  ; Let the user manually select a wavelength calibration (or polarization
  ; calibration) file

  hd = *((*self.state).head_ptr)
  if ptr_valid((*self.state).exthead_ptr) then exthd = *((*self.state).exthead_ptr) else exthd = ['', 'END']

  inst = gpi_get_keyword(hd, exthd, 'INSTRUME',count=cc)
  if strc(inst) ne 'GPI' then begin
    self->message, "The current file does not appear to be a GPI IFS 2D image",msgtype='error', /window
    return
  endif

  if (size(*self.images.main_image_stack))[0] ne 2 then begin
    self->message, "The current file does not appear to be a GPI IFS 2D image",msgtype='error', /window
    return
  endif

  disperser = gpi_get_keyword(hd, exthd, 'DISPERSR',count=cc)
  if strmatch(disperser, '*PRISM*',/fold) then begin
    calfiletype = 'Wavecal'
    filter='*wavecal*.fits'
  endif else if strmatch(disperser, '*WOLL*',/fold) then begin
    calfiletype = 'Polcal'
    filter='*polcal*.fits'
  endif else begin
    self->message, "The current file does not appear to have a valid DISPERSR keyword",msgtype='error', /window
    return
  endelse



  fitsfile = DIALOG_PICKFILE( TITLE='Select '+calfiletype+'File ', FILTER = filter, FILE='*.fits',/MUST_EXIST,$
    path=gpi_get_directory('GPI_CALIBRATIONS_DIR'))
  if (fitsfile EQ '') then return ; 'cancel' button returns empty string

  (*self.state).wcfilename= fitsfile
  self->message, [calfiletype+" file set to "+(*self.state).wcfilename, "Now select 'Plot Wavecal/Polcal Grid' to display it."],/window

end

;---------------------------------------------------------------------
pro GPItv::getautowavecal,silent=silent
  ; load automatic best wavelength calibration (or polarizatoin calibration)
  ; file from the GPI Calibration DB


  hd = *((*self.state).head_ptr)
  if ptr_valid((*self.state).exthead_ptr) then exthd = *((*self.state).exthead_ptr) else exthd = ['', 'END']

  inst = gpi_get_keyword(hd, exthd, 'INSTRUME',count=cc)
  if strc(inst) ne 'GPI' then begin
    self->message, "The current file does not appear to be a GPI IFS 2D image",msgtype='error', /window
    return
  endif

  if (size(*self.images.main_image_stack))[0] ne 2 then begin
    self->message, "The current file does not appear to be a GPI IFS 2D image",msgtype='error', /window
    return
  endif

  disperser = gpi_get_keyword(hd, exthd, 'DISPERSR',count=cc)
  if strmatch(disperser, '*PRISM*',/fold) then calfiletype = 'wavecal' $
  else if strmatch(disperser, '*WOLL*',/fold) then calfiletype = 'polcal' $
  else begin
    self->message, "The current file does not appear to have a valid DISPERSR keyword",msgtype='error', /window
    return
  endelse

  caldb = obj_new('gpicaldatabase')

  bestfile = caldb->get_best_cal_from_header( calfiletype, hd, exthd )

  if strc(bestfile) eq '-1' then begin
    self->message, ['ERROR: No available appropriate calibration files for this data!','', 'The calibration database does not contain a wavecal or polcal file','that matches this image in IFSFILT and DISPERSR keywords. Cannot load data to plot.'],/window,msgtype='error'
    (*self.state).wcfilename=''
  endif else begin
	if ~(keyword_set(silent)) then $
	    self->message, ["Retrieved "+calfiletype+" file from Calibration DB: "+bestfile, "Now select 'Plot Wavecal/Polcal Grid' to display it."],/window
    (*self.state).wcfilename = bestfile
  endelse


end
;---------------------------------------------------------------------

pro GPItv::wavecalgridlabel
  ; Front-end widget for wavecal labels

  ; if we don't have a wavecal selected, try to load one automatically:
  if (*self.state).wcfilename eq '' then begin
	  self->getautowavecal,/silent

	  ; if we still don't have one (because the auto load didn't work)
	  ; then tell the user they have to intervene manually.
	  if (*self.state).wcfilename eq '' then begin
		self->message, msgtype = 'error', "You must select a wavelength/polarization calibration file first before you can overplot the solution!",/window
		return
	  endif
  endif

  ; Check for applied shifts to account for flexure
  shiftx = sxpar( *((*self.state).head_ptr), 'SPOT_DX', count=ct)
  if ct eq 0 then shiftx=0
  shifty = sxpar( *((*self.state).head_ptr), 'SPOT_DY', count=ct)
  if ct eq 0 then shifty=0

  ; estimate the appropriate shifts from the wavecal and the flexure model

  recommend_shifts=0
  caldb = obj_new('gpicaldatabase')
  shiftsfile = caldb->get_best_cal_from_header( 'shifts', *((*self.state).head_ptr),  *((*self.state).exthead_ptr) )
  ; determine if shiftsfile is a string - if it is then it found a valid file
  ; if it returned an interger (-1) then it found nothing
  result_type=size(shiftsfile,/tname)

  if ((result_type eq 'STRING') and file_test(string(shiftsfile))) then begin
    ; Try to read in all the necessary info and call the flexure model
    elevation = sxpar(*((*self.state).head_ptr), 'ELEVATIO')
    wchd = headfits((*self.state).wcfilename)
    wc_elevation = sxpar(wchd, 'ELEVATIO')
    lookuptable = gpi_readfits(shiftsFile)
    recommended_shifts = gpi_flexure_model( lookuptable, elevation, wavecal_elevation=wc_elevation,display=-1)
  endif else begin
    recommended_shifts = [0.0, 0.0]
  endelse

  ; Query the user for desired wavecal display options

  formdesc = ['0, droplist, black|red|green|blue|cyan|magenta|yellow|white,label_left=Grid Color:   , set_value=1 ', $ ; tag0
    '0, droplist, black|red|green|blue|cyan|magenta|yellow|white,label_left=Trace Color:   , set_value=2 ', $ ; tag1
    '0, label, Recommended spot shifts from flexure model:,left ',$	; tag2
    '0, label,     (delta X\, delta Y) = ('+sigfig(recommended_shifts[0],3)+'\, '+sigfig(recommended_shifts[1],3)+' ) , center',$	; tag3
    '0, float, '+string(shiftx)+', label_left=Spot Shift X: ', $ ; tag4
    '0, float, '+string(shifty)+', label_left=Spot Shift Y: ', $ ; tag5
    '0, droplist, no|yes,label_left=Include mlens coord labels:, set_value=0 ', $ ; tag6
    '0, droplist, black|red|green|blue|cyan|magenta|yellow|white,label_left=Label Color:       , set_value=7 ', $ ; tag7
    '0, float, 1.0, label_left=Charsize: ', $ ; tag8
    '0, integer, 1, label_left=Charthick: ', $ ; tag9
    '1, base, , row', $	; tag10
    '0, button, Cancel, quit', $ ; tag11
    '0, button, DrawGrid, quit'] ; tag12

  if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
  gridform=cw_form(formdesc, /column, title = title_base+' Plot Wavecal Grid Options ')

  gridcolor = gridform.tag0
  wcslabelcolor = gridform.tag1

  if (gridform.tag12 eq 1) then begin
    ;; switch red and black indices
    ;  case gridform.tag0 of
    ;    0: gridcolor = 1
    ;    1: gridcolor = 0
    ;    else: gridcolor = gridform.tag0
    ;  endcase
    ;
    ;  case gridform.tag1 of
    ;    0: wcslabelcolor = 1
    ;    1: wcslabelcolor = 0
    ;    else: wcslabelcolor = gridform.tag1
    ;  endcase

    shiftx = gridform.tag4
    shifty = gridform.tag5

    print, "Shifts", shiftx, shifty
    sxaddpar,  *((*self.state).head_ptr), 'SPOT_DX', shiftx
    sxaddpar,  *((*self.state).head_ptr), 'SPOT_DY', shifty

    self->wavecalgrid, gridcolor=gridform.tag0, tiltcolor=gridform.tag1, labeldisp=gridform.tag6, $
      labelcolor=gridform.tag7, charsize=gridform.tag8, charthick=gridform.tag9

  endif

end

;---------------------------------------------------------------------

pro GPItv::oplotcontour

  ; widget front end for GPItvcontour

  minvalstring = strcompress('0, float, ' + string((*self.state).min_value) + $
    ', label_left=MinValue: , width=15 ')
  maxvalstring = strcompress('0, float, ' + string((*self.state).max_value) + $
    ', label_left=MaxValue: , width=15')

  formdesc = ['0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
    ;            '0, float, 1.0, label_left=Charsize: ', $
    ;            '0, integer, 1, label_left=Charthick: ', $
    '0, droplist, solid|dotted|dashed|dashdot|dashdotdotdot|longdash, label_left=Linestyle: , set_value=0', $
    '0, integer, 1, label_left=LineThickness: ', $
    minvalstring, $
    maxvalstring, $
    '0, integer, 6, label_left=NLevels: ', $
    '1, base, , row,', $
    '0, button, Cancel, quit', $
    '0, button, DrawContour, quit']

  cform = cw_form(formdesc, /column, $
    title = 'GPItv text label')


  if (cform.tag8 EQ 1) then begin
    ; switch red and black indices
    case cform.tag0 of
      0: labelcolor = 1
      1: labelcolor = 0
      else: labelcolor = cform.tag0
    endcase

    self->contour, *self.images.main_image, c_color = labelcolor, $
      ;      c_charsize = cform.tag1, c_charthick = cform.tag2, $
      c_linestyle = cform.tag1, $
      c_thick = cform.tag2, $
      min_value = cform.tag3, max_value = cform.tag4, $,
      nlevels = cform.tag5
  endif

end

;---------------------------------------------------------------------

pro GPItv::setcompass

  ; Routine to prompt user for compass parameters

  if (self.pdata.nplot GE self.pdata.maxplot) then begin
    self->message, 'Total allowed number of overplots exceeded.', $
      msgtype = 'error', /window
    return
  endif


  if ((*self.state).wcstype NE 'angle') then begin
    self->message, 'Cannot get coordinate info for this image!', $
      msgtype = 'error', /window
    return
  endif

  view_min = round((*self.state).centerpix - $
    (0.5 * (*self.state).draw_window_size / (*self.state).zoom_factor))
  view_max = round(view_min + (*self.state).draw_window_size / (*self.state).zoom_factor) - 1

  xpos = string(round(view_min[0] + 0.15 * (view_max[0] - view_min[0])))
  ypos = string(round(view_min[1] + 0.15 * (view_max[1] - view_min[1])))

  xposstring = strcompress('0,integer,'+xpos+',label_left=XCenter: ')
  yposstring = strcompress('0,integer,'+ypos+',label_left=YCenter: ')

  formdesc = [ $
    xposstring, $
    yposstring, $
    '0, droplist, Vertex of Compass|Center of Compass, label_left = Coordinates Specify:, set_value=0', $
    '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
    '0, integer, 1, label_left=LineThickness: ', $
    '0, float, 1, label_left=Charsize: ', $
    '0, float, 3.5, label_left=ArrowLength: ', $
    '1, base, , row,', $
    '0, button, Cancel, quit', $
    '0, button, DrawCompass, quit']

  cform = cw_form(formdesc, /column, $
    title = 'GPItv compass properties')

  if (cform.tag8 EQ 1) then return

  cform.tag0 = 0 > cform.tag0 < ((*self.state).image_size[0] - 1)
  cform.tag1 = 0 > cform.tag1 < ((*self.state).image_size[1] - 1)

  ; switch red and black indices
  case cform.tag3 of
    0: labelcolor = 1
    1: labelcolor = 0
    else: labelcolor = cform.tag3
  endcase

  pstruct = {type: 'compass',  $  ; type of plot
    x: cform.tag0,         $
    y: cform.tag1,         $
    notvertex: cform.tag2, $
    color: labelcolor, $
    thick: cform.tag4, $
    charsize: cform.tag5, $
    arrowlen: cform.tag6 $
  }

  self.pdata.nplot = self.pdata.nplot + 1
  self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)

  self->plotwindow
  self->plot1compass, self.pdata.nplot

end

;---------------------------------------------------------------------

pro GPItv::setscalebar

  ; Routine to prompt user for scalebar parameters

  if (self.pdata.nplot GE self.pdata.maxplot) then begin
    self->message, 'Total allowed number of overplots exceeded.', $
      msgtype = 'error', /window
    return
  endif


  if ((*self.state).wcstype NE 'angle') then begin
    self->message, 'Cannot get coordinate info for this image!', $
      msgtype = 'error', /window
    return
  endif

  view_min = round((*self.state).centerpix - $
    (0.5 * (*self.state).draw_window_size / (*self.state).zoom_factor))
  view_max = round(view_min + (*self.state).draw_window_size / (*self.state).zoom_factor) - 1

  xpos = string(round(view_min[0] + 0.75 * (view_max[0] - view_min[0])))
  ypos = string(round(view_min[1] + 0.15 * (view_max[1] - view_min[1])))

  xposstring = strcompress('0,integer,'+xpos+',label_left=X (left end of bar): ')
  yposstring = strcompress('0,integer,'+ypos+',label_left=Y (center of bar): ')

  formdesc = [ $
    xposstring, $
    yposstring, $
    '0, float, 5.0, label_left=BarLength: ', $
    '0, droplist, arcsec|arcmin, label_left=Units:,set_value=0', $
    '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
    '0, integer, 1, label_left=LineThickness: ', $
    '0, float, 1, label_left=Charsize: ', $
    '1, base, , row,', $
    '0, button, Cancel, quit', $
    '0, button, DrawScalebar, quit']

  cform = cw_form(formdesc, /column, $
    title = 'GPItv scalebar properties')

  if (cform.tag8 EQ 1) then return

  ; switch red and black indices
  case cform.tag4 of
    0: labelcolor = 1
    1: labelcolor = 0
    else: labelcolor = cform.tag4
  endcase


  cform.tag0 = 0 > cform.tag0 < ((*self.state).image_size[0] - 1)
  cform.tag1 = 0 > cform.tag1 < ((*self.state).image_size[1] - 1)
  cform.tag3 = abs(cform.tag3 - 1)  ; set default to be arcseconds

  arclen = cform.tag2
  if (float(round(arclen)) EQ arclen) then arclen = round(arclen)

  pstruct = {type: 'scalebar',  $  ; type of plot
    arclen: arclen, $
    seconds: cform.tag3, $
    position: [cform.tag0,cform.tag1], $
    color: labelcolor, $
    thick: cform.tag5, $
    size: cform.tag6 $
  }

  self.pdata.nplot = self.pdata.nplot + 1
  self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)

  self->plotwindow
  self->plot1scalebar, self.pdata.nplot

end

;---------------------------------------------------------------------

pro GPItv::saveregion

  ; Save currently displayed regions to a file

  if self.pdata.nplot ge 1 then begin
    reg_savefile = dialog_pickfile(file='GPItv.reg', filter='*.reg', /write)

    if (reg_savefile ne '') then begin
      openw, lun, reg_savefile, /get_lun

      for iplot = 1, self.pdata.nplot do begin
        if ((*(self.pdata.plot_ptr[iplot])).type eq 'region') then begin
          n_regions = n_elements((*(self.pdata.plot_ptr[iplot])).reg_array)
          for n = 0, n_regions - 1 do begin
            printf, lun, strcompress((*(self.pdata.plot_ptr[iplot])).reg_array[n],/remove_all)
          endfor
        endif
      endfor

      close, lun
      free_lun, lun
    endif else begin
      return
    endelse
  endif else begin
    self->message, 'There is no over-plot to save!', $
      msgtype = 'error', /window
    return
  endelse
end

;---------------------------------------------------------------------
;          routines for drawing in the lineplot window
;---------------------------------------------------------------------

pro GPItv::lineplot_init

  ; This routine creates the window for line plots

  if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
  (*self.state).lineplot_base_id = $
    widget_base(group_leader = (*self.state).base_id, $
    /row, $
    ;              mbar=mbar, $
    /base_align_right, $
    title = title_base+' plot', $
    /tlb_size_events, $
    uvalue = 'lineplot_base')

  (*self.state).lineplot_widget_id = $
    widget_draw((*self.state).lineplot_base_id, $
    frame = 0, $
    scr_xsize = (*self.state).lineplot_size[0], $
    scr_ysize = (*self.state).lineplot_size[1], $
    uvalue = 'lineplot_window')

  lbutton_base = $
    widget_base((*self.state).lineplot_base_id, $
    /base_align_bottom, $
    /column, frame=2)

  ;filemenu_base = widget_button(mbar, value='File')
  ;lineplot_ps = $
  ;  widget_button(filemenu_base, $
  ;                value = 'Create PS', $
  ;                uvalue = 'lineplot_ps')

  ;lineplot_done = widget_button(filemenu_base, value='Exit', $
  ;                  uvalue = 'lineplot_done')

  (*self.state).histbutton_base_id = $
    widget_base(lbutton_base, $
    /base_align_bottom, $
    /column, map=1)
  xsizetmp=12
  (*self.state).x1_pix_id = $
    cw_field((*self.state).histbutton_base_id, $
    /return_events, $
    /floating, $
    title = 'X1:', $
    uvalue = 'lineplot_newrange', $
    xsize = xsizetmp)

  (*self.state).x2_pix_id = $
    cw_field((*self.state).histbutton_base_id, $
    /return_events, $
    /floating, $
    title = 'X2:', $
    uvalue = 'lineplot_newrange', $
    xsize = xsizetmp)

  (*self.state).y1_pix_id = $
    cw_field((*self.state).histbutton_base_id, $
    /return_events, $
    /floating, $
    title = 'Y1:', $
    uvalue = 'lineplot_newrange', $
    xsize = xsizetmp)

  (*self.state).y2_pix_id = $
    cw_field((*self.state).histbutton_base_id, $
    /return_events, $
    /floating, $
    title = 'Y2:', $
    uvalue = 'lineplot_newrange', $
    xsize = xsizetmp)

  (*self.state).histplot_binsize_id = $
    cw_field((*self.state).histbutton_base_id, $
    /return_events, $
    /floating, $
    title = 'Bin:', $
    uvalue = 'lineplot_newrange', $
    xsize = xsizetmp)

  (*self.state).lineplot_xmin_id = $
    cw_field(lbutton_base, $
    /return_events, $
    /floating, $
    title = 'XMin:', $
    uvalue = 'lineplot_newrange', $
    xsize = xsizetmp)

  (*self.state).lineplot_xmax_id = $
    cw_field(lbutton_base, $
    /return_events, $
    /floating, $
    title = 'XMax:', $
    uvalue = 'lineplot_newrange', $
    xsize = xsizetmp)

  (*self.state).lineplot_ymin_id = $
    cw_field(lbutton_base, $
    /return_events, $
    /floating, $
    title = 'YMin:', $
    uvalue = 'lineplot_newrange', $
    xsize = xsizetmp)

  (*self.state).lineplot_ymax_id = $
    cw_field(lbutton_base, $
    /return_events, $
    /floating, $
    title = 'YMax:', $
    uvalue = 'lineplot_newrange', $
    xsize = xsizetmp)


  (*self.state).holdrange_base_id = $
    widget_base(lbutton_base, $
    row = 1, $
    /nonexclusive, frame=1)

  (*self.state).holdrange_butt_id = $
    widget_button((*self.state).holdrange_base_id, $
    value = 'Hold Ranges', $
    uvalue = 'lineplot_holdrange')

  lineplot_fullrange = $
    widget_button(lbutton_base, $
    value = 'AutoScale', $
    uvalue = 'lineplot_fullrange')

  lineplot_ps = $
    widget_button(lbutton_base, $
    value = 'Create PS', $
    uvalue = 'lineplot_ps')

  lineplot_save = $
    widget_button(lbutton_base, $
    value = 'Save values...', $
    uvalue = 'lineplot_save')


  lineplot_done = $
    widget_button(lbutton_base, $
    value = 'Done', $
    uvalue = 'lineplot_done')

  widget_control, (*self.state).lineplot_base_id, /realize
  widget_control, (*self.state).holdrange_butt_id, set_button=(*self.state).holdrange_value

  widget_control, (*self.state).lineplot_widget_id, get_value = tmp_value
  (*self.state).lineplot_window_id = tmp_value

  lbuttgeom = widget_info(lbutton_base, /geometry)
  (*self.state).lineplot_min_size[1] = lbuttgeom.ysize

  basegeom = widget_info((*self.state).lineplot_base_id, /geometry)
  drawgeom = widget_info((*self.state).lineplot_widget_id, /geometry)

  (*self.state).lineplot_pad[0] = basegeom.xsize - drawgeom.xsize
  (*self.state).lineplot_pad[1] = basegeom.ysize - drawgeom.ysize

  xmanager, self.xname+'_lineplot', (*self.state).lineplot_base_id, /no_block
  widget_control, (*self.state).lineplot_base_id, set_uvalue={object:self, method: 'lineplot_event'}
  widget_control, (*self.state).lineplot_base_id, event_pro = 'GPItvo_subwindow_event_handler'

  self->resetwindow
end


;--------------------------------------------------------------------

pro GPItv::centerplot, ps=ps, update=update

  ;; Create plot of center positions as a function of wavelength.
  ;;
  ;; Only initialize plot window and plot ranges to the min/max ranges
  ;; when centerplot window is not already present, plot window is present
  ;; but last plot was not a centerplot, or last plot was a centerplot but the
  ;; 'Hold Range' button is not selected.  Otherwise, use the values
  ;; currently in the min/max boxes

  ;;if not data cube, bail
  if (n_elements((*self.state).image_size) ne 3) || (((*self.state).image_size)[2] lt 2) then begin
    self->message, msgtype='error', "Star location plotting only works with 3D datacube"
    return
  endif

  ;;if no satspots in memory, calculate them
  if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
    self->update_sat_spots

    ;;if failed, need to return
    if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
      self->message, msgtype='error', "Cannot plot star location because we cannot determine the center without satellite spots."
      return
    endif
  endif

  ;;calculate center locations
  ;  cents = mean(*self.satspots.cens,dim=2) ; not idl 7.0 compatible
  tmp=*self.satspots[*].cens
  cents=fltarr(2,N_ELEMENTS(tmp[0,0,*]))
  for p=0, N_ELEMENTS(tmp[0,0,*]) -1 do begin
    for q=0, 1 do cents[q,p]=mean(tmp[q,*,p])
  endfor

  if (not (keyword_set(ps))) then begin

    if (not (xregistered(self.xname+'_lineplot'))) then begin
      ;;create new lineplot window
      self->lineplot_init
      newplot = 1
    endif else newplot = 0

    widget_control, (*self.state).histbutton_base_id, map=0
    widget_control, (*self.state).holdrange_butt_id, sensitive=1
    if (newplot eq 1) || ((*self.state).plot_type ne 'centerplot') || ((*self.state).holdrange_value eq 0) then begin
      (*self.state).lineplot_xmin = (*self.state).CWV_lmin
      (*self.state).lineplot_xmax = (*self.state).CWV_lmax
      (*self.state).lineplot_ymin = 0
      (*self.state).lineplot_ymax = max((*self.state).image_size)

      widget_control,(*self.state).lineplot_xmin_id, set_value = (*self.state).lineplot_xmin
      widget_control,(*self.state).lineplot_xmax_id, set_value = (*self.state).lineplot_xmax
      widget_control,(*self.state).lineplot_ymin_id, set_value = (*self.state).lineplot_ymin
      widget_control,(*self.state).lineplot_ymax_id, set_value = (*self.state).lineplot_ymax
    endif

    (*self.state).plot_type = 'centerplot'
    self->setwindow, (*self.state).lineplot_window_id
    erase
    col = 7
  endif else col = 0

  ;;since x & y can be different (if pointing is off-center) and
  ;;the ranges will be very small, split into two plots
  pmulti0 = !P.MULTI
  !P.MULTI = [0, 0, 2, 0, 0]
  plot,(*(*self.state).CWV_ptr),cents[0,*],$
    xst = 3, yst = 3, psym = 4, $
    title = strcompress('Plot of Star Position'), $
    ytitle = 'X [Pixel Value]', $
    color = col, xmargin=[15,3]

  meanXcen = mean(cents[0,*])
  plots, [min(*(*self.state).CWV_ptr), max(*(*self.state).CWV_ptr)], [meanXcen, meanXcen], /lines, color=6
  xyouts, min(*(*self.state).CWV_ptr)+0.05, meanXcen+0.01, "Mean: "+strc(meanXcen), color=6, charsize=1.5


  plot,(*(*self.state).CWV_ptr),cents[1,*],$
    xst = 3, yst = 3, psym = 4, $
    ytitle = 'Y [Pixel Value]', $
    color = col, xmargin=[15,3], $
    xtitle = 'Wavelength ['+'!4' + string("154B) + '!Xm]' ;;"just here to keep emacs from flipping out


  meanYcen = mean(cents[1,*])
  plots, [min(*(*self.state).CWV_ptr), max(*(*self.state).CWV_ptr)], [meanYcen, meanYcen], /lines, color=6
  xyouts, min(*(*self.state).CWV_ptr)+0.05, meanYcen+0.01, "Mean: "+strc(meanYcen), color=6, charsize=1.5


  ;;put window back to orig state
  !P.MULTI = pmulti0

  if (not (keyword_set(ps))) then begin
    widget_control, (*self.state).lineplot_base_id, /clear_events
    self->resetwindow
  endif

end

;--------------------------------------------------------------------

pro GPItv::rowplot, ps=ps, update=update


  if (not (keyword_set(ps))) then begin

    ; Only initialize plot window and plot ranges to the min/max ranges
    ; when rowplot window is not already present, plot window is present
    ; but last plot was not a rowplot, or last plot was a rowplot but the
    ; 'Hold Range' button is not selected.  Otherwise, use the values
    ; currently in the min/max boxes

    if (not (xregistered(self.xname+'_lineplot', /noshow))) then begin
      self->lineplot_init

      widget_control,(*self.state).lineplot_xmin_id, $
        set_value=0

      (*self.state).lineplot_xmin = 0.0

      widget_control,(*self.state).lineplot_xmax_id, $
        set_value=(*self.state).image_size[0]

      (*self.state).lineplot_xmax = (*self.state).image_size[0]

      widget_control,(*self.state).lineplot_ymin_id, $
        set_value=min((*self.images.main_image)[*,(*self.state).coord[1]],/nan)

      (*self.state).lineplot_ymin = min((*self.images.main_image)[*,(*self.state).coord[1]],/nan)

      widget_control,(*self.state).lineplot_ymax_id, $
        set_value=max((*self.images.main_image)[*,(*self.state).coord[1]],/nan)

      (*self.state).lineplot_ymax = max((*self.images.main_image)[*,(*self.state).coord[1]],/nan)

    endif

    widget_control, (*self.state).histbutton_base_id, map=0
    widget_control, (*self.state).holdrange_butt_id, sensitive=1

    if ((*self.state).plot_type ne 'rowplot' OR $
      (*self.state).holdrange_value eq 0) then begin

      widget_control,(*self.state).lineplot_xmin_id, $
        set_value=0

      (*self.state).lineplot_xmin = 0.0

      widget_control,(*self.state).lineplot_xmax_id, $
        set_value=(*self.state).image_size[0]

      (*self.state).lineplot_xmax = (*self.state).image_size[0]

      widget_control,(*self.state).lineplot_ymin_id, $
        set_value=min((*self.images.main_image)[*,(*self.state).coord[1]],/nan)

      (*self.state).lineplot_ymin = min((*self.images.main_image)[*,(*self.state).coord[1]],/nan)

      widget_control,(*self.state).lineplot_ymax_id, $
        set_value=max((*self.images.main_image)[*,(*self.state).coord[1]],/nan)

      (*self.state).lineplot_ymax = max((*self.images.main_image)[*,(*self.state).coord[1]],/nan)

    endif

    (*self.state).plot_type = 'rowplot'
    self->setwindow, (*self.state).lineplot_window_id
    erase

    ; must store the coordinates in state structure if you want to make a
    ; PS plot because (*self.state).coord array will change if you move cursor
    ; before pressing 'Create PS' button

    if (not (keyword_set(update))) then (*self.state).plot_coord = (*self.state).coord

    plot, (*self.images.main_image)[*, (*self.state).plot_coord[1]], $
      xst = 3, yst = 3, psym = 10, $
      title = strcompress('Plot of row ' + $
      string((*self.state).plot_coord[1])), $
      xtitle = 'Column', $
      ytitle = 'Pixel Value', $
      color = 7, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

  endif else begin

    plot, (*self.images.main_image)[*, (*self.state).plot_coord[1]], $
      xst = 3, yst = 3, psym = 10, $
      title = strcompress('Plot of row ' + $
      string((*self.state).plot_coord[1])), $
      xtitle = 'Column', $
      ytitle = 'Pixel Value', $
      color = 0, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

  endelse

  if (not (keyword_set(ps))) then begin
    widget_control, (*self.state).lineplot_base_id, /clear_events
    self->resetwindow
  endif

end

;--------------------------------------------------------------------

pro GPItv::colplot, ps=ps, update=update


  if (not (keyword_set(ps))) then begin

    ; Only initialize plot window and plot ranges to the min/max ranges
    ; when colplot window is not already present, plot window is present
    ; but last plot was not a colplot, or last plot was a colplot but the
    ; 'Hold Range' button is not selected.  Otherwise, use the values
    ; currently in the min/max boxes

    if (not (xregistered(self.xname+'_lineplot', /noshow))) then begin
      self->lineplot_init

      widget_control,(*self.state).lineplot_xmin_id, $
        set_value=0

      (*self.state).lineplot_xmin = 0.0

      widget_control,(*self.state).lineplot_xmax_id, $
        set_value=(*self.state).image_size[1]

      (*self.state).lineplot_xmax = (*self.state).image_size[1]

      widget_control,(*self.state).lineplot_ymin_id, $
        set_value=min((*self.images.main_image)[(*self.state).coord[0], *],/nan)

      (*self.state).lineplot_ymin = min((*self.images.main_image)[(*self.state).coord[0], *],/nan)

      widget_control,(*self.state).lineplot_ymax_id, $
        set_value=max((*self.images.main_image)[(*self.state).coord[0], *],/nan)

      (*self.state).lineplot_ymax = max((*self.images.main_image)[(*self.state).coord[0], *],/nan)

    endif

    widget_control, (*self.state).histbutton_base_id, map=0
    widget_control, (*self.state).holdrange_butt_id, sensitive=1

    if ((*self.state).plot_type ne 'colplot' OR $
      (*self.state).holdrange_value eq 0) then begin

      widget_control,(*self.state).lineplot_xmin_id, $
        set_value=0

      (*self.state).lineplot_xmin = 0.0

      widget_control,(*self.state).lineplot_xmax_id, $
        set_value=(*self.state).image_size[1]

      (*self.state).lineplot_xmax = (*self.state).image_size[1]

      widget_control,(*self.state).lineplot_ymin_id, $
        set_value=min((*self.images.main_image)[(*self.state).coord[0], *],/nan)

      (*self.state).lineplot_ymin = min((*self.images.main_image)[(*self.state).coord[0], *],/nan)

      widget_control,(*self.state).lineplot_ymax_id, $
        set_value=max((*self.images.main_image)[(*self.state).coord[0], *],/nan)

      (*self.state).lineplot_ymax = max((*self.images.main_image)[(*self.state).coord[0], *],/nan)

    endif

    (*self.state).plot_type = 'colplot'
    self->setwindow, (*self.state).lineplot_window_id
    erase

    ; must store the coordinates in state structure if you want to make a
    ; PS plot because (*self.state).coord array will change if you move cursor
    ; before pressing 'Create PS' button

    if (not (keyword_set(update))) then (*self.state).plot_coord = (*self.state).coord

    plot, (*self.images.main_image)[(*self.state).plot_coord[0], *], $
      xst = 3, yst = 3, psym = 10, $
      title = strcompress('Plot of column ' + $
      string((*self.state).plot_coord[0])), $
      xtitle = 'Row', $
      ytitle = 'Pixel Value', $
      color = 7, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

  endif else begin

    plot, (*self.images.main_image)[(*self.state).plot_coord[0], *], $
      xst = 3, yst = 3, psym = 10, $
      title = strcompress('Plot of column ' + $
      string((*self.state).plot_coord[0])), $
      xtitle = 'Row', $
      ytitle = 'Pixel Value', $
      color = 0, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

  endelse

  if (not (keyword_set(ps))) then begin
    widget_control, (*self.state).lineplot_base_id, /clear_events
    self->resetwindow
  endif

end

;--------------------------------------------------------------------

pro GPItv::gaussrowplot, ps=ps, update=update


  if (not (keyword_set(ps))) then begin

    ; Only initialize plot window and plot ranges to the min/max ranges
    ; when gaussrowplot window is not already present or plot window is present
    ; but last plot was not a gaussrowplot.  Otherwise, use the values
    ; currently in the min/max boxes

    if (not (xregistered(self.xname+'_lineplot', /noshow))) then begin
      self->lineplot_init
    endif

    widget_control, (*self.state).histbutton_base_id, map=0
    widget_control, (*self.state).holdrange_butt_id, sensitive=0

    (*self.state).plot_type = 'gaussrowplot'
    self->setwindow, (*self.state).lineplot_window_id
    erase

    ; must store the coordinates in state structure if you want to make a
    ; PS plot because (*self.state).coord array will change if you move cursor
    ; before pressing 'Create PS' button

    if (not (keyword_set(update))) then (*self.state).plot_coord = (*self.state).coord

    x2=long(((*self.state).plot_coord[0]+10.) < ((*self.state).image_size[0]-1.))
    x1=long(((*self.state).plot_coord[0]-10.) > 0.)
    y2=long(((*self.state).plot_coord[1]+2.) < ((*self.state).image_size[1]-1))
    y1=long(((*self.state).plot_coord[1]-2.) > 0.)
    x=fltarr(x2-x1+1)
    y=fltarr(x2-x1+1)

    n_x = x2-x1+1
    n_y = y2-y1+1

    for i=0, n_x - 1 do begin
      x[i]=x1+i
      y[i]=total((*self.images.main_image)[x[i],y1:y2])/(n_y)
    endfor

    x_interp=interpol(x,1000)
    y_interp=interpol(y,1000)
    yfit=gaussfit(x_interp,y_interp,a,nterms=4)
    peak = a[0]
    center = a[1]
    fwhm = a[2] * 2.354
    bkg = min(yfit)

    if (not (keyword_set(update))) then begin

      widget_control,(*self.state).lineplot_xmin_id, $
        set_value=x[0]

      (*self.state).lineplot_xmin = x[0]

      widget_control,(*self.state).lineplot_xmax_id, $
        set_value=x[n_x-1]

      (*self.state).lineplot_xmax = x[n_x-1]

      widget_control,(*self.state).lineplot_ymin_id, $
        set_value=min(y)

      (*self.state).lineplot_ymin = min(y)

      widget_control,(*self.state).lineplot_ymax_id, $
        set_value=(max(y) > max(yfit))

      (*self.state).lineplot_ymax = max(y) > max(yfit)

    endif

    title_str = 'Rows ' + $
      strcompress(string(y1),/remove_all) + $
      '-' + strcompress(string(y2),/remove_all) + $
      '   Center=' + strcompress(string(center,format='(f10.2)'),/remove_all) + $
      '   Peak=' + strcompress(string(peak,format='(f10.2)'),/remove_all) + $
      '   FWHM=' + strcompress(string(fwhm,format='(f10.2)'),/remove_all) + $
      '   Bkg=' + strcompress(string(bkg,format='(f10.2)'),/remove_all)

    plot,x,y,psym=1,/ynozero, title = title_str, xtitle='Column (pixels)', $
      ytitle='Pixel Value', $
      color = 7, xst = 3, yst = 3, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

    oplot, x_interp, yfit

  endif else begin

    x2=long(((*self.state).plot_coord[0]+10.) < ((*self.state).image_size[0]-1.))
    x1=long(((*self.state).plot_coord[0]-10.) > 0.)
    y2=long(((*self.state).plot_coord[1]+2.) < ((*self.state).image_size[1]-1))
    y1=long(((*self.state).plot_coord[1]-2.) > 0.)
    x=fltarr(x2-x1+1)
    y=fltarr(x2-x1+1)

    n_x = x2-x1+1
    n_y = y2-y1+1

    for i=0, n_x - 1 do begin
      x[i]=x1+i
      y[i]=total((*self.images.main_image)[x[i],y1:y2])/(n_y)
    endfor

    x_interp=interpol(x,1000)
    y_interp=interpol(y,1000)
    yfit=gaussfit(x_interp,y_interp,a,nterms=4)
    peak = a[0]
    center = a[1]
    fwhm = a[2] * 2.354
    bkg = min(yfit)

    title_str = 'Rows ' + $
      strcompress(string(y1),/remove_all) + $
      '-' + strcompress(string(y2),/remove_all) + $
      ' Ctr=' + strcompress(string(center,format='(f10.2)'),/remove_all) + $
      ' Pk=' + strcompress(string(peak,format='(f10.2)'),/remove_all) + $
      ' FWHM=' + strcompress(string(fwhm,format='(f10.2)'),/remove_all) + $
      ' Bkg=' + strcompress(string(bkg,format='(f10.2)'),/remove_all)

    plot,x,y,psym=1,/ynozero, title = title_str, xtitle='Column (pixels)', $
      ytitle='Pixel Value', $
      color = 0, xst = 3, yst = 3, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

    oplot, x_interp, yfit

  endelse

  if (not (keyword_set(ps))) then begin
    widget_control, (*self.state).lineplot_base_id, /clear_events
    self->resetwindow
  endif

end

;--------------------------------------------------------------------

pro GPItv::gausscolplot, ps=ps, update=update


  if (not (keyword_set(ps))) then begin

    ; Only initialize plot window and plot ranges to the min/max ranges
    ; when gausscolplot window is not already present or plot window is present
    ; but last plot was not a gausscolplot.  Otherwise, use the values
    ; currently in the min/max boxes

    if (not (xregistered(self.xname+'_lineplot', /noshow))) then begin
      self->lineplot_init
    endif

    widget_control, (*self.state).histbutton_base_id, map=0
    widget_control, (*self.state).holdrange_butt_id, sensitive=0

    (*self.state).plot_type = 'gausscolplot'
    self->setwindow, (*self.state).lineplot_window_id
    erase

    ; must store the coordinates in state structure if you want to make a
    ; PS plot because (*self.state).coord array will change if you move cursor
    ; before pressing 'Create PS' button

    if (not (keyword_set(update))) then (*self.state).plot_coord = (*self.state).coord

    x2=long(((*self.state).plot_coord[1]+10.) < ((*self.state).image_size[1]-1.))
    x1=long(((*self.state).plot_coord[1]-10.) > 0.)
    y2=long(((*self.state).plot_coord[0]+2.) < ((*self.state).image_size[0]-1))
    y1=long(((*self.state).plot_coord[0]-2.) > 0.)
    x=fltarr(x2-x1+1)
    y=fltarr(x2-x1+1)

    n_x = x2-x1+1
    n_y = y2-y1+1

    for i=0, n_x - 1 do begin
      x[i]=x1+i
      y[i]=total((*self.images.main_image)[y1:y2,x[i]])/(n_y)
    endfor

    x_interp=interpol(x,1000)
    y_interp=interpol(y,1000)
    yfit=gaussfit(x_interp,y_interp,a,nterms=4)
    peak = a[0]
    center = a[1]
    fwhm = a[2] * 2.354
    bkg = min(yfit)

    if (not (keyword_set(update))) then begin

      widget_control,(*self.state).lineplot_xmin_id, $
        set_value=x[0]

      (*self.state).lineplot_xmin = x[0]

      widget_control,(*self.state).lineplot_xmax_id, $
        set_value=x[n_x-1]

      (*self.state).lineplot_xmax = x[n_x-1]

      widget_control,(*self.state).lineplot_ymin_id, $
        set_value=min(y)

      (*self.state).lineplot_ymin = min(y)

      widget_control,(*self.state).lineplot_ymax_id, $
        set_value=(max(y) > max(yfit))

      (*self.state).lineplot_ymax = max(y) > max(yfit)

    endif

    title_str = 'Columns ' + $
      strcompress(string(y1),/remove_all) + $
      '-' + strcompress(string(y2),/remove_all) + $
      '   Center=' + strcompress(string(center,format='(f10.2)'),/remove_all) + $
      '   Peak=' + strcompress(string(peak,format='(f10.2)'),/remove_all) + $
      '   FWHM=' + strcompress(string(fwhm,format='(f10.2)'),/remove_all) + $
      '   Bkg=' + strcompress(string(bkg,format='(f10.2)'),/remove_all)

    plot,x,y,psym=1,/ynozero, title = title_str, xtitle='Row (pixels)', $
      ytitle='Pixel Value', $
      color = 7, xst = 3, yst = 3, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

    oplot, x_interp, yfit

  endif else begin

    x2=long(((*self.state).plot_coord[1]+10.) < ((*self.state).image_size[1]-1.))
    x1=long(((*self.state).plot_coord[1]-10.) > 0.)
    y2=long(((*self.state).plot_coord[0]+2.) < ((*self.state).image_size[0]-1))
    y1=long(((*self.state).plot_coord[0]-2.) > 0.)
    x=fltarr(x2-x1+1)
    y=fltarr(x2-x1+1)

    n_x = x2-x1+1
    n_y = y2-y1+1

    for i=0, n_x - 1 do begin
      x[i]=x1+i
      y[i]=total((*self.images.main_image)[y1:y2,x[i]])/(n_y)
    endfor

    x_interp=interpol(x,1000)
    y_interp=interpol(y,1000)
    yfit=gaussfit(x_interp,y_interp,a,nterms=4)
    peak = a[0]
    center = a[1]
    fwhm = a[2] * 2.354
    bkg = min(yfit)

    title_str = 'Cols ' + $
      strcompress(string(y1),/remove_all) + $
      '-' + strcompress(string(y2),/remove_all) + $
      ' Ctr=' + strcompress(string(center,format='(f10.2)'),/remove_all) + $
      ' Pk=' + strcompress(string(peak,format='(f10.2)'),/remove_all) + $
      ' FWHM=' + strcompress(string(fwhm,format='(f10.2)'),/remove_all) + $
      ' Bkg=' + strcompress(string(bkg,format='(f10.2)'),/remove_all)

    plot,x,y,psym=1,/ynozero, title = title_str, xtitle='Row (pixels)', $
      ytitle='Pixel Value', $
      color = 0, xst = 3, yst = 3, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

    oplot, x_interp, yfit

  endelse

  if (not (keyword_set(ps))) then begin
    widget_control, (*self.state).lineplot_base_id, /clear_events
    self->resetwindow
  endif

end

;--------------------------------------------------------------------

pro GPItv::vectorplot, ps=ps, update=update, newcoord=newcoord


  if (keyword_set(ps)) then begin
    thick = 3
    color = 0
  endif else begin
    thick = 1
    color = 7
  endelse

  ;;do some sanity checking first
  tmp = where([(*self.state).vector_coord1[0],(*self.state).vector_coord2[0]] gt (*self.state).image_size[0],ct1)
  tmp = where([(*self.state).vector_coord1[1],(*self.state).vector_coord2[1]] gt (*self.state).image_size[1],ct2)

  if ct1+ct2 ne 0 then begin
    self->message, 'Selected vector is out of range of current image.', msgtype='warning'
    (*self.state).vector_coord1 =  [0L, 0L]
    (*self.state).vector_coord2 =  [0L, 0L]
    (*self.state).plot_type = '' ;need this to reset units next time
    if (xregistered(self.xname+'_lineplot', /noshow)) then begin
      self->setwindow, (*self.state).lineplot_window_id
      erase
    endif
    return
  endif

  d = sqrt(((*self.state).vector_coord1[0]-(*self.state).vector_coord2[0])^2 + $
    ((*self.state).vector_coord1[1]-(*self.state).vector_coord2[1])^2)

  v_d = fix(d + 1)
  dx = ((*self.state).vector_coord2[0]-(*self.state).vector_coord1[0]) / float(v_d - 1)
  dy = ((*self.state).vector_coord2[1]-(*self.state).vector_coord1[1]) / float(v_d - 1)

  x = fltarr(v_d)
  y = fltarr(v_d)
  vectdist = indgen(v_d)
  pixval = fltarr(v_d)

  x[0] = (*self.state).vector_coord1[0]
  y[0] = (*self.state).vector_coord1[1]

  for i = 1, n_elements(x) - 1 do begin
    x[i] = (*self.state).vector_coord1[0] + dx * i
    y[i] = (*self.state).vector_coord1[1] + dy * i
  endfor

  for j = 0, n_elements(x) - 1 do begin
    col = x[j]
    row = y[j]
    floor_col = floor(col)
    ceil_col = ceil(col)
    floor_row = floor(row)
    ceil_row = ceil(row)

    pixval[j] = (total([(*self.images.main_image)[floor_col,floor_row], $
      (*self.images.main_image)[floor_col,ceil_row], $
      (*self.images.main_image)[ceil_col,floor_row], $
      (*self.images.main_image)[ceil_col,ceil_row]])) / 4.

  endfor


  if (not (keyword_set(ps))) then begin
    newplot = 0
    if (not (xregistered(self.xname+'_lineplot', /noshow))) then begin
      self->lineplot_init
      ;;(*self.state).holdrange_value = 0.
      ;;widget_control, (*self.state).holdrange_butt_id, set_button=(*self.state).holdrange_value
      newplot = 1
    endif

    widget_control, (*self.state).histbutton_base_id, map=0
    widget_control, (*self.state).holdrange_butt_id, sensitive=1

    widget_control, (*self.state).lineplot_xmin_id, get_value=xmin
    widget_control, (*self.state).lineplot_xmax_id, get_value=xmax
    widget_control, (*self.state).lineplot_ymin_id, get_value=ymin
    widget_control, (*self.state).lineplot_ymax_id, get_value=ymax
    if (newplot EQ 1 OR (*self.state).plot_type NE 'vectorplot' OR $
      keyword_set(fullrange) OR $
      ((*self.state).holdrange_value EQ 0 AND keyword_set(newcoord))) then begin
      xmin = 0.0
      xmax = max(vectdist)
      ymin = min(pixval,/NAN)
      ymax = max(pixval,/NAN)

    endif

    widget_control, (*self.state).lineplot_xmin_id, set_value=xmin
    widget_control, (*self.state).lineplot_xmax_id, set_value=xmax
    widget_control, (*self.state).lineplot_ymin_id, set_value=ymin
    widget_control, (*self.state).lineplot_ymax_id, set_value=ymax

    (*self.state).lineplot_xmin = xmin
    (*self.state).lineplot_xmax = xmax
    (*self.state).lineplot_ymin = ymin
    (*self.state).lineplot_ymax = ymax

    (*self.state).plot_type = 'vectorplot'
    self->setwindow, (*self.state).lineplot_window_id
    erase



    plot, vectdist, pixval, $
      xst = 3, yst = 3, psym = 10, $
      title = strcompress('Plot of cut through image [' + $
      strcompress(string((*self.state).vector_coord1[0]) + ',' + $
      string((*self.state).vector_coord1[1]),/remove_all) + $
      '] to [' + $
      strcompress(string((*self.state).vector_coord2[0]) + ',' + $
      string((*self.state).vector_coord2[1]),/remove_all) + ']'), $
      xtitle = 'Distance along image cut vector', $
      ytitle = 'Pixel Value', $
      color = 7, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

  endif else begin

    ;; Postscript output
    plot, vectdist, pixval, $
      xst = 3, yst = 3, psym = 10, $
      title = strcompress('Plot of cut through image [' + $
      strcompress(string((*self.state).vector_coord1[0]) + ',' + $
      string((*self.state).vector_coord1[1]),/remove_all) + $
      '] to [' + $
      strcompress(string((*self.state).vector_coord2[0]) + ',' + $
      string((*self.state).vector_coord2[1]),/remove_all) + ']'), $
      xtitle = 'Distance along image cut vector', $
      ytitle = 'Pixel Value', $
      color = 0, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

  endelse

  if (not (keyword_set(ps))) then begin
    widget_control, (*self.state).lineplot_base_id, /clear_events
    self->resetwindow
  endif

end

;--------------------------------------------------------------------

pro GPItv::linesplot_event, event

  ;event handler for linesplot

  widget_control, event.id, get_uvalue = uvalue

  case uvalue of
    'done': begin
      widget_control, event.top, /destroy
      self->refresh
    end

    'imin': begin

      s=(*self.state).linesbox
      widget_control, (*self.state).imin, get_value=imin
      ;calculate angle of rotation
      angle=0
      hypotenuse=double(sqrt( (s[0]-s[2])^2 + (s[1]-s[3])^2))
      ;1st quadrant
      if (s[0] lt s[2] and s[1] lt s[3]) then begin
        opposite=double(abs(s[1]-s[3]))
        angle=asin(opposite/hypotenuse) * 360./(2*!pi) +90.
      endif

      ;2nd quadrant
      if (s[0] lt s[2] and s[1] gt s[3]) then begin
        opposite=double(abs(s[0]-s[2]))
        angle=asin(opposite/hypotenuse) * 360./(2*!pi)
      endif

      ;3rd quadrant
      if (s[0] gt s[2] and s[1] gt s[3]) then begin
        opposite=double(abs(s[0]-s[2]))
        angle=-asin(opposite/hypotenuse) * 360./(2*!pi)
      endif

      ;4th quadrant
      if (s[0] gt s[2] and s[1] lt s[3]) then begin
        opposite=double(abs(s[1]-s[3]))
        angle=-asin(opposite/hypotenuse) * 360./(2*!pi) -90.
      endif

      ;rotate image about point of first click
      ;im=dblarr((*self.state).image_size[0]*1.5, (*self.state).image_size[1]*1.5)

      im=rot(*self.images.main_image, angle, 1.0, s[0], s[1], /interp, /pivot)

      ;check that line rotated isn't bigger than image
      height=hypotenuse
      if (hypotenuse ge s[1]) then height=s[1]

      data=dblarr(height)

      j=0
      for i=s[1]-height+1, s[1] do begin
        data[j]=im[s[0], i]
        j=j+1
      endfor

      data=reverse(data)

      ;updating controls
      widget_control, (*self.state).imin, set_value=imin

      widget_control, (*self.state).imin, get_value=imin
      widget_control, (*self.state).imax, get_value=imax
      ;plotting
      widget_control, (*self.state).lines_plot_screen, get_value=scr
      wset, scr
      plot, data, xtitle='X - axis: Position', ytitle='Y - axis: Intensity', yrange=[imin, imax]
    end


    'imax': begin

      s=(*self.state).linesbox
      widget_control, (*self.state).imax, get_value=imax
      ;calculate angle of rotation
      angle=0
      hypotenuse=double(sqrt( (s[0]-s[2])^2 + (s[1]-s[3])^2))
      ;1st quadrant
      if (s[0] lt s[2] and s[1] lt s[3]) then begin
        opposite=double(abs(s[1]-s[3]))
        angle=asin(opposite/hypotenuse) * 360./(2*!pi) +90.
      endif

      ;2nd quadrant
      if (s[0] lt s[2] and s[1] gt s[3]) then begin
        opposite=double(abs(s[0]-s[2]))
        angle=asin(opposite/hypotenuse) * 360./(2*!pi)
      endif

      ;3rd quadrant
      if (s[0] gt s[2] and s[1] gt s[3]) then begin
        opposite=double(abs(s[0]-s[2]))
        angle=-asin(opposite/hypotenuse) * 360./(2*!pi)
      endif

      ;4th quadrant
      if (s[0] gt s[2] and s[1] lt s[3]) then begin
        opposite=double(abs(s[1]-s[3]))
        angle=-asin(opposite/hypotenuse) * 360./(2*!pi) -90.
      endif

      ;rotate image about point of first click
      ;im=dblarr((*self.state).image_size[0]*1.5, (*self.state).image_size[1]*1.5)

      im=rot(*self.images.main_image, angle, 1.0, s[0], s[1], /interp, /pivot)

      ;check that line rotated isn't bigger than image
      height=hypotenuse
      if (hypotenuse ge s[1]) then height=s[1]

      data=dblarr(height)

      j=0
      for i=s[1]-height+1, s[1] do begin
        data[j]=im[s[0], i]
        j=j+1
      endfor

      data=reverse(data)

      ;updating controls
      widget_control, (*self.state).imax, set_value=imax

      widget_control, (*self.state).imin, get_value=imin
      widget_control, (*self.state).imax, get_value=imax
      ;plotting
      widget_control, (*self.state).lines_plot_screen, get_value=scr
      wset, scr
      plot, data, xtitle='X - axis: Position', ytitle='Y - axis: Intensity', yrange=[imin, imax]
    end

    'lines_gauss': begin

      s=(*self.state).linesbox
      widget_control, (*self.state).imax, get_value=imax
      ;calculate angle of rotation
      angle=0
      hypotenuse=double(sqrt( (s[0]-s[2])^2 + (s[1]-s[3])^2))
      ;1st quadrant
      if (s[0] le s[2] and s[1] le s[3]) then begin
        opposite=double(abs(s[1]-s[3]))
        angle=asin(opposite/hypotenuse) * 360./(2*!pi) +90.
      endif

      ;2nd quadrant
      if (s[0] le s[2] and s[1] ge s[3]) then begin
        opposite=double(abs(s[0]-s[2]))
        angle=asin(opposite/hypotenuse) * 360./(2*!pi)
      endif

      ;3rd quadrant
      if (s[0] ge s[2] and s[1] ge s[3]) then begin
        opposite=double(abs(s[0]-s[2]))
        angle=-asin(opposite/hypotenuse) * 360./(2*!pi)
      endif

      ;4th quadrant
      if (s[0] ge s[2] and s[1] le s[3]) then begin
        opposite=double(abs(s[1]-s[3]))
        angle=-asin(opposite/hypotenuse) * 360./(2*!pi) -90.
      endif

      ;rotate image about point of first click
      ;im=dblarr((*self.state).image_size[0]*1.5, (*self.state).image_size[1]*1.5)

      im=rot(*self.images.main_image, angle, 1.0, s[0], s[1], /interp, /pivot)

      ;check that line rotated isn't bigger than image
      height=hypotenuse

      if (hypotenuse ge s[1]) then height=s[1]

      data=dblarr(height)

      j=0
      for i=s[1]-height+1, s[1] do begin
        data[j]=im[s[0], i]
        j=j+1
      endfor

      data=reverse(data)

      ;get info on where the fit is
      widget_control, (*self.state).gaussmin, get_value=min
      widget_control, (*self.state).gaussmax, get_value=max

      x=data[min:max]

      l=double(fix(min[0]))
      y=dindgen( fix(max)-fix(min)+1)
      y=(y)
      plot, y,x, xtitle='X - axis: Position', ytitle='Y - axis: Intensity', psym=6

      ;not enough data
      if( fix(max)-fix(min)+1 lt 6) then return

      ;res is the fit. To make anything other than a gaussian fit
      ;replace the subroutine GPItv_gaussfit with your own routine
      res=self->gaussfit(x,y)

      ;display
      widget_control, (*self.state).lines_plot_screen, get_value=scr
      wset, scr
      oplot, res, linestyle=2
    end

    else:
  endcase




end

;--------------------------------------------------------------------

pro GPItv::linesplot


  s=(*self.state).linesbox

  ;check if a window is already open; if so, don't open a new one
  if (not (xregistered(self.xname+'_linesplot'))) then begin


    ;main base for linesplot
    if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
    res=widget_info((*self.state).base_id, /geometry)
    lines_base = $
      widget_base(/floating, $
      group_leader = (*self.state).base_id, $
      /row, $
      /base_align_left, $
      title = 'GPItv arbitrary line plot', $
      uvalue = 'stats_base', $
      xoffset=res.xoffset+550)

    ;1st column base, holds the plot area
    plot_base = $
      widget_base(lines_base,$
      /align_center, $
      /column, $
      frame=2)

    ;2nd column base, holds the plot controls
    control_base = $
      widget_base(lines_base, $
      /align_center, $
      /column, $
      frame=2)

    ;main screen for plot in 1st column
    (*self.state).lines_plot_screen = $
      widget_draw(plot_base, $
      xsize=600, $
      ysize=450, $
      frame=2, $
      uvalue='plotscreen')

    (*self.state).imin = $
      cw_field(control_base, $
      value=0, $
      title='Intensity min.. = ', $
      uvalue='imin', $
      xsize=6, $
      /return_events)
    (*self.state).imax = $
      cw_field(control_base, $
      value=0, $
      title='Intensity max. = ', $
      uvalue='imax', $
      xsize=6, $
      /return_events)

    ;oplot buttons
    (*self.state).gaussmin = $
      cw_field(control_base, $
      value=0, $
      title='Low end of fit = ', $
      uvalue='gaussmin', $
      xsize=6, $
      /return_events)


    (*self.state).gaussmax = $
      cw_field(control_base, $
      value=8, $
      title='High end of fit = ', $
      uvalue='gaussmax', $
      xsize=6, $
      /return_events)

    (*self.state).lines_gauss=widget_button(control_base, $
      /align_center, $
      value='Make Gaussian Fit', $
      uvalue='lines_gauss')

    (*self.state).lines_done=widget_button(control_base, $
      /align_center, $
      value='Done', $
      uvalue='done')

    widget_control, lines_base, /realize


    ;sdgsdg

    ;calculate angle of rotation
    angle=0
    hypotenuse=double(sqrt( (s[0]-s[2])^2 + (s[1]-s[3])^2))
    ;1st quadrant
    if (s[0] le s[2] and s[1] le s[3]) then begin
      opposite=double(abs(s[1]-s[3]))
      angle=asin(opposite/hypotenuse) * 360./(2*!pi) +90.
    endif

    ;2nd quadrant
    if (s[0] le s[2] and s[1] ge s[3]) then begin
      opposite=double(abs(s[0]-s[2]))
      angle=asin(opposite/hypotenuse) * 360./(2*!pi)
    endif

    ;3rd quadrant
    if (s[0] ge s[2] and s[1] ge s[3]) then begin
      opposite=double(abs(s[0]-s[2]))
      angle=-asin(opposite/hypotenuse) * 360./(2*!pi)
    endif

    ;4th quadrant
    if (s[0] ge s[2] and s[1] le s[3]) then begin
      opposite=double(abs(s[1]-s[3]))
      angle=-asin(opposite/hypotenuse) * 360./(2*!pi) -90.
    endif

    ;rotate image about point of first click
    ;im=dblarr((*self.state).image_size[0]*1.5, (*self.state).image_size[1]*1.5)

    im=rot(*self.images.main_image, angle, 1.0, s[0], s[1], /interp, /pivot)

    ;check that line rotated isn't bigger than image
    height=hypotenuse
    if (hypotenuse ge s[1]) then height=s[1]

    ;if a bad line, quit
    if (height gt 0) then begin

      data=dblarr(height)

      j=0
      for i=s[1]-height+1, s[1] do begin
        data[j]=im[s[0], i]
        j=j+1
      endfor

      data=reverse(data)
    endif else begin
      data=dindgen(25)
    endelse


    xmanager, self.xname+'_linesplot', lines_base, /no_block
    widget_control, lines_base, set_uvalue = {object:self, method: 'linesplot_event'}
    widget_control, lines_base, event_pro = 'GPItvo_subwindow_event_handler'
    self->resetwindow

    ;updating controls
    widget_control, (*self.state).imin, set_value=min(data)
    widget_control, (*self.state).imax, set_value=max(data)

    ;plotting
    widget_control, (*self.state).lines_plot_screen, get_value=scr
    wset, scr
    plot, data, xtitle='X - axis: Position', ytitle='Y - axis: Intensity'

  endif
end

;--------------------------------------------------------------------

pro GPItv::surfplot, ps=ps, update=update


  if (not (keyword_set(ps))) then begin

    if (not (xregistered(self.xname+'_lineplot'))) then begin
      self->lineplot_init
    endif

    widget_control, (*self.state).histbutton_base_id, map=0
    widget_control, (*self.state).holdrange_butt_id, sensitive=0

    if (not (keyword_set(update))) then begin

      plotsize = $
        fix(min([50, (*self.state).image_size[0]/2., (*self.state).image_size[1]/2.]))
      center = plotsize > (*self.state).coord < ((*self.state).image_size[0:1] - plotsize)

      shade_image = (*self.images.main_image)[center[0]-plotsize:center[0]+plotsize-1, $
        center[1]-plotsize:center[1]+plotsize-1]

      (*self.state).lineplot_xmin = center[0]-plotsize
      (*self.state).lineplot_xmax = center[0]+plotsize-1
      (*self.state).lineplot_ymin = center[1]-plotsize
      (*self.state).lineplot_ymax = center[1]+plotsize-1

      ; must store the coordinates in state structure if you want to make a
      ; PS plot because (*self.state).coord array will change if you move cursor
      ; before pressing 'Create PS' button

      (*self.state).plot_coord = (*self.state).coord

      widget_control, (*self.state).lineplot_xmin_id, $
        set_value = (*self.state).lineplot_xmin

      widget_control, (*self.state).lineplot_xmax_id, $
        set_value = (*self.state).lineplot_xmax

      widget_control, (*self.state).lineplot_ymin_id, $
        set_value = (*self.state).lineplot_ymin

      widget_control, (*self.state).lineplot_ymax_id, $
        set_value = (*self.state).lineplot_ymax

    endif

    (*self.state).plot_type = 'surfplot'
    self->setwindow, (*self.state).lineplot_window_id
    erase

    (*self.state).lineplot_xmin = fix(round(0 > (*self.state).lineplot_xmin))
    (*self.state).lineplot_xmax = $
      fix(round((*self.state).lineplot_xmax < ((*self.state).image_size[0] - 1)))
    (*self.state).lineplot_ymin = fix(round(0 > (*self.state).lineplot_ymin))
    (*self.state).lineplot_ymax = $
      fix(round((*self.state).lineplot_ymax < ((*self.state).image_size[1] - 1)))

    if ((*self.state).lineplot_xmin ge (*self.state).lineplot_xmax OR $
      (*self.state).lineplot_ymin ge (*self.state).lineplot_ymax) then begin
      self->message, 'XMin and YMin must be less than Xmax and YMax', $
        msgtype='error', /window
      return
    endif

    widget_control,(*self.state).lineplot_xmin_id, $
      set_value=(*self.state).lineplot_xmin

    widget_control,(*self.state).lineplot_xmax_id, $
      set_value=(*self.state).lineplot_xmax

    widget_control,(*self.state).lineplot_ymin_id, $
      set_value=(*self.state).lineplot_ymin

    widget_control,(*self.state).lineplot_ymax_id, $
      set_value=(*self.state).lineplot_ymax

    shade_image =  (*self.images.main_image)[(*self.state).lineplot_xmin:(*self.state).lineplot_xmax, $
      (*self.state).lineplot_ymin:(*self.state).lineplot_ymax]

    tmp_string = $
      strcompress('Surface plot of ' + $
      strcompress('['+string(round((*self.state).lineplot_xmin))+ $
      ':'+string(round((*self.state).lineplot_xmax))+ $
      ','+string(round((*self.state).lineplot_ymin))+ $
      ':'+string(round((*self.state).lineplot_ymax))+ $
      ']', /remove_all))

    xdim = (*self.state).lineplot_xmax - (*self.state).lineplot_xmin + 1
    ydim = (*self.state).lineplot_ymax - (*self.state).lineplot_ymin + 1
    xran = lonarr(xdim)
    yran = lonarr(ydim)
    xran[0] = (*self.state).lineplot_xmin
    yran[0] = (*self.state).lineplot_ymin

    for i = 1L, xdim - 1, 1 do xran[i] = (*self.state).lineplot_xmin + i
    for j = 1L, ydim - 1, 1 do yran[j] = (*self.state).lineplot_ymin + j

    shade_surf, shade_image, $
      xran, yran, $
      title = temporary(tmp_string), $
      xtitle = 'X', ytitle = 'Y', ztitle = 'Pixel Value', $
      color = 7, charsize=2.0;, ax=60, az=60

  endif else begin

    shade_image =  (*self.images.main_image)[(*self.state).lineplot_xmin:(*self.state).lineplot_xmax, $
      (*self.state).lineplot_ymin:(*self.state).lineplot_ymax]

    tmp_string = $
      strcompress('Surface plot of ' + $
      strcompress('['+string(round((*self.state).lineplot_xmin))+ $
      ':'+string(round((*self.state).lineplot_xmax))+ $
      ','+string(round((*self.state).lineplot_ymin))+ $
      ':'+string(round((*self.state).lineplot_ymax))+ $
      ']', /remove_all))

    xdim = (*self.state).lineplot_xmax - (*self.state).lineplot_xmin + 1
    ydim = (*self.state).lineplot_ymax - (*self.state).lineplot_ymin + 1
    xran = lonarr(xdim)
    yran = lonarr(ydim)
    xran[0] = (*self.state).lineplot_xmin
    yran[0] = (*self.state).lineplot_ymin

    for i = 1L, xdim - 1, 1 do xran[i] = (*self.state).lineplot_xmin + i
    for j = 1L, ydim - 1, 1 do yran[j] = (*self.state).lineplot_ymin + j

    shade_surf, shade_image, $
      xran, yran, $
      title = temporary(tmp_string), $
      xtitle = 'X', ytitle = 'Y', ztitle = 'Pixel Value', $
      color = 0, charsize=2.0

  endelse

  if (not (keyword_set(ps))) then begin
    widget_control, (*self.state).lineplot_base_id, /clear_events
    self->resetwindow
  endif

end

;--------------------------------------------------------------------

pro GPItv::contourplot, ps=ps, update=update


  if (not (keyword_set(ps))) then begin

    if (not (xregistered(self.xname+'_lineplot'))) then begin
      ;; Only initialize plot window and plot ranges to the min/max ranges
      ;; when rowplot window is not already present.  Otherwise, use
      ;; the values currently set in the min/max range boxes
      self->lineplot_init
    endif

    widget_control, (*self.state).histbutton_base_id, map=0
    widget_control, (*self.state).holdrange_butt_id, sensitive=0

    if (not (keyword_set(update))) then begin

      plotsize = $
        fix(min([50, (*self.state).image_size[0]/2., (*self.state).image_size[1]/2.]))
      center = plotsize > (*self.state).coord < ((*self.state).image_size[0:1] - plotsize)

      contour_image =  (*self.images.main_image)[center[0]-plotsize:center[0]+plotsize-1, $
        center[1]-plotsize:center[1]+plotsize-1]

      (*self.state).lineplot_xmin = (center[0]-plotsize)
      (*self.state).lineplot_xmax = (center[0]+plotsize-1)
      (*self.state).lineplot_ymin = (center[1]-plotsize)
      (*self.state).lineplot_ymax = (center[1]+plotsize-1)

      ;; must store the coordinates in state structure if you want to make a
      ;; PS plot because (*self.state).coord array will change if you move cursor
      ;; before pressing 'Create PS' button

      (*self.state).plot_coord = (*self.state).coord

      widget_control,(*self.state).lineplot_xmin_id, $
        set_value=(*self.state).lineplot_xmin

      widget_control,(*self.state).lineplot_xmax_id, $
        set_value=(*self.state).lineplot_xmax

      widget_control,(*self.state).lineplot_ymin_id, $
        set_value=(*self.state).lineplot_ymin

      widget_control,(*self.state).lineplot_ymax_id, $
        set_value=(*self.state).lineplot_ymax

    endif

    (*self.state).plot_type = 'contourplot'
    self->setwindow, (*self.state).lineplot_window_id
    erase

    (*self.state).lineplot_xmin = fix(round(0 > (*self.state).lineplot_xmin))
    (*self.state).lineplot_xmax = $
      fix(round((*self.state).lineplot_xmax < ((*self.state).image_size[0] - 1)))
    (*self.state).lineplot_ymin = fix(round(0 > (*self.state).lineplot_ymin))
    (*self.state).lineplot_ymax = $
      fix(round((*self.state).lineplot_ymax < ((*self.state).image_size[1] - 1)))

    if ((*self.state).lineplot_xmin ge (*self.state).lineplot_xmax OR $
      (*self.state).lineplot_ymin ge (*self.state).lineplot_ymax) then begin
      self->message, 'XMin and YMin must be less than Xmax and YMax', $
        msgtype='error', /window
      return
    endif

    widget_control,(*self.state).lineplot_xmin_id, $
      set_value=(*self.state).lineplot_xmin

    widget_control,(*self.state).lineplot_xmax_id, $
      set_value=(*self.state).lineplot_xmax

    widget_control,(*self.state).lineplot_ymin_id, $
      set_value=(*self.state).lineplot_ymin

    widget_control,(*self.state).lineplot_ymax_id, $
      set_value=(*self.state).lineplot_ymax

    contour_image =  (*self.images.main_image)[(*self.state).lineplot_xmin:(*self.state).lineplot_xmax, $
      (*self.state).lineplot_ymin:(*self.state).lineplot_ymax]

    if strcmp((*self.state).scaling,'log',/fold_case) then begin
      contour_image = alog10(contour_image)
      logflag = 'Log'
    endif else begin
      logflag = ''
    endelse

    tmp_string =  $
      strcompress(logflag + $
      ' Contour plot of ' + $
      strcompress('['+string(round((*self.state).lineplot_xmin))+ $
      ':'+string(round((*self.state).lineplot_xmax))+ $
      ','+string(round((*self.state).lineplot_ymin))+ $
      ':'+string(round((*self.state).lineplot_ymax))+ $
      ']', /remove_all))


    xdim = (*self.state).lineplot_xmax - (*self.state).lineplot_xmin + 1
    ydim = (*self.state).lineplot_ymax - (*self.state).lineplot_ymin + 1
    xran = lonarr(xdim)
    yran = lonarr(ydim)
    xran[0] = (*self.state).lineplot_xmin
    yran[0] = (*self.state).lineplot_ymin

    for i = 1L, xdim - 1, 1 do xran[i] = (*self.state).lineplot_xmin + i
    for j = 1L, ydim - 1, 1 do yran[j] = (*self.state).lineplot_ymin + j

    contour, temporary(contour_image), $
      xran, yran, $
      nlevels = 10, $
      /follow, $
      title = temporary(tmp_string), $
      xtitle = 'X', ytitle = 'Y', color = 7

  endif else begin

    contour_image =  (*self.images.main_image)[(*self.state).lineplot_xmin:(*self.state).lineplot_xmax, $
      (*self.state).lineplot_ymin:(*self.state).lineplot_ymax]

    if strcmp((*self.state).scaling,'log',/fold_case) then begin
      contour_image = alog10(contour_image)
      logflag = 'Log'
    endif else begin
      logflag = ''
    endelse

    tmp_string =  $
      strcompress(logflag + $
      ' Contour plot of ' + $
      strcompress('['+string(round((*self.state).lineplot_xmin))+ $
      ':'+string(round((*self.state).lineplot_xmax))+ $
      ','+string(round((*self.state).lineplot_ymin))+ $
      ':'+string(round((*self.state).lineplot_ymax))+ $
      ']', /remove_all))

    xdim = (*self.state).lineplot_xmax - (*self.state).lineplot_xmin + 1
    ydim = (*self.state).lineplot_ymax - (*self.state).lineplot_ymin + 1
    xran = lonarr(xdim)
    yran = lonarr(ydim)
    xran[0] = (*self.state).lineplot_xmin
    yran[0] = (*self.state).lineplot_ymin

    for i = 1L, xdim - 1, 1 do xran[i] = (*self.state).lineplot_xmin + i
    for j = 1L, ydim - 1, 1 do yran[j] = (*self.state).lineplot_ymin + j

    contour, temporary(contour_image), $
      xran, yran, $
      nlevels = 10, $
      /follow, $
      title = temporary(tmp_string), $
      xtitle = 'X', ytitle = 'Y', color = 0

  endelse

  if (not (keyword_set(ps))) then begin
    widget_control, (*self.state).lineplot_base_id, /clear_events
    self->resetwindow
  endif

end

;----------------------------------------------------------------------

pro GPItv::histplot, ps=ps, update=update


  if (not (keyword_set(ps))) then begin

    if (not (xregistered(self.xname+'_lineplot'))) then begin
      self->lineplot_init
    endif

    widget_control, (*self.state).histbutton_base_id, map=1
    widget_control, (*self.state).holdrange_butt_id, sensitive=0

    if (not (keyword_set(update))) then begin

      (*self.state).plot_coord = (*self.state).coord

      plotsize_x = $
        fix(min([20, (*self.state).image_size[0]/2.]))

      plotsize_y = $
        fix(min([20, (*self.state).image_size[1]/2.]))

      ; Establish pixel boundaries to histogram
      x1 = ((*self.state).plot_coord[0]-plotsize_x) > 0.
      x2 = ((*self.state).plot_coord[0]+plotsize_x) < ((*self.state).image_size[0]-1)
      y1 = ((*self.state).plot_coord[1]-plotsize_y) > 0.
      y2 = ((*self.state).plot_coord[1]+plotsize_y) < ((*self.state).image_size[1]-1)

      ; Set up histogram pixel array.  User may do rectangular regions.

      hist_image = (*self.images.main_image)[x1:x2, y1:y2]

      (*self.state).lineplot_xmin = min(hist_image)
      (*self.state).lineplot_xmin_orig = (*self.state).lineplot_xmin
      (*self.state).lineplot_xmax = max(hist_image)
      (*self.state).lineplot_xmax_orig = (*self.state).lineplot_xmax
      (*self.state).lineplot_ymin = 0.

      ; must store the coordinates in state structure if you want to make a
      ; PS plot because (*self.state).coord array will change if you move cursor
      ; before pressing 'Create PS' button

      widget_control, (*self.state).lineplot_xmin_id, $
        set_value = (*self.state).lineplot_xmin

      widget_control, (*self.state).lineplot_xmax_id, $
        set_value = (*self.state).lineplot_xmax

      widget_control, (*self.state).lineplot_ymin_id, $
        set_value = (*self.state).lineplot_ymin

      (*self.state).binsize = ((*self.state).lineplot_xmax - (*self.state).lineplot_xmin) * 0.01
      (*self.state).binsize = $
        (*self.state).binsize > (((*self.state).lineplot_xmax - (*self.state).lineplot_xmin) * 1.0e-5)
      (*self.state).binsize = fix((*self.state).binsize)

      widget_control, (*self.state).x1_pix_id, set_value=x1
      widget_control, (*self.state).x2_pix_id, set_value=x2
      widget_control, (*self.state).y1_pix_id, set_value=y1
      widget_control, (*self.state).y2_pix_id, set_value=y2
      widget_control, (*self.state).histplot_binsize_id, set_value=(*self.state).binsize

    endif else begin

      widget_control, (*self.state).x1_pix_id, get_value=x1
      widget_control, (*self.state).x2_pix_id, get_value=x2
      widget_control, (*self.state).y1_pix_id, get_value=y1
      widget_control, (*self.state).y2_pix_id, get_value=y2

      x1 = (fix(x1)) > 0.
      x2 = (fix(x2)) < ((*self.state).image_size[0]-1)
      y1 = (fix(y1)) > 0.
      y2 = (fix(y2)) < ((*self.state).image_size[1]-1)

      hist_image = (*self.images.main_image)[x1:x2, y1:y2]

    endelse

    (*self.state).plot_type = 'histplot'
    self->setwindow, (*self.state).lineplot_window_id
    erase

    ; Only initialize plot window and plot ranges to the min/max ranges
    ; when histplot window is not already present or plot window is present
    ; but last plot was not a histplot.  Otherwise, use the values
    ; currently in the min/max boxes

    widget_control, (*self.state).histplot_binsize_id, get_value=binsize
    widget_control, (*self.state).lineplot_xmin_id, get_value=xmin
    widget_control, (*self.state).lineplot_xmax_id, get_value=xmax
    widget_control, (*self.state).lineplot_ymin_id, get_value=ymin
    widget_control, (*self.state).lineplot_ymax_id, get_value=ymax

    (*self.state).binsize = binsize
    (*self.state).lineplot_xmin = xmin
    (*self.state).lineplot_xmax = xmax
    (*self.state).lineplot_ymin = ymin
    (*self.state).lineplot_ymax = ymax

    tmp_string = $
      strcompress('Histogram plot of ' + $
      strcompress('['+string(round(x1))+ $
      ':'+string(round(x2))+ $
      ','+string(round(y1))+ $
      ':'+string(round(y2))+ $
      ']', /remove_all))

    ;Call plothist to create histogram arrays
    plothist, hist_image, xhist, yhist, bin=(*self.state).binsize, /NaN, /nodata

    ;Create ymax for plot with slight buffer (if initial plot, else take
    ;ymax in range box)
    if (not (keyword_set(update))) then begin
      (*self.state).lineplot_ymax = fix(max(yhist) + 0.05 * max(yhist))
      widget_control, (*self.state).lineplot_ymax_id, set_value=(*self.state).lineplot_ymax
    endif

    ;Plot histogram with proper ranges
    plothist, hist_image, xhist, yhist, bin=(*self.state).binsize, /NaN, $
      xtitle='Pixel Value', ytitle='Number', title=tmp_string, $
      xran=[(*self.state).lineplot_xmin,(*self.state).lineplot_xmax], $
      yran=[(*self.state).lineplot_ymin,(*self.state).lineplot_ymax], $
      xstyle=1, ystyle=1

  endif else begin

    widget_control, (*self.state).x1_pix_id, get_value=x1
    widget_control, (*self.state).x2_pix_id, get_value=x2
    widget_control, (*self.state).y1_pix_id, get_value=y1
    widget_control, (*self.state).y2_pix_id, get_value=y2

    x1 = (fix(x1)) > 0.
    x2 = (fix(x2)) < ((*self.state).image_size[0]-1)
    y1 = (fix(y1)) > 0.
    y2 = (fix(y2)) < ((*self.state).image_size[1]-1)

    widget_control, (*self.state).x1_pix_id, set_value=x1
    widget_control, (*self.state).x2_pix_id, set_value=x2
    widget_control, (*self.state).y1_pix_id, set_value=y1
    widget_control, (*self.state).y2_pix_id, set_value=y2

    hist_image = (*self.images.main_image)[x1:x2, y1:y2]

    tmp_string = $
      strcompress('Histogram plot of ' + $
      strcompress('['+string(round(x1))+ $
      ':'+string(round(x2))+ $
      ','+string(round(y1))+ $
      ':'+string(round(y2))+ $
      ']', /remove_all))

    ;Plot histogram with proper ranges
    plothist, hist_image, xhist, yhist, bin=(*self.state).binsize, /NaN, $
      xtitle='Pixel Value', ytitle='Number', title=tmp_string, $
      xran=[(*self.state).lineplot_xmin,(*self.state).lineplot_xmax], $
      yran=[(*self.state).lineplot_ymin,(*self.state).lineplot_ymax], $
      xstyle=1, ystyle=1

  endelse

  if (not (keyword_set(ps))) then begin
    widget_control, (*self.state).lineplot_base_id, /clear_events
    self->resetwindow
  endif

END

;----------------------------------------------------------------------

pro GPItv::slice3dplot, ps=ps, update=update


  if (not (keyword_set(ps))) then begin

    ; Only initialize plot window and plot ranges to the min/max ranges
    ; when slice3dplot window is not already present, plot window is present
    ; but last plot was not a slice3dplot, or last plot was a slice3dplot
    ; but the 'Hold Range' button is not selected.  Otherwise, use the values
    ; currently in the min/max boxes

    if (not (xregistered(self.xname+'_lineplot'))) then begin
      self->lineplot_init

      widget_control,(*self.state).lineplot_xmin_id, $
        set_value=0

      (*self.state).lineplot_xmin = 0.0

      widget_control,(*self.state).lineplot_xmax_id, $
        set_value=(*self.state).image_size[2]

      (*self.state).lineplot_xmax = (*self.state).image_size[2]

      widget_control,(*self.state).lineplot_ymin_id, $
        set_value=min((*self.images.main_image_stack)[(*self.state).coord[0], (*self.state).coord[1], *])

      (*self.state).lineplot_ymin = $
        min((*self.images.main_image_stack)[(*self.state).coord[0], (*self.state).coord[1], *])

      widget_control,(*self.state).lineplot_ymax_id, $
        set_value=max((*self.images.main_image_stack)[(*self.state).coord[0], (*self.state).coord[1], *])

      (*self.state).lineplot_ymax = $
        max((*self.images.main_image_stack)[(*self.state).coord[0], (*self.state).coord[1], *])

    endif

    widget_control, (*self.state).histbutton_base_id, map=0

    if ((*self.state).plot_type ne 'slice3dplot' OR $
      (*self.state).holdrange_value eq 0) then begin

      widget_control,(*self.state).lineplot_xmin_id, $
        set_value=0

      (*self.state).lineplot_xmin = 0.0

      widget_control,(*self.state).lineplot_xmax_id, $
        set_value=(*self.state).image_size[2]

      (*self.state).lineplot_xmax = (*self.state).image_size[2]

      widget_control,(*self.state).lineplot_ymin_id, $
        set_value=min((*self.images.main_image_stack)[(*self.state).coord[0], (*self.state).coord[1], *])

      (*self.state).lineplot_ymin = $
        min((*self.images.main_image_stack)[(*self.state).coord[0], (*self.state).coord[1], *])

      widget_control,(*self.state).lineplot_ymax_id, $
        set_value=max((*self.images.main_image_stack)[(*self.state).coord[0], (*self.state).coord[1], *])

      (*self.state).lineplot_ymax = $
        max((*self.images.main_image_stack)[(*self.state).coord[0], (*self.state).coord[1], *])

    endif

    (*self.state).plot_type = 'slice3dplot'
    self->setwindow, (*self.state).lineplot_window_id
    erase

    ; must store the coordinates in state structure if you want to make a
    ; PS plot because (*self.state).coord array will change if you move cursor
    ; before pressing 'Create PS' button

    if (not (keyword_set(update))) then (*self.state).plot_coord = (*self.state).coord

    plot, (*self.images.main_image_stack)[(*self.state).plot_coord[0], (*self.state).plot_coord[1], *], $
      xst = 3, yst = 3, psym = 2, $
      title = 'Plot of pixel [' + $
      strcompress(string((*self.state).plot_coord[0]), /remove_all) + ',' + $
      strcompress(string((*self.state).plot_coord[1]), /remove_all) + ']', $
      xtitle = 'Image Slice', $
      ytitle = 'Pixel Value', $
      color = 7, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

  endif else begin

    plot, (*self.images.main_image_stack)[(*self.state).plot_coord[0], (*self.state).plot_coord[1], *], $
      xst = 3, yst = 3, psym = 2, $
      title = 'Plot of pixel [' + $
      strcompress(string((*self.state).plot_coord[0]), /remove_all) + ',' + $
      strcompress(string((*self.state).plot_coord[1]), /remove_all) + ']', $
      xtitle = 'Image Slice', $
      ytitle = 'Pixel Value', $
      color = 0, xmargin=[15,3], $
      xran = [(*self.state).lineplot_xmin, (*self.state).lineplot_xmax], $
      yran = [(*self.state).lineplot_ymin, (*self.state).lineplot_ymax]

  endelse

  if (not (keyword_set(ps))) then begin
    widget_control, (*self.state).lineplot_base_id, /clear_events
    self->resetwindow
  endif

end

;--------------------------------------------------------------------

pro GPItv::lineplot_update,update=update

  ;;upate whatever lineplot may be up

  case ((*self.state).plot_type) of
    'centerplot': begin
      self->centerplot,update=update
    end

    'rowplot': begin
      self->rowplot,update=update
    end

    'colplot': begin
      self->colplot,update=update
    end

    'gaussrowplot': begin
      self->gaussrowplot,update=update
    end

    'gausscolplot': begin
      self->gausscolplot,update=update
    end

    'vectorplot': begin
      self->vectorplot,update=update
    end

    'histplot': begin
      self->histplot,update=update
    end

    'surfplot': begin
      self->surfplot,update=update
    end

    'contourplot': begin
      self->contourplot,update=update
    end

    'slice3dplot': begin
      self->slice3dplot,update=update
    end

    else:
  endcase

end

;--------------------------------------------------------------------

pro GPItv::lineplot_event, event


  widget_control, event.id, get_uvalue = uvalue


  case uvalue of
    'lineplot_done': widget_control, event.top, /destroy
    'lineplot_base': begin                       ; Resize event
      self->setwindow, (*self.state).lineplot_window_id
      (*self.state).lineplot_size = [event.x, event.y]- (*self.state).lineplot_pad
      widget_control, (*self.state).lineplot_widget_id, $
        xsize = ((*self.state).lineplot_size[0] > (*self.state).lineplot_min_size[0]), $
        ysize = ((*self.state).lineplot_size[1] > (*self.state).lineplot_min_size[1])
      self->resetwindow
    end
    'lineplot_holdrange': begin
      ;        widget_control, (*self.state).holdrange_butt_id
      if ((*self.state).holdrange_value eq 1) then (*self.state).holdrange_value = 0 $
      else (*self.state).holdrange_value = 1
    end
    'lineplot_fullrange': begin
      case (*self.state).plot_type of
        'rowplot': begin

          widget_control,(*self.state).lineplot_xmin_id, $
            set_value=0

          (*self.state).lineplot_xmin = 0.0

          widget_control,(*self.state).lineplot_xmax_id, $
            set_value=(*self.state).image_size[0]

          (*self.state).lineplot_xmax = (*self.state).image_size[0]

          widget_control,(*self.state).lineplot_ymin_id, $
            set_value=min((*self.images.main_image)[*,(*self.state).plot_coord[1]])

          (*self.state).lineplot_ymin = min((*self.images.main_image)[*,(*self.state).plot_coord[1]])

          widget_control,(*self.state).lineplot_ymax_id, $
            set_value=max((*self.images.main_image)[*,(*self.state).plot_coord[1]])

          (*self.state).lineplot_ymax = max((*self.images.main_image)[*,(*self.state).plot_coord[1]])

          self->rowplot, /update
        end
        'colplot': begin

          widget_control,(*self.state).lineplot_xmin_id, $
            set_value=0

          (*self.state).lineplot_xmin = 0.0

          widget_control,(*self.state).lineplot_xmax_id, $
            set_value=(*self.state).image_size[1]

          (*self.state).lineplot_xmax = (*self.state).image_size[1]

          widget_control,(*self.state).lineplot_ymin_id, $
            set_value=min((*self.images.main_image)[(*self.state).plot_coord[0], *])

          (*self.state).lineplot_ymin = min((*self.images.main_image)[(*self.state).plot_coord[0], *])

          widget_control,(*self.state).lineplot_ymax_id, $
            set_value=max((*self.images.main_image)[(*self.state).plot_coord[0], *])

          (*self.state).lineplot_ymax = max((*self.images.main_image)[(*self.state).plot_coord[0], *])

          self->colplot, /update
        end
        'gaussrowplot': begin

          x2=long(((*self.state).plot_coord[0]+10.) < ((*self.state).image_size[0]-1.))
          x1=long(((*self.state).plot_coord[0]-10.) > 0.)
          y2=long(((*self.state).plot_coord[1]+2.) < ((*self.state).image_size[1]-1))
          y1=long(((*self.state).plot_coord[1]-2.) > 0.)
          x=fltarr(x2-x1+1)
          y=fltarr(x2-x1+1)

          n_x = x2-x1+1
          n_y = y2-y1+1

          for i=0, n_x - 1 do begin
            x[i]=x1+i
            y[i]=total((*self.images.main_image)[x[i],y1:y2])/(n_y)
          endfor

          x_interp=interpol(x,1000)
          y_interp=interpol(y,1000)
          yfit=gaussfit(x_interp,y_interp,a,nterms=4)

          widget_control,(*self.state).lineplot_xmin_id, $
            set_value=x[0]

          (*self.state).lineplot_xmin = x[0]

          widget_control,(*self.state).lineplot_xmax_id, $
            set_value=x[n_x-1]

          (*self.state).lineplot_xmax = x[n_x-1]

          widget_control,(*self.state).lineplot_ymin_id, $
            set_value=min(y)

          (*self.state).lineplot_ymin = min(y)

          widget_control,(*self.state).lineplot_ymax_id, $
            set_value=(max(y) > max(yfit))

          (*self.state).lineplot_ymax = max(y) > max(yfit)

          self->gaussrowplot, /update
        end
        'gausscolplot': begin

          x2=long(((*self.state).plot_coord[1]+10.) < ((*self.state).image_size[1]-1.))
          x1=long(((*self.state).plot_coord[1]-10.) > 0.)
          y2=long(((*self.state).plot_coord[0]+2.) < ((*self.state).image_size[0]-1))
          y1=long(((*self.state).plot_coord[0]-2.) > 0.)
          x=fltarr(x2-x1+1)
          y=fltarr(x2-x1+1)

          n_x = x2-x1+1
          n_y = y2-y1+1

          for i=0, n_x - 1 do begin
            x[i]=x1+i
            y[i]=total((*self.images.main_image)[y1:y2,x[i]])/(n_y)
          endfor

          x_interp=interpol(x,1000)
          y_interp=interpol(y,1000)
          yfit=gaussfit(x_interp,y_interp,a,nterms=4)

          widget_control,(*self.state).lineplot_xmin_id, $
            set_value=x[0]

          (*self.state).lineplot_xmin = x[0]

          widget_control,(*self.state).lineplot_xmax_id, $
            set_value=x[n_x-1]

          (*self.state).lineplot_xmax = x[n_x-1]

          widget_control,(*self.state).lineplot_ymin_id, $
            set_value=min(y)

          (*self.state).lineplot_ymin = min(y)

          widget_control,(*self.state).lineplot_ymax_id, $
            set_value=(max(y) > max(yfit))

          (*self.state).lineplot_ymax = max(y) > max(yfit)

          self->gausscolplot, /update
        end
        'vectorplot': begin

          d = sqrt(((*self.state).vector_coord1[0]-(*self.state).vector_coord2[0])^2 + $
            ((*self.state).vector_coord1[1]-(*self.state).vector_coord2[1])^2)

          v_d = fix(d + 1)
          dx = ((*self.state).vector_coord2[0]-(*self.state).vector_coord1[0]) / float(v_d - 1)
          dy = ((*self.state).vector_coord2[1]-(*self.state).vector_coord1[1]) / float(v_d - 1)

          x = fltarr(v_d)
          y = fltarr(v_d)
          vectdist = indgen(v_d)
          pixval = fltarr(v_d)

          x[0] = (*self.state).vector_coord1[0]
          y[0] = (*self.state).vector_coord1[1]

          for i = 1, n_elements(x) - 1 do begin
            x[i] = (*self.state).vector_coord1[0] + dx * i
            y[i] = (*self.state).vector_coord1[1] + dy * i
          endfor

          for j = 0, n_elements(x) - 1 do begin
            col = x[j]
            row = y[j]
            floor_col = floor(col)
            ceil_col = ceil(col)
            floor_row = floor(row)
            ceil_row = ceil(row)

            pixval[j] = (total([(*self.images.main_image)[floor_col,floor_row], $
              (*self.images.main_image)[floor_col,ceil_row], $
              (*self.images.main_image)[ceil_col,floor_row], $
              (*self.images.main_image)[ceil_col,ceil_row]])) / 4.

          endfor

          widget_control,(*self.state).lineplot_xmin_id, set_value=0
          (*self.state).lineplot_xmin = 0.0

          widget_control,(*self.state).lineplot_xmax_id, set_value=max(vectdist)
          (*self.state).lineplot_xmax = max(vectdist)

          widget_control,(*self.state).lineplot_ymin_id, set_value=min(pixval)
          (*self.state).lineplot_ymin = min(pixval)

          widget_control,(*self.state).lineplot_ymax_id, set_value=max(pixval)
          (*self.state).lineplot_ymax = max(pixval)

          self->vectorplot, /update

        end
        'histplot': begin

          plotsize_x = $
            fix(min([20, (*self.state).image_size[0]/2.]))

          plotsize_y = $
            fix(min([20, (*self.state).image_size[1]/2.]))

          ; Establish pixel boundaries to histogram
          x1 = ((*self.state).plot_coord[0]-plotsize_x) > 0.
          x2 = ((*self.state).plot_coord[0]+plotsize_x) < ((*self.state).image_size[0]-1)
          y1 = ((*self.state).plot_coord[1]-plotsize_y) > 0.
          y2 = ((*self.state).plot_coord[1]+plotsize_y) < ((*self.state).image_size[1]-1)

          ; Set up histogram pixel array.  User may do rectangular regions.
          hist_image = (*self.images.main_image)[x1:x2, y1:y2]

          (*self.state).lineplot_xmin = min(hist_image)
          (*self.state).lineplot_xmin_orig = (*self.state).lineplot_xmin
          (*self.state).lineplot_xmax = max(hist_image)
          (*self.state).lineplot_xmax_orig = (*self.state).lineplot_xmax
          (*self.state).lineplot_ymin = 0

          widget_control, (*self.state).lineplot_xmin_id, $
            set_value = (*self.state).lineplot_xmin

          widget_control, (*self.state).lineplot_xmax_id, $
            set_value = (*self.state).lineplot_xmax

          widget_control, (*self.state).lineplot_ymin_id, $
            set_value = (*self.state).lineplot_ymin

          (*self.state).binsize = ((*self.state).lineplot_xmax - (*self.state).lineplot_xmin) * 0.01
          (*self.state).binsize = (*self.state).binsize > $
            (((*self.state).lineplot_xmax - (*self.state).lineplot_xmin) * 1.0e-5)
          ;(*self.state).binsize = fix((*self.state).binsize)

          widget_control, (*self.state).x1_pix_id, set_value=x1
          widget_control, (*self.state).x2_pix_id, set_value=x2
          widget_control, (*self.state).y1_pix_id, set_value=y1
          widget_control, (*self.state).y2_pix_id, set_value=y2
          widget_control, (*self.state).histplot_binsize_id, set_value=(*self.state).binsize

          ;Set lineplot window and erase
          self->setwindow, (*self.state).lineplot_window_id
          erase

          ;Call plothist to create histogram arrays.  Necessary to get
          ;default ymax
          plothist, hist_image, xhist, yhist, bin=(*self.state).binsize, $
            /NaN, /nodata

          (*self.state).lineplot_ymax = fix(max(yhist) + 0.05*max(yhist))

          widget_control, (*self.state).lineplot_ymax_id, $
            set_value = (*self.state).lineplot_ymax

          self->histplot, /update

        end
        'surfplot': begin

          plotsize = $
            fix(min([50, (*self.state).image_size[0]/2., (*self.state).image_size[1]/2.]))
          center = plotsize > (*self.state).plot_coord < $
            ((*self.state).image_size[0:1] - plotsize)

          (*self.state).lineplot_xmin = (center[0]-plotsize)
          (*self.state).lineplot_xmax = (center[0]+plotsize-1)
          (*self.state).lineplot_ymin = (center[1]-plotsize)
          (*self.state).lineplot_ymax = (center[1]+plotsize-1)

          widget_control,(*self.state).lineplot_xmin_id, $
            set_value=(*self.state).lineplot_xmin

          widget_control,(*self.state).lineplot_xmax_id, $
            set_value=(*self.state).lineplot_xmax

          widget_control,(*self.state).lineplot_ymin_id, $
            set_value=(*self.state).lineplot_ymin

          widget_control,(*self.state).lineplot_ymax_id, $
            set_value=(*self.state).lineplot_ymax

          self->surfplot, /update
        end
        'contourplot': begin

          plotsize = $
            fix(min([50, (*self.state).image_size[0]/2., (*self.state).image_size[1]/2.]))
          center = plotsize > (*self.state).plot_coord < $
            ((*self.state).image_size[0:1] - plotsize)

          (*self.state).lineplot_xmin = (center[0]-plotsize)
          (*self.state).lineplot_xmax = (center[0]+plotsize-1)
          (*self.state).lineplot_ymin = (center[1]-plotsize)
          (*self.state).lineplot_ymax = (center[1]+plotsize-1)

          widget_control,(*self.state).lineplot_xmin_id, $
            set_value=(*self.state).lineplot_xmin

          widget_control,(*self.state).lineplot_xmax_id, $
            set_value=(*self.state).lineplot_xmax

          widget_control,(*self.state).lineplot_ymin_id, $
            set_value=(*self.state).lineplot_ymin

          widget_control,(*self.state).lineplot_ymax_id, $
            set_value=(*self.state).lineplot_ymax

          self->contourplot, /update
        end
        'slice3dplot': begin

          widget_control,(*self.state).lineplot_xmin_id, $
            set_value=0

          (*self.state).lineplot_xmin = 0.0

          widget_control,(*self.state).lineplot_xmax_id, $
            set_value=(*self.state).image_size[2]

          (*self.state).lineplot_xmax = (*self.state).image_size[2]

          widget_control,(*self.state).lineplot_ymin_id, $
            set_value=min((*self.images.main_image_stack)[(*self.state).plot_coord[0], $
            (*self.state).plot_coord[1], *])

          (*self.state).lineplot_ymin = $
            min((*self.images.main_image_stack)[(*self.state).plot_coord[0], $
            (*self.state).plot_coord[1], *])

          widget_control,(*self.state).lineplot_ymax_id, $
            set_value=max((*self.images.main_image_stack)[(*self.state).plot_coord[0], $
            (*self.state).plot_coord[1], *])

          (*self.state).lineplot_ymax = $
            max((*self.images.main_image_stack)[(*self.state).plot_coord[0], $
            (*self.state).plot_coord[1], *])

          self->slice3dplot, /update
        end
        else:
      endcase
    end
    'lineplot_save': begin
      case ((*self.state).plot_type) of
        'centerplot': begin
          nm = (*self.state).imagename
          strps = strpos(nm,'/',/reverse_search)
          strpe = strpos(nm,'.fits',/reverse_search)
          nm = strmid(nm,strps+1,strpe-strps-1)
          outfile = dialog_pickfile(filter='*.fits', $
            file=nm+'-center_position.fits', get_path = tmp_dir, $
            path=(*self.state).current_dir,$
            title='Please Select File to save center positions')

          IF (strcompress(outfile, /remove_all) EQ '') then RETURN

          IF (outfile EQ tmp_dir) then BEGIN
            self->message, 'Must indicate filename to save.', $
              msgtype = 'error', /window
            return
          ENDIF

          ;;output & header
          tmp=*self.satspots[*].cens
          cents=fltarr(2,N_ELEMENTS(tmp[0,0,*]))
          for p=0, N_ELEMENTS(tmp[0,0,*]) -1 do begin
            for q=0, 1 do cents[q,p]=mean(tmp[q,*,p])
          endfor

          mkhdr,hdr,cents

          ;;write
          writefits,outfile,cents,hdr
        end
        else: begin
          message, /info, "This feature not yet implemented, sorry!"
        end
      endcase
    end
    'lineplot_ps': begin
      fname = strcompress((*self.state).current_dir + 'GPItv_plot.ps', /remove_all)
      forminfo = cmps_form(cancel = canceled, create = create, $
        parent = (*self.state).lineplot_base_id, $
        /preserve_aspect, $
        /color, $
        /nocommon, papersize='Letter', $
        filename = fname, $
        button_names = ['Create PS File'])

      if (canceled) then return
      if (forminfo.filename EQ '') then return

      tmp_result = findfile(forminfo.filename, count = nfiles)

      result = ''
      if (nfiles GT 0) then begin
        mesg = strarr(2)
        mesg[0] = 'Overwrite existing file:'
        tmp_string = strmid(forminfo.filename, strpos(forminfo.filename, $
          '/') + 1)
        mesg[1] = strcompress(tmp_string + '?', /remove_all)
        result =  dialog_message(mesg, $
          /default_no, $
          dialog_parent = (*self.state).base_id, $
          /question)
      endif

      if (strupcase(result) EQ 'NO') then return

      widget_control, /hourglass

      screen_device = !d.name

      set_plot, 'ps'
      device, _extra = forminfo

      case ((*self.state).plot_type) of

        'centerplot': begin
          self->centerplot, /ps
        end

        'rowplot': begin
          self->rowplot, /ps
        end

        'colplot': begin
          self->colplot, /ps
        end

        'gaussrowplot': begin
          self->gaussrowplot, /ps
        end

        'gausscolplot': begin
          self->gausscolplot, /ps
        end

        'vectorplot': begin
          self->vectorplot, /ps
        end

        'histplot': begin
          self->histplot, /ps
        end

        'surfplot': begin
          if ((*self.state).lineplot_xmin ge (*self.state).lineplot_xmax OR $
            (*self.state).lineplot_ymin ge (*self.state).lineplot_ymax) then begin
            self->message, 'XMin and YMin must be less than Xmax and YMax', $
              msgtype='error', /window
            device, /close
            set_plot, screen_device
            return
          endif

          self->surfplot, /ps
        end

        'contourplot': begin
          if ((*self.state).lineplot_xmin ge (*self.state).lineplot_xmax OR $
            (*self.state).lineplot_ymin ge (*self.state).lineplot_ymax) then begin
            self->message, 'XMin and YMin must be less than Xmax and YMax', $
              msgtype='error', /window
            device, /close
            set_plot, screen_device
            return
          endif

          self->contourplot, /ps
        end

        'slice3dplot': begin
          self->slice3dplot, /ps
        end

        else:
      endcase

      device, /close
      set_plot, screen_device

    end

    'lineplot_newrange': begin

      widget_control, (*self.state).lineplot_xmin_id, get_value = tmp_value
      (*self.state).lineplot_xmin = tmp_value

      widget_control, (*self.state).lineplot_xmax_id, get_value = tmp_value
      (*self.state).lineplot_xmax = tmp_value

      widget_control, (*self.state).lineplot_ymin_id, get_value = tmp_value
      (*self.state).lineplot_ymin = tmp_value

      widget_control, (*self.state).lineplot_ymax_id, get_value = tmp_value
      (*self.state).lineplot_ymax = tmp_value

      case (*self.state).plot_type of
        'rowplot': begin
          self->rowplot, /update
        end
        'colplot': begin
          self->colplot, /update
        end
        'gaussrowplot': begin
          self->gaussrowplot, /update
        end
        'gausscolplot': begin
          self->gausscolplot, /update
        end
        'vectorplot': begin
          self->vectorplot, /update
        end
        'histplot': begin
          widget_control, (*self.state).histplot_binsize_id, get_value = tmp_value
          (*self.state).binsize = tmp_value
          self->histplot, /update
        end
        'surfplot': begin
          self->surfplot, /update
        end
        'contourplot': begin
          self->contourplot, /update
        end
        'slice3dplot': begin
          self->slice3dplot, /update
        end
        else:
      endcase
    end

    else:
  endcase

end

;--------------------------------------------------------------------------------

pro GPITv::plot1satspots, iplot
; Draw satellite spot indicators on the main window

  ;if (*self.state).cube_mode ne 'WAVE' then begin
	  ;self->message,"Can't plot sat spots in pol mode yet - still to be implemented"
	  ;return
  ;endif
 
  
	; if we have FPM location, mark that too.
	; (Do this first so it works even for images without sat spots)
  if (*self.state).fpmoffset_fpmpos[0] gt 0 then begin
	hd = *((*self.state).head_ptr)
	IFSFILT = gpi_simplify_keyword_value(sxpar(hd, 'IFSFILT'))
	fpmdiam = gpi_get_constant('fpm_diam_'+strlowcase(IFSFILT))
	scale = gpi_get_constant('ifs_lenslet_scale')

    tvcircle, /data, fpmdiam/2/scale, $
			(*self.state).fpmoffset_fpmpos[0],$
			(*self.state).fpmoffset_fpmpos[1],$
			color=cgcolor('black'), thick=2, psym=0
	tvcircle, /data, fpmdiam/2/scale, $
			(*self.state).fpmoffset_fpmpos[0],$
			(*self.state).fpmoffset_fpmpos[1],$
			color=cgcolor('yellow'), thick=2, lines=2, psym=0


  endif

; First make sure we have sat spot info
  if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
    self->update_sat_spots,locs0=locs0
    ;;if failed, bail
    if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
		self->message, "Can't mark sat spots because no sat spot info available."
      return
    endif
  endif

	ind = (*self.state).cur_image_num

	;;check for warnings
	case (*self.satspots.warns)[ind] of
		0: color='cyan'
		1: color="orange"
		-1: color="red"
	endcase


    ;;find center
    xc = mean( (*self.satspots.cens)[0,*,ind] )
    yc = mean( (*self.satspots.cens)[1,*,ind] )

	;self->plotwindow

	oplot, (*self.satspots.cens)[0,*,ind],$
		(*self.satspots.cens)[1,*,ind],psym=1, color=cgcolor(color)

     for i=0,3 do begin

		; Mark position at current wavelength
        tvcircle, /data, (*self.state).contrap, $
			(*self.satspots.cens)[0,i,ind],$
			(*self.satspots.cens)[1,i,ind],$
			color=cgcolor(color), thick=2, psym=0

		; mark trace over all wavelengths
		oplot, (*self.satspots.cens)[0,i,*], (*self.satspots.cens)[1,i,*], psym=-3, color=cgcolor(color), thick=1, lines=2
	endfor

	; mark any that are flagged with warnings
	for j=0,(*self.state).image_size[2]-1 do begin
		if (*self.satspots.warns)[j] ne 0 then $
			oplot, (*self.satspots.cens)[0,*,j],$
				   (*self.satspots.cens)[1,*,j],psym=1, color=cgcolor('red')
	endfor

	; mark center of star
    oplot, [xc], [yc], psym=1, symsize=3, color=cgcolor('orange'), thick=2
 



end


;--------------------------------------------------------------------------------
pro GPItv::polarim_from_cube, status=status, $
  magnification=magnification, $
  binning=binning, fractional=fractional, $
  color=color, thetaoffset=thetaoffset
  ; Routine to set up polarization plot data structure and options
  ; Set up polarization vector overplot, based on the data present
  ; in the currently loaded image cube itself.

  status=0

  if (self.pdata.nplot ge self.pdata.maxplot) then begin
    self->message, msgtype='error', 'Too many calls to GPITVPLOT.'
    return
  endif
  self.pdata.nplot = self.pdata.nplot + 1

  if ~(keyword_set(color)) then color='red'
  if n_elements(thetaoffset) eq 0 then thetaoffset=0.0
  if ~(keyword_set(magnification)) then magnification=1.0
  if ~(keyword_set(binning)) then binning = 4.0
  if ~(keyword_set(fractional)) then fractional=0


  options = {magnification: float(magnification),$ ; arbitrary scale factor adjustment
    binning: float(binning),$			; How many lenslets to bin to show one vector
    fractional: uint(fractional),$		; fractional polarization or pol intensity?
    mask_vectors: 0, $					; apply the mask?
    polfrac_lowthresh: 0.0,$			; low threshhold for polarization fraction
    polfrac_highthresh: 1.0,$			; high threshhold for polarization fraction
    polint_lowthresh: !values.f_nan,$   ; low threshhold for polarized intensity
    polint_highthresh: !values.f_nan,$  ; high threshhold for polarized intensity
    display_legend: 1, $				; Display the legend?
    thetaoffset: float(thetaoffset), $	; Optional offset for position angles?
    color: color}						; plot color. Anything that works for cgColor.

  pstruct = {type: 'polarization',   $     ; points
    options: options  $     ; plot keyword options
  }

  self.pdata.plot_ptr[self.pdata.nplot] = ptr_new(pstruct)
  (*self.state).polarim_plotindex=self.pdata.nplot

  self->message, msgtype='information', 'Polarimetry vector plot setup complete.'
  status=1

end



;---------------------------------------------------------------------
pro GPItv::plot1pol, iplot
  ; This overprints polarization vectors onto the image.
  ;
  ; Based on Marshall's polvect.pro, heavily modified for GPItv.

  if (*self.state).polarim_display eq 0 then return

  self->setwindow, (*self.state).draw_window_id

  widget_control, /hourglass

  polplotoptions = (*(self.pdata.plot_ptr[iplot])).options

  thetaoffset =	polplotoptions.thetaoffset
  binning =		polplotoptions.binning > 1
  magnification = polplotoptions.magnification * 30 ; 30 screen pixels is reasonable for the default length
  resample = binning
  ;self->message, msgtype = 'information', "Resample: "+strc(resample)+"     zoom factor: "+strc((*self.state).zoom_factor)

  ;--- Obtain Stokes {I,Q,U} from datacube ---
  ; This is somewhat tricky since it has to be generalized;
  ; it should handle both Stokes cubes and polarization pair cubes,
  ; and more generally any polarized datacube with a valid WCS axis

  ; For specification of Stokes WCS axis, see
  ; Greisen & Calabretta 2002 A&A 395, 1061, section 5.4
  crval3 = sxpar(*(*self.state).exthead_ptr, "CRVAL3")
  crPIX3 = sxpar(*(*self.state).exthead_ptr, "CRPIX3")
  naxis3 = sxpar(*(*self.state).exthead_ptr, "NAXIS3")
  stokesaxis0 = indgen(naxis3)-crpix3+crval3
  modelabels = ["YX", "XY", "YY", "XX", "LR", "RL", "LL", "RR", "INVALID", "I", "Q", "U", "V", "P"]
  stokesaxis = modelabels[stokesaxis0+8]
  wi =  (where(stokesaxis eq "I", ict))[0]
  wq =  (where(stokesaxis eq "Q", qct))[0]
  wu =  (where(stokesaxis eq "U", uct))[0]
  wxx = (where(stokesaxis eq "XX", xxct))[0]
  wyy = (where(stokesaxis eq "YY", yyct))[0]

  if qct eq 1 and uct eq 1 then begin
    ;self->message, msgtype = 'information', "Loading Q and U Stokes vectors from image slices "+strc(wq)+" and "+strc(wu)
    io = (*self.images.main_image_backup)[*,*,wi]	; Stokes I original
    qo = (*self.images.main_image_backup)[*,*,wq]	; Stokes Q original
    uo = (*self.images.main_image_backup)[*,*,wu]	; Stokes U original
  endif else if xxct eq 1 and yyct eq 1 then begin
    ;self->message, msgtype = 'information',  "Loading perpendicular polarization vectors from image slices x="+strc(wxx)+" and y="+strc(wyy)
    io = ((*self.images.main_image_stack)[*,*,wxx] + (*self.images.main_image_stack)[*,*,wyy])
    qo = ((*self.images.main_image_stack)[*,*,wxx] - (*self.images.main_image_stack)[*,*,wyy])
    sz = size(qo)
    uo = fltarr(sz[1],sz[2])
  endif else begin
    self->message, "Error: Can't determine Stokes I,Q,U from currently loaded cube and WCS header.", msgtype='error'

  endelse
  max_pol_intensity = max(sqrt(qo^2+uo^2),/nan) ; we will use this below for normalization.
  ; calculate it before any
  ; transformations on Q and U



  ;---  Linear transformations of the image ---
  ; To enable masking by either polarized and total intensity we
  ; have to propagate all of [I,Q,U] through the rotation steps here.

  ; We have to transform the Q and U to match any transformations that
  ; have been applied to the image itself.
  ; The inversion and rotation have basically been copied from gpitv::refresh_image_invert_rotate
  ; is X flip needed?
  if strpos((*self.state).invert_image, 'x') ge 0 then begin
    io = reverse(io)
    qo = reverse(qo)
    uo = reverse(uo)
  endif

  ; is Y flip needed?
  if strpos((*self.state).invert_image, 'y') ge 0 then begin
    io = reverse(io,2)
    qo = reverse(qo,2)
    uo = reverse(uo,2)
  endif

  ; is Image Rotation needed?
  if (*self.state).rot_angle ne 0 then begin
    desired_angle = (*self.state).rot_angle  ; for back compatibility with prior implementation

    ;; Are we rotating by some multiple of 90 degrees? If so, we can do so
    ;; exactly.
    if (desired_angle/90. eq fix(desired_angle/90)) then begin
      desired_angle = desired_angle mod 360
      if desired_angle lt 0 then desired_angle +=360
      rchange = strc(fix(desired_angle)) ; how much do we need to change the image to get the new rotation?

      case rchange of
        '0':  rot_dir=0           ;; do nothing
        '90': rot_dir=1
        '180': rot_dir=2
        '270': rot_dir=3
      endcase

      ;; no astrometry, just do the rotate
      io = rotate(io, rot_dir)
      qo = rotate(qo, rot_dir)
      uo = rotate(uo, rot_dir)

    endif else begin
      ;Arbitrary Rotation Angle
      interpolated_io= rot(io, (-1)*desired_angle,  cubic=-0.5, missing=!values.f_nan)
      nearest_io = rot(io, (-1)*desired_angle,  interp =0,  missing=!values.f_nan)
      wnan = where(~finite(interpolated_io), nanct)
      if nanct gt 0 then interpolated_io[wnan] = nearest_io[wnan]
      io = interpolated_io

      interpolated_qo= rot(qo, (-1)*desired_angle,  cubic=-0.5, missing=!values.f_nan)
      nearest_qo = rot(qo, (-1)*desired_angle,  interp =0,  missing=!values.f_nan)
      wnan = where(~finite(interpolated_qo), nanct)
      if nanct gt 0 then interpolated_qo[wnan] = nearest_qo[wnan]
      qo = interpolated_qo

      interpolated_uo= rot(uo, (-1)*desired_angle,  cubic=-0.5, missing=!values.f_nan)
      nearest_uo = rot(uo, (-1)*desired_angle,  interp =0,  missing=!values.f_nan)
      wnan = where(~finite(interpolated_uo), nanct)
      if nanct gt 0 then interpolated_uo[wnan] = nearest_uo[wnan]
      uo = interpolated_uo
    endelse
  endif

  ; Do we need to resample the Stokes images?
  if resample eq 1 then begin
    i = io
    q = qo
    u = uo
  endif else begin
    sz = size(qo)
    i = congrid(io,sz[1]/resample,sz[2]/resample,/int);,/half)
    q = congrid(qo,sz[1]/resample,sz[2]/resample,/int);,/half)
    u = congrid(uo,sz[1]/resample,sz[2]/resample,/int);,/half)
  endelse

  ; Create x and y coordinate arrays we will use for plotting
  sz = size(q)
  x = (findgen(sz[1]))*resample
  y = (findgen(sz[2]))*resample
  pol_intensity = sqrt(u^2.+q^2.)
  pol_fraction = pol_intensity / i


  if keyword_set(polplotoptions.fractional) then begin
    mag = pol_fraction
    label = 'linear polarization fraction'
  endif else begin
    ; normalize relative to 1.0 = peak polarized intensity. This keeps the
    ; plotting length scales more consistent between frac. and intensity
    ; display modes
    mag = pol_intensity/max_pol_intensity
    label='linear polarized intensity'
  endelse


  ; check whether the polarization masking options are selected and apply it;
  if polplotoptions.mask_vectors then begin
    good  = where ( (pol_fraction ge polplotoptions.polfrac_lowthresh) and $
      (pol_fraction le polplotoptions.polfrac_highthresh) and $
      (pol_intensity ge polplotoptions.polint_lowthresh) and $
      (pol_intensity le polplotoptions.polint_highthresh))
  endif else begin
    good = where(finite(mag))
  endelse

  if n_elements(good) eq 1 then return

  ugood = u[good]
  qgood = q[good]
  x0 = min(x,max=x1,/NaN)      ; get coordinates
  y0 = min(y,max=y1,/NaN)
  x_step=(x1-x0)/(sz[1]-1.0)   ; Convert to float. Integer math
  y_step=(y1-y0)/(sz[2]-1.0)   ; could result in divide by 0

  ;To compensate for the use of the Rotate North Up Primitive, we may need to
  ;apply some additional rotation here to the position angle.
  if ptr_valid((*self.state).exthead_ptr) then begin ;If the header exists
    hdr = *((*self.state).exthead_ptr)
    rot_ang = sxpar(hdr, 'ROTANG') ;If this keyword isn't set sxpar just returns 0, which is acceptable.
    getrot, hdr, npa, cdelt, /silent
    d_PAR_ANG = - rot_ang
  endif else begin
    d_PAR_ANG = 0
    cdelt = [1,1] ;If there's no header create a dummy cdelt whose first element is positive
  endelse

  ;print, "Rotating pol vectors by angle of: "+string(-d_PAR_ANG) ; To match with north rotation
  if cdelt[0] gt 0 then sgn = -1 else sgn = 1 ; To check for flip between RH and LH coordinate systems

  theta =  sgn* 0.5 * atan(u,q)+npa*!dtor+thetaoffset*!dtor

  ;theta = 0.5 * atan(u/q)+thetaoffset*!dtor
  ;   self->Message, "Mean theta "+string(mean(theta,/nan)/!dtor)
  ;   self->Message, "Sign"+string(sgn)
  ;   self->Message, "npa"+string(npa)
  ;   self->Message, "PA Offset from GPItv:"+string(thetaoffset)
  ;   self->Message, "Image Rotation from GPItv:"+string((*self.state).rot_angle)
  ;   self->Message, "Image Rotation Angle:"+string(d_par_ang)

  ; Compute offsets {dx, dy} for each vector.
  ; remember position angle is defined starting at NORTH so
  ; the usual positions of sin and cosine are swapped.
  deltax = - magnification * resample * mag * sin(theta)/2
  deltay =   magnification * resample * mag * cos(theta)/2

  ; compute start and end coordinates for each vector
  ys = y[good /sz[1]]
  xs = x[good mod sz[1]]
  x0 = xs-deltax[good]
  x1 = xs+deltax[good]
  y0 = ys-deltay[good]
  y1 = ys+deltay[good]

  color = cgcolor( polplotoptions.color )
  for i=0l,n_elements(good)-1 do begin     ;Each point
    plots,[x0[i],x1[i]], [y0[i],y1[i]], color=color, noclip=0
  endfor


  if polplotoptions.display_legend then begin
    ; Draw a key at lower right to indicate the degree of polarization scale
    ; for the vectors
    ystart = total(!y.crange*[0.95, 0.05])
    xstart = total(!x.crange*[0.25, 0.75])
    labelxstart = total(!x.crange*[0.23, 0.77])
    labelystart = total(!y.crange*[0.96, 0.04])

    legendcolor='orange'
    thick=3
    if keyword_set(polplotoptions.fractional) then begin
      ; Draw and label a vector for 20% polarization
      ; Basically this just repeats the calculation done for plotting any
      ; typical vector, using a value fixed to 0.5
      deltax =  magnification * resample * 0.2 * cos(0)/2
      xyouts, labelxstart, labelystart , 'Pol. Frac. = 20%', charsize=1.5, color=cgcolor(legendcolor)
      plots, [xstart-2*deltax, xstart], [ystart, ystart], thick=thick, color=cgcolor(legendcolor)
    endif else begin
      ; draw and label a vector for the 97th percentile of the displayed  polarizations
      ; So first figure out that percentage:
      sorted_pol_int = pol_intensity[sort(pol_intensity)]
      sorted_pol_int = sorted_pol_int[where(finite(sorted_pol_int))]
      med_pol_int = median(pol_intensity)
      pol_int_97th = sorted_pol_int[0.97*n_elements(sorted_pol_int)]
      ; And then display it. Remember to normalize by the max of the
      ; polarized intensity as we do when creating the 'mag' variable above.
      deltax =  magnification * resample * pol_int_97th/max_pol_intensity* cos(0)/2
      xyouts, labelxstart, labelystart , 'Pol. Int. = '+sigfig(pol_int_97th,3), charsize=1.5, color=cgcolor(legendcolor)
      plots, [xstart-2*deltax, xstart], [ystart, ystart], thick=thick, color=cgcolor(legendcolor)
      ;print, "pol legend: ", magnification, resample, pol_int_97th/max(pol_intensity,/nan)

    endelse

  endif


  self->resetwindow
  (*self.state).newrefresh=1
end

;--------------------------------------------------------------------------------


pro GPItv::polarim_event, event
  ; This is the event handler for the polarization plot window.
  ; It will either
  ;  (a) create a new polarization plot, when called the first time
  ;  or
  ;  (b) update a polarization plot, on subsequent calls.

  @gpitv_err

  if (*self.state).polarim_plotindex lt 0 then begin
    ; create a new polarization plot structure if somehow it's not already defined
    self->polarim_from_cube, status=status
    if ~status then return
  endif


  widget_control, event.id, get_uvalue = uvalue
  ;self.pdata.nplot = (*self.state).polarim_plotindex
  pol_index = (*self.state).polarim_plotindex

  dorefresh=1 ; by default should refresh after any change
  case uvalue of
    'polarim_display': (*self.state).polarim_display = event.value
    'polarim_display_yes': if ~(*self.state).polarim_display then (*self.state).polarim_display = 1 else dorefresh=0
    'polarim_display_no': if (*self.state).polarim_display then (*self.state).polarim_display = 0 else dorefresh=0
    'polarim_mask_yes':   (*(self.pdata.plot_ptr[pol_index])).options.mask_vectors = 1
    'polarim_mask_no':    (*(self.pdata.plot_ptr[pol_index])).options.mask_vectors = 0
    'polarim_legend_yes': (*(self.pdata.plot_ptr[pol_index])).options.display_legend = 1
    'polarim_legend_no':  (*(self.pdata.plot_ptr[pol_index])).options.display_legend = 0
    'polarim_polfrac_highthresh': (*(self.pdata.plot_ptr[pol_index])).options.polfrac_highthresh = float(event.value)
    'polarim_polfrac_lowthresh':  (*(self.pdata.plot_ptr[pol_index])).options.polfrac_lowthresh  = float(event.value)
    'polarim_polint_highthresh':  (*(self.pdata.plot_ptr[pol_index])).options.polint_highthresh = float(event.value)
    'polarim_polint_lowthresh':   (*(self.pdata.plot_ptr[pol_index])).options.polint_lowthresh  = float(event.value)
    'magnification':	  (*(self.pdata.plot_ptr[pol_index])).options.magnification = event.value
    'binning':            (*(self.pdata.plot_ptr[pol_index])).options.binning = event.value
    'fractional':		  (*(self.pdata.plot_ptr[pol_index])).options.fractional = event.index
    'polarim_offset':     (*(self.pdata.plot_ptr[pol_index])).options.thetaoffset = event.value
    'Refresh': dorefresh=1
    'polarim_done': widget_control, event.top, /destroy
    else:
  endcase
  if keyword_set(dorefresh) then self->refresh

end

;--------------------------------------------------------------------------------

pro GPItv::polarim_options_dialog
  ; Display the polarimetry vector overplotting control dialog window.

  if (*self.state).cube_mode ne 'STOKES' then begin
	  self->message, 'Not a polarization cube. The currently loaded data is not polarimetry mode so polarimetry vector display is not possible.',msgtype='error', /window
	  return
  endif
  if (*self.state).image_size[2] lt 4 then begin
	  self->message, ['Not a Stokes polarization cube. The currently loaded data is only 2 orthogonal polarizations,','not a 4-element Stokes vector cube, so polarimetry vector display is not possible.'],msgtype='error', /window
	  return
  endif



  (*self.state).polarim_display = 1 ; Any time you open this dialog, you probably want the plot active

  if (*self.state).polarim_plotindex eq -1 then begin
    ; create a new polarization plot structure if none exists.
    self->polarim_from_cube, status=status
    if ~status then return
  endif


  if (not (xregistered(self.xname+'_polarim'))) then begin

    pol_index = (*self.state).polarim_plotindex
    polplotoptions = (*(self.pdata.plot_ptr[pol_index])).options

    if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '

    polarim_base = $
      widget_base(/base_align_center, /base_align_right, $
      group_leader = (*self.state).base_id, $
      /column, $
      title = title_base + ' Polarimetry Options', $
      uvalue = 'polarim_base')
    (*self.state).polarim_dialog_id = polarim_base

    polarim_data_base1 = widget_base(  polarim_base, /column, frame=1)

    polarim_data_base1a = widget_base(polarim_data_base1, /column, frame=0, /base_align_left)

    ; all this code creates the Yes/No buttons
    base1 = widget_base(polarim_data_base1a,/row, frame=0, /base_align_right)
    label = widget_label(base1, value="Plot pol. vectors?")
    base2 = widget_base(base1,/row,/exclusive, frame=0)
    b_plot_yes = widget_button(base2, uvalue="polarim_display_yes", value="Yes")
    b_plot_no = widget_button(base2, uvalue="polarim_display_no", value="no" )



    ;(*self.state).polarim_fractional_id = $
    res=	widget_droplist(polarim_data_base1a, $
      frame=0, $
      title='Using  ', uvalue='fractional',$
      value=['Pol. Intensity', 'Pol. Fraction'])

    ;(*self.state).polarim_mag_id = $
    res=  cw_field(polarim_data_base1a, $
      /float, /return_events, $
      title = 'Magnification:', $
      uvalue = 'magnification', $
      value = sigfig(polplotoptions.magnification,2), $
      xsize = 8)

    ;(*self.state).polarim_mag_id = $
    res= cw_field(polarim_data_base1a, $
      /float, $
      /return_events, $
      title = 'Binning:      ', $
      uvalue = 'binning', $
      value = sigfig(polplotoptions.binning ,2), $
      xsize = 8)

    base_mask = widget_base(polarim_data_base1a,/column, frame=1, /base_align_left)

    base3 = widget_base(base_mask ,/row, frame=0)
    label = widget_label(base3, value="Mask pol. vectors?")
    base3b= widget_base(base3,/row,/exclusive, frame=0)
    b_yes = widget_button(base3b, uvalue="polarim_mask_yes", value="Yes")
    b_no =  widget_button(base3b, uvalue="polarim_mask_no", value="No" )

    if keyword_set(polplotoptions.mask_vectors) then $
      widget_control, b_yes, /set_button else widget_control, b_no, /set_button
    label = widget_label(base_mask, value=" Pol. fraction (between 0.0 - 1.0):  ")


    base3 = widget_base(base_mask,/row, frame=0)
    res=  cw_field(base3, $
      /float, /return_events, $
      title = 'Min:', $
      uvalue = 'polarim_polfrac_lowthresh', $
      value = polplotoptions.polfrac_lowthresh, $
      xsize = 10)

    res=  cw_field(base3, $
      /float, /return_events, $
      title = 'Max:', $
      uvalue = 'polarim_polfrac_highthresh', $
      value = polplotoptions.polfrac_highthresh, $
      xsize = 10)

    ; default is to set min/max thresh to the min/max of raw untransformed polarized intensity
    pol_intensity = sqrt(((*self.images.main_image_stack)[*,*,1])^2 + ((*self.images.main_image_stack)[*,*,2]^2))
    if ~finite(polplotoptions.polint_lowthresh  )  then polplotoptions.polint_lowthresh= min(pol_intensity,/nan)
    if ~finite(polplotoptions.polint_highthresh  ) then polplotoptions.polint_highthresh= max(pol_intensity,/nan)
    (*(self.pdata.plot_ptr[pol_index])).options = polplotoptions ; save the modified structure!

    label = widget_label(base_mask, value=" Pol. intensity (between "+sigfig(min(pol_intensity,/nan),3)+" - "+$
      sigfig(max(pol_intensity,/nan),3)+"): ")
    base3 = widget_base(base_mask,/row, frame=0)
    res=  cw_field(base3, $
      /float, /return_events, $
      title = 'Min:', $
      uvalue = 'polarim_polint_lowthresh', $
      value = sigfig(polplotoptions.polint_lowthresh,4), $
      xsize = 10)

    res=  cw_field(base3, $
      /float, /return_events, $
      title = 'Max:', $
      uvalue = 'polarim_polint_highthresh', $
      value = sigfig(polplotoptions.polint_highthresh,4), $
      xsize = 10)



    if gpi_get_setting('gpitv_enable_pol_angle_offset', /bool, default=0) then  begin
      ; being able to adjust the polarization position angle was useful early
      ; in gpi polarimetry development, but is not generally needed any more
      ; so it's hidden
      res = cw_field(polarim_data_base1a, $
        /float, $
        /return_events, $
        title = 'Pos Angle Offset:', $
        uvalue = 'polarim_offset', $
        value = polplotoptions.thetaoffset, $
        xsize = 10)
    endif

    base3 = widget_base(polarim_data_base1a,/row, frame=0)
    label = widget_label(base3, value="Display legend?")
    base3b = widget_base(base3,/row,/exclusive, frame=0)
    b_yes = widget_button(base3b, uvalue="polarim_legend_yes", value="Yes")
    b_no = widget_button(base3b, uvalue="polarim_legend_no", value="No" )
    widget_control, b_yes, /set_button


    base_row = widget_base(polarim_data_base1a,/row, frame=0)
    photsettings_id = $
      widget_button(base_row, $
      value = '  Refresh Display  ', $
      uvalue = 'Refresh')

    polarim_done = $
      widget_button(base_row, $
      value = '       Close       ', $
      uvalue = 'polarim_done')

    widget_control, b_plot_yes, /set_button ; make sure the plot is enabled!

    widget_control, polarim_base, /realize

    xmanager, self.xname+'_polarim', polarim_base, /no_block
    widget_control, polarim_base, set_uvalue = {object:self, method: 'polarim_event'}
    widget_control, polarim_base, event_pro = 'GPItvo_subwindow_event_handler'


    self->resetwindow
    self->refresh
  endif


end



;----------------------------------------------------------------------
;                         help window
;---------------------------------------------------------------------

pro GPItv::help

  h = ['GPItv HELP',$
    '',$
    '**************************************************',$
    '* This is only a very brief, incomplete list of  *',$
    '* instructions. Please see the full GPItv user   *',$
    '* manual at:                                     *',$
    '* http://docs.planetimager.org/pipeline/gpitv/   *',$
    '**************************************************',$
    '',$
    'MENU BAR:',$
    'File->Open...:                Read in a new fits image from disk',$
    'File->Browse Files...:        Start directory browser',$
    'File->Show gpidiagram...:     Bring up gpidiagram of GPI light path at the time of observation',$
    '                              This only works if header is loaded.  Requires working Python installation',$
    '                              and ifspython branch to be installed',$
    'File->Get Image from Catalog: Download archive images',$
    'File->View FITS Header...:    Display any loaded header information',$
    'File->Change FITS extension...: Switch to different extension in loaded FITS file',$
    'File->Write FITS...:          Write out a new fits image to disk (single-plane or entire image)',$
    'File->Write PS...:            Write a PostScript file of the current display',$
    'File->Write Image...:         Write a JPEG, TIFF, BMP, PICT, or PNG image of the current display',$
    'File->Make Movie...:          Generate animated gif or mpeg of data cube slices',$
    'File->Save to IDL variable...: Save cube, slice or header to variable in the main scope',$
    'File->Quit:                   Quits GPItv',$
    '',$
    'ColorMap Menu:                Selects color table',$
    '',$
    'Scaling->Linear:              Selects linear scaling',$
    'Scaling->Log:                 Selects log scaling',$
    'Scaling->HistEq:              Selects histogram-equalized scaling',$
    'Scaling->Square Root:         Selects square root scaling',$
    'Scaling->Asinh:               Selects asinh scaling',$
    'Scaling->Asinh Seetings...:   Brings up dialog for Asinh scaling settings',$
    'Scaling->Auto Scale:          Toggle auto scaling',$
    'Scaling->Full Range:          Restretch to full range',$
    'Scaling->Zero to Max:         Set scale from zero to maximum slice value',$
    '',$
    'Labels->TextLabel:            Brings up a dialog box for text input',$
    'Labels->Arrow:                Brings up a dialog box for overplotting arrows',$
    'Labels->Contour:              Brings up a dialog box for overplotting contours',$
    'Labels->Compass:              Draws a compass (requires WCS info in header)',$
    'Labels->Scalebar:             Draws a scale bar (requires WCS info in header)',$
    'Labels->Polarimetry:          Label polarimetry slices',$
    'Labels->Draw Region:          Brings up a dialog box for overplotting regions',$
    'Labels->WCS Grid:             Draws a WCS grid on current image',$
    'Labels->Select Wavecal/Polcal File:  Brings up a dialog box to select wavelength calibration file',$
    'Labels->Get Wavecal/Polcal from CalDB: Automatically selects wavelength calibration from available ones',$
    'Labels->Plot Wavecal Grid:    Display wavelength calibration (only meaningful for raw data images)',$
    'Labels->EraseLast:            Erases the most recent plot label',$
    'Labels->EraseAll:             Erases all plot labels',$
    'ImageInfo->Load Regions:      Load in an SAOImage/DS9 region file and overplot on image',$
    '                              Region files must be in the following format:',$
    '                              circle( xcenter, ycenter, radius)',$
    '                              box( xcenter, ycenter, xwidth, ywidth)',$
    '                              ellipse( xcenter, ycenter, xwidth, ywidth, rotation angle)',$
    '                              polygon( x1, y1, x2, y2, x3, y3, ...)',$
    '                              line( x1, y1, x2, y2)',$
    '                              Coordinates may be specified in pixels or WCS.  Radii and widths',$
    '                              are specified in pixels or arcminutes.  For example,',$
    '',$
    '                               circle( 100.5, 46.3, 10.0)',$
    '',$
    '                              draws a circle with a radius of 10 pixels, centered at (100.5, 46.3)',$
    ' ',$
    '                               circle(00:47:55.121, -25:22:11.98, 0.567)',$
    ' ',$
    '                              draws a circle with a radius of 0.567 arcminutes, centered at (00:47:55.121, -25:22:11.98)',$
    ' ',$
    '                              The coordinate system for the region coordinates may be specified by',$
    ' ',$
    '                              circle(00:47:55.121, -25:22:11.98, 0.567, J2000)',$
    '                              circle(11.97967, -25.36999, 0.567, J2000)',$
    '                              circle(00:45:27.846, -25:38:33.51, 0.567, B1950)',$
    '                              circle(11.366, -25.6426, 0.567, B1950)',$
    '                              circle(98.566, -88.073, 0.567, galactic)',$
    '                              circle(0.10622, -27.88563, 0.567, ecliptic)',$
    ' ',$
    '                              If no coordinate system is given and coordinates are in colon-separated WCS format, the',$
    '                              native coordinate system is used.',$
    ' ',$
    '                              Region color may be specified for the following colors in the format below:',$
    '                              Red, Black, Green, Blue, Cyan, Magenta, Yellow, White',$
    ' ',$
    '                               circle(100.5, 46.3, 10.0) # color=red',$
    ' ',$
    '                              Region text may be specified in the following format:',$
    ' ',$
    '                               circle(100.5, 46.3, 10.0) # text={Text written here}',$
    '',$
    '',$
    'Blink->SetBlink:              Sets the current display to be the blink image for mouse button 1, 2, or 3',$
    'Blink->MakeRGB:               Generate RGB image from data cube',$
    '',$
    'Zoom->Zoom In:                Zoom in by 2x',$
    'Zoom->Zoom Out:               Zoom out by 2x',$
    'Zoom->1/16:                   Zoom out to 1/16x original image',$
    'Zoom->1/8:                    Zoom out to 1/8x original image',$
    'Zoom->1/4:                    Zoom out to 1/4x original image',$
    'Zoom->1/2:                    Zoom out to 1/2x original image',$
    'Zoom->1:                      No Zoom',$
    'Zoom->2:                      Zoom in to 2x original image',$
    'Zoom->4:                      Zoom in to 4x original image',$
    'Zoom->8:                      Zoom in to 8x original image',$
    'Zoom->16:                     Zoom in to 16x original image',$
    'Zoom->Center:                 Recenter image',$
    'Zoom->None:                   Invert to original image',$
    'Zoom->Invert X:               Invert the X-axis of the original image',$
    'Zoom->Invert Y:               Invert the Y-axis of the original image',$
    'Zoom->Invert X&Y:             Invert both the X and Y axes of the original image',$
    'Zoom->Rotate:                 Rotate image by arbitrary angle',$
    'Zoom->0 deg:                  Rotate image to original orientation',$
    'Zoom->90 deg:                 Rotate original image by 90 degrees',$
    'Zoom->180 deg:                Rotate original image by 180 degrees',$
    'Zoom->270 deg:                Rotate original image by 270 degrees',$
    'Zoom->Rotate GPI field square: Rotate so that IFS axes align with image axes',$
    'Zoom->Rotate arbitrary angle: Rotate by user selected angle',$
    '',$
    'ImageInfo->View FITS Header...:   Display the FITS header, if there is one',$
    'ImageInfo->Contrast:          Brings up the contrast display window',$
    'ImageInfo->Photometry:        Brings up the photometry window',$
    'ImageInfo->Statistics:        Brings up the statistics window',$
    'ImageInfo->Histogram/Exposure: Brings up the histogram window',$
    'ImageInfo->Pixel Table:       Brings up a pixel table that tracks as the cursor moves',$
    'ImageInfo->Star Position:     Brings up star position window',$
    'ImageInfo->Display Coordinate System:',$
    '                              RA,dec(J2000): Coordinates displayed are RA,dec (J2000)',$
    '                              RA,dec(B1950): Coordinates displayed are RA,dec (B1950)',$
    '                              RA,dec(J2000) deg: Coordinates displayed are RA,dec (J2000) in degrees',$
    '                              Galactic:      Coordinates displayed are Galactic coordinates',$
    '                              Ecliptic(J2000): Coordinates displayed are Ecliptic (J2000)',$
    '                              Native:        Coordinates displayed are those of the image',$
    '',$
    'Options->Contrast Settings...: Brings up contrast plot settings window',$
    'Options->SDI Settings...:     Brings up SDI settings window',$
    'Options->KLIP Settings...:    Brings up KLIP settings window',$
    'Options->Clear KLIP Data:     Removes KLIP processed cube from memory',$
    'Options->Retain Current Slice: Current slice index will be displayed when next image is loaded',$
    '                              (if next image is a data cube)',$
    'Options->Retain Current Stretch: Current stretch settings will be applied to next image loaded',$
    'Options->Retain Current View: Current zoom + position settings will be applied to next image loaded',$
    'Options->Flag Bad Pix from DQ: Display saturated or otherwise bad pixels in a contrasting color',$
    ;'Options->Auto Align:          Center image on load',$
    ;'Options->Auto Zoom:           ZoomFit on load',$
    'Options->Supress Information Messages: Do not print out information messages',$
    'Options->Supress Warning Messages: Do not print out warning messages',$
    ;'Options->Always Autoscale:    Autoscale for each slice',$
    'Options->Display Full Paths:  Show full paths to loaded files',$
    '',$
    'CONTROL PANEL ITEMS:',$
    'Min(colorbar):                 Shows minimum data value displayed; enter new min value here',$
  'Max(colorbar):                 Shows maximum data value displayed; enter new max value here',$
  'Pan Window:                    Use mouse to drag the image-view box around',$
    '',$
    'MOUSE MODE SELECTOR:',$
    'Recenter/Color:                Button 1 or 2 click: center on current position',$
    '                               Button 3 click and drag to change the color stretch:',$
    '                               Move vertically to change contrast, and horizontally to change brightness.',$
    '',$
    'Zoom:                          Button 1: Zoom in & center on current position',$
    '                               Button 2: Center on current position',$
    '                               Button 3: Zoom out & center on current position',$
    ' ',$
    'Blink:                         ButtonX blinks to image X (Set via Blink menu)',$
    '',$
    'Statistics 2D/3D:              Button 2: Bring up 2D statistics window centered on click location',$
    '                               Button 3: Image 3D statistics:',$
    ' 					            Select arbitrary box with two clicks, defining the corners',$
    '',$
    'Plot Cut along Vector:         Button 1: Press and hold while dragging across image.',$
    '                               Release to draw vector cut plot between two points.',$
    '',$
    'Measure Distance:              Button 1: Press and hold while dragging across image.',$
    '                               Release to display distance between two points.',$
    '',$
    'Photometry:                    Button 1: Bring up Aperture Photometry window centered at click location',$
    '                               Button 3: Bring up Angular Profile window centered at click location',$
    'Spectrum Plot:                 Button 1: Bring up Spectral Profile window centered at click location',$
    '                               Button 3: Bring up z axis plot of clicked pixel',$
    '',$
    'Draw Region:                   Button 1: Brings up dialog to overplot regions on displayed image',$
    '',$
    'Row/Column Plot:               Button 1: Plot pixel values of clicked row',$
    '                               Button 3: Plot pixel values of clicked column',$
    'Gaus Row/Column Plot:          Button 1: Plot pixel values of clicked row with best-fit Gaussian',$
    '                               Button 3: Plot pixel values of clicked column with best-fit Gaussian',$
    '',$
    'Histogram/Contour Plot:        Button 1: Plot pixel value histogram centered at click location',$
    '                               Button 3: Plot 2D contours of log(pixel value) centered at click location' ,$
    '',$
    'Surface Plot:                  Button 1: Plot 3D surface contour centered at click location',$
    '',$
    'Move Wavecal Grid:             Button 1: Press and hold while dragging across image.',$
    '                               Release to display repositioned wavecal grid.',$
    '',$
    'BUTTONS:',$
    'Invert:                        Inverts the current color table',$
    'Restretch:                     Sets min and max to preserve display colors while linearizing the color table',$
    'AutoScale:                     Sets min and max to show data values around image median',$
    'FullRange:                     Sets min and max to show the full data range of the image',$
    'ZoomIn:                        Zooms in by 2x',$
    'ZoomOut:                       Zooms out by 2x',$
    'Zoom1:                         Sets zoom level to original scale',$
    'ZoomFit:                       Sets zoom level to fit whole image in display',$
    'Center:                        Centers image on display window',$
    '',$
    'MULTI-PLANE IMAGE SLIDER:',$
    'Image #= :                     Type image plane number to display',$
    '                               Use slidebar to display other image planes',$
    '',$
    'MULTI-PLANE COLOR SCALING DROPLIST:',$
    'Constant:                      Keep Min/Max display values the same for each image plane',$
    'AutoScale:                     GPItv AutoScale Min/Max display values for the displayed plane',$
    'Min/Max:                       Set Min/Max display values to Min/Max of the displayed plane',$
    '',$
    'COLLAPSE MODE DROPLIST:',$
    'Show Cube Slices:              Show original image cube',$
    'Collapse by Mean:              Show mean of all pixels in lambda dimension',$
    'Collapse by Median:            Show median of all pixels in lambda dimension',$
    'Collaspe by SDI:               Bring up SDI dialog',$
    'Collapse to RGB Color:         Display RGB image generated from 3 slices',$
    'Align speckles:                Re-project image so that speckles are aligned to current slice',$
    'Run KLIP:                      Perform KLIP processing on all image slices',$
    'High Pass Filter:              Remove low-frequency structure',$
    'Low Pass Filter:               Remove high-frequency structure',$
    'Create SNR Map:                Create SNR Map using contrast profile',$
    '',$
    'KEYBOARD SHORTCUTS:',$
    'Numeric keypad (with NUM LOCK on) moves cursor',$
    '1 	    Down-Left',$
    '2 	    Down',$
    '3 	    Down-Right',$
    '4 	    Left',$
    '6 	    Right',$
    '7 	    Up-Left',$
    '8 	    Up',$
    '9 	    Up-Right',$
    ' ',$
    'b 	    Change slice number, previous (“back”)',$
    'n 	    Change slice number, next',$
    'a 	    Change image display min/max to Auto-Scale -2/+5 sigma',$
    'g  	    Show region plot',$
    'h  	    Show histogram plot of pixels around current cursor position',$
    'c  	    Show column plot',$
    'i 	    Show image statistics at current position',$
    'j 	    Show 1D Gaussian fit to image rows around current cursor position, +- 10 pixels',$
    'k 	    Show 1D Gaussian fit to image columns around current cursor position, +- 10 pixels',$
    'l 	    Plot pixel value vs wavelength, for 3D images (“l” for “lambda”)',$
    'm  	    Change mouse mode (cycles through list of modes, one mode at a time.)',$
    'p 	    Do aperture photometry at current position',$
    'q 	    Quit GPItv',$
    'r 	    Show row plot',$
    's 	    Show surface plot',$
    't 	    Show contour plot',$
    'y 	    Recenter plot',$
    'z 	    Show pixel table',$
    'E 	    Erase anything drawn in main window',$
    'M 	    Change image display min/max to image min/max',$
    'R  	    Rotate image by arbitrary angle',$
    '- 	    Zoom out',$
    '+ 	    Zoom in',$
    '',$
    'IDL COMMAND LINE HELP:',$
    'To pass an array to GPItv:',$
    '   GPItv, array_name [, options]',$
    '',$
    'To pass a FITS filename to GPItv:',$
    '   GPItv, fitsfile_name [, options] (enclose filename in single quotes) ',$
    '',$
    'Command-line options are: ',$
    '   [,array_name OR fits_file] [header],[,min = min_value][,max=max_value] ',$
    '   [,/linear|/log|,/histeq|/asinh|/sqrt] [,/block] [,/exit] ',$
    '   [,header = header][extensionhead = extenshionhead] ',$
    '   [,nbrsatspot=nbrsatspot][/dispwavecalgrid] ',$
    '',$
    'To overplot a contour plot on the draw window:',$
    '   GPItvcontour, array_name [, options...]',$
    '',$
    'To overplot text on the draw window: ',$
    '   GPItvxyouts, x, y, text_string [, options]  (enclose string in single quotes)',$
    '',$
    'To overplot points or lines on the current plot:',$
    '   GPItvplot, xvector, yvector [, options]',$
    'The options for GPItvcontour, GPItvxyouts, and GPItvplot are essentially',$
    '  the same as those for the idl contour, xyouts, and plot commands,',$
    '  except that data coordinates are always used.',$
    '',$
    'The default color for overplots is RED.',$
    'The lowest 8 entries in the color table are:',$
    '    0 = black',$
    '    1 = red',$
    '    2 = green',$
    '    3 = blue',$
    '    4 = cyan',$
    '    5 = magenta',$
    '    6 = yellow',$
    '    7 = white',$
    'The top entry in the color table is also reserved for white. ',$
    'OTHER COMMANDS:',$
    '  self->erase [, N]:       Erases all (or last N) plots and text',$
    '  GPItv_shutdown:          Quits GPItv',$
    'NOTE: If GPItv should crash, type GPItv_shutdown at the idl prompt.']


  if (not (xregistered(self.xname+'_help'))) then begin

    helptitle = strcompress('GPItv v' + (*self.state).version + ' help')

    help_base =  widget_base(group_leader = (*self.state).base_id, $
      /column, $
      /base_align_right, $
      title = helptitle, $
      uvalue = 'help_base',$
      tlb_size_events = 1)

    (*self.state).helptext_id = widget_text(help_base, $
      /scroll, $
      value = h, $
      xsize = 100, $
      ysize = 50)

    help_done = widget_button(help_base, $
      value = 'Done', $
      uvalue = 'help_done')

    widget_control, help_base, /realize
    xmanager, self.xname+'_help', help_base, /no_block
    widget_control, help_base, set_uvalue = {object:self, method: 'help_event'}
    widget_control, help_base, event_pro='GPItvo_subwindow_event_handler'
  endif

end

;----------------------------------------------------------------------

pro GPItv::help_event, event

  @gpitv_err

  widget_control, event.id, get_uvalue = uvalue

  ;;check for resize event
  havex = where(strcmp(tag_names(event),'X'),ct)
  if ct gt 0 then begin
    widget_control,(*self.state).helptext_id,scr_xsize=event.X,scr_ysize=event.Y
  endif else begin
    case uvalue of
      'help_done': widget_control, event.top, /destroy
      else:
    endcase
  endelse

end

;----------------------------------------------------------------------
;      Routines for displaying image statistics
;----------------------------------------------------------------------

pro GPItv::stats_refresh

  ; Calculate box statistics and update the results


  bx = round(((*self.state).xstatboxsize - 1) / 2)
  by = round(((*self.state).ystatboxsize - 1) / 2)

  xmin = 0 > ((*self.state).cursorpos[0] - bx) < ((*self.state).image_size[0] - 1)
  xmax = 0 > ((*self.state).cursorpos[0] + bx) < ((*self.state).image_size[0] - 1)
  ymin = 0 > ((*self.state).cursorpos[1] - by) < ((*self.state).image_size[1] - 1)
  ymax = 0 > ((*self.state).cursorpos[1] + by) < ((*self.state).image_size[1] - 1)

  xmin = round(xmin)
  xmax = round(xmax)
  ymin = round(ymin)
  ymax = round(ymax)

  cut = float((*self.images.main_image)[xmin:xmax, ymin:ymax])
  npix = (xmax - xmin + 1) * (ymax - ymin + 1)

  cutmin = min(cut, max=maxx, /nan)
  cutmax = maxx
  cutmean = mean(cut, /nan, /double)
  cutmedian = median(cut)
  cutstddev = stddev(cut, /nan, /double)

  widget_control, (*self.state).xstatbox_id, set_value=(*self.state).xstatboxsize
  widget_control, (*self.state).ystatbox_id, set_value=(*self.state).ystatboxsize
  widget_control, (*self.state).statxcenter_id, set_value = (*self.state).cursorpos[0]
  widget_control, (*self.state).statycenter_id, set_value = (*self.state).cursorpos[1]

  tmp_string = strcompress('# Pixels in Box:  ' + string(npix))
  widget_control, (*self.state).stat_npix_id, set_value = tmp_string
  tmp_string = strcompress('Min:  ' + string(cutmin, format='(g12.6)'))
  widget_control, (*self.state).statbox_min_id, set_value = tmp_string
  tmp_string = strcompress('Max:  ' + string(cutmax, format='(g12.6)'))
  widget_control, (*self.state).statbox_max_id, set_value = tmp_string
  tmp_string = strcompress('Mean:  ' + string(cutmean, format='(g12.6)'))
  widget_control, (*self.state).statbox_mean_id, set_value = tmp_string
  tmp_string = strcompress('Median:  ' + string(cutmedian, format='(g12.6)'))
  widget_control, (*self.state).statbox_median_id, set_value = tmp_string
  tmp_string = strcompress('StdDev:  ' + string(cutstddev, format='(g12.6)'))
  widget_control, (*self.state).statbox_stdev_id, set_value = tmp_string
  void=where(~FINITE(cut), cnan)
  tmp_string = strcompress('NbNan:  ' + string(cnan))
  widget_control, (*self.state).statbox_nbnan_id, set_value = tmp_string

  self->tvstats

end

;----------------------------------------------------------------------

pro GPItv::stats_event, event

  @gpitv_err

  widget_control, event.id, get_uvalue = uvalue

  case uvalue of

    'xstatbox': begin
      (*self.state).xstatboxsize = long(event.value) > 3
      if ( ((*self.state).xstatboxsize / 2 ) EQ $
        round((*self.state).xstatboxsize / 2.)) then $
        (*self.state).xstatboxsize = (*self.state).xstatboxsize + 1
      if ((*self.state).stat_xyresize eq 1) then $
        (*self.state).ystatboxsize = (*self.state).xstatboxsize
      self->stats_refresh
    end

    'ystatbox': begin
      (*self.state).ystatboxsize = long(event.value) > 3
      if ( ((*self.state).ystatboxsize / 2 ) EQ $
        round((*self.state).ystatboxsize / 2.)) then $
        (*self.state).ystatboxsize = (*self.state).ystatboxsize + 1
      if ((*self.state).stat_xyresize eq 1) then $
        (*self.state).xstatboxsize = (*self.state).ystatboxsize
      self->stats_refresh
    end

    'statxcenter': begin
      (*self.state).cursorpos[0] = 0 > long(event.value) < ((*self.state).image_size[0] - 1)
      self->stats_refresh
    end

    'statycenter': begin
      (*self.state).cursorpos[1] = 0 > long(event.value) < ((*self.state).image_size[1] - 1)
      self->stats_refresh
    end

    'statxyresize': begin
      widget_control, (*self.state).stat_xyresize_button_id
      if ((*self.state).stat_xyresize eq 1) then (*self.state).stat_xyresize = 0 $
      else (*self.state).stat_xyresize = 1
    end

    'showstatzoom': begin
      widget_control, (*self.state).showstatzoom_id, get_value=val
      case val of
        'Show Region': begin
          widget_control, (*self.state).statzoom_widget_id, $
            xsize=(*self.state).statzoom_size, ysize=(*self.state).statzoom_size
          widget_control, (*self.state).showstatzoom_id, $
            set_value='Hide Region'
        end
        'Hide Region': begin
          widget_control, (*self.state).statzoom_widget_id, $
            xsize=1, ysize=1
          widget_control, (*self.state).showstatzoom_id, $
            set_value='Show Region'
        end
      endcase
      self->stats_refresh
    end

    'stats_hist': begin

      x1 = (*self.state).cursorpos[0] - ((*self.state).xstatboxsize/2)
      x2 = (*self.state).cursorpos[0] + ((*self.state).xstatboxsize/2)
      y1 = (*self.state).cursorpos[1] - ((*self.state).ystatboxsize/2)
      y2 = (*self.state).cursorpos[1] + ((*self.state).ystatboxsize/2)

      if (not (xregistered(self.xname+'_lineplot', /noshow))) then begin
        self->lineplot_init
      endif

      (*self.state).plot_coord = (*self.state).cursorpos
      widget_control, (*self.state).x1_pix_id, set_value=x1
      widget_control, (*self.state).x2_pix_id, set_value=x2
      widget_control, (*self.state).y1_pix_id, set_value=y1
      widget_control, (*self.state).y2_pix_id, set_value=y2
      hist_image = (*self.images.main_image)[x1:x2,y1:y2]

      (*self.state).lineplot_xmin = min(hist_image)
      (*self.state).lineplot_xmax = max(hist_image)
      (*self.state).lineplot_ymin = 0.
      (*self.state).binsize = ((*self.state).lineplot_xmax - (*self.state).lineplot_xmin) * 0.01
      (*self.state).binsize = (*self.state).binsize > $
        (((*self.state).lineplot_xmax - (*self.state).lineplot_xmin) * 1.0e-5)
      if (*self.state).binsize gt 1 then  (*self.state).binsize = fix((*self.state).binsize)

      ;Set plot window before calling plothist to get histogram ranges
      self->setwindow, (*self.state).lineplot_window_id
      erase

      plothist, hist_image, xhist, yhist, bin=(*self.state).binsize, /NaN, /nodata

      (*self.state).lineplot_ymax = max(yhist) + (0.05*max(yhist))

      widget_control, (*self.state).lineplot_xmin_id, $
        set_value = (*self.state).lineplot_xmin

      widget_control, (*self.state).lineplot_xmax_id, $
        set_value = (*self.state).lineplot_xmax

      widget_control, (*self.state).lineplot_ymin_id, $
        set_value = (*self.state).lineplot_ymin

      widget_control, (*self.state).lineplot_ymax_id, $
        set_value = (*self.state).lineplot_ymax

      widget_control, (*self.state).histplot_binsize_id, set_value=(*self.state).binsize

      self->histplot, /update

    end

    'stats_save': begin
      stats_outfile = dialog_pickfile(filter='*.txt', $
        file='GPItv_stats.txt', get_path = tmp_dir, $
        title='Please Select File to Append Stats')

      IF (strcompress(stats_outfile, /remove_all) EQ '') then RETURN

      IF (stats_outfile EQ tmp_dir) then BEGIN
        self->message, 'Must indicate filename to save.', $
          msgtype = 'error', /window
        return
      ENDIF

      openw, lun, stats_outfile, /get_lun, /append

      widget_control, (*self.state).stat_npix_id, get_value = npix_str
      widget_control, (*self.state).statbox_min_id, get_value = minstat_str
      widget_control, (*self.state).statbox_max_id, get_value = maxstat_str
      widget_control, (*self.state).statbox_mean_id, get_value = meanstat_str
      widget_control, (*self.state).statbox_median_id, get_value = medianstat_str
      widget_control, (*self.state).statbox_stdev_id, get_value = stdevstat_str
      widget_control, (*self.state).statbox_nbnan_id, get_value = nbnanstat_str

      printf, lun, 'GPItv IMAGE BOX STATISTICS--NOTE: IDL Arrays Begin With Index 0'
      printf, lun, '============================================================='
      printf, lun, ''
      printf, lun, 'Image Name: ' + strcompress((*self.state).imagename,/remove_all)
      printf, lun, 'Image Size: ' + strcompress(string((*self.state).image_size[0]) $
        + ' x ' + string((*self.state).image_size[1]))

      printf, lun, 'Image Min: ' + $
        strcompress(string((*self.state).image_min),/remove_all)
      printf, lun, 'Image Max: ' + $
        strcompress(string((*self.state).image_max),/remove_all)

      if ((*self.state).image_size[2] gt 1) then printf, lun, 'Image Slice: ' + $
        strcompress(string((*self.state).cur_image_num),/remove_all)

      printf, lun, ''
      printf, lun, 'Selected Box Statistics:'
      printf, lun, '------------------------'

      printf, lun, 'X-Center: ' + strcompress(string((*self.state).cursorpos[0]), $
        /remove_all)
      printf, lun, 'Y-Center: ' + strcompress(string((*self.state).cursorpos[1]), $
        /remove_all)
      printf, lun, 'Xmin: ' + $
        strcompress(string((*self.state).cursorpos[0] - (*self.state).xstatboxsize/2), $
        /remove_all)
      printf, lun, 'Xmax: ' + $
        strcompress(string((*self.state).cursorpos[0] + (*self.state).xstatboxsize/2), $
        /remove_all)
      printf, lun, 'Ymin: ' + $
        strcompress(string((*self.state).cursorpos[1] - (*self.state).ystatboxsize/2), $
        /remove_all)
      printf, lun, 'Ymax: ' + $
        strcompress(string((*self.state).cursorpos[1] + (*self.state).ystatboxsize/2), $
        /remove_all)

      printf, lun, npix_str
      printf, lun, minstat_str
      printf, lun, maxstat_str
      printf, lun, meanstat_str
      printf, lun, medianstat_str
      printf, lun, stdevstat_str
      printf, lun, nbnanstat_str
      printf, lun, ''

      close, lun
      free_lun, lun

    end

    'stats_done': widget_control, event.top, /destroy
    else:
  endcase


end

;----------------------------------------------------------------------

pro GPItv::showstats

  ; Brings up a widget window for displaying image statistics


  (*self.state).cursorpos = (*self.state).coord

  if (not (xregistered(self.xname+'_stats'))) then begin


    if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
    stats_base = $
      widget_base(group_leader = (*self.state).base_id, $
      /column, $
      /base_align_center, $
      title = title_base+' image statistics', $
      uvalue = 'stats_base')
    (*self.state).stats_base_id = stats_base

    stats_nbase = widget_base(stats_base, /row, /base_align_center)
    stats_base1 = widget_base(stats_nbase, /column, frame=1)
    stats_base2 = widget_base(stats_nbase, /column)
    stats_base2a = widget_base(stats_base2, /column, frame=1)
    stats_zoombase = widget_base(stats_base, /column)

    tmp_string = strcompress('Image size:  ' + $
      string((*self.state).image_size[0]) + $
      ' x ' + $
      string((*self.state).image_size[1]))

    size_label = widget_label(stats_base1, value = tmp_string, /align_left)

    tmp_string = strcompress('Image Min:  ' + string((*self.state).image_min))
    min_label= widget_label(stats_base1, value = tmp_string, /align_left)
    tmp_string = strcompress('Image Max:  ' + string((*self.state).image_max))
    max_label= widget_label(stats_base1, value = tmp_string, /align_left)

    (*self.state).xstatbox_id = $
      cw_field(stats_base1, $
      /long, $
      /return_events, $
      title = 'Box Size (X) for Stats:', $
      uvalue = 'xstatbox', $
      value = (*self.state).xstatboxsize, $
      xsize = 5)

    (*self.state).ystatbox_id = $
      cw_field(stats_base1, $
      /long, $
      /return_events, $
      title = 'Box Size (Y) for Stats:', $
      uvalue = 'ystatbox', $
      value = (*self.state).ystatboxsize, $
      xsize = 5)

    (*self.state).statxcenter_id = $
      cw_field(stats_base1, $
      /long, $
      /return_events, $
      title = 'Box X Center:', $
      uvalue = 'statxcenter', $
      value = (*self.state).cursorpos[0], $
      xsize = 5)

    (*self.state).statycenter_id = $
      cw_field(stats_base1, $
      /long, $
      /return_events, $
      title = 'Box Y Center:', $
      uvalue = 'statycenter', $
      value = (*self.state).cursorpos[1], $
      xsize = 5)

    statxyresize_id = $
      widget_base(stats_base1, $
      row = 1, $
      /nonexclusive)

    (*self.state).stat_xyresize_button_id = $
      widget_button(statxyresize_id, $
      value = 'Square Box Statistics', $
      uvalue = 'statxyresize')

    tmp_string = strcompress('# Pixels in Box:  ' + string(100000))
    (*self.state).stat_npix_id = widget_label(stats_base2a, value = tmp_string,$
      /align_left)
    tmp_string = strcompress('Min:  ' + '0.00000000000')
    (*self.state).statbox_min_id = widget_label(stats_base2a, value = tmp_string,$
      /align_left)
    tmp_string = strcompress('Max:  ' + '0.00000000000')
    (*self.state).statbox_max_id = widget_label(stats_base2a, value = tmp_string, $
      /align_left)
    tmp_string = strcompress('Mean:  ' + '0.00000000000')
    (*self.state).statbox_mean_id = widget_label(stats_base2a, value = tmp_string, $
      /align_left)
    tmp_string = strcompress('Median:  ' + '0.00000000000')
    (*self.state).statbox_median_id = widget_label(stats_base2a, value = tmp_string, $
      /align_left)
    tmp_string = strcompress('StdDev:  ' + '0.00000000000')
    (*self.state).statbox_stdev_id = widget_label(stats_base2a, value = tmp_string, $
      /align_left)
    tmp_string = strcompress('NbNan:  ' + '0000')
    (*self.state).statbox_nbnan_id = widget_label(stats_base2a, value = tmp_string, $
      /align_left)

    (*self.state).showstatzoom_id = widget_button(stats_base2, $
      value = 'Hide Region', uvalue = 'showstatzoom')

    stat_hist = widget_button(stats_base2, value = 'Histogram Pixels', $
      uvalue = 'stats_hist')

    stat_save = widget_button(stats_base2, value = 'Save Stats', $
      uvalue = 'stats_save')

    stat_done = $
      widget_button(stats_base2, $
      value = 'Done', $
      uvalue = 'stats_done')

    (*self.state).statzoom_widget_id = widget_draw(stats_zoombase, $
      xsize = (*self.state).statzoom_size, ysize = (*self.state).statzoom_size)

    widget_control, statxyresize_id, set_button = (*self.state).stat_xyresize

    widget_control, stats_base, /realize

    xmanager, self.xname+'_stats', stats_base, /no_block
    widget_control, stats_base, set_uvalue = {object:self, method: 'stats_event'}
    widget_control, stats_base, event_pro = 'GPItvo_subwindow_event_handler'


    widget_control, (*self.state).statzoom_widget_id, get_value = tmp_val
    (*self.state).statzoom_window_id = tmp_val

    self->resetwindow

  endif

  self->stats_refresh

end

;---------------------------------------------------------------------

pro GPItv::showstats3d_event, event

  ;event handler for showstats3d

  @gpitv_err

  xmin=(*self.state).stat3dminmax[0]
  xmax=(*self.state).stat3dminmax[1]
  ymin=(*self.state).stat3dminmax[2]
  ymax=(*self.state).stat3dminmax[3]

  widget_control, event.id, get_uvalue = uvalue

  case uvalue of
    'im_slider1': begin
      self->stats3d_refresh
    end
    'im_slider2': begin
      self->stats3d_refresh
    end
    'done':  begin
      widget_control, event.top, /destroy
      self->refresh
    end

    'refresh': begin
      ;refresh rectangle

      self->refresh
      ;calculate box size
      xsize=abs((*self.state).s3sel[2]-(*self.state).s3sel[0])
      ysize=abs((*self.state).s3sel[3]-(*self.state).s3sel[1])

      if ((*self.state).s3sel[1] lt (*self.state).s3sel[3]) then begin
        tmp=(*self.state).s3sel[1]
        (*self.state).s3sel[1]=(*self.state).s3sel[3]
        (*self.state).s3sel[3]=tmp
      endif

      if ((*self.state).s3sel[0] gt (*self.state).s3sel[2]) then begin
        tmp=(*self.state).s3sel[0]
        (*self.state).s3sel[0]=(*self.state).s3sel[2]
        (*self.state).s3sel[2]=tmp
      endif

      s=(*self.state).s3sel
      r=[0, 0, s[0], s[1], s[0]+xsize, s[1], s[2], s[3], s[0], s[1]-ysize]

      ;get draw widget id, draw box
      self->setwindow, (*self.state).draw_window_id
      self->display_box, r
    end

    ;update box size
    'xsize': begin
      widget_control, event.id, get_value=xsize

      ;check if entered boxsize is even
      if (xsize mod 2) eq 0 then xsize=xsize+1

      ;check if entered boxsize is smaller than image
      if (xsize gt (*self.state).image_size[0]) then xsize=(*self.state).image_size[0]

      ;update widget
      widget_control, event.id, set_value=xsize
      (*self.state).stat3dbox[0]=xsize
      self->stats3d_refresh
    end

    'ysize': begin
      widget_control, event.id, get_value=ysize

      ;check if entered boxsize is even
      if (ysize mod 2) eq 0 then ysize=ysize+1

      ;check if entered boxsize is smaller than image
      if (ysize gt (*self.state).image_size[1]) then ysize=(*self.state).image_size[1]

      ;update widget
      widget_control, event.id, set_value=ysize
      (*self.state).stat3dbox[1]=ysize
      self->stats3d_refresh
    end

    ;update box center
    'xcenter': begin
      widget_control, event.id, get_value=xcenter

      ;check that new center is in image
      if (xcenter gt (*self.state).image_size[0]) then xcenter=(*self.state).image_size[0]
      (*self.state).stat3dcenter[0]=xcenter

      ;update widget
      widget_control, event.id, set_value=xcenter
      self->stats3d_refresh
    end

    'ycenter': begin
      widget_control, event.id, get_value=ycenter

      ;check that new center is in image
      if (ycenter gt (*self.state).image_size[1]) then ycenter=(*self.state).image_size[1]
      (*self.state).stat3dcenter[1]=ycenter

      ;update widget
      widget_control, event.id, set_value=ycenter
      self->stats3d_refresh
    end

    'save': begin
      widget_control, (*self.state).data_table, get_value=data

      ;let user choose filename
      res=dialog_pickfile(dialog_parent=(*self.state).base_id, $
        file='stats3d.dat', $
        get_path = tmp_dir, $
        title='Please Select File to save 3dStats')

      ;check that selected file is ok
      if (strcompress(res, /remove_all) eq '') then return

      if (res eq tmp_dir) then begin
        self->message, msgtype = 'error', 'Must select a filename!',/window
        return
      endif

      ;open output
      get_lun, u
      openw, u, res

      ;begin writing

      printf, u, '#GPItv IMAGE CUBE STATISTICS--NOTE: IDL Arrays Begin With Index 0'
      printf, u, '#============================================================='
      printf, u, '#'
      printf, u, '#Image Size:  '+strtrim((*self.state).image_size[0],1)+' x '+strtrim((*self.state).image_size[1],1)+  ' x '+strtrim((*self.state).image_size[2],1)
      printf, u, '#File Name,  Minimum, Maximum, Mean, Median, Std. dev., Nb Nan'


      data1=strarr(7, (*self.state).image_size[2])
      for i=0, (*self.state).image_size[2]-1 do begin
        data1[0,i]=strtrim(*self.images.names_stack[i],2)
        data1[1,i]=data[0,i]
        data1[2,i]=data[1,i]
        data1[3,i]=data[2,i]
        data1[4,i]=data[3,i]
        data1[5,i]=data[4,i]
        data1[6,i]=data[5,i]
      endfor

      printf, u, format='(A35, T40, F12.4, T57, F12.4, T74, F12.4, T91, F12.4, T108, F12.4, T108, I5)', data1

      ;close up
      close, u
      free_lun, u
    end

    else: begin
      self->message, msgtype='error', 'ERROR: Problem with showstat3d.'
    end
  endcase

end

;---------------------------------------------------------------------

pro GPItv::stats3d_refresh

  ;;refreshes stat3d


  ;preparing the center & size of window
  (*self.state).cursorpos=(*self.state).coord

  bx = round(((*self.state).stat3dbox[0] - 1) / 2)
  by = round(((*self.state).stat3dbox[1] - 1) / 2)

  xmin = 0 > ((*self.state).stat3dcenter[0] - bx) < ((*self.state).image_size[0] - 1)
  xmax = 0 > ((*self.state).stat3dcenter[0] + bx) < ((*self.state).image_size[0] - 1)
  ymin = 0 > ((*self.state).stat3dcenter[1] - by) < ((*self.state).image_size[1] - 1)
  ymax = 0 > ((*self.state).stat3dcenter[1] + by) < ((*self.state).image_size[1] - 1)


  xmin = round(xmin)
  xmax = round(xmax)
  ymin = round(ymin)
  ymax = round(ymax)

  (*self.state).stat3dminmax[0]=xmin
  (*self.state).stat3dminmax[1]=xmax
  (*self.state).stat3dminmax[2]=ymin
  (*self.state).stat3dminmax[3]=ymax

  ;refreshing screens
  ;1st screen
  widget_control, (*self.state).screen1, get_value=scr1
  widget_control, (*self.state).im_slider1, get_value=im1_num
  wset, scr1

  ;;before bytscl, assure that values are gt 1
  im=congrid((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, im1_num], 256, 256)
  tvscl, bytscl((100.*256.*256./total(im,/double, /nan))*im,top=31)


  ;2nd screen
  widget_control, (*self.state).screen2, get_value=scr2
  widget_control, (*self.state).im_slider2, get_value=im2_num
  wset, scr2
  ;tvscl, bytscl(congrid(*self.images.main_image_stack(xmin:xmax, ymin:ymax, im2_num), 256, 256),31)
  ;;before bytscl, assure that values are gt 1
  im=congrid((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, im2_num], 256, 256)
  tvscl, bytscl((100.*256.*256./total(im,/double, /nan))*im,top=31)

  ;refreshing data
  data=dblarr(6, (*self.state).image_size[2])

  for i=0, (*self.state).image_size[2]-1 do begin
    data[0,i]=min((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i], /nan)
    data[1,i]=max((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i], /nan)
    data[2,i]=mean((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i], /nan)
    data[3,i]=median((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i])
    data[4,i]=stddev((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i], /nan)
    void=where(~FINITE((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i]), cnan)
    data[5,i]=cnan
  endfor

  widget_control, (*self.state).data_table, set_value=data
end

;---------------------------------------------------------------------

pro GPItv::showstats3d

  ;; Brings up a widget window for displaying image statistics


  ;;quit if there is no image
  n_images=(*self.state).image_size[2]
  if (n_images eq 0) then return
  n_stats=6

  ;; preparing the center & size of window
  (*self.state).cursorpos=(*self.state).coord

  bx = round(((*self.state).stat3dbox[0] - 1) / 2)
  by = round(((*self.state).stat3dbox[1] - 1) / 2)

  xmin = 0 > ((*self.state).stat3dcenter[0] - bx) < ((*self.state).image_size[0] - 1)
  xmax = 0 > ((*self.state).stat3dcenter[0] + bx) < ((*self.state).image_size[0] - 1)
  ymin = 0 > ((*self.state).stat3dcenter[1] - by) < ((*self.state).image_size[1] - 1)
  ymax = 0 > ((*self.state).stat3dcenter[1] + by) < ((*self.state).image_size[1] - 1)

  xmin = round(xmin)
  xmax = round(xmax)
  ymin = round(ymin)
  ymax = round(ymax)

  if (xmin eq xmax) || (ymin eq ymax) then return
  if ((*self.state).mosaic eq 1) then return

  ;store box info
  (*self.state).stat3dminmax=[xmin, xmax, ymin, ymax]


  ;;if none exists then create one
  if (not (xregistered(self.xname+'_showstats3d'))) then begin
    ;;main base for stat3d
    res=widget_info((*self.state).base_id, /geometry)
    stats_base = $
      widget_base(/floating, $
      group_leader = (*self.state).base_id, $
      /column, $
      /base_align_left, $
      title = 'GPItv 3d image statistics', $
      uvalue = 'stats_base', $
      xoffset=res.xoffset+650)

    row1=widget_base(stats_base, column=2)
    row2=widget_base(stats_base, column=3, /align_left)
    column1=widget_base(row1, frame=2, /align_left, /column)
    column2=widget_base(row1, frame=2, /align_left, /column)
    column3=widget_base(row2, frame=2, /align_left, /column)
    column4=widget_base(row2, frame=2, /align_left, /column)
    column5=widget_base(row2, frame=2, /align_left, /column)

    tmp_string='Image Cube Size: '+strtrim((*self.state).image_size[0],1)+ $
      ' x '+strtrim((*self.state).image_size[1],1)+ $
      ' x '+strtrim((*self.state).image_size[2],1)
    title_field=widget_label(column1, value=tmp_string)

    ;;box size forms
    xsize=cw_field(column1, $
      value=(*self.state).stat3dbox[0], $
      title='Box size (x) = ', $
      uvalue='xsize', $
      xsize=6, $
      /return_events)

    ysize=cw_field(column1, $
      value=(*self.state).stat3dbox[1], $
      title='Box size (y) = ', $
      uvalue='ysize', $
      xsize=6, $
      /return_events)

    xcenter=cw_field(column1, $
      value=(*self.state).stat3dcenter[0], $
      title='Box center (x) = ', $
      uvalue='xcenter', $
      xsize=6, $
      /return_events)

    ycenter=cw_field(column1, $
      value=(*self.state).stat3dcenter[1], $
      title='Box center (y) = ', $
      uvalue='ycenter', $
      xsize=6, $
      /return_events)

    (*self.state).stat3d_done=widget_button(column1, $
      /align_center, $
      value='Done', $
      uvalue='done')
    (*self.state).stat3d_refresh=widget_button(column1, $
      /align_center, $
      value='Refresh Screen', $
      uvalue='refresh')
    save_stats=widget_button(column1, $
      /align_center, $
      value='Save Cube Statistics', $
      uvalue='save')

    title_field1=widget_label(column2, value='Image Cube Statistics')

    ;;gathering data, preparing table
    rows=strarr(n_images)
    cols=['Minimum','Maximum', 'Mean', 'Median','Std. dev.','Nb Nan']

    data=dblarr(n_stats, n_images)

    for i=0, n_images-1 do begin
      rows[i]='Image #'+strtrim(i+1,1)
      data[0,i]=min((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i], /nan)
      data[1,i]=max((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i], /nan)
      data[2,i]=mean((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i], /nan)
      data[3,i]=median((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i])
      data[4,i]=stddev((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i], /nan)
      void=where(~FINITE((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, i]), cnan)
      data[5,i]=cnan
    endfor

    ;;making table
    (*self.state).data_table=widget_table(column2, $
      xsize=6, $
      column_labels=cols, $
      row_labels=rows, $
      ;ysize=8,$
      y_scroll_size=10, $
      value=data, $
      /scroll)

    ;;display
    (*self.state).screen1=widget_draw(column3, $
      xsize=256, $
      ysize=256, $
      frame=1)

    (*self.state).im_slider1=widget_slider(column3, $
      minimum=0, $
      maximum=n_images-1, $
      value=0, $
      uvalue='im_slider1', $
      title='Image #')

    (*self.state).screen2=widget_draw(column4, $
      xsize=256, $
      ysize=256, $
      frame=1)

    (*self.state).im_slider2=widget_slider(column4, $
      minimum=0, $
      maximum=n_images-1, $
      value=0, $
      uvalue='im_slider2', $
      title='Image #')

    (*self.state).screen3=widget_draw(column5, $
      xsize=256, $
      ysize=256, $
      frame=1, $
      uvalue=scr2)

    widget_control, stats_base, /realize

    xmanager, self.xname+'_showstats3d', stats_base, /no_block
    widget_control, stats_base, set_uvalue = {object:self, method: 'showstats3d_event'}
    widget_control, stats_base, event_pro = 'GPItvo_subwindow_event_handler'

    self->resetwindow

  endif

  ;showing initial screens
  widget_control, (*self.state).screen3, get_value=scr3
  wset, scr3
  tvscl, bytscl(congrid((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, 0], 256, 256),top=31), /nan

  widget_control, (*self.state).screen1, get_value=scr1
  wset, scr1
  ;tvscl, congrid(*self.images.main_image_stack(xmin:xmax, ymin:ymax, 0), 256, 256)
  tvscl, bytscl(congrid((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, 0], 256, 256),top=31), /nan

  widget_control, (*self.state).screen2, get_value=scr2
  wset, scr2
  ;tvscl, congrid(*self.images.main_image_stack(xmin:xmax, ymin:ymax, 0), 256, 256)
  tvscl, bytscl(congrid((*self.images.main_image_stack)[xmin:xmax, ymin:ymax, 0], 256, 256),top=31), /nan

  self->stats3d_refresh

end
;---------------------------------------------------------------------

pro GPItv::tvstats

  ; Routine to display the zoomed region around a stats point


  self->setwindow, (*self.state).statzoom_window_id
  erase

  x = round((*self.state).cursorpos[0])
  y = round((*self.state).cursorpos[1])

  xboxsize = ((*self.state).xstatboxsize - 1) / 2
  yboxsize = ((*self.state).ystatboxsize - 1) / 2

  xsize = (*self.state).xstatboxsize
  ysize = (*self.state).ystatboxsize

  image = bytarr(xsize,ysize)

  xmin = (0 > (x - xboxsize))
  xmax = ((x + xboxsize) < ((*self.state).image_size[0] - 1) )
  ymin = (0 > (y - yboxsize) )
  ymax = ((y + yboxsize) < ((*self.state).image_size[1] - 1))

  startx = abs( (x - xboxsize) < 0 )
  starty = abs( (y - yboxsize) < 0 )

  image[startx, starty] = (*self.images.scaled_image)[xmin:xmax, ymin:ymax]

  xs = indgen(xsize) + xmin - startx
  ys = indgen(ysize) + ymin - starty

  xs_delta = (xs[xsize-1] - xs[0]) / float(xsize - 1.0)
  ys_delta = (ys[ysize-1] - ys[0]) / float(ysize - 1.0)
  x_ran = [xs[0]-xs_delta/2.0,xs[xsize-1]+xs_delta/2.0]
  y_ran = [ys[0]-ys_delta/2.0,ys[ysize-1]+ys_delta/2.0]

  dev_width = 0.8 * (*self.state).statzoom_size
  dev_pos = [0.15 * (*self.state).statzoom_size, $
    0.15 * (*self.state).statzoom_size, $
    0.95 * (*self.state).statzoom_size, $
    0.95 * (*self.state).statzoom_size]

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
  xsize = Float(sz[1])       ;image width
  ysize = Float(sz[2])       ;image height
  dev_width = dev_pos[2] - dev_pos[0] + 1
  dev_width = dev_pos[3] - dev_pos[1] + 1

  tv, image, /device, dev_pos[0], dev_pos[1], $
    xsize=dev_pos[2]-dev_pos[0], $
    ysize=dev_pos[3]-dev_pos[1]

  plot, [0, 1], /noerase, /nodata, xstyle = 1, ystyle = 1, $
    /device, position = dev_pos, color=7, $
    xrange = x_ran, yrange = y_ran, xtitle='X', ytitle='Y'

  self->resetwindow
end
;----------------------------------------------------------------------
;-- Image histograms and recommended exposure times -------------------
;----------------------------------------------------------------------

pro GPItv::showhist

  ; Brings up a widget window for displaying image histogram


  (*self.state).cursorpos = (*self.state).coord

  if (not (xregistered(self.xname+'_hist'))) then begin


    if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
    stats_base = $
      widget_base(group_leader = (*self.state).base_id, $
      /column, $
      /base_align_center, $
      title = title_base+' image histogram', $
      uvalue = 'histogram_base')
    (*self.state).histplot_base_id = stats_base

    stats_nbase = widget_base(stats_base, /row, /base_align_center)
    stats_base1 = widget_base(stats_nbase, /column, frame=1)
    stats_base2 = widget_base(stats_nbase, /column)
    stats_base2a = widget_base(stats_base2, /column, frame=1)
    stats_zoombase = widget_base(stats_base, /column)

    tmp_string = strcompress('Image size:  ' + $
      string((*self.state).image_size[0]) + $
      ' x ' + $
      string((*self.state).image_size[1]))

    size_label = widget_label(stats_base1, value = tmp_string, /align_left)

    tmp_string = strcompress('Image Min:  ' + string((*self.state).image_min))
    min_label= widget_label(stats_base1, value = tmp_string, /align_left)
    tmp_string = strcompress('Image Max:  ' + string((*self.state).image_max))
    max_label= widget_label(stats_base1, value = tmp_string, /align_left)

    tmp_string0 = 'Mean :   ' + '         '
    tmp_string1 = '90% <:   ' + '         '
    tmp_string2 = '95% <:   ' + '         '
    tmp_string3 = '99% <:   ' + '         '
    tmp_string4 = '99.9% <:   ' + '         '
    tmp_string5 = 'Exp Time to Full Well for 99.5% :'
    tmp_string6 = ' TBD s                           '

    (*self.state).stat_npix_id =    widget_label(stats_base2a, value = tmp_string0, /align_left)
    (*self.state).statbox_min_id =  widget_label(stats_base2a, value = tmp_string1, /align_left)
    (*self.state).statbox_max_id =  widget_label(stats_base2a, value = tmp_string2,  /align_left)
    (*self.state).statbox_mean_id = widget_label(stats_base2a, value = tmp_string3,  /align_left)
    (*self.state).statbox_median_id= widget_label(stats_base2a, value = tmp_string4,  /align_left)
    (*self.state).statbox_stdev_id = widget_label(stats_base2a, value = tmp_string5,  /align_left)
    (*self.state).statbox_nbnan_id = widget_label(stats_base2a, value = tmp_string6,  /align_left)

    ;    stat_save = widget_button(stats_base2, value = 'Save Stats', $
    ;          uvalue = 'stats_save')

    hist_done = $
      widget_button(stats_base2, $
      value = 'Done', $
      uvalue = 'hist_done')

    (*self.state).histplot_widget_id = widget_draw(stats_zoombase, $
      xsize = (*self.state).statzoom_size*2, ysize = fix((*self.state).statzoom_size)*1.5)

    widget_control, stats_base, /realize

    xmanager, self.xname+'_hist', stats_base, /no_block
    widget_control, stats_base, set_uvalue = {object:self, method: 'hist_event'}
    widget_control, stats_base, event_pro = 'GPItvo_subwindow_event_handler'


    widget_control, (*self.state).histplot_widget_id, get_value = tmp_val
    (*self.state).histplot_window_id = tmp_val

    self->resetwindow

  endif

  self->hist_refresh

end


;---------------
pro GPItv::hist_refresh

  ; Calculate histogram and update the results


  self->setwindow, (*self.state).histplot_window_id
  erase

  im = (*self.images.main_image)

  sz = size(im)
  if sz[1] eq 2048 and sz[2] eq 2048 then begin
    ; H2RG has ref pixels around the edge - ignore those
    ; custom for GPI
    im = im[4:2043, 4:2043]
  endif

  wg = where(finite(im))
  im = im[wg]

  arrmin = min( im, MAX = arrmax)
  if  ( arrmin EQ arrmax ) then begin
    plot, [0,1],/nodata
    xyouts, 0.1, 0.5, "ERROR: Image must contain distinct values!Cto plot a histogram.", charsize=2
  endif else begin

    plothist, im,/ylog, /xlog, $
      xtitle="Pixel values", ytitle='Number of pixels', /nan
  endelse



  sorted = im[sort(im)]

  npix = n_elements(im)
  ;print, "90%: "+strc(sorted[npix*0.9])
  ;print, "95%: "+strc(sorted[npix*0.95])
  ;print, "99%: "+strc(sorted[npix*0.99])

  tmp_string0 = 'Mean:    ' + sigfig(mean(im[wg]),4)
  tmp_string1 = '90% <:   ' + sigfig(sorted[npix*0.90], 4)
  tmp_string2 = '95% <:   ' + sigfig(sorted[npix*0.95], 4)
  tmp_string3 = '99% <:   ' + sigfig(sorted[npix*0.99], 4)
  tmp_string4 = '99.5% <: ' + sigfig(sorted[npix*0.995], 4)
  tmp_string5 = 'Exp Time to Full Well for 99.5% :'

  vals = [0.90, 0.95, 0.99, 0.995]
  for i=0, n_elements(vals)-1 do begin
    pixval = sorted[npix*vals[i]]
    if i eq n_elements(vals)-1 then color='cyan' else color='red'
    oplot, [pixval, pixval], [0.00001, 1e9], /line, color=fsc_color(color)
  endfor

  self->resetwindow

  if ptr_valid ((*self.state).exthead_ptr) then begin
    itime = sxpar( *((*self.state).exthead_ptr), 'ITIME', count=ct)
  endif else ct=0

  if ct eq 0 then begin
    tmp_string6 = '  ERROR: cannot find ITIME header'
  endif else begin
    satcounts = 33000. ;  HARD CODED FOR GPI H2RG  - about 100 k e- full well, gain of 3.

    full_well_itime = satcounts / sorted[npix*0.995] * itime
    tmp_string6 = '       '+sigfig(full_well_itime, 3) + ' s'

  endelse


  widget_control, (*self.state).stat_npix_id, set_value = tmp_string0
  widget_control, (*self.state).statbox_min_id, set_value = tmp_string1
  widget_control, (*self.state).statbox_max_id, set_value = tmp_string2
  widget_control, (*self.state).statbox_mean_id, set_value = tmp_string3
  widget_control, (*self.state).statbox_median_id, set_value = tmp_string4
  widget_control, (*self.state).statbox_stdev_id, set_value = tmp_string5
  widget_control, (*self.state).statbox_nbnan_id, set_value = tmp_string6


  return


end

pro GPItv::hist_event, event

  @gpitv_err

  widget_control, event.id, get_uvalue = uvalue

  case uvalue of

    'hist_done': widget_control, event.top, /destroy
    else:
  endcase


end



;----------------------------------------------------------------------
;        aperture photometry and radial profile routines
;---------------------------------------------------------------------

pro GPItv::imcenterf, xcen, ycen

  ; program to calculate the center of mass of an image around
  ; the point (x,y), return the answer in (xcen,ycen).
  ;
  ; by M. Liu, adapted for inclusion in GPItv by AJB
  ;
  ; ALGORITHM:
  ;   1. first finds max pixel value in
  ;	   a 'bigbox' box around the cursor
  ;   2. then calculates centroid around the object
  ;   3. iterates, recalculating the center of mass
  ;      around centroid until the shifts become smaller
  ;      than MINSHIFT (0.3 pixels)


  ; iteration controls
  MINSHIFT = 0.3

  ; max possible x or y direction shift
  MAXSHIFT = 3

  ; Bug fix 4/16/2000: added call to round to make sure bigbox is an integer
  bigbox=round(1.5*(*self.state).centerboxsize)

  sz = size(*self.images.main_image)

  ; box size must be odd
  dc = ((*self.state).centerboxsize-1)/2
  if ( (bigbox / 2 ) EQ round(bigbox / 2.)) then bigbox = bigbox + 1
  db = (bigbox-1)/2

  ; need to start with integers
  xx = (*self.state).cursorpos[0]
  yy = (*self.state).cursorpos[1]

  ; first find max pixel in box around the cursor
  x0 = (xx-db) > 0
  x1 = (xx+db) < (sz[1]-1)
  y0 = (yy-db) > 0
  y1 = (yy+db) < (sz[2]-1)
  cut = (*self.images.main_image)[x0:x1,y0:y1]
  cutmax = max(cut)
  w=where(cut EQ cutmax)
  cutsize = size(cut)
  my = (floor(w/cutsize[1]))[0]
  mx = (w - my*cutsize[1])[0]

  xx = mx + x0
  yy = my + y0
  xcen = xx
  ycen = yy

  ; then find centroid
  if  (n_elements(xcen) gt 1) then begin
    xx = round(total(xcen)/n_elements(xcen))
    yy = round(total(ycen)/n_elements(ycen))
  endif

  done = 0
  niter = 1

  ;	cut out relevant portion
  sz = size(*self.images.main_image)
  x0 = round((xx-dc) > 0)		; need the ()'s
  x1 = round((xx+dc) < (sz[1]-1))
  y0 = round((yy-dc) > 0)
  y1 = round((yy+dc) < (sz[2]-1))
  xs = x1 - x0 + 1
  ys = y1 - y0 + 1
  cut = float((*self.images.main_image)[x0:x1, y0:y1])

  ; find x position of center of mass
  cenxx = fltarr(xs, ys, /nozero)
  for i = 0L, (xs-1) do $         ; column loop
    cenxx[i, *] = cut[i, *] * i
  xcen = total(cenxx,/nan) / total(cut,/nan) + x0

  ; find y position of center of mass
  cenyy = fltarr(xs, ys, /nozero)
  for i = 0L, (ys-1) do $         ; row loop
    cenyy[*, i] = cut[*, i] * i
  ycen = total(cenyy,/nan) / total(cut,/nan) + y0

  if (abs(xcen-(*self.state).cursorpos[0]) gt MAXSHIFT) or $
    (abs(ycen-(*self.state).cursorpos[1]) gt MAXSHIFT) then begin
    (*self.state).photwarning = 'Warning: Possible mis-centering?'
  endif

end

;----------------------------------------------------------------------

function GPItv::splinefwhm, rad, prof, splrad, splprof

  ; given a radial profile (counts vs radius) will use
  ; a spline to extract the FWHM
  ;
  ; ALGORITHM
  ;   finds peak in radial profile, then marches along until finds
  ;   where radial profile has dropped to half of that,
  ;   assumes peak value of radial profile is at minimum radius
  ;
  ; original version by M. Liu, adapted for atv by AJB


  nrad = n_elements(rad)

  ; check the peak
  w = where(prof eq max(prof))
  if float(rad[w[0]]) ne min(rad) then begin
    (*self.state).photwarning = 'Warning: Profile peak is off-center!'
    return,-1
  endif

  ; interpolate radial profile at 50 times as many points
  splrad = min(rad) + findgen(nrad*50+1) * (max(rad)-min(rad)) / (nrad*50)
  nspl = n_elements(splrad)

  ; spline the profile
  splprof = spline(rad,prof,splrad)

  ; march along splined profile until cross 0.5*peak value
  found = 0
  i = 0
  repeat begin
    if splprof[i] lt 0.5*max(splprof) then $
      found = 1 $
    else $
      i = i+1
  endrep until ((found) or (i eq nspl))

  if (i lt 2) or (i eq nspl) then begin
    (*self.state).photwarning = 'Warning: Unable to measure FWHM!'
    return,-1
  endif

  ; now interpolate across the 2 points straddling the 0.5*peak
  fwhm = splrad[i]+splrad[i-1]

  return,fwhm
end

;-----------------------------------------------------------------------

pro GPItv::radplotf, x, y, fwhm, ps=ps, enc_ener=enc_ener, out=out

  ; Program to calculate radial profile of an image
  ; given aperture location, range of sizes, and inner and
  ; outer radius for sky subtraction annulus.  Calculates sky by
  ; median.
  ;
  ; original version by M. Liu


  ; set defaults
  inrad = 0.5*sqrt(2)
  outrad = round((*self.state).outersky * 1.2)
  drad=1.
  insky = outrad+drad
  outsky = insky+drad+20.

  ; initialize arrays
  inrad = float(inrad)
  outrad = float(outrad)
  drad = float(drad)
  nrad = ceil((outrad-inrad)/drad) + 1
  out = fltarr(nrad,12)


  ; Added check that "x" and "y" values are finite (IE. not "NaN")

  if not finite(x) then x = 0.0
  if not finite(y) then y = 0.0


  ; extract relevant image subset (may be rectangular), translate coord origin,
  ;   bounded by edges of image
  ;   (there must be a cute IDL way to do this neater)
  sz = size(*self.images.main_image)
  x0 = floor(x-outsky)
  x1 = ceil(x+outsky)   ; one pixel too many?
  y0 = floor(y-outsky)
  y1 = ceil(y+outsky)
  x0 = x0 > 0.0
  x1 = x1 < (sz[1]-1)
  y0 = y0 > 0.0
  y1 = y1 < (sz[2]-1)
  nx = x1 - x0 + 1
  ny = y1 - y0 + 1


  ; trim the image, translate coords
  img = (*self.images.main_image)[x0:x1,y0:y1]
  bdpix=where(~FINITE(img),cnt)
  if cnt gt 0 then img[bdpix]=0
  xcen = x - x0
  ycen = y - y0

  ; for debugging, can make some masks showing different regions
  skyimg = fltarr(nx,ny)			; don't use /nozero!!
  photimg = fltarr(nx,ny)			; don't use /nozero!!

  ; makes an array of (distance)^2 from center of aperture
  ;   where distance is the radial or the semi-major axis distance.
  ;   based on DIST_CIRCLE and DIST_ELLIPSE in Goddard IDL package,
  ;   but deals with rectangular image sections
  distsq = fltarr(nx,ny,/nozero)

  xx = findgen(nx)
  yy = findgen(ny)
  x2 = (xx - xcen)^(2.0)
  y2 = (yy - ycen)^(2.0)
  for i = 0L,(ny-1) do $          ; row loop
    distsq[*,i] = x2 + y2[i]

  ; get sky level by masking and then medianing remaining pixels
  ; note use of "gt" to avoid picking same pixels as flux aperture
  ns = 0
  msky = 0.0
  errsky = 0.0

  in2 = insky^(2.0)
  out2 = outsky^(2.0)
  if (in2 LT max(distsq)) then begin
    w = where((distsq gt in2) and (distsq le out2),ns)
    skyann = img[w]
  endif else begin
    w = where(distsq EQ distsq)
    skyann = img[w]
    (*self.state).photwarning = 'Not enough pixels in sky!'
  endelse

  msky = median(skyann)
  errsky = stddev(skyann)
  skyimg[w] = -5.0
  photimg = skyimg

  errsky2 = errsky * errsky

  out[*,8] = msky
  out[*,9] = ns
  out[*,10]= errsky

  ; now loop through photometry radii, finding the total flux, differential
  ;	flux, and differential average pixel value along with 1 sigma scatter
  ; 	relies on the fact the output array is full of zeroes
  for i = 0,nrad-1 do begin

    dr = drad
    if i eq 0 then begin
      rin =  0.0
      rout = inrad
      rin2 = -0.01
    endif else begin
      rin = inrad + drad *(i-1)
      rout = (rin + drad) < outrad
      rin2 = rin*rin
    endelse
    rout2 = rout*rout

    ; 	get flux and pixel stats in annulus, wary of counting pixels twice
    ;	checking if necessary if there are pixels in the sector
    w = where(distsq gt rin2 and distsq le rout2,np)

    pfrac = 1.0                 ; fraction of pixels in each annulus used

    if np gt 0 then begin
      ann = img[w]
      dflux = total(ann,/nan) * 1./pfrac
      dnpix = np
      dnet = dflux - (dnpix * msky) * 1./pfrac
      davg = dnet / (dnpix * 1./pfrac)
      if np gt 1 then dsig = stddev(ann) else dsig = 0.00

      ;		std dev in each annulus including sky sub error
      derr = sqrt(dsig*dsig + errsky2)

      photimg[w] = rout2


      if finite((rout+rin)/2.0)       then out[i,0]  = (rout+rin)/2.0
      if finite(out[i-1>0,1] + dflux) then out[i,1]  = out[i-1>0,1] + dflux
      if finite(out[i-1>0,2] + dnet)  then out[i,2]  = out[i-1>0,2] + dnet
      if finite(out[i-1>0,3] + dnpix) then out[i,3]  = out[i-1>0,3] + dnpix
      if finite(dflux)                then out[i,4]  = dflux
      if finite(dnpix)                then out[i,5]  = dnpix
      if finite(davg)                 then out[i,6]  = davg
      if finite(dsig)                 then out[i,7]  = dsig
      if finite(derr)                 then out[i,11] = derr
    endif else if (i ne 0) then begin
      if finite(rout)         then out[i,0]   = rout
      if finite(out[i-1,1:3]) then out[i,1:3] = out[i-1,1:3]
      out[i, 4:7] = 0.0
      out[i,11]   = 0.0
    endif else begin
      if finite(rout) then out[i, 0] = rout
    endelse

    ;-------------------------------------------------------PH 29 Aug. 2005

  endfor

  ; fill radpts array after done with differential photometry
  w = where(distsq ge 0.0 and distsq le outrad*outrad)
  radpts = dblarr(2,n_elements(w))
  radpts[0,*] = sqrt(distsq[w])
  radpts[1,*] = img[w]

  ; compute FWHM via spline interpolation of radial profile
  fwhm = self->splinefwhm(out[*,0],out[*,6])


  ;;Encircled Energy
  nr= 2.*double((*self.state).r)
  ee=dblarr(nr)
  for ii=1,nr do begin
    eerad=(double(ii)/double(nr))*double((*self.state).r)
    ee[ii-1]=myaper((img-msky)>0.,xcen,ycen,eerad,mask,imask)
  endfor


  ; plot the results
  if (not (keyword_set(enc_ener))) then begin
    if n_elements(radpts[1, *]) gt 100 then pp = 3 else pp = 1
    void= where(finite(radpts[1, *]),cc)
    if cc gt 1 then begin
      if (not (keyword_set(ps))) then begin
        plot, radpts[0, *], radpts[1, *], /nodata, xtitle = 'Radius (pixels)', $
          ytitle = 'Counts', color=7, charsize=1.2, /ynozero
        oplot, radpts[0, *], radpts[1, *], psym = pp, color=6
        oploterror, out[*, 0], out[*, 6]+out[*, 8], $
          out[*, 11]/sqrt(out[*, 5]), psym=-4, color=7, errcolor=7

      endif else begin

        plot, radpts[0, *], radpts[1, *], /nodata, xtitle = 'Radius (pixels)', $
          ytitle = 'Counts', color=0, charsize=1.2, /ynozero
        ;  oplot, radpts[0, *], radpts[1, *], psym = pp, color=0
        oploterror, out[*, 0], out[*, 6]+out[*, 8], $
          out[*, 11]/sqrt(out[*, 5]), psym=-4, color=0, errcolor=0

      endelse
    endif
  endif else begin
    eerad=((findgen(nr)+1.)/double(nr))*double((*self.state).r)
    plot, eerad, 100.*ee/(ee[nr-1]),  xtitle = 'Radius (pixels)', xrange=[eerad[0],eerad[n_elements(eerad)-1]],yrange=[0.,100.],$
      ytitle = 'Encircled Energy (%)',  charsize=1.2, xstyle=1,ystyle=1;, /ynozero
    plots, [eerad[0],eerad[n_elements(eerad)-1]], 90. , line = 1, color=2, thick=2, psym=0
    xyouts, /data, 0.8*eerad[n_elements(eerad)-1], 85., '90% EE', $
      color=2, charsize=1.
  endelse
end

;-----------------------------------------------------------------------

pro GPItv::apphot_refresh, ps=ps, enc_ener=enc_ener, sav=sav

  ;; Do aperture photometry using idlastro daophot routines.


  if (*self.state).rgb_mode then begin
    self->message, msgtype='warning', "I don't know how to properly do photometry on an RGB cube. Returning."
    return
  endif

  (*self.state).photwarning = 'Warnings: None.'

  ;; Center on the object position nearest to the cursor
  if ((*self.state).centerboxsize GT 0) then begin
    self->imcenterf, x, y
  endif else begin              ; no centering
    x = (*self.state).cursorpos[0]
    y = (*self.state).cursorpos[1]
  endelse

  ;; Make sure that object position is on the image
  x = 0 > x < ((*self.state).image_size[0] - 1)
  y = 0 > y < ((*self.state).image_size[1] - 1)

  if ((x - (*self.state).outersky) LT 0) OR $
    ((x + (*self.state).outersky) GT ((*self.state).image_size[0] - 1)) OR $
    ((y - (*self.state).outersky) LT 0) OR $
    ((y + (*self.state).outersky) GT ((*self.state).image_size[1] - 1)) then $
    (*self.state).photwarning = 'Warning: Sky apertures fall outside image!'

  ;; Condition to test whether phot aperture is off the image
  if (x LT (*self.state).r) OR $
    (((*self.state).image_size[0] - x) LT (*self.state).r) OR $
    (y LT (*self.state).r) OR $
    (((*self.state).image_size[1] - y) LT (*self.state).r) then begin
    flux = -1.
    (*self.state).photwarning = 'Warning: Aperture Outside Image Border!'
  endif

  phpadu = 1.0                  ; don't convert counts to electrons
  apr = [(*self.state).r]
  skyrad = [(*self.state).innersky, (*self.state).outersky]
  ;; Assume that all pixel values are good data
  badpix = [(*self.state).image_min-1, (*self.state).image_max+1]

  if ((*self.state).skytype EQ 1) then begin ; calculate median sky value

    xmin = (x - (*self.state).outersky) > 0
    xmax = (xmin + (2 * (*self.state).outersky + 1)) < ((*self.state).image_size[0] - 1)
    ymin = (y - (*self.state).outersky) > 0
    ymax = (ymin + (2 * (*self.state).outersky + 1)) < ((*self.state).image_size[1] - 1)

    small_image = (*self.images.main_image)[xmin:xmax, ymin:ymax]
    nx = (size(small_image))[1]
    ny = (size(small_image))[2]
    i = lindgen(nx)#(lonarr(ny)+1)
    j = (lonarr(nx)+1)#lindgen(ny)
    xc = x - xmin
    yc = y - ymin

    w = where( (((i - xc)^2 + (j - yc)^2) GE (*self.state).innersky^2) AND $
      (((i - xc)^2 + (j - yc)^2) LE (*self.state).outersky^2),  nw)

    if ((x - (*self.state).outersky) LT 0) OR $
      ((x + (*self.state).outersky) GT ((*self.state).image_size[0] - 1)) OR $
      ((y - (*self.state).outersky) LT 0) OR $
      ((y + (*self.state).outersky) GT ((*self.state).image_size[1] - 1)) then $
      (*self.state).photwarning = 'Warning: Sky apertures fall outside image!'

    if (nw GT 0) then  begin
      skyval = median(small_image[w])
    endif else begin
      skyval = -1
      (*self.state).photwarning = 'Warning: No pixels in sky!'
    endelse
  endif
  ; Do the photometry now
  case (*self.state).skytype of
    0: aper, *self.images.main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
      skyrad, badpix, flux=abs((*self.state).magunits-1), /silent, /nan
    1: aper, *self.images.main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
      skyrad, badpix, flux=abs((*self.state).magunits-1), /silent, $
      setskyval = skyval,/nan
    2: aper, *self.images.main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
      skyrad, badpix, flux=abs((*self.state).magunits-1), /silent, $
      setskyval = 0,/nan
  endcase

  flux = flux[0]
  sky = sky[0]

  if (flux EQ 99.999) then begin
    (*self.state).photwarning = 'Warning: Error in computing flux!'
    flux = -1.0
  endif

  if ((*self.state).magunits EQ 1) then begin ; apply zeropoint
    flux = flux + (*self.state).photzpt - 25.0
  endif

  ;; Run self->radplotf and plot the results
  if (not (keyword_set(ps))) then begin
    self->setwindow, (*self.state).radplot_window_id
    if (not (keyword_set(enc_ener))) then self->radplotf, x, y, fwhm, out=out
    if ( (keyword_set(enc_ener))) then self->radplotf, x, y, fwhm, /enc_ener, out=out
  endif else begin
    self->radplotf, x, y, fwhm, /ps
  endelse

  ;; overplot the phot apertures on radial plot
  if (not (keyword_set(enc_ener))) then begin
    if (not (keyword_set(ps))) AND (not (keyword_set(enc_ener))) then begin
      plots, [(*self.state).r, (*self.state).r], !y.crange, line = 1, color=2, thick=2, psym=0
      xyouts, /data, (*self.state).r, !y.crange[1]*0.92, ' aprad', $
        color=2, charsize=1.5
      if ((*self.state).skytype NE 2) then begin
        plots, [(*self.state).innersky,(*self.state).innersky], !y.crange, $
          line = 1, color=4, thick=2, psym=0
        xyouts, /data, (*self.state).innersky, !y.crange[1]*0.85, ' insky', $
          color=4, charsize=1.5
        plots, [(*self.state).outersky,(*self.state).outersky], !y.crange, $
          line = 1, color=5, thick=2, psym=0
        xyouts, /data, (*self.state).outersky * 0.82, !y.crange[1]*0.75, ' outsky', $
          color=5, charsize=1.5
      endif

      plots, !x.crange, [sky, sky], color=1, thick=2, psym=0, line = 2
      xyouts, /data, (*self.state).innersky + (0.1*((*self.state).outersky-(*self.state).innersky)), $
        sky+0.06*(!y.crange[1] - sky), 'sky level', color=1, charsize=1.5

      self->resetwindow

    endif else begin

      plots, [(*self.state).r, (*self.state).r], !y.crange, line = 1, color=0, thick=2, psym=0
      xyouts, /data, (*self.state).r, !y.crange[1]*0.92, ' aprad', $
        color=0, charsize=1.5
      if ((*self.state).skytype NE 2) then begin
        plots, [(*self.state).innersky,(*self.state).innersky], !y.crange, $
          line = 1, color=0, thick=2, psym=0
        xyouts, /data, (*self.state).innersky, !y.crange[1]*0.85, ' insky', $
          color=0, charsize=1.5
        plots, [(*self.state).outersky,(*self.state).outersky], !y.crange, $
          line = 1, color=0, thick=2, psym=0
        xyouts, /data, (*self.state).outersky * 0.82, !y.crange[1]*0.75, ' outsky', $
          color=0, charsize=1.5
      endif
      plots, !x.crange, [sky, sky], color=1, thick=2, psym=0, line = 2
      xyouts, /data, (*self.state).innersky + (0.1*((*self.state).outersky-(*self.state).innersky)), $
        sky+0.06*(!y.crange[1] - sky), 'sky level', color=1, charsize=1.5

    endelse
  endif

  ;; output the results
  case (*self.state).magunits of
    0: fluxstr = 'Object counts: '
    1: fluxstr = 'Magnitude: '
  endcase

  ;;update display
  (*self.state).centerpos = [x, y]
  xy2ad, (*self.state).centerpos[0], (*self.state).centerpos[1],*((*self.state).astr_ptr) ,  startra, startdec
  tmp_stringb = 'RA: '+sigfig(startra,5)+" DEC: "+sigfig(startdec,5)

  ; Let's display relative coords instead of absolute, if we have a datacube
  ; with sat spots:
    if (n_elements((*self.state).image_size) eq 3) then begin
        if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then self->update_sat_spots
		; if we still don't have sat spots, skip this
		if (n_elements(*self.satspots.cens) eq 8L * (*self.state).image_size[2]) then begin
			;;calculate center locations
			;  cents = mean(*self.satspots.cens,dim=2) ; not idl 7.0 compatible
			tmp=*self.satspots[*].cens
			cents=fltarr(2)
			for q=0, 1 do cents[q]=mean(tmp[q,*,*])
			vector_coord1 = cents
			coord = [x,y]

			pixel_distance =sqrt( ((vector_coord1[0]-coord[0]))^2 $
			  +((vector_coord1[1]-coord[1]))^2 )

			; Compute rigorous great circle distance using gcirc etc
			;  provides correct results for complicated projections.
			xy2ad, vector_coord1[0], vector_coord1[1],*((*self.state).astr_ptr) ,  startra, startdec
			xy2ad, coord[0],         coord[1],        *((*self.state).astr_ptr) ,  stopra, stopdec
			gcirc, 1, startra/15, startdec, stopra/15, stopdec, distance
			posang, 1, startra/15, startdec, stopra/15, stopdec, pa


		tmp_stringb = "Relative offset:  "+sigfig(distance,3)+'"  PA='+sigfig(pa,3)+" deg"


		endif
 

    endif

  tmp_string = string((*self.state).cursorpos[0], (*self.state).cursorpos[1], $
    format = '("Cursor position:  x=",i4,"  y=",i4)' )
  tmp_string1 = string((*self.state).centerpos[0], (*self.state).centerpos[1], $
    format = '("Object centroid:  x=",f7.2,"  y=",f7.2)' )
  tmp_string2 = strcompress(fluxstr+string(flux, format = '(g12.6)' ))

  tmp_string3 = "Sky level:"+string(sky,format = '(f6.1)')+" +/- "+strtrim(string(skyerr, format='(f6.1)'),2)

  tmp_string4 = string(fwhm, format='("FWHM (pix): ",g7.3)' )

  widget_control, (*self.state).centerbox_id, set_value = (*self.state).centerboxsize
  widget_control, (*self.state).cursorpos_id_apphot, set_value = tmp_string
  widget_control, (*self.state).centerpos_id, set_value = tmp_string1
  widget_control, (*self.state).centerpos_id_arc, set_value = tmp_stringb
  widget_control, (*self.state).radius_id, set_value = (*self.state).r
  widget_control, (*self.state).outersky_id, set_value = (*self.state).outersky
  widget_control, (*self.state).innersky_id, set_value = (*self.state).innersky
  widget_control, (*self.state).skyresult_id, set_value = tmp_string3
  widget_control, (*self.state).photresult_id, set_value = tmp_string2
  widget_control, (*self.state).fwhm_id, set_value = tmp_string4
  widget_control, (*self.state).photwarning_id, set_value=(*self.state).photwarning

  ; Uncomment next lines if you want GPItv to output the WCS coords of
  ; the centroid for the photometry object:
  ;if ((*self.state).wcstype EQ 'angle') then begin
  ;    xy2ad, (*self.state).centerpos[0], (*self.state).centerpos[1], *((*self.state).astr_ptr), $
  ;      clon, clat
  ;    wcsstring = GPItv_wcsstring(clon, clat, (*(*self.state).astr_ptr).ctype,  $
  ;                (*self.state).equinox, (*self.state).display_coord_sys, (*self.state).display_equinox)
  ;    print, 'Centroid WCS coords: ', wcsstring
  ;endif

  ;;update photometric aperture window
  if (not (keyword_set(ps))) then $
    self->tvphot

  ;;write fits file
  if (keyword_set(sav)) then begin
    ;;synthesize name
    nm = (*self.state).imagename
    strps = strpos(nm,'/',/reverse_search)
    strpe = strpos(nm,'.fits',/reverse_search)
    nm = strmid(nm,strps+1,strpe-strps-1)

    angu_outfile = dialog_pickfile(filter='*.fits', $
      file=nm+'-radial_profile.fits', get_path = tmp_dir, $
      path=(*self.state).current_dir,$
      title='Please Select File to save radial profile')

    IF (strcompress(angu_outfile, /remove_all) EQ '') then RETURN

    IF (angu_outfile EQ tmp_dir) then BEGIN
      self->message, 'Must indicate filename to save.', $
        msgtype = 'error', /window
      return
    ENDIF

    ;;output & header
    msky = out[0,8]
    nsky = out[0,9]
    errsky = out[0,10]
    out = out[*,[lindgen(8),11]]
    mkhdr,hdr,out
    sxaddpar,hdr,'CENTER_X',x,'x coord of aperture center'
    sxaddpar,hdr,'CENTER_Y',y,'y coord of aperture center'
    sxaddpar,hdr,'RADIUS',(*self.state).r,'Radius of aperture'
    sxaddpar,hdr,'FLUX',flux,'Object flux'
    sxaddpar,hdr,'FLUXU',(['Counts','Mag'])[(*self.state).magunits],'Flux units'
    sxaddpar,hdr,'SKY_LEVEL',sky,'Sky level'
    sxaddpar,hdr,'FWHM',fwhm,'Full width at half max (pix)'
    sxaddpar,hdr,'MSKY',msky,'Median of sky annulus'
    sxaddpar,hdr,'NSKY',nsky,'Number of sky pixels'
    sxaddpar,hdr,'ERRSKY',errsky,'Standard deviation of sky annulus'
    sxaddpar,hdr,'COMMENT','Data cols are: pix #, total flux, diff flux, diff av pix val'
    sxaddpar,hdr,'COMMENT','tot flux in ann, # pix in ann, diff avg, stdev ann, stdev + sky sub err'

    ;;write
    writefits,angu_outfile,out,hdr
  endif

  self->resetwindow
end

;----------------------------------------------------------------------

pro GPItv::tvphot

  ; Routine to display the zoomed region around a photometry point,
  ; with circles showing the photometric apterture and sky radii.


  self->setwindow, (*self.state).photzoom_window_id
  erase

  x = round((*self.state).centerpos[0])
  y = round((*self.state).centerpos[1])

  boxsize = round((*self.state).outersky * 1.2)
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

  dev_width = 0.8 * (*self.state).photzoom_size
  dev_pos = [0.15 * (*self.state).photzoom_size, $
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

  tvcircle, /data, (*self.state).r, (*self.state).centerpos[0], (*self.state).centerpos[1], $
    color=2, thick=2, psym=0
  if ((*self.state).skytype NE 2) then begin
    tvcircle, /data, (*self.state).innersky, (*self.state).centerpos[0], (*self.state).centerpos[1], $
      color=4, thick=2, psym=0
    tvcircle, /data, (*self.state).outersky, (*self.state).centerpos[0], (*self.state).centerpos[1], $
      color=5, thick=2, psym=0
  endif

  self->resetwindow
end

;----------------------------------------------------------------------

pro GPItv::apphot_event, event

  @gpitv_err

  widget_control, event.id, get_uvalue = uvalue

  case uvalue of

    'centerbox': begin
      if (event.value EQ 0) then begin
        (*self.state).centerboxsize = 0
      endif else begin
        (*self.state).centerboxsize = long(event.value) > 3
        if ( ((*self.state).centerboxsize / 2 ) EQ $
          round((*self.state).centerboxsize / 2.)) then $
          (*self.state).centerboxsize = (*self.state).centerboxsize + 1
      endelse
      self->apphot_refresh
    end

    'radius': begin
      (*self.state).r = 1 > long(event.value) < (*self.state).innersky
      self->apphot_refresh
    end

    'innersky': begin
      (*self.state).innersky = (*self.state).r > long(event.value) < ((*self.state).outersky - 1)
      (*self.state).innersky = 2 > (*self.state).innersky
      if ((*self.state).outersky EQ (*self.state).innersky + 1) then $
        (*self.state).outersky = (*self.state).outersky + 1
      self->apphot_refresh
    end

    'outersky': begin
      (*self.state).outersky = long(event.value) > ((*self.state).innersky + 2)
      self->apphot_refresh
    end

    'showradplot': begin
      widget_control, (*self.state).showradplot_id, get_value=val
      case val of
        'Show Radial Profile': begin
          ysize = 350 < ((*self.state).screen_ysize - 350)
          widget_control, (*self.state).radplot_widget_id, $
            xsize=500, ysize=ysize
          widget_control, (*self.state).showradplot_id, $
            set_value='Hide Radial Profile'
        end
        'Hide Radial Profile': begin
          widget_control, (*self.state).radplot_widget_id, $
            xsize=1, ysize=1
          widget_control, (*self.state).showradplot_id, $
            set_value='Show Radial Profile'
        end
      endcase
      self->apphot_refresh
    end

    'showeeplot': begin
      widget_control, (*self.state).showeeplot_id, get_value=val
      case val of
        'Show Encircled Energy': begin
          ysize = 350 < ((*self.state).screen_ysize - 350)
          widget_control, (*self.state).radplot_widget_id, $
            xsize=500, ysize=ysize
          widget_control, (*self.state).showeeplot_id, $
            set_value='Hide Encircled Energy'
          widget_control, (*self.state).showradplot_id, $
            set_value='Show Radial Profile'
        end
        'Hide Encircled Energy': begin
          widget_control, (*self.state).radplot_widget_id, $
            xsize=1, ysize=1
          widget_control, (*self.state).showeeplot_id, $
            set_value='Show Encircled Energy'
        end
      endcase
      self->apphot_refresh,/enc_ener
    end

    'magunits': begin
      (*self.state).magunits = event.value
      self->apphot_refresh
    end

    'photsettings': self->apphot_settings

    'radplot_stats_save': begin
      radplot_stats_outfile = dialog_pickfile(filter='*.txt', $
        file='GPItv_phot.txt', get_path = tmp_dir, $
        title='Please Select File to Append Photometry Stats')

      IF (strcompress(radplot_stats_outfile, /remove_all) EQ '') then RETURN

      IF (radplot_stats_outfile EQ tmp_dir) then BEGIN
        self->message, 'Must indicate filename to save.', $
          msgtype = 'error', /window
        return
      ENDIF

      openw, lun, radplot_stats_outfile, /get_lun, /append

      widget_control, (*self.state).cursorpos_id_apphot, get_value = cursorpos_str
      widget_control, (*self.state).centerbox_id, get_value = centerbox_str
      widget_control, (*self.state).centerpos_id, get_value = centerpos_str
      widget_control, (*self.state).radius_id, get_value = radius_str
      widget_control, (*self.state).innersky_id, get_value = innersky_str
      widget_control, (*self.state).outersky_id, get_value = outersky_str
      widget_control, (*self.state).fwhm_id ,get_value = fwhm_str
      widget_control, (*self.state).skyresult_id, get_value = skyresult_str
      widget_control, (*self.state).photresult_id, get_value = objectcounts_str

      printf, lun, 'GPItv PHOTOMETRY RESULTS--NOTE: IDL Arrays Begin With Index 0'
      printf, lun, '============================================================='
      if ((*self.state).image_size[2] gt 1) then printf, lun, 'Image Slice: ' + $
        strcompress(string((*self.state).cur_image_num),/remove_all)
      printf, lun, strcompress(cursorpos_str)
      printf, lun, 'Centering box size (pix): ' + $
        strcompress(string(centerbox_str),/remove_all)
      printf, lun, strcompress(centerpos_str)
      printf, lun, 'Aperture radius: ' + $
        strcompress(string(radius_str), /remove_all)
      printf, lun, 'Inner sky radius: ' + $
        strcompress(string(innersky_str), /remove_all)
      printf, lun, 'Outer sky radius: ' + $
        strcompress(string(outersky_str), /remove_all)
      printf, lun, strcompress(fwhm_str)
      printf, lun, strcompress(skyresult_str)
      printf, lun, objectcounts_str
      printf, lun, ''

      close, lun
      free_lun, lun
    end

    'apphot_prof_save': self->apphot_refresh, /sav

    'apphot_ps': begin

      fname = strcompress((*self.state).current_dir + 'GPItv_phot.ps', /remove_all)
      forminfo = cmps_form(cancel = canceled, create = create, $
        /preserve_aspect, $
        /color, $
        /nocommon, papersize='Letter', $
        filename = fname, $
        button_names = ['Create PS File'])

      if (canceled) then return
      if (forminfo.filename EQ '') then return

      tmp_result = findfile(forminfo.filename, count = nfiles)

      result = ''
      if (nfiles GT 0) then begin
        mesg = strarr(2)
        mesg[0] = 'Overwrite existing file:'
        tmp_string = strmid(forminfo.filename, strpos(forminfo.filename, $
          '/') + 1)
        mesg[1] = strcompress(tmp_string + '?', /remove_all)
        result =  dialog_message(mesg, $
          /default_no, $
          dialog_parent = (*self.state).base_id, $
          /question)
      endif

      if (strupcase(result) EQ 'NO') then return

      widget_control, /hourglass

      screen_device = !d.name

      set_plot, 'ps'
      device, _extra = forminfo

      self->apphot_refresh, /ps

      device, /close
      set_plot, screen_device

    end

    'apphot_done': widget_control, event.top, /destroy
    else:
  endcase

end

;----------------------------------------------------------------------

pro GPItv::apphot_settings


  ; Routine to get user input on various photometry settings

  skyline = strcompress('0, button, IDLPhot Sky|Median Sky|No Sky Subtraction,'+$
    'exclusive,' + $
    'label_left=Select Sky Algorithm: , set_value = ' + $
    string((*self.state).skytype))

  magline = strcompress('0, button, Counts|Magnitudes, exclusive,' + $
    'label_left = Select Output Units: , set_value =' + $
    string((*self.state).magunits))

  zptline = strcompress('0, float,'+string((*self.state).photzpt) + $
    ',label_left = Magnitude Zeropoint:,' + $
    'width = 12')

  formdesc = [skyline, $
    magline, $
    zptline, $
    '0, label, [Magnitude = zeropoint - 2.5 log (counts)]', $
    '0, button, Apply Settings, quit', $
    '0, button, Cancel, quit']

  textform = cw_form(formdesc, /column, $
    title = 'GPItv photometry settings')

  if (textform.tag5 EQ 1) then return ; cancelled

  (*self.state).skytype = textform.tag0
  (*self.state).magunits = textform.tag1
  (*self.state).photzpt = textform.tag2

  self->apphot_refresh

end

;----------------------------------------------------------------------

pro GPItv::apphot

  ; aperture photometry front end


  (*self.state).cursorpos = (*self.state).coord

  if (not (xregistered(self.xname+'_apphot'))) then begin

    if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
    apphot_base = $
      widget_base(/base_align_center, $
      group_leader = (*self.state).base_id, $
      /column, $
      title = title_base+' aperture photometry', $
      uvalue = 'apphot_base')

    apphot_top_base = widget_base(apphot_base, /row, /base_align_center)

    apphot_data_base1 = widget_base( $
      apphot_top_base, /column, frame=0)

    apphot_data_base2 = widget_base( $
      apphot_top_base, /column, frame=0)

    apphot_draw_base = widget_base( $
      apphot_base, /row, /base_align_center, frame=0)

    apphot_data_base1a = widget_base(apphot_data_base1, /column, frame=1)
    tmp_string = $
      string(1000, 1000, $
      format = '("Cursor position:  x=",i4,"  y=",i4)' )

    (*self.state).cursorpos_id_apphot = $
      widget_label(apphot_data_base1a, $
      value = tmp_string, $
      uvalue = 'cursorpos', /align_left)

    (*self.state).centerbox_id = $
      cw_field(apphot_data_base1a, $
      /long, $
      /return_events, $
      title = 'Centering box size (pix):', $
      uvalue = 'centerbox', $
      value = (*self.state).centerboxsize, $
      xsize = 5)

    tmp_string1 = $
      string(99999.0, 99999.0, $
      format = '("Object centroid:  x=",f7.2,"  y=",f7.2)' )
    tmp_stringb = $
      string(0.0, 0.0, $
      format = '("Relative offset:  sep=",f5.2,"  PA=",f5.2)' )


    (*self.state).centerpos_id = $
      widget_label(apphot_data_base1a, $
      value = tmp_string1, $
      uvalue = 'centerpos', /align_left)

    (*self.state).centerpos_id_arc = $
      widget_label(apphot_data_base1a, $
      value = tmp_stringb, $
      uvalue = 'centerpos', /align_left)

    (*self.state).radius_id = $
      cw_field(apphot_data_base1a, $
      /long, $
      /return_events, $
      title = 'Aperture radius:', $
      uvalue = 'radius', $
      value = (*self.state).r, $
      xsize = 5)

    (*self.state).innersky_id = $
      cw_field(apphot_data_base1a, $
      /long, $
      /return_events, $
      title = 'Inner sky radius:', $
      uvalue = 'innersky', $
      value = (*self.state).innersky, $
      xsize = 5)

    (*self.state).outersky_id = $
      cw_field(apphot_data_base1a, $
      /long, $
      /return_events, $
      title = 'Outer sky radius:', $
      uvalue = 'outersky', $
      value = (*self.state).outersky, $
      xsize = 5)

    photzoom_widget_id = widget_draw( $
      apphot_data_base2, $
      scr_xsize=(*self.state).photzoom_size, scr_ysize=(*self.state).photzoom_size)

    tmp_string4 = string(0.0, format='("FWHM (pix): ",g7.3)' )
    (*self.state).fwhm_id = widget_label(apphot_data_base2, $
      value=tmp_string4, $
      uvalue='fwhm')

    ;    tmp_string3 = string(10000000.00, format = '("Sky level: ",g12.6)' )
    tmp_string3 = "Sky level:"+string(10000000.0,format = '(f6.1)')+" +/- "+strtrim(string(100000000.0, format='(f6.1)'),2)

    (*self.state).skyresult_id = $
      widget_label(apphot_data_base2, $
      value = tmp_string3, $
      uvalue = 'skyresult')

    tmp_string2 = string(1000000000.00, $
      format = '("Object counts: ",g12.6)' )

    (*self.state).photresult_id = $
      widget_label(apphot_data_base2, $
      value = tmp_string2, $
      uvalue = 'photresult', $
      /frame)

    (*self.state).photwarning_id = $
      widget_label(apphot_data_base1, $
      value='-------------------------', $
      /dynamic_resize, $
      frame=1)

    photsettings_id = $
      widget_button(apphot_data_base1, $
      value = 'Photometry Settings...', $
      uvalue = 'photsettings')

    radplot_log_save = $
      widget_button(apphot_data_base1, $
      value = 'Save Photometry Stats', $
      uvalue = 'radplot_stats_save')

    (*self.state).showradplot_id = $
      widget_button(apphot_data_base1, $
      value = 'Hide Radial Profile', $
      uvalue = 'showradplot')

    (*self.state).showEEplot_id = $
      widget_button(apphot_data_base1, $
      value = 'Show Encircled Energy', $
      uvalue = 'showeeplot')

    (*self.state).radplot_widget_id = widget_draw( $
      apphot_draw_base, scr_xsize=500, $
      scr_ysize=(350 < ((*self.state).screen_ysize - 350)))

    apphot_ps = $
      widget_button(apphot_data_base2, $
      value = 'Create Profile PS', $
      uvalue = 'apphot_ps')
    anpphot_prof_save = $
      widget_button(apphot_data_base2, $
      value = 'Save Radial Profile', $
      uvalue = 'apphot_prof_save')

    apphot_done = $
      widget_button(apphot_data_base2, $
      value = 'Done', $
      uvalue = 'apphot_done')

    widget_control, apphot_base, /realize

    widget_control, photzoom_widget_id, get_value=tmp_value
    (*self.state).photzoom_window_id = tmp_value
    widget_control, (*self.state).radplot_widget_id, get_value=tmp_value
    (*self.state).radplot_window_id = tmp_value

    xmanager, self.xname+'_apphot', apphot_base, /no_block
    widget_control, apphot_base, set_uvalue = {object:self, method: 'apphot_event'}
    widget_control, apphot_base, event_pro = 'GPItvo_subwindow_event_handler'


    self->resetwindow
  endif

  self->apphot_refresh

end


;----------------------------------------------------------------------
;-------------------------------------------------------------------


;----------------------------------------------------------------------
;----------------------------------------------------------------------

pro GPItv::tvlamb

  ; Routine to display the zoomed region around a spaxel,
  ; with circles showing the photometric apterture.


  ;print,'numla',(*self.state).lambzoom_window_id
  self->setwindow, (*self.state).lambzoom_window_id
  erase

  x = round((*self.state).cursorpos[0])
  y = round((*self.state).cursorpos[1])

  ;boxsize = round((*self.state).outersky * 1.2)
  widget_control,(*self.state).radius_id, get_value= radi
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

  dev_width = 0.8 * (*self.state).photzoom_size
  dev_pos = [0.15 * (*self.state).photzoom_size, $
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

  tvcircle, /data, radi, (*self.state).cursorpos[0], (*self.state).cursorpos[1], $
    color=2, thick=2, psym=0
  ;if ((*self.state).skytype NE 2) then begin
  ;    tvcircle, /data, (*self.state).innersky, (*self.state).centerpos[0], (*self.state).centerpos[1], $
  ;      color=4, thick=2, psym=0
  ;    tvcircle, /data, (*self.state).outersky, (*self.state).centerpos[0], (*self.state).centerpos[1], $
  ;      color=5, thick=2, psym=0
  ;endif

  self->resetwindow
end

;----------------------------------------------------------------------
;----------------------------------------------------------------------

pro GPItv::lambprof_event, event

  @gpitv_err

  widget_control, event.id, get_uvalue = uvalue

  case uvalue of
    'meth': begin
      (*self.state).currmeth=(*self.state).methlist[event.index]
      self->lambprof_refresh
    end


    'radius': begin
      (*self.state).r = 1 > long(event.value) ;< (*self.state).innersky
      ;print, 'Aper. radius=',(*self.state).r
      self->lambprof_refresh
    end


    'showlambplot': begin
      widget_control, (*self.state).showlambplot_id, get_value=val
      case val of
        'Show Spaxel Profile': begin
          ysize = 350 < ((*self.state).screen_ysize - 350)
          widget_control, (*self.state).lambplot_widget_id, $
            xsize=500, ysize=ysize
          widget_control, (*self.state).showlambplot_id, $
            set_value='Hide Spaxel Profile'
        end
        'Hide Spaxel Profile': begin
          widget_control, (*self.state).lambplot_widget_id, $
            xsize=1, ysize=1
          widget_control, (*self.state).showlambplot_id, $
            set_value='Show Spaxel Profile'
        end
      endcase
      self->lambprof_refresh
    end



    'lamb_save': self->lambprof_refresh,/sav


    'lamb_ps': begin
      fname = strcompress((*self.state).current_dir + 'GPItv_spax.ps', /remove_all)
      forminfo = cmps_form(cancel = canceled, create = create, $
        /preserve_aspect, $
        /color, $
        /nocommon, papersize='Letter', $
        filename = fname, $
        button_names = ['Create PS File'])

      if (canceled) then return
      if (forminfo.filename EQ '') then return

      tmp_result = findfile(forminfo.filename, count = nfiles)

      result = ''
      if (nfiles GT 0) then begin
        mesg = strarr(2)
        mesg[0] = 'Overwrite existing file:'
        tmp_string = strmid(forminfo.filename, strpos(forminfo.filename, $
          '/') + 1)
        mesg[1] = strcompress(tmp_string + '?', /remove_all)
        result =  dialog_message(mesg, $
          /default_no, $
          dialog_parent = (*self.state).base_id, $
          /question)
      endif

      if (strupcase(result) EQ 'NO') then return

      widget_control, /hourglass

      screen_device = !d.name

      set_plot, 'ps'
      device, _extra = forminfo

      self->lambprof_refresh, /ps

      device, /close
      set_plot, screen_device

    end
    ;end

    'lambprof_done': widget_control, event.top, /destroy
    else:
  endcase

end

;----------------------------------------------------------------------

pro GPItv::lambprof_refresh, ps=ps, sav=sav

  ;; Do aperture photometry using idlastro daophot routines.


  (*self.state).photwarning = 'Warnings: None.'

  x = (*self.state).cursorpos[0]
  y = (*self.state).cursorpos[1]

  tmp_string = $
    string(x, y, $
    format = '("Cursor position:  x=",i4,"  y=",i4)' )
  if widget_info((*self.state).cursorpos_id_lambprof,/valid_id) then $
    widget_control,(*self.state).cursorpos_id_lambprof, set_value = tmp_string

  widget_control,(*self.state).radius_id, get_value= radi

  widget_control,(*self.state).spaxelmeth_id

  ;for aperture radius
  ;distsq = fltarr(2*radi+1,2*radi+1,/nozero)
  ;xx = findgen(2*radi+1)
  ;yy = findgen(2*radi+1)
  ;x2 = (xx - x)^(2.0)
  ;y2 = (yy - y)^(2.0)
  ;for i = 0L,(2*radi) do $          ; row loop
  ;  distsq[*,i] = x2 + y2[i]
  ;distsq=distarr(2*radi+1,2*radi+1)
  if radi gt 0 then begin
    distsq=shift(dist(2*radi+1),radi,radi)
    inda=array_indices(distsq,where(distsq le radi))
    inda[0,*]+=x-radi
    inda[1,*]+=y-radi
    ;;be sure circle doesn't go outside the image:
    inda_outx=intersect(where(inda[0,*] ge 0,cxz),where(inda[0,*] lt ((size(*self.images.main_image_stack))[1]) ))
    inda_outy=intersect( where(inda[1,*] ge 0,cyz), where(inda[1,*] lt ((size(*self.images.main_image_stack))[2])) )
    inda_out=intersect(inda_outx,inda_outy)
    inda2x=inda[0,inda_out]
    inda2y=inda[1,inda_out]
    inda=[inda2x,inda2y]
  endif else begin
    inda=intarr(2,1)
    inda[0,0]=x
    inda[1,0]=y
  endelse

  self->setwindow, (*self.state).lambplot_window_id
  if (size(*self.images.main_image_stack))[0] eq 3 then begin
    if radi gt 0 then begin
      mi=dblarr((size(inda))[2],(size(*self.images.main_image_stack))[3],/nozero)
      for i=0,(size(inda))[2]-1 do $
        mi[i,*]=(*self.images.main_image_stack)[inda[0,i],inda[1,i], *]
      p1d=fltarr((size(*self.images.main_image_stack))[3])
      if STRMATCH((*self.state).currmeth,'Total(/nan)') then $
        p1d=total(mi,1,/nan)
      if STRMATCH((*self.state).currmeth,'Median') then $
        p1d=median(mi,dimension=1)
      if STRMATCH((*self.state).currmeth,'Mean') then $
        for i=0,(size(mi))[2]-1 do $
        p1d[i]=mean(mi[*,i],/nan)
    endif else begin
      p1d=(*self.images.main_image_stack)[x, y, *]
    endelse
    ;print, 'smi',size(mi)
    ;print, 'sp1d',size(p1d)
    ;p1d=*self.images.main_image_stack[x, y, *]
    ;endif else begin
    ;  self->radplotf, x, y, fwhm, /ps
    ;endelse

    lmin=(*self.state).CWV_lmin
    lmax=(*self.state).CWV_lmax
    NLam=(*self.state).CWV_NLam
    indf=where(finite(p1d))
    if (NLam gt 0)  then $
      xlam=(*(*self.state).CWV_ptr)[indf] $
    else xlam=(indgen((size(*self.images.main_image_stack))[3]))[indf]

    ;; overplot the phot apertures on radial plot
    if (not (keyword_set(ps)))  then begin

      if n_elements(indf) gt 1 then $
        plot, xlam, p1d[indf],ytitle='Flux ['+(*self.state).current_units+']', xtitle='Wavelength (um)', psym=-1
    endif else begin
      ;indf=where(finite(p1d))
      ;if n_elements(indf) gt 1 then $
      ;plot, (*(*self.state).CWV_ptr)[indf], p1d[indf],ytitle='Flux ['+(*self.state).units+']', xtitle='Lambda (um)', psym=-1
    endelse

    if (not (keyword_set(ps))) then self->tvlamb
  endif

  ;;write fits file
  if (keyword_set(sav)) then begin
    ;;synthesize name
    nm = (*self.state).imagename
    strps = strpos(nm,'/',/reverse_search)
    strpe = strpos(nm,'.fits',/reverse_search)
    nm = strmid(nm,strps+1,strpe-strps-1)

    lamb_outfile = dialog_pickfile(filter='*.fits', $
      file=nm+'-spaxel_profile.fits', get_path = tmp_dir, $
      path=(*self.state).current_dir,$
      title='Please Select File to save spaxel profile')

    IF (strcompress(lamb_outfile, /remove_all) EQ '') then RETURN

    IF (lamb_outfile EQ tmp_dir) then BEGIN
      self->message, 'Must indicate filename to save.', $
        msgtype = 'error', /window
      return
    ENDIF

    ;;output & header
    out = [[(*(*self.state).CWV_ptr)[indf]],[p1d[indf]]]
    mkhdr,hdr,out
    sxaddpar,hdr,'CENTER_X',x,'x coord of aperture center'
    sxaddpar,hdr,'CENTER_Y',y,'y coord of aperture center'
    sxaddpar,hdr,'RADIUS',radi,'Radius of aperture'
    sxaddpar,hdr,'METHOD',(*self.state).currmeth

    ;;write
    writefits,lamb_outfile,out,hdr
  endif

  ; Uncomment next lines if you want GPItv to output the WCS coords of
  ; the centroid for the photometry object:
  ;if ((*self.state).wcstype EQ 'angle') then begin
  ;    xy2ad, (*self.state).centerpos[0], (*self.state).centerpos[1], *((*self.state).astr_ptr), $
  ;      clon, clat
  ;    wcsstring = GPItv_wcsstring(clon, clat, (*(*self.state).astr_ptr).ctype,  $
  ;                (*self.state).equinox, (*self.state).display_coord_sys, (*self.state).display_equinox)
  ;    print, 'Centroid WCS coords: ', wcsstring
  ;endif


  self->resetwindow
end

;----------------------------------------------------------------------
pro GPItv::lambprof

  ; aperture radial profil front end


  (*self.state).cursorpos = (*self.state).coord

  if (not (xregistered(self.xname+'_lambprof'))) then begin

    lambprof_base = $
      widget_base(/base_align_center, $
      group_leader = (*self.state).base_id, $
      /column, $
      title = 'GPItv Spectral Profile', $
      uvalue = 'lambprof_base')

    lambprof_top_base = widget_base(lambprof_base, /row, /base_align_center)

    lambprof_data_base1 = widget_base( $
      lambprof_top_base, /column, frame=0)

    lambprof_data_base2 = widget_base( $
      lambprof_top_base, /column, frame=0)

    lambzoom_widget_id = widget_draw( $
      lambprof_data_base2, $
      scr_xsize=(*self.state).photzoom_size, scr_ysize=(*self.state).photzoom_size)
    ;print, 'lambz', (*self.state).lambzoom_window_id

    lambprof_draw_base = widget_base( $
      lambprof_base, /row, /base_align_center, frame=0)


    lambprof_data_base1a = widget_base(lambprof_data_base1, /column, frame=1)
    tmp_string = $
      string(1000, 1000, $
      format = '("Cursor position:  x=",i4,"  y=",i4)' )

    (*self.state).cursorpos_id_lambprof = $
      widget_label(lambprof_data_base1a, $
      value = tmp_string, $
      uvalue = 'cursorpos', /align_left)

    ;    (*self.state).centerbox_id = $
    ;      cw_field(lambprof_data_base1a, $
    ;               /long, $
    ;               /return_events, $
    ;               title = 'Centering box size (pix):', $
    ;               uvalue = 'centerbox', $
    ;               value = (*self.state).centerboxsize, $
    ;               xsize = 5)
    ;
    ;    tmp_string1 = $
    ;      string(99999.0, 99999.0, $
    ;             format = '("Object centroid:  x=",f7.1,"  y=",f7.1)' )
    ;
    ;    (*self.state).centerpos_id = $
    ;      widget_label(lambprof_data_base1a, $
    ;                   value = tmp_string1, $
    ;                   uvalue = 'centerpos', /align_left)

    (*self.state).radius_id = $
      cw_field(lambprof_data_base1a, $
      /long, $
      /return_events, $
      title = 'Aperture radius:', $
      uvalue = 'radius', $
      value = (*self.state).r, $
      xsize = 5)
    (*self.state).methlist = ['Total(/nan)', 'Median',  'Mean']
    (*self.state).spaxelmeth_id = widget_droplist(lambprof_data_base1a, $
      frame = 0, $
      title = 'Method:', $
      uvalue = 'meth', $
      value = (*self.state).methlist)
    (*self.state).currmeth=(*self.state).methlist[0]
    ;    (*self.state).innersky_id = $
    ;      cw_field(lambprof_data_base1a, $
    ;               /long, $
    ;               /return_events, $
    ;               title = 'Inner sky radius:', $
    ;               uvalue = 'innersky', $
    ;               value = (*self.state).innersky, $
    ;               xsize = 5)
    lambplot_log_save = $
      widget_button(lambprof_data_base1, $
      value = 'Save Spaxel Profile', $
      uvalue = 'lamb_save')

    ;    lamb_ps = $
    ;      widget_button(lambprof_data_base1, $
    ;                    value = 'Create Profile PS', $
    ;                    uvalue = 'lamb_ps')



    (*self.state).showlambplot_id = $
      widget_button(lambprof_data_base1, $
      value = 'Hide Spaxel Profile', $
      uvalue = 'showlambplot')

    (*self.state).lambplot_widget_id = widget_draw( $
      lambprof_draw_base, scr_xsize=500, $
      scr_ysize=(350 < ((*self.state).screen_ysize - 350)))

    lambprof_done = $
      widget_button(lambprof_data_base2, $
      value = 'Done', $
      uvalue = 'lambprof_done')

    widget_control, lambprof_base, /realize

    widget_control, lambzoom_widget_id, get_value=tmp_value
    (*self.state).lambzoom_window_id = tmp_value
    widget_control, (*self.state).lambplot_widget_id, get_value=tmp_value
    (*self.state).lambplot_window_id = tmp_value

    xmanager, self.xname+'_lambprof', lambprof_base, /no_block
    widget_control, lambprof_base, set_uvalue = {object:self, method: 'lambprof_event'}
    widget_control, lambprof_base,  event_pro = 'GPItvo_subwindow_event_handler'



    self->resetwindow
  endif

  self->lambprof_refresh
end

;-------------------------------------------------------------------

pro GPItv::sdi_event, event

  @gpitv_err

  widget_control, event.id, get_uvalue = uvalue

  case uvalue of

    'userdef':begin
    widget_control, (*self.state).sdi_userdef_id,get_value=res
    (*self.state).sdi_userdef = res
    self->sdi_refresh
  end

  'slicebox': begin
    ;;only care about leaving the widget
    if tag_exist(event,'ENTER') then if event.enter eq 0 then return

    ;;if image is currently loaded, grab the wavelengths associated
    ;;with the slices
    if ptr_valid((*self.state).CWV_ptr) then begin
      for j = 0,3 do begin
        widget_control, (*self.state).sdi_sliceids[j],get_value=res
        res = long(res)
        if (res ge 0) && (res lt n_elements(*(*self.state).CWV_ptr)) then $
          widget_control, (*self.state).sdi_wavids[j], set_value=$
          string((*((*self.state).CWV_ptr))[res],format='(F4.2)')+' um'$
        else widget_control,(*self.state).sdi_sliceids[j],set_value=string((*self.state).sdi_slices[j],format='(I3)')
      endfor
    endif
  end

  ;;grab all info and save to state
  'save': begin
    widget_control, (*self.state).sdi_userdef_id,get_value=res
    (*self.state).sdi_userdef = res
    for j = 0,3 do begin
      widget_control, (*self.state).sdi_sliceids[j],get_value=res
      (*self.state).sdi_slices[j] = long(res)
    endfor
    widget_control, (*self.state).sdik_id,get_value=res
    (*self.state).sdik = res
    ;;close
    widget_control, event.top, /destroy

    ;;if you are currently in the SDI collapse mode, update the view
    widget_control,(*self.state).collapse_button,get_value=modelist
    if ((*self.state).collapse eq where(strmatch(modelist,'Collapse by SDI'))) then $
      self->sdi
  end

  'cancel': widget_control, event.top, /destroy
  else:
endcase

end
;----------------------------------------------------------------------

pro GPItv::sdi_update_defs
  ;;update default slices based on current band

  ;;if no image loaded or user selection set, do nothing
  if ~ptr_valid((*self.state).CWV_ptr) || (*self.state).sdi_userdef then return

  ;;figure out which slices you're using based on band
  case (*self.state).obsfilt of
    'H': wavs = [1.585, 1.593, 1.617, 1.625]
    'J': wavs = [1.207, 1.213, 1.232, 1.238]
    'Y': wavs = [1.002, 1.008, 1.033, 1.038]
    'K1': wavs = [1.957, 1.965, 1.996, 2.004]
    else: wavs = -1
  endcase

  if n_elements(wavs) eq 1 then begin
    self->message,msgtyp='warning',"No default defined for this band.  Using H-equivalent slices."
    slices = [10,11,14,15]
  endif else begin
    slices = lonarr(4)
    for j = 0,3 do slices[j] = VALUE_LOCATE(*((*self.state).CWV_ptr),wavs[j])
  endelse

  (*self.state).sdi_slices = slices

end

;----------------------------------------------------------------------

pro GPItv::sdi
  ;; Do SSDI

  ;; if you were previously speckle aligned kliped or restore the
  ;; backup cube before doing anything else
  if ((*self.state).specalign_mode eq 1) || ((*self.state).klip_mode eq 1)  then begin
    (*self.images.main_image_stack)=(*self.images.main_image_backup)
    (*self.state).specalign_mode = 0
    (*self.state).klip_mode = 0
  endif

  widget_control, /hourglass

  ;;if no satspots in memory, calculate them
  if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
    self->update_sat_spots

    ;;if failed, need to return
    if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
      self->message, msgtype='error', "Cannot find satellite spots."
      status=0
      return
    endif
  endif

  ;;figure out which slices you're using
  self->sdi_update_defs
  slices = (*self.state).sdi_slices

  ;;make sure that slices are ordered correctly
  if slices[0] gt slices[1] then begin
    self->message,msgtype='warning','Slice 2 is before slice 1.  Changing order.'
    slices[0:1] = slices[[1,0]]
  endif
  if slices[2] gt slices[3] then begin
    self->message,msgtype='warning','Slice 4 is before slice 3.  Changing order.'
    slices[2:3] = slices[[3,2]]
  endif

  ;note that following 2 code lines remove a lot of nan...
  if (slices[0] ne slices[1]) then $
    I1 = avg((*self.images.main_image_stack)[*,*,slices[0]:slices[1]],2,/double,/nan) else $
    I1 = (*self.images.main_image_stack)[*,*,slices[0]]

  if (slices[2] ne slices[3]) then $
    I2 = avg((*self.images.main_image_stack)[*,*,slices[2]:slices[3]],2,/double,/nan) else $
    I2 = (*self.images.main_image_stack)[*,*,slices[2]]

  I1[where(~FINITE(I1))]=0.
  I2[where(~FINITE(I2))]=!VALUES.F_NAN

  ;;generate SDI settings
  Ls = (*((*self.state).CWV_ptr))[slices]
  L1m = Ls[0]+0.5*(Ls[1] - Ls[0])
  L2m = Ls[2]+0.5*(Ls[2] - Ls[3])
  vscaleopt=1
  knum=1
  locs = dblarr(2,4)
  for j = 0,1 do for k = 0,3 do locs[j,k] = mean((*self.satspots.cens)[j,k,slices[0]:slices[1]],/nan)

  sdidiff=gpi_ssdi(I1,I2,L1m,L2m,vscaleopt,(*self.state).sdik,knum,locs)

  *self.images.main_image=sdidiff
  self->message, msgtype='information','Optimal SDI image magnification is = '+strtrim(vscaleopt[0],2)
  self->message, msgtype='information','Optimal SDI image intensity renormalization is = '+strtrim(knum[0],2)

  ;Reset GPItv to SSDI mode
  (*self.state).rgb_mode=0
  (*self.state).specalign_mode=0

  self->getstats
  self->recenter
  self->autoscale
  self->set_minmax
  self->displayall
  self->update_child_windows,/update
  self->resetwindow

end

;----------------------------------------------------------------------

pro GPItv::sdi_refresh
  ;;refresh the SDI settings box, if it exists

  if ~(xregistered(self.xname+'_sdi', /noshow)) then return

  if ptr_valid((*self.state).CWV_ptr) then begin
    self->sdi_update_defs
    wavs = strarr(4)
    for j = 0,3 do wavs[j] = string((*((*self.state).CWV_ptr))[(*self.state).sdi_slices[j]],format='(F4.2)')+' um'
  endif else wavs =  ['','','','']

  ;;update displays
  for j = 0,3 do begin
    widget_control, (*self.state).sdi_sliceids[j],$
      set_value = string((*self.state).sdi_slices[j],format='(I3)'),$
      sensitive=(*self.state).sdi_userdef
    widget_control,(*self.state).sdi_wavids[j],set_value = wavs[j]
  endfor

end

;----------------------------------------------------------------------
pro GPItv::SDI_settings

  ;; SDI settings front end
  if ~(xregistered(self.xname+'_sdi')) then begin
    sdi_base = $
      widget_base(/base_align_center, $
      group_leader = (*self.state).base_id, $
      /column, $
      title = 'GPItv SDI', $
      uvalue = 'sdi_base')

    message = ['            *** SIMPLE DIFFERENCE IMAGING ***',$
      'Choose default (methane band) or enter user-defined values.',$
      'SDI collapse mode generates a difference image between the',$
      'average of all slices between Slice 1 and Slice 2 (Im1), and',$
      'the average of all slices between Slice 3 and Slice 4 (Im2).', $
      'Im1 is spatially scaled by the ratio of the central wavelengths',$
      'and Im2 is photometrically scaled by the subraction factor (f).',$
      'Setting the subtraction factor to -1 causes the code to find',$
      'the optimum value.',$
      'Wavelengths are for current cube (or none if no cube loaded).',$
      "Settings are only applied when 'Save Settings' is clicked."]

    void = widget_text(sdi_base, value = message, xsize = max(strlen(message)), ysize = n_elements(message))
    sdi_base1 = widget_base(sdi_base, /row)
    (*self.state).sdi_userdef_id = CW_BGROUP(sdi_base1, ['Default', 'User-defined'], /COLUMN,$
      /EXCLUSIVE,/FRAME, SET_VALUE=(*self.state).sdi_userdef,$
      uvalue='userdef')
    sdi_base1a = widget_base(sdi_base1, /row)
    void = widget_label(sdi_base1a,Value='Subtraction Factor')
    (*self.state).sdik_id =  widget_text(sdi_base1a,uvalue = 'subfrac', $
      value = strtrim((*self.state).sdik,2),$
      xsize = 5,/editable)

    sdi_base2 = widget_base( $
      sdi_base, /column, frame=0)
    sdi_base2s = lonarr(4)
    sdi_base2s[0] = widget_base( $
      sdi_base2, /row, frame=0)
    sdi_base2s[1] = widget_base( $
      sdi_base2, /row, frame=0)
    sdi_base2s[2] = widget_base( $
      sdi_base2, /row, frame=0)
    sdi_base2s[3] = widget_base( $
      sdi_base2, /row, frame=0)

    ;;if image is currently loaded, grab the wavelengths associated
    ;;with the slices
    if ptr_valid((*self.state).CWV_ptr) then begin
      self->sdi_update_defs
      wavs = strarr(4)
      for j = 0,3 do wavs[j] = string((*((*self.state).CWV_ptr))[(*self.state).sdi_slices[j]],format='(F4.2)')+' um'
    endif else wavs =  ['','','','']

    extratext1 = ['   mean( ','         ','-f*mean( ','         ']
    extratext2 = ['  ',' )','  ',' )']
    for j = 0,3 do begin
      void = widget_label( sdi_base2s[j], VALUE=extratext1[j]+'Slice '+strtrim(j,2)+':' )
      (*self.state).sdi_sliceids[j] = widget_text(sdi_base2s[j],uvalue = 'slicebox', $
        value = string((*self.state).sdi_slices[j],$
        format='(I3)'), $
        xsize = 5,/editable,/KBRD_FOCUS_EVENTS)
      widget_control,(*self.state).sdi_sliceids[j],sensitive=(*self.state).sdi_userdef
      void =  widget_label( sdi_base2s[j], VALUE=extratext2[j])
      (*self.state).sdi_wavids[j] = widget_label( sdi_base2s[j], VALUE=wavs[j] )
    endfor

    sdi_base3 = widget_base( sdi_base, /row, frame=0)

    void = widget_button(sdi_base3, $
      value = 'Cancel', $
      uvalue = 'cancel')
    void = widget_button(sdi_base3, $
      value = 'Save Settings', $
      uvalue = 'save')

    widget_control, sdi_base, /realize

    xmanager, self.xname+'_sdi', sdi_base, /no_block
    widget_control, sdi_base, set_uvalue={object: self, method: 'sdi_event'}
    widget_control, sdi_base,event_pro = 'GPItvo_subwindow_event_handler'
    self->resetwindow
  endif

end

;----------------------------------------------------------------------
pro GPItv::alignspeckle, status=status
  ;; routine to align speckles
  ;;  with respect to current slice
  ;; JM -2012-02-22
  ;; DS 2012-07-30 - offloaded backend to speckle_align

  widget_control, /hourglass

  if n_elements((*self.state).image_size) eq 3 then begin

    ;;if no satspots in memory, calculate them
    if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
      self->update_sat_spots

      ;;if failed, need to return
      if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
        self->message, msgtype='error', "Cannot align speckles because we cannot determine the center without satellite spots."
        status=0
        return
      endif
    endif

    Ima2 = speckle_align(*self.images.main_image_stack,$
      band=(*self.state).obsfilt,$
      refslice=(*self.state).cur_image_num,$
      locs=(*self.satspots.cens)[*,*,(*self.state).cur_image_num])

    *self.images.main_image_stack=Ima2
    (*self.state).specalign_mode=1
    (*self.state).specalign_to = (*self.state).cur_image_num

    self->getstats
    self->displayall
    status=1

  endif else begin
    self->message, msgtype='error', "Speckle Alignment only works with 3D datacube"
    status=0
  endelse

end

;;----------------------------------------------------------------------
pro GPItv::create_snr_map, status=status
  ;;; routine to create SNR maps from contrast+data
  ;;; PI - 2014-12-10

  widget_control, /hourglass

  if (n_elements((*self.state).image_size) eq 3) or (n_elements((*self.state).image_size) eq 2) then begin


    hd = *((*self.state).head_ptr)
    if ptr_valid((*self.state).exthead_ptr) then exthd = *((*self.state).exthead_ptr) else exthd = ['', 'END']

    ; are there sat spots declared?
    ;*self.satspots[*].cens
    ;if N_ELEMENTS(*self.satspots.cens) eq 0 then begin
    ;self->message, msgtype='info', 'No satellite spot information loaded yet, finding satellite spots'
    ;		self->update_sat_spots
    ;endif
    ; is there any contrast information?
    ;  self.satspots.contrprof ;contour profile (will be Z x 3 pointer array with second dimension being stdev,median,mean)

    ((*self.state).snr_map_mode) = 1

    if N_ELEMENTS( *(*self.satspots.contrprof)[0,0]) eq 0 then begin
      self->message, msgtype='info', 'No contrast information calculated yet, calculating contrast'
      self->contrast
    endif

    ;;check to make sure that we actually have a valid contour profile in memory
    ;; maybe the sat spot finding failed? not sure if this is necessary in the long run

    if (*self.state).contr_plotmult then inds = (*self.satspots.good) else $
      inds = (*self.state).cur_image_num
    if n_elements(*(*self.satspots.contrprof)[inds[0],(*self.state).contr_yunit]) eq 0 then begin
      self->message, msgtype='error', 'No valid contour profile exists, cannot create SNR map.'
      return
    endif

    ; get satellits and calculate image center
    cens = (*self.satspots.cens)
    cent = [mean(cens[0,*]),mean(cens[1,*])]
    ; create a radial distance array
    dimx=281 & dimy=281
    xc= cent[0] & yc=cent[1]
    distarr=sqrt((findgen(dimx)#replicate(1.,dimy)-xc)^2+$
      (replicate(1.,dimx)#findgen(dimy)-yc)^2)
    distarr=float(round(distarr)) ; this has to be float of the flagging as Nan doesn't work... not sure why.
    im=*self.images.main_image_stack
    ; mask out the regions in the distarr were not interested in
    ind=where(finite(im[*,*,0]) eq 0, count)
    if count ge 1 then distarr[ind]=!values.f_nan
    ; need a contrast for all elements, so find the unique ones
    all_rad_vals = distarr[UNIQ(distarr, SORT(distarr))]

    all_rad_vals=all_rad_vals[where(finite(all_rad_vals) eq 1)]
    ; calculate the contrast for all elements
    sz=size(im)
    im=*self.images.main_image_stack
    ; now need to take the contrast measurements and the center of the image, then create a 2d image for contrast centered on the star and divide by it.
    contr_arr=fltarr(281,281,sz[3])+!values.f_nan

    ; this next loop is slow (~5 seconds)
    ; loop over radii values
    for p=0, N_ELEMENTS(all_rad_vals)-1 do begin
      ind=where(distarr eq all_rad_vals[p], count)
      if count gt 1 then begin
        ; loop over slices
        for s=0, sz[3]-1 do begin
          slice=contr_arr[*,*,s]
          slice[ind]=robust_sigma((im[*,*,s])[ind])
          contr_arr[*,*,s]=slice
          ;((contr_arr[*,*,s])[ind])=stddev((im[*,*,s])[ind],/nan)
        endfor
      endif
    endfor

    *self.images.main_image_stack=(im/contr_arr)
    *self.images.main_image=(*self.images.main_image_stack)[*,*,(*self.state).cur_image_num]

    self->getstats
    self->displayall

    status=1
  endif else begin
    self->message, msgtype='error', "SNR map only works with 2D or 3D datacubes"
    status=0
  endelse

end

;;----------------------------------------------------------------------
pro GPItv::low_pass_filter, status=status, forcestack=forcestack
  ;;; routine to remove high frequency structure from cubes
  ;;; PI - 2014-12-10

  widget_control, /hourglass

  if (n_elements((*self.state).image_size) eq 3) or (n_elements((*self.state).image_size) eq 2) then begin


    hd = *((*self.state).head_ptr)
    if ptr_valid((*self.state).exthead_ptr) then exthd = *((*self.state).exthead_ptr) else exthd = ['', 'END']


    ; get the filter and determine the FWHM
    filter = gpi_simplify_keyword_value(gpi_get_keyword(hd, exthd, 'IFSFILT',count=cc, silent=silent))

    ; these are just rough approximations from images. The real values change wrt seeing etc.
    case filter of
      'Y':fwhm=3.0
      'J':fwhm=3.5
      'H':fwhm=4.1
      'K1':fwhm=4.5
      'K2':fwhm=5.0
      else:	begin
        self->message, msgtype='error', "No filter keyword in the header, assuming H-band"
        fwhm=4.1
      end
    endcase

    ; visibility of the cube slice widget is a proxy for whether we are
    ; looking at a cube slice or a combined image (e.g. averaged, medianed)
    visibility = widget_info((*self.state).curimnum_base_id,/map)

    ; if the widget is visible, we are looking slices so we should filter all
    ; of the slices for consistency
    if (visibility eq 1) || keyword_set(forcestack) then begin
      im=*self.images.main_image_stack
      ; careful to smooth using the proper call of filter_image
      ; the runtime doesn't support convolution in fourier space
      ;if LMGR(/runtime) eq 0 then for s=0,N_ELEMENTS(im[0,0,*])-1 do $
      ;im[*,*,s]=filter_image(im[*,*,s],fwhm=fwhm,/all) $
      ;else im[*,*,s]=filter_image(im[*,*,s],fwhm=fwhm, /no_ft,/all)

      ; note that setting the no_ft to zero is bad! it should either be 1 or not declared at all
      ; leaving it as 0 causes the image to fill with nans sometimes (not sure when)
	  ; MP - FIXME this will not work on IDL 7!
      if LMGR(/runtime) eq 1 then no_ft=1 else no_ft=0

      for s=0,N_ELEMENTS(im[0,0,*])-1 do $
        im[*,*,s]=filter_image(im[*,*,s],fwhm=fwhm,/all, no_ft = no_ft)
      *self.images.main_image_stack=im
      *self.images.main_image=(*self.images.main_image_stack)[*,*,(*self.state).cur_image_num]
    endif else begin
      ; we are looking at a collapsed image of some sort so save time by not
      ; filtering all the slices, just the current combined image
      im = *self.images.main_image
      if LMGR(/runtime) eq 0 then im = filter_image(im, fwhm=fwhm,/all) else im = filter_image(im, fwhm=fwhm, /no_ft,/all)
      *self.images.main_image = im
    endelse
    ((*self.state).low_pass_mode) = 1
    self->getstats
    self->displayall

    status=1
  endif else begin
    self->message, msgtype='error', "Low pass filter only works with 2D or 3D datacubes"
    status=0
  endelse

end

;----------------------------------------------------------------------


pro GPItv::high_pass_filter, status=status, forcestack=forcestack
  ;;; routine to remove low frequency structure from cubes
  ;;; PI - 2013-07-24
  ;;; JW - 2014-02-03 Added capability to do stacked images and 2d cubes
  ;;; ds - 2014-11-10 /forcestack forces operation on image_stack
  ;;;      regardless of visibility of slicer

  widget_control, /hourglass

  if (n_elements((*self.state).image_size) eq 3) or (n_elements((*self.state).image_size) eq 2) then begin

    medboxsize = (*self.state).high_pass_size

    ; visibility of the cube slice widget is a proxy for whether we are
    ; looking at a cube slice or a combined image (e.g. averaged, medianed)
    visibility = widget_info((*self.state).curimnum_base_id,/map)

    ; if the widget is visible, we are looking slices so we should filter all
    ; of the slices for consistency
    if (visibility eq 1) || keyword_set(forcestack) then begin
      ;im=*self.images.main_image_stack
      ;im = gpi_highpass_filter_cube(im, boxsize=medboxsize)

      *self.images.main_image_stack= gpi_highpass_filter_cube( *self.images.main_image_stack, boxsize=medboxsize)
      *self.images.main_image=(*self.images.main_image_stack)[*,*,(*self.state).cur_image_num]
    endif else begin
      ; we are looking at a collapsed image of some sort so save time by not
      ; filtering all the slices, just the current combined image
      im = *self.images.main_image
      im -= filter_image(im, median=medboxsize)
      *self.images.main_image = im
    endelse

    ((*self.state).high_pass_mode) = 1
    self->getstats
    self->displayall

    status=1
  endif else begin
    self->message, msgtype='error', "High pass filter only works with 2D or 3D datacubes"
    status=0
  endelse

end

;----------------------------------------------------------------------

pro GPItv::runKLIP, status=status

  ;; front end for KLIP - added 06.19.2013 ds

  widget_control, /hourglass

  if n_elements((*self.state).image_size) eq 3 then begin

    ;;only recalculate klip image if necessary
    if n_elements(*self.images.klip_image) le 1 then begin
      ;;if no satspots in memory, calculate them
      if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
        self->update_sat_spots

        ;;if failed, need to return
        if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
          self->message, msgtype='error', "Cannot align speckles because we cannot determine the center without satellite spots."
          status=0
          return
        endif
      endif

      self->message,msgtype='Information','KLIP processing takes a while, please be patient.'

      Ima2 = speckle_align(*self.images.main_image_stack,$
        band=(*self.state).obsfilt,$
        refslice=(*self.state).cur_image_num,$
        locs=(*self.satspots.cens)[*,*,(*self.state).cur_image_num])

      res =  klip(Ima2, refslice=(*self.state).cur_image_num,$
        band=(*self.state).obsfilt,$
        locs=(*self.satspots.cens),$
        annuli=(*self.state).klip_annuli,$
        movmt=(*self.state).klip_movmt, $
        prop=(*self.state).klip_prop, $
        arcsec=(*self.state).klip_arcsec)
      *self.images.klip_image = res
    endif

    *self.images.main_image_stack = *self.images.klip_image
    (*self.state).specalign_mode = 0
    (*self.state).klip_mode = 1
    (*self.state).specalign_to = (*self.state).cur_image_num

    self->getstats
    self->displayall
    status=1

  endif else begin
    self->message, msgtype='error', "KLIP only works with 3D datacube"
    status=0
  endelse

end

pro GPITV::radial_stokes, status=status

  ;MMB - Started 140716

  im=*self.images.main_image_stack

  ;If we've already transformed the stokes then don't do it again (unless we've rotated the image within radial mode)!
  if ((*self.state).stokesdc_im_mode ne 1) || ((*self.state).rot_angle ne (*self.state).radial_stokes_rot_angle) then begin

    q=im[*,*,1]
    u=im[*,*,2]

    extheader=(*(*self.state).exthead_ptr)

    psfcentx=sxpar(extheader, 'PSFCENTX', count=ct1)
    psfcenty=sxpar(extheader, 'PSFCENTY', count=ct2)

    if ct1+ct2 eq 2 then begin
      indices, im[*,*,0], x,y,z

      ;Get the angle from each pixel to the center (compensating for any any image rotation in GPItv)
      phi=atan((y-psfcenty)/(x-psfcentx))-(*self.state).rot_angle*!dtor

      ;Perform the Transformation
      qr=Q*cos(2*phi)+U*sin(2*phi)
      ur=-Q*sin(2*phi)+U*cos(2*phi)

      ;Put things back in the cube
      im[*,*,1]=qr
      im[*,*,2]=ur

      ;Two new states just for this mode

      if (*self.state).stokesdc_im_mode eq 3 then (*self.state).stokesdc_im_mode=3 else (*self.state).stokesdc_im_mode = 1
      (*self.state).radial_stokes_rot_angle = (*self.state).rot_angle

      status=1
    endif else begin
      self->message, msgtype='error', "No PSFCENT keywords found"
      status=0
    endelse
  endif

  *self.images.main_image_stack=im
  *self.images.main_image=(*self.images.main_image_stack)[*,*,(*self.state).cur_image_num]

end
;----------------------------------------------------------------------


pro GPITV::divide_by_stokesi, status=status

  ;Divide the Stokes Q and U cubes by Stokes I
  ;MMB - Started 150212

  if ((*self.state).stokesdc_im_mode ne 2) and ((*self.state).stokesdc_im_mode ne 3) then begin

    im=*self.images.main_image_stack

    im[*,*,1] /= im[*,*,0]
    im[*,*,2] /= im[*,*,0]

    if (*self.state).stokesdc_im_mode eq 1 then (*self.state).stokesdc_im_mode = 3 else (*self.state).stokesdc_im_mode=2

    *self.images.main_image_stack=im
    *self.images.main_image=(*self.images.main_image_stack)[*,*,(*self.state).cur_image_num]
  endif

end

pro GPItv::tvangu

  ; Routine to display the zoomed region around radial profil center,
  ; with circles showing the radius.


  self->setwindow, (*self.state).anguzoom_window_id
  erase

  x = round((*self.state).cursorpos[0])
  y = round((*self.state).cursorpos[1])
  imacenter= WIDGET_INFO((*self.state).anguprof_imacenter_button, /BUTTON_SET)
  if imacenter then begin
    x=((size(*self.images.main_image))[1])/2
    y=((size(*self.images.main_image))[2])/2
  endif
  ;boxsize = round((*self.state).outersky * 1.2)
  radi=(*self.state).angur
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

  dev_width = 0.8 * (*self.state).photzoom_size
  dev_pos = [0.15 * (*self.state).photzoom_size, $
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

  tvcircle, /data, radi, x, y, $
    color=2, thick=2, psym=0
  ;if ((*self.state).skytype NE 2) then begin
  ;    tvcircle, /data, (*self.state).innersky, (*self.state).centerpos[0], (*self.state).centerpos[1], $
  ;      color=4, thick=2, psym=0
  ;    tvcircle, /data, (*self.state).outersky, (*self.state).centerpos[0], (*self.state).centerpos[1], $
  ;      color=5, thick=2, psym=0
  ;endif

  self->resetwindow
end

;----------------------------------------------------------------------
pro GPItv::anguprof_event, event

  @gpitv_err

  widget_control, event.id, get_uvalue = uvalue

  case uvalue of

    'radius': begin
      widget_control,(*self.state).anguradius_id,get_value=xx
      xxx=uint(xx)
      (*self.state).angur = 1 > xxx < ((size(*self.images.main_image))[1])/2
      self->anguprof_refresh
    end

    'maxr':begin
    maxr= WIDGET_INFO((*self.state).anguprof_maxr_button, /BUTTON_SET)
    if maxr then begin
      widget_control,(*self.state).basemaxr,sensitive=0
      (*self.state).angur=((size(*self.images.main_image))[1])/2
    endif else begin
      widget_control,(*self.state).basemaxr,sensitive=1
      widget_control,(*self.state).anguradius_id,get_value=xx
      (*self.state).angur=uint(xx)
    endelse

    self->anguprof_refresh
  end

  'Imacenter':begin
  x = (*self.state).cursorpos[0]
  y = (*self.state).cursorpos[1]
  imacenter= WIDGET_INFO((*self.state).anguprof_imacenter_button, /BUTTON_SET)
  if imacenter then begin
    x=((size(*self.images.main_image))[1])/2
    y=((size(*self.images.main_image))[2])/2
  endif
  tmp_string = $
    string(x, y, $
    format = '("Cursor position:  x=",i4,"  y=",i4)' )
  widget_control,(*self.state).cursorpos_id_anguprof,set_value =tmp_string
  self->anguprof_refresh
end

'reso':begin
widget_control,(*self.state).angureso_id,get_value=tmp
(*self.state).angureso=tmp
self->anguprof_refresh
end



'showanguplot': begin
  widget_control, (*self.state).showanguplot_id, get_value=val
  case val of
    'Show Angular Profile': begin
      ysize = 350 < ((*self.state).screen_ysize - 350)
      widget_control, (*self.state).anguplot_widget_id, $
        xsize=500, ysize=ysize
      widget_control, (*self.state).showanguplot_id, $
        set_value='Hide Angular Profile'
    end
    'Hide Angular Profile': begin
      widget_control, (*self.state).anguplot_widget_id, $
        xsize=1, ysize=1
      widget_control, (*self.state).showanguplot_id, $
        set_value='Show Angular Profile'
    end
  endcase
  self->anguprof_refresh
end


'anguplot_save': self->anguprof_refresh, /sav

'angu_ps': begin
  fname = strcompress((*self.state).current_dir + 'GPItv_prad.ps', /remove_all)
  forminfo = cmps_form(cancel = canceled, create = create, $
    /preserve_aspect, $
    /color, $
    /nocommon, papersize='Letter', $
    filename = fname, $
    button_names = ['Create PS File'])

  if (canceled) then return
  if (forminfo.filename EQ '') then return

  tmp_result = findfile(forminfo.filename, count = nfiles)

  result = ''
  if (nfiles GT 0) then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = strmid(forminfo.filename, strpos(forminfo.filename, $
      '/') + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
      /default_no, $
      dialog_parent = (*self.state).base_id, $
      /question)
  endif

  if (strupcase(result) EQ 'NO') then return

  widget_control, /hourglass

  screen_device = !d.name

  set_plot, 'ps'
  device, _extra = forminfo

  self->anguprof_refresh, /ps

  device, /close
  set_plot, screen_device

end

'anguprof_done': widget_control, event.top, /destroy
else:
endcase

end

;----------------------------------------------------------------------

pro GPItv::anguprof_refresh, ps=ps,  sav=sav

  ;; Do aperture photometry using idlastro daophot routines.


  x = (*self.state).cursorpos[0]
  y = (*self.state).cursorpos[1]

  imacenter= WIDGET_INFO((*self.state).anguprof_imacenter_button, /BUTTON_SET)
  if imacenter then begin
    x=((size(*self.images.main_image))[1])/2
    y=((size(*self.images.main_image))[2])/2
  endif
  tmp_string =  string(x, y,  format = '("Cursor position:  x=",i4,"  y=",i4)' )

  widget_control,(*self.state).cursorpos_id_anguprof,set_value =tmp_string

  maxr= WIDGET_INFO((*self.state).anguprof_maxr_button, /BUTTON_SET)
  if maxr then begin
    (*self.state).angur=((size(*self.images.main_image))[1])/2
  endif
  ;; Run self->radplotf and plot the results
  prof_image=subarr(*self.images.main_image,2*(*self.state).angur+1,[[x],[y]],/nanout)
  ;;if (not (keyword_set(ps))) then begin
  self->setwindow, (*self.state).anguplot_window_id
  profrad, prof_image, (*self.state).angureso, p1d=p1d, rayon=(*self.state).angur

  ;; overplot the phot apertures on radial plot
  if (not (keyword_set(ps))) then begin
    xx=(*self.state).angureso*(indgen((size(p1d))[1]))
    plot, xx,p1d,ytitle='Flux ['+(*self.state).current_units+']', xtitle='pixel', psym=-1
    self->resetwindow

  endif else begin
    xx=(*self.state).angureso*(indgen((size(p1d))[1]))
    plot, xx,p1d,ytitle='Flux ['+(*self.state).current_units+']', xtitle='pixel', psym=-1

  endelse
  if (not (keyword_set(ps))) then  self->tvangu

  ;;write fits file
  if (keyword_set(sav)) then begin
    ;;synthesize name
    nm = (*self.state).imagename
    strps = strpos(nm,'/',/reverse_search)
    strpe = strpos(nm,'.fits',/reverse_search)
    nm = strmid(nm,strps+1,strpe-strps-1)

    angu_outfile = dialog_pickfile(filter='*.fits', $
      file=nm+'-radial_profile.fits', get_path = tmp_dir, $
      path=(*self.state).current_dir,$
      title='Please Select File to save radial profile')

    IF (strcompress(angu_outfile, /remove_all) EQ '') then RETURN

    IF (angu_outfile EQ tmp_dir) then BEGIN
      self->message, 'Must indicate filename to save.', $
        msgtype = 'error', /window
      return
    ENDIF

    ;;output & header
    out = [[xx],[p1d]]
    mkhdr,hdr,out
    sxaddpar,hdr,'CENTER_X',x,'x coord of aperture center'
    sxaddpar,hdr,'CENTER_Y',y,'y coord of aperture center'
    sxaddpar,hdr,'RADIUS',(*self.state).angur,'Radius of aperture'
    sxaddpar,hdr,'PIX_RES',(*self.state).angureso,'Pixel resolution'

    ;;write
    writefits,angu_outfile,out,hdr
  endif

  ; Uncomment next lines if you want GPItv to output the WCS coords of
  ; the centroid for the photometry object:
  ;if ((*self.state).wcstype EQ 'angle') then begin
  ;    xy2ad, (*self.state).centerpos[0], (*self.state).centerpos[1], *((*self.state).astr_ptr), $
  ;      clon, clat
  ;    wcsstring = GPItv_wcsstring(clon, clat, (*(*self.state).astr_ptr).ctype,  $
  ;                (*self.state).equinox, (*self.state).display_coord_sys, (*self.state).display_equinox)
  ;    print, 'Centroid WCS coords: ', wcsstring
  ;endif

  self->resetwindow
end


;----------------------------------------------------------------------
pro GPItv::anguprof

  ; aperture radial profil front end


  (*self.state).cursorpos = (*self.state).coord

  if (not (xregistered(self.xname+'_anguprof'))) then begin

    anguprof_base = $
      widget_base(/base_align_center, $
      group_leader = (*self.state).base_id, $
      /column, $
      title = 'GPItv angular profile', $
      uvalue = 'anguprof_base')

    anguprof_top_base = widget_base(anguprof_base, /row, /base_align_center)

    anguprof_data_base1 = widget_base( $
      anguprof_top_base, /column, frame=0)

    anguprof_data_base2 = widget_base( $
      anguprof_top_base, /column, frame=0)

    anguzoom_widget_id = widget_draw( $
      anguprof_data_base2, $
      scr_xsize=(*self.state).photzoom_size, scr_ysize=(*self.state).photzoom_size)

    anguprof_draw_base = widget_base( $
      anguprof_base, /row, /base_align_center, frame=0)

    anguprof_data_base1a = widget_base(anguprof_data_base1, /column, frame=1)
    anguprof_data_base1a0 = widget_base(anguprof_data_base1a, /row)
    tmp_string = $
      string(1000, 1000, $
      format = '("Cursor position:  x=",i4,"  y=",i4)' )

    (*self.state).cursorpos_id_anguprof = $
      widget_label(anguprof_data_base1a0, $
      value = tmp_string, $
      uvalue = 'cursorpos', /align_left)
    basecenter = Widget_Base(anguprof_data_base1a0,   $
      COLUMN=1 ,/NONEXCLUSIVE)


    (*self.state).anguprof_imacenter_button = Widget_Button(basecenter,   $
      /ALIGN_LEFT ,VALUE='Image center',uvalue = 'Imacenter')
    ; Widget_control,(*self.state).anguprof_imacenter_button,/SET_BUTTON

    anguprof_data_base1a1 = widget_base(anguprof_data_base1a, /row)

    (*self.state).basemaxr = Widget_Base(anguprof_data_base1a1, /ROW,$
      sensitive=1)
    void=WIDGET_LABEL((*self.state).basemaxr,value='Aperture radius:', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).anguradius_id = $
      WIDGET_TEXT((*self.state).basemaxr, $
      /editable, $
      uvalue = 'radius', $
      value = strcompress(string((*self.state).angur)),xsize=8)

    basecenter2 = Widget_Base(anguprof_data_base1a1,   $
      COLUMN=1 ,/NONEXCLUSIVE)
    (*self.state).anguprof_maxr_button = Widget_Button(basecenter2,   $
      /ALIGN_LEFT ,VALUE='max radius',uvalue = 'maxr')
    ;Widget_control,(*self.state).anguprof_maxr_button,/SET_BUTTON

    anguprof_data_base1a2 = Widget_Base(anguprof_data_base1a,  /row)
    void=WIDGET_LABEL(anguprof_data_base1a2,value='Pixel resolution:', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).angureso_id = $
      WIDGET_TEXT(anguprof_data_base1a2, $
      /editable, $
      uvalue = 'reso', $
      value = strcompress(string((*self.state).angureso)),xsize=8)

    anguplot_log_save = $
      widget_button(anguprof_data_base1, $
      value = 'Save Angular Profile', $
      uvalue = 'anguplot_save')

    ;    angu_ps = $
    ;      widget_button(anguprof_data_base1, $
    ;                    value = 'Create Profile PS', $
    ;                    uvalue = 'angu_ps')

    (*self.state).showanguplot_id = $
      widget_button(anguprof_data_base1, $
      value = 'Hide Angular Profile', $
      uvalue = 'showanguplot')

    (*self.state).anguplot_widget_id = widget_draw( $
      anguprof_draw_base, scr_xsize=500, $
      scr_ysize=(350 < ((*self.state).screen_ysize - 350)))

    anguprof_done = $
      widget_button(anguprof_data_base2, $
      value = 'Done', $
      uvalue = 'anguprof_done')

    widget_control, anguprof_base, /realize

    widget_control, anguzoom_widget_id, get_value=tmp_value
    (*self.state).anguzoom_window_id = tmp_value
    widget_control, (*self.state).anguplot_widget_id, get_value=tmp_value
    (*self.state).anguplot_window_id = tmp_value

    ;  xmanager, 'GPItv_anguprof', anguprof_base, /no_block
    xmanager, self.xname+'_anguprof', anguprof_base, /no_block
    widget_control, anguprof_base, set_uvalue={object:self, method: 'anguprof_event'}
    widget_control, anguprof_base, event_pro = 'GPItvo_subwindow_event_handler'
    self->resetwindow
  endif

  self->anguprof_refresh
end

;--------------------------------------------------------------------------------
pro GPItv::KLIP_settings

  ;; Routine to get user input on various KLIP settings
  annuli_line = strcompress('0, float,'+string((*self.state).klip_annuli) + $ ;1
    ',label_left = # of Annuli:,' + $
    'width = 10')
  movmt_line = strcompress('0, float,'+string((*self.state).klip_movmt) + $ ;2
    ',label_left = Min pix move:,' + $
    'width = 10')
  prop_line= strcompress('0, float,'+string((*self.state).klip_prop) + $ ;3
    ',label_left = Trunc. ratio:,' + $
    'width = 10')
  arcsec_line= strcompress('0, float,'+string((*self.state).klip_arcsec) + $ ;4
    ',label_left = Targ Radius (as):,' + $
    'width = 10')

  formdesc = ['0, label, Select options for KLIP', $
    annuli_line,movmt_line,prop_line,arcsec_line,$
    '0, button, Save Settings, quit', $ ;5
    '0, button, Cancel, quit']          ;6

  textform = cw_form(formdesc, /column, $
    title = 'GPItv KLIP settings')

  if (textform.tag6 EQ 1) then return ; cancelled (tag# = # of inputs above+2)

  (*self.state).klip_annuli = textform.tag1
  (*self.state).klip_movmt = textform.tag2
  (*self.state).klip_prop = textform.tag3
  (*self.state).klip_arcsec = textform.tag4

  ;;kill any existing klip image
  self.images.klip_image = ptr_new(/allocate_heap)

end

;----------------------------------------------------------------------

pro GPItv::high_pass_filter_settings

  ;; Routine to get user input on various high pass settings
  box_line = strcompress('0, float,'+string((*self.state).high_pass_size) + $ ;1
    ',label_left = Median Box Size:,' + $
    'width = 10')

  formdesc = ['0, label, Select options for high pass filter', $
    box_line,$
    '0, button, Save Settings, quit', $ ;5
    '0, button, Cancel, quit']          ;6

  if (*self.state).multisess GT 0 then title = "GPItv #"+strc((*self.state).multisess) else title="GPItv"
  title += " High pass filter settings"
  textform = cw_form(formdesc, /column,  title = title)

  if (textform.tag3 EQ 1) then return ; cancelled (tag# = # of inputs above+2)

  (*self.state).high_pass_size = textform.tag1


end


;----------------------------------------------------------------------

pro GPItv::statvsr,color=color,linestyle=linestyle,xrange=xrange,yrange=yrange,$
  overplot=overplot,xlog=xlog,$
  silent=silent,xtitle=xtitle,ytitle=ytitle,psym=psym,$
  symsize=symsize,mapsig=mapsig, data = data

  ;; as of 08/07/12 this is just a plotting frontend.  All calculations
  ;; are done in radial_profile.pro, which is called from
  ;; contrprof_refresh
  ;; all inputs are now optional, as the actual contour profile is
  ;; stored in the common pointer heap.  However, x & y data can be
  ;; passed in via the data keyword


  ;Optional inputs
  ;-------------------------------
  ;color: determine la couleur des courbes, vecteur, les courbes sont
  ;       plottees dans l'ordre, dot, med, sig
  ;linestyle: determine le style du trait des courbes, vecteur, les courbes sont
  ;           plottees dans l'ordre, med, sig
  ;xrange:
  ;yrange:
  ;overplot: pour faire un oplot
  ;/xlog:
  ;

  if not keyword_set(data) then begin
    ;;check to make sure that we actually have a valid contour profile in
    ;;memory
    if (*self.state).contr_plotmult then inds = (*self.satspots.good) else $
      inds = (*self.state).cur_image_num
    if n_elements(*(*self.satspots.contrprof)[inds[0],(*self.state).contr_yunit]) eq 0 then begin
      self->message, msgtype='error', 'No valid contour profile exists.'
      return
    endif
  endif else inds = 0

  ;;set up graphs
  self->setwindow, (*self.state).contrplot_window_id
  erase

  ;;set proper scale unit
  if (*self.state).contr_yunit eq 0 then sclunit = (*self.state).contrsigma else sclunit = 1d

  ;;set color
  if (not keyword_set(color)) then begin
    if ~(*self.state).contr_plotmult then color = [1] else begin
      color = round(findgen((*self.state).image_size[2])/$
        ((*self.state).image_size[2]-1)*100.+100.)
    endelse
  endif

  ;;other plot stuff
  if (not keyword_set(linestyle)) then linestyle=[0,2,3,5]
  if (not keyword_set(psym)) then psym = [4,1,2,5,6]
  if (not keyword_set(symsize)) then symsize=1.

  ;;get plot ranges, if none given
  if (not keyword_set(xrange)) then begin

    if not keyword_set(data) then asec = *(*self.satspots.asec)[inds[0]] else $
      asec = data.asec
    if (*self.state).contr_xunit eq 1 then $
      asec *= 1d/3600d*!dpi/180d*gpi_get_constant('primary_diam',default=7.7701d0)/((*(*self.state).CWV_ptr)[inds[0]]*1d-6)
    xrange=[min(asec),max(asec)]
    for j=1,n_elements(inds)-1 do begin
      asec = *(*self.satspots.asec)[inds[j]]
      if (*self.state).contr_xunit eq 1 then $
        asec *= 1d/3600d*!dpi/180d*gpi_get_constant('primary_diam',default=7.7701d0)/((*(*self.state).CWV_ptr)[inds[j]]*1d-6)
      xrange[0] = xrange[0] < min(asec)
      xrange[1] = xrange[1] > max(asec)
    endfor
  endif
  if not(keyword_set(yrange)) or (*self.state).contr_yaxis_mode then begin
    if not keyword_set(data) then tmp = *(*self.satspots.contrprof)[inds[0],(*self.state).contr_yunit] else $
      tmp = data.contrprof
    tmp = tmp[where(finite(tmp) and tmp gt 0)] * sclunit
    yrange = [min(tmp),max(tmp)]
    for j=1,n_elements(inds)-1 do begin
      tmp = *(*self.satspots.contrprof)[inds[j],(*self.state).contr_yunit]
      tmp = tmp[where(finite(tmp) and tmp gt 0)] * sclunit
      yrange[0] = yrange[0] < min(tmp)
      yrange[1] = yrange[1] > max(tmp)
    endfor
  endif
  ;;Tick labels don't appear if yrange less than an order
  ;;of magnitude, so check for that
  if floor(alog10(max(yrange))) eq floor(alog10(min(yrange))) then begin
    ;;As of now no labels will be drawn on Y-axis, so set them by hand
    ytickv = 10.^floor(alog10(min(yrange))) * (findgen(10)+1)
    ytickv = ytickv(where(ytickv ge min(yrange) and ytickv le max(yrange)))
    yticks = n_elements(ytickv)-1
  endif

  ;;figure out title
  widget_control,(*self.state).contrwarning_id,get_value=warn
  if strcmp(warn,'Warnings: Possible Misdetection: Fluxes vary >25%') then $
    title='Warning: Possible Misdetection: Fluxes vary >25%' else $
    title = ''

  ;;plot contrast
  if not(keyword_set(overplot)) then begin
    plot,[0],[0],ylog=(*self.state).contr_yaxis_type,xlog=xlog,xrange=xrange,yrange=yrange,/xstyle,/ystyle,$
      xtitle=xtitle,ytitle=ytitle,/nodata, charsize=(*self.state).contr_font_size, title=title,ytickv=ytickv,yticks=yticks
  endif
  for j = 0, n_elements(inds)-1 do begin
    if not keyword_set(data) then asec = *(*self.satspots.asec)[inds[j]] else $
      asec = data.asec
    if (*self.state).contr_xunit eq 1 then $
      asec *= 1d/3600d*!dpi/180d*gpi_get_constant('primary_diam',default=7.7701d0)/((*(*self.state).CWV_ptr)[inds[j]]*1d-6)

    if not keyword_set(data) then tmp = *(*self.satspots.contrprof)[inds[j],(*self.state).contr_yunit] else $
      tmp = data.contrprof

    oplot,asec,tmp[*,0] * sclunit, color=color[j],linestyle=linestyle[0]
    if (*self.state).contr_plotouter then oplot,asec,tmp[*,1] * sclunit, color=color[j],linestyle=linestyle[1]
  endfor
  xyouts, /normal,0.6,0.8,'Star Magnitude = '+strtrim(strmid(*self.satspots.mags,0,10),2),charsize=1.2

end

;;-------------------------------------------------------------

pro GPItv::tvcontr, nosat=nosat, ps3=ps3, nodh=nodh

  ;; Routine to display the image used for the contrast plot
  ;; with circles showing the satellite spots.


  self->setwindow, (*self.state).contrzoom_window_id
  erase

  x=((size(*self.images.main_image))[1])/2
  y=((size(*self.images.main_image))[2])/2

  ;boxsize = round((*self.state).outersky * 1.2)
  radi=((size(*self.images.main_image))[1])/2
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

  dev_width = 0.8 * (*self.state).photzoom_size
  dev_pos = [0.15 * (*self.state).photzoom_size, $
    0.15 * (*self.state).photzoom_size, $
    0.95 * (*self.state).photzoom_size, $
    0.95 * (*self.state).photzoom_size]

  x_factor = dev_width / xsize
  y_factor = dev_width / ysize
  x_offset = (x_factor - 1.0) / x_factor / 2.0
  y_offset = (y_factor - 1.0) / y_factor / 2.0
  xi = findgen(dev_width) / x_factor - x_offset       ;x interp index
  yi = findgen(dev_width) / y_factor - y_offset       ;y interp index

  image = Poly_2D(image, [[0,0],[1.0/x_factor,0]], $
    [[0,1.0/y_factor],[0,0]], $
    0, dev_width, dev_width)

  xsize = (size(image))[1]
  ysize = (size(image))[2]
  out_xs = xi * xs_delta + xs[0]
  out_ys = yi * ys_delta + ys[0]

  sz = size(image)
  xsize = Float(sz[1])          ;image width
  ysize = Float(sz[2])          ;image height
  dev_width = dev_pos[2] - dev_pos[0] + 1
  dev_width = dev_pos[3] - dev_pos[1] + 1

  tv, image, /device, dev_pos[0], dev_pos[1], $
    xsize=dev_pos[2]-dev_pos[0], $
    ysize=dev_pos[3]-dev_pos[1]

  plot, [0, 1], /noerase, /nodata, xstyle = 1, ystyle = 1, $
    /device, position = dev_pos, color=7, $
    xrange = x_ran, yrange = y_ran

  if  not(keyword_set(ps3)) then begin
    ;;determine which index to use
    if (*self.state).specalign_mode eq 1 then ind = (*self.state).specalign_to else $
      ind = (*self.state).cur_image_num

    ;;find center
    xc = mean( (*self.satspots.cens)[0,*,ind] )
    yc = mean( (*self.satspots.cens)[1,*,ind] )

    ;;circle sat spots
    if not(keyword_set(nosat)) then begin
      for i=0,3 do $
        tvcircle, /data, (*self.state).contrap+10, $
        (*self.satspots.cens)[0,i,ind],$
        (*self.satspots.cens)[1,i,ind],$
        color=2, thick=2, psym=0
      oplot, [xc], [yc], psym=1, symsize=3, color=0, thick=2
    endif

    ;;highlight the dark hole edge
    if not(keyword_set(nodh)) then begin
      lambda = (*(*self.state).CWV_ptr)[ind]
      pixscl = gpi_get_ifs_lenslet_scale(*(*self.state).exthead_ptr,res=res)
      if res lt 0 then self->message, msgtype = 'information', 'Missing valid WCS: using constant file value.'

      pix_to_ripple = gpi_get_constant('pix_to_ripple',default = $
        44d0*1d-6/gpi_get_constant('primary_diam',default=7.7701d0)*$
        180d0/!dpi*3600d0/pixscl*1.5040541d)
      pix_to_ripple *= lambda/1.5040541d

      memsrot = gpi_get_constant('mems_rotation',default=1d0)
      memsrot *= !dpi/180d

      satang = atan(((*self.satspots.cens)[1,*,ind] - yc)/$
        ((*self.satspots.cens)[0,*,ind] - xc))
      binds = where(satang lt 0, ct)
      if ct gt 0 then satang[binds] += !dpi/2d
      rotang = mean(satang) - memsrot - 45d0*!dpi/180d0
      rotMat = [[cos(rotang),-sin(rotang)],$
        [sin(rotang),cos(rotang)]]

      dhl = ceil(pix_to_ripple/2)
      x = [-dhl,dhl,dhl,-dhl,-dhl]
      y = [-dhl,-dhl,dhl,dhl,-dhl]
      dh_inds = rotMat ## [[x],[y]]
      oplot, dh_inds[*,0]+xc, dh_inds[*,1]+yc, psym=0, color=2, thick=2
    endif
  endif

  ;;if ((*self.state).skytype NE 2) then begin
  ;;    tvcircle, /data, (*self.state).innersky, (*self.state).centerpos[0], (*self.state).centerpos[1], $
  ;;      color=4, thick=2, psym=0
  ;;    tvcircle, /data, (*self.state).outersky, (*self.state).centerpos[0], (*self.state).centerpos[1], $
  ;;      color=5, thick=2, psym=0
  ;;endif

  self->resetwindow
end


;----------------------------------------------------------------------
pro GPItv::contrprof_event, event

  @gpitv_err

  widget_control, event.id, get_uvalue = uvalue

  case uvalue of
    'gridfac':begin
    widget_control,(*self.state).contrgridfac_id,get_value=xx
    (*self.state).gridfac=double(xx)
    self->contrprof_refresh,/forcecalc
  end

  'cent1':self->contrprof_refresh

  'radius': begin
    widget_control,(*self.state).contrradius_id,get_value=xx
    xxx=uint(xx)
    (*self.state).contrr = 1 > xxx < ((size(*self.images.main_image))[1])/2
    self->contrprof_refresh
  end

  'maxr':begin
  maxr= WIDGET_INFO((*self.state).contrprof_maxr_button, /BUTTON_SET)
  if maxr then begin
    widget_control,(*self.state).basemaxr,sensitive=0
    (*self.state).contrr=((size(*self.images.main_image))[1])/2
  endif else begin
    widget_control,(*self.state).basemaxr,sensitive=1
    widget_control,(*self.state).contrradius_id,get_value=xx
    (*self.state).contrr=uint(xx)
  endelse
  self->contrprof_refresh
end

'Imacenter':begin
x = (*self.state).cursorpos[0]
y = (*self.state).cursorpos[1]
imacenter= WIDGET_INFO((*self.state).contrprof_imacenter_button, /BUTTON_SET)
if imacenter then begin
  x=((size(*self.images.main_image))[1])/2
  y=((size(*self.images.main_image))[2])/2
endif
tmp_string = $
  string(x, y, $
  format = '("Cursor position:  x=",i4,"  y=",i4)' )
widget_control,(*self.state).cursorpos_id,set_value =tmp_string
self->contrprof_refresh
end

'reso':begin
widget_control,(*self.state).contrreso_id,get_value=(*self.state).contrreso
self->contrprof_refresh
end

'showcontrplot': begin
  widget_control, (*self.state).showcontrplot_id, get_value=val
  case val of
    'Show contrast Profile': begin
      ysize = 350 < ((*self.state).screen_ysize - 350)
      widget_control, (*self.state).contrplot_widget_id, $
        xsize=500, ysize=ysize
      widget_control, (*self.state).showcontrplot_id, $
        set_value='Hide contrast Profile'
    end
    'Hide contrast Profile': begin
      widget_control, (*self.state).contrplot_widget_id, $
        xsize=1, ysize=1
      widget_control, (*self.state).showcontrplot_id, $
        set_value='Show contrast Profile'
    end
  endcase
  self->contrprof_refresh
end


'contrplot_save': self->contrprof_refresh, /sav
'contr_plot_refresh': self->contrprof_refresh
'satellite_refresh': begin
	self.satspots.attempted = 0 ; forget about any past attempts that might have failed and retry anyway.
	self->contrprof_refresh,/forcesat
end
'contr_radial': self->contrprof_refresh, /radialsav

'contr_ps': begin
  fname = strcompress((*self.state).current_dir + path_sep()+ 'GPItv_contr.ps', /remove_all)
  forminfo = cmps_form(cancel = canceled, create = create, $
    /preserve_aspect, $
    /color, $
    /nocommon, papersize='Letter', $
    filename = fname, $
    button_names = ['Create PS File'])

  if (canceled) then return
  if (forminfo.filename EQ '') then return

  tmp_result = findfile(forminfo.filename, count = nfiles)

  result = ''
  if (nfiles GT 0) then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = strmid(forminfo.filename, strpos(forminfo.filename, $
      '/') + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
      /default_no, $
      dialog_parent = (*self.state).base_id, $
      /question)
  endif

  if (strupcase(result) EQ 'NO') then return

  widget_control, /hourglass

  screen_device = !d.name

  set_plot, 'ps'
  device, _extra = forminfo

  self->contrprof_refresh, /ps

  device, /close
  set_plot, screen_device
  self->message, msgtype = 'information', 'Postscript plot saved to '+forminfo.filename
end

'contr_plot_options': self->contrast_settings
'contrprof_done': widget_control, event.top, /destroy
else:
endcase

end

;--------------------------------------------------------------------------------
pro GPItv::obsnotes

  if (*self.state).imagename eq "NO IMAGE LOADED   " then begin
    self->message, msgtype='warning', 'No image loaded - nothing to mark.'
    return
  end
  ;; Frontend for bad file marking in files database

  mark = strcompress('0, button, Mark OK|Mark Bad, exclusive, set_value = 0') ;1
  notes = strcompress('0, text, ,label_left = Notes:,width = 70,') ;2

  formdesc = ['0, label, Write To GPIES Files Database', $
	  '0, label, (this will do nothing if you lack GPIES campaign database access)', $
    mark,notes,$
    '0, button, Send, quit', $
    '0, button, Cancel, quit']

  textform = cw_form(formdesc, /column, $
    title = 'GPItv Mark File Status')

  if (textform.tag5 EQ 1) then return ; cancelled (tag# = # of inputs above+2)

  mrkval  = textform.tag2
  msgval = textform.tag3

  gpitv_obsnotes,(*self.state).imagename,mrkval,msgval,errout=errout,$
                 curlpath=gpi_get_setting('gpitv_curl_path',default='')
  if errout then self->message, msgtype='error', 'Could not mark file.'

end


;--------------------------------------------------------------------------------
pro GPItv::contrast_settings


  ;; Routine to get user input on various contrast plot settings
  plotline = strcompress('0, button, Linear|Log, exclusive,' + $      ;1
    'label_left = Select Plot Scale: , set_value =' + $
    string( (*self.state).contr_yaxis_type))
  yrange = strcompress('1, button, Manual|Auto, exclusive,' + $       ;2
    'label_left = Y Range:, set_value =' + $
    string( (*self.state).contr_yaxis_mode))
  yminline= strcompress('0, float,'+string((*self.state).contr_yaxis_min) + $  ;3
    ',label_left = Y axis minimum:,' + $
    'width = 12')
  ymaxline = strcompress('2, float,'+string((*self.state).contr_yaxis_max) + $  ;4
    ',label_left = Y axis maximum:,' + $
    'width = 12')
  fontline = strcompress('0, float,'+string((*self.state).contr_font_size) + $  ;5
    ',label_left = Font size:,' + $
    'width = 12')
  plotmult = strcompress('1, button, Current|All, exclusive,' + $              ;6
    'label_left = Select Image Slice: , set_value =' + $
    string( (*self.state).contr_plotmult))
  plotouter = strcompress('2, button, Dark Hole Only|All Image, exclusive,' + $  ;7
    'label_left = Plot Contrast In:, set_value =' + $
    string( (*self.state).contr_plotouter))
  autocent = strcompress('0, button, Auto Locate Sat Spots|Use Highpass Filter|Constrain Spot Locs,' + $ ;8
    ' set_value = ' + $
    '['+strtrim((*self.state).contr_autocent,2)+'\,'+strtrim((*self.state).contr_highpassspots,2)+'\,'+strtrim((*self.state).contr_constspots,2)+']')
  yunits = strcompress('1, button, Sigma|Median|Mean, exclusive,' + $ ;9
    'label_left = Contrast Y units:, set_value =' + $
    string( (*self.state).contr_yunit))
  xunits = strcompress('2, button, Arcseconds|l/D, exclusive,' + $ ;10
    'label_left = Contrast X units:, set_value =' + $
    string( (*self.state).contr_xunit))
  ftype = strcompress('0, button, FITS|TXT|FITS TABLE, exclusive,' + $ ;11
    'label_left = Profile Filetype:, set_value =' + $
    string( (*self.state).contr_prof_filetype))

  formdesc = ['0, label, Select options for contrast plot display', $
    plotline, yrange, yminline, ymaxline, fontline,$
    plotmult, plotouter,autocent, yunits, xunits, ftype,$
    '0, button, Apply Settings, quit', $
    '0, button, Cancel, quit']

  textform = cw_form(formdesc, /column, $
    title = 'GPItv Contrast Plot settings')

  if (textform.tag13 EQ 1) then return ; cancelled (tag# = # of inputs above+2)

  (*self.state).contr_yaxis_type = textform.tag1
  (*self.state).contr_yaxis_mode = textform.tag2
  (*self.state).contr_yaxis_min = textform.tag3
  (*self.state).contr_yaxis_max = textform.tag4
  (*self.state).contr_font_size = textform.tag5
  (*self.state).contr_plotmult = textform.tag6
  (*self.state).contr_plotouter = textform.tag7
  (*self.state).contr_autocent = (textform.tag8)[0]
  (*self.state).contr_highpassspots = (textform.tag8)[1]
  (*self.state).contr_constspots = (textform.tag8)[2]
  (*self.state).contr_yunit = textform.tag9
  (*self.state).contr_xunit = textform.tag10
  (*self.state).contr_prof_filetype = textform.tag11

  if not xregistered(self.xname+'_contrprof',/noshow) then return

  ;;update sensitivity of sat spot inputs
  for j=0,3 do if (*self.state).contrcen_base_ids[j] ne 0 then $
    widget_control,(*self.state).contrcen_base_ids[j], sensitive = 1 - (*self.state).contr_autocent

  self->contrprof_refresh

end

;----------------------------------------------------------------------

pro GPItv::clear_contrprof_windows

  ;;clear window
  self->setwindow, (*self.state).contrplot_window_id
  erase
  self->setwindow, (*self.state).contrzoom_window_id
  erase

end


;----------------------------------------------------------------------

pro GPItv::contrprof_refresh, ps=ps,  sav=sav, radialsav=radialsav,noplot=noplot, $
  forcesat=forcesat,forcecalc=forcecalc
  ;; Plot contrast relative to PSF peak using satellite spots.

  ;;if no image lodaed, nothing to do
  if n_elements(*self.images.names_stack) eq 0 then return

  ;;don't support non-cubes
  if (*self.state).image_size[2] lt 2 then return

  if ~strcmp((*self.state).cube_mode, 'WAVE') then begin
    self->message, msgtype='warning', 'Contrast calculation currently only supported for spectral cubes.'
    self->clear_contrprof_windows
    return
  endif

  ;;if this is image doesn't look like it has sat spots, don't waste
  ;;time on it (unless forced or a special case)
  if ~(keyword_set(forcesat))  && ((*self.state).collapse eq 0)  && $
    ((*self.state).current_units ne 'Contrast')  && $
    (strpos(strupcase((*self.state).filetype),'ADI') eq -1) then begin
    apod = gpi_simplify_keyword_value(sxpar((*(*self.state).head_ptr),'APODIZER'))
    if (median((*self.images.main_image)[where(finite(*self.images.main_image))]) lt 1.) || (strlen(strtrim(apod,2)) gt 2) then begin
      self->message, msgtype='warning', 'This image does not appear to have satellite spots.'
      self->message, msgtype='warning', 'If you disagree, press Find Sat Spots.'
      self->clear_contrprof_windows
      return
    endif
  endif

  ;;if gridfac is nan, bail out
  if ~finite((*self.state).gridfac) then begin
    self->message,msgtype='warning','The sat spot flux ratio is currently NaN, indicating that the apodizer for this image could not be matched.  To generate the contrast curve, please enter the proper value in the contrast profile window.'
    self->clear_contrprof_windows
    return
  endif

  ;; if we're not auto-centering, get the user input for
  ;; initial sat spot locations
  if ~(*self.state).contr_autocent && ~keyword_set(noplot) then begin
    widget_control,(*self.state).contrcen1x_id,get_value=xx
    (*self.state).contrcen_x[0]=uint(xx)
    widget_control,(*self.state).contrcen1y_id,get_value=xx
    (*self.state).contrcen_y[0]=uint(xx)
    widget_control,(*self.state).contrcen2x_id,get_value=xx
    (*self.state).contrcen_x[1]=uint(xx)
    widget_control,(*self.state).contrcen2y_id,get_value=xx
    (*self.state).contrcen_y[1]=uint(xx)
    widget_control,(*self.state).contrcen3x_id,get_value=xx
    (*self.state).contrcen_x[2]=uint(xx)
    widget_control,(*self.state).contrcen3y_id,get_value=xx
    (*self.state).contrcen_y[2]=uint(xx)
    widget_control,(*self.state).contrcen4x_id,get_value=xx
    (*self.state).contrcen_x[3]=uint(xx)
    widget_control,(*self.state).contrcen4y_id,get_value=xx
    (*self.state).contrcen_y[3]=uint(xx)

    locs0 = dblarr(2,4)
    for j=0,3 do locs0[*,j] = double([(*self.state).contrcen_x[j],(*self.state).contrcen_y[j]])
  endif

  widget_control,(*self.state).contrwinap_id,get_value=xx
  (*self.state).contrwinap=uint(xx)
  widget_control,(*self.state).contrap_id,get_value=xx
  (*self.state).contrap=uint(xx)

  widget_control,(*self.state).contrsigma_id,get_value=xx
  (*self.state).contrsigma=float(xx)

  widget_control, /hourglass

  ;;if none exist in memory (or are the wrong size), get the sat spot
  ;;locations
  ;;also, do this always if you're in manual mode (i.e., user
  ;;wants to override)
  if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) || $
    keyword_set(forcesat) || $
    (~(*self.state).contr_autocent and not(keyword_set(ps)) and not(keyword_set(sav)) and not(keyword_set(radial_sav))) $
    then begin
    self->update_sat_spots,locs0=locs0
    ;;if failed, bail
    if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
		self->message, "Failed to locate sat spots"
      self->clear_contrprof_windows
      return
    endif
  endif

  ;;check for warnings
  case (*self.satspots.warns)[(*self.state).cur_image_num] of
    0: widget_control,(*self.state).contrwarning_id,set_value='Warnings: none'
    1: widget_control,(*self.state).contrwarning_id,set_value='Warnings: Possible Misdetection: Fluxes vary >25%'
    -1: begin
      if ~(*self.state).contr_plotmult then begin
        widget_control,(*self.state).contrwarning_id,set_value='Warnings: **** Satellite PSF '+strc(i+1)+' not well detected ****'
        self->clear_contrprof_windows
        self->tvcontr, /nosat
        return
      endif
    end
  endcase

  ;;update display
  for i=0,3 do begin
    tmp_string = string( (*self.satspots.cens)[0,i,(*self.state).cur_image_num],$
      (*self.satspots.cens)[1,i,(*self.state).cur_image_num],$
      format = '("Sat'+strc(i+1)+' position:  x=",g14.7,"  y=",g14.7)' )
    widget_control,(*self.state).satpos_ids[i],set_value=tmp_string
  endfor

  ;;if we're showing slices, do the usual thing.  However, if you're
  ;;in a collapse mode, we're going to do a one-off for that mode only

  ;;we only need to update a given slice's profile if the
  ;;contrprof pointer has been reset (has zero dim)  or the total value of
  ;;the slice's entry is zero (has been allocated but not
  ;;filled in yet)
  if ((*self.state).collapse eq 0) || ((*self.state).specalign_mode eq 1) || $
    ((*self.state).klip_mode eq 1) || ((*self.state).high_pass_mode eq 1) || $
    ((*self.state).low_pass_mode eq 1) || ((*self.state).snr_map_mode eq 1) then begin
    if (*self.state).contr_plotmult then inds = (*self.satspots.good) else $
      inds = (*self.state).cur_image_num
    copsf = (*self.images.main_image_stack)[*,*,inds]
  endif else begin
    copsf = *self.images.main_image
    inds = (*self.state).cur_image_num
  endelse
  ;;if you're specaligned, all of the sat spots will be at
  ;;the locations of the ones in the slice you're aligned
  ;;to.  otherwise, just use the stored satspot locations
  if ((*self.state).specalign_mode eq 1) then begin
    cens = dblarr(2,4,n_elements(inds))
    for j = 0,n_elements(inds)-1 do cens[*,*,j] = (*self.satspots.cens)[*,*,(*self.state).specalign_to]
  endif else cens = (*self.satspots.cens)[*,*,inds]

  for j = 0, n_elements(inds)-1 do begin
    ;;scale by sat spot mean
    copsf[*,*,j] = copsf[*,*,j]/((1./(*self.state).gridfac)*mean((*self.satspots.satflux)[*,inds[j]]))

    ;;conditions in which you would re-calculate the profile:

    if keyword_set(forcecalc) || $                                                              ;/forcecalc set
      (((*self.state).collapse ne 0) && ((*self.state).specalign_mode ne 1)) || $              ;this is a collapse mode
      (n_elements(*(*self.satspots.contrprof)[inds[j],(*self.state).contr_yunit]) eq 0) || $   ;pointers have been reset
      (total((*(*self.satspots.contrprof)[inds[j],(*self.state).contr_yunit])[*,0]) eq 0) || $ ;allocated but not filled
      (((*self.state).contr_plotouter eq 1) && $                                               ;need to do profile outside the darkhole
      (((size(*(*self.satspots.contrprof)[inds[j],(*self.state).contr_yunit]))[0] eq 1) || $  ;second dim never allocated
      (total((*(*self.satspots.contrprof)[inds[j],(*self.state).contr_yunit])[*,1]) eq 0))) then begin

      ;; get the radial profile desired
		case (*self.state).contr_yunit of
			0: radial_profile,copsf[*,*,j],cens[*,*,j],$
					lambda=(*(*self.state).CWV_ptr)[inds[j]],asec=asec,isig=outval,$
					/dointerp,doouter=(*self.state).contr_plotouter
			1: radial_profile,copsf[*,*,j],cens[*,*,j],$
					lambda=(*(*self.state).CWV_ptr)[inds[j]],asec=asec,imed=outval,$
					/dointerp,doouter=(*self.state).contr_plotouter
			2: radial_profile,copsf[*,*,j],cens[*,*,j],$
					lambda=(*(*self.state).CWV_ptr)[inds[j]],asec=asec,imn=outval,$
					/dointerp,doouter=(*self.state).contr_plotouter
		endcase

      if ((*self.state).collapse eq 0) || ((*self.state).specalign_mode eq 1) || $
        ((*self.state).klip_mode eq 1) || ((*self.state).high_pass_mode eq 1) || $
        ((*self.state).low_pass_mode eq 1) || ((*self.state).snr_map_mode eq 1) then begin
        ;;write asec and radial profile to proper array
        *(*self.satspots.contrprof)[inds[j],(*self.state).contr_yunit] = outval
        *(*self.satspots.asec)[inds[j]] = asec
      endif
    endif
  endfor

  ;;update the plot/write postscript
  yr=[(*self.state).contr_yaxis_min, (*self.state).contr_yaxis_max]
  ytitle = 'Contrast '
  sigma = '!7r!X'
  case (*self.state).contr_yunit of
    0: if ((*self.state).collapse eq 0) then ytitle ='Single Slice Contrast ['+strc(uint((*self.state).contrsigma))+sigma+' limit]' else ytitle ='Contrast ['+strc(uint((*self.state).contrsigma))+sigma+' limit]'
    1: ytitle += '[Median]'
    2: ytitle += '[Mean]'
  endcase
  xtitle =  'Angular separation '
  if (*self.state).contr_xunit eq 0 then xtitle += '["]' else $
    xtitle += '['+'!4' + string("153B) + '!X/D]' ;;"just here to keep emacs from flipping out

  ;;clear windows before replotting
  self->clear_contrprof_windows


  ;;------------- do the actual plotting here (code formerly in the ::statvsr function) -----

  if ~ (((*self.state).collapse eq 0) || ((*self.state).specalign_mode eq 1) || $
    ((*self.state).high_pass_mode eq 1) || ((*self.state).low_pass_mode eq 1) || $
    ((*self.state).klip_mode eq 1) || ((*self.state).snr_map_mode eq 1)  ) then data = {asec:asec,contrprof:outval}

  ;self->statvsr, yr=yr, xtitle=xtitle, ytitle=ytitle else $
  ;self->statvsr, yr=yr, xtitle=xtitle, ytitle=ytitle, data = {asec:asec,contrprof:outval}


  if not keyword_set(data) then begin
    ;;check to make sure that we actually have a valid contour profile in
    ;;memory
    if (*self.state).contr_plotmult then inds = (*self.satspots.good) else $
      inds = (*self.state).cur_image_num
    if n_elements(*(*self.satspots.contrprof)[inds[0],(*self.state).contr_yunit]) eq 0 then begin
      self->message, msgtype='error', 'No valid contour profile exists.'
      return
    endif
  endif else inds = 0

  ;;set up graphs
  self->setwindow, (*self.state).contrplot_window_id
  erase

  ;;set proper scale unit
  if (*self.state).contr_yunit eq 0 then sclunit = (*self.state).contrsigma else sclunit = 1d

  self->initcolors
  if ~(*self.state).contr_plotmult then color = cgcolor('red') else begin
    color = round(findgen((*self.state).image_size[2])/$
      ((*self.state).image_size[2]-1)*100.+100.)
  endelse
  ;;other plot stuff
  if (not keyword_set(linestyle)) then linestyle=[0,2,3,5]
  if (not keyword_set(psym)) then psym = [4,1,2,5,6]
  if (not keyword_set(symsize)) then symsize=1.


  ;;get plot ranges, if none given
  if (not keyword_set(xrange)) then begin

    if not keyword_set(data) then asec = *(*self.satspots.asec)[inds[0]] else $
      asec = data.asec
    if (*self.state).contr_xunit eq 1 then $
      asec *= 1d/3600d*!dpi/180d*gpi_get_constant('primary_diam',default=7.7701d0)/((*(*self.state).CWV_ptr)[inds[0]]*1d-6)
    xrange=[min(asec),max(asec)]
    for j=1,n_elements(inds)-1 do begin
      asec = *(*self.satspots.asec)[inds[j]]
      if (*self.state).contr_xunit eq 1 then $
        asec *= 1d/3600d*!dpi/180d*gpi_get_constant('primary_diam',default=7.7701d0)/((*(*self.state).CWV_ptr)[inds[j]]*1d-6)
      xrange[0] = xrange[0] < min(asec)
      xrange[1] = xrange[1] > max(asec)
    endfor
  endif

  if not(keyword_set(yrange)) or (*self.state).contr_yaxis_mode then begin
    if not keyword_set(data) then tmp = *(*self.satspots.contrprof)[inds[0],(*self.state).contr_yunit] else $
      tmp = data.contrprof
    tmp = tmp[where(finite(tmp) and tmp gt 0)] * sclunit
    yrange = [min(tmp),max(tmp)]
    for j=1,n_elements(inds)-1 do begin
      tmp = *(*self.satspots.contrprof)[inds[j],(*self.state).contr_yunit]
      tmp = tmp[where(finite(tmp) and tmp gt 0)] * sclunit
      yrange[0] = yrange[0] < min(tmp)
      yrange[1] = yrange[1] > max(tmp)
    endfor
  endif

  ;;Tick labels don't automatically appear if yrange less than an order
  ;;of magnitude, so check for that
  if floor(alog10(max(yrange))) eq floor(alog10(min(yrange))) then begin
    ;;As of now no labels will be drawn on Y-axis, so set them by hand
    ytickv = 10.^floor(alog10(min(yrange))) * (findgen(10)+1)
    ytickv = ytickv(where(ytickv ge min(yrange) and ytickv le max(yrange)))
    yticks = n_elements(ytickv)-1
  endif

  ;;figure out title
  widget_control,(*self.state).contrwarning_id,get_value=warn
  if strcmp(warn,'Warnings: Possible Misdetection: Fluxes vary >25%') then $
    title='Warning: Possible Misdetection: Fluxes vary >25%' else $
    title = ''


  ;;plot contrast
  ;; and while doing so, keep track of contrast at 0.4 arcsec fiducial radius

  if not(keyword_set(overplot)) then begin
    plot,[0],[0],ylog=(*self.state).contr_yaxis_type,xlog=xlog,xrange=xrange,yrange=yrange,/xstyle,/ystyle,$
      xtitle=xtitle,ytitle=ytitle,/nodata, charsize=(*self.state).contr_font_size, title=title,ytickv=ytickv,yticks=yticks
  endif

  radius=0.4
  contr_at_04=fltarr(n_elements(inds))
  for j = 0, n_elements(inds)-1 do begin
    if not keyword_set(data) then asec = *(*self.satspots.asec)[inds[j]] else $
      asec = data.asec

    mindiff = min(abs(asec-radius), /nan, closest_radius_subscript)

    if (*self.state).contr_xunit eq 1 then $
      asec *= 1d/3600d*!dpi/180d*gpi_get_constant('primary_diam',default=7.7701d0)/((*(*self.state).CWV_ptr)[inds[j]]*1d-6)

    if not keyword_set(data) then tmp = *(*self.satspots.contrprof)[inds[j],(*self.state).contr_yunit] else $
      tmp = data.contrprof

    contr_at_04[j] = tmp[closest_radius_subscript]

    oplot,asec,tmp[*,0] * sclunit, color=color[j], linestyle=linestyle[0]
    if (*self.state).contr_plotouter then oplot,asec,tmp[*,1] * sclunit, color=color[j],linestyle=linestyle[1]
  endfor

  xyouts, /normal,0.55,0.83,'Star Magnitude = '+strtrim(strmid(*self.satspots.mags,0,10),2),charsize=1.2

  if n_elements(contr_at_04) gt 1 then contr_at_04 = median(contr_at_04)
  sigma = '!7r!X'
  xyouts, /normal,0.55,0.75,strc(fix(round(sclunit)))+sigma+' Contrast = '+sigfig(sclunit*contr_at_04,2,/sci)+' at 0.4"',charsize=1.2
  if ((*self.state).collapse eq 0) then xyouts, /normal,0.75,0.71,"at "+sigfig((*(*self.state).CWV_ptr)[inds[0]],4)+" um",charsize=1.2

  oplot, [0.4], [contr_at_04]*sclunit, psym=1, color=cgcolor('white'), symsize=2

	; in in SNR map mode - the contrast plot is extremely difficult to understand - so lets just erase it
	if ((*self.state).snr_map_mode eq 1) then begin
	  ;;set up graphs
	  self->setwindow, (*self.state).contrplot_window_id
	  erase
	  xyouts, /normal,0.30,0.5,'Contrast plot not available',charsize=1.7
	  xyouts,/normal,0.28,0.43,' when using SNR Map mode',charsize=1.7
 	endif


  ;;------------- end of code merged from ::starvsr -----------------------------------------

  ;;update window
  if not(keyword_set(ps)) then self->tvcontr

  if keyword_set(sav) or keyword_set(radialsav) then begin
    ;if ptr_valid((*self.state).head_ptr) then hdr = *((*self.state).head_ptr) else mkhdr,hdr,copsf
    nm = (*self.state).imagename
    strps = strpos(nm,'/',/reverse_search)
    strpe = strpos(nm,'.fits',/reverse_search)
    nm = strmid(nm,strps+1,strpe-strps-1)

    tmp = intarr((*self.state).image_size[2])
    tmp[inds] = 1
    slices = string(strtrim(tmp,2),format='('+strtrim(n_elements(tmp),2)+'(A))')
  endif
  ;;save whole contrast image
  if (keyword_set(sav)) then begin
    contr_outfile = dialog_pickfile(filter='*.fits', $
      file=nm+'-contrast.fits', get_path = tmp_dir, $
      path=(*self.state).current_dir,$
      title='Please Select File to save contrast image')

    IF (strcompress(contr_outfile, /remove_all) EQ '') then RETURN

    IF (contr_outfile EQ tmp_dir) then BEGIN
      self->message, 'Must indicate filename to save.', $
        msgtype = 'error', /window
      return
    ENDIF

    mkhdr,hdr,copsf
    sxaddpar,hdr,'SLICES',slices,'Cube slices used.'
    sxaddpar,hdr,'WINAP',(*self.state).contrwinap,'Search window size'
    sxaddpar,hdr,'GAUSSAP',(*self.state).contrap,'Gaussian window size'

    writefits,contr_outfile,copsf,hdr
  endif

  ;;save radial contrast as fits
  if (keyword_set(radialsav)) then begin
    ftype = (['fits','txt','fits'])[(*self.state).contr_prof_filetype]
    contr_outfile = dialog_pickfile(filter='*.'+ftype, $
      file=nm+'-contrast_profile.'+ftype, get_path = tmp_dir, $
      path=(*self.state).current_dir,$
      title='Please Select File to save contrast radial profile')

    IF (strcompress(contr_outfile, /remove_all) EQ '') then RETURN

    IF (contr_outfile EQ tmp_dir) then BEGIN
      self->message, 'Must indicate filename to save.', $
        msgtype = 'error', /window
      return
    ENDIF

    if ((*self.state).collapse eq 0) || ((*self.state).specalign_mode eq 1) || $
      ((*self.state).klip_mode eq 1) || ((*self.state).high_pass_mode eq 1) || $
      ((*self.state).low_pass_mode eq 1) || ((*self.state).snr_map_mode eq 1) then begin
      out = dblarr(n_elements(*(*self.satspots.asec)[inds[0]]), n_elements(inds)+1)+!values.d_nan
      out[*,0] = *(*self.satspots.asec)[inds[0]]
      for j=0,n_elements(inds)-1 do $
        out[where((*(*self.satspots.asec)[inds[0]]) eq (*(*self.satspots.asec)[inds[j]])[0]):-1,j+1] = $
        (*(*self.satspots.contrprof)[inds[j],(*self.state).contr_yunit])[*,0]
    endif else out = [[asec],[outval[*,0]]]

    case (*self.state).contr_prof_filetype of
      0: begin
        mkhdr,hdr,out
        sxaddpar,hdr,'SLICES',slices,'Cube slices used.'
        sxaddpar,hdr,'YUNITS',(['Std Dev','Median','Mean'])[(*self.state).contr_yunit],'Contrast units'
        sxaddpar,hdr,'WINAP',(*self.state).contrwinap,'Search window size'
        sxaddpar,hdr,'GAUSSAP',(*self.state).contrap,'Gaussian window size'
        writefits,contr_outfile,out,hdr
      end
      1: begin
        openw,lun,contr_outfile,/get_lun
        printf,lun,transpose(out),format='('+strtrim((size(out,/dim))[1],2)+'(F))'
        free_lun,lun
      end
      2: begin
        hdr = ['',string('END',format='(A-80)')]

        sxaddpar,hdr,'SLICES',slices,'Cube slices used.'
        sxaddpar,hdr,'YUNITS',(['Std Dev','Median','Mean'])[(*self.state).contr_yunit],'Contrast units'
        sxaddpar,hdr,'WINAP',(*self.state).contrwinap,'Search window size'
        sxaddpar,hdr,'GAUSSAP',(*self.state).contrap,'Gaussian window size'
        names = ['Angle']
        fmt = 'D'
        for j=0,n_elements(inds)-1 do begin &$
          names = [names,'Slice_'+strtrim(fix(inds[j]),2)] &$
          fmt = fmt+',D' &$
        end
      create_struct,out1,'',names,fmt
      out1 = replicate(out1,  (size(out,/dim))[0])
      for j = 0,n_elements(names)-1 do out1.(j) = out[*,j]
      mwrfits,out1,contr_outfile,hdr,/create
    end
  endcase
endif

self->resetwindow
end

;----------------------------------------------------------------------
pro GPItv::contrast

  ;; contrast radial profile front end


  (*self.state).cursorpos = (*self.state).coord

  if (not (xregistered(self.xname+'_contrprof'))) then begin

    if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
    contrprof_base = $
      widget_base(/base_align_center, $
      group_leader = (*self.state).base_id, $
      /column, $
      title = title_base+' contrast profile', $
      uvalue = 'contrprof_base')

    contrprof_top_base = widget_base(contrprof_base, /row, /base_align_center)

    contrprof_data_base1 = widget_base( contrprof_top_base, /column, frame=0)

    contrprof_data_base2 = widget_base( contrprof_top_base, /column, frame=0)

    contrzoom_widget_id = widget_draw( $
      contrprof_data_base2, $
      scr_xsize=(*self.state).photzoom_size, scr_ysize=(*self.state).photzoom_size)


    contrprof_draw_base = widget_base( contrprof_base, /row, /base_align_center, frame=0)

    contrprof_data_base1a = widget_base(contrprof_data_base1, /column, frame=1)
    contrprof_data_base1a2 = Widget_Base(contrprof_data_base1a,  /row)

    void=WIDGET_LABEL(contrprof_data_base1a2,value='Sat spot flux ratio=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrgridfac_id = $
      WIDGET_TEXT(contrprof_data_base1a2, $
      /editable, $
      uvalue = 'gridfac', $
      value = strcompress(string((*self.state).gridfac)),xsize=8)

    void=WIDGET_LABEL(contrprof_data_base1a2,value='Sigma limit=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrsigma_id = $
      WIDGET_TEXT(contrprof_data_base1a2, $
      /editable, $
      uvalue = 'contrsigma', $
      value = strcompress(string((*self.state).contrsigma)),xsize=8)

    contrprof_data_base1a4 = widget_base(contrprof_data_base1a, /row)
    sat_bases = make_array(4,type=size(contrprof_data_base1a4,/type))
    sat_bases[0] = contrprof_data_base1a4

    void=WIDGET_LABEL(contrprof_data_base1a4,value='Sat1 detec. window center x=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrcen1x_id = $
      WIDGET_TEXT(contrprof_data_base1a4, $
      /editable, $
      uvalue = 'cent1', $
      value = strcompress(string((*self.state).contrcen1x)),xsize=8)
    void=WIDGET_LABEL(contrprof_data_base1a4,value='  y=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrcen1y_id = $
      WIDGET_TEXT(contrprof_data_base1a4, $
      /editable, $
      uvalue = 'cent1', $
      value = strcompress(string((*self.state).contrcen1y)),xsize=8)

    contrprof_data_base1a4 = widget_base(contrprof_data_base1a, /row)
    sat_bases[1] = contrprof_data_base1a4
    void=WIDGET_LABEL(contrprof_data_base1a4,value='Sat2 detec. window center x=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrcen2x_id = $
      WIDGET_TEXT(contrprof_data_base1a4, $
      /editable, $
      uvalue = 'cent1', $
      value = strcompress(string((*self.state).contrcen2x)),xsize=8)
    void=WIDGET_LABEL(contrprof_data_base1a4,value='  y=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrcen2y_id = $
      WIDGET_TEXT(contrprof_data_base1a4, $
      /editable, $
      uvalue = 'cent1', $
      value = strcompress(string((*self.state).contrcen2y)),xsize=8)

    contrprof_data_base1a4 = widget_base(contrprof_data_base1a, /row)
    sat_bases[2] = contrprof_data_base1a4
    void=WIDGET_LABEL(contrprof_data_base1a4,value='Sat3 detec. window center x=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrcen3x_id = $
      WIDGET_TEXT(contrprof_data_base1a4, $
      /editable, $
      uvalue = 'cent1', $
      value = strcompress(string((*self.state).contrcen3x)),xsize=8)

    void=WIDGET_LABEL(contrprof_data_base1a4,value='  y=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrcen3y_id = $
      WIDGET_TEXT(contrprof_data_base1a4, $
      /editable, $
      uvalue = 'cent1', $
      value = strcompress(string((*self.state).contrcen3y)),xsize=8)

    contrprof_data_base1a4 = widget_base(contrprof_data_base1a, /row)
    sat_bases[3] = contrprof_data_base1a4
    void=WIDGET_LABEL(contrprof_data_base1a4,value='Sat4 detec. window center x=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrcen4x_id = $
      WIDGET_TEXT(contrprof_data_base1a4, $
      /editable, $
      uvalue = 'cent1', $
      value = strcompress(string((*self.state).contrcen4x)),xsize=8)
    void=WIDGET_LABEL(contrprof_data_base1a4,value='  y=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrcen4y_id = $
      WIDGET_TEXT(contrprof_data_base1a4, $
      /editable, $
      uvalue = 'cent1', $
      value = strcompress(string((*self.state).contrcen4y)),xsize=8)

    (*self.state).contrcen_base_ids = sat_bases

    contrprof_data_base1a5 = widget_base(contrprof_data_base1a, /row)
    void=WIDGET_LABEL(contrprof_data_base1a5,value='Half-length of max box (pix)=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrwinap_id = $
      WIDGET_TEXT(contrprof_data_base1a5, $
      /editable, $
      uvalue = 'cent1', $
      value = strcompress(string((*self.state).contrwinap)),xsize=8)

    contrprof_data_base1a6 = widget_base(contrprof_data_base1a, /row)
    void=WIDGET_LABEL(contrprof_data_base1a6,value='Half-length of Gauss. box (pix)=', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    (*self.state).contrap_id = $
      WIDGET_TEXT(contrprof_data_base1a6, $
      /editable, $
      uvalue = 'cent1', $
      value = strcompress(string((*self.state).contrap)),xsize=8)

    for i=0,3 do begin
      tmp_string = $
        string(0., 0., $
        format = '("Sat'+strc(i+1)+' position:  x=",g14.7,"  y=",g14.7)' )
      (*self.state).satpos_ids[i] = $
        widget_label(contrprof_data_base1, $
        value = tmp_string, $
        uvalue = 'cursorpos', /align_left)
    endfor

    (*self.state).contrwarning_id = $
      widget_label(contrprof_data_base1, $
      value = 'Warnings: None.', $
      uvalue = 'cursorpos', /align_left,xsize=300)

    refreshplot = $
      widget_button(contrprof_data_base2, $
      value = 'Refresh Plot', $
      uvalue = 'contr_plot_refresh')

    refreshsats = $
      widget_button(contrprof_data_base2, $
      value = 'Find Sat Spots', $
      uvalue = 'satellite_refresh')

    plotoptions = $
      widget_button(contrprof_data_base2, $
      value = 'Plot Options...', $
      uvalue = 'contr_plot_options')
    contrplot_log_save = $
      widget_button(contrprof_data_base2, $
      value = 'Save contrast image', $
      uvalue = 'contrplot_save')

    contr_ps = $
      widget_button(contrprof_data_base2, $
      value = 'Save contrast profile plot', $
      uvalue = 'contr_ps')

    contr_radial = $
      widget_button(contrprof_data_base2, $
      value = 'Save contrast profile', $
      uvalue = 'contr_radial')

    (*self.state).contrplot_widget_id = $
      widget_draw(contrprof_draw_base, scr_xsize=500, $
      scr_ysize=(350 < ((*self.state).screen_ysize - 350)))

    contrprof_done = $
      widget_button(contrprof_data_base2, $
      value = 'Done', $
      uvalue = 'contrprof_done')

    widget_control, contrprof_base, /realize

    widget_control, contrzoom_widget_id, get_value=tmp_value
    (*self.state).contrzoom_window_id = tmp_value
    widget_control, (*self.state).contrplot_widget_id, get_value=tmp_value
    (*self.state).contrplot_window_id = tmp_value

    ;		xmanager, 'GPItv_contrprof', contrprof_base, /no_block
    ;		widget_control, contrprof_base, set_uvalue=self

    xmanager, self.xname+'_contrprof', contrprof_base, /no_block
    widget_control, contrprof_base, set_uvalue={object:self, method: 'contrprof_event'}
    widget_control, contrprof_base, event_pro = 'GPItvo_subwindow_event_handler'
    self->resetwindow
  endif

  ;;update sensitivity of sat spot inputs
  for j=0,3 do widget_control,(*self.state).contrcen_base_ids[j],$
    sensitive = 1 - (*self.state).contr_autocent

  self->contrprof_refresh
end

;----------------------------------------------------------------------
pro GPItv::show_fpmoffset

  ;; FPM offset/centering tool front end

  (*self.state).cursorpos = (*self.state).coord

  if (not (xregistered(self.xname+'_fpmoffset'))) then begin

    if (*self.state).multisess GT 0 then title_base = "GPItv #"+strc((*self.state).multisess) else title_base = 'GPItv '
    fpmoffset_base = $
      widget_base(/base_align_center, $
      group_leader = (*self.state).base_id, $
      /column, $
      title = title_base+' FPM Offset', $
      uvalue = 'fpmoffset_base')

    fpmoffset_top_base = widget_base(fpmoffset_base, /column, /base_align_center)

    fpmoffset_data_base1  = widget_base(fpmoffset_top_base, /column, frame=0)
    void=WIDGET_LABEL(fpmoffset_data_base1,value='Star Position from Sat Spots: ', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    void=WIDGET_LABEL(fpmoffset_data_base1,value='(For H, only 1.5-1.7 um)', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    fpmoffset_data_base1a = widget_base(fpmoffset_data_base1, /row, frame=0)

    fpmoffset_data_base2 = widget_base( fpmoffset_top_base, /column, frame=0)
    void=WIDGET_LABEL(fpmoffset_data_base2,value='FPM Position from Wavecal: ', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    fpmoffset_data_base2a = widget_base(fpmoffset_data_base2, /row, frame=0)

    fpmoffset_data_base3 = widget_base( fpmoffset_top_base, /column, frame=1)
    void=WIDGET_LABEL(fpmoffset_data_base3,value='Offset to Align: ', /ALIGN_LEFT,/DYNAMIC_RESIZE )
    fpmoffset_data_base3a = widget_base(fpmoffset_data_base3, /row, frame=0)

    (*self.state).fpmoffset_psfcentx_id = $
      cw_field(fpmoffset_data_base1a, $
	  title="  X:",$
      uvalue = 'psfcentx', $
	  /noedit, tab_mode=0,$
      value = '0.0',xsize=8)

    (*self.state).fpmoffset_psfcenty_id = $
      cw_field(fpmoffset_data_base1a, $
	  title="   Y:",$
      uvalue = 'psfcenty', $
	  /noedit,$
      value = '0.0',xsize=8)
    void=WIDGET_LABEL(fpmoffset_data_base1a,value=' pixels', /ALIGN_LEFT,/DYNAMIC_RESIZE )

    (*self.state).fpmoffset_fpmcentx_id = $
      cw_field(fpmoffset_data_base2a, $
	  title="  X:",$
      uvalue = 'fpmcentx', $
	  /noedit,$
      value = '0.0',xsize=8)

    (*self.state).fpmoffset_fpmcenty_id = $
      cw_field(fpmoffset_data_base2a, $
	  title="   Y:",$
      uvalue = 'fpmcenty', $
	  /noedit,$
      value = '0.0',xsize=8)
    void=WIDGET_LABEL(fpmoffset_data_base2a,value=' pixels', /ALIGN_LEFT,/DYNAMIC_RESIZE )

    (*self.state).fpmoffset_statuslabel_id=WIDGET_LABEL(fpmoffset_data_base2,value='    FPM position not available. ', /ALIGN_LEFT,/DYNAMIC_RESIZE )

    (*self.state).fpmoffset_offsettip_id = $
      cw_field(fpmoffset_data_base3a, $
	  title="Tip:",$
      uvalue = 'offsettip', $
	  /noedit,$
      value = '0',xsize=8)

    (*self.state).fpmoffset_offsettilt_id = $
      cw_field(fpmoffset_data_base3a, $
	  title="Tilt:",$
      uvalue = 'offsettilt', $
	  /noedit,$
      value = '0',xsize=8)
    void=WIDGET_LABEL(fpmoffset_data_base3a,value=' mas   ', /ALIGN_LEFT,/DYNAMIC_RESIZE )


    widget_control, fpmoffset_base, /realize

    xmanager, self.xname+'_fpmoffset', fpmoffset_base, /no_block
    widget_control, fpmoffset_base, set_uvalue={object:self, method: 'fpmoffset_event'}
    widget_control, fpmoffset_base, event_pro = 'GPItvo_subwindow_event_handler'
    self->resetwindow
  endif

  self->fpmoffset_refresh
end

;--------------------------------------------------------------------------------
pro GPItv::fpmoffset_refresh
  ;; Plot star position relative to FPM using satellite spots.

  ;;if no image lodaed, nothing to do
  if n_elements(*self.images.names_stack) eq 0 then return

  ;;don't support non-cubes
  if (*self.state).image_size[2] lt 2 then return


  ;;-- Get FPM location--

  if (*self.state).fpmoffset_fpmpos[0] eq 0 and (*self.state).fpmoffset_fpmpos[1] eq 0 then begin
	; Attempt to get FPM position data from a calibration file
    caldb = obj_new('gpicaldatabase')
    bestfile = caldb->get_best_cal_from_header( 'fpm_position', *((*self.state).head_ptr), *(*self.state).exthead_ptr) 

    if strc(bestfile) eq '-1' then begin
		(*self.state).fpmoffset_calfilename = 'None'
		self->message, "Couldn't load any FPM offset file from CalDB."
		 (*self.state).fpmoffset_fpmpos = [-1,-1] ; record that we don't have one so it doesn't try again on every refresh
	endif else begin 
		(*self.state).fpmoffset_calfilename = bestfile
		header = headfits(bestfile)
		FPMCENTX = sxpar(header, 'FPMCENTX', count=ct1)
		FPMCENTY = sxpar(header, 'FPMCENTY', count=ct2)
		if ct1+ct2 eq 2 then begin
			(*self.state).fpmoffset_fpmpos = [fpmcentx,fpmcenty] 
		endif else begin
			(*self.state).fpmoffset_fpmpos = [-1,-1] ; record that we don't have one so it doesn't try again on every refresh
		endelse
	endelse


  endif


  ;;-- Get PSF location --
  ;;if no satspots in memory, calculate them
  if (n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]) then begin
    self->update_sat_spots
  endif

    ;; only do the calculation if we now have good sat spots
    if (n_elements(*self.satspots.cens) eq 8L * (*self.state).image_size[2]) then begin
	  ; compute mean 
	  ;;calculate center locations
	  tmp=*self.satspots[*].cens
	  cents=fltarr(2,N_ELEMENTS(tmp[0,0,*]))
	  for p=0, N_ELEMENTS(tmp[0,0,*]) -1 do begin
		for q=0, 1 do cents[q,p]=mean(tmp[q,*,p])
	  endfor
      ; find the mean PSF center
      ;;for H band, only using wavelength slices between 1.5 and 1.7 um (for better S/N)
      ;;for other bands, using all the wavelength slices for now
      if (*self.state).obsfilt eq 'H' then begin
        psfcentx = mean(cents[0,1:24]) 
        psfcenty = mean(cents[1,1:24])
      endif else begin
        psfcentx = mean(cents[0,*]) 
        psfcenty = mean(cents[1,*])
      endelse

  endif else begin
	  self->message, "Could not find star pos from sat spots; cannot calculate FPM offset"
	  psfcentx = !values.f_nan
	  psfcenty = !values.f_nan
  endelse



  ;;--update display--

  fpmcentx_text = 'Unknown'
  fpmcenty_text = 'Unknown'
  offsettip_text = 'Unknown'
  offsettilt_text = 'Unknown'
  psfcentx_text = 'Unknown'
  psfcenty_text = 'Unknown'

  if (*self.state).fpmoffset_fpmpos[0] le 0 then begin
	  self->message, "No FPM position available."
	  statuslabel ='    FPM position not available. '
  endif else begin
	  pixscale = gpi_get_constant('ifs_lenslet_scale') ; arcsec per pixel
      fpmcentx = (*self.state).fpmoffset_fpmpos[0]
      fpmcenty = (*self.state).fpmoffset_fpmpos[1]
	  fpmcentx_text = string(fpmcentx,format="(f7.2)")
	  fpmcenty_text = string(fpmcenty,format="(f7.2)")
      statuslabel = "  FPM pos from "+file_basename((*self.state).fpmoffset_calfilename)

	  if finite(psfcentx) then begin
		  psfcentx_text = string(psfcentx,format="(f7.2)")
		  psfcenty_text = string(psfcenty,format="(f7.2)")

		  angle = gpi_get_constant('ifs_rotation')*!pi/180 ; img rotation in radians
		  offsetx = (psfcentx-fpmcentx) *pixscale*1000 ; convert to mas
		  offsety = (psfcenty-fpmcenty) *pixscale*1000 ; convert to mas
		  offsettip  = -offsetx * cos(angle) - offsety * sin(angle)
		  offsettilt = -offsetx * sin(angle) + offsety * cos(angle)

		  offsettip_text = string(round(offsettip),format="(i+7)")
		  offsettilt_text = string(round(offsettilt),format="(i+7)")
	  endif else begin
	  endelse
  endelse

  widget_control,(*self.state).fpmoffset_fpmcentx_id,set_value=fpmcentx_text
  widget_control,(*self.state).fpmoffset_fpmcenty_id,set_value=fpmcenty_text
  widget_control,(*self.state).fpmoffset_psfcentx_id,set_value=psfcentx_text
  widget_control,(*self.state).fpmoffset_psfcenty_id,set_value=psfcenty_text
  widget_control,(*self.state).fpmoffset_offsettip_id,set_value=offsettip_text
  widget_control,(*self.state).fpmoffset_offsettilt_id,set_value=offsettilt_text
  widget_control,(*self.state).fpmoffset_statuslabel_id,set_value=statuslabel

end


;--------------------------------------------------------------------------------
pro GPItv::dq_mask_settings

  ;; Routine to get user input on which data quality flag pixels to flag.
  ;; Hard coded for GPI IFS DQ right now - should be generalized?
  bit_descriptions = ['Bit 0: Permanent Bad Pixel from detector server',  $
    'Bit 1: Raw pixel read exceeds saturation value',  $
    'Bit 2: UTR step exceeds saturation value',  $
    'Bit 3: UTR calculation removed minimum delta',  $
    'Bit 4: UTR calculation removed maximum delta',  $
    'Bit 5: Flagged bad by data pipeline badpix mask', $
    'Bit 6: TBD/Unused', $
    'Bit 7: TBD/Unused']


  bit_current_settings = bytarr(8)
  for i=0,7 do bit_current_Settings[i] = (*self.state).dq_bit_mask and 2^i


  bit_options = '2, button, '+strjoin(bit_descriptions,'|')+',' + $
    ' set_value = [' + strjoin(strc(fix(bit_current_settings ne 0)),'$\,') +'], tag=selected_bits'

  formdesc = ['0, label, Select options for which DQ bit flags indicate, Center', $
    '0, label, that a given pixel should be considered "Bad", Center',$
    '1, base, , frame, ', $
    bit_options,$
    '0, droplist, Black|Red|Green|Blue|Cyan|Magenta|Yellow|White, set_value='+strc(fix((*self.state).dq_display_color))+', tag=color, label_left=Color to display bad pixels', $
    '0, button, Apply Settings, quit, tag=OK', $
    '0, button, Cancel, quit, tag=Cancel']

  textform = cw_form(formdesc, /column, $
    title = 'GPItv DQ Bitmask Settings')

  if (textform.cancel EQ 1) then return ; cancelled (tag# = # of inputs above+2)

  new_bitmask = 0b
  for i=0,7 do new_bitmask = new_bitmask or (2^i)*textform.selected_bits[i]

  message,/info,'New DQ bitmask: '+strc(new_bitmask)
  (*self.state).dq_bit_mask = new_bitmask

  ; color indices defined in initcolors are
  ; black, red, green, blue, cyan, magenta, yellow, white

  (*self.state).dq_display_color = textform.color
  self->update_DQ_warnings
  self->displayall

end


;----------------------------------------------------------------------

function gpitv::get_session
  ;;accessor function for session number, for use by external programs
  return, (*self.state).multisess
end

function gpitv::xname
  ;;accessor function for xname, for use by external programs
  return, self.xname
end


;-------------------------------------------------------------------
;-------------------------------------------------------------------
;--------------------------------------------------------------------
;    GPItv main program.  needs to be last in order to compile.
;---------------------------------------------------------------------
;-------------------------------------------------------------------
;--------------------------------------------------------------------

; Main program routine for GPItv.  If there is no current GPItv session,
; then run GPItv_startup to create the widgets.  If GPItv already exists,
; then display the new image to the current GPItv window.

function GPItv::init, image, header, $                      ;main inputs
  multises=multises, session=session, $ ;session keywords headed in init
  block = block, exit = exit, $
  nbrsatspot=nbrsatspot, $              ;handled by startup
  _extra = _extra                     ;all other keywords


  ;; can't work in z-buffer or something equally silly
  if (!d.name NE 'X' AND !d.name NE 'WIN' AND !d.name NE 'MAC') then begin
    self->message, msgtype='error', 'Graphics device must be set to X, WIN, or MAC for GPItv to work.'
    retall
  endif

  ;; if exiting, you're done
  if (keyword_set(exit)) then begin
    self->shutdown
    return, 0
  endif

  ; Before starting up GPItv, get the user's external window id.  We can't
  ; use the GPItv::getwindow routine yet because we haven't run GPItv
  ; startup.  A subtle issue: self->resetwindow won't work the first time
  ; through because xmanager doesn't get called until the end of this
  ; routine.  So we have to deal with the external window explicitly in
  ; this routine.
  userwindow = !d.window
  self->startup, nbrsatspot=nbrsatspot

  ;;determine session multiplicity
  if keyword_set(session) then multises=session ; synonyms for back compatibility
  if (keyword_set(multises)) then (*self.state).multisess=multises

  ;;If there is no image, create one here, then proceed normally.
  if ~keyword_set(image) then begin
    gridsize = 281
    image = fltarr(gridsize, gridsize)
    image[0] = 1.0
    if ~(keyword_set(imname)) then imname = "NO IMAGE LOADED   "
  endif

  self->open,image, header,imname=imname, _extra=_extra

  ;; Register the widget with xmanager if it's not already registered
  nb = ~keyword_set(block)
  block = keyword_set(block)
  self.xname = 'GPItv'+strc((*self.state).multisess)
  xmanager, self.xname, (*self.state).base_id, no_block = nb, cleanup = 'GPItvo_shutdown', event_handler ='gpitvo_event'
  wset, userwindow

  ;; if blocking mode is set, then when the procedure reaches this
  ;; line GPItv has already been terminated.  If non-blocking, then
  ;; the procedure continues below.  If blocking, then the state
  ;; structure doesn't exist any more so don't set active window.
  if (block EQ 0) then (*self.state).active_window_id = userwindow

  return, 1

end

;------------------------------------------------

pro GPItv__define

  ncolors = 256L-9; !d.table_size - 9

  colors = {gpitv_color, r_vector: bytarr(ncolors), $
    g_vector: bytarr(ncolors), $
    b_vector: bytarr(ncolors), $
    user_r: bytarr(256), $
    user_g: bytarr(256), $
    user_b: bytarr(256)}

  pdata = { gpitv_pdata, nplot: 0, maxplot:50, plot_ptr: ptrarr(51)}

  images= { gpitv_image, main_image: ptr_new(), $
    main_image_stack: ptr_new(), $
    main_image_backup: ptr_new(), $
    names_stack: ptr_new(), $
    display_image: ptr_new(), $
    scaled_image: ptr_new(), $
    blink_image1: ptr_new(), $
    blink_image2: ptr_new(), $
    blink_image3: ptr_new(), $
    unblink_image: ptr_new(), $
    dq_image_stack: ptr_new(), $
    dq_image: ptr_new(), $
    pan_image: ptr_new(),$
    klip_image: ptr_new()}

  satspots = {gpitv_satspots,$
	  valid: 0, $		; are satspots currently valid for the image?
	  attempted: 0, $	; have we tried to load them for this image yet?
						; (to prevent repeatedly trying if we can't)
    cens: ptr_new(), $
    warns: ptr_new(), $
    good: ptr_new(), $
    satflux: ptr_new(), $
    contrprof: ptr_new(), $
    asec: ptr_new(), $
    mags: ptr_new()}


  gpitv = {gpitv, $
    xname: '', $
    state: ptr_new(), $
    colors: colors, $
    pdata: pdata, $
    images: images,$
    satspots:satspots}


end
