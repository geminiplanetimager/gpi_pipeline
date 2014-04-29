;+
; NAME: gpi_combine_polarization_sequence
; PIPELINE PRIMITIVE DESCRIPTION: Combine Polarization Sequence
; 
;	Combine a sequence of polarized images via the SVD method. 
;
;	See James Graham's SVD algorithm document, or this algorithm may be hard to
;	follow.  This is not your father's imaging polarimeter any more!
;
; INPUTS:
; 	This routine assumes that it can read in a series of files on disk which were written by
; 	the previous stage of processing. 
;
;
; 
; GEM/GPI KEYWORDS:EXPTIME,ISS_PORT,PAR_ANG,WPANGLE
; DRP KEYWORDS:CDELT3,CRPIX3,CRVAL3,CTYPE3,CUNIT3,DATAFILE,NAXISi,PC3_3
; ALGORITHM:
;
;
; PIPELINE ARGUMENT: Name="HWPoffset" Type="float" Range="[-360.,360.]" Default="-29.14" Desc="The internal offset of the HWP. If unknown set to 0"
; PIPELINE ARGUMENT: Name="IncludeSystemMueller" Type="int" Range="[0,1]" Default="0" Desc="1: Include, 0: Don't"
; PIPELINE ARGUMENT: Name="IncludeSkyRotation" Type="int" Range="[0,1]" Default="1" Desc="1: Include, 0: Don't"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="10" Desc="1-500: choose gpitv session for displaying output, 0: no display "

; PIPELINE ORDER: 4.4
; PIPELINE CATEGORY: PolarimetricScience,Calibration
;
;
; HISTORY:
;  2009-07-21: MDP Started 
;    2009-09-17 JM: added DRF parameters
;    2013-01-30: updated with some new keywords
;    2014-03 MP and MM-B: Polarization coordinates and angles verification and debug
;-


;------------------------------------------

function gpi_combine_polarization_sequence, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

	if tag_exist( Modules[thisModuleIndex], "includesystemmueller") then IncludeSystemMueller=uint(Modules[thisModuleIndex].IncludeSystemMueller) else IncludeSystemMueller=1
	if tag_exist( Modules[thisModuleIndex], "includeskyrotation") then   Includeskyrotation=  uint(Modules[thisModuleIndex].Includeskyrotation)   else Includeskyrotation=1

	nfiles=dataset.validframecount

	; Load the first file so we can figure out their dimensions, etc. 
	im0 = accumulate_getimage(dataset, 0, hdr0,hdrext=hdrext)


	; Load all files at once. 
	M = fltarr(4, nfiles*2)			; this will be the measurement matrix of coefficients for the Stokes parameters.
	Msumdiff = fltarr(4, nfiles*2)	; a similar measurement matrix, for the sum and single-difference images. 

	sz = [0, sxpar(hdrext,'NAXIS1'), sxpar(hdrext,'NAXIS2'), sxpar(hdrext,'NAXIS3')]
	exptime = gpi_get_keyword( hdr0, hdrext, 'ITIME') 
	polstack = fltarr(sz[1], sz[2], sz[3]*nfiles)


	; right now this routine carries out two parallel sets of computations:
	;  one acting on the observed images, and
	;  one acting on the pairs of sums and difference images. 
	;
	; It's TBD whether this makes any difference or not.
	; But so far it appears the answer is not.


	sumdiffstack = polstack			; a transformed version of polstack, holding the sum and single-difference images
	stokes = fltarr(sz[1], sz[2], 4); the output Stokes cube!
	stokes2 = stokes
	stokes[*] = !values.f_nan
	stokes2[*] = !values.f_nan
	wpangle = fltarr(nfiles)		; waveplate angles

	portnum=strc(sxpar(hdr0,"INPORT", count=pct))

	if pct eq 0 then port="side"
	if pct eq 1 then begin
	    if portnum eq 1 then port='bottom'
        if (portnum ge 2) && (portnum le 5) then port='side'
        if portnum eq 6 then port='perfect'
	endif    
	backbone->Log, "using instr pol for port = "+port
	sxaddhist, functionname+": using instr pol for port ="+port, hdr0
	
	;Good for on-sky data
  ; woll_mueller_vert = mueller_linpol_rot(0,/degrees)
	; woll_mueller_horiz= mueller_linpol_rot(90,/degrees)
	
	;Good for lab data
    woll_mueller_vert = mueller_linpol_rot(90,/degrees) 
    woll_mueller_horiz= mueller_linpol_rot(0,/degrees)
    
    ;Getting Filter Information
    filter=gpi_simplify_keyword_value(sxpar(hdr0,"IFSFILT"))
    tabband=['Y','J','H','K1','K2']
    if where(strcmp(tabband, filter) eq 1) lt 0 then return, error('FAILURE ('+functioname+'): IFSFILT keyword invalid. No HWP mueller matrix for that filter')
    
    if (include_mueller eq 1) then system_mueller = DST_instr_pol(/mueller, pband=filter, port=port) else system_mueller = identity(4)

	for i=0L,nfiles-1 do begin
		polstack[0,0,i*2] = accumulate_getimage(dataset,i,hdr0,hdrext=hdrext)

		wpangle[i] =-(float(sxpar(hdr0, "WPANGLE"))-float(Modules[thisModuleIndex].HWPOffset)) ;Include the known offset
		parang = sxpar(hdr0, "PAR_ANG") ; we want the original, not rotated or de-rotated
										; since that's what set's how the
										; polarizations relate to the sky
										; FIXME this should be updated to AVPARANG
		logmsg =  "   File "+strc(i)+ ": WP="+sigfig(wpangle[i],4)+ "     PA="+sigfig(parang, 4)
		backbone->Log, logmsg
		sxaddhist, functionname+":"+logmsg, hdr0
 
		wp_mueller = DST_waveplate(angle=wpangle[i], pband=pband, /mueller,/silent, /degrees)
		
		  
		if include_sky eq 1 then skyrotation_mueller =  mueller_rot((parang+90-18.5)*!dtor) else skyrotation_mueller=identity(4)
    
;    object=sxpar(hdr0, 'OBJECT') 
;    if strcmp(strcompress(object), 'Zenith ') eq 1 and include_sky eq 1 then begin ;If we aren't tracking then don't trust the parallactic angle. 
;      skyrotation_mueller =  mueller_rot((90-18.5)*!dtor)
;      print, 'Ignoring the parallactic angles'
;    endif	
    
    sign_flip=[[1,0,0,0],[0,1,0,0],[0,0,-1,0],[0,0,0,-1]]
    
	if (include_mueller eq 1) then begin ;Either include the system mueller matrix or not. Depending on the keyword
		total_mueller_vert = woll_mueller_vert ##  sign_flip ## wp_mueller ## system_mueller ## skyrotation_mueller 
		total_mueller_horiz = woll_mueller_horiz ## sign_flip## wp_mueller ## system_mueller ## skyrotation_mueller
    endif else begin
		total_mueller_vert = woll_mueller_vert ## sign_flip ## wp_mueller ## skyrotation_mueller
		total_mueller_horiz = woll_mueller_horiz ## sign_flip ## wp_mueller ## skyrotation_mueller
    endelse

;		M[*,2*i] = total_mueller_vert[*,0]
;		M[*,2*i+1] = total_mueller_horiz[*,0]
		
		; fill in rows into the system measurement matrix
		M[*,2*i+1] = total_mueller_vert[*,0]
		M[*,2*i] = total_mueller_horiz[*,0]

		; for convenience, set up summed and differences images from each
		; polarization pair 
		sumdiffstack[0,0,i*2] = polstack[*,*,i*2] + polstack[*,*,i*2+1]
		sumdiffstack[0,0,i*2+1] = polstack[*,*,i*2] - polstack[*,*,i*2+1]
		Msumdiff[*,2*i] = M[*,2*i]+M[*,2*i+1]
		Msumdiff[*,2*i+1] = M[*,2*i]-M[*,2*i+1]

	endfor 
	
	stack0 =polstack

	svdc, M, w, u, v
	svdc, Msumdiff, wsd, usd, vsd

	; check for singular values and set to zero if they are close to machine
	; precision limit
	wsingular = where(w lt (machar()).eps*5, nsing)
	if nsing gt 0 then w[wsingular]=0
	wsdsingular = where(wsd lt (machar()).eps*5, nsdsing)
	if nsdsing gt 0 then wsd[wsdsingular]=0

	; at this point we should have properly computed the system response matrix M.
	; We can now iterate over each position in the FOV and compute the derived
	; Stokes vector at that position.


	;--------- Experimental development code here

	; ignoring rotation - partially hard coded for HR 4796A - 
	sumstack = sumdiffstack[*,*,indgen(nfiles)*2]
	diffstack = sumdiffstack[*,*,indgen(nfiles)*2+1]


	; subtract off median difference to reduce systematics
	mdiff = median(diffstack,dim=3)
	skysub, diffstack, mdiff, subdiffstack
	subdiffstack = ns_fixpix(subdiffstack)
	lpi =  total(abs(subdiffstack),3) / nfiles
	sum =  total(abs(sumstack),3) / nfiles

	;stop

	; for HD 100546 the above doesn't work well since the disk is TOO visible.
	; Instead:
	cleandiff = ns_fixpix(diffstack)
	cleandiff = ns_fixpix(cleandiff)

	cleansum = ns_fixpix(sumstack)
	cleansum = ns_fixpix(cleansum)

	


	cleandiff2= cleandiff
	for k=0,3 do cleandiff2[*,*,k] = median(cleandiff2[*,*,k],3)
	cleansum2= cleansum
	for k=0,3 do cleansum2[*,*,k] = median(cleansum2[*,*,k],3)
	
	lpi = sqrt(total(cleandiff2^2, 3)/2)

	sum = total(cleansum2,3)/4

	stop

	;--------- End of experimental section


  
	for x=0L, sz[1]-1 do begin
	for y=0L, sz[2]-1 do begin
		;statusline, "Solving for Stokes vector at lenslet "+printcoo(x,y)
		wvalid = where( finite(polstack[x,y,*]), nvalid ) ; how many pixels are valid for this slice?
		wsdvalid = where(finite(sumdiffstack[x,y,*]), nsdvalid) ; how many sum-difference pixels are value for this slice?
		if nvalid eq 0 then continue
		if nvalid eq nfiles*2 then begin
			; apply the overall solution for pixels which are valid in all
			; frames
			stokes[x,y,*] = svsol( u, w, v, reform(polstack[x,y,*]))
			;stokes2[x,y,*] = svsol( usd, wsd, vsd, reform(sumdiffstack[x,y,*]))
		endif else begin
			; apply a custom solution for pixels which are only valid in SOME
			; frames (e.g. because of field rotation)
			svdc, M[*,wvalid], w2, u2, v2
			;svdc, Msumdiff[*,wsdvalid], wsd2,usd2,vsd2
	
			wsingular = where(w2 lt (machar()).eps*5, nsing)
			;wsdsingular = where(wsd2 lt (machar()).eps*5, nsdsing)
			
			if nsing gt 0 then w2[wsingular]=0
      ;if nsdsing gt 0 then wsd2[wsdsingular]=0
      
			stokes[x,y,*] = svsol( u2, w2, v2, reform(polstack[x,y,wvalid]))
			;stokes2[x,y,*] = svsol( usd2, wsd2, vsd2, reform(sumdiffstack[x,y,wsdvalid]))
			
		endelse
	endfor 
	endfor 

	; should we do the fit to the two polarized images, or to the sum and diff
	; images?
	; there does not appear to be much difference between the two methods, 
	; which seems logical given that they are a linear combination...
	
	; stokes=stokes2 ;Output the sum difference stack
	 
	; Apply threshhold for ridiculously high values
	imax = max(polstack,/nan)
	wbad = where(abs(stokes) gt imax*4, badct)
	stokes0=stokes
	if badct gt 0 then stokes[wbad]=0

	q = stokes[*,*,1]
	u = stokes[*,*,2]
	p = sqrt(q^2+u^2)


	; Compute a "minimum speckle" version of the Stokes I image. 
	wbad = where(polstack eq 0, badct)
	if badct gt 0 then polstack[where(polstack eq 0)]=!values.f_nan
	polstack2 = polstack[*,*,findgen(nfiles)*2]+polstack[*,*,findgen(nfiles)*2+1]
	minim = q*0
	sz = size(minim)
	for ix=0L,sz[1]-1 do for iy=0L,sz[1]-1 do minim[ix,iy] = min(polstack2[ix,iy,*],/nan)
	;atv, [[[minim]],[[stokes]],[[p]]],/bl, names = ["Mininum I", "I", "Q", "U", "V", "P"]

	if tag_exist( Modules[thisModuleIndex], "display") then display=keyword_set(Modules[thisModuleIndex].display) else display=0 
	if keyword_set(display) then begin
		atv, [[[stokes]],[[p]]],/bl, names = ["I", "Q", "U", "V", "P"], stokesq=q/minim, stokesu=u/minim
		; Display I Q U P
		!p.multi=[0,4,1]
		 imdisp_with_contours, alogscale(stokes[*,*,0]), /center, pixel=0.014,/nocontour, title="Stokes I"
		 sd = stddev(stokes[*,*,1],/nan)/3
		 imdisp_with_contours, bytscl(stokes[*,*,1], -sd, sd), /center, pixel=0.014,/nocontour, title="Stokes Q"
		 imdisp_with_contours, bytscl(stokes[*,*,2], -sd, sd), /center, pixel=0.014,/nocontour, title="Stokes U"
		 imdisp_with_contours, alogscale(p), /center, pixel=0.014,/nocontour , title = "Polarized Intensity"

		demo = [stokes[*,*,0], stokes[*,*,1], stokes[*,*,2], p]

		stop
	endif
	; Display I P
	
	if keyword_set(smooth) then begin
		smq = filter_image(q, fwhm_gaussian=3)
		smu = filter_image(u, fwhm_gaussian=3)
		ps = sqrt (smq^2+smu^2)
	endif

;	erase
;	outname = "disk-demo2"
;
;	if keyword_set(ps) then psopen, outname, xs=6, ys=3
;	!p.multi=0
;	imax=1e3 & imin=1e-1
;	pmax=1e2 & pmin=1e-1
;	;pmax=1e1 & pmin=1e-2
;	pos = [ 0.112500, 0.423918, 0.387500, 0.874943 ]
;	pos2 = [ 0.462500, 0.423918, 0.727500, 0.874943 ]
;	 ;imdisp_with_contours, stokes[*,*,0], min=imin, max=imax,/alog, /center, pixel=0.014,/nocontour, title="Total Intensity", $
;	 imdisp_with_contours, minim/exptime, min=imin, max=imax,/alog, /center, pixel=0.014,/nocontour, title="Total Intensity", $
;	 	out_pos = opi, /noscale, ytitle="Arcsec", pos=pos
;	 imdisp_with_contours, p/exptime, min=pmin, max=pmax,/alog, /center, pixel=0.014,/nocontour , title = "Polarized Intensity", $
;	 	out_pos = opp, /noscale, pos=pos2, xvals=xv, yvals=yv, /noerase
;	 colorbar, /horizontal, range=[imin, imax], pos = [opi[0], 0.25, opi[2], 0.3],/xlog, xtickformat='exponent', $
;	 	xtitle= "Counts/sec/lenslet", xminor=1, charsize=0.7, divisions=4
;	 colorbar, /horizontal, range=[pmin, pmax], pos = [opp[0], 0.25, opp[2], 0.3],/xlog, xtickformat='exponent', divisions=3,$
;	 	xtitle= "Counts/sec/lenslet", xminor=1, charsize=0.7
;
;	white=getwhite()
;	 polvect, q/stokes[*,*,0], u/stokes[*,*,0], xv, yv,resample=12,minmag=0.03, thetaoffset=-155, color=white, thick=1;;
;	 ; Faint version:
;	 ;polvect, smq/stokes[*,*,0], smu/stokes[*,*,0], xv, yv,resample=12,minmag=0.0001, thetaoffset=-155, color=white, thick=1, badmask=(p gt 200), magnif=3
;	 if keyword_set(ps) then psclose,/show
;
;
;	imdisp_with_contours, alogscale([stokes[*,*,0],p],imin,imax),/center,pixel=0.014,/nocontour
;
;	stop
;
;	; sanity check - how well does this work for 1 pixel?
;	x = 160 & y=130
;	plot, polstack[x,y,*],/yno
;
;	soln = M ## reform(stokes[x,y,*])
;	oplot, soln, color=cgcolor('red')
;
;
;	; check the whole cube
;	synth = polstack
;	for ix=0L,sz[1]-1 do for iy=0L,sz[1]-1 do synth[ix,iy,*] = M ## reform(stokes[ix,iy,*])
;
;	; estimate errors - See Numerical Recipes eqn 15.4.19 in 2nd ed. 
;	errors = fltarr(4)
;	for j=0L,3 do for i=0L,3 do if w[i] ne 0 then errors[j] += (V[j,i]/w[i])^2
;
;	stop
;
	sxaddhist, functionname+": Updating WCS header", hdrext
	; Assume all the rest of the WCS keywords are still OK...
    sz = size(Stokes)
    sxaddpar, hdrext, "NAXIS", sz[0], /saveComment
    sxaddpar, hdrext, "NAXIS1", sz[1], /saveComment
    sxaddpar, hdrext, "NAXIS2", sz[2], /saveComment
    sxaddpar, hdrext, "NAXIS3", sz[3], /saveComment

    sxaddpar, hdrext, "CTYPE3", "STOKES",  "Polarization"
    sxaddpar, hdrext, "CUNIT3", "N/A",     "Polarizations"
    sxaddpar, hdrext, "CRVAL3", 1, 		" Stokes axis:  I Q U V "
    sxaddpar, hdrext, "CRPIX3", 0,         "Reference pixel location"
    sxaddpar, hdrext, "CDELT3", 1, 		" Stokes axis:  I Q U V "
    sxaddpar, hdrext, "PC3_3", 1, "Stokes axis is unrotated"



	; store the outputs: this should be the ONLY valid file in the stack now, 
	; and adjust the # of files!
;stop
; endif else begin
	*(dataset.headersPHU[numfile])=hdr0
	*(dataset.headersExt[numfile])=hdrext

	backbone->set_keyword, 'DRPNFILE', nfiles, "# of files combined to produce this output file"

	*(dataset.currframe)= Stokes
	;*(dataset.headers[numfile]) = hdr
	suffix = "-stokesdc"
  
  I=stokes[*,*,0]
  Q=stokes[*,*,1]
  U=stokes[*,*,2]
  V=stokes[*,*,3]
  
  normQ=Q/I
  normU=U/I
  normV=V/I

  meanclip, I[where(finite(I))], imean, istd
  meanclip, normQ[where(finite(normQ))], qmean, qstd
  meanclip, normU[where(finite(normU))], umean, ustd
  meanclip, normV[where(finite(normV))], vmean, vstd


  print, "------Mean Normalized Stokes Values------"
  print, "Q = "+string(qmean)
  print, "U = "+string(umean)
  print, "V = "+string(vmean)
  print, "P = "+string(100*sqrt(qmean^2+umean^2))+"    percent linear polarization"
  print, "PA = "+string(atan(umean,qmean)/!dtor/2)+" Mean PA across the field"
  print, string(100*sqrt(qmean^2+umean^2+vmean^2))+"     percent polarization"
  print, "------------------------------"
  
;; This is some code to write the mean stokes parameters out to a file called stokes.gpi
;; It's currently set-up to just make the file in the reduced data directory
;; If the file is there it appends to it.   
;  filnm=fxpar(*(DataSet.HeadersPHU[numfile]),'DATAFILE',count=cdf)
;  if ~file_test(Modules[thisModuleIndex].OutputDir+"stokes.gpi") then begin
;    openw, lun, Modules[thisModuleIndex].OutputDir+"stokes.gpi", /get_lun, width=200 
;    printf, lun, "#imean, qmean,umean,vmean,qstd,ustd,vstd,' ',filnm"
;  endif else begin
;  openu, lun, Modules[thisModuleIndex].OutputDir+"stokes.gpi",/get_lun, /append, width=200
;  endelse
;  printf, lun, imean, qmean,umean,vmean,istd,qstd,ustd,vstd,' ',filnm
;  close, lun


  ; save the 'quick and dirty' pol code version
  real_currframe = *dataset.currframe
  *dataset.currframe = [[[sum]],[[lpi]]]

   save_suffix = 'quickpol'
   b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, save_suffix, display=3)

   ; now save the 'real' code version.
  *dataset.currframe = real_currframe
   save_suffix = 'stokesdc'
	@__end_primitive
end

