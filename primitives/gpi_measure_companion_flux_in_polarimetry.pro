;+
; NAME: gpi_measure_companion_flux_in_polarimetry
; PIPELINE PRIMITIVE DESCRIPTION: Measure Companion Flux in Polarimetry
;
; PIPELINE COMMENT:  Measure Companion Flux for Polarimetry with APER
; PIPELINE CATEGORY: PolarimetricScience
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: Save Flux Value in Header, 0: don't save"
; PIPELINE ARGUMENT: Name="ShowAperture" Type="int" Range="[0,1]" Default="0" Desc="Show Apertures Used in GPItv"
; PIPELINE ARGUMENT: Name="StarXPos" Type="int" Range="[0,500]" Default="98" Desc="Companion X pos for CNTRD"
; PIPELINE ARGUMENT: Name="StarYPos" Type="int" Range="[0,500]" Default="121" Desc="Companion Y pos for CNTRD"
; PIPELINE ARGUMENT: Name="StarAperture" Type="int" Range="[3,18]" Default="10" Desc="Optimum Aperture value used in APER"
; PIPELINE ARGUMENT: Name="StarInnerSkyRad" Type="int" Range="[5,20]" Default="15" Desc="Inner Skyrad  value used in APER"
; PIPELINE ARGUMENT: Name="StarOuterSkyRad" Type="int" Range="[10,30]" Default="20" Desc="Outer Skyrad  value used in APER"

function gpi_measure_companion_flux_for_polarimetry, DataSet, Modules, Backbone
  ; enforce modern IDL compiler options:
  compile_opt defint32, strictarr, logical_predicate

  @__start_primitive
  imgcub = *(dataset.currframe[0])
  $clear
  ;getting some header keywords
  targetname=backbone->get_keyword("OBJECT")
  itime=backbone->get_keyword("ITIME")
  ncoadd=backbone->get_keyword("COADDS0")
  readnum=backbone->get_keyword('READS')
  sysgain=backbone->get_keyword('SYSGAIN')
  uttime=backbone->get_keyword("UT", count=cc)
  IF (cc EQ 0) THEN BEGIN
    print, 'Missing Keyword: UT'
    print, 'Setting UT to zero'
    uttimeobs=0
  ENDIF ELSE BEGIN
    UT=MAKE_ARRAY(3,1,/STRING, VALUE=0)
    UT = strsplit(uttime, ':',/EXTRAC)
    utimes=DOUBLE(UT)
    uttimeobs=utimes[0]+utimes[1]/60.0 + utimes[2]/3600.0
  ENDELSE
  print, ' '
  print, 'TARGET: ', targetname
  print, 'ITIME: ', itime
  print, 'OBSTIME: ', uttimeobs
  print, 'COADDS: ', ncoadd 
  print, 'NREADS: ', readnum
  print, 'SYSGAIN: ', sysgain
  mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
  mode = strlowcase(mode)
  
  ;/////////////////////////////////////////////////////////////
  ;Reading primitive parameters
  showaperture=fix(Modules[thisModuleIndex].ShowAperture)
  ;Companion values for CNTRD
  incomposx=fix(Modules[thisModuleIndex].StarXpos)
  incomposy=fix(Modules[thisModuleIndex].StarYpos)
  ;Aperture photometry values for APER
  comaper=fix(Modules[thisModuleIndex].StarAperture)
  inncomskrad=fix(Modules[thisModuleIndex].StarInnerSkyRad)
  outcomskrad=fix(Modules[thisModuleIndex].StarOuterSkyRad)
  ;Save
  save=fix(Modules[thisModuleIndex].save)
  ;////////////////////////////////////////////////////////////

  IF strmatch(mode,"*wollaston*",/fold) THEN BEGIN
    dim1 = backbone->get_keyword("NAXIS1")
    dim2 = backbone->get_keyword("NAXIS2")
    dime=[dim1, dim2]
    img0=imgcub[*,*,0] ; first slice
    img1=imgcub[*,*,1] ; second slice
    imgspare0=img0  
    imgspare1=img1
    
  cntrd, img0, incomposx,incomposy, compx, compy,4 ;centroid of companion assuming fwhm 4pix
  IF (compx EQ -1) THEN BEGIN
  print, ' '
  return, error('FAILURE (CNTRD): ERROR in CNTRD: Check Companion initial position.')
  print, ' '
  ENDIF
  aper, img0, compx, compy, compflux0, compdeltaflux0, skyval0, deltasky0, 1, comaper, [inncomskrad,outcomskrad], /NAN, /EXACT, /FLUX
  aper, img1, compx, compy, compflux1, compdeltaflux1, skyval1, deltasky1, 1, comaper, [inncomskrad,outcomskrad], /NAN, /EXACT, /FLUX
  
  compflux0=compflux0[0];
  compdeltaflux0=compdeltaflux0[0];
  compflux1=compflux1[0];
  compdeltaflux1=compdeltaflux1[0];
  
  IF (showaperture) THEN BEGIN
    dist_circle, circ0, 281, compx, compy
    com=where(circ0 le comaper, countcom)
    skycom=where((circ0 ge inncomskrad) and (circ0 le outcomskrad), skycountcom)
    imgspare0[com]=1e5
    imgspare0[skycom]=!values.f_nan
    imgspare1[com]=1e5
    imgspare1[skycom]=!values.f_nan

    atv, imgspare0,/block ;SLICE 0
    atv, imgspare1,/block ;SLICE 1
  ENDIF
  print, ' '
  print, 'Slice 0'
  print, ' COMPANION FLUX (ADU coadd^-1):  ', compflux0
  print, ' DELTA FLUX (ADU coadd^-1): ', compdeltaflux0
  print, ' '
  print, 'Slice 1'
  print, ' COMPANION FLUX (ADU  coadd^-1):  ', compflux1
  print, ' DELTA FLUX (ADU coadd^-1): ', compdeltaflux1
  print, ' '
  
  IF (save) THEN BEGIN
    print, 'Storing fluxes in Header'
    backbone->set_keyword,  'COMPF_0',   compflux0, "Companion flux (ADU coadd^-1) slice 1", ext_num=1
    backbone->set_keyword, 'COMPF_0E',  compdeltaflux0, "Uncertainty Comp. flux (ADU coadd^-1) slice 1 ", ext_num=1 
    backbone->set_keyword,  'COMPF_1',   compflux1, "Companion flux (ADU coadd^-1) slice 2", ext_num=1
    backbone->set_keyword, 'COMPF_1E',  compdeltaflux1, "Uncertainty Comp. flux (ADU coadd^-1) slice 2", ext_num=1
  ENDIF
  
  ;Just for reference
  ;compfluxout = dindgen(6,2) ;Each row includes: compflux, compdeltaflux, compx, compy, skyval, deltasky
  ;compfluxout[0,0]=compflux0
  ;compfluxout[1,0]=compdeltaflux0
  ;compfluxout[2,0]=compx
  ;compfluxout[3,0]=compy
  ;compfluxout[4,0]=skyval0
  ;compfluxout[5,0]=deltasky0
  ;
  ;compfluxout[0,1]=compflux1
  ;compfluxout[1,1]=compdeltaflux1
  ;compfluxout[2,1]=compx
  ;compfluxout[3,1]=compy
  ;compfluxout[4,1]=skyval1
  ;compfluxout[5,1]=deltasky1
  
ENDIF ELSE BEGIN
    print, ' '
    return, error('FAILURE: Not a pol cube, run this primitive on pol cubes.')
    print, ' '

  ENDELSE
  @__end_primitive
end