;+
; NAME: extractcube_undispersed
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Undispersed Image
;
;	This routine performs a simple extraction of GPI IFS undispersed
;	data. It requires a pair of fits files explicitly named xlocs.fits
;	and ylocs.fits located in the current directory. Those files contain 
;	a 300x300 array of x and y positions for spots. These files are
;	produced by the routine identify.pro which examines a flood illuminated
;	grid of spots.
;
;	The routine currently assumes the spots in the IFS are shifted by
;	2.36 and 2.63 pixels from the time the calibration frame was taken
;	in the UCLA lab. If your image has significant flux in the central lenslets
;	then you can comment out the fitting portion of the code, and the
;	pattern shift will be determined for you.
;
;	fname = name of the fits file you want to reduce
;	outname = name of the output file this routine will produce
;
;	example usage:
;	     extu, "test0159.fits", "extu0159.fits"
;
;
; KEYWORDS: 
; OUTPUTS:
;
; PIPELINE COMMENT: Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis
; PIPELINE ARGUMENT: Name="xshift" Type="float" Range="[-100,100]" Default="-2.363" Desc="Shift in X direction"
; PIPELINE ARGUMENT: Name="yshift" Type="float" Range="[-100,100]" Default="-2.6134" Desc="Shift in Y direction"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-extu" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE TYPE: ALL-SPEC
;
; HISTORY:
;   Originally by James Larkin as extu.pro
;   2012-02-07 Pipelinified by Marshall Perrin
;   2012-03-30 Rotated by 90 deg to match spectral cube orientation. NaNs outside of FOV. - MP
;+
function extractcube_undispersed, DataSet, Modules, Backbone

primitive_version= '$Id: extractcube.pro 560 2012-01-31 22:10:03Z maire $' ; get version from subversion to store in header history
  @__start_primitive

    ;get the 2D detector image
    array=*(dataset.currframe[0])
	
	
	
	array0=array
; Read in the input fits file and remove the horizontal banding.
for j=0,2047 do begin
	array[*,j]=array[*,j]-median(array[*,j])
end



; Read the locations of the spots from the required files.
config_dir = gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()
xloc=readfits(config_dir+"xlocs.fits")
yloc=readfits(config_dir+"ylocs.fits")

outarr=fltarr(250,250)

; Hardwire the shift for this directory
xshf=float(Modules[thisModuleIndex].xshift)
yshf=float(Modules[thisModuleIndex].yshift)
;xshf=-2.363
;yshf=-2.6134

;; Center array
; Uncomment this section if you want the routine to try and adjust
; the centering of the pattern to your frame. In this simple form
; it checks 5 spots near the center of the array to determine the
; relative offset between your file and the calibration frame.
;xsh=fltarr(5)
;ysh=fltarr(5)
;for i = 148,152 do begin
;	j = 150
;	xs=(fix(xloc[i,j])-3)
;	ys=(fix(yloc[i,j])-3)
;
;	res=gauss2dfit(array[xs:xs+6,ys:ys+6],A)
;	xsh[i-148]=A[4]+fix(xloc[i,j])-3-xloc[i,j]
;	ysh[i-148]=A[5]+fix(yloc[i,j])-3-yloc[i,j]
;	; Shift is median of 5 central shifts
;	xshf = median(xsh)
;	yshf = median(ysh)
;end

;print, "Xshift=",xshf,"  Yshif=",yshf
xloc=xloc+xshf
yloc=yloc+yshf

; Do very simple aperture photometry on the images
; masking off lenslets that don't fall on the detector.
for i = 0, 249 do begin
	for j = 0, 249 do begin
		xs=0>(fix(xloc[i+25,j+25])-2)<2041
		ys=0>(fix(yloc[i+25,j+25])-2)<2041
		outarr[i,j]=total(array[xs:xs+4,ys:ys+4])
		if xloc[i+25,j+25] lt 4 then outarr[i,j]=0.0
		if yloc[i+25,j+25] lt 4 then outarr[i,j]=0.0
		if xloc[i+25,j+25] gt 2035 then outarr[i,j]=0.0
		if yloc[i+25,j+25] gt 2035 then outarr[i,j]=0.0
	end
end


; Rotate the data to match the orientation produced for spectral + pol mode
; datasets

outarr = rotate(outarr, 1)


; put the datacube in the dataset.currframe output structure:
*(dataset.currframe[0])=outarr

@__end_primitive

end

