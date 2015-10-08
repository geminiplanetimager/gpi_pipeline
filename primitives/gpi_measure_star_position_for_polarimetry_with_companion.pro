;+
; NAME: gpi_measure_star_position_for_polarimetry_with_companion
; PIPELINE PRIMITIVE DESCRIPTION: Measure Star Position with Bright Companion for Polarimetry
;
; PIPELINE COMMENT:  Measure Star Position With a Bright Companion in Pol Mode
; PIPELINE CATEGORY: Calibration, PolarimetricScience
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="5" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="STARXCEN" Type="int" Range="[0,300]" Default="145" Desc="Initial X position in Radon Transform"
; PIPELINE ARGUMENT: Name="STARYCEN" Type="int" Range="[0,300]" Default="148" Desc="Initial Y position in Radon Transform"
; PIPELINE ARGUMENT: Name="StarXPos" Type="int" Range="[0,500]" Default="98" Desc="Companion X pos for CNTRD"
; PIPELINE ARGUMENT: Name="StarYPos" Type="int" Range="[0,500]" Default="121" Desc="Companion Y pos for CNTRD"
; PIPELINE ARGUMENT: Name="MaskRad" Type="int" Range="[1,25]" Default="15" Desc="Mask Radius"
function gpi_measure_star_position_for_polarimetry_with_companion, DataSet, Modules, Backbone
  ; enforce modern IDL compiler options:
  compile_opt defint32, strictarr, logical_predicate

  @__start_primitive
  imgcub = *(dataset.currframe[0])
  $clear
  mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
  mode = strlowcase(mode)
  ;/////////////////////////
  ;Primitive parameters
  xposstar=fix(Modules[thisModuleIndex].STARXCEN)
  yposstar=fix(Modules[thisModuleIndex].STARYCEN)
  incomposx=fix(Modules[thisModuleIndex].StarXpos)
  incomposy=fix(Modules[thisModuleIndex].StarYpos)
  maskradius=fix(Modules[thisModuleIndex].MaskRad)
    ;///////////////////////////
  IF strmatch(mode,"*wollaston*",/fold) THEN BEGIN
    dim1 = backbone->get_keyword("NAXIS1")
    dim2 = backbone->get_keyword("NAXIS2")
    dime=[dim1, dim2]
    img0=imgcub[*,*,0] ; first slice
    img1=imgcub[*,*,1] ; second slice
    
  print, ' '
  print, 'Computing PSFCENTX and PSFCENTY'
  print, 'Using the Radon Transform masking out the Companion'
  ;masking out companion
  imgmask=img0
  
  cntrd, imgmask, incomposx,incomposy, compx, compy,4   ;companion's centroid assuming fwhm=4pix
  IF (compx EQ -1) THEN BEGIN
    print, ' '
    return, error('FAILURE (CNTRD): ERROR in CNTRD: Check Companion initial position.')
    print, ' '
  ENDIF
  dist_circle, circ0, 281, compx, compy
  com=where(circ0 lt maskradius, countcom)
  imgmask[com]=!values.f_nan
  print, ' '
  print, 'Mask Created'
  print, 'Compaion masked-out'
  cent = find_pol_center(imgmask, xposstar, yposstar, 7.0, 7.0, maskrad=50, highpass=1, pixlowerbound=-100.0, statuswindow=statuswindow)
  IF (cent[0] EQ -1) THEN BEGIN
    return, error('FAILURE (Find_pol_center): ERROR in Find_pol_center: Check Star initial position.')
  ENDIF
  print, ' '
  print, 'PSFCENTX ', cent[0]
  print, 'PSFCENTY ', cent[1]
  print, 'Saving PSFCENTX and PSFCENTY in header'
  backbone->set_keyword,"PSFCENTX", cent[0], 'X-Location of PSF center', ext_num=1
  backbone->set_keyword,"PSFCENTY", cent[1], 'Y-Location of PSF center', ext_num=1 
  print, 'Done'
  print, ' '
  ENDIF ELSE BEGIN
    print, ' '
    return, error('FAILURE: Not a pol cube, run this primitive on pol cubes.')
    print, ' '

  ENDELSE 
  @__end_primitive
end