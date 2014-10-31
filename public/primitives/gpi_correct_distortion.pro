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
; PIPELINE ORDER: 2.44
; PIPELINE CATEGORY: SpectralScience,PolarimetricScience
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   2013-04-23 Major change of the code, now based on Quinn's routine for distortion correction - JM
;   2013-07-16 MP: Rename for consistency
;	2013-12-16 MP: CalibrationFile argument syntax update.
;	2014-05-10 MP: Update to enable this to work before or after accumulate
;	images. 
;- 

function gpi_correct_distortion_one, image, parms

	sz=(size(image))
	x0 = 140.  ;center of cube slice
	y0 = 140.  ; center of cube slice
	
    
    a=parms[*,0]
    b=parms[*,1]
    
    
    ;;; 3. Set up x and y coordinate arrays
  xobs = REBIN(FINDGEN(sz[1],1),sz[1],sz[2])
  x1 = xobs - x0
  yobs = REBIN(FINDGEN(1,sz[2]),sz[1],sz[2])
  y1 = yobs - y0

;;; 4. Perform forward transformation (x -> x')
  xp = 140.+POLYSOL(x1,y1,a)
  yp = 140.+POLYSOL(x1,y1,b)

;;; 5. Bilinearly interpolate output image at negative offset locations
  ix = 2*xobs - xp
  jy = 2*yobs - yp
  
  for ii=0, sz[3]-1 do begin
    im_in=image[*,*,ii]
    im_out = BILINEAR(im_in,ix,jy)
    image[*,*,ii]=im_out
  endfor

  return, image

end

;-------------------------

function gpi_correct_distortion, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history

calfiletype='distor' 
@__start_primitive

	cubef3D=*(dataset.currframe)

    parms= gpi_readfits(c_File, header=Headercal)
	
	suffix+='_distorcorr'

	; are we reducing one file at a time, or are we dealing with a set of
	; multiple files?
	reduction_level = backbone->get_current_reduction_level() 

	case reduction_level of
	1: begin ;---------  Rotate one single file ----------
		cube=*(dataset.currframe)
		*(dataset.currframe) = gpi_correct_distortion_one(cube, parms)

		backbone->set_keyword, "HISTORY", "Applied distortion correction"
		backbone->set_keyword, "DRPDSTCR", "Yes", 'Distortion correction applied?'

		@__end_primitive
	end
	2: begin ;----- Rotate all files stored in the accumulator ------

		backbone->Log, "This primitive is after Accumulate Images so this is a Level 2 step", depth=3
		backbone->Log, "Therefore all currently accumulated cubes will be undistorted.", depth=3
		nfiles=dataset.validframecount
		for i=0,nfiles-1 do begin

			backbone->Log, "Undistorting cube "+strc(i+1)+" of "+strc(nfiles), depth=3
			original_cube =  accumulate_getimage(dataset,i,hdr,hdrext=hdrext)

			undistorted_cube = gpi_correct_distortion_one(original_cube, parms)

			backbone->set_keyword, "HISTORY", "Applied distortion correction", indexFrame=i
			backbone->set_keyword, "DRPDSTCR", "Yes", 'Distortion correction applied?', indexFrame=i

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
