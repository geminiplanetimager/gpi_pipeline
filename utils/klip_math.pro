function klip_math, image, ref_psf, numbasis
;+
; NAME:
;        klip_math
; PURPOSE:
;        Does the heavy duty matrix algebra KLIP algorithm
;
; EXPLAINATION
;        Calculates the covariance matrix of the refernece PSFs
;        Finds the KLIP eigenbasis and does the PSF subtraction
;
; CALLING SEQUENCE:
;        subtracted_img = klip_math(image, psf_reference)
; 
; INPUT/OUTPUT:
;        image - an array of length 'p' of the science image. 
;        ref_psf - an p x N matrix of the N reference PSFs that 
;                  also contain p pixels
;        subtracted_img - an array of length 'p' that is the subtracted science image
;        numbasis - number of KLIP basis vectors to use
;
; OPTIONAL INPUT:
;        None at the moment
; DEPENDENCIES:
; eigenql.pro
;
; REVISION HISTORY
;        Wrttien 07/03/2014. Refactored for parallelization -jasonwang
;-

;;subtract the mean off each image
;;do it for the science image
T = image - mean(image,/double,/nan)
nanpix = where(~finite(T), num_nanpix)
if num_nanpix gt 0 then T[nanpix] = 0

mean_R_dim1=dblarr(N_ELEMENTS(ref_psf[0,*]))                        
for zz=0,N_ELEMENTS(ref_psf[0,*])-1 do mean_R_dim1[zz]=mean(ref_psf[*,zz],/double,/nan)
R_bar = ref_psf - matrix_multiply(replicate(1,n_elements(image),1),mean_R_dim1,/btranspose)
naninds = where(R_bar ne R_bar,countnan)
if countnan ne 0 then begin 
   ref_psf[naninds] = 0
   R_bar[naninds] = 0
   naninds = array_indices(R_bar,naninds)
endif

;;find covariance of all slices
covar = matrix_multiply(R_bar,R_bar,/atranspose)/(n_elements(image)-1d0) 

;;get the eigendecomposition
;residual = 1         ;initialize the residual
;evals = eigenql(covar,eigenvectors=evecs,/double,residual=residual)  
evals = la_eigenql(covar,eigenvectors=evecs,/double)  

;;determines which eigenalues to truncate
;evals_cut = where(total(evals,/cumulative) gt prop*total(evals))
;K = evals_cut[0]
;	print, "truncating at eigenvalue", K
;if K eq -1 then continue
maxbasis = (size(covar,/dim))[0]-1
K = min([numbasis,maxbasis])

;;creates mean subtracted and truncated KL transform vectors
;Z = evecs ## R_bar[*,fileinds]
Z = evecs ## R_bar
G = diag_matrix(sqrt(1d0/evals/(n_elements(image)-1)))

Z_bar = G ## Z
Z_bar_trunc=Z_bar[*,maxbasis-K:maxbasis] 

;;Project KL transform vectors and subtract from target
signal_step_1 = matrix_multiply(T,Z_bar_trunc,/atranspose)
signal_step_2 = matrix_multiply(signal_step_1,Z_bar_trunc,/btranspose)
subtracted_img = T - transpose(signal_step_2)

;;restore,NANs
if num_nanpix gt 0 then subtracted_img[nanpix] = !values.d_nan

return, subtracted_img

end