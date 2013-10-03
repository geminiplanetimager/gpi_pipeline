;+
; NAME: gpi_generate_combined_bad_pixel_map
; PIPELINE PRIMITIVE DESCRIPTION: Generate Combined Bad Pixel Map
;
; This routine is used to combine the 3 individual types of bad pixel maps::
;  
;     Hot bad pixels
;     Cold bad pixels
;     Nonlinear (too nonlinear to be usable) pixels
;
; into one master bad pixel map. 
;
; This is an unusual recipe, in that its input file data is not actually 
; used in any way. All it does is use the first file to identify the date for
; which the bad pixel maps are generated.
;
; For this routine to run, there must be at least Hot and Cold bad pixel maps
; already present in the calibration DB. The nonlinear pixels map is optional.
;
; INPUTS: bad pixel maps 
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: FILETYPE,ISCALIB
;
; OUTPUTS:
; PIPELINE ORDER: 4.02
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE COMMENT: This routine combines various sub-types of bad pixel mask (hot, cold,  anomalous nonlinear pixels) to generate a master bad pixel list.
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 
;
; HISTORY:
;    Jerome Maire 2009-08-10
;   2009-09-17 JM: added DRF parameters
;   2012-01-31 Switched sxaddpar to backbone->set_keyword Dmitry Savransky
;   2012-11-19 MP: Complete algorithm overhaul.
;   2013-04-29 MP: Better error checking; nonlinearbadpix is optional.
;   2013-07-12 MP: rename for consistency
;-


function gpi_generate_combined_bad_pixel_map,  DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
	nfiles=dataset.validframecount

   
	; There are three different kinds of bad pixels that we are currently
	; tracking:
	;   1. Hot bad pixels (identified from darks, in which they have too high counts)
	;   2. Cold bad pixels (identified from flats, in which they have too low counts)
	; 	3. "anomalous" nonlinear pixels (identified from UTR flat sequences saving every frame,
	;		in which these pixels do not show any linear portion of their slope at all)
	;
	;	The latter are harder to measure and are therefore optional. We
	;	definitely need both of the first two types to combine 

	bptypes = ['hotbadpix','coldbadpix','nonlinearbadpix']
	types = ['hot pixels', 'cold pixels', 'pixels with no linear behavior']
	required = [1, 1, 0]
	ignore_cooldowns = [0,1,1]
	bpmasks = fltarr(2048,2048, n_elements(bptypes))

	for i=0L,n_elements(bptypes)-1 do begin

		c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( bptypes[i],$ 
				*(dataset.headersphu)[numfile],*(dataset.headersext)[numfile],$
				ignore_cooldown_cycles = ignore_cooldowns[i], /verbose) 

		if size(c_file,/tname) eq 'int' then begin ; this will only happen if NOT_OK = -1 is returned
			;if c_file eq not_ok then begin
			if required[i] then begin
				return, error('ERROR ('+strtrim(functionname)+'): bad pix mask of type '+bptypes[i]+' could not be found in calibrations database.')
			endif else begin
				backbone->Log, "Could not find any file for optional bad pixel type "+bptypes[i]
				continue
			endelse

		endif else begin
			backbone->set_keyword, 'history',"  Resolved calibration file of type '"+bptypes[i]+"':"
			backbone->set_keyword, 'history',"  "+c_file 
		endelse

		c_file = gpi_expand_path(c_file) 
		if ( ~ file_test ( c_file ) ) then $
		   return, error ('ERROR ('+strtrim(functionname)+'): calibration file  ' +  strtrim(string(c_file),2) + ' not found.' )

		data = gpi_load_fits(c_File)
		if n_elements(*data.image) ne 2048l*2048 then begin
		   return, error ('ERROR ('+strtrim(functionname)+'): calibration file  ' + strtrim(string(c_file),2) + ' does not have the correct size or dimensions.' )
		endif
		bpmasks[*,*,i] = *data.image

		backbone->Log, "From file "+c_file+", have "+strc(fix(total(*data.image)))+" "+types[i]
		backbone->set_keyword, 'HISTORY', functionname+":   Mask has "+strc(total(*data.image))+" "+types[i],ext_num=0

	endfor 


	badpixcomb = total(bpmasks,3) gt 0
	totbadpix = fix(total(badpixcomb))

	*dataset.currframe=byte(badpixcomb)

  	thisModuleIndex = Backbone->GetCurrentModuleIndex()
	suffix = '-badpix'


	backbone->set_keyword, 'HISTORY', functionname+": Result has "+strc(totbadpix)+" total bad pixels",ext_num=0
	backbone->Log, "Combined bad pixel map has "+strc(totbadpix)+" total bad pixels"

	backbone->set_keyword, "FILETYPE", "Bad Pixel Map", "What kind of IFS file is this?"
	backbone->set_keyword,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.'
	backbone->set_keyword,  "DRPNBAD", totbadpix, 'Total number of pixels marked bad.'
	backbone->set_keyword,  "DRPNFILE", n_elements(bptypes), '# of input files combined to produce this file'
  

@__end_primitive

end
