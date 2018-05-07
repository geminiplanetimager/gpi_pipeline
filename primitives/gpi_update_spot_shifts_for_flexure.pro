;+
; NAME: gpi_update_spot_shifts_for_flexure
; PIPELINE PRIMITIVE DESCRIPTION: Update Spot Shifts for Flexure
; 
;  This primitive updates the wavelength calibration and spot location table
;  to account for shifts in the apparent position of each spectrum due to 
;  elevation-dependent flexure within the IFS.  The observed image motion is
;  about 0.7 pixels in X and 0.5 pixels in Y between 0 and 90 degrees 
;
;  By updating the X and Y coordinates of each lenslet across the field of view, 
;  this primitive enables the extraction of well behaved data cubes 
;  regardless of the orientation. 
;  
;  There are several options for how to determine the shifts, set by the
;  method keyword:
;
;    method="None"     No correction applied.
;    method='Manual'   Apply shifts provided by the user via the
;                      manual_dx and manual_dy arguments. 
;    method='Lookup'   Correction applied based on a lookup table of shifts
;                      precomputed based on arc lamp data at multiple
;                      orientations, obtained from the calibration
;                      database. 
;    method='BandShift'Estimate the flexure values by comparing to the
;                      most recent wavecal regardless of the band and 
;                      interpolating.
;    method='Auto'     [work in progress, use at your own risk]
;                      Attempt to determine the shifts on-the-fly from each
;                      individual exposure via model fitting.
; 
; If the 'gpitv' argument to this primitive is used to send the output 
; image to a gpitv session, it will be displayed *with the updated 
; wavelength calibration information overplotted*. 
;
;
; PIPELINE COMMENT: Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis
; PIPELINE ARGUMENT: Name="method" Type="string" Range="[None|Manual|Lookup|BandShift|Auto]" Default="None" Desc='How to correct spot shifts due to flexure? [None|Manual|Lookup|BandShift|Auto]'
; PIPELINE ARGUMENT: Name="manual_dx" Type="float" Range="[-10,10]" Default="0" Desc="If method=Manual, the X shift of spectra at the center of the detector"
; PIPELINE ARGUMENT: Name="manual_dy" Type="float" Range="[-10,10]" Default="0" Desc="If method=Manual, the Y shift of spectra at the center of the detector"
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[-1,100]" Default="-1" Desc="-1 = No display; 0 = New (unused) window; else = Window number to display diagnostic plot."
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.34
; PIPELINE TYPE: ALL
; PIPELINE CATEGORY: SpectralScience, Calibration, PolarimetricScience
;
; HISTORY:
;   2013-03-08 MP: Started based on extractcube, initial attempts at automated
;                   on-the-fly measurements.
;   2013-03-25 JM: Implemented lookup table version.
;   2013-04-22 PI: A few bug fixes to lookup table code.
;   2013-04-25 MP: Documentation improvements.
;   2013-06-04 JBR: Now compatible with polarimetry.
;   2013-07-17 MP: Rename for consistency
;   2013-12-02 JM: new way of dealing with the lookup table for flexure effect correction, independent of the reference wavelength solution used to calculate the shifts
;-


; This first function is a helper function for the auto-optimization mode
; (experimental, not to be trusted yet)
; Scroll on down further for the main primitive code!
;
function update_shifts_for_flexure_auto_optimize, det, wavcal, filter, coarse=coarse, guess=guess, nsteps=nsteps,display=display
	compile_opt defint32, strictarr, logical_predicate
	
    if keyword_set(coarse) then begin
        xsteps = [    -1, -0.5, 0, 0.5,  1]
        ysteps = [-3, -2.5, -2, -1, -0.5, 0, 0.5 ]
    endif else begin
        if ~(keyword_set(nsteps)) then nsteps=5
        if ~(keyword_set(guess)) then guess=[0,0]
        xsteps = findgen(nsteps)/(nsteps-1)-0.5 + guess[0]
        ysteps = findgen(nsteps)/(nsteps-1)-0.5 + guess[1]
    endelse


    dim = (size(det))[1]

    mask2D = fltarr(dim,dim)
    
    cwv = get_cwv(filter)
    lmin = cwv.commonwavvect[0]
    lmax = cwv.commonwavvect[1]
    nl   = fix(cwv.commonwavvect[2])

    ;xsteps = [-2,-1.5, -0.5, -1, 0, 0.5, 1, 1.5, 2]
    ;ysteps = [-2, -1, 0, 1, 2]


    mask_traces = fltarr(dim,dim, n_elements(xsteps), n_elements(ysteps))

    xcors = fltarr(n_elements(xsteps), n_elements(ysteps))


    ;mask_trace_noshifts = fltarr(dim,dim)

    ; We compute here basically a brute-force cross-correlation. We do this
    ; because we are cross-correlating against not an image array, but
    ; instead a mask computed from an analytic wavelength solution, and this 
    ; way is more precise due to avoiding shifting after pixel quantization 

    nsteps = n_elements(ysteps)*n_elements(xsteps)
    reflam = median(wavcal[*,*,2])
    for iy =0,n_elements(ysteps)-1 do begin
    for ix =0,n_elements(xsteps)-1 do begin
        statusline, "Testing "+strc( ix+1+ n_elements(xsteps)*iy)+"/"+strc(nsteps)
        mask_trace = fltarr(dim,dim)

        for i=0,nl-1,2 do begin
            lam = cwv.lambda[i]
            dlam_pix = (lam - reflam) / wavcal[*,*,3]
            ;print, "wavelen:", lam, median(dlam_pix)
            X = wavcal[*,*,1] + dlam_pix * sin(wavcal[*,*,4])
            Y = wavcal[*,*,0] - dlam_pix * cos(wavcal[*,*,4])

            wg = where(finite(x) and finite(y))
            Xg = X[wg]
            Yg = Y[wg]
            ;mask_trace_noshifts[round(Xg),round(Yg)] += 1  ; Be sure to round here not truncate!
                ;print, iy, ix
                ;mask_trace = dblarr(dim,dim)
            mask_trace[round(Xg+xsteps[ix]),round(Yg+ysteps[iy])] += 1  ; Be sure to round here not truncate!
                ;mask_traces[round(X+xsteps[ix]),round(Y+ysteps[iy]),ix,iy] += 1
        end
        mask_traces[0,0,ix,iy] = (mask_trace ne 0) ; ignore multiple pixels set high

        xcors[ix,iy] = total(mask_trace*det,/nan)
    endfor
    endfor

    ;atv, reform(mask_traces, dim,dim,  n_elements(xsteps)*n_elements(ysteps)),/bl
if display ne -1 then begin
    window,display
    imdisp, xcors,/axis
endif
    whereismax, xcors, mx, my,/silent
    shiftx = xsteps[mx]
    shifty = ysteps[my]
    print, "Estimated shifts : "+strc(shiftx)+", "+strc(Shifty)

    return, [shiftx, shifty]

end



function gpi_update_spot_shifts_for_flexure, DataSet, Modules, Backbone
compile_opt defint32, strictarr, logical_predicate
primitive_version= '$Id$' ; get version from subversion to store in header history

@__start_primitive


  COMMON flexure_shifts_common, last_elevation, last_mjd, last_shifts
        ; for the last modeled file: the elevation, MJD, and shifts used are
        ; kept in a common block for efficient starting guess when processing
        ; a file similar in time for the automatic mode. Ignored otherwise.


  det=*(dataset.currframe[0])   ;get the 2D detector image
  dim=(size(det))[1]            ;detector sidelength in pixels
  
  mode = gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', count=c))
  case strupcase(strc(mode)) of
    'PRISM':  begin
      nlens=(size(wavcal))[1]       ;pixel sidelength of final datacube (spatial dimensions) 
      
    
      ;error handle if readwavcal not used before
      if (nlens eq 0) || (dim eq 0)  then begin
         return, error('FAILURE ('+functionName+'): Failed to load wavelength calibration data prior to calling this primitive.') 
      endif
    end
    'WOLLASTON':    begin
        polspot_coords = polcal.coords
        polspot_pixvals = polcal.pixvals
        polspot_spotpos = polcal.spotpos
        
        if ((size(polspot_coords))[0] eq 0) || (dim eq 0)  then begin
          return, error('FAILURE ('+functionName+'): Failed to load polarimetry calibration data prior to calling this primitive.') 
        endif

        nlens=(size(polspot_coords))[3] 
    end
    else: begin
           backbone->set_keyword, "HISTORY", "NO SHIFTS FOR FLEXURE APPLIED, Don't recognize current mode (PRISM|WOLLASTON)"
                   message,/info, "NO SHIFTS FOR FLEXURE APPLIED, Don't recognize current mode (PRISM|WOLLASTON)"
                   return,ok
    end
  endcase
  


  if tag_exist( Modules[thisModuleIndex], "display") then display=fix(Modules[thisModuleIndex].display) else display=-1
  if tag_exist( Modules[thisModuleIndex], "Method") then Method= strupcase(Modules[thisModuleIndex].method) else method="None"
  backbone->set_keyword, 'DRPFLEX', Method, ' Selected method for handling flexure-induced shifts'


  ; Switch based on requested method: 
  case strlowcase(Method) of
    'none': begin
        shiftx=0
        shifty=0
        backbone->Log, "NO shifts applied for flexure, because method=None",depth=2
        backbone->set_keyword, 'SPOT_DX', shiftx, ' No X shift applied for flexure'
        backbone->set_keyword, 'SPOT_DY', shifty, ' No Y shift applied for flexure'
    end
    'manual': begin
        shiftx= strupcase(Modules[thisModuleIndex].manual_dx)
        shifty= strupcase(Modules[thisModuleIndex].manual_dy)
        backbone->set_keyword, 'SPOT_DX', shiftx, ' User manually set lenslet PSF X shift'
        backbone->set_keyword, 'SPOT_DY', shifty, ' User manually set lenslet PSF Y shift'
    end
    'bandshift': begin
        referencex = 1025.0
        referencey = 1008.0
        offsetstable=[[0.0827484130859, -0.725752610427],[0.0807710535386, 21.2717500574],[-1.28990246001, -29.3275960286],[-1.02818661644, -29.7074904669],[0.491973876953, 35.8689860026]] ;Updated May 7, 2018
        ;offsetstable=[[-1.0921069159, 1.77147995216],[-0.609225365423, 22.5658628402],[-1.84011404855, -28.2399793352],[-1.26617050171, -28.7445812225],[-0.509966169085, 37.7846505301]]
        ;offsetstable = [[0.909729003906,-0.230499267578],[1.11206054688,21.3256225586],[0.625366210938,-30.5368652344],[0.666259765625,-30.3093261719],[-1.51550292969, 37.090250651]] ;[x,y] offset values for H, J, K1, K2, Y
        my_filter =  gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=c))
      
        bandxpos = wavcal[140,140,1]
        bandypos = wavcal[140,140,0]
        ;print, 'K2 wavecal location: '+sigfig(bandxpos,5)+'  '+sigfig(bandypos,5)


        ;read in the most recent wavecal regardless of band
        c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( 'wavecal', *(dataset.headersphu)[numfile],*(dataset.headersext)[numfile], /ignore_band)
        backbone->Log, 'Shifts calculated using: '+c_file, depth=2
        refwavecal = gpi_readfits(c_File,header=Header,priheader=Priheader)
        ;break
        refoffsetx = refwavecal[140,140,1]
        refoffsety = refwavecal[140,140,0]
        ;print, 'H wavecal location: '+sigfig(refoffsetx,5)+'  '+sigfig(refoffsety,5)
        reference_filter = gpi_get_keyword(Priheader, Header, 'IFSFILT', count=ct)
        ref_filter = gpi_simplify_keyword_value(reference_filter)

        case ref_filter of
           'H': bulkoffsets = offsetstable[*,0]
           'J': bulkoffsets = offsetstable[*,1]
           'K1': bulkoffsets = offsetstable[*,2]
           'K2': bulkoffsets = offsetstable[*,3]
           'Y': bulkoffsets = offsetstable[*,4]
        endcase
        case my_filter of
           'H': mybulkoffsets = offsetstable[*,0]
           'J': mybulkoffsets = offsetstable[*,1]
           'K1': mybulkoffsets = offsetstable[*,2]
           'K2': mybulkoffsets = offsetstable[*,3]
           'Y': mybulkoffsets = offsetstable[*,4]
        endcase
        myxoffset = bandxpos - referencex
        myyoffset = bandypos - referencey
        bandshiftx = (refoffsetx - bandxpos) + (mybulkoffsets[0] - bulkoffsets[0])
        bandshifty = (refoffsety - bandypos) + (mybulkoffsets[1] - bulkoffsets[1])
        ;backbone->set_keyword, 'SPOT_DX', shiftx, ' (lenslet PSF X shift)'
        ;backbone->set_keyword, 'SPOT_DY', shifty, ' (lenslet PSF Y shift)'

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;;;;;;;;;;; Now Including the Lookup Table Flexure ;;;;;;;;;;;;;;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        my_elevation =  double(backbone->get_keyword('ELEVATIO', count=ct))
        ; the above line returns zero if no keyword is found. This is
        ; acceptable since all data taken without this keyword has an
        ; elevation of zero!

        calfiletype = 'shifts'

        c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( calfiletype, *(dataset.headersphu)[numfile],*(dataset.headersext)[numfile], /ignore_cooldown_cycles)
	if ( ~ file_test ( string(c_file) ) ) then begin
		return, error ('error in call ('+strtrim(functionname)+'): calibration file  ' +  strtrim(string(c_file),2) + ' not found.' )
	endif

	c_file = gpi_expand_path(c_file)

	lookuptable = gpi_readfits(c_File,header=Header)


	;;now calculate shifts of the quick wavelength solution
        wc_elevation = double(gpi_get_keyword(Priheader, Header, 'ELEVATIO', count=ct))
        backbone->Log,'quick wavecal elevation: '+sigfig(wc_elevation,3),depth=2
	if ct eq 0  then begin
		return, error ('error in call ('+strtrim(functionname)+'): Wavelength solution elevation not found.' )
	endif
		
	shifts = gpi_flexure_model(lookuptable, my_elevation, wavecal_elevation=wc_elevation, display=display)
	tableshiftx = shifts[0]
	tableshifty = shifts[1]
                
        ; COMBINE SHIFTS FROM BANDSHIFT AND LOOKUP TABLE
        shiftx = bandshiftx+tableshiftx
        shifty = bandshifty+tableshifty
	 
        backbone->set_keyword, 'SPOT_DX', shiftx, ' Applied lenslet PSF X shift for flexure'
	backbone->set_keyword, 'SPOT_DY', shifty, ' Applied lenslet PSF Y shift for flexure'

        
    end
    'lookup': begin
        my_elevation =  double(backbone->get_keyword('ELEVATIO', count=ct))
        ; the above line returns zero if no keyword is found. This is
        ; acceptable since all data taken without this keyword has an
        ; elevation of zero!

        calfiletype = 'shifts'

        c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( calfiletype, *(dataset.headersphu)[numfile],*(dataset.headersext)[numfile], /ignore_cooldown_cycles)
		if ( ~ file_test ( string(c_file) ) ) then begin
			return, error ('error in call ('+strtrim(functionname)+'): calibration file  ' +  strtrim(string(c_file),2) + ' not found.' )
		endif

		c_file = gpi_expand_path(c_file)

		lookuptable = gpi_readfits(c_File,header=Header)


		;;now calculate shifts of the current wavelength solution
		wc_elevation= backbone->get_keyword('WVELEV', count=ct)
                backbone->Log,'wavecal elevation: '+sigfig(wc_elevation,3),depth=2
		if ct eq 0  then begin
			return, error ('error in call ('+strtrim(functionname)+'): Wavelength solution elevation not found.' )
		endif
		

		shifts = gpi_flexure_model(lookuptable, my_elevation, wavecal_elevation=wc_elevation, display=display)
		shiftx = shifts[0]
		shifty = shifts[1]

	 
		backbone->set_keyword, 'SPOT_DX', shiftx, ' Applied lenslet PSF X shift for flexure'
		backbone->set_keyword, 'SPOT_DY', shifty, ' Applied lenslet PSF Y shift for flexure'

   
;		elevtable=lookuptable[*,0]
;		xtable=lookuptable[*,1]
;		ytable=lookuptable[*,2]
;		;if ct ge 1 then begin
;		elevsortedind=sort(elevtable)
;		sortedelev=elevtable[elevsortedind]
;		sortedxshift=xtable[elevsortedind]
;		sortedyshift=ytable[elevsortedind]
;		  
;		;;polynomial fit
;		shiftpolyx = POLY_FIT( sortedelev, sortedxshift, 2)
;		shiftpolyy = POLY_FIT( sortedelev, sortedyshift, 2)
;		my_shiftx=shiftpolyx[0]+shiftpolyx[1]*my_elevation+(my_elevation^2)*shiftpolyx[2]
;		my_shifty=shiftpolyy[0]+shiftpolyy[1]*my_elevation+(my_elevation^2)*shiftpolyy[2]
;
;    wcshiftx=shiftpolyx[0]+shiftpolyx[1]*wc_elevation+(wc_elevation^2)*shiftpolyx[2]
;    wcshifty=shiftpolyy[0]+shiftpolyy[1]*wc_elevation+(wc_elevation^2)*shiftpolyy[2]
;    
;    ;;now calculate the absolute shifts independent of the reference 
;      shiftx= wcshiftx - my_shiftx
;      shifty= wcshifty - my_shifty 
;		if display ne -1 then begin
;                   if display eq 0 then window,/free else select_window, display
;			!p.multi=[0,2,1]
;			elevs = findgen(90)
;			plot, sortedelev, sortedxshift, xtitle='Elevation [deg]', ytitle='X shift from Flexure [pixel]', xrange=[-10,100], yrange=[-0.9, 0.1], psym=1, charsize=1.5
;			oplot, elevs, poly(elevs, shiftpolyx), /line
;			oplot, [my_elevation], [shiftx], psym=2, color=fsc_color('yellow'), symsize=2
;			oplot, [my_elevation,my_elevation],[-1,1], color=fsc_color("blue"), linestyle=2
;			oplot, [wc_elevation,wc_elevation],[-1,1], color=fsc_color("red"), linestyle=2
;
;			plot, sortedelev, sortedyshift, xtitle='Elevation [deg]', ytitle='Y shift from Flexure [pixel]', xrange=[-10,100], yrange=[-0.9, 0.1], psym=1, charsize=1.5
;			oplot, elevs, poly(elevs, shiftpolyy), /line
;			oplot, [my_elevation], [shifty], psym=2, color=fsc_color('yellow'), symsize=2
;			oplot, [my_elevation,my_elevation],[-0.6,1], color=fsc_color("blue"), linestyle=2
;      oplot, [wc_elevation,wc_elevation],[-0.6,1], color=fsc_color("red"), linestyle=2
;
;			legend,/bottom,/right, ['Shifts in lookup table','Model','Applied shift','Data Elevation','Calibration Elevation'], color=[!p.color, !p.color, fsc_color('yellow'), fsc_color('blue'), fsc_color('red')], line=[0,1,1,2,2], psym=[1,0,2,0,0], charsize=1.5
;			xyouts, 0.5, 0.96, /normal, "Flexure Shift Model for "+backbone->get_keyword('DATAFILE'), charsize=1.8, alignment=0.5
;                        !p.multi = 0
;		endif
;
   
    end
    'auto': begin
        ;------------ Experimental code for automatic flexure measurement ----------
        
        if ~strcmp(mode,'PRISM') then begin
          backbone->set_keyword, "HISTORY", "NO SHIFTS FOR FLEXURE APPLIED, Method auto is not implemented for another mode than PRISM"
                   message,/info, "NO SHIFTS FOR FLEXURE APPLIED, Method auto is not implemented for another mode than PRISM"
                   return,ok
        endif
                
        ;define the common wavelength vector with the IFSFILT keyword:
        filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
        if (filter eq '') then return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 
        
        ;get length of spectrum
        sdpx = calc_sdpx(wavcal, filter, spectra_startys, CommonWavVect, spectra_stopys)
        if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')
        

        backbone->Log, "Generating spectra traces to scan for flexure shifts"

        my_elevation =  backbone->get_keyword('ELEVATIO', count=ct)
        my_mjd = backbone->get_keyword('MJD-OBS', count=ct)
        if my_mjd eq 0.0 then begin
            ; work around broken GDS config
            my_mjd = date_conv( backbone->get_keyword('DATE-OBS')+" "+backbone->get_keyword('UTSTART'),'M')
        endif

        ; if within 5 degrees and 10 minutes of prior exposure, re-use from last
        ; starting guess

        if n_elements(last_elevation) ne 0 and n_elements(last_mjd) ne 0 then $
            if (last_elevation - my_elevation) lt 5 and (last_mjd - my_mjd) lt 1./24/6 then reuse_last=1
        
        
        if keyword_set(reuse_last) then begin
            shifts = last_shifts
            backbone->Log, "Using last image's shifts as a starting guess: "+strc(shifts[0])+", "+strc(shifts[1])

        endif else begin
            backbone->Log, "Making a first coarse estimate of shifts"
            shifts = update_shifts_for_flexure_auto_optimize(det, wavcal, filter, /coarse,display=display)
            backbone->Log, "Coarse shift estimate = "+strc(shifts[0])+", "+strc(shifts[1])
        endelse

        backbone->Log, "Refining estimate of shifts"
        fineshifts = update_shifts_for_flexure_auto_optimize(det, wavcal, filter, guess=shifts, display=display)

        shiftx = fineshifts[0]
        shifty = fineshifts[1]
        ;get tilts of the spectra included in the wavelength solution:
        ;tilt=wavcal[*,*,4]
        
        ; Create a simple 2D image showing the 'trace' of each spectrum
        ;stop

;        for i=0,sdpx-1 do begin       
;               ;through spaxels
;               cubef=dblarr(nlens,nlens) 
;               ;get the locations on the image where intensities will be extracted:
;               y3=spectra_startys-i
;
;               x3=wavcal[*,*,1]+(wavcal[*,*,0]-y3)*tan(tilt[*,*])    
;              
;             wg = where(y3 gt spectra_stopys, goodct)
;             ; mark pixels that will be used in the extraction
;               if goodct gt 0 then mask2D[x3[wg],y3[wg]] = 1
;        endfor
;        
;        
;        ; now let's cross-correlate the central part of that mask with the
;        ; central part of the datacube
;        cx = 1024
;        cy = 1024
;        
;        hbx = 256 ; half box size
;        
;        cen_mask = mask2D[ cx-hbx:cx+hbx-1, cy-hbx:cy+hbx-1]
;        cen_det  =    det[ cx-hbx:cx+hbx-1, cy-hbx:cy+hbx-1]
;        
;        cor = convolve(cen_mask,cen_det,/correlate)
;
;        ; let's assume the total shift must be <4 pixels absolute in any
;        ; direction
;        maxshift=4
;        cor_middle = cor[ hbx-maxshift:hbx+maxshift, hbx-maxshift:hbx+maxshift]
;
;        findmaxstar,cor_middle,xi,yi,/silent       ; get rough center
;        mrecenter,cor_middle,xi,yi,x,y,/silent,/nodisp  ; get fine center
;        
;        shiftx = maxshift - x
;        shifty = maxshift - y

        backbone->set_keyword, 'SPOT_DX', shiftx, 'Measured X shift inferred for flexure'
        backbone->set_keyword, 'SPOT_DY', shifty, 'Measured Y shift inferred for flexure'
        backbone->Log, "Via cross correlation estimated shifts to be "+strc(shiftx)+", "+strc(shifty)
    
        

        ; Save the measured/estimated shifts for use in processing subsequent
        ; files.  Only do this for automatic mode - there is no benefit to
        ; saving manual or lookup table shifts. 
        last_elevation =  my_elevation
        last_mjd = my_mjd
        last_shifts = [shiftx, shifty]
       

    end
    endcase

  case strupcase(strc(mode)) of
    'PRISM':  begin
      ;  Now we actually apply the shifts to the wavelength solution
      wavcal[*,*,0]+=shifty
      wavcal[*,*,1]+=shiftx  
    end
    'WOLLASTON':    begin
       ;  Now we actually apply the shifts to the wavelength solution
       polspot_coords[0,*,*,*,*]+=shiftx
       polspot_coords[1,*,*,*,*]+=shifty
       polspot_spotpos[0,*,*,*]+=shiftx
       polspot_spotpos[1,*,*,*]+=shifty
       
       polcal.coords = polspot_coords
       polcal.spotpos = polspot_spotpos
    end
  endcase
     
    logmsg = "Applied shifts of "+strc(shiftx)+", "+strc(shifty)+" based on method="+method
    backbone->Log, logmsg, depth=3
    backbone->set_keyword, "HISTORY", "  "+logmsg


;--- for this one, we don't call the usual __end_primitive common code
;    because we want to special handle the gpitv display.

	save_suffix=suffix
	; prepend dash if needed
	if strmid(save_suffix,0,1) ne '-' then save_suffix = '-'+save_suffix

	; first save the file if desired, with no attempt at display
	if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
	    b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, save_suffix, output_filename=output_filename)
      	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
	endif
 

    ; special handle the gpitv display here - display the 2D image with wavecal
    ; overplotted and this will include the shifts
    if tag_exist( Modules[thisModuleIndex], "gpitv") then begin
        gpitvsession=fix(Modules[thisModuleIndex].gpitv) 
        if gpitvsession ne 0 then begin
            prism = gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR'))
            case prism of
            'PRISM': calfilename =  backbone->get_keyword('DRPWVCLF') 
            'WOLLASTON': calfilename =  backbone->get_keyword('DRPPOLCF') 
            endcase
            
			if keyword_set(output_filename) then begin
				; gpitv display of the saved output file
				;
				backbone_comm->gpitv, output_filename , session=gpitvsession, $
					dispwavecalgrid=calfilename


			endif else begin
				; gpitv display of the array in memory

				backbone_comm->gpitv, *dataset.currframe , session=gpitvsession, $
					header=*(dataset.headersPHU)[numfile],  $
					extheader=*(dataset.headersEXT)[numfile], $ 
					dispwavecalgrid=calfilename

			endelse
        endif
    endif 

   	if tag_exist( Modules[thisModuleIndex], "stopidl") then if keyword_set( Modules[thisModuleIndex].stopidl) then stop

	return, ok


end

