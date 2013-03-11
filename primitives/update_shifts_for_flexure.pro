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
function update_shifts_for_flexure, DataSet, Modules, Backbone
primitive_version= '$Id: extractcube.pro 1175 2013-01-17 06:48:58Z mperrin $' ; get version from subversion to store in header history
@__start_primitive


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

		message, 'Finding flexures from a lookup table is not yet implemented!'
	end
	'auto': begin
		;------------ Experimental code for automatic flexure measurement ----------
				
		;define the common wavelength vector with the IFSFILT keyword:
		filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
		if (filter eq '') then return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 
		
		;get length of spectrum
		sdpx = calc_sdpx(wavcal, filter, spectra_startys, CommonWavVect)
		if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')
		
		;get tilts of the spectra included in the wavelength solution:
		tilt=wavcal[*,*,4]
		
		; Create a simple 2D image showing the 'trace' of each spectrum
		mask2D = fltarr(dim,dim)
		
		for i=0,sdpx-1 do begin       
		 ;through spaxels
		 cubef=dblarr(nlens,nlens) 
		 ;get the locations on the image where intensities will be extracted:
		 y3=spectra_startys-i
		 x3=wavcal[*,*,1]+(wavcal[*,*,0]-x3)*tan(tilt[*,*])	
		
		 ;extract intensities on a 3x1 box:
		 ;cubef=det[y3,x3]+det[y3+1,x3]+det[y3-1,x3]
		 mask2D[x3,y3] = 1
		endfor
		
		
		; now let's cross-correlate the central part of that mask with the
		; central part of the datacube
		cx = 1024
		cy = 1024
		
		hbx = 256 ; half box size
		
		cen_mask = mask2D[ cx-hbx:cx+hbx-1, cy-hbx:cy+hbx-1]
		cen_det  =    det[ cx-hbx:cx+hbx-1, cy-hbx:cy+hbx-1]
		
		cor = convolve(cen_mask,cen_det,/correlate)
		findmaxstar,cor,xi,yi,/silent       ; get rough center
		mrecenter,cor,xi,yi,x,y,/silent,/nodisp  ; get fine center
		
		shiftx = hbx - x
		shifty = hbx - y
		backbone->set_keyword, 'SPOT_DX', shiftx, 'Measured X shift inferred for flexure'
		backbone->set_keyword, 'SPOT_DY', shifty, 'Measured Y shift inferred for flexure'
	
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
			wavecalfilename =  backbone->get_keyword('DRPWVCLF') 
			backbone_comm->gpitv, *dataset.currframe , session=display, $
				header=*(dataset.headersPHU)[numfile],  $
				extheader=*(dataset.headersEXT)[numfile], $ 
				dispwavecalgrid=wavecalfilename

			; disable gpitv flag to prevent regular gpitv displaying in
			; @__end_primitive
			Modules[thisModuleIndex].gpitv = 0 

		endif
	endif 

@__end_primitive

end

