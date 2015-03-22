;+
; NAME: gpi_measure_contrast_pol
; PIPELINE PRIMITIVE DESCRIPTION: Measure Contrast in Pol Mode
;
; Measure, display on screen, and optionally save the contrast.
;
;   TODO - should we revise this to call the same contrast measurement backend
;   as GPItv?
;
;   By default, the sat spots information are saved to the FITS header keywords
;   of the current file in memory, and will only be saved if you subsequently
;   save that datacube (i.e. using 'save=1' on this primitive or a subsequent
;   one). The 'update_prev_fits_header' option will, in addition, also let you
;   write the same keyword information to the header of the most recently saved
;   file. This is useful if you have just already saved the datacube, and you
;   only now want to update this metadata.
;
; INPUTS: Spectral mode datacube
; OUTPUTS:  Contrast datacube, plot of contrast curve
;
;
; PIPELINE COMMENT: Measure the contrast. Save as PNG or FITS table.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[-1,100]" Default="-1" Desc="-1 = No display; 0 = New (unused) window; else = Window number to display in."
; PIPELINE ARGUMENT: Name="update_prev_fits_header" Type="int" Range="[0,1]" Default="0" Desc="Update FITS metadata in the most recently saved datacube?"
; PIPELINE ARGUMENT: Name="SaveProfile" Type="string" Default="" Desc="Save radial profile to filename as FITS (blank for no save, dir name for default naming, AUTO for auto full path)"
; PIPELINE ARGUMENT: Name="SavePNG" Type="string" Default="" Desc="Save plot to filename as PNG (blank for no save, dir name for default naming, AUTO for auto full path) "
; PIPELINE ARGUMENT: Name="contrsigma" Type="float" Range="[0.,20.]" Default="5." Desc="Contrast sigma limit"
; PIPELINE ARGUMENT: Name="slice" Type="int" Range="[-1,50]" Default="-1" Desc="Slice to plot. -1 for all"
; PIPELINE ARGUMENT: Name="DarkHoleOnly" Type="int" Range="[0,1]" Default="1" Desc="0: Plot profile in dark hole only; 1: Plot outer profile as well."
; PIPELINE ARGUMENT: Name="contr_yunit" Type="int" Range="[0,2]" Default="0" Desc="0: Standard deviation; 1: Median; 2: Mean."
; PIPELINE ARGUMENT: Name="contr_xunit" Type="int" Range="[0,1]" Default="0" Desc="0: Arcsec; 1: lambda/D."
; PIPELINE ARGUMENT: Name="yscale" Type="int" Range="[0,1]" Default="0" Desc="0: Auto y axis scaling; 1: Manual scaling."
; PIPELINE ARGUMENT: Name="contr_yaxis_type" Type="int" Range="[0,1]" Default="1" Desc="0: Linear; 1: Log"
; PIPELINE ARGUMENT: Name="contr_yaxis_min" Type="float" Range="[0.,1.]" Default="0.00000001" Desc="Y axis minimum"
; PIPELINE ARGUMENT: Name="contr_yaxis_max" Type="float" Range="[0.,1.]" Default="1." Desc="Y axis maximum"
; PIPELINE ORDER: 2.7
; PIPELINE CATEGORY: SpectralScience,PolarimetricScience
;
; HISTORY:
;   initial version imported GPItv (with definition of contrast corrected) - JM
;-
;       Fixed issue where y-axis values will not be printed on axis if
;       contrast curve spans less than an order of magnitude -EN
;
;   19/03/15: MMB - Branched off this version to work on a stokes cube
;
;
function gpi_measure_contrast_pol, DataSet, Modules, Backbone

  primitive_version= '$Id: gpi_measure_contrast.pro 3637 2015-01-14 18:04:02Z ingraham $' ; get version from subversion to store in header history
    @__start_primitive

  suffix='-contr'

  cube = *(dataset.currframe[0])
  band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))

  sz=size(cube)
  dim=size(cube, /dim)


  ;;error handle if extractcube not used before
  if ((sz)[0] ne 3) || (strlen(band) eq 0)  then $
    return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use "Assemble Datacube" before this one.')

  ; Verify this is in fact polarization mode data
  mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
  mode = strlowcase(mode)
  if ~strmatch(mode,"*wollaston*",/fold) then begin
    return, error('FAILURE ('+functionName+"): This is not a polarimetry file!")
  endif

  nslice=2
  ctr_cube=fltarr(sz[1],sz[2],nslice)

  ; Check the dimensions
  ; We'll set:
  ; polmode=0 for podc cubes
  ; polmode=1 for stokesdc
  ; polmode=2 for radial stokes
  
  if sz[3] eq 2 then begin ; If podc cube
    polmode=0
    ctr_cube[*,*,0]=cube[*,*,0]+cube[*,*,1]
    ctr_cube[*,*,1]=cube[*,*,0]-cube[*,*,1] ;For podc cube we look at the difference
    hdr_suff='' ; A suffix to get the header fluxes
  endif else if sz[3] eq 4 then begin
    type = backbone->get_keyword('STKESTYP', count=ct)
    if ct lt 1 then polmode=1 else begin
      case type of
        'STOKES': begin
          print, "Found a Stokes Cube"
          polmode=1
          ctr_cube[*,*,0]=cube[*,*,0]
          ctr_cube[*,*,1]=sqrt(cube[*,*,1]^2+cube[*,*,2]^2) ;For normal stokes cube we look at the linear polarized intensity
        end
        'RADIAL': begin
          print, "Found a Radial Stokes Cube"
          polmode=2
          ctr_cube[*,*,0]=cube[*,*,0]
          ctr_cube[*,*,1]=cube[*,*,2] ;For radial stokes cube we look at the radial stokes values
        end
        else: begin
          ;Something weird has happened, but let's assume it's normal stokes
          print, "Couldn't find STKESTYP keyword, assuming Stokes cube"
          polmode=1
          ctr_cube[*,*,0]=cube[*,*,0]
          ctr_cube[*,*,1]=sqrt(cube[*,*,1]^2+cube[*,*,2]^2) ;For normal stokes cube we look at the linear polarized intensity
        end
      endcase
      hdr_suff='S' ;The s goes at the end for stokes
    endelse

  endif else $
    return, error('FAILURE ('+functionName+"): The dimensions don't match any known pol cube")

  cwv = get_cwv(band,spectralchannels=(dim)[2])
  ;  cwv = cwv.lambda
  cwv=[mean(cwv.lambda), mean(cwv.lambda)]

  ;error handle if sat spots haven't been found
  tmp = backbone->get_keyword("SATSMASK", ext_num=1, count=ct)
  if ct eq 0 then $
    return, error('FAILURE ('+functionName+'): SATSMASK undefined.  Use "Measure satellite spot locations" before this one.')

  ;;grab satspots
  goodcode = hex2bin(tmp,(dim)[2])
;  good = long(where(goodcode eq 1))
  good=[0,1]
  cens = fltarr(2,4,(dim)[2])
  for s=0,n_elements(good) - 1 do begin
    for j = 0,3 do begin
      tmp = fltarr(2) + !values.f_nan
      reads,backbone->get_keyword('SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2),ext_num=1),tmp,format='(F7," ",F7)'
      cens[*,j,good[s]] = tmp
    endfor
  endfor

  ;;error handle if sat spots haven't been found
  tmp = backbone->get_keyword("SATSWARN", ext_num=1, count=ct)
  if ct eq 0 then $
    return, error('FAILURE ('+functionName+'): SATSWARN undefined.  Use "Measure satellite spot fluxes" before this one.')

  good=[0,1]
  ;;grab sat fluxes
  warns = hex2bin(tmp,n_elements(good))
  satflux = fltarr(4,n_elements(good))
  for s=0,n_elements(good) - 1 do begin
    for j = 0,3 do begin
      satflux[j,s] = backbone->get_keyword('SATF0_'+strtrim(j,2)+hdr_suff,ext_num=1)
;      print,'SATF0_'+strtrim(j,2)+hdr_suff,backbone->get_keyword('SATF0_'+strtrim(j,2)+hdr_suff,ext_num=1) 
    endfor
  endfor
 

  ;;get grid fac
  apodizer = backbone->get_keyword('APODIZER', count=ct)
  if strcmp(apodizer,'UNKNOWN',/fold_case) then begin
    val = backbone->get_keyword('OCCULTER', count=ct)
    if ct ne 0 then begin
      res = stregex(val,'FPM_([A-Za-z])',/extract,/subexpr)
      if res[1] ne '' then apodizer = res[1]
    endif
  endif
  gridfac = gpi_get_gridfac(apodizer)
  if ~finite(gridfac) then return, error('FAILURE ('+functionName+'): Could not match apodizer.')

  ;;get user inputs
  contrsigma = float(Modules[thisModuleIndex].contrsigma)
  slice = fix(Modules[thisModuleIndex].slice)
  doouter = 1 - fix(Modules[thisModuleIndex].DarkHoleOnly)
  wind = fix(Modules[thisModuleIndex].Display)
  radialsave = Modules[thisModuleIndex].SaveProfile
  pngsave = Modules[thisModuleIndex].SavePNG
  contr_yunit = fix(Modules[thisModuleIndex].contr_yunit)
  contr_xunit = fix(Modules[thisModuleIndex].contr_xunit)
  contr_yaxis_type = fix(Modules[thisModuleIndex].contr_yaxis_type)
  contr_yaxis_min=float(Modules[thisModuleIndex].contr_yaxis_min)
  contr_yaxis_max=float(Modules[thisModuleIndex].contr_yaxis_max)
  yscale = fix(Modules[thisModuleIndex].yscale)
  update_prev_fits_header = fix(Modules[thisModuleIndex].update_prev_fits_header)

  ;;we're going to do the copsf for all the slices
  copsf = ctr_cube
  for j = 0, 1 do begin ; Only ever two slices in pol mode
    tmp = where(good eq j,ct)
    if ct eq 1 then copsf[*,*,j] = copsf[*,*,j]/((1./gridfac)*mean(satflux[*,j])) else $
      copsf[*,*,j] = !values.f_nan
  endfor

  ;;set proper scale unit
  if contr_yunit eq 0 then sclunit = contrsigma else sclunit = 1d

  ;Hardcode this for now. Maybe I'll have to change it later
  good=[0,1]
  

  if (wind ne -1) || (radialsave ne '') || (pngsave ne '') then begin
    ;;determine which we are plotting

    if slice eq -1 then inds = good else begin
      inds = slice
      tmp = where(good eq slice,ct)
      if ct eq 0 then $
        return, error('FAILURE ('+functionName+'): SATSPOTS not found for requested slice.')
    endelse

    xrange = [1e12,-1e12]
    yrange = [1e12,-1e12]
    contrprof = ptrarr(n_elements(inds),/alloc)
    asecs = ptrarr(n_elements(inds),/alloc)

    
    ;----- actually measure the contrast here -----
    for j = 0, n_elements(inds)-1 do begin
      ;; get the radial profile desired
      case contr_yunit of
        0: radial_profile_pol,copsf[*,*,inds[j]],cens[*,*,inds[j]],$
          lambda=cwv[inds[j]],asec=asec,isig=outval,$
          /dointerp,doouter = doouter
        1: radial_profile_pol,copsf[*,*,inds[j]],cens[*,*,inds[j]],$
          lambda=cwv[inds[j]],asec=asec,imed=outval,$
          /dointerp,doouter = doouter
;        2: radial_profile,copsf[*,*,inds[j]],(*self.satspots.cens)[*,*,inds[j]],$
        2: radial_profile_pol,copsf[*,*,inds[j]],cense[*,*,inds[j]],$
          lambda=cwv[inds[j]],asec=asec,imn=outval,$
          /dointerp,doouter = doouter
      endcase
      outval *= sclunit
      *contrprof[j] = outval
      if contr_xunit eq 1 then $
        asec *= 1d/3600d*!dpi/180d*gpi_get_constant('primary_diam',default=7.7701d0)/(cwv[inds[j]]*1d-6) ; convert to lambda/D
      *asecs[j] = asec

      xrange[0] = xrange[0] < min(asec,/nan)
      xrange[1] = xrange[1] > max(asec,/nan)
      yrange[0] = yrange[0] < min(outval,/nan)
      yrange[1] = yrange[1] > max(outval,/nan)
    endfor

    ;;------ assess contrast at fiducial radii ------

    fiducial_radii = [0.25, 0.4, 0.8]
    fiducial_contrasts = fltarr(n_elements(fiducial_radii),2) ;One for each pol slice
    fiducial_keywords = [['CONTR25I', 'CONTR40I','CONTR80I'],['CONTR25P', 'CONTR40P','CONTR80P']]


    for r =0,2 do begin
      radius = fiducial_radii[r]
      if contr_xunit eq 1 then $
        radius *= 1d/3600d*!dpi/180d*gpi_get_constant('primary_diam',default=7.7701d0)/(cwv[inds[j]]*1d-6) ; convert to lambda/D
      mindiff = min(abs(asec-radius), /nan, closest_radius_subscript)

      ;Grab the constrast at the right radius
      icontrast_at_radius = (*contrprof[0])[closest_radius_subscript]
      pcostrast_at_radius = (*contrprof[1])[closest_radius_subscript]
      fiducial_contrasts[r,0] = icontrast_at_radius
      fiducial_contrasts[r,1] = pcostrast_at_radius

      backbone->set_keyword,fiducial_keywords[r,0], fiducial_contrasts[r,0],$
        " Median total intensity contrast at "+sigfig(radius,2)+"'' from sat spots", ext_num=1

      backbone->set_keyword,fiducial_keywords[r,1], fiducial_contrasts[r,1],$
        " Median polarized intensity contrast at "+sigfig(radius,2)+"'' from sat spots", ext_num=1

    endfor
    
    if keyword_set(update_prev_fits_header) then begin
      ; update the same fits keyword information into a prior saved version of
      ; this datacube.
      ; this is somewhat inelegant code to repeat all these keywords here, but
      ; it's more efficient in execution time than trying to integrate this header
      ; update into backbone->set_keyword since that would unnecessarily read and
      ; write the file from disk each time, which is no good. -mp
      prevheader = gpi_get_prev_saved_header(status=status)
      if status eq OK then begin
        for r =0,2 do sxaddpar, prevheader, fiducial_keywords[r], fiducial_contrasts[r],$
          " Median (75% band) contrast at "+sigfig(fiducial_radii[r],2)+"'' from sat spots"
        gpi_update_prev_saved_header, prevheader
      endif
    endif


    ;;------ plot ------
    if (wind ne -1) || (pngsave ne '') then begin
      if yscale eq 1 then yrange = [contr_yaxis_min, contr_yaxis_max]
      ;;Tick labels don't appear if yrange less than an order
      ;;of magnitude, so check for that
      if floor(alog10(max(yrange))) eq floor(alog10(min(yrange))) then begin
        ;;As of now no labels will be drawn on Y-axis, so set them by hand
        ytickv = 10.^floor(alog10(min(yrange))) * (findgen(10)+1)
        ytickv = ytickv[where(ytickv ge min(yrange) and ytickv le max(yrange))]
        yticks = n_elements(ytickv)-1
      endif
      ytitle = 'Contrast '
      sigma = '!7r!X'
      case contr_yunit of
        0: ytitle +=  '['+strc(uint(contrsigma))+sigma+' limit]'
        1: ytitle += '[Median]'
        2: ytitle += '[Mean]'
      endcase
      xtitle =  'Angular separation '
      if contr_xunit eq 0 then xtitle += '["]' else $
        xtitle += '['+'!4' + string("153B) + '!X/D]' ;;"just here to keep emacs from flipping out

      if slice ne -1 then color = cgcolor('red') else begin
        color = round(findgen((dim)[2])/$
          ((dim)[2]-1)*200.+10.)
      endelse

      if wind ne -1 then begin
        ;;reuse existing window if possible
        if wind eq 0 then window,/free,xsize=800,ysize=600,retain=2  else select_window,wind,xsize=800,ysize=600,retain=2
      endif else begin
        odevice = !D.NAME
        set_plot,'Z',/copy
        device,set_resolution=[800,600],z_buffer = 0
        erase
      endelse

      plot,[0],[0],ylog=contr_yaxis_type,xrange=xrange,yrange=yrange,/xstyle,/ystyle,$
        xtitle=xtitle,ytitle=ytitle,/nodata, charsize=1.5,background=cgcolor('white'),color = cgcolor('black'),yticks=yticks,ytickv=ytickv, $
        title="Contrast for "+(strsplit(dataset.outputfilenames[numfile],'/',/extract,count=length))[length-1] 
       
;       strsplit(dataset.outputfilenames[numfile], '/') 
;        stop
      ;stop
      ; load in a color table, while saving the original
      tvlct, user_r, user_g, user_b, /get
      loadct, 13
      ; if it's just a single slice, plot it in red
      if N_ELEMENTS(inds) eq 1 then color=cgcolor('red')
      linestyles=[0,2]
      for j = 0, n_elements(inds)-1 do begin
        oplot,*asecs[j],(*contrprof[j])[*,0],color=cgcolor('black'),linestyle=linestyles[j]
        ;oplot,*asecs[j],(*contrprof[j])[*,0],color=color[j],linestyle=0
        ;if doouter then oplot,*asecs[j],(*contrprof[j])[*,1], color=color[j],linestyle=2
        if doouter then oplot,*asecs[j],(*contrprof[j])[*,1],linestyle=2
      endfor
      ; revert to original colors
      tvlct, user_r, user_g, user_b


      ; plot indicators where the contrasts are measured
      plotsym,0,2,/fill,color=cgcolor('red')
      oplot,fiducial_radii,fiducial_contrasts[*,0],psym=8

      ; plot indicators where the contrasts are measured
      plotsym,0,2,/fill,color=cgcolor('blue')
      oplot,fiducial_radii,fiducial_contrasts[*,1],psym=8

      ; put in the labels for contrasts
      label = "Total Intensity contrasts: "
      xyouts, 0.35, 0.9, label, /norm, charsize=1.5, color=cgcolor('red')

      ; put in the labels for contrasts
      label = "Polarized Intensity contrasts: "
      xyouts, 0.65, 0.9, label, /norm, charsize=1.5, color=cgcolor('blue')

      for r=0,2 do begin
        label = sigfig(fiducial_contrasts[r,0],2,/sci)+" at "+sigfig(fiducial_radii[r],2)+'"'
        xyouts, 0.4, 0.9-0.04*(r+1), label, /norm, charsize=1.5, color=cgcolor('red')
      endfor
      
      for r=0,2 do begin
        label = sigfig(fiducial_contrasts[r,1],2,/sci)+" at "+sigfig(fiducial_radii[r],2)+'"'
        xyouts, 0.7, 0.9-0.04*(r+1), label, /norm, charsize=1.5, color=cgcolor('blue')
      endfor

      if pngsave ne '' then begin
        ;;if user set AUTO then synthesize entire path
        if strcmp(strupcase(pngsave),'AUTO') then begin
          s_OutputDir = Modules[thisModuleIndex].OutputDir
          s_OutputDir = gpi_expand_path(s_OutputDir)
          if strc(s_OutputDir) eq "" then return, error('FAILURE: supplied output directory is a blank string.')
          s_OutputDir = s_OutputDir+path_sep()+'contrast'+path_sep()

          if ~file_test(s_OutputDir,/directory, /write) then begin
            if gpi_get_setting('prompt_user_for_outputdir_creation',/bool, default=0,/silent) then $
              res =  dialog_message('The requested output directory '+s_OutputDir+' does not exist. Should it be created now?', $
              title="Nonexistent Output Directory", /question) else res='Yes'

            if res eq 'Yes' then  file_mkdir, s_OutputDir

            if ~file_test(s_OutputDir,/directory, /write) then $
              return, error("FAILURE: Directory "+s_OutputDir+" does not exist or is not writeable.",/alert)
          endif
          pngsave = s_OutputDir
        endif

        ;;if this is a directory, then you want to save to it with the
        ;;default naming convention
        if file_test(pngsave,/dir) then begin
          nm = gpi_expand_path(DataSet.filenames[numfile])
          strps = strpos(nm,path_sep(),/reverse_search)
          strpe = strpos(nm,'.fits',/reverse_search)
          nm = strmid(nm,strps+1,strpe-strps-1)
          nm = gpi_expand_path(pngsave+path_sep()+nm+'_contrast_profile.png')
        endif else nm = pngsave

        if wind eq -1 then begin
          snapshot = tvrd()
          tvlct,r,g,b,/get
          write_png,nm,snapshot,r,g,b
          device,z_buffer = 1
          set_plot,odevice
        endif else write_png,nm,tvrd(true=1)
      endif
    endif

    ;;save radial contrast as fits
    if radialsave ne '' then begin
      ;;if user set AUTO then synthesize entire path
      if strcmp(strupcase(radialsave),'AUTO') then begin
        s_OutputDir = Modules[thisModuleIndex].OutputDir
        s_OutputDir = gpi_expand_path(s_OutputDir)
        if strc(s_OutputDir) eq "" then return, error('FAILURE: supplied output directory is a blank string.')
        s_OutputDir = s_OutputDir+path_sep()+'contrast'+path_sep()

        if ~file_test(s_OutputDir,/directory, /write) then begin
          if gpi_get_setting('prompt_user_for_outputdir_creation',/bool, default=0,/silent) then $
            res =  dialog_message('The requested output directory '+s_OutputDir+' does not exist. Should it be created now?', $
            title="Nonexistent Output Directory", /question) else res='Yes'

          if res eq 'Yes' then  file_mkdir, s_OutputDir

          if ~file_test(s_OutputDir,/directory, /write) then $
            return, error("FAILURE: Directory "+s_OutputDir+" does not exist or is not writeable.",/alert)
        endif
        radialsave = s_OutputDir
      endif

      ;;if this is a directory, then you want to save to it with the
      ;;default naming convention
      if file_test(radialsave,/dir) then begin
        nm = gpi_expand_path(DataSet.filenames[numfile])
        strps = strpos(nm,path_sep(),/reverse_search)
        strpe = strpos(nm,'.fits',/reverse_search)
        nm = strmid(nm,strps+1,strpe-strps-1)
        nm = gpi_expand_path(radialsave+path_sep()+nm+'_contrast_profile.fits')
      endif else nm = radialsave

      out = dblarr(n_elements(*asecs[n_elements(inds[0])-1]), n_elements(inds)+1)+!values.d_nan
      out[*,0] = *asecs[n_elements(inds[0])-1]
      for j=0,n_elements(inds)-1 do $
        out[where((*asecs[j]) eq (*asecs[j])[0]):n_elements(*asecs[j])-1,j+1] = $
        (*contrprof[j])[*,0]

      tmp = intarr((dim)[2])
      tmp[inds] = 1
      slices = string(strtrim(tmp,2),format='('+strtrim(n_elements(tmp),2)+'(A))')

      mkhdr,hdr,out
      sxaddpar,hdr,'SLICES',slices,'Cube slices used.'
      sxaddpar,hdr,'YUNITS',(['Std Dev','Median','Mean'])[contr_yunit],'Contrast units'

      writefits,nm,out,hdr
    endif

  endif

  *(dataset.currframe)=cube

  @__end_primitive


end
