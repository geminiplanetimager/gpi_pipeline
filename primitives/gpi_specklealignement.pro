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
; PIPELINE TYPE: ASTR/SPEC
; PIPELINE SEQUENCE: 
;
;
; HISTORY:
; 	2012-02 JM
;-

Function  gpi_specklealignement, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id: gpi_specklealignement.pro 525 2012-02-23 16:02:46Z maire $' ; get version from subversion to store in header history
  getmyname, functionname
@__start_primitive
 
cubefin=*(dataset.currframe[0])
if (size(cubefin))[0] ne 3  then return, error('FAILURE ('+functionName+'): speckle alignment can only be done on 3D datacube.')
;thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
thisModuleIndex = Backbone->GetCurrentModuleIndex()

k=Modules[thisModuleIndex].k
if k ge (size(cubefin))[3] then return, error('FAILURE ('+functionName+'): Reference slice does not exist. k must be smaller than number of spectral channels.')

sz=(size(cubefin))


filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
;Common Wavelength Vector
lambdamax=CommonWavVect[1]
lambdamin=CommonWavVect[0]
CommonWavVect[2]=(size(cubefin))[3]
lambda=dblarr(CommonWavVect(2))
for i=0,CommonWavVect(2)-1 do lambda(i)=lambdamin+double(i)*(lambdamax-lambdamin)/(CommonWavVect(2)-1)


if sz[0] eq 3 then begin
  Ima2=fltarr(sz[1]-(sz[1] mod 2),sz[2]-(sz[2] mod 2),sz[3])
  L1=lambda[k]
  for numL1=0,sz[3]-1 do begin
    Ima0=(cubefin)[*,*,numL1] 
    if (sz[1] mod 2) then begin
      Imag=Ima0[0:sz[1]-2,0:sz[2]-2]
    endif else begin
      Imag=Ima0
    endelse
    if numL1 eq k then begin 
      Ima2[*,*,k]=Imag[*,*]
    endif else begin  
      Imag(where(~FINITE(Imag)))=0.
      L2m=(lambda)[numL1]
      Ima2[*,*,numL1]=fftscale(Imag,double(L1)/double(L2m),double(L1)/double(L2m),1e-7)
    endelse  
  endfor
 
 endif
 
thisModuleIndex = Backbone->GetCurrentModuleIndex()
;if numext eq 0 then hdr= *(dataset.headers)[numfile] else hdr= *(dataset.headersPHU)[numfile]
hdr=*(dataset.headersExt)[numfile]
       ;remove wcs keywords because astrometry will not be the same across the datacube:
;    sxdelpar, hdr , 'CDELT1'
;    sxdelpar, hdr, 'CRPIX1'
;    sxdelpar, hdr, 'CRVAL1'
;    sxdelpar, hdr , 'CDELT1'
;    sxdelpar, hdr, 'CTYPE1'
 

suffix2=suffix+'-specalign'    
   if tag_exist( Modules[thisModuleIndex],"ReuseOutput")  then begin
   ; put the datacube in the dataset.currframe output structure:
   *(dataset.currframe[0])=Ima2
    Modules[thisModuleIndex].Save=1 ;will save output on disk, so outputfilenames changed
    sssd=0
    suffix+='-specalign' 
    *(dataset.headersExt)[numfile]=hdr
    endif
    
    
 ; sxaddparlarge,*(dataset.headersPHU[numfile]),'HISTORY',functionname+": Simple Spectral Diff. applied."
backbone->set_keyword,'HISTORY', functionname+": Speckle alignment applied.",ext_num=1
    

;*(dataset.headers)[numfile]=hdr
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix2, savedata=Ima2, saveheader=hdr, display=display)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
          Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
    endelse

 

return, ok
end
