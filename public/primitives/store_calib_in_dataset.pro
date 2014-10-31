;+
; NAME: store_calib_in_dataset
; PIPELINE PRIMITIVE DESCRIPTION: Stores calibration in dataset
; 
; To be called before an accumulate image.
; It is used for high resolution microlens PSF determination
;
; INPUTS: data-cube
; common needed:
;
; KEYWORDS:
; OUTPUTS:
;
; PIPELINE COMMENT: Stores the current calibration into the dataset structure.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 3.0
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 
;
; HISTORY:
;     Originally by Jean-Baptiste Ruffio 2013-08
;-

Function store_calib_in_dataset, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS

primitive_version= '$Id: accumulate_images.pro 1066 2012-12-11 22:18:06Z mperrin $' ; get version from subversion to store in header history
  @__start_primitive
  ;getmyname, functionName

  if n_elements(wavcal) ne 0 then dataset.Wavcals[numfile] = ptr_new(wavcal) else dataset.Wavcals[numfile] = ptr_new()
  if n_elements(polcal) ne 0 then dataset.Polcals[numfile] = ptr_new(polcal) else dataset.Polcals[numfile] = ptr_new()

@__end_primitive
end