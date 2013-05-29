;+
; NAME: Noise and Flux Analysis
; PIPELINE PRIMITIVE DESCRIPTION: Noise and Flux Analysis
;
;   This routine quantifies the noise and the flux in an image without changing it. It generates fits keyword for this values for further easy image sorting.
;   If asked, it can generate a fits files too.
;   
;   If Flux = 1: Generate fits keywords related with total flux in the image
;     DN, total data number of the image. 
;     DNLENS, total data number in the lenslets aera (if not a dark and not a cube)
;     DNBACK, total data number outside the lenslets aera (if not a dark and not a cube)
;   
;   
;   If StddevMed > 1: Generate fits keywords related with the standard deviation in the image
;   
;   If StddevMed = 2:
;     Compute the local median and the local standard deviation by moving a square of size Width.
;     Because it is time consuming, you can skip pixels using the parameter PixelsSkipped.
;     In the output, the finite value pixels correspond to pixels where the media and the standard deviation were computed.
;     If 2d image: Generate a file with the suffix '-stddevmed' containing an 3d array. [*,*,0] is the median and [*,*,1] is the standard deviation.
;     If 3d image: Generate two files '-stddev' and '-median'. Both same size of the original image.
;     
;     
;   If microNoise = 1:
;     Estimate the quantity of microphonics noise in the image based on a model stored as a calibration file.
;     The quantity of microphonics noise is measured with the ratio of the dot_product and the norm of the image: dot_product/sqrt(sum(abs(fft(image))^2)).
;     With dot_product = sum(abs(fft(image))*abs(fft(noise_model))) which correspond to the projection of the image on the microphonics noise model in the absolute Fourier space.
;     The fits keyword associated is MICRONOI.
;   
;   
;   If FourierTransf = 1 or 2:
;     Build and save the Fourier transform of the image.
;     If 1, the output is the one directly from the idl function (fft). Therefore, the Fourier image is not centered.
;     If 2, the output will be centered.
;     In the case of a cube it is not a 3d fft that is performed but several 2d ffts.
;     suffix='-absfft' or suffix='-absfftdc' if it is a cube.
;
; KEYWORDS:
; 
; OUTPUTS: Changes is the header of the file without changing the data and saving a fits file report with the value of the sliding median/standard deviation computation.
;
; PIPELINE COMMENT: Store a few key values as fits keywords in the file. It can generate anciliary files too.
; PIPELINE ARGUMENT: Name="Flux" Type="int" Range="[0,1]" Default="1" Desc='Trigger flux analysis'
; PIPELINE ARGUMENT: Name="StddevMed" Type="int" Range="[0,2]" Default="1" Desc='Trigger the standard deviation (and median) analysis of the image. if StddevMed=1, only keywords and log are produced. If StddevMed=2, fits files are generated with a sliding median and standard deviation.'
; PIPELINE ARGUMENT: Name="Width" Type="int" Range="[3,2048]" Default="101" Desc='If Stddev = 2, Width of the moving rectangle. It has to be odd.'
; PIPELINE ARGUMENT: Name="PixelsSkipped" Type="int" Range="[0,2047]" Default="100" Desc='If Stddev = 2, Pixels skipped between two points'
; PIPELINE ARGUMENT: Name="MicroNoise" Type="int" Range="[0,1]" Default="1" Desc='Trigger the microphonics noise analysis'
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="string" Default="/Users/jruffio/gpi/Reduced/calibrations/S20130430S0003-microModel.fits" Desc="Filename of the desired microphonics model file to be read"
; PIPELINE ARGUMENT: Name="FourierTransf" Type="int" Range="[0,1,2]" Default="1" Desc='1: frequency 0 on the bottom left. 2: frequencies 0 will be centered on the image.'
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.0
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: SpectralScience, Calibration, PolarimetricScience
;
; HISTORY:
;   Originally by Jean-Baptiste Ruffio 2013-05
;-
function noise_flux_analysis, DataSet, Modules, Backbone
primitive_version= '$Id: noise_flux_analysis.pro ?? 2013-05-29 ?? jruffio $' ; get version from subversion to store in header history
calfiletype = 'Micro Model'
@__start_primitive

  ;get the 2D detector image
  im=*(dataset.currframe[0])

  size_im = size(im)
  if size_im[0] EQ 2 then begin
    nx = size_im[1]
    ny = size_im[2]
    nz=1
    skipping = 0
  endif else if size_im[0] EQ 3 then begin
    nx = size_im[1]
    ny = size_im[2]
    nz = size_im[3]
    skipping = 0
  endif else begin
    backbone->Log, "Skipping noise and flux analysis. Image size invalid, needs 2 or 3 dimensionnal array.",depth=2
    skipping = 1
  endelse

;load wavelength solution if it is not a dark frame
if ~strcmp(strtrim(backbone->get_keyword('OBSTYPE'), 2),'DARK') and (size_im[0] EQ 2) then begin
      backbone->Log, "No dark image detected. Trying to apply lenslets mask"
      
        ;define the common wavelength vector with the IFSFILT keyword:
        filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
        
        ;error handle if IFSFILT keyword not found
        if (filter eq '') then begin
           backbone->Log, "Skipping noise and flux analysis. IFSFILT keyword not found."
           skipping = 1
        endif
               
        mode = gpi_simplify_keyword_value(backbone->get_keyword('DISPERSR', count=c))
        case strupcase(strc(mode)) of
          'PRISM':  begin
              nlens=(size(wavcal))[1]       ;pixel sidelength of final datacube (spatial dimensions) 
              dim=(size(im))[1]            ;detector sidelength in pixels
            
              ;handle if readwavcal or not used before
              if (nlens eq 0) || (dim eq 0)  then begin
                 backbone->Log, "Skipping noise and flux analysis. Failed to load wavelength calibration data prior to calling this primitive.'
                 skipping = 1
              endif
            
              ;get length of spectrum
              sdpx = calc_sdpx(wavcal, filter, xmini, CommonWavVect)
              if (sdpx < 0) then begin
                backbone->Log, "Skipping noise and flux analysis. Wavelength solution is bogus! All values are NaN."
                skipping = 1
              endif
              
              if (skipping EQ 0) then begin
                ;Find the coordinates of the lenslets
                xx = fltarr(nlens,nlens,sdpx)
                yy = fltarr(nlens,nlens,sdpx)
                for i=0,21 do begin
                  xx[*,*,i] = xmini - i
                  yy[*,*,i] = round(wavcal[*,*,1]+(wavcal[*,*,0]-xx[*,*,i])*tan(wavcal[*,*,4]))
                endfor
                xCoord_mask = xx[where(finite(xx) AND finite(yy) AND ~((xx LE 4.0) OR (xx GE 2043.0)) AND ~((yy LE 5.0) OR (yy GE 2042.0)) )]
                yCoord_mask = yy[where(finite(xx) AND finite(yy) AND ~((xx LE 4.0) OR (xx GE 2043.0)) AND ~((yy LE 5.0) OR (yy GE 2042.0)) )]
                
                mask = intarr(nx,ny)
                mask[yCoord_mask-1, xCoord_mask] = 1
                mask[yCoord_mask, xCoord_mask] = 1
                mask[yCoord_mask+1, xCoord_mask] = 1
                
                mask[*,0:4] = 2
                mask[0:4,*] = 2
                mask[*,(ny-5):(ny-1)] = 2
                mask[(nx-5):(nx-1),*] = 2
              endif
          end
          'WOLLASTON':    begin
              ; Assume pol cal info already loaded by readpolcal primitive 
              polspot_coords = polcal.coords
              polspot_pixvals = polcal.pixvals
              
              sz = size(polspot_coords)
              nx = sz[1+2]
              ny = sz[2+2]
              
              for pol=0,1 do begin
                for ix=0L,nx-1 do begin
                  for iy=0L,ny-1 do begin
                  ;if ~ptr_valid(polcoords[ix, iy,pol]) then continue
                  wg = where(finite(polspot_pixvals[*,ix,iy,pol]) and polspot_pixvals[*,ix,iy,pol] gt 0, gct)
                  if gct eq 0 then continue
        
                  spotx = polspot_coords[0,wg,ix,iy,pol]
                  spoty = polspot_coords[1,wg,ix,iy,pol]
                  
                  mask[spotx,spoty]= 1
                   
                  endfor 
                endfor 
              endfor 
          end
          'OPEN':    begin
                 backbone->set_keyword, "HISTORY", "NO ANALYSIS PERFORMED, not implemented for Undispersed mode"
                         message,/info, "NO ANALYSIS PERFORMED, not implemented for Undispersed mode"
                         return,ok
          end
          endcase
          
        if (skipping EQ 0) then begin  
          ;Extract the pixels belonging to the lenslets
          im_lenslets = im[where(mask EQ 1)]
          im_background =  im[where(mask EQ 0)]
          ;stop
        endif
endif


;///////////////////////////////
;/////////Flux analysis/////////
;///////////////////////////////
if tag_exist( Modules[thisModuleIndex], "Flux") AND skipping EQ 0 then if uint(Modules[thisModuleIndex].Flux) EQ 1 then begin
backbone->Log, "Begin Flux analysis"

  if size_im[0] EQ 2 then begin
    if strcmp(strtrim(backbone->get_keyword('OBSTYPE'), 2),'DARK') then begin
      im_totalDN = total(im)
      backbone->set_keyword, "DN", im_totalDN
      backbone->set_keyword, "HISTORY", "Keyword DN added. The total data number is " + string(im_totalDN)
      backbone->Log, "Keyword DN added. The total data number is " + string(im_totalDN)
    endif else begin
        im_totalDN = total(im)
        im_lenslets_totalDN = total(im_lenslets)
        
        backbone->set_keyword, "DN", im_totalDN
        backbone->set_keyword, "DNLENS", im_lenslets_totalDN
        backbone->set_keyword, "DNBACK", (im_totalDN - im_lenslets_totalDN)
        backbone->set_keyword, "HISTORY", "Keyword DN, DNLENS and DNBACK added. Values are " + string(im_totalDN) + ', ' + string(im_lenslets_totalDN) + ' and ' + string((im_totalDN - im_lenslets_totalDN))
        backbone->Log, "Keyword DN, DNLENS and DNBACK added. Values are " + string(im_totalDN) + ', ' + string(im_lenslets_totalDN) + ' and ' + string(im_totalDN - im_lenslets_totalDN)
    endelse
  endif else begin
    backbone->Log, "Image cube detected. No lenslet mask applied"
    im_totalDN = total(im)
    backbone->set_keyword, "DN", im_totalDN
    backbone->set_keyword, "HISTORY", "Keyword DN added. The total data number is " + string(im_totalDN)
    backbone->Log, "Keyword DN added. The total data number is " + string(im_totalDN)
  end
endif

;////////////////////////////////////////////////////////
;/////////Standard deviation and median analysis/////////
;////////////////////////////////////////////////////////
if tag_exist( Modules[thisModuleIndex], "StddevMed") AND skipping EQ 0 then begin 

  if uint(Modules[thisModuleIndex].StddevMed) GE 1 then begin
      backbone->Log, "Begin Standard deviation and median analysis"
      
      im_median = median(im)
      backbone->set_keyword, "MED", im_median
      backbone->set_keyword, "HISTORY", "Keyword MED added. The median is " + string(im_median)
      backbone->Log, "Keyword MED added. The median is " + string(im_median)
      
      im_stddev = stddev(im, /nan)
      backbone->set_keyword, "DEV", im_stddev
      backbone->set_keyword, "HISTORY", "Keyword DEV added. The standard deviation is " + string(im_stddev)
      backbone->Log, "Keyword DEV added. The standard deviation is " + string(im_stddev)
      
    if ~strcmp(strtrim(backbone->get_keyword('OBSTYPE'), 2),'DARK') AND size_im[0] EQ 2 then begin
      im_lens_median = median(im_lenslets)
      backbone->set_keyword, "MEDLENS", im_lens_median
      backbone->set_keyword, "HISTORY", "Keyword MEDLENS added. The median of the lenslets is " + string(im_lens_median)
      backbone->Log, "Keyword MEDLENS added. The median  of the lenslets is " + string(im_lens_median)
      
      im_stddev = stddev(im_lenslets, /nan)
      backbone->set_keyword, "DEVLENS", im_stddev
      backbone->set_keyword, "HISTORY", "Keyword DEVLENS added. The standard deviation is " + string(im_stddev)
      backbone->Log, "Keyword DEVLENS added. The standard deviation is " + string(im_stddev)
      
      im_back_median = median(im_background)
      backbone->set_keyword, "MEDBACK", im_back_median
      backbone->set_keyword, "HISTORY", "Keyword MEDBACK added. The median of the backgroung is " + string(im_back_median)
      backbone->Log, "Keyword MEDBACK added. The median of the backgroung is " + string(im_back_median)
      
      im_back_stddev = stddev(im_background, /nan)
      backbone->set_keyword, "DEVBACK", im_back_stddev
      backbone->set_keyword, "HISTORY", "Keyword DEVBACK added. The standard deviation of the backgroung is " + string(im_back_stddev)
      backbone->Log, "Keyword DEVBACK added. The standard deviation of the backgroung is " + string(im_back_stddev)
    endif
  endif
  
  if uint(Modules[thisModuleIndex].StddevMed) EQ 2 then begin
    if tag_exist( Modules[thisModuleIndex], "Width") then Width=uint(Modules[thisModuleIndex].Width) else begin
      Width=101
      backbone->Log, "Setting default Width = 101pix. Parameter 'Width' undefined."
    endelse
    if tag_exist( Modules[thisModuleIndex], "PixelsSkipped") then PixelsSkipped=uint(Modules[thisModuleIndex].PixelsSkipped) else begin
      PixelsSkipped=100
      backbone->Log, "Setting default PixelsSkipped = 100pix. Parameter 'PixelsSkipped' undefined."
    endelse

    if width GE min([nx,ny]) then begin
      backbone->Log, "Setting default Width = 101pix. Parameter 'Width' too large compared to the size of the image."
      width = 101
    endif
    if width LT 3 then begin
      backbone->Log, "Setting default Width = 101pix. Parameter 'Width' too small."
      width = 101
    endif
    if (floor(width) mod 2) EQ 0 then begin
      backbone->Log, "Width = Width-1 because Width is even while Width need to be odd."
      Width = Width-1
    endif
    
    width = floor(Width) ;in case a float arrived here...
    
    result = fltarr(nx,ny,nz,2) + !VALUES.F_NAN; [*,*,*,0] = median, [*,*,*,1] = stddev
    
    for frame_id=0,(nz-1) do begin
      for i=0,(nx-width)/(PixelsSkipped+1) do begin
        for j=0,(ny-width)/(PixelsSkipped+1) do begin
          x = (width/2) + i*(PixelsSkipped+1)
          y = (width/2) + j*(PixelsSkipped +1)
          moving_rectangle = im[(x-width/2):((x+width/2)),(y-width/2):((y+width/2)),frame_id]
          result[x,y,frame_id,0] = median(moving_rectangle)
          result[x,y,frame_id,1] = stddev(moving_rectangle)
    ;      result[x:min([(x+skip),(nx-width/2)]),y:min([(y+skip),(ny-width/2)]),frame_id,0] = median(moving_rectangle)
    ;      result[x:min([(x+skip),(nx-width/2)]),y:min([(y+skip),(ny-width/2)]),frame_id,1] = stddev(moving_rectangle)
        endfor
      endfor
    endfor
    
    min_stddev = min(result[*,*,*,1], /nan)
    backbone->set_keyword, "DEVMIN", min_stddev
    backbone->set_keyword, "HISTORY", "Keyword DEVMIN added. The standard deviation is " + string(min_stddev)
    backbone->Log, "Keyword DEVMIN added. The standard deviation is " + string(min_stddev)
    
    max_stddev = max(result[*,*,*,1], /nan)
    backbone->set_keyword, "DEVMAX", max_stddev
    backbone->set_keyword, "HISTORY", "Keyword DEVMAX added. The standard deviation is " + string(max_stddev)
    backbone->Log, "Keyword DEVMAX added. The standard deviation is " + string(max_stddev)

    if size_im[0] EQ 2 then begin ;2d image
      result = reform(result, nx,ny,2)
      *(dataset.currframe[0])=result
      suffix='-stddevMed'
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
    endif else begin ;cube
      *(dataset.currframe[0])=result[*,*,*,1]
      suffix='-stddev'
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
      *(dataset.currframe[0])=result[*,*,*,0]
      suffix='-median'
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
    endelse
  endif
endif

;/////////////////////////////////////////////
;/////////Microphonics noise analysis/////////
;/////////////////////////////////////////////
if tag_exist( Modules[thisModuleIndex], "MicroNoise") AND skipping EQ 0 then if uint(Modules[thisModuleIndex].MicroNoise) EQ 1 then begin
  backbone->Log, "Begin Microphonics noise analysis"

  if size_im[0] EQ 2 then begin ;2d image
    micro_noise_abs_model = gpi_readfits(c_File,header=Header_micro_model)
    ;micro_noise_abs_model = readfits("/Users/jruffio/IDLWorkspace/pipeline/primitives/microphonics_model_abs_normalized.fits")
    
    ft_im_abs = abs(fft(im))
    micro_noise_level = total(ft_im_abs*micro_noise_abs_model)/sqrt(total(ft_im_abs^2))
    backbone->set_keyword, "MICRONOI", micro_noise_level
    backbone->set_keyword, "HISTORY", "Keyword MICRONOI added. The quantity of microphonics is " + string(micro_noise_level)
    backbone->Log, "Keyword MICRONOI added. The quantity of microphonics is " + string(micro_noise_level)
  endif else begin ;3D image
    backbone->set_keyword, "HISTORY", "Microphonics noise analysis not performed because this analysis doesn't manage 3D images yet" 
    backbone->Log, "Microphonics noise analysis not performed because this analysis doesn't manage 3D images yet" 
  endelse
endif



;////////////////////////////////////
;/////////Fourier transforms/////////
;////////////////////////////////////
if tag_exist( Modules[thisModuleIndex], "FourierTransf") AND skipping EQ 0 then if uint(Modules[thisModuleIndex].FourierTransf) GE 1 then begin
  if size_im[0] EQ 2 then begin ;2d image
    if uint(Modules[thisModuleIndex].FourierTransf) EQ 1 then begin
      *(dataset.currframe[0])=abs(fft(im))
    endif else if uint(Modules[thisModuleIndex].FourierTransf) EQ 2 then begin
      *(dataset.currframe[0])=abs(shift(fft(im),nx/2,ny/2))
    endif
    suffix='-absfft'
    b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
  endif else begin ;3D image
    fft_cube = complexarr(nx,ny,nz)
    for i=0,(nz-1) do begin
      if uint(Modules[thisModuleIndex].FourierTransf) EQ 1 then begin
        fft_cube[*,*,i] = fft(im[*,*,i])
      endif else if uint(Modules[thisModuleIndex].FourierTransf) EQ 2 then begin
        fft_cube[*,*,i] = shift(fft(im[*,*,i]),nx/2,ny/2)
      endif
    end
    *(dataset.currframe[0])= abs(fft_cube)
    suffix='-absfftdc' ;absolute fft Data Cube
    b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
  endelse
endif



*(dataset.currframe[0])=im
  
suffix='-noiseFlux'
@__end_primitive

end