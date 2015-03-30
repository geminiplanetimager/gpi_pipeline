;+
; NAME: subtract_mean_stellar_polarization.pro
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Mean Stellar Polarization
;
;		Subtract an estimate of the stellar polarization, measured from
;		the mean polarization inside the occulting spot radius.
;
;		This primitive is simple, but has not been extensively tested.
;		Under what circumstances, if any, it is useful on GPI data in practice
;		is still TBD.
;
;
; INPUTS: Coronagraphic mode Stokes Datacube
;
; OUTPUTS: That datacube with an estimated stellar polarization subtracted off.
;
; PIPELINE COMMENT: This description of the processing or calculation will show up in the Recipe Editor GUI. This is an example template for creating new primitives. It multiples any input cube by a constant value.
; PIPELINE ARGUMENT: Name="Method" Type="String" Range="Auto|Manual" Default="Auto" Desc="Choose where to meausre the inst_pol. Auto = within the FPM"
; PIPELINE ARGUMENT: Name="InnerRadius" Type="float" Range="[-1,140]" Default="-1" Desc="The inner radius in pix for measuring the mean polarization. -1 = the radius of the FPM."
; PIPELINE ARGUMENT: Name="OuterRadius" Type="float" Range="[-1,140]" Default="20" Desc="The outer radius in pix for measuring the mean polarization. -1 = the radius of the FPM."
; PIPELINE ARGUMENT: Name="Fraction" Type="float" Range="[0,1]" Default="1" Desc="The fraction of the measured mean polarization applied"
; PIPELINE ARGUMENT: Name="WriteToFile" Type="int" Range="[0,1]" Default="0" Desc="1: Write the difference to a file, 0: Dont"
; PIPELINE ARGUMENT: Name="Filename" Type="string" Default="Stellar_Pol_Stokes.txt" Desc="The filename where you write out the stellar polarization"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
; PIPELINE ORDER: 5.0
;
; PIPELINE CATEGORY: PolarimetricScience
;
; HISTORY:
;    2014-03-23 MP: Started
;    2015-02-05 LWH: Added more parameters
;-

function gpi_subtract_mean_stellar_polarization, DataSet, Modules, Backbone
  compile_opt defint32, strictarr, logical_predicate
  
  primitive_version= '$Id$' ; get version from subversion to store in header history
  
  
  @__start_primitive
  
  ; set this to the desired output filename suffix
  if fix(Modules[thisModuleIndex].save) eq 1 then suffix='sub' 		 
    
  centerx = backbone->get_keyword('PSFCENTX', count=ct1, indexFrame=indexFrame)
  centery = backbone->get_keyword('PSFCENTY', count=ct2, indexFrame=indexFrame)
  center = [centerx, centery] 
   
  if ct1+ct2 ne 2 then $
        return, error('FAILURE ('+functionName+'): Star Position Not Found in file'+string(j));+string(*(dataset.frames[j]))) 
  
  sz = size(*dataset.currframe)
  
  indices, (*dataset.currframe)[*,*,0], center=center,r=r
  
  
  ifsfilt = backbone->get_keyword('IFSFILT',/simplify)
  ; size of occulting masks in milliarcsec
  case ifsfilt of
    'Y': fpm_diam = 156
    'J': fpm_diam = 184
    'H': fpm_diam = 246
    'K1': fpm_diam = 306
    'K2': fpm_diam = 306
  endcase
  fpm_diam *= 1./1000 /gpi_get_constant('ifs_lenslet_scale')      ; in pixels
  fpm_rad=fpm_diam/2                                              ; in pixels

  ; Set the inner and outer radius for the measurement of the mean polarization
  if strcmp(string(Modules[thisModuleIndex].Method),"Auto",4) then begin
    inner=0
    outer=fpm_rad
    endif else begin
  inner=float(Modules[thisModuleIndex].InnerRadius)
  outer=float(Modules[thisModuleIndex].OuterRadius)
  endelse 

  ; Check for special situations
  if inner eq -1 then inner = fpm_rad
  if outer eq -1 then outer = fpm_rad

  ; Check for the validity of the input boundries
  if outer le inner then begin
    print, "Your inner and outer radii are incompatible. Measuring the instrumental polarization within the whole fpm."
    inner = 0
    outer = fpm_rad
  endif

  ; Where to measure the polatization
  wfpm = where(r lt outer and r ge inner, ct) 
  print, string(ct)+" pixels used to measure stellar polarization"

  ; Set up some data arrays
  totalint = (*dataset.currframe)[*,*,0]
  q_div_i = (*dataset.currframe)[*,*,1]/totalint
  u_div_i = (*dataset.currframe)[*,*,2]/totalint
  v_div_i = (*dataset.currframe)[*,*,3]/totalint
  
  mean_q = mean(q_div_i[wfpm])
  mean_u = mean(u_div_i[wfpm])
  mean_v = mean(v_div_i[wfpm])

  fraction=float(Modules[thisModuleIndex].Fraction)

  modified_cube = *dataset.currframe

  modified_cube[*,*,1] -= totalint * mean_q * fraction
  modified_cube[*,*,2] -= totalint * mean_u * fraction
  modified_cube[*,*,3] -= totalint * mean_v * fraction

  ; Write to file
  if uint(Modules[thisModuleIndex].WriteToFile) eq 1 then begin
    openw, lun, Modules[thisModuleIndex].Filename, /get_lun, /append, width=200
    printf, lun, string(dataset.filenames[numfile]), mean_q, mean_u, mean_v, fraction, inner, outer
    close, lun
    free_lun, lun
  endif

  backbone->set_keyword,'HISTORY',functionname+ "Subtracting" + strcompress(round(fraction*100)) + "% of the estimated mean apparent stellar polarization from pixels that are between" + strcompress(floor(inner)) + " and" + strcompress(floor(outer))+" pixels from the center"  
  ;backbone->set_keyword,'STELLARQ', mean_q, "Estimated apparent stellar Q/I over the region of interest (default: behind FPM)"
  ;backbone->set_keyword,'STELLARU', mean_u, "Estimated apparent stellar U/I over the region of interest (default: behind FPM)"
  ;backbone->set_keyword,'STELLARV', mean_v, "Estimated apparent stellar V/I over the region of interest (default: behind FPM)"
  
  
  *dataset.currframe = modified_cube
  
  @__end_primitive
  
end
