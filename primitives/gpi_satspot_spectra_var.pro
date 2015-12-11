;+
; NAME: gpi_satspot_spectra_var
; PIPELINE PRIMITIVE DESCRIPTION: Satellite Spot Spectra variability across sequence
;
;
;
; PIPELINE COMMENT:  Satellite Spot Spectra variability
; PIPELINE CATEGORY: SpectralScience

; PIPELINE ARGUMENT: Name="SavePNG" Type="string" Default="" Desc="Save plot to filename as PNG (blank for no save, dir name for default naming, AUTO for auto full path) "
; PIPELINE ARGUMENT: Name="ApertureRadius" Type="int" Range="[0,50]" Default="4" Desc="Radius in aperture photometry"
; PIPELINE ARGUMENT: Name="InnerSkyRadius" Type="int" Range="[5,50]" Default="10" Desc="Inner Sky Radius"
; PIPELINE ARGUMENT: Name="OuterSkyRadius" Type="int" Range="[5,50]" Default="15" Desc="Outer Sky Radius"
; PIPELINE ARGUMENT: Name="Plot" Type="int" Range="[0,1]" Default="0" Desc="1: Do spectra plot. 0: Don't plot"
; PIPELINE ARGUMENT: Name="PrintonScreen" Type="int" Range="[0,1]" Default="0" Desc="1: Print output on screen 0: Don't" 
;
; HISTORY: S. Bruzzone Dec 11 2015
;-
function gpi_satspot_spectra_var, DataSet, Modules, Backbone
  ; enforce modern IDL compiler options:
  compile_opt defint32, strictarr, logical_predicate

  @__start_primitive
  doplot=fix(Modules[thisModuleIndex].Plot)
  verbose=fix(Modules[thisModuleIndex].PrintonScreen)
  pngsave = Modules[thisModuleIndex].SavePNG
  ;store = fix(Modules[thisModuleIndex].Save)
  aperrad=fix(Modules[thisModuleIndex].ApertureRadius)
  insky=fix(Modules[thisModuleIndex].InnerSkyRadius)
  outsky=fix(Modules[thisModuleIndex].OuterSkyRadius)
  imgcub = *(dataset.currframe[0])
  nfiles=dataset.validframecount
  BIGDATA=findgen(5,37,nfiles)
      
  FOR i=0,nfiles-1 DO BEGIN

    imgcub =  accumulate_getimage(dataset,i,hdr,hdrext=hdrext)
    hdrext0 = hdrext
    BIGDATA[*,*,i] = satflux_wave(backbone, imgcub, aperrad, insky, outsky,verbose)
    if n_elements(BIGDATA) eq 1 then return, error('Error loeading fluxes, Spectra Var FAILED =(')
    ; doing stuff now
   
  ENDFOR
  
  wavelength=BIGDATA[4,*,0]
  FW=findgen(37)
  FW2=findgen(37)
  SD=findgen(37)
    
  
  xrange = [1e12,-1e12]
  yrange = [0,1]
  xrange[0] = xrange[0] < min(wavelength)
  xrange[1] = xrange[1] > max(wavelength)
  
  ;Plot spectra
  IF (doplot EQ 1) THEN BEGIN
    ;cindex=round((indgen(nfiles)/nfiles)*200)
    if nfiles EQ 1 then color = cgcolor('red') else begin
      ;ctable = COLORTABLE(13, NCOLORS = nfiles, INDICES=cindex,/TRANSPOSE)
      ctable = round(findgen(nfiles)/(nfiles-1)*200.+10.)
    endelse
    ;print, 'ctable', ctable
    window,/free,xsize=800,ysize=600,retain=2

    yrange[0] = 0
    mx = MAX(BIGDATA[0,*,*], location)
    ind = ARRAY_INDICES(BIGDATA[0,*,*], location)
    maxima=BIGDATA[0,ind[1],ind[2]]
    yrange[1] = maxima

    plot,[0],[0],/xstyle,/ystyle,$
   /nodata, charsize=1.5,background=cgcolor('white'),color = cgcolor('black'),XTITLE='Wavelength (nm)', YTITLE='FLUX (ADU coadd^-1)',$
   THICK=3,xrange=xrange,yrange=yrange
   tvlct, r, g,b, /get
   loadct, 13
  
    FOR i=0,nfiles-1 DO BEGIN
   ; ii=string(i)
   ; ii=strtrim(ii,1)
   ; fileok = FILE_TEST( '~/SPECFLUX/'+targetname+'/'+targetname+'-'+ii+'.dat')
   ; IF (fileok NE 1) THEN BEGIN
   ;   print, ' '
   ;   return, error('FAILURE('+functionName+'): File not found. Run primitive with Plot=0')
   ; ENDIF
   ; infile = '~/SPECFLUX/'+targetname+'/'+targetname+'-'+ii+'.dat'
   ; get_lun, unit3
   ; openr,unit3,infile
   ; readf,unit3,T
   ;print, 'T: ', T
      FW=BIGDATA[0,*,i]
      OPLOT,wavelength, FW,color=ctable[i],linestyle=0
                     
    ENDFOR
   tvlct, r, g,b
  ENDIF
  
  FOR i=0,36 DO BEGIN
    FW2[i] = mean(BIGDATA[0,i,*]) ; mean
    ;print, 'FW: ', FW[i]
    SD[i] = stddev(BIGDATA[0,i,*]); stddev
  ENDFOR
  NSD=SD/FW2
  IF verbose  THEN BEGIN
    print, ' '
    print, '-----------------------------------------'
    print, 'F & SD calculated'
    print, 'Normalized Standard dev: ', NSD
    print, '-----------------------------------------'
  ENDIF
  
  ;Use new window
  window,/free,xsize=800,ysize=600,retain=2
 
  plot,wavelength, NSD,/xstyle,/ystyle,$
   charsize=1.5,background=cgcolor('white'),color = cgcolor('black'),XTITLE='Wavelength (nm)', YTITLE='Normalized STDEV',THICK=3,xrange=xrange,linestyle=0
  
  
     IF pngsave NE '' THEN BEGIN
         ;;if user set AUTO then synthesize entire path
         if strcmp(strupcase(pngsave),'AUTO') then begin 
            s_OutputDir = Modules[thisModuleIndex].OutputDir
            s_OutputDir = gpi_expand_path(s_OutputDir) 
            if strc(s_OutputDir) eq "" then return, error('FAILURE: supplied output directory is a blank string.')
            s_OutputDir = s_OutputDir+path_sep()+'NormSTDEV'+path_sep()

            if ~file_test(s_OutputDir,/directory, /write) then begin
               if gpi_get_setting('prompt_user_for_outputdir_creation',/bool, default=0,/silent) then $
                  res =  dialog_message('The requested output directory '+s_OutputDir+' does not exist. Should it be created now?', $
                                        title="Nonexistent Output Directory", /question) else res='Yes'
               
               if res eq 'Yes' then  file_mkdir, s_OutputDir
               
               if ~file_test(s_OutputDir,/directory, /write) then $
                  return, error("FAILURE: Directory "+s_OutputDir+" does not exist or is not writeable.",/alert)
            endif         
            pngsave = s_OutputDir
         endif 
         
         ;;if this is a directory, then you want to save to it with the
         ;;default naming convention
         if file_test(pngsave,/dir) then begin
            nm = gpi_expand_path(DataSet.filenames[numfile])
            strps = strpos(nm,path_sep(),/reverse_search)
            strpe = strpos(nm,'.fits',/reverse_search)
            nm = strmid(nm,strps+1,strpe-strps-1)
            nm = gpi_expand_path(pngsave+path_sep()+nm+'_RSRF-stdev.png')
            
         endif else nm = pngsave

           
         write_png,nm,tvrd(true=1)
         print, 'PNG File Saved at: ', pngsave
      ENDIF
   
  @__end_primitive
  end