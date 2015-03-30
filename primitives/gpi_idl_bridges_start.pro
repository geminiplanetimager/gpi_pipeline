;+
; NAME: gpi_idl_bridges_start.pro
; PIPELINE PRIMITIVE DESCRIPTION: Start IDL Bridges
;
;	Starts IDL bridges for a sequence of images
;
; INPUTS: files
;
; OUTPUTS: list of bridges
;
; PIPELINE COMMENT: Starts up IDL bridges to process code in parrallel when a primitive requires it.
; PIPELINE ARGUMENT: Name="np" Type="float" Default="10" Range="[0,100]" Desc="Number of processors to use in reduction (double check enviroment before running)"
; PIPELINE ORDER: 0.0
; PIPELINE CATEGORY: ALL
;
; HISTORY:
;   2015-03-04 ZHD
;-

function gpi_idl_bridges_start, DataSet, Modules, Backbone

compile_opt defint32, strictarr, logical_predicate

primitive_version='$Id: gpi_accumulate_images.pro 2722 2014-03-24 06:08:50Z mperrin $' ; get version from subversion to store in header history

calfiletype=''

@__start_primitive

	common gpi_parallel, oBridge, np

	if tag_exist( Modules[thisModuleIndex], "np") then np=float(Modules[thisModuleIndex].np) else np=10

	;print,tag_names(dataset)
	nfiles = dataset.validframecount

	;print,nfiles,numfile,'test file numbers'
	
	if numfile eq 0 then begin
		print,'startup'	
		; start bridges from utils function
		oBridge=gpi_obridgestartup(nbproc=np)
	endif 

@__end_primitive

end
