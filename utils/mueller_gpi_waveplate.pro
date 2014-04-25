;+
; NAME:  mueller_gpi_waveplate
;
;	Return the Mueller matrix for the GPI half wave plate
;
;	This is based on measured retardances for each band.
;	See mueller_retarder_rotated for arbitrary retardances
;
; INPUTS:
;	ifsfilt=	name of IFS filter
;	angle=		Rotation angle for the waveplate, by default in radians
;   /degrees	specifies that the angle is given in degrees
;
; OUTPUTS:
;
; HISTORY:
;	2014-02-28	forked and renamed from dst_waveplate
;-


function mueller_gpi_waveplate, ifsfilt=ifsfilt, angle=angle, degrees=degrees

	if n_elements(angle) eq 0 then angle=0.0
	if keyword_set(degrees) then angle = angle*!dtor ; convert to radians


      case ifsfilt of 
        'Y': M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9997,0.0258],[0,0,-0.0258,-0.9997]] ;0.4959 Waves
        'J': M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9963,0.0860],[0,0,-0.0860,-0.9963]] ;0.4863 Waves
        'H': M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9977,0.1134],[0,0,-0.1134,-0.9977]] ;0.4819 Waves
        'K1':M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9994,0.0345],[0,0,-0.0345,-0.9994]] ;0.4945 Waves
        'K2':M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9986,-0.0534],[0,0,0.0534,-0.9986]] ;0.5085 Waves
		else: begin
			message,"Invalid/unknown value for IFSFILT: "+ifsfilt
		end
      endcase
 
  ; Rotate the mueller matrix to the requested position angle.
  mueller = mueller_rot(-angle)##M##mueller_rot(angle) 

	return, mueller


end
