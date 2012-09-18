;+
; NAME: get_spots_locations
; PIPELINE PRIMITIVE DESCRIPTION: Load Satellite Spot locations  
;
;	
;	
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	/Save	Set to 1 to save the output image to a disk file. 
;
; DRP KEYWORDS: PSFCENTX,PSFCENTY,SPOT[1-4][x-y],SPOTWAVE
; OUTPUTS:  
;
; PIPELINE COMMENT: Load satellite spot locations from calibration file 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="spotloc" Default="AUTOMATIC" Desc="Filename of spot locations calibration file to be read"
; PIPELINE ORDER: 2.45
; PIPELINE NEWTYPE: SpectralScience
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   2010-10-19 JM: split HISTORY keyword if necessary
;- 

function get_spots_locations, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='spotloc'
@__start_primitive
	;loadedcalfiles->load, c_File, calfiletype
	;spotloc = loadedcalfiles->get(calfiletype, header=HeaderCalib)
	 spotloc = gpi_readfits(c_File,header=HeaderCalib)
    ;pmd_fluxcalFrame        = ptr_new(READFITS(c_File, HeaderCalib, /SILENT))
    ;spotloc =*pmd_fluxcalFrame
    SPOTWAVE=strcompress(sxpar( HeaderCalib, 'SPOTWAVE',  COUNT=cc4),/rem)
   ; if numext eq 0 then hdr= *(dataset.headers)[numfile] else hdr= *(dataset.headersPHU)[numfile]
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
