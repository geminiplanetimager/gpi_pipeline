;+
; NAME: gpi_measure_satellite_spot_flux_pol
; PIPELINE PRIMITIVE DESCRIPTION: Measure Satellite Spot Flux in Polarimetry
;
; PIPELINE COMMENT:  Measure Flux in Polarimetry
; PIPELINE CATEGORY: Calibration, PolarimetricScience
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: Save Flux Value in Header, 0: don't save"
; PIPELINE ARGUMENT: Name="Aperture" Type="int" Range="[1,5]" Default="4" Desc="Aperture value used in Racetrack, Default: 4pix"
; PIPELINE ARGUMENT: Name="Inskyrad" Type="int" Range="[4,8]" Default="6" Desc="Inner Sky Aperture Radius in Racetrack"
; PIPELINE ARGUMENT: Name="Outskyrad" Type="int" Range="[6,14]" Default="9" Desc="Outer Sky Aperture Radius in Racetrack"
; PIPELINE ARGUMENT: Name="ShowAperture" Type="int" Range="[0,1]" Default="0" Desc="Show the Satellite Spot Apertures"
; PIPELINE ARGUMENT: Name="FindPSFCENT" Type="int" Range="[0,1]" Default="0" Desc="1: Radon, 0: Do Nothing"
; PIPELINE ARGUMENT: Name="STARXCEN" Type="int" Range="[0,300]" Default="145" Desc="Initial X position in CNTRD or RADON"
; PIPELINE ARGUMENT: Name="STARYCEN" Type="int" Range="[0,300]" Default="148" Desc="Initial Y position in CNTRD or RADON"
; PIPELINE ARGUMENT: Name="Companion" Type="int" Range="[0,1]" Default="0" Desc="Is there a companion? 0: No 1: Yes"
; PIPELINE ARGUMENT: Name="StarXPos" Type="int" Range="[0,500]" Default="98" Desc="Companion X pos for CNTRD"
; PIPELINE ARGUMENT: Name="StarYPos" Type="int" Range="[0,500]" Default="121" Desc="Companion Y pos for CNTRD"
; PIPELINE ARGUMENT: Name="StarAperture" Type="int" Range="[3,10]" Default="8" Desc="Optimum Aperture value used in APER"
; PIPELINE ARGUMENT: Name="StarInnerSkyRad" Type="int" Range="[5,15]" Default="12" Desc="Inner Skyrad  value used in APER"
; PIPELINE ARGUMENT: Name="StarOuterSkyRad" Type="int" Range="[10,20]" Default="16" Desc="Outer Skyrad  value used in APER"
;
; PIPELINE ORDER: 2.446
;
; HISTORY:
;
function gpi_measure_satellite_spot_flux_pol, DataSet, Modules, Backbone
  ; enforce modern IDL compiler options:
  compile_opt defint32, strictarr, logical_predicate

  @__start_primitive
  imgcub = *(dataset.currframe[0])
  $clear
  print, '  '
  print,'*******************************'
  print,'*                             *'
  print,'*                             *'
  print,'* Measure Flux in Polarimetry *'
  print,'*                             *'
  print,'*                             *'
  print,'*******************************'
  print, ' '


  targetname=backbone->get_keyword("OBJECT")
  itime=backbone->get_keyword("ITIME")
  ncoadd=backbone->get_keyword("COADDS0")
  readnum=backbone->get_keyword('READS')
  ;UT time of expose
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
  print, 'TARGET: ',targetname
  print, 'ITIME: ',  itime
  print, 'OBSTIME: ', uttimeobs
  print, 'COADDS: ', ncoadd
  print, 'NREADS: ', readnum
  print, ' '
  ;Creating folder
  ; isfolder=FILE_TEST('~/RACETRACK-DATA/'+targetname, /DIRECTORY)
  ; IF (isfolder EQ 0 ) THEN BEGIN
  ;   FILE_MKDIR, '~/RACETRACK-DATA/'+targetname
  ;   print, ' '
  ;   print, ' SAVING DATA AT: ',  '~/RACETRACK-DATA/'+targetname
  ; ENDIF ELSE BEGIN
  ;   print, ' SAVING DATA AT: ',  '~/RACETRACK-DATA/'+targetname
  ; ENDELSE


  mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
  mode = strlowcase(mode)

  showaperture=fix(Modules[thisModuleIndex].ShowAperture)

  ;Initial values for CNTRD (Occulted Star)
  xposstar=fix(Modules[thisModuleIndex].STARXCEN)
  yposstar=fix(Modules[thisModuleIndex].STARYCEN)
  ;Companion values for CNTRD
  companion=fix(Modules[thisModuleIndex].companion)
  incomposx=fix(Modules[thisModuleIndex].StarXpos)
  incomposy=fix(Modules[thisModuleIndex].StarYpos)
  ;Use centroid instead of Radon transform
  findPSFCENT=fix(Modules[thisModuleIndex].findpsfcent)
  ; READING IMAGE IN POL OR SPEC MODE

  ;samesatpos=fix(Modules[thisModuleIndex].quicksatpos)

  IF strmatch(mode,"*wollaston*",/fold) THEN BEGIN
    print, '  '
    print, '  Loading Polarimetric Cube'
    print, '  '
    print, 'Reading NAXIS'
    dim1 = backbone->get_keyword("NAXIS1")
    dim2 = backbone->get_keyword("NAXIS2")
    dime=[dim1, dim2]
    print, "IMAGE DIMENSION: ", dime[0], dime[1]
    print, ''

    img0=imgcub[*,*,0] ; first slice
    img1=imgcub[*,*,1] ; second slice

    imgmask0=findgen(dime[0], dime[1]);
    imgmask1=findgen(dime[0], dime[1]);
    ; Run this if you have a very bright companion in your field and you want it masked out before running Jason's Radon

    IF ((findpsfcent EQ 1) AND (companion EQ 1)) THEN BEGIN
      print, ' '
      print, 'Computing PSFCENTX and PSFCENTY'
      print, 'Using RADON Transform'
      ;masking out companion
      imgmask=img0;
      ; imgmask=readfits("~/RACETRACK-DATA/"+targetname+"/"+targetname+"-IMG-0-RADON.fits",/silent,EXTEN_NO=0)
      cntrd, imgmask, incomposx,incomposy, compx, compy,3   ;companion's centroid assuming fwhm=3pix
      IF (compx EQ -1) THEN BEGIN
        print, ' '
        return, error('FAILURE (CNTRD): ERROR in CNTRD: Check Companion initial position.')
        print, ' '
      ENDIF
      dist_circle, circ0, 281, compx, compy
      com=where(circ0 lt 14, countcom)
      mv=where( (circ0 GE 14) AND (circ0 LE 18), countmean)
      imgmask[com]=!values.d_nan
      ;writefits, '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-RADON.fits', imgmask
      print, ' '
      print, 'MASK Created'
      print, 'Compaion masked-out'
      ;imgmask=readfits('~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-RADON.fits',/silent,EXTEN_NO=0)
      statuswindow = backbone->getstatusconsole()
      cent = find_pol_center(imgmask, xposstar, yposstar, 3.0, 3.0, maskrad=30, highpass=1, pixlowerbound=-100.0, statuswindow=statuswindow)
      IF (cent[0] EQ -1) THEN BEGIN
        return, error('FAILURE (Find_pol_center): ERROR in Find_pol_center: Check Star initial position.')
      ENDIF
      backbone->set_keyword,"PSFCENTX", cent[0], 'X-Location of PSF center', ext_num=1
      backbone->set_keyword,"PSFCENTY", cent[1], 'Y-Location of PSF center', ext_num=1
      starx = cent[0]
      stary = cent[1]
      print, ' '
      print, 'PSFCENTX ', starx
      print, 'PSFCENTY ', stary
      print, ' '
    ENDIF ELSE BEGIN
      print, 'Reading star position from header          '
      starx = backbone->get_keyword( "PSFCENTX" )
      stary = backbone->get_keyword( "PSFCENTY" )
      IF (starx EQ 0.0)  THEN BEGIN
        return, error('FAILURE: Missing Keyword: PSFCENTX. Run Measure Star Position in Polarimetry first')
      ENDIF
      print, 'PSFCENTX', starx
      print, 'PSFCENTY', stary
    ENDELSE


    ;//////// Calculating Sat Spot Positions in POL MODE
    ; sat spots at 20*lambda/D
    filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
    ;if cc eq 0 then filter=SXPAR( hdr, 'IFSFILT',cc)
    ;get the common wavelength vector
    ;error handle if extractcube not used before
    if (strlen(filter) eq 0)  then $
      return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before.')
    cwv=get_cwv(filter)
    CommonWavVect=cwv.CommonWavVect
    lambda=cwv.lambda
    lambdamin=CommonWavVect[0]*1e-6 ; in meters
    lambdamax=CommonWavVect[1]*1e-6 ;in meters
    landa=lambdamin + (lambdamax-lambdamin)/2.0; center wavelength band
    D=43.2*0.18;
    R_spot=findgen(3)
    R_spot[0]=(206265/0.01414)*20*lambdamin/D; in pixels, platescale 0.01414 arcsec/pxs
    R_spot[1]=(206265/0.01414)*20*landa/D; in pixels, platescale 0.01414 arcsec/pxs
    R_spot[2]=(206265/0.01414)*20*lambdamax/D; in pixels, platescale 0.01414 arcsec/pxs
    halflength= R_spot[2]-R_spot[1]
    print, 'Lambda min [mu m]: ' , lambdamin*1e6;
    print, 'Lambda max [mu m]: ' , lambdamax*1e6;
    print, 'Streak Length (pixels): ', halflength
    print, 'R_spot[0]: ', R_spot[0]
    print, 'R_spot[2]: ', R_spot[2]
    print, ''
    ;Angles
    ;Rotation Angle values:  ; 155.6119, 65.7933, -24.08, -113.8689
    ROT_ANG=(!PI/180.0)*[ 155.6119 , -113.8689, 65.7933,-24.08];
    s0posx=starx+[R_spot[0]*cos(ROT_ANG[0]),      R_spot[2]*cos(ROT_ANG[0])];
    s0posy=stary+[R_spot[0]*sin(ROT_ANG[0]),      R_spot[2]*sin(ROT_ANG[0])];
    s1posx=starx+[R_spot[0]*cos(ROT_ANG[1]),      R_spot[2]*cos(ROT_ANG[1])];
    s1posy=stary+[R_spot[0]*sin(ROT_ANG[1]),      R_spot[2]*sin(ROT_ANG[1])];
    s2posx=starx+[R_spot[0]*cos(ROT_ANG[2]),      R_spot[2]*cos(ROT_ANG[2])];
    s2posy=stary+[R_spot[0]*sin(ROT_ANG[2]),      R_spot[2]*sin(ROT_ANG[2])];
    s3posx=starx+[R_spot[0]*cos(ROT_ANG[3]),      R_spot[2]*cos(ROT_ANG[3])];
    s3posy=stary+[R_spot[0]*sin(ROT_ANG[3]),      R_spot[2]*sin(ROT_ANG[3])];
    ;////////


    ;
    ; Defining Satellite Spots Positions at half band
    xs0=halflength*((s0posx[1]-s0posx[0])/(2*halflength))+s0posx[0]
    ys0=s0posy[0]+halflength*((s0posy[1]-s0posy[0])/(2*halflength))
    xs1=halflength*((s1posx[1]-s1posx[0])/(2*halflength))+s1posx[0]
    ys1=s1posy[0]+halflength*((s1posy[1]-s1posy[0])/(2*halflength))
    xs2=halflength*((s2posx[1]-s2posx[0])/(2*halflength))+s2posx[0]
    ys2=s2posy[0]+halflength*((s2posy[1]-s2posy[0])/(2*halflength))
    xs3=halflength*((s3posx[1]-s3posx[0])/(2*halflength))+s3posx[0]
    ys3=s3posy[0]+halflength*((s3posy[1]-s3posy[0])/(2*halflength))

    spot_xsep=[xs0-starx, xs1-starx, xs2-starx, xs3-starx]
    spot_ysep=[ys0-stary, ys1-stary, ys2-stary, ys3-stary]
    spec=0; % SAVE DATA IN FILE IN POL  MODE

    print, '  '
    ;NOW DEALING WITH SPECTRAL CUBES
  ENDIF ELSE BEGIN  ;Now reading in spec mode
    print, ' '
    return, error('FAILURE: Not a polarimetric cube, run this primitive on polarimetric cubes.')
    print, ' '

  ENDELSE  ;END OF READING IMAGE IN POL OR SPEC MODE


  ;Save
  ;  saveinheader=fix(Modules[thisModuleIndex].Save)

  ;Aperture photometry values for APER
  comaper=fix(Modules[thisModuleIndex].StarAperture)
  inncomskrad=fix(Modules[thisModuleIndex].StarInnerSkyRad)
  outcomskrad=fix(Modules[thisModuleIndex].StarOuterSkyRad)
  ;Aperture photometry values in racetrack
  aperrad=fix(Modules[thisModuleIndex].aperture)
  inskyradius=fix(Modules[thisModuleIndex].inskyrad)
  outskyradius=fix(Modules[thisModuleIndex].outskyrad)  ;
  aperradii=indgen(3)
  aperradii=[aperrad, inskyradius, outskyradius ];
  ;Mean and/or Median filtering Options////////////
  ;Check if median filtering is needed and specify box width

  ;skyfilt = fix(Modules[thisModuleIndex].filter)
  ;boxwidth = fix(Modules[thisModuleIndex].boxwidth)
  ;Type of aperture for background estimation
  ;step = fix(Modules[thisModuleIndex].step)
  ;width = fix(Modules[thisModuleIndex].width)
  ;inner_radius = fix(Modules[thisModuleIndex].inner_radius)
  ;outer_radius = fix(Modules[thisModuleIndex].outer_radius)

  ;rotation angles
  ;////////////
  spot_rotang = [atan(spot_ysep[0],spot_xsep[0]) - !PI, !PI + atan(spot_ysep[1],spot_xsep[1]), atan(spot_ysep[2],spot_xsep[2]), atan(spot_ysep[3],spot_xsep[3]) ]
  ;/////////////
  ;print, ' '
  ; print, 'SPOT_ROTANG= ', spot_rotang
  ; print, ' '


  ;MASKS AND FITLERS

  ; First, it there is a companion, mask it first
  ; then continue to skyfilters as one should use the masked image anyways

  ;  IF (companion EQ 1) THEN BEGIN
  ;    print, ' '
  ;    print, 'Companion found'
  ;    imgmask0=img0
  ;    imgmask1=img1
  ;    ;imgmask=readfits('~/RACETRACK-DATA/'+targetname+'/'+targetname+'-IMG-0-HPF.fits',/silent,EXTEN_NO=0)
  ;    cntrd, imgmask0, incomposx,incomposy, compx, compy,3 ;companion's centroid assuming fwhm=3pix
  ;    IF (compx EQ -1) THEN BEGIN
  ;      print, ' '
  ;      return, error('FAILURE (CNTRD): ERROR in CNTRD: Check Companion initial position.')
  ;      print, ' '
  ;    ENDIF
  ;    dist_circle, circ0, 281, compx, compy
  ;    com=where(circ0 lt 12, countcom)
  ;    imgmask0[com]=!values.d_nan
  ;    imgmask1[com]=!values.d_nan
  ;    ;writefits, '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-HPF.fits', imgmask
  ;  ENDIF ELSE BEGIN
  ;    ;No Companion
  ;    imgmask0=img0
  ;    imgmask1=img1
  ;    ;writefits, '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-HPF.fits', img0
  ;  ENDELSE ; END COMPANION
  ;
  ;  ;Now call skyfitlers if requested
  ;  IF (skyfilt EQ 1) THEN BEGIN
  ;    print, ' '
  ;    print, 'High-pass Filtering             '
  ;    print, 'box width in pixels: ' , boxwidth
  ;    print, 'Masking out satellite spots'
  ;
  ;    FOR spot=0,3 DO BEGIN
  ;      spotx = starx + spot_xsep[spot]
  ;      spoty = stary + spot_ysep[spot]
  ;      imgmask0=sourcemask(imgmask0, spotx, spoty, spot_rotang[spot], aperradii, halflength,targetname,skyfilt)
  ;      imgmask1=sourcemask(imgmask1, spotx, spoty, spot_rotang[spot], aperradii, halflength,targetname,skyfilt)
  ;    ENDFOR
  ;    writefits, '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-HPF0.fits', imgmask0
  ;    writefits, '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-HPF1.fits', imgmask1
  ;    ;masked image
  ;    imgmean0=filter_image(imgmask0, MEDIAN=boxwidth,/ALL_PIXELS)
  ;    imgmean1=filter_image(imgmask1, MEDIAN=boxwidth,/ALL_PIXELS)
  ;    ;then substract filtered image to original image
  ;    im0=img0-imgmean0
  ;    im1=img1-imgmean1
  ;    writefits, '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-HPF0-EXIT..fits', im0
  ;    writefits, '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-HPF1-EXIT..fits', im1
  ;    imgspare0=im0; spare image
  ;    imgspare1=im1; spare image
  ;    atv, im0,/block ; Filtered image
  ;    atv, im1,/block ; Filtered image
  ;  ENDIF ELSE IF (skyfilt EQ 2) THEN BEGIN
  ;    print, ' '
  ;    print, 'Calling Radial Profile Subtract'
  ;    print, ' '
  ;    print, 'Masking out satellite spots'
  ;    ;////////////////////////////////////////
  ;
  ;    FOR spot=0,3 DO BEGIN
  ;      ;imgmask=readfits('~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-RPS.fits',/silent,EXTEN_NO=0)
  ;      spotx = starx + spot_xsep[spot]
  ;      spoty = stary + spot_ysep[spot]
  ;      imgmask0=sourcemask(imgmask0, spotx, spoty, spot_rotang[spot], aperradii, halflength,targetname, skyfilt)
  ;      imgmask1=sourcemask(imgmask1, spotx, spoty, spot_rotang[spot], aperradii, halflength,targetname, skyfilt)
  ;    ENDFOR
  ;    writefits, '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-RPS0.fits', imgmask0
  ;    writefits, '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-RPS1.fits', imgmask1
  ;    radprof_subtract, img0, starx, stary, step, width, inner_radius, outer_radius, dime, filename_masked='~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-RPS0.fits',$
  ;       '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-RPS0-EXIT.fits', '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-RPS0-EXIT-FILE.log',targetname
  ;    radprof_subtract, img1, starx, stary, step, width, inner_radius, outer_radius, dime, filename_masked='~/RACETRACK-DATA/'+targetname+'/'+targetname+'-MASK-RPS1.fits',$
  ;       '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-RPS1-EXIT.fits', '~/RACETRACK-DATA/'+targetname+'/'+targetname+'-RPS1-EXIT-FILE.log',targetname
  ;    im0 = readfits('~/RACETRACK-DATA/'+targetname+'/'+targetname+'-RPS0-EXIT.fits',/silent, EXTEN_NO=0)
  ;    im1 = readfits('~/RACETRACK-DATA/'+targetname+'/'+targetname+'-RPS1-EXIT.fits',/silent, EXTEN_NO=0)
  ;    imgspare0=im0; spare image
  ;    imgspare1=im1; spare image
  ;    ;
  ;    ENDIF ELSE IF (skyfilt EQ 0 ) THEN BEGIN
  ;    print, 'No Filters Applied         '
  ;    im0=img0
  ;    im1=img1
  ;    imgspare0=img0; spare image
  ;    imgspare1=img1; spare image
  ;    ENDIF


  imgspare0=img0; spare image
  imgspare1=img1; spare image


  fluxes0 = dindgen(5,4)
  fluxes1 = dindgen(5,4)

  ;NOW, MEASURING FLUXES
  ;IN EACH SLICE
  print,  ' '
  FOR spot=0,3 DO BEGIN
    spotx = starx + spot_xsep[spot]
    spoty = stary + spot_ysep[spot]
    print, ''
    print, 'Now on Sat Spot #: ', spot
    print, 'FLUXES IN SLICE 0:'
    flux0 = racetrack_aper( img0, imgspare0, spotx, spoty, spot_rotang[spot],  aperradii, halflength, spot, spec, uttimeobs, targetname, ncoadd)
;    flux0 = racetrack_aper( img0, imgspare0, spotx, spoty, spot_rotang[spot],  aperradii, halflength, spot, spec, uttimeobs, targetname, ncoadd, itime)
    print, 'FLUXES IN SLICE 1:'
    flux1 = racetrack_aper( img1, imgspare1, spotx, spoty, spot_rotang[spot],  aperradii, halflength, spot, spec, uttimeobs, targetname, ncoadd)
;    flux1 = racetrack_aper( img1, imgspare1, spotx, spoty, spot_rotang[spot],  aperradii, halflength, spot, spec, uttimeobs, targetname, ncoadd, itime)
    ;SLICE 0
    fluxes0[0,spot]=flux0[0]        ; SAT SPOT FLUX
    fluxes0[1,spot]=flux0[1]        ; SAT SPOT FLUX UNCERTAINTIES
    fluxes0[2,spot]=flux0[2]        ; SKY MEDIAN
    fluxes0[3,spot]=flux0[3]        ; SKY MODE
    fluxes0[4,spot]=flux0[4]        ; SKY MODE
    ;SLICE 1
    fluxes1[0,spot]=flux1[0]        ; SAT SPOT FLUX
    fluxes1[1,spot]=flux1[1]        ; SAT SPOT FLUX UNCERTAINTIES
    fluxes1[2,spot]=flux1[2]        ; SKY MEDIAN
    fluxes1[3,spot]=flux1[3]        ; SKY MODE
    fluxes1[4,spot]=flux1[4]        ; SKY MODE


    flag0=flux0[7]                  ; FLAG -1 Warning, 1 All good. Bad if at least one sat spot is saturated
    flag1=flux1[7]
  ENDFOR

  totflux0=total(fluxes0[0,*])
  totflux1=total(fluxes1[0,*])
  totdeltaflux0=total(fluxes0[1,*])
  totdeltaflux1=total(fluxes1[1,*])
  meanflux0=mean(fluxes0[0,*])
  meanflux1=mean(fluxes1[0,*])
  print, '******************************'
  print, 'SATSPOT TOTAL FLUX (ADU s-1 coadd-1) in Slice 0:  ', totflux0
  print, 'SATSPOT TOTAL FLUX (ADU s-1 coadd-1) in Slice 1:  ', totflux1
  print, 'MEAN FLUX (ADU s-1 coadd-1) in Slice 0: ', meanflux0
  print, 'MEAN FLUX (ADU s-1 coadd-1) in Slice 1: ', meanflux1
  print, '******************************'
  print, ' '

  ;Finding companion centroid, then calling apper to find its flux
  ;pro cntrd, img, x, y, xcen, ycen, fwhm, SILENT= silent, DEBUG=debug, $
  ;EXTENDBOX = extendbox, KeepCenter = KeepCenter
  ;comppos  cntrd, img, 98, 121,3
  IF (companion EQ 1) THEN BEGIN
    cntrd, img0, incomposx,incomposy, compx, compy,3 ;companion's centroid assuming fwhm=2pix
    IF (compx EQ -1) THEN BEGIN
      print, ' '
      return, error('FAILURE (CNTRD): ERROR in CNTRD: Check Companion initial position.')
      print, ' '
    ENDIF
    aper, img0, compx, compy, compflux0, compdeltaflux0, skyval0, deltasky0, 1, comaper, [inncomskrad,outcomskrad], /NAN, /EXACT, /FLUX
    aper, img1, compx, compy, compflux1, compdeltaflux1, skyval1, deltasky1, 1, comaper, [inncomskrad,outcomskrad], /NAN, /EXACT, /FLUX

    dist_circle, circ0, 281, compx, compy
    com=where(circ0 le comaper, countcom)
    skycom=where((circ0 ge inncomskrad) and (circ0 le outcomskrad), skycountcom)
    imgspare0[com]=1e5
    imgspare0[skycom]=!values.f_nan
    imgspare1[com]=1e5
    imgspare1[skycom]=!values.f_nan
    atv, imgspare0,/block ;SLIXE 0
    atv, imgspare1,/block ;SLICE 1


    ;save results

    ;*(dataset.currframe[0])=img ;
    ;APER, image, xc, yc, [ mags, errap, sky, skyerr, phpadu, apr, skyrad,
    ;                       badpix, /NAN, /EXACT, /FLUX, PRINT = , /SILENT,
    ;                       /MEANBACK, MINSKY=, SETSKYVAL = ]

    compflux0=compflux0/(itime)                   ;By unit time and coadd
    compdeltaflux0=compdeltaflux0/(itime)
    compflux1=compflux1/(itime)                   ;By unit time and coadd
    compdeltaflux1=compdeltaflux1/(itime)

    print, '****************************'
    print, 'Slice 0'
    print, ' COMPANION FLUX (ADU s-1 coadd-1):  ', compflux0
    print, ' DELTA FLUX (ADU s-1 coadd-1): ', compdeltaflux0
    print, ' FLUX RATIO ( Sum of all satspots to Companion)', totflux0/compflux0
    print, ' '
    print, 'Slice 1'
    print, ' COMPANION FLUX (ADU s-1 coadd-1):  ', compflux1
    print, ' DELTA FLUX (ADU s-1 coadd-1): ', compdeltaflux1
    print, ' FLUX RATIO ( Sum of all satspots to Companion)', totflux1/compflux1
    print, '****************************'
  ENDIF ELSE BEGIN
    compflux0=0.0 ; NO COMPANION, ZERO FLUX AND DELTAF THEN
    compdeltaflux0=0.0
    compflux1=0.0 ; NO COMPANION, ZERO FLUX AND DELTAF THEN
    compdeltaflux1=0.0
    if showaperture then begin
      atv, imgspare0,/block
      atv, imgspare1,/block
    endif
  ENDELSE

  ;/////////////////////
  ; Saving to File
  ;///////////////////////


  ;Saving results
  ;  IF (saveinheader EQ 1) THEN BEGIN
  ;Save the half-band location
  ;The may eventually get written by something else.

  ;Put in the theoretical location of the center of the satellite spots
  ;SLICE0
  backbone->set_keyword, 'SATS0_0', string(strtrim([xs0,ys0],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 0 of slice 0'
  backbone->set_keyword, 'SATS0_1', string(strtrim([xs1,ys1],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 1 of slice 0'
  backbone->set_keyword, 'SATS0_2', string(strtrim([xs2,ys2],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 2 of slice 0'
  backbone->set_keyword, 'SATS0_3', string(strtrim([xs3,ys3],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 3 of slice 0'
  ;SLICE1
  backbone->set_keyword, 'SATS1_0', string(strtrim([xs0,ys0],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 0 of slice 1'
  backbone->set_keyword, 'SATS1_1', string(strtrim([xs0,ys1],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 1 of slice 1'
  backbone->set_keyword, 'SATS1_2', string(strtrim([xs0,ys2],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 2 of slice 1'
  backbone->set_keyword, 'SATS1_3', string(strtrim([xs0,ys3],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 3 of slice 1'

  ;This keeps track of which slices have valid satellite spot positions.
  ;For now set this all to one.
  ;For now set these all to one.(valid)
  good=[0,1]
  ;;convert good elements to HEX
  goodcode = ulon64arr((size(imgcub,/dim))[2])
  goodcode[good] = 1
  ;print,string(goodcode,format='('+strtrim(n_elements(goodcode),2)+'(I1))')
  gooddec = ulong64(0)
  for j=n_elements(goodcode)-1,0,-1 do gooddec += goodcode[j]*ulong64(2)^ulong64(n_elements(goodcode)-j-1)
  goodhex = strtrim(string(gooddec,format='((Z))'),2)
  backbone->set_keyword,'SATSMASK',goodhex,'HEX->binary mask for slices with found sats',ext_num=1

  ;Save the fluxes
  ;SLICE 0
  backbone->set_keyword, 'SATF0_0',      fluxes0[0,0], "Sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF0_0E',  fluxes0[1,0], "Uncertainty in sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF0_1',      fluxes0[0,1], "Sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF0_1E',  fluxes0[1,1], "Uncertainty in sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF0_2',      fluxes0[0,2], "Sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF0_2E',  fluxes0[1,2], "Uncertainty in sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF0_3',      fluxes0[0,3], "Sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF0_3E',  fluxes0[1,3], "Uncertainty in sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  ;SLICE 1
  backbone->set_keyword, 'SATF1_0',      fluxes1[0,0], "Sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF1_0E',  fluxes1[1,0], "Uncertainty in sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF1_1',      fluxes1[0,1], "Sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF1_1E',  fluxes1[1,1], "Uncertainty in sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF1_2',      fluxes1[0,2], "Sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF1_2E',  fluxes1[1,2], "Uncertainty in sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF1_3',      fluxes1[0,3], "Sat. spot flux (ADU s-1 coadd-1)", ext_num=1
  backbone->set_keyword, 'SATF1_3E',  fluxes1[1,3], "Uncertainty in sat. spot flux (ADU s-1 coadd-1)", ext_num=1

  ;This keeps track of which slices have valid satellite spot fluxes.
  ;For now set these all to one.(valid)
  warns=0
  ;;convert warnings to hex elements to HEX
  bad = where(warns eq -1,ct)
  if ct gt 0 then warns[bad] = 0
  warncode = ulong64(warns)
  ;print,string(warncode,format='('+strtrim(n_elements(warncode),2)+'(I1))')
  warndec = ulong64(0)
  for j=n_elements(warncode)-1,0,-1 do warndec += warncode[j]*ulong64(2)^ulong64(n_elements(warncode)-j-1)
  warnhex = strtrim(string(warndec,format='((Z))'),2)
  backbone->set_keyword,'SATSWARN',warnhex,'HEX->binary mask for slices with varying sat fluxes.',ext_num=1
  ;  ENDIF


  ;*(dataset.currframe[0])=imgcub;

  ; SATPOS=findgen(2,4);
  ;  FOR spot=0,3 DO BEGIN
  ;    SATPOS[0, spot] = starx + spot_xsep[spot]
  ;    SATPOS[1, spot] = stary + spot_ysep[spot]
  ;  END
  ;
  ;
  ;CASE skyfilt OF
  ;   0: BEGIN
  ;      OPENW,unit,'~/RACETRACK-DATA/'+targetname+'/'+targetname+'-POL-FLUX-0.dat',/APPEND, /get_lun
  ;      printf, unit, totflux0, totdeltaflux0, meanflux0, compflux0, compdeltaflux0, uttimeobs,ncoadd,flag0,$
  ;      format='(G13.10, G13.10, G13.10,G13.10,G13.10, G13.10,G13.10,G13.10)'
  ;      free_lun, unit
  ;      OPENW,unit,'~/RACETRACK-DATA/'+targetname+'/'+targetname+'-POL-FLUX-1.dat',/APPEND, /get_lun
  ;      printf, unit, totflux1, totdeltaflux1, meanflux1, compflux1, compdeltaflux1, uttimeobs,ncoadd,flag1,$
  ;      format='(G13.10, G13.10, G13.10,G13.10,G13.10, G13.10,G13.10,G13.10)'
  ;      free_lun, unit
  ;      OPENW,unit,'~/RACETRACK-DATA/'+targetname+'/'+targetname+'-SATPOS-POL.dat',/APPEND, /get_lun
  ;      printf, unit, SATPOS[0,0],SATPOS[1,0], SATPOS[0,1], SATPOS[1,1], SATPOS[0,2], SATPOS[1,2], SATPOS[0,3], SATPOS[1,3], uttimeobs, flag0,$
  ;      format='(G13.10, G13.10, G13.10,G13.10,G13.10, G13.10, G13.10, G13.10, G13.10,G13.10)'
  ;      free_lun, unit
  ;      END
  ;   1: BEGIN
  ;      OPENW,unit,'~/RACETRACK-DATA/'+targetname+'/'+targetname+'-POL-FLUX-HPass-0.dat',/APPEND, /get_lun
  ;      printf, unit, totflux0, totdeltaflux0, meanflux0, compflux0, compdeltaflux0, uttimeobs,ncoadd,flag0,$
  ;      format='(G13.10, G13.10, G13.10,G13.10,G13.10, G13.10,G13.10,G13.10)'
  ;      free_lun, unit
  ;      OPENW,unit,'~/RACETRACK-DATA/'+targetname+'/'+targetname+'-POL-FLUX-HPass-1.dat',/APPEND, /get_lun
  ;      printf, unit, totflux1, totdeltaflux1, meanflux1, compflux1, compdeltaflux1, uttimeobs,ncoadd,flag1,$
  ;      format='(G13.10, G13.10, G13.10,G13.10,G13.10, G13.10,G13.10,G13.10)'
  ;      free_lun, unit
  ;      END
  ;   2: BEGIN
  ;      OPENW,unit,'~/RACETRACK-DATA/'+targetname+'/'+targetname+'-POL-FLUX-RPS-0.dat',/APPEND, /get_lun
  ;      printf, unit, totflux0, totdeltaflux0, meanflux0, compflux0, compdeltaflux0, uttimeobs,ncoadd,flag0,$
  ;      format='(G13.10, G13.10, G13.10,G13.10,G13.10, G13.10,G13.10,G13.10)'
  ;      free_lun, unit
  ;      OPENW,unit,'~/RACETRACK-DATA/'+targetname+'/'+targetname+'-POL-FLUX-RPS-1.dat',/APPEND, /get_lun
  ;      printf, unit, totflux1, totdeltaflux1, meanflux1, compflux1, compdeltaflux1, uttimeobs,ncoadd,flag1,$
  ;      format='(G13.10, G13.10, G13.10,G13.10,G13.10, G13.10,G13.10,G13.10)'
  ;      free_lun, unit
  ;      END
  ;ENDCASE

  print, ' '
  print, '/////  Done ///// '
  print, ' '
  @__end_primitive
end
