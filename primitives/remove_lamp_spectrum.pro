;+
; NAME: Remove_lamp_spectrum
; PIPELINE PRIMITIVE DESCRIPTION: Remove Flat Lamp spectrum
;                                 Rescale flat-field (keep large scale variations)
;
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	/Save	set to 1 to save the output image to a disk file. 
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: FILETYPE, ISCALIB
; OUTPUTS:  datacube with slice at the same wavelength
;
; PIPELINE COMMENT: Fit the lamp spectrum and remove it (for delivering flat field cubes)
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="method" Type="string" Range="polyfit|linfit|blackbody" Default="blackbody" Desc="Method to use for removing lamp spectrum"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-specflat" Desc="Enter output suffix"

; PIPELINE ORDER: 2.25
; PIPELINE TYPE: CAL-SPEC
; PIPELINE SEQUENCE: 21-
;
; HISTORY:
; 	2009-06-20: JM created
; 	2009-07-22: MDP added doc header keywords
;-

function Remove_lamp_spectrum, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

	cubef3D=*(dataset.currframe[0])
	;if Modules[thisModuleIndex].method eq 'blackbody' then $
	;tempelamp=Modules[thisModuleIndex].tempelamp

    cwv=get_cwv(filter)
    CommonWavVect=cwv.CommonWavVect
    lambda=cwv.lambda
	lambdamin=CommonWavVect[0]
	lambdamax=CommonWavVect[1]
	nlens=(size(wavcal))[1]

	;what is the pixel corresponding to lambda_min?
	xmini=(change_wavcal_lambdaref( wavcal, lambdamin))[*,*,0]
	xminifind=where(finite(xmini))
	xmini[xminifind]=floor(xmini[xminifind])
	;what is the pixel corresponding to lambda_max?
	xmaxi=(change_wavcal_lambdaref( wavcal, lambdamax))[*,*,0]
	;length of spectrum in pix
	;sdpx=ceil(xmaxi[nlens/2,nlens/2])-xmini[nlens/2,nlens/2]+1
	sdpx=max(ceil(xmaxi-xmini))+1 

;Common Wavelength Vector
;lambda=dblarr(CommonWavVect[2])
;for i=0,CommonWavVect[2]-1 do lambda[i]=lambdamin+double(i)*(lambdamax-lambdamin)/(CommonWavVect[2]-1)


Result=dblarr(nlens,nlens,sdpx)+!VALUES.F_NAN

;for rescaling, keep median value of each spectrum
medianspectrum=median(cubef3D, dimension=3)
indNan=where(~FINITE(cubef3D[*,*,0]),cc)
if cc ne 0 then medianspectrum[indNan]=!VALUES.F_NAN
;calculate median of median values
medtot=median(medianspectrum)

message,/info, 'Extracting flat-field; Removing lamp spectrum...'
for xsi=0,nlens-1 do begin	
  	for ysi=0,nlens-1 do begin
		if finite(xmini[xsi,ysi]) then begin
			valx=xmini[xsi,ysi]+indgen(sdpx)
      		lambint=wavcal[xsi,ysi,2]+wavcal[xsi,ysi,3]*(valx-wavcal[xsi,ysi,0])*(1./cos(wavcal[xsi,ysi,4]))
			;    if (xsi eq 140) && (ysi eq 140) then stop
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
                    lampspec=(planck(10000*lambint,tempelampe)/mean(planck(10000*lambint,tempelampe)))*mean((spectrum)[indforfit])
                      end
          else:   lampspec=replicate(mean((spectrum)[indforfit]), n_elements(lambint))
         endcase        


		  
	   		;toDO:implement other methods
		  ; remove the linear fit.
		  Result[xsi,ysi,*] = reform(( spectrum/lampspec) *medianspectrum[xsi,ysi] /medtot, 1,1,sz)
		  ;Result[xsi,ysi,*] = reform(( spectrum0/lampspec) *medianspectrum[xsi,ysi] /medtot, 1,1,sz)
		  ;if (xsi gt 140) && (ysi gt 140) then stop
    	endif
	endfor
endfor

*(dataset.currframe[0])=Result

; Set keywords for outputting files into the Calibrations DB
if numext eq 0 then begin
  sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Flat Field", "What kind of IFS file is this?"
  sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
endif else begin
  sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Flat Field", "What kind of IFS file is this?"
  sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
endelse

;suffix='flat'
@__end_primitive

;;	if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=Modules[thisModuleIndex].suffix else suffix='flat'
;;	
;;	
;;	
;;	    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;;	      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;;	      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
;;	      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;;	    endif else begin
;;	      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;;	          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
;;	    endelse
;;	
;;	
;;	;drpPushCallStack, functionName
;;	return, ok
;;	

end
