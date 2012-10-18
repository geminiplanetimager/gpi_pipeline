;+
; NAME: combinedarkframes
; PIPELINE PRIMITIVE DESCRIPTION: Combine 2D dark images
;
;  TODO: more advanced combination methods. Mean, sigclip, etc.
;
; INPUTS: 
; common needed:
;
; KEYWORDS:
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS:  FILETYPE, ISCALIB,NAXIS1,NAXIS2
; OUTPUTS:
;
; PIPELINE COMMENT: Combine 2D dark images into a master file via mean or median. 
; PIPELINE ARGUMENT: Name="Method" Type="enum" Range="MEAN|MEDIAN|MEANCLIP"  Default="MEDIAN" Desc="How to combine images: median, mean, or mean with outlier rejection?[MEAN|MEDIAN]"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.01
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 22-

; HISTORY:
; 	 Jerome Maire 2008-10
;   2009-09-17 JM: added DRF parameters
;   2009-10-22 MDP: Created from mediancombine_darks, converted to use
;   				accumulator.
;   2010-01-25 MDP: Added support for multiple methods, MEAN method.
;   2010-03-08 JM: ISCALIB flag for Calib DB
;   2011-07-30 MP: Updated for multi-extension FITS
;-
function combinedarkframes, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
	suffix='dark-comb'

	if tag_exist( Modules[thisModuleIndex], "method") then method=Modules[thisModuleIndex].method else method='median'

	nfiles=dataset.validframecount

	; Load the first file so we can figure out their size, etc. 

	im0 = accumulate_getimage(dataset, 0, hdr,hdrext=hdrext)

	sz = [0, backbone->get_keyword('NAXIS1',ext_num=1), backbone->get_keyword('NAXIS2',ext_num=1)]
	imtab = dblarr(sz[1], sz[2], nfiles)

	itimes = fltarr(nfiles)

	; read in all the images at once
	for i=0,nfiles-1 do begin
		imtab[*,*,i] =  accumulate_getimage(dataset,i,hdr, hdrext=hdrext)
		itimes[i] = sxpar(hdrext, 'ITIME')
	endfor

	; verify all input files have the same exp time
	

	; now combine them.
	if nfiles gt 1 then begin
		backbone->set_keyword, 'HISTORY', functionname+":   Combining n="+strc(nfiles)+' files using method='+method,ext_num=0
		backbone->Log, "	Combining n="+strc(nfiles)+' files using method='+method
		backbone->set_keyword, 'DRPNFILE', nfiles, "# of files combined to produce this output file"
		case STRUPCASE(method) of
		'MEDIAN': begin 
			combined_im=median(imtab,/DOUBLE,DIMENSION=3) 
		end
		'MEAN': begin
			combined_im=total(imtab,/DOUBLE,3) /((size(imtab))[3])
		end
		'MEANCLIP': begin
			message, 'Method MEANCLIP not implemented yet - bug someone to program it!'
		end
		else: begin
			message,"Invalid combination method '"+method+"' in call to Combine 2D Dark Frames."
			return, NOT_OK
		endelse
		endcase
	endif else begin

		backbone->set_keyword, 'HISTORY', functionname+":   Only 1 file supplied, so nothing to combine.",ext_num=0
		message,/info, "Only one frame supplied - can't really combine it with anything..."

		combined_im = imtab[*,*,0]
	endelse



	; store the output into the backbone datastruct
	*(dataset.currframe)=combined_im
	dataset.validframecount=1
  	backbone->set_keyword, "FILETYPE", "Dark File", /savecomment
  	backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
	suffix = '-dark'

@__end_primitive
end
