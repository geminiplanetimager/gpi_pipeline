; NAME: gpi_correct_interpixel_capacitance
;
; Fourier deconvolution algorithm based upon McCullough 2008
;
; INPUTS: 2D image file
;
; OUTPUTS: 2D image corrected for interpixel capacitance
;
; PIPELINE CATEGORY: ALL
; PIPELINE PRIMITIVE DESCRIPTION: Correct for Interpixel Capacitance
; PIPELINE COMMENT: Correct image for interpixel capacitance using Fourier deconvolution.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display " 
; PIPELINE ARGUMENT: Name="alpha" Type="float" Range="[0,1]" Default="0.014" Desc="Fraction of charge in adjacent pixels along columns"
; PIPELINE ARGUMENT: Name="beta" Type="float" Range="[0,1]" Default="0.014" Desc="Fraction of charge in adjacent pixels along rows"
; PIPELINE ORDER: 0.1

function gpi_correct_interpixel_capacitance,  DataSet, Modules, Backbone
	
primitive_version= '$Id: gpi_apply_reference_pixel_correction.pro 2511 2014-02-11 05:57:27Z mperrin $' ; get version from subversion to store in header history
	
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "before_and_after") then before_and_after=fix(Modules[thisModuleIndex].before_and_after) else before_and_after=0

	im =  *dataset.currframe
	
	alpha=float(Modules[thisModuleIndex].alpha) 
	beta=float(Modules[thisModuleIndex].beta) 
	
	ipcdim = 3
	ipc = [0,beta,0,alpha,1.-2.*(beta+alpha),alpha,0,beta,0] 
	ipc = reform(ipc,ipcdim,ipcdim)
	
	; Fourier deconvolution requires an array of even dimensions
	; We're also going to preserve the reference pixels, so check that image is 2048x2048 so we know where they are
	sz = size(im)
	if sz[1] ne 2048 or sz[2] ne 2048 then begin
        backbone->Log, "IPCCOR: Image is not 2048x2048, cannot apply IPC correction."
        backbone->set_keyword, "HISTORY", "Image is not 2048x2048, cannot apply IPC correction."
        return, NOT_OK
    endif
	
	; Don't deconvolve reference pixels
	im_sci = im[4:2043,4:2043]
	
	; ipcdecon
	si1 = size(im_sci)
	si2 = size(ipc)
	
	; bias the image to avoid negative pixel values in the image, which the 
	; FFT method of deconvolution has trouble with.
	
	min_im = min(im_sci)
	im_sci = im_sci - min_im
	
	ipc_big = im_sci*0.
	sx = si1[1]/2 - si2[1]/2
	sy = si1[2]/2 - si2[2]/2 
	ipc_big[sx:sx+si2[1]-1,sy:sy+si2[2]-1] = ipc
	
	ft_im = fft(im_sci)
	ft_psf = fft(ipc_big)
	im_sci = shift(fft(ft_im/ft_psf,/inverse),-si1[1]/2,-si1[2]/2)/(float(si1[1])*float(si1[2]))
	
	; convert from Complex to Real 
	im_sci = float(im_sci)
	
	; restore by removing the bias 
	im_sci = im_sci + min_im
	
	; end of ipcdecon
	
	; Combine reference pixels with deconvoled array
	im[4:2043,4:2043] = im_sci

	*dataset.currframe = im
	
	suffix = 'ipccor'

@__end_primitive

end
	