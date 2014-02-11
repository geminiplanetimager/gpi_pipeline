;+
; NAME: gpi_create_2d_low_frequency_flat
; PIPELINE PRIMITIVE DESCRIPTION: Create 2D Low Frequency Flat
; 
; /!\ PROBABLY OUT OF DATE /!\ /!\ PROBABLY OUT OF DATE /!\ 
; That's why it is hidden. It was not even ready for release. 
; See new LF flat determination with the work in progress by JB and Patrick on high resolution microlens PSF.
; /!\ PROBABLY OUT OF DATE /!\ /!\ PROBABLY OUT OF DATE /!\ 
; 
; This primitive use a combined image of polarimetry flat-fields to build a low frequency flat for the detector array.
; The idea applied here is to integrate the flux of each single spot using aperture photometry. For every spot, the neighbors are masked and the function aper computes the total flux and the sky/background correction. The neighbors are masked in order to have enough pixels to compute the sky. Then, we combine the flux of every couple of spots.
; Then, we divide all the values with their median.
; Artifacts are removed by computing a local std deviation and median. Every pixels further than n-sigma were replaced by the value of the smoothed flat.
; To finish, we interpolates the resulting values over the 2048x2048 detector array using triangulate/trigrid function (linear interpolation using nearest neighbors).
; 
; There are still borders problem. The flat is not valid near the edges.
; 
; INPUTS:  Polarimetry flats
; OUTPUTS: Low frequency flat
;
; PIPELINE COMMENT: Create Low Frequency Flat 2D from polarimetry flats
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.01
; PIPELINE CATEGORY: HIDDEN
;
; HISTORY:
;     Originally by Jean-Baptiste Ruffio 2013-06
;     2013-07-17 MP: Renamed for consistency
;	  2013-12-03 MP: Add check for GCALLAMP=QH on input images 
;-
function gpi_create_2d_low_frequency_flat, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
 
  image=*(dataset.currframe[0])
  
   sz=size(image) 
   if sz[1] ne 2048 or sz[2] ne 2048 then begin
    backbone->Log, "REFPIX: Image is not 2048x2048, don't know how to manage it."
    return, NOT_OK
   endif
  
  ;Check that all the images 
  ;  - have the same elevation 
  ;  - are polarimetric data
  ;  - are flats ;2013-06-04 jruffio: has to be disabled right now because headers for polarimetric data are not consistent
  nfiles = 0
  my_first_elevation = backbone->get_keyword('ELEVATIO', indexFrame=nfiles)
  my_first_mode =  gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', indexFrame=nfiles))
  while (size(*dataset.headersphu[nfiles+1]))[0] ne 0 do begin ;hard to understand but it checks if there is indeed a header behind the pointer
    nfiles+=1
    my_elevation = backbone->get_keyword('ELEVATIO', indexFrame=nfiles)
    my_mode =  gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', indexFrame=nfiles))
        ; the above line returns zero if no keyword is found. This is
        ; acceptable since all data taken without this keyword has an
        ; elevation of zero!
    if my_elevation ne my_first_elevation then return, error('Image '+strc(nfiles+1)+' has different elevation (ELEVATIO keyword) than first image in sequence. Cannot create LF flat!')
    if ~strcmp(my_mode, 'WOLLASTON') then return, error('Image '+strc(nfiles+1)+' is not polarimetric data (DISPERSR keyword). Cannot create LF flat!')
    ;2013-06-04 jruffio: this check has to be disabled right now because headers for polarimetric data are not consistent
    ;if strcompress(backbone->get_keyword('OBSTYPE'),/remove_all) ne 'FLAT' then return, error('Image '+strc(nfiles+1)+' is not a flat  (OBSTYPE keyword). Cannot create LF flat!')
    my_lamp= backbone->get_keyword('GCALLAMP', indexFrame=nfiles)
	if strc(my_lamps) ne "QH" then return,  error('FAILURE ('+functionName+'): Expected quartz halogen flat lamp images as input, but GCALLAMP != QH.')
  endwhile
  nfiles+=1 ; because it was previously used as an index and index starts at 0
  
  ;load the pol solution
  polspot_coords = polcal.coords
  polspot_position = polcal.spotpos
  if ((size(polspot_coords))[0] eq 0) || (dim eq 0)  then begin
    return, error('FAILURE ('+functionName+'): Failed to load polarimetry calibration data prior to calling this primitive.') 
  endif
  nlens=(size(polspot_coords))[3]
  
  integrated_flux = fltarr(nlens,nlens,2)
  
;///////////////////////////////////   
;Extraction: Version using the pol calibration
;/////////////////////////////////// 
;  ;loop over all the spots
;  for npol=0,1 do begin
;    for i=0,nlens-1 do begin
;      for j=0,nlens-1 do begin
;        ;Get the coordinates of all the pixels of the current spot
;        valid_spot_pix = where( finite(polspot_coords[0,*,i,j,npol]) AND $
;                                 finite(polspot_coords[1,*,i,j,npol]) AND $
;                                 polspot_coords[0,*,i,j,npol] gt 0 AND $
;                                 polspot_coords[1,*,i,j,npol] gt 0 AND $
;                                 polspot_coords[0,*,i,j,npol] lt 2048 AND $
;                                 polspot_coords[1,*,i,j,npol] lt 2048)
;        if valid_spot_pix[0] ne -1 then begin
;          x_coords_of_the_spot_pixels = polspot_coords[0, valid_spot_pix,i,j,npol]
;          y_coords_of_the_spot_pixels = polspot_coords[1, valid_spot_pix,i,j,npol]
;          
;;          ;get the position of the current spot. It is the center of the fit gaussian.
;;          spot_x_pos = polspot_position[0,i,j,npol]
;;          spot_y_pos = polspot_position[1,i,j,npol]
;
;          integrated_flux[i,j,npol] = total(image[x_coords_of_the_spot_pixels,y_coords_of_the_spot_pixels])
;        endif else begin
;          integrated_flux[i,j,npol] = !Values.F_NAN
;        endelse
;      endfor
;    endfor
;  endfor
;/////////////////////////////////// 

;///////////////////////////////////   
;Extraction: Version using aperture photometry
;///////////////////////////////////
  ;loop over all the spots
  for npol=0,1 do begin
    for i=0,nlens-1 do begin
      for j=0,nlens-1 do begin
      
        ;!!!!!!!!!!!!!!!!TO CHANGE TO MAX AFTER DEBUGGING
        width = mean(polspot_position[3:4,i,j,npol],/nan)
        ;There are a lot of nans in the array so skip them
        if finite(polspot_position[3,i,j,npol]) AND $
          finite(polspot_position[4,i,j,npol]) then begin
          
          ;get the coordinates of the pixels close to the current one
          all_x_coords_neighboors = reform(polspot_coords[0,*,max([0,(i-1)]):min([(nlens-1),(i+1)]),max([0,(j-1)]):min([(nlens-1),(j+1)]),*])
          all_y_coords_neighboors = reform(polspot_coords[1,*,max([0,(i-1)]):min([(nlens-1),(i+1)]),max([0,(j-1)]):min([(nlens-1),(j+1)]),*])
          
          ;remove from that list the coordinate corresponding to the current pixel
          all_x_coords_neighboors[*,i-max([0,(i-1)]),j-max([0,(j-1)]),npol] = !values.f_nan
          all_y_coords_neighboors[*,i-max([0,(i-1)]),j-max([0,(j-1)]),npol] = !values.f_nan
          
          ;take only the valid coordinates
          valid_neighbors = where( finite(all_x_coords_neighboors) AND $
                                   finite(all_y_coords_neighboors) AND $
                                   all_x_coords_neighboors gt 0 AND $
                                   all_y_coords_neighboors gt 0 AND $
                                   all_x_coords_neighboors lt 2048 AND $
                                   all_y_coords_neighboors lt 2048)
                                   
          ;we want to save them before to be able to restore them after the aperture photometry (because we will temporarly erase this pixels from the image)
          save_neighbors_flux = image[all_x_coords_neighboors[valid_neighbors],all_y_coords_neighboors[valid_neighbors]]
          
          ;temporarly mask the neighbors for the sky computation in function aper
          image[all_x_coords_neighboors[valid_neighbors],all_y_coords_neighboors[valid_neighbors]] = !values.f_nan
          
;          ;We have some problems with nans that are in the aperture and prevent aper to compute the spot flux so we will set them a value that will not change a lot the sky.
;          ;So all Nans that are closer than 3.*width to the current spot are set to a value very close to the sky
;          ;This pixels will be restored right after
          x_current_spot = polspot_position[0,i,j,npol]
          y_current_spot = polspot_position[1,i,j,npol]
          nans_too_close = where(abs(all_x_coords_neighboors[valid_neighbors[*]] - x_current_spot) lt 3.*width AND abs(all_y_coords_neighboors[valid_neighbors[*]] - y_current_spot) lt 3.*width AND ~finite(image[all_x_coords_neighboors[valid_neighbors[*]],all_y_coords_neighboors[valid_neighbors[*]]]) )
          if nans_too_close[0] ne -1 then begin
            image[all_x_coords_neighboors[valid_neighbors[nans_too_close]],$
                  all_y_coords_neighboors[valid_neighbors[nans_too_close]]] = median(image[max([0,(x_current_spot-5*width)]):min([2047,(x_current_spot+5*width)]),$
                                                                                          max([0,(y_current_spot-5*width)]):min([2047,(y_current_spot+5*width)]) ])
          endif

          ;/////////////////////////
          ;APERTURE PHOTOMETRY!!!!!
          ;Note: Aperture photometry with a radius of 2.35482*width = FWHM = 2*sqrt(2*Ln(2))*sigma
          ;Note: Sky computation in the interval of radii [2.35482*width,5*width], We masked the spot in the aera so it should be fine.
          APER, image, x_current_spot, y_current_spot, flux, errap, sky, skyerr, 1.0, 2.35482*width, [2.35482*width,5*width], /FLUX, /NAN, /SILENT
          integrated_flux[i,j,npol] = flux
          ;/////////////////////////

          ;restore the masked pixels
          image[all_x_coords_neighboors[valid_neighbors],all_y_coords_neighboors[valid_neighbors]] = save_neighbors_flux
          
;          ;for debugging
;          if i eq 150 and j eq 150 then stop
          
        endif else begin
          integrated_flux[i,j,npol] = !Values.F_NAN
        endelse
        
      endfor
    endfor
  endfor
;/////////////////////////////////// 

;/////////////////////////////////// 
;Normalization: division by the median
;/////////////////////////////////// 
  ;Divide by the median to get the flat coefficients
  integrated_flux_total = integrated_flux[*,*,0]+integrated_flux[*,*,1]
  integrated_flux_total_normalized = integrated_flux_total/median(integrated_flux_total)
  xpos_middle = reform((polspot_position[0,*,*,0]+polspot_position[0,*,*,1])/2.0)
  ypos_middle = reform((polspot_position[1,*,*,0]+polspot_position[1,*,*,1])/2.0)
;  window, 12
;  surface, integrated_flux_total_normalized, xpos_middle, ypos_middle, charsize = 2, zrange = [0.0,1.2]
;  stop
;/////////////////////////////////// 

;///////////////////////////////////
;Correction of the artifacts probably due to the none corrected badpixels
;///////////////////////////////////
  width = 10
    
  integrated_flux_total_normalized_smoothed = median(integrated_flux_total_normalized,width) ;tried 25, 50 and 100: 50 seems the best to me
  
  nx = nlens
  ny = nlens
  ;Compute the local stddev
    PixelsSkipped= 5
    local_stddev = fltarr((nx-width/2)/(PixelsSkipped+1)+1,(ny-width/2)/(PixelsSkipped+1)+1) + !VALUES.F_NAN
    x_samples = fltarr((nx-width/2)/(PixelsSkipped+1)+1,(ny-width/2)/(PixelsSkipped+1)+1) + !VALUES.F_NAN
    y_samples = fltarr((nx-width/2)/(PixelsSkipped+1)+1,(ny-width/2)/(PixelsSkipped+1)+1) + !VALUES.F_NAN
      for i=0,(nx-width/2)/(PixelsSkipped+1) do begin
        for j=0,(ny-width/2)/(PixelsSkipped+1) do begin
          x_samples[i,j]  = (width/2) + i*(PixelsSkipped+1)
          y_samples[i,j]  = (width/2) + j*(PixelsSkipped +1)
          moving_rectangle = integrated_flux_total_normalized[ max([0,(x_samples[i,j]-width/2)]):min([nx-1,(x_samples[i,j]+width/2)]) ,$
                                                                 max([0,(y_samples[i,j]-width/2)]):min([ny-1,(y_samples[i,j]+width/2)]) ]
          if total(finite(moving_rectangle)) ge 2 then begin
            local_stddev[i,j] = stddev(moving_rectangle, /nan)
          endif else begin
            local_stddev[i,j] = !values.f_nan
          endelse
          
        endfor
      endfor
  
  ;interpolate the stddev to fit the 2048x2048 detector array
  x_samples = reform(x_samples, n_elements(x_samples))
  y_samples = reform(y_samples, n_elements(y_samples))
  local_stddev = reform(local_stddev, n_elements(local_stddev))
  TRIANGULATE, x_samples, y_samples, triangles, bounds
  sized_stddev = TRIGRID(x_samples, y_samples, local_stddev,triangles, [1.0,1.0], [0.0,0.0,float(nx-1),float(ny-1)], NX = nx, NY = ny, XGRID = x_grid, YGRID = y_grid)
  
;  ;for debugging only
;  window, 16
;  SHADE_SURF, sized_stddev, x_grid, y_grid, charsize = 2, zrange = [0.0,1.2]
;  writefits, "/Users/jruffio/Desktop/stddev.fits",sized_stddev 
  
  ;get artifacts position by selection the value over 3sigma of the local median
  artifacts_coordinates = where(abs(integrated_flux_total_normalized - integrated_flux_total_normalized_smoothed) gt 1.0*sized_stddev AND finite(sized_stddev))
  ;take one more pixel on each side. Massive edge effects but right now it is not a big deal.
  mask_artifacts = intarr(nx,ny)
  if artifacts_coordinates[0] ne -1 then begin
  
    ;it is if you want to correct the pixels around the so called artifacts. If overfill = 1, all the neighbors of an artifacts will be consider as bed as well.
    overfill = 0
    mask_artifacts[artifacts_coordinates] = 1
    for i=0,nx-1 do begin
      for j=0,ny-1 do begin
        if mask_artifacts[i,j] eq 1 then mask_artifacts[ max([0,(i-overfill)]):min([(nx-1),(i+overfill)]) ,$
                                                        max([0,(j-overfill)]):min([(ny-1),(j+overfill)]) ] = 2
      endfor
    endfor
;    writefits, "/Users/jruffio/Desktop/mask_artifacts.fits", mask_artifacts

  endif
  
  ;remove the artifacts (but not near the edges of the image, it shouldn't be a problem...)
  fat_artifacts_coordinates = where(mask_artifacts eq 2)
  if fat_artifacts_coordinates[0] ne -1 then begin
    integrated_flux_total_normalized[fat_artifacts_coordinates] = integrated_flux_total_normalized_smoothed[fat_artifacts_coordinates]
;    writefits, "/Users/jruffio/Desktop/my2smoothed.fits",integrated_flux_total_normalized
  endif
  
  
;  stop
;///////////////////////////////////

;///////////////////////////////////   
;Inteprolation over the 2048x2048 detector array: polynomial fit
;///////////////////////////////////  
;  deg_2d_poly = 2
;  valid_points = where(finite(integrated_flux_total_normalized),cc)
;  fit_2d_poly = sfit([reform(xpos_middle[valid_points],1,cc),reform(ypos_middle[valid_points],1,cc),reform(integrated_flux_total_normalized[valid_points],1,cc)],deg_2d_poly,KX = coefs,/IRREGULAR)
;  x_grid = findgen(2048)
;  x_grid = rebin(x_grid,2048,2048)
;  y_grid = transpose(x_grid)
;  resampled_2d_fit = fltarr(2048,2048)
;  for i=0,deg_2d_poly do begin
;    for j= 0,deg_2d_poly do begin
;      resampled_2d_fit += coefs[i,j] *x_grid^j * y_grid^i
;    endfor
;  endfor
;  window, 13
;  SHADE_SURF, resampled_2d_fit, x_grid, y_grid, charsize = 2, zrange = [0.0,1.2]
  ;polspot_position[0,150,150,0], polspot_position[1,150,150,0],polspot_position[0,150,150,1], polspot_position[1,150,150,1]
;/////////////////////////////////// 

;///////////////////////////////////   
;Inteprolation over the 2048x2048 detector array: Trigrid, Linear interpolation
;///////////////////////////////////
  valid_points = where(finite(integrated_flux_total_normalized),cc)
  x_valid = xpos_middle[valid_points]
  y_valid = ypos_middle[valid_points]
  z_valid = integrated_flux_total_normalized[valid_points]

  TRIANGULATE, x_valid, y_valid, triangles, bounds
  z_interp = TRIGRID(x_valid, y_valid, z_valid,triangles, [1.0,1.0], [0.0,0.0,2047.0,2047.0], NX = 2048, NY = 2048, XGRID = x_grid, YGRID = y_grid)
  
  ;todo if where = -1
  z_interp[where(z_interp eq 0.0)] = !values.f_nan
  
  ;useless but for readibility
  detector_sized_flat = z_interp
  
;  ;temporarly for debugging  
;  window, 15
;  SHADE_SURF, z_interp, x_grid, y_grid, charsize = 2, zrange = [0.0,1.2]
;  writefits, "/Users/jruffio/Desktop/my2.fits",detector_sized_flat
;///////////////////////////////////



;Patrick = readfits("/Users/jruffio/Desktop/low_res_flat_for_JB.fits")
;Patrick = rot(Patrick, 24.5)
;Patrick[where(~finite(PAtrick))] = 0.0
;cou = Patrick[35:246,35:246]
;bon = congrid(cou, 2048,2048)
;SHADE_SURF, bon, x_grid, y_grid, charsize = 2, zrange = [0.0,1.2]
;
;z2 = median(z1,50)
;diff= z2-bon
;diff[where(diff lt (-0.5))] = !values.f_nan
;diff[where(diff gt (0.5))] = !values.f_nan
;
;diff2 = congrid(diff, 248,248)
;z3 = congrid(z1,248,248)
;bon2 = congrid(cou,248,248)
;
;SHADE_SURF, bon2-z3, x_grid, y_grid, charsize = 2, zrange = [0.0,1.2]

;///////////////////////////////////   
;Spline fit
;/////////////////////////////////// 
;  z1 = GRID_TPS(xpos_middle[valid_points], ypos_middle[valid_points], integrated_flux_total_normalized[valid_points], NGRID=[2048, 2048], START=[0.5,0.5], DELTA=[1,1]) 
;  window, 13
;  SHADE_SURF, z1, x_grid, y_grid, charsize = 2, zrange = [0.0,1.2]
;  stop
;  

;  stop
  ;----- store the output into the backbone datastruct
  *(dataset.currframe)=detector_sized_flat ;which has no artifacts anymore
  dataset.validframecount=1
    backbone->set_keyword, "FILETYPE", "LF flat", /savecomment
    backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
  suffix = '-LFFlat'

@__end_primitive
end
