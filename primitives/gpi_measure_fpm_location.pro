;+
; NAME: gpi_measure_fpm_location.pro
; PIPELINE PRIMITIVE DESCRIPTION: Measure FPM Location
;
; Measures the location of the focal plane mask; saves the center into the 
; calibration database in the header of a FITS file under the keywords 
; "FPMCENTX" and "FPMCENTY". 
; This code measures the FPM location on the collapsed cube by 
; (a)taking the average of the coordinates of the depressed pixels or 
; (b)fitting it to the model with a circular depressed area with hard edge
; (c)fitting it to the model with a circular depressed area with soft edge
;
; INPUTS: a flat or an arc data cube
; OUTPUTS: a calibration FITS file with the FPM location recorded in header
;
; PIPELINE COMMENT: Measures the location of the FPM and saves the result to the header of the output calibration FITS file.
; PIPELINE ARGUMENT: Name="method" Type="string" Range="[Auto|HCircle|SCircle|CoordinateMean]" Default="Auto" Desc='How to measure the FPM location? [HCircle|SCircle|CoordinateMean]'
; PIPELINE ARGUMENT: Name="x0" Type="int" Range="[0,300]" Default="145" Desc="initial guess for FPM x position"
; PIPELINE ARGUMENT: Name="y0" Type="int" Range="[0,300]" Default="145" Desc="initial guess for FPM y position"
; PIPELINE ARGUMENT: Name="r0" Type="float" Range="[0,300]" Default="8.7" Desc="initial guess for FPM radius in pixels."
; PIPELINE ARGUMENT: Name="rfit" Type="int" Range="[1,140]" Default="20" Desc="Radius in pixels for finding the FPM center"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ORDER: 5.3
;
; PIPELINE CATEGORY: Calibration, PolarimetricScience
;
; HISTORY:
;    2015-03-01 LWH: Created.
;    2015-05-11 LWH: Added the model (c) described above.
;    2015-05-16 LWH: Made the code prettier.
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


;;Get user inputs
fpm_x0 = Modules[thisModuleIndex].x0
fpm_y0 = Modules[thisModuleIndex].y0
fpm_r0 = Modules[thisModuleIndex].r0
fit_r0 = Modules[thisModuleIndex].rfit


;;Generate the image grids
sz = size(cube)
x  = (dindgen(sz[1])) # (dblarr(sz[2]) + 1)
y  = (dblarr(sz[1]) + 1) # (dindgen(sz[2]))
s  = make_array(sz[1], sz[2], value=1.)  ;make the uncertainty map uniform


;;Set the fitting area to be within fit_r0 pixels in radius
cube_sum = total(cube,3)
fit_area = where(((x-fpm_x0)^2 + (y-fpm_y0)^2) lt fit_r0^2 and ~finite(cube_sum,/nan))
xfit = x[fit_area]
yfit = y[fit_area]
zfit = cube_sum[fit_area]
sfit = s[fit_area]


;;Find the FPM location by taking the average of the coordinates of the depessed pixels
low = min(zfit)
med = median(cube_sum)
w_fpm = where(zfit lt (med+low)/2)
mean_coordinate_fpm_x = mean(xfit[w_fpm])
mean_coordinate_fpm_y = mean(yfit[w_fpm])


;;Find the FPM location by fitting a circular depressed area to the collapsed cube (sum of all the slices). 
p0 = [fpm_x0, fpm_y0, low, fpm_r0, max(zfit)]
parinfo_base = {relstep:0.1, fixed:0, limited:[0,0], limits:[0.D,0]}
parinfo = replicate(parinfo_base, size(p0,/dimension))
pbest = mpfit2dfun('circle', xfit, yfit, zfit, sfit, p0, parinfo=parinfo, status=stat, xtol=1D-15, ftol=1D-15, quiet='quiet')
if stat eq 0 then return, error('FAILURE ('+functionName+'): Fitting routine failed -- improper input parameters')
best_fit_fpm_x1 = pbest[0]
best_fit_fpm_y1 = pbest[1]


;;Find the FPM location by fitting a circular depressed area with soft edge to the collapsed cube (sum of all the slices). 
p0 = [fpm_x0, fpm_y0, max(zfit)-low, fpm_r0, max(zfit)]
parinfo_base = {relstep:0.1, fixed:0, limited:[0,0], limits:[0.D,0]}
parinfo = replicate(parinfo_base, size(p0,/dimension))
pbest = mpfit2dfun('circle_soft', xfit, yfit, zfit, sfit, p0, parinfo=parinfo, status=stat, xtol=1D-15, ftol=1D-15, quiet='quiet')
if stat eq 0 then return, error('FAILURE ('+functionName+'): Fitting routine failed -- improper input parameters')
best_fit_fpm_x2 = pbest[0]
best_fit_fpm_y2 = pbest[1]


;;Select which measured FPM centers as the output
Method = strupcase(Modules[thisModuleIndex].method)
case strlowcase(Method) of
  'auto': begin
      fpm_x = best_fit_fpm_x1 
      fpm_y = best_fit_fpm_y1 
      backbone->Log, "The FPM location is measured on the collapsed cube by fitting it to the model with a circular depressed area with hard edge.",depth=3
  end
  'hcircle': begin
      fpm_x = best_fit_fpm_x1 
      fpm_y = best_fit_fpm_y1 
      backbone->Log, "The FPM location is measured on the collapsed cube by fitting it to the model with a circular depressed area with hard edge.",depth=3
  end
  'scircle': begin
      fpm_x = best_fit_fpm_x2 
      fpm_y = best_fit_fpm_y2 
      backbone->Log, "The FPM location is measured on the collapsed cube by fitting it to the model with a circular depressed area with soft edge.",depth=3
  end
  'coordinatemean': begin
      fpm_x = mean_coordinate_fpm_x
      fpm_y = mean_coordinate_fpm_y
      backbone->Log, "The FPM location is measured on the collapsed cube by taking the average of the coordinates of the depressed pixels.",depth=3
  end
endcase

print, 'Mean-coor FPM (x,y) location:', mean_coordinate_fpm_x, mean_coordinate_fpm_y
print, 'Best-fit hard-circular FPM (x,y) location:', best_fit_fpm_x1, best_fit_fpm_y1
print, 'Best-fit soft-circular FPM (x,y) location:', best_fit_fpm_x2, best_fit_fpm_y2
print, 'Adopted FPM (x,y) location:', fpm_x, fpm_y


;;Check that the FPM locations found by all three methods are within one pixel
best_x = [mean_coordinate_fpm_x, best_fit_fpm_x1, best_fit_fpm_x2]
best_y = [mean_coordinate_fpm_y, best_fit_fpm_y1, best_fit_fpm_y2]

dx = max(best_x) - min(best_x)
dy = max(best_y) - min(best_y)

if (dx gt 1) or (dy gt 1) then begin
    backbone->Log, "***WARNING***: The FPM locations estimated by three different methods differ by more than 1 pixel. The measurement might be bad."
    backbone->set_keyword,'HISTORY',functionname+ "  ***WARNING***: The FPM locations estimated by three different methods differ by more than 1 pixel. The measurement might be bad."

    if Modules[thisModuleIndex].Save and (Method eq 'AUTO') then begin
        return, error('FAILURE ('+functionName+'): File not saved -- To save the file, select a specific measuring method.') 
    endif

endif

;;Save to the header of a calibration file
*(dataset.currframe) = [0]

backbone->set_keyword, "FPMCENTX", fpm_x
backbone->set_keyword, "FPMCENTY", fpm_y
backbone->set_keyword, "FILETYPE", 'FPM Position', 'What kind of IFS file is this?'
backbone->set_keyword, "ISCALIB" , "YES", 'This is a reduced calibration file of some type.'

suffix='fpmposition'

@__end_primitive
end

