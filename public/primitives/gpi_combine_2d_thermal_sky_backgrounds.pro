;+
; NAME: gpi_combine2D_thermal_sky_backgrounds
; PIPELINE PRIMITIVE DESCRIPTION: Combine 2D Thermal/Sky Backgrounds 
;
;	Generate a 2D background image for use in removing e.g. thermal emission
;	from lamp images
;
; INPUTS: 2D image(s) taken with lamps off. 
;
; OUTPUTS: thermal background file, saved as calibration file
;
; PIPELINE COMMENT: Combine 2D images with measurement of thermal or sky background
; PIPELINE ARGUMENT: Name="Method" Type="enum" Range="MEAN|MEDIAN|SIGMACLIP"  Default="SIGMACLIP" Desc="How to combine images: median, mean, or mean with outlier rejection?[MEAN|MEDIAN|SIGMACLIP]"
; PIPELINE ARGUMENT: Name="Sigma_cut" Type="float" Range="[1,100]" Default="3" Desc="If Method=SIGMACLIP, then data points more than this many standard deviations away from the median value of a given pixel will be discarded. "
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.51
; PIPELINE CATEGORY: Calibration
;
; HISTORY:
;   2012-12-13 MP: Forked from combine2dframes
;   2013-07-10 MP: Minor documentation cleanup
;   2013-07-12 MP: Rename for consistency
;	2014-01-02 MP: Copied SIGMACLIP implementation from gpi_combine_2d_dark_images
;-
function gpi_combine_2D_thermal_sky_backgrounds, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "method") then method=Modules[thisModuleIndex].method else method='median'

	nfiles=dataset.validframecount

	; Load the first file so we can figure out their size, etc. 
	im0 = accumulate_getimage(dataset, 0, hdr,hdrext=hdrext)

	sz = [0, backbone->get_keyword('NAXIS1'), backbone->get_keyword('NAXIS2')]
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
			combined_im = gpi_sigma_clip_image_stack( imtab, sigma=sigma_cut,/parallelize)
		end
		else: begin
			return, error("Invalid combination method '"+method+"' in call to Combine 2D Thermal Backgrounds.")
		endelse
		endcase
		suffix = strlowcase(method)
	endif else begin

		 backbone->set_keyword,'HISTORY', functionname+":   Only 1 file supplied, so nothing to combine.",ext_num=0
		message,/info, "Only one frame supplied - can't really combine it with anything..."

		combined_im = imtab[*,*,0]
	endelse


	; Normalize output to units of counts/second
	if bunit0 ne 'ADU per coadd' then return, error('Images do not have the expected units of ADU/coadd. Cannot determine how to normalize properly...')
	combined_im = combined_im / itime0
	backbone->set_keyword,'BUNIT', 'ADU/s', 'Physical units of the array values is ADU per second'
	backbone->set_keyword,'HISTORY', functionname+":   Normalized by ITIME to get units of ADU/s.",ext_num=0


	; store the output into the backbone datastruct
	backbone->set_keyword, "FILETYPE", "Thermal/Sky Background", /savecomment
  	backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
	suffix = '-bkgnd'

	*(dataset.currframe)=combined_im
	dataset.validframecount=1


@__end_primitive
end
