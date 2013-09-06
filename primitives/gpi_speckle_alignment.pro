;+
; NAME: gpi_speckle_alignment
; PIPELINE PRIMITIVE DESCRIPTION: Speckle alignment 
;
; 		This recipe rescales datacube slices with respect to a chosen reference slice. 
;
; INPUTS: 
; 	input datacube 
; 	wavelength solution from common block
;
; KEYWORDS:
;
;
; DRP KEYWORDS: CDELT3,CRPIX3,CRVAL3,CTYPE3,NAXIS3
; OUTPUTS:
;
; ALGORITHM:
;	Given the user's specified wavelength ranges, extract the 3D datacube slices
;	for each of those wavelength ranges.   Rescale slices with respect to a reference slice
;	using fftscale so that the PSF scale matches that of reference (as computed
;	from the average wavelength for each image). 
;
; PIPELINE COMMENT: This recipe rescales datacube PSF slices with respect to a chosen reference PSF slice.
; PIPELINE ARGUMENT: Name="k" Type="int" Range="[0,100]" Default="0" Desc="Slice of the reference PSF"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="5" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.61
; PIPELINE NEWTYPE: SpectralScience
;
;
; HISTORY:
; 	2012-02 JM
;       07.30.2012 - offladed backend to speckle_align - ds
;       05.10.2012 - updates to match other primitives and to reflect
;                    changes to backend by Tyler Barker
;-

Function  gpi_speckle_alignment, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
 
cubefin=*(dataset.currframe[0])
filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
;;error handle if extractcube not used before
if ((size(cubefin))[0] ne 3) || (strlen(filter) eq 0)  then $
   return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use "Assemble Datacube" before this one.')  

;;get user input
k=Modules[thisModuleIndex].k
if k ge (size(cubefin))[3] then $
   return, error('FAILURE ('+functionName+'): Reference slice does not exist. k must be smaller than number of spectral channels.')

;;error handle if sat spots haven't been found
tmp = backbone->get_keyword("SATSMASK", ext_num=1, count=ct)
if ct eq 0 then $
   return, error('FAILURE ('+functionName+'): SATSMASK undefined.  Use "Measure satellite spot locations" before this one.')

;;convert mask to binary
goodcode = hex2bin(tmp,(size(cubefin,/dim))[2])
good = long(where(goodcode eq 1))
cens = fltarr(2,4,(size(cubefin,/dim))[2])
for s=0,n_elements(good) - 1 do begin
   for j = 0,3 do begin 
      tmp = fltarr(2) + !values.f_nan 
      reads,backbone->get_keyword('SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2),ext_num=1),tmp,format='(F7," ",F7)' 
      cens[*,j,good[s]] = tmp 
   endfor 
endfor

;;make sure we have the sat spots for the ref slice
tmp = where(~finite(cens[*,*,k]),ct)
if ct ne 0 then $
   return, error('FAILURE ('+functionName+'): Cannot find sat spots for reference slice.')

Ima2 = speckle_align(cubefin,refslice=k,band=filter,locs=cens[*,*,k])
*(dataset.currframe[0]) = Ima2
suffix = suffix+'-specalign'    

backbone->set_keyword,'HISTORY', functionname+": Speckle alignment applied.",ext_num=0
backbone->set_keyword,'SPKALIGN', 1 , 'Cube is speckle aligned', ext_num=1
    
@__end_primitive 

end
