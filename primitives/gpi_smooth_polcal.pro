;+
; NAME: gpi_smooth_polcal
; PIPELINE PRIMITIVE DESCRIPTION: Smooth polarization calibration
;
;   This routine smooths the best fit gaussian parameters of the
;   polarization calibration file that is already loaded in memory.
;   It does not alter the original file.
;
;
; ALGORITHM NOTES:
;
;   Must have already loaded the polarization calibration file.
;
; INPUTS: detector image in polarimetry mode
; common needed: filter, wavcal, tilt, (nlens)
;
; OUTPUTS: None
;
; PIPELINE COMMENT:  Smooth polarization calibration parameters.
; PIPELINE ARGUMENT: Name="Boxsize" Type="int" Range="[1,100]" Default="10" Desc="The size of the median filter"
; PIPELINE ORDER: 0.52
; PIPELINE CATEGORY: PolarimetricScience
;
; HISTORY:
; 2014-10-27 - MMB: Started

function gpi_smooth_polcal, DataSet, Modules, Backbone
  primitive_version= '$Id: gpi_assemble_polarization_cube.pro 3039 2014-07-01 20:26:02Z fitz $' ; get version from subversion to store in header history
  
  @__start_primitive
  
  if ~(keyword_set(polcal.spotpos)) then return, error("You muse use Load Polarization Calibration before Assemble Polarization Cube")
  
  polspot_params=polcal.spotpos
  
  if tag_exist( Modules[thisModuleIndex], "Boxsize") then boxsize=uint(Modules[thisModuleIndex].Boxsize) else boxsize=0
  print, "Filtering with a box size of "+string(boxsize)
  
;  params = polspot_params[*, ix, iy, pol]
;  p = [0, 1., params[3]*fact, params[4]*fact, params[0]-lowx, params[1]-lowy, params[2]*!dtor]
  sz=281
  
;  imbefore_after=fltarr(sz*2,sz)
  
  filtered_params=polspot_params
  
  for param=2,4 do begin
    for npol=0,1 do begin
;      imbefore_after[0:sz-1,0:sz-1]=reform(polspot_params[param,*,*,npol])
      filtered_params[param,*,*,npol]=filter_image(reform(polspot_params[param,*,*,npol]), median=boxsize)
      
      if param eq 2 then begin
        tmp=reform(polspot_params[param,*,*,npol])
        tmp[where(tmp gt 90)]-=180
        filtered_params[param,*,*,npol]=filter_image(tmp, median=boxsize)
      endif
;      imbefore_after[sz:2*sz-1,0:sz-1]=reform(filtered_params[param,*,*,npol])
;      atv,imbefore_after,/block
  endfor
  endfor
  
  
  polcal.spotpos=filtered_params
  
  @__end_primitive
end


