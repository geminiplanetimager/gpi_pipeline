
;+
; NAME: ApplyDarkCorrection
; PIPELINE PRIMITIVE DESCRIPTION: Subtract Dark/Sky Background
;
;
; INPUTS: 
;
; KEYWORDS:
; 	CalibrationFile=	Name of dark file to subtract.
;
; OUTPUTS: 
; 	2D image corrected
;
; ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.
;
; PIPELINE COMMENT: Subtract a dark frame. 
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="dark" Default="GPI-dark.fits"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-darksub" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.26
; PIPELINE TYPE: ALL
;
; HISTORY:
; 	Originally by Jerome Maire 2008-06
; 	2009-04-20 MDP: Updated to pipeline format, added docs. 
; 				    Some code lifted from OSIRIS subtradark_000.pro
;   2009-09-02 JM: hist added in header
;   2009-09-17 JM: added DRF parameters
;   2010-10-19 JM: split HISTORY keyword if necessary
;
function ApplyDarkCorrection, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
calfiletype = 'dark'
@__start_primitive

  fits_info, c_File, /silent, N_ext=n_ext
  if n_ext eq 0 then dark=readfits(c_File) else dark=mrdfits(c_File,1)
  
	;dark=readfits(c_File)
	*(dataset.currframe[0]) -= dark

;  sxaddhist, functionname+": dark subtracted", *(dataset.headers[numfile])
;  sxaddhist, functionname+": "+c_File, *(dataset.headers[numfile])
  sxaddparlarge,*(dataset.headers[numfile]),'HISTORY',functionname+": dark subtracted"
  sxaddparlarge,*(dataset.headers[numfile]),'HISTORY',functionname+": "+c_File
  
thisModuleIndex = Backbone->GetCurrentModuleIndex()
  if tag_exist( Modules[thisModuleIndex], "Save") && tag_exist( Modules[thisModuleIndex], "suffix") then suffix+=Modules[thisModuleIndex].suffix
  

  suffix = 'darksub'
@__end_primitive 


end
