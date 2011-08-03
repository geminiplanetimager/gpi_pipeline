;+
; NAME: extract_one_spectrum
; PIPELINE PRIMITIVE DESCRIPTION: Extract one spectrum 
;
;	
;	
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	/Save	Set to 1 to save the output image to a disk file. 
;
; GEM/GPI KEYWORDS:FILTER,IFSUNIT
; DRP KEYWORDS: CUNIT,DATAFILE,SPECCENX,SPECCENY
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

function extract_one_spectrum, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS

primitive_version= '$Id$' ; get version from subversion to store in header history
	;getmyname, functionname
	  @__start_primitive
    mydevice = !D.NAME
   	; save starting time
   	T = systime(1)

  	main_image_stack=*(dataset.currframe[0])
        ;if numext eq 0 then hdr=*(dataset.headers[numfile]) else hdr=*(dataset.headersPHU[numfile])
        band = gpi_simplify_keyword_value(backbone->get_keyword('FILTER1', count=ct))
        ;band=strcompress(sxpar( hdr, 'FILTER',  COUNT=cc),/rem)
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
      if (NLam gt 0)  then $
        xlam=(lambda)[indf] $
        else xlam=(indgen((size(main_image_stack))[3]))[indf]

      ps_figure = Modules[thisModuleIndex].ps_figure 
;      calunits=sxpar( *(dataset.headers[numfile]), 'CUNIT',  COUNT=cc)
;      ifsunits=sxpar( *(dataset.headers[numfile]), 'BUNIT',  COUNT=ci)
      calunits=backbone->get_keyword('CUNIT', count=cc)
      ifsunits=backbone->get_keyword('BUNIT', count=ci)
      units='counts/s'
      if ci eq 1 then units=ifsunits 
      if cc eq 1 then units=calunits 

      s_Ext='-spectrum_x'+Modules[thisModuleIndex].xcenter+'_y'+Modules[thisModuleIndex].ycenter
     filnm==backbone->get_keyword('DATAFILE') ;sxpar(hdr,'DATAFILE')
     slash=strpos(filnm,path_sep(),/reverse_search)
     psFilename = Modules[thisModuleIndex].OutputDir+'fig'+path_sep()+strmid(filnm, slash,strlen(filnm)-5-slash)+s_Ext+'.ps'

;;;;method#2 standard photometric measurement (DAOphot-like)
    cubcent2=main_image_stack
    ;;set photometric aperture and parameters
    phpadu = 1.0                    ; don't convert counts to electrons
    ;;apr is 2.5*lambda/D (EE=94%)
    ;;apr is 2.5*lambda/D (EE=94%)
    apr =  2.5*(lambda[0]*1.e-6/7.7)*(180.*3600./!dpi)/0.014 ;lambda[0]*float(radi) ;(1./2.)*
    skyrad =[apr+1.,apr+3.]
    print, 'Photometric aperture used:',apr
    print, 'Aperture sky annulus  inner radius:',skyrad[0],' outer radius:',skyrad[1]
    ;skyrad = lambda[0]*[float(radi)+2.,float(radi)+5.] ;(1./2.)*
   ; if (skyrad[1]-skyrad[0] lt 2.) then skyrad[1]=skyrad[0]+2.
    ; Assume that all pixel values are good data
    badpix = [-1.,1e6];state.image_min-1, state.image_max+1
    
    ;;do the photometry of the companion
    x0=x & y0=y & hh=3.
    phot_comp=fltarr(CommonWavVect[2])+!VALUES.F_NAN 
    while (total(~finite(phot_comp)) ne 0) && (skyrad[1]-skyrad[0] lt 20.) do begin
      for i=0,CommonWavVect[2]-1 do begin
            cent=centroid(cubcent2[x0-hh:x0+hh,y0-hh:y0+hh,i])
            x=x0+cent[0]-hh
            y=y0+cent[1]-hh
          aper, cubcent2[*,*,i], [x], [y], flux, errap, sky, skyerr, phpadu, (lambda[i]/lambda[0])*apr, $
            (lambda[i]/lambda[0])*skyrad, badpix, /flux, /silent ;, flux=abs(state.magunits-1)
            print, 'slice#',i,' flux comp #'+'=',flux[0],'at positions ['+strc(x)+','+strc(y)+']',' sky=',sky[0]
          phot_comp[i]=(flux[0])
      endfor
      skyrad[1]+=1.
    endwhile
     ;Need to take in to account Enc.Energy in the aperture (EE=9%): 
      phot_comp*=(1./0.91)
; overplot the phot apertures on radial plot
if (ps_figure gt 0)  then begin
  openps, psFilename
  if n_elements(indf) gt 1 then $
  if NLam eq 0 then plot, xlam, p1d[indf],ytitle='Intensity ['+units+']', xtitle='spaxel', psym=-1
  if NLam gt 0 then plot, xlam, p1d[indf],ytitle='Intensity ['+units+']', xtitle='Wavelength (um)', psym=-1, yrange=[0,1.3*max(p1d)]
  oplot, xlam,phot_comp
  closeps
  set_plot,'win'
endif 
if (ps_figure gt 0)  then begin
  openps, psFilename
  plot, xlam,phot_comp, xtitle='Wavelength (um)', psym=-1, yrange=[0,1.3*max(phot_comp)]
  closeps
 SET_PLOT, mydevice ; set_plot,'win'
endif 
suffix+='-spec'

;hdr=*(dataset.headers[numfile])

	thisModuleIndex = Backbone->GetCurrentModuleIndex()
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
		  if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0
		  wav_spec=[[lambda],[p1d],[phot_comp]] 
;		    sxaddpar, hdr, "SPECCENX", Modules[thisModuleIndex].xcenter, "x-locations in pixel on datacube where extraction has been made"
;        sxaddpar, hdr, "SPECCENY", Modules[thisModuleIndex].ycenter, 'y-locations in pixel on datacube where extraction has been made'
    backbone->set_keyword,"SPECCENX", Modules[thisModuleIndex].xcenter, "x-locations in pixel on datacube where extraction has been made",ext_num=1
    backbone->set_keyword,"SPECCENY", Modules[thisModuleIndex].ycenter, 'y-locations in pixel on datacube where extraction has been made',ext_num=1
    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix ,savedata=wav_spec, display=display) ;saveheader=hdr,
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
