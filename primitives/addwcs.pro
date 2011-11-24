;+
; NAME: Addwcs
; PIPELINE PRIMITIVE DESCRIPTION: Update World Coordinates
;
;    Creates a WCS-compliant header based on the target star's RA and DEC.
;    Currently assumes the target star is precisely centered.
;
; INPUTS: 
;
; KEYWORDS:
;     CalibrationFile=    Name of astrometric binaries calibration file 
;
; OUTPUTS: 
;     
; GEM/GPI KEYWORDS:CRPA,RA,DEC
; DRP KEYWORDS: CDELT1,CDELT2,CRPIX1,CRPIX2,CRVAL1,CRVAL2,CTYPE1,CTYPE2,HISTORY,PC1_1,PC2_2,PSFCENTX,PSFCENTY
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
;  JM 2009-12
;  JM 2010-03-10: add handle of x0,y0 ref point with PSFcenter
;  2010-10-19 JM: split HISTORY keyword if necessary
;  2011-08-01 MP: Update for multi-extension FITS
;
function addwcs, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='plate'

@__start_primitive

    
	;fits_info, c_File, /silent, N_ext=n_ext
	;if n_ext eq 0 then calib=readfits(c_File) else calib=mrdfits(c_File,1)
	calib=gpi_readfits(c_file, header=cal_header)
  
	pixelscale=calib[0]
	xaxis_pa_at_zeroCRPA=calib[1]
	
	;if numext eq 0 then 
	;header= *(dataset.headersExt)[numfile]
	;else header=*(dataset.headersPHU)[numfile]
	;;get current CRPA
	;obsCRPA=float(SXPAR( header, 'CRPA'))
	obsCRPA = backbone->get_keyword('CRPA')


    ; handle of x0,y0 ref point 
    x0=float(backbone->get_keyword( 'PSFCENTX',count=ccx))
    y0=float(backbone->get_keyword( 'PSFCENTY',count=ccy))
    if (ccx eq 0) || (ccy eq 0) || ~finite(x0) || ~finite(y0) then begin
        x0=((size(*(dataset.currframe[0])))(1))/2+1
        y0=((size(*(dataset.currframe[0])))(1))/2+1
    endif


    backbone->set_keyword, 'CTYPE1', 'RA---TAN', 'the coordinate type for the first axis'
    backbone->set_keyword, 'CRPIX1', x0, 'x-coordinate of ref pixel'
    ra= float(backbone->get_keyword( 'RA'))
    backbone->set_keyword, 'CRVAL1', ra, 'RA at ref point' 
    backbone->set_keyword, 'CDELT1', pixelscale/3600.

    backbone->set_keyword, 'CTYPE2', 'DEC--TAN', 'the coordinate type for the second axis'
    backbone->set_keyword, 'CRPIX2', y0, 'y-coordinate of ref pixel'
    dec= float(SXPAR( Header, 'DEC',count=c2))
    backbone->set_keyword, 'CRVAL2', double(backbone->get_keyword( 'DEC')), 'Dec at ref point'  ;TODOshould see gemini type convention
    backbone->set_keyword, 'CDELT2', pixelscale/3600.

    backbone->set_keyword, 'PC1_1', 1.
    backbone->set_keyword, 'PC2_2', 1.

    
    extast, *(dataset.headersExt)[numfile], astr

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
	cd[0,0]*=-1. ;;;hmmm, need to be verified!
	astr.cd=cd

	;put in header
	putast,*(dataset.headersExt)[numfile],astr
  	;  endif
    print, astr
    ;*(dataset.headersExt)[numfile]=header
        
    backbone->set_keyword,'HISTORY',functionname+": updating world coordinates",ext_num=1
    backbone->set_keyword,'HISTORY',functionname+": "+c_File,ext_num=1
@__end_primitive
end
