;+
; NAME: gpi_find_badpixels
; PIPELINE PRIMITIVE DESCRIPTION: Find Bad pixels from flats
;
;
;
; KEYWORDS:
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: FILETYPE,ISCALIB
; OUTPUTS:
;
; PIPELINE COMMENT: Find Hot/cold pixels using flat-field images. find deviation which is nbdev times greater or lower than the estimated value of the pixel as if it was not hot/cold.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-badpix" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.3
; PIPELINE TYPE: CAL-SPEC
; PIPELINE SEQUENCE: 24-
;
; HISTORY:
;   2009-07-20 JM: created
;   2009-09-17 JM: added DRF parameters
;   2012-01-31 Switched sxaddpar and sxaddhist to backbone->set_keyword Dmitry Savransky
;-
function gpi_find_badpixels, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

;;find deviation which is nbdev times greater or lower than the estimated value of the pixel if it was not bad. 
nbdev=0.7
;;it is pretty difficult to find bad pix on edges of spectra due to the filter attenuation,
; conditions of detection are elevated.
;Use Flats with different filters to be sure to detect bad pixels located on edges of spectra  
nbdev0=27.
nbdev1=3.
nbdev17=2.  
nbdev18=18.
nbdevedge=[nbdev0,nbdev1,nbdev17,nbdev18]
  
  ; if numext eq 0 then h= *(dataset.headers)[numfile] else h= *(dataset.headersPHU)[numfile]
;h=*(dataset.headers[numfile])
filter = gpi_simplify_keyword_value(backbone->get_keyword('FILTER1', count=ct))
;if c4 eq 0 then filter=SXPAR( h, 'FILTER1',count=c4)
                    ;error handle if FILTER1 keyword not found
                    if (filter eq '') then $
                    return, error('FAILURE ('+functionName+'): FILTER1 keyword not found.') 
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect        
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]
;define length of detection boxes
case strcompress(filter,/REMOVE_ALL) of
  'Y': specpixlength=15. ; rough estimation of spec pix length
  'J': specpixlength=15. 
  'H': specpixlength=20. 
  'K1':specpixlength=21. 
  'K2': specpixlength=21. 
endcase

;;because of spectrum tilt, edge can appear in the middle of the detection box
; so we add a condition to assure that the detected bad pix is not an edge effect:
; for a suspected bad pix at a given wav, if mean flux at smaller wav is (isedge) lower than flux at greater wav
; then the flux attenuation of this pixel is probably  an edge effect and it will not be declared as a bad pix  
isedge=0.2

 det=*(dataset.currframe[0])

nlens=(size(wavcal))[1]
dim=(size(det))[1]

lambdamin=CommonWavVect[0]
lambdamax=CommonWavVect[1]

tilt=wavcal[*,*,4]
;what is the pixel corresponding to lambda_min?
xmini=(change_wavcal_lambdaref( wavcal, lambdamin))[*,*,0]
xminifind=where(finite(xmini))
;xmini(xminifind)=floor(xmini(xminifind))
;what is the pixel corresponding to lambda_max?
xmaxi=(change_wavcal_lambdaref( wavcal, lambdamax))[*,*,0]
;length of spectrum in pix
sdpx=max(ceil(abs(xmaxi-xmini)))+2
;print, 'spdx=',sdpx
; after the above, sdpx gives the length of the spectra in pixels.

;;define boxes of detection
cubef3D_top=dblarr(nlens,nlens,sdpx)
cubef3D_mid=dblarr(nlens,nlens,sdpx)
cubef3D_bot=dblarr(nlens,nlens,sdpx)
cubef3D_extratilt=dblarr(nlens,nlens,sdpx)
cubef3D_extratilt2=dblarr(nlens,nlens,sdpx)

;;define the kernel of convolution for estimation of non-badpixel flux
OPERATEUR=(1./3.)*(dblarr(3)+1.)

badpixmap=bytarr(2048,2048)
for xsi=0,nlens-1 do begin
print, 'Extract bad-pixels ..line#',xsi, '/',string(nlens-1)
  for ysi=0,nlens-1 do begin
    if finite(xmini[xsi,ysi]) then begin
 
      x3=floor(xmini[xsi,ysi])
      y3=round(wavcal[xsi,ysi,1]-(wavcal[xsi,ysi,0]-xmini[xsi,ysi])*tan(tilt[xsi,ysi]))
      if (x3+sdpx-1 le 2047) && (x3 ge 0) && (y3 ge 2) && (y3 le 2045) then begin
         cubef3D_top[xsi,ysi,*]=det[x3:x3+sdpx-1,y3+1]
         cubef3D_mid[xsi,ysi,*]=det[x3:x3+sdpx-1,y3]
         cubef3D_bot[xsi,ysi,*]=det[x3:x3+sdpx-1,y3-1] 
         cubef3D_extratilt[xsi,ysi,*]=det[x3:x3+sdpx-1,y3+round(tilt[xsi,ysi]/abs(tilt[xsi,ysi]))*2] 

      gpi_finddeviants, cubef3D_mid,xsi,ysi,badpixmap,nbdev,xmini,OPERATEUR,y3,nbdev0,nbdev1,nbdev17,nbdev18,isedge,specpixlength
      gpi_finddeviants, cubef3D_top,xsi,ysi,badpixmap,nbdev,xmini,OPERATEUR,y3+1,nbdev0,nbdev1,nbdev17,nbdev18,isedge,specpixlength
      gpi_finddeviants, cubef3D_bot,xsi,ysi,badpixmap,nbdev,xmini,OPERATEUR,y3-1,nbdev0,nbdev1,nbdev17,nbdev18,isedge,specpixlength
      gpi_finddeviants, cubef3D_extratilt,xsi,ysi,badpixmap,nbdev,xmini,OPERATEUR,y3+round(tilt[xsi,ysi]/abs(tilt[xsi,ysi]))*2,nbdev0,nbdev1,nbdev17,nbdev18,isedge,specpixlength
      gpi_finddeviants, cubef3D_extratilt2,xsi,ysi,badpixmap,nbdev,xmini,OPERATEUR,y3+round(tilt[xsi,ysi]/abs(tilt[xsi,ysi]))*3,nbdev0,nbdev1,nbdev17,nbdev18,isedge,specpixlength
     endif
    endif
  endfor
endfor
print, 'nb bad-pixels detected =', total(double(badpixmap))



  if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=Modules[thisModuleIndex].suffix else suffix='baxpix'

; FIXME: Update FITS header of the output file to specify that it's a bad pixel
; map. 
  ;sxaddhist, functionname+"from " + dataset.outputFileNames[numfile], *(dataset.headers[numfile])

backbone->set_keyword, "HISTORY", functionname+"from " + dataset.outputFileNames[numfile]
*(dataset.currframe[0])=badpixmap

	; Set keywords for outputting files into the Calibrations DB
;	 if numext eq 0 then begin
;    sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Bad Pixel Map", "What kind of IFS file is this?"
;    sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
;  endif else begin
;    sxaddpar, *(dataset.headersPHU[numfile]), "FILETYPE", "Bad Pixel Map", "What kind of IFS file is this?"
;    sxaddpar, *(dataset.headersPHU[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
;  endelse
    backbone->set_keyword, "FILETYPE", "Bad Pixel Map", "What kind of IFS file is this?"
    backbone->set_keyword,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'


@__end_primitive
;;		  thisModuleIndex = Backbone->GetCurrentModuleIndex()
;;		    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;;		      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;;		      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display,saveheader=*(dataset.headers[numfile]))
;;		      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;;		    endif else begin
;;		      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;;		          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
;;		    endelse
;;		
;;		
;;		
;;		return, ok
;;		
end

