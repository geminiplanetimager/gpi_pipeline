;+
; NAME: subtract_mean_stellar_polarization.pro
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Mean Stellar Polarization from podc
;
;   Subtract an estimate of the stellar polarization, measured from
;   the mean polarization inside the occulting spot radius.
;
;   This primitive is simple, but has not been extensively tested.
;   Under what circumstances, if any, it is useful on GPI data in practice
;   is still TBD.
;
;
; INPUTS: Coronagraphic mode Stokes Datacube
;
; OUTPUTS: That datacube with an estimated stellar polarization subtracted off.
;
; PIPELINE COMMENT: This description of the processing or calculation will show ; up in the Recipe Editor GUI. This is an example template for creating new ; primitives. It multiples any input cube by a constant value.
; PIPELINE ARGUMENT: Name="WriteToFile" Type="int" Range="[0,1]" Default="1" Desc="1: Write the difference to a file, 0: Dont"
; PIPELINE ARGUMENT: Name="Filename" Type="string" Default="Stellar_Polarization.txt" Desc="The filename where you write out the stellar polarization"
; PIPELINE ARGUMENT: Name="InnerRadius" Type="float" Range="[-1,140]" Default="-1" Desc="The inner radius where you start to measure the instrumental polarization. -1 = the size of the FPM"
; PIPELINE ARGUMENT: Name="OuterRadius" Type="float" Range="[0,140]" Default="20" Desc="The radius out to which you measure the instrumental polarization. 0 = inside the occulter"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
;
; PIPELINE ORDER: 5.0
;
; PIPELINE CATEGORY: PolarimetricScience
;
; HISTORY:
;    2014-03-23 MP: Started
;    2014-05-14 MMB: Rewrote for
;-

function gpi_subtract_mean_stellar_polarization_podc, DataSet, Modules, Backbone
  compile_opt defint32, strictarr, logical_predicate

  primitive_version= '$Id: gpi_subtract_mean_stellar_polarization.pro 2878 2014-04-29 04:11:51Z mperrin $' ; get version from subversion to store in header history


    @__start_primitive
  if fix(Modules[thisModuleIndex].save) eq 1 then suffix='podc_sub'      ; set this to the desired output filename suffix

  centerx = backbone->get_keyword('PSFCENTX', count=ct1, indexFrame=indexFrame)
  centery = backbone->get_keyword('PSFCENTY', count=ct2, indexFrame=indexFrame)
  center = [centerx, centery] ; hard coded for HD 141569 output files for now.

  if ct1+ct2 ne 2 then $
    return, error('FAILURE ('+functionName+'): Star Position Not Found in file'+string(*(dataset.filenames[0])))

  pa = backbone->get_keyword('PAR_ANG', indexFrame=indexFrame)
  sz = size(*dataset.currframe)

  indices, (*dataset.currframe)[*,*,0], center=center,r=r

  ifsfilt = backbone->get_keyword('IFSFILT',/simplify)
  ; size of occulting masks in milliarcsec
  case ifsfilt of
    'Y': fpm_diam = 156
    'J': fpm_diam = 184
    'H': fpm_diam = 246
    'K1': fpm_diam = 306
    'K2': fpm_diam = 306
  endcase
  fpm_diam *= 1./1000 /gpi_get_constant('ifs_lenslet_scale')
  
  fpm_rad=fpm_diam/2

  inner=float(Modules[thisModuleIndex].InnerRadius)
  outer=float(Modules[thisModuleIndex].OuterRadius)

  ;Check for special situations
  if inner eq -1 then begin
    if outer le fpm_rad then begin
      print, "Your inner and outer radii are incompatible. Measuring the instrumental polarization within the whole fpm."
      inner = 0
      outer = fpm_rad
    endif else inner = fpm_rad
  endif

  ;
  if outer eq 0 then outer = fpm_rad

  if outer lt inner then begin
    print, "Your inner and outer radii are incompatible. Measuring the instrumental polarization within the whole fpm."
    inner=0
    outer=fpm_rad
  endif

  wfpm = where(r lt outer and r gt inner, ct)

  print, string(ct)+" pixels used to measure stellar polarization"

  polstack =     fltarr(sz[1], sz[2], sz[3])
  sumstack = fltarr(sz[1], sz[2]) ; a transformed version of polstack, holding the sum and single-difference images
  diffstack = fltarr(sz[1],sz[2])
  polstack[*,*,*] = (*dataset.currframe)[*,*,*]

  sumstack[0,0] = polstack[*,*,0] + polstack[*,*,1]
  diffstack[0,0] = polstack[*,*,0] - polstack[*,*,1]

  ;The the mean normalized difference inside the FPM
  meanclip, diffstack[wfpm]/sumstack[wfpm], mn, stddev
  mean_stellar_diff=mn

  ;Subtract it off the difference stack

  diffstack -= sumstack*mean_stellar_diff

  modified_podc = *dataset.currframe

  modified_podc[*,*,0] = (sumstack+diffstack)/2
  modified_podc[*,*,1] = (sumstack-diffstack)/2

  if uint(Modules[thisModuleIndex].WriteToFile) eq 1 then begin
    wpangle = backbone->get_keyword('WPANGLE', count=ct1, indexFrame=indexFrame)
    openw, lun, Modules[thisModuleIndex].Filename, /get_lun, /append, width=200
;    printf, lun, "#Inner Radius: "+strcompress(inner)
;    printf, lun, "#Outer Radius: "+strcompress(outer)
;    printf, lun, "#Filename  p_frac  wpangle PA"
    printf, lun, string(dataset.filenames[numfile]), mean_stellar_diff, wpangle,pa, inner, outer
    close, lun
    free_lun, lun
  endif


  backbone->set_keyword,'HISTORY',functionname+ " Subtracting estimated mean apparent stellar polarization"
  backbone->set_keyword,'HISTORY',functionname+ " from pixels that are between "+strcompress(inner)+" and "+strcompress(outer)+"pixels from the center"
  backbone->set_keyword,'HISTORY', functionname+" The measured normalized difference:", mean_stellar_diff
  ;backbone->set_keyword,'STELLARQ', mean_q, "Estimated apparent stellar Q/I from behind FPM"
  ;backbone->set_keyword,'STELLARU', mean_u, "Estimated apparent stellar U/I from behind FPM"
  ;backbone->set_keyword,'STELLARV', mean_v, "Estimated apparent stellar V/I from behind FPM"

  *dataset.currframe = modified_podc

  @__end_primitive

end
