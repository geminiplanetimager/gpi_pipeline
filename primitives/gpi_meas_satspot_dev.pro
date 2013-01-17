;+
; NAME: gpi_meas_satspot_dev
; PIPELINE PRIMITIVE DESCRIPTION: Plot the satellite spot locations vs. the expected location from wavelength scaling
;
; INPUTS: 
;
; KEYWORDS:
; 	
;
; OUTPUTS: 
; 	Plot of results.
;
; 
;
; PIPELINE COMMENT: Measured vs. wavelength scaled sat spot locations
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[-1,100]" Default="0" Desc="Window number to display in.  -1 for no display."
; PIPELINE ARGUMENT: Name="SaveData" Type="string" Default="" Desc="Save data to filename (blank for no save)"
; PIPELINE ARGUMENT: Name="SavePNG" Type="string" Default="" Desc="Save plot to filename as PNG(blank for no save)"
; PIPELINE ORDER: 2.7
; PIPELINE NEWTYPE: SpectralScience,PolarimetricScience
; PIPELINE TYPE: ALL
;
; HISTORY:
; 	written 12/11/2012 - ds
;-
function gpi_meas_satspot_dev, DataSet, Modules, Backbone

primitive_version= '$Id: gpi_meas_satspot_dev.pro 1060 2012-12-10 23:39:47Z Dmitry $' ; get version from subversion to store in header history
@__start_primitive

cube = *(dataset.currframe[0])
band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
;;error handle if extractcube not used before
if ((size(cube))[0] ne 3) || (strlen(band) eq 0)  then $
   return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use "Assemble Datacube" before this one.')   
cwv = get_cwv(band,spectralchannels=(size(cube,/dim))[2])
lambda = cwv.lambda

;;error handle if sat spots haven't been found
tmp = backbone->get_keyword("SATSMASK", ext_num=1, count=ct)
if ct eq 0 then $
   return, error('FAILURE ('+functionName+'): SATSMASK undefined.  Use "Measure satellite spot locations" before this one.')

;;grab satspots 
goodcode = hex2bin(tmp,(size(cube,/dim))[2])
good = long(where(goodcode eq 1))
cens = fltarr(2,4,(size(cube,/dim))[2])
for s=0,n_elements(good) - 1 do begin 
   for j = 0,3 do begin 
      tmp = fltarr(2) + !values.f_nan 
      reads,backbone->get_keyword('SATS'+strtrim(long(good[s]),2)+'_'+strtrim(j,2),ext_num=1),tmp,format='(F7," ",F7)' 
      cens[*,j,good[s]] = tmp 
   endfor 
endfor

;;compute distancesbetween spots
dists = sqrt(total((cens[*,[0,0,0,1,1,2],*] - cens[*,[1,2,3,2,3,3],*])^2d,1))
legs = fltarr((size(cube,/dim))[2])
for j=0,n_elements(legs) - 1 do $
   legs[j] = mean((dists[sort(dists[*,j]),j])[0:3])

;;least squares fit to leg
A = [[fltarr(n_elements(legs),1)+1],[lambda]]
bm = (invert(transpose(A) # A) # transpose(A)) # legs
legsfit = bm[0]+bm[1]*lambda
tmp = round(n_elements(legs)/2.)
legsscaled = legs[tmp]*lambda/lambda[tmp]

;;get user inputs
wind = fix(Modules[thisModuleIndex].Display)
datasave = Modules[thisModuleIndex].SaveData
pngsave = Modules[thisModuleIndex].SavePNG

;;plot
if (wind ne -1) || (pngsave ne '') then begin
   
   if wind ne -1 then window,wind,xsize=800,ysize=600,retain=2 else begin
      odevice = !D.NAME
      set_plot,'Z',/copy
      device,set_resolution=[800,600],z_buffer = 0
      erase
   endelse
   mu = '!4' + string("154B) + '!Xm'  ;;" this is only here to stop emacs from freaking out
   plot,/nodata,[min(lambda),max(lambda)],[min([legs,legsfit,legsscaled]),max([legs,legsfit,legsscaled])],$
        charsize=1.5, Background=cgcolor('white'), Color=cgcolor('black'),$
        xtitle='Wavelength ('+mu+')',ytitle='Sat. Spot Distance From Center (pix)',/ystyle
   oplot,lambda,legs,color=cgcolor('red'),psym=2
   oplot,lambda,legs,color=cgcolor('red')
   oplot,lambda,legsfit,color=cgcolor('dark green'),linestyle=2
   oplot,lambda,legsscaled,color=cgcolor('blue')
   
   if pngsave ne '' then begin
      if wind eq -1 then begin
         snapshot = tvrd()
         tvlct,r,g,b,/get
         write_png,pngsave,snapshot,r,g,b
         device,z_buffer = 1
         set_plot,odevice
      endif else write_png,pngsave,tvrd(true=1)
   endif
endif

;;save values as fits
if datasave ne '' then begin
   out = dblarr(n_elements(lambda), 4)
   out[*,0] = lambda
   out[*,1] = legs
   out[*,2] = legsfit
   out[*,3] = legsscaled

   mkhdr,hdr,out
   sxaddpar,hdr,'COMMENT','Cols. are: wavelength (um), measured dist, least squares fit, 
   sxaddpar,hdr,'COMMENT','and scaled from central wavelength.'
   
   writefits,datasave,out,hdr
endif

@__end_primitive 


end
