;+
; NAME: gpi_measure_satellite_spot_locations
; PIPELINE PRIMITIVE DESCRIPTION: Measure satellite spot locations 
;
;  Measures the locations of the satellite spots; saves to FITS keywords.
;
; PIPELINE COMMENT: Measure the locations of the satellite spots in the datacube, and save the results to the FITS keyword headers.
; PIPELINE ARGUMENT: Name="refine_fits" Type="int" Range="[0,1]" Default="1" Desc="0: Use wavelength scaling only; 1: Fit each slice"
; PIPELINE ARGUMENT: Name="reference_index" Type="int" Range="[0,50]" Default="0" Desc="Index of slice to use for initial satellite detection."
; PIPELINE ARGUMENT: Name="search_window" Type="int" Range="[1,50]" Default="20" Desc="Radius of aperture used for locating satellite spots."
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="loc_input" Type="int" Range="[0,2]" Default="0" Desc="0: Find spots automatically; 1: Use values below as initial satellite spot location"
; PIPELINE ARGUMENT: Name="x1" Type="int" Range="[0,300]" Default="0" Desc="approx x-location of top left spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y1" Type="int" Range="[0,300]" Default="0" Desc="approx y-location of top left spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="x2" Type="int" Range="[0,300]" Default="0" Desc="approx x-location of bottom left spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y2" Type="int" Range="[0,300]" Default="0" Desc="approx y-location of bottom left spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="x3" Type="int" Range="[0,300]" Default="0" Desc="approx x-location of top right spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y3" Type="int" Range="[0,300]" Default="0" Desc="approx y-location of top right spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="x4" Type="int" Range="[0,300]" Default="0" Desc="approx x-location of bottom right spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y4" Type="int" Range="[0,300]" Default="0" Desc="approx y-location of bottom right spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ORDER: 2.44
; PIPELINE NEWTYPE: Calibration,SpectralScience
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   2012-09-18 Offloaded functionality to common backend - ds
;   2013-07-17 MP Documentation updated, rename for consistency.
;- 

function gpi_measure_satellite_spot_locations, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

cube = *(dataset.currframe[0])
band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
;;wavelength info
cwv = get_cwv(band,spectralchannels=(size(cube,/dim))[2])  

;;error handle if extractcube not used before
if ((size(cube))[0] ne 3) || (strlen(band) eq 0)  then $
   return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before this one.')   

;;get user inputs
refinefits = fix(Modules[thisModuleIndex].refine_fits)
indx = fix(Modules[thisModuleIndex].reference_index)
winap = fix(Modules[thisModuleIndex].search_window)
loc_input = fix(Modules[thisModuleIndex].loc_input)
if loc_input eq 1 then begin 
   approx_loc=fltarr(4,2)
   approx_loc[0,0]=fix(Modules[thisModuleIndex].x1)
   approx_loc[0,1]=fix(Modules[thisModuleIndex].y1)
   approx_loc[1,0]=fix(Modules[thisModuleIndex].x2)
   approx_loc[1,1]=fix(Modules[thisModuleIndex].y2)
   approx_loc[2,0]=fix(Modules[thisModuleIndex].x3)
   approx_loc[2,1]=fix(Modules[thisModuleIndex].y3)
   approx_loc[3,0]=fix(Modules[thisModuleIndex].x4)
   approx_loc[3,1]=fix(Modules[thisModuleIndex].y4)
   approx_locs = transpose(approx_loc)
endif

;;find sat spots
cens = find_sat_spots_all(cube,band=band,indx=indx,good=good,$
                          refinefits=refinefits,winap=winap,locs=approx_locs)
if n_elements(cens) eq 1 then return, error ('FAILURE ('+functionName+'): Could not find satellite spots.')
good = long(good)

;;write spot results to header
backbone->set_keyword,"SPOTWAVE", cwv.lambda[indx], "Wavelength of ref for SPOT locations", ext_num=1
tmp_sz=size(cens)
PSFcenter=fltarr(tmp_sz[1],tmp_sz[2])
for p=0,tmp_sz[1]-1 do for q=0, tmp_sz[2]-1 do PSFcenter[p,q]=mean(cens[p,q,indx])
;PSFcenter = mean(cens[*,*,indx],dim=2) ; only works from IDL8.0

backbone->set_keyword,"PSFCENTX", mean(PSFcenter[0,*]), 'X-Locations of PSF center', ext_num=1
backbone->set_keyword,"PSFCENTY", mean(PSFcenter[1,*]), 'Y-Locations of PSF center', ext_num=1
for s=0,n_elements(good) - 1 do begin
   for j = 0,3 do begin
      backbone->set_keyword,'SATS'+strtrim(good[s],2)+'_'+strtrim(j,2),$
                            string(strtrim(cens[*,j,good[s]],2),format='(F7.3," ",F7.3)'),$
                            'Location of sat. spot '+strtrim(j,2)+' of slice '+strtrim(good[s],2),$
                            ext_num=1
   endfor
endfor
;;convert good elements to HEX
goodcode = ulon64arr((size(cube,/dim))[2])
goodcode[good] = 1
;print,string(goodcode,format='('+strtrim(n_elements(goodcode),2)+'(I1))')
gooddec = ulong64(0)
for j=n_elements(goodcode)-1,0,-1 do gooddec += goodcode[j]*ulong64(2)^ulong64(n_elements(goodcode)-j-1)
goodhex = strtrim(string(gooddec,format='((Z))'),2)
backbone->set_keyword,'SATSMASK',goodhex,'HEX->binary mask for slices with found sats',ext_num=1

suffix='-satspots'

@__end_primitive
end
