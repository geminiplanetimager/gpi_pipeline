;+
; NAME: gpi_normalize_by_total_intensity
; PIPELINE PRIMITIVE DESCRIPTION: Normalize podc by total intensity
;
; Normalizes by the two podc slices by the total intensity
;
; INPUTS: podc data-cube
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: HISTORY
; OUTPUTS:  datacube with slices normalized
;
; PIPELINE COMMENT: Divides a 2-slice polarimetry file by its total intensity
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 3.5
; PIPELINE CATEGORY: PolarimetricScience, Calibration
;
;
; HISTORY:
;   2014-03-25: MMB created
;-

function gpi_normalize_by_total_intensity, DataSet, Modules, Backbone
primitive_version= '$Id: gpi_divide_by_polarized_flat_field.pro 2511 2014-02-11 05:57:27Z mperrin $' ; get version from subversion to store in header history
calfiletype=''
@__start_primitive

    mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
    mode = strlowcase(mode)
    if ~strmatch(mode,"*wollaston*",/fold) then begin
    backbone->Log, "ERROR: That's not a polarimetry file!"
    return, error('FAILURE ('+functioName+'): data is NOT a polarimetry file!')
    endif

    ;Make sure it's a podc file
    sz=size(*(dataset.currframe))
  
    if (sz)[3] ne 2 then $ 
    return, error('FAILURE ('+functionName+'): This primitive only accepts -podc files.')

    ; update FITS header history
    backbone->set_keyword,'HISTORY', functionname+": Dividing both slices by total intensity",ext_num=0

    tot=total(*(dataset.currframe),3)
    (*(dataset.currframe))[*,*,0] = (*(dataset.currframe))[*,*,0]/tot
    (*(dataset.currframe))[*,*,1] = (*(dataset.currframe))[*,*,1]/tot

@__end_primitive
end
