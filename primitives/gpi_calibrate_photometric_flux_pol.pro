;+
; NAME: gpi_calibrate_photometric_flux_pol
; PIPELINE PRIMITIVE DESCRIPTION: Calibrate Photometric Flux in Pol Mode
;
;	This primitive applies a photometric calibrations to the datacube (either a 
;   podc cube or a Stokes cube) using its satellite spots. Using this primitive 
;   is complicated. Thus, we might create a tutorial to guide the users through.
;	See <list the URL here after the tutorial is created>. 
;
;   The percentage error recorded in the header is propagated from the 
;   uncertainties of the measured sat spot flux and the know stellar flux from 
;   the literature.
;
;
; INPUTS: 
;	1. Either a podc or a Stokes cube (loaded as an input FITS file). Make sure 
;      the sat spot flux information is provided either by using the header 
;      associated with the input image or from another user supplied image.   
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
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="8" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="sat_file" Type="string" Default="" Desc="Blank = use the sat spots of this cube. Alternatively, enter a file w/ its full path"
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
;-

function gpi_calibrate_photometric_flux_pol, DataSet, Modules, Backbone
primitive_version= '$Id: __template.pro 2878 2014-04-29 04:11:51Z mperrin $' ; get version from subversion to store in header history

@__start_primitive

suffix='-phot'

cube = *(dataset.currframe[0])                               ; [ADU/coadd]
size = size(cube)

;; This section can be removed once the sat_spot_flux primitive is ready to be used.
;; Determine if the input is a podc or Stokes cube.
filetype = backbone->get_keyword('FILETYPE')
if(~strmatch(filetype,'*Stokes Cube*',/fold_case)) then $
    return, error('FAILURE ('+functionName+'): Invalid input -- The FILETYPE keyword does not mark this data as a Stokes cube.') 
if size[0] eq 2 then filetype='podc'


;; Get the user inputs for the stellar flux and the desired output unit
f_star = float(Modules[thisModuleIndex].stellar_flux)               ; [Jy]
f_star_err = float(Modules[thisModuleIndex].stellar_flux_err)       ; [Jy]
final_unit = fix(Modules[thisModuleIndex].FinalUnits)
if f_star eq 0. then $
    return, error('FAILURE ('+functionName+'): Invalid input -- The stellar_flux cannot be zero.') 


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


;; Determine which file we should use the sat spots from and
;; Read in measured sat spot fluxes and errors from the header        
;if tag_exist(Modules[thisModuleIndex], "sat_file") then begin
if Modules[thisModuleIndex].sat_file eq '' then begin
	backbone->Log,functionname+": sat_file is not specified; using the sat spots in the input cube for the calibration"
    s00 = backbone->get_keyword('SATF0_0')         ; sat spot flux  [ADU/coadd]
    e00 = backbone->get_keyword('SATF0_0E')        ; sat spot error [ADU/coadd]
    s01 = backbone->get_keyword('SATF0_1')         
    e01 = backbone->get_keyword('SATF0_1E')  
    s02 = backbone->get_keyword('SATF0_2')      
    e02 = backbone->get_keyword('SATF0_2E') 
    s03 = backbone->get_keyword('SATF0_3')         
    e03 = backbone->get_keyword('SATF0_3E') 
    s10 = backbone->get_keyword('SATF1_0')     
    e10 = backbone->get_keyword('SATF1_0E') 
    s11 = backbone->get_keyword('SATF1_1')              
    e11 = backbone->get_keyword('SATF1_1E') 
    s12 = backbone->get_keyword('SATF1_2')             
    e12 = backbone->get_keyword('SATF1_2E')  
    s13 = backbone->get_keyword('SATF1_3')                
    e13 = backbone->get_keyword('SATF1_3E') 
endif else begin
    sat_file = string(Modules[thisModuleIndex].sat_file)
    sat_cube = gpi_load_fits(sat_file)
	backbone->Log,functionname+": sat_file is specified to be "+sat_file+"; using the sat spots in this cube for the calibration"
    s00 = sxpar(*sat_cube.ext_header,'SATF0_0')    ; sat spot flux  [ADU/coadd]
    e00 = sxpar(*sat_cube.ext_header,'SATF0_0E')   ; sat spot error [ADU/coadd]
    s01 = sxpar(*sat_cube.ext_header,'SATF0_1')         
    e01 = sxpar(*sat_cube.ext_header,'SATF0_1E')  
    s02 = sxpar(*sat_cube.ext_header,'SATF0_2')      
    e02 = sxpar(*sat_cube.ext_header,'SATF0_2E') 
    s03 = sxpar(*sat_cube.ext_header,'SATF0_3')         
    e03 = sxpar(*sat_cube.ext_header,'SATF0_3E') 
    s10 = sxpar(*sat_cube.ext_header,'SATF1_0')     
    e10 = sxpar(*sat_cube.ext_header,'SATF1_0E') 
    s11 = sxpar(*sat_cube.ext_header,'SATF1_1')              
    e11 = sxpar(*sat_cube.ext_header,'SATF1_1E') 
    s12 = sxpar(*sat_cube.ext_header,'SATF1_2')             
    e12 = sxpar(*sat_cube.ext_header,'SATF1_2E')  
    s13 = sxpar(*sat_cube.ext_header,'SATF1_3')                
    e13 = sxpar(*sat_cube.ext_header,'SATF1_3E') 
endelse


;; Calculate the average sat spot flux and its error
f_sat0 = mean([s00, s01, s02, s03])
f_sat0_err = sqrt(total([e00^2, e01^2, e02^2, e03^2]))/4.
f_sat1 = mean([s10, s11, s12, s13])
f_sat1_err = sqrt(total([e10^2, e11^2, e12^2, e13^2]))/4.
if strmatch(filetype,'*Stokes Cube*',/fold_case) then begin     ; In the case for a Stokes cube, only the first slice (stokes I) matters 
    f_sat = f_sat0                                              ; [ADU/coadd]
    f_sat_err = f_sat0_err                                      ; [ADU/coadd]
endif else begin                                                ; In the case for a podc file, we use the sum of two slices (total intensity)
    f_sat = total([f_sat0, f_sat1])                             ; [ADU/coadd]
    f_sat_err = sqrt(f_sat0_err^2 + f_sat1_err^2)               ; [ADU/coadd]
endelse


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
platescale = 0.01414                                            ; [arcsec/pix]
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
