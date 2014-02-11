;+
; NAME: gpi_create_sky_bkgd_cube
; PIPELINE PRIMITIVE DESCRIPTION: Creates a thermal/sky background datacube
;
; Create a thermal/sky background cube (3D) rather than using 2D detector frames as is done using the Combine 2D Thermal/Sky Backgrounds primitive. This allows a smoothing of the sky frame that will decrease the photon noise. 
;
; INPUTS:  A 2D sky image (should be a combination of several frames)
; OUTPUTS: A master sky frame, saved as a calibration file
;
; PIPELINE COMMENT: Create Sky/Thermal background cubes 
; PIPELINE ARGUMENT: Name="smooth_box_size" Type="int" Range="[0,100]" Default="3" Desc="Size of box to smooth by (0: No smooth)"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.01
; PIPELINE CATEGORY: Calibration
;
; HISTORY:
;   2013-12-23 PI: Created Primitive
;-
function gpi_create_sky_bkgd_cube, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "smooth_box_size") then smooth_box_size=Modules[thisModuleIndex].smooth_box_size $
		else smooth_box_size=3

cube = *(dataset.currframe[0])
band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
;;error handle if extractcube not used before
if ((size(cube))[0] ne 3) || (strlen(band) eq 0)  then $
   return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use "Assemble Datacube" before this one.')   
cwv = get_cwv(band,spectralchannels=(size(cube,/dim))[2])
lambda = cwv.lambda

	; now smooth them
	if smooth_box_size gt 0 then begin
		backbone->set_keyword, 'HISTORY', functionname+":   Smoothing using a box size of "+strc(smooth_box_size),ext_num=0
		backbone->Log, "	Smoothing sky/thermal cube using a box size of "+strc(smooth_box_size)
		endif else begin
		backbone->set_keyword, 'HISTORY', functionname+":   No smoothing performed" ,ext_num=0
		backbone->Log, "	No smoothing performed"
 		endelse

for s=0,N_ELEMENTS(lambda)-1 do cube[*,*,s]=filter_image(cube[*,*,s],median=smooth_box_size)

		itime = backbone->get_keyword('ITIME')
		gain = backbone->get_keyword('SYSGAIN') ; gives e-/DN

        ; Normalize output to units of counts/second
				bunit0 = backbone->get_keyword('BUNIT')
        if bunit0 ne 'ADU per coadd' then return, error('Images do not have the expected units of ADU/coadd. Cannot determine how to normalize properly...')
        cube/=itime
      
				backbone->set_keyword,'BUNIT', 'ADU/s', 'Physical units of the array values is ADU per second'
        backbone->set_keyword,'HISTORY', functionname+":   Normalized by ITIME to get units of ADU/s.",ext_num=0
				 
			 ; store the output into the backbone datastruct
        backbone->set_keyword, "FILETYPE", "Thermal/Sky Background Cube", /savecomment
        backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
        suffix = '-bkgnd_cube'

        *(dataset.currframe)=cube
        dataset.validframecount=1

@__end_primitive
end
