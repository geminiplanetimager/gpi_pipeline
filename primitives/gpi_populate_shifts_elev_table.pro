;+
; NAME: gpi_populate_shifts_elev_table
; PIPELINE PRIMITIVE DESCRIPTION: Populate Shifts vs Elevation Table 
;
;	This function produces the table of spectral position shifts vs 
;	elevation angle used to compensate for flexure within the GPI IFS.
;
;	It takes as input a series of reduced wavelength calibration
;	files. It compares them against a reference wavelength calibration file
;	obtained from the calibration database (which must have been taken in 
;	horizontal orientation).  The shift in X and Y positions are calculated
;	for each lenslet, and then the mean over the entire field is taken. 
;
;	The median X shift and Y shift for each elevation is saved into
;	a table in the calibration database. 
;
;	 
;   Optionally the user can request diagnostic plots displayed on screen or
;   saved to disk as postscript files.
;
;
; ALGORITHM:
;
;
; INPUTS: wavecal
; common needed:
;
; KEYWORDS:
; GEM/GPI KEYWORDS:FILTER,IFSFILT,GCALLAMP,GCALSHUT,OBSTYPE
; DRP KEYWORDS: FILETYPE,HISTORY,ISCALIB
; OUTPUTS:
;
; PIPELINE ORDER: 4.2

; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="display" Type="string" Range="[yes|no]" Default="yes" Desc='Show diagnostic plot when running? [yes|no]'
; PIPELINE ARGUMENT: Name="saveplots" Type="string" Range="[yes|no]" Default="no" Desc='Save diagnostic plots to PS files after running? [yes|no]'
; PIPELINE COMMENT: Derive shifts vs elevation lookup table.
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 
; HISTORY:      
;      Jerome Maire 2013-02
;-

function gpi_populate_shifts_elev_table,  DataSet, Modules, Backbone
primitive_version= '$Id: gpi_populate_shifts_elev_table.pro 1224 2013-02-04 22:22:13Z maire $' ; get version from subversion to store in header history
@__start_primitive

    if tag_exist( Modules[thisModuleIndex], "display") then display=strlowcase(Modules[thisModuleIndex].display) else display='yes'
    if tag_exist( Modules[thisModuleIndex], "saveplots") then saveplots=strlowcase(Modules[thisModuleIndex].saveplots) else saveplots='no'

    nfiles=dataset.validframecount
    ;get the reference wavecal
    calfiletype = 'wavecal'
    c_file = (backbone_comm->getgpicaldb())->get_best_cal_from_header( calfiletype, *(dataset.headersphu)[numfile],*(dataset.headersext)[numfile] ) 
    c_file = gpi_expand_path(c_file)  
    currwavcal = gpi_readfits(c_File,header=Header)
    backbone->set_keyword, "SHIFTREF", c_File, "Shift reference file used.", ext_num=1
    
    ;; must make sure the reference file has zenith angle of 90 =
    ;; elevation 0, and uses the same lamp!

    ; get c_file primary header
    pri_cal_header=headfits(c_File,exten=0)

    if abs(gpi_get_keyword(pri_cal_header,header,'ELEVATIO')) ge 1 then begin
        logstr = 'Reference calibration is not at horizontal (elevation eq 0), aborting sequence'
        backbone->Log,logstr
        message,/info, logstr
        return, NOT_OK
    endif

    if strcompress(backbone->get_keyword('GCALLAMP')) ne strcompress(gpi_get_keyword(pri_cal_header,header,'GCALLAMP')) then begin
        logstr = 'Reference file does not use the same lamp! Aborting sequence'
        backbone->Log,logstr
        message,/info, logstr
        return, NOT_OK
    endif

    currwavcal0 = (accumulate_getimage( dataset, 0))[*,*,*]
    szw=size(currwavcal)
    lambdaref=currwavcal[szw[1]/2,szw[2]/2,2]
     
    xshift=fltarr(nfiles)
    yshift=fltarr(nfiles)
    xshiftmed=fltarr(nfiles)
    yshiftmed=fltarr(nfiles)
    xshift0=fltarr(nfiles)
    yshift0=fltarr(nfiles)
    xshiftmed0=fltarr(nfiles)
    yshiftmed0=fltarr(nfiles)
    elevation=fltarr(nfiles)
    
    for n=0,nfiles-1 do begin
        ;calculate the shifts with respect to the current wavelength solution in DB
        wavcal =(accumulate_getimage( dataset, n))[*,*,*]
        wavcal_samewav = change_wavcal_lambdaref( wavcal, lambdaref)
        ; backbone_comm->gpitv, (wavcal_samewav-currwavcal), session=22
        xshift[n]=mean((wavcal_samewav-currwavcal)[*,*,1],/nan)
        yshift[n]=mean((wavcal_samewav-currwavcal)[*,*,0],/nan)
        xshiftmed[n]=median((wavcal_samewav-currwavcal)[*,*,1])
        yshiftmed[n]=median((wavcal_samewav-currwavcal)[*,*,0])
     
        ;calculate the shifts with respect of the first image of the data reduction
        ; backbone_comm->gpitv, (wavcal-currwavcal0), session=23
        xshift0[n]=mean((wavcal-currwavcal0)[*,*,1],/nan)
        yshift0[n]=mean((wavcal-currwavcal0)[*,*,0],/nan)
        xshiftmed0[n]=median((wavcal-currwavcal0)[*,*,1])
        yshiftmed0[n]=median((wavcal-currwavcal0)[*,*,0])
        elev=backbone->get_keyword( 'ELEVATIO',count=c1,indexframe=n)
        if c1 eq 1 then begin
            elevation[n]=float(elev) 
        endif else begin
            print, "There is no elevation keyword in header. Failed to populate the shifts vs elevation lookup table."
            return, NOT_OK
            ;;hard-coded for ucsc tests
            ;elevation=[95.,95.,95.,60.5,60.5,60.5,29.,29.,29.,0.,0.,0.,60.,60.,60.]
        endelse
    endfor  

    *(dataset.currframe[0])=[[elevation],[xshiftmed],[yshiftmed]]
    ;stop
    suffix = '-shifts'
    backbone->set_keyword, "FILETYPE", "Flexure shift Cal File"
    backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
       
    ;remove NAXIS3
    hdrtmp=*(dataset.headersExt)[numfile]
    sxdelpar, hdrtmp, 'NAXIS'
    sxdelpar, hdrtmp, 'NAXIS1'
    sxdelpar, hdrtmp, 'NAXIS2'
    sxdelpar, hdrtmp, 'NAXIS3'
    sxaddpar,  hdrtmp, 'NAXIS',  (size(*(dataset.currframe[0])))[0]
    sxaddpar,  hdrtmp, 'NAXIS1', (size(*(dataset.currframe[0])))[1]
    sxaddpar,  hdrtmp, 'NAXIS2', (size(*(dataset.currframe[0])))[2]
    *(dataset.headersExt)[numfile]=hdrtmp
       
    ;need plots ?
    if saveplots eq 'yes' then begin
        direc=""
        mydevice = !D.NAME
        psFilename = direc+"flex_x.ps"    
        openps, psFilename
        plot, elevation,xshift, xtitle='Elevation [deg]', ytitle='Shift [pixel]',psym=-1
        closeps
        psFilename = direc+"flex_y.ps"    
        openps, psFilename
        plot, elevation,yshift, xtitle='Elevation [deg]', ytitle='Shift [pixel]',psym=-1, yrange=[min(yshift)-0.5,max(yshift)+0.5]
        closeps
            psFilename = direc+"flex_xmed.ps"    
        openps, psFilename
        plot, elevation,xshiftmed, xtitle='Elevation [deg]', ytitle='Shift [pixel]',psym=-1
        closeps
        psFilename = direc+"flex_ymed.ps"    
        openps, psFilename
        plot, elevation,yshiftmed, xtitle='Elevation [deg]', ytitle='Shift [pixel]',psym=-1, yrange=[min(yshiftmed)-0.5,max(yshiftmed)+0.5]
        closeps
        
            psFilename = direc+"flex_x0.ps"    
        openps, psFilename
        plot, elevation,xshift0, xtitle='Elevation [deg]', ytitle='Shift [pixel]',psym=-1
        closeps
        psFilename = direc+"flex_y0.ps"    
        openps, psFilename
        plot, elevation,yshift0, xtitle='Elevation [deg]', ytitle='Shift [pixel]',psym=-1, yrange=[min(yshift0)-0.5,max(yshift0)+0.5]
        closeps
            psFilename = direc+"flex_x0med.ps"    
        openps, psFilename
        plot, elevation,xshiftmed0, xtitle='Elevation [deg]', ytitle='Shift [pixel]',psym=-1
        closeps
        psFilename = direc+"flex_y0med.ps"    
        openps, psFilename
        plot, elevation,yshiftmed0, xtitle='Elevation [deg]', ytitle='Shift [pixel]',psym=-1, yrange=[min(yshiftmed0)-0.5,max(yshiftmed0)+0.5]
        closeps
        SET_PLOT, mydevice
	endif

	if strlowcase(display) eq 'yes' then begin
		select_window, 0
		elevsortedind=sort(elevation)
		sortedelev=elevation[elevsortedind]
		sortedxshift=xshiftmed[elevsortedind]
		sortedyshift=yshiftmed[elevsortedind]
	
		shiftpolyx = POLY_FIT( sortedelev, sortedxshift, 2)
		shiftpolyy = POLY_FIT( sortedelev, sortedyshift, 2)

		!p.multi=[0,2,1]
		elevs = findgen(90)
		plot, sortedelev, sortedxshift, xtitle='Elevation [deg]', ytitle='X shift [pixel]', xrange=[-10,100], yrange=[-0.9, 0.1], psym=1, charsize=1.5
		oplot, elevs, poly(elevs, shiftpolyx), /line

		plot, sortedelev, sortedyshift, xtitle='Elevation [deg]', ytitle='Y shift [pixel]', xrange=[-10,100], yrange=[-0.9, 0.1], psym=1, charsize=1.5
		oplot, elevs, poly(elevs, shiftpolyy), /line

		legend,/bottom,/right, ['Shifts in lookup table','Model'], color=[!p.color, !p.color, fsc_color('yellow')], line=[0,1,1], psym=[1,0,2], charsize=1.5

	endif



@__end_primitive

end
