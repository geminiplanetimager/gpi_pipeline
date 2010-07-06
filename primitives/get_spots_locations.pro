;+
; NAME: get_spots_locations
; PIPELINE PRIMITIVE DESCRIPTION: Load satellite spot locations  
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
; OUTPUTS:  
;
; PIPELINE COMMENT: Load sat spot locations from calibration file 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="spotloc" Default="GPI-spotloc.fits" Desc="Filename of spot locations calibration file to be read"
; PIPELINE ORDER: 2.45
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;- 

function get_spots_locations, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='spotloc'
@__start_primitive

	loadedcalfiles->load, c_File, calfiletype
	spotloc = loadedcalfiles->get(calfiletype, header=HeaderCalib)

    ;pmd_fluxcalFrame        = ptr_new(READFITS(c_File, HeaderCalib, /SILENT))
    ;spotloc =*pmd_fluxcalFrame
    SPOTWAVE=strcompress(sxpar( HeaderCalib, 'SPOTWAVE',  COUNT=cc4),/rem)
    sxaddpar, *(dataset.headers[numfile]), "SPOTWAVE", SPOTWAVE, "Wavelength of ref for SPOT locations"
	sxaddpar, *(dataset.headers[numfile]), "PSFCENTX", spotloc[0,0], "x-locations of PSF Center"
	sxaddpar, *(dataset.headers[numfile]), "PSFCENTY", spotloc[0,1], "y-locations of PSF Center"
	for ii=1,(size(spotloc))[1]-1 do begin
	  sxaddpar, *(dataset.headers[numfile]), "SPOT"+strc(ii)+'x', spotloc[ii,0], "x-locations of spot #"+strc(ii)
	  sxaddpar, *(dataset.headers[numfile]), "SPOT"+strc(ii)+'y', spotloc[ii,1], "y-locations of spot #"+strc(ii)  
	endfor

  sxaddhist, functionname+": Loaded satellite spot locations", *(dataset.headers[numfile])
  sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])

return, ok


end
