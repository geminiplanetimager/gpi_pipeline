;+
; NAME: gpi_klip_algorithm_angular_differential_imaging_pol
; PIPELINE PRIMITIVE DESCRIPTION: KLIP ADI for Pol Mode
;
;   This algorithm reduces PSF speckles in a datacube using the
;   KLIP algorithm and Angular Differential Imaging in Pol Mode
;
; ALGORITHM:
;       Star location must have been previously measured using satellite spots.
;       Measure annuli out from the center of the cube and create a
;       reference set for each annuli of each slice. Apply KLIP to the
;       reference set and project the target slice onto the KL
;       transform vector. Subtract the projected image from the
;       original and repeat for all slices
;
; INPUTS: Multiple spectral datacubes
; OUTPUTS: A reduced datacube with reduced PSF speckle halo
;
;
; PIPELINE COMMENT: Reduce speckle noise using the KLIP algorithm with ADI data
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="annuli" Type="int" Range="[0,100]" Default="0" Desc="Number of annuli to use"
; PIPELINE ARGUMENT: Name="MinRotation" Type="float" Range="[0.0,360.0]" Default="1" Desc="Minimum rotation between images (degrees)"
; PIPELINE ARGUMENT: Name="CollapsePol" Type="int" Range="[0,1]" Default="0" Desc="Collapse the pol cube and perform KLIP on the total intensity?"
; PIPELINE ARGUMENT: Name="prop" Type="float" Range="[0.8,1.0]" Default=".99999" Desc="Proportion of eigenvalues used to truncate KL transform vectors"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="5" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.2
; PIPELINE CATEGORY: PolarimetricScience
;
; HISTORY:
;        2013-10-21 - ds
;        2014-03-23 - MMB: Started adjusting for pol mode
;-

function gpi_klip_algorithm_angular_differential_imaging_pol, DataSet, Modules, Backbone
  primitive_version= '$Id$' ; get version from subversion to store in header history
  @__start_primitive
  
  if numfile ne ((dataset.validframecount)-1) then return, OK
  
  ; Verify this is in fact polarization mode data
  mode= strc(backbone->get_keyword( "DISPERSR", count=ct))
  mode = strlowcase(mode)
  if ~strmatch(mode,"*wollaston*",/fold) then begin
    backbone->Log, "ERROR: That's not a polarimetry file!"
    return, not_ok
  endif
  
  ;; get some info about the dataset
  nlam = backbone->get_keyword('NAXIS3',indexFrame=0, count=ct) ; This should be 2 for podc frames mode
  dim = [backbone->get_keyword('NAXIS1',indexFrame=0, count=ct1),backbone->get_keyword('NAXIS2',indexFrame=0, count=ct2)]
  if ct+ct1+ct2 ne 3 then return, error('FAILURE ('+functionName+'): Missing NAXIS* keyword(s).')
  
  nfiles=dataset.validframecount
  
  ;Make sure there's a filter keyword
  band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
  if ct eq 0 then return, error('FAILURE ('+functionName+'): Missing IFSFILT keyword.')
  
  cwv = get_cwv(band)
  
  ;;get PA angles and satspots of all images and check that they have
  ;;the same number of slices
  PAs = dblarr(dataset.validframecount)
  locs = dblarr(2,4,nlam,nfiles)
  cens = dblarr(2,nlam,nfiles)
  
  
  for j = 0, nfiles - 1 do begin
    PAs[j] = double(backbone->get_keyword('AVPARANG', indexFrame=j ,count=ct, ext_num=1))
    if ct eq 0 then return, error('FAILURE ('+functionName+'): Missing average parallactic angle in file'+string(j))
    
    if (backbone->get_keyword('NAXIS3',indexFrame=j) ne nlam) then $
      return, error('FAILURE ('+functionName+'): All cubes in dataset must have the same number of slices.')
      
    if ~strcmp(gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct)),band) then $
      return, error('FAILURE ('+functionName+'): All cubes in dataset must be in the same band.')
      
    ;tmp = gpi_satspots_from_header(*DataSet.HeadersExt[j])
    tmp1 = string(backbone->get_keyword('PSFCENTX', indexFrame=j, count=ct1))
    tmp2 = string(backbone->get_keyword('PSFCENTY', indexFrame=j, count=ct1))
    
    if ct1+ct2 ne 2 then $
      return, error('FAILURE ('+functionName+'): Star Position Not Found in file'+string(j));+string(*(dataset.frames[j])))
      
    for k = 0,nlam-1 do cens[*,k,j] = [tmp1,tmp2]
    
  endfor
  
  ;;get user inputs
  annuli=long(Modules[thisModuleIndex].annuli)
  minrot=double(Modules[thisModuleIndex].minRotation)
  prop=double(Modules[thisModuleIndex].prop)
  
  ;;get the status console and number of modules
  statuswindow = backbone->getstatusconsole()
  nummodules = double(N_ELEMENTS(Modules))
  
  ;;get the pixel scale, telescope diam  and define conversion factors
  ;;and figure out IWA in pixels
  pixscl = gpi_get_ifs_lenslet_scale(*DataSet.HeadersExt[numfile]) ;as/lenslet
  rad2as = 180d0*3600d0/!dpi                                       ;rad->as
  tel_diam = gpi_get_constant('primary_diam',default=7.7701d0)     ;m
  IWA = 2.8d0 * (cwv.commonwavvect)[0]*1d-6/tel_diam*rad2as/pixscl ; 2.8 l/D (pix)
  OWA = 44d0 * (cwv.commonwavvect)[0]*1d-6/tel_diam*rad2as/pixscl  ;
  waffle = OWA*sqrt(2);/2*sqrt(2)                                           ;radial location of MEMS waffle
  
  if ceil(waffle) - floor(IWA) lt annuli*2 then $
    return,error('INPUT ERROR ('+functionName+'): Your requested annuli will be smaller than 2 pixels.')
    
  ;;figure out starting and ending points of annuli and their centers
  case annuli of
    0: rads = [0,max(dim)+1]
    1: rads = [floor(IWA),ceil(waffle)]
    else: begin
      if keyword_set(eqarea) then begin
        rads = dblarr(annuli+1)
        rads[0] = floor(IWA)
        rads[n_elements(rads)-1] = ceil(waffle)
        A = !dpi*(rads[n_elements(rads)-1]^2d0 - rads[0]^2d0)
        for j = 1,n_elements(rads)-2 do rads[j] = sqrt(A/!dpi/annuli + rads[j-1]^2d0)
      endif else rads = round(dindgen(annuli+1d0) / (annuli) * (ceil(waffle) - floor(IWA)) + floor(IWA))
    end
  endcase
  if max(rads) lt max(dim)+1 then rads = [rads,max(dim)+1]
  radcents = (rads[0:n_elements(rads)-2]+rads[1:n_elements(rads)-1])/2d0
  
  ;;figure out total number of iterations
  totiter = (n_elements(rads)-1)*nlam*nfiles
  
  xs = reform(dindgen(dim[0]) # (dblarr(dim[1])+1d0),dim[0]*dim[1])
  ys = reform((dblarr(dim[0])+1d0) # dindgen(dim[1]),dim[0]*dim[1])
  ;imcent = (dim-1)/2. ;Original
  ;imcent = [cens[0,0,0],cens[1,0,0]] ;We'll center everything around the center of the first image
  imcent = [140,140] ; Let's center everything around 140,140 like in other modes. 
  
  rth = cv_coord(from_rect=transpose([[xs-imcent[0]],[ys-imcent[1]]]),/to_polar)
  rs = rth[1,*]
  
  ;;allocate output
  final_im = dblarr(dim[0],dim[1],nlam)
  
  ;;an array that keeps track of whether or not a pixel is nan for a given slice
  where_valid = intarr(dim[0],dim[1], nlam)
  
  nan_count = intarr(dim[0],dim[1])
  
  ;Are we collapsing the pol data cube?
  collapse=fix(Modules[thisModuleIndex].CollapsePol)
  ;if collapse eq 1 then nlam = 1
  
  if collapse eq 1 then imgs = dblarr(dim[0], dim[1], 1, nfiles) else imgs = dblarr(dim[0], dim[1], nlam, nfiles)
  
  for l=0,nfiles-1 do begin
    for ll=0,nlam-1 do begin
      if collapse eq 1 then begin
      imgs[*,*,0,l] += accumulate_getimage(dataset,l,slice=ll) 
      tmp_rot_img=rot(imgs[*,*,0,l],PAs[l],1.0, imcent[0], imcent[1], /interp,cubic=-0.5, /pivot)
    endif else begin
      imgs[*,*,ll,l] = accumulate_getimage(dataset,l,slice=ll)
      tmp_rot_img=rot(imgs[*,*,ll,l],PAs[l],1.0, imcent[0], imcent[1], /interp,cubic=-0.5, /pivot)
      endelse
    if collapse eq 1 then nlam = 1
    endfor
    
    nan_count[where(~finite(tmp_rot_img))] += 1
    ;nan_count[where(~finite(imgs[*,*,0]))] += 1
    
  endfor
  
  ;; do this by slice
  for l = 0,nlam-1 do begin
  
    R0 = dblarr(dim[0]*dim[1],nfiles)
    ;;get all of the data for the current slice & align image centers
    ;;to center pixel
    for imnum = 0,nfiles-1 do begin
      ;tmp =  accumulate_getimage(dataset,imnum, slice=l)
      R0[*,imnum] = interpolate(imgs[*,*,l,imnum],xs+cens[0,l,imnum]-imcent[0],ys+cens[1,l,imnum]-imcent[1],cubic=-0.5)
    endfor
    
    ;;apply KLIP to each annulus
    for radcount = 0,n_elements(rads)-2 do begin
      ;;rad range: rads[radcount]<= R <rads[radcount+1]
      radinds = where((rs ge rads[radcount]) and (rs lt rads[radcount+1]))
      R = R0[radinds,*] ;;ref set
      
      ;;check that you haven't just grabbed a blank annulus
      if (total(finite(R)) eq 0) then begin
        statuswindow->set_percent,-1,double(nfiles)/totiter*100d/nummodules,/append
        continue
      endif
      
      ;;create mean subtracted versions and get rid of NaNs
      mean_R_dim1=dblarr(N_ELEMENTS(R[0,*]))
      for zz=0,N_ELEMENTS(R[0,*])-1 do mean_R_dim1[zz]=mean(R[*,zz],/double,/nan)
      R_bar = R-matrix_multiply(replicate(1,n_elements(radinds),1),mean_R_dim1,/btranspose)
      naninds = where(R_bar ne R_bar,countnan)
      if countnan ne 0 then begin
        R[naninds] = 0
        R_bar[naninds] = 0
        naninds = array_indices(R_bar,naninds)
      endif
      
      ;;find covariance of all slices
      covar0 = matrix_multiply(R_bar,R_bar,/atranspose)/(n_elements(radinds)-1d0)
      
      ;;cycle through images
      for imnum = 0,nfiles-1 do begin
      
        ;;update progress as needed
        statuswindow->set_percent,-1,1d/totiter*100d/nummodules,/append
        
        ;;figure out which images are to be used
        fileinds = where(abs(PAs - PAs[imnum]) gt minrot, count)
        if count lt 2 then begin
          logstr = 'No reference slices available for requested motion. Skipping.'
          message,/info,logstr
          backbone->Log,logstr
          continue
        endif
        
        ;;grab covariance submatrix
        covar = covar0[fileinds,*]
        covar = covar[*,fileinds]
        
        ;;get the eigendecomposition
        residual = 1         ;initialize the residual
        evals = eigenql(covar,eigenvectors=evecs,/double,residual=residual)
        
        ;;determines which eigenalues to truncate
        evals_cut = where(total(evals,/cumulative) gt prop*total(evals))
        K = evals_cut[0]
        if K eq -1 then continue
        
        ;;creates mean subtracted and truncated KL transform vectors
        Z = evecs ## R_bar[*,fileinds]
        G = diag_matrix(sqrt(1d0/evals/(n_elements(radinds)-1)))
        
        Z_bar = G ## Z
        Z_bar_trunc=Z_bar[*,0:K]
        T = R_bar[*,imnum]
        ;;T = R[*,ref_value]
        
        ;;Project KL transform vectors and subtract from target
        signal_step_1 = matrix_multiply(T,Z_bar_trunc,/atranspose)
        signal_step_2 = matrix_multiply(signal_step_1,Z_bar_trunc,/btranspose)
        Test = T - transpose(signal_step_2)
        
        ;;restore,NANs,rotate estimate by -PA and add to output
        ;if countnan ne 0 then TEST[naninds[0,where(naninds[1,*] eq imnum)]] = !values.d_nan
        
        ;To help later with edge clipping we're putting back in the NAN for this temporary array
        out=dblarr(dim[0],dim[1])
        out[radinds]=test
        test=out
        tmp=dblarr(dim[0], dim[1])
        tmp[*]=test
        
        if countnan ne 0 then tmp[radinds[naninds[0,where(naninds[1,*] eq imnum)]]] = !values.d_nan
        
        ;Actually let's just make it zero, and then later when we divide by the number of files we'll
        ;divide by the number of files used
        ;if countnan ne 0 then Test[naninds[0,where(naninds[1,*] eq imnum)]] = 0
        
        ;Where there is a nan we don't count it.
        ;This ignores anywhere this is a nan. Need to center image properly.
        ;           tmp = intarr(n_elements(test))+1
        ;           tmp[naninds[0,where(naninds[1,*] eq imnum)]] = 0
        ;           tmp = reform(tmp,dim)
        tmp=reform(tmp,dim)
        rot_img = rot(tmp,PAs[imnum],1.0, imcent[0], imcent[1], /interp,cubic=-0.5, /pivot)
        where_valid_tmp = intarr(dim[0],dim[1])+1
      
        nanloc=where(~finite(rot_img),ct)
        if ct ne 0 then where_valid_tmp[nanloc] = 0
        
        ;Let's shave off the ugly pixels at the edge of the frame.
        ;To do this I will see if there is a NAN in a 5x5 box centered on the pixel
        
        test=reform(test,dim)
        
        test=rot(test,PAs[imnum],1.0, imcent[0], imcent[1], /interp,cubic=-0.5, /pivot)
        ;atv, test, /bl
        cut=2 ;How many pixels from the edge do you want to cut?
        for bb=cut, dim[0]-1-cut do $
          for vv=cut, dim[1]-1-cut do $
          ;if ~finite(total(rot_img[bb-2:bb+2,vv-2:vv+2])) or ~finite(total(tmp[bb-2:bb+2,vv-2:vv+2])) then begin
          if ~finite(total(rot_img[bb-cut:bb+cut,vv-cut:vv+cut])) then begin
          Test[bb,vv]=0
          where_valid_tmp[bb,vv] = 0
        endif
        ;         atv, test,/bl
        ;stop
        
        where_valid[*,*,l] += where_valid_tmp
        final_im[*,*,l] += test
        
      endfor
    endfor
    
    final_im[*,*,l] = final_im[*,*,l]/where_valid[*,*,l]
  endfor
  
  for l=0,nlam-1 do begin
    f=final_im[*,*,l]
    f[where(nan_count ge nfiles-1)]=!values.d_nan
    ;f[where(f eq 0.00)]=!values.d_nan
    final_im[*,*,l]=f
  endfor
  
  *(dataset.currframe[0]) = final_im
  suffix = suffix+'-klip'
  
  backbone->set_keyword,'HISTORY', functionname+": ADI KLIP applied.",ext_num=0
  
  ;;update WCS info
  gpi_update_wcs_basic,backbone,parang=0d0,imsize=dim
  
  ;;update satspot locations to new position and rotation
  ;  flocs = locs[*,*,*,numfile]
  ;  fcens = cens[*,*,numfile]
  ;  for j=0,1 do for k=0,nlam-1 do flocs[j,*,k] +=  imcent[j] - fcens[j,k]
  ;  gpi_rotate_header_satspots,backbone,PAs[numfile],flocs,imcent=imcent
  
  backbone->set_keyword, "FILETYPE", "Pol ADI KLIP" ; Need to fix this
  @__end_primitive
end



