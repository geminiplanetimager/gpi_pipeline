;+
; NAME: gpi_rotate_north_up
; PIPELINE PRIMITIVE DESCRIPTION: Rotate North Up
;
;   Rotate so that North is Up, and east is to the left. 
;   If necessary this will flip handedness as well as rotate
;   to get the right parity in the output image.
;
;	Note that this primitive can go *either* before or after
;	Accumulate Images. As a Level 1 primitive, it will rotate
;	one cube at a time; as a Level 2 primitive it will rotate 
;	the whole stack of accumulated images all at once (though
;	it rotates each one by its own particular rotation angle).
;
; INPUTS: Datacube(s) in either spectral or polarimetric mode
; OUTPUTS: Rotated datacube(s) with north up and east left.
;
; KEYWORDS:
; GEM/GPI KEYWORDS:RA,DEC,PAR_ANG
; DRP KEYWORDS: CDELT1,CDELT2,CRPIX1,CRPIX2,CRVAL1,CRVAL2,NAXIS1,NAXIS2,PC1_1,PC1_2,PC2_1,PC2_2
;
; PIPELINE COMMENT: Rotate datacubes so that north is up and east is left. 
; PIPELINE ARGUMENT: Name="Rot_Method" Type="string" Range="CUBIC|FFT" Default="CUBIC" Desc='Method to compute the rotation'
; PIPELINE ARGUMENT: Name="Center_Method" Type="string" Range="HEADERS|MANUAL" Default="HEADERS" Desc="Determine the center of rotation from FITS header keywords, manual entry"
; PIPELINE ARGUMENT: Name="centerx" Type="int" Range="[0,281]" Default="140" Desc="Center X Pixel if Center_Method=Manual"
; PIPELINE ARGUMENT: Name="centery" Type="int" Range="[0,281]" Default="140" Desc="Center Y Pixel if Center_Method=Manual"
; PIPELINE ARGUMENT: Name="pivot" Type ="int" Range="[0,1]" Default="0" Desc="Pivot about the center of the image? 0 = No" 
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 3.9
; PIPELINE CATEGORY: SpectralScience,PolarimetricScience
;
; HISTORY:
;-
function gpi_rotate_north_up, DataSet, Modules, Backbone
  primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive


	if tag_exist( Modules[thisModuleIndex], "Rot_Method") then Rot_Method= strupcase(Modules[thisModuleIndex].rot_method) else rot_method="CUBIC" ; can be CUBIC or FFT
	if tag_exist( Modules[thisModuleIndex], "center_Method") then center_Method= strupcase(Modules[thisModuleIndex].center_method) else center_method="HEADERS" ; can be CUBIC or FFT
	backbone->Log, "Using rotation method "+rot_method, depth=3
	backbone->Log, "Using centering method "+center_method, depth=3
	if rot_method ne 'CUBIC' and rot_method ne 'FFT' then return, error("Invalid rotation method: "+rot_method)
	if center_method ne 'HEADERS' and center_method ne 'MANUAL' then return, error("Invalid rotation method: "+center_method)


	if strupcase(center_method) eq 'MANUAL' then  begin
  		centerx=long(Modules[thisModuleIndex].centerx)
  		centery=long(Modules[thisModuleIndex].centery)
		rot_center = [centerx, centery]
	end
	suffix += '-northup'

	; are we reducing one file at a time, or are we dealing with a set of
	; multiple files?
	reduction_level = backbone->get_current_reduction_level() 

  pivot=fix(Modules[thisModuleIndex].pivot)

	case reduction_level of
	1: begin ;---------  Rotate one single file ----------
		cube=*(dataset.currframe)
		
		; The actual rotation is offloaded to a helper function. 
		; This will also update the FITS headers appropriately
		rotated_cube = gpi_rotate_cube(backbone, dataset, cube, $
						rot_method=rot_method, center_method=center_method, rot_center=rot_center, pivot=pivot )
		if n_elements(rotated_cube) eq 1 then return, error('Rotate cube failed.')

		; And output the results:
		*(dataset.currframe)=rotated_cube

		@__end_primitive

	end
	2: begin ;----- Rotate all files stored in the accumulator ------

		backbone->Log, "This primitive is after Accumulate Images so this is a Level 2 step", depth=3
		backbone->Log, "Therefore all currently accumulated cubes will be rotated.", depth=3

		nfiles=dataset.validframecount
		for i=0,nfiles-1 do begin

			backbone->Log, "Rotating cube "+strc(i+1)+" of "+strc(nfiles), depth=3
			original_cube =  accumulate_getimage(dataset,i,hdr,hdrext=hdrext)

			hdrext0 = hdrext
			; For various mostly historical reasons the code is such that
			; headers get updated directly in gpi_rotate_cube but we have to
			; explicitly store the output rotated cube
			rotated_cube = gpi_rotate_cube(backbone, dataset, original_cube, indexFrame=i, $
							rot_method=rot_method, center_method=center_method, rot_center=rot_center, pivot=pivot )
			if n_elements(rotated_cube) eq 1 then return, error('Rotate cube failed.')

			accumulate_updateimage, dataset, i, newdata = rotated_cube

		endfor


	end
	endcase

end
