;+
; NAME: gpi_extract_polcal
; PIPELINE PRIMITIVE DESCRIPTION: Measure Polarization Spot Calibration
;
;	gpi_extract_polcal detects the positions of the polarized spots in a 2D
;	image based on flat field observations. 
;
; ALGORITHM:
;	gpi_extract_polcal starts by detecting the central peak of the image.
;	Next, starting with a initial value of w & P, it finds the nearest peak (with an increment on the microlens coordinates)
;	when nearest peak has been detected, it reevaluates w & P and so forth..
;
;	; TODO modify to deal with the 2nd polarization...
;
;
; INPUTS: 2D image from flat field  in polarization mode
;
; KEYWORDS:
; OUTPUTS:
;
; PIPELINE ORDER: 1.8
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1"
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[0,1]" Default="1"
; PIPELINE COMMENT: Derive polarization calibration files from a flat field image.
; PIPELINE TYPE: CALIBRATION/POL
; PIPELINE SEQUENCE: 1-
;
; HISTORY:
; 	2009-06-17: Started, based on gpi_extract_wavcal - Marshall Perrin 
;   2009-09-17 JM: added DRF parameters
;-

function gpi_extract_polcal,  DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
   
    im=*(dataset.currframe[0]) 
    h=header
    obstype=SXPAR( h, 'OBSTYPE')
	bandeobs=SXPAR( h, 'FILTER', count=ct)
	if ct eq 0 then bandeobs= sxpar(h,'FILTER1')

   	; TODO verify image is a POL mode FLAT FIELD. 
	disp = sxpar(h,'DISPERSR', count=ct)
	if ct eq 0 then disp = sxpar(h,'FILTER2')

	
	if disp ne 'Polarimetry' then message,"Invalid input file: "+functionname+" requires a POLARIMETRY mode file"
	if strpos(sxpar(h,'OBSTYPE') ,'Flat') eq -1 then message,"Invalid input file: "+functionname+" requires a FLAT FIELD file as its input"
	
   
	if (size(im))[0] eq 0 then im=readfits(filename,h)
	szim=size(im)


; version 1 sketch: We model each peak as a 2D rotated Gaussian. 
;
; for each peak, we store
; 0: x position of the peak center
; 1: y position of the peak center
; 2: rotation angle
; 3: outer radius to use (25% max? ) in X, rotated
; 4: outer radius to use (25% max? ) in Y, rotated
;
; and the last dimension is for the polarization.
;
; NOTE: The code to do the above is NOT yet implemented - only the first 2
; quantities are stored right now!
;
; version 2 sketch: Weighted optimal extraction of each pixel. 
; 	TBD later. See notes in extractpol.pro


nlens=281
; Create the SPOTPOS array, which stores the Gaussian-fit 
; spot locations. 
;
; NOTE: spotpos dimensions re-arranged relative to spectral version
; for better speed. And to add pol dimension of course.
spotpos=dblarr(5,nlens,nlens,2)+!VALUES.D_NAN
nspot_pixels=25
; Now create the PIXELS and PIXVALS arrays, which store the actual
; X,Y, and values for each pixel, that we can use for optimal extraction
spotpos_pixels = intarr(2,nspot_pixels, nlens, nlens, 2)
spotpos_pixvals = dblarr(nspot_pixels, nlens, nlens, 2)+!values.f_nan

;localize central peak around the center of the image
cen1=dblarr(2)	& cen1[0]=-1 & cen1[1]=-1
wx=5 & wy=0
hh=1.
;localize first peak ;; this coordiantes depends strongly on data!!
  cenx=szim[1]/2.
  ceny=szim[2]/2.

while (~finite(cen1[0])) || (~finite(cen1[1])) || $
		(cen1[0] lt 0) || (cen1[0] gt (size(im))[1]) || $
		(cen1[1] lt 0) || (cen1[1] gt (size(im))[1])  do begin
	wx+=1 & wy+=1
	cen1=localizepeak( im, cenx, ceny,wx,wy,hh)
	print, 'Center peak detected at pos:',cen1
endwhile
spotpos[0:1,nlens/2,nlens/2,0]=cen1


;;micro-lens basis
  idx=(findgen(nlens)-(nlens-1)/2)#replicate(1l,nlens)
  jdy=replicate(1l,nlens)#(findgen(nlens)-(nlens-1)/2)
;  dx=idx*W*P+jdy*W
;  dy=jdy*W*P-W*idx

wx=1. & wy=1.
hh=1. ; box for fit
wcst=4.8 & Pcst=-1.8



for quadrant=1L,4 do find_pol_positions_quadrant, quadrant,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,spotpos,im, spotpos_pixels, spotpos_pixvals, display=display_flag


suffix="-"+strcompress(bandeobs,/REMOVE_ALL)+'-polcal'
;fname=strmid(filename,0,STRLEN(filename)-6)+suffix+'.fits'
fname = file_basename(filename, ".fits")+suffix+'.fits'

;we want wavcal with even side pixel length  -JM
; Why? -MP
if (nlens mod 2) eq 1 then spotpos=spotpos[*,0:nlens-2,0:nlens-2,*]

; Set keywords for outputting files into the Calibrations DB
sxaddpar, h, "FILETYPE", "Polarimetry Spots Cal File", /savecomment
sxaddpar, h,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'

sxaddhist, " ",/blank, h
sxaddhist, " Pol Calib File Format:",  h
sxaddhist, "    Axis 1:  pos_x, pos_y, rotangle, width_x, width_y",  h
sxaddhist, "       rotangle is in degrees, widths in pixels",  h
sxaddhist, "    Axis 2:  Lenslet X",  h
sxaddhist, "    Axis 3:  Lenslet Y",  h
sxaddhist, "    Axis 4:  Polarization ( -- or | ) ",  h
sxaddhist, " ",/blank, h





;@__end_primitive
; - NO - 
; due to special output requirements (outputting pixels lists, not anything in
; the *dataset.currframe structure as usual)
; we can't use the standardized template end-of-procedure file saving code here.
; Instead do it this way: 

if ( Modules[thisModuleIndex].Save eq 1 ) then begin
	b_Stat = save_currdata ( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=0 ,$
		   savedata=spotpos, saveheader=h, output_filename=out_filename)
    if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')

	writefits, out_filename, spotpos_pixels, /append
	writefits, out_filename, spotpos_pixvals, /append
end

if tag_exist( Modules[thisModuleIndex], "stopidl") then if keyword_set( Modules[thisModuleIndex].stopidl) then stop

return, ok

end
