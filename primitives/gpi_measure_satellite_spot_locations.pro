;+
; NAME: gpi_measure_satellite_spot_locations
; PIPELINE PRIMITIVE DESCRIPTION: Measure satellite spot locations 
;
;  Measures the locations of the satellite spots; saves to FITS keywords.
;  The sat spots locations are saved to SATS1_1, SATS1_2, and so on.
;  The inferred location of the star is saved to PSFCENTX and PSFCENTY
;  (this is the mean location of all the locations at each wavelength)
;
;  By default, the sat spots information are saved to the FITS header keywords
;  of the current file in memory, and will only be saved if you subsequently
;  save that datacube (i.e. using 'save=1' on this primitive or a subsequent
;  one). The 'update_prev_fits_header' option will, in addition, also let you
;  write the same keyword information to the header of the most recently saved
;  file. This is useful if you have just already saved the datacube, and you
;  only now want to update this metadata. 
;
;
; PIPELINE COMMENT: Measure the locations of the satellite spots in the datacube, and save the results to the FITS keyword headers.
; PIPELINE ARGUMENT: Name="refine_fits" Type="int" Range="[0,1]" Default="1" Desc="0: Use wavelength scaling only; 1: Fit each slice"
; PIPELINE ARGUMENT: Name="reference_index" Type="int" Range="[-1,50]" Default="-1" Desc="Index of slice to use for initial satellite detection. -1 for Auto."
; PIPELINE ARGUMENT: Name="search_window" Type="int" Range="[1,50]" Default="20" Desc="Radius of aperture used for locating satellite spots."
; PIPELINE ARGUMENT: Name="highpass" Type="int" Range="[0,25]" Default="1" Desc="1: Use high pass filter (default size) 0: don't 2+: size of highpass filter box"
; PIPELINE ARGUMENT: Name="constrain" Type="int" Range="[0,1]" Default="0" Desc="1: Constrain distance between sat spots by band; 0: Unconstrained search."
; PIPELINE ARGUMENT: Name="secondorder" Type="int" Range="[0,1]" Default="0" Desc="1: Constrain uses 2nd order spots for Y or J bands; no effect for H, K1, K2"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="update_prev_fits_header" Type="int" Range="[0,1]" Default="0" Desc="Update FITS metadata in the most recently saved datacube?"
; PIPELINE ARGUMENT: Name="loc_input" Type="int" Range="[0,2]" Default="0" Desc="0: Find spots automatically; 1: Use values below as initial satellite spot location"
; PIPELINE ARGUMENT: Name="x1" Type="int" Range="[0,300]" Default="0" Desc="approx x-location of top left spot on reference slice of the datacube in pixels"
; PIPELINE ARGUMENT: Name="y1" Type="int" Range="[0,300]" Default="0" Desc="approx y-location of top left spot on reference slice of the datacube in pixels"
; PIPELINE ARGUMENT: Name="x2" Type="int" Range="[0,300]" Default="0" Desc="approx x-location of bottom left spot on reference slice of the datacube in pixels"
; PIPELINE ARGUMENT: Name="y2" Type="int" Range="[0,300]" Default="0" Desc="approx y-location of bottom left spot on reference slice of the datacube in pixels"
; PIPELINE ARGUMENT: Name="x3" Type="int" Range="[0,300]" Default="0" Desc="approx x-location of top right spot on reference slice of the datacube in pixels"
; PIPELINE ARGUMENT: Name="y3" Type="int" Range="[0,300]" Default="0" Desc="approx y-location of top right spot on reference slice of the datacube in pixels"
; PIPELINE ARGUMENT: Name="x4" Type="int" Range="[0,300]" Default="0" Desc="approx x-location of bottom right spot on reference slice of the datacube in pixels"
; PIPELINE ARGUMENT: Name="y4" Type="int" Range="[0,300]" Default="0" Desc="approx y-location of bottom right spot on reference slice of the datacube in pixels"
; PIPELINE ORDER: 2.44
; PIPELINE CATEGORY: Calibration,SpectralScience
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   2012-09-18 Offloaded functionality to common backend - ds
;   2013-07-17 MP Documentation updated, rename for consistency.
;   2014-10-11 DS Added PSFCEN_XX for all slices to header
;   2016-09-20 MP added secondorder option
;- 

function gpi_measure_satellite_spot_locations, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

cube = *(dataset.currframe[0]) 
band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))

;;error handle if extractcube not used before
if ((size(cube))[0] ne 3) || (strlen(band) eq 0)  then $
   return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before this one.')   

;;wavelength info
cwv = get_cwv(band,spectralchannels=(size(cube,/dim))[2])  

;;get user inputs
refinefits = fix(Modules[thisModuleIndex].refine_fits)
indx = fix(Modules[thisModuleIndex].reference_index)
if indx eq -1 then indx = round((size(cube,/dim))[2]/2.)
winap = fix(Modules[thisModuleIndex].search_window)
loc_input = fix(Modules[thisModuleIndex].loc_input)
highpass = fix(Modules[thisModuleIndex].highpass)
constrain = fix(Modules[thisModuleIndex].constrain)
secondorder = fix(Modules[thisModuleIndex].secondorder)
update_prev_fits_header = fix(Modules[thisModuleIndex].update_prev_fits_header)
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

if keyword_set( secondorder) and (band eq 'H' or band eq 'K1' or band eq 'K2') then secondorder=0 ; it doesn't apply to those filters

;;find sat spots
cens = find_sat_spots_all(cube,band=band,indx=indx,good=good,$
                          refinefits=refinefits,winap=winap,locs=approx_locs,$
                          constrain=constrain,highpass=highpass,secondorder=secondorder)
if n_elements(cens) eq 1 then return, error ('FAILURE ('+functionName+'): Could not find satellite spots.')
good = long(good)

;;write spot results to header
backbone->set_keyword,"SPOTWAVE", cwv.lambda[indx],$
                      "Wavelength of ref for SPOT locations", ext_num=1

PSFcens = fltarr(2,n_elements(good))
for s=0,n_elements(good) - 1 do begin
   for j = 0,3 do begin
      backbone->set_keyword,'SATS'+strtrim(good[s],2)+'_'+strtrim(j,2),$
                            string(strtrim(cens[*,j,good[s]],2),format='(F7.3," ",F7.3)'),$
                            'Location of sat. spot '+strtrim(j,2)+' of slice '+strtrim(good[s],2),$
                            ext_num=1
   endfor 

   PSFcens[*,s] = [mean(cens[0,*,good[s]]),mean(cens[1,*,good[s]])]
   backbone->set_keyword,'PSFC_'+strtrim(good[s],2),$
                            string(strtrim(PSFcens[*,s],2),format='(F7.3," ",F7.3)'),$
                            'PSF Center of slice '+strtrim(good[s],2),$
                            ext_num=1
endfor

backbone->set_keyword,"PSFCENTX", mean(PSFcens[0,*]), 'Mean PSF center X', ext_num=1
backbone->set_keyword,"PSFCENTY", mean(PSFcens[1,*]), 'Mean PSF center Y', ext_num=1

;;convert good elements to HEX
goodcode = ulon64arr((size(cube,/dim))[2])
goodcode[good] = 1
;print,string(goodcode,format='('+strtrim(n_elements(goodcode),2)+'(I1))')
gooddec = ulong64(0)
for j=n_elements(goodcode)-1,0,-1 do gooddec += goodcode[j]*ulong64(2)^ulong64(n_elements(goodcode)-j-1)
goodhex = strtrim(string(gooddec,format='((Z))'),2)
backbone->set_keyword,'SATSMASK',goodhex,'HEX->binary mask for slices with found sats',ext_num=1

backbone->set_keyword,'SATSORDR',secondorder+1,'Sat spot grid order used (primary or secondary)',ext_num=1

if keyword_set(update_prev_fits_header) then begin
	; Update the same FITS keyword information into a prior saved version of
	; this datacube. 
	; This is somewhat inelegant code to repeat all these keywords here, but
	; it's more efficient in execution time than trying to integrate this header
	; update into backbone->set_keyword since that would unnecessarily read and
	; write the file from disk each time, which is no good. -MP

	prevheader = gpi_get_prev_saved_header(ext_num=1, status=status)

	if status eq OK then begin
		sxaddpar,prevheader, "SPOTWAVE", cwv.lambda[indx], "Wavelength of ref for SPOT locations"
		for s=0,n_elements(good) - 1 do begin
		   for j = 0,3 do begin
			   sxaddpar,prevheader, 'SATS'+strtrim(good[s],2)+'_'+strtrim(j,2),$
									string(strtrim(cens[*,j,good[s]],2),format='(F7.3," ",F7.3)'),$
									'Location of sat. spot '+strtrim(j,2)+' of slice '+strtrim(good[s],2)
		   endfor 
		   PSFcens[*,s] = [mean(cens[0,*,good[s]]),mean(cens[1,*,good[s]])]
		   sxaddpar,prevheader, 'PSFC_'+strtrim(good[s],2),$
									string(strtrim(PSFcens[*,s],2),format='(F7.3," ",F7.3)'),$
									'PSF Center of slice '+strtrim(good[s],2)
		endfor
		sxaddpar,prevheader, "PSFCENTX", mean(PSFcens[0,*]), 'Mean PSF center X'
		sxaddpar,prevheader, "PSFCENTY", mean(PSFcens[1,*]), 'Mean PSF center Y'
		sxaddpar,prevheader, 'SATSMASK',goodhex,'HEX->binary mask for slices with found sats'
        sxaddpar,prevheader, 'SATSORDR',secondorder+1,'Sat spot grid order used (primary or secondary)'

		gpi_update_prev_saved_header, prevheader, ext_num=1

	endif 
endif

@__end_primitive
end
