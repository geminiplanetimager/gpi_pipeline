;+
; NAME: gpi_accumulate_images
; PIPELINE PRIMITIVE DESCRIPTION: Accumulate Images
;
;	Stores images for later combination.
;
; INPUTS: data-cube
; common needed:
;
; KEYWORDS:
; OUTPUTS:
;
; PIPELINE COMMENT: Stores images for combination by a subsequent primitive. Can buffer on disk for datasets too large to hold just in RAM.
; PIPELINE ARGUMENT: Name="Method" Type="string" Range="OnDisk|InMemory" Default="InMemory" Desc="OnDisk|InMemory"
; PIPELINE ORDER: 4.0
; PIPELINE CATEGORY: ALL
;
; HISTORY:
;   2009-07-22 MDP: started
;   2009-09-17 JM: added DRF parameters
;   2013-08, 2013-10 MDP: Minor code formatting cleanup
;-

Function gpi_accumulate_images, DataSet, Modules, Backbone

  primitive_version= '$Id$' ; get version from subversion to store in header history
  @__start_primitive
   
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
  nfiles=dataset.validframecount


	if tag_exist( Modules[thisModuleIndex], "Method") then Method= Modules[thisModuleIndex].method else method="InMemory"


	case method of
	'InMemory': begin
		; Store all images into memory for simultaneous access in the future
		; TODO: error checking here to make sure that we have enough memory!

		;header=*(dataset.headers[numfile])		
    	;if numext eq 1 then headerPHU= *(dataset.headersPHU)[numfile]
    
		*(dataset.frames[numfile]) = *dataset.currframe

		backbone->Log, "	Accumulated file "+strc(numfile)+" in memory."

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

		backbone->Log, "Saved file "+strc(numfile)+" to disk."
	end
	endcase


if numfile  eq (dataset.validframecount-1) then begin
	backbone->set_reduction_level, 2 ; we are now moving on to the second level of reduction
	return, OK 
endif else return, GOTO_NEXT_FILE

end
