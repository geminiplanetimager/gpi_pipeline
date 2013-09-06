;+
; NAME: gpi_subtract_thermal_sky_background_if_k_band
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Thermal/Sky Background if K band
;
;  Subtract thermal background emission, for K band data only
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
;	Get the best available thermal background calibration file from CalDB
;	Scale it to current exposure time
;	Subtract it. 
;   The name of the calibration file used is saved to the DRPBKGND header keyword.
;
; ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.
;
; INPUTS: 2D image file
;
; OUTPUTS: 2D image file, unchanged if YJH, background subtracted if K1 or K2.
;
;
; PIPELINE COMMENT: Subtract a dark frame. 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="dark" Default="AUTOMATIC" Desc='Name of thermal background file to subtract'
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.2
; PIPELINE NEWTYPE: ALL
;
; HISTORY:
;   2012-12-13 MP: Initial implementation
;   2013-01-16 MP: Documentation cleanup.
;   2013-07-12 MP: Rename for consistency
;-

function gpi_subtract_thermal_sky_background_if_k_band, DataSet, Modules, Backbone


; Implement the special "do nothing if not K band" behavior. 
; Do this first, even before __start_primitive, to avoid cluttering
; up log files unnecessarily in the case of YJH. 
current_filt = backbone->get_keyword('IFSFILT',/simplify)
if (current_filt ne 'K1') and (current_filt ne 'K2') then return, 0 ; indicates OK to proceed .
	; can't use common block vars here since we're above the common block import...



; Now, go on to the regular behavior in the case of K band. 
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'background'
@__start_primitive

	background_data = gpi_readfits(c_File, header=bkgndhdr)
	bkgndunits = strc(sxpar(bkgndhdr, 'BUNIT'))
	if bkgndunits ne 'ADU/s' then return, error('Thermal background file '+c_File+' has unexpected units:"'+bkgndunits+'". Must be ADU/s!')
	
	itime = backbone->get_keyword('ITIME')

	scaled_background = background_data * itime



	*(dataset.currframe[0]) -= scaled_background
	backbone->set_keyword,'HISTORY',functionname+": thermal background subtracted using "+strc(string(itime,format='(F7.2)'))+ " s * file=",ext_num=0
	backbone->set_keyword,'HISTORY',functionname+": "+c_File,ext_num=0
	backbone->set_keyword,'DRPBKGND',c_File,ext_num=0
  
  	suffix = 'bkgndsub'
@__end_primitive 


end
