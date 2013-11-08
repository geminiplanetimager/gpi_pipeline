;+
; NAME: gpi_rotate_field_of_view_square
; PIPELINE PRIMITIVE DESCRIPTION: Rotate Field of View Square
;
;    Rotate by the lenslet/field relative angle, so that the GPI IFS 
;    field of view is roughly square with the pixel coordinate axes.
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
; PIPELINE COMMENT: Rotate datacubes so that the field of view is squarely aligned with the image axes. 
; PIPELINE ARGUMENT: Name="Method" Type="enum" Range="CUBIC|FFT" Default="CUBIC"
; PIPELINE ARGUMENT: Name="crop" Type="int" Range="[0,1]" Default="0" Desc="Set to 1 to crop out non-illuminated pixels"
; PIPELINE ARGUMENT: Name="Show" Type="int" Range="[0,1]" Default="0"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 3.9
; PIPELINE TYPE: ASTR/POL
; PIPELINE NEWTYPE: SpectralScience,PolarimetricScience
; PIPELINE SEQUENCE: 11-
;
; HISTORY:
;   2012-04-10 MDP: Created, based on rotate_north_up.pro
;   2013-11-07 ds - updated to use gpi_update_wcs_basic
;-
function gpi_rotate_field_of_view_square, DataSet, Modules, Backbone
  primitive_version= '$Id$' ; get version from subversion to store in header history
  @__start_primitive

  cube=*(dataset.currframe[0])
  sz = size(cube)
  nslice = sz[3]                ; works for either POL or SPEC modes


  if tag_exist( Modules[thisModuleIndex], "Method") then Method= strupcase(Modules[thisModuleIndex].method) else method="CUBIC" ;; can be CUBIC or FFT
  if tag_exist( Modules[thisModuleIndex], "crop") then crop= strupcase(Modules[thisModuleIndex].crop) else crop=0 
  message,/info, " using rotation method "+method
  if method ne 'CUBIC' and method ne 'FFT' then return, error("Invalid rotation method: "+method)

  ;; ====== Rotation =======
  ;; The angle by design ought to be atan(1,2), but in practice with the 
  ;; as built instrument there appears to be a slight offset from this.
  ;; Hence the following default:
  rotangle_d = gpi_get_constant('ifs_rotation', default=atan(1,2)*!radeg -2)
  ;; and we need to flip the sign here since we want to rotate back in the
  ;; opposite direction
  rotangle_d *= -1

  padsize=281
  cube0 =cube
  ;; TODO more careful handling of center location here.
  
  xcen = (padsize-1)/2+1 & ycen = (padsize-1)/2+1

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
  ;;zeromask = (cube[*,*,0] eq 0) or (cube[*,*,1] eq 0)
  badmask = ~(finite(total(cube,3))) ; any loc not good in ALL slices
  kernel = replicate(1,7,7)
  badmask2 = dilate(badmask, kernel)
  edgemask = badmask2-badmask
  sz = size(cube)
  cube_r = cube
  ;; find where the bad region rotates to
  case method of
     'CUBIC': rotmask = rot(float(badmask), -rotangle_d,cubic=-0.5,/interp) gt 0.5
     'FFT': begin
        rotmask = fftrot(badmask, rotangle_d) gt 0.5
                                ; mask out the corner regions outside the FOV too 
        rotmask[search2d(rotmask,0,0,0,0)]=1
        rotmask[search2d(rotmask,0,padsize-1,0,0)]=1
        rotmask[search2d(rotmask,padsize-1,0,0,0)]=1
        rotmask[search2d(rotmask,padsize-1,padsize-1,0,0)]=1
     end
  endcase


  for i=0L,nslice-1 do begin
     edgeval = median(cube[where(edgemask)+ sz[1]*sz[2]*i ])
     ;;print, edgeval
     cube[where(badmask)+ sz[1]*sz[2]*i ] = edgeval
     ;; set the background to 0 when fftrotating?
     case method of
        'CUBIC': cube_r[*,*,i] = rot(cube[*,*,i]-edgeval,  -rotangle_d ,cubic=-0.5,/interp)+edgeval
        'FFT': cube_r[*,*,i] = fftrot(cube[*,*,i]-edgeval,  rotangle_d)+edgeval
     endcase
     
     cube_r[where(rotmask)+ sz[1]*sz[2]*i ] = !values.f_nan
  endfor


  if keyword_set(stop) then    begin
     ss =  [[[cube]],[[cube_r]]]
     ss = ss[*,*,[0,2,1,3]]
     atv, ss,/bl

     stop
  endif
  backbone->set_keyword, 'HISTORY', "Rotated by "+sigfig(rotangle_d, 4)+" deg to have FOV square",ext_num=0
  
  cube=cube_r
  if keyword_set(crop) then begin
     cube = cube[48:233, 47:232, *]
     backbone->set_keyword, 'HISTORY', "Cropped to square FOV only"
  endif

  ;;if avparang exists get that, otherwise fall back to PAR_ANG
  ang0 = backbone->get_keyword('AVPARANG',count=ct)
  if ct eq 0 then ang0 = backbone->get_keyword('PAR_ANG',count=ct)
  ;;update WCS info
  gpi_update_wcs_basic,backbone,parang=ang0-rotangle_d,imsize=sz[1:2]

  ;;if there are satspots, rotate them as well
  locs = gpi_satspots_from_header(*DataSet.HeadersExt[numfile])
  if n_elements(locs) gt 1 then  gpi_rotate_header_satspots,backbone,rotangle_d-ang0,locs

  *(dataset.currframe[0])=cube
  suffix += '-fovsquare'
  
@__end_primitive

end

