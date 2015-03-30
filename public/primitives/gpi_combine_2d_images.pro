;+
; NAME: gpi_combine_2D_images
; PIPELINE PRIMITIVE DESCRIPTION: Combine 2D images
;
;  Multiple 2D images can be combined into one using either a mean, 
;  a sigma-clipped mean,  or a median. 
;
;
; INPUTS: Multiple 2D images
; OUTPUTS: a single combined 2D image
;
; PIPELINE COMMENT: Combine 2D images such as darks into a master file via mean or median. 
; PIPELINE ARGUMENT: Name="Method" Type="string" Range="MEAN|MEDIAN|SIGMACLIP"  Default="SIGMACLIP" Desc="How to combine images: median, mean, or mean with outlier rejection?[MEAN|MEDIAN|SIGMACLIP]"
; PIPELINE ARGUMENT: Name="Sigma_cut" Type="float" Range="[1,100]" Default="3" Desc="If Method=SIGMACLIP, then data points more than this many standard deviations away from the median value of a given pixel will be discarded. "
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.5
; PIPELINE CATEGORY: ALL
;
; HISTORY:
; 	 Jerome Maire 2008-10
;   2009-09-17 JM: added DRF parameters
;   2009-10-22 MDP: Created from mediancombine_darks, converted to use
;   				accumulator.
;   2010-01-25 MDP: Added support for multiple methods, MEAN method.
;   2011-07-30 MP: Updated for multi-extension FITS
;   2012-10-10 MP: Minor code cleanup
;   2013-07-10 MP: Minor documentation cleanup
;   2013-07-12 MP: file rename for consistency
;   2014-01-02 MP: Copied SIGMACLIP implementation from gpi_combine_2d_dark_images
;   2014-11-04 MP: Avoid trying to run parallelized sigmaclip if in IDL runtime.
;
;-
function gpi_combine_2D_images, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "method") then method=Modules[thisModuleIndex].method else method='median'

	nfiles=dataset.validframecount

	; Load the first file so we can figure out their size, etc. 

	im0 = accumulate_getimage(dataset, 0, hdr,hdrext=hdrext)

	sz = [0, backbone->get_keyword('NAXIS1'), backbone->get_keyword('NAXIS2')]
	; create an array of the same type as the input file:
	imtab = make_array(sz[1], sz[2], nfiles, type=size(im0,/type))

	bunit0 = backbone->get_keyword('BUNIT')
	itime0 = backbone->get_keyword('ITIME')

	; read in all the images at once
	for i=0,nfiles-1 do begin
		imtab[*,*,i] =  accumulate_getimage(dataset,i,hdr,hdrext=hdrext)
		; let's make sure the images are dimensionally consistent to combine.
		; (Note, integration times must be equal since we expect the BUNIT =
		; "ADU per coadd" for GPI 2D data...)
		if sxpar(hdrext, 'BUNIT') ne bunit0 then return, error('Image '+strc(i+1)+' has different units (BUNIT keyword) than first image in sequence. Cannot combine!')
		if sxpar(hdrext, 'ITIME') ne itime0 then return, error('Image '+strc(i+1)+' has different integration time (ITIME keyword) than first image in sequence. Cannot combine!')
	endfor

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
		'SIGMACLIP': begin
			can_parallelize = ~ LMGR(/runtime)  ; cannot parallelize if you are in runtime compiled IDL
			combined_im = gpi_sigma_clip_image_stack( imtab, sigma=sigma_cut,parallelize=can_parallelize)
		end
		else: begin
			message,"Invalid combination method '"+method+"' in call to Combine 2D Frames."
			return, NOT_OK
		endelse
		endcase
		suffix = strlowcase(method)
	endif else begin

		 backbone->set_keyword,'HISTORY', functionname+":   Only 1 file supplied, so nothing to combine.",ext_num=0
		message,/info, "Only one frame supplied - can't really combine it with anything..."

		combined_im = imtab[*,*,0]
	endelse



	; store the output into the backbone datastruct
	*(dataset.currframe)=combined_im
	dataset.validframecount=1

@__end_primitive
end
