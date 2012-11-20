;+
; NAME: gpi_badpixels_from_list
; PIPELINE PRIMITIVE DESCRIPTION: Create Bad Pixel Map from text list of pixels
;
;	This is kind of an oddball. This routine takes an ASCII text file containing a list of 
;	pixels, formatted as two columns of X and Y values, and converts it into a GPI 
;	calibration file format. The input FITS file is pretty much ignored entirely except
;	inasmuch as it provides a header to lift some keywords from easily.
;
; KEYWORDS:
; DRP KEYWORDS: FILETYPE,ISCALIB
; OUTPUTS:
;
; PIPELINE COMMENT: Generate FITS bad pixel map from a text list of pixel coords X, Y
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="bptype" Type="string" Range="hotbadpix|coldbadpix|nonlinearbadpix" Default="coldbadpix" Desc="Type of bad pixel mask to write"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="string" Default="AUTOMATIC" Desc="Input ASCII pixel list file"
; PIPELINE ORDER: 4.01
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 22-

;
; HISTORY:
;   2012-11-19 MP: New routine
;-
function gpi_badpixels_from_list, DataSet, Modules, Backbone
primitive_version= '$Id: gpi_find_hotpixels_from_darks.pro 1004 2012-11-17 01:52:14Z Dmitry $' ; get version from subversion to store in header history

@__start_primitive

	c_file = (modules[thismoduleindex].calibrationfile)
	if c_file eq 'AUTOMATIC' then return, error("Cannot use an AUTOMATIC calibration file for gpi_badpixels_from_list, it needs an explicit filename.")
   
	backbone->set_keyword, 'HISTORY', functionname+":   Creating Bad pixel mask from an input text file list" ,ext_num=0
	backbone->set_keyword, 'HISTORY', functionname+":     "+c_file ,ext_num=0


	readcol, c_file, pixX, pixY, format="I,I"
	mask = bytarr(2048,2048)
	mask[pixX, pixY] = 1

	;----- store the output into the backbone datastruct
	*(dataset.currframe)=mask
	bptype = (modules[thismoduleindex].bptype)
    suffix=bptype

	case bptype of 
	'coldbadpix': 		longtype = 'Cold Bad Pixel Map'
	'hotbadpix': 		longtype = 'Hot Bad Pixel Map'
	'nonlinearbadpix': 	longtype = 'Nonlinear Bad Pixel Map'
	endcase


    backbone->set_keyword, "FILETYPE", longtype, "What kind of IFS file is this?"
    backbone->set_keyword,  "ISCALIB", "YES", 'This is a reduced calibration file of some type.' 

@__end_primitive
end

