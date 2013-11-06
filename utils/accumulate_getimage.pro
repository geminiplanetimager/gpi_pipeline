;+
; NAME:  accumulate_getimage
; PIPELINE PRIMITIVE DESCRIPTION: Return one of the images saved by Accumulate_Images
;		
;		Return one of the images saved by Accumulate_Images.pro
;
;		To be used as an accessor routine inside any primitive that 
;		combines multiple files from the accumulator.
;
; INPUTS:
; KEYWORDS:     slice - Return individual slice (or slices if array)
; OUTPUTS:
; 	hdr		primary HDU header
; 	hdrext	image extension header
;
; PIPELINE COMMENT: Return one of the images saved by Accumulate_Images
; HISTORY:
; 	Began 2009-07-22 17:12:00 by Marshall Perrin 
;   2011-07-30 MP: Updated for multi-extension FITS
;   2013-11-05 - ds - Added support for single slice return
;-


FUNCTION accumulate_getimage, dataset, index, hdr, hdrext=hdrext, slice=slice
  common PIP
  common APP_CONSTANTS

  
  case size( *(dataset.frames[index])   ,/TNAME ) of
     ;; Option 1: Nothing has been accumulated in position N. 
     ;; In that case, read in the input file of that filename

     'UNDEFINED': begin
        ;; image was never read in the first place. 
        fits_info, dataset.inputdir + path_sep() + *(dataset.filenames[index]), n_ext = num_ext, /silent
        if num_ext eq 0 then begin
           image = readfits( dataset.inputdir + path_sep() + *(dataset.filenames[index]), hdr,/silent) 
           hdrext=hdr           ; copy so hdrext is defined
        endif else begin
           image = mrdfits( dataset.inputdir + path_sep() + *(dataset.filenames[index]), 1,hdrext,/silent)
           hdr =   headfits(dataset.inputdir + path_sep() + *(dataset.filenames[index]), exten=0, /silent)
           hdrext = headfits(dataset.inputdir + path_sep() + *(dataset.filenames[index]), exten=1, /silent)
        endelse
        if n_elements(slice) ne 0 then return, image[*,*,slice] else return, image
     end

     ;; Option 2:  image was stored on disk, so read it in and return it
     "STRING": begin
        fits_info,  *(dataset.frames[index]), n_ext = num_ext, /silent
        if num_ext eq 0 then begin
           image = readfits(  *(dataset.frames[index]), hdr,/silent) 
           hdrext=hdr           ; copy so hdrext is defined
        endif else begin
           image = mrdfits( *(dataset.frames[index]), 1, hdrext,/silent)
           hdr =   headfits(*(dataset.frames[index]), exten=0, /silent) 
           hdrext =   headfits(*(dataset.frames[index]), exten=1, /silent) 
        endelse  
        
        if n_elements(slice) ne 0 then return, image[*,*,slice] else return, image
     end

     ;; Option 3: image was kept in memory so just hand that back.
     else :begin

        hdr =   *(dataset.headersPHU[index])
        hdrext =  *(dataset.headersExt[index])  
        
        if n_elements(slice) ne 0 then return,(*(dataset.frames[index]))[*,*,slice] else  return, *(dataset.frames[index])
     end
  endcase

end
