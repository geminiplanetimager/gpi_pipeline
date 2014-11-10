;+
; NAME:   mueller_gpi_instr_pol
;
;	Return Mueller Matrix for GPI instrumental polarization
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;	Began 2014-03-20 by Marshall Perrin, refactored from DST_instr_pol which
;					 dates back to 2008
;-


function mueller_gpi_instr_pol, port=port, ifsfilt=ifsfilt

 if ~keyword_set(ifsfilt) then return, error("mueller_gpi_instr_pol: You must specify which IFS filter you want the instrumental polarization for.")
 if ~(keyword_set(port)) then return, error("mueller_gpi_instr_pol: You must specify which ISS port GPI is mounted onto.")

; Step 1: Compute the Mueller matrix corresponding to the telescope's 
; instrumental polarization.

; We take this from the GPI optical model in ZEMAX and Matlab 
; by J. Atwood, K. Wallace and J. R. Graham
;  - see the OCDD appendix 15. 

;The instrumental mueller matrices 

; Where is GPI mounted? 

case port of 
	"side": system_mueller = [ $
			[0.5263, 0.0078, 0.0006, 0.0000], $
			[0.0078, 0.5263, -0.0001, 0.0063], $
			[0.0006, 0.0012, 0.5182, -0.0920], $
			[0.0000, -0.0062, 0.0920, 0.5181] $
			]
	"bottom": begin
	          print, "No system mueller matrix for bottom port yet!"
	          print, "Using a perfect telescope mueller matrix for now"
	          system_mueller = [ $
            [ 1.0, 0.0, 0.0, 0.0 ], $
            [ 0.0, 1.0, 0.0, 0.0 ], $
            [ 0.0, 0.0, 1.0, 0.0 ], $
            [ 0.0, 0.0, 0.0, 1.0 ] $
            ]
            end
	"perfect": system_mueller = [ $
			[ 1.0, 0.0, 0.0, 0.0 ], $
			[ 0.0, 1.0, 0.0, 0.0 ], $
			[ 0.0, 0.0, 1.0, 0.0 ], $
			[ 0.0, 0.0, 0.0, 1.0 ] $
			]
endcase

;Insert the instrumental polarization measured in the UCSC lab


 print, "Using the instrumental polarization matrix from the "+ifsfilt+" band"
 case ifsfilt of 
    'Y': M_IP=[[1.,0,0,0],[-0.024, 0.94, 0.04, 0.26], [-0.026, -0.099, 0.94, 0.16], [0.04, 0.8, 0.9, -0.4]]
    'J': M_IP=[[1.,0,0,0], [-0.024, 0.95, 0.049, 0.25], [-0.018, -0.108, 0.95, 0.09], [0.1, 0.1, 0.4, -2.8]]
    'H': M_IP=[[1.,0,0,0], [-0.022, 0.96, 0.054, 0.19], [-0.009, -0.097, 0.96, 0.01], [0.04, 0.22, 0.17, -1.2]]
    'K1':M_IP=[[1.,0,0,0], [-0.007, 0.97, 0.071, 0.15], [-0.009, -0.1, 0.96, 0.036], [0.3,0.3, 0.9, -1.0]]
    'K2': begin
          M_IP=[[1.,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
          print, "No instrumental polarization matrix measured in the lab"
          print, "Instead using an indentity matrix"
          end
	else: return, error(functionname+": The supplied IFSFILT value is not valid: "+strc(ifsfilt))
 endcase


return, M_IP##system_mueller

end


