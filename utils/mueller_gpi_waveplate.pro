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
        'Y': M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9998,0.0186],[0,0,-0.0186,-0.9998]]
        'J': M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9970,0.0772],[0,0,-0.0772,-0.9970]]
        'H': M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9924,0.1228],[0,0,-0.1228,-0.9924]] ; 0.480405 waves?? where is this value from?
        'K1':M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9996,0.0266],[0,0,-0.0266,-0.9996]]
        'K2':M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9973,-0.0729],[0,0,0.0729,-0.9973]]
		else: begin
			message,"Invalid/unknown value for IFSFILT: "+ifsfilt
		end
      endcase
 
  ; Rotate the mueller matrix to the requested position angle.
  mueller = mueller_rot(-angle)##M##mueller_rot(angle) 

	return, mueller


end
