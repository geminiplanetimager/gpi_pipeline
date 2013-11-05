;+
; NAME: gpi_klip_algorithm_spectral_differential_imaging
; PIPELINE PRIMITIVE DESCRIPTION: KLIP algorithm Spectral Differential Imaging
;
;             This algorithm reduces noise in a datacube using the
;             KLIP algorithm
; 
; INPUTS:
;       input datacube
;       wavelength solution from common block
;
; KEYWORDS:
;
; GEM/GPI KEYWORDS:
;
; DRP KEYWORDS:
;
; OUTPUTS: 
;       A reduced datacube with reduced noise
;
; ALGORITHM:
;       Measure annuli out from the center of the cube and create a
;       reference set for each annuli of each slice. Apply KLIP to the
;       reference set and project the target slice onto the KL
;       transform vector. Subtract the projected image from the
;       original and repeat for all slices 
;
; PIPELINE COMMENT: Reduce speckle noise using the KLIP algorithm across the spectral axis of a datacube.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="refslice" Type="int" Range="[0,100]" Default="0" Desc="Slice of the reference PSF"
; PIPELINE ARGUMENT: Name="annuli" Type="int" Range="[0,100]" Default="5" Desc="Number of annuli used"
; PIPELINE ARGUMENT: Name="movement" Type="float" Range="[0.0,5.0]" Default="2.0" Desc="Minimum pixel movement for reference set"
; PIPELINE ARGUMENT: Name="prop" Type="float" Range="[0.8,1.0]" Default=".99999" Desc="Proportion of eigenvalues used to truncate KL transform vectors"
; PIPELINE ARGUMENT: Name="arcsec" Type="float" Range="[0.0,1.0]" Default=".4" Desc="Radius of interest if using 1 annulus"
; PIPELINE ARGUMENT: Name="signal" Type="int" Range="[0,1]" Default="0" Desc="1: calculate signal to noise ration, 0: don't calculate"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="5" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.8
; PIPELINE NEWTYPE: SpectralScience
;
; HISTORY:
;        Written 2013. Tyler Barker
;        2013-07-18 MP: Renamed for consistency
;-

function gpi_klip_algorithm_spectral_differential_imaging, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

cube = *(dataset.currframe[0])
band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
cwv = get_cwv(band,spectralchannels=(size(cube,/dim))[2]) 

;;error handle if extractcube not used before
if ((size(cube))[0] ne 3) || (strlen(band) eq 0)  then $
   return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before this one.')

;;verify that speckle align has been run
if ~ backbone->get_keyword('SPKALIGN',/silent) then $
   return, error('FAILURE ('+functionName+'): Must align the speckles before running this code.')

;;get the sat spots
tmp = backbone->get_keyword("SATSMASK", ext_num=1, count=ct)
if ct eq 0 then $
   return, error('FAILURE ('+functionName+'): SATSMASK undefined.  Use "Measure satellite spot locations" before this one.')

;;convert mask to binary
goodcode = hex2bin(tmp,(size(cube,/dim))[2])
good = long(where(goodcode eq 1))
cens = fltarr(2,4,(size(cube,/dim))[2])
for s=0,n_elements(good) - 1 do begin
   for j = 0,3 do begin 
      tmp = fltarr(2) + !values.f_nan 
      reads,backbone->get_keyword('SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2),ext_num=1),tmp,format='(F7," ",F7)' 
      cens[*,j,good[s]] = tmp 
   endfor 
endfor

;;get user inputs
refslice=Modules[thisModuleIndex].refslice
if refslice ge (size(cube))[3] then $
   return, error('FAILURE ('+functionName+'): Reference slice does not exist. k must be smaller than number of spectral channels.')
annuli=long(Modules[thisModuleIndex].annuli)
movmt=double(Modules[thisModuleIndex].movement)
prop=double(Modules[thisModuleIndex].prop)
arcsec=double(Modules[thisModuleIndex].arcsec)
signal=long(Modules[thisModuleIndex].signal)

;;get the status console
statuswindow = backbone->getstatusconsole()

output=klip(cube,refslice=refslice,band=band,locs=cens,annuli=annuli,movmt=movmt,prop=prop,arcsec=arcsec,snr=snr,signal=signal,statuswindow=statuswindow,nummodules=double(N_ELEMENTS(Modules)))

*(dataset.currframe[0]) = output
suffix = suffix+'-klip'

backbone->set_keyword,'HISTORY', functionname+": SDI KLIP applied.",ext_num=0

if signal then begin
   save_suffix = suffix+'-snr'
   tmp = dataset
   *(tmp.currframe[0]) = snr
   b_Stat = save_currdata( tmp, Modules[thisModuleIndex].OutputDir, save_suffix, display=display)
   if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save SNR cube.')
endif 

@__end_primitive
end

      
 
