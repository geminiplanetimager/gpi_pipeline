;+
; NAME:  get_spectral_response
;
;	Return the combined throughput of the instrument and telluric transmission 
;
;	This is based on measured throughput for each band.
;
; INPUTS:
; mode= 'coronagraphic' for standard occulted observations | 'direct' for open lyot, clear apod
;	ifsfilt=	name of IFS filter
;
; OUTPUTS:
; throughput
;
; HISTORY:
;	2014-03-31 JM	created, based on Patrick's ideas
;-


pro get_spectral_response, mode=mode, ifsfilt=ifsfilt, throughput_struc=throughput_struc

	if ~keyword_set(ifsfilt) || (n_elements(ifsfilt) eq 0) then ifsfilt='H'
	if ~keyword_set(mode) || (n_elements(mode) eq 0) then mode='coronagraphic'
	
	;get the transmission from config directory
	case strc(strlowcase(mode)) of 
	  'coronagraphic':	throughput_file = gpi_get_directory('DRP_CONFIG') + path_sep() + 'throughput.fits'
      'direct':   throughput_file = gpi_get_directory('DRP_CONFIG') + path_sep() + 'throughput_openLyot_openApod.fits'
    else: begin
      message,"Invalid/unknown value for Mode (use coronographic or direct): "+mode
    end
      endcase
      
      throughput_allbands= readfits(throughput_file,/silent)
      
      ;wav_through = {wavelength:im[*,0], throughput:im[*,1]}
      
      case ifsfilt of 
        'Y': begin
              throughput=throughput_allbands[0:36,1]
              wavelength=throughput_allbands[0:36,0]
            end
        'J': begin
              throughput=throughput_allbands[37:73,1]
              wavelength=throughput_allbands[37:73,0]
            end
        'H': begin
              throughput=throughput_allbands[74:110,1]
              wavelength=throughput_allbands[74:110,0]
             end 
        'K1':begin
              throughput=throughput_allbands[111:147,1]
              wavelength=throughput_allbands[111:147,0]
              end
        'K2':begin
              throughput=throughput_allbands[148:184,1]
              wavelength=throughput_allbands[148:184,0]
              end
		else: begin
			message,"Invalid/unknown value for IFSFILT: "+ifsfilt
		end
      endcase
 
  throughput_struc = {wavelength:wavelength, throughput:throughput}

end
