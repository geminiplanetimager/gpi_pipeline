;+
; NAME: gpi_remove_flat_lamp_spectrum
; PIPELINE PRIMITIVE DESCRIPTION: Remove Flat Lamp spectrum
;                                 Rescale flat-field (keep large scale variations)
;
;
; INPUTS: data-cube
;
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: FILETYPE, ISCALIB
; OUTPUTS:  datacube with slice at the same wavelength
;
; PIPELINE COMMENT: Fit the lamp spectrum and remove it (for delivering flat field cubes)
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="method" Type="string" Range="polyfit|linfit|blackbody|none" Default="blackbody" Desc="Method to use for removing lamp spectrum"

; PIPELINE ORDER: 2.25
; PIPELINE NEWTYPE: Calibration
;
; HISTORY:
; 	2009-06-20 JM: created
; 	2009-07-22 MP: added doc header keywords
; 	2012-10-11 MP: added min/max wavelength checks
; 	2013-07-17 MP: Rename for consistency
;   2013-12-03 MP: Add check for GCALLAMP=QH on input images 
;-

function gpi_remove_flat_lamp_spectrum, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
	suffix='specflat'

	cubef3D=*dataset.currframe


	my_lamp = backbone->get_keyword('GCALLAMP')
	if strc(my_lamp) ne "QH" then return,  error('FAILURE ('+functionName+'): Expected quartz halogen flat lamp images as input, but GCALLAMP != QH.')


    nlens=(size(wavcal))[1]
  	;;get length of spectrum
  	sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)
  	if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')

	;;before doing anything we need to take into account length of spectra so the
	;; the median of all spectra is not affected by flux concentration due to smaller spectrum length
	;; in the Fov

  	for zz=0,(size(cubef3D))[3]-1 do cubef3D[*,*,zz]/=wavcal[*,*,3]
	;;take into account filter transmission
 	cwv=get_cwv(filter)
	lambda=cwv.lambda

	meth=Modules[thisModuleIndex].method
  	Result=dblarr(nlens,nlens,sdpx)+!VALUES.F_NAN
  
  	;for rescaling, keep median value of each spectrum
  	medianspectrum=median(cubef3D[*,*,5:12], dimension=3)
  	indNan=where(~FINITE(cubef3D[*,*,0]),cc)
  	if cc ne 0 then medianspectrum[indNan]=!VALUES.F_NAN
  	;calculate median of median values
  	medtot=median(medianspectrum)
  
  	message,/info, 'Extracting flat-field; Removing lamp spectrum...'
  	for xsi=0,nlens-1 do begin	
    	for ysi=0,nlens-1 do begin
			if finite(xmini[xsi,ysi]) then begin
				valx=double(xmini[xsi,ysi]-findgen(sdpx))
					lambint=wavcal[xsi,ysi,2]-wavcal[xsi,ysi,3]*(valx-wavcal[xsi,ysi,0])*(1./cos(wavcal[xsi,ysi,4]))
					;if (xsi eq 140) && (ysi eq 140) then stop
				;    Transmfiltnominal=pipeline_getfilter(lambint,filter=filter)
				;    spectrum0=reform(cubef3D[xsi,ysi,*])
				;    spectrum=spectrum0/Transmfiltnominal
				spectrum=reform(cubef3D[xsi,ysi,*])
			  ;if Modules[thisModuleIndex].method eq 'blackbody' then   lampspec=planck(10000*lambint,tempelamp)/median(planck(10000*lambint,tempelamp))
			  ;linear fit:
			  ;do not use pixels on the edges of spectrum, use central part
				sz=n_elements(lambint)
				offsetpix=floor(sz/4)-1
				indforfit=offsetpix+indgen(sz-2*offsetpix)
				meth=Modules[thisModuleIndex].method
				case meth of 
				  'linfit':begin
							res=linfit(lambint[indforfit], (spectrum)[indforfit] )
						  lampspec=res[0]+res[1]*lambint
							end
				  'polyfit':begin
						  res=POLY_FIT(lambint[indforfit], (spectrum)[indforfit], 2, MEASURE_ERRORS=measure_errors, SIGMA=sigma) 
						  lampspec=res[0]+res[1]*lambint+res[2]*(lambint)^2.                
						  end
				'blackbody':begin
						  tempelampe = 1100
						  lampspec=(planck(10000*lambint,tempelampe)/mean(planck(10000*lambint,tempelampe)))*medianspectrum[xsi,ysi] ;mean((spectrum)[indforfit])
							end
				;else:   lampspec=replicate(median((spectrum)[indforfit]), n_elements(lambint))
				else:   lampspec=replicate(medianspectrum[xsi,ysi], n_elements(lambint))
			   endcase        
	  
	  
			  
				;toDO:implement other methods
			  ; remove the linear fit.
			  Result[xsi,ysi,*] = reform(( spectrum/lampspec) *medianspectrum[xsi,ysi] /medtot, 1,1,sz)
			  ;Result[xsi,ysi,*] = reform(( spectrum0/lampspec) *medianspectrum[xsi,ysi] /medtot, 1,1,sz)
	 ; 		  if (xsi gt 140) && (ysi gt 140) then stop
			endif
  	  endfor
  	endfor

	*(dataset.currframe[0])=Result

    backbone->set_keyword,  "DRP_WMIN", min(cwv.lambda), 'Wavelength Min for this extracted flat field data', ext_num=0
    backbone->set_keyword,  "DRP_WMAX", max(cwv.lambda), 'Wavelength Max for this extracted flat field data', ext_num=0
	backbone->set_keyword,  "FILETYPE", 'Flat Field', "What kind of IFS file is this?"
	backbone->set_keyword,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'


@__end_primitive



end
