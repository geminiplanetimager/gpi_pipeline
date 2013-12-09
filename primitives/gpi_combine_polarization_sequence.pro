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
; PIPELINE ARGUMENT: Name="IncludeSystemMueller" Type="int" Range="[0,1]" Default="1" Desc="1: Include, 0: Don't"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="10" Desc="1-500: choose gpitv session for displaying output, 0: no display "

; PIPELINE ORDER: 4.4
; PIPELINE TYPE: ASTR/POL
; PIPELINE NEWTYPE: PolarimetricScience,Calibration
; PIPELINE SEQUENCE: 11-
;
;
; HISTORY:
;  2009-07-21: MDP Started 
;    2009-09-17 JM: added DRF parameters
;    2013-01-30: updated with some new keywords
;-

;------------------------------------------

;+
; NAME: mueller_rot
;
;  The mueller matrix for a rotation of angle theta
;
; INPUTS:
;   theta - the angle of rotation for the matrix in radians
; OUTPUTS:
;   a 4 x 4 mueller matrix 
; HISTORY:
;   Began 2012 - MMB  
;
;-
function mueller_rot, theta
theta=double(theta)
M=[[1,0,0,0],[0,cos(2*theta),sin(2*theta),0],[0,-sin(2*theta),cos(2*theta),0],[0,0,0,1]]

return, M
end


;------------------------------------------


;+
; NAME: DST_waveplate
;   Given a Stokes datacube, transform it to model instrumental polarization.
;
;   The result is a modified Stokes datacube with the same dimensions as the
;   input cube.
;
;   Right now, this assumes the retarder is a perfect achromatic half wave plate.
;   TODO more realistic imperfect waveplate.
;
; INPUTS:
;   polcube   A polarization datacube. Dimensions [npixels, npixels, nlambda, nStokes ]
;         NOTE: nStokes **must** be 4.
; KEYWORDS:
; angle   Waveplate fast axis angle, in DEGREES.
; /mueller  if set, just return the Mueller matrix instead of applying it.
; OUTPUTS:
;
; HISTORY:
;   Began 2008-02-05 15:29:54 by Marshall Perrin
;-



function DST_waveplate, polcube, angle=angle, degrees=degrees, mueller=return_mueller, silent=silent, retardance=retardance, pband=pband

	if ~ keyword_set(angle) then angle=0
  if keyword_Set(degrees) then theta=angle*!dtor else theta=angle; If keyword set then the input was in degrees
  
; Step 1: Compute the Mueller matrix for a retarder.
  
  if ~ keyword_set(retardance) then begin 
   ;If the retardance isn't set then assume that we are dealing with the GPI HWP, with a
   ;measured retardance
   
    if ~ keyword_set(pband) then pband = 'H' 
      ;prprint, "Using the HWP Mueller Matrix for "+pband+" band"
      case pband of 
        'Y': M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9998,0.0186],[0,0,-0.0186,-0.9998]]
        'J': M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9970,0.0772],[0,0,-0.0772,-0.9970]]
        'H': M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9924,0.1228],[0,0,-0.1228,-0.9924]]
        'K1':M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9996,0.0266],[0,0,-0.0266,-0.9996]]
        'K2':M=[[1,0,0,0],[0,1,0,0],[0,0,-0.9973,-0.0729],[0,0,0.0729,-0.9973]]
      endcase
   ;stop   
  mueller = mueller_rot(-theta)##M##mueller_rot(theta) ; Apply a rotation matrix. If angle wasn't set this has no effect
  
  endif else begin
  d = retardance*360*!dtor
  S2 = sin(2*theta)
  C2 = cos(2*theta)

    mueller = [ [1, 0,                 0,                  0           ],$
              [0, C2^2+S2^2*cos(d),  S2*C2*(1-cos(d)),   -S2*sin(d)  ],$
              [0, S2*C2*(1-cos(d)),  S2^2+C2^2*cos(d),   C2*sin(d)   ],$
              [0, S2*sin(d),         -C2*sin(d),         cos(d)      ]]
  endelse 

	if keyword_set(return_mueller) then return, mueller

; Step 2: Apply that Mueller matrix to the polarization data cube.

	sz = size(polcube)
	if sz[4] ne 4 then message, "Error - polarization axis must be 4 elements long!"

	; we want to transform the polarization cube into a 2D array, nvoxels * 3,
	; so that we can then easily apply the Mueller matrix to multiply it.
	; Empirical speed tests by Marshall indicate that for the matrix multiply, for
	; the sizes of arrays we are dealing with here there is essentially no speedup
	; for arranging things as [3, nvoxels] versus [nvoxels, 3]. Both take ~ 0.04 s
	; to run on my Macbook Pro, as of 2008-02-05.

	tmpCube = reform(polcube, sz[1]*sz[2]*sz[3], sz[4])

	tmpCube2 = mueller ## tmpCube

	outcube = reform(tmpcube2, sz[1], sz[2], sz[3], sz[4])

	return, outcube


end


;+
; NAME: DST_instr_pol
;
; 	Given a Stokes datacube, transform it to model instrumental polarization.
;
; 	The result is a modified Stokes datacube with the same dimensions as the
; 	input cube. 
;
;		Note: Right now this code assumes GPI is on a side-looking port. We
;		don't yet have a system Mueller matrix for the up-looking port.
;
;
; INPUTS:
; 	polcube		A polarization datacube. Dimensions [npixels, npixels, nlambda,	nStokes ]
; 				NOTE: nStokes **must** be 4.
; KEYWORDS: 
; 	mueller=	If present, just return the mueller matrix rather than applying
; 				it to anything. 
; OUTPUTS:
;
; HISTORY:
; 	Began 2008-02-05 10:08:33 by Marshall Perrin 
;
;-


function DST_instr_pol, polcube, mueller=mueller, port=port


; Step 1: Compute the Mueller matrix corresponding to the instrumental
; polarization.


; We take this from the GPI optical model in ZEMAX and Matlab 
; by J. Atwood, K. Wallace and J. R. Graham
;  - see the OCDD appendix 15. 


; Where is GPI mounted? 
if ~(keyword_set(port)) then port="side"
case port of 
	"side": system_mueller = [ $
			[0.5263, 0.0078, 0.0006, 0.0000], $
			[0.0078, 0.5263, -0.0001, 0.0063], $
			[0.0006, 0.0012, 0.5182, -0.0920], $
			[0.0000, -0.0062, 0.0920, 0.5181] $
			]
	"bottom": message, "No system mueller matrix for bottom port yet!"
	"perfect": system_mueller = [ $
			[ 1.0, 0.0, 0.0, 0.0 ], $
			[ 0.0, 1.0, 0.0, 0.0 ], $
			[ 0.0, 0.0, 1.0, 0.0 ], $
			[ 0.0, 0.0, 0.0, 1.0 ] $
			]
endcase

if keyword_set(mueller) then return, system_mueller

; Step 2: Apply that Mueller matrix to the polarization data cube. 
;
sz = size(polcube)
if sz[4] ne 4 then message, "Error - polarization axis must be 4 elements long!"

; we want to transform the polarization cube into a 2D array, nvoxels * 3, 
; so that we can then easily apply the Mueller matrix to multiply it. 
; Empirical speed tests by Marshall indicate that for the matrix multiply, for
; the sizes of arrays we are dealing with here there is essentially no speedup
; for arranging things as [3, nvoxels] versus [nvoxels, 3]. Both take ~ 0.04 s
; to run on my Macbook Pro, as of 2008-02-05.

tmpCube = reform(polcube, sz[1]*sz[2]*sz[3], sz[4])

tmpCube2 = system_mueller ## tmpCube

outcube = reform(tmpcube2, sz[1], sz[2], sz[3], sz[4])

return, outcube


end

;------------------------------------------
;
; FUNCTION: mueller_linpol_rot
;   Returns the 4x4 Mueller polarization matrix for a perfect linear polarizer
;   at position angle theta.
;
; INPUTS:
;   theta   an angle, in degrees

FUNCTION mueller_linpol_rot,theta
;
; The following formula is taken from C.U.Keller's Instrumentation for
;  Astronomical Spectropolarimetry, page 11.
;
;  Or equivalently see Eq. 4.47 of "Introduction to Spectropolarimetry" by 
;  Jose Carlos del Toro Iniesta, Cambridge University Press 2003

ct = cos(2*theta*!dtor)
st = sin(2*theta*!dtor)
return,0.5*[[1.0,   ct,     st,     0],$
            [ct,    ct^2,   ct*st,  0],$
            [st,    st*ct,  st^2,   0],$
            [0,     0,      0,      0]]

end


;------------------------------------------

function gpi_combine_polarization_sequence, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive
	silent=1


	nfiles=dataset.validframecount

	; Load the first file so we can figure out their size, etc. 
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


	sumdiffstack = polstack			; a transformed version of polstack, holding the sum and single-difference images
	stokes = fltarr(sz[1], sz[2], 4); the output Stokes cube!
	stokes2 = stokes
	stokes[*] = !values.f_nan
	stokes2[*] = !values.f_nan
	wpangle = fltarr(nfiles)		; waveplate angles

	portnum=strc(sxpar(hdr0,"INPORT", count=pct))
stop
portnum=4
	if pct eq 0 then port="side"
	if pct eq 1 then begin
	    if portnum eq 1 then port='bottom'
        if (portnum ge 2) && (portnum le 5) then port='side'
        if portnum eq 6 then port='perfect'
	endif    
		print, "using port = "+port
		sxaddhist, functionname+": using instr pol for port ="+port, hdr0
	system_mueller = DST_instr_pol(/mueller, port=port)
  	woll_mueller_vert = mueller_linpol_rot(0)
	woll_mueller_horiz= mueller_linpol_rot(90)
;    woll_mueller_vert = mueller_linpol_rot(90)
;   woll_mueller_horiz= mueller_linpol_rot(0)

	for i=0L,nfiles-1 do begin
	;if numext eq 0 then begin
		;polstack[0,0,i*2] = accumulate_getimage(dataset,i,hdr)
	;endif else begin
	  polstack[0,0,i*2] = accumulate_getimage(dataset,i,hdr0,hdrext=hdrext)
	;endelse	
		wpangle[i] = float(sxpar(hdr0, "WPANGLE"))-float(Modules[thisModuleIndex].HWPOffset) ;Include the known offset
		parang = sxpar(hdr0, "PAR_ANG") ; we want the original, not rotated or de-rotated
										; since that's what set's how the
										; polarizations relate to the sky
		print, "   File "+strc(i)+ ": WP="+strc(wpangle[i]), "     PA="+strc(parang)
		sxaddhist, functionname+":  File "+strc(i)+ ": WP="+strc(wpangle[i])+ "  PA="+strc(parang) , hdr0

    filter=strsplit(sxpar(hdr0,"IFSFILT"), '_',/extract)
    pband=filter[1]

    tabband=[['Y'],['J'],['H'],['K1'],['K2']]
    
    if where(strcmp(tabband, pband) eq 1) lt 0 then return, error('FAILURE ('+functioname+'): IFSFILT keyword invalid. No HWP mueller matrix for that filter')
    
    ;Just testing something: 
    ;wpangle[i]=-wpangle[i]
    ;*****
    
    
		wp_mueller = DST_waveplate(angle=wpangle[i], pband=pband, /mueller,/silent, /degrees)
		;skyrotation_mueller =  mueller_rotate(parang)

		; FIXME: Sky rotation!!
		include_mueller=uint(Modules[thisModuleIndex].IncludeSystemMueller)
		
		if (include_mueller eq 1) then begin ;Either include the system mueller matrix or not. Depending on the keyword
    total_mueller_vert = woll_mueller_vert ## wp_mueller ## system_mueller ;## skyrotation_mueller
    total_mueller_horiz = woll_mueller_horiz ## wp_mueller ## system_mueller ;## skyrotation_mueller
    endif else begin
    total_mueller_vert = woll_mueller_vert ## wp_mueller ;## system_mueller ;## skyrotation_mueller
    total_mueller_horiz = woll_mueller_horiz ## wp_mueller ;## system_mueller ;## skyrotation_mueller
    endelse

		M[*,2*i] = total_mueller_vert[*,0]
		M[*,2*i+1] = total_mueller_horiz[*,0]


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

	*(dataset.currframe)=Stokes
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
  print, string(100*sqrt(qmean^2+umean^2+vmean^2))+" percent polarization"
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


	@__end_primitive
end

