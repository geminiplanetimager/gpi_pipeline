;+
; NAME: gpi_parallelized_polarization_spot_calibration
; PIPELINE PRIMITIVE DESCRIPTION: Parallelized Polarization Spot Calibration
;
;   This is a parallelized version of the polarization spot algorithm.
;   The normal version is in gpi_measure_polarization_spot_calibration
;
;    detects the positions of the polarized spots in a 2D
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
; PIPELINE COMMENT: Derive polarization calibration files from a flat field image.
; PIPELINE ARGUMENT: Name="nlens" Type="int" Range="[0,400]" Default="281" Desc="side length of  the  lenslet array "
; PIPELINE ARGUMENT: Name="centrXpos" Type="int" Range="[0,2048]" Default="1078" Desc="Initial approximate x-position [pixel] of central peak at 1.5microns"
; PIPELINE ARGUMENT: Name="centrYpos" Type="int" Range="[0,2048]" Default="1028" Desc="Initial approximate y-position [pixel] of central peak at 1.5microns"
; PIPELINE ARGUMENT: Name="w" Type="float" Range="[0.,10.]" Default="4.4" Desc="Spectral spacing perpendicular to the dispersion axis at the detcetor in pixel"
; PIPELINE ARGUMENT: Name="P" Type="float" Range="[-7.,7.]" Default="2.18" Desc="Micro-pupil pattern"
; PIPELINE ARGUMENT: Name="maxpos" Type="float" Range="[-7.,7.]" Default="2.5" Desc="Allowed maximum location fluctuation (in pixel) between adjacent mlens"
; PIPELINE ARGUMENT: Name="FitWidth" Type="float" Range="[-10.,10.]" Default="3" Desc="Size of box around a spot used to find center"
;
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1"
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[0,1]" Default="1"
; PIPELINE ORDER: 1.8
; PIPELINE CATEGORY: Testing
;
; HISTORY:
;   2009-06-17: Started, based on gpi_extract_wavcal - Marshall Perrin 
;   2009-09-17 JM: added DRF parameters
;   2013-01-28 MMB: added some keywords to pass to find_pol_positions_quadrant
;   2013-07-17 MP: Renamed for consistency
;   2013-10-31 MMB: Big update, 
;-

function gpi_parallelized_polarization_spot_calibration,  DataSet, Modules, Backbone

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

    ;DONE -  TODO verify image is a POL mode FLAT FIELD.  - DONE (copied from gpi_measure_polarization_spot_calibration.pro - the single thread version)
    ;mode = sxpar(h,'prism', count=ct)
    ;if ct eq 0 then disp = sxpar(h,'DISPERSR')
    ;if ct eq 0 then disp = sxpar(h,'FILTER2')(

    ; verify image is a POL mode FLAT FIELD. 
    if ~strmatch(mode,'*wollaston*',/fold_case)  then return, error('FAILURE ('+functionName+'): Invalid input -- a POLARIMETRY mode file is required.') 
    if(~strmatch(obstype,'*arc*',/fold_case)) && (~strmatch(obstype,'*flat*',/fold_case)) then $
        return, error('FAILURE ('+functionName+'): Invalid input -- The OBSTYPE keyword does not mark this data as a FLAT or ARC image.') 

    ;if (size(im))[0] eq 0 then im=readfits(filename,h)
    szim=size(im)

    szbp=size(badpixmap)
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
    nspot_pixels=45  ; NOTE: this **MUST** match the nspot_pixels value in
           ; find_pol_positions_quadrant.pro
    
    
    ; Setting up the shared memory
    shmmap, 'spotpos', /double, 5,nlens,nlens,2
;    shmmap, 'spotpos', /double, 6,nlens,nlens,2
    shmmap, 'spotpos_pixels', /integer, 2, nspot_pixels,nlens,nlens,2
    shmmap, 'spotpos_pixvals', /double, nspot_pixels,nlens,nlens,2
    shmmap, 'imshr',type=szim[0], szim[1],szim[2] ;2d array
    shmmap, 'bpshr', type=szbp[0], szbp[1],szbp[2] 
    
    spotpos=shmvar('spotpos')
    spotpos_pixels=shmvar('spotpos_pixels')
    spotpos_pixvals=shmvar('spotpos_pixvals')
    imshr=shmvar('imshr')
    bpshr=shmvar('bpshr')
    
    spotpos[*]+=!values.d_nan
    spotpos_pixvals[*]+=!values.f_nan
    imshr[0,0]=im
    
    
    bpshr[0,0]=badpixmap
    
    ; Create the SPOTPOS array, which stores the Gaussian-fit 
    ; spot locations. 
    ;
    ; NOTE: spotpos dimensions re-arranged relative to spectral version
    ; for better speed. And to add pol dimension of course.
    ;spotpos[0,0,0,0]=dblarr(5,nlens,nlens,2)+!VALUES.D_NAN
    
    ; Now create the PIXELS and PIXVALS arrays, which store the actual
    ; X,Y, and values for each pixel, that we can use for optimal extraction
    ;spotpos_pixels[0,0,0,0,0] = intarr(2,nspot_pixels, nlens, nlens, 2)
    ;spotpos_pixvals[0,0,0,0,0] = dblarr(nspot_pixels, nlens, nlens, 2)+!values.f_nan
    
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
        cen1=localizepeak( im, cenx, ceny,wx,wy,hh, meth=gaussfit)
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
     

	;sz = size(spotpos) & shmmap, "GPIDRP_spotpos", sz[1],sz[2], sz[3], sz[4],/float & shared_spotpos = shmvar("GPIDRP_spotpos") & shared_spotpos[*]=spotpos
	;sz = size(spotpos_pixels) & shmmap, "GPIDRP_spotpos_pixels", sz[1],sz[2],sz[3], sz[4],sz[5],/int & shared_spotpos_pixels = shmvar("GPIDRP_spotpos_pixels") & shared_spotpos_pixels[*]=spotpos_pixels
	;sz = size(spotpos_pixvals) & shmmap, "GPIDRP_spotpos_pixvals", sz[1],sz[2], sz[3],sz[4],/float & shared_spotpos_pixvals = shmvar("GPIDRP_spotpos_pixvals") & shared_spotpos_pixvals[*]=spotpos_pixvals

	nbparallel = 4 ; always 4 quadrants
	bridges = ptrarr(nbparallel)
	
	t0=Systime(/Seconds)
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
		(*bridges[ipar])->Setvar,'tight_pos', tight_pos
		(*bridges[ipar])->Setvar,'boxwidth', boxwidth
		(*bridges[ipar])->Setvar,'im', im
		;(*bridges[ipar])->Setvar,'display_flag', display_flag
		
		(*bridges[ipar])->Execute, "SHMMap, 'spotpos', /double, 5,"+string(nlens)+","+string(nlens)+",2"
;		(*bridges[ipar])->Execute, "SHMMap, 'spotpos', /double, 6,"+string(nlens)+","+string(nlens)+",2"
		(*bridges[ipar])->Execute, "SHMMap, 'spotpos_pixels', /integer, 2,"+string(nspot_pixels)+","+string(nlens)+","+string(nlens)+",2"
		(*bridges[ipar])->Execute, "SHMMap, 'spotpos_pixvals', /double,"+string(nspot_pixels)+","+string(nlens)+","+string(nlens)+",2"
		;(*bridges[ipar])->Execute, "SHMMap, 'imshr', type="+string(szim[0])+","+string(szim[1])+","+string(szim[2])
		(*bridges[ipar])->Execute, "SHMMap, 'bpshr', type="+string(szbp[0])+","+string(szbp[1])+","+string(szbp[2])
		
		
		(*bridges[ipar])->Execute, "spotpos=shmvar('spotpos')"
		(*bridges[ipar])->Execute, "spotpos_pixels=shmvar('spotpos_pixels')"
		(*bridges[ipar])->Execute, "spotpos_pixvals=shmvar('spotpos_pixvals')"
		;(*bridges[ipar])->Execute, "im=shmvar('imshr')"
		;(*bridges[ipar])->Execute, ";=shmvar('imshr')"
		(*bridges[ipar])->Execute, "bpshr=shmvar('bpshr')"
		;(*bridges[ipar])->Execute, "bpshr[0,0]=badpixmap
		

    ;The orginal called for a badpixelmap, but this is now dealt with earlier in the pipeline
		(*bridges[ipar])->Execute, "find_pol_positions_quadrant, quadrant,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,spotpos,im, spotpos_pixels, spotpos_pixvals, tight_pos, boxwidth, display=display_flag, badpixmap=bpshr", /nowait
		;wait, 5
		;
		; The above should automatically write the output into the shared memory, I think,
		; if we've done it right? 
    ; Yes I believe so

	endfor
	    
    ;for quadrant=1L,4 do find_pol_positions_quadrant, quadrant,wcst,Pcst,nlens,idx,jdy,cen1,wx,wy,hh,szim,spotpos,im, spotpos_pixels, spotpos_pixvals, display=display_flag, badpixmap=badpixmap
    
        ; now keep looping and wait for them all to finish
        going = 1
        stats =intarr(nbparallel)
        while (going) do begin
            for ipar=0L,nbparallel-1 do stats[ipar] = (*bridges[ipar])->Status()
            if total(stats) eq 0 then going=0
            print,"Parallel calculation still running... "+strc(fix(total(stats)))+"/"+strc(nbparallel)+" threads executing." ;,/erase
            wait, 3
        endwhile
        message,/info, "Parallel computation done!"
      print, "This took "+string(SysTime(/Seconds)-t0)+" seconds"
     
     
     ;Cleanup 
     ;Some of this may be excessive, but better safe than sorry!
     for quadrant=0L,3 do begin
      
     (*bridges[quadrant])->Execute, "spotpos=0d"
     (*bridges[quadrant])->Execute, "spotpos_pixels=0d"
     (*bridges[quadrant])->Execute, "spotpos_pixvals=0d"
     (*bridges[quadrant])->Execute, "im=0d"
      
      (*bridges[quadrant])->Execute, "SHmunMap, 'spotpos'"
      (*bridges[quadrant])->Execute, "SHMunMap, 'spotpos_pixels'"
      (*bridges[quadrant])->Execute, "SHMunMap, 'spotpos_pixvals'"
     ; (*bridges[quadrant])->Execute, "SHMunMap, 'imshr'"
     
      obj_destroy, (*bridges[quadrant])
      
     endfor
     
 
    suffix="-"+strcompress(bandeobs,/REMOVE_ALL)+'-polcal'
    ;fname=strmid(filename,0,STRLEN(filename)-6)+suffix+'.fits'
    fname = file_basename(filename, ".fits")+suffix+'.fits'
    
    ; Set keywords for outputting files into the Calibrations DB
    backbone->set_keyword, "FILETYPE", "Polarimetry Spots Cal File"
    backbone->set_keyword,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
    
	backbone->set_keyword, "HISTORY", "      ",ext_num=0
	backbone->set_keyword, "HISTORY", " Center peak detected at pos:"+string(cen1[0])+","+string(cen1[1]), ext_num=0
  backbone->set_keyword, "HISTORY", " Pol Calib File Format:",ext_num=0
  backbone->set_keyword, "HISTORY", "    Axis 1:  pos_x, pos_y, rotangle, width_x, width_y",ext_num=0
  backbone->set_keyword, "HISTORY", "       rotangle is in degrees, widths in pixels",ext_num=0
  backbone->set_keyword, "HISTORY", "    Axis 2:  Lenslet X",ext_num=0
  backbone->set_keyword, "HISTORY", "    Axis 3:  Lenslet Y",ext_num=0
  backbone->set_keyword, "HISTORY", "    Axis 4:  Polarization ( -- or | ) ",ext_num=0
	backbone->set_keyword, "HISTORY", "      ",ext_num=0
    
    ;Unmapping the shared memory
    
    


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

    shmunmap, 'spotpos'
    shmunmap, 'spotpos_pixels'
    shmunmap, 'spotpos_pixvals'
    shmunmap, 'imshr'

return, ok

end
