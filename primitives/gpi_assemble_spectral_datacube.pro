;+
; NAME: gpi_assemble_spectral_datacube
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Spectral Datacube
;
;		This routine transforms a 2D detector image in the dataset.currframe input
;		structure into a 3D data cube in the dataset.currframe output structure.
;   This routine extracts data cube from an image using spatial summation along the dispersion axis
;     introduced suffix '-rawspdc' (raw spectral data-cube)
;
; KEYWORDS: 
; GEM/GPI KEYWORDS:IFSFILT
;
; PIPELINE COMMENT: Assemble a 3D datacube from a 2D image. Spatial integration (3 pixels box) along the dispersion axis
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE CATEGORY: SpectralScience, Calibration
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
;   2013-04-02 JBR: Correction on the y coordinate when reading the det array to match centered pixel convention. Removal of the reference pixel area.
;   2013-07-17 MDP: Rename for consistency
;   2013-08-06 MDP: Documentation update, code cleanup to relabel X and Y properly
;   2013-11-30 MDP: Clear DQ and Uncert pointers
;   2015-02-17 KBF: Added DQ propagation
;-
function gpi_assemble_spectral_datacube, DataSet, Modules, Backbone
  primitive_version= '$Id$' ; get version from subversion to store in header history
  @__start_primitive

  ;;get the 2D detector image
  det=*(dataset.currframe[0])

  nlens=(size(wavcal))[1]       ;pixel sidelength of final datacube (spatial dimensions) 
  dim=(size(det))[1]            ;detector sidelength in pixels

  ;;error handle if readwavcal or not used before
  if (nlens eq 0) || (dim eq 0)  then $
     return, error('FAILURE ('+functionName+'): Failed to load wavelength calibration data prior to calling this primitive.') 
  
  ;;define the common wavelength vector with the IFSFILT keyword:
  filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  
  ;;error handle if IFSFILT keyword not found
  if (filter eq '') then $
     return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 

  ;;get length of spectrum
  sdpx = calc_sdpx(wavcal, filter, Ymini, CommonWavVect)
  
                                ; sdpx = length in pixels of longest spectra
                                ; Ymini = array with Y coordinates for min wavelength for each lenslet. 
                                ;		  (note, this is actually the *MAX* Y value since wavelength
                                ;		  increases downward, but it's for the MIN wavelength.)

  if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')
  
  ;;get tilts of the spectra included in the wavelength solution:
  tilt=wavcal[*,*,4]

  cubef3D=dblarr(nlens,nlens,sdpx) ;create the datacube
  cubedq3D=bytarr(nlens,nlens,sdpx) 

  if keyword_set(debug) then mask = det*0 ; create a mask of which pixels were used in the extraction.

  for i=0,sdpx-1 do begin       ; iterate over length of longest spectrum in pixels     
     ;;through spaxels
     cubef=dblarr(nlens,nlens) 
     cubedq=bytarr(nlens,nlens) 
     
     ;;get the locations on the image where intensities will be extracted:
     ;; y3 is a float and the reference is to the center of the pixel. 
     ;; It means for instance that -0.5<y<0.5 refers to pixel number 0 and 1.5<y<2.5 refers to pixel number 2.
     ;; So the round function is needed to be sure we reference the right pixel, 
     ;; versus IDL's default behavior of just truncating.
     Y3=Ymini-i
     X3=round(wavcal[*,*,1]+(wavcal[*,*,0]-Y3)*tan(tilt[*,*]))    
     
     ;;extract intensities on a 3x1 box:
     cubef=det[X3,Y3]+det[X3+1,Y3]+det[X3-1,Y3]
     cubedq=(*dataset.currdq)[X3,Y3] OR (*dataset.currdq)[X3+1,Y3] OR (*dataset.currdq)[X3-1,Y3]
     
	 if keyword_set(debug) then begin
		 mask[X3-1, Y3] = 1 
		 mask[X3, Y3] = 1 
		 mask[X3+1, Y3] = 1 
   endif
     
     ;;declare as NaN mlens not on the detector (or on the reference pixel area, i.e. 4 pixels on each side):
     bordy=where(~finite(y3) OR (Round(y3) LT 4.0) OR (Round(y3) GT 2043.0),cc)
     if (cc ne 0) then begin
      cubef[bordy]=!VALUES.F_NAN
      cubedq[bordy]=!VALUES.F_NAN 
     endif
     ;; we expand the border region by 2 pixels in X, so that we flag as NaN
     ;; any 3x1 pixel box that has at least one pixel off the edge...
     bordx=where(~finite(x3) OR (x3 LT 6.0) OR (x3 GT 2041.0),cc)
     if (cc ne 0) then begin
      cubef[bordx]=!VALUES.F_NAN
      cubedq[bordx]=!VALUES.F_NAN
     endif    
     cubef3D[*,*,i]=cubef
     cubedq3d[*,*,i]=cubedq
  endfor

  ;; Update FITS header with RA and Dec WCS information
  ;; the spectral axis WCS will be added in interpol_spec_oncommwavvect
  gpi_update_wcs_basic,backbone,imsize=[nlens,nlens]

	suffix='-rawspdc'
	;; put the datacube in the dataset.currframe output structure:
	*dataset.currframe=cubef3D
  *dataset.currdq=cubedq3D	
	ptr_free, dataset.currUncert  ; right now we're not creating an uncert cube


  @__end_primitive

end

