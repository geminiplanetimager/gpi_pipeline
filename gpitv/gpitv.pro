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
;       GPItv [,array_name OR fits_file] [,min = min_value] [,max=max_value]
;           [,/linear] [,/log] [,/histeq] [,/block]
;           [,/alignp] [,/alignwav][,/stretch] [,header = header]
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
;
; KEYWORDS:
;		session=	Number of GPI session to invoke. By defaut you can have up
;					to 100 different GPItv windows open at once, each identified
;					by a different integer. 
;		/new		By default, if you send an image to an already-loaded
;					session, it will be sent to that existing gpitv window. 
;					Set the /new keyword to destroy that window and recreate a
;					new one instead, if you want your image loaded in a fresh
;					session for some reason.
;
;       min=        minimum data value to be mapped to the color table
;       max=        maximum data value to be mapped to the color table
;       /linear     use linear stretch
;       /log        use log stretch
;       /histeq     use histogram equalization
;       /asinh      use asinh stretch
;       /block      block IDL command line until GPItv terminates
;       /align      align image with previously displayed image
;       /stretch    keep same min and max as previous image
;       header=     FITS image header (string array) for use with data array
;
; OUTPUTS:
;       None.
;
;
; RESTRICTIONS:
;       Requires IDL version 5.1 or greater.
;       Requires Craig Markwardt's cmps_form.pro routine.
;       Requires the GSFC IDL astronomy users' library routines.
;       Some features may not work under all operating systems.
;
; EXAMPLE:
;       To start GPItv running, just enter the command 'GPItv' at the idl
;       prompt, either with or without an array name or fits file name
;       as an input. 
;
; MODIFICATION HISTORY:
;       ATV Written by Aaron J. Barth, with other contributions
;		GPITV written by Jerome Maire & Marshall Perrin including datacubes view, contrast plot,
;						multi-session mode (no ATV-freezing), units, "spaxel" mode,
;						angular profile, collapse,...
;		2010-04  Major rewrite by Marshall Perrin for object orientation
;				 Actual code is in gpitv__define now. 
;		2012-01	 Documentation cleanup by Marshall Perrin.
;
; GPITV's main code is now in the gpitv__define.pro routine, 
; rewritten as an IDL object to allow multiple instances.
; gpitv.pro is now just a startup wrapper implementing a simple multi-session mode.
;----------------------------------------------------------------------

pro gpitv, filename_or_array, header, session=session, new=new, _extra=_extra

	common GPITV_COMM, objvars, nobj_max

	if ~(keyword_set(nobj_max)) then begin
		nobj_max = 100
		objvars = objarr(nobj_max)
	endif

	if ~(keyword_set(session)) then session=1
	if keyword_set(new) then obj_destroy, objvars[session]


	if ~obj_valid(objvars[session]) then objvars[session] = obj_new('gpitv', multises=session, _extra=_extra )

	if obj_valid(objvars[session]) and keyword_set(filename_or_array) then objvars[session]->open, filename_or_array, header, _extra=_extra

end

