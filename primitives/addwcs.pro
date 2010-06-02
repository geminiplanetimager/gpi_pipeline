
;+
; NAME: Addwcs
; PIPELINE PRIMITIVE DESCRIPTION: Update World Coordinates
;
;	Creates a WCS-compliant header based on the target star's RA and DEC.
;	Currently assumes the target star is precisely centered.
;
; INPUTS: 
;
; KEYWORDS:
; 	CalibrationFile=	Name of astrometric binaries calibration file 
;
; OUTPUTS: 
; 	
;
;
; PIPELINE COMMENT: Add wcs info, assuming target star is precisely centered.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="astrom" Default="GPI-astrom.fits"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-wcs" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.9
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	JM 2009-12
;  JM 2010-03-10: add handle of x0,y0 ref point with PSFcenter
;
function addwcs, DataSet, Modules, Backbone
calfiletype='plate'
@__start_primitive

	calib=readfits(c_File)
	pixelscale=calib[0]
	xaxis_pa_at_zeroCRPA=calib[1]
	
	header=*(dataset.headers)[numfile]
	;;get current CRPA
	obsCRPA=float(SXPAR( header, 'CRPA'))
	
	; handle of x0,y0 ref point 
	x0=float(SXPAR( header, 'PSFCENTX',count=ccx))
    y0=float(SXPAR( header, 'PSFCENTY',count=ccy))
    if (ccx eq 0) || (ccy eq 0) || ~finite(x0) || ~finite(y0) then begin
  		x0=((size(*(dataset.currframe[0])))(1))/2+1
  		y0=((size(*(dataset.currframe[0])))(1))/2+1
	endif


	FXADDPAR, header, 'CTYPE1', 'RA---TAN', 'the coordinate type for the first axis'
	FXADDPAR, header, 'CRPIX1', x0, 'x-coordinate of ref pixel'
	ra= float(SXPAR( Header, 'RA',count=c1))
	FXADDPAR, header, 'CRVAL1', ra, 'RA at ref point' 
	FXADDPAR, header, 'CDELT1', pixelscale/3600.

	FXADDPAR, header, 'CTYPE2', 'DEC--TAN', 'the coordinate type for the second axis'
	FXADDPAR, header, 'CRPIX2', y0, 'y-coordinate of ref pixel'
	dec= float(SXPAR( Header, 'DEC',count=c2))
	FXADDPAR, header, 'CRVAL2', double(SXPAR( Header, 'dec')), 'Dec at ref point'  ;TODOshould see gemini type convention
	FXADDPAR, header, 'CDELT2', pixelscale/3600.

	FXADDPAR, header, 'PC1_1', 1.
	FXADDPAR, header, 'PC2_2', 1.

	

	extast, header, astr

	deg=obsCRPA-xaxis_pa_at_zeroCRPA-90.

	  ;if n_elements(astr) gt 0 then begin
		crpix=astr.crpix
		cd=astr.cd
		theta=deg*!dpi/180.
		ct=cos(theta)
		st=sin(theta)
		rot_mat=[ [ ct, st], [-st, ct] ]

		;new values
		crpix=transpose(rot_mat)#(crpix-1-[x0,y0])+1+[x0,y0]
		cd=cd#rot_mat
		astr.crpix=crpix
		astr.cd=cd
		;put in header
		putast,header,astr
	  ;  endif
	print, astr
	*(dataset.headers)[numfile]=header
		
  sxaddhist, functionname+": updating wold coordinates", *(dataset.headers[numfile])
  sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
@__end_primitive
end
