;+
; NAME: MeasureContrast
; PIPELINE PRIMITIVE DESCRIPTION: Measure the contrast
;
;
; INPUTS: 
;
; KEYWORDS:
; 	CalibrationFile=	Name of grid ratio file.
;
; OUTPUTS: 
; 	Same datacube, plot of contrast curve
;
; 
;
; PIPELINE COMMENT: Measure the contrast. 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="gridratio" Default="AUTOMATIC"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="contrsigma" Type="float" Range="[0.,20.]" Default="5." Desc="Contrast sigma limit"
; PIPELINE ARGUMENT: Name="contrcen_x0" Type="int" Range="[0,300]" Default="168" Desc="Sat 1 detec. window center x"
; PIPELINE ARGUMENT: Name="contrcen_y0" Type="int" Range="[0,300]" Default="192" Desc="Sat 1 detec. window center y"
; PIPELINE ARGUMENT: Name="contrcen_x1" Type="int" Range="[0,300]" Default="90" Desc="Sat 2 detec. window center x"
; PIPELINE ARGUMENT: Name="contrcen_y1" Type="int" Range="[0,300]" Default="160" Desc="Sat 2 detec. window center y"
; PIPELINE ARGUMENT: Name="contrcen_x2" Type="int" Range="[0,300]" Default="122" Desc="Sat 3 detec. window center x"
; PIPELINE ARGUMENT: Name="contrcen_y2" Type="int" Range="[0,300]" Default="85" Desc="Sat 3 detec. window center y"
; PIPELINE ARGUMENT: Name="contrcen_x3" Type="int" Range="[0,300]" Default="197" Desc="Sat 4 detec. window center x"
; PIPELINE ARGUMENT: Name="contrcen_y3" Type="int" Range="[0,300]" Default="115" Desc="Sat 4 detec. window center y"
; PIPELINE ARGUMENT: Name="contrwinap" Type="int" Range="[0,300]" Default="20" Desc="Half-length of max box [pix]"
; PIPELINE ARGUMENT: Name="contrap" Type="int" Range="[0,300]" Default="3" Desc="Half length of Gauss. box"
; PIPELINE ARGUMENT: Name="contr_yaxis_min" Type="float" Range="[0.,1.]" Default="0.00000001" Desc="Y axis minimum"
; PIPELINE ARGUMENT: Name="contr_yaxis_max" Type="float" Range="[0.,1.]" Default="1." Desc="Y axis maximum"
; PIPELINE ARGUMENT: Name="ic_psfs" Type="float" Range="[0.,1.e5]" Default="0." Desc="Max intensity of spots (0 if need to be calculated)"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.7
; PIPELINE NEWTYPE: SpectralScience,PolarimetricScience
; PIPELINE TYPE: ALL
;
; HISTORY:
; 	initial version imported GPItv (with definition of contrast corrected) - JM
;
function measurecontrast, DataSet, Modules, Backbone

primitive_version= '$Id: measurecontrast.pro 674 2012-03-31 17:54:07Z Maire $' ; get version from subversion to store in header history
calfiletype = 'Gridratio'
@__start_primitive



gridfac = gpi_readfits(c_File) ;8317.6 

contrcen_x=intarr(4)
contrcen_y=intarr(4)
contrcen_x[0]=uint(Modules[thisModuleIndex].contrcen_x0)
contrcen_y[0]=uint(Modules[thisModuleIndex].contrcen_y0)
contrcen_x[1]=uint(Modules[thisModuleIndex].contrcen_x1)
contrcen_y[1]=uint(Modules[thisModuleIndex].contrcen_y1)
contrcen_x[2]=uint(Modules[thisModuleIndex].contrcen_x2)
contrcen_y[2]=uint(Modules[thisModuleIndex].contrcen_y2)
contrcen_x[3]=uint(Modules[thisModuleIndex].contrcen_x3)
contrcen_y[3]=uint(Modules[thisModuleIndex].contrcen_y3)
  
contrwinap=uint(Modules[thisModuleIndex].contrwinap)
contrap=uint(Modules[thisModuleIndex].contrap)

contrsigma=uint(Modules[thisModuleIndex].contrsigma)

  sz=(size(*(dataset.currframe[0]) ))
  ; let's start with middle slice, should we do it for all wav? 
  if sz[0] eq 3 then Cubefini= (*(dataset.currframe[0]) )[*,*,sz[3]/2]
  if sz[0] eq 2 then Cubefini= (*(dataset.currframe[0]) )
  badind=where(~FINITE( Cubefini),cc)
  if cc ne 0 then Cubefini(badind )=0 ;TODO:median value

if float(Modules[thisModuleIndex].ic_psfs) eq 0. then begin
    cens = fltarr(4,2)
    ic_psfs = fltarr(4)
    for i=0,3 do begin
        ;define first sat. box
        x1=0> (contrcen_x[i]-contrwinap) <((size(Cubefini))(1)-1)
        x2=5> (contrcen_x[i]+contrwinap) <((size(Cubefini))(1)-1)
        y1=0> (contrcen_y[i]-contrwinap) <((size(Cubefini))(2)-1)
        y2=5> (contrcen_y[i]+contrwinap) <((size(Cubefini))(2)-1)


        hh=5. ; box for fit

        array=Cubefini[x1:x2,y1:y2]
        max1=max(array,location)
        ind1 = ARRAY_INDICES(array, location)
        ind1(0)=hh> (ind1(0)+x1) < ((size(cubefini))[1]-hh-1)
        ind1(1)=hh> (ind1(1)+y1) < ((size(cubefini))[2]-hh-1)

        delvarx, paramgauss
        yfit = GAUSS2DFIT(Cubefini[ind1[0]-hh:ind1[0]+hh,ind1[1]-hh:ind1[1]+hh], paramgauss)

    cen1=double(ind1)
      ; cent coord in initial image coord
      cens[i,0]=double(ind1(0))-hh+paramgauss(4)
      cens[i,1]=double(ind1(1))-hh+paramgauss(5)

    if (~finite(cens[i,0])) || (~finite(cens[i,1])) || $
            (cens[i,0] lt 0) || (cens[i,0] gt (size(cubefini))(1)) || $
            (cens[i,1] lt 0) || (cens[i,1] gt (size(cubefini))(1)) then begin
       print, 'Warnings: **** Satellite PSF '+strc(i+1)+' not well detected ****'
      ; self->tvcontr, /nosat
       ;return,ok
      endif
     tmp_string = $
      string(cens[i,0], cens[i,1], $
         format = '("Sat'+strc(i+1)+' position:  x=",g14.7,"  y=",g14.7)' )
     ; widget_control,(*self.state).satpos_ids[i],set_value=tmp_string

      ic_psfs[i]=max(subarr(Cubefini,contrap,cens[i,*],/zeroout))

    endfor

    ;--- check for warnings
    contrcens = cens
    warn = 0
    for i=0,3 do if (abs(ic_psfs[i]-mean(ic_psfs)))/mean(ic_psfs) gt 0.25 then warn=1

    if warn then begin
      print, 'Warnings: *** Possible Sat. Misdetection: Fluxes vary >25%***'
     ; self->tvcontr
      return,ok
  endif else begin
      ; widget_control,(*self.state).contrwarning_id,set_value='Warnings: none'
  endelse
endif else begin
  ic_psfs=float(Modules[thisModuleIndex].ic_psfs)
endelse
    ;--- now compute the profile
    print, "Max intensity of spots (use this value for contrast curve on speckle-suppressed image):", mean(ic_psfs)
  ic_psfi=gridfac*mean(ic_psfs) ;[[ic_psfi1],[ic_psfi2]])
  dim=sz[1]
  ;mask psf center
  immask=1.-mkpupil(dim,0.028/0.014)
  im=avgaper(immask,1.)

  copsf=Cubefini/ic_psfi/im
  pixscl=0.0145

  contr_yaxis_min=float(Modules[thisModuleIndex].contr_yaxis_min)
  contr_yaxis_max=float(Modules[thisModuleIndex].contr_yaxis_max)


  ;;mask satellites
  for isat=0,3 do begin
      dis=distarr(dim,dim,cens[isat,0],cens[isat,1])
      imask=where(dis lt 0.1/pixscl)
      copsf[imask]=!values.f_nan
  endfor
  
lenstr=strlen((dataset.outputfilenames)[numfile])
contr_outfile= strmid((dataset.outputfilenames)[numfile],0,lenstr-5)+"-contrast"
  plotps=1
  if (plotps) then begin
    mydevice = !D.NAME

    set_plot,"ps"
    openps,contr_outfile+".ps"
    statvsr,copsf,0.,pixscl=pixscl,/psig,nsig=contrsigma,yr=[contr_yaxis_min, contr_yaxis_max],$
      xtitle='Angular separation [Arcsec]',ytitle='Contrast ('+strc(uint(contrsigma))+greek('sigma')+' limit)', cens=cens, asec=asec,isig=isig ;
     closeps
    SET_PLOT, mydevice

  endif



  if uint(Modules[thisModuleIndex].Save) then begin
      SAVE, FILENAME = contr_outfile+".sav", asec,isig
  endif


@__end_primitive 


end
