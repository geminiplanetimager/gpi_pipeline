;+
; NAME: find_spectra_dispersions_quadrant
;find_spectra_dispersions_quadrant evaluate dispersion coeff and tilts with narrow band lamp image.
;find_spectra_dispersions_quadrant starts estimate the positions of the second peak in each spectrum.
;
; INPUTS, OUTPUTS:
;  quad: which quadrant to consider [1,2,3,4]
;  peakwavelen: wavelength of peaks that will be located
;  apprXpos0: approximate x-locations of these peaks
;  apprYpos:  approximate y-locations of these peaks
;  nlens: side length of lenslets matrix
;  w3: spectral spacing perpendicular to the dispersion axis at the detector in pixel
;  w3med: spectral spacing perpendicular to the dispersion axis at the detector in pixel
;  tilt: tilt angle between the lenslet array and the detector
;  specpos: 3D array where dispersion linear coefficients and tilt values are stored. 
;  im: The 2D detector image
;  wx,wy: define side box length (=2*wx+1) for (first) max detection 
;  hh: define side box length (=2*hh+1) for (second more accurate) centroid detection
;  szim: size of im
;  edge_x1,edge_x2,edge_y1,edge_y2: locations that define area to consider over im
;  dispeak,dispeak2:
;  tight_tilt: allowed tilt fluctuations for adjacent mlens
;
;
; HISTORY:
;    Jerome Maire 2008-10
;    2009-06 : JM put it in the form of a procedure
;    2009-12-10: JM: projected length of spectra as a function of tilts;
;    2009-12-10: JM: allowed fluctuations of tilt not greater than 2 degree (25 was too large)
;    2010-03-05: JM: allowed fluctuations of tilt in parameter (tight_tilt keyword)


pro find_spectra_dispersions_quadrant, quad,peakwavelen,apprXpos0,apprYpos,nlens,w3,w3med,tilt,specpos,im,wx,wy,hh,szim,edge_x1,edge_x2,edge_y1,edge_y2,dispeak,dispeak2,tight_tilt

case quad of 
  1: begin 
      jlim1=0 & jlim2=nlens/2-(1- (nlens mod 2)) & jdir=1 & ilim=nlens/2-(1- (nlens mod 2)) & idir=1 
      end
  2: begin 
      jlim1=0 & jlim2=nlens/2-(1- (nlens mod 2)) & jdir=1 & ilim=-nlens/2 & idir=-1 
      end
  3: begin 
      jlim1=-1 & jlim2=-nlens/2 & jdir=-1 & ilim=-nlens/2 & idir=-1 
     end
  4: begin 
      jlim1=-1 & jlim2=-nlens/2 & jdir=-1 & ilim=nlens/2-(1- (nlens mod 2)) & idir=1
     end
endcase

szdp=size(dispeak)
apprXpos=apprXpos0

tilt0=0.
tiltini=tilt0
;for each spectrum, (i,j) 
for j=jlim1,jlim2,jdir do begin
tilt0=tiltini
  for i=0,ilim,idir do begin
  ;if (quad eq 3)&&(j lt jlim1)  then print, 'pos:',specpos[nlens/2+i,nlens/2+j,0], specpos[nlens/2+i,nlens/2+j,1]
  ;if (quad eq 3) then stop
   inside=0
   ;if (nlens/2+i eq 23) && (nlens/2+j eq 97) then stop
    for p=1,n_elements(peakwavelen)-1 do begin ;for each peak in the spectrum
      if p eq 1 then  apprXpos[p]=apprXpos0[p]*cos(tilt0)
      if p gt 1 then  apprXpos[p]=apprXpos0[p]*cos(median(tilt[nlens/2+i,nlens/2+j,*]))
      
      if p eq 1 then  apprYpos[p]=apprXpos[p]*tan(tilt0)
      if p gt 1 then  apprYpos[p]=apprXpos[p]*tan(median(tilt[nlens/2+i,nlens/2+j,*]))
      ;;if this peak is in the raw image
      if (specpos[nlens/2+i,nlens/2+j,0]+apprXpos[p]-wx-hh ge edge_x1) && (ceil(specpos[nlens/2+i,nlens/2+j,0]+apprXpos[p]+wx+hh) le szim[1]-1-edge_x2)$
        && (specpos[nlens/2+i,nlens/2+j,1]+apprYpos[p]-wy-hh ge edge_y1) && (ceil(specpos[nlens/2+i,nlens/2+j,1]+apprYpos[p]+wy+hh) le szim[2]-1-edge_y2) then begin
        pospeak=localizepeak( im, specpos[nlens/2+i,nlens/2+j,0]+apprXpos[p],specpos[nlens/2+i,nlens/2+j,1]+apprYpos[p],wx,wy,hh)
        if szdp[0] gt 1 then begin
          dispeak[nlens/2+i,nlens/2+j,2*p]=pospeak[0]
          dispeak[nlens/2+i,nlens/2+j,2*p+1]=pospeak[1]
          ;dispeak2[nlens/2+i,nlens/2+j,p]=splinefwhm(im[pospeak[0]-2:pospeak[0]+2,pospeak[1]-2:pospeak[1]+2])
          ;dispeak2[nlens/2+i,nlens/2+j,p]=radplotfwhm(im,pospeak[0],pospeak[1])
          dispeak2[nlens/2+i,nlens/2+j,p]=gaussfwhm(im[pospeak[0]-5:pospeak[0]+5,pospeak[1]-5:pospeak[1]+5])
        endif
        tilt[nlens/2+i,nlens/2+j,p-1]=atan((pospeak[1]-specpos[nlens/2+i,nlens/2+j,1])/(pospeak[0]-specpos[nlens/2+i,nlens/2+j,0]))
          ;if i eq 0 then print, 'peak #', p, ' at pos', pospeak, ' tilt(deg)=', (180./!dpi)*tilt[nlens/2+i,nlens/2+j,p-1]
          ;;correct edge problem (and corner tilt pbm): assure fluctuations of tilt not greater than 2 degree between adjacent spectra
          if abs((180./!dpi)*(tilt[nlens/2+i,nlens/2+j,p-1] - tilt0)) gt double(tight_tilt) then tilt[nlens/2+i,nlens/2+j,p-1] = tilt0
          ;;dispersion law: lambda(um)=w3*(sqrt(dx^2+dy^2)) + w2
          w3[p-1]=(peakwavelen[p]-peakwavelen[0])/(sqrt((pospeak[0]-specpos[nlens/2+i,nlens/2+j,0])^2+(pospeak[1]-specpos[nlens/2+i,nlens/2+j,1])^2))
          ;w2(nlens/2+i,nlens/2+j,p-1)=peakwavelen(0)
            inside=1
      endif
    endfor
    ;keep only median values:
    tilt0=median(tilt[nlens/2+i,nlens/2+j,*])
    if finite(tilt0)&& (inside eq 1) then begin
      w3med[nlens/2+i,nlens/2+j]=median(w3)
;print, 'disp.law: coeff.dir=', w3,' med=',w3med(nlens/2+i,nlens/2+j)
      specpos[nlens/2+i,nlens/2+j,3]=median(w3)
      specpos[nlens/2+i,nlens/2+j,4]=tilt0
      ;;;for better apprYpos:
;      neighboortilt=[specpos[nlens/2+i,nlens/2+j,4],specpos[nlens/2+i,nlens/2+j-jdir,4],$
;                     specpos[nlens/2+i,nlens/2+j-2*jdir,4],specpos[nlens/2+i-1,nlens/2+j,4],$
;                     specpos[nlens/2+i-2,nlens/2+j,4],specpos[nlens/2+i-1,nlens/2+j-jdir,4],$
;                     specpos[nlens/2+i-2,nlens/2+j-jdir,4],specpos[nlens/2+i-1,nlens/2+j-2*jdir,4],$
;                     specpos[nlens/2+i-3,nlens/2+j,4],specpos[nlens/2+i,nlens/2+j-3*jdir,4]]
      neighboortilt=[specpos[((nlens/2+i>0)<(nlens-1)),((nlens/2+j>0)<(nlens-1)),4],$
                    specpos[((nlens/2+i>0)<(nlens-1)),((nlens/2+j-jdir>0)<(nlens-1)),4],$
                     specpos[((nlens/2+i>0)<(nlens-1)),((nlens/2+j-2*jdir>0)<(nlens-1)),4],$
                     specpos[((nlens/2+i-1>0)<(nlens-1)),((nlens/2+j>0)<(nlens-1)),4],$
                     specpos[((nlens/2+i-2>0)<(nlens-1)),((nlens/2+j>0)<(nlens-1)),4],$
                     specpos[((nlens/2+i-1>0)<(nlens-1)),((nlens/2+j-jdir>0)<(nlens-1)),4],$
                     specpos[((nlens/2+i-2>0)<(nlens-1)),((nlens/2+j-jdir>0)<(nlens-1)),4],$
                     specpos[((nlens/2+i-1>0)<(nlens-1)),((nlens/2+j-2*jdir>0)<(nlens-1)),4],$
                     specpos[((nlens/2+i-3>0)<(nlens-1)),((nlens/2+j>0)<(nlens-1)),4],$
                     specpos[((nlens/2+i>0)<(nlens-1)),((nlens/2+j-3*jdir>0)<(nlens-1)),4]]     
                     void=where(finite(neighboortilt),cf)      
                        
      if cf ne 0 then neighboortilt=neighboortilt[where(finite(neighboortilt))]
                    void=where(neighboortilt ne 0.,cz) 
      if cz ne 0 then neighboortilt=neighboortilt[where(neighboortilt ne 0.)]
      tilt0=median(neighboortilt)
    endif else begin
      tilt0=tiltini
    endelse
    if (i eq 0) then begin
        tiltini=tilt0
    endif
  endfor
endfor

end