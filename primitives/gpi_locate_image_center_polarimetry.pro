;+
; NAME: gpi_locate_image_center_polarimetry.pro
; PIPELINE PRIMITIVE DESCRIPTION: Locate Image Center Polarimetry
;
;  Finds the location of the occulted star (i.e. image center); saves center to FITS keywords.
;
; PIPELINE COMMENT: Finds the location of the occulted star in polarimetry mode, and save the results to the FITS keyword headers.
; PIPELINE ARGUMENT: Name="x0" Type="int" Range="[0,300]" Default="147" Desc="initial guess for image center x-coordinate"
; PIPELINE ARGUMENT: Name="y0" Type="int" Range="[0,300]" Default="147" Desc="inital guess ofr image center y-coordinate"
; PIPELINE ARGUMENT: Name="search_window" Type="int" Range="[1,50]" Default="5" Desc="Radius of search window to search for the center"
; PIPELINE ARGUMENT: Name="mask_radius" Type="int" Range="[0,100]" Default="50" Desc="Radius of center of image to mask (centered on x0, y0 inputs)"
; PIPELINE ARGUMENT: Name="highpass" Type="int" Range="[0,1]" Default="1" Desc="1: Use high pass filter 0: don't"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
; PIPELINE ORDER: 2.445
; PIPELINE NEWTYPE: Calibration, PolarimetricScience
;
; HISTORY:
; 	2014-01-31 JW: Created. Accurary is subpixel - hopefully.
;- 

function gpi_locate_image_center_polarimetry, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id: __template.pro 2340 2014-01-06 16:52:56Z ingraham $' ; get version from subversion to store in header history

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

; the following line sources a block of code common to all primitives
; It loads some common blocks, records the primitive version in the header for
; history, then if calfiletype is not blank it queries the calibration database
; for that file, and does error checking on the returned filename.
@__start_primitive
suffix='' 		 ; set this to the desired output filename suffix


cube = *dataset.currframe
cubetype = strtrim(backbone->get_keyword('CTYPE3'), 2)

; check for polarization data
if (cubetype ne 'STOKES') then $
	return, error('FAILURE ('+functionName+'): Datacube must be a Stokes cube. Cannot be from spectral mode.')

; check for data dimensions that probably won't happen. We will support 3d Stokes cubes and 2d ones
; that have collapsed the polarization dimension
if ((size(cube))[0] gt 3) || ((size(cube))[0] lt 2) then $
	return, error('FAILURE ('+functionName+'): data is either less than 2D or more than 3D.')

; get user inputs
search_window = fix(Modules[thisModuleIndex].search_window)
mask_radius = fix(Modules[thisModuleIndex].mask_radius)
x0 = fix(Modules[thisModuleIndex].x0)
y0 = fix(Modules[thisModuleIndex].y0)
highpass = fix(Modules[thisModuleIndex].highpass)

statuswindow = backbone->getstatusconsole()

;find location of image center
cent = find_pol_center(cube, x0, y0, search_window, search_window, maskrad=mask_radius, highpass=highpass, statuswindow=statuswindow)

; write calculated center to header
backbone->set_keyword,"PSFCENTX", cent[0], 'X-Location of PSF center', ext_num=1
backbone->set_keyword,"PSFCENTY", cent[1], 'Y-Location of PSF center', ext_num=1

@__end_primitive

end
