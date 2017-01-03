;+
; NAME: subtract_median_background_polarization.pro
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Median Background Polarization from podc
;
;   Subtract an estimate of the median background polarization,
;   measured as the median difference across the frame
;
; INPUTS: Coronagraphic mode polarization datacube
;
; OUTPUTS: That datacube with an estimated background polarization subtracted off.
;
; PIPELINE COMMENT: This description of the processing or calculation will show ; up in the Recipe Editor GUI. This is an example template for creating new ; primitives. It multiples any input cube by a constant value.
; PIPELINE ARGUMENT: Name="InnerRadius" Type="float" Range="[-1,140]" Default="-1" Desc="The inner radius where you start to measure the instrumental polarization. -1 = the size of the FPM"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
; PIPELINE ORDER: 3.85
;
; PIPELINE CATEGORY: PolarimetricScience
;
; HISTORY:
;    2016-10-07 MMB: Started (cut apart gpi subtract mean stellar polarization)
;-

function subtract_median_background_polarization, DataSet, Modules, Backbone
  compile_opt defint32, strictarr, logical_predicate

  primitive_version= '$Id: gpi_subtract_mean_stellar_polarization.pro 2878 2014-04-29 04:11:51Z mperrin $' ; get version from subversion to store in header history


    @__start_primitive
  if fix(Modules[thisModuleIndex].save) eq 1 then suffix='podc_subbkg'      ; set this to the desired output filename suffix

  sz=size(*dataset.currframe)

  if sz[1] eq 2048 then return, error('Can only apply filter to cubes, not detector images')

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
  ;Check for special situations
  if inner eq -1 then begin
    inner = fpm_rad
  endif

  reduction_level = backbone->get_current_reduction_level()

  case reduction_level of
    1: begin ;----------Subtract polarization from one single file-----------
      centerx = backbone->get_keyword('PSFCENTX', count=ct1, indexFrame=indexFrame)
      centery = backbone->get_keyword('PSFCENTY', count=ct2, indexFrame=indexFrame)
      center = [centerx, centery]

      if ct1+ct2 ne 2 then $
        return, error('FAILURE ('+functionName+'): Star Position Not Found in file'+string(*(dataset.filenames[0])))

      indices, (*dataset.currframe)[*,*,0], center=center,r=r
      wnfpm = where(r gt inner, ct) ;Where to measure the polatization (where not focal plane mask)

      ;Set up some data arrays
      sz = size(*dataset.currframe)
      polstack = fltarr(sz[1], sz[2], sz[3])
      diffstack = fltarr(sz[1],sz[2])
      sumstack = fltarr(sz[1], sz[2])
      polstack[*,*,*] = (*dataset.currframe)[*,*,*]
      sumstack[0,0] = polstack[*,*,0] + polstack[*,*,1]
      diffstack[0,0] = polstack[*,*,0] - polstack[*,*,1]

      ;The the median difference outside the FPM
      median_diff = median(diffstack[wnfpm])

      diffstack -= median_diff

      modified_podc = *dataset.currframe

      modified_podc[*,*,0] = (sumstack+diffstack)/2
      modified_podc[*,*,1] = (sumstack-diffstack)/2

      *dataset.currframe = modified_podc

    end
    2: begin

      nfiles=dataset.validframecount
      for i=0,nfiles-1 do begin


        original_cube=accumulate_getimage(dataset,i,hdr,hdrext=hdrext)
        hdrext0 = hdrext

        ;Get the Center coordinates
        centerx = sxpar(hdrext0,'PSFCENTX', count=ct1)
        centery = sxpar(hdrext0,'PSFCENTY', count=ct2)
        center = [centerx, centery]
        
        if ct1+ct2 ne 2 then $
          return, error('FAILURE ('+functionName+'): Star Position Not Found in file'+string(i))

        ;Set up some data arrays
        sz = size(original_cube)
        polstack = fltarr(sz[1], sz[2], sz[3])
        diffstack = fltarr(sz[1],sz[2])
        sumstack = fltarr(sz[1], sz[2])
        polstack[*,*,*]=original_cube
        sumstack[0,0] = polstack[*,*,0] + polstack[*,*,1]
        diffstack[0,0] = polstack[*,*,0] - polstack[*,*,1]

        indices, (*dataset.currframe)[*,*,0], center=center,r=r
        wnfpm = where(r gt inner, ct);Where to measure the polatization (where not focal plane mask)
        
        ;The the median difference outside the FPM
        median_diff = median(diffstack[wnfpm])

        diffstack -= median_diff

        modified_podc = original_cube

        modified_podc[*,*,0] = (sumstack+diffstack)/2
        modified_podc[*,*,1] = (sumstack-diffstack)/2

        accumulate_updateimage, dataset, i, newdata = modified_podc

      endfor
    end
  endcase

  backbone->set_keyword,'HISTORY',functionname+ " Subtracting background polarization from pixels outside of "+strcompress(floor(inner))+" pixels from the center"
  backbone->set_keyword,'HISTORY', functionname+" The measured background lvl is:"+strcompress(median_diff)+" in ADU/coadd"

  @__end_primitive

end
