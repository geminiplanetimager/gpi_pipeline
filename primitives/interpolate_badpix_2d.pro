;+
; NAME: interpolate_badpix_2d
; PIPELINE PRIMITIVE DESCRIPTION: Interpolate to fix bad pixels in a 2D detector image
;
;	Interpolates between vertical (spectral dispersion) direction neighboring
;	pixels to fix each bad pixel.
;
;	TODO: need to evaluate whether that algorithm is still a good approach for
;	polarimetry mode files. 
;
; KEYWORDS:
; 	gpitv=		session number for the GPITV window to display in.
; 				set to '0' for no display, or >=1 for a display.
;
; OUTPUTS:
;
; PIPELINE ARGUMENT: Name="CalibrationFile" type="badpix" default="AUTOMATIC" Desc="Filename of the desired bad pixel file to be read"
; PIPELINE ARGUMENT: Name="method" Type="string" Range="[vertical|all8]" Default="threshhold" Desc='Find background based on interpolating all 8 neighboring pixels, or just the 2 vertical ones?'
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="1" Desc="1-500: choose gpitv session for displaying output, 0: no display "
;
; PIPELINE COMMENT:  Repair bad pixels by interpolating between their neighbors in the spectral dispersion direction.
; PIPELINE ORDER: 1.1 
; PIPELINE TYPE: ALL HIDDEN
; PIPELINE NEWTYPE: SpectralScience,Calibration
;
;
; HISTORY:
; 	Originally by Marshall Perrin, 2012-10-18
;-
function interpolate_badpix_2d, DataSet, Modules, Backbone
primitive_version= '$Id: displayrawimage.pro 417 2012-02-09 14:13:04Z maire $' ; get version from subversion to store in header history
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


	case strlowcase(method) of
	'vertical': begin
		; don't bother trying to fix anything in the ref pix region
		bpmask[0:4,*] = 0
		bpmask[2043:2047,*] = 0
		bpmask[*,0:4] = 0
		bpmask[*,2043:2047] = 0

		wbad = where(bpmask, count)
		; 1 row is 2048 pixels, so we can add or subtract 2048 to get to
		; adjacent rows
		*(dataset.currframe[0]) =  ( (*(dataset.currframe[0]))[wbad+2048] + (*(dataset.currframe[0]))[wbad-2048]) / 2
		backbone->set_keyword, 'HISTORY', 'Masking out '+src(count)+' bad pixels and replacing with interpolated values between vertical neighbors', ext_num=0
		backbone->Log, 'Masking out '+src(count)+' bad pixels and replacing with interpolated values between vertical neighbors'
	end
	'all': begin 
		; don't bother trying to fix anything in the ref pix region
		bpmask[0:4,*] = 0
		bpmask[2043:2047,*] = 0
		bpmask[*,0:4] = 0
		bpmask[*,2043:2047] = 0

		wbad = where(bpmask, count)
		; 1 row is 2048 pixels, so we can add or subtract 2048 to get to
		; adjacent rows

		*(dataset.currframe[0]) =  ( (*(dataset.currframe[0]))[wbad+2048-1:wbad+2048+1] + $
									 (*(dataset.currframe[0]))[wbad-2048-1:wbad-2048+1] + $
									 (*(dataset.currframe[0]))[wbad-1] + $
									 (*(dataset.currframe[0]))[wbad+1] ) / 8
		backbone->set_keyword, 'HISTORY', 'Masking out '+src(count)+' bad pixels; replacing with interpolated values between each 8 neighbor pixels', ext_num=0
		backbone->Log, 'Masking out '+src(count)+' bad pixels;  replacing with interpolated values between each 8 neighbor pixels'

	end

	endcase


 

  suffix='-bpfix'


@__end_primitive
end

