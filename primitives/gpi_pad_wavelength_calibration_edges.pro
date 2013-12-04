;+
; NAME: gpi_pad_wavelength_calibration_edges
; PIPELINE PRIMITIVE DESCRIPTION: Pad Wavelength Calibration Edges
;
; INPUTS: 3D wavcal 
;
;
; PIPELINE COMMENT:  pads the outer edges of the wavecal via extrapolation to cover lenslets whose spectra only partially fall on the detector field of view.
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: Save output to disk, 0: Don't save"
; PIPELINE ARGUMENT: Name="gpitvim_dispgrid" Type="int" Range="[0,500]" Default="15" Desc="1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display "
; PIPELINE ORDER: 4.6
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
;
; HISTORY:
;   2013-11-28 MP: Created.
;-

function gpi_pad_wavelength_calibration_edges,  DataSet, Modules, Backbone
primitive_version= '$Id: gpi_combine_wavelength_calibrations.pro 1715 2013-07-17 18:56:52Z mperrin $' ; get version from subversion to store in header history
@__start_primitive


	; Assumption: The current frame must be a wavelength calibration file. No checking done here yet.

	; First we perform the padding to handle lenslets that fall only partially on the detector FOV.
	padded = gpi_wavecal_extrapolate_edges(*dataset.currframe)
	*dataset.currframe = padded
	backbone->set_keyword, 'HISTORY',  functionname+": Extrapolated/padded edges to provide approximate solutions for spectra only partially on the detector." 

	; Now the wavecal is done and ready to be saved.	
	; We handle this a bit more manually here than is typically done via __end_primitive,
	; because we want to make use of some nonstandard display hooks to show the wavecal (optionally).
	

    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
    	if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
	
		; save it:
    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, filter+"_"+suffix, display=display,savedata=shiftedwavecal,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile], output_filename=output_filename)
    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')

		; display wavecal overplotted on top of 2D image
	  	prev_saved_fn = backbone_comm->get_last_saved_file() ; ideally this should be the 2D image which was saved shortly before this step
		; verify that the prev saved file is from this same data file
	  	my_base_fn = (strsplit(dataset.filenames[numFile], '_',/extract))[0]
	  	if strpos(prev_saved_fn, my_base_fn) ge 0 then begin
			backbone_comm->gpitv, prev_saved_fn, session=fix(Modules[thisModuleIndex].gpitvim_dispgrid), dispwavecalgrid=output_filename, imname='Wavecal grid for '+  dataset.filenames[numfile]  ;Modules[thisModuleIndex].name
	  	endif else begin
			backbone->Log, "Cannot display wavecal plotted on top of 2D image, because 2D image wasn't saved in the previous step."
	  	endelse
	  
          
    endif else begin
		; not saving the wavecal
      	if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
        	backbone_comm->gpitv, double(*DataSet.currFrame), session=fix(Modules[thisModuleIndex].gpitv), header=*(dataset.headersPHU)[numfile], imname='Pipeline result from '+ Modules[thisModuleIndex].name,dispwavecalgrid=output_filename
    endelse

return, ok


; Not needed here because we just included here all of the steps just above
;@__end_primitive

end
