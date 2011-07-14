;+
; NAME: combine_3dcubes
; PIPELINE PRIMITIVE DESCRIPTION: Combine 3D cubes
;
;  TODO: more advanced combination methods. Mean, sigclip, etc.
;
; INPUTS: 2D image from narrow band arclamp
; common needed:
;
; KEYWORDS:
; OUTPUTS:
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: NAXIS1,NAXIS2
;
; PIPELINE COMMENT: Combine 3D data cubes via mean or median. 
; PIPELINE ARGUMENT: Name="Method" Type="enum" Range="MEAN|MEDIAN|MEANCLIP|MINIMUM"  Default="MEDIAN" Desc="How to combine images: median, mean, or mean with outlier rejection?"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name='suffix' Type='string' Default='median' Desc="choose the suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.5
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 22- 

; HISTORY:
; 	 Jerome Maire 2008-10
;   2009-09-17 JM: added DRF parameters
;   2009-10-22 MDP: Created from mediancombine_darks, converted to use
;   				accumulator.
;   2010-01-25 MDP: Added support for multiple methods, MEAN method.
;
;-
function combine_3dcubes, DataSet, Modules, Backbone
primitive_version= '$Id: combine_3dcubes.pro 278 2011-02-09 19:20:31Z maire $' ; get version from subversion to store in header history
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=Modules[thisModuleIndex].suffix else suffix='median'
	if tag_exist( Modules[thisModuleIndex], "method") then method=Modules[thisModuleIndex].method else method='median'
	header=*(dataset.headers[numfile])

	nfiles=dataset.validframecount

	; Load the first file so we can figure out their size, etc. 
	im0 = accumulate_getimage(dataset, 0, hdr0)
	;imtab=dblarr(naxis(0),naxis(1),numfile)
	sz = [0, sxpar(hdr0,'NAXIS1'), sxpar(hdr0,'NAXIS2'), sxpar(hdr0,'NAXIS3')]
	; create an array of the same type as the input file:
	imtab = make_array(sz[1], sz[2], sz[3], nfiles, type=size(im0,/type))



	; read in all the images at once
	for i=0,nfiles-1 do imtab[*,*,*,i] =  accumulate_getimage(dataset,i,hdr)


	; now combine them.
	if nfiles gt 1 then begin
		sxaddhist, functionname+":   Combining n="+strc(nfiles)+' files using method='+method, *(dataset.headers[numfile])
		backbone->Log, "	Combining n="+strc(nfiles)+' files using method='+method
		case STRUPCASE(method) of
		'MEDIAN': begin 
			combined_im=median(imtab,/DOUBLE,DIMENSION=4) 
		end
		'MEAN': begin
			combined_im=total(imtab,/DOUBLE,4) /((size(imtab))[4])
		end
		'MEANCLIP': begin
			message, 'Method MEANCLIP not implemented yet - bug Marshall to program it!'
		end
		'MINIMUM': begin
			combined_im=min(imtab,DIMENSION=4) 
		end
		else: begin
			message,"Invalid combination method '"+method+"' in call to Combine 2D Frames."
			return, NOT_OK
		endelse
		endcase
	endif else begin

		sxaddhist, functionname+":   Only 1 file supplied, so nothing to combine.", *(dataset.headers[numfile])
		message,/info, "Only one frame supplied - can't really combine it with anything..."

		combined_im = imtab[*,*,0]
	endelse


	 ;TODO header update
	 pos=strpos(filename,'-',/REVERSE_SEARCH)
	; writefits,strmid(filename,0,pos+1)+suffix+'.fits',im,h

	; store the output into the backbone datastruct
	*(dataset.currframe)=combined_im
	;*(dataset.headers[numfile]) = hdr0 ; NO!! DO NOT JUST REPLACE THIS HEADER - that screws up the 'DATAFILE' keyword used in
										; save_currdata for the filename.
	dataset.validframecount=1

@__end_primitive
end
