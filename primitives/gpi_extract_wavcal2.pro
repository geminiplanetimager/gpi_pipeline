;+
; NAME: gpi_extract_wavcal2
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
;
; INPUTS: 2D image from narrow band arclamp
; common needed:
;
; KEYWORDS:
; GEM/GPI KEYWORDS:FILTER,FILTER1,GCALLAMP,GCALSHUT,OBSTYPE
; DRP KEYWORDS: FILETYPE,HISTORY,ISCALIB
; OUTPUTS:
;
; PIPELINE ORDER: 1.7

; PIPELINE ARGUMENT: Name="nlens" Type="int" Range="[0,400]" Default="281" Desc="side length of  the  lenslet array "
; PIPELINE ARGUMENT: Name="centrXpos" Type="int" Range="[0,2048]" Default="1024" Desc="Initial approximate x-position [pixel] of central peak at 1.5microns"
; PIPELINE ARGUMENT: Name="centrYpos" Type="int" Range="[0,2048]" Default="1024" Desc="Initial approximate y-position [pixel] of central peak at 1.5microns"
; PIPELINE ARGUMENT: Name="w" Type="float" Range="[0.,10.]" Default="4.8" Desc="Spectral spacing perpendicular to the dispersion axis at the image center [pixel]"
; PIPELINE ARGUMENT: Name="P" Type="float" Range="[-7.,7.]" Default="-1.8" Desc="Micro-pupil pattern"
; PIPELINE ARGUMENT: Name="emissionlinesfile" Type="string"  Default="$GPI_DRP_DIR\config\lampemissionlines.txt" Desc="File of emission lines."
; PIPELINE ARGUMENT: Name="wav_of_centrXYpos" Type="int" Range="[1,2]" Default="2" Desc="1 if centrX-Ypos is the smallest-wavelength peak of the band; 2 if centrX-Ypos refer to 1.5microns"
; PIPELINE ARGUMENT: Name="maxpos" Type="float" Range="[-7.,7.]" Default="2." Desc="Allowed maximum location fluctuation (in pixel) between adjacent mlens"
; PIPELINE ARGUMENT: Name="maxtilt" Type="float" Range="[-360.,360.]" Default="10." Desc="Allowed maximum tilt fluctuation (in degree) between adjacent mlens"
; PIPELINE ARGUMENT: Name="medfilter" Type="int" Range="[0,1]" Default="1" Desc="1: Median filtering of dispersion coeff and tilts with a (5x5) median filtering"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-wavcal" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitvim_dispgrid" Type="int" Range="[0,500]" Default="15" Desc="1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display "
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying wavcal file, 0: no display "
; PIPELINE ARGUMENT: Name="tests" Type="int" Range="[0,3]" Default="0" Desc="1 for extensive tests "
; PIPELINE ARGUMENT: Name="testsDST" Type="int" Range="[0,3]" Default="0" Desc="1 for DST tests "
; PIPELINE COMMENT: Derive wavelength calibration from an arc lamp or flat-field image.
; PIPELINE TYPE: CAL-SPEC
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
;-

function gpi_extract_wavcal2,  DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

   im=*(dataset.currframe[0])

   ;;'Image rotated to match old DST convention of horizontal dispersion!' 
   ;; final wavelength solution at the end of this routine is derotated to match vertical dispersion
   im=rotate(im,1)
    ;if numext eq 0 then h= *(dataset.headers)[numfile] else h= *(dataset.headersPHU)[numfile]
  ; h=*(dataset.headers[numfile])
            ;error handle if image or header not well handled
            if ((size(im))[0] eq 0) then $
            return, error('FAILURE ('+functionName+'): Failed to load data.') 
   
  valid_header=1
  ; error handle missing FITS keywords
  keywords_to_check = ['OBSTYPE', 'GCALLAMP', 'FILTER1', 'INSTRUME']

  for i=0L,n_elements(keywords_to_check)-1 do begin
      val=backbone->get_keyword( keywords_to_check[i],count=c)
    if c eq 0 then begin
        err=error('FAILURE ('+functionName+'): FITS header keyword '+keywords_to_check[i]+" is missing!")
        valid_header=0
    endif
    if strlen(val) eq 0 then begin
      err=error('FAILURE ('+functionName+'): FITS header keyword '+keywords_to_check[i]+" is a null string, which is an invalid value!")
      valid_header=0
    endif
  endfor 

    obstype=backbone->get_keyword( 'OBSTYPE',count=c1)
       lamp=backbone->get_keyword( 'GCALLAMP',count=c2)
  if c2 eq 0 then return, error("No GCALLAMP keyword was present, therefore cannot determine what spectrum would be appropriate.")
    
    ;lamp=backbone->get_keyword( 'OBJECT',count=c2);backbone->get_keyword( 'GCALLAMP',count=c2) ;
    c3=1&lampshut='ON';lampshut=SXPAR( h, 'GCALSHUT',count=c3) ;will be implemented if necessary
    bandeobs=backbone->get_keyword( 'FILTER1',count=c4)
	if strpos(bandeobs, '_') gt 0 then bandeobs = (strsplit(bandeobs,'_',/extract))[1] ; turn IFSFILT_H_G1213 into just H
  ;if c4 eq 0 then bandeobs=SXPAR( h, 'FILTER1',count=c4)
    instrum=backbone->get_keyword( 'INSTRUME',count=cinstru)
    
;             ;error handle if keywords are missing
;            if (c1 eq 0) || (c2 eq 0) || (c3 eq 0)|| (c4 eq 0) || $
;            (strlen(obstype) eq 0) || (strlen(lamp) eq 0) || (strlen(lampshut) eq 0)|| (strlen(bandeobs) eq 0) then $
;            return, error('FAILURE ('+functionName+'): At least, one of the following keywords is missing: OBSTYPE,GCALLAMP,GCALSHUT,FILTER.') 
;   
;             ;error handle if obstype is not 'wavecal' or 'flat' 
;            if (~strmatch(obstype,'*wavecal*',/fold_case)) && (~strmatch(obstype,'*flat*',/fold_case))  then $
;            return, error('FAILURE ('+functionName+'): this data are not wavecal or flat image.') 

            ;to do : do something if gcalshut=off

   if strmatch(obstype,'*flat*',/fold) then begin
        im0=im
        im = (SHIFT_DIFF(im, DIRECTION=3)>0.) ;works with spatial derivative of the image (this direction works for lambda_min edge)
 ;stop
 ;       im = (SHIFT_DIFF(im>(2.*stddev(im0>0.)), DIRECTION=3)>0.) ;works with spatial derivative of the image (this direction works for lambda_min edge)
   endif     
   
	;if (size(im))[0] eq 0 then im=readfits(filename,h)
	szim=size(im)

;;create the cube which will contain in the slice 
;;0:x-positions (x0) of spectra (spectral direction) at a given lambda [lambda0] (can be lambda_min)
;;1:y-positions (y0) of spectra at a given lambda
;; The relation of dispersion for each spectrum is defined as lambda=w3*(sqrt((x-x0)^2+(y-y0)^2))+lambda0
;;2: lambda0
;;3: w3 (median value given by the n peaks of each spectrum, n>1)
;;4: tilts of spectra (median value given by the n peaks, n>1)
;nlens will be the spatial sidelength of the wavecal in pixels (usually =281 for DST images)
nlens=uint(Modules[thisModuleIndex].nlens)
specpos=dblarr(nlens,nlens,5)+!VALUES.F_NAN  ;specpos will handle the wavecal in this routine!

;localize central peak around the center of the image
cen1=dblarr(2)	& cen1[0]=-1 & cen1[1]=-1
wx=0 & wy=0 ;define sidelength (2wx+1 by 2wy+1 ) of box for maximum intensity detection
hh=1. ;define sidelength (2hh+1 by 2hh+1 ) of box for centroid intensity detection

;
if (tag_exist( Modules[thisModuleIndex], "emissionlinesfile")) && file_test(gpi_expand_path(Modules[thisModuleIndex].emissionlinesfile),/read) then $
emissionlinefile=  gpi_expand_path(Modules[thisModuleIndex].emissionlinesfile) else $
    emissionlinefile=  gpi_expand_path('$GPI_DRP_DIR'+path_sep()+'config'+path_sep()+'lampemissionlines.txt')
backbone->set_keyword, "HISTORY", "Lamp emission lines file used: "+emissionlinefile,ext_num=1

;res=read_ascii(emissionlinefile,data_start=2)
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

case strcompress(bandeobs,/REMOVE_ALL) of
  'Y':begin
;      if strmatch(lamp,'*Xe*',/fold) then begin
;        if (cinstru eq 1) && strmatch(instrum,'*DST*') then  peakwavelen=[[1.084]] else $ ;peakwavelen=[[1.084],[1.17455]]-0.03 else $ ;
;          peakwavelen=[[1.084],[1.17454]]
;      endif
;      if strmatch(lamp,'*Ar*',/fold) then begin
;        if (cinstru eq 1) && strmatch(instrum,'*DST*') then peakwavelen=[[1.07],[1.14]] else $;peakwavelen=[[1.0676]] else $
;          peakwavelen=[[1.0676],[1.1445]]
;        endif
;      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[0.95],[1.14]]
       if (cinstru eq 1) && strmatch(instrum,'*DST*') then begin
            specpixlength=15. ;spec pix length for rough estimation of peak positions
            bandwidth=0.2  ;bandwidth in microns
        endif else begin
          specpixlength=17. ;spec pix length for rough estimation of peak positions
          bandwidth=0.2;0.18; 0.23  ;bandwidth in microns
        endelse
    end
  'J':begin
;      if strmatch(lamp,'*Xe*',/fold) then peakwavelen=[[1.175],[1.263]] ;take into account secondary peak[[1.175],[1.263]]
;      if strmatch(lamp,'*Ar*',/fold) then peakwavelen=[[1.246],[1.296]]
      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[1.15],[1.33]] ;[[1.12],[1.35]]
      if (cinstru eq 1) && strmatch(instrum,'*DST*') then begin
        specpixlength= 15. ;spec pix length for rough estimation of peak positions
        bandwidth=0.18; 0.23  ;bandwidth in microns
        endif else begin
        specpixlength=17. ;spec pix length for rough estimation of peak positions
        bandwidth=0.23;0.18; 0.23  ;bandwidth in microns
        endelse
    end
  'H':begin
;      if strmatch(lamp,'*Xe*',/fold) then peakwavelen=[[1.542],[1.605],[1.6732],[1.733]]
;      if strmatch(lamp,'*Ar*',/fold) then peakwavelen=[[1.50506],[1.695],[1.79196]] ;[[1.695]] ;[[1.50506],[1.695],[1.79196]]
      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[1.5],[1.8]]
;      if strmatch(lamp,'*laser*',/fold) then peakwavelen=[[1.55]]
      specpixlength=20. ;17. ;spec pix length for rough estimation of peak positions
      bandwidth=0.3 ;bandwidth in microns
    end
  'K1':begin
;      if strmatch(lamp,'*Xe*',/fold) then peakwavelen=[[2.02678],[2.14759]]
;      if strmatch(lamp,'*Ar*',/fold) then peakwavelen=[[1.997],[2.06],[2.099],[2.154]]
      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[1.9],[2.19]]
      specpixlength=20. ;spec pix length for rough estimation of peak positions
      bandwidth=0.3 ;bandwidth in microns
    end
  'K2':begin
;      if strmatch(lamp,'*Xe*',/fold) then peakwavelen=[[2.14759],[2.31996]]
;      if strmatch(lamp,'*Ar*',/fold) then peakwavelen=[[2.154],[2.2],[2.314],[2.397]]
      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[2.13],[2.4]]
      specpixlength=20. ;spec pix length for rough estimation of peak positions
      bandwidth=0.27  ;bandwidth in microns
    end
endcase
    ;;2010-07-14 J.Maire: added for testing, 
    ;; use it only for wavelength solution testing based on DST sim
    ;;correct for finite DST spectral resolution !!
    
   ; if (tag_exist( Modules[thisModuleIndex], "testsDST")) && ( fix(Modules[thisModuleIndex].testsDST) eq 1 ) then begin
   if strmatch(instrum,'*DST*') && ~strmatch(bandeobs,'*Y*') then begin
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
          DST_CODE_DIR= getenv('GPI_IFS_DIR')+path_sep()+'dst';getenv()

          readcol, DST_CODE_DIR+path_sep()+strmid(lamp,0,2)+'ArcLampG.txt', wavelen, strength
          wavelen=1.e-4*wavelen
          ;if (strcompress(bandeobs,/REMOVE_ALL) eq 'Y') && strmatch(lamp,'*Xenon*',/fold) then wavelen-=0.03
          lambdadst=readfits(DST_CODE_DIR+path_sep()+'zemdispLam'+strcompress(bandeobs, /rem)+'.fits')
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
		readcol, gpi_expand_path('$GPI_DRP_DIR'+path_sep()+'config'+path_sep()+'wavcal_start_positions.txt'), $
			def_pos_band, def_pos_x, def_pos_y, def_type, def_orient, format='A,F,F,A,A'
		; are we looking at data from real IFS or DST here?
		dstver = backbone->get_keyword('DST_VER',count=dstct)
		if dstct eq 0 then data_type='REAL' else data_type = 'DST'

		wm = where(def_pos_band eq bandeobs and strlowcase(def_type) eq strlowcase(data_type) and strlowcase(def_orient) eq strlowcase(backbone->get_keyword('DSORIENT')), mct)
		if mct eq 0 then begin
			message,/info, 'Could not find default settings for starting position! Results undefined.'
		endif else begin
			if cenx eq 0 then cenx = float(def_pos_x[wm])
			if ceny eq 0 then ceny = float(def_pos_y[wm])
		endelse
		message,/info, 'Loaded default starting position(s) from config table: '+printcoo(cenx, ceny)
	endif else begin
		;;take into account the rotation we made on image: note that axes have been switched with regard to old definition
		cenx=float(szim[1])-1.-float(Modules[thisModuleIndex].centrYpos)
		ceny=float(Modules[thisModuleIndex].centrXpos)
	endelse



if fix(Modules[thisModuleIndex].wav_of_centrXYpos) eq 2. then begin
    ;;from cenx at 1.5microns, estimate x-location of first peak to detect
    cenx+=(peakwavelen[0]-1.5)*(18./0.3)
    ;make a slight correction for far Y-band spectra:
    if (strcompress(bandeobs,/REMOVE_ALL) eq 'Y') && (cinstru eq 1) && strmatch(instrum,'*DST*') then cenx+=0. else $
    if (strcompress(bandeobs,/REMOVE_ALL) eq 'Y') then cenx -=8.
    print, 'estimate x-location of first peak at',peakwavelen[0], 'microns =',cenx
endif

while (~finite(cen1[0])) || (~finite(cen1[1])) || $
		(cen1[0] lt 0) || (cen1[0] gt (size(im))[1]) || $
		(cen1[1] lt 0) || (cen1[1] gt (size(im))[1])  do begin
	wx+=1 & wy+=1
	cen1=localizepeak( im, cenx, ceny,wx,wy,hh)
	print, 'peak detected at pos:', cen1[1],float(szim[1])-1.-cen1[0]
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
wx=0. & wy=0. ; JM change  wx=1. & wy=0. good for flat
hh=1. ; box for fit
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



;calculate now x-y locations of the first peak of all spectra (specpos[*,*,0] and specpos[*,*,1]): 
;for quadrant=1L,4 do find_spectra_positions_quadrant, quadrant,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,specpos,im,edge_x1,edge_x2,edge_y1,edge_y2,tight_pos
for quadrant=1L,4 do find_spectra_positions_quadrant, quadrant,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,specpos,im,edge_x1,edge_x2,edge_y1,edge_y2,tight_pos,badpixmap=badpixmap

if strcmp(obstype,'flat',4,/fold) then specpos[*,*,0]-=0.5 ;take account of spatial shift in derivative


;;;;;;;;;;;;;;;;;;;;;;;;
;;dispersion law & tilts
;;;;;;;;;;;;;;;;;;;;;;;;

  if (tag_exist( Modules[thisModuleIndex], "tests")) && ( Modules[thisModuleIndex].tests eq 1 ) then begin
    dispeak=dblarr(nlens,nlens,2*n_elements(peakwavelen))+!VALUES.F_NAN 
    dispeak[*,*,0]=specpos[*,*,0]
    dispeak[*,*,1]=specpos[*,*,1]
    dispeak2=dblarr(nlens,nlens,n_elements(peakwavelen))+!VALUES.F_NAN
      for xi=0,nlens-1 do begin
        for yi=0,nlens-1 do begin
            ;dispeak2[xi,yi,0]=splinefwhm(im[dispeak[xi,yi,0]-2:dispeak[xi,yi,0]+2,dispeak[xi,yi,1]-2:dispeak[xi,yi,1]+2])
            ;dispeak2[xi,yi,0]=radplotfwhm(im,dispeak[xi,yi,0],dispeak[xi,yi,1])
            dispeak2[xi,yi,0]=gaussfwhm(im[dispeak[xi,yi,0]-5:dispeak[xi,yi,0]+5,dispeak[xi,yi,1]-5:dispeak[xi,yi,1]+5])
        endfor
      endfor
   endif else begin 
    dispeak=0
  endelse

;if strmatch(obstype,'*flat*',/fold) then im = (SHIFT_DIFF(im0, DIRECTION=4)>0.) ;works with spatial derivative of the image (lambda_max edge)
if strmatch(obstype,'*flat*',/fold) then im = (SHIFT_DIFF(im0>(2.*stddev(im0>0.)), DIRECTION=4)>0.) ;works with spatial derivative of the image (lambda_max edge)

   specpos[*,*,2]=peakwavelen[0]
if n_elements(peakwavelen) gt 1 then begin
  apprXpos=(peakwavelen-peakwavelen[0])*specpixlength/bandwidth ;  *nbpix for the band / bandwidth
  apprYpos=fltarr(n_elements(apprXpos))
  tilt=fltarr(nlens,nlens,n_elements(apprXpos)-1)+!VALUES.F_NAN

  w3med=fltarr(nlens,nlens)
  w3=fltarr(n_elements(apprXpos)-1)
;wx=0. & wy=1.
wx=1. & wy=0. ;flat
;wx=0. & wy=0. & hh=1. ;flat

;calculate now x-y locations of the other peaks and deduce linear dispersion coeffs and tilts
 for quadrant=1L,4 do find_spectra_dispersions_quadrant, quadrant,peakwavelen,apprXpos,apprYpos,nlens,w3,w3med,tilt,specpos,im,wx,wy,hh,szim,edge_x1,edge_x2,edge_y1,edge_y2, dispeak, dispeak2, tight_tilt
 
 
endif ; verif si n_elements(peakwavelen) gt 1

; median filtering for bad detection on the edge where part of spectrum are absent...
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
 
if tag_exist( Modules[thisModuleIndex], "medfilter") then if ( fix(Modules[thisModuleIndex].medfilter) eq 1 ) then begin
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

;suffix=strcompress(bandeobs,/REMOVE_ALL)+'-wavcal'
if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=strcompress(bandeobs,/REMOVE_ALL)+Modules[thisModuleIndex].suffix
fname=strmid(filename,0,STRLEN(filename)-6)+suffix+'.fits'


;if (nlens mod 2) eq 1 then specpos=specpos[0:nlens-2,0:nlens-2,*]
backbone->set_keyword, "FILETYPE", "Wavelength Solution Cal File"
backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'

;backbone->set_keyword, "NAXIS", 3;,/blank
;backbone->set_keyword, "NAXIS3", 5;,/blank ;;for some reason this does not work??! error about NAXIS2 is missing which is false
sxaddpar,*dataset.headersExt[numfile],'NAXIS',3
sxaddpar,*dataset.headersExt[numfile],'NAXIS3',5,after='NAXIS2'

backbone->set_keyword, "HISTORY", " ",ext_num=1;,/blank
backbone->set_keyword, "HISTORY", " Wavelength solution File Format:",ext_num=1
backbone->set_keyword, "HISTORY", " Dispersion for each spectrum is defined as ",ext_num=1
backbone->set_keyword, "HISTORY", " lambda=w3*(sqrt((x-x0)^2+(y-y0)^2))+lambda0",ext_num=1
backbone->set_keyword, "HISTORY", "    Slice 1:  x-positions (x0) of spectra (x:spectral direction) at [lambda0]",ext_num=1
backbone->set_keyword, "HISTORY", "    Slice 2:  y-positions (y0) of spectra at [lambda0]",ext_num=1
backbone->set_keyword, "HISTORY", "    Slice 3:  lambda0 [um]",ext_num=1
backbone->set_keyword, "HISTORY", "    Slice 4:   w3 [um/pixel]",ext_num=1
backbone->set_keyword, "HISTORY", "    Slice 5:   tilts of spectra [rad]",ext_num=1
backbone->set_keyword, "HISTORY", " ",ext_num=1;,/blank


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
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display,savedata=specpos,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile] ,output_filename=output_filename)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
      if tag_exist( Modules[thisModuleIndex], "gpitvim_dispgrid") && ( fix(Modules[thisModuleIndex].gpitvim_dispgrid) ne 0 ) then $
           if strcmp(obstype,'flat',4,/fold) then im=im0
          
      backbone_comm->gpitv, double(im), session=fix(Modules[thisModuleIndex].gpitvim_dispgrid), header=*(dataset.headersPHU)[numfile], dispwavcalgrid=output_filename, imname='Wavecal grid for '+  *((dataset.frames)[numfile]);Modules[thisModuleIndex].name
           ;gpitvms, double(im), ses=fix(Modules[thisModuleIndex].gpitvim_dispgrid),head=h,opt='dispwavcalgrid='+output_filename
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          backbone_comm->gpitv, double(*DataSet.currFrame), session=fix(Modules[thisModuleIndex].gpitv), header=*(dataset.headersPHU)[numfile], imname='Pipeline result from '+ Modules[thisModuleIndex].name
          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=h
    endelse


return, ok

end
