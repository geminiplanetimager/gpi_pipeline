;+
; NAME: gpi_get_obs_keywords 
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
;	Began 2014-10-31 by Marshall, refactoring out code from
;		gpi_recipe_editor__define to a standalone routine.
;-


function gpi_get_obs_keywords, filename, where_to_log=where_to_log

	if ~file_test(filename) then begin
		logmsg = "ERROR can't find file: "+filename 
		if obj_valid(where_to_log) then where_to_log->Log, logmsg else message, logmsg,/info
		return, -1
	endif


	; Load FITS file
	fits_data = gpi_load_fits(filename,/nodata,/silent,/fast)
	head = *fits_data.pri_header
	ext_head = *fits_data.ext_header
	ptr_free, fits_data.pri_header, fits_data.ext_header

	obsstruct = {struct_obs_keywords, $
				FILENAME: filename,$
				ASTROMTC: strc(  gpi_get_keyword(head, ext_head,  'ASTROMTC', count=ct0)), $
				OBSCLASS: strc(  gpi_get_keyword(head, ext_head,  'OBSCLASS', count=ct1)), $
				obstype:  strc(  gpi_get_keyword(head, ext_head,  'OBSTYPE',  count=ct2)), $
				obsmode:  strc(  gpi_get_keyword(head, ext_head,  'OBSMODE',  count=ctobsmode)), $
				OBSID:    strc(  gpi_get_keyword(head, ext_head,  'OBSID',    count=ct3)), $
				filter:   strc(gpi_simplify_keyword_value(strc(   gpi_get_keyword(head, ext_head,  'IFSFILT',   count=ct4)))), $
				dispersr: strc(gpi_simplify_keyword_value(gpi_get_keyword(head, ext_head,  'DISPERSR', count=ct5))), $
				OCCULTER: strc(gpi_simplify_keyword_value(gpi_get_keyword(head, ext_head,  'OCCULTER', count=ct6))), $
				LYOTMASK: strc(  gpi_get_keyword(head, ext_head,  'LYOTMASK',     count=ct7)), $
				APODIZER: strc(  gpi_get_keyword(head, ext_head,  'APODIZER',     count=ct8)), $
				DATALAB:  strc(  gpi_get_keyword(head, ext_head,  'DATALAB',     count=ct11)), $
				ITIME:    float( gpi_get_keyword(head, ext_head,  'ITIME',    count=ct9)), $
				COADDS:   fix( gpi_get_keyword(head, ext_head,  'COADDS',    count=ctcoadd)), $
				OBJECT:   string(  gpi_get_keyword(head, ext_head,  'OBJECT',   count=ct10)), $
      			ELEVATIO: float(  gpi_get_keyword(head, ext_head,  'ELEVATIO',   count=ct12)), $
				MJDOBS:   float(gpi_get_keyword(head, ext_head,  'MJD-OBS',   count=ct13)), $
				summary: '',$
				valid: 0}

	; some are OK to be missing without making it impossible to parse
	if ct11 eq 0 then obsstruct.datalab = 'no DATALAB'
	if ct10 eq 0 then obsstruct.object = 'no OBJECT'
	if ct3 eq 0 then obsstruct.obsid = 'no OBSID'
	if ct0 eq 0 then obsstruct.astromtc= 'F'
        if ct12 eq 0 then obsstruct.elevatio = 'no elevation'
		if ct13 eq 0 then obsstruct.mjdobs=0.0
;        if ct13 eq 0 then obsstruct.gcalfilt = 'no gcalfilt'
;print,'counts',ct1,ct2,ct4,ct5,ct6,ct7,ct8,ct9,ctobsmode
	; some we need to have in order to be able to parse.
	vec=[ct1,ct2,ct4,ct5,ct6,ct7,ct8,ct9,  ctobsmode]
	if total(vec) lt n_elements(vec) then begin
		obsstruct.valid=0
		;give some info on missing keyw:
		keytab=['OBSCLASS','OBSTYPE', 'IFSFILT','DISPERSR','OCCULTER','LYOTMASK','APODIZER', 'ITIME', 'OBSMODE']
		indzero=where(vec eq 0, cc)
		;print, "Invalid/missing keywords for file "+filename
		logmsg = 'Missing keyword(s): '+strjoin(keytab[indzero]," ")+" for "+filename
		if cc gt 0 then if obj_valid(where_to_log) then where_to_log->Log, logmsg else message, logmsg, /info
		;message,/info, logmsg

		if ct1 eq 0 then obsstruct.obsclass = 'no OBSCLASS'
		if ct2 eq 0 then obsstruct.obstype = 'no OBSTYPE'
		if ctobsmode eq 0 then obsstruct.obsmode = 'no OBSMODE'

	endif else begin
		obsstruct.valid=1
	endelse

	if obsstruct.dispersr eq 'PRISM' then obsstruct.dispersr='Spectral'	 ; preferred display nomenclature is as Spectral/Wollaston. Both are prisms!
	if obsstruct.object eq 'GCALflat' then obsstruct.object+= " "+gpi_get_keyword(head, ext_head,  'GCALLAMP')

    ; Append (SKY) if we appear to be offset off to sky
    qoffset = sxpar(head,'QOFFSET')
    poffset = sxpar(head,'POFFSET')
    xoffset = sxpar(head,'XOFFSET')
    yoffset = sxpar(head,'YOFFSET')
    raoffset = sxpar(head,'RAOFFSET')
    deoffset = sxpar(head,'DECOFFSE')
    is_sky = ((abs(qoffset) gt 1) or (abs(poffset) gt 1) or (abs(xoffset) gt 1) or $
			(abs(yoffset) gt 1) or (abs(raoffset) gt 1) or (abs(deoffset) gt 1))
    if keyword_set(is_sky) then begin
        if (strpos(strupcase(obsstruct.object), 'SKY') eq -1) then obsstruct.object += " (SKY)"
    endif




	if obsstruct.coadds eq 1 then coaddstr = "     " else coaddstr = "*"+string(obsstruct.coadds,format='(I-4)')
    obsstruct.summary = file_basename(filename)+"    "+string(obsstruct.obsmode,format='(A-10)')+" "+string(obsstruct.dispersr,format='(A-10)') +" "+string(obsstruct.obstype, format='(A-10)')+$
				" "+string(obsstruct.itime,format='(F5.1)')+coaddstr+"  "+string(obsstruct.object,format='(A-15)')+"   "+obsstruct.datalab+"   el="+sigfig(obsstruct.elevatio,3)
 
	
	return, obsstruct



end



