;+
; NAME: gpi_highres_microlens_psf_read_highres_psf_structure
; 
; DESCRIPTION: Read the fits file (S2013******-H-PSFs.fits) containing the high resolution psf.
; 
; Only the valid PSFs are saved in the file so that the dimensions of the array have nothing to do with the lenslets array (281x281 (x2)).
; This function sort the PSFs into an array with the dimension given in the input size. One wants it to be [281,281,1] (if "PRISM") or [281,281,2] (if "WOLLASTON").
; 
; INPUTS:
; - filename, thename of the file containing the PSFs: S2013******-H-PSFs.fits for example.
; - the size of the array corresponding to the indices stored in the variable id of the PSF structure.
; 
; OUTPUTS:  
; - return a pointer array with dimensions specified by size. The null pointers are microlens with no available PSF. The valid pointers correspond to the PSFs which were stored in the file.
;     
; HISTORY:
;   Originally by Jean-Baptiste Ruffio 2013-08
;-
function gpi_highres_microlens_psf_read_highres_psf_structure, filename, size
  psfs_from_file = mrdfits(filename,1)
  n_psfs = n_elements(psfs_from_file)
  
  sorted_psfs = ptrarr(size[0],size[1],size[2])
  
  for it_psf = 0,n_psfs-1 do begin
    sorted_psfs[(psfs_from_file[it_psf].id)[0],$
                (psfs_from_file[it_psf].id)[1],$
                (psfs_from_file[it_psf].id)[2]] = ptr_new(psfs_from_file[it_psf],/no_copy)
  endfor
  
  return, sorted_psfs
end

