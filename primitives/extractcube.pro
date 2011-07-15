;+
; NAME: extractcube
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Spectral Datacube
;
;		This routine transforms a 2D detector image in the dataset.currframe input
;		structure into a 3D data cube in the dataset.currframe output structure.
;   This routine extracts data cube from an image using spatial summation along the dispersion axis
;     introduced suffix '-rawspdc' (raw spectral data-cube)
;
; KEYWORDS: 
; GEM/GPI KEYWORDS:FILTER1
; OUTPUTS:
;
; PIPELINE COMMENT: Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-rawspdc" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE TYPE: ALL-SPEC
;
; HISTORY:
; 	Originally by Jerome Maire 2007-11
;   2008-04-02 JM: spatial summation window centered on pixel and interpolation on the zem. comm. wav. vector
;	  2008-06-06 JM: adapted to pipeline inputs
;   2009-04-15 MDP: Documentation updated. 
;   2009-06-20 JM: adapted to wavcal input
;   2009-09-17 JM: added DRF parameters
;+
function extractcube, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS


primitive_version= '$Id$' ; get version from subversion to store in header history
  ; getmyname, functionname
  @__start_primitive

   ; save starting time
   T = systime(1)

    ;get the 2D detector image
    det=*(dataset.currframe[0])

    nlens=(size(wavcal))[1]  ;pixel sidelength of final datacube (spatial dimensions) 
    dim=(size(det))[1]    ;detector sidelength in pixels

            ;error handle if readwavcal or not used before
            if (nlens eq 0) || (dim eq 0)  then $
            return, error('FAILURE ('+functionName+'): Failed to load data.') 
            
            
        ;define the common wavelength vector with te FILTER1 keyword:
        header=*(dataset.headers)[numfile]
        filter = strcompress(sxpar( header ,'FILTER1', count=fcount),/REMOVE_ALL)
        if fcount eq 0 then filter = strcompress(sxpar( header ,'FILTER'),/REMOVE_ALL)
                    ;error handle if FILTER1 keyword not found
                    if (filter eq '') then $
                    return, error('FAILURE ('+functionName+'): FILTER1 keyword not found.') 
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect        
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]

    ;get tilts of the spectra included in the wavelength solution:
    tilt=wavcal[*,*,4]
    ;what is the pixel corresponding to lambda_min?
    xmini=(change_wavcal_lambdaref( wavcal, lambdamin))[*,*,0]
    xminifind=where(finite(xmini), wct)
	if wct eq 0 then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')
    xmini(xminifind)=floor(xmini(xminifind))
    ;what is the pixel corresponding to lambda_max?
    xmaxi=(change_wavcal_lambdaref( wavcal, lambdamax))[*,*,0]
    ;length of spectrum in pix
    ;sdpx=ceil(xmaxi(nlens/2,nlens/2))-xmini(nlens/2,nlens/2)+1
    sdpx=max(ceil(xmaxi-xmini))+1 ;JM change 2009/08, from zemax sim, sdpx is greater when spec are far from center
    ;print, 'spdx=',sdpx
    ; after the above, sdpx gives the length of the spectra in pixels.

cubef3D=dblarr(nlens,nlens,sdpx) ;create the datacube

for i=0,sdpx-1 do begin  ;through spaxels

	cubef=dblarr(nlens,nlens) 
  ;get the locations on the image where intensities will be extracted:
	x3=xmini+i
  y3=wavcal[*,*,1]-(wavcal[*,*,0]-x3)*tan(tilt[*,*])	
  ;extract intensities on a 3x1 box:
	cubef=det[x3,y3]+det[x3,y3+1]+det[x3,y3-1]

  ;declare as Nan mlens not on the detector:
  bordx=where(~finite(x3),cc)
  if (cc ne 0) then cubef[bordx]=!VALUES.F_NAN
  bordy=where(~finite(y3),cc)
  if (cc ne 0) then cubef[bordy]=!VALUES.F_NAN

	cubef3D[*,*,i]=cubef

endfor

suffix='-spdc'
; put the datacube in the dataset.currframe output structure:
*(dataset.currframe[0])=cubef3D

;save if asked and handle error if save function failed:
  ;thisModuleIndex = Backbone->GetCurrentModuleIndex()
 ;if tag_exist( Modules[thisModuleIndex], "Save") && $
 ;tag_exist( Modules[thisModuleIndex], "suffix") && $
 ;(uint(Modules[thisModuleIndex].save) eq 1 ) then suffix=Modules[thisModuleIndex].suffix
 
;
    ;if ( Modules[thisModuleIndex].Save eq 1 ) then begin
       ;b_Stat = save_currdata ( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=fix(Modules[thisModuleIndex].gpitv) )
       ;if ( b_Stat ne OK ) then  return, error('FAILURE ('+functionName+'): Failed to save dataset.')
    ;end


;return, ok
@__end_primitive

end

