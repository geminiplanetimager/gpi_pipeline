;+
; NAME:  __End_primitive_wavecal
;
;  Like __end_primitive, but with some customizations for primitives that
;  are generating new wavecal files. 
;
; This file is meant to be included at the END of a GPI primitive via
; @__end_primitive_wavecal
;
; This provides generic options common to essentially all primitives. 
;   save output to disk?
;   display in gpitv? (from disk or memory)
;   pause IDL here for debugging?
;
; HISTORY:
;    2013-12-09 MP: Forked from __end_primitive
;-

save_suffix=suffix
;; prepend dash if needed
if strmid(save_suffix,0,1) ne '_' then save_suffix = '_'+save_suffix


    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
    	if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
	
		; save it: (Wavecals get the filter name in the filename before the suffix)
    	b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, "_"+filter+suffix, display=display,savedata=shiftedwavecal,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile], output_filename=output_filename)
    	if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')

		; display wavecal overplotted on top of 2D image
	  	prev_saved_fn = backbone_comm->get_last_saved_file() ; ideally this should be the 2D image which was saved shortly before this step
		; verify that the prev saved file is from this same data file
	  	my_base_fn = (strsplit(dataset.filenames[numFile], '_',/extract))[0]
	  	if strpos(prev_saved_fn, my_base_fn) ge 0 then begin
			backbone_comm->gpitv, prev_saved_fn, session=fix(Modules[thisModuleIndex].gpitvim_dispgrid), dispwavecalgrid=output_filename, imname='Wavecal grid for '+  dataset.filenames[numfile]  ;Modules[thisModuleIndex].name
	  	endif else begin
			backbone->Log, "Cannot display wavecal plotted on top of 2D image, because 2D image wasn't saved in a previous step."
	  	endelse
	  
          
    endif else begin
		; not saving the wavecal
      	if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
        	backbone_comm->gpitv, double(*DataSet.currFrame), session=fix(Modules[thisModuleIndex].gpitv), header=*(dataset.headersPHU)[numfile], imname='Pipeline result from '+ Modules[thisModuleIndex].name,dispwavecalgrid=output_filename
    endelse

return, ok


if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
   ;; if we're saving the file, then we can invoke GPITV using that filename

   if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
   b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, save_suffix, display=display)
   if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
endif else begin
   ;; otherwise, any invocations of GPITV must pass the data set as a temp
   ;; file. 
   ;; FIXME this doesn't propagate headers
   if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then begin
      backbone_comm->gpitv, double(*DataSet.currFrame), session=fix(Modules[thisModuleIndex].gpitv), $
                            imname='Pipeline result from '+ Modules[thisModuleIndex].name, $
                            header=*DataSet.HeadersPHU[numfile],extheader=*DataSet.HeadersExt[numfile] 
   endif
endelse

if tag_exist( Modules[thisModuleIndex], "stopidl") then if keyword_set( Modules[thisModuleIndex].stopidl) then stop

return, ok


