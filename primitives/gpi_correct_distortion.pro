;+
; NAME: gpi_correct_distortion
; PIPELINE PRIMITIVE DESCRIPTION: Correct Distortion
;	
;	Corrects distortion by bilinear resampling of the
;	input datacube according to a predetermined distortion solution.
;
;	Note that this primitive can go *either* before or after
;	Accumulate Images. 
;	As a Level 1 primitive, it will undistort one cube at a time; 
;	As a Level 2 primitive it will undistort the whole stack of 
;	accumulated images all at once.
;
;	This primitive *MUST* be run before the 'Measure Satellite spot locations' primitive
;
;
; INPUTS: spectral or polarimetric datacube 
;
;
;
; OUTPUTS:  Distortion-corrected datacube
;
; PIPELINE COMMENT: Correct GPI distortion
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="string" CalFileType="distorcal" Default="AUTOMATIC" Desc="Filename of the desired distortion calibration file to be read"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="10" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.43
; PIPELINE CATEGORY: SpectralScience,PolarimetricScience
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   2013-04-23 Major change of the code, now based on Quinn's routine for distortion correction - JM
;   2013-07-16 MP: Rename for consistency
;	2013-12-16 MP: CalibrationFile argument syntax update.
;	2014-05-10 MP: Update to enable this to work before or after accumulate
;	images. 
;   2015-02-20 MPF: Re-worked routine to preserve flux.
;- 



; convert coefficient vectors to 2d coefficient arrays
pro get_ca_cb, a, b, ca, cb

  na = n_elements(a)
  nb = n_elements(b)
  if na ne nb then message, /trace, 'coefficient arrays not the same length'

  deg = round((sqrt(1+8*na)-3)/2.)

  ca = dblarr(deg+1, deg+1)
  cb = dblarr(deg+1, deg+1)
  j = 0

  for k = 0, deg do $
     for i = 0, k do begin
       ca[k-i, i] = a[j]
       cb[k-i, i] = b[j]
       j += 1
     endfor
  
end


; evaluate a 2d polynomial.  c is a 2d coefficient array.  the
; polynomial evaluated is the sum of c[i,j] * x**i * y**j
function polyval2d, x, y, c
  sz = size(c)
  nx = sz[1]                    ; order of x values
  ny = sz[2]                    ; order of y values

  ;; compute power arrays
  sz = size(x)
  xx = dblarr(sz[1], sz[2], nx)
  yy = dblarr(sz[1], sz[2], ny)
  for i = 0, nx-1 do xx[*, *, i] = x^i
  for j = 0, ny-1 do yy[*, *, j] = y^j

  ;; evaluate polynomial
  v = dblarr(sz[1], sz[2])
  for i = 0, nx-1 do $
    for j = 0, ny-1 do $
      v += c[i, j] * xx[*, *, i] * yy[*, *, j]

  return, v
end



; evaluate the determinant of the Jacobian of the polynomial
; transformation paramaterized by ca, cb
function get_Jacobian_det, x, y, ca, cb

  ;; flatten arrays
  szx = size(x)
  if szx[0] eq 2 then begin
    xx = reform(x, szx[1]*szx[2])
    yy = reform(y, szx[1]*szx[2])
  endif else begin
    xx = x
    yy = y
  endelse  
  
  ;; constants for taking derivatives
  sz = size(ca)
  c1 = rebin(dindgen(sz[1]-1, 1)+1, sz[1]-1, sz[2])
  c2 = rebin(dindgen(1, sz[2]-1)+1, sz[1], sz[2]-1)

  ;; evaluate polynomial derivatives
  dF1dx = polyval2d(x, y, c1*ca[1:*, *])
  dF1dy = polyval2d(x, y, ca[*, 1:*]*c2)
  dF2dx = polyval2d(x, y, c1*cb[1:*, *])
  dF2dy = polyval2d(x, y, cb[*, 1:*]*c2)

  detJ = dblarr(szx[1]*szx[2])
  for i = 0L, szx[1]*szx[2]-1 do begin
    ;; compute Jacobian
    J = [[dF1dx[i], dF1dy[i]], [dF2dx[i], dF2dy[i]]]
  
    ;; compute determinant
    detJ[i] = determ(J)
  endfor

  ;; reform array in 2d if necessary
  if szx[0] eq 2 then detJ = reform(detJ, szx[1], szx[2])

  return, detJ
end


; distortion transformation in coordinate space
pro gpi_undistorted_to_distorted, x, y, parms, u, v

  ;; dimensions
  xc = 140.                     ; center of cube slice (undistorted)
  yc = 140.                     ; center of cube slice (undistorted)
  uc = xc                       ; center of cube slice (distorted)
  vc = yc                       ; center of cube slice (distorted)

  ;; get polynomial coefficient arrays
  a = parms[*, 0]
  b = parms[*, 1]
  get_ca_cb, a, b, ca, cb
  

  ;; perform forward transformation (x,y) -> (u,v) undistorted to distorted
  u = polyval2d(x-xc, y-yc, ca) + uc
  v = polyval2d(x-xc, y-yc, cb) + vc

end




; correct distortion in a data cube
function gpi_correct_distortion_one, image, parms

  ;; dimensions
  sz = (size(image))
  xc = 140.                     ; center of cube slice (undistorted)
  yc = 140.                     ; center of cube slice (undistorted)
  uc = xc                       ; center of cube slice (distorted)
  vc = yc                       ; center of cube slice (distorted)

  ;; get polynomial coefficient arrays
  a = parms[*, 0]
  b = parms[*, 1]
  get_ca_cb, a, b, ca, cb
  

  ;; get x,y coordinates in undistorted space, centered on image center
  x = rebin(dindgen(sz[1], 1), sz[1], sz[2]) - xc
  y = rebin(dindgen(1, sz[2]), sz[1], sz[2]) - yc


  ;; perform forward transformation (x,y) -> (u,v) undistorted to distorted
  u = polyval2d(x, y, ca) + uc
  v = polyval2d(x, y, cb) + vc

  ;; compute Jacobian determinant
  detJ = get_Jacobian_det(x, y, ca, cb)
  absdetJ = abs(detJ)
  
  ;; interpolate each image
  for ii = 0, sz[3]-1 do begin
    im_in = image[*, *, ii]
    ;im_out = bilinear(im_in, u, v) ; bilinear interpolation
    im_out = interpolate(im_in, u, v, cubic = -0.5, missing = !values.f_nan)
    image[*, *, ii] = im_out*absdetJ
  endfor

  return, image

end


; test routine
pro test_gpi_correct_distortion_one
  ;; parameters for transform
  a = [0., 1.841e-3, 1.000e0, -2.273e-4, -3.613e-3, -9.666e-3]
  b = [0., 9.998e-1,  4.230e-5, -1.184e-3, -6.588e-3, 6.869e-4]
  parms = [[a], [b]]
  
  ;; pixel locations in distorted space
  u = rebin(dindgen(280, 1), 280, 280)
  v = rebin(dindgen(1, 280.), 280, 280)

  ;; image data in distorted space
  sig = 5.
  u0 = 40.
  v0 = 30.
  dist_im = exp(-((u-u0)^2 + (v-v0)^2)/2./sig^2)
  dist_im /= total(dist_im)

  ;; get undistorted image
  input = reform(dist_im, 280, 280, 1)
  output = gpi_correct_distortion_one(input, parms)

  print, total(dist_im), total(output)

  ;stop
end



;-------------------------

function gpi_correct_distortion, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history

calfiletype='distor' 
@__start_primitive

  cubef3D = *(dataset.currframe)

  parms = gpi_readfits(c_File, header = Headercal, priheader = Priheadercal)
  distsol_verstr = sxpar(Priheadercal, 'DISTVER', count = ct)
  if ct eq 0 then begin
    distsol_verstr = '0'
    message, /info, "No version code found in distortion solution calibration file header.  Assuming version "+distsol_verstr
  endif
      
  distsol_ver = strsplit(distsol_verstr, '.', /extract)
  if fix(distsol_ver[0]) lt 1 then $
     return, error('FAILURE ('+functionName+'): Distortion solution version '+distsol_ver+' found, but require at least version 1. Please download updated file from Gemini GPI public data web page.')
  
  
  suffix += '_distorcorr'

  ;; are we reducing one file at a time, or are we dealing with a set of
  ;; multiple files?
  reduction_level = backbone -> get_current_reduction_level() 

  case reduction_level of
    1: begin                    ;---------  Rotate one single file ----------
      cube = *(dataset.currframe)
		
      ;; check to make sure that no satellite locations exist
      ;; this primitive must be run BEFORE satellite locations are determined
      test = (backbone -> get_keyword('SPOTWAVE', count = c))
      if c ne 0 then return, error('FAILURE ('+functionName+'): Satellite spot locations have been determined previously. This primitive must be run BEFORE measuring the satellite spot locations.') 

      *(dataset.currframe) = gpi_correct_distortion_one(cube, parms)

      backbone -> set_keyword, "HISTORY", "Applied distortion correction"
      backbone -> set_keyword, "HISTORY", "Using distortion solution version "+distsol_verstr
      backbone -> set_keyword, "DRPDSTCR", "Yes", 'Distortion correction applied?'
      
      @__end_primitive
    end
    2: begin           ;----- Rotate all files stored in the accumulator ------

      backbone -> Log, "This primitive is after Accumulate Images so this is a Level 2 step", depth = 3
      backbone -> Log, "Therefore all currently accumulated cubes will be undistorted.", depth = 3
      nfiles = dataset.validframecount
      for i = 0, nfiles-1 do begin

        backbone -> Log, "Undistorting cube "+strc(i+1)+" of "+strc(nfiles), depth = 3
        original_cube =  accumulate_getimage(dataset, i, hdr, hdrext = hdrext)
			
        ;; check to make sure that no satellite locations exist
        ;; this primitive must be run BEFORE satellite locations are determined

        test = sxpar(hdrext, 'SPOTWAVE', count = c)
        if c ne 0 then return, error('FAILURE ('+functionName+'): Satellite spot locations have been determined previously. This primitive must be run BEFORE measuring the satellite spot locations.') 

        undistorted_cube = gpi_correct_distortion_one(original_cube, parms)

        backbone -> set_keyword, "HISTORY", "Applied distortion correction", indexFrame = i
        backbone -> set_keyword, "HISTORY", "Using distortion solution version "+distsol_verstr
        backbone -> set_keyword, "DRPDSTCR", "Yes", 'Distortion correction applied?', indexFrame = i

        accumulate_updateimage, dataset, i, newdata = undistorted_cube

      endfor


    end
  endcase


;
;
;
;	sz=(size(cubef3D))
;	x0 = 140.  ;center of cube slice
;	y0 = 140.  ; center of cube slice
;	
;
;    
;    a=parms[*,0]
;    b=parms[*,1]
;    
;    
;    ;;; 3. Set up x and y coordinate arrays
;  xobs = REBIN(FINDGEN(sz[1],1),sz[1],sz[2])
;  x1 = xobs - x0
;  yobs = REBIN(FINDGEN(1,sz[2]),sz[1],sz[2])
;  y1 = yobs - y0
;
;;;; 4. Perform forward transformation (x -> x')
;  xp = 140.+POLYSOL(x1,y1,a)
;  yp = 140.+POLYSOL(x1,y1,b)
;
;;;; 5. Bilinearly interpolate output image at negative offset locations
;  ix = 2*xobs - xp
;  jy = 2*yobs - yp
;  
;  for ii=0, sz[3]-1 do begin
;    im_in=cubef3D[*,*,ii]
;    im_out = BILINEAR(im_in,ix,jy)
;    cubef3D[*,*,ii]=im_out
;  endfor
;  *(dataset.currframe[0])=cubef3D
;    
;    


;@__end_primitive

end
