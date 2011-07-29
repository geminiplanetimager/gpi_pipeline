;+
; NAME: extractpol
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Polarization Cube
; 
; 		extract polarization-mode data cube from an image
;		define first suffix '-podc' (polarization data-cube)
;
;		This routine transforms a 2D detector image in the dataset.currframe input
;		structure into a 3D data cube in the dataset.currframe output structure.
;		(not much of a data cube - really just 2x 2D images)
;
;	*** This routine is ENTIRELY UNTESTED AND WILL NOT WORK ***
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
;		-Combine these into a weighted average, weighted by the S/N per pixel
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
; PIPELINE ARGUMENT: Name="Rotate" Type="enum" Range="0|1" Default="0"
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
;   2011-06-07 JM: added FITS/MEF compatibility
;+

forward_function error

function extractpol, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='polcal'
@__start_primitive


;;	common PIP
;;	COMMON APP_CONSTANTS
;;		getmyname, functionname

 input=*(dataset.currframe[0])
  if numext eq 0 then begin 
    hdr=*(dataset.headers)[numfile] 
  endif else begin 
      hdr=*(dataset.headersPHU)[numfile]
      hdrext=*(dataset.headers)[numfile]
  endelse    
 ;hdr=*(dataset.headers[numfile])



;------------------
;+
; NAME:  cubeextract_polarized
; 	Extract polarizations from a detector image, 
; 	using lookup tables for each lenslet from an IDL save file.
;
; INPUTS:
; 	filename	name of file to extract
; KEYWORDS:
; 	/rotate		rotate to put north up
;	/forceh		force it to reduce it as H (useful for missing keywords?)
;	/stop		stop to examine
;	/grow		use slightly larger regions by 1 pixel in all directions to extract
;	/makeflat	make a flat by normalizing it
; OUTPUTS:
; 	mask=		compute and return a mask? I forget what this was for
;
; 	Writes file to Pol_##_filter.fits
;
; HISTORY:
; 	Began 2008-04-24 13:25:55 by Marshall Perrin 
;-

	; Validate the input data
	if ~(keyword_set(forceh)) then begin
		filt = strc(sxpar(hdr, "FILTER"))
		mode= strc(sxpar(hdr, "PRISM", count=ct))
		if ct eq 0 then mode= strc(sxpar(hdr, "DISPERSR", count=ct))
		if ct eq 0 then mode= strc(sxpar(hdr, "FILTER2", count=ct))

		if mode ne "Polarimetry" then message, "That's not a polarimetry file!"
	endif else begin
		filt="H"
	endelse

;;		; Read in calibration file
;;		; FIXME: this needs to be way, way better! - MP
;;		thisModuleIndex=backbone->GetCurrentModuleIndex()
;;	
;;	    c_File = Modules[thisModuleIndex].CalibrationFile
;;		if strmatch(c_File, 'AUTOMATIC',/fold) then c_File = (Backbone_comm->Getgpicaldb())->get_best_cal_from_header( 'polcal', *(dataset.headers)[numfile] )
;;	
;;		if file_test(c_File) then begin
	polspot_coords = readfits(c_File, ext=1)
	polspot_pixvals = readfits(c_File, ext=2)
;;		endif else begin
;;			return, error("Calibration file "+c_File+" does not exist!")
;;		endelse
	
	sz = size(polspot_coords)
	nx = sz[1+2]
	ny = sz[2+2]

	polcube = fltarr(nx, ny, 2)+!values.f_nan
	polcube2 = fltarr(nx, ny, 2)+!values.f_nan
	wpangle =  strc(sxpar(hdr, "WPANGLE"))
	print, "    WP angle is "+strc(wpangle)
	;sxaddhist, functionname+": Extracting polarized slices using ", hdr
	;sxaddhist, functionname+": "+c_File, hdr
  sxaddparlarge,hdr,'HISTORY',functionname+": Extracting polarized slices using "
  sxaddparlarge,hdr,'HISTORY',functionname+": "+c_File

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

		;iii = *(polcoords[ix, iy,pol])
		;if n_elements(iii) eq 1 and iii[0] eq -1 then continue
		if keyword_set(grow) then iii= uniqvals([iii, iii+1, iii-1, iii+nx, iii-nx])
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

	
;
;	; ====== Rotation =======
;	;if keyword_set(stop) then	stop
;	print, "PAR_ANG is "+strc(d_PA)
;
;	; optional: rotate to have NORTH UP
;	if  keyword_set(rotate) then begin
;		; we first pad into a 289x289 array. This is large enough to have the
;		; full FOV within it at all orientations. 
;		padsize=289
;		polcube0 =polcube
;		polcube = padarr(polcube0, padsize, [xcen, ycen])
;		xcen = (padsize-1)/2 & ycen = (padsize-1)/2
;
;		; TODO masking of edges?
;		;  Need to have a better understanding of FFTROT boundary conditions
;		;  here
;		;  Enforce the same exact mask on both pols, for consistency
;		zeromask = (polcube[*,*,0] eq 0) or (polcube[*,*,1] eq 0)
;		kernel = replicate(1,7,7)
;		zeromask2 = dilate(zeromask, kernel)
;		edgemask = zeromask2-zeromask
;		sz = size(polcube)
;		polcube_r = polcube
;		rotmask = fftrot(zeromask, d_PA) gt 0.5
;		; grab the corners and mask them too.
;		rotmask[search2d(rotmask,0,0,0,0)]=1
;		rotmask[search2d(rotmask,0,padsize-1,0,0)]=1
;		rotmask[search2d(rotmask,padsize-1,0,0,0)]=1
;		rotmask[search2d(rotmask,padsize-1,padsize-1,0,0)]=1
;		for i=0L,1 do begin
;			edgeval = median(polcube[where(edgemask)+ sz[1]*sz[2]*i ])
;			polcube[where(zeromask)+ sz[1]*sz[2]*i ] = edgeval
;			; set the background to 0 when fftrotating?
;			polcube_r[*,*,i] = fftrot(polcube[*,*,i]-edgeval,  d_PA)+edgeval
;			polcube_r[where(rotmask)+ sz[1]*sz[2]*i ] = !values.f_nan
;		endfor
;
;		
;		if keyword_set(stop) then	begin
;			ss =  [[[polcube]],[[polcube_r]]]
;			ss = ss[*,*,[0,2,1,3]]
;			atv, ss,/bl
;
;			stop
;		endif
;		sxaddhist, "Rotated by "+sigfig(d_PA, 4)+" deg to have north up", hdr
;		d_PA = 0.0
;		polcube=polcube_r
;
;	endif
;


;
;	if keyword_set(stop) then	stop
;
;
;
	; TODO build FITS header information here.
	; Some notes on angle conventions for WCS:
	; The rotation angle below needs to be the angle for how much the image's Y
	; axis was rotated with respect to north. This is termed the 'Vertical
	; angle'; see http://www.ucolick.org/~sla/deimos/swpdr/va.html
	;
	; The rotation matrix here is used to convert from IMAGE coords to SKY
	; coords. Hence the sense of the rotation is opposite the PA.
	pixelscale = 0.014
    ; rotation matrix.
	d_PA = sxpar(hdr, "PAR_ANG") ; in DEGREEs
    pc = [[cos(-d_PA*!dtor), -sin(-d_PA*!dtor)], $
          [sin(-d_PA*!dtor), cos(-d_PA*!dtor)]]
	ra = sxpar(hdr,"RA") 
	if size(ra,/tname) eq 'STRING' then begin
		; read in old-style incorrectly formatted as strings values.
		if strc(ra) eq "" then ra=0.0 else $
		ra = ten_string(sxpar(hdr,"RA"))*15 ; in deg
		stop
		dec = ten_string(sxpar(hdr,"dec")) ; in deg
	endif else begin ; read in properly formatted ones, already in decimal degrees
		ra = sxpar(hdr,"RA") 
		dec = sxpar(hdr,"dec") 
	endelse
	;stop
	if numext eq 0 then begin
	    hdrim=hdr
	endif else begin
	    hdrim=hdrext
	endelse
	sxaddhist, /comment, "  For specification of Stokes WCS axis, see ", hdrim
	sxaddhist, /comment, "  Greisen & Calabretta 2002 A&A 395, 1061, section 5.4", hdrim


	sxaddhist, functionname+": Creating WCS header", hdrim
    sz = size(polcube)
    sxaddpar, hdrim, "NAXIS", sz[0], /saveComment
    sxaddpar, hdrim, "NAXIS1", sz[1], /saveComment, after='NAXIS'
    sxaddpar, hdrim, "NAXIS2", sz[2], /saveComment, after='NAXIS1'
    sxaddpar, hdrim, "NAXIS3", sz[3], /saveComment, after='NAXIS2'

	sxaddpar, hdrim, "FILETYPE", "Stokes Cube", "What kind of IFS file is this?"
    sxaddpar, hdrim, "WCSAXES", 3, "Number of axes in WCS system"
    sxaddpar, hdrim, "CTYPE1", "RA---TAN","Right Ascension."
    sxaddpar, hdrim, "CTYPE2", "DEC--TAN","Declination."
    sxaddpar, hdrim, "CTYPE3", "STOKES",     "Polarization"
    sxaddpar, hdrim, "CUNIT1", "deg",  "R.A. unit is degrees, always"
    sxaddpar, hdrim, "CUNIT2", "deg",  "Declination unit is degrees, always"
    sxaddpar, hdrim, "CUNIT3", "N/A",       "Polarizations"
    sxaddpar, hdrim, "CRVAL1", ra, "R.A. at reference pixel"
    sxaddpar, hdrim, "CRVAL2", dec, "Declination at reference pixel"
    sxaddpar, hdrim, "CRVAL3", -6, " Stokes axis: image 0 is Y parallel, 1 is X parallel "
	; need to add 1 here to account for "IRAF/FITS" 1-based convention used for
	; WCS coordinates
	xcen=139 ; always perfectly centered for sims
	ycen=139 
    sxaddpar, hdrim, "CRPIX1", xcen+1,         "Reference pixel location"
    sxaddpar, hdrim, "CRPIX2", ycen+1,         "Reference pixel location"
    sxaddpar, hdrim, "CRPIX3", 0,         "Reference pixel location"
    sxaddpar, hdrim, "CDELT1", pixelscale/3600., "Pixel scale is "+sigfig(pixelscale,2)+" arcsec/pixel"
    sxaddpar, hdrim, "CDELT2", pixelscale/3600., "Pixel scale is "+sigfig(pixelscale,2)+" arcsec/pixel"
    sxaddpar, hdrim, "CDELT3", 1, "Stokes axis: image 0 is Y parallel, 1 is X parallel"

    sxaddpar, hdrim, "PC1_1", pc[0,0], "RA, Dec axes rotated by "+sigfig(d_pa*!radeg,4)+" degr."
    sxaddpar, hdrim, "PC1_2", pc[0,1], "RA, Dec axes rotated by "+sigfig(d_pa*!radeg,4)+" degr."
    sxaddpar, hdrim, "PC2_1", pc[1,0], "RA, Dec axes rotated by "+sigfig(d_pa*!radeg,4)+" degr."
    sxaddpar, hdrim, "PC2_2", pc[1,1], "RA, Dec axes rotated by "+sigfig(d_pa*!radeg,4)+" degr."
    sxaddpar, hdrim, "PC3_3", 1, "Stokes axis is unrotated"
    ; TODO WCS paper III suggests adding MJD-AVG to specify midpoint of
    ; observations for conversions to barycentric.
    sxaddpar, hdrim, "RADESYS", "FK5", "RA and Dec are in FK5"
    sxaddpar, hdrim, "EQUINOX", 2000.0, "RA, Dec equinox is J2000"




;
;	if keyword_set(show) then begin
;		erase
;		imdisp_with_contours, total(polcube,3), pixelscale=0.014, /nocontours, title=outname,/alog
;		getrot, hdr, angle, cdelt,/silent
;		arrows2, angle-90, /data, 1.4, -1.4  ; need to subtract 90 to account for astronomical north=0 convention
;
;	endif
;
	
;------------------

suffix='-podc'
*(dataset.currframe[0])=polcube
if numext eq 0 then begin
 *(dataset.headers[numfile])=hdrim 
 endif else begin
  *(dataset.headersPHU[numfile])=hdr
 *(dataset.headers[numfile])=hdrim
endelse 


@__end_primitive 
;;	
;;	   if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;;	      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;;	      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
;;	      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;;	    endif else begin
;;	      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;;	          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
;;	    endelse
;;	
;; return, ok

end

