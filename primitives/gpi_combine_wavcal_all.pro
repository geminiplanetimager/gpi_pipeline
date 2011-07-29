;+
; NAME: gpi_combine_wavcal_all
; PIPELINE PRIMITIVE DESCRIPTION: Combine Wavelength Calibrations
;
; gpi_combine_wavcal_all is a simple median combination of wav. cal. files obtained with flat and arc images.
;  TO DO: exclude some mlens from the median in case of  wavcal 
;
; INPUTS: 3D wavcal 
;
; GEM/GPI KEYWORDS:DATE-OBS,FILTER,FILTER1,TIME-OBS
; DRP KEYWORDS: DATAFILE
; OUTPUTS:

; PIPELINE COMMENT: Performs simple median combination of wavelength calibrations from flat and/or arc lamps
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-comb" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.2
; PIPELINE TYPE: CAL-SPEC
; PIPELINE SEQUENCE: 23-
;
; HISTORY:
;    Jerome Maire 2009-08-10
;   2009-09-17 JM: added DRF parameters
;-

function gpi_combine_wavcal_all,  DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
	nfiles=dataset.validframecount
  if numext eq 0 then hdr= *(dataset.headers)[numfile] else hdr= *(dataset.headersPHU)[numfile]

	if nfiles gt 1 then begin

		if tag_exist( Modules[thisModuleIndex], "Exclude") then Exclude= Modules[thisModuleIndex].exclude ;else exclude=

		sz=size(accumulate_getimage( dataset, 0))
		wavcalcomb=dblarr(sz[1],sz[2],sz[3])
	  
	
;		header=*(dataset.headers)[numfile]
		filter = strcompress(sxpar( hdr ,'FILTER', count=fcount),/REMOVE_ALL)
		if fcount eq 0 then filter = strcompress(sxpar( hdr ,'FILTER1'),/REMOVE_ALL)
		cwv=get_cwv(filter)
		CommonWavVect=cwv.CommonWavVect
		lambda=cwv.lambda
	   
		lambdamin=commonwavvect[0]
		for wv=0,sz[3]-1 do begin
			wavcaltab=dblarr(sz[1],sz[2],nfiles)
			for n=0,nfiles-1 do begin
				wavcal =(accumulate_getimage( dataset, n))[*,*,*]
				wavcal = change_wavcal_lambdaref( wavcal, lambdamin)
				wavcaltab[*,*,n]=wavcal[*,*,wv]
			endfor
			wavcalcomb[*,*,wv]=median(wavcaltab,/double,dimension=3,/even)
		endfor
		*(dataset.currframe[0])=wavcalcomb

		basename=findcommonbasename(dataset.filenames[0:nfiles-1])
		FXADDPAR, hdr, 'DATAFILE', basename+'.fits'
		sxaddhist, functionname+": combined wavcal files:", hdr

		for i=0,nfiles do $ 
			sxaddhist, functionname+": "+strmid(dataset.filenames[i], 0,strlen(dataset.filenames[i])-5)+suffix+'.fits', *(dataset.headers[numfile])

  ;update with the most recent dateobs and timeobs
  dateobs3=dblarr(nfiles)
  for n=0,nfiles-1 do begin
   dateobs2 =  strc(sxpar(*(DataSet.Headers[n]), "DATE-OBS"))+" "+strc(sxpar(*(DataSet.Headers[n]),"TIME-OBS"))
   dateobs3[n] = date_conv(dateobs2, "J")
  endfor
   recent=max(dateobs3,indrecent)
   ;;we add 1second to the last time-obs so the combinaison will the most recent
   dateobscomb=date_conv(dateobs3[indrecent]+1./24./60./60.,'F')
   datetimecomb=strsplit(dateobscomb,'T', /extract)
   FXADDPAR, hdr, 'DATE-OBS', datetimecomb[0]
   FXADDPAR, hdr, 'TIME-OBS', datetimecomb[1]

		;suffix+='-comb'
	endif else begin
		sxaddhist, functionname+": Only one wavelength calibration supplied; nothing to combine!", hdr ;*(dataset.headers[numfile])
		  backbone->Log, "Only one wavelength calibration supplied; nothing to combine!"
	endelse
	     if numext eq 0 then *(dataset.headers)[numfile]=hdr else *(dataset.headersPHU)[numfile] =hdr
@__end_primitive

end
