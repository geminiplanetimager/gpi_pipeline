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
; GEM/GPI KEYWORDS:FILTER1
; OUTPUTS:
;
; PIPELINE COMMENT: Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-rawspdc" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE TYPE: ALL-SPEC
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
;+
function extractcube, DataSet, Modules, Backbone
  common PIP
  COMMON APP_CONSTANTS
  primitive_version= '$Id$' ; get version from subversion to store in header history

  ; getmyname, functionname
  @__start_primitive


  ;get the 2D detector image
  det=*(dataset.currframe[0])

  nlens=(size(wavcal))[1]       ;pixel sidelength of final datacube (spatial dimensions) 
  dim=(size(det))[1]            ;detector sidelength in pixels

  ;error handle if readwavcal or not used before
  if (nlens eq 0) || (dim eq 0)  then $
     return, error('FAILURE ('+functionName+'): Failed to load data.') 
            
  ;define the common wavelength vector with the FILTER1 keyword:
  filter = gpi_simplify_keyword_value(backbone->get_keyword('FILTER1', count=ct))
  
  ;error handle if FILTER1 keyword not found
  if (filter eq '') then $
     return, error('FAILURE ('+functionName+'): FILTER1 keyword not found.') 

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
     cubef=det[y3,x3]+det[y3+1,x3]+det[y3-1,x3]
     
     ;declare as Nan mlens not on the detector:
     bordx=where(~finite(x3),cc)
     if (cc ne 0) then cubef[bordx]=!VALUES.F_NAN
     bordy=where(~finite(y3),cc)
     if (cc ne 0) then cubef[bordy]=!VALUES.F_NAN
     
     cubef3D[*,*,i]=cubef
  endfor

  suffix='-spdc'
  ; put the datacube in the dataset.currframe output structure:
  *(dataset.currframe[0])=cubef3D


@__end_primitive

end

