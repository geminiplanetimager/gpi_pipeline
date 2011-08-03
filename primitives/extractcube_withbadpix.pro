;+
; NAME: extractcube
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Spectral Datacube (bp)
;
; 		extract data cube from an image using spatial summation along the dispersion axis
;		  introduced suffix '-spdc' (spectral data-cube)
;
;		This routine transforms a 2D detector image in the dataset.currframe input
;		structure into a 3D data cube in the dataset.currframe output structure.
;
;
; KEYWORDS:
; GEM/GPI KEYWORDS:FILTER1
; OUTPUTS:
;
; PIPELINE COMMENT: Extract a 3D datacube from a 2D image taking account of the hot/cold pixel map (need to use also readbadpixmap with this primitive).
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-rawspdc" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE TYPE: ALL/SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2007-11
;   2008-04-02 JM: spatial summation window centered on pixel and interpolation on the zem. comm. wav. vector
;	  2008-06-06 JM: adapted to pipeline inputs
;   2009-04-15 MDP: Documentation updated. 
;   2009-06-20 JM: adapted to wavcal input
;   2009-08-30 JM: take into acount bad-pixels
;   2009-09-17 JM: added DRF parameters
;+
function extractcube_withbadpix, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id$' ; get version from subversion to store in header history
     ;getmyname, functionname
     @__start_primitive

   ; save starting time
   T = systime(1)


 det=*(dataset.currframe[0])

; check for positive intensities in detector frame
    negvalue=where(det lt 0.,cneg)
    if cneg gt 0 then begin 
        print,'Found ',n_elements(negvalue), ' negative intensity(ies) in detector frame !'
        print,'Force negative value(s) to be 0.'
        det[where(det lt 0.)]=1e-8
    endif

nlens=(size(wavcal))[1]
dim=(size(det))[1]
       ; if numext eq 0 then header=*(dataset.headers)[numfile] else header=*(dataset.headersPHU)[numfile]
         filter = gpi_simplify_keyword_value(backbone->get_keyword('FILTER1', count=ct))
       ; if fcount eq 0 then filter = strcompress(sxpar( header ,'FILTER'),/REMOVE_ALL)
                    ;error handle if FILTER1 keyword not found
                    if (filter eq '') then $
                    return, error('FAILURE ('+functionName+'): FILTER1 keyword not found.') 
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect        
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]


tilt=wavcal[*,*,4]
;what is the pixel corresponding to lambda_min?
xmini=(change_wavcal_lambdaref( wavcal, lambdamin))[*,*,0]
xminifind=where(finite(xmini))
xmini(xminifind)=floor(xmini(xminifind))
;what is the pixel corresponding to lambda_max?
xmaxi=(change_wavcal_lambdaref( wavcal, lambdamax))[*,*,0]
;length of spectrum in pix
;sdpx=ceil(xmaxi(nlens/2,nlens/2))-xmini(nlens/2,nlens/2)+1
sdpx=max(ceil(xmaxi-xmini))+1 ;JM change 2009/08 sdpx is greater when spec are far from center
;print, 'spdx=',sdpx
; after the above, sdpx gives the length of the spectra in pixels.

cubef3D=dblarr(nlens,nlens,sdpx)

for i=0,sdpx-1 do begin  ;through spaxels

	cubef=dblarr(nlens,nlens)

	x3=xmini+i
  y3=wavcal[*,*,1]-(wavcal[*,*,0]-x3)*tan(tilt[*,*])	
	;cubef=det[x3,y3]+det[x3,y3+1]+det[x3,y3-1]

  bordx=where(~finite(x3),ccx)  
  bordy=where(~finite(y3),ccy)
  refpixwidth=4
  bordedge=[where(x3 ge dim-refpixwidth),where(x3 lt 0.+refpixwidth),where(y3 ge dim-refpixwidth),where(y3 lt 0.+refpixwidth)]
  ccedge=n_elements(bordedge)
  
  if (size(badpixmap))[0] eq 0 then badpixmap=bytarr(2048,2048)
;;force badpix as Nan
det_temp=det
indbadpix=where(badpixmap eq 1,nbbadpix)
if nbbadpix gt 0 then det_temp[indbadpix]=  !VALUES.F_NAN
  
;;test if only 1 (or0) badpix then sum, else put a 0. value
 zeroif2nan=total([[[det_temp[x3,y3]*det_temp[x3,y3+1]]],[[det_temp[x3,y3]*det_temp[x3,y3-1]]],$
 [[det_temp[x3,y3+1]*det_temp[x3,y3-1]]] ],3,/nan)
 zeroif2nan[where(zeroif2nan ne 0.,cz)]=1.
   cubef=zeroif2nan*(det[x3,y3]+det[x3,y3+1]+det[x3,y3-1])

;;put Nan value outside fov
  if (ccx ne 0) then cubef[bordx]=!VALUES.F_NAN
  if (ccy ne 0) then cubef[bordy]=!VALUES.F_NAN
  if (ccedge ne 0) then cubef[bordedge]=!VALUES.F_NAN

	cubef3D[*,*,i]=cubef

endfor

;;interpolate where 2 or 3 badpixs were in the sum box
ind2or3badpix=where(cubef3D eq 0.,cbp)
if cbp gt 0 then ind2or3badpix3D=array_indices(cubef3D,ind2or3badpix)
;cubef3D[ind2or3badpix]=interpolate(cubef3D, ind2or3badpix3D[0,*], ind2or3badpix3D[1,*],ind2or3badpix3D[2,*])

if n_elements(ind2or3badpix3D) gt 0 then begin
  for ii=0L, n_elements(ind2or3badpix)-1 do begin
     xmin=ind2or3badpix3D[0,ii]-1>0
     xmax=ind2or3badpix3D[0,ii]+1<(size(cubef3D))[1]-1
     ymin=ind2or3badpix3D[1,ii]-1>0
     ymax=ind2or3badpix3D[1,ii]+1<(size(cubef3D))[2]-1
     zmin=ind2or3badpix3D[2,ii]-1>0
     zmax=ind2or3badpix3D[2,ii]+1<(size(cubef3D))[3]-1
       cubef3D[ind2or3badpix[ii]]=(total(cubef3d[xmin:xmax,ymin:ymax,zmin:zmax],/nan,/double)-cubef3d[ind2or3badpix[ii]])/$
              double((n_elements(finite(cubef3d[xmin:xmax,ymin:ymax,zmin:zmax]))-1))
  endfor
endif 
 

*(dataset.currframe[0])=cubef3D

	thisModuleIndex = Backbone->GetCurrentModuleIndex()
 if tag_exist( Modules[thisModuleIndex], "Save") && $
 tag_exist( Modules[thisModuleIndex], "suffix") && $
 (uint(Modules[thisModuleIndex].save) eq 1 ) then suffix=Modules[thisModuleIndex].suffix
  
    if ( Modules[thisModuleIndex].Save eq 1 ) then begin
       b_Stat = save_currdata ( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=fix(Modules[thisModuleIndex].gpitv) )
       if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    end


return, ok

end

