;+
; NAME: gpi_combine_3d_datacubes
; PIPELINE PRIMITIVE DESCRIPTION: Combine 3D Datacubes
;
;  Multiple 3D cubes can be combined into one, using either a Mean, Median, Sigma-clipped Mean, or the minimum pixel values.
;
;  TODO: more advanced combination methods. Improved sigma-clipped mean implementation
;
; INPUTS: 3d datacubes
; OUTPUTS: a single combined datacube
;
; PIPELINE COMMENT: Combine 3D datacubes via mean or median. 
; PIPELINE ARGUMENT: Name="Method" Type="enum" Range="MEAN|MEDIAN|SIGMACLIP|MINIMUM"  Default="MEDIAN" Desc="How to combine images: median, mean, mean with outlier rejection, or minimum pixel values?"
; PIPELINE ARGUMENT: Name="sig_clip" Type="int" Range="0,10" Default="3" Desc="Clipping value to be used with SIGMACLIP in sigma (stddev)"
; PIPELINE ARGUMENT: Name="align_star" Type="int" Range="0,1" Default="0" Desc="Translate datacubes to align star (from header) on same center pixel? 1: Yes"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.5
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
;   2013-07-29 MP: Rename for consistency
;   2018-07-30 TME: Added option to align star in all frames before combining.
;-
function gpi_combine_3d_datacubes, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "method") then method=Modules[thisModuleIndex].method else method='median'
	if method eq '' then method='median'
    if tag_exist( Modules[thisModuleIndex], "sig_clip") then sig_clip=Modules[thisModuleIndex].sig_clip else sig_clip=3.0
    if tag_exist( Modules[thisModuleIndex], "align_star") then align_star=Modules[thisModuleIndex].align_star else align_star=0
	
	nfiles=dataset.validframecount

	; Load the first file so we can figure out their size, etc. 
    im0 = accumulate_getimage(dataset, 0, hdr0, hdrext=hdrext0)

	sz = [0, sxpar(hdrext0,'NAXIS1'), sxpar(hdrext0,'NAXIS2'), sxpar(hdrext0,'NAXIS3')]
	if sz[3] eq 0 then return, error('FAILURE ('+functionName+'): Input not a datacube, check that the input is a datacube and that Accumulate Images has been run prior to this primitive. ') 

	; create an array of the same type as the input file:
	imtab = make_array(sz[1], sz[2], sz[3], nfiles, type=size(im0,/type))

	; read in all the images at once
	for i=0,nfiles-1 do imtab[*,*,*,i] =  accumulate_getimage(dataset,i,hdr)

	; optionally shift all images to align the star on same pixel at center of array.
	if (align_star eq 1) then begin
		newcenx=(sz[1]-1)/2
		newceny=(sz[2]-1)/2
		print, 'Aligning image centers to common', newcenx, newceny, ' before combining.'
		for i=0, nfiles-1 do begin
			astr_header=*DataSet.HeadersExt[i]
			psfcenx=sxpar(astr_header,"PSFCENTX")
			psfceny=sxpar(astr_header,"PSFCENTY")
			if (psfcenx eq 0.0) then begin
				return, error('FAILURE: Missing Keyword: PSFCENTX. Run "Measure satellite spot locations" (spec) or "Measure Star Position in Polarimetry" (pol) first.')
			endif
			imtab[*,*,*,i]=translate(imtab[*,*,*,i],newcenx-psfcenx,newceny-psfceny,missing=!values.f_nan)
		endfor
	endif

	; now combine them.
	if nfiles gt 1 then begin
		backbone->set_keyword, 'HISTORY', functionname+":   Combining n="+strc(nfiles)+' files using method='+method,ext_num=0
		
		backbone->Log, "	Combining n="+strc(nfiles)+' files using method='+method
		backbone->set_keyword, 'DRPNFILE', nfiles, "# of files combined to produce this output file"
		case STRUPCASE(method) of
		'MEDIAN': begin 
			combined_im=median(imtab,/DOUBLE,DIMENSION=4) 
		end
		'MEAN': begin
			;combined_im=total(imtab,/DOUBLE,4) /((size(imtab))[4])
			combined_im=mean(imtab,/double,dimension=4,/nan)
		end
		'SIGMACLIP': begin
                                ; this is rather dirty but functional
                    ; first calculate median
                   combined_im=median(imtab,/DOUBLE,DIMENSION=4)
                                ;calculate robust_sigma
                   stddev_arr=dblarr(sz[1],sz[2],sz[3])
                   im_mean=dblarr(sz[1],sz[2],sz[3])
                   for i=0, sz[1]-1 do begin
                      for j=0, sz[2]-1 do begin
                         for k=0, sz[3]-2 do begin
                            ind=where(finite(imtab[i,j,k,*]) eq 1)
                            if N_ELEMENTS(ind) gt 3 then stddev_arr[i,j,k]=robust_sigma(imtab[i,j,k,*]) else continue
                            ind2=where(abs(imtab[i,j,k,*]-combined_im[i,j,k]) le sig_clip*stddev_arr[i,j,k])
                            if ind2[0] ne -1 then im_mean[i,j,k]=mean(imtab[i,j,k,ind2])
                         endfor
                           endfor
                   endfor
                   im_mean[where(im_mean eq 0)]=!values.f_nan
                   combined_im=im_mean
                           
		end
		'MINIMUM': begin
			combined_im=min(imtab,DIMENSION=4) 
		end
		else: begin
			message,"Invalid combination method '"+method+"' in call to "+functionname
			return, NOT_OK
		endelse
		endcase
		suffix = strlowcase(method)
	endif else begin

		 backbone->set_keyword,'HISTORY', functionname+":   Only 1 file supplied, so nothing to combine.",ext_num=0
		message,/info, "Only one frame supplied - can't really combine it with anything..."

		combined_im = imtab
	endelse

	; if re-aligned the center, save new center coordinates in header of combined file.
	if (align_star eq 1) then begin
		backbone->set_keyword,"PSFCENTX",newcenx
		backbone->set_keyword,"PSFCENTY",newceny
	endif

	; store the output into the backbone datastruct
	*(dataset.currframe)=combined_im
	dataset.validframecount=1

@__end_primitive
end
