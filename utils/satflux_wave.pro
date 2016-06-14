function satflux_wave, backbone, cube0, aperrad, insky, outsky, verbose
  ; enforce modern IDL compiler options:
  ;compile_opt defint32, strictarr, logical_predicate


  mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
  mode = strlowcase(mode)
  IF strmatch(mode,"*wollaston*",/fold) THEN BEGIN
    return, error('FAILURE): Input file must be a Spdc cube.')
  ENDIF
  filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  targetname=backbone->get_keyword("OBJECT")
  cwv=get_cwv(filter)
  CommonWavVect=cwv.CommonWavVect
  lambda=cwv.lambda
  D=43.2*0.18; not deeded right now?
  lambdamin=CommonWavVect[0]
  lambdamax=CommonWavVect[1]
  dlamb=(lambdamax-lambdamin)/37.0
  wavvect=lambdamin+dlamb*findgen(37)
  landa=lambdamin + (lambdamax-lambdamin)/2.0
  apr=aperrad*wavvect/landa
  skyin=insky*wavvect/landa
  skyout=outsky*wavvect/landa
  
  IF verbose THEN BEGIN
    print, ' '
    print, 'Scaled aperture radii: ', apr
    print, ' '
  ENDIF
 
  imgcub=cube0
  
  
  
  ; loading sat spot locations for each slice.
  ; for loop in sat spots
    P=findgen(2,4,37)
    S=findgen(2,4)
   
    FOR i=0,36 DO BEGIN
         
      m=string(i)
      m=strtrim(m,1)
      n=string(0)
      n=strtrim(n,1)
      s="SATS"+m+"_"+n; SATS0_3
      IF verbose THEN BEGIN
      print, 'Checking sat: ', s
        
      ENDIF
      B = backbone->get_keyword(s,/silent)
      bb = strtrim(B,1)
      s0=MAKE_ARRAY(2,1,/STRING, VALUE=0)
      s0 = strsplit(bb, ' ',/EXTRAC)
      s0=DOUBLE(s0)
      
      m=string(i)
      m=strtrim(m,1)
      n=string(1)
      n=strtrim(n,1)
      s="SATS"+m+"_"+n; SATS0_3
      IF verbose THEN BEGIN
      print, 'Checking sat: ', s  
      ENDIF
      
      B = backbone->get_keyword(s,/silent)
      bb = strtrim(B,1)
      s1=MAKE_ARRAY(2,1,/STRING, VALUE=0)
      s1 = strsplit(bb, ' ',/EXTRAC)
      s1=DOUBLE(s1)
      
      m=string(i)
      m=strtrim(m,1)
      n=string(2)
      n=strtrim(n,1)
      s="SATS"+m+"_"+n; SATS0_3
      IF verbose THEN BEGIN
      print, 'Checking sat: ', s  
      ENDIF
      
      B = backbone->get_keyword(s,/silent)
      bb = strtrim(B,1)
      s2=MAKE_ARRAY(2,1,/STRING, VALUE=0)
      s2 = strsplit(bb, ' ',/EXTRAC)
      s2=DOUBLE(s2)
       
      m=string(i)
      m=strtrim(m,1)
      n=string(3)
      n=strtrim(n,1)
      s="SATS"+m+"_"+n; SATS0_3
      IF verbose THEN BEGIN
      print, 'Checking sat: ', s  
      ENDIF
      B = backbone->get_keyword(s,/silent)
      bb = strtrim(B,1)
      s3=MAKE_ARRAY(2,1,/STRING, VALUE=0)
      s3 = strsplit(bb, ' ',/EXTRAC)
      s3=DOUBLE(s3) 
      S=[[s0],[s1],[s2],[s3]]
      P[*,*,i]=S
      
     ENDFOR
     IF verbose THEN BEGIN
     print, 'Sat spot locations stored'
     print, 'Calling APER'
     ENDIF
     
     F=findgen(37)
     DF=findgen(37)
     S=findgen(37)
     DS=findgen(37)
  
    FOR i=0,36 DO BEGIN ; ignore centering
      ;CNTRD, imgcub[*,*,i],P[0,0,i],P[1,0,i], x, y,4 ;centroid of sat spot  
      ;IF (x EQ -1) THEN BEGIN
        ;print, ' '
        ;return, error('FAILURE (CNTRD): ERROR in CNTRD: Check Companion initial position.')
        ;print, ' '
        ;ENDIF
        IF verbose THEN BEGIN
          APER, imgcub[*,*,i], P[0,0,i],P[1,0,i], flux, deltaflux, skyval, deltasky, 1, apr[i], [skyin[i], skyout[i]], /NAN, /EXACT, /FLUX
          print, ' '
          print, 'Aperture Photometry Settings: ', apr[i], skyin[i], skyout[i]
          print, ' '
        ENDIF ELSE BEGIN
          APER, imgcub[*,*,i], P[0,0,i],P[1,0,i], flux, deltaflux, skyval, deltasky, 1, apr[i], [skyin[i], skyout[i]], /NAN, /EXACT, /FLUX,/SILENT
        ENDELSE
        f0=flux
        d0=deltaflux
        s0=skyval
        ds0=deltasky
    
      ;CNTRD, imgcub[*,*,i],P[0,1,i],P[1,1,i], x, y,4 ;centroid of sat spot
      ;IF (x EQ -1) THEN BEGIN
      ; print, ' '
       ;return, error('FAILURE (CNTRD): ERROR in CNTRD: Check Companion initial position.')
       ;print, ' '
       ;ENDIF
       IF verbose THEN BEGIN
         APER, imgcub[*,*,i], P[0,1,i],P[1,1,i], flux, deltaflux, skyval, deltasky, 1,apr[i], [skyin[i], skyout[i]], /NAN, /EXACT, /FLUX
         print, ' '
         print, 'Aperture Photometry Settings: ', apr[i], skyin[i], skyout[i]
         print, ' '
       ENDIF ELSE BEGIN
         APER, imgcub[*,*,i], P[0,1,i],P[1,1,i], flux, deltaflux, skyval, deltasky, 1, apr[i], [skyin[i], skyout[i]], /NAN, /EXACT, /FLUX,/SILENT
       ENDELSE
       
       f1=flux
       d1=deltaflux
       s1=skyval
       ds1=deltasky
    
      ;CNTRD, imgcub[*,*,i],P[0,2,i],P[1,2,i], x, y,4 ;centroid of sat spot
      ;IF (x EQ -1) THEN BEGIN
      ; print, ' '
      ; return, error('FAILURE (CNTRD): ERROR in CNTRD: Check Companion initial position.')
      ; print, ' '
      ;ENDIF
      IF verbose THEN BEGIN
        APER, imgcub[*,*,i], P[0,2,i],P[1,2,i], flux, deltaflux, skyval, deltasky, 1, apr[i], [skyin[i], skyout[i]], /NAN, /EXACT, /FLUX
        print, ' '
        print, 'Aperture Photometry Settings: ', apr[i], skyin[i], skyout[i]
        print, ' '
      ENDIF ELSE BEGIN
        APER, imgcub[*,*,i], P[0,2,i],P[1,2,i], flux, deltaflux, skyval, deltasky, 1,apr[i], [skyin[i], skyout[i]], /NAN, /EXACT, /FLUX,/SILENT
      ENDELSE
      
      f2=flux
      d2=deltaflux
      s2=skyval
      ds2=deltasky
    
      ;CNTRD, imgcub[*,*,i],P[0,3,i],P[1,3,i], x, y,4 ;centroid of sat spot
      ;IF (x EQ -1) THEN BEGIN
      ;print, ' '
      ;return, error('FAILURE (CNTRD): ERROR in CNTRD: Check Companion initial position.')
      ;print, ' '
      ;ENDIF
      IF verbose THEN BEGIN
        APER, imgcub[*,*,i], P[0,3,i],P[1,3,i], flux, deltaflux, skyval, deltasky, 1, apr[i], [skyin[i], skyout[i]], /NAN, /EXACT, /FLUX
        print, ' '
        print, 'Aperture Photometry Settings: ', apr[i], skyin[i], skyout[i]
        print, ' '
      ENDIF ELSE BEGIN
        APER, imgcub[*,*,i], P[0,3,i],P[1,3,i], flux, deltaflux, skyval, deltasky, 1, apr[i], [skyin[i], skyout[i]], /NAN, /EXACT, /FLUX,/SILENT
      ENDELSE
      f3=flux
      d3=deltaflux
      s3=skyval
      ds3=deltasky
    
      fv=[f0,f1,f2,f3]
      dfv=[d0,d1,d2,d3]
      sv=[s0,s1,s2,s3]
      dsv=[ds0,ds1,ds2,ds3]
      
      F[i]=mean(fv)
      DF[i]=mean(dfv) 
      S[i]=mean(sv)
      DS[i]=mean(dsv)
      
      ENDFOR
      DATA=[[F], [DF], [S], [DS],[wavvect]]
      DATA=transpose(DATA)
      return, DATA
   
 end