;+
; NAME: destripe_mask_spectra
; PIPELINE PRIMITIVE DESCRIPTION: Destripe science frame
;
; Subtract the detector readout noise (striping) from the background
; of a 2d raw IFS image by masking spectra and using the remaining
; regions to obtain a sampling of the striping. The masking can be performed by using the wavelength
; calibration to mask the spectra (recommended) or by thresholding
; (not recommended).

; WARNING: This destriping algorithm will not work correctly on flat fields or any image
; where there is very large amounts of signal covering the entire
; field. 
;

;
; KEYWORDS:
;       method= "[threshhold|calfile]" which masking method to adopt. Pixel threshold or by wavelength calibration file.
;       abort_fraction = [0-1.0] - Necessary fraction of pixels in mask to continue. Set at 0.9 to ensure quicklook tool is robust
;       fraction = 0.7 float indicating the fractional amount of
;                      pixels to mask per row
;       high_limit= [0-Inf]  pixel value where exceeding values have
;                            a larger mask applied. Only used in
;                            calfile mode. 
;       save_stripes=[0,1]   saves the determined striping frame to
;                            disk (-stripes.fits)
;       save = [0,1]    saves corrected image to disk (-bgsub.fits)
; 	gpitv=		session number for the GPITV window to display in.
; 				set to '0' for no display, or >=1 for a display.
;
; OUTPUTS:
;
; PIPELINE ARGUMENT: Name="method" Type="string" Range="[threshhold|calfile]" Default="calfile" Desc='Find background based on image value threshhold cut, or calibration file spectra/spot locations?'
; PIPELINE ARGUMENT: Name="abort_fraction" Type="float" Range="[0.0,1.0]" Default="0.9" Desc="Necessary fraction of pixels in mask to continue - set at 0.9 to ensure quicklook tool is robust"
; PIPELINE ARGUMENT: Name="chan_offset_correction" Type="int" Range="[0,1]" Default="0" Desc="Tries to correct for channel bias offsets - useful when no dark is available"
; PIPELINE ARGUMENT: Name="fraction" Type="float" Range="[0.0,1.0]" Default="0.7" Desc="What fraction of the total pixels in a row should be masked"
; PIPELINE ARGUMENT: Name="high_limit" Type="float" Range="[0,Inf]" Default="1" Desc="Pixel value where exceeding values are assigned a larger mask"
; PIPELINE ARGUMENT: Name="Save_stripes" Type="int" Range="[0,1]" Default="0" Desc="Save the striping noise image subtracted from frame?"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: Save output to disk, 0: Don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="1" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
; PIPELINE COMMENT:  Subtract detector striping using measurements between the microspectra
; PIPELINE ORDER: 1.12 
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE NEWTYPE: SpectralScience,Calibration
;
;
; HISTORY:
; 	Originally by Marshall Perrin, 2011-07-15
;   2011-07-30 MP: Updated for multi-extension FITS
;   2012-12-12 PI: Moved from Subtract_2d_background.pro
;-
function destripe_mask_spectra, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
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

 ;get the 2D detector image
 image=*(dataset.currframe[0])

 backbone->Log, 'Generating model of 2D image background based on pixels in between spectra'

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
	
	;stop
  		;mode=SXPAR( header, 'PRISM', count=c)
		mode = gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', count=c))
		filter= gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=c))
		case strupcase(strc(mode)) of
	  	'PRISM':		begin
			; load mask from spectral calib file

			; The following code is lifted directly from extractcube.
		  ;;get length of spectrum

            sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)
            if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')

			tilt=wavcal[*,*,4]
                        if ~keyword_set(high_limit) then high_limit=3000
                        ; must also mask edges where no wavcal is present
                                mask[0:8,*]=1
                                mask[2040:2047,*]=1
                                mask[*,0:10]=1
                                mask[*,2028:2047]=1
			for i=0,sdpx-1 do begin  ;through spaxels
				;get the locations on the image where intensities will be extracted:
				x3=xmini-i
				y3=wavcal[*,*,1]+(wavcal[*,*,0]-x3)*tan(tilt[*,*])	
				;extract intensities on a 3x1 box:
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
	  	'WOLLASTON':	begin
                    message,/info, "NO DESTRIPING PERFORMED, not implemented for the Wollaston mode"
                    return,ok
		; load mask from polarimetr cal file
		
	  	end
	  	'OPEN':	begin
                   message,/info, "NO DESTRIPING PERFORMED, not implemented for Undispersed mode"
                   return,ok
                   ;return, error ('FAILURE ('+functionName+'): method=calfile not implemented for prism='+mode)
                   ;else: return, error ('FAILURE ('+functionName+'): method=calfile not implemented for prism='+mode)
                end
	  	endcase

	endelse

	; Chop the image into the 32 readout channels. 
	; Flip every other channel to account for the readout direction
	; alternating for the H2RG
    im=image
    im[where(mask eq 1)]=!values.f_nan
    
	parts = transpose(reform(im, 64,32, 2048),[0,2,1])
 	for i=0,15 do parts[*,*,2*i+1] = reverse(parts[*,*,2*i+1]) 

	; Generate a median image from all 32 readout channels
 	medpart0 = median(parts,dim=3)

; remove broad variations prior to clipping
        sm_medpart1d=smooth(median(medpart0,dim=1),20,/edge_truncate,/nan)
        broad_variations=sm_medpart1d##(fltarr(64)+1)
; create a full image 
        full_broad_variations = sm_medpart1d##(fltarr(2048)+1)
        
                                       ; Any pixel which is 3-sigma
                                ; discrepant should probably have been
                                ; masked out
        medsig=stddev(medpart0-broad_variations,/nan)
        medmed = median(medpart0-broad_variations)
        
        discrepant = where(abs(im-full_broad_variations-medmed) gt (5*medsig))

        ; apply this as a cutoff and then regenerate the parts array
        im[discrepant] = !values.f_nan
	parts = transpose(reform(im, 64,32, 2048),[0,2,1])
 	for i=0,15 do parts[*,*,2*i+1] = reverse(parts[*,*,2*i+1]) 

        ; do a controlled median - flags as NaN when less than 3 pixels are used.
        medpart=fltarr(64,2048)
        for c=0, 63 do begin
           for l=0, 2047 do begin
              ind=where(finite(parts[c,l,*]) eq 1)
              if N_ELEMENTS(ind) le 3 then parts[c,l,*]=!values.f_nan
              medpart[c,l]=median(parts[c,l,*],/even)  
           endfor
        endfor

; determine if medpart is usable - this is just to make sure that if a
;                                  flat is put through the pipeline
;                                  and it does not have the proper
;                                  keywords then it will not crash the
;                                  script but rather exit nicely

        if total(finite(medpart))/(2048.0*64) le abort_fraction then begin
           backbone->set_keyword, "HISTORY", "NOT Destriped, too many pixels above the abort_fraction in Subtract_background_2d"
           logstr = 'NOT Destriped, too many pixels '+strcompress(string(total(finite(medpart))/(2048.0*64)),/remove_all)+' above the abort_fraction '+strcompress(string(abort_fraction),/remove_all)+' in Subtract_background_2d'
           backbone->set_keyword, "HISTORY", logstr,ext_num=0
           message,/info, 'NOT Destriped, too many pixels '+strcompress(string(total(finite(medpart))/(2048.0*64)),/remove_all)+' above the abort_fraction '+strcompress(string(abort_fraction),/remove_all)+' in Subtract_background_2d'
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
              
	; Generate a model stripe image from that median, replicated for 
	; each of the 32 channels with appropriate flipping
        model = rebin(medpart, 64,2048,32)
        for i=0,15 do model[*,*,2*i+1] = reverse(model[*,*,2*i+1]) 
        stripes = reform(transpose(model, [0,2,1]), 2048, 2048)	

; replace NaN's by smoothed values - these are the lines that were masked out

; the values that are masked out at the top and bottom - set to zero
        stripes[*,0:10]=0
        stripes[*,2028:2047]=0

; now other values that have nans
        nan_ind=where(finite(stripes) eq 0)
        if nan_ind[0] ne -1 then begin
           sm_im=smooth(stripes,5,/nan)
           stripes[nan_ind]=sm_im[nan_ind]
        endif
       
; derive median channel offsets
;stripes0=stripes ; for testing
        if keyword_set(chan_offset_correction) then begin
           ;ch_off=fltarr(2048,2048)
           for c=0, 31 do begin
              ;ch_off[c*64:((c+1)*64)-1,*]=(median(im[c*64:((c+1)*64)-1,*]))
              stripes[c*64:((c+1)*64)-1,*]*=(median(im[c*64:((c+1)*64)-1,*]) $
                                             /median(stripes[c*64:((c+1)*64)-1,*]))
           endfor
        endif

 imout = image - stripes

; input safety to make sure no NaN's are in the image
        nan_check=where(finite(imout) eq 0)
        
        if nan_check[0] ne -1 then begin
           backbone->set_keyword, "HISTORY", "NOT Destriped, failed in Subtract_background_2d - NaN found in mask"
           logstr = 'Destripe failed in Subtract_background_2d - NaN found in output image - so no destripe performed'
           backbone->set_keyword, "HISTORY", logstr,ext_num=0
           message,/info, 'Destripe failed in Subtract_background_2d - NaN found in mask - so no destripe performed'
           imout=image
        endif


	backbone->set_keyword, "HISTORY", "Destriped, using a spectral masking + channel median"
	backbone->set_keyword, "HISTORY", "This does not work on flat fields!"

        *(dataset.currframe[0]) = imout
        sxaddhist, "Subtracted 2D image background estimated from spectral masking + channel median", *(dataset.headersPHU[numfile])
        backbone->set_keyword, "HISTORY", "Subtracted 2D image background estimated from pixels between spectra",ext_num=0
        suffix='-bgsub2d'

        if tag_exist( Modules[thisModuleIndex], "Save_Stripes") && ( Modules[thisModuleIndex].Save_stripes eq 1 ) then b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, '-stripes', display=display,savedata=stripes,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile])
        
        logstr = 'Robust sigma of unmasked pixels before destriping: '+strc(robust_sigma(image[where(~mask)]))
        backbone->set_keyword, "HISTORY", logstr,ext_num=0
        message,/info,'Robust sigma of unmasked pixels before destriping: '+strc(robust_sigma(image[where(~mask)]))
        logstr = 'Robust sigma of unmasked pixels after destriping: '+strc(robust_sigma(imout[where(~mask)]))
                                ;sxaddhist, logstr, *(dataset.headersPHU[numfile])
        backbone->set_keyword, "HISTORY", logstr,ext_num=0
        backbone->Log, logstr

@__end_primitive
end

