;+
; NAME: gpi_tloci
; PIPELINE PRIMITIVE DESCRIPTION: Primitive to interface TLOCI code and dependecies for PSF subtraction with the GPI pipeline.
; 		
; INPUTS: data-cubes *spdc*
;
; KEYWORDS:
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: 
;
;
; PIPELINE COMMENT: Implements the TLOCI algorithm (Marois et al. 2014)
; PIPELINE ARGUMENT: Name="np" Type="float" Range="[0,20]" Default="1" Desc="Number of processors to use."
; PIPELINE ARGUMENT: Name="badpix" Type="int" Range="[0,1]" Default="0" Desc="Clean bad spaxels of each datacube?"
; PIPELINE ARGUMENT: Name="unshrpmsk" Type="int" Range="[0,1]" Default="0" Desc="Use unsharp mask?"
; PIPELINE ARGUMENT: Name="register" Type="int" Range="[0,1]" Default="0" Desc="Image registration?"
; PIPELINE ARGUMENT: Name="p_spec" Type="string" Range="[STRING]" Default="None" Desc="Planet spectrum filename."
; PIPELINE ARGUMENT: Name="s_spec" Type="string" Range="[STRING]" Default="None" Desc="Stellar spectrum filename."
; PIPELINE ARGUMENT: Name="coeff" Type="int" Range="[0,1]" Default="0" Desc="Positive Coeffecients?"
; PIPELINE ARGUMENT: Name="Lambda" Type="float" Range="[0,1]" Default="0.5" Desc="Lambda (Spectrum weighting)"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="10" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.11
; PIPELINE CATEGORY: SpectralScience
;
; HISTORY:
; 	 ZHD: Intial creation.
;-

function gpi_adi_with_loci, DataSet, Modules, Backbone

primitive_version= '$Id: gpi_adi_with_loci.pro 2511 2014-02-11 05:57:27Z mperrin $' ; get version from subversion to store in header history
@__start_primitive

;read input parameters and force default if in error
if tag_exist( Modules[thisModuleIndex], "np") eq 1 then np=long(Modules[thisModuleIndex].np) else np=1
if tag_exist( Modules[thisModuleIndex], "badpix") eq 1 then badpix=long(Modules[thisModuleIndex].np) else badpix=0
if tag_exist( Modules[thisModuleIndex], "unshrpmsk") eq 1 then unshrpmsk=long(Modules[thisModuleIndex].np) else unshrpmsk=0
if tag_exist( Modules[thisModuleIndex], "register") eq 1 then register=long(Modules[thisModuleIndex].np) else register=0
if tag_exist( Modules[thisModuleIndex], "p_spec") eq 1 then p_spec=strupcase(Modules[thisModuleIndex].p_spec) else p_spec="None"
if tag_exist( Modules[thisModuleIndex], "s_spec") eq 1 then s_spec=strupcase(Modules[thisModuleIndex].s_spec) else s_spec="None"
if tag_exist( Modules[thisModuleIndex], "coeff") eq 1 then coeff=long(Modules[thisModuleIndex].coeff) else coeff=0
if tag_exist( Modules[thisModuleIndex], "Lambda") eq 1 then Lambda=long(Modules[thisModuleIndex].Lambda) else Lambda=0

;use varible names to get at a file stored in pipe, adopt some naming convention for ease of parameter selection (mass, age, composition)?
planet_model_filename=gpi_get_directory('DRP_CONFIG')+'/planet_models/'+p_spec
if not FILE_TEST(planet_model_filename) then begin
	backbone->Log, "Planet spectrum not found."
	return 
endif

star_model_filename=gpi_get_directory('DRP_CONFIG')+'/planet_models/'+s_spec
if not FILE_TEST(star_model_filename) then begin
	backbone->Log, "Stellar spectrum not found."
	return 
endif

;determine runtime enviroment
if lmgr(/runtime) and np gt 1 then begin 
	np=1
	backbone->Log, "Cannot use parrallel version in IDL runtime"
endif

;run datacube cleaning
if badpix eq 1 then begin
	tmp = 0
endif

;check for datacubes ready for processing...
if numfile eq ((dataset.validframecount)-1) then begin

	subsuffix='-tloci'

	;get filenames from pipeline
	nfiles=dataset.validframecount
	listfilenames=strarr(nfiles)

	;EXECUTE TLOCI CODE HERE

endif

;put header information into outputs
backbone->set_keyword,'Number_7',7,ext_num=1

@__end_primitive

end
