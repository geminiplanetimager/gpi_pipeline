;+
; NAME: gpi_rotate_north_up
; PIPELINE PRIMITIVE DESCRIPTION: Rotate North Up
;
;    Rotate so that North is Up.
;
;
; INPUTS: detector image
; common needed: filter, wavcal, tilt, (nlens)
;
; KEYWORDS:
; GEM/GPI KEYWORDS:RA,DEC,PAR_ANG
; DRP KEYWORDS: CDELT1,CDELT2,CRPIX1,CRPIX2,CRVAL1,CRVAL2,NAXIS1,NAXIS2,PC1_1,PC1_2,PC2_1,PC2_2
; OUTPUTS:
;
; PIPELINE COMMENT: Rotate datacubes so that north is up. 
; PIPELINE ARGUMENT: Name="Method" Type="enum" Range="CUBIC|FFT" Default="CUBIC"
; PIPELINE ARGUMENT: Name="Show" Type="enum" Range="0|1" Default="0"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 3.9
; PIPELINE NEWTYPE: SpectralScience,PolarimetricScience
;
; HISTORY:
;   2009-04-22 MDP: Created, based on DST's cubeextract_polarized. 
;   2011-07-30 MP: Updated for multi-extension FITS
;   2013-07-17 MP: Renamed for consistency
;-
function gpi_rotate_north_up, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

    cube=*(dataset.currframe[0])
    ;if numext eq 0 then hdr=*(dataset.headers)[numfile] else 
	;hdr   =*(dataset.headersPHU)[numfile]
	;hdrext=*(dataset.headersExt)[numfile]
    ;hdr=*(dataset.headers[numfile])
    sz = size(cube)
    nslice = sz[3] ; works for either POL or SPEC modes


    if tag_exist( Modules[thisModuleIndex], "Method") then Method= strupcase(Modules[thisModuleIndex].method) else method="CUBIC" ; can be CUBIC or FFT
    message,/info, " using rotation method "+method
	if method ne 'CUBIC' and method ne 'FFT' then return, error("Invalid rotation method: "+method)

    ; ====== Rotation =======
	; First some notes on FITS headers and orientations. 
	; CRPA = Cass Rotator Position Angle. Should be always near 0.0 for GPI.
	; PA keyword = The position angle of the instrument. Fredrik says: "PA is an offset to
	;			the CRPA. In the fixed mode the PA is NOT used and is set to 0. We will
	;			for GPI always have CRPA in a fixed value and thus PA would be "0.0"."
	; PAR_ANG = Parallactic angle; i.e. angle between vector to zenith and vector to north.
	;			Depends only on RA, DEC, LST; is independent of CRPA, IAA, PA etc.
	; IAA = Instrument Alignment Angle. Fredrik 2013-03-08: With "0" CRPA and
	;			the instrument at the horizon IAA is the angle that is needed to correct
	;			so that the N is up in the instrument. Assuming perfect mounting then this
	;			would be "0.0", there is a multiple of 90 degrees pending on sideport but
	;			"0.0" is fine. This is fixed for any time it is mounted and changes only
	;			if the instrument is mounted off and on. 
	;
	
	; Therefore to rotate an image or cube to have north=up, 
	;  (1) rotate it so that up in the image = 'up' for GPI in its standard
	;      horizontal orientation e.g. on the L frame cart
	;  (2) rotate by the PAR_ANG
	;
	;  (3) apply small offsets if nonzero values of IAA/CRPA? Or is the idea
	;      that Gemini takes into account those when orienting the telescope
	;      such that GPI is oriented precisely aligned with the zenith?

	;d_PA = backbone->get_keyword('PA', count=pa_ct) ; in degrees
	;if PA_ct eq 0 then  
	d_PAR_ANG = backbone->get_keyword('PAR_ANG', count=pa_ct) 
    message,/info, "PAR_ANG is "+strc(d_PAR_ANG)

    ; we first pad into a 289x289 array. This is large enough to have the
    ; full FOV within it at all orientations. 
    padsize=289
    cube0 =cube
    ; TODO more careful handling of center location here.
    
    xcen=139  ; FIXME - hard coded for DST data
    ycen=142
    cube = padarr(cube0, padsize, [xcen,ycen], value=!values.f_nan)
    xcen = (padsize-1)/2+1 & ycen = (padsize-1)/2+1

    ; In order to not have ugly ringing from the FFT rotation, we must
    ;  (a) not have any NaNs in the input data! and
    ;  (b) have the out-of-FOV regions match the in-the-FOV regions in intensity
    ;
    ; Therefore make a mask to look at the edges, and extrapolate this out
    ; everywhere. (TODO: a better/more careful job of this.)


    ; TODO masking of edges?
    ;  Need to have a better understanding of FFTROT boundary conditions
    ;  here
    ;  Enforce the same exact mask on both pols, for consistency
    ;zeromask = (cube[*,*,0] eq 0) or (cube[*,*,1] eq 0)
    badmask = ~(finite(total(cube,3))) ; any loc not good in ALL slices
    kernel = replicate(1,7,7)
    badmask2 = dilate(badmask, kernel)
    edgemask = badmask2-badmask
    sz = size(cube)
    cube_r = cube
    ; find where the bad region rotates to
    case method of
    'CUBIC': rotmask = rot(float(badmask), -d_PAR_ANG,cubic=-0.5,/interp) gt 0.5
    'FFT': begin
        rotmask = fftrot(badmask, d_PAR_ANG) gt 0.5
        ; mask out the corner regions outside the FOV too 
        rotmask[search2d(rotmask,0,0,0,0)]=1
        rotmask[search2d(rotmask,0,padsize-1,0,0)]=1
        rotmask[search2d(rotmask,padsize-1,0,0,0)]=1
        rotmask[search2d(rotmask,padsize-1,padsize-1,0,0)]=1
    end
    endcase
    for i=0L,nslice-1 do begin
        edgeval = median(cube[where(edgemask)+ sz[1]*sz[2]*i ])
        ;print, edgeval
        cube[where(badmask)+ sz[1]*sz[2]*i ] = edgeval
        ; set the background to 0 when fftrotating?
        case method of
        'CUBIC': cube_r[*,*,i] = rot(cube[*,*,i]-edgeval,  -d_PAR_ANG ,cubic=-0.5,/interp)+edgeval
        'FFT': cube_r[*,*,i] = fftrot(cube[*,*,i]-edgeval,  d_PAR_ANG)+edgeval
        endcase
    
        cube_r[where(rotmask)+ sz[1]*sz[2]*i ] = !values.f_nan
    endfor

;  code for examining PSF alignment. TODO - figure out center shift issues in FFTROT
;    sl = cube[*,*,0]-edgeval
;    slr = fftrot(sl, d_PA)
;    slr2 = fftrot(sl, d_PA,/nopad)
;    slr3 = rot(sl,-d_PA,/interp,/cubic)
;     atv, [[[sl]],[[slr]],[[slr2]],[[slr3]]],/bl
;
;    stop
;
    
    if keyword_set(stop) then    begin
        ss =  [[[cube]],[[cube_r]]]
        ss = ss[*,*,[0,2,1,3]]
        atv, ss,/bl

        stop
    endif
    backbone->set_keyword, 'HISTORY', "Rotated by "+sigfig(d_PAR_ANG, 4)+" deg to have north up",ext_num=0
    ;backbone->set_keyword, "PA", 0.0, 'Image is rotated to have north=up';/saveComment


    ;atv, [[[cube]],[[cube_r]]],/bl
    cube=cube_r






    ;--- Update FITS header information here. --
    ; Only modify parameters which we have just changed!
    ;
    ; Some notes on angle conventions for WCS:
    ; The rotation angle below needs to be the angle for how much the image's Y
    ; axis was rotated with respect to north. This is termed the 'Vertical
    ; angle'; see http://www.ucolick.org/~sla/deimos/swpdr/va.html
    ;
    ; The rotation matrix here is used to convert from IMAGE coords to SKY
    ; coords. Hence the sense of the rotation is opposite the Parallactic Angle
    pixelscale = gpi_get_ifs_lenslet_scale(*DataSet.HeadersExt[numfile])

    ; rotation matrix.
    ;
    ; TODO: figure out whether the image is SKY RIGHT or SKY LEFT
    ;  i.e. where's east??
	new_PA = 0.0
    pc = [[cos(-new_PA*!dtor), -sin(-new_PA*!dtor)], $
          [sin(-new_PA*!dtor), cos(-new_PA*!dtor)]]
	  
	; 2012-12-09 MP update: Gemini standards require us to write CDi_j instead
	; of the older PCi_j and CDELTi keywords. 
	; See Griesen et al. 2002 section 2.1.2 for a detailed discussion of the relation between these. 
	; Briefly, the CD matrix is the PC matrix plus the scaling factor formerly
	; known as CDELT.
	cdmatrix = pc * pixelscale / 3600

    ra = backbone->get_keyword("RA") 
    dec = backbone->get_keyword("dec") 

;    sxaddhist, /comment, "  For specification of Stokes WCS axis, see ", hdr
;    sxaddhist, /comment, "  Greisen & Calabretta 2002 A&A 395, 1061, section 5.4", hdr
;
;    sxaddpar, hdr, "FILETYPE", "Stokes Cube", "What kind of IFS file is this?"
;    sxaddpar, hdr, "WCSAXES", 3, "Number of axes in WCS system"
;    sxaddpar, hdr, "CTYPE1", "RA---TAN","Right Ascension."
;    sxaddpar, hdr, "CTYPE2", "DEC--TAN","Declination."
;    sxaddpar, hdr, "CTYPE3", "STOKES",     "Polarization"
;    sxaddpar, hdr, "CUNIT1", "deg",  "R.A. unit is degrees, always"
;    sxaddpar, hdr, "CUNIT2", "deg",  "Declination unit is degrees, always"
;    sxaddpar, hdr, "CUNIT3", "N/A",       "Polarizations"
    sz = size(cube)
    backbone->set_keyword, "NAXIS1", sz[1], ext_num=1
    backbone->set_keyword, "NAXIS2", sz[2], ext_num=1
    backbone->set_keyword, "CRVAL1", ra, "R.A. at reference pixel"
    backbone->set_keyword, "CRVAL2", dec, "Declination at reference pixel"
;    backbone->set_keyword, "CRVAL3", -6, " Stokes axis: image 0 is Y parallel, 1 is X parallel "
    ; need to add 1 here to account for "IRAF/FITS" 1-based convention used for
    ; WCS coordinates
    backbone->set_keyword, "CRPIX1", xcen+1,         "Reference pixel location"
    backbone->set_keyword, "CRPIX2", ycen+1,         "Reference pixel location"
;    backbone->set_keyword, "CRPIX3", 0,         "Reference pixel location"
    ;backbone->set_keyword, "CDELT1", pixelscale/3600., "Pixel scale is "+sigfig(pixelscale,2)+" arcsec/pixel"
    ;backbone->set_keyword, "CDELT2", pixelscale/3600., "Pixel scale is "+sigfig(pixelscale,2)+" arcsec/pixel"
;    backbone->set_keyword, "CDELT3", 1, "Stokes axis: image 0 is Y parallel, 1 is X parallel"


    backbone->set_keyword, "CD1_1", cdmatrix[0,0], "partial of first axis coordinate w.r.t. x"
    backbone->set_keyword, "CD1_2", cdmatrix[0,1], "partial of first axis coordinate w.r.t. y"
    backbone->set_keyword, "CD2_1", cdmatrix[1,0], "partial of second axis coordinate w.r.t. x"
    backbone->set_keyword, "CD2_2", cdmatrix[1,1], "partial of second axis coordinate w.r.t. y"
;    sxaddpar, hdr, "PC3_3", 1, "Stokes axis is unrotated"
    ; TODO WCS paper III suggests adding MJD-AVG to specify midpoint of
    ; observations for conversions to barycentric.
;    sxaddpar, hdr, "RADESYS", "FK5", "RA and Dec are in FK5"
;    sxaddpar, hdr, "EQUINOX", 2000.0, "RA, Dec equinox is J2000"
;


    suffix += '-northup'

    *(dataset.currframe[0])=cube
	;*(dataset.headersPHU)[numfile] = hdr
	;*(dataset.headersExt)[numfile] = hdrext
    
    ;if numext eq 0 then *(dataset.headers)[numfile]=hdr else *(dataset.headersPHU)[numfile]=hdr
    ;*(dataset.headers[numfile])=hdr
    
@__end_primitive

end

