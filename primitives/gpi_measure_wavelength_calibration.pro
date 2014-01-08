;+
; NAME: gpi_measure_wavelength_calibration
; PIPELINE PRIMITIVE DESCRIPTION: Measure Wavelength Calibration 
;
;	gpi_extract_wavcal detects positions of spectra in the image with narrow
;	band lamp image.
;
; ALGORITHM:
;	gpi_extract_wavcal starts by detecting the central peak of the image.
;	Next, starting with a initial value of w & P, find the nearest peak (with an increment on the microlens coordinates)
;	when nearest peak has been detected, it reevaluates w & P and so forth..
;
; *********************************************************************************
; *
; *  IMPORTANT WARNING for future software maintainers:
; *     The complicated algorithms implemented here were originally developed
; *     assuming the dispersion direction in GPI would be horizontal. Given data
; *     orientation conventions later adopted, it became vertical. Rather than
; *     rewriting all of the following and swapping all the indices around, 
; *     the images are just *transposed* as the first step of this process, and
; *     then the original horizontal algorithm applied. This leads to various
; *     complexities about index transformations. Be wary when editing the
; *     code here and keep that in mind....
; *
; *
; *********************************************************************************
;  
;
;
; INPUTS: 2D image from narrow band arclamp
; common needed:
;
; KEYWORDS:
; GEM/GPI KEYWORDS:FILTER,IFSFILT,GCALLAMP,GCALSHUT,OBSTYPE
; DRP KEYWORDS: FILETYPE,HISTORY,ISCALIB
; OUTPUTS:
;
; PIPELINE ORDER: 1.7

; PIPELINE ARGUMENT: Name="nlens" Type="int" Range="[0,400]" Default="281" Desc="side length of  the  lenslet array "
; PIPELINE ARGUMENT: Name="centrXpos" Type="int" Range="[0,2048]" Default="1024" Desc="Initial approximate x-position [pixel] of central peak at 1.5microns"
; PIPELINE ARGUMENT: Name="centrYpos" Type="int" Range="[0,2048]" Default="1024" Desc="Initial approximate y-position [pixel] of central peak at 1.5microns"
; PIPELINE ARGUMENT: Name="w" Type="float" Range="[0.,10.]" Default="4.8" Desc="Spectral spacing perpendicular to the dispersion axis at the image center [pixel]"
; PIPELINE ARGUMENT: Name="P" Type="float" Range="[-7.,7.]" Default="-1.8" Desc="Ratio of spectral offset parallel to dispersion over spectral spacing perpendicular to dispersion"
; PIPELINE ARGUMENT: Name="emissionlinesfile" Type="string"  Default="AUTOMATIC" Desc="File of emission lines."
; PIPELINE ARGUMENT: Name="wav_of_centrXYpos" Type="int" Range="[1,2]" Default="2" Desc="1 if centrX-Ypos is the smallest-wavelength peak of the band; 2 if centrX-Ypos refer to 1.5microns"
; PIPELINE ARGUMENT: Name="maxpos" Type="float" Range="[-7.,7.]" Default="2." Desc="Allowed maximum location fluctuation (in pixel) between adjacent mlens"
; PIPELINE ARGUMENT: Name="maxtilt" Type="float" Range="[-360.,360.]" Default="10." Desc="Allowed maximum tilt fluctuation (in degree) between adjacent mlens"
; PIPELINE ARGUMENT: Name="centroidmethod" Type="int" Range="[0,1]" Default="0" Desc="Centroid method: 0 means barycentric (fast), 1 means gaussian fit (slow)"
; PIPELINE ARGUMENT: Name="medfilter" Type="int" Range="[0,1]" Default="1" Desc="1: Median filtering of dispersion coeff and tilts with a (5x5) median filtering"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="iscalib" Type="int" Range="[0,1]" Default="1" Desc="1: save to Calibrations Database, 0: save in regular reduced data dir"
; PIPELINE ARGUMENT: Name="lamp_override" Type="int" Range="[0,1]" Default="0" Desc="0,1: override the filter/lamp combinations?"
; PIPELINE ARGUMENT: Name="gpitvim_dispgrid" Type="int" Range="[0,500]" Default="15" Desc="1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display "
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying wavcal file, 0: no display "
; PIPELINE ARGUMENT: Name="tests" Type="int" Range="[0,3]" Default="0" Desc="1 for extensive tests "
; PIPELINE ARGUMENT: Name="testsDST" Type="int" Range="[0,3]" Default="0" Desc="1 for DST tests "
; PIPELINE COMMENT: Derive wavelength calibration from an arc lamp or flat-field image.
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 
; HISTORY:      
; 	 Jerome Maire 2008-10
;	  JM: nlens, w (initial guess), P (initial guess), cenx (or centrXpos), ceny (or centrYpos) as parameters
;   2009-09-17 JM: added DRF parameters
;   2009-12-10 JM: initiate position at 1.5microns so we can take into account several band
;   2010-07-14 JM:for DRP testing, correct for DST finite spectral resolution 
;   2010-08-16 JM: added bad pixel map
;   2011-07-14 MP: Reworked FITS keyword handling to provide more informative
;         error messages in case of missing or invalid keywords.
;   2011-08-02 MP: Updated for multi-extension FITS.
;   2012-12-13 MP: Bad pixel map now taken from DQ extension if present.
;				   Print more informative logging messages for the user
;				   Various bits of code cleanup.
;   2012-12-20 JM: more centroid methods added
;   2013-07-12 MP: Rename for consistency 
;-

function gpi_measure_wavelength_calibration,  DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

    im=*dataset.currframe
 
    ;;'Image rotated to match old DST convention of horizontal dispersion!' 
    ;; final wavelength solution at the end of this routine is derotated to match vertical dispersion
    im=rotate(im,1)
    ;;need to rotate the bad pixel map too

    if ptr_valid( dataset.currDQ) then begin
		badpixmaprot=rotate( *dataset.currDQ,1)
	endif
   
    valid_header=1
    ; error handle missing FITS keywords
    keywords_to_check = ['OBSTYPE', 'GCALLAMP', 'IFSFILT', 'INSTRUME']

    for i=0L,n_elements(keywords_to_check)-1 do begin
      val=backbone->get_keyword( keywords_to_check[i],count=c)
      if c eq 0 then return, error('FAILURE ('+functionName+'): FITS header keyword '+keywords_to_check[i]+" is missing!")
      if strlen(val) eq 0 then return, error('FAILURE ('+functionName+'): FITS header keyword '+keywords_to_check[i]+" is a null string, which is an invalid value!")
    endfor 

    obstype=backbone->get_keyword( 'OBSTYPE',count=c1)
    lamp   =backbone->get_keyword( 'GCALLAMP',count=c2)
    if c2 eq 0 then return, error("No GCALLAMP keyword was present, therefore cannot determine what spectrum would be appropriate.")
    
    c3=1&lampshut='ON';lampshut=SXPAR( h, 'GCALSHUT',count=c3) ;will be implemented if necessary

    bandeobs=backbone->get_keyword( 'IFSFILT',count=c4,/simplify)
    instrum=backbone->get_keyword( 'INSTRUME',count=cinstru)
    

    if strmatch(obstype,'*flat*',/fold) then begin
         im0=im
         im = (SHIFT_DIFF(im, DIRECTION=3)>0.) ;works with spatial derivative of the image (this direction works for lambda_min edge)
    endif     
   
	szim=size(im)

;;;centroid algo chosen by the user
if tag_exist( Modules[thisModuleIndex], "centroidmethod")  then begin
  meth=uint(Modules[thisModuleIndex].centroidmethod)
;  case methint of
;    1:meth="barycentric"
;    2:meth="mpfit"
;    3:meth="gaussfit"
;  endcase 
endif else begin
meth=0
endelse
	;;create the cube which will contain in the slice 
	; 0:x-positions (x0) of spectra (spectral direction) at a given lambda [lambda0] (can be lambda_min)
	; 1:y-positions (y0) of spectra at a given lambda
	;  The relation of dispersion for each spectrum is defined as lambda=w3*(sqrt((x-x0)^2+(y-y0)^2))+lambda0
	; 2: lambda0
	; 3: w3 (median value given by the n peaks of each spectrum, n>1)
	; 4: tilts of spectra (median value given by the n peaks, n>1)
	; nlens will be the spatial side length of the wavecal in pixels (usually =281 for DST images)
	nlens=uint(Modules[thisModuleIndex].nlens)
	specpos=dblarr(nlens,nlens,5)+!VALUES.F_NAN  ;specpos will handle the wavecal in this routine!

	;localize central peak around the center of the image
	cen1=dblarr(2)	& cen1[0]=-1 & cen1[1]=-1
	wx=0 & wy=0 ;define sidelength (2wx+1 by 2wy+1 ) of box for maximum intensity detection
	hh=1. ;define sidelength (2hh+1 by 2hh+1 ) of box for centroid intensity detection


	; Read in the file of emission line wavelengths to use in calibration
	if (tag_exist( Modules[thisModuleIndex], "emissionlinesfile")) && file_test(gpi_expand_path(Modules[thisModuleIndex].emissionlinesfile),/read) then $
		emissionlinefile=  gpi_expand_path(Modules[thisModuleIndex].emissionlinesfile) else $
		emissionlinefile=  gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'lampemissionlines.txt'
	backbone->set_keyword, "HISTORY", "Lamp emission lines file used: "+emissionlinefile,ext_num=0

	nlines = FILE_LINES(emissionlinefile) 
	sarr = STRARR(nlines) 
	OPENR, unit, emissionlinefile,/GET_LUN 
	READF, unit, sarr 
	FREE_LUN, unit 
	sarr_nocomm=sarr[2:nlines-1]
	lamp2=lamp
	if strmatch(lamp,'*Xe*',/fold) then lamp2='Xe'
	if strmatch(lamp,'*Ar*',/fold) then lamp2='Ar'
	indemis=where(stregex(sarr_nocomm,bandeobs, /bool) and stregex(sarr_nocomm,lamp2, /bool), countval )
	if countval gt 0 then begin
	  split=strsplit(sarr_nocomm[indemis],count=csplit,/extract)
	  split2=split[2:csplit-1]
	  peakwavelen=float(split2)
	endif else begin
	  stop
	  return, error('FAILURE ('+functionName+'): Failed to load emission lines.') 
	endelse

        if  Modules[thisModuleIndex].lamp_override eq 1 then begin
           message,/info, "Lamp override enabled, bypassing lamp/filter enforcements"
           backbone->set_keyword, "HISTORY", "Lamp override enabled, bypassing lamp/filter enforcements"
        endif
        case strcompress(bandeobs,/REMOVE_ALL) of
           'Y':begin
           ; error handling for usable filters
              if Modules[thisModuleIndex].lamp_override eq 0 and lamp ne 'Xe' and lamp ne 'Ar' then return, error('ERROR ('+functionName+'): Incorrect Lamp/Filter combination - Y band wavelength calibrations should be performed with Argon or Xenon lamps. You can override this error by setting the lamp_override keyword to 1') 
              
              if (cinstru eq 1) && strmatch(instrum,'*DST*') then begin
                 specpixlength=15. ;spec pix length for rough estimation of peak positions
                 bandwidth=0.2     ;bandwidth in microns
        endif else begin
			specpixlength=17. ;spec pix length for rough estimation of peak positions
			bandwidth=0.2;0.18; 0.23  ;bandwidth in microns
                     endelse
     end
           'J':begin
              if Modules[thisModuleIndex].lamp_override eq 0 and lamp ne 'Xe' then return, error('ERROR ('+functionName+'): Incorrect Lamp/Filter combination - J band wavelength calibrations should be performed with the Xenon lamp. You can override this error by setting the lamp_override keyword to 1') 
              if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[1.15],[1.33]] ;[[1.12],[1.35]]
              if (cinstru eq 1) && strmatch(instrum,'*DST*') then begin
                 specpixlength= 15.    ;spec pix length for rough estimation of peak positions
                 bandwidth=0.18        ; 0.23  ;bandwidth in microns
              endif else begin
                 specpixlength=17.     ;spec pix length for rough estimation of peak positions
                 bandwidth=0.23        ;0.18; 0.23  ;bandwidth in microns
              endelse
           end
           'H':begin
           if Modules[thisModuleIndex].lamp_override eq 0 and lamp ne 'Xe' then return, error('ERROR ('+functionName+'): Incorrect Lamp/Filter combination - H band wavelength calibrations should be performed with the Xenon lamp. You can override this error by setting the lamp_override keyword to 1') 
      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[1.5],[1.8]]
		specpixlength=20. ;17. ;spec pix length for rough estimation of peak positions
		bandwidth=0.3 ;bandwidth in microns
             end
	'K1':begin
           if Modules[thisModuleIndex].lamp_override eq 0 and lamp ne 'Xe' then return, error('ERROR ('+functionName+'): Incorrect Lamp/Filter combination - K1 band wavelength calibrations should be performed with the Xenon lamp. You can override this error by setting the lamp_override keyword to 1') 
           if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[1.9],[2.19]]
           specpixlength=20.    ;spec pix length for rough estimation of peak positions
           bandwidth=0.3        ;bandwidth in microns
        end
        'K2':begin
           if  Modules[thisModuleIndex].lamp_override eq 0 and lamp ne 'Xe' then return, error('ERROR ('+functionName+'): Incorrect Lamp/Filter combination - K2 band wavelength calibrations should be performed with the Xenon lamp. You can override this error by setting the lamp_override keyword to 1')
        if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[2.13],[2.4]]
        specpixlength=20. ;spec pix length for rough estimation of peak positions
        bandwidth=0.27    ;bandwidth in microns
     end
endcase



    ;;2010-07-14 J.Maire: The following added for testing, 
    ;; use it only for wavelength solution testing based on DST sim
    ;;correct for finite DST spectral resolution !!
    
   ; if (tag_exist( Modules[thisModuleIndex], "testsDST")) && ( fix(Modules[thisModuleIndex].testsDST) eq 1 ) then begin
   if strmatch(instrum,'*DST*') && ~strmatch(bandeobs,'*Y*') then begin
		backbone->Log, "Detected DST data - running additional code to correct for finite DST spectral resolution "
		case strcompress(bandeobs,/REMOVE_ALL) of
            'Y':begin
                if strmatch(lamp,'*Xe*',/fold) then relativethresh=0.35
                if strmatch(lamp,'*Ar*',/fold) then relativethresh=0.5
              end
            'J':begin
                if strmatch(lamp,'*Xe*',/fold) then relativethresh=0.05
                if strmatch(lamp,'*Ar*',/fold) then relativethresh=0.5
              end
            'H':begin
                if strmatch(lamp,'*Xe*',/fold) then relativethresh=0.2
                if strmatch(lamp,'*Ar*',/fold) then relativethresh=0.5
              end
            'K1':begin
                if strmatch(lamp,'*Xe*',/fold) then relativethresh=0.2
                if strmatch(lamp,'*Ar*',/fold) then relativethresh=0.5
              end
            'K2':begin
                if strmatch(lamp,'*Xe*',/fold) then relativethresh=0.2
                if strmatch(lamp,'*Ar*',/fold) then relativethresh=0.43
              end
          endcase
          if   ~(strmatch(obstype,'*flat*',/fold)) then begin
          DSTdir= gpi_get_directory('GPI_DST_DIR')

          readcol, DSTdir+path_sep()+strmid(lamp,0,2)+'ArcLampG.txt', wavelen, strength
          wavelen=1.e-4*wavelen
          ;if (strcompress(bandeobs,/REMOVE_ALL) eq 'Y') && strmatch(lamp,'*Xenon*',/fold) then wavelen-=0.03
          lambdadst=readfits(DSTdir+path_sep()+'zemdispLam'+strcompress(bandeobs, /rem)+'.fits')
          spect = fltarr(n_elements(lambdadst))
      
          wg = where(wavelen gt min(lambdadst) and wavelen lt max(lambdadst), gct)
        
          for i=0L,gct-1 do begin
            diff = min(abs(lambdadst - wavelen[wg[i]]), closest)
            spect[closest] += strength[wg[i]]
          endfor  
           mlensarr=rebin(spect,  n_elements(lambdadst))
           seuil=(relativethresh)* max(mlensarr)
           print, 'seuil=',seuil
           lambdadstind=where(mlensarr gt seuil)
           peakwavelen2=transpose(lambdadst[lambdadstind])
           print, 'Testing: correct for finite DST spectral resolution...'
           print, 'True reference peak for this lamp:',peakwavelen
           print, 'Reference peak adopted:',peakwavelen2
           peakwavelen=peakwavelen2
           endif
           wavstr=''
           for st=0,n_elements(peakwavelen)-1 do wavstr+=strcompress(string(peakwavelen[st]),/rem)+'/'
           backbone->set_keyword, "TESTWAV", wavstr, 'wav of detected peaks', ext_num=0
           ;stop
       
    endif

	;;---- localize first peak ;; these coordinates depend strongly on data!!
	; The user may specify the starting coordinates directly in the DRF, or else
	; this code will look up a default starting position from the
	; wavcal_start_positions file. 
	;
	; Also, the starting position can be automatically modified based on
	; wavelength (but it seems more reliable to hard code these in a lookup
	; table?)
	;


	if float(Modules[thisModuleIndex].centrYpos) eq 0 or Modules[thisModuleIndex].centrXpos eq 0 then begin
		backbone->Log, "Starting position given as (X,Y) = (0,0). Therefore loading position from wavcal_start_positions.txt"
		readcol, gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'wavcal_start_positions.txt', $
			def_pos_band, def_pos_x, def_pos_y, def_type, def_orient, format='A,F,F,A,A'
		; are we looking at data from real IFS or DST here?
		dstver = backbone->get_keyword('DST_VER',count=dstct)
		if dstct eq 0 then data_type='REAL' else data_type = 'DST'

		wm = where(def_pos_band eq bandeobs and strlowcase(def_type) eq strlowcase(data_type) and strlowcase(def_orient) eq strlowcase(backbone->get_keyword('DSORIENT')), mct)
		if mct eq 0 then begin
			backbone->Log, 'Could not find default settings for starting position! Results undefined.'
		endif else begin
			if cenx eq 0 then cenx = float(def_pos_x[wm])
			if ceny eq 0 then ceny = float(def_pos_y[wm])
		endelse
		backbone->Log, 'Loaded default starting position(s) from config table: '+printcoo(cenx, ceny)
	endif else begin
		;;take into account the rotation we made on image: note that axes have been switched with regard to old definition
		cenx=float(szim[1])-1.-float(Modules[thisModuleIndex].centrYpos)
		ceny=float(Modules[thisModuleIndex].centrXpos)
		backbone->Log, "Starting position given as (X,Y) = ("+strc(Modules[thisModuleIndex].centrXpos)+", "+strc(Modules[thisModuleIndex].centrYpos)+") in the recipe file"
	endelse



	if fix(Modules[thisModuleIndex].wav_of_centrXYpos) eq 2. then begin
		backbone->Log, "Extrapolating from starting position (implictly at 1.5 microns) to current line wavelengths"
		;;from cenx at 1.5microns, estimate x-location of first peak to detect
		cenx+=(peakwavelen[0]-1.5)*(18./0.3)

		;make a slight correction for far Y-band spectra:
		;if (strcompress(bandeobs,/REMOVE_ALL) eq 'Y') && (cinstru eq 1) && strmatch(instrum,'*DST*') then cenx+=0. else $
		;if (strcompress(bandeobs,/REMOVE_ALL) eq 'Y') then cenx -=0. ; this is not used anymore

		; compute location in original image coordinates for display:
		display_ceny = float(szim[1])-1. - cenx
		display_cenx = ceny
		backbone->Log, 'Estimated Y-location of first peak at '+sigfig(peakwavelen[0],5)+ ' microns = '+strc(display_ceny)+ " pix"
		backbone->Log, '         (X-location is unchanged, at '+strc(display_cenx)+ " pix"
	endif

while (~finite(cen1[0])) || (~finite(cen1[1])) || $
		(cen1[0] lt 0) || (cen1[0] gt (size(im))[1]) || $
		(cen1[1] lt 0) || (cen1[1] gt (size(im))[1])  do begin
	wx+=1 & wy+=1
	cen1=localizepeak( im, cenx, ceny,wx,wy,hh)
	backbone->Log, 'Peak detected at pos: ('+strc( cen1[1])+", "+strc(float(szim[1])-1.-cen1[0])+")"
endwhile
specpos[nlens/2,nlens/2,0:1]=cen1

;;micro-lens basis
;  idx=(findgen(nlens)-(nlens-1)/2)#replicate(1l,nlens)
;  jdy=replicate(1l,nlens)#(findgen(nlens)-(nlens-1)/2)
  idx=(findgen(nlens)-(nlens-(nlens mod 2))/2)#replicate(1l,nlens)
  jdy=replicate(1l,nlens)#(findgen(nlens)-(nlens-(nlens mod 2))/2)
;  dx=idx*W*P+jdy*W
;  dy=jdy*W*P-W*idx

wx=0. & wy=0.
wx=5. & wy=5. ; MDP change
wx=2. & wy=2. ; JM change  wx=1. & wy=0. good for flat
hh=2. ; box for fit
;wcst=4.8 & Pcst=-1.8
wcst=float(Modules[thisModuleIndex].w) & Pcst=float(Modules[thisModuleIndex].P)
edge_x1=4.
edge_x2=4.
edge_y1=4.
edge_y2=4.
if strmatch(obstype,'*flat*',/fold) then begin
  wx=1. & wy=0.
endif

tight_pos=float(Modules[thisModuleIndex].maxpos)  
tight_tilt=float(Modules[thisModuleIndex].maxtilt)  

;;this is going to take forever, so let's give the user
;;something to look at (reuse the fits file bar as you're
;;effectively working on a new file)
statuswindow = backbone->getstatusconsole()
if obj_valid(statuswindow) then statuswindow->set_percent,-1,0

backbone->Log, 'Now measuring positions of all lenslets...'
;calculate now x-y locations of the first peak of all spectra (specpos[*,*,0] and specpos[*,*,1]): 
;for quadrant=1L,4 do find_spectra_positions_quadrant, quadrant,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,specpos,im,edge_x1,edge_x2,edge_y1,edge_y2,tight_pos
for quadrant=1L,4 do find_spectra_positions_quadrant, quadrant,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,specpos,im,edge_x1,edge_x2,edge_y1,edge_y2,tight_pos,badpixmap=badpixmaprot,meth=meth,statuswindow=statuswindow,progscale=1d/4d/4d

if strcmp(obstype,'flat',4,/fold) then specpos[*,*,0]-=0.5 ;take account of spatial shift in derivative


;;;;;;;;;;;;;;;;;;;;;;;;
;;dispersion law & tilts
;;;;;;;;;;;;;;;;;;;;;;;;

  if (tag_exist( Modules[thisModuleIndex], "tests")) && ( Modules[thisModuleIndex].tests eq 1 ) then begin
	  backbone->Log, 'User requested running additional tests. Now doing so...'
	  backbone->Log, "Tests disabled; missing gaussfwhm.pro"

;      dispeak=dblarr(nlens,nlens,2*n_elements(peakwavelen))+!VALUES.F_NAN 
;      dispeak[*,*,0]=specpos[*,*,0]
;      dispeak[*,*,1]=specpos[*,*,1]
;      dispeak2=dblarr(nlens,nlens,n_elements(peakwavelen))+!VALUES.F_NAN
;      for xi=0,nlens-1 do begin
;        for yi=0,nlens-1 do begin
;            ;dispeak2[xi,yi,0]=splinefwhm(im[dispeak[xi,yi,0]-2:dispeak[xi,yi,0]+2,dispeak[xi,yi,1]-2:dispeak[xi,yi,1]+2])
;            ;dispeak2[xi,yi,0]=radplotfwhm(im,dispeak[xi,yi,0],dispeak[xi,yi,1])
;            dispeak2[xi,yi,0]=gaussfwhm(im[dispeak[xi,yi,0]-5:dispeak[xi,yi,0]+5,dispeak[xi,yi,1]-5:dispeak[xi,yi,1]+5])
;        endfor
;      endfor
  endif else begin 
	dispeak=0
  endelse

;if strmatch(obstype,'*flat*',/fold) then im = (SHIFT_DIFF(im0, DIRECTION=4)>0.) ;works with spatial derivative of the image (lambda_max edge)
if strmatch(obstype,'*flat*',/fold) then im = (SHIFT_DIFF(im0>(2.*stddev(im0>0.)), DIRECTION=4)>0.) ;works with spatial derivative of the image (lambda_max edge)

specpos[*,*,2]=peakwavelen[0]
if n_elements(peakwavelen) gt 1 then begin
	backbone->Log, 'Now calculating dispersions of all lenslets...'
	apprXpos=(peakwavelen-peakwavelen[0])*specpixlength/bandwidth ;  *nbpix for the band / bandwidth
	apprYpos=fltarr(n_elements(apprXpos))
	tilt=fltarr(nlens,nlens,n_elements(apprXpos)-1)+!VALUES.F_NAN

	w3med=fltarr(nlens,nlens)
	w3=fltarr(n_elements(apprXpos)-1)
	;wx=0. & wy=1.
	wx=1. & wy=0. ;flat
	;wx=0. & wy=0. & hh=1. ;flat

	;calculate now x-y locations of the other peaks and deduce linear dispersion coeffs and tilts
	for quadrant=1L,4 do find_spectra_dispersions_quadrant, quadrant,peakwavelen,apprXpos,apprYpos,nlens,w3,w3med,tilt,specpos,im,wx,wy,hh,szim,edge_x1,edge_x2,edge_y1,edge_y2, dispeak, dispeak2, tight_tilt, meth=meth,statuswindow=statuswindow,progscale=3d/4d/4d


endif ; verif si n_elements(peakwavelen) gt 1

; median filtering for bad detection on the edge where part of spectrum are absent...
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
 
if tag_exist( Modules[thisModuleIndex], "medfilter") then if ( fix(Modules[thisModuleIndex].medfilter) eq 1 ) then begin
  backbone->Log, ' Median filtering dispersion and tilt coefficients by 5 pixels.'
  ;do the median filter for dispersion coeff:
  specpostemp=median(specpos[*,*,3],5)
  indNan=where(~finite(specpos[*,*,3]),cnan)
  if cnan ne 0 then specpostemp[where(~finite(specpos[*,*,3]))]=!VALUES.F_NAN
  specpos[*,*,3]=specpostemp
  ;do the median filter for tilts:
  specpostemp=median(specpos[*,*,4],5)
  indNan=where(~finite(specpos[*,*,4]),cnan)
  if cnan ne 0 then specpostemp[where(~finite(specpos[*,*,4]))]=!VALUES.F_NAN
  specpos[*,*,4]=specpostemp
endif

;;quick sanity Nan on edge 
indNan=where(~finite(specpos[*,*,0]),cnan)
if cnan ne 0 then begin
    specpostemp=specpos[*,*,0]
    specpostemp[indNan]=!VALUES.F_NAN
    specpos[*,*,0]=specpostemp
    specpostemp=specpos[*,*,1]
    specpostemp[indNan]=!VALUES.F_NAN
    specpos[*,*,1]=specpostemp
endif

suffix = 'wavecal'
;fname=strmid(filename,0,STRLEN(filename)-6)+suffix+'.fits'
;fname = file_basename(filename,remove_suffix)='.fits')+"-"+bandeobs+"-"+suffix+'.fits'


;if (nlens mod 2) eq 1 then specpos=specpos[0:nlens-2,0:nlens-2,*]
backbone->set_keyword, "FILETYPE", "Wavelength Solution Cal File"

; The user can override the ISCALIB setting, for instance to avoid writing
; intermediate data product wavecal files to the calibrations directory
if tag_exist( Modules[thisModuleIndex], "iscalib") then iscalib = uint(Modules[thisModuleIndex].iscalib) else iscalib = 1
if keyword_set(iscalib) then begin
	backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
endif else begin
	backbone->set_keyword, "ISCALIB", 'NO', 'This file will not be saved to calibrations directory.'
endelse

;backbone->set_keyword, "NAXIS", 3;,/blank
;backbone->set_keyword, "NAXIS3", 5;,/blank ;;for some reason this does not work??! error about NAXIS2 is missing which is false
sxaddpar,*dataset.headersExt[numfile],'NAXIS',3
sxaddpar,*dataset.headersExt[numfile],'NAXIS3',5,after='NAXIS2'

backbone->set_keyword, "HISTORY", " ",ext_num=0;,/blank
backbone->set_keyword, "HISTORY", " Wavelength solution File Format:",ext_num=0
backbone->set_keyword, "HISTORY", " Dispersion for each spectrum is defined as ",ext_num=0
backbone->set_keyword, "HISTORY", " lambda=w * (sqrt((x-x0)^2+(y-y0)^2))+lambda0",ext_num=0
backbone->set_keyword, "HISTORY", "    Slice 1:  Y-positions (y0) of spectra (Y=spectral direction) at [lambda0]",ext_num=0
backbone->set_keyword, "HISTORY", "    Slice 2:  X-positions (x0) of spectra at [lambda0]",ext_num=0
backbone->set_keyword, "HISTORY", "    Slice 3:  lambda0 [um]",ext_num=0
backbone->set_keyword, "HISTORY", "    Slice 4:  dispersion w [um/pixel]",ext_num=0
backbone->set_keyword, "HISTORY", "    Slice 5:  tilts of spectra [radians]",ext_num=0
backbone->set_keyword, "HISTORY", " ",ext_num=0;,/blank


;rotate the wavcal to have vertical dispersion
for qq=0,(size(specpos))[3]-1 do specpos[*,*,qq]=rotate(specpos[*,*,qq],3)
specpos[*,*,0]=float(szim[1])-1.-specpos[*,*,0]

*(dataset.currframe[0])=specpos

;derotate image
im=rotate(im,3)
;*(dataset.headers[numfile])=h
;if numext eq 0 then *(dataset.headers)[numfile]=h else *(dataset.headersPHU)[numfile]=h

;if ( Modules[thisModuleIndex].Save eq 1 ) then begin
;       b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix,  savedata=specpos,saveheader=h)
;       if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;end

if tag_exist( Modules[thisModuleIndex], "tests") then if ( Modules[thisModuleIndex].tests eq 1 ) then $
writefits, strmid(output_filename, 0,strlen(output_filename)-5)+'testdis'+'.fits',dispeak,h
if tag_exist( Modules[thisModuleIndex], "tests") then if ( Modules[thisModuleIndex].tests eq 1 ) then $
writefits, strmid(output_filename, 0,strlen(output_filename)-5)+'testdis2'+'.fits',dispeak2,h


    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
		; Save the wavecal and optionally display it in gpitv
		if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
		b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, bandeobs+"_"+suffix, display=display, $
			savedata=specpos, saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile], output_filename=output_filename)
		if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')

		if tag_exist( Modules[thisModuleIndex], "gpitvim_dispgrid") && ( fix(Modules[thisModuleIndex].gpitvim_dispgrid) ne 0 ) then begin
           if strcmp(obstype,'flat',4,/fold) then im=im0 ; if we took a spatial derivative of a flat to fit it, undo that step
          
			backbone_comm->gpitv, double(im), session=fix(Modules[thisModuleIndex].gpitvim_dispgrid), header=*(dataset.headersPHU)[numfile], dispwavecalgrid=output_filename, imname='Wavecal grid for '+  dataset.filenames[numfile]  ;Modules[thisModuleIndex].name
		endif
    endif else begin
		; Display just the wavecal in gpitv
		if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
			backbone_comm->gpitv, double(*DataSet.currFrame), session=fix(Modules[thisModuleIndex].gpitv), header=*(dataset.headersPHU)[numfile], imname='Pipeline result from '+ Modules[thisModuleIndex].name,dispwavecalgrid=output_filename
    endelse

return, ok

end
