;+
; NAME: gpi_specklealignement
; PIPELINE PRIMITIVE DESCRIPTION: Speckle alignment 
;
; 		This recipe rescales datacube slices with respect to a chosen reference slice. 
;
;		This routine does NOT update the data structures in memory. You **MUST**
;		set the keyword SAVE=1 or else the output is silently discarded.
;
; INPUTS: 
; 	input datacube 
; 	wavelength solution from common block
;
; KEYWORDS:
;
; 	/Save		Set to 1 to save the output file to disk
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
; PIPELINE COMMENT: This recipe rescales datacube PSF slices with respect to a chosen reference PSF slice. This routine does NOT update the data structures in memory. You MUST set the keyword SAVE to 1 or else the output is silently discarded.
; PIPELINE ARGUMENT: Name="k" Type="int" Range="[0,100]" Default="0" Desc="Slice of the reference PSF"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="ReuseOutput" Type="int" Range="[0,1]" Default="1" Desc="1: keep output for following primitives, 0: don't keep"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="5" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.61
; PIPELINE NEWTYPE: SpectralScience
; PIPELINE TYPE: ASTR/SPEC
; PIPELINE SEQUENCE: 
;
;
; HISTORY:
; 	2012-02 JM
;       07.30.2012 - offladed backend to speckle_align - ds
;-

Function  gpi_specklealignement, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS

primitive_version= '$Id$' ; get version from subversion to store in header history
  getmyname, functionname
@__start_primitive
 
cubefin=*(dataset.currframe[0])
if (size(cubefin))[0] ne 3  then return, error('FAILURE ('+functionName+'): speckle alignment can only be done on 3D datacube.')
;thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
thisModuleIndex = Backbone->GetCurrentModuleIndex()

k=Modules[thisModuleIndex].k
if k ge (size(cubefin))[3] then return, error('FAILURE ('+functionName+'): Reference slice does not exist. k must be smaller than number of spectral channels.')

filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
Ima2 = speckle_align(cubefin,refslice=k,band=filter)
 
thisModuleIndex = Backbone->GetCurrentModuleIndex()
;if numext eq 0 then hdr= *(dataset.headers)[numfile] else hdr= *(dataset.headersPHU)[numfile]
hdr=*(dataset.headersExt)[numfile]
;;remove wcs keywords because astrometry will not be the same across the datacube:
;    sxdelpar, hdr , 'CDELT1'
;    sxdelpar, hdr, 'CRPIX1'
;    sxdelpar, hdr, 'CRVAL1'
;    sxdelpar, hdr , 'CDELT1'
;    sxdelpar, hdr, 'CTYPE1'

suffix2=suffix+'-specalign'    
if tag_exist( Modules[thisModuleIndex],"ReuseOutput")  then begin
   ;; put the datacube in the dataset.currframe output structure:
   *(dataset.currframe[0])=Ima2
   Modules[thisModuleIndex].Save=1 ;will save output on disk, so outputfilenames changed
   sssd=0
   suffix+='-specalign' 
   *(dataset.headersExt)[numfile]=hdr
endif

backbone->set_keyword,'HISTORY', functionname+": Speckle alignment applied.",ext_num=0
    
if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
   if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
   b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix2, savedata=Ima2, saveheader=hdr, display=display)
   if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
endif else begin
   if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
      Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
endelse

return, ok
end
