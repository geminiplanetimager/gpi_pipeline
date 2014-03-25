;+
; NAME: subtract_mean_stellar_polarization.pro
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Mean Stellar Polarization
;
;		Subtract an estimate of the stellar polarization, measured from
;		the mean polarization inside the occulting spot radius. 
;
; INPUTS: Coronagraphic mode Stokes Datacube
;
; OUTPUTS: That datacube with an estimated stellar polarization subtracted off. 
;
; PIPELINE COMMENT: This description of the processing or calculation will show ; up in the Recipe Editor GUI. This is an example template for creating new ; primitives. It multiples any input cube by a constant value.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; 
; PIPELINE ORDER: 5.0
;
; PIPELINE CATEGORY: PolarimetricScience
;
; HISTORY:
;    2014-03-23 MP: Started
;-  

function gpi_subtract_mean_stellar_polarization, DataSet, Modules, Backbone
compile_opt defint32, strictarr, logical_predicate

primitive_version= '$Id: __template.pro 2340 2014-01-06 16:52:56Z ingraham $' ; get version from subversion to store in header history


@__start_primitive
suffix='stokesdc_sub' 		 ; set this to the desired output filename suffix


	center = [127, 152] ; hard coded for HD 141569 output files for now. 

	sz = size(*dataset.currframe)

	indices, (*dataset.currframe)[*,*,0], center=center,r=r


	ifsfilt = backbone->get_keyword('IFSFILT',/simplify)
	; size of occulting masks in milliarcsec
	case ifsfilt of
	'Y': fpm_diam = 156
	'J': fpm_diam = 184
	'H': fpm_diam = 246
	'K1': fpm_diam = 306
	'K2': fpm_diam = 306
	endcase
	fpm_diam *= 1./1000 /gpi_get_constant('ifs_lenslet_scale')

	wfpm = where(r lt (fpm_diam / 2))


	totalint = (*dataset.currframe)[*,*,0]
	q_div_i = (*dataset.currframe)[*,*,1]/totalint
	u_div_i = (*dataset.currframe)[*,*,2]/totalint
	v_div_i = (*dataset.currframe)[*,*,3]/totalint

	mean_q = mean(q_div_i[wfpm])
	mean_u = mean(u_div_i[wfpm])
	mean_v = mean(v_div_i[wfpm])


	modified_cube = *dataset.currframe
	
	modified_cube[*,*,1] -= totalint * mean_q
	modified_cube[*,*,2] -= totalint * mean_u
	modified_cube[*,*,3] -= totalint * mean_v

	stop

	backbone->set_keyword,'HISTORY',functionname+ " Subtracting estimated mean apparent stellar pol"
	backbone->set_keyword,'STELLARQ', mean_q, "Estimated apparent stellar Q/I from behind FPM"
	backbone->set_keyword,'STELLARU', mean_u, "Estimated apparent stellar U/I from behind FPM"
	backbone->set_keyword,'STELLARV', mean_v, "Estimated apparent stellar V/I from behind FPM"


	*dataset.currframe = modified_cube

@__end_primitive

end
