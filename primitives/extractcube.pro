;+
; NAME: extractcube
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Spectral Datacube
;
;		This routine transforms a 2D detector image in the dataset.currframe input
;		structure into a 3D data cube in the dataset.currframe output structure.
;   This routine extracts data cube from an image using spatial summation along the dispersion axis
;     introduced suffix '-rawspdc' (raw spectral data-cube)
;
; KEYWORDS: 
; GEM/GPI KEYWORDS:IFSFILT
; OUTPUTS:
;
; PIPELINE COMMENT: Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: SpectralScience, Calibration
;
; HISTORY:
; 	Originally by Jerome Maire 2007-11
;   2008-04-02 JM: spatial summation window centered on pixel and interpolation on the zem. comm. wav. vector
;	  2008-06-06 JM: adapted to pipeline inputs
;   2009-04-15 MDP: Documentation updated. 
;   2009-06-20 JM: adapted to wavcal input
;   2009-09-17 JM: added DRF parameters
;   2012-02-01 JM: adapted to vertical dispersion
;   2012-02-09 DS: offloaded sdpx calculation
;   2013-04-02 JBR: Correction on the y coordinate when reading the det array to match centered pixel convention. Removal of the reference pixel aera.
;-
function extractcube, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

  ;get the 2D detector image
  det=*(dataset.currframe[0])

  nlens=(size(wavcal))[1]       ;pixel sidelength of final datacube (spatial dimensions) 
  dim=(size(det))[1]            ;detector sidelength in pixels

  ;error handle if readwavcal or not used before
  if (nlens eq 0) || (dim eq 0)  then $
     return, error('FAILURE ('+functionName+'): Failed to load wavelength calibration data prior to calling this primitive.') 
            
  ;define the common wavelength vector with the IFSFILT keyword:
  filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  
  ;error handle if IFSFILT keyword not found
  if (filter eq '') then $
     return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 

  ;get length of spectrum
  sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)
  if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')
  
  ;get tilts of the spectra included in the wavelength solution:
  tilt=wavcal[*,*,4]

  cubef3D=dblarr(nlens,nlens,sdpx) ;create the datacube

  for i=0,sdpx-1 do begin       
     ;through spaxels
     cubef=dblarr(nlens,nlens) 
     ;get the locations on the image where intensities will be extracted:
     x3=xmini-i
     y3=wavcal[*,*,1]+(wavcal[*,*,0]-x3)*tan(tilt[*,*])	
  
     ;extract intensities on a 3x1 box:
     ;y3 is a float and the reference is the center of the pixel. It means for instance that -0.5<y<0.5 refers to pixel number 0 and 1.5<y<2.5 refers to pixel number 2.
     ;So the round function is needed to reference the right pixel.
     cubef=det[Round(y3),x3]+det[Round(y3+1),x3]+det[Round(y3-1),x3]
      
     ;declare as Nan mlens not on the detector (or on the reference pixel aera, i.e. 5 pixels on each side):
     bordx=where(~finite(x3) OR (x3 LE 4.0) OR (x3 GE 2043.0),cc)
     if (cc ne 0) then cubef[bordx]=!VALUES.F_NAN
     bordy=where(~finite(y3) OR (Round(y3) LE 5.0) OR (Round(y3) GE 2042.0),cc)
     if (cc ne 0) then cubef[bordy]=!VALUES.F_NAN
     
     cubef3D[*,*,i]=cubef
  endfor

  suffix='-rawspdc'
  ; put the datacube in the dataset.currframe output structure:
  *(dataset.currframe[0])=cubef3D

  ; Update FITS header with RA and Dec WCS information
  ; the spectral axis WCS will be added in interpol_spec_oncommwavvect
  
  ; Assume the star is precisely centered in the FOV (TBD improve this)
   
    x0=nlens/2
    y0=nlens/2
 

    backbone->set_keyword, 'CTYPE1', 'RA---TAN', 'the coordinate type for the first axis'
    backbone->set_keyword, 'CRPIX1', x0+1, 'x-coordinate of ref pixel [note: first pixel is 1]'
    ra= float(backbone->get_keyword( 'RA'))
    backbone->set_keyword, 'CRVAL1', ra+1, 'Right ascension at ref point' 

    backbone->set_keyword, 'CTYPE2', 'DEC--TAN', 'the coordinate type for the second axis'
    backbone->set_keyword, 'CRPIX2', y0, 'y-coordinate of ref pixel [note: first pixel is 1]'
    dec= float(SXPAR( Header, 'DEC',count=c2))
    backbone->set_keyword, 'CRVAL2', double(backbone->get_keyword( 'DEC')), 'Declination at ref point'  ;TODO should see gemini type convention

	
	; enforce standard convention preferred by Gemini of using the CD instead of
	; PC + CDELT matrices
	backbone->del_keyword, 'PC1_1' 
	backbone->del_keyword, 'PC1_2' 
	backbone->del_keyword, 'PC2_1' 
	backbone->del_keyword, 'PC2_2' 
	backbone->del_keyword, 'CDELT1' 
	backbone->del_keyword, 'CDELT2'

@__end_primitive

end

