;+
; NAME: gpi_combine_wavcal_all
; PIPELINE PRIMITIVE DESCRIPTION: Combine Wavelength Calibrations
;
; gpi_combine_wavcal_all is a simple median combination of wav. cal. files obtained with flat and arc images.
;  TO DO: exclude some mlens from the median in case of  wavcal 
;
; INPUTS: 3D wavcal 
;
; GEM/GPI KEYWORDS:DATE-OBS,FILTER,IFSFILT,TIME-OBS
; DRP KEYWORDS: DATAFILE
; OUTPUTS:

; PIPELINE COMMENT: Performs simple median combination of wavelength calibrations from flat and/or arc lamps
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.2
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 23-
;
; HISTORY:
;    Jerome Maire 2009-08-10
;   2009-09-17 JM: added DRF parameters
;   2012-10-17 MP: Removed deprecated suffix= keyword
;-

function gpi_combine_wavcal_all,  DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
	nfiles=dataset.validframecount

	if nfiles gt 1 then begin

		if tag_exist( Modules[thisModuleIndex], "Exclude") then Exclude= Modules[thisModuleIndex].exclude ;else exclude=

		sz=size(accumulate_getimage( dataset, 0))
		wavcalcomb=dblarr(sz[1],sz[2],sz[3])
	  
	
		filter=gpi_simplify_keyword_value(strc(backbone->get_keyword('IFSFILT')))
		cwv=get_cwv(filter)
		CommonWavVect=cwv.CommonWavVect
		lambda=cwv.lambda
	   
		lambdamin=commonwavvect[0]
		; MP note: The algorithm here seems inefficient - you end up reading in
		; the individual wavelength solutions many times in succession? 
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
		backbone->set_keyword,'DATAFILE',basename+'.fits'
		backbone->set_keyword,'HISTORY', functionname+": combined "+strc(nfiles)+" wavcal files:",ext_num=0
        for i=0,nfiles-1 do $ 
        	backbone->set_keyword,'HISTORY', functionname+":    "+dataset.filenames[i]+'   '+ backbone->get_keyword("GCALLAMP"),ext_num=0

        ;update with the most recent dateobs and timeobs
        dateobs3=dblarr(nfiles)
        for n=0,nfiles-1 do begin
            dateobs2 =  strc(backbone->get_keyword("DATE-OBS"))+" "+strc(backbone->get_keyword("TIME-OBS"))
            dateobs3[n] = date_conv(dateobs2, "J")
        endfor
        recent=max(dateobs3,indrecent)
	    ;;we add 1second to the last time-obs so the combination will the most recent
		; MP - this is not a good algorithm. 
	    dateobscomb=date_conv(dateobs3[indrecent]+1./24./60./60.,'F')
	    datetimecomb=strsplit(dateobscomb,'T', /extract)

	    backbone->set_keyword, 'DATE-OBS', datetimecomb[0]
	    backbone->set_keyword, 'TIME-OBS', datetimecomb[1]

	    backbone->set_keyword, "FILETYPE", "Wavelength Solution Cal File"
		backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
  
	endif else begin
		  backbone->set_keyword, 'HISTORY',  functionname+": Only one wavelength calibration supplied; nothing to combine!" ,ext_num=0;*(dataset.headers[numfile])
		  backbone->Log, "Only one wavelength calibration supplied; nothing to combine!"
	endelse

@__end_primitive

end
