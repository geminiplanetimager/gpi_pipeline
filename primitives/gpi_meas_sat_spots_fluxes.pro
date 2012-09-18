;+
; NAME: gpi_meas_sat_spots_fluxes
; PIPELINE PRIMITIVE DESCRIPTION: Measure satellite spot peak fluxes
;
;
; INPUTS: data-cube, spot locations
;
;
; KEYWORDS:
;	
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Calculate peak fluxes of satellite spots in datacubes 
; PIPELINE ARGUMENT: Name="gauss_fit" Type="int" Range="[0,1]" Default="1" Desc="0: Extract maximum pixel; 1: Correlate with Gaussian to find peak"
; PIPELINE ARGUMENT: Name="reference_index" Type="int" Range="[0,50]" Default="0" Desc="Index of slice to use for initial satellite detection."
; PIPELINE ARGUMENT: Name="ap_rad" Type="int" Range="[1,50]" Default="7" Desc="Radius of aperture used for finding peaks."
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ORDER: 2.45
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: Calibration,SpectralScience
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Written 09-18-2012 savransky1@llnl.gov
;- 

function gpi_meas_sat_spots_fluxes, DataSet, Modules, Backbone
primitive_version= '$Id: gpi_meas_sat_spots_fluxes.pro $' ; get version from subversion to store in header history
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
dec = ulong64(0)
reads,tmp,dec,format='(Z)'
goodbin = string(dec,format='(B+'+strtrim((size(cube,/dim))[2],2)+'.'+strtrim((size(cube,/dim))[2],2)+')')
goodcode = ulonarr((size(cube,/dim))[2])
for j=0,n_elements(goodcode)-1 do goodcode[j] = long(strmid(goodbin,j,1))
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

;;get the fluxes
fluxes = get_sat_fluxes(cube,band=band,good=good,cens=cens,warns=warns,$
                        gaussfit=gaussfit,gaussap=gaussap,locs=locs,/usecens)
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

suffix='-satsfluxes'

@__end_primitive
end
