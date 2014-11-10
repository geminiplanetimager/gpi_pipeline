;+
; NAME:  gpi_load_keyword_table
;
;	Read in the table of which keywords are in which header (primary
;	or extension HDUs). Save this in a common block for use in the 
;	gpi_get_keyword and gpi_set_keyword functions.
;
; INPUTS: 
; 	None
; KEYWORDS:
; 	None
; OUTPUTS:
; 	No direct outputs, but a structure is stored in the GPI_KEYWORD_TABLE common
; 	block.
;
; HISTORY:
; 	Began 2012-01-31 01:09:15 by Marshall Perrin 
; 	2013-07-12 MP: Documentation update
;-

;--------------------------------------------------------------------------------
; Read in GPI keywords table for which keyword is in which extension
PRO gpi_load_keyword_table
	compile_opt defint32, strictarr, logical_predicate

	common GPI_KEYWORD_TABLE, keyword_info

	if ptr_valid(keyword_info) then ptr_free, keyword_info

	; this file will be in the same directory as drsconfig.xml
	keyword_config_file = gpi_get_directory('DRP_CONFIG') + path_sep() + 'keywordconfig.txt'
	readcol, keyword_config_file, keywords, extensions,  format='A,A',SKIPLINE=2,silent=1 ; tab separated
	; TODO: error checking!
	;JM: I removed the "delimiter=string(09b)," keyword in call to readcol (is it system dependent?)
	; MP: that just specifies the delimiter to be a tab character (ASCII 09),
	; and so it should work on any OS
	keyword_info = ptr_new({keyword: strupcase(keywords), extension: strlowcase(extensions)} )

end


; 	
