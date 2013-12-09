;+
; NAME:  gpi_estimate_2d_uncertainty_image
;
;	Given an image, estimate the uncertainty at a given pixel
;	based on photon noise, read noise, and statistics. 
;
;
;	**CAUTION** This is an ESTIMATE, and a simple one at that.
;		Do not trust it too much. Code has only been tested partially
;		on a subset of cases.
;
; INPUTS:	The image data and headers from a 2D GPI detector image
; KEYWORDS:
; OUTPUTS:	Returns a 2D image giving estimated uncertainty, or a
;			-1 if the calculation fails for some reason.
;			
;
; HISTORY:
;	Began 013-12-07 23:35:18 by Marshall Perrin 
;-

function gpi_estimate_2d_uncertainty_image, image, priheader, sciheader, dq=dq, dqheader=dqheader, filename=filename, $
	debug=debug

	if keyword_set(filename) then begin
		if ~file_test(filename) then return, error("File does not exist: "+filename)

		tmp = readfits(filename, priheader,/silent)
		image = readfits(filename, ext=1, sciheader,/silent)
		dq = readfits(filename, ext=2, dqheader, /silent)
	endif


bunit = sxpar(sciheader,'BUNIT', count=ct)
if ct ne 1 then return, error('missing BUNIT keyword')
if bunit ne 'ADU per coadd' then return, error('Unsupported unit; must be ADU per coadd')

nREADs = sxpar(sciheader,'READS',count=ct)
if ct ne 1 then return, error('missing READS keyword')
ncoadds = sxpar(sciheader,'COADDS',count=ct)
if ct ne 1 then return, error('missing COADDS keyword')
gain = sxpar(sciheader,'SYSGAIN',count=ct)
if ct ne 1 then return, error('missing SYSGAIN keyword')
;
; optional DRP produced keyword recording how many files were combined together 
nexposures = sxpar(priheader,'DRPNFILE',count=ct)
if ct ne 1 then nexposures = 1 
; we assume all had the same coadds; this is not strictly guaranteed but should
; be true in all typical cases. 






; what is the gain for the image? This depends not just on the actual gain but
; the number of combined exposures. 
effective_gain = gain * ncoadds * nexposures


photon_noise_variance = image * effective_gain ; in photoelectrons

wneg = where(photon_noise_variance lt 0, negct)
if negct gt 0 then photon_noise_variance[wneg] = 10 ; totally arbitrary floor.


read_noise_variance = ((11.-3)/sqrt(nreads)+3) * effective_gain ; FIXME this is a super rough hack barely even an eyeball fit
	; also in electrons

; noise from destriping or other steps is neglected


; TODO make use of DATA QUALITY extension here?




; Now compute the uncertainty and hand it back

total_variance = photon_noise_variance + read_noise_variance
estimated_noise = sqrt(total_variance / effective_gain)

if keyword_set(debug) then begin
	atv, [[[image]],[[estimated_noise]]],/bl
	stop
endif

return, estimated_noise

end


