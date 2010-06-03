;+
; NAME: spectral_telluric_transm_div
; PIPELINE PRIMITIVE DESCRIPTION: Divide spectral data by telluric transmission
;
; INPUTS: data-cube
;
; KEYWORDS:
;	/Save	set to 1 to save the output image to a disk file. 
;
; OUTPUTS:  datacube with slice at the same wavelength
;
; PIPELINE COMMENT: Divides a spectral data-cube by a flat field data-cube.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="-tellucal" Default="GPI-tellucal.fits" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-telcal" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.5
; PIPELINE TYPE: ALL/SPEC
; PIPELINE SEQUENCE: 3-
;
; HISTORY:
; 	2009-08-27: JM created
;   2009-09-17 JM: added DRF parameters
;   2009-10-09 JM added gpitv display
;-

function spectral_telluric_transm_div, DataSet, Modules, Backbone
calfiletype='telluric'

@__start_primitive

	
	if ~file_test( c_File) then return, error("Telluric transmission file does not exist!")

	tellurictrans = readfits( c_File)

; TODO error check sizes of arrays, etc. 
; TODO update FITS header history
	sxaddhist, functionname+": dividing by telluric transmission", *(dataset.headers[numfile])
  sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
  	datacube=*(dataset.currframe[0])
  	sz=size(datacube)
  	if sz[3] ne n_elements(tellurictrans) then return, error("Error: Telluric transmission do not have same dim than datacube!")
  
	; TODO vectorize!
	for ii=0,sz[1]-1 do begin
	  for jj=0,sz[2]-1 do begin
       datacube[ii,jj,*]/= tellurictrans
      endfor
    endfor
  
    *(dataset.currframe[0])=datacube

@__end_primitive 
;;
;;    thisModuleIndex = Backbone->GetCurrentModuleIndex()
;;    if tag_exist( Modules[thisModuleIndex], "Save") && tag_exist( Modules[thisModuleIndex], "suffix") then suffix+=Modules[thisModuleIndex].suffix
;;  
;;    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;;      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;;      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
;;      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;;    endif else begin
;;      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;;          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
;;    endelse
;;
;;return, ok
;;
;;
end
