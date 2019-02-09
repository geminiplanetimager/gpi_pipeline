;+
; NAME: gpi_measure_satellite_spot_peak_fluxes
; PIPELINE PRIMITIVE DESCRIPTION: Measure satellite spot peak fluxes
; 
;   Measure the fluxes of the satellite spots. 
;   You must run 'Measure Satellite Spot Locations' before you can use this
;   one.
;
;	Spot fluxes are measured and then saved to SATF1_1, SATF1_2 etc keywords
;	in the header.
;
;   By default, the sat spots information are saved to the FITS header keywords
;   of the current file in memory, and will only be saved if you subsequently
;   save that datacube (i.e. using 'save=1' on this primitive or a subsequent
;   one). The 'update_prev_fits_header' option will, in addition, also let you
;   write the same keyword information to the header of the most recently saved
;   file. This is useful if you have just already saved the datacube, and you
;   only now want to update this metadata. 
;
; INPUTS: spectral datacube with spot locations in the header
; OUTPUTS:  datacube with measured spot fluxes
;
;
;
; PIPELINE COMMENT: Calculate peak fluxes of satellite spots in datacubes 
; PIPELINE ARGUMENT: Name="gauss_fit" Type="int" Range="[0,1]" Default="1" Desc="0: Extract maximum pixel; 1: Correlate with Gaussian to find peak"
; PIPELINE ARGUMENT: Name="reference_index" Type="int" Range="[0,50]" Default="0" Desc="Index of slice to use for initial satellite detection."
; PIPELINE ARGUMENT: Name="ap_rad" Type="int" Range="[1,50]" Default="7" Desc="Radius of aperture used for finding peaks."
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="update_prev_fits_header" Type="int" Range="[0,1]" Default="0" Desc="Update FITS metadata in the most recently saved datacube?"
; PIPELINE ARGUMENT: Name="highpass" Type="int" Range="[0,25]" Default="0" Desc="1: Use high pass filter (default size) 0: don't 2+: size of highpass filter box"
; PIPELINE ORDER: 2.45
; PIPELINE CATEGORY: Calibration,SpectralScience
;
; HISTORY:
; 	Written 09-18-2012 savransky1@llnl.gov
; 	2013-07-17 MP: Renamed for consistency
;- 

function gpi_measure_satellite_spot_peak_fluxes, DataSet, Modules, Backbone
primitive_version= '$Id: gpi_measure_satellite_spot_peak_fluxes.pro 3601 2014-12-14 05:12:03Z mperrin $' ; get version from subversion to store in header history
@__start_primitive

cube = *(dataset.currframe[0])
band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))

;;error handle if extractcube not used before
if ((size(cube))[0] ne 3) || (strlen(band) eq 0)  then $
   return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use "Assemble Datacube" before this one.')   

;;error handle if sat spots haven't been found
tmp = backbone->get_keyword("SATSMASK", ext_num=1, count=ct)
if ct eq 0 then $
   return, error('FAILURE ('+functionName+'): SATSMASK undefined.  Use "Measure satellite spot locations" before this one.')

;;convert mask to binary
goodcode = hex2bin(tmp,(size(cube,/dim))[2])
good = long(where(goodcode eq 1))
cens = fltarr(2,4,(size(cube,/dim))[2])
for s=0,n_elements(good) - 1 do begin
   for j = 0,3 do begin 
      tmp = fltarr(2) + !values.f_nan 
      reads,backbone->get_keyword('SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2),ext_num=1),tmp,format='(F7," ",F7)' 
      cens[*,j,good[s]] = tmp 
   endfor 
endfor

;;get user inputs
gaussfit = fix(Modules[thisModuleIndex].gauss_fit)
gaussap = fix(Modules[thisModuleIndex].ap_rad)
highpass = fix(Modules[thisModuleIndex].highpass)

; default high pass filter size
if highpass eq 1 then highpass = 15 

;;get the fluxes
fluxes = get_sat_fluxes(cube,band=band,good=good,cens=cens,warns=warns,$
                        gaussfit=gaussfit,gaussap=gaussap,locs=locs,highpass_beforeflux=highpass,/usecens)
if n_elements(fluxes) eq 1 then $
   return, error('FAILURE ('+functionName+'): Failed to extract satellite fluxes.')

;;write results to header
good = long(good)
for s=0,n_elements(good) - 1 do begin
   for j = 0,3 do begin
      backbone->set_keyword,'SATF'+strtrim(good[s],2)+'_'+strtrim(j,2),$
                            fluxes[j,good[s]],$
                            'Peak flux of sat. spot '+strtrim(j,2)+' of slice '+strtrim(good[s],2),$
                            ext_num=1
   endfor
endfor

;;convert warnings to hex elements to HEX
bad = where(warns eq -1,ct)
if ct gt 0 then warns[bad] = 0
warncode = ulong64(warns)
;print,string(warncode,format='('+strtrim(n_elements(warncode),2)+'(I1))')
warndec = ulong64(0)
for j=n_elements(warncode)-1,0,-1 do warndec += warncode[j]*ulong64(2)^ulong64(n_elements(warncode)-j-1)
warnhex = strtrim(string(warndec,format='((Z))'),2)
backbone->set_keyword,'SATSWARN',warnhex,'HEX->binary mask for slices with varying sat fluxes.',ext_num=1


	update_prev_fits_header = fix(Modules[thisModuleIndex].update_prev_fits_header)
    if keyword_set(update_prev_fits_header) then begin
		; update the same fits keyword information into a prior saved version of
		; this datacube. 
		; this is somewhat inelegant code to repeat all these keywords here, but
		; it's more efficient in execution time than trying to integrate this header
		; update into backbone->set_keyword since that would unnecessarily read and
		; write the file from disk each time, which is no good. -mp
		prevheader = gpi_get_prev_saved_header(ext=1, status=status)
		if status eq OK then begin
			for s=0,n_elements(good) - 1 do begin
			   for j = 0,3 do begin
				  sxaddpar, prevheader, 'SATF'+strtrim(good[s],2)+'_'+strtrim(j,2),$
								fluxes[j,good[s]],$
								'Peak flux of sat. spot '+strtrim(j,2)+' of slice '+strtrim(good[s],2)
			   endfor
			endfor
			sxaddpar, prevheader, 'SATSWARN',warnhex,'HEX->binary mask for slices with varying sat fluxes.'

			gpi_update_prev_saved_header, prevheader, ext=1
		endif
	endif




@__end_primitive
end
