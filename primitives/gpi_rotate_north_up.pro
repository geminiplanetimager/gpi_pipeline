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
; PIPELINE ARGUMENT: Name="Rot_Method" Type="string" Range="CUBIC|FFT" Default="CUBIC" Desc='Method to compute the rotation'
; PIPELINE ARGUMENT: Name="Center_Method" Type="string" Range="HEADERS|MANUAL" Default="HEADERS" Desc="Determine the center of rotation from FITS header keywords, manual entry"
; PIPELINE ARGUMENT: Name="centerx" Type="int" Range="[0,281]" Default="140" Desc="Center X Pixel if Center_Method=Manual"
; PIPELINE ARGUMENT: Name="centery" Type="int" Range="[0,281]" Default="140" Desc="Center Y Pixel if Center_Method=Manual"
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
  nslice = sz[3]                ; works for either POL or SPEC modes

  if tag_exist( Modules[thisModuleIndex], "Rot_Method") then Rot_Method= strupcase(Modules[thisModuleIndex].rot_method) else rot_method="CUBIC" ; can be CUBIC or FFT
  if tag_exist( Modules[thisModuleIndex], "center_Method") then center_Method= strupcase(Modules[thisModuleIndex].center_method) else center_method="HEADERS" ; can be CUBIC or FFT
  backbone->Log," using rotation method "+rot_method
  backbone->Log, " using centering method "+center_method
  if rot_method ne 'CUBIC' and rot_method ne 'FFT' then return, error("Invalid rotation method: "+rot_method)
  if center_method ne 'HEADERS' and center_method ne 'MANUAL' then return, error("Invalid rotation method: "+center_method)


	case strupcase(center_method) of
	'HEADERS': begin
		centerx = backbone->get_keyword('PSFCENTX', count=ct1)
		centery = backbone->get_keyword('PSFCENTY', count=ct2)
  		if ct1+ct2 ne 2 then begin
			return, error("Could not get PSFCENTX and PSFCENTY keywords from header. Cannot determine PSF center.")
  		endif 

	end
	'MANUAL': begin
  		centerx=long(Modules[thisModuleIndex].centerx)
  		centery=long(Modules[thisModuleIndex].centery)

		 backbone->set_keyword, 'PSFCENTX', centerx, 'Manually set by user'
		 backbone->set_keyword, 'PSFCENTY', centery, 'Manually set by user'


	end
	endcase
	
  backbone->Log, " center =  ("+strc(centerx)+", "+strc(centery)+")"


  ;; ====== Rotation =======
  ;; First some notes on FITS headers and orientations. 
  ;; CRPA = Cass Rotator Position Angle. Should be always near 0.0 for GPI.
  ;; PA keyword = The position angle of the instrument. Fredrik says: "PA is an offset to
  ;;			the CRPA. In the fixed mode the PA is NOT used and is set to 0. We will
  ;;			for GPI always have CRPA in a fixed value and thus PA would be "0.0"."
  ;; PAR_ANG = Parallactic angle; i.e. angle between vector to zenith and vector to north.
  ;;			Depends only on RA, DEC, LST; is independent of CRPA, IAA, PA etc.
  ;; IAA = Instrument Alignment Angle. Fredrik 2013-03-08: With "0" CRPA and
  ;;			the instrument at the horizon IAA is the angle that is needed to correct
  ;;			so that the N is up in the instrument. Assuming perfect mounting then this
  ;;			would be "0.0", there is a multiple of 90 degrees pending on sideport but
  ;;			"0.0" is fine. This is fixed for any time it is mounted and changes only
  ;;			if the instrument is mounted off and on. 
  ;;
  
  ;; Therefore to rotate an image or cube to have north=up, 
  ;;  (1) rotate it so that up in the image = 'up' for GPI in its standard
  ;;      horizontal orientation e.g. on the L frame cart
  ;;  (2) rotate by the PAR_ANG
  ;;
  ;;  (3) apply small offsets if nonzero values of IAA/CRPA? Or is the idea
  ;;      that Gemini takes into account those when orienting the telescope
  ;;      such that GPI is oriented precisely aligned with the zenith?


  ;; get WCS info from header
  astr_header =  *DataSet.HeadersExt[numfile]
  extast, astr_header, astr, res
  if res eq -1 then return, error("No valid WCS present.")

  getrot, astr_header, npa, cdelt, /silent
  ;;reverse handedness as needed
  if cdelt[0] gt 0 then begin
     hreverse2, cube[*,*,0],  astr_header , tmp,  astr_header , 1, /silent
     for i=0,nslice-1 do cube[*,*,i] = reverse(reform(cube[*,*,i],sz[1],sz[2]))
     npa = -npa
	 centerx0=centerx
	 centerx = sz[1]-1-centerx
	 backbone->set_keyword, 'PSFCENTX', centerx, 'After image flip for handedness'

  endif

  ;;d_PAR_ANG is the angle you wish to rotate
  d_PAR_ANG = -npa

  ;;rotate header (hrot2 rots are CW so rotate -d_PAR_ANG)
  hrot2, cube[*,*,0], astr_header, nearest , astr_header, -d_PAR_ANG, $
         -1, -1, 2,  interp=0,  missing=!values.f_nan
  
  ;Add the rotation angle to the header for future use
  sxaddpar, astr_header, 'ROTANG', -d_PAR_ANG, 'The rotation from Rotate North Up primitive'
  
  case rot_method of
     'FFT': begin
        padsize=289
        cube = padarr(cube0, padsize, [centerx,centery], value=!values.f_nan)
        centerx = (padsize-1)/2+1 & centery = (padsize-1)/2+1

        ;; In order to not have ugly ringing from the FFT rotation, we must
        ;;  (a) not have any NaNs in the input data! and
        ;;  (b) have the out-of-FOV regions match the in-the-FOV regions in intensity
        ;;
        ;; Therefore make a mask to look at the edges, and extrapolate this out
        ;; everywhere. (TODO: a better/more careful job of this.)


        ;; TODO masking of edges?
        ;;  Need to have a better understanding of FFTROT boundary conditions
        ;;  here
        ;;  Enforce the same exact mask on both pols, for consistency
        ;; zeromask = (cube[*,*,0] eq 0) or (cube[*,*,1] eq 0)
        badmask = ~(finite(total(cube,3))) ; any loc not good in ALL slices
        kernel = replicate(1,7,7)
        badmask2 = dilate(badmask, kernel)
        edgemask = badmask2-badmask
        sz = size(cube)
        cube_r = cube

        ;; find where the bad region rotates to
        rotmask = fftrot(badmask, d_PAR_ANG) gt 0.5
        ;; mask out the corner regions outside the FOV too 
        rotmask[search2d(rotmask,0,0,0,0)]=1
        rotmask[search2d(rotmask,0,padsize-1,0,0)]=1
        rotmask[search2d(rotmask,padsize-1,0,0,0)]=1
        rotmask[search2d(rotmask,padsize-1,padsize-1,0,0)]=1

        for i=0L,nslice-1 do begin
           edgeval = median(cube[where(edgemask)+ sz[1]*sz[2]*i ])
           cube[where(badmask)+ sz[1]*sz[2]*i ] = edgeval
           cube_r[*,*,i] = fftrot(cube[*,*,i]-edgeval,  d_PAR_ANG)+edgeval
           cube_r[where(rotmask)+ sz[1]*sz[2]*i ] = !values.f_nan
        endfor
     end 

     'CUBIC': begin
        cube_r = cube
        for i=0,sz[3]-1 do begin
           ;;rot has the same stupid CW conventionas hrot2
           interpolated = rot(reform(cube_r[*,*,i],sz[1],sz[2]), -d_PAR_ANG,1.,centerx,centery, cubic=-0.5, /pivot, missing=!values.f_nan)
           nearest = rot(reform(cube_r[*,*,i],sz[1],sz[2]), -d_PAR_ANG, 1.,centerx,centery, interp=0, /pivot, missing=!values.f_nan)
           wnan = where(~finite(interpolated), nanct)
           if nanct gt 0 then interpolated[wnan] = nearest[wnan]
           cube_r[*,*,i] = interpolated
        endfor
     end  
  endcase 


  backbone->set_keyword, 'HISTORY', "Rotated by "+sigfig(d_PAR_ANG, 4)+" deg to have north up",ext_num=0

  ;;update WCS info
  *DataSet.HeadersExt[numfile] = astr_header

  ;;if there are satspots, rotate them as well
  locs = gpi_satspots_from_header(*DataSet.HeadersExt[numfile])
  if n_elements(locs) gt 1 then  begin
     gpi_rotate_header_satspots,backbone, d_PAR_ANG ,locs,imcent = (sz[1:2]-1)/2
  endif 

  suffix += '-northup'

  *(dataset.currframe[0])=cube_r

  @__end_primitive

 end

