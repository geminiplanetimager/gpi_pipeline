;+
; NAME: subtract_mean_stellar_polarization.pro
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Mean Stellar Polarization
;
;		Subtract an estimate of the stellar polarization, measured from
;		the mean polarization inside the occulting spot radius.
;
;		This primitive is simple, but has not been extensively tested.
;		Under what circumstances, if any, it is useful on GPI data in practice
;		is still TBD.
;
;
; INPUTS: Coronagraphic mode Stokes Datacube
;
; OUTPUTS: That datacube with an estimated stellar polarization subtracted off.
;
; PIPELINE COMMENT: This description of the processing or calculation will show up in the Recipe Editor GUI. This is an example template for creating new primitives. It multiples any input cube by a constant value.
; PIPELINE ARGUMENT: Name="Method" Type="String" Range="Auto|Manual" Default="Auto" Desc="Choose where to meausre the inst_pol. Auto = within the FPM"
; PIPELINE ARGUMENT: Name="InnerRadius" Type="float" Range="[-1,140]" Default="-1" Desc="The inner radius in pix for measuring the mean polarization. -1 = the radius of the FPM."
; PIPELINE ARGUMENT: Name="OuterRadius" Type="float" Range="[-1,140]" Default="20" Desc="The outer radius in pix for measuring the mean polarization. -1 = the radius of the FPM."
; PIPELINE ARGUMENT: Name="Fraction" Type="float" Range="[0,1]" Default="1" Desc="The fraction of the measured mean polarization applied"
; PIPELINE ARGUMENT: Name="WriteToFile" Type="int" Range="[0,1]" Default="0" Desc="1: Write the difference to a file, 0: Dont"
; PIPELINE ARGUMENT: Name="Filename" Type="string" Default="Stellar_Pol_Stokes.txt" Desc="The filename where you write out the stellar polarization"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
; PIPELINE ORDER: 4.3
;
; PIPELINE CATEGORY: PolarimetricScience
;
; HISTORY:
;    2014-03-23 MP: Started
;    2015-02-05 LWH: Added more parameters
;    2015-12-20 MMB: Merged with podc version.
;-

function gpi_subtract_mean_stellar_polarization, DataSet, Modules, Backbone
  compile_opt defint32, strictarr, logical_predicate

  primitive_version= '$Id$' ; get version from subversion to store in header history


    @__start_primitive

  ; set this to the desired output filename suffix
  if fix(Modules[thisModuleIndex].save) eq 1 then suffix='ipsub'

  ;Get the filter and the focal plane mask diameter
  ifsfilt = backbone->get_keyword('IFSFILT',/simplify)
  ; size of occulting masks in milliarcsec
  case ifsfilt of
    'Y': fpm_diam = 156
    'J': fpm_diam = 184
    'H': fpm_diam = 246
    'K1': fpm_diam = 306
    'K2': fpm_diam = 306
  endcase
  fpm_diam *= 1./1000 /gpi_get_constant('ifs_lenslet_scale')      ; in pixels
  fpm_rad=fpm_diam/2                                              ; in pixels

  ; Set the inner and outer radius for the measurement of the mean polarization
  if strcmp(string(Modules[thisModuleIndex].Method),"Auto",4) then begin
    inner=0
    outer=fpm_rad
  endif else begin
    inner=float(Modules[thisModuleIndex].InnerRadius)
    outer=float(Modules[thisModuleIndex].OuterRadius)
  endelse

  ;;Check for special situations
  if inner eq -1 then begin
    if outer le fpm_rad then begin
      print, "Your inner and outer radii are incompatible. Measuring the instrumental polarization within the whole fpm."
      inner = 0
      outer = fpm_rad
    endif else inner = fpm_rad
  endif

  if outer eq 0 then outer = fpm_rad

  if outer lt inner then begin
    print, "Your inner and outer radii are incompatible. Measuring the instrumental polarization within the whole fpm."
    inner=0
    outer=fpm_rad
  endif
  ; Check for the validity of the input boundries
  if outer le inner then begin
    print, "Your inner and outer radii are incompatible. Measuring the instrumental polarization within the whole fpm."
    inner = 0
    outer = fpm_rad
  endif
  ;;Done Checking for special situations

  data_type = backbone->get_keyword('CTYPE3', count=ct1, indexFrame=indexFrame)
  
  if data_type ne "STOKES" then begin
    backbone->Log, "ERROR: That's not a polarimetry file, can't subtract polarization from it!"
    return, not_ok  
  endif
  
  naxis3 = backbone->get_keyword('NAXIS3', indexFrame=indexFrame)
  
  fraction=float(Modules[thisModuleIndex].Fraction)

  case naxis3 of
    4: begin
      centerx = backbone->get_keyword('PSFCENTX', count=ct1, indexFrame=indexFrame)
      centery = backbone->get_keyword('PSFCENTY', count=ct2, indexFrame=indexFrame)
      center = [centerx, centery]
      
      sz = size(*dataset.currframe)
      indices, (*dataset.currframe)[*,*,0], center=center,r=r

      if ct1+ct2 ne 2 then $
        return, error('FAILURE ('+functionName+'): Star Position Not Found in file'+string(j));+string(*(dataset.frames[j])))
      
      ; Set up some data arrays
      totalint = (*dataset.currframe)[*,*,0]
      q_div_i = (*dataset.currframe)[*,*,1]/totalint
      u_div_i = (*dataset.currframe)[*,*,2]/totalint
      v_div_i = (*dataset.currframe)[*,*,3]/totalint

      wfpm = where(r lt outer and r ge inner and finite(totalint) and finite(q_div_i) and finite(u_div_i) and finite(v_div_i), ct)

      print, "Using ",ct, "pixels"
;      mean_q = mean(q_div_i[wfpm],/nan)
;      mean_u = mean(u_div_i[wfpm],/nan)
;      mean_v = mean(v_div_i[wfpm],/nan)
      
      meanclip, q_div_i[wfpm], mean_q, stddev
      meanclip, u_div_i[wfpm], mean_u, stddev
      meanclip, v_div_i[wfpm], mean_v, stddev

      
      
      modified_cube = *dataset.currframe
      
      modified_cube[*,*,1] -= totalint * mean_q * fraction
      modified_cube[*,*,2] -= totalint * mean_u * fraction
      modified_cube[*,*,3] -= totalint * mean_v * fraction
      
      ; Write to file
      if uint(Modules[thisModuleIndex].WriteToFile) eq 1 then begin
        openw, lun, Modules[thisModuleIndex].Filename, /get_lun, /append, width=200
        printf, lun, string(dataset.filenames[numfile]), mean_q, mean_u, mean_v, fraction, inner, outer
        close, lun
        free_lun, lun
      endif
      
      *dataset.currframe = modified_cube
      
      backbone->set_keyword,'HISTORY',functionname+ "Measured" + strcompress(round(sqrt(mean_u^2+mean_q^2)*100)) + "% polarization from pixels between" + strcompress(floor(inner)) + " and" + strcompress(floor(outer))+" pixels from the center"   
      backbone->set_keyword,'HISTORY',functionname+ "Subtracting" + strcompress(round(fraction*100)) + "% of the estimated mean apparent stellar polarization"
      backbone->set_keyword,'STELLARQ', mean_q, "Estimated apparent stellar Q/I over the region of interest (default: behind FPM)", ext_num=1
      backbone->set_keyword,'STELLARU', mean_u, "Estimated apparent stellar U/I over the region of interest (default: behind FPM)", ext_num=1
      backbone->set_keyword,'STELLARV', mean_v, "Estimated apparent stellar V/I over the region of interest (default: behind FPM)", ext_num=1

    end
    2: begin
      reduction_level = backbone->get_current_reduction_level()

      case reduction_level of
        1: begin ;----------Subtract polarization from one single file-----------
          centerx = backbone->get_keyword('PSFCENTX', count=ct1, indexFrame=indexFrame)
          centery = backbone->get_keyword('PSFCENTY', count=ct2, indexFrame=indexFrame)
          center = [centerx, centery]
          
          sz = size(*dataset.currframe)
          indices, (*dataset.currframe)[*,*,0], center=center,r=r

          if ct1+ct2 ne 2 then $
            return, error('FAILURE ('+functionName+'): Star Position Not Found in file'+string(*(dataset.filenames[0])))

          pa = backbone->get_keyword('AVPARANG', indexFrame=indexFrame, count=ct);Set up some data arrays
          if ct lt 1 then $
            return, error('FAILURE ('+functionName+'): Parallactic Angle Not Found in file'+string(i))

          indices, (*dataset.currframe)[*,*,0], center=center,r=r
          wfpm = where(r lt outer and r gt inner, ct) ;Where to measure the polatization
          print, string(ct)+" pixels used to measure stellar polarization"

          ;Set up some data arrays
          sz = size(*dataset.currframe)
          polstack = fltarr(sz[1], sz[2], sz[3])
          sumstack = fltarr(sz[1], sz[2]) ; a transformed version of polstack, holding the sum and single-difference images
          diffstack = fltarr(sz[1],sz[2])
          polstack[*,*,*] = (*dataset.currframe)[*,*,*]
          sumstack[0,0] = polstack[*,*,0] + polstack[*,*,1]
          diffstack[0,0] = polstack[*,*,0] - polstack[*,*,1]

          ;The the mean normalized difference inside the FPM
          meanclip, diffstack[wfpm]/sumstack[wfpm], mn, stddev
          mean_stellar_diff=mn

          diffstack -= sumstack*mean_stellar_diff*fraction

          modified_podc = *dataset.currframe

          modified_podc[*,*,0] = (sumstack+diffstack)/2
          modified_podc[*,*,1] = (sumstack-diffstack)/2

          if uint(Modules[thisModuleIndex].WriteToFile) eq 1 then begin
            wpangle = backbone->get_keyword('WPANGLE', count=ct1, indexFrame=indexFrame)
            object_nm = "   "+backbone -> get_keyword('OBJECT', count=ct2, indexFrame=indexFrame)
            openw, lun, Modules[thisModuleIndex].Filename, /get_lun, /append, width=200
            ;    printf, lun, "#Inner Radius: "+strcompress(inner)
            ;    printf, lun, "#Outer Radius: "+strcompress(outer)
            ;    printf, lun, "#Filename  p_frac  wpangle PA"
            printf, lun, string(dataset.filenames[i]), string(object_nm),mean_stellar_diff, wpangle, stddev,pa, inner, outer
            ;        printf, lun, string(dataset.filenames[numfile]), mean_stellar_diff, wpangle,pa, inner, outer
            close, lun
            free_lun, lun
          endif

          
          backbone->set_keyword,'HISTORY',functionname+ " Subtracting estimated mean apparent stellar polarization from pixels that are between "+strcompress(floor(inner))+" and "+strcompress(floor(outer))+" pixels from the center"
          backbone->set_keyword,'FRACPOL', mean_stellar_diff, " The measured mean stellar normalized difference "
          
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

            pa=sxpar(hdrext, 'AVPARANG', count=ct)
            if ct lt 1 then $
              return, error('FAILURE ('+functionName+'): Parallactic Angle Not Found in file'+string(i))

            ;Set up some data arrays
            sz = size(original_cube)
            polstack = fltarr(sz[1], sz[2], sz[3])
            sumstack = fltarr(sz[1], sz[2]) ; a transformed version of polstack, holding the sum and single-difference images
            diffstack = fltarr(sz[1],sz[2])
            polstack[*,*,*]=original_cube

            sumstack[0,0] = polstack[*,*,0] + polstack[*,*,1]
            diffstack[0,0] = polstack[*,*,0] - polstack[*,*,1]

            indices, (*dataset.currframe)[*,*,0], center=center,r=r
            wfpm = where(r lt outer and r gt inner, ct);Where to measure the polatization
            print, string(ct)+" pixels used to measure stellar polarization"

            ;The the mean normalized difference inside the FPM
            meanclip, diffstack[wfpm]/sumstack[wfpm], mn, stddev
            mean_stellar_diff=mn

            diffstack -= sumstack*mean_stellar_diff*fraction

            modified_podc = original_cube

            modified_podc[*,*,0] = (sumstack+diffstack)/2
            modified_podc[*,*,1] = (sumstack-diffstack)/2
            
            sxaddpar, hdr, 'HISTORY',functionname+ " Subtracting estimated mean apparent stellar polarization from pixels that are between "+strcompress(floor(inner))+" and "+strcompress(floor(outer))+" pixels from the center"
            sxaddpar, hdrext, 'FRACPOL', mean_stellar_diff, " The measured mean stellar normalized difference "

            accumulate_updateimage, dataset, i, newdata = modified_podc,newhdr=hdr, newexthdr=hdrext

            if uint(Modules[thisModuleIndex].WriteToFile) eq 1 then begin
              ;          wpangle=backbone->get_keyword('WPANGLE', count=ct1, indexFrame=indexFrame)
              wpangle = sxpar(hdr, 'WPANGLE')
              object_nm = "   "+backbone -> get_keyword('OBJECT', count=ct2, indexFrame=indexFrame)
              openw, lun, Modules[thisModuleIndex].Filename, /get_lun, /append, width=200
              ;    printf, lun, "#Inner Radius: "+strcompress(inner)
              ;    printf, lun, "#Outer Radius: "+strcompress(outer)
              ;    printf, lun, "#Filename  p_frac  wpangle PA"
              printf, lun, string(dataset.filenames[i]), string(object_nm),mean_stellar_diff, wpangle, stddev,pa, inner, outer
              ;          printf, lun, string(dataset.filenames[numfile]), string(object_nm), mean_stellar_diff, wpangle,pa, inner, outer
              close, lun
              free_lun, lun
            endif
            
           
          endfor
          
          *dataset.currframe = modified_podc
        end
      endcase
           
    end

    else: begin
      backbone->Log, "ERROR: That's not a polarimetry file, can't subtract polarization from it!"
      return, not_ok 
    end
  endcase

  

  @__end_primitive

end
