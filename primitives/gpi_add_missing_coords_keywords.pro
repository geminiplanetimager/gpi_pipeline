;+
; NAME: gpi_add_missing_coords_keywords
; PIPELINE PRIMITIVE DESCRIPTION: Add missing keywords for RA, DEC, PAR_ANG
; Useful for GPI commissioning data not yet getting the headers from the
; telescope.
;
; Caches results to avoid delays from repeated identical SIMBAD queries.
;
; OUTPUTS: The FITS file is modified in memory to add the specified keyword and
; value. The file on disk is NOT changed. 
;
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="string" Default="${GPI_DRP_CONFIG_DIR}object_coordinates.txt" Desc="File containing names, RA, Dec for targets."
; PIPELINE ARGUMENT: Name="OBJECT" Default="NO CHANGE" Desc="Enter value here to override the OBJECT keyword of a given file"
; PIPELINE COMMENT: Add missing RA, DEC, PAR_ANG keywords based on a lookup table of objects or SIMBAD.
; PIPELINE ORDER: 0.1
; PIPELINE NEWTYPE: Calibration,Testing
;
; HISTORY:
; 2013-11-13 Written by Marshall Perrin
;-
;=================================================================================================

function gpi_add_missing_coords_keywords,  DataSet, Modules, Backbone

primitive_version= '$Id: gpi_add_missingkeyword.pro 2026 2013-10-29 22:44:50Z mperrin $' ; get version from subversion to store in header history
@__start_primitive

	common drp_object_locations, names, ras, decs

	; Figure out the object
	object = backbone->get_keyword('OBJECT')

	if tag_exist( Modules[thisModuleIndex], "OBJECT") then begin
		if strupcase(Modules[thisModuleIndex].object) ne 'NO CHANGE' then object = Modules[thisModuleIndex].object
	endif

    backbone->Log, 'Add missing RA, DEC, PAR_ANG keywords based on object='+object

	; load optional configuration file lookup table.
	if ~(keyword_set(names)) then begin
		if file_test(gpi_expand_path(Modules[thisModuleIndex].CalibrationFile)) then begin
			readcol, gpi_expand_path(Modules[thisModuleIndex].CalibrationFile), names, ras, decs
		endif else begin
			; initialize some basic values so these arrays will exist later.
			names = ['unknown']
			ras = [0.0]
			decs = [0.0]
		endelse
	endif



	; first check the lookup table for objects we already know the coordinates of
	wm = where(names eq object, mct)
	if mct eq 1 then begin
		ra = ras[wm[0]]
		dec = decs[wm[0]]
		backbone->Log, "Coordinates found from lookup table already in memory"

	endif else begin
		
		; then try to figure out the coords from SIMBAD
		backbone->Log, "Querying SIMBAD for object coordinates"
		querysimbad, object, ra, dec, found=found

		if found then begin
			backbone->Log, "Found object coordinates OK."
			names = [names, object]
			ras = [ras, ra]
			decs = [decs, dec]
		endif else begin
			backbone->Log, "Could not resolve coordinates for "+object
			return, NOT_OK

		endelse
	endelse 

	backbone->set_keyword, 'RA', ra, 'RA post facto from name='+object
	backbone->set_keyword, 'DEC', dec, 'Dec post facto from name='+object


  ; Now we can figure out the altaz sky coordinates. 
  ; first is, what is the hour angle?
 

	lon = gpi_get_constant('observatory_lon')
	lat = gpi_get_constant('observatory_lat')

	mjd = backbone->get_keyword('MJD-OBS')
	jd  = mjd + 2400000.5

	; get lst in decimal hours
	ct2lst, lst, lon, dummy, JD

	backbone->set_keyword, 'LST', lst, 'LST computed post facto [hours]'

	; hangle function wants everything in radians. 
	;hangle,jd,ra*!dtor, dec*!dtor, lat*!dtor,lon*!dtor, ha, lst
	ha = lst - ra/15 

	backbone->set_keyword, 'HA', ha, 'Hour Angle computed post facto [hours]'

	par_ang = parangle(ha, dec, lat)

	backbone->set_keyword, 'PAR_ANG', par_ang, 'Par Ang computed post facto [deg]'

   
   
@__end_primitive


end
