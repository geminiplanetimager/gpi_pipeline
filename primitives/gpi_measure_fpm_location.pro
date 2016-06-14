;+
; NAME: gpi_measure_fpm_location.pro
; PIPELINE PRIMITIVE DESCRIPTION: Measure FPM Location
;
; Measures the location of the focal plane mask; saves the center into the 
; calibration database in the header of a FITS file under the keywords 
; "FPMCENTX" and "FPMCENTY". 
;
; This code measures the FPM location on the collapsed cube by first asking 
; users to provide the initial guessed center of the FPM. Then, around the user 
; input center, the code computes the average of positions of the depressed 
; pixels and use them to initialize the fitting parameters. The code uses two 
; different models to fit the data, and users have the following model choices: 
; (a) HardCircle model: a circular depressed area with hard edge
; (b) SoftCircle model: a circular depressed area with soft edge
; (c) Auto = Average: taking the average of the best-fit values from (a) and (b) 
;
; INPUTS: a flat or an arc data cube
; OUTPUTS: a calibration FITS file with the FPM location recorded in header
;
; PIPELINE COMMENT: Measures the location of the FPM and saves the result to the header of the output calibration FITS file.
; PIPELINE ARGUMENT: Name="method" Type="string" Range="[Auto|Average|HardCircle|SoftCircle]" Default="Auto" Desc='How to measure the FPM location? [Auto|Average|HardCircle|SoftCircle]'
; PIPELINE ARGUMENT: Name="x0" Type="int" Range="[0,300]" Default="145" Desc="initial guess for FPM x position"
; PIPELINE ARGUMENT: Name="y0" Type="int" Range="[0,300]" Default="145" Desc="initial guess for FPM y position"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ORDER: 5.3
;
; PIPELINE CATEGORY: Calibration, PolarimetricScience
;
; HISTORY:
;    2015-03-01 LWH: Created.
;    2015-12-08 LWH: Cleaned and made the code more robust
;-


;; model function 1 -- a dark circular hole on a flat background
;; p = [mx, my, mh, mr, b] xcenter, ycenter, height of the hole, radius, background height
function circle, x, y, p
    w = where(((x-p[0])^2 + (y-p[1])^2) lt (p[3]^2))
    f = make_array(size(x,/dimension), value=p[4])
    f[w] = p[2]
    return, f
end

;; model function 2 -- a dark circular hole with soft edge on a flat background
;; p = [mx, my, mh, mr, b] xcenter, ycenter, depth of the hole, radius, background height
function circle_soft, x, y, p
    f = p[4]-p[2]*pixwt(p[0],p[1],p[3],x,y)
    return, f
end

function gpi_measure_fpm_location, DataSet, Modules, Backbone

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id$' ; get version from subversion to store in header history

@__start_primitive

cube = *(dataset.currframe[0]) 

; verify the image is a FLAT cube or an ARC.
; verify the image is a reduced data cube
; verify the image is observed with the coronagraph in position
obstype  = backbone->get_keyword('OBSTYPE')
filetype = backbone->get_keyword('FILETYPE')
obsmode =  backbone->get_keyword('OBSMODE')
if(~strmatch(obstype,'*arc*',/fold_case)) && (~strmatch(obstype,'*flat*',/fold_case)) then $
    return, error('FAILURE ('+functionName+'): Invalid input -- The OBSTYPE keyword does not mark this data as a FLAT or ARC image.') 
if(~strmatch(filetype,'*Spectral Cube*',/fold_case)) && (~strmatch(filetype,'*Stokes Cube*',/fold_case)) then $
    return, error('FAILURE ('+functionName+'): Invalid input -- The FILETYPE keyword does not mark this data as a Spectral or Stokes cube.') 
if ~strmatch(obsmode,'*coron*',/fold_case) then $
    return, error('FAILURE ('+functionName+'): Invalid input -- The OBSMODE keyword does not mark this data as observed with the coronagraph.') 


;; Get the user inputs for the guessed initial position of the FPM center
fpm_x0 = Modules[thisModuleIndex].x0
fpm_y0 = Modules[thisModuleIndex].y0


;; Read in the radius of the band-specific focal plane mask in pixels
fpm_band = backbone->get_keyword('OCCULTER',/simplify)
fpm_diam = gpi_get_constant('fpm_diam_'+STRLOWCASE(fpm_band))    ;[arcseconds]
fpm_r0 = fpm_diam / gpi_get_constant('ifs_lenslet_scale') / 2    ;[pix]


;; Generate the image grids
sz = size(cube)
x  = (dindgen(sz[1])) # (dblarr(sz[2]) + 1)
y  = (dblarr(sz[1]) + 1) # (dindgen(sz[2]))


;; Set the fitting area to be within fit_r0 pixels in radius
cube_sum = total(cube,3)
fit_r0 = 2.2 * fpm_r0
fit_area = where(((x-fpm_x0)^2 + (y-fpm_y0)^2) lt fit_r0^2 and ~finite(cube_sum,/nan))
xfit = x[fit_area]
yfit = y[fit_area]
zfit = cube_sum[fit_area]


;; Update the initial guess of the FPM center to the average of the coordinates of the depessed pixels
low = min(zfit)
med = median(cube_sum)
w_fpm = where(zfit lt (med+low)/2)
mean_coordinate_fpm_x = mean(xfit[w_fpm])
mean_coordinate_fpm_y = mean(yfit[w_fpm])


;;Find the FPM location by fitting a circular depressed area to the collapsed cube (sum of all the slices). 
p0 = [mean_coordinate_fpm_x, mean_coordinate_fpm_y, low, fpm_r0, max(zfit)]
parinfo_base = {relstep:0.1, fixed:0, limited:[0,0], limits:[0.D,0]}
parinfo = replicate(parinfo_base, size(p0,/dimension))
pbest = mpfit2dfun('circle', xfit, yfit, zfit, sfit, p0, parinfo=parinfo, status=stat, xtol=1D-15, ftol=1D-15, quiet='quiet')
if stat eq 0 then return, error('FAILURE ('+functionName+'): Fitting routine failed -- improper input parameters')
hardx = pbest[0]
hardy = pbest[1]


;;Find the FPM location by fitting a circular depressed area with soft edge to the collapsed cube (sum of all the slices). 
p0 = [mean_coordinate_fpm_x, mean_coordinate_fpm_y, max(zfit)-low, fpm_r0, max(zfit)]
parinfo_base = {relstep:0.1, fixed:0, limited:[0,0], limits:[0.D,0]}
parinfo = replicate(parinfo_base, size(p0,/dimension))
pbest = mpfit2dfun('circle_soft', xfit, yfit, zfit, sfit, p0, parinfo=parinfo, status=stat, xtol=1D-15, ftol=1D-15, quiet='quiet')
if stat eq 0 then return, error('FAILURE ('+functionName+'): Fitting routine failed -- improper input parameters')
softx = pbest[0]
softy = pbest[1]


;;Select which measured FPM centers as the output
method = strlowcase(Modules[thisModuleIndex].method)
case 1 of
  (method eq 'auto') || (method eq 'average'): begin
      fpm_x = mean([hardx, softx])
      fpm_y = mean([hardy, softy])
      backbone->Log, "The FPM location is measured on the collapsed cube by taking the average of the bestfits of a hard-edge circle and a soft-edge circle.",depth=3
  end
  method eq 'hardcircle': begin
      fpm_x = hardx 
      fpm_y = hardy 
      backbone->Log, "The FPM location is measured on the collapsed cube by fitting it to the model with a circular depressed area with hard edge.",depth=3
  end
  method eq 'softcircle': begin
      fpm_x = softx 
      fpm_y = softy 
      backbone->Log, "The FPM location is measured on the collapsed cube by fitting it to the model with a circular depressed area with soft edge.",depth=3
  end
endcase


print, 'Mean-coordinate FPM (x,y) location:', mean_coordinate_fpm_x, mean_coordinate_fpm_y
print, '  Hard-circular FPM (x,y) location:', hardx, hardy
print, '  Soft-circular FPM (x,y) location:', softx, softy
print, '        Adopted FPM (x,y) location:', fpm_x, fpm_y


;;Check that best fits from the two fitting methods agree within the limit
limit = 0.5  ;[pixel]

best_x = [hardx, softx]
best_y = [hardy, softy]

dx = max(best_x) - min(best_x)
dy = max(best_y) - min(best_y)

if (dx gt limit) or (dy gt limit) then begin
    backbone->Log, "***WARNING***: The FPM locations estimated by two different methods differ by more than 0.5 pixel. The measurement might be bad."
    backbone->set_keyword,'HISTORY',functionname+ "  ***WARNING***: The FPM locations estimated by two different methods differ by more than 0.5 pixel. The measurement might be bad."

    if Modules[thisModuleIndex].Save and (method eq 'auto') then begin
        return, error('FAILURE ('+functionName+'): File not saved -- To save the file, select a specific measuring method.') 
    endif
endif

;;Save to the header of a calibration file
*(dataset.currframe) = [0]

backbone->set_keyword, "FPMCENTX", fpm_x
backbone->set_keyword, "FPMCENTY", fpm_y
backbone->set_keyword, "FPMCMETH", method,"FPM Centroid Measurement Method"
backbone->set_keyword, "FILETYPE", 'FPM Position', 'What kind of IFS file is this?'
backbone->set_keyword, "ISCALIB" , "YES", 'This is a reduced calibration file of some type.'

suffix='fpmposition'

@__end_primitive
end

