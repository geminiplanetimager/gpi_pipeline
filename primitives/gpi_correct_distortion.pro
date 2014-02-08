;+
; NAME: gpi_correct_distortion
; PIPELINE PRIMITIVE DESCRIPTION: Correct Distortion
;
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Correct GPI distortion
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="string" CalFileType="distorcal" Default="AUTOMATIC" Desc="Filename of the desired distortion calibration file to be read"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="10" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.44
; PIPELINE NEWTYPE: SpectralScience,PolarimetricScience
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;   2013-04-23 Major change of the code, now based on Quinn's routine for distortion correction - JM
;   2013-07-16 MP: Rename for consistency
;	2013-12-16 MP: CalibrationFile argument syntax update.
;- 

function gpi_correct_distortion, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history

calfiletype='distor' 
@__start_primitive

	cubef3D=*(dataset.currframe[0])

	sz=(size(cubef3D))
	x0 = 140.  ;center of cube slice
	y0 = 140.  ; center of cube slice
	

    parms= gpi_readfits(c_File, header=Headercal)
    
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
    im_in=cubef3D[*,*,ii]
    im_out = BILINEAR(im_in,ix,jy)
    cubef3D[*,*,ii]=im_out
  endfor
  *(dataset.currframe[0])=cubef3D
    
    

suffix+='_distorcorr'

@__end_primitive

end
