;+
; NAME: gpi_smooth_cube
; PIPELINE PRIMITIVE DESCRIPTION: Smooth a 3D Cube
;
; Convolves images with a gaussian kernel
;
; INPUTS: data-cube
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: HISTORY
; OUTPUTS:  cleaned up datacube
;
; PIPELINE COMMENT: Cleans up a 2-slice polarization cube
; PIPELINE ARGUMENT: Name="Smooth_FWHM" Type="int" Range="[0,100]" Default="3" Desc="FWHM of gaussian kernel"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 3.5
; PIPELINE NEWTYPE: PolarimetricScience, Calibration
;
;
; HISTORY:
;   2014-01-09 MMB created
;-

function gpi_smooth_cube, DataSet, Modules, Backbone
  primitive_version= '$Id: gpi_clean_up_podc.pro 2302 2013-12-18 00:39:44Z mmb $' ; get version from subversion to store in header history
  @__start_primitive
  suffix += 'clean'
  
  cube=*(dataset.currframe)
  
  ;Make sure we're a 3d cube
  naxis=backbone->get_keyword('NAXIS')
  if naxis lt 3 then return, error('FAILURE ('+functionName+'): Must be a 3D cube.')
  
  ;Use currframe or acculator?
  reduction_level = backbone->get_current_reduction_level()
  
  ;FWHM of Gaussian Kernel
  fwhm=Modules[thisModuleIndex].Smooth_FWHM
  
  ;Number of Slices
  nlam = backbone->get_keyword('NAXIS3', count=ct)
  
  case reduction_level of
    1: begin;---------  Smooth one single file ----------
      cube=*(dataset.currframe)
      
      for i=0,nlam-1 do begin
        nanlist=where(~finite(cube[*,*,i]), nct)
        data=filter_image(cube[*,*,i], fwhm_gaussian=fwhm); The filter function does funny things to NAN pixels.
        if nct gt 0 then data[nanlist]=!values.f_nan
        cube[*,*,i]=data
      endfor
       *(dataset.currframe)=cube
    end
    
   
    
    2:BEGIN;----- Smooth all files stored in the accumulator ------
    backbone->Log, "This primitive is after Accumulate Images so this is a Level 2 step", depth=3
    backbone->Log, "Therefore all currently accumulated cubes will be smoothed.", depth=3
    
    nfiles=dataset.validframecount
    for i=0,nfiles-1 do begin
      backbone->Log, "Smoothing cube "+strc(i+1)+" of "+strc(nfiles), depth=3
      
      ;Get the images
      cube=accumulate_getimage(dataset,i, hdr, hdrext=hdrext)
      
      ;Smooth
      for j=0, nlam-1 do cube[*,*,j]=filter_image(cube[*,*,j], fwhm_gaussian=fwhm)
      
      ;Update
      accumulate_updateimage, dataset, i, newdata=cube
    endfor
  end
endcase

backbone->set_keyword, "History", functionname+":Applied Gaussian Kernel Smoothing to all the slices", ext_num=0
backbone->set_keyword, "History", functionname+":FWHM="+string(fwhm), ext_num=0

@__end_primitive
end
