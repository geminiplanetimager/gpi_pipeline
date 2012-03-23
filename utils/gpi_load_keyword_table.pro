;+
; NAME:  
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2012-01-31 01:09:15 by Marshall Perrin 
;-

;--------------------------------------------------------------------------------
; Read in GPI keywords table for which keyword is in which extension
PRO gpi_load_keyword_table
	common GPI_KEYWORD_TABLE, keyword_info

	if ptr_valid(keyword_info) then ptr_free, keyword_info

	; this file will be in the same directory as drsconfig.xml
	mod_config_file=GETENV('GPI_DRP_CONFIG_DIR')
	keyword_config_file = file_dirname(mod_config_file) + path_sep() + 'keywordconfig.txt'
	readcol, keyword_config_file, keywords, extensions,  format='A,A',SKIPLINE=2,silent=1 ; tab separated
	; TODO: error checking!
	;JM: I removed the "delimiter=string(09b)," keyword in call to readcol (is it system dependent?)
	; MP: that just specifies the delimiter to be a tab character (ASCII 09),
	; and so it should work on any OS
	keyword_info = ptr_new({keyword: strupcase(keywords), extension: strlowcase(extensions)} )

end


; 	
