;+
; NAME: gpi_idl_bridges_end.pro
; PIPELINE PRIMITIVE DESCRIPTION: End IDL Bridges
;
;	Ends IDL bridges for a sequence of images
;
; INPUTS: nothing
;
; OUTPUTS: nothing
;
; PIPELINE COMMENT: Starts up IDL bridges to process code in parrallel when a primitive requires it.
; PIPELINE ARGUMENT: Name="singularity" Type="float" Default="0" Range="[0,42]" Desc="At least one arguement required by pipeline? Not Needed"
; PIPELINE ORDER: 0.0
; PIPELINE CATEGORY: ALL
;
; HISTORY:
;   2015-03-04 ZHD
;-

function gpi_idl_bridges_end, DataSet, Modules, Backbone

compile_opt defint32, strictarr, logical_predicate

primitive_version='$Id: gpi_accumulate_images.pro 2722 2014-03-24 06:08:50Z mperrin $' ; get version from subversion to store in header history

calfiletype=''

@__start_primitive

	common gpi_parallel, oBridge

	;print,tag_names(dataset)
	nfiles = dataset.validframecount

	;print,nfiles,numfile,'test file numbers'

	if numfile eq (nfiles-1) then begin
		print,'kill'	
		;stadard kill method for IDL
		gpi_obridgeabort,oBridge
		;unix dependent kill method of zombie processes
		;gpi_unixobridgekill
	endif 

@__end_primitive

end
