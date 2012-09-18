;+
; NAME: get_sat_spots
; PIPELINE PRIMITIVE DESCRIPTION: Find locations of satellite spots
; and extract their peak fluxes
;
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: FILETYPE,ISCALIB,SPOTWAVE
;
; OUTPUTS:  
;
; PIPELINE COMMENT:  Find locations of satellite spots in datacubes and extract their peak fluxes
; PIPELINE ARGUMENT: Name="refine_fits" Type="int" Range="[0,1]" Default="1" Desc="0: Use wavelength scaling only; 1: Fit each slice"
; PIPELINE ARGUMENT: Name="reference_index" Type="int" Range="[0,50]" Default="0" Desc="Index of slice to use for initial satellite detection."
; PIPELINE ARGUMENT: Name="search_window" Type="int" Range="[1,50]" Default="20" Desc="Radius of aperture used for locating satellite spots."
; PIPELINE ARGUMENT: Name="gauss_window" Type="int" Range="[1,50]" Default="7" Desc="Radius of aperture used for extracting peak fluxes."
; PIPELINE ARGUMENT: Name="gauss_fit" Type="int" Range="[0,1]" Default="1" Desc="0:Extract maximum pixel value for peak flux; 1: Fit Gaussian to find peak flux."
; PIPELINE ARGUMENT: Name="loc_input" Type="int" Range="[0,2]" Default="0" Desc="0: Find spots automatically; 1: Use calibration file; 2:Use values below as initial satellite spot location"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="spotloc" Default="AUTOMATIC" Desc="Filename of spot locations calibration file to be read for first location guess. Will override following user guess."
; PIPELINE ARGUMENT: Name="x1" Type="int" Range="[0,300]" Default="0" Desc="approximate x-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y1" Type="int" Range="[0,300]" Default="0" Desc="approximate y-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="x2" Type="int" Range="[0,300]" Default="0" Desc="approximate x-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y2" Type="int" Range="[0,300]" Default="0" Desc="approximate y-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="x3" Type="int" Range="[0,300]" Default="0" Desc="approximate x-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y3" Type="int" Range="[0,300]" Default="0" Desc="approximate y-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="x4" Type="int" Range="[0,300]" Default="0" Desc="approximate x-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ARGUMENT: Name="y4" Type="int" Range="[0,300]" Default="0" Desc="approximate y-location of first spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)"
; PIPELINE ORDER: 2.44
; PIPELINE TYPE: ALL-SPEC
; PIPELINE NEWTYPE: SpectralScience
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Written 2012-09-17 savransky1@llnl.gov
;   based on code by Jerome Maire
;   replaced primitives gpi_meas_sat_spots_locations, sat_spots_locations, sat_spots_calib_from_unocc
;- 

function get_sat_spots, DataSet, Modules, Backbone
  primitive_version= '$Id: gpi_meas_sat_spots_locations.pro 78 2010-09-03 18:58:45Z maire $' ; get version from subversion to store in header history
  
  ;;calefiletype will not be defined if CalibrationFile='', so the user-param x1,y1,x2,... will be considered 
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
  @__start_primitive
  
  cube = *(dataset.currframe[0])
  band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))

  ;;error handle if extractcube not used before
  if ((size(cube))[0] ne 3) || (strlen(band) eq 0)  then $
     return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before this one.')    

  ;;wavelength info
  cwv = get_cwv(band,spectralchannels=(size(cube,/dim))[2])  

  ;;get user inputs
  refinefits = fix(Modules[thisModuleIndex].refine_fits)
  indx = fix(Modules[thisModuleIndex].reference_index)
  winap = fix(Modules[thisModuleIndex].search_window)
  gaussap = fix(Modules[thisModuleIndex].gauss_window)
  gaussfit = fix(Modules[thisModuleIndex].gauss_fit)
  loc_input = fix(Modules[thisModuleIndex].loc_input)
  case loc_input of 
     0:
     1: begin
        approx_loc = readfits(Modules[thisModuleIndex].CalibrationFile)
        if (n_elements(approx_loc) eq 1) && (approx_loc eq -1) then $
           return, error('FAILURE ('+functionName+'): Invalid calibration file.')   
     end
     2: begin
        approx_loc[0,0]=fix(Modules[thisModuleIndex].x1)
        approx_loc[0,1]=fix(Modules[thisModuleIndex].y1)
        approx_loc[1,0]=fix(Modules[thisModuleIndex].x2)
        approx_loc[1,1]=fix(Modules[thisModuleIndex].y2)
        approx_loc[2,0]=fix(Modules[thisModuleIndex].x3)
        approx_loc[2,1]=fix(Modules[thisModuleIndex].y3)
        approx_loc[3,0]=fix(Modules[thisModuleIndex].x4)
        approx_loc[3,1]=fix(Modules[thisModuleIndex].y4)
        approx_locs = transpose(approx_loc)
     end
  endcase
  
  fluxes = get_sat_fluxes(cube,band=band, indx=indx, $                  ;inputs
                          good=good,cens=cens,warns=warns,$             ;outputs
                          gaussfit=gaussfit,refinefits=refinefits,$     ;options
                          winap=winap,gaussap=gaussap,locs=approx_locs) ;optional inputs
  

  ;;write spot results to header
  backbone->set_keyword,"SPOTWAVE", cwv.lambda[indx], "Wavelength of ref for SPOT locations", ext_num=1
  for s=0,(size(cube,/dim))[2] - 1 do begin
     for j = 0,3 do begin
        backbone->set_keyword,'SATS'+strtrim(s,2)+'_'+strtrim(j,2),$
                              string(strtrim(cens[*,j,s],2),format='(2(F6.2," "))'),$
                              'Location of sat. spot '+strtrim(j,2)+' of slice '+strtrim(s,2),$
                              ext_num=1
     endfor
  endfor
  ;;convert good elements to HEX
  goodcode = ulon64arr((size(cube,/dim))[2])
  goodcode[good] = 1
  ;print,string(goodcode,format='('+strtrim(n_elements(goodcode),2)+'(I1))')
  gooddec = ulong64(0)
  for j=n_elements(goodcode)-1,0,-1 do gooddec += goodcode[j]*ulong64(2)^ulong64(n_elements(goodcode)-j-1)
  goodhex = strtrim(string(gooddec,format='((Z))'),2)
  backbone->set_keyword,'SATSFOUND',goodhex,'HEX representation of slices where sat spots were found.',ext_num=1

;  ;;converting back to bin
;  dec = ulong64(0)
;  reads,goodhex,dec,format='(Z)'
;  goodbin = string(dec,format='(B+'+strtrim((size(cube,/dim))[2],2)+'.'+strtrim((size(cube,/dim))[2],2)+')')
;  goodcode2 = ulonarr((size(cube,/dim))[2])
;  for j=0,n_elements(goodcode2)-1 do goodcode2[j] = long(strmid(goodbin,j,1))
  
  suffix+='-spotloc'

  ; Set keywords for outputting files into the Calibrations DB
 ; if numext eq 0 then begin
    hdrphu=*dataset.headersPHU[numfile]
    hdrext=*dataset.headersExt[numfile]
    sxaddpar, hdrphu, "FILETYPE", "Spot Location Measurement", "What kind of IFS file is this?"
    sxaddpar, hdrphu,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'  

;    sxaddpar, *(dataset.headers[numfile]), "FILETYPE", "Spot Location Measurement", "What kind of IFS file is this?"
;    sxaddpar, *(dataset.headers[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
;  endif else begin
;  backbone->set_keyword, "FILETYPE", "Spot Location Measurement", "What kind of IFS file is this?", ext_num=0
;  backbone->set_keyword,"ISCALIB", "YES", 'This is a reduced calibration file of some type.', ext_num=0
;;    sxaddpar, *(dataset.headersPHU[numfile]), "FILETYPE", "Spot Location Measurement", "What kind of IFS file is this?"
;;    sxaddpar, *(dataset.headersPHU[numfile]),  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
;  endelse
    sxdelpar,hdrext,"NAXIS3"

if fix(Modules[thisModuleIndex].ReuseOutput) eq 0 then begin
   if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, savedata=[transpose(PSFcenter),spotloc2],savephu=hdrphu,saveheader=hdrext)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif 

  return, ok
endif else begin
  *(dataset.currframe[0])=[transpose(PSFcenter),spotloc2]
  @__end_primitive
endelse


end
