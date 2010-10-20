;+
; NAME: accumulate_images
; PIPELINE PRIMITIVE DESCRIPTION: Accumulate Images
;
;	Stores images for the combination routine
;
; INPUTS: data-cube
; common needed:
;
; KEYWORDS:
; OUTPUTS:
;
; PIPELINE COMMENT: Stores images for the combination routine
; PIPELINE ARGUMENT: Name="Method" Type="string" Range="OnDisk|InMemory" Default="OnDisk" Desc="OnDisk|InMemory"
; PIPELINE ORDER: 4.0
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 02-03-11-23-24-
;
; HISTORY:
;  2009-07-22: MDP started
;   2009-09-17 JM: added DRF parameters
;-

Function accumulate_images, DataSet, Modules, Backbone
common PIP
COMMON APP_CONSTANTS

primitive_version= '$Id$' ; get version from subversion to store in header history
  @__start_primitive
  ;getmyname, functionName
   
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
  nfiles=dataset.validframecount


	if tag_exist( Modules[thisModuleIndex], "Method") then Method= Modules[thisModuleIndex].method else method="InMemory"


	case method of
	'InMemory': begin
		; Store all images into memory for simultaneous access in the future
		; TODO: error checking here to make sure that we have enough memory!

		header=*(dataset.headers[numfile])
		*(dataset.frames[numfile]) = *dataset.currframe

		backbone->Log, "	Accumulated file "+strc(numfile)+" in memory.",/DRF

	end
	'OnDisk': begin
		; If the image has already been saved on disk, then just remember the
		; filename.
		; Otherwise, save the data, and *then* remember the filename
		;
		if strc(dataset.outputFileNames[numfile]) eq "" then begin
			b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=0)
			if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
		endif

		*(dataset.frames[numfile]) = dataset.outputFileNames[numfile]	

		backbone->Log, "Saved file "+strc(numfile)+" to disk.",/DRF
	end
	endcase


if numfile  eq ((dataset.validframecount)-1) then return, OK else return, GOTO_NEXT_FILE
end
