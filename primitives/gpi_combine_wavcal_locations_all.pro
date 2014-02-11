;+
; NAME: gpi_combine_wavcal_locations_all
; PIPELINE PRIMITIVE DESCRIPTION: Combine Wavelength Calibrations locations
;
; gpi_combine_wavcal_all is a simple median combination of wav. cal. files obtained with flat and arc images.
;  TO DO: exclude some mlens from the median in case of  wavcal 
;
; INPUTS: 3D wavcal 
;
; OUTPUTS: 
; GEM/GPI KEYWORDS:FILTER,IFSFILT
; DRP KEYWORDS: DATAFILE, DATE-OBS,TIME-OBS
;
; PIPELINE COMMENT: Combine wavelength calibration from  flat and arc
; PIPELINE ARGUMENT: Name="polydegree" Type="int" Range="[1,2]" Default="1" Desc="1: linear wavelength solution, 2: quadratic wav. sol."
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.2
; PIPELINE NEWTYPE: Calibration
;
; HISTORY:
;    Jerome Maire 2009-08-10
;   2009-09-17 JM: added DRF parameters
;   2012-10-17 MP: Removed deprecated suffix= keyword
;   2013-08-07 ds: idl2 compiler compatible 
;-

function gpi_combine_wavcal_locations_all,  DataSet, Modules, Backbone
  primitive_version= '$Id$' ; get version from subversion to store in header history
  @__start_primitive
  nfiles=dataset.validframecount

  if nfiles gt 1 then begin

     if tag_exist( Modules[thisModuleIndex], "Exclude") then Exclude= Modules[thisModuleIndex].exclude ;else exclude=

     sz=size(accumulate_getimage( dataset, 0))
     wavcalcomb=dblarr(sz[1],sz[2],sz[3])
     filter=gpi_simplify_keyword_value(strc(backbone->get_keyword('IFSFILT')))
     cwv=get_cwv(filter)
     CommonWavVect=cwv.CommonWavVect
     lambda=cwv.lambda
     
     lambdamin=commonwavvect[0]
     
     if tag_exist( Modules[thisModuleIndex], "polydegree") then polydegree=fix(Modules[thisModuleIndex].polydegree)
     
     ;;get #peaks used
     peakwav_vect=[0]
     peakwav_file=[0]
     for nf=0,nfiles-1 do begin
        im=accumulate_getimage( dataset, nf,head)
        c1=1
        pind=0
        while c1 eq 1 do begin
           peakwav=SXPAR( head, 'PEAKWAV'+strcompress(string(pind),/re),count=c1)
           if c1 ne 0 then peakwav_vect=[peakwav_vect,peakwav]
           if c1 ne 0 then peakwav_file=[peakwav_file,nf]
           pind+=1
        end
     endfor
     peakwav_vect=peakwav_vect[1:n_elements(peakwav_vect)-1]
     peakwav_file=peakwav_file[1:n_elements(peakwav_file)-1]
     
     induniq=UNIQ(peakwav_vect, SORT(peakwav_vect)) 
     refwav=peakwav_vect[induniq]
     nbwav=n_elements(refwav)
     
     ;;for each reference wav, calculate the mean x-y locations of the lamp peak
     wavcaltabgenx=dblarr(sz[1],sz[2],nbwav)
     wavcaltabgeny=dblarr(sz[1],sz[2],nbwav)
     for rw=0, nbwav-1 do begin
        indwav=where(peakwav_vect eq refwav[rw])
        indfile=peakwav_file[indwav]

        wavcaltabx=dblarr(sz[1],sz[2],n_elements(indfile))
        wavcaltaby=dblarr(sz[1],sz[2],n_elements(indfile))
        for nn=0,n_elements(indfile)-1 do begin
           wavcaltmp =(accumulate_getimage( dataset, indfile[nn]))[*,*,*]
           wv=where(peakwav_vect[where(peakwav_file eq indfile[nn])] eq refwav[rw])
           wavcaltabx[*,*,nn]=wavcaltmp[*,*,2*wv]
           wavcaltaby[*,*,nn]=wavcaltmp[*,*,2*wv+1]
        endfor
        
        if n_elements(indfile) gt 1 then begin
           print, 'median combin. of',n_elements(indfile),' files at ',refwav[rw],'um'
           wavcaltabgenx[*,*,rw]=median(wavcaltabx,/double,dimension=3,/even)
           wavcaltabgeny[*,*,rw]=median(wavcaltaby,/double,dimension=3,/even)
        endif else begin
           wavcaltabgenx[*,*,rw]=wavcaltabx
           wavcaltabgeny[*,*,rw]=wavcaltaby
        endelse     
     endfor
     
     ;; for a linear wavelength solution
     if polydegree eq 1 then begin        
        tilt2=dblarr(sz[1],sz[2])
        w3=dblarr(sz[1],sz[2])
        lam=dblarr(sz[1],sz[2])
                                ;w3d=dblarr(nlens,nlens)
        for i=0,sz[1]-1 do begin
           for j=0,sz[2]-1 do begin
                                ;if (j eq 137) && (i eq 137) then stop 
              tiltp=dblarr(nbwav-1)
              w3p=dblarr((nbwav-1))
                                ; if (abs(zemdispY[i,j,zemwavind]-1024.+1024.) lt 3.) && (abs(zemdispX[i,j,zemwavind]-1073.+1024.) lt 3.) then stop
              for p=1,(nbwav)-1 do begin
                 tiltp[p-1]=atan((wavcaltabgeny[i,j,p]-wavcaltabgeny[i,j,0])/(wavcaltabgenx[i,j,p]-wavcaltabgenx[i,j,0]))
                 w3p[p-1]=abs(refwav[p]-refwav[0])/(sqrt(((wavcaltabgeny[i,j,p]-wavcaltabgeny[i,j,0]))^2+(wavcaltabgenx[i,j,p]-wavcaltabgenx[i,j,0])^2))
                 tilt2[i,j]=median(tiltp,/even)
                 w3[i,j]=median(w3p,/even)
                                ;  w3d[i,j]=stddev(w3p)
              endfor
                                ;let's do again it with linfit for comparison
              distance=fltarr(nbwav)
              for rw=0, nbwav-1 do distance[rw]=sqrt( (wavcaltabgenx[i,j,rw]-wavcaltabgenx[i,j,0])^2.+(wavcaltabgeny[i,j,rw]-wavcaltabgeny[i,j,0])^2. )
              ;;calculate  (linear) dispersion relation
              if nbwav ge 2 then linfitcoef=linfit(distance,refwav)
              w3[i,j]=linfitcoef[1]
              lam[i,j]=linfitcoef[0]
           endfor
        endfor
        wavcalcomb=fltarr(sz[1],sz[2],5) ;Lin case
        wavcalcomb[*,*,0]=wavcaltabgenx[*,*,0]
        wavcalcomb[*,*,1]=wavcaltabgeny[*,*,0]
        wavcalcomb[*,*,2]=lam   ;refwav[0]
        wavcalcomb[*,*,3]=w3[*,*]
        wavcalcomb[*,*,4]=tilt2[*,*]

     endif

     ;; for a quadratic wavelength solution
     if polydegree eq 2 then     begin
        
        distance=fltarr(sz[1],sz[2],nbwav)
        for rw=0, nbwav-1 do distance[*,*,rw]=sqrt( (wavcaltabgenx[*,*,rw]-wavcaltabgenx[*,*,0])^2.+(wavcaltabgeny[*,*,rw]-wavcaltabgeny[*,*,0])^2. )
        ;;calculate  (non-linear) dispersion relation
        polyfit=fltarr(sz[1],sz[2],3)
        for szx=0,sz[1]-1 do begin
           for szy=0,sz[2]-1 do begin
              if nbwav gt 2 then polyfit[szx,szy,*]=reform(poly_fit(refwav,reform(distance[szx,szy,*]),2),1,1,3)
              if nbwav eq 2 then polyfit[szx,szy,0:1]=reform(poly_fit(refwav,reform(distance[szx,szy,*]),1),1,1,2)
           endfor
        endfor
        
        window,1
        xlens=137 & ylens=137
        plot, refwav, distance[xlens,ylens,*],psym=1
        oplot, refwav, polyfit[xlens,ylens,0]+polyfit[xlens,ylens,1]*refwav+polyfit[xlens,ylens,2]*refwav*refwav
        print, max(abs(distance[xlens,ylens,*]-(polyfit[xlens,ylens,0]+polyfit[xlens,ylens,1]*refwav+polyfit[xlens,ylens,2]*refwav*refwav)))
                                ;stop
        
                                ;tilt of spectra
        if nbwav ge 2 then begin
           tilt2=fltarr(sz[1],sz[2],nbwav-1)
           ;;calculate tilts for sevral locations of each spectrum and keep the median value
           for rw=1, nbwav-1 do tilt2[*,*,rw-1]= atan((wavcaltabgeny[*,*,rw]-wavcaltabgeny[*,*,0])/(wavcaltabgenx[*,*,rw]-wavcaltabgenx[*,*,0]))
        endif
        
        wavcalcomb=fltarr(sz[1],sz[2],7) ;NLin case
        wavcalcomb[*,*,0]=wavcaltabgenx[*,*,0]
        wavcalcomb[*,*,1]=wavcaltabgeny[*,*,0]
        wavcalcomb[*,*,2]=refwav[0]
        wavcalcomb[*,*,3]=polyfit[*,*,0]
        wavcalcomb[*,*,4]=polyfit[*,*,1]
        wavcalcomb[*,*,5]=polyfit[*,*,2]
        if (size(tilt2))[0] eq 2  then  wavcalcomb[*,*,6]=tilt2 else wavcalcomb[*,*,6]=median(tilt2,/double,dimension=3,/even)

;      ;do the median filter for dispersion coeff& tilts:
;      for indwc=3,6 do begin
;          wavcalcombtemp=median(wavcalcomb[*,*,indwc],5)
;          indNan=where(~finite(wavcalcomb[*,*,indwc]),cnan)
;          if cnan ne 0 then wavcalcombtemp[where(~finite(wavcalcomb[*,*,indwc]))]=!VALUES.F_NAN
;          wavcalcomb[*,*,indwc]=wavcalcombtemp
;      endfor
     endif
     *(dataset.currframe[0])=wavcalcomb
;stop
     basename=findcommonbasename(dataset.filenames[0:nfiles-1])
     FXADDPAR, hdr, 'DATAFILE', basename+'.fits'
     sxaddhist, functionname+": combined wavcal files:", hdr ;*(dataset.headers[numfile])
     for i=0,nfiles do $ 
        sxaddhist, functionname+": "+strmid(dataset.filenames[i], 0,strlen(dataset.filenames[i])-6)+suffix+'.fits', hdr ;*(dataset.headers[numfile])

;update with the most recent dateobs and timeobs
     dateobs3=dblarr(nfiles)
     for n=0,nfiles-1 do begin
        dateobs2 =  strc(sxpar(hdr, "DATE-OBS"))+" "+strc(sxpar(hdr,"TIME-OBS"))
        dateobs3[n] = date_conv(dateobs2, "J")
     endfor
     recent=max(dateobs3,indrecent)
     ;;we add 1second to the last time-obs so the combinaison will the most recent
     dateobscomb=date_conv(dateobs3[indrecent]+1./24./60./60.,'F')
     datetimecomb=strsplit(dateobscomb,'T', /extract)
     FXADDPAR, hdr, 'DATE-OBS', datetimecomb[0]
     FXADDPAR, hdr, 'TIME-OBS', datetimecomb[1]


                                ;suffix+='-comb'
  endif else begin
     backbone->set_keyword, 'HISTORY',  functionname+": Only one wavelength calibration supplied; nothing to combine!" ,ext_num=0 ;*(dataset.headers[numfile])
     backbone->Log, "Only one wavelength calibration supplied; nothing to combine!"
  endelse

@__end_primitive

end
