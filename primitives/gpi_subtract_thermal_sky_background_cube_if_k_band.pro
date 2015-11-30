;+
; NAME: gpi_subtract_thermal_sky_background_cube_if_k_band
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Thermal/Sky Background Cube if K band
;
;  Subtract thermal background emission in the datacube, for K band data only
;
;  This is identical to the gpi_subtact_thermal_sky_if_k_band primtive except the subtraction 
;  is done in cube space instead of detector space. It also uses sky cubes rather than the 2d sky images. 
;
;	** special note: ** 
;	
;	This is a new kind of "data dependent optional primitive". If the filter of
;	the current data is YJH, return without doing *anything*, even logging the
;	start/end of this primitive.  It becomes a complete no-op for non-K-band
;	cases.
;
; Algorithm:
;
;	Get the best available thermal/sky background cube calibration file from CalDB
;	Scale it to current exposure time
;	Subtract it. 
;   The name of the calibration file used is saved to the DRPBKGND header keyword.
;
; ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.
;
; INPUTS: 3D image file
;
; OUTPUTS: 3D image file, unchanged if YJH, background subtracted if K1 or K2.
;
;
; PIPELINE COMMENT: Subtract a thermal/sky cube 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="string" CalFileType="bkgnd_cube" Default="AUTOMATIC" Desc='Name of thermal/sky background cube to subtract'
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="Override_scaling" Type="float" Range="[0,10]" Default="1.0" Desc="Set to value other than 1 to manually adjust the background image flux scaling to better match the science data"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.35
; PIPELINE CATEGORY: ALL
;
; HISTORY:
;   2013-12-23 PI: Initial implementation
;-

function gpi_subtract_thermal_sky_background_cube_if_k_band, DataSet, Modules, Backbone


; Implement the special "do nothing if not K band" behavior. 
; Do this first, even before __start_primitive, to avoid cluttering
; up log files unnecessarily in the case of YJH. 
current_filt = backbone->get_keyword('IFSFILT',/simplify)
if (current_filt ne 'K1') and (current_filt ne 'K2') then return, 0 ; indicates OK to proceed .
	; can't use common block vars here since we're above the common block import...

; Now, go on to the regular behavior in the case of K band. 
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'background_cube'
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "gpitv") then gpitv=long(Modules[thisModuleIndex].gpitv) else gpitv=0
	if tag_exist( Modules[thisModuleIndex], "save") then save=long(Modules[thisModuleIndex].save) else save=0
	if tag_exist( Modules[thisModuleIndex], "override_scaling") then override_scaling= float(Modules[thisModuleIndex].override_scaling) else override_scaling=1.0

	background_data = gpi_readfits(c_File, header=bkgndhdr)
	bkgndunits = strc(sxpar(bkgndhdr, 'BUNIT'))
	if bkgndunits ne 'ADU/s' then return, error('Thermal background file '+c_File+' has unexpected units:"'+bkgndunits+'". Must be ADU/s!')
	
	itime = backbone->get_keyword('ITIME')

    scaled_background = background_data * itime * override_scaling ; (2.0/3.0)

	; now subtract it from the cube
	cube = *(dataset.currframe)

	band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
	cwv = get_cwv(band,spectralchannels=(size(cube,/dim))[2])
	lambda = cwv.lambda

	for s=0, N_ELEMENTS(lambda)-1 do cube[*,*,s]-=scaled_background[*,*,s]

	;atv, [[[ *dataset.currframe]],[[scaled_background]],[[*dataset.currframe-scaled_background]]],/bl 

	*(dataset.currframe) = cube
	backbone->set_keyword,'HISTORY',functionname+": thermal background subtracted using "+strc(string(itime,format='(F7.2)'))+ " s * file="+strc(c_File),ext_num=0
	backbone->set_keyword,'HISTORY',functionname+": "+c_File,ext_num=0
	backbone->set_keyword,'DRPBKGND',c_File,ext_num=0

	logstr = functionname+":  thermal background subtracted using an integration time of "+strc(string(itime,format='(F7.2)'))+ " s * file="+strc(c_File)
	backbone->Log,logstr

  
  	suffix = 'bkgndcubesub'
@__end_primitive 


end
