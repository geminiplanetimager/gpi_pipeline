;+
; NAME: destripe_mask_spectra_micro
; PIPELINE PRIMITIVE DESCRIPTION: Destripe science frame micro
;
;  
;  Subtract horizontal striping from the background of a 2d
;  raw IFS image by masking spectra and using the remaining regions to obtain a
;  sampling of the striping. 
;
;  The masking can be performed by using the wavelength calibration to mask the
;  spectra (recommended) or by thresholding (not recommended).
;
;  WARNING: This destriping algorithm will not work correctly on flat fields or
;  any image where there is very large amounts of signal covering the entire
;  field. If called on such data, it will print a warning message and return
;  without modifying the data array.
;  
; Summary of the primitive:
; The principle of the primitive is to build models of the different source of noise you want to treat and then subtract them to the real image at the end.
; 1/ mask computation
; 2/ Channels offset model based on im = image => chan_offset
; 3/ Microphonics computation based on im = image - chan_offset => microphonics_model
; 4/ Destriping model based on im = image - chan_offset - microphonics_model => stripes
; 5/ Output: imout = image - chan_offset - microphonics_model - stripes
;
; Destripping Algorithm Details:
;    Generate a mask of where the spectra are located, based on the
;      already-loaded wavelength or pol spots solutions.
;    Mask out those pixels. 
;  Break the image up into the 32 readout channels
;  Flip the odd channels to account for the alternating readout direction.
;  Generate a median image across the 32 readout channels
;  Smooth by 20 pixels to generate the broad variations
;  mask out any pixels that are >3 sigma discrepant vs the broad variations
;  Generate a better median image across the 32 readout channels post masking
;  Perform some sanity checks for model validity and interpolate NaNs as needed
;  Expand to a 2D image model of the detector
;
;
; OPTIONAL/EXPERIMENTAL: 
;  The microphonics noise attenuation can be activitated by setting the parameter remove_microphonics to 1 or 2.
;  The microphonics from the image can be saved in a file using the parameter save_microphonics.
;  If Plot_micro_peaks equal 'yes', then it will open 3 plot windows with the peaks aera of the microphonics in Fourier space (Before microphonics subtraction, the microphonics to be removed and the final result). Used for debugging purposes.
;  
;  If remove_microphonics = 1:
;    The algorithm is always applied.
;  
;  If remove_microphonics = 2:
;    The algorithm is applied only of the quantity of noise is greater than the micro_treshold parameter.
;    A default empirical value of 0.01 has been set based on the experience of the author of the algorithm. 
;    The quantity of microphonics noise is measured with the ratio of the dot_product and the norm of the image: dot_product/sqrt(sum(abs(fft(image))^2)).
;    With dot_product = sum(abs(fft(image))*abs(fft(noise_model))) which correspond to the projection of the image on the microphonics noise model in the absolute Fourier space.
;  
;  There are 3 implemented methods right now depending on the value of the parameter method_microphonics.
;  
;  If method_microphonics = 1:
;    The microphonics noise removal is based on a fixed precomputed model. This model is the normalized absolute value of the Fourier coefficients.
;    The filtering consist of diminishing the intensity of the frequencies corresponding to the noise in the image proportionaly to the dot product of the image witht the noise model.
;    The phase remains unchanged.
;    The filtered coefficients in Fourier space become (1-dot_product*(Amplitude_noise_model/Amplitude_image)).
;    With dot_product = sum(abs(fft(image))*abs(fft(noise_model))) which correspond to the projection of the image on the microphonics noise model in the absolute Fourier space.
;  
;  If method_microphonics = 2:
;    The frequencies around the 3 identified peaks of the microphonics noise in Fourier space are all set to zero.
;    This algorithm is the best one of you are sure that there is no data in this aera but it is probably better not to use it...
;  
;  If method_microphonics = 3:
;    A 2d gaussian is fitted for each of the three peaks of the microphonics noise in Fourier space and then removed.
;    Only the absolute value is considered and the phase remains unchanged.
;    This algorthim is not as efficient as the two others but if you don't have an accurate model, it can be better than nothing.
;
;
; PIPELINE ARGUMENT: Name="method" Type="string" Range="[threshhold|calfile]" Default="calfile" Desc='Find background based on image value threshhold cut, or calibration file spectra/spot locations?'
; PIPELINE ARGUMENT: Name="abort_fraction" Type="float" Range="[0.0,1.0]" Default="0.9" Desc="Necessary fraction of pixels in mask to continue - set at 0.9 to ensure quicklook tool is robust"
; PIPELINE ARGUMENT: Name="chan_offset_correction" Type="int" Range="[0,1]" Default="0" Desc="Tries to correct for channel bias offsets - useful when no dark is available"
; PIPELINE ARGUMENT: Name="fraction" Type="float" Range="[0.0,1.0]" Default="0.7" Desc="What fraction of the total pixels in a row should be masked"
; PIPELINE ARGUMENT: Name="high_limit" Type="float" Range="[0,Inf]" Default="1" Desc="Pixel value where exceeding values are assigned a larger mask"
; PIPELINE ARGUMENT: Name="Save_stripes" Type="int" Range="[0,1]" Default="0" Desc="Save the striping noise image subtracted from frame?"
; PIPELINE ARGUMENT: Name="display" Type="string" Range="[yes|no]" Default="no" Desc='Show diagnostic before and after plots when running?'
; PIPELINE ARGUMENT: Name="remove_microphonics" Type="int" Range="[0,2]" Default="0" Desc='Remove microphonics noise based on a precomputed fixed model.0: not applied. 1: applied. 2: the algoritm is applied only if the measured noise is greater than micro_treshold'
; PIPELINE ARGUMENT: Name="method_microphonics" Type="int" Range="[1,3]" Default="0" Desc='Method applied for microphonics 1: model projection. 2: all to zero 3: gaussian fit'
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="string" Default="/Users/jruffio/gpi/Reduced/calibrations/S20130430S0003-microModel.fits" Desc="Filename of the desired microphonics model file to be read"
; PIPELINE ARGUMENT: Name="Plot_micro_peaks" Type="string" Range="[yes|no]" Default="no" Desc="Plot in 3d the peaks corresponding to the microphonics"
; PIPELINE ARGUMENT: Name="save_microphonics" Type="string" Range="[yes|no]" Default="no" Desc='If remove_microphonics = 1 or (auto and micro_treshold overpassed), save the removed microphonics'
; PIPELINE ARGUMENT: Name="micro_treshold" Type="float" Range="[0.0,1.0]" Default="0.01" Desc='If remove_microphonics = 2, set the treshold. This value is sum(abs(fft(image))*abs(fft(noise_model)))/sqrt(sum(image^2))'
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: Save output to disk, 0: Don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="1" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE COMMENT:  Subtract detector striping using measurements between the microspectra
; PIPELINE ORDER: 1.3
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE NEWTYPE: SpectralScience,Calibration, PolarimetricScience
;
;
; HISTORY:
;     Originally by Marshall Perrin, 2011-07-15
;   2011-07-30 MP: Updated for multi-extension FITS
;   2012-12-12 PI: Moved from Subtract_2d_background.pro
;   2012-12-30 MMB: Updated for pol extraction. Included Cal file, inserted IDL version checking for smooth() function
;   2013-01-16 MP: Documentation cleanup.
;   2013-03-12 MP: Code cleanup, some speed enhancements by vectorization
;   2013-05-28 JBR: Primitive copy pasted from the destripe_mask_spectra.pro primitive. Microphonics noise enhancement. Microphonics algorithm now applied before the destripping.
;-
function destripe_mask_spectra_micro, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'Micro Model'
@__start_primitive

; check to see if the frame is a flat or ARC
if strcompress(backbone->get_keyword('OBSTYPE'),/remove_all) eq 'FLAT' or $
   strcompress(backbone->get_keyword('OBSTYPE'),/remove_all) eq 'ARC' then begin
   logstr = 'This is a flat or arc observation - no destriping will be performed!'
   backbone->set_keyword, "HISTORY", logstr,ext_num=0
   message,/info, "This is a flat or arc observation - no destriping will be performed!"
   return, ok
endif

 if tag_exist( Modules[thisModuleIndex], "method") then method=(Modules[thisModuleIndex].method) else method=''
 if tag_exist( Modules[thisModuleIndex], "abort_fraction") then abort_fraction=float(Modules[thisModuleIndex].abort_fraction) else abort_fraction=0.9
 if tag_exist( Modules[thisModuleIndex], "Chan_offset_correction") then chan_offset_correction=float(Modules[thisModuleIndex].chan_offset_correction) else chan_offset_correction=0.9
 if tag_exist( Modules[thisModuleIndex], "fraction") then fraction=float(Modules[thisModuleIndex].fraction) else fraction=0.7
 if tag_exist( Modules[thisModuleIndex], "high_limit") then high_limit=float(Modules[thisModuleIndex].high_limit) else high_limit=1000
 if tag_exist( Modules[thisModuleIndex], "Save") then save=float(Modules[thisModuleIndex].Save) else Save=0
 if tag_exist( Modules[thisModuleIndex], "Save_stripes") then save_stripes=float(Modules[thisModuleIndex].Save_stripes) else Save_stripes=0 
 if tag_exist( Modules[thisModuleIndex], "method_microphonics") then method_microphonics=uint(Modules[thisModuleIndex].method_microphonics) else method_microphonics=1
 if tag_exist( Modules[thisModuleIndex], "remove_microphonics") then remove_microphonics=uint(Modules[thisModuleIndex].remove_microphonics) else remove_microphonics=0
 if tag_exist( Modules[thisModuleIndex], "Plot_micro_peaks") then Plot_micro_peaks=string(Modules[thisModuleIndex].Plot_micro_peaks) else Plot_micro_peaks='no'
 if tag_exist( Modules[thisModuleIndex], "save_microphonics") then save_microphonics=Modules[thisModuleIndex].save_microphonics else save_microphonics='no'
 if tag_exist( Modules[thisModuleIndex], "display") then display=Modules[thisModuleIndex].display else display='yes'
 display = strlowcase(string(display))
 
 ;get the 2D detector image
 ;This variable will remain unchanged
 image=*(dataset.currframe[0])

 backbone->Log, 'Generating model of 2D image background based on pixels in between spectra'
 
 ;////////////////////////////////////////////////////////////////////////////////
 ;Summary of the primitive
 ;The principle of the primitive is to build models of the different source of noise you want to treat and then subtract them to the real image at the end.
 ;1/ mask computation
 ;2/ Channels offset model computation based on im = image => chan_offset
 ;3/ Microphonics computation based on im = image - chan_offset => microphonics_model
 ;4/ Destriping model computation based on im = image - chan_offset - microphonics_model => stripes
 ;5/ Output: imout = image - chan_offset - microphonics_model - stripes
 ;////////////////////////////////////////////////////////////////////////////////

;////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////Building the mask//////////////////////////////////
;////////////////////////////////////////////////////////////////////////////////

 ; The first step is to figure out which pixels are from spectra (or pol spots)
 ; and which are not. Perhaps eventually this will be done from a lookup table
 ; or by invoking the wavelength solution, but for now we just do it using a 
 ; cut on the image pixels itself: values > thresh * median value are considered
 ; to be the spectra
 sz=size(image) 

 if sz[1] ne 2048 or sz[2] ne 2048 then begin
  backbone->Log, "REFPIX: Image is not 2048x2048, don't know how to destripe"
  return, NOT_OK
 endif

 mask = bytarr(sz[1],sz[2])

 ; load in bad pixel map if it exists
 if keyword_set(badpixmap) then mask[where(badpixmap eq 1)]=1

 backbone->set_keyword, "HISTORY", "Destriping, using spectral masking + median across channels"
 backbone->set_keyword, "HISTORY", "   (This does not work on flat fields!)"

 if strlowcase(method) eq 'threshhold' then begin

  for r=0L,sz[2]-1 do begin ; loop over rows
      row=image[*,r] - min(image[*,r]) +1 ; MAKES EVERYTHING POSITIVE
      med = median(row)
      ; want to mask X percent of the pixels
      frac=fraction
      dz=0.01
      ; determine pixels to mask (this is embarassingly dirty)
      sorted_ind=reverse(sort(row)) ; high to low
      for i=0, floor((sz[2]-1)*frac)-1 do mask[sorted_ind[i],r]=1
  endfor 
        
    ; now expand the mask by 1 pixel in all directions to grab things close to
    ; the edges of the spectra. 1 pixel was chosen based on visual examination of
    ; how well the final mask works, and is also plausible based on the existence
    ; of interpixel capacitance that affects adjacent pixels at a ~few percent
    ; level. 

  ;kernel = [[0,1,0],[1,1,1],[0,1,0]]  ; This appears to work pretty well based on visual examination of the masked region
  ;mask = dilate(mask, kernel)

  backbone->Log, "Identified "+strc(total(~mask))+" pixels for use as background pixels"

 endif else begin ;======= use calibration file to determine the regions to use. =====
    
  mode = gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', count=c))
  filter= gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=c))
  case strupcase(strc(mode)) of
    'PRISM':  begin
      ; Assume wavecal already loaded by readwavcal primitive
        
      ; Extrapolate wavecal an additional 2 lenslets, to let us mask out
      ; the edge spectra that are half on/half off the detector.
      wavecal2 = gpi_wavecal_extrapolate_edges(wavcal)
        

            ; The following code is lifted directly from extractcube.

            sdpx = calc_sdpx(wavecal2, filter, xmini, CommonWavVect)
            if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')

            tilt=wavecal2[*,*,4]
      if ~keyword_set(high_limit) then high_limit=3000
      ; must also mask edges where no wavcal is present
      mask[0:8,*]=1
      mask[2040:2047,*]=1
            for i=0,sdpx-1 do begin  ;through spaxels
                ;get the locations on the image where intensities will be extracted:
                x3=xmini-i
                y3=round(wavecal2[*,*,1]+(wavecal2[*,*,0]-x3)*tan(tilt[*,*]))    
                ; Normally we extract intensities on a 3x1 box;
                ; instead of extracting pixels, mask out those pixels.
                dy=1
                mask[y3,x3] = 1
                mask[y3+dy,x3] = 1
                mask[y3-dy,x3] = 1

                high_ind=where(image[y3,x3] gt high_limit $
                              and finite(image[x3,y3] eq 1),complement=low_ind)
        ; mask a 5x1 box for pixels passing
        ; the high limit
        dy=2
        if high_ind[0] ne -1 then begin
           mask[y3[high_ind]+dy,x3[high_ind]] = 1
           mask[y3[high_ind]-dy,x3[high_ind]] = 1
        endif
        ; limit where cross-talk dominates
        ; entire spectrum.
        very_high_ind=where(image[y3,x3] gt 4000 $
                 and finite(image[x3,y3] eq 1))
        ; mask a 7x1 box for pixels passing
        ; the high limit
        dy=3
        if very_high_ind[0] ne -1 then begin
           mask[y3[very_high_ind]+dy,x3[very_high_ind]] = 1
           mask[y3[very_high_ind]-dy,x3[very_high_ind]] = 1
        endif
      endfor
    end
    'WOLLASTON':    begin
        ; Assume pol cal info already loaded by readpolcal primitive 
        polspot_coords = polcal.coords
        polspot_pixvals = polcal.pixvals
        
        sz = size(polspot_coords)
        nx = sz[1+2]
        ny = sz[2+2]
        
        for pol=0,1 do begin
        for ix=0L,nx-1 do begin
          for iy=0L,ny-1 do begin
          ;if ~ptr_valid(polcoords[ix, iy,pol]) then continue
          wg = where(finite(polspot_pixvals[*,ix,iy,pol]) and polspot_pixvals[*,ix,iy,pol] gt 0, gct)
          if gct eq 0 then continue

          spotx = polspot_coords[0,wg,ix,iy,pol]
          spoty = polspot_coords[1,wg,ix,iy,pol]
          
          mask[spotx,spoty]= 1
           
          endfor 
        endfor 
        endfor 
    end
    'OPEN':    begin
           backbone->set_keyword, "HISTORY", "NO DESTRIPING PERFORMED, not implemented for Undispersed mode"
                   message,/info, "NO DESTRIPING PERFORMED, not implemented for Undispersed mode"
                   return,ok
    end
        endcase

    endelse


;////////////////////////////////////////////////////////////////////////////////
  ;---- OPTIONAL channel offset repair
  ; derive median channel offsets
;////////////////////////////////////////////////////////////////////////////////

    im=image
    im[where(mask eq 1)]=!values.f_nan

    if keyword_set(chan_offset_correction) then begin
       backbone->set_keyword, "HISTORY", " Also applying optional channel offset correction."
       chan_offset=fltarr(2048,2048)
       for c=0, 31 do begin
          chan_offset[c*64:((c+1)*64)-1,*]=(median(im[c*64:((c+1)*64)-1,*]))
       endfor
    ;im-=chan_offset
    endif

;////////////////////////////////////////////////////////////////////////////////
    ;--- OPTIONAL / EXPERIMENTAL  microphonics repair
;////////////////////////////////////////////////////////////////////////////////

  if (remove_microphonics GE 1) then begin
    microphonics_model = fltarr(2048, 2048)
    backbone->Log, "Fourier filtering to remove microphonics noise.",depth=2
    backbone->set_keyword, "HISTORY", "Fourier filtering to remove microphonics noise."
    
    ;load the image from which to remove the noise and subtract the channels offset if the option is activated
    im = image
        if keyword_set(chan_offset_correction) then im-=chan_offset
    
    ;load the microphonics model
    micro_noise_abs_model = gpi_readfits(c_File,header=Header)
    ;micro_noise_abs_model = readfits("/Users/jruffio/IDLWorkspace/pipeline/primitives/microphonics_model_abs_normalized.fits")
    
    ;measure the noise before anything is done
    FT_im = fft(im)
    noise_before = total(abs(FT_im)*micro_noise_abs_model)/sqrt(total(abs(FT_im)^2))
    backbone->Log, "The measured noise before is"+ string(noise_before),depth=2
    backbone->set_keyword, "HISTORY", "The measured noise before is"+ string(noise_before)
    
    ;If the algorithm is applied based on the treshold, load the treshold or get a default value
    ;Else treshold set to zero to be sure the algo will be applied
    if (remove_microphonics eq 2) then begin
        if tag_exist( Modules[thisModuleIndex], "micro_treshold") then micro_treshold = float(Modules[thisModuleIndex].micro_treshold) else begin
          micro_treshold = 0.01
          backbone->Log, "Parameter micro_treshold not found. Default value = 0.01",depth=2
          backbone->set_keyword, "HISTORY", "Parameter micro_treshold not found. Default value = 0.01"
        endelse
    endif else begin
        micro_treshold = 0.0
    endelse
      
        ;this will be always applied if remove_microphonics = 1 because micro_teshold would equal 0.0
        if (noise_before  GE micro_treshold) then begin
        ;Conditions for the different methods based on the parameter: methode_microphonics
          if (method_microphonics eq 1) then begin 
              ;model projection
              ;see the primitive documentation for the explanation
              abs_FT_im = abs(FT_im)
              ;abs_FT_im[0:25,165:183] = median(abs_FT_im[0:25,165:183],2)
              ;abs_FT_im[(2048-25):2047,165:183] = median(abs_FT_im[(2048-25):2047,165:183],2)
              ;abs_FT_im[(2048-25):2047,(2048-183):(2048-165)] = median(abs_FT_im[(2048-25):2047,(2048-183):(2048-165)],2)
              ;abs_FT_im[0:25,(2048-183):(2048-165)] = median(abs_FT_im[0:25,(2048-183):(2048-165)],2)
          
              dot_product = total(abs_FT_im*micro_noise_abs_model)
              isnotnull = where(abs_FT_im ne 0.0)
              FT_im_filt = FT_im
              FT_im_filt[isnotnull] = (1-dot_product*micro_noise_abs_model[isnotnull]/abs_FT_im[isnotnull]) * FT_im[isnotnull]
	      ;FT_im_filt = (1-dot_product*micro_noise_abs_model/abs_FT_im) * FT_im
              im_filt = real_part(fft(FT_im_filt,/inverse))
              microphonics_model = im-im_filt

        backbone->Log, "Microphonics noise filtering applied.",depth=2
              backbone->set_keyword, "HISTORY", "Microphonics noise filtering applied."
              
              noise_after = total(abs(FT_im_filt)*micro_noise_abs_model)/sqrt(total(abs(FT_im_filt)^2))
              backbone->Log, "The measured noise after is"+ string(noise_after),depth=2
              backbone->set_keyword, "HISTORY", "The measured noise after is"+ string(noise_after)
              
              ;If Plot_micro_peaks equal 'yes', then it will open 3 plot windows with the peaks aera of the microphonics in Fourier space (Before microphonics subtraction, the microphonics to be removed and the final result). Used for debugging purposes.   
              if strlowcase(Plot_micro_peaks) eq 'yes' then begin
                window, 20, retain=2
                surface, (shift(abs(FT_im),1024,1024))[1004:1046, 1190:1210],TITLE = 'Before microphonics subtraction', SUBTITLE = 'Aera of the 3 microphonics peaks in absolute Fourier Space', CHARSIZE = 3, XTITLE = 'x-axis in pixels', YTITLE = 'y-axis in pixels', ZTITLE = 'Data number'
                window, 21, retain=2
                surface, (shift(dot_product*micro_noise_abs_model,1024,1024))[1004:1046, 1190:1210],TITLE = 'The subtracted microphonics model', SUBTITLE = 'Aera of the 3 microphonics peaks in absolute Fourier Space', CHARSIZE = 3, XTITLE = 'x-axis in pixels', YTITLE = 'y-axis in pixels', ZTITLE = 'Data number'
                window, 22, retain=2
                surface, (shift(abs(FT_im_filt),1024,1024))[1004:1046, 1190:1210],TITLE = 'After microphonics subtraction', SUBTITLE = 'Aera of the 3 microphonics peaks in absolute Fourier Space', CHARSIZE = 3, XTITLE = 'x-axis in pixels', YTITLE = 'y-axis in pixels', ZTITLE = 'Data number'
              endif 
          
          endif else if (method_microphonics eq 2) then begin ;all to zero
             ;///////////// just erasing the noise frequencies///////////////
             ; Now we use a FFT filter to generate a model of the microphonics noise
             ; We do this here **entirely ignoring the masking out of spectra** and trusting
             ; in Fourier space frequency selection to pick out only the microphonics-related 
             ; power in the image. YMMV, Use at your own risk!
               fftmask = bytarr(2048,2048)
             fftmask[1004:1046, 1190:1210]  = 1  ; a box around the 3 peaks from the microphonics blobs,
                               ; as seen in an FFT array if 'flopped'
                               ; to be centered on the 0-freq component
             ;fftmask[1004:1046, 1368:1378] = 1
             fftmask += reverse(fftmask, 2)
             fftmask = shift(fftmask,-1024,-1024) ; flop to line up with fftim
          
             microphonics_model = real_part(fft( FT_im*fftmask,/inverse))
          
             ; For some reason presumably explicable in Fourier space, the resulting
             ; microphonics model often appears to have extra striping in the top rows
             ; of the image. This leads to some *induced* extra striping there
             ; when subtracted. Let's force the top rows to zero to avoid this. 
             microphonics_model[*, 1975:*] = 0
               
             backbone->set_keyword, "HISTORY", "Microphonics noise removed via Fourier filtering."
             backbone->set_keyword, "HISTORY", "   CAUTION - may or may not work well on science data."
             backbone->set_keyword, "HISTORY", "   YMMV depending on image content. User discretion is advised."
           endif else if (method_microphonics eq 3) then begin ;gaussian fit
              abs_FT_im = shift(abs(FT_im),1024,1024)
              
              peakleft = abs_FT_im[1004:1015, 1190:1210]
              peakmiddle = abs_FT_im[1016:1035, 1190:1210]
              peakright = abs_FT_im[1036:1046, 1190:1210]
              
              peakleft_gauss = gauss2dfit(peakleft, para_left)
              peakmiddle_gauss = gauss2dfit(peakmiddle, para_middle)
              peakright_gauss = gauss2dfit(peakright, para_right)
              peakleft_gauss = peakleft_gauss-para_left[0]
              peakmiddle_gauss = peakmiddle_gauss-para_middle[0]
              peakright_gauss = peakright_gauss-para_right[0]
              
              correction = fltarr(2048,2048)
              correction[1004:1046, 1190:1210] = [peakleft_gauss,peakmiddle_gauss,peakright_gauss]
              correction = shift(correction, -1024, -1024)
              correction += reverse(reverse(correction, 2),1)
              
              abs_FT_im = shift(abs_FT_im,-1024,-1024)
              FT_im_filt = (1-correction/abs_FT_im) * FT_im
              im_filt = real_part(fft(FT_im_filt,/inverse))
              microphonics_model = im - im_filt
              backbone->Log, "Microphonics noise filtering applied.",depth=2
              backbone->set_keyword, "HISTORY", "Microphonics noise filtering applied."
              
              noise_after = total(abs(FT_im_filt)*micro_noise_abs_model)/sqrt(total(abs(FT_im_filt)^2))
              backbone->Log, "The measured noise after is"+ string(noise_after),depth=2
              backbone->set_keyword, "HISTORY", "The measured noise after is"+ string(noise_after)
              
              ;If Plot_micro_peaks equal 'yes', then it will open 3 plot windows with the peaks aera of the microphonics in Fourier space (Before microphonics subtraction, the microphonics to be removed and the final result). Used for debugging purposes. 
              if strlowcase(Plot_micro_peaks) eq 'yes' then begin
                window, 20, retain=2
                surface, (shift(abs(FT_im),1024,1024))[1004:1046, 1190:1210],TITLE = 'Before microphonics subtraction', SUBTITLE = 'Aera of the 3 microphonics peaks in absolute Fourier Space', CHARSIZE = 3, XTITLE = 'x-axis in pixels', YTITLE = 'y-axis in pixels', ZTITLE = 'Data number'
                window, 21, retain=2
                surface, (shift(correction,1024,1024))[1004:1046, 1190:1210],TITLE = 'The subtracted microphonics model', SUBTITLE = 'Aera of the 3 microphonics peaks in absolute Fourier Space', CHARSIZE = 3, XTITLE = 'x-axis in pixels', YTITLE = 'y-axis in pixels', ZTITLE = 'Data number'
                window, 22, retain=2
                surface, (shift(abs(FT_im_filt),1024,1024))[1004:1046, 1190:1210],TITLE = 'After microphonics subtraction', SUBTITLE = 'Aera of the 3 microphonics peaks in absolute Fourier Space', CHARSIZE = 3, XTITLE = 'x-axis in pixels', YTITLE = 'y-axis in pixels', ZTITLE = 'Data number' 
              endif 
          endif
        endif else begin
          backbone->Log, "Not enough microphonics. Algorithm not applied.",depth=2
          backbone->set_keyword, "HISTORY", "Not enough microphonics. Algorithm not applied."
        endelse


  if strlowcase(save_microphonics) eq 'yes' then begin
    *(dataset.currframe[0])=microphonics_model
    suffix='-micronoise'
    b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
  endif
  endif


;////////////////////////////////////////////////////////////////////////////////
;--- DESTRIPPING
;////////////////////////////////////////////////////////////////////////////////

    im = image
        if keyword_set(chan_offset_correction) then im-=chan_offset
  if remove_microphonics ge 1 then im-=microphonics_model

  ;--- Generate a first estimate of the striping
    ; Chop the image into the 32 readout channels. 
    ; Flip every other channel to account for the readout direction
    ; alternating for the H2RG
 
    parts = transpose(reform(im, 64,32, 2048),[0,2,1])
    for i=0,15 do parts[*,*,2*i+1] = reverse(parts[*,*,2*i+1]) 

    ; Generate a median image from all 32 readout channels
    medpart0 = median(parts,dim=3)

  ;--- mask out pixels that are >3 sigma discrepant relative to that first estimate
  ; remove broad variations prior to clipping
    ; Note: allowed keywords to the smooth() function changed in IDL 8.1 
    if !version[0].release lt 8.1 then begin
    sm_medpart1d=smooth(median(medpart0,dim=1),20,/edge,/nan)
  endif else begin 
    sm_medpart1d=smooth(median(medpart0,dim=1),20,/edge_truncate,/nan)
  endelse
  
    broad_variations=sm_medpart1d##(fltarr(64)+1)
  ; create a full image 
    full_broad_variations = sm_medpart1d##(fltarr(2048)+1)
        
    ; Any pixel which is 3-sigma discrepant should 
  ; probably be masked out
    medsig=stddev(medpart0-broad_variations,/nan)
    medmed = median(medpart0-broad_variations)
    discrepant = where(abs(im-full_broad_variations-medmed) gt (5*medsig))

    ; apply this as a cutoff and then regenerate the parts array
    im[discrepant] = !values.f_nan

  ;--- Generate a second estimate of the striping
    parts = transpose(reform(im, 64,32, 2048),[0,2,1])
    for i=0,15 do parts[*,*,2*i+1] = reverse(parts[*,*,2*i+1]) 

  ; do a controlled median - flags as NaN when less than 3 pixels are used.
  medpart = median(parts,/even,dim=3)
  validcts = total(finite(parts),3)
  wlow = where(validcts le 3, lowct)
  if lowct gt 0 then medpart[wlow] = !values.f_nan

  ;----- Sanity checks for validity
  ; determine if medpart is usable - this is just to make sure that if a
  ;                                  flat is put through the pipeline
  ;                                  and it does not have the proper
  ;                                  keywords then it will not crash the
  ;                                  script but rather exit nicely

  if total(finite(medpart))/(2048.0*64) le abort_fraction then begin
     backbone->set_keyword, "HISTORY", "NOT Destriped, too many pixels above the abort_fraction in Subtract_background_2d"
     logstr = 'NOT Destriped, too many pixels '+strcompress(string(total(finite(medpart))/(2048.0*64)),/remove_all)+' above the abort_fraction '+strcompress(string(abort_fraction),/remove_all)+' in Subtract_background_2d'
     backbone->set_keyword, "HISTORY", logstr,ext_num=0
     message,/info, logstr
     return, ok
  endif


  ; interpolate pixels having NaN to be the median of the row
  ; this could be improved to fit a line!
  nans=where(finite(medpart) eq 0)
  if nans[0] ne -1 then begin          
     for i=0, 2048-1 do begin
      ind=where(finite(medpart[*,i]) eq 0)
      if ind[0] eq -1 then continue   
      medpart[ind,i]=median(medpart[*,i])
     endfor 
  endif        
              

  ;----- Generate 2D model to subtract from the image
    ; Generate a model stripe image from that median, replicated for 
    ; each of the 32 channels with appropriate flipping
  model = rebin(medpart, 64,2048,32)
  for i=0,15 do model[*,*,2*i+1] = reverse(model[*,*,2*i+1]) 
  stripes = reform(transpose(model, [0,2,1]), 2048, 2048)    

  ; replace NaN's by smoothed values - these are the lines that were masked out

  ; the values that are masked out at the top and bottom - set to zero
  stripes[*,0:4] = 0
  stripes[*,2044:2047] = 0

  ; now other values that have nans
  nan_ind=where(finite(stripes) eq 0)
  if nan_ind[0] ne -1 then begin
     sm_im=smooth(stripes,5,/nan)
     stripes[nan_ind]=sm_im[nan_ind]
  endif
    
    
;////////////////////////////////////////////////////////////////////////////////
;---- At last, the actual subtraction!
;////////////////////////////////////////////////////////////////////////////////
  imout = image - stripes
        if keyword_set(chan_offset_correction) then imout-=chan_offset
  if remove_microphonics ge 1 then imout-=microphonics_model
  ; input safety to make sure no NaN's are in the image
  nan_check=where(finite(imout) eq 0)

  
  if nan_check[0] ne -1 then begin
     backbone->set_keyword, "HISTORY", "NOT Destriped, failed in Subtract_background_2d - NaN found in mask"
     logstr = 'Destripe failed in Subtract_background_2d - NaN found in output image - so no destripe performed'
     backbone->set_keyword, "HISTORY", logstr,ext_num=0
     message,/info, 'Destripe failed in Subtract_background_2d - NaN found in mask - so no destripe performed'
     imout=image
  endif





  ; interpolate pixels having NaN to be the median of the row
  ; this could be improved to fit a line!
  nans=where(finite(medpart) eq 0)
  if nans[0] ne -1 then begin          
     for i=0, 2048-1 do begin
      ind=where(finite(medpart[*,i]) eq 0)
      if ind[0] eq -1 then continue   
      medpart[ind,i]=median(medpart[*,i])
     endfor 
  endif        
              

  ;----- Generate 2D model to subtract from the image
    ; Generate a model stripe image from that median, replicated for 
    ; each of the 32 channels with appropriate flipping
  model = rebin(medpart, 64,2048,32)
  for i=0,15 do model[*,*,2*i+1] = reverse(model[*,*,2*i+1]) 
  stripes = reform(transpose(model, [0,2,1]), 2048, 2048)    

  ; replace NaN's by smoothed values - these are the lines that were masked out

  ; the values that are masked out at the top and bottom - set to zero
  stripes[*,0:4] = 0
  stripes[*,2044:2047] = 0

  ; now other values that have nans
  nan_ind=where(finite(stripes) eq 0)
  if nan_ind[0] ne -1 then begin
     sm_im=smooth(stripes,5,/nan)
     stripes[nan_ind]=sm_im[nan_ind]
  endif
    
  ;---- At last, the actual subtraction!
  imout = image - stripes
        if keyword_set(chan_offset_correction) then imout-=chan_offset
	if remove_microphonics ge 1 then imout-=microphonics_model
  ; input safety to make sure no NaN's are in the image
  nan_check=where(finite(imout) eq 0)

               ; window, 23, retain=2
               ; surface, (shift(abs(fft(imout)),1024,1024))[1004:1046, 1190:1210],TITLE = 'after' 
  
  if nan_check[0] ne -1 then begin
     backbone->set_keyword, "HISTORY", "NOT Destriped, failed in Subtract_background_2d - NaN found in mask"
     logstr = 'Destripe failed in Subtract_background_2d - NaN found in output image - so no destripe performed'
     backbone->set_keyword, "HISTORY", logstr,ext_num=0
     message,/info, 'Destripe failed in Subtract_background_2d - NaN found in mask - so no destripe performed'
     imout=image
  endif




  if display eq 'yes' then begin
    select_window, 1
    loadct, 0
    erase

    if strlowcase(remove_microphonics) eq 'yes' then begin
      ; display for destriping and microphonics removal
      !p.multi=[0,4,1]
      mean_offset = mean(image) - mean(imout)
      imdisp, image - mean_offset, /axis, range=[-10,30], title='Input Data', charsize=2
      imdisp, image - stripes, /axis, range=[-10,30], title='Destriped', charsize=2
      imdisp, microphonics_model, /axis, range=[-10,30],title="Microphonics model", charsize=2
      imdisp, imout, /axis, range=[-5,15], title="Destriped and de-microphonicsed", charsize=2
      xyouts, 0.5, 0.95, /normal, "Stripe & Microphonics Noise Removal for "+backbone->get_keyword('DATAFILE'), charsize=2, alignment=0.5
    endif else begin
      ; display for just destriping
      if numfile eq 0 then window,0
      !p.multi=[0,3,1]
      mean_offset = mean(image) - mean(imout)
      imdisp, image-mean_offset, /axis, range=[-10,30], title='Input Data', charsize=2
      imdisp, stripes-mean_offset, /axis, range=[-10,30], title='Stripes Model', charsize=2
      imdisp, imout, /axis, range=[-10,30], title='Destriped Data', charsize=2
      xyouts, 0.5, 0.95, /normal, "Stripe Noise Removal for "+backbone->get_keyword('DATAFILE'), charsize=2, alignment=0.5
    endelse
  endif

  ; and now output
  *(dataset.currframe[0]) = imout
  backbone->set_keyword, "HISTORY", "Subtracted 2D image background estimated from pixels between spectra",ext_num=0
  suffix='-bgsub2d'

  if tag_exist( Modules[thisModuleIndex], "Save_Stripes") && ( Modules[thisModuleIndex].Save_stripes eq 1 ) then b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, '-stripes', display=display,savedata=stripes,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile])
  
  logstr = 'Robust sigma of unmasked pixels before destriping: '+strc(robust_sigma(image[where(~mask)]))
  backbone->set_keyword, "HISTORY", logstr,ext_num=0
  backbone->Log, logstr

@__end_primitive
end
