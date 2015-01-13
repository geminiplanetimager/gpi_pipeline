pro gpi_update_wcs_basic,backbone,parang=parang,imsize=imsize
;+
; NAME:
;      GPI_UPDATE_WCS_BASIC
;
; PURPOSE:
;      Update WCS info in GPI header based only on info available from
;      Gemini and GPI keywords (assume ra/dec are correct, star is
;      centered in image and approximate true exposure start/end times).
;
; CALLING SEQUENCE:
;      gpi_update_wcs_basic,backbone
;
; INPUTS:
;      Backbone - Pipeline backbone object
;      imsize - Image dimensions (defaults to 281x281)
;      parang - Parallactic angle (degrees) - overrides
;               PARANG keyword in header. If set, AVPARANG is also set
;               to this value.
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; COMMON BLOCKS:
;     
;
; RESTRICTIONS:
;
; EXAMPLE:
;
; NOTES:
;     This is intended to be called from pipeline primitives. When a
;     parang input is given, both the PAR_ANG and AVPARANG keywords
;     are set to this value.  This makes the PAR_ANG not correspond to
;     the UTSART
;
; ====== Rotation =======
; First some notes on FITS headers and orientations. 
; CRPA = Cass Rotator Position Angle. Should be always near 0.0 for GPI.
; PA keyword = The position angle of the instrument. Fredrik says: "PA is an offset to
;	       the CRPA. In the fixed mode the PA is NOT used and is set to 0. We will
;	       for GPI always have CRPA in a fixed value and thus PA would be "0.0"."
; PAR_ANG = Parallactic angle; i.e. angle between vector to zenith and vector to north.
;	    Depends only on RA, DEC, LST; is independent of CRPA, IAA, PA etc.
; IAA = Instrument Alignment Angle. Fredrik 2013-03-08: With "0" CRPA and
;	the instrument at the horizon IAA is the angle that is needed to correct
;	so that the N is up in the instrument. Assuming perfect mounting then this
;	would be "0.0", there is a multiple of 90 degrees pending on sideport but
;	"0.0" is fine. This is fixed for any time it is mounted and changes only
;	if the instrument is mounted off and on. 
;
; ==== Angle conventions for WCS ==========
; The rotation angle below needs to be the angle for how much the image's Y
; axis was rotated with respect to north. This is termed the 'Vertical
; angle'; see http://www.ucolick.org/~sla/deimos/swpdr/va.html
;
; The rotation matrix here is used to convert from IMAGE coords to SKY
; coords. Hence the sense of the rotation is opposite the Parallactic Angle
;
; MODIFICATION HISTORY:
;	Written 08.15.2013 - ds
;	2013-11-12 M. P: Modified to account for IFS internal rotations as
;					 determined by Perrin, Thomas, Chilcote, & Savransky
;-

  compile_opt defint32, strictarr, logical_predicate

  ;;we're assuming that the star is centered
  if ~keyword_set(imsize) then begin
     imsize = [backbone->get_keyword('NAXIS1',count=ct1),backbone->get_keyword('NAXIS2',count=ct2)]
     if ct1+ct2 ne 2 then begin
        backbone->log,'GPI_UPDATE_WCS_BASIC: NAXISi keywords not found in header.'
        return
     end 
  end 

  x0 = imsize[0]/2
  y0 = imsize[1]/2

  ;;grab the pixelscale
  pixelscale = gpi_get_constant('ifs_lenslet_scale') ; arcseconds
  
  ;;get the necessary keywords from the header
  totcount = 0
  ra = 	    double(backbone->get_keyword( 'RA',count=ct)) & totcount += ct
  dec =     double(backbone->get_keyword( 'DEC',count=ct)) & totcount += ct
  if n_elements(parang) eq 0 then begin
     par_ang = double(backbone->get_keyword( 'PAR_ANG',count=ct))
 	 ; this angle in the header is an inaccurate approximation since the
	 ; field is rotating during the image. Adding a comment to say it's 
	 ; inaccurate in the header comment
	 backbone->set_keyword, "PAR_ANG", par_ang, "Parallactic Angle (Inaccurate. Use AVPARANG)"
     totcount += ct 
  endif else begin
     backbone->set_keyword, "PAR_ANG", parang, "average parallactic angle during exposure"
     par_ang = parang
     totcount += 1
  endelse
  if totcount ne 3 then begin
     backbone->log,'GPI_UPDATE_WCS_BASIC: RA/DEC/PAR_ANG keyword not found in header.'
     return
  endif 

  ;;write first block of CD matrix
  backbone->set_keyword, 'HISTORY', "GPI_UPDATE_WCS_BASIC: Creating WCS header",ext_num=0
  backbone->set_keyword, 'CTYPE1', 'RA---TAN', 'First axis is Right Ascension'
  backbone->set_keyword, 'CTYPE2', 'DEC--TAN', 'Second axis is Declination'
  backbone->set_keyword, 'CRPIX1', x0+1, 'x-coordinate of ref pixel [note: first pixel is 1]'
  backbone->set_keyword, 'CRPIX2', y0+1, 'y-coordinate of ref pixel [note: first pixel is 1]'
  backbone->set_keyword, 'CRVAL1', ra, 'Right ascension at ref point' 
  backbone->set_keyword, 'CRVAL2', dec, 'Declination at ref point' ;TODO should see gemini type convention

;Remainder of CD matrix update takes place at the end of the file
;after AVPARANG is calculated.  PAR_ANG is from the start of the
;exposure, and can be off by up to 10 degrees.

  ;;specify coord sys - Gemini standard is FK5 J2000.0
  backbone->set_keyword, "RADESYS", "FK5", "RA and Dec are in FK5"
  backbone->set_keyword, "EQUINOX", 2000.0, "RA, Dec equinox is J2000"


  ;;you only need to figure out the AVPARANG if you're not
  ;;overriding the header PARANG value.  Otherwise, they are equal
  if n_elements(parang) ne 0 then begin
     backbone->set_keyword, "AVPARANG", parang, "average parallactic angle during exposure"
  endif else begin

     ;;now we figure out when the exposure was actually taken
     ;;grab header info you'll need
     totcount = 0
     readtime = backbone->get_keyword('READTIME',count=ct) & totcount += ct
     itime = backbone->get_keyword('ITIME',count=ct) & totcount += ct
     utstart = backbone->get_keyword('UTSTART',count=ct) & totcount += ct
     utend = backbone->get_keyword('UTEND',count=ct) & totcount += ct
     dateobs =  backbone->get_keyword('DATE-OBS',count=ct) & totcount += ct
     ngroup =  backbone->get_keyword('NGROUP',count=ct) & totcount += ct
     
     if (totcount ne 6)  then begin
        backbone->log,'GPI_UPDATE_WCS_BASIC: Could not extract timing information from header.'
        return
     endif 

     ;;get exposure start and end times
     utstartd =  ten(double(strsplit(utstart,':',/extract))) ;dec hrs
     utendd =  ten(double(strsplit(utend,':',/extract)))     ; dec hrs
     readtimed = double(readtime)/1d6/3600d0                 ;us -> dec hrs
     if utendd lt utstartd then dateline = 1 else dateline = 0 ;account for crossing UTC dateline
     expend = utendd - 0.5d0*readtimed
                                ;expstart = utendd - (ngroup-0.5)*readtimed
     expstart = utendd - itime/3600d
     if expend lt 0d then begin
        expend += 24d0
        dateline = 0
     endif 

     ;;sanity checks
                                ;if (abs(itime/3600d - (expend-expstart)) gt 1d-6) || (expstart lt utstartd) then begin
     if expstart lt utstartd then begin   
        backbone->log,'GPI_UPDATE_WCS_BASIC: Error calculating exposure start and end times.'
        return
     endif

     ;;get the date
     ymd0 = double(strsplit(dateobs,'-',/extract))
     ;;account for dateline, if needed
     if dateline then begin
        jd0 = julday(ymd0[1],ymd0[2],ymd0[0])
        caldat, jd0+1d0, m1, d1, y1
        ymd1 = double([y1,m1,d1])
     endif else ymd1 = ymd0
     hms0 = sixty(expstart)
     hms1 = sixty(expend)
     jd0 = julday(ymd0[1], ymd0[2], ymd0[0],hms0[0],hms0[1],hms0[2])
     jd1 = julday(ymd1[1], ymd1[2], ymd1[0],hms1[0],hms1[1],hms1[2])
     epoch0 = (jd0 - 2451545d0)/365.25d0 + 2000d0 
     epoch1 = (jd1 - 2451545d0)/365.25d0 + 2000d0 
     
     ;;grab longitude of observatory
     lon = gpi_get_constant('observatory_lon',default=-70.73669333333333d0)/15d0 ;East lon (dec. hr)
     
     ;; converting from UT to GMST - call CT2LST on prime meridian
     CT2LST, gmst0, 0., 0., expstart, ymd0[2], ymd0[1], ymd0[0]
     CT2LST, gmst1, 0., 0., expend, ymd1[2], ymd1[1], ymd1[0]
     
     ;;GMST -> LST
     lst0 = gmst0 + lon
     lst1 = gmst1 + lon

     ;;precess RA/DEC to current epoch
     ra0 = ra
     dec0 = dec
     precess, ra0, dec0, 2000d0, epoch0

     ;; get hour angles
     ha0 = lst0 - ra0/15d0
     ha1 = lst1 - ra0/15d0
     
     ;; calcualte average parang
     avparang = calc_avparang(ha0,ha1,dec0)

     ;;calculate the MJD-AVG
     avmjd = (jd0+jd1)/2d0 - 2400000.5d0

     ;;write additional keywords
     backbone->set_keyword, "EXPSTART", string(sixty(expstart),format='(I02.2,":",I02.2,":",F06.3)'),"true exposure start time (UTC)"
     backbone->set_keyword, "EXPEND", string(sixty(expend),format='(I02.2,":",I02.2,":",F06.3)'),"true exposure start time (UTC)"
     backbone->set_keyword, "AVPARANG", avparang, "average parallactic angle during exposure"
     backbone->set_keyword, "MJD-AVG", avmjd, "MJD at midpoint of exposure"
  endelse 

  ;Now using AVPARANG to compute CD matrix.

  ifs_rotation = gpi_get_constant('ifs_rotation')
  vert_angle = -(360-avparang) + ifs_rotation  -90 ; 90 deg is rotation of the H2RG w.r.t. where the (0,0) corner is

  ;;; CLockwise rotation of negative PA
  pc = [[cos(vert_angle*!dtor), -sin(vert_angle*!dtor)], $
        [sin(vert_angle*!dtor), cos(vert_angle*!dtor)]]
  cdmatrix = pc * pixelscale / 3600d0

  ;; flip sign of X axis?  ; Not necessary if GPI is on bottom port!
  ;cdmatrix[0, *] *= -1
  
  backbone->set_keyword, "CD1_1", cdmatrix[0,0], "partial of first axis coordinate w.r.t. x"
  backbone->set_keyword, "CD1_2", cdmatrix[0,1], "partial of first axis coordinate w.r.t. y"
  backbone->set_keyword, "CD2_1", cdmatrix[1,0], "partial of second axis coordinate w.r.t. x"
  backbone->set_keyword, "CD2_2", cdmatrix[1,1], "partial of second axis coordinate w.r.t. y"


  ;; enforce standard convention preferred by Gemini of using the CD instead of
  ;; PC + CDELT matrices
  backbone->del_keyword, 'PC1_1' 
  backbone->del_keyword, 'PC1_2' 
  backbone->del_keyword, 'PC2_1' 
  backbone->del_keyword, 'PC2_2' 
  backbone->del_keyword, 'PC3_3'
  backbone->del_keyword, 'PC1_1',ext_num=1 
  backbone->del_keyword, 'PC1_2',ext_num=1 
  backbone->del_keyword, 'PC2_1',ext_num=1 
  backbone->del_keyword, 'PC2_2',ext_num=1  
  backbone->del_keyword, 'PC3_3',ext_num=1 

end



