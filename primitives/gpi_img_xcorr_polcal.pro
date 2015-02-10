;+
; NAME: gpi_img_xcorr_pol.pro
; PIPELINE PRIMITIVE DESCRIPTION: Flexure 2D x correlation with polcal
;
;   This primitive uses the relevent microlense PSF and pol cal to generate a model detector image to cross correlate with a science image.
;   The resulting output can be used as a flexure offset prior to flux extraction.
;
; INPUTS: Science image, polcal
;
; OUTPUTS: Flexure offset in xy detector coordinates.
;
; PIPELINE COMMENT: This primitive uses the relevent pol cal file to generate a model detector image to cross correlate with a science image and find the flexure offset.
;   The resulting output can be used as a flexure offset prior to flux extraction.
;
; PIPELINE ARGUMENT: Name="range" Type="float" Default="0.3" Range="[0,5]" Desc="Range of cross corrleation search in pixels."
; PIPELINE ARGUMENT: Name="resolution" Type="float" Default="0.1" Range="[0,1]" Desc="Subpixel resolution of cross correlation"
; PIPELINE ARGUMENT: Name="psf_sep" Type="float" Default="0.1" Range="[0,1]" Desc="PSF separation in pixels"
; PIPELINE ARGUMENT: Name="stopidl" Type="int" Range="[0,1]" Default="0" Desc="1: stop IDL, 0: dont stop IDL"
; PIPELINE ARGUMENT: Name="configuration" Type="string" Range="[tight|wide]" Default="tight" Desc="tight=only spots near the psf center, wide=across the field"
; PIPELINE ARGUMENT: Name="x_off" Type="float" Default="0" Range="[-5,5]" Desc="initial guess for large offsets"
; PIPELINE ARGUMENT: Name="y_off" Type="float" Default="0" Range="[-5,5]" Desc="initial guess for large offsets"
; PIPELINE ARGUMENT: Name="badpix" Type="float" Default="1" Range="[0,1]" Desc="Weight by bad pixel map?"
; PIPELINE ARGUMENT: Name="iterate" Type="int" Default="1" Range="[0,1]" Desc="Take the first result? Or iterate"
; PIPELINE ARGUMENT: Name="max_iter" Type='int' Default="15" Range="[1,100]" Desc="The maximum number of iterations"
; PIPELINE ARGUMENT: Name="manual_dx" Type='float' Default="0." Range="[-1,100]" Desc="A pixel shift value. If this is set then no cross-correlation is performed."
; PIPELINE ARGUMENT: Name="manual_dy" Type='float' Default="0." Range="[-1,100]" Desc="A pixel shift value. If this is set then no cross-correlation is performed."
;
; where in the order of the primitives should this go by default?
; PIPELINE ORDER: 1.34
;
; pick one of the following options for the primitive type:
; PIPELINE NEWTYPE: PolarimetricScience
;
; HISTORY:
;    Began 2014-01-13 by Zachary Draper
;          2014-09-12 MMB: Branched to a version that cross correlates with the polcal file rather than use the microlens
;-

;-----------------------------
;

function gpi_img_xcorr_polcal, DataSet, Modules, Backbone

  ; enforce modern IDL compiler options:
  compile_opt defint32, strictarr, logical_predicate

  ; don't edit the following line, it will be automatically updated by subversion:
  primitive_version= '$Id: gpi_img_xcorr.pro 2878 2014-04-29 04:11:51Z mperrin $' ; get version from subversion to store in header history

    ;calfiletype='polcal'   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

    @__start_primitive
  suffix=''      ; set this to the desired output filename suffix
  
  
  ;Get the polcal files
  polspot_params=polcal.spotpos
  polspot_coords=polcal.coords
  polspot_pixvals=polcal.pixvals
 

  ;Get the primitive keywords
  if tag_exist(Modules[thisModuleIndex],"range") then range=float(Modules[thisModuleIndex].range) else range=2.0
  if tag_exist(Modules[thisModuleIndex],"resolution") then resolution=float(Modules[thisModuleIndex].resolution) else resolution=0.01
  if tag_exist(Modules[thisModuleIndex],"configuration") then config=Modules[thisModuleIndex].configuration else config='tight'
  if tag_exist(Modules[thisModuleIndex],"psf_sep") then steps=float(Modules[thisModuleIndex].psf_sep) else steps=0.01
  if tag_exist(Modules[thisModuleIndex],"stopidl") then stopidl=long(Modules[thisModuleIndex].stopidl) else save=0
  if tag_exist(Modules[thisModuleIndex],"x_off") then x_off=float(Modules[thisModuleIndex].x_off) else x_off=0
  if tag_exist(Modules[thisModuleIndex],"y_off") then y_off=float(Modules[thisModuleIndex].y_off) else y_off=0
  if tag_exist(Modules[thisModuleIndex],"iterate") then iterate=float(Modules[thisModuleIndex].iterate) else iterate=0
  if tag_exist(Modules[thisModuleIndex],"max_iter") then max_iter=float(Modules[thisModuleIndex].max_iter) else max_iter=15
  if tag_exist(Modules[thisModuleIndex], "manual_dx") then manual_dx=float(Modules[thisModuleIndex].manual_dx) else manual_dx=0
  if tag_exist(Modules[thisModuleIndex], "manual_dy") then manual_dy=float(Modules[thisModuleIndex].manual_dy) else manual_dy=0.


  ;If the manual keywords are set then don't do any cross correlation
  if manual_dx ne 0 or manual_dy ne 0 then begin
    x_off=manual_dx
    y_off=manual_dy
    
    backbone->Log, "Flexure offset manually set to to be; X: "+string(x_off)+" Y: "+string(y_off)
    backbone->set_keyword, 'SPOT_DX', x_off, ' PSFX shift set manually'
    backbone->set_keyword, 'SPOT_DY', y_off, ' PSFY shift set manually'
  endif else begin



    ;Get the current image
    img = *dataset.currframe

    ;define the common wavelength vector with the IFSFILT keyword:
    filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
    if (filter eq '') then return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.')

    ;run badpixel suppresion
    if tag_exist(Modules[thisModuleIndex],"badpix") then $
      badpix=float(Modules[thisModuleIndex].badpix) else badpix=0

    if (badpix eq 1) then begin
      badpix_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header('badpix',*(dataset.headersphu)[numfile],*(dataset.headersext)[numfile])
      badpix = gpi_READFITS(badpix_file)
      ones = bytarr(2048,2048)+1
      badpix = ones-badpix
      ;supress all bad pixels
      img=img*badpix
    endif

    ;;error handle if readpolcal or not used before
    if ~(keyword_set(polcal.coords)) then return, error("You must use Load Polarization Calibration before Assemble Polarization Cube")
    if (size(img))[0] gt 2 then return, error("You must cross-correlate with a raw detector image. This is not a raw detector image.")

    ;free optimization knobs
    xwidth=10     ;spectra sub image size
    ywidth=16      ; extracted for lsqr

    ;Choose either tight or wide configuration
    if strlowcase(config) eq 'tight' then begin
      lensx=[120,130,140,120,130,140,120,130,140]
      lensy=[120,120,120,130,130,130,140,140,140]
    endif else if strlowcase(config) eq 'wide' then begin
      backbone->Log, "The wide configuration isn't working very well right now, so we're going to do 'tight' anyway"
      lensx=[120,130,140,120,130,140,120,130,140]
      lensy=[120,120,120,130,130,130,140,140,140]

      ;The actual wi
      ;    lensx=[100,150,200,85,130,185,230,60,100,175,190,60, 100,150,180]
      ;    lensy=[30,50,70,100,85,100,125,140,150,175,200,210,180,200,230,240]
    endif else return, error("You must choose either tight or wide configurations")


    nlens=n_elements(lensx)

    ; blank2 = fltarr(xsize,ysize)

    ;get filter wavelength range
    cwv=get_cwv(filter)
    gpi_lambda=cwv.lambda
    para=cwv.CommonWavVect

    wcal_off = [0,0,0,0,0]
    del_lam_best=0
    del_x_best=0
    del_theta_best=0

    ;extract stellar spectra in order to match shape of microspectra
    ; add more extractions to make an average? tune to lenslet at satellite spots or edge of choronograph?

    ;This code is no longer needed
    ;exe_tst = execute("resolve_routine,'gpi_lsqr_mlens_extract_pol_dep',/COMPILE_FULL_FILE")

    n=0
    b=0
    a=0
    xsft=resolution
    xsft_sav=xsft
    ysft=resolution
    range_start=range
    stddev_mem=[0]
    y_off_mem=[0]
    flux_mem=[0]

    polspot_params=polcal.spotpos
    polspot_coords=polcal.coords
    polspot_pixvals=polcal.pixvals
    ;stop

    img_reform=fltarr(xwidth*nlens,ywidth)

    ;The x,y locations of the peaks
    spotx=fltarr(nlens)
    spoty=fltarr(nlens)

    ;Some offsets for where to put the box
    xlow=4
    xhigh=5
    ylow=11
    yhigh=4

    for z=0,nlens-1 do begin
      ;Get the coordinate of the first lens
      ix=lensx[z]
      iy=lensy[z]

      spotx = floor(polspot_params[0, ix, iy, 0])
      spoty = floor(polspot_params[1, ix, iy, 0])

      img_reform[z*xwidth:(z+1)*xwidth-1,*]=img[spotx-xlow:spotx+xhigh,spoty-ylow:spoty+yhigh]/total(img[spotx-xlow:spotx+xhigh,spoty-ylow:spoty+yhigh])

    endfor

    ;  atv, img_reform, /block

    ;Some matrix and index setup
    model_reform=fltarr(xwidth*nlens,ywidth)
    tmpbox=fltarr(xwidth,ywidth)
    indices, tmpbox, xx, yy

    nit=0 ; Number of iterations

    while (abs(ysft) gt (resolution/2)) or (abs(xsft) gt (resolution/2)) do begin

      if nit gt max_iter then begin
        backbone->Log, "Flexure cross correlation failed after "+string(nit)+" iterations. Resetting offset to 0"
        backbone->Log, "Try setting the inital guess parameters x_off and y_ff"
        xoff=0
        yoff=0
        break
      endif

      model_reform *= 0

      for z=0,nlens-1 do begin
        tmpbox *= 0

        ix=lensx[z]
        iy=lensy[z]

        spot1x = floor(polspot_params[0, ix, iy, 0])
        spot1y = floor(polspot_params[1, ix, iy, 0])

        for pol=0,1 do begin
          params=polspot_params[*, ix, iy, pol]
          fact = .35 ; factor for scaling gaussian width (?!) ;This was copied from assemble pol cube. Who put this there? Me (Max)? Mike?
          p = [0, 1., params[3]*fact, params[4]*fact, x_off+xlow+params[0]-spot1x, y_off+ylow+params[1]-spot1y, params[2]*!dtor]
          ;stop
          tmpbox +=mpfit2dpeak_gauss(xx,yy,p,/tilt)
        endfor


        model_reform[z*xwidth:(z+1)*xwidth-1,*]=tmpbox/total(tmpbox)

      endfor
      dummy=[[model_reform],[img_reform]]

      ;atv, model_reform,/block

      model_save = model_reform
      gpi_twod_img_corr, model_reform, img_reform,range,resolution,xsft,ysft,corr

      print,xsft,ysft

      x_off=x_off-xsft
      y_off=y_off-ysft

      print,x_off,y_off

      ;    range=min([range_start,max(abs([ysft,xsft]))])
      ;    range=max([range,7*resolution])
      ;    ;range=range_start

      ;;window,1
      ;imdisp,corr,/axis
      ;window,2
      ;imdisp,mdl_full,/axis
      ;window,3
      ;imdisp,sub_full-(total(sub_full)/total(mdl_full))*mdl_full
      ;print,sdev
      ;print,total(spec_flx_all)

      ;tstimg=fltarr(3*xsize,ysize)
      ;data = sub_mdl_img[*,*,1]*(total(sub_mdl_img[*,*,0])/total(sub_mdl_img[*,*,1]))
      ;tstimg[0:xsize-1,0:ysize-1] = data
      ;model = sub_mdl_img[*,*,0]
      ;tstimg[xsize:(2*xsize)-1,0:ysize-1] = model
      ;residual = sub_mdl_img[*,*,1]-(total(sub_mdl_img[*,*,1])/total(sub_mdl_img[*,*,0]))*sub_mdl_img[*,*,0]
      ;tstimg[(2*xsize):(3*xsize)-1,0:ysize-1] = residual
      ;imdisp,tstimg,/axis

      ;cgimage, residual, /keep_aspect_ratio, /axis
      ;cgColorbar,/fit, /vertical, position=[0.10, 0.90, 0.90, 0.91]

      ;    stop
      nit++
      if ~iterate then break

    endwhile
    backbone->Log, "Flexure offset determined to be; X: "+string(x_off)+" Y: "+string(y_off)
    backbone->set_keyword, 'SPOT_DX', x_off, ' PSFX shift determined by cross correlation with polcal'
    backbone->set_keyword, 'SPOT_DY', y_off, ' PSFY shift determined by cross correlation with polcal'

  endelse

  ;atv, dummy,/block
  ;  backbone->set_keyword,'HISTORY',functionname+ " Flexure determined by 2D xcorrelation with wavecal"
  ;fxaddpar not working to add keyword ??
  ;backbone->set_keyword,'FLEXURE_X',xsft
  ;backbone->set_keyword,'FLEXURE_Y',ysft

  ;itime = backbone->get_keyword('ITIME')

  polspot_coords[0,*,*,*,*]+=x_off
  polspot_coords[1,*,*,*,*]+=y_off
  polspot_params[0,*,*,*]+=x_off
  polspot_params[1,*,*,*]+=y_off

  polcal.coords = polspot_coords
  polcal.spotpos = polspot_params

  

  @__end_primitive

end
