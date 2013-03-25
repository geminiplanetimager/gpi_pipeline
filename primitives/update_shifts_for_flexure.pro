;+
; NAME: update_shifts_for_flexure
; PIPELINE PRIMITIVE DESCRIPTION: Update Spot Shifts for Flexure
;
;
; KEYWORDS: 
; GEM/GPI KEYWORDS:IFSFILT
; OUTPUTS:
;
; PIPELINE COMMENT: Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis
; PIPELINE ARGUMENT: Name="method" Type="string" Range="[None|Manual|Lookup|Auto]" Default="None" Desc='How to accomodate spot position shifts due to flexure?'
; PIPELINE ARGUMENT: Name="manual_dx" Type="float" Range="[-10,10]" Default="0" Desc="If method=Manual, the X shift of spectra at the center of the detector"
; PIPELINE ARGUMENT: Name="manual_dy" Type="float" Range="[-10,10]" Default="0" Desc="If method=Manual, the Y shift of spectra at the center of the detector"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.99
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: SpectralScience, Calibration
;
; HISTORY:
;   2013-03-08 MP: Started based on extractcube
;-


function update_shifts_for_flexure_auto_optimize, det, wavcal, filter, coarse=coarse, guess=guess, nsteps=nsteps

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

		xcors[ix,iy] = total(mask_trace*det)
	endfor
	endfor

	;atv, reform(mask_traces, dim,dim,  n_elements(xsteps)*n_elements(ysteps)),/bl

	window, 0
	imdisp, xcors,/axis
	whereismax, xcors, mx, my,/silent
	shiftx = xsteps[mx]
	shifty = ysteps[my]
	print, "Estimated shifts : "+strc(shiftx)+", "+strc(Shifty)

	return, [shiftx, shifty]

end



function update_shifts_for_flexure, DataSet, Modules, Backbone
primitive_version= '$Id: extractcube.pro 1175 2013-01-17 06:48:58Z mperrin $' ; get version from subversion to store in header history
@__start_primitive


	COMMON flexure_shifts_common, last_elevation, last_mjd, last_shifts
		; for the last modeled file: the elevation, MJD, and shifts used are
		; kept in a common block for efficient starting guess when processing
		; a file similar in time for the automatic mode. Ignored otherwise.


  ;get the 2D detector image
  det=*(dataset.currframe[0])

  nlens=(size(wavcal))[1]       ;pixel sidelength of final datacube (spatial dimensions) 
  dim=(size(det))[1]            ;detector sidelength in pixels

  ;error handle if readwavcal or not used before
  if (nlens eq 0) || (dim eq 0)  then $
     return, error('FAILURE ('+functionName+'): Failed to load wavelength calibration data prior to calling this primitive.') 


  if tag_exist( Modules[thisModuleIndex], "Method") then Method= strupcase(Modules[thisModuleIndex].method) else method="None"
  backbone->set_keyword, 'DRPFLEX', Method, 'Selected method for handling flexure-induced shifts'


  ; Switch based on requested method: 
  case strlowcase(Method) of
	'none': begin
		shiftx=0
		shifty=0
	    backbone->Log, "NO shifts applied for flexure, because method=None",depth=2
		backbone->set_keyword, 'SPOT_DX', shiftx, 'No X shift applied for flexure'
		backbone->set_keyword, 'SPOT_DY', shifty, 'No Y shift applied for flexure'
	end
	'manual': begin
		shiftx= strupcase(Modules[thisModuleIndex].manual_dx)
		shifty= strupcase(Modules[thisModuleIndex].manual_dy)
		backbone->set_keyword, 'SPOT_DX', shiftx, 'User manually set X shift for flexure'
		backbone->set_keyword, 'SPOT_DY', shifty, 'User manually set Y shift for flexure'
	end
	'lookup': begin
    my_elevation =  backbone->get_keyword('ELEVATIO', count=ct)
		calfiletype = 'shifts'
    c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( calfiletype, *(dataset.headersphu)[numfile],*(dataset.headersext)[numfile] ) 
    c_file = gpi_expand_path(c_file)
    lookuptable = gpi_readfits(c_File,header=Header)
    ;;sanity check: are we using the same shift reference file?
      
      wavcalname=backbone->get_keyword('DRPWVCLF', count=cw)
      shiftref = SXPAR( Header, "SHIFTREF", COUNT=cr)
      if wavcalname eq shiftref then begin 
    
        		xtable=lookuptable[*,1]
        		ytable=lookuptable[*,2]
        		elevtable=lookuptable[*,0]
        		if ct ge 1 then begin
        		  elevsortedind=sort(elevtable)
        		  sortedelev=elevtable[elevsortedind]
        		  sortedxshift=xtable[elevsortedind]
        		  sortedyshift=ytable[elevsortedind]
        		  
        		  ;;polynomial fit
        		  shiftpolyx = POLY_FIT( sortedelev, sortedxshift, 2)
        		  shiftpolyy = POLY_FIT( sortedelev, sortedyshift, 2)
        		      shiftx=shiftpolyx[0]+shiftpolyx[1]*my_elevation+(my_elevation^2)*shiftpolyx[2]
                  shifty=shiftpolyy[0]+shiftpolyy[1]*my_elevation+(my_elevation^2)*shiftpolyy[2]
;                  fshiftx=shiftpolyx[0]+shiftpolyx[1]*findgen(90)+(findgen(90)^2)*shiftpolyx[2]
;                  fshifty=shiftpolyy[0]+shiftpolyy[1]*findgen(90)+(findgen(90)^2)*shiftpolyy[2]
;        		  
;        	psFilename = "Z:\"+"flex_xfit.ps"    
;          openps, psFilename
;          plot, elevtable,xtable, xtitle='Elevation [deg]', ytitle='Shift [pixel]',psym=-1
;          oplot, findgen(90),fshiftx,linestyle=2
;          closeps
;                    psFilename = "Z:\"+"flex_yfit.ps"    
;          openps, psFilename
;          plot, elevtable,ytable, xtitle='Elevation [deg]', ytitle='Shift [pixel]',psym=-1
;          oplot, findgen(90),fshifty,linestyle=2
;          closeps
        		  
;        		  indeq= where(sortedelev eq my_elevation,ceq)
;        		  if ceq gt 0 then begin
;        		      shiftx=mean(sortedxshift[indeq])
;        		      shifty=mean(sortedyshift[indeq])
;        		  endif else begin
;        		      indlt= where(sortedelev lt my_elevation,clt)
;                  indgt= where(sortedelev gt my_elevation,cgt)
;                  if (clt gt 0) && (cgt gt 0) then begin
;                      shiftx=mean(sortedxshift[indlt[n_elements(indlt)-1]])
;                      shifty=mean(sortedyshift[indgt[0]])                      
;                  endif 
;                  if (clt eq 0)then begin
;                      shiftx=mean(sortedxshift[0])
;                      shifty=mean(sortedyshift[0])                      
;                  endif 
;                  if (cgt eq 0)then begin
;                      shiftx=mean(sortedxshift[n_elements(sortedxshift)-1])
;                      shifty=mean(sortedyshift[n_elements(sortedyshift)-1])                      
;                  endif 
;        		  endelse
        		  
          		;shiftx = INTERPOL(xtable, elevtable, my_elevation) 
          		;shifty = INTERPOL(ytable, elevtable, my_elevation)
          		backbone->set_keyword, 'SPOT_DX', shiftx, 'User manually set X shift for flexure'
              backbone->set_keyword, 'SPOT_DY', shifty, 'User manually set Y shift for flexure'
            endif else begin
                  backbone->Log, "No ELEVATIO keyword found in image. No shifting applied."
                  shiftx = 0.
                  shifty = 0.
            endelse
         endif else begin
                  backbone->Log, "Shift reference files are different. No shifting applied."
                  shiftx = 0.
                  shifty = 0.
         endelse   
   
	end
	'auto': begin
		;------------ Experimental code for automatic flexure measurement ----------
				
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
			shifts = update_shifts_for_flexure_auto_optimize(det, wavcal, filter, /coarse)
			backbone->Log, "Coarse shift estimate = "+strc(shifts[0])+", "+strc(shifts[1])
		endelse

		backbone->Log, "Refining estimate of shifts"
		fineshifts = update_shifts_for_flexure_auto_optimize(det, wavcal, filter, guess=shifts)

		shiftx = fineshifts[0]
		shifty = fineshifts[1]
		;get tilts of the spectra included in the wavelength solution:
		;tilt=wavcal[*,*,4]
		
		; Create a simple 2D image showing the 'trace' of each spectrum
		;stop

;		for i=0,sdpx-1 do begin       
;      		 ;through spaxels
;      		 cubef=dblarr(nlens,nlens) 
;      		 ;get the locations on the image where intensities will be extracted:
;      		 y3=spectra_startys-i
;
;      		 x3=wavcal[*,*,1]+(wavcal[*,*,0]-y3)*tan(tilt[*,*])	
;      		
;			 wg = where(y3 gt spectra_stopys, goodct)
;			 ; mark pixels that will be used in the extraction
;      		 if goodct gt 0 then mask2D[x3[wg],y3[wg]] = 1
;		endfor
;		
;		
;		; now let's cross-correlate the central part of that mask with the
;		; central part of the datacube
;		cx = 1024
;		cy = 1024
;		
;		hbx = 256 ; half box size
;		
;		cen_mask = mask2D[ cx-hbx:cx+hbx-1, cy-hbx:cy+hbx-1]
;		cen_det  =    det[ cx-hbx:cx+hbx-1, cy-hbx:cy+hbx-1]
;		
;		cor = convolve(cen_mask,cen_det,/correlate)
;
;		; let's assume the total shift must be <4 pixels absolute in any
;		; direction
;		maxshift=4
;		cor_middle = cor[ hbx-maxshift:hbx+maxshift, hbx-maxshift:hbx+maxshift]
;
;		findmaxstar,cor_middle,xi,yi,/silent       ; get rough center
;		mrecenter,cor_middle,xi,yi,x,y,/silent,/nodisp  ; get fine center
;		
;		shiftx = maxshift - x
;		shifty = maxshift - y

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


	;  Now we actually apply the shifts to the wavelength solution
    wavcal[*,*,0]+=shifty
    wavcal[*,*,1]+=shiftx       
	logmsg = "Applied shifts of "+strc(shiftx)+", "+strc(shifty)+" based on method="+method
	backbone->Log, logmsg
	backbone->set_keyword, "HISTORY", functionname+": "+logmsg
    backbone->set_keyword, "HISTORY", functionname+": wavecal shift dx: "+strc(shiftx,format="(f7.2)")
    backbone->set_keyword, "HISTORY", functionname+": wavecal shift dy: "+strc(shifty,format="(f7.2)")




	; special handle the gpitv display here - display the 2D image with wavecal
	; overplotted and this will include the shifts
	if tag_exist( Modules[thisModuleIndex], "gpitv") then begin
		display=fix(Modules[thisModuleIndex].gpitv) 
		if display ne 0 then begin
			prism = gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR'))
			case prism of
			'PRISM': calfilename =  backbone->get_keyword('DRPWVCLF') 
			'WOLLASTON': calfilename =  backbone->get_keyword('DRPPOLCF') 
			endcase

			backbone_comm->gpitv, *dataset.currframe , session=display, $
				header=*(dataset.headersPHU)[numfile],  $
				extheader=*(dataset.headersEXT)[numfile], $ 
				dispwavecalgrid=calfilename

			; disable gpitv flag to prevent regular gpitv displaying in
			; @__end_primitive
			Modules[thisModuleIndex].gpitv = 0 

		endif
	endif 

@__end_primitive

end

