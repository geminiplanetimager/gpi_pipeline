;+
; NAME: calc_astrometry_binaries_sixth_orbit_catalog
; PIPELINE PRIMITIVE DESCRIPTION: Calibrate astrometry from binary (using 6th orbit catalog)
;
;
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	/Save	Set to 1 to save the output image to a disk file. 
;
; GEM/GPI KEYWORDS:CRPA,DATE-OBS,OBJECT,TIME-OBS
; DRP KEYWORDS: FILETYPE,ISCALIB
; OUTPUTS:  plate scale & orientation
;
; PIPELINE COMMENT: Calculate astrometry from unocculted binaries; Calculate Separation and PA at date DATEOBS using the sixth orbit catalog.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-astrom" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.61
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;- 

function calc_astrometry_binaries_sixth_orbit_catalog, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id$' ; get version from subversion to store in header history
	;getmyname, functionName
	  @__start_primitive

   
   	thisModuleIndex = Backbone->GetCurrentModuleIndex()

  	cubef3D=*(dataset.currframe[0])

	cubef3Dz=cubef3D
	wnf1 = where(~FINITE(cubef3D),nancount1)
	if nancount1 gt 0 then cubef3Dz[wnf1]=0.

	sz=size(cubef3Dz)
	posmax1=intarr(2)
	gfit1=dblarr(7,CommonWavVect[2])
	cubef3dmaskbinary1=cubef3Dz
	; find where the maximum brightness is
    maxintensity= max(cubef3Dz[*,*,CommonWavVect[2]/2],indmax,/Nan)
    posmax1=array_indices(cubef3Dz[*,*,CommonWavVect[2]/2],indmax)

   ; For each wavelength, fit a 2D Gaussian around the location of the maximum
   ; brightness. 
   ; Create a modified copy of the array where that peak is masked out too, for
   ; the binary fit.
for i=0,CommonWavVect[2]-1 do begin
   gfit = GAUSS2DFIT(cubef3Dz[((posmax1[0]-10)>0):((posmax1[0]+10)<sz[1]),((posmax1[1]-10)>0):((posmax1[1]+10)<sz[1]),i], B)
   gfit1[*,i]=B[*] 
   gfit1[4,i]+=posmax1[0]-10
   gfit1[5,i]+=posmax1[1]-10
   ;mask binary 1 for detection of binary 2
   cubef3dmaskbinary1[((posmax1[0]-10)>0):((posmax1[0]+10)<sz[1]),((posmax1[1]-10)>0):((posmax1[1]+10)<sz[1]),i]=0.
endfor
print, 'Max intens. of binary 1 x-Pos :',reform(posmax1[0])
print, 'Max intens. of binary 1 y-Pos :',reform(posmax1[1])
print, 'x-Pos of binary 1:',reform(gfit1[4,*])
print, 'y-Pos of binary 1:',reform(gfit1[5,*])


; Now do the fit for the second star.
posmax2=intarr(2,CommonWavVect[2])
gfit2=dblarr(7,CommonWavVect[2])
for i=0,CommonWavVect[2]-1 do begin
   maxintensity= max(cubef3dmaskbinary1[*,*,i],indmax,/Nan)
   posmax2[*,i]=array_indices(cubef3dmaskbinary1[*,*,i],indmax)
   gfit = GAUSS2DFIT(cubef3dmaskbinary1[((posmax2[0,i]-10)>0):((posmax2[0,i]+10)<sz[1]),((posmax2[1,i]-10)>0):((posmax2[1,i]+10)<sz[1]),i], B)
   gfit2[*,i]=B[*] 
   gfit2[4,i]+=posmax2[0,i]-10
   gfit2[5,i]+=posmax2[1,i]-10
endfor
print, 'Max intens. of binary 2 x-Pos :',reform(posmax2[0])
print, 'Max intens. of binary 2 y-Pos :',reform(posmax2[1])
print, 'x-Pos of binary 2:',reform(gfit2[4,*])
print, 'y-Pos of binary 2:',reform(gfit2[5,*])


hdr= *(dataset.headers)[0]
name=(SXPAR( hdr, 'OBJECT'))
dateobs=(SXPAR( hdr, 'DATE-OBS'))
timeobs=(SXPAR( hdr, 'TIME-OBS'))
res=read6thorbitcat( name, dateobs, timeobs) 

; TODO error checking here, in case that object is
; not present in the catalog.

rho=res.sep ;float(Modules[thisModuleIndex].rho) ;get current separation of the binaries
pa=res.pa ;float(Modules[thisModuleIndex].pa) ;get current position angle of the binaries


;;calculate distance in pixels
dist=  sqrt( ((gfit1[4,*]-gfit2[4,*])^2.) + ((gfit1[5,*]-gfit2[5,*])^2.)  )
angle_xaxis_deg=(180./!dpi)*atan((gfit1[5,*]-gfit2[5,*])/(gfit1[4,*]-gfit2[4,*]))

pixelscale=rho/mean(dist,/nan)
print, 'dist between binaries [pix]=',mean(dist,/nan), '  plate scale [arcsec/pix]=',pixelscale
print, ' angle x-axis [deg]', mean(angle_xaxis_deg,/nan)
;;now calculate position angle of x-axis

xaxis_pa=pa-mean(angle_xaxis_deg,/nan)
;;calculate this angle for CRPA=0.
   obsCRPA=float(SXPAR( header, 'CRPA'))
   xaxis_pa_at_zeroCRPA=xaxis_pa-obsCRPA

Result=[pixelscale,xaxis_pa_at_zeroCRPA]


*(dataset.currframe[0])=Result

sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Plate scale & orientation", /savecomment
sxaddpar, *(dataset.headers[numfile]), "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'


	
	if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=Modules[thisModuleIndex].suffix
	
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
		  if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
    endelse


return, ok


end
