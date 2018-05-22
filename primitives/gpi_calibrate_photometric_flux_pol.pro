;+
; NAME: gpi_calibrate_photometric_flux_pol
; PIPELINE PRIMITIVE DESCRIPTION: Calibrate Photometric Flux in Pol Mode
;
;	This primitive applies photometric calibration to a podc or podc-like file
;   using the measured sat spot fluxes stored in the header. A tutorial will be 
;   created to guide the users on how to do pol mode photometric calibration.
;	See <put the link here when it's availiable>. 
;
;   The percentage error recorded in the header is propagated from the 
;   uncertainties of the measured sat spot flux and the uncertainty from the 
;   input stellar flux.
;
;
; INPUTS: 
;	1. The input file (podc or podc-like) should have the measured sat spot 
;      fluxes stored in the header.   
;   2. The flux of the star (required) with the uncertainty (optional) in the 
;      observed band. 
;   3. Desired output unit.
;
; OUTPUTS: 
;   The calibrated data cube with the conversion factor and the percentage error
;   recorded in the header.
;
;
; PIPELINE COMMENT: Apply photometric calibration to a podc or Stokes cube
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="8" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="stellar_flux" Type="float" Range="[0,9000]" Default="0" Desc="Known stellar flux in the observed band in [Jy]"
; PIPELINE ARGUMENT: Name="stellar_flux_err" Type="float" Range="[0,9000]" Default="0" Desc="Uncertainty on the known stellar flux in [Jy]"
; PIPELINE ARGUMENT: Name="FinalUnits" Type="int" Range="[0,3]" Default="0" Desc="0: Jy, 1: Jy/arcsec^2, 2: mJy, 3: mJy/arcsec^2"
; 
; PIPELINE ORDER: 4.8
; PIPELINE CATEGORY: PolarimetricScience,
;
; HISTORY:
;
;   2015-07-23 LWH: Created
;   2015-09-03 LWH: Modified it so it's compatible with the sat flux measurement primitive 
;-

function gpi_calibrate_photometric_flux_pol, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history

@__start_primitive

suffix='-phot'

cube = *(dataset.currframe[0])                               ; [ADU/coadd]

;; Get the user inputs for the stellar flux and the desired output unit
f_star = float(Modules[thisModuleIndex].stellar_flux)               ; [Jy]
f_star_err = float(Modules[thisModuleIndex].stellar_flux_err)       ; [Jy]
final_unit = fix(Modules[thisModuleIndex].FinalUnits)
if f_star eq 0. then $
    return, error('FAILURE ('+functionName+'): Invalid input -- You must enter the stellar_flux value.') 


;; Read in the sat spot to star flux ratio
apodizer = backbone->get_keyword('APODIZER')      ; apodizer used
gridfac = gpi_get_gridfac(apodizer)               ; sat spot to star flux ratio


CATCH, Error_status
;This statement begins the error handler:
if Error_status NE 0 THEN BEGIN
    print, 'Error index: ', Error_status
    print, 'Error message: ', !ERROR_STATE.MSG
    print, 'Check the previous errors' 
    return, not_ok
endif


;; Read in the measured sat spot fluxes and errors from the header        

S = make_array(2, 4, /float, value = 0.)        ; sat spot flux  [ADU/coadd]
SE = make_array(2, 4, /float, value = 0.)       ; sat spot error [ADU/coadd]

for i=0,3 do begin
    for j=0,1 do begin
        headername = 'SATF'+strtrim(j,1)+'_'+strtrim(i,1)
        S[j,i] = backbone->get_keyword(headername)
        SE[j,i] = backbone->get_keyword(headername+'E')
    endfor
endfor


;; Calculate the average sat spot flux and its error
f_sat = total(S)/4.                             ; [ADU/coadd]
f_sat_err = sqrt(total(SE^2))/4.                ; [ADU/coadd]


;; Return if the sat spot measurements are missing or not positive. 
if f_sat le 0. or f_sat_err le 0. then begin
    print, "The average sat spot flux or the flux error is not positive." 
    print, "Check the sat spot flux in the header to make sure it's not missing or negative."
    return, not_ok
endif


;; Compute the calibration factor cf and its percentage uncertainty
cf = gridfac * f_star / f_sat                                   ; [Jy*coadd/ADU]
cf_err = sqrt((f_star_err/f_star)^2+(f_sat_err/f_sat)^2)*100.   ; [%]


;; Do photometric calibration
cube_calibrated = cube * cf                                     ; [Jy]


;; Adjust to the desired output unit
unitslist = ['Jy', 'Jy/arcsec^2', 'mJy', 'mJy/arcsec^2']
platescale = gpi_get_constant('ifs_lenslet_scale')              ; [arcsec/pix]
case final_unit of 
0: begin ;'Jy' 
    end 
1: begin ;'Jy/arcsec^2'
    cube_calibrated /= platescale^2
    end
2: begin ;'mJy'
    cube_calibrated *= 1000.
    end
3: begin ;'mJy/arcsec^2'
    cube_calibrated *= 1000./platescale^2
    end
endcase


*dataset.currframe = cube_calibrated

;; Log the calibration factor, the error, and the history in the header
backbone->set_keyword, 'BUNIT',  unitslist[final_unit] ,'Physical units of the array values', ext_num=1
backbone->set_keyword, 'CALIBFAC', cf, 'Photometric calibration factor [Jy/(ADU/coadd)]', ext_num=1
backbone->set_keyword, 'CALIBERR', cf_err, 'Photometric calibration factor percentage error [%]', ext_num=1
backbone->set_keyword, 'HISTORY',functionname + "The photometric calibration factor is " + strc(cf) + 'Jy/(ADU/coadd) with ' + strc(cf_err) + '% uncertainty.'


@__end_primitive 


end
