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
;	Began 2013-12-07 23:35:18 by Marshall Perrin 
;       2014-07-01 MPF  bugfix, cleanup, and added UTR stdev vs. nreads curve
;-

function gpi_estimate_2d_uncertainty_image, image, priheader, sciheader, dq=dq, dqheader=dqheader, filename=filename, $
	debug=debug

  if keyword_set(filename) then begin
    if ~file_test(filename) then return, error("File does not exist: "+filename)
    
    tmp = readfits(filename, priheader, /silent)
    image = readfits(filename, ext = 1, sciheader, /silent)
    dq = readfits(filename, ext = 2, dqheader, /silent)
  endif


  bunit = sxpar(sciheader, 'BUNIT', count = ct)
  if ct ne 1 then return, error('missing BUNIT keyword')
  if bunit ne 'ADU per coadd' then return, error('Unsupported unit; must be ADU per coadd')

  nreads = sxpar(sciheader, 'READS', count = ct)
  if ct ne 1 then return, error('missing READS keyword')
  ncoadds = sxpar(sciheader, 'COADDS', count = ct)
  if ct ne 1 then return, error('missing COADDS keyword')
  gain = sxpar(sciheader, 'SYSGAIN', count = ct)
  if ct ne 1 then return, error('missing SYSGAIN keyword')


  ;; optional DRP produced keyword recording how many files were combined together 
  nexposures = sxpar(priheader, 'DRPNFILE', count = ct)
  if ct ne 1 then nexposures = 1 
  ;; we assume all had the same coadds; this is not strictly guaranteed but should
  ;; be true in all typical cases. 

  ;; what is the gain for the image? This depends not just on the actual gain but
  ;; the number of combined exposures. 
  effective_gain = gain * ncoadds * nexposures ; [e-/ADU]


  ;; load the UTR read noise vs. # reads curve
  readcol, gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'utr_read_noise.dat', tab_nreads, tab_rn, skipline = 1, format = ('F,F'), /silent

  ;; figure out what the read noise is per coadd per exposure
  rn_std_per_coadd = tab_rn[where(tab_nreads eq nreads, /null)] ; [e-]
  rn_std_per_coadd = rn_std_per_coadd[0] ; convert to scalar
  ;rn_std_per_coadd = 2.913175

  ;; compute photon noise variance
  photon_noise_variance = image * effective_gain ; [e-^2]

  ;; apply arbitrary photon noise variance floor
  photon_noise_variance[where(photon_noise_variance lt 0, /null)] = 10. ; [e-^2]


  read_noise_variance = rn_std_per_coadd^2 * ncoadds * nexposures ; [e-^2]


  ;; noise from destriping or other steps is neglected (?)

  ;; TODO make use of DATA QUALITY extension here?


  ;; Now compute the uncertainty and hand it back
  total_variance = photon_noise_variance + read_noise_variance ; [e-^2]
  estimated_noise = sqrt(total_variance / effective_gain^2) ; [ADU]

  if keyword_set(debug) then begin
    atv, [[[image]], [[estimated_noise]]], /bl
    stop
  endif

  return, estimated_noise

end


