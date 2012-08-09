pro ifs_cube_movie,fname,imdat=imdat,imnum=imnum,outname=outname,table=table,strtch=strtch,$
                   fps=fps,tottime=tottime,mpeg=mpeg,nolog=nolog,r=r,g=g,b=b,prescaled=prescaled,$
                   lambdas=lambdas
;+
; NAME:
;       ifs_cube_movie
; PURPOSE:
;       Animate moving through wavelength in IFS cube
;
; CALLING SEQUENCE:
;       tlc_move_source,fname|imdat=,imnum=,[options]
;
; INPUT/OUTPUT:
;       fname - Filename of cube (full path) or image cube
;       imdat,imnum - When working on 17-33, can specify these instead
;                     of fname to auto-generate filenames.  imdat is
;                     the directory date string (i.e., '120622') and
;                     imnum is the image number (i.e., 398)
;       outname - Optional name for output movie.  Otherwise, output
;                 name is auto-generated.
;       table - Color table (see loadct for details).  Defaults to 5
;               (standard gamma)
;       strtch - Top stretch of color space. (default to 1.5)
;       fps - Frames per slice.  Defaults to 5 (longer than that start
;             to look a bit choppy).
;       tottime - Total movie time in seconds.  Overrides fps setting.
;       /mpeg - make mpeg; defaults to animated gif
;       /nolog - linear stretch (defaults to log stretch)
;       r,g,b - Custom color tables (overrides table and strtch).
;       /nolog - Use linear stretch (defaults to log)
;       /prescaled - Don't change image scaling (overrides nolog)
;       lambdas - Array of wavelength values (in microns) to print on image
;
; OPTIONAL OUTPUT:
;       None.
;
; EXAMPLE:
;      ifs_cube_movie,imdat='061222',imnum=398
;      ifs_cube_movie,'/mnt/ifs/Reduced/120622/S20120622S0398-spdc.fits',outname='ifs_movie1.mpg'
;
; DEPENDENCIES:
;	None.
;
; NOTES: 
;             
; REVISION HISTORY
;       Written 06/28/2012. savransky1@llnl.gov
;       08.09.12 Partial rewrite to integrate with gpitv - ds
;-

;;assemble input &output filenames and check for existence
if keyword_set(imdat) and keyword_set(imnum) then $
  fname = '/mnt/ifs/Reduced/'+imdat+'/S20'+imdat+'S'+string(imnum,format='(I04)')+'-spdc.fits'
if n_elements(fname) eq 0 then begin 
    message,'No filename specified or cube given.',/continue 
    return 
endif

;;get the image
if size(fname,/type) ne 7 then im = fname else begin
    if not file_test(fname) then begin
        message,'File not found: ',fname,/continue
        return
    endif
    im = readfits(fname,/ext)
endelse 

;;assemble output name if needed
if not keyword_set(outname) then begin
    if size(fname,/type) eq 7 then $
      outname = strmid(fname,strpos(fname,'/',/reverse_search)+1,$
                       strpos(fname,'.fits')-strpos(fname,'/',/reverse_search)-1)+'-movie' $
    else outname = 'ifs_cube_movie' 
    if keyword_set(mpeg) then outname += '.mpg' else outname += '.gif'
endif

;;set frame rates and colors
if not keyword_set(fps) then fps = 5
if keyword_set(tottime) then fps = round(tottime*30./sz[2])
if not(keyword_set(r) and keyword_set(g) and keyword_set(b)) then begin
    if not keyword_set(table) then table = 5
    if not keyword_set(strtch) then strtch = 1.5
    LoadCT, 0 > table < 41, /Silent
    TVLCT, r, g, b, /Get
endif else strtch = 1.

;;crop to smallest frame size
if not keyword_set(prescaled) then $
   good = array_indices(im[*,*,0],where(im[*,*,0] eq im[*,*,0])) $
else good = array_indices(im[*,*,0],where(im[*,*,0] ne 0))
lim = [min(good[0,*]),max(good[0,*]),min(good[1,*]),max(good[1,*])]
im = im[lim[0]:lim[1],lim[2]:lim[3],*]

;;determine sizes (double image to make it easier to see features)
sz = size(im,/dim)
xs = sz[0]*2
ys = sz[1]*2

;;check for wavelength val vector
if keyword_set(lambdas) && n_elements(lambdas) ne sz[2] then begin
   message,'Wavelength value array is different size from image.  Wavelengths will not be printed.',/continue
   tmp = temporary(lambdas)
endif

;;set up zbuffer for wavelength text
if n_elements(lambdas) ne 0 then begin
   origDevice = !D.Name
   set_plot, 'Z', /COPY
   device,set_resolution=[xs,ys]
   erase
   mu = '!4' + string("154B) + '!Xm'  ;;" this is only here to stop emacs from freaking out
endif

;;set up mpeg if necessary
if keyword_set(mpeg) then begin
   mpegID = MPEG_Open([xs, ys], Filename=outname)
   image24 = BytArr(3, xs, ys)
endif

;;set up image vals
if not keyword_set(prescaled) then begin
   mn = min(im[where(im eq im)])
   mx = max(im[where(im eq im)])
   top = !D.table_size-1
   logtab = byte(round(alog10(indgen(top+1)+1)/alog10(top+1)*top))
endif else begin
   if size(im,/type) ne 1 then im = byte(im)
endelse

framecounter = 0
for j=0,sz[2]-1 do begin
   ;;rebin the image
   fim = rebin(im[*,*,j],xs,ys)
   
   ;;scale as necessary
   if not keyword_set(prescaled) then begin
      fim = bytscl(fim,mn,mx*strtch,top=top)
      if not keyword_set(nolog) then fim = logtab[fim]
   endif

   ;;write wavelength, if necessary
   if n_elements(lambdas) ne 0 then begin
      erase
      xyouts,0,0,strtrim(lambdas[j],2)+' '+mu,charsize=1.5
      snapshot = tvrd()
      inds = where(snapshot ne 0)
      fim[inds] = snapshot[inds]
   endif

   ;;write the frame
   if not keyword_set(mpeg) then begin
      if j ne sz[2]-1 then $
         write_gif,outname,fim,r,g,b,delay_time=fps/30.*100.,/multiple,repeat_count=0 $
      else $
         write_gif,outname,fim,r,g,b,delay_time=fps/30.*100.,/multiple,repeat_count=0,/close       
   endif else begin
      image24[0,*,*] = r(fim)
      image24[1,*,*] = g(fim)
      image24[2,*,*] = b(fim) 
      MPEG_Put, mpegID, Image=image24, Frame=framecounter
      framecounter += fps
   endelse
endfor

if keyword_set(mpeg) then begin
   MPEG_Save, mpegID
   MPEG_Close, mpegID
endif

if n_elements(lambdas) ne 0 then set_plot,origDevice

end

