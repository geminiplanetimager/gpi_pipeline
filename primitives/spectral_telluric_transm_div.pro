;+
; NAME: spectral_telluric_transm_div
; PIPELINE PRIMITIVE DESCRIPTION: Divide spectral data by telluric transmission
;
; INPUTS: data-cube
;
; KEYWORDS:
;	/Save	set to 1 to save the output image to a disk file. 
;
; DRP KEYWORDS: HISTORY
; OUTPUTS:  datacube with slice at the same wavelength
;
; PIPELINE COMMENT: Divides a spectral data-cube by a flat field data-cube.
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="-tellucal" Default="AUTOMATIC" Desc="Filename of the desired wavelength calibration file to be read"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.5
; PIPELINE TYPE: ALL/SPEC
; PIPELINE NEWTYPE: SpectralScience,Calibration
; PIPELINE SEQUENCE: 3-
;
; HISTORY:
; 	2009-08-27: JM created
;   2009-09-17 JM: added DRF parameters
;   2009-10-09 JM added gpitv display
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2011-08-01 MP: Update for multi-extension FITS files
;   2012-10-10 MP: Minor code cleanup; remove deprecated suffix= parameter
;-

function spectral_telluric_transm_div, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype='telluric'
@__start_primitive

	
	if ~file_test( c_File) then return, error("Telluric transmission file does not exist!")
  
	tellurictrans = gpi_readfits( c_File) 

  	;datacube=*(dataset.currframe[0])

  	sz=size(  *dataset.currframe)
  	if sz[3] ne n_elements(tellurictrans) then return, error("Error: Telluric transmission does not have same dimensions as datacube!")

   	backbone->set_keyword,'HISTORY',functionname+": dividing by telluric transmission",ext_num=0
   	backbone->set_keyword,'HISTORY',functionname+": "+c_File,ext_num=0
 
	; TODO vectorize!  Which way is faster?
;	for ii=0,sz[1]-1 do begin
;	  for jj=0,sz[2]-1 do begin
;       datacube[ii,jj,*]/= tellurictrans
;      endfor
;    endfor
	for i=0,sz[3]-1 do (*dataset.currframe)[*,*,i] /= tellurictrans[i]
  
    ;*(dataset.currframe)=datacube

@__end_primitive 
end
