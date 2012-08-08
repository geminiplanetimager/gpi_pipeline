pro ifs_cube_movie,fname,imdat=imdat,imnum=imnum,outname=outname,table=table,strtch=strtch,$
                   fps=fps,tottime=tottime,mpeg=mpeg,nolog=nolog,r=r,g=g,b=b,minmax=minmax
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
if not(keyword_set(r) and keyword_set(g) and keyword_set(b)) then begin
    if not keyword_set(table) then table = 5
    if not keyword_set(strtch) then strtch = 1.5
    LoadCT, 0 > table < 41, /Silent
    TVLCT, r, g, b, /Get
endif else strtch = 1.


;;crop to smallest frame size
good = array_indices(im[*,*,0],where(im[*,*,0] eq im[*,*,0]))
lim = [min(good[0,*]),max(good[0,*]),min(good[1,*]),max(good[1,*])]
im = im[lim[0]:lim[1],lim[2]:lim[3],*]

;;get rid of NANs
;im[where(im ne im)] = min(im[where(im eq im)])

;;determine sizes (double image to make it easier to see features)
sz = size(im,/dim)
xs = sz[0]*2
ys = sz[1]*2
if keyword_set(tottime) then fps = round(tottime*30./sz[2])

;;set up mpeg if necessary
if keyword_set(mpeg) then mpegID = MPEG_Open([xs, ys], Filename=outname)

;;set up image vals
image24 = BytArr(3, xs, ys)
top = !D.table_size-1
logtab = byte(round(alog10(indgen(top+1)+1)/alog10(top+1)*top))

if not keyword_set(minmax) then begin
    mn = min(im[where(im eq im)])
    mx = max(im[where(im eq im)])
endif else begin 
    mn = minmax[0]
    mx = minmax[1]
endelse

framecounter = 0
for j=0,sz[2]-1 do begin
    fim = bytscl(rebin(im[*,*,j],xs,ys),mn,mx*strtch,top=top)
    if not keyword_set(nolog) then fim = logtab[fim]
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

end

