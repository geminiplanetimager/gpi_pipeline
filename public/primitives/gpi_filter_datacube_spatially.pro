;+
; NAME: gpi_filter_datacube_spatially
; PIPELINE PRIMITIVE DESCRIPTION: Filter datacube spatially
;
;
; Highpass filter each slice of a GPI datacube using a median box filter.
;
; This is useful for removing the halos created by uncorrected atmospheric turbulence. This is a tad slow but a useful tool.
;
; Other filters can be added later.
;
; INPUTS: raw 2D image file
;
; OUTPUTS: 2D image corrected for dark current
;
;
; PIPELINE COMMENT: Apply spatial filter to datacubes
; PIPELINE ARGUMENT: Name="hp_boxsize" Type="int" Range="[0,50]" Default="0" Desc="0: no filter, 1+: Filter box size"
; PIPELINE ARGUMENT: Name="high_or_lowpass" Type="string" Range="[high|low]" Default="high" Desc="High pass or lowpass filter?"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.1
; PIPELINE CATEGORY: ALL
;
; HISTORY:
; 	Originally by Patrick Ingraham Apr 2, 2014
; 	MMB updated to include lowpass and polarimetry.
;
;-
function gpi_filter_datacube_spatially, DataSet, Modules, Backbone

  primitive_version= '$Id: gpi_filter_datacube_spatially.pro 2717 2014-03-23 21:30:29Z mperrin $' ; get version from subversion to store in header history
  
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
  if tag_exist( Modules[thisModuleIndex], "hp_boxsize") then hp_boxsize=uint(Modules[thisModuleIndex].hp_boxsize) else hp_boxsize=0
  
  @__start_primitive
  
  ; apply hp box filter
  
  if (hp_boxsize gt 0) then begin
  
    ; get wavelengths
  
  
    data0 = *dataset.currframe
    
    sz=size(data0)
    
    ;Check prism
    mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
    mode = strlowcase(mode)
    
    
    if ~strmatch(mode,"*wollaston*",/fold) then begin
      band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=cc))
      cwv=get_cwv(band)
      CommonWavVect=cwv.CommonWavVect
      lambda=cwv.lambda
      nlam=n_elements(lambda)
      ; quick check to make sure it isn't a detector frame
      if sz[3] ne 37 then return,error ('Must be placed after Interpolate_wavelength_axis')
    endif else begin
      nlam=2
    endelse
    
    
    if sz[1] eq 2048 then return, error('Can only apply filter to cubes, not detector images')
    
    
    filtered_data=fltarr(sz[1],sz[2],nlam)
    
    for l=0, nlam-1 do filtered_data[*,*,l]=filter_image(data0[*,*,l],median=hp_boxsize)
    
    
    if tag_exist( Modules[thisModuleIndex], "high_or_lowpass") then method=strupcase(Modules[thisModuleIndex].high_or_lowpass) else method='HIGH'
    if method eq '' then method='HIGH'
    if method ne 'HIGH' and method ne 'LOW' then return, error("Not a valid high_or_lowpass argument name: "+method)
    
    case method of
      'HIGH': begin
      
        *dataset.currframe -= filtered_data
        
        backbone->set_keyword,'HISTORY',functionname+": Applied highpass filter, boxsize="+strc(hp_boxsize)+" pixels"
        backbone->set_keyword,'HPBOXSZ',strc(hp_boxsize),'Highpass filter boxsize',ext_num=0
        
      end
      'LOW': begin
      
        *dataset.currframe = filtered_data
        
        backbone->set_keyword,'HISTORY',functionname+": Applied lowpass filter, boxsize="+strc(hp_boxsize)+" pixels"
        backbone->set_keyword,'HPBOXSZ',strc(hp_boxsize),'Lowpass filter boxsize',ext_num=0
      end
    endcase
  endif
  
  suffix = 'sfilt'
  @__end_primitive
  
  
end