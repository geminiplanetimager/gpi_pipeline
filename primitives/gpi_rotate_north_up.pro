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

        ;;preferentially use AVPARANG
        d_PAR_ANG = backbone->get_keyword('AVPARANG',count=pa_ct)
        if pa_ct eq 0 then d_PAR_ANG = backbone->get_keyword('PAR_ANG',count=pa_ct)

        ;message,/info, "PAR_ANG is "+strc(d_PAR_ANG)
    
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

    cube=cube_r

    ;;update WCS info
    gpi_update_wcs_basic,backbone,parang=0d0,imsize=sz[1:2]

    ;;if there are satspots, rotate them as well
    locs = gpi_satspots_from_header(*DataSet.HeadersExt[numfile])
    if n_elements(locs) gt 1 then  begin
       gpi_rotate_header_satspots,backbone, d_PAR_ANG ,locs,imcent = (sz[1:2]-1)/2
    endif 

    suffix += '-northup'

    *(dataset.currframe[0])=cube

    @__end_primitive

end

