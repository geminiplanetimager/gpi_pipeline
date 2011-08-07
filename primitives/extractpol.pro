;+
; NAME: extractpol
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Polarization Cube
; 
;         extract polarization-mode data cube from an image
;        define first suffix '-podc' (polarization data-cube)
;
;        This routine transforms a 2D detector image in the dataset.currframe input
;        structure into a 3D data cube in the dataset.currframe output structure.
;        (not much of a data cube - really just 2x 2D images)
;
;
; ALGORITHM NOTES:
;
;    Ideally this should be done as an optimum weighting 
;    (see e.g. Naylor et al, 1997 MNRAS)
;
;    That algorithm is as follows: For each lenslet spot,
;       -divide each pixel by the expected fraction of the total lenslet flux
;        in that pixel. (this makes each pixel an estimate of the total lenslet
;        flux)
;        -Combine these into a weighted average, weighted by the S/N per pixel
;
;
; INPUTS: detector image
; common needed: filter, wavcal, tilt, (nlens)
;
; GEM/GPI KEYWORDS:DEC,DISPERSR,PRISM,FILTER,FILTER2,PAR_ANG,RA,WPANGLE
; DRP KEYWORDS:CDELT1,CDELT2,CDELT3,CRPIX1,CRPIX2,CRPIX3,CRVAL1,CRVAL2,CRVAL3,CTYPE1,CTYPE2,CTYPE3,CUNIT1,CUNIT2,CUNIT3,EQUINOX,FILETYPE,HISTORY, PC1_1,PC1_2,PC2_1,PC2_2,PC3_3,RADESYS,WCSAXES
; OUTPUTS:
;
; PIPELINE COMMENT: Extract 2 perpendicular polarizations from a 2D image.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="polcal" Default="GPI-polcal.fits"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE TYPE: ALL/POL
; PIPELINE SEQUENCE: 11-31-
;
; HISTORY:
;   2009-04-22 MDP: Created, based on DST's cubeextract_polarized. 
;   2009-09-17 JM: added DRF parameters
;   2009-10-08 JM: add gpitv display
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2011-07-15 MP: Code cleanup.
;   2011-06-07 JM: added FITS/MEF compatibility
;+

function extractpol, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='polcal'

@__start_primitive

	input=*(dataset.currframe[0])
  	;if numext eq 0 then begin 
    	;hdr=*(dataset.headers)[numfile] 
  	;endif else begin 
      ;hdr=*(dataset.headersPHU)[numfile]
      ;hdrext=*(dataset.headers)[numfile]
 	;endelse    

    ; Validate the input data
    filt = gpi_simplify_keyword_value(strc(backbone->get_keyword( "FILTER1")))
    mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
    ;if ct eq 0 then mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
    ;if ct eq 0 then mode= strc(backbone->get_keyword( "FILTER2", count=ct))
    mode = strlowcase(mode)
    if ~strmatch(mode,"*wollaston*",/fold) then message, "That's not a polarimetry file!"

    ; read in polarization spot locations from the calibration file
    fits_info, c_File,N_ext=n_ext
    polspot_coords = readfits(c_File, ext=n_ext-1)
    polspot_pixvals = readfits(c_File, ext=n_ext)
    
    sz = size(polspot_coords)
    nx = sz[1+2]
    ny = sz[2+2]

    polcube = fltarr(nx, ny, 2)+!values.f_nan
    polcube2 = fltarr(nx, ny, 2)+!values.f_nan
    wpangle =  strc(backbone->get_keyword( "WPANGLE"))
	backbone->Log, "    WP angle is "+strc(wpangle)

    ;sxaddhist, functionname+": Extracting polarized slices using ", hdr
    ;sxaddhist, functionname+": "+c_File, hdr
    backbone->set_keyword, 'HISTORY',functionname+": Extracting polarized slices using "
    backbone->set_keyword, 'HISTORY',functionname+": "+c_File

    if keyword_set(mask) then mask = input*0

    ;  Extract the data to a datacube
    for pol=0,1 do begin
    for ix=0L,nx-1 do begin
    for iy=0L,ny-1 do begin
        ;if ~ptr_valid(polcoords[ix, iy,pol]) then continue
        wg = where(finite(polspot_pixvals[*,ix,iy,pol]) and polspot_pixvals[*,ix,iy,pol] gt 0, gct)
        if gct eq 0 then continue

        spotx = polspot_coords[0,wg,ix,iy,pol]
        spoty = polspot_coords[1,wg,ix,iy,pol]
        pixvals= polspot_pixvals[wg,ix,iy,pol] ; the 'spot PSF' for that spot
        pixvals /= total(pixvals)

        ; need to swap X and Y here to match output from DST.
        ;  - MDP 2008-05-09
        ;polcube[iy, ix, pol] = total(input[iii])
        polcube[iy, ix, pol] = total(input[spotx,spoty])
        ; No - the following does NOT make things better. This is the wrong way
        ; to normalize things here. 
        ;polcube2[iy, ix, pol] = total(input[spotx,spoty]*pixvals) 
        if keyword_set(mask) then mask[iii]=pol+1
    endfor 
    endfor 
    endfor 


    ; ==== build FITS header information here. ====
    ; Some notes on angle conventions for WCS:
    ; The rotation angle below needs to be the angle for how much the image's Y
    ; axis was rotated with respect to north. This is termed the 'Vertical
    ; angle'; see http://www.ucolick.org/~sla/deimos/swpdr/va.html
    ;
    ; The rotation matrix here is used to convert from IMAGE coords to SKY
    ; coords. Hence the sense of the rotation is opposite the PA.
    pixelscale = 0.014
    ; rotation matrix.
    d_PA = backbone->get_keyword( "PAR_ANG") ; in DEGREEs
    pc = [[cos(-d_PA*!dtor), -sin(-d_PA*!dtor)], $
          [sin(-d_PA*!dtor), cos(-d_PA*!dtor)]]
	ra = backbone->get_keyword("RA") 
	if size(ra,/tname) eq 'STRING' then begin
		; read in old-style incorrectly formatted as strings values.
		if strc(ra) eq "" then ra=0.0 else $
		ra = ten_string(backbone->get_keyword("RA"))*15 ; in deg
		;stop
		dec = ten_string(backbone->get_keyword("dec")) ; in deg
	endif else begin ; read in properly formatted ones, already in decimal degrees
		ra = backbone->get_keyword("RA") 
		dec = backbone->get_keyword("dec") 
	endelse
	;stop
	;if numext eq 0 then begin
	    ;hdrim=hdr
	;endif else begin
	    ;hdrim=hdrext
	;endelse
	backbone->set_keyword, 'COMMENT', "  For specification of Stokes WCS axis, see "
	backbone->set_keyword, 'COMMENT', "  Greisen & Calabretta 2002 A&A 395, 1061, section 5.4"


    backbone->set_keyword, 'HISTORY', functionname+": Creating WCS header"
    sz = size(polcube)
    backbone->set_keyword, "NAXIS", sz[0], /saveComment
    backbone->set_keyword, "NAXIS1", sz[1], /saveComment, after='NAXIS'
    backbone->set_keyword, "NAXIS2", sz[2], /saveComment, after='NAXIS1'
    backbone->set_keyword, "NAXIS3", sz[3], /saveComment, after='NAXIS2'

	backbone->set_keyword, "FILETYPE", "Stokes Cube", "What kind of IFS file is this?"
    backbone->set_keyword, "WCSAXES", 3, "Number of axes in WCS system"
    backbone->set_keyword, "CTYPE1", "RA---TAN","Right Ascension."
    backbone->set_keyword, "CTYPE2", "DEC--TAN","Declination."
    backbone->set_keyword, "CTYPE3", "STOKES",     "Polarization"
    backbone->set_keyword, "CUNIT1", "deg",  "R.A. unit is degrees, always"
    backbone->set_keyword, "CUNIT2", "deg",  "Declination unit is degrees, always"
    backbone->set_keyword, "CUNIT3", "N/A",       "Polarizations"
    backbone->set_keyword, "CRVAL1", ra, "R.A. at reference pixel"
    backbone->set_keyword, "CRVAL2", dec, "Declination at reference pixel"
    backbone->set_keyword, "CRVAL3", -6, " Stokes axis: image 0 is Y parallel, 1 is X parallel "
    ; need to add 1 here to account for "IRAF/FITS" 1-based convention used for
    ; WCS coordinates
    xcen=139 ; always perfectly centered for sims
    ycen=139 
    backbone->set_keyword, "CRPIX1", xcen+1,         "Reference pixel location"
    backbone->set_keyword, "CRPIX2", ycen+1,         "Reference pixel location"
    backbone->set_keyword, "CRPIX3", 0,         "Reference pixel location"
    backbone->set_keyword, "CDELT1", pixelscale/3600., "Pixel scale is "+sigfig(pixelscale,2)+" arcsec/pixel"
    backbone->set_keyword, "CDELT2", pixelscale/3600., "Pixel scale is "+sigfig(pixelscale,2)+" arcsec/pixel"
    backbone->set_keyword, "CDELT3", 1, "Stokes axis: image 0 is Y parallel, 1 is X parallel"

    backbone->set_keyword, "PC1_1", pc[0,0], "RA, Dec axes rotated by "+sigfig(d_pa*!radeg,4)+" degr."
    backbone->set_keyword, "PC1_2", pc[0,1], "RA, Dec axes rotated by "+sigfig(d_pa*!radeg,4)+" degr."
    backbone->set_keyword, "PC2_1", pc[1,0], "RA, Dec axes rotated by "+sigfig(d_pa*!radeg,4)+" degr."
    backbone->set_keyword, "PC2_2", pc[1,1], "RA, Dec axes rotated by "+sigfig(d_pa*!radeg,4)+" degr."
    backbone->set_keyword, "PC3_3", 1, "Stokes axis is unrotated"
    ; TODO WCS paper III suggests adding MJD-AVG to specify midpoint of
    ; observations for conversions to barycentric.
    backbone->set_keyword, "RADESYS", "FK5", "RA and Dec are in FK5"
    backbone->set_keyword, "EQUINOX", 2000.0, "RA, Dec equinox is J2000"





	suffix='-podc'
	*(dataset.currframe[0])=polcube
	;if numext eq 0 then begin
	 ;*(dataset.headers[numfile])=hdrim 
	 ;endif else begin
	  ;*(dataset.headersPHU[numfile])=hdr
	 ;*(dataset.headers[numfile])=hdrim
	;endelse 


@__end_primitive 
end

