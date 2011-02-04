;+
; NAME:
;    extractspectra
;
; PURPOSE:
;    extract  Pickles spectra data file
;
; HISTORY:
;   2007/12 J�r�me Maire
;-
function ExtractSpectra2,  spect, lambda, lamb=lamb

;common DST_INPUT
widthL=(lambda(1)-lambda(0))

fileSpectra=getenv('GPI_IFS_DIR')+path_sep()+'dst'+path_sep()+'pickles'+path_sep()+'uk'+spect+'.dat'
Spectra = READ_ASCII(fileSpectra, DATA_START=10) ;[lambda(A) f(lambda)/f(0.5556um)]   lambda sampling: 5A

Spectra.field1(1,*)=Spectra.field1(0,*)*Spectra.field1(1,*) ;flambda=�f
;for i=0,17 do begin &$
dummy=VALUE_LOCATE(Spectra.field1(0,*), (lambda(0)-widthL)*1e4)
dummy2=VALUE_LOCATE(Spectra.field1(0,*), (lambda(n_elements(lambda)-1)+widthL)*1e4)

;dummy=-1 ;&$
;repeat dummy=dummy+1 until $
;     (abs(Spectra.field1(0,dummy)-(lambda(0)-widthL)*1e4) le (Spectra.field1(0,2)-Spectra.field1(0,1))/2.)&$
;dummy2=-1 ;&$
;repeat dummy2=dummy2+1 until $
;      (abs(Spectra.field1(0,dummy2)-(lambda(nlambda-1)+widthL)*1e4) le (Spectra.field1(0,2)-Spectra.field1(0,1))/2.);&$
;      ;if i eq 0 then Spec=dblarr(dummy2-dummy+1,18) &$
;      ;if i eq 0 then Lamb=dblarr(dummy2-dummy+1,18) &$
  Spec = (Spectra.field1(1,dummy:dummy2)) ;&$ ;spectra normalized [f(lambda)/f(0.5556um)] sampling 5A from [lmin-DL/2:lmax+DL/2]
  Lamb = (Spectra.field1(0,dummy:dummy2)) ;&$

;endfor

;found value at lambda=1.65um and normalize at lambda=1.65um =� [f(lambda)/f(1.65um)]
;dummy=-1
;repeat dummy=dummy+1 until $
;      (abs(Spectra.field1(0,dummy)-(1.65)*1e4) le (Lamb(2)-Lamb(1))/2.)
;for H band (example), found value at lambda=1.65um and normalize at lambda=1.65um =� [f(lambda)/f(1.65um)]
dummy=VALUE_LOCATE(Spectra.field1(0,*), (lambda(0)+0.5*(lambda(n_elements(lambda)-1)-lambda(0)))*1e4)

Spec=Spec/Spectra.field1(1,dummy) ;normalize



return, spec
end

;+
; NAME:
;    n_phot_H
;
; PURPOSE:
;    Computes the number of photons/second/nm/m^2 emitted by a star
;    of a given magnitude in one of the UBVRIJHK bandpasses
;
; HISTORY:
;   2007/11/21 Jerome Maire
;-
function n_phot_H, mag,             $
                 BAND=band,       $
                 SURF=surf,       $
                 DELTA_T=delta_t, $
                 WIDTH=width

; bands:
band_tab   = $
[ "U",  "B",  "V",  "R",  "I", "Y",  "J",  "H",  "K"]
;
;FIXME NOTE: Y band flux is entirely made up! - MDP
zero_point = [7.59e7, 1.46e8, 9.71e7, 6.46e7, 3.9e7, 1.0e7, 1.97e7, 9.6e6, 4.5e6]
;[ph/s/nm/m^2] ref:http://www.gemini.edu/sciops/instruments/instrumentIndex.html,http://www.gemini.edu/sciops/instruments/?q=sciops/instruments&q=node/10257
;These values were derived from the CIT system used in the STScI units conversin tool (UBVRI) and Cohen et al. (1992. AJ, 104, 1650; JHKL'M' from Vega and Sirius for 10 and 20um).]



dummy=-1
if (n_elements(band)) then begin
   ;MDP repeat dummy=dummy+1 until (band_tab[dummy] eq band)
   ; MDP modification for IDL idiom!
   dummy = (where(band_tab eq band))[0]

endif


zeropoint=zero_point[dummy] ;;[photons/s/nm/m^2]

nb_of_photons = delta_t*surf*(width*1e9)*zeropoint * 10^(-mag/2.5)
                                          ; source number of photons



return, nb_of_photons      ; back to calling program
end

;+
; NAME: nbphot_trans
; 		Compute the transmitted spectrum of an object through the atmosphere,
; 		including both atmospheric absorption and sky glow emission.
;
; INPUTS:
; 	/obj	if 0, use mag and spectrum from common block
; KEYWORDS:
; 	HDR		FITS header for history recording
; OUTPUTS:
;
; HISTORY:
; 	Originally by Jerome Maire 2007-11
; 	2008-01-24	M. Perrin 	Documentation added, minor code cleanups
;   r
;   2008-04-02 JM: do not force filter to be H in n_phot_H call
;   2008-04-07	MP: The sky background stuff in here is wrong; moved to dst_add_sky
;-

function PIP_nbphot_trans_lowres, hdr, lambda, atmostrans=atmostrans, filtertrans=filtertrans
	;common DST_INPUT

	;if obj eq 0 then begin
		magni=double(SXPAR( hdr, 'Hmag'))
		spect=strcompress(SXPAR( hdr, 'SPECTYPE'),/rem)
		print, 'star mag=',magni,' spectype=',spect
		Dtel=double(SXPAR( hdr, 'TELDIAM'))
		Obscentral=double(SXPAR( hdr, 'SECDIAM'))
		exposuretime=double(SXPAR( hdr, 'EXPTIME'))
		filter=SXPAR( hdr, 'FILTER')
		nlambda=n_elements(lambda)
	;endif
	widthL=(lambda(1)-lambda(0))
	SURFA=!dpi*(Dtel^2.)/4.-!dpi*((Obscentral)^2.)/4.
;	if strcmp(bande,'H') NE 1 then begin
;		Result = DIALOG_MESSAGE('In this DST early version, magnitude must be given in H band')
;		;stop
;	end

	;Nb photons for mag(band H) with bandpass, surface and int. time
	;============================================================
	nbphot = n_phot_H(double(magni), $
					  BAND=STRMID(filter, 0, 1),    $
					  WIDTH=(1e-6)*widthL, $
					  SURF=surfa,        $
					  DELTA_T=exposuretime)


	;Extract Spectra
	;========================================
	Spec=ExtractSpectra2(spect, lambda, lamb=lamb)
		; spect is in ?? units
		; lamb is in Angstroms; convert it to microns
	lamb  = reform(lamb/ 1e4)
;stop
	;Atmospheric Transmission
	;==========================================
	if keyword_set(atmostrans) then $
;	transmission_Atmos=Atmos_Trans(Lamb=Lamb, hdr=hdr) else transmission_Atmos=1.
transmission_Atmos=atmos_trans_forpipeline(wind=21,Lamb=lamb) else transmission_Atmos=1.

if keyword_set(filtertrans) then $
filter_trans=pipeline_getfilter(lamb, filter=filter) else filter_trans=1.
;	;sky background;
;	;==============================================
;	if (skybackg eq 1 and obj eq 0) then  photon_SkyBackground=SkyBackgr(state.airmass) else photon_SkyBackground=0.

	; adding sky background, taking into account atmosp. and instru. transmissions
		  ;=============================================================================
	HiResGrndSpec=Spec* transmission_Atmos * filter_trans

	GroundSpec=dblarr(nlambda)

width=lambda[n_elements(lambda)-1]-lambda[0]
case strcompress(filter,/REMOVE_ALL) of
  'Y':specresolution=35.
  'J':specresolution=37.
  'H':specresolution=45.
  'K1':specresolution=65.
  'K2':specresolution=75.
endcase
         cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]

dlam=((lambdamin+lambdamax)/2.)/specresolution
fwhmloc = VALUE_LOCATE(Lamb, [(lambda[0]),(lambda[0]+dlam)])
fwhm=float(fwhmloc[1]-fwhmloc[0])
print, 'fwhm=',fwhm
gaus = PSF_GAUSSIAN( Npixel=3*fwhm, FWHM=fwhm, NDIMEN =1, /NORMAL )
LowResGrndSpec = CONVOL( reform(HiResGrndSpec), gaus , /EDGE_TRUNCATE ) 

	; MDP note: The following bit of extremely convoluted code integrates the
	; HiResGrndSpec array over Lambda, repeatedly, to obtain the low resolution
	; ground spectrum. This could absolutely be done in a more IDL-like fashion!
	;  But this loop executes for such a very short time in practice that it doesn't
	;  matter that it's terribly inefficient code...
	;
	; FIXME - how is the coronagraphic starlight suppression handled?

locg=intarr(2)
	for i=0,nlambda-1 do begin
	loc = VALUE_LOCATE(Lamb, [(lambda(i)-widthL/2.),(lambda(i)+widthL/2.)])
	if i eq 0 then locg[0]=loc[0]
	if i eq nlambda-1 then locg[1]=loc[1]
		dummy=loc[0];double(-1)
		;repeat dummy=dummy+1 until (abs(Lamb(dummy)-(lambda(i)-widthL/2.)) le (Lamb(20)-Lamb(19))/2.)

		;diff = (lamb[20]-lamb[19])/2 ; MDP
		;step = 1e4*(lambda[i]-widthL/2.) ; MDP
		
		


		 dummy2=loc[1];double(-1)
		;repeat dummy2=dummy2+1 until  (abs(Lamb(dummy2)-(lambda(i)+widthL/2.)) le (Lamb(20)-Lamb(19))/2.)
		 ;phot_SB(i) = total(photSB.field1(1,dummy:dummy2)) &$  ;ph/sec/arcsec2/nm/m2
		GroundSpec[i] = (1./((Lamb(2)-Lamb(1))*(dummy2-dummy)))*INT_TABULATED(Lamb(dummy:dummy2),LowResGrndSpec(dummy:dummy2),/DOUBLE)
	endfor

	; transmission_instrument=transmi/100.

	 ;nbtot_phot=(nbphot* GroundSpec+ photon_SkyBackground)*  transmission_instrument
	 nbtot_phot=(nbphot* GroundSpec);*  transmission_instrument
;stop

  if 0 then begin

    window, 20
    plot, lamb[locg[0]:locg[1]], HiResGrndSpec[locg[0]:locg[1]]/max(HiResGrndSpec[locg[0]+10:locg[1]]), xtitle="Wavelength", ytitle="star spec (normalized)"
    oplot, lambda, nbtot_phot/max(nbtot_phot), psym=10,color=fsc_color('red')
  endif
	return, nbtot_phot
end
