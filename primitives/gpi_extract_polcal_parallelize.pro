;+
; NAME: gpi_extract_polcal
; PIPELINE PRIMITIVE DESCRIPTION: Measure Polarization Spot Calibration (parallelized)
;
;    gpi_extract_polcal detects the positions of the polarized spots in a 2D
;    image based on flat field observations. 
;
; ALGORITHM:
;    gpi_extract_polcal starts by detecting the central peak of the image.
;    Next, starting with a initial value of w & P, it finds the nearest peak (with an increment on the microlens coordinates)
;    when nearest peak has been detected, it reevaluates w & P and so forth..
;
;    ; TODO modify to deal with the 2nd polarization...
;
;
; INPUTS: 2D image from flat field  in polarization mode
;
; KEYWORDS:
; GEM/GPI KEYWORDS:DISPERSR,FILTER,IFSFILT,FILTER2,OBSTYPE
; DRP KEYWORDS: FILETYPE,ISCALIB
; OUTPUTS:
;
; PIPELINE ORDER: 1.8
; PIPELINE ARGUMENT: Name="nlens" Type="int" Range="[0,400]" Default="281" Desc="side length of  the  lenslet array "
; PIPELINE ARGUMENT: Name="centrXpos" Type="int" Range="[0,2048]" Default="1024" Desc="Initial approximate x-position [pixel] of central peak at 1.5microns"
; PIPELINE ARGUMENT: Name="centrYpos" Type="int" Range="[0,2048]" Default="1024" Desc="Initial approximate y-position [pixel] of central peak at 1.5microns"
; PIPELINE ARGUMENT: Name="w" Type="float" Range="[0.,10.]" Default="4.8" Desc="Spectral spacing perpendicular to the dispersion axis at the detcetor in pixel"
; PIPELINE ARGUMENT: Name="P" Type="float" Range="[-7.,7.]" Default="-1.8" Desc="Micro-pupil pattern"
; PIPELINE ARGUMENT: Name="maxpos" Type="float" Range="[-7.,7.]" Default="2.5" Desc="Allowed maximum location fluctuation (in pixel) between adjacent mlens"
; PIPELINE ARGUMENT: Name="FitWidth" Type="float" Range="[-10.,10.]" Default="3" Desc="Size of box around a spot used to find center"

; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1"
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[0,1]" Default="1"
; PIPELINE COMMENT: Derive polarization calibration files from a flat field image.
; PIPELINE NEWTYPE: Calibration
; PIPELINE TYPE: CALIBRATION/POL
; PIPELINE SEQUENCE: 1-
;
; HISTORY:
;     2009-06-17: Started, based on gpi_extract_wavcal - Marshall Perrin 
;   2009-09-17 JM: added DRF parameters
;   2013-01-28 MMB: added some keywords to pass to find_pol_positions_quadrant
;-

function gpi_extract_polcal_parallelize,  DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

    im=*(dataset.currframe[0]) 
    
    ;if numext eq 0 then h= *(dataset.headers)[numfile] else h= *(dataset.headersPHU)[numfile]
   ; h=header
    obstype=backbone->get_keyword('OBSTYPE')
	bandeobs=gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
	mode=backbone->get_keyword('DISPERSR', count=ct)
    ;obstype=SXPAR( h, 'OBSTYPE')
    ;bandeobs=SXPAR( h, 'FILTER', count=ct)
    ;if ct eq 0 then bandeobs= sxpar(h,'IFSFILT')

       ; TODO verify image is a POL mode FLAT FIELD. 
    ;mode = sxpar(h,'prism', count=ct)
    ;if ct eq 0 then disp = sxpar(h,'DISPERSR')
    ;if ct eq 0 then disp = sxpar(h,'FILTER2')


    if ~strmatch(mode,'*wollaston*',/fold_case)  then return, error('FAILURE ('+functionName+'): Invalid input -- a POLARIMETRY mode file is required.') 
    if(~strmatch(obstype,'*arc*',/fold_case)) && (~strmatch(obstype,'*flat*',/fold_case)) then $
        return, error('FAILURE ('+functionName+'): Invalid input -- The OBSTYPE keyword does not mark this data as a FLAT or ARC image.') 
    

    ;if (size(im))[0] eq 0 then im=readfits(filename,h)
    szim=size(im)


    ; version 1 sketch: We model each peak as a 2D rotated Gaussian. 
    ;
    ; for each peak, we store
    ; 0: x position of the peak center
    ; 1: y position of the peak center
    ; 2: rotation angle
    ; 3: outer radius to use (25% max? ) in X, rotated
    ; 4: outer radius to use (25% max? ) in Y, rotated
    ;
    ; and the last dimension is for the polarization.
    ;
    ; NOTE: The code to do the above is NOT yet implemented - only the first 2
    ; quantities are stored right now!
    ;
    ; version 2 sketch: Weighted optimal extraction of each pixel. 
    ;     TBD later. See notes in extractpol.pro
    
    
    nlens=uint(Modules[thisModuleIndex].nlens)
    
    ; Create the SPOTPOS array, which stores the Gaussian-fit 
    ; spot locations. 
    ;
    ; NOTE: spotpos dimensions re-arranged relative to spectral version
    ; for better speed. And to add pol dimension of course.
    spotpos=dblarr(5,nlens,nlens,2)+!VALUES.D_NAN
    nspot_pixels=45  ; NOTE: this **MUST** match the nspot_pixels value in
					 ; find_pol_positions_quadrant.pro
    ; Now create the PIXELS and PIXVALS arrays, which store the actual
    ; X,Y, and values for each pixel, that we can use for optimal extraction
    spotpos_pixels = intarr(2,nspot_pixels, nlens, nlens, 2)
    spotpos_pixvals = dblarr(nspot_pixels, nlens, nlens, 2)+!values.f_nan
    
    ;localize central peak around the center of the image
    cen1=dblarr(2)    & cen1[0]=-1 & cen1[1]=-1
    wx=5 & wy=0
    hh=1.
    ;localize first peak ;; this coordiantes depends strongly on data!!
    cenx=float(Modules[thisModuleIndex].centrXpos)
    ceny=float(Modules[thisModuleIndex].centrYpos)
    ;  cenx=szim[1]/2.
    ;  ceny=szim[2]/2.
    
    while (~finite(cen1[0])) || (~finite(cen1[1])) || $
            (cen1[0] lt 0) || (cen1[0] gt (size(im))[1]) || $
            (cen1[1] lt 0) || (cen1[1] gt (size(im))[1])  do begin
        wx+=1 & wy+=1
        cen1=localizepeak( im, cenx, ceny,wx,wy,hh)
        print, 'Center peak detected at pos:',cen1
    endwhile
    spotpos[0:1,nlens/2,nlens/2,0]=cen1
    
    
    ;;micro-lens basis
    idx=(findgen(nlens)-(nlens-1)/2)#replicate(1l,nlens)
    jdy=replicate(1l,nlens)#(findgen(nlens)-(nlens-1)/2)
    ;  dx=idx*W*P+jdy*W
    ;  dy=jdy*W*P-W*idx
    
    wx=1. & wy=1.
    hh=1. ; box for fit
    wcst=float(Modules[thisModuleIndex].w) & Pcst=float(Modules[thisModuleIndex].P)
    ;wcst=4.8 & Pcst=-1.8
    

    tight_pos=float(Modules[thisModuleIndex].maxpos) 
    boxwidth=float(Modules[thisModuleIndex].fitwidth)
     

	sz = size(spotpos) & shmmap, "GPIDRP_spotpos", sz[1],sz[2], sz[3], sz[4],/float & shared_spotpos = shmvar("GPIDRP_spotpos") & shared_spotpos[*]=spotpos
	sz = size(spotpos_pixels) & shmmap, "GPIDRP_spotpos_pixels", sz[1],sz[2],sz[3], sz[4],sz[5],/int & shared_spotpos_pixels = shmvar("GPIDRP_spotpos_pixels") & shared_spotpos_pixels[*]=spotpos_pixels
	sz = size(spotpos_pixvals) & shmmap, "GPIDRP_spotpos_pixvals", sz[1],sz[2], sz[3],sz[4],/float & shared_spotpos_pixvals = shmvar("GPIDRP_spotpos_pixvals") & shared_spotpos_pixvals[*]=spotpos_pixvals

	nbparallel = 4 ; always 4 quadrants
	bridges = ptrarr(nbparallel)
	for ipar=0L,nbparallel-1 do begin
		; create new IDL session and initialize the necessary variables
		; there.
		bridges[ipar] = ptr_new(obj_new('IDL_IDLBridge'))
		(*bridges[ipar])->Setvar,'quadrant', ipar+1

		(*bridges[ipar])->Setvar,'wcst', wcst
		(*bridges[ipar])->Setvar,'pcst', pcst
		(*bridges[ipar])->Setvar,'nlens', nlens
		(*bridges[ipar])->Setvar,'idx', idx
		(*bridges[ipar])->Setvar,'jdy', jdy
		(*bridges[ipar])->Setvar,'cen1', cen1
		(*bridges[ipar])->Setvar,'wx', wx
		(*bridges[ipar])->Setvar,'wy', wy
		(*bridges[ipar])->Setvar,'hh', hh
		(*bridges[ipar])->Setvar,'szim', szim
		
		; TODO allocate and access the shared memory segments in the remote
		; session
		
		; TODO run a quadrant of  find_pol_positions_quadrant in the remote
		; session
		
		; The above should automatically write the output into the shared memory, I think,
		; if we've done it right? 

	endfor


    
    
    for quadrant=1L,4 do find_pol_positions_quadrant, quadrant,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,spotpos,im, spotpos_pixels, spotpos_pixvals, display=display_flag, badpixmap=badpixmap
    
        ; now keep looping and wait for them all to finish
        going = 1
        stats =intarr(nbparallel)
        while (going) do begin
            for ipar=0L,nbparallel-1 do stats[ipar] = (*bridges[ipar])->Status()
            if total(stats) eq 0 then going=0
            print,"Parallel calculation still running... "+strc(fix(total(stats)))+"/"+strc(nbparallel)+" threads executing.",/erase
            wait, 3
        endwhile
        message,/info, "Parallel computation done!"
 
    suffix="-"+strcompress(bandeobs,/REMOVE_ALL)+'-polcal'
    ;fname=strmid(filename,0,STRLEN(filename)-6)+suffix+'.fits'
    fname = file_basename(filename, ".fits")+suffix+'.fits'
    
    ; Set keywords for outputting files into the Calibrations DB
    backbone->set_keyword, "FILETYPE", "Polarimetry Spots Cal File"
    backbone->set_keyword,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
    
	backbone->set_keyword, "HISTORY", "      ",ext_num=0
    backbone->set_keyword, "HISTORY", " Pol Calib File Format:",ext_num=0
    backbone->set_keyword, "HISTORY", "    Axis 1:  pos_x, pos_y, rotangle, width_x, width_y",ext_num=0
    backbone->set_keyword, "HISTORY", "       rotangle is in degrees, widths in pixels",ext_num=0
    backbone->set_keyword, "HISTORY", "    Axis 2:  Lenslet X",ext_num=0
    backbone->set_keyword, "HISTORY", "    Axis 3:  Lenslet Y",ext_num=0
    backbone->set_keyword, "HISTORY", "    Axis 4:  Polarization ( -- or | ) ",ext_num=0
	backbone->set_keyword, "HISTORY", "      ",ext_num=0
    
    
    

;@__end_primitive
; - NO - 
; due to special output requirements (outputting pixels lists, not anything in
; the *dataset.currframe structure as usual)
; we can't use the standardized template end-of-procedure file saving code here.
; Instead do it this way: 

if ( Modules[thisModuleIndex].Save eq 1 ) then begin
	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=0 ,$
		   savedata=spotpos,  output_filename=out_filename)
    if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')

    writefits, out_filename, spotpos_pixels, /append
    writefits, out_filename, spotpos_pixvals, /append
end

*(dataset.currframe[0])=spotpos
if tag_exist( Modules[thisModuleIndex], "stopidl") then if keyword_set( Modules[thisModuleIndex].stopidl) then stop

return, ok

end
