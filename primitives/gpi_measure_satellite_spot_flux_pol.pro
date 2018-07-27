;+
; NAME: gpi_measure_satellite_spot_flux_pol
; PIPELINE PRIMITIVE DESCRIPTION: Measure Satellite Spot Flux in Polarimetry
;
; This primitive measures the satellite spot fluxes in polarimetry mode.
;
; It will behave differently depending on where in the recipe it is placed:
; If before accumulate images , then perform on a single image normally.
; If after accumulate images, then perform on the stack of images averaged into one image for better SNR.
;   It then saves into each cube the average sat spot fluxes
;
; PIPELINE COMMENT:  Measure Flux in Polarimetry
; PIPELINE CATEGORY: Calibration, PolarimetricScience
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: Save flux value in header, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="5" Desc="1-500: Choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="Aperture" Type="int" Range="[1,5]" Default="4" Desc="Aperture value used in Racetrack, Default: 4pix"
; PIPELINE ARGUMENT: Name="Inskyrad" Type="int" Range="[4,8]" Default="6" Desc="Inner sky aperture radius in Racetrack"
; PIPELINE ARGUMENT: Name="Outskyrad" Type="int" Range="[6,14]" Default="9" Desc="Outer sky aperture radius in Racetrack"
; PIPELINE ARGUMENT: Name="SecondOrder" Type="int" Range="[0,1]" Default="0" Desc="Use 2nd order sat spots? 1: Yes (for Y or J only)"
; PIPELINE ARGUMENT: Name="ShowAperture" Type="int" Range="[0,1]" Default="0" Desc="Show the satellite spot apertures? 1: Yes"
; PIPELINE ARGUMENT: Name="FindPSFCENT" Type="int" Range="[0,1]" Default="0" Desc="1: Radon, 0: Do Nothing"
; PIPELINE ARGUMENT: Name="STARXCEN" Type="int" Range="[0,300]" Default="145" Desc="Initial X position in CNTRD or RADON"
; PIPELINE ARGUMENT: Name="STARYCEN" Type="int" Range="[0,300]" Default="148" Desc="Initial Y position in CNTRD or RADON"
; PIPELINE ARGUMENT: Name="Companion" Type="int" Range="[0,1]" Default="0" Desc="Is there a companion? 0: No, 1: Yes"
; PIPELINE ARGUMENT: Name="StarXPos" Type="int" Range="[0,500]" Default="98" Desc="Companion X pos for CNTRD"
; PIPELINE ARGUMENT: Name="StarYPos" Type="int" Range="[0,500]" Default="121" Desc="Companion Y pos for CNTRD"
; PIPELINE ARGUMENT: Name="StarAperture" Type="int" Range="[3,10]" Default="8" Desc="Optimum Aperture value used in APER"
; PIPELINE ARGUMENT: Name="StarInnerSkyRad" Type="int" Range="[5,15]" Default="12" Desc="Inner Skyrad  value used in APER"
; PIPELINE ARGUMENT: Name="StarOuterSkyRad" Type="int" Range="[10,20]" Default="16" Desc="Outer Skyrad  value used in APER"
; PIPELINE ARGUMENT: Name="Verbose" Type="int" Range="[0,1]" Default="0" Desc="0 = quiet, 1 = verbose"
;
; PIPELINE ORDER: 2.52
;
; HISTORY:
;
;   06-01-15 Created - Sebastian
;   08-24-15 MMB: Fixed up with comments and added pipeline level functionality and 'verbose' keyword
;   10-22-15 Sebastian: Removed itime call in racetrack_aper. Not needed since fluxes are in ADU coadd^-1. Removed flag variable here and in racetrack_aper.
;   07-27-18 TME: Added different sat spot angles and separations for Y,J,H,K1 apodizers. K2 assumes K1 angles. Added 2nd order spot option.
;
function gpi_measure_satellite_spot_flux_pol, DataSet, Modules, Backbone
  ; enforce modern IDL compiler options:
  compile_opt defint32, strictarr, logical_predicate

  @__start_primitive
  imgcub = *(dataset.currframe[0])

  $clear

  ;Get some important header info
  targetname=backbone->get_keyword("OBJECT")
  itime=backbone->get_keyword("ITIME")
  ncoadd=backbone->get_keyword("COADDS0")
  readnum=backbone->get_keyword('READS')
  sysgain=backbone->get_keyword('SYSGAIN')
  uttime=backbone->get_keyword("UT", count=cc)
  apod=backbone->get_keyword("APODIZER")

  ; are we reducing one file at a time, or are we dealing with a set of
  ; multiple files?
  reduction_level = backbone->get_current_reduction_level()

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

  verbose=fix(Modules[thisModuleIndex].Verbose)

  if verbose then begin
    print, ' '
    print, 'TARGET: ', targetname
    print, 'ITIME: ', itime
    print, 'OBSTIME: ', uttimeobs
    print, 'COADDS: ', ncoadd ;needed in flux uncertainties
    print, 'NREADS: ', readnum
    print, 'SYSGAIN: ', sysgain
    print, ' '
  endif

  ;Check to make sure wollaston mode
  mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
  mode = strlowcase(mode)

  ;;;Get Primitive arguments
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
  
  ;Are we using 2nd order sat spots?
  secOrder=fix(Modules[thisModuleIndex].SecondOrder)


  IF strmatch(mode,"*wollaston*",/fold) THEN BEGIN

    if verbose then begin
      print, '  '
      print, '  Loading Polarimetry Cube'
      print, '  '
    endif

    ;;Get the dimensions
    ;print, 'Reading NAXIS'
    dim1 = backbone->get_keyword("NAXIS1")
    dim2 = backbone->get_keyword("NAXIS2")
    dime=[dim1, dim2]
    ; print, "IMAGE DIMENSION: ", dime[0], dime[1]
    ; print, ''

    ;Get the two slices of the cube
    img0=imgcub[*,*,0] ; first slice
    img1=imgcub[*,*,1] ; second slice
    imgmask0=findgen(dime[0], dime[1]);
    imgmask1=findgen(dime[0], dime[1]);

    ; Run this if you have a very bright companion in your field and you want it masked out before running Jason's Radon
    IF ((findpsfcent EQ 1) AND (companion EQ 1)) THEN BEGIN

      if reduction_level eq 2 then begin
        return, error("For now, we can't get find the centroids again after the accumulate images primitive. Returning." )
      endif

      if verbose then begin
        print, ' '
        print, 'Computing PSFCENTX and PSFCENTY'
        print, 'Using RADON Transform'
      endif
      ;masking out companion
      imgmask=img0;
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

      if verbose then begin
        print, ' '
        print, 'Mask Created'
        print, 'Companion masked-out'
      endif

      statuswindow = backbone->getstatusconsole()
      cent = find_pol_center(imgmask, xposstar, yposstar, 7.0, 7.0, maskrad=50, highpass=1, pixlowerbound=-100.0, statuswindow=statuswindow)
      IF (cent[0] EQ -1) THEN BEGIN
        return, error('FAILURE (Find_pol_center): ERROR in Find_pol_center: Check Star initial position.')
      ENDIF
      backbone->set_keyword,"PSFCENTX", cent[0], 'X-Location of PSF center', ext_num=1
      backbone->set_keyword,"PSFCENTY", cent[1], 'Y-Location of PSF center', ext_num=1
      starx = cent[0]
      stary = cent[1]
      if verbose then begin
        print, ' '
        print, 'PSFCENTX ', starx
        print, 'PSFCENTY ', stary
        print, ' '
      endif

    ENDIF ELSE BEGIN
      if verbose then print, 'Reading star position from header          '
      starx = backbone->get_keyword( "PSFCENTX" )
      stary = backbone->get_keyword( "PSFCENTY" )
      IF (starx EQ 0.0)  THEN BEGIN
        return, error('FAILURE: Missing Keyword: PSFCENTX. Run Measure Star Position in Polarimetry first')
      ENDIF
      if verbose then begin
        print, 'PSFCENTX', starx
        print, 'PSFCENTY', stary
      endif
    ENDELSE

    ;//////// Calculating Sat Spot Positions in POL MODE
    ;1st order sat spots at ~20*lambda/D depending on apodizer.
    ;2nd order at ~40*lambda/D.

    ;;The azimuthal angles of the 4 sat spots, depending on apodizer used.
    ;Rotation Angle values in spot order: [S0, S1, S2, S3].
    ;K2 has no measurement (no test data available), uses K1 angles.

    ;Set default values in case non-standard apodizer was used.
    spot_angles=[ 155.9, -114.1, 66.0, -24.2] ; degrees
    sep_spots=21.26 ; lambda/D units
    print, ' '
    IF (apod eq 'APOD_Y_G6203') THEN BEGIN
      spot_angles=[ 158.3, -112.2, 68.2, -21.8]
      IF (secOrder eq 1) THEN BEGIN
        sep_spots=2*21.26 ; lambda/D units
        print, 'Using 2nd order sat spots!'
      ENDIF ELSE BEGIN
        sep_spots=21.26 ; lambda/D units
        print, 'Using 1st order sat spots.'
      ENDELSE
    ENDIF ELSE IF (apod eq 'APOD_J_G6204') THEN BEGIN
      spot_angles=[ 160.4, -109.9, 70.2, -19.4]
      IF (secOrder eq 1) THEN BEGIN
        sep_spots=2*21.26 ; lambda/D units
        print, 'Using 2nd order sat spots!'
      ENDIF ELSE BEGIN
        sep_spots=21.26 ; lambda/D units
        print, 'Using 1st order sat spots.'
      ENDELSE
    ENDIF ELSE IF (apod eq 'APOD_H_G6205') THEN BEGIN
      spot_angles=[ 155.9, -114.1, 66.0, -24.2]
      sep_spots=20.17 ; lambda/D units
    ENDIF ELSE IF (apod eq 'APOD_K1_G6206') THEN BEGIN
      spot_angles=[ 158.7, -111.7, 68.0, -21.9]
      sep_spots=20.17 ; lambda/D units
    ENDIF ELSE IF (apod eq 'APOD_K2_G6207') THEN BEGIN
      spot_angles=[ 158.7, -111.7, 68.0, -21.9]
      sep_spots=20.17 ; lambda/D units
    ENDIF

    ROT_ANG=(!PI/180.0)*spot_angles
    print, 'Locating spots at ', apod, ' angles: ', spot_angles

    ;Get the filter band
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
    ;get the platescale from config/pipeline_constants.txt
    platescale=gpi_get_constant('ifs_lenslet_scale')

    ;An array that holds the [inner, central, outer] location of the the satellite spots.
    R_spot=findgen(3)
    R_spot[0]=(206265/platescale)*sep_spots*lambdamin/D; in pixels, platescale in arcsec/pxs
    R_spot[1]=(206265/platescale)*sep_spots*landa/D; in pixels, platescale in arcsec/pxs
    R_spot[2]=(206265/platescale)*sep_spots*lambdamax/D; in pixels, platescale in arcsec/pxs
    halflength= R_spot[2]-R_spot[1]
    ;print, 'Lambda min [mu m]: ' , lambdamin*1e6;
    ;print, 'Lambda max [mu m]: ' , lambdamax*1e6;
    ;print, 'Streak Length (pixels): ', halflength
    ;print, 'R_spot[0]: ', R_spot[0]
    ;print, 'R_spot[1]: ', R_spot[1]
    ;print, 'R_spot[2]: ', R_spot[2]
    ;print, ''


    ;Get the x,y position of each sat spot.
    ;////////
    xs0=starx+R_spot[1]*cos(ROT_ANG[0])
    ys0=stary+R_spot[1]*sin(ROT_ANG[0])
    xs1=starx+R_spot[1]*cos(ROT_ANG[1])
    ys1=stary+R_spot[1]*sin(ROT_ANG[1])
    xs2=starx+R_spot[1]*cos(ROT_ANG[2])
    ys2=stary+R_spot[1]*sin(ROT_ANG[2])
    xs3=starx+R_spot[1]*cos(ROT_ANG[3])
    ys3=stary+R_spot[1]*sin(ROT_ANG[3])
    ;////////
    ;+++++++++++++++++++++++
    spot_posx=[xs0, xs1, xs2, xs3]
    spot_posy=[ys0, ys1, ys2, ys3]
    ;+++++++++++++++++++++++
    ;
    ;Now express it as a separation from the central star.
    ;++++
    spot_xsep=[xs0-starx, xs1-starx, xs2-starx, xs3-starx]
    spot_ysep=[ys0-stary, ys1-stary, ys2-stary, ys3-stary]
    ;++++
    ;

  ENDIF ELSE BEGIN
    print, ' '
    return, error('FAILURE: Not a polarimetry cube, run this primitive on pol cubes.')
    print, ' '

  ENDELSE  ;END OF READING IMAGE IN POL MODE

  ;;Read in some more primitive arguments.
  ;
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
  ;rotation angles
  ;////////////
  spot_rotang = [atan(spot_ysep[0],spot_xsep[0]) - !PI, !PI + atan(spot_ysep[1],spot_xsep[1]), atan(spot_ysep[2],spot_xsep[2]), atan(spot_ysep[3],spot_xsep[3]) ]
  ;/////////////

  imgspare0=img0; spare image
  imgspare1=img1; spare image

  fluxes0 = dindgen(5,4)
  fluxes1 = dindgen(5,4)


  ;Check the pipeline reduction level.
  ;if level 1, then perform on a single image normally.
  ;if level 2, then perform on either the stack of images summed into one image.

  case reduction_level of
    1: ;Keep things as they are
    2: begin
      ;Two images that will be the sum of all the images
      print, "Stacking all the images to measure the sat spot fluxes. "
      backbone->Log, "This primitive is after Accumulate Images so this is a Level 2 step", depth=3
      backbone->Log, "Therefore all accumulated cubes will be stacked on top of each other to measure the sat spot fluxes.", depth=3

      sum0=img0*0 ;Make a blank slate
      sum1=img1*0

      ;The number of files
      nfiles=dataset.validframecount

      for i=0,nfiles-1 do begin
        tmp=accumulate_getimage(dataset,i,hdr)
        sum0 += tmp[*,*,0]
        sum1 += tmp[*,*,1]
      endfor

      img0=sum0/nfiles
      img1=sum1/nfiles
    end

  endcase



  ;NOW, MEASURING FLUXES [ADU coadd^-1]
  ;IN EACH SLICE
  print,  ' '
  FOR spot=0,3 DO BEGIN
    spotx = spot_posx[spot]
    spoty = spot_posy[spot]
    print, ''
    print, 'Now on Sat Spot #: ', spot
    print, 'Fluxes in slice 0:'
    ;img, imgspare,xpos, ypos, rotang, aper_radii, halflength,spot, spec, skyfilt, uttimeobs, targetname, sysgain
    flux0 = racetrack_aper( img0, imgspare0, spotx, spoty, spot_rotang[spot],  aperradii, halflength, spot, uttimeobs, targetname, ncoadd, sysgain)
    print, 'Fluxes in slice 1:'
    flux1 = racetrack_aper( img1, imgspare1, spotx, spoty, spot_rotang[spot],  aperradii, halflength, spot, uttimeobs, targetname, ncoadd, sysgain)
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

  
  ENDFOR

  totflux0=total(fluxes0[0,*])
  totflux1=total(fluxes1[0,*])
  totdeltaflux0=total(fluxes0[1,*])
  totdeltaflux1=total(fluxes1[1,*])
  meanflux0=mean(fluxes0[0,*])
  meanflux1=mean(fluxes1[0,*])

  if verbose then begin
    print, '******************************'
    print, 'SATSPOT TOTAL FLUX (ADU coadd^-1) in Slice 0:  ', totflux0
    print, 'SATSPOT TOTAL FLUX (ADU coadd^-1) in Slice 1:  ', totflux1
    print, 'MEAN FLUX (ADU coadd^-1) in Slice 0: ', meanflux0
    print, 'MEAN FLUX (ADU coadd^1) in Slice 1: ', meanflux1
    print, '******************************'
    print, ' '
  endif

  ;Finding companion centroid, then calling apper to find its flux



  IF (companion EQ 1) THEN BEGIN
    cntrd, img0, incomposx,incomposy, compx, compy,4 ;companion's centroid assuming fwhm 4pix
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
    atv, imgspare0,/block ;SLICE 0
    atv, imgspare1,/block ;SLICE 1


    ;Print results
    print, '****************************'
    print, 'Slice 0'
    print, ' COMPANION FLUX (ADU coadd^-1):  ', compflux0
    print, ' DELTA FLUX (ADU coadd^-1): ', compdeltaflux0
    print, ' FLUX RATIO ( Sum of all satspots to Companion)', totflux0/compflux0
    print, ' '
    print, 'Slice 1'
    print, ' COMPANION FLUX (ADU  coadd^-1):  ', compflux1
    print, ' DELTA FLUX (ADU coadd^-1): ', compdeltaflux1
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
  ; Updating Headers
  ;///////////////////////
  ;
  case reduction_level of
    1: begin
      ;Put in the theoretical location of the center of the satellite spots
      ;SLICE0
      backbone->set_keyword, 'SAT0_0', string(strtrim([xs0,ys0],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 0 of slice 0', ext_num=1
      backbone->set_keyword, 'SAT0_1', string(strtrim([xs1,ys1],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 1 of slice 0', ext_num=1
      backbone->set_keyword, 'SAT0_2', string(strtrim([xs2,ys2],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 2 of slice 0', ext_num=1
      backbone->set_keyword, 'SAT0_3', string(strtrim([xs3,ys3],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 3 of slice 0', ext_num=1
      ;SLICE1
      backbone->set_keyword, 'SAT1_0', string(strtrim([xs0,ys0],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 0 of slice 1', ext_num=1
      backbone->set_keyword, 'SAT1_1', string(strtrim([xs1,ys1],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 1 of slice 1', ext_num=1
      backbone->set_keyword, 'SAT1_2', string(strtrim([xs2,ys2],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 2 of slice 1', ext_num=1
      backbone->set_keyword, 'SAT1_3', string(strtrim([xs3,ys3],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 3 of slice 1', ext_num=1

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

      ;Saving the fluxes
      ;SLICE 0
      backbone->set_keyword, 'SATF0_0',      fluxes0[0,0], "Sat. spot flux (ADU coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF0_0E',  fluxes0[1,0], "Uncertainty in sat. spot flux (ADU coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF0_1',      fluxes0[0,1], "Sat. spot flux (ADU coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF0_1E',  fluxes0[1,1], "Uncertainty in sat. spot flux (ADU coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF0_2',      fluxes0[0,2], "Sat. spot flux (ADU coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF0_2E',  fluxes0[1,2], "Uncertainty in sat. spot flux (ADU coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF0_3',      fluxes0[0,3], "Sat. spot flux (ADU coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF0_3E',  fluxes0[1,3], "Uncertainty in sat. spot flux (ADU coadd^-1)", ext_num=1
      ;SLICE 1
      backbone->set_keyword, 'SATF1_0',      fluxes1[0,0], "Sat. spot flux (ADU s-1 coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF1_0E',  fluxes1[1,0], "Uncertainty in sat. spot flux (ADU  coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF1_1',      fluxes1[0,1], "Sat. spot flux (ADU s-1 coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF1_1E',  fluxes1[1,1], "Uncertainty in sat. spot flux (ADU coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF1_2',      fluxes1[0,2], "Sat. spot flux (ADU s-1 coadd-1)", ext_num=1
      backbone->set_keyword, 'SATF1_2E',  fluxes1[1,2], "Uncertainty in sat. spot flux (ADU coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF1_3',      fluxes1[0,3], "Sat. spot flux (ADU s-1 coadd^-1)", ext_num=1
      backbone->set_keyword, 'SATF1_3E',  fluxes1[1,3], "Uncertainty in sat. spot flux (ADU coadd^-1)", ext_num=1

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
    end
    ;Reduction level 2
    ;Here we'll write the sat spot values from the 'averaged frame' to every single header.
    2: begin

      for i=0,nfiles-1 do begin
        tmp=accumulate_getimage(dataset,i,hdr,hdrext=hdrext)
        ;Put in the theoretical location of the center of the satellite spots
        ;SLICE0
        sxaddpar, hdrext,  'SAT0_0', string(strtrim([xs0,ys0],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 0 of slice 0'
        sxaddpar, hdrext,  'SAT0_1', string(strtrim([xs1,ys1],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 1 of slice 0'
        sxaddpar, hdrext,  'SAT0_2', string(strtrim([xs2,ys2],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 2 of slice 0'
        sxaddpar, hdrext,  'SAT0_3', string(strtrim([xs3,ys3],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 3 of slice 0'
        ;SLICE1
        sxaddpar, hdrext,  'SAT1_0', string(strtrim([xs0,ys0],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 0 of slice 1'
        sxaddpar, hdrext,  'SAT1_1', string(strtrim([xs1,ys1],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 1 of slice 1'
        sxaddpar, hdrext,  'SAT1_2', string(strtrim([xs2,ys2],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 2 of slice 1'
        sxaddpar, hdrext,  'SAT1_3', string(strtrim([xs3,ys3],2),format='(F7.3," ",F7.3)'),'Location of sat. spot 3 of slice 1'

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
        sxaddpar, hdrext, 'SATSMASK',goodhex,'HEX->binary mask for slices with found sats'

        ;Saving the fluxes
        ;SLICE 0
        sxaddpar, hdrext,  'SATF0_0',      fluxes0[0,0], "Sat. spot flux (ADU coadd^-1)"
        sxaddpar, hdrext,  'SATF0_0E',  fluxes0[1,0], "Uncertainty in sat. spot flux (ADU coadd^-1)"
        sxaddpar, hdrext,  'SATF0_1',      fluxes0[0,1], "Sat. spot flux (ADU coadd^-1)"
        sxaddpar, hdrext,  'SATF0_1E',  fluxes0[1,1], "Uncertainty in sat. spot flux (ADU coadd^-1)"
        sxaddpar, hdrext,  'SATF0_2',      fluxes0[0,2], "Sat. spot flux (ADU coadd^-1)"
        sxaddpar, hdrext,  'SATF0_2E',  fluxes0[1,2], "Uncertainty in sat. spot flux (ADU coadd^-1)"
        sxaddpar, hdrext,  'SATF0_3',      fluxes0[0,3], "Sat. spot flux (ADU coadd^-1)"
        sxaddpar, hdrext,  'SATF0_3E',  fluxes0[1,3], "Uncertainty in sat. spot flux (ADU coadd^-1)"
        ;SLICE 1
        sxaddpar, hdrext,  'SATF1_0',      fluxes1[0,0], "Sat. spot flux (ADU s-1 coadd^-1)"
        sxaddpar, hdrext,  'SATF1_0E',  fluxes1[1,0], "Uncertainty in sat. spot flux (ADU  coadd^-1)"
        sxaddpar, hdrext,  'SATF1_1',      fluxes1[0,1], "Sat. spot flux (ADU s-1 coadd^-1)"
        sxaddpar, hdrext,  'SATF1_1E',  fluxes1[1,1], "Uncertainty in sat. spot flux (ADU coadd^-1)"
        sxaddpar, hdrext,  'SATF1_2',      fluxes1[0,2], "Sat. spot flux (ADU s-1 coadd-1)"
        sxaddpar, hdrext,  'SATF1_2E',  fluxes1[1,2], "Uncertainty in sat. spot flux (ADU coadd^-1)"
        sxaddpar, hdrext,  'SATF1_3',      fluxes1[0,3], "Sat. spot flux (ADU s-1 coadd^-1)"
        sxaddpar, hdrext,  'SATF1_3E',  fluxes1[1,3], "Uncertainty in sat. spot flux (ADU coadd^-1)"

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
        sxaddpar, hdrext, 'SATSWARN',warnhex,'HEX->binary mask for slices with varying sat fluxes.'

        accumulate_updateimage, dataset, i, newexthdr = hdrext
      endfor

    end
    endcase

    if verbose then begin
      print, ' '
      print, '/////  Done ///// '
      print, ' '
    endif

    @__end_primitive
  end
