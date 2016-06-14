;+
; NAME: gpi_check_gcal_data_quality
; PIPELINE PRIMITIVE DESCRIPTION: Check GCAL Data Quality 
;
;   This routine looks at various FITS header keywords and the contents of the
;   image to assess whether GCAL data should be considered usable or not. 
;   Developed in response to intermittent failures of some day cal data taking.
;
; INPUTS: 2D image file
; OUTPUTS: No change in data; reduction either continues or is terminated.
;
; PIPELINE COMMENT: Check quality of data based on header keywords. For bad data, can fail the reduction or simply alert the user.
; PIPELINE ARGUMENT: Name="Data_type" Type="string" Range="[wavecal|specflat|polflat]" Default="wavecal" Desc="What type of data are we expecting?. "
; PIPELINE ARGUMENT: Name="Action" Type="int" Range="[0,10]" Default="1" Desc="0:Simple alert and continue reduction, 1:Reduction fails"
; PIPELINE ORDER: 0.0001
; PIPELINE CATEGORY: Calibration
;
; HISTORY:
;	2015-04-30 MP: Created based on gpi_check_data_quality
;
;
;- 

function gpi_check_gcal_data_quality, DataSet, Modules, Backbone

primitive_version= '$Id: gpi_check_data_quality.pro 2511 2014-02-11 05:57:27Z mperrin $' ; get version from subversion to store in header history
 
@__start_primitive

  if tag_exist( Modules[thisModuleIndex], "action") then action=float(Modules[thisModuleIndex].action) else action=1
  if tag_exist( Modules[thisModuleIndex], "data_type") then data_type=strlowcase(Modules[thisModuleIndex].data_type) else data_type='wavecal'



	shouldfail=0

	; Check keywords
	case data_type of
	    'wavecal': begin
    		gcallamp = backbone->get_keyword('GCALLAMP',count=cc)
    		if strc(gcallamp) ne 'Ar' and strc(gcallamp) ne 'Xe' then begin
    			backbone->Log, "Unexpected GCALLAMP (should be Xe or Ar): "+gcallamp
    			shouldfail=1
    		endif
    		gcalfilt = backbone->get_keyword('GCALFILT',count=cc)
    		if strc(gcalfilt) ne 'CLEAR' then begin
    			backbone->Log, "Unexpected GCALFILT (should be CLEAR): "+gcalfilt
    			shouldfail=1
    		endif
    		disperser = backbone->get_keyword('DISPERSR',count=cc)
    		if strc(disperser) ne 'DISP_PRISM_G6262' then begin
    			backbone->Log, "Unexpected disperser (should be DISP_PRISM_G6262): "+disperser
    			shouldfail=1
    		endif
    	end
    	'specflat': begin
    		gcallamp = backbone->get_keyword('GCALLAMP',count=cc)
    		if strc(gcallamp) ne 'QH' then begin
    			backbone->Log, "Unexpected GCALLAMP (should be QH): "+gcallamp
    			shouldfail=1
    		endif
    		gcalfilt = backbone->get_keyword('GCALFILT',count=cc)
    		if strc(gcalfilt) ne 'ND2.0' then begin
    			backbone->Log, "Unexpected GCALFILT (should be ND2.0): "+gcalfilt
    			shouldfail=1
    		endif
    		disperser = backbone->get_keyword('DISPERSR',count=cc)
    		if strc(disperser) ne 'DISP_PRISM_G6262' then begin
    			backbone->Log, "Unexpected disperser (should be DISP_PRISM_G6262): "+disperser
    			shouldfail=1
    		endif
    
    	end
    	'polflat': begin
    		gcallamp = backbone->get_keyword('GCALLAMP',count=cc)
    		if strc(gcallamp) ne 'QH' then begin
    			backbone->Log, "Unexpected GCALLAMP (should be QH): "+gcallamp
	    		shouldfail=1
       		endif
    		gcalfilt = backbone->get_keyword('GCALFILT',count=cc)
    		if strc(gcalfilt) ne 'ND2.0' then begin
    			backbone->Log, "Unexpected GCALFILT (should be ND2.0): "+gcalfilt
    			shouldfail=1
    		endif
    		disperser = backbone->get_keyword('DISPERSR',count=cc)
    		if strc(disperser) ne 'DISP_WOLLASTON_G6261' then begin
    			backbone->Log, "Unexpected disperser (should be DISP_WOLLASTON_G6261): "+disperser
    			shouldfail=1
    		endif
    	end
    endcase

	
	; Check there is actually some flux

	w_good_snr = where(*dataset.currframe gt 1000, good_snr_ct)

	if good_snr_ct lt 1e5 then begin
		backbone->Log, "Image has too few pixels with high flux. Lamp off or M3 science fold in wrong position?"
		shouldfail=1
	endif


if shouldfail then begin
  case action of
    0: begin
       backbone->set_keyword, 'HISTORY', functionname+": ALERT BAD QUALITY DATA",ext_num=0
      end
    1: begin
      return, error(functionname+': GCAL DATA QUALITY CHECK FAILED. Terminating reduction.')
    end
  
  endcase
endif


  return, ok

end
