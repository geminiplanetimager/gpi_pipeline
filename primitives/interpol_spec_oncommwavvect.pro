;+
; NAME: Interpol_Spec_OnCommWavVect
; PIPELINE PRIMITIVE DESCRIPTION: Interpolate Wavelength Axis
;
;		interpolate datacube to have each slice at the same wavelength
;		add wavelength keywords to the FITS header
;
;
; INPUTS: 
;
;
; KEYWORDS:
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: CDELT3,CRPIX3,CRVAL3,CTYPE3,CUNIT3
;	/Save	Set to 1 to save the output image to a disk file. 
;
; OUTPUTS:  datacube with slice at the same wavelength
;
; PIPELINE COMMENT: Interpolate spectral datacube onto regular wavelength sampling.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-spdc" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.3
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 03-
;
; HISTORY:
; 	Originally by Jerome Maire 2008-06
; 	2009-04-15 MDP: Documentation improved. 
;   2009-06-20 JM: adapted to wavcal
;   2009-09-17 JM: added DRF parameters
;   2010-03-15 JM: added error handling
;- 

function Interpol_Spec_OnCommWavVect, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

   ;get the datacube from the dataset.currframe
   cubef3D=*(dataset.currframe[0])
        
        ;get the common wavelength vector
         filter = gpi_simplify_keyword_value(backbone->get_keyword('FILTER1', count=ct))
            ;error handle if extractcube not used before
            if ((size(cubef3D))[0] ne 3) || (strlen(filter) eq 0)  then $
            return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before.')        

        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]
        nlens=(size(wavcal))[1]
  
    ;;get length of spectrum
  sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)
  if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')


;; Now we must interpolate the extracted cube onto a regular wavelength grid
;; common to all lenslets.
Result=dblarr(nlens,nlens,CommonWavVect[2])+!VALUES.F_NAN
for xsi=0,nlens-1 do begin
  for ysi=0,nlens-1 do begin
	;pixint=UNIQ(floor(zemdispX(xsi,ysi,*))) ; uniq X pixel values for this lenslet
	;while (n_elements(pixint) lt sdpx) do pixint=[pixint, pixint(n_elements(pixint)-1)+1] ; add more pixels up to sdpx.
	;while (n_elements(pixint) gt sdpx) do pixint= pixint[ 0:n_elements(pixint)-2 ] ; throw away elements if necessary
	; now there are precisely sdpx elements in pixint.
	
	
	; what are the wavelengths for each of those pixels?
	if finite(xmini[xsi,ysi]) then begin
		  valx=double(xmini[xsi,ysi]-findgen(sdpx))
       ; if (valx[sdpx-1] lt (dim)) then begin
      
          lambint=wavcal[xsi,ysi,2]-wavcal[xsi,ysi,3]*(valx-wavcal[xsi,ysi,0])*(1./cos(wavcal[xsi,ysi,4]))
        	;for bandpass normalization
        	bandpassmoy=mean(lambint[1:(size(lambint))[1]-1]-lambint[0:(size(lambint))[1]-2],/DOUBLE)
        	bandpassmoy_interp=mean(lambda[1:(size(lambda))[1]-1]-lambda[0:(size(lambda))[1]-2],/DOUBLE)
        	norma=bandpassmoy_interp/bandpassmoy
        	
;        	;;remove extraflux on the edge before interpo
;        	indedgemax=where(lambint GT lambda[n_elements(lambda)-1],cc )
;        	if cc gt 0 then cubef3D[xsi,ysi,indedgemax]=0.; cubef3D[xsi,ysi,indedgemax[0]-1]  ;0.
;        	indedgemin=where(lambint LT lambda[0],cc )
;          if cc gt 0 then cubef3D[xsi,ysi,indedgemin]=0.; cubef3D[xsi,ysi,indedgemin[n_elements(indedgemin)-1]+1]  ;0.
        	
        	; interpolate the cube onto a regular grid.
        	Result[xsi,ysi,*] = norma*INTERPOL( cubef3D[xsi,ysi,*], lambint, lambda )
  	 ;  endif
  endif
  endfor
endfor


;create keywords related to the common wavelength vector:
backbone->set_keyword,'NAXIS',3, ext_num=1
backbone->set_keyword,'NAXIS1',nlens, ext_num=1
backbone->set_keyword,'NAXIS2',nlens, ext_num=1
backbone->set_keyword,'NAXIS3',CommonWavVect[2], ext_num=1

backbone->set_keyword,'CDELT3',(CommonWavVect[1]-CommonWavVect[0])/(CommonWavVect[2]),'wav. increment', ext_num=1
; FIXME this CRPIX3 should probably be **1** in the FORTRAN index convention
backbone->set_keyword,'CRPIX3',0.,'pixel coordinate of reference point', ext_num=1
backbone->set_keyword,'CRVAL3',CommonWavVect[0]+(CommonWavVect[1]-CommonWavVect[0])/(2.*CommonWavVect[2]),'wav. at reference point', ext_num=1
backbone->set_keyword,'CTYPE3','WAVE', ext_num=1
backbone->set_keyword,'CUNIT3','microms', ext_num=1
;FXADDPAR, *(dataset.headers)[numfile], 'NAXIS',3, after='BITPIX'
;FXADDPAR, *(dataset.headers)[numfile], 'NAXIS1',nlens, after='NAXIS'
;FXADDPAR, *(dataset.headers)[numfile], 'NAXIS2',nlens, after='NAXIS1'
;FXADDPAR, *(dataset.headers)[numfile], 'NAXIS3',CommonWavVect[2], after='NAXIS2'
;
;FXADDPAR, *(dataset.headers)[numfile], 'CDELT3', (CommonWavVect[1]-CommonWavVect[0])/(CommonWavVect[2]),'wav. increment'
;; FIXME this CRPIX3 should probably be **1** in the FORTRAN index convention
;; used in FITS file headers
;FXADDPAR, *(dataset.headers)[numfile], 'CRPIX3', 0.,'pixel coordinate of reference point'
;FXADDPAR, *(dataset.headers)[numfile], 'CRVAL3', CommonWavVect[0]+(CommonWavVect[1]-CommonWavVect[0])/(2.*CommonWavVect[2]),'wav. at reference point'
;FXADDPAR, *(dataset.headers)[numfile], 'CTYPE3','WAVE'
;FXADDPAR, *(dataset.headers)[numfile], 'CUNIT3','microms'

; put the datacube in the dataset.currframe output structure:
*(dataset.currframe[0])=Result

@__end_primitive
;;	
;;	;if asked, save the datacube and/or display it with GPItv:
;;		thisModuleIndex = Backbone->GetCurrentModuleIndex()
;;		if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=Modules[thisModuleIndex].suffix
;;		
;;	    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;;			  if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;;	    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
;;	    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;;	    endif else begin
;;	      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;;	          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
;;	    endelse
;;	
;;	
;;	return, ok
;;	

end
