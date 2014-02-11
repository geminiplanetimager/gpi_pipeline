;+
; NAME: gpi_interpolate_wavelength_axis
; PIPELINE PRIMITIVE DESCRIPTION: Interpolate Wavelength Axis
;
;		Interpolate datacube to have each slice at the same wavelength.
;		This is a necessary step of creating datacubes in spectral mode
;		and should always be used right after Assemble Spectral Datacube.
;
;		Also adds wavelength keywords to the FITS header.
;
; INPUTS:  A raw irregularly-sampled spectral datacube 
; OUTPUTS: Spectral datacube with slices at a regular wavelength sampling
;
; PIPELINE COMMENT: Interpolate spectral datacube onto regular wavelength sampling.
; PIPELINE ARGUMENT: Name="Spectralchannels" Type="int" Range="[0,100]" Default="37" Desc="Choose how many spectral channels for output datacube"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.3
; PIPELINE CATEGORY: SpectralScience,Calibration
;
; HISTORY:
; 	Originally by Jerome Maire 2008-06
; 	2009-04-15 MDP: Documentation improved. 
;   2009-06-20 JM: adapted to wavcal
;   2009-09-17 JM: added DRF parameters
;   2010-03-15 JM: added error handling
;   2012-12-09 MP: Updates to WCS output
;   2013-07-12 MP: Rename for consistency
;- 

function gpi_interpolate_wavelength_axis, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
	suffix='spdc'

	;get the datacube from the dataset.currframe
	cubef3D=*(dataset.currframe[0])
        
	;get the common wavelength vector
    filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
    ;error handle if extractcube not used before
	if ((size(cubef3D))[0] ne 3) || (strlen(filter) eq 0)  then $
	return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before.')        

	;;get length of spectrum
	sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)
	if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')

	if (tag_exist( Modules[thisModuleIndex], "Spectralchannels")) then $
	spectralchannels=( Modules[thisModuleIndex].Spectralchannels) else $
	spectralchannels=-1

	cwv=get_cwv(filter,spectralchannels=spectralchannels)
	CommonWavVect=cwv.CommonWavVect
	lambda=cwv.lambda
	lambdamin=CommonWavVect[0]
	lambdamax=CommonWavVect[1]
	nlens=(size(wavcal))[1]
  
  
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
	; Note: the following is correct, not a "fencepost error" (http://en.wikipedia.org/wiki/Off-by-one_error#Fencepost_error)
	; because the CommonWavVect 0 and 1 are NOT the coordinates of the centers
	; of the outer wavelength bins, they're the actual outer edges of those
	; bins. - MP 2012-12-09
	wavestep = (CommonWavVect[1]-CommonWavVect[0])/(CommonWavVect[2])

        backbone->set_keyword, "FILETYPE", "Spectral Cube", "What kind of IFS file is this?"
	;backbone->set_keyword,'CDELT3',wavestep,'wav. step [CDELT deprecated, use CD3_3 instead]', ext_num=1
	backbone->set_keyword,'CD3_3',wavestep,'wavelength step [micron]', ext_num=1
	; FIXME this CRPIX3 should probably be **1** in the FORTRAN index convention
	; MP 2012-12-09:  changing to 1. Verified this is as required by WCS
	; standards.
	backbone->set_keyword,'CRPIX3',1.,'Spectral wavelengths are references to the first slice', ext_num=1
	backbone->set_keyword,'CRVAL3',CommonWavVect[0]+wavestep/2,'Center wavelength for first spectral channel [micron]', ext_num=1
	backbone->set_keyword,'CTYPE3','WAVE', '3rd axis is vaccuum wavelength', ext_num=1
	backbone->set_keyword,'CUNIT3','microns', 'Wavelengths are in microns.', ext_num=1
	
	; put the datacube in the dataset.currframe output structure:
	*(dataset.currframe)=Result

@__end_primitive

end
