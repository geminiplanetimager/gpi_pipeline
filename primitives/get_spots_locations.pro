;+
; NAME: get_spots_locations
; PIPELINE PRIMITIVE DESCRIPTION: Load Satellite Spot locations  
;	
; INPUTS: data-cube
;
; DRP KEYWORDS: PSFCENTX,PSFCENTY,SPOT[1-4][x-y],SPOTWAVE
;
; PIPELINE COMMENT: Load satellite spot locations from calibration file 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="spotloc" Default="AUTOMATIC" Desc="Filename of spot locations calibration file to be read"
; PIPELINE ORDER: 2.45
; PIPELINE NEWTYPE: Deprecated
; SpectralScience
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2013-07-10 MP: Deprecated during code cleanup.
;- 

function get_spots_locations, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='spotloc'
@__start_primitive
	;loadedcalfiles->load, c_File, calfiletype
	;spotloc = loadedcalfiles->get(calfiletype, header=HeaderCalib)
	spotloc = gpi_readfits(c_File,header=HeaderCalib)
    SPOTWAVE=strcompress(sxpar( HeaderCalib, 'SPOTWAVE',  COUNT=cc4),/rem)

    backbone->set_keyword, "SPOTWAVE", SPOTWAVE, "Wavelength of ref for SPOT locations"
	backbone->set_keyword, "PSFCENTX", spotloc[0,0], "x-locations of PSF Center"
	backbone->set_keyword, "PSFCENTY", spotloc[0,1], "y-locations of PSF Center"
	for ii=1,(size(spotloc))[1]-1 do begin
	  backbone->set_keyword, "SPOT"+strc(ii)+'x', spotloc[ii,0], "x-locations of spot #"+strc(ii), ext_num=1
	  backbone->set_keyword, "SPOT"+strc(ii)+'y', spotloc[ii,1], "y-locations of spot #"+strc(ii), ext_num=1
	endfor

    backbone->set_keyword,'HISTORY',functionname+": Loaded satellite spot locations",ext_num=0
    backbone->set_keyword,'HISTORY',functionname+": "+c_File,ext_num=0
  
return, ok


end
