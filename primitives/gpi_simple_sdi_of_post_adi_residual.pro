;+
; NAME: gpi_simple_sdi_of_post_adi_residual
; PIPELINE PRIMITIVE DESCRIPTION: Simple SDI of post ADI residual
;
;   This recipe rescales and subtracts 2 frames in different user-defined 
;   bandwidths. This recipe is used for speckle suppression using the 
;   Marois et al (2000) algorithm.
;
;   This routine does NOT update the data structures in memory. You **MUST**
;   set the keyword SAVE=1 or else the output is silently discarded.
;
; ALGORITHM:
;    Given the user's specified wavelength ranges, extract the 3D datacube slices
;    for each of those wavelength ranges. Collapse these down into 2D images by
;    simply averaging the values at each lenslet (ignoring NANs).  Rescale Image1
;    using fftscale so that the PSF scale matches that of Image2 (as computed
;    from the average wavelength for each image). Then compute
;       diffImage = I1scaled - k* I2
;    Then hopefully output the image somewhere if SAVE=1 is set. 
;
; INPUTS:  Datacube of ADI residuals
;
; OUTPUTS: Datacube with simple 2-wavelength SDI subtraction
;
;
; PIPELINE COMMENT: Apply SSDI to create a 2D subtracted image from a cube. Given the user's specified wavelength ranges, extract the 3D datacube slices for each of those wavelength ranges. Collapse these down into 2D images by simply averaging the values at each lenslet (ignoring NANs).  Rescale Image1, then compute  diffImage = I1scaled - k* I2
; PIPELINE ARGUMENT: Name="L1Min" Type="float" Range="[0.9,2.5]" Default="1.55" Desc="Wavelength range 1, minimum wavelength [in microns]"
; PIPELINE ARGUMENT: Name="L1Max" Type="float" Range="[0.9,2.5]" Default="1.57" Desc="Wavelength range 1, maximum wavelength [in microns]"
; PIPELINE ARGUMENT: Name="L2Min" Type="float" Range="[0.9,2.5]" Default="1.60" Desc="Wavelength range 2, minimum wavelength [in microns]"
; PIPELINE ARGUMENT: Name="L2Max" Type="float" Range="[0.9,2.5]" Default="1.65" Desc="Wavelength range 2, maximum wavelength [in microns]"
; PIPELINE ARGUMENT: Name="k" Type="float" Range="[0,10]" Default="1.0" Desc="Scaling factor of Intensity(wav_range2) with diffImage = I1scaled - k* I2"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="5" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.3
; PIPELINE CATEGORY: SpectralScience
;
;
; HISTORY:
;     2007-11 Jerome Maire
;    2009-04-15 MDP: Documentation updated; slight code cleanup 
;    2009-09-17 JM: added DRF parameters
;    2013-07-17 MP: Renamed for consistency
;    2013-08-07 ds: idl2 compiler compatible 
;-

Function  gpi_simple_sdi_of_post_adi_residual, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
 
cubefin=*(dataset.currframe[0])
if (size(cubefin))[0] ne 3  then return, error('FAILURE ('+functionName+'): SSDI can only be done on 3D datacube.')
;thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName)
thisModuleIndex = Backbone->GetCurrentModuleIndex()
L1min=Modules[thisModuleIndex].L1min
L1max=Modules[thisModuleIndex].L1max
L2min=Modules[thisModuleIndex].L2min
L2max=Modules[thisModuleIndex].L2max
k=Modules[thisModuleIndex].k
if ~(keyword_set(k)) then k=1.
;check if outside spectral range
filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
case filter of 
  'H': specrange=[1.5,1.8,1.55,1.57,1.60,1.65] ;[min wav of the band, max wav, 4 reasonable wav value for defining 2 spectral range]
  'Y': specrange=[0.95, 1.15,1.04,1.08,1.10,1.13]
  'Z': specrange=[0.95, 1.15,1.04,1.08,1.10,1.13]
  'J': specrange=[1.15, 1.33,1.23,1.28,1.16,1.19]
  'K1': specrange=[1.9, 2.19,2.08,2.11,1.95,1.97]
  'K2': specrange=[2.13, 2.4,2.13,2.16,2.34,2.37]
  else : return, error('FAILURE ('+functionName+'): Failed to filter range.')
endcase
if (L1min ge specrange[0]) && (L1min le specrange[1])  && $
    (L1max ge specrange[0]) && (L1max le specrange[1])  && $
    (L2min ge specrange[0]) && (L2min le specrange[1])  && $
    (L2max ge specrange[0]) && (L2max le specrange[1])  then inside = 1 else inside = 0
    ;if outside then set default values for spectral ranges:
if inside eq 0 then begin
  L1min=specrange[2]
  L1max=specrange[3]
  L2min=specrange[4]
  L2max=specrange[5]

endif    
     

;        cwv=get_cwv('H')
;        CommonWavVect=cwv.CommonWavVect
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
lambdamin=specrange[0]
lambdamax=specrange[1]
;Common Wavelength Vector
lambda=dblarr(CommonWavVect[2])
for i=0,CommonWavVect[2]-1 do lambda[i]=lambdamin+double(i)*(lambdamax-lambdamin)/(CommonWavVect[2]-1)


numL1=VALUE_LOCATE(lambda,double(L1min) )
numL2=VALUE_LOCATE(lambda,double(L1max) )
numL3=VALUE_LOCATE(lambda,double(L2min) )
numL4=VALUE_LOCATE(lambda,double(L2max) )

L1=lambda[numL1]
L2=lambda[numL2]
L3=lambda[numL3]
L4=lambda[numL4]
; compute the middle/average wavelength for each chosen slice
L1m=double(L1)+0.5*(double(L2)-double(L1))
L2m=double(L3)+0.5*(double(L4)-double(L3))
; extract the slices from the datacube and collapse them to 2D images
;note that following 2 code lines remove a lot of nan...
I1=avg(Cubefin[*,*,numL1:numL2],2,/double,/nan)
I2=avg(Cubefin[*,*,numL3:numL4],2,/double,/nan)

wnf1 = where(~FINITE(I1),nancount1)
wnf2 = where(~FINITE(I2),nancount2)
if nancount1 gt 0 then I1[wnf1]=0.
if nancount2 gt 0 then I2[wnf2]=!VALUES.F_NAN
    ; QUERY BY MDP: Why are I1 and I2 not handled the same way here??
    ;ANS JM: 0 for I1 corners because  the fftscale do not work with Nan. 


;;fftscale bugs with image of odd size:
szim=size(I1)
if (szim[1] mod 2) then begin
    I1=I1[0:szim[1]-2,0:szim[2]-2]
    I2=I2[0:szim[1]-2,0:szim[2]-2]
endif 


;;todo: handle PSF center before fftscale 
I1s=fftscale(I1,double(L2m)/double(L1m),double(L2m)/double(L1m),1e-7)


;sssd=I2-k*I1s
sssd=I1s-k*I2

;change keywords related to the common wavelength vector:
hdr=*(dataset.headersExt)[numfile]
;change keywords related to the common wavelength vector:
sxdelpar, hdr, 'NAXIS3'
sxdelpar, hdr , 'CDELT3'
sxdelpar, hdr, 'CRPIX3'
sxdelpar, hdr, 'CRVAL3'
sxdelpar, hdr, 'CTYPE3'
sxaddparlarge, hdr, "HISTORY", functionName+": spectral ranges used [Angtrom]:"
sxaddparlarge, hdr, "HISTORY", functionName+": wav. range 1:"+strc(1.e4*L1min)
sxaddparlarge, hdr, "HISTORY", functionName+": wav. range 1:"+strc(1.e4*L1max)
sxaddparlarge, hdr, "HISTORY", functionName+": wav. range 2:"+strc(1.e4*L2min)
sxaddparlarge, hdr, "HISTORY", functionName+": wav. range 2:"+strc(1.e4*L2max)

backbone->set_keyword,'HISTORY', functionname+": Simple Spectral Diff. applied.",ext_num=0
    
@__end_primitive
end
