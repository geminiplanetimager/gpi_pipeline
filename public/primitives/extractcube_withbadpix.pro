;+
; NAME: extractcube
; PIPELINE PRIMITIVE DESCRIPTION: Assemble Spectral Datacube (bp)
;
;         extract data cube from an image using spatial summation along the dispersion axis
;          introduced suffix '-spdc' (spectral data-cube)
;
;        This routine transforms a 2D detector image in the dataset.currframe input
;        structure into a 3D data cube in the dataset.currframe output structure.
;
;
; KEYWORDS:
; GEM/GPI KEYWORDS:IFSFILT
; OUTPUTS:
;
; PIPELINE COMMENT: Extract a 3D datacube from a 2D image taking account of the hot/cold pixel map (need to use also readbadpixmap with this primitive).
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-rawspdc" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE TYPE: ALL/SPEC
; PIPELINE NEWTYPE: SpectralScience
; PIPELINE SEQUENCE: 
;
; HISTORY:
;     Originally by Jerome Maire 2007-11
;   2008-04-02 JM: spatial summation window centered on pixel and interpolation on the zem. comm. wav. vector
;      2008-06-06 JM: adapted to pipeline inputs
;   2009-04-15 MDP: Documentation updated. 
;   2009-06-20 JM: adapted to wavcal input
;   2009-08-30 JM: take into acount bad-pixels
;   2009-09-17 JM: added DRF parameters
;   2012-10-18 MP: Code cleanup and debugging.
;-
function extractcube_withbadpix, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
     @__start_primitive

  det=*(dataset.currframe[0])

  ; This is completely wrong, don't do it.
;  ; check for positive intensities in detector frame
;  negvalue=where(det lt 0.,cneg)
;  if cneg gt 0 then begin 
;     print,'Found ',n_elements(negvalue), ' negative intensity(ies) in detector frame !'
;     print,'Force negative value(s) to be 0.'
;     det[where(det lt 0.)]=1e-8
;  endif
;
    nlens=(size(wavcal))[1]
    dim=(size(det))[1]
    filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
    if (filter eq '') then return, error('FAILURE ('+functionName+'): IFSFILT keyword not found.') 

    ;get length of spectrum
    sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)
    if (sdpx < 0) then return, error('FAILURE ('+functionName+'): Wavelength solution is bogus! All values are NaN.')
    
    ;get tilts of the spectra included in the wavelength solution:
    tilt=wavcal[*,*,4]

    cubef3D=dblarr(nlens,nlens,sdpx)


    ; Iterate for each spectral channel
    for i=0,sdpx-1 do begin  ;through spaxels

        cubef=dblarr(nlens,nlens)

        x3=xmini-i
        y3=wavcal[*,*,1]+(wavcal[*,*,0]-x3)*tan(tilt[*,*])    
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
        zeroif2nan=total([[[det_temp[y3,x3]*det_temp[y3+1,x3]]],[[det_temp[y3,x3]*det_temp[y3-1,x3]]],$
        [[det_temp[y3+1,x3]*det_temp[y3-1,x3]]] ],3,/nan)
        zeroif2nan[where(zeroif2nan ne 0.,cz)]=1.
        cubef=zeroif2nan*(det[y3,x3]+det[y3+1,x3]+det[y3-1,x3])

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

@__end_primitive
end

