;+
; NAME: interpolate_badpix_2d
; PIPELINE PRIMITIVE DESCRIPTION: Interpolate bad pixels in 2D frame 
;
;	Interpolates between vertical (spectral dispersion) direction neighboring
;	pixels to fix each bad pixel.
;
;	TODO: need to evaluate whether that algorithm is still a good approach for
;	polarimetry mode files. 
;
;	TODO: implement Christian's suggestion of a 3D interpolation in 2D space,
;	using adjacent lenslet spectra as well. See emails of Oct 18, 2012
;	(excerpted below)
;
; KEYWORDS:
; 	gpitv=		session number for the GPITV window to display in.
; 				set to '0' for no display, or >=1 for a display.
;
; OUTPUTS:
;
; PIPELINE ARGUMENT: Name="CalibrationFile" type="badpix" default="AUTOMATIC" Desc="Filename of the desired bad pixel file to be read"
; PIPELINE ARGUMENT: Name="method" Type="string" Range="[nan|vertical|all8]" Default="threshhold" Desc='Find background based on interpolating all 8 neighboring pixels, or just the 2 vertical ones, or just flag as NaN?'
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="1" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
; PIPELINE COMMENT:  Repair bad pixels by interpolating between their neighbors. Can optionally just flag as NaNs or else interpolate.
; PIPELINE ORDER: 1.1 
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE NEWTYPE: SpectralScience,Calibration
;
;
; HISTORY:
; 	Originally by Marshall Perrin, 2012-10-18
;-
function interpolate_badpix_2d, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='badpix'
@__start_primitive

	sz = size( *(dataset.currframe[0]) )
    if sz[1] ne 2048 or sz[2] ne 2048 then begin
        backbone->Log, "Image is not 2048x2048, don't know how to handle this for interpolating"
        return, NOT_OK
    endif


	if ~file_test( c_File) then return, error("Bad pixel file does not exist!")
    bpmask= gpi_READFITS(c_File)

    backbone->set_keyword,'HISTORY',functionname+": Loaded bad pixel map",ext_num=0
    backbone->set_keyword,'HISTORY',functionname+": "+c_File,ext_num=0
    backbone->set_keyword,'DRPBADPX',c_File,ext_num=0

	if tag_exist( Modules[thisModuleIndex], "method") then method=(Modules[thisModuleIndex].method) else method='vertical'

	; don't bother trying to fix anything in the ref pix region
	bpmask[0:4,*] = 0
	bpmask[2043:2047,*] = 0
	bpmask[*,0:4] = 0
	bpmask[*,2043:2047] = 0

	wbad = where(bpmask, count)
	case strlowcase(method) of
	'nan': begin
		; just flag bad pixels as NaNs
		(*(dataset.currframe[0]))[wbad] = !values.f_nan
		backbone->set_keyword, 'HISTORY', 'Masking out '+src(count)+' bad pixels to NaNs ', ext_num=0
		backbone->Log, 'Masking out '+src(count)+' bad pixels and to NaNs'
	
	end

	'vertical': begin
		; Just uses neighboring pixels above and below

		; 1 row is 2048 pixels, so we can add or subtract 2048 to get to
		; adjacent rows
		(*(dataset.currframe[0]))[wbad] =  ( (*(dataset.currframe[0]))[wbad+2048] + (*(dataset.currframe[0]))[wbad-2048]) / 2
		backbone->set_keyword, 'HISTORY', 'Masking out '+src(count)+' bad pixels and replacing with interpolated values between vertical neighbors', ext_num=0
		backbone->Log, 'Masking out '+src(count)+' bad pixels and replacing with interpolated values between vertical neighbors'
	end
	'all8': begin 
		; Uses all 8 neighboring pixels
		;

		; 1 row is 2048 pixels, so we can add or subtract 2048 to get to
		; adjacent rows
		(*(dataset.currframe[0]))[wbad] =  ( (*(dataset.currframe[0]))[wbad+2048-1:wbad+2048+1] + $
		 							 		 (*(dataset.currframe[0]))[wbad-2048-1:wbad-2048+1] + $
		 							 		 (*(dataset.currframe[0]))[wbad-1] + $
									 		 (*(dataset.currframe[0]))[wbad+1] ) / 8
		backbone->set_keyword, 'HISTORY', 'Masking out '+src(count)+' bad pixels; replacing with interpolated values between each 8 neighbor pixels', ext_num=0
		backbone->Log, 'Masking out '+src(count)+' bad pixels;  replacing with interpolated values between each 8 neighbor pixels'

	end
	'3D': begin
		stop
		;Let's say you have a bad pixel right at the middle of a spectrum. Instead of
		;taking the 2 vertical pixel neighbors, you take instead the values along the
		;spectrum and use also the information of surrounding spectra to help with the
		;interpolation (do a spatial and wavelength interpolation, but in the raw
		;detector plane ahead of the data cube extraction).
		;
		;
		;I like this idea. To expand on it a little bit, you would need to take each bad
		;pixel in the 2D array, and calculate which of the 40,000 lenslet spectra it's
		;closest to, using the wavelength solution. You'd end up with an (x,y) index for
		;the lenslet, a wavelength, and an offset from the spectrum midline in the cross
		;dispersion direction. 
		;
		;Then, you compute the adjacencies. You'd end up with 6 neighboring pixels:
		;  1 & 2: pixels in same lenslet spectrum at adjacent wavelengths. Immediate vertical neighboring pixels on the 2D array. 
		;  3,4,5,6: pixels at the same wavelength and cross-dispersion offset, for the 4 immediately adjacent lenslets. These pixels are offset on the detector by about 10 pixels in various diagonal directions. 
		;
		;So, then do you just take the average of all 6 of those? Or is there some more
		;clever way to interpolate in space and wavelength at once? 
		;
		;(In some small set of cases you'd have fewer than those 6, because you hit the
		;edge of the array or one of those other pixels is itself bad too. But that's a
		;tiny fraction of cases)
		;
	end

	endcase


 

  suffix='-bpfix'


@__end_primitive
end

