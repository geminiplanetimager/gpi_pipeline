;+
; NAME: collapsedatacube
; PIPELINE PRIMITIVE DESCRIPTION: Collapse datacube
;
;  TODO: more advanced collapse methods. 
;
; INPUTS: 
; common needed:
;
; KEYWORDS:
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: CDELT3, CRPIX3,CRVAL3,CTYPE3,NAXIS3
; OUTPUTS:
;
; PIPELINE COMMENT: Collapse the wavelength dimension of a datacube via mean, median or total. 
; PIPELINE ARGUMENT: Name="Method" Type="enum" Range="MEDIAN|TOTAL"  Default="TOTAL" Desc="How to collapse datacube: total or median (with flux conservation)"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="ReuseOutput" Type="int" Range="[0,1]" Default="1" Desc="1: keep output for following primitives, 0: don't keep"
; PIPELINE ARGUMENT: Name='suffix' Type='string' Default='-coll' Desc="choose the suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.6
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 

; HISTORY:
;  2010-04-23 JM created
;-
function collapsedatacube, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "method") then method=Modules[thisModuleIndex].method else method='total'

	;if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=Modules[thisModuleIndex].suffix else suffix=method

	header=*(dataset.headers[numfile])
	
  sz = size(*(dataset.currframe))
  
if sz[0] eq 3 then begin
		sxaddhist, functionname+':   Collapsing datacube using method='+method, *(dataset.headers[numfile])
		backbone->Log, "	Combining datacube using method="+method
		case STRUPCASE(method) of
		'MEDIAN': begin  ;here the [* float(sz[3])] operation is for energy conservation in order to keep the same units.
			collapsed_im=(median(*(dataset.currframe),DIMENSION=3)) * float(sz[3]) 
		end
		'TOTAL': begin
			collapsed_im=total(*(dataset.currframe),3,/NAN)
		end
		else: begin
			message,"Invalid combination method '"+method+"' in call to Collapse datacube."
			return, NOT_OK
		endelse
		endcase

    ;change keywords related to the common wavelength vector:
    sxdelpar, *(dataset.headers)[numfile], 'NAXIS3'
    sxdelpar, *(dataset.headers)[numfile], 'CDELT3'
    sxdelpar, *(dataset.headers)[numfile], 'CRPIX3'
    sxdelpar, *(dataset.headers)[numfile], 'CRVAL3'
    sxdelpar, *(dataset.headers)[numfile], 'CTYPE3'
  

	if tag_exist( Modules[thisModuleIndex], "suffix") then suffix2=suffix+Modules[thisModuleIndex].suffix
  
   if tag_exist( Modules[thisModuleIndex],"ReuseOutput")  then begin
   ; put the datacube in the dataset.currframe output structure:
   *(dataset.currframe[0])=collapsed_im
    Modules[thisModuleIndex].Save=1 ;will save output on disk, so outputfilenames changed
    collapsed_im=0
    suffix+=Modules[thisModuleIndex].suffix 
    
    endif


    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix2, savedata=collapsed_im, display=display)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
    endelse

 endif  

return, ok

end
