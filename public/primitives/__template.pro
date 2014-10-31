;+
; NAME: __template_primitive.pro
; PIPELINE PRIMITIVE DESCRIPTION: Template for new primitives
;
;   Descriptive text here will show up in the online HTML documentation.
;   This example primitive multiplies the current datacube by a constant.
;
; INPUTS: Some datacube
;
; OUTPUTS: That datacube multiplied by a constant.
;
; PIPELINE COMMENT: This description of the processing or calculation will show ; up in the Recipe Editor GUI. This is an example template for creating new ; primitives. It multiples any input cube by a constant value.
; PIPELINE ARGUMENT: Name="multiplier" Type="float" Default="2.0" Desc="Scalar to multiply the input cube by."
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; 
; where in the order of the primitives should this go by default?
; PIPELINE ORDER: 5.0
;
; pick one of the following options for the primitive type:
; PIPELINE CATEGORY: SpectralScience,PolarimetricScience,Calibration,Testing,ALL
;
; HISTORY:
;    2013-07-17 MP: Update template.
;-  

function __template, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id$' ; get version from subversion to store in header history

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

; the following line sources a block of code common to all primitives
; It loads some common blocks, records the primitive version in the header for
; history, then if calfiletype is not blank it queries the calibration database
; for that file, and does error checking on the returned filename.
@__start_primitive
suffix='' 		 ; set this to the desired output filename suffix


	; put your code here
	;
	

	; Here is how to access a primitive's arguments. Note the error checking to
	; set a default value in case the recipe is missing this argument entirely
 	if tag_exist( Modules[thisModuleIndex], "multiplier") then multiplier=float(Modules[thisModuleIndex].multiplier) else multiplier=2.0

	
	; the current image or datacube is available from a pointer
	; *dataset.currframe
	
	*dataset.currframe  *= multiplier 

	
	; The current headers (primary and extension) are available from the
	; pipeline backbone set_keyword and get_keyword functions. 
	; Using these functions saves you from having to worry about whether a 
	; given quantity is in the primary or extension HDU.
	;

	backbone->set_keyword,'HISTORY',functionname+ " Multiplied datacube by a constant"
	backbone->set_keyword,'MULTPLYR',multiplier, "Scalar value this datacube was multiplied by"


	itime = backbone->get_keyword('ITIME')

	; There is also a log function.
	backbone->Log, "This image's exposure time is: "+string(itime)+" s"
	backbone->Log, "This log message will be saved in the pipeline log, and displayed in the status console window."

; The following line also loads a block of code common to all primitives
; It saves the data to disk if the Save argument is set, and
; sends the data to a gpitv session if the gpitv argument is set.
;
; Optionally if a stopidl argument exists and is set, then stop 
; IDL at its command line debugger for interactive work. (This only
; works in source code IDL, not the compiled runtime.)
@__end_primitive

end
