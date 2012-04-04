;+
; NAME: extract_one_spectrum2
; PIPELINE PRIMITIVE DESCRIPTION: Extract one spectrum, plots 
;
;	
;	
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	/Save	Set to 1 to save the output image to a disk file.
; KEYWORDS:
; GEM/GPI KEYWORDS:FILTER,IFSUNIT
; DRP KEYWORDS: CUNIT,DATAFILE,SPECCENX,SPECCENY
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Extract one spectrum from a datacube somewhere in the FOV specified by the user.
; PIPELINE ARGUMENT: Name="xcenter" Type="int" Range="[0,1000]" Default="141" Desc="x-locations in pixel on datacube where extraction will be made"
; PIPELINE ARGUMENT: Name="ycenter" Type="int" Range="[0,1000]" Default="141" Desc="y-locations in pixel on datacube where extraction will be made"
; PIPELINE ARGUMENT: Name="radius" Type="float" Range="[0,1000]" Default="5." Desc="Aperture radius (in pixel i.e. mlens) to extract photometry for each wavelength. "
; PIPELINE ARGUMENT: Name="method" Type="string"  Default="total" Range="[median|mean|total]"  Desc="method of photometry extraction:median,mean,total"
; PIPELINE ARGUMENT: Name="ps_figure" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose # of saved fig suffix name, 0: no ps figure "
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output (fits) on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-spec" Desc="Enter output suffix (fits)"
; PIPELINE ORDER: 2.51
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	
;   JM 2010-03 : created module.
;- 

function extract_one_spectrum2, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS

primitive_version= '$Id: extract_one_spectrum2.pro 96 2010-10-20 13:47:13Z maire $' ; get version from subversion to store in header history
	;getmyname, functionname
	  @__start_primitive

   	; save starting time
   	T = systime(1)

  	main_image_stack=*(dataset.currframe[0])

        ;band=strcompress(sxpar( *(dataset.headersext[numfile]), 'IFSFILT',  COUNT=cc),/rem)
        band=gpi_simplify_keyword_value(backbone->get_keyword( 'IFSFILT',count=cc))
        if cc eq 1 then begin
          cwv=get_cwv(band)
          CommonWavVect=cwv.CommonWavVect
          lambda=cwv.lambda
          lambdamin=CommonWavVect[0]
          lambdamax=CommonWavVect[1]
          NLam=CommonWavVect[2]
        endif else begin
          NLam=0
          lambda=(indgen((size(main_image_stack))[3]))
        endelse
	mydevice = !D.NAME
	thisModuleIndex = Backbone->GetCurrentModuleIndex()

   x = float(Modules[thisModuleIndex].xcenter)
   y = float(Modules[thisModuleIndex].ycenter)
   radi = float(Modules[thisModuleIndex].radius)
   currmeth = Modules[thisModuleIndex].method

;;method#1: radial photometry (it doesn't remove sky background)
  if radi gt 0 then begin
      distsq=shift(dist(2*radi+1),radi,radi)
    inda=array_indices(distsq,where(distsq le radi))
    inda[0,*]+=x-radi
    inda[1,*]+=y-radi
    ;;be sure circle doesn't go outside the image:
    inda_outx=intersect(where(inda[0,*] ge 0,cxz),where(inda[0,*] lt ((size(main_image_stack))[1]) ))
    inda_outy=intersect( where(inda[1,*] ge 0,cyz), where(inda[1,*] lt ((size(main_image_stack))[2])) )
    inda_out=intersect(inda_outx,inda_outy)
    inda2x=inda[0,inda_out]
    inda2y=inda[1,inda_out]
    inda=[inda2x,inda2y]
  endif else begin
    inda=intarr(2,1)
    inda[0,0]=x
    inda[1,0]=y
  endelse


  if (size(main_image_stack))[0] eq 3 then begin
    if radi gt 0 then begin
    mi=dblarr((size(inda))(2),(size(main_image_stack))(3),/nozero)
      for i=0,(size(inda))(2)-1 do $
      mi[i,*]=main_image_stack[inda(0,i),inda(1,i), *]
      p1d=fltarr((size(main_image_stack))(3))
      if STRMATCH(currmeth,'Total',/fold) then $
      p1d=total(mi,1,/nan)
      if STRMATCH(currmeth,'Median',/fold) then $
      p1d=median(mi,dimension=1)
      if STRMATCH(currmeth,'Mean',/fold) then $
      for i=0,(size(mi))(2)-1 do $
      p1d[i]=mean(mi(*,i),/nan)
      endif else begin
      p1d=main_image_stack[x, y, *]
      endelse

      indf=where(finite(p1d))
      if (n_elements(indf) eq 1) then return,0
      if (NLam gt 0)  then $
        xlam=(lambda)[indf] $
        else xlam=(indgen((size(main_image_stack))[3]))[indf]

      ps_figure = float(Modules[thisModuleIndex].ps_figure) 
      calunits=sxpar( *(dataset.headersext[numfile]), 'CUNIT',  COUNT=cc)
      ifsunits=sxpar( *(dataset.headersext[numfile]), 'IFSUNIT',  COUNT=ci)
      units='counts/s'
      if ci eq 1 then units=ifsunits 
      if cc eq 1 then units=calunits 

      s_Ext='-spectrum_x'+Modules[thisModuleIndex].xcenter+'_y'+Modules[thisModuleIndex].ycenter
     filnm=sxpar(*(DataSet.Headersphu[numfile]),'DATAFILE')
     slash=strpos(filnm,path_sep(),/reverse_search)
     psFilename = gpi_expand_path(Modules[thisModuleIndex].OutputDir)+strmid(filnm, slash,strlen(filnm)-5-slash)+s_Ext+'.ps'
print, 'ps filename:',psfilename
;;;;method#2 standard photometric measurement (DAOphot-like)
    cubcent2=main_image_stack
    ;;set photometric aperture and parameters
    phpadu = 1.0                    ; don't convert counts to electrons
    apr = (1./2.)*lambda[0]*float(radi)
    skyrad = (1./2.)*lambda[0]*[float(radi),float(radi)+2.] 
    if (skyrad[1]-skyrad[0] lt 2.) then skyrad[1]=skyrad[0]+2.
    ; Assume that all pixel values are good data
    badpix = [-1.,1e6];state.image_min-1, state.image_max+1
    
    ;;do the photometry of the companion
    x0=x & y0=y & hh=3.
    phot_comp=fltarr(CommonWavVect[2])+!VALUES.F_NAN 
    while (total(~finite(phot_comp)) ne 0) && (skyrad[1]-skyrad[0] lt 20.) do begin
      for i=0,CommonWavVect[2]-1 do begin
            cent=gpicentroid(cubcent2[x0-hh:x0+hh,y0-hh:y0+hh,i])
            x=x0+cent[0]-hh
            y=y0+cent[1]-hh
          aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, (lambda[i]/lambda[0])*apr, $
            (lambda[i]/lambda[0])*skyrad, badpix, /flux, /silent ;, flux=abs(state.magunits-1)
            print, 'slice#',i,' flux comp #'+'=',flux[0],'at positions ['+strc(x)+','+strc(y)+']',' sky=',sky[0]
          phot_comp[i]=(flux[0])
      endfor
      skyrad[1]+=1.
    endwhile
     
; overplot the phot apertures on radial plot
;if (ps_figure gt 0)  then begin
;  openps, psFilename
;  if n_elements(indf) gt 1 then $
;  if NLam eq 0 then plot, xlam, p1d[indf],ytitle='Intensity ['+units+']', xtitle='spaxel', psym=-1
;  if NLam gt 0 then plot, xlam, p1d[indf],ytitle='Intensity ['+units+']', xtitle='Wavelength (um)', psym=-1, yrange=[0,1.3*max(p1d)]
;  oplot, xlam,phot_comp
;  closeps
;  set_plot,'win'
;endif
if currmeth eq '' then photcomp=phot_comp else photcomp=p1d
;;;;;estimate spectral resolution from H-band Argon lamp image 
h=*(dataset.headersext[0])
obstype=SXPAR( h, 'OBSTYPE',count=c1)
;what's happen with OBSTYPE? Ok let's force this for now..
obstype="wavecal"

lamp=SXPAR( h, 'GCALLAMP',count=c2)
lamp=backbone->get_keyword( 'GCALLAMP',count=c1)
calc_res=0
;;calculate spectral resolution onl in the following specific cases:
 if strmatch(obstype, '*wavecal*')   then begin
    case band of 
     'H':begin
            if strmatch(lamp, '*Argon*') then begin
              lammin=1.68
              lammax=1.73
              refpic=1.7
              calc_res=1
               nterm=3
            endif
        end
             'J':begin
                if strmatch(lamp, '*Xenon*') then begin
                  lammin=1.24
                  lammax=1.28
                  refpic=1.26
                  calc_res=1
                   nterm=3
                endif
            end
                         'Y':begin
                if strmatch(lamp, '*Argon*') then begin
                  lammin=0.95
                  lammax=0.98
                  refpic=0.965
                  calc_res=1
                   nterm=3
                endif
            end
            
             'K1':begin
                if strmatch(lamp, '*Xenon*') then begin
                  lammin=2.0
                  lammax=2.05
                  refpic=2.02
                  calc_res=1
                  nterm=3
                endif
                end
              'K2':begin
                if strmatch(lamp, '*Xenon*') then begin
                  lammin=2.30
                  lammax=2.34
                  refpic=2.32
                  calc_res=1
                  nterm=4
                endif
                end
                
     endcase
     if calc_res eq 1 then begin
   indwav=where((xlam gt lammin) AND (xlam lt lammax))
    res=gaussfit(xlam[indwav], photcomp[indwav],A,nterms=nterm)
    fwhm=2.*sqrt(2.*alog(2.))*A[2]
    print, 'FWHM=', fwhm
    specres=refpic/FWHM
    print, 'Spec Res=', specres
    
    ;;let's see what the resolution vs fov
    specresfov=fltarr((size(main_image_stack))[1],(size(main_image_stack))[2])
    for xx=0, (size(main_image_stack))[1]-1 do begin
        for yy=0, (size(main_image_stack))[2]-1 do begin
              spectrum=main_image_stack[xx,yy,*]
              if (total(finite(spectrum)) gt 5) then begin
                res=gaussfit(xlam[indwav], spectrum[indwav],A,nterms=nterm)
                fwhm=2.*sqrt(2.*alog(2.))*A[2]
                specresfov[xx,yy]=refpic/FWHM
              endif
      endfor
    endfor
    plotc, specresfov, 30, 900,900,'micro-lens','micro-lens','Spectral resolution',valmin=30,valmax=60
    endif
 endif

 if strmatch(obstype, '*wavecal*') then begin
    if strmatch(lamp, '*Argon*') then lampe='Ar'
    if strmatch(lamp, '*Xenon*') then lampe='Xe'
        readcol, getenv('GPI_IFS_DIR')+path_sep()+'dst'+path_sep()+lampe+'ArcLampG.txt', wavelen, strength
      wavelen=1.e-4*wavelen
        spect = fltarr(n_elements(xlam))      
        wg = where(wavelen gt min(xlam) and wavelen lt max(xlam), gct)      
        for i=0L,gct-1 do begin 
          diff = min(abs(xlam - wavelen[wg[i]]), closest) 
          spect[closest] += strength[wg[i]] 
        endfor       
      msp=max(spect)
      spect=spect/msp
      strength=strength/msp
   endif

if (ps_figure gt 0.)  then begin
  
 ; if numfile eq 0 then begin
 ;if ~file_test(psFilename) then begin
    openps, psFilename
    plot, xlam,photcomp, xtitle='Wavelength (um)', ytitle='Intensity',psym=-1, yrange=[0,1.3*max(photcomp)]
    if strmatch(obstype, '*wavecal*') then $
    for i=0L,gct-1 do  plots, wavelen[wg[[i,i]]], max(photcomp)*[0, strength[wg[i]]], color=fsc_color('blue'), /clip
    xyouts,xlam[3], 1.2*max(photcomp), 'Median spectrum of '+strc((size(inda))[2])+' spectra centered on mlens ['+strc(x0,format='(I3)')+','+strc(y0,format='(I3)')+']'
     if n_elements(specres) gt 0 then xyouts,xlam[3], 1.1*max(photcomp), 'Spectral Resolution='+strc(specres, format='(g5.3)') 
;  endif else begin
;  set_plot,'ps'
;    oplot, xlam,photcomp
;  endelse
  ;if numfile eq 2 then begin
    closeps
    
 ; endif
  SET_PLOT, mydevice
endif 
suffix+='-spec'

hdr=*(dataset.headersext[numfile])



	thisModuleIndex = Backbone->GetCurrentModuleIndex()
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
		  if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0
		  wav_spec=[[lambda],[p1d],[phot_comp]] 
		    sxaddpar, hdr, "SPECCENX", Modules[thisModuleIndex].xcenter, "x-locations in pixel on datacube where extraction has been made"
        sxaddpar, hdr, "SPECCENY", Modules[thisModuleIndex].ycenter, 'y-locations in pixel on datacube where extraction has been made'  
    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix ,savedata=wav_spec, saveheader=hdr,savePHU=*(dataset.headersPHU[numfile]),display=display)
    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
          Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
    endelse

endif 
;drpPushCallStack, functionName

return, ok


end
