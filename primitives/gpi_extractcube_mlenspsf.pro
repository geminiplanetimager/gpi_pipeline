;+
; NAME: gpi_extractcube_mlenspsf
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Spectral Datacube using mlens PSF 
;
;		This routine transforms a 2D detector image in the dataset.currframe input
;		structure into a 3D data cube in the dataset.currframe output structure.
;   This routine extracts data cube from an image using an inversion method along the dispersion axis
;    
;
;
; KEYWORDS: 
; GEM/GPI KEYWORDS:
; OUTPUTS:
;
; PIPELINE COMMENT: Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="mlenspsf" Default="AUTOMATIC" Desc="Filename of the mlens-PSF calibration file to be read"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-spdci" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="ReuseOutput" Type="int" Range="[0,1]" Default="0" Desc="1: keep output for following primitives, 0: don't keep"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE TYPE: ALL-SPEC
;
; HISTORY:
; 	Originally by Jerome Maire 2007-11
;   2012-02-01 JM: adapted to vertical dispersion
;   2012-02-15 JM: adapted as a pipeline module

;+
function gpi_extractcube_mlenspsf, DataSet, Modules, Backbone
  common PIP
  COMMON APP_CONSTANTS
  primitive_version= '$Id: gpi_extractcube_mlenspsf.pro 1000 2012-02-10 04:41:40Z maire $' ; get version from subversion to store in header history

  calfiletype='mlenspsf' 

  ; getmyname, functionname
  @__start_primitive



  ;get the 2D detector image
  det=*(dataset.currframe[0])
  dim=(size(det))[1]
  detector_array=fltarr(dim,dim)
  ;detector_array2=fltarr(dim,dim)
  nlens=(size(wavcal))[1]       ;pixel sidelength of final datacube (spatial dimensions) 
  dim=(size(det))[1]            ;detector sidelength in pixels

  ;error handle if readwavcal or not used before
  if (nlens eq 0) || (dim eq 0)  then $
     return, error('FAILURE ('+functionName+'): Failed to load data.') 


  ;define the common wavelength vector with the FILTER1 keyword:
   filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  
  ;error handle if FILTER1 keyword not found
  if (filter eq '') then $
     return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 

  ;get length of spectrum
  sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)-2
  if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')
  
  ;get tilts of the spectra included in the wavelength solution:
  tilt=wavcal[*,*,4]

        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]
       
psfmlens = gpi_readfits(c_File,header=HeaderCalib)
sizepsfmlens=size(psfmlens)
psfDITHER = float(sxpar(HeaderCalib,"DITHER",count=cc))
if cc eq 0 then begin
  print, "mlens PSF DITHER keyword not found. It will be assumed that the fraction of a pixel the mlens PSF are dithering by is 1/5."
  psfDITHER = 5.  
endif
psfLMIN=float(sxpar(HeaderCalib,"LMIN",count=cc))
if cc eq 0 then begin
  print, "mlens-PSF LMIN keyword not found. It will be assumed that the minimal wavelength of the mlens PSFs is the minimal wavelength of the band."
  psfLMIN=  lambdamin  
endif
psfLMAX=float(sxpar(HeaderCalib,"LMAX",count=cc))
if cc eq 0 then begin
  print, "mlens-PSF LMAX keyword not found. It will be assumed that the maximal wavelength of the mlens PSFs is the maximal wavelength of the band."
  psfLMAX=  lambdamax  
endif
psfNBchannel=float(sxpar(HeaderCalib,"NLAM",count=cc))
if cc eq 0 then begin
  print, "mlens-PSF NLAM keyword not found. It will be assumed that the maximal wavelength for the mlens PSFs is the maximal wavelength of the band."
  psfNBchannel= float((sizepsfmlens)[3]) / (float(psfdither))^2
endif
;;minimal verification
if (psfNBchannel * (float(psfdither))^2 NE float((sizepsfmlens)[3]) ) then begin
    return, error('FAILURE ('+functionName+'): mlens-PSF database seems corrupted. Please verify all keywords are present and properly fed.') 
endif

 
 szpsfmlens=(size(psfmlens))[1]
 dimpsf=(size(psfmlens))(1)
 szpsf = size(psfmlens)
 psftot=fltarr(szpsfmlens,szpsfmlens)


  dl = psfLMAX - psfLMIN
  dx = dl/psfNBchannel
 zemdisplamraw=  dindgen(psfNBchannel)/psfNBchannel*dl + psfLMIN + dx/2d
  

        nlam=10.
        pas=psfDITHER 
         nlamdst= psfNBchannel
         
        psfmlens2=fltarr(szpsfmlens,szpsfmlens,nlam)
        
        lambda2=fltarr(nlam)
        ;lambda2=lambdamin+findgen(nlam)*(lambdamax-lambdamin)/(nlam-1) 
        
        for qq=0,nlam-1 do lambda2[qq]=zemdisplamraw[round(nlamdst / nlam)*qq]
       
        
          cubef3D=dblarr(nlens,nlens,nlam)+ !values.f_nan;create the datacube
        
        
        szwavcal=size(wavcal)
        xloctab=fltarr(szwavcal[1],szwavcal[2],nlam)
        yloctab=fltarr(szwavcal[1],szwavcal[2],nlam)
         for lam=0,nlam-1 do begin
           loctab=(change_wavcal_lambdaref( wavcal, lambda2[lam]))
           xloctab[*,*,lam]=loctab[*,*,1]
           yloctab[*,*,lam]=loctab[*,*,0]
         endfor
         

             
        
         larg=2
         longu=20
  for xsi=0,nlens-1 do begin    
  print, "mlens PSF invert method for datacube extraction, row #",xsi," /",nlens-1   
     for ysi=0,nlens-1 do begin   

    ; get the locations on the image where intensities will be extracted:
     x3=xloctab[xsi,ysi,0]  ;xmini[xsi,ysi]
     y3= yloctab[xsi,ysi,0]  ;wavcal[xsi,ysi,1]+(wavcal[xsi,ysi,0]-x3)*tan(tilt[xsi,ysi])	
  
  if finite(x3) && finite(y3)&& (x3 gt 0) && (x3 lt 2030) && (y3 gt 20) && (y3 lt 2048) then begin

      x4=x3
      y4=y3
      cci=-1
      
 
      ;choice of pixels for the inversion
      xchoiceind=[0.]
      ychoiceind=[0.]
      for nl=0,nlam-1 do begin
        if (round(xloctab[xsi,ysi,nl])+larg lt 2048) && (round(yloctab[xsi,ysi,nl]) lt 2048) then begin
        ;evite les doublons qd nlam>sdpx
            if (nl eq 0) || ~( (round(xloctab[xsi,ysi,nl-1]) eq round(xloctab[xsi,ysi,nl])) && (round(yloctab[xsi,ysi,nl-1]) eq round(yloctab[xsi,ysi,nl])))  then begin
              for clarg=-larg,larg do xchoiceind=[xchoiceind,round(xloctab[xsi,ysi,nl])+clarg>0]
              for clarg=-larg,larg do ychoiceind=[ychoiceind,round(yloctab[xsi,ysi,nl])>0]
            endif  
         endif     
                  
      endfor
      xchoiceind=xchoiceind[1:(n_elements(xchoiceind)-1)]
      ychoiceind=ychoiceind[1:(n_elements(ychoiceind)-1)]
      ;do we need to add extreme pixels?
      
         if (round(yloctab[xsi,ysi,0]) lt 2047) && (round(xloctab[xsi,ysi,0]) lt 2047) && (round(xloctab[xsi,ysi,0]) gt 0) then begin ;&& ((yloctab[xsi,ysi,0]-round(yloctab[xsi,ysi,0]) gt 0.5))  then begin
          xchoiceind=[round(xloctab[xsi,ysi,0])-1,round(xloctab[xsi,ysi,0]),round(xloctab[xsi,ysi,0])+1,xchoiceind]
          ychoiceind=[round(yloctab[xsi,ysi,0])+1,round(yloctab[xsi,ysi,0])+1,round(yloctab[xsi,ysi,0])+1,ychoiceind]
        endif
       if (round(yloctab[xsi,ysi,nl-1]) gt 0) && (round(xloctab[xsi,ysi,nl-1]) lt 2047) && (round(xloctab[xsi,ysi,nl-1]) gt 0) then begin ;&& ((yloctab[xsi,ysi,nl-1]-round(yloctab[xsi,ysi,nl-1]) lt 0))  then begin
          xchoiceind=[xchoiceind,round(xloctab[xsi,ysi,nl-1])-1,round(xloctab[xsi,ysi,nl-1]),round(xloctab[xsi,ysi,nl-1])+1]
          ychoiceind=[ychoiceind,round(yloctab[xsi,ysi,nl-1])-1,round(yloctab[xsi,ysi,nl-1])-1,round(yloctab[xsi,ysi,nl-1])-1]
        endif


             for nl=0,nlam-1 do begin
                                 
               
                 nlval=min( abs(zemdisplamraw[*]-lambda2[nl]),minind)
                nla=minind
       
 
                  cci+=1

                  dx2L=reform(xloctab[xsi,ysi,*] )
                  dy2L=round(reform(yloctab[xsi,ysi,*] ))
            

                  i=xsi
           

                  psflmens2_tmp=psfmlens(*,*,nla*pas*pas+pas*( round( (dx2L[nl]-floor(dx2L[nl])) * pas) mod pas) + (round( (dy2L[nl]-floor(dy2L[nl])) * pas) mod pas))

                      xshift=floor(dx2L[nl])-floor(dx2L[0])
                      yshift=floor(dy2L[nl])-floor(dy2L[0])
                    
                    if (dx2L[nl]-floor(dx2L[nl])) ge 1.-0.5*(1./float(pas)) then xshift+=1
                    if (dy2L[nl]-floor(dy2L[nl])) ge 1.-0.5*(1./float(pas)) then yshift+=1
                    
                      psfmlens2[0,0,nl]=SHIFT(psflmens2_tmp,xshift,yshift)
                      
                  endfor
                  psfmlens4=reform(psfmlens2,szpsf[1]*szpsf[2],nlam)
                  
                spectrum=reform(psfmlens4#(fltarr(nlam)+1.),szpsf[1],szpsf[2])  ;;Calcul d'un spectrum 

          
                tmpx = floor(dx2L[0])
                tmpy = floor(dy2L[0])
                indxmin= (tmpx-(dimpsf-1)/2) > 0
                    indxmax= (tmpx+(dimpsf-1)/2-1) < (dim-1)
                    indymin= (tmpy-(dimpsf-1)/2) > 0
                    indymax= (tmpy+(dimpsf-1)/2-1) < (dim-1)

    
                aa = -(tmpx-(dimpsf-1)/2)
                bb = -(tmpy-(dimpsf-1)/2)
  
                detector_array[indxmin:indxmax,indymin:indymax]+=  spectrum(indxmin+aa: indxmax+aa, indymin+bb:indymax+bb)
                

                psfmat=fltarr(n_elements(xchoiceind),nlam)
                psfmat2=fltarr((2*larg+1)*nlam,nlam)
                for nelam=0,nlam-1 do begin
                  
                  for nbpix=0,n_elements(xchoiceind)-1 do $
                  psfmat[nbpix,nelam]=psfmlens2[xchoiceind[nbpix]+aa,ychoiceind[nbpix]+bb,nelam]
                  
               endfor
                

               if ((tmpx-larg) lt 0) OR  ((tmpx+larg) ge (dim-1)) OR (tmpy lt 0) OR ((tmpy+longu-1) ge (dim-1)) then  flagedge=0 else flagedge=1

;                    print, "create intensity vector..."
                    bbc=fltarr(n_elements(xchoiceind))
                    for nel=0,n_elements(xchoiceind)-1 do bbc[nel]=det[xchoiceind[nel],ychoiceind[nel]]
                   
                   
     

         ;;invert to get flux
         if 1 eq 1 then begin
              SVDC, transpose(psfmat), W, U, V , /double
          
            ; Compute the solution and print the result: 
            if flagedge eq 1 then  flux= SVSOL(U, W, V, bbc, /double) else flux=fltarr(nlam)+!values.f_nan
          
          endif else begin
                       ;;positive constraints
                       a=transpose(psfmat)
                       m=n_elements(xchoiceind)
                       n=nlam
                       b=bbc
                       x=fltarr(nlam)+1.
                       w2=fltarr(nlam)
                       indx=intarr(nlam+1)
                       nnls, a, m, n, b, x, rnorm, w2, indx, mode
                       flux=x
                        
          endelse
         cubef3D[xsi,ysi,*]=flux*(float(nlam)/18.) ;this is normalized to take into account the number of slices we considered with respect to the length of spectra
         
         if 1 eq 0 then begin ; these 2 lines are just to check out the reconstruction
           reconspec=fltarr(dimpsf,dimpsf)
           for zl=0,nlam-1 do  reconspec+=flux[zl]*psfmlens2[*,*,zl]
         endif


     endif
  endfor
  endfor

  suffix='-spdci'
  ; put the datacube in the dataset.currframe output structure:
   if tag_exist( Modules[thisModuleIndex],"ReuseOutput") && (float(Modules[thisModuleIndex].ReuseOutput) eq 1.)  then begin
    *(dataset.currframe[0])=cubef3D

      ;create keywords related to the common wavelength vector:
      backbone->set_keyword,'NAXIS',3, ext_num=1
      backbone->set_keyword,'NAXIS1',nlens, ext_num=1
      backbone->set_keyword,'NAXIS2',nlens, ext_num=1
      backbone->set_keyword,'NAXIS3',nlam, ext_num=1
      
      backbone->set_keyword,'CDELT3',(lambda2[1]-lambda2[0]),'wav. increment', ext_num=1
      ; FIXME this CRPIX3 should probably be **1** in the FORTRAN index convention
      backbone->set_keyword,'CRPIX3',0.,'pixel coordinate of reference point', ext_num=1
      backbone->set_keyword,'CRVAL3',lambda2[0],'wav. at reference point', ext_num=1
      backbone->set_keyword,'CTYPE3','WAVE', ext_num=1
      backbone->set_keyword,'CUNIT3','microms', ext_num=1
      backbone->set_keyword,'HISTORY', functionname+": Inversion datacube extraction applied.",ext_num=0

      @__end_primitive
    endif else begin  
        hdr=*(dataset.headersExt)[numfile]
        sxaddparlarge, hdr, 'NAXIS',3
        sxaddparlarge, hdr, 'NAXIS1',nlens
        sxaddparlarge, hdr, 'NAXIS2',nlens
        sxaddparlarge, hdr, 'NAXIS3',nlam
        
        sxaddparlarge, hdr, 'CDELT3',(lambda2[1]-lambda2[0])
        sxaddparlarge, hdr, 'CRPIX3',0.
        sxaddparlarge, hdr, 'CRVAL3',lambda2[0]
        sxaddparlarge, hdr, 'CTYPE3','WAVE'
        sxaddparlarge, hdr, 'CUNIT3','microms'
        sxaddparlarge, hdr, 'HISTORY', functionname+": Inversion datacube extraction applied."
   
            if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
              if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
              b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, savedata=cubef3D, saveheader=hdr, display=display)
              if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
            endif else begin
              if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
                  Backbone_comm->gpitv, double(cubef3D), ses=fix(Modules[thisModuleIndex].gpitv)
            endelse

  endelse

end

