;+
; NAME: gpi_extract_wavcal_locations
; PIPELINE PRIMITIVE DESCRIPTION: Measure locations of Emission Lines
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
; GEM/GPI KEYWORDS:FILTER,IFSFILT,GCALLAMP,GCALSHUT,OBSTYPE
; DRP KEYWORDS: FILETYPE,HISTORY,ISCALIB
; OUTPUTS:
;
; PIPELINE ORDER: 1.7

; PIPELINE ARGUMENT: Name="nlens" Type="int" Range="[0,400]" Default="281" Desc="side length of  the  lenslet array "
; PIPELINE ARGUMENT: Name="centrXpos" Type="int" Range="[0,2048]" Default="1024" Desc="Initial approximate x-position [pixel] of central peak at 1.5microns"
; PIPELINE ARGUMENT: Name="centrYpos" Type="int" Range="[0,2048]" Default="1024" Desc="Initial approximate y-position [pixel] of central peak at 1.5microns"
; PIPELINE ARGUMENT: Name="w" Type="float" Range="[0.,10.]" Default="4.8" Desc="Spectral spacing perpendicular to the dispersion axis at the detcetor in pixel"
; PIPELINE ARGUMENT: Name="P" Type="float" Range="[-7.,7.]" Default="-1.8" Desc="Micro-pupil pattern"
; PIPELINE ARGUMENT: Name="wav_of_centrXYpos" Type="int" Range="[1,2]" Default="2" Desc="1 if centrX-Ypos is the smallest-wavelength peak of the band; 2 if centrX-Ypos refer to 1.5microns"
; PIPELINE ARGUMENT: Name="maxpos" Type="float" Range="[-7.,7.]" Default="2." Desc="Allowed maximum location fluctuation (in pixel) between adjacent mlens"
; PIPELINE ARGUMENT: Name="maxtilt" Type="float" Range="[-360.,360.]" Default="10." Desc="Allowed maximum tilt fluctuation (in degree) between adjacent mlens"
; PIPELINE ARGUMENT: Name="medfilter" Type="int" Range="[0,1]" Default="1" Desc="1: Median filtering of dispersion coeff and tilts with a (5x5) median filtering"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-wavcal" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitvim_dispgrid" Type="int" Range="[0,500]" Default="15" Desc="1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display "
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying wavcal file, 0: no display "
; PIPELINE ARGUMENT: Name="tests" Type="int" Range="[0,3]" Default="0" Desc="1 for extensive tests "
; PIPELINE COMMENT: Derive wavelength calibration from an arc lamp or flat-field image.
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 
; HISTORY:      
; 	 Jerome Maire 2008-10
;	  JM: nlens, w (initial guess), P (initial guess), cenx (or centrXpos), ceny (or centrYpos) as parameters
;   2009-09-17 JM: added DRF parameters
;   2009-12-10 JM: initiate position at 1.5microns so we can take into account several 
;   2010-07-14 J.Maire:for DRP testing, correct for DST finite spectral resolution 
;-

function gpi_extract_wavcal_locations,  DataSet, Modules, Backbone
primitive_version= '$Id: gpi_extract_wavcal_locations.pro 11 2010-07-06 01:22:03Z maire $' ; get version from subversion to store in header history
@__start_primitive

   
   im=*(dataset.currframe[0]) 
   
    if numext eq 0 then h= *(dataset.headers)[numfile] else h= *(dataset.headersPHU)[numfile]
  ; h=*(dataset.headers[numfile])
            ;error handle if image or header not well handled
            if ((size(im))[0] eq 0) || (n_elements(h) eq 0)  then $
            return, error('FAILURE ('+functionName+'): Failed to load data.') 
   
   obstype=SXPAR( h, 'OBSTYPE',count=c1)
   if c1 eq 0 then return, error('FAILURE ('+functionName+'): FITS header is missing keyword OBSTYPE')
   lamp=SXPAR( h, 'GCALLAMP',count=c2)
   if c2 eq 0 then return, error('FAILURE ('+functionName+'): FITS header is missing keyword GCALLAMP')
   c3=1&lampshut='ON';lampshut=SXPAR( h, 'GCALSHUT',count=c3) ;will be implemented if necessary
   bandeobs=SXPAR( h, 'FILTER',count=c4)
   if c4 eq 0 then bandeobs=SXPAR( h, 'IFSFILT',count=c4)
   
             ;error handle if keywords are missing
            if (c1 eq 0) || (c2 eq 0) || (c3 eq 0)|| (c4 eq 0) || $
            (strlen(obstype) eq 0) || (strlen(lamp) eq 0) || (strlen(lampshut) eq 0)|| (strlen(bandeobs) eq 0) then $
            return, error('FAILURE ('+functionName+'): At least, one of the following keywords is missing: OBSTYPE,GCALLAMP,GCALSHUT,FILTER.') 
   
             ;error handle if obstype is not 'wavecal' or 'flat' 
            if (~strmatch(obstype,'*wavecal*',/fold_case)) && (~strmatch(obstype,'*flat*',/fold_case))  then $
            return, error('FAILURE ('+functionName+'): this data are not wavecal or flat image.') 

            ;to do : do something if gcalshut=off

   if strmatch(obstype,'*flat*',/fold) then begin
        im0=im
    ;    im = (SHIFT_DIFF(im, DIRECTION=3)>0.) ;works with spatial derivative of the image (this direction works for lambda_min edge)

        im = (SHIFT_DIFF(im>(2.*stddev(im0>0.)), DIRECTION=3)>0.) ;works with spatial derivative of the image (this direction works for lambda_min edge)
   endif     
   
	;if (size(im))[0] eq 0 then im=readfits(filename,h)
	szim=size(im)

;;get the backbone for input parameters
thisModuleIndex = Backbone->GetCurrentModuleIndex()

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


case strcompress(bandeobs,/REMOVE_ALL) of
  'Y':begin
      if strmatch(lamp,'*Xenon*',/fold) then peakwavelen=[[1.084]]
      if strmatch(lamp,'*Argon*',/fold) then peakwavelen=[[1.0676]]
      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[0.95],[1.14]]
      specpixlength=15.;20.;;17.;14. ;spec pix length for rough estimation of peak positions
      bandwidth=0.19;0.2;0.19  ;bandwidth in microns
    end
  'J':begin
      if strmatch(lamp,'*Xenon*',/fold) then peakwavelen=[[1.175],[1.263]]
      if strmatch(lamp,'*Argon*',/fold) then peakwavelen=[[1.246],[1.296]]
      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[1.15],[1.33]] ;[[1.12],[1.35]]
      specpixlength=17.; 15. ;spec pix length for rough estimation of peak positions
      bandwidth=0.3; 0.18; 0.23  ;bandwidth in microns !to check
    end
  'H':begin
      if strmatch(lamp,'*Xenon*',/fold) then peakwavelen=[[1.542],[1.605],[1.6732],[1.733]]
      if strmatch(lamp,'*Argon*',/fold) then peakwavelen=[[1.50506],[1.695],[1.79196]] ;[[1.695]] ;[[1.50506],[1.695],[1.79196]]
      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[1.5],[1.8]]
      if strmatch(lamp,'*laser*',/fold) then peakwavelen=[[1.55]]
      specpixlength=20. ;17. ;spec pix length for rough estimation of peak positions
      bandwidth=0.3 ;bandwidth in microns
    end
  'K1':begin
      if strmatch(lamp,'*Xenon*',/fold) then peakwavelen=[[2.02678],[2.14759]]
      if strmatch(lamp,'*Argon*',/fold) then peakwavelen=[[1.997],[2.06],[2.099],[2.154]]
      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[1.9],[2.19]]
      specpixlength=19. ;spec pix length for rough estimation of peak positions
      bandwidth=0.3 ;bandwidth in microns
    end
  'K2':begin
      if strmatch(lamp,'*Xenon*',/fold) then peakwavelen=[[2.14759],[2.31996]]
      if strmatch(lamp,'*Argon*',/fold) then peakwavelen=[[2.154],[2.2],[2.314],[2.397]]
      if strmatch(obstype,'*flat*',/fold) then peakwavelen=[[2.13],[2.4]]
      specpixlength=20. ;spec pix length for rough estimation of peak positions
      bandwidth=0.27  ;bandwidth in microns
    end
endcase
    ;;2010-07-14 J.Maire: added for testing, 
    ;; use it only for wavelength solution testing based on DST sim
    ;;correct for finite DST spectral resolution !!
    testdeb=1
    if testdeb then begin
              case strcompress(bandeobs,/REMOVE_ALL) of
            'Y':begin
                if strmatch(lamp,'*Xenon*',/fold) then relativethresh=0.5
                if strmatch(lamp,'*Argon*',/fold) then relativethresh=0.5
              end
            'J':begin
                if strmatch(lamp,'*Xenon*',/fold) then relativethresh=0.806
                if strmatch(lamp,'*Argon*',/fold) then relativethresh=0.5
              end
            'H':begin
                if strmatch(lamp,'*Xenon*',/fold) then relativethresh=0.2
                if strmatch(lamp,'*Argon*',/fold) then relativethresh=0.5
              end
            'K1':begin
                if strmatch(lamp,'*Xenon*',/fold) then relativethresh=0.2
                if strmatch(lamp,'*Argon*',/fold) then relativethresh=0.1;0.1;0.2;0.5
              end
            'K2':begin
                if strmatch(lamp,'*Xenon*',/fold) then relativethresh=0.2
                if strmatch(lamp,'*Argon*',/fold) then relativethresh=0.8;0.43 ;0.28
              end
          endcase
        if   ~(strmatch(obstype,'*flat*',/fold)) then begin
          DSTdir= gpi_get_directory('GPI_DST_DIR')
          readcol, DSTdir+path_sep()+strmid(lamp,0,2)+'ArcLampG.txt', wavelen, strength
          wavelen=1.e-4*wavelen
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
           if (strmatch(strcompress(bandeobs,/REMOVE_ALL),'J')) && ~(strmatch(obstype,'*flat*',/fold)) then peakwavelen2=peakwavelen2[where(peakwavelen2 lt 1.28)]
           if (strmatch(strcompress(bandeobs,/REMOVE_ALL),'Y')) && ~(strmatch(obstype,'*flat*',/fold)) then peakwavelen2=peakwavelen2[where(peakwavelen2 lt 1.13)]
           print, 'Reference peak adopted:',peakwavelen2
           peakwavelen=peakwavelen2
         endif  
            wavstr=''
           for st=0,n_elements(peakwavelen)-1 do wavstr+=strcompress(string(peakwavelen[st]),/rem)+'/'
           sxaddpar, h, "TESTWAV", wavstr, 'wav of detected peaks'
           ;stop
          
    endif

;;localize first peak ;; this coordiantes depends strongly on data!!
cenx=float(Modules[thisModuleIndex].centrXpos)
ceny=float(Modules[thisModuleIndex].centrYpos)

if strmatch(strcompress(bandeobs,/REMOVE_ALL),'Y') then specpixlength2=specpixlength+4. else specpixlength2=specpixlength
if (Modules[thisModuleIndex].wav_of_centrXYpos) eq 2. then begin
    ;;from cenx at 1.5microns, estimate x-location of first peak to detect
   ; cenx+=(peakwavelen[0]-1.5)*(18./0.3)
    cenx+=(peakwavelen[0]-1.5)*(specpixlength2/0.3)    
    print, 'estimate x-location of first peak at',peakwavelen[0], 'microns =',cenx
endif

while (~finite(cen1[0])) || (~finite(cen1[1])) || $
		(cen1[0] lt 0) || (cen1[0] gt (size(im))[1]) || $
		(cen1[1] lt 0) || (cen1[1] gt (size(im))[1])  do begin
	wx+=1 & wy+=1
	cen1=localizepeak( im, cenx, ceny,wx,wy,hh)
	print, 'peak detected at pos:',cen1
endwhile
specpos[nlens/2,nlens/2,0:1]=cen1
;stop
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
if strmatch(obstype,'*flat*',/fold) then begin
  wx=1. & wy=0.
endif
hh=1. ; box for fit
;wcst=4.8 & Pcst=-1.8
wcst=float(Modules[thisModuleIndex].w) & Pcst=float(Modules[thisModuleIndex].P)
edge_x1=4.
edge_x2=4.
edge_y1=4.
edge_y2=4.


 tight_pos=float(Modules[thisModuleIndex].maxpos)  
 tight_tilt=float(Modules[thisModuleIndex].maxtilt)  

;calculate now x-y locations of the first peak of all spectra (specpos[*,*,0] and specpos[*,*,1]): 
for quadrant=1L,4 do find_spectra_positions_quadrant, quadrant,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,specpos,im,edge_x1,edge_x2,edge_y1,edge_y2,tight_pos,badpixmap=badpixmap

if strcmp(obstype,'flat',4,/fold) then specpos[*,*,0]+=0.5 ;take account of spatial shift in derivative


;;;;;;;;;;;;;;;;;;;;;;;;
;;dispersion law & tilts
;;;;;;;;;;;;;;;;;;;;;;;;

;  if (tag_exist( Modules[thisModuleIndex], "tests")) && ( Modules[thisModuleIndex].tests eq 1 ) then begin
    dispeak=dblarr(nlens,nlens,2*n_elements(peakwavelen))+!VALUES.F_NAN 
    dispeak[*,*,0]=specpos[*,*,0]
    dispeak[*,*,1]=specpos[*,*,1]
   ; dispeak2=dblarr(nlens,nlens,n_elements(peakwavelen))+!VALUES.F_NAN
;      for xi=0,nlens-1 do begin
;        for yi=0,nlens-1 do begin
;            ;dispeak2[xi,yi,0]=splinefwhm(im[dispeak[xi,yi,0]-2:dispeak[xi,yi,0]+2,dispeak[xi,yi,1]-2:dispeak[xi,yi,1]+2])
;            ;dispeak2[xi,yi,0]=radplotfwhm(im,dispeak[xi,yi,0],dispeak[xi,yi,1])
;            ;dispeak2[xi,yi,0]=gaussfwhm(im[dispeak[xi,yi,0]-5:dispeak[xi,yi,0]+5,dispeak[xi,yi,1]-5:dispeak[xi,yi,1]+5])
;        endfor
;      endfor
;   endif else begin 
;    dispeak=0
;  endelse

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
wx=1. & wy=0. 
if strmatch(obstype,'*flat*',/fold) then begin
  wx=2. & wy=0.
endif
;calculate now x-y locations of the other peaks and deduce linear dispersion coeffs and tilts
 for quadrant=1L,4 do find_spectra_dispersions_quadrant, quadrant,peakwavelen,apprXpos,apprYpos,nlens,w3,w3med,tilt,specpos,im,wx,wy,hh,szim,edge_x1,edge_x2,edge_y1,edge_y2, dispeak, dispeak2, tight_tilt
 
;  if strcmp(obstype,'flat',4,/fold) then dispeak[*,*,(size(dispeak))[3]-2]-=1.3 ;take account of spatial shift in derivative
;   if strcmp(obstype,'flat',4,/fold) then dispeak[*,*,0]-=1.0
;   if strcmp(obstype,'flat',4,/fold) then dispeak[*,*,(size(dispeak))[3]-1]-=0.8
; stop
endif ; verif si n_elements(peakwavelen) gt 1

; median filtering for bad detection on the edge where part of spectrum are absent...
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
 
if tag_exist( Modules[thisModuleIndex], "medfilter") then if ( Modules[thisModuleIndex].medfilter eq 1 ) then begin
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
sxaddpar, h, "FILETYPE", "Wavelength Solution Cal File", /savecomment
sxaddpar, h, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'

for pind=0,n_elements(peakwavelen)-1 do sxaddpar, h, "PEAKWAV"+strcompress(string(pind),/re), peakwavelen[pind], 'Wav of peak used for wav.solution measurement'


sxaddhist, " ",/blank, h
sxaddhist, " Wavelength solution File Format:",  h
sxaddhist, " Dispersion for each spectrum is defined as ",h
sxaddhist, " lambda=w3*(sqrt((x-x0)^2+(y-y0)^2))+lambda0",h
sxaddhist, "    Slice 1:  x-positions (x0) of spectra (x:spectral direction) at [lambda0]",  h
sxaddhist, "    Slice 2:  y-positions (y0) of spectra at [lambda0]",  h
sxaddhist, "    Slice 3:  lambda0 [um]",  h
sxaddhist, "    Slice 4:   w3 [um/pixel]",  h
sxaddhist, "    Slice 5:   tilts of spectra [rad]",  h
sxaddhist, " ",/blank, h


;rotate (180deg) the wavcal to have quadrant "aligned" (modulo 26deg) with the image  
for qq=0,(size(specpos))[3]-1 do specpos[*,*,qq]=rotate(specpos[*,*,qq],2)

for qq=0,(size(dispeak))[3]-1 do dispeak[*,*,qq]=rotate(dispeak[*,*,qq],2)
*(dataset.currframe[0])=dispeak ;specpos
;*(dataset.headers[numfile])=h

if numext eq 0 then *(dataset.headers)[numfile]=h else *(dataset.headersPHU)[numfile]=h
;stop
;if ( Modules[thisModuleIndex].Save eq 1 ) then begin
;       b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix,  savedata=specpos,saveheader=h)
;       if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;end

;if tag_exist( Modules[thisModuleIndex], "tests") then if ( Modules[thisModuleIndex].tests eq 1 ) then $
;writefits, strmid(output_filename, 0,strlen(output_filename)-5)+'testdis'+'.fits',dispeak,h
;if tag_exist( Modules[thisModuleIndex], "tests") then if ( Modules[thisModuleIndex].tests eq 1 ) then $
;writefits, strmid(output_filename, 0,strlen(output_filename)-5)+'testdis2'+'.fits',dispeak2,h


    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display,savedata=dispeak,saveheader=h,output_filename=output_filename)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
      if tag_exist( Modules[thisModuleIndex], "gpitvim_dispgrid") && ( fix(Modules[thisModuleIndex].gpitvim_dispgrid) ne 0 ) then $
           if strcmp(obstype,'flat',4,/fold) then im=im0
           if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
           backbone_comm->gpitv, double(im), session=fix(Modules[thisModuleIndex].gpitvim_dispgrid), header=h, dispwavcalgrid=output_filename
          ;gpitvms, double(im), ses=fix(Modules[thisModuleIndex].gpitvim_dispgrid),head=h,opt='dispwavcalgrid='+output_filename
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
		  backbone_comm->gpitv, double(*DataSet.currFrame), session=fix(Modules[thisModuleIndex].gpitv), header=h
          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=h
    endelse


return, ok

end
