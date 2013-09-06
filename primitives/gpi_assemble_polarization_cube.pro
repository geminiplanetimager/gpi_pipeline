;+
; NAME: gpi_assemble_polarization_cube
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
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE NEWTYPE: PolarimetricScience, Calibration
;
; HISTORY:
;   2009-04-22 MDP: Created, based on DST's cubeextract_polarized. 
;   2009-09-17 JM: added DRF parameters
;   2009-10-08 JM: add gpitv display
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2011-07-15 MP: Code cleanup.
;   2011-06-07 JM: added FITS/MEF compatibility
;   2013-01-02 MP: Updated output file orientation to be consistent with
;				   spectral mode and raw data. 
;	2013-07-17 MP: Renamed for consistency
;-

function gpi_assemble_polarization_cube, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history

@__start_primitive

	input=*(dataset.currframe[0])

    ; Validate the input data
    filt = gpi_simplify_keyword_value(strc(backbone->get_keyword( "IFSFILT")))
    mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
    mode = strlowcase(mode)
    if ~strmatch(mode,"*wollaston*",/fold) then begin
		backbone->Log, "ERROR: That's not a polarimetry file!"
		return, not_ok
	endif

    ; polarization spot locations come from the calibration file, loaded already
	; in readpolcal
    
    polspot_coords=polcal.coords
    polspot_pixvals=polcal.pixvals
    
    sz = size(polspot_coords)
    nx = sz[1+2]
    ny = sz[2+2]

    polcube = fltarr(nx, ny, 2)+!values.f_nan
    polcube2 = fltarr(nx, ny, 2)+!values.f_nan
    wpangle =  strc(backbone->get_keyword( "WPANGLE"))
	backbone->Log, "WP angle is "+strc(wpangle), depth=2

    if keyword_set(mask) then mask = input*0

    ;  Extract the data to a datacube
    for pol=0,1 do begin
    for ix=0L,nx-1 do begin
    for iy=0L,ny-1 do begin
		;if ix eq 121 and iy eq 127 then stop
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
        ;polcube[iy, ix, pol] = total(input[spotx,spoty])
		; swap not desired any more - need to match orientation convention in
		; spectral mode. -MDP 2013-01-02
        polcube[ix, iy, pol] = total(input[spotx,spoty])


        ; No - the following does NOT make things better. This is the wrong way
        ; to normalize things here. 
        ;polcube2[iy, ix, pol] = total(input[spotx,spoty]*pixvals) 

        if keyword_set(mask) then mask[iii]=pol+1

    endfor 
    endfor 
    endfor 

    ;; Update FITS header with RA and Dec WCS information
    sz = size(polcube)
    gpi_update_wcs_basic,backbone,imsize=sz[1:2]

    backbone->set_keyword, 'COMMENT', "  For specification of Stokes WCS axis, see ",ext_num=1
    backbone->set_keyword, 'COMMENT', "  Greisen & Calabretta 2002 A&A 395, 1061, section 5.4",ext_num=1

   
    backbone->set_keyword, "NAXIS", sz[0], /saveComment
    backbone->set_keyword, "NAXIS1", sz[1], /saveComment, after='NAXIS'
    backbone->set_keyword, "NAXIS2", sz[2], /saveComment, after='NAXIS1'
    backbone->set_keyword, "NAXIS3", sz[3], /saveComment, after='NAXIS2'

    backbone->set_keyword, "FILETYPE", "Stokes Cube", "What kind of IFS file is this?"
    backbone->set_keyword, "WCSAXES", 3, "Number of axes in WCS system"
    backbone->set_keyword, "CTYPE3", "STOKES",     "Polarization"
    backbone->set_keyword, "CUNIT3", "N/A",       "Polarizations"
    backbone->set_keyword, "CRVAL3", -6, " Stokes axis: image 0 is Y parallel, 1 is X parallel "

    backbone->set_keyword, "CRPIX3", 1.,         "Reference pixel location" ;;ds - was 0, but should be 1, right?
    backbone->set_keyword, "CD3_3",  1, "Stokes axis: image 0 is Y parallel, 1 is X parallel"
    ;backbone->set_keyword, "CDELT3", 1, "Stokes axis: image 0 is Y parallel, 1 is X parallel"

    suffix='-podc'
    *(dataset.currframe[0])=polcube

    @__end_primitive 
end

