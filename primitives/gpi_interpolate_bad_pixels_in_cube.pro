;+
; NAME: gpi_interpolate_bad_pixels_in_cube
; PIPELINE PRIMITIVE DESCRIPTION: Interpolate bad pixels in cube
;
;	Searches for statistical outlier bad pixels in a cube and replace them
;	by interpolating between their neighbors. 
;
;  CAUTION:
;	Heuristic and not guaranteed or tested in any way; this is more a 
;	convenience function than a rigorous statistcally justified repair tool
;
;	"NEW" method is less of a black box and has been more thought out to identify deviant
;	pixels within a cube and use neighbouring spaxels to interpolate the missing value.
; 	
;
; INPUTS: Cube in either spectral or polarization mode
; OUTPUTS: Cube with bad pixels potentially found and cleaned up. 
;
; PIPELINE ARGUMENT: Name="method" Type="string" Range="[OLD|NEW]" Default="NEW" Desc="Old or new method"
; PIPELINE ARGUMENT: Name="threshold" Type="float" Range="[1,3]" Default="1.2" Desc="Agressivness of new code, 1 (agressive) to 3 (laxed)"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="1" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="before_and_after" Type="int" Range="[0,1]" Default="0" Desc="Show the before-and-after images for the user to see? (for debugging/testing)"
;
; PIPELINE COMMENT:  Repair bad pixels by interpolating between their neighbors. 
; PIPELINE ORDER: 2.5
; PIPELINE CATEGORY: SpectralScience, PolarimetricScience, Calibration
;
;
; HISTORY:
;	2013-12-14 MP: Created as a convenience function cleanup tool. Almost
;	certainly not the best algorithm - just something quick and good enough for
;	now? 
;	2015-05-21 ZD: Added "NEW" method to clean cube using spectral information.
;-
function gpi_interpolate_bad_pixels_in_cube, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive


 	if tag_exist( Modules[thisModuleIndex], "before_and_after") then before_and_after=fix(Modules[thisModuleIndex].before_and_after) else before_and_after=0
    	if keyword_set(before_and_after) then cube0= *dataset.currframe ; save copy for later display if desired

	if tag_exist( Modules[thisModuleIndex], "Method") then method= strupcase(Modules[thisModuleIndex].method) else method="NEW"

	if tag_exist( Modules[thisModuleIndex], "Threshold") then threshold= strupcase(Modules[thisModuleIndex].threshold) else threshold=1.2

  backbone->set_keyword, 'DRPFLEX', Method, ' Selected method for handling flexure-induced shifts'

    backbone->set_keyword,'HISTORY',functionname+": Heuristically locating and interpolating"
    backbone->set_keyword,'HISTORY',functionname+": bad pixels in the data cube."

	print,"Method ",method
	CASE strupcase(method) OF
		"OLD": begin
		 	*dataset.currframe = ns_fixpix(*dataset.currframe)		
			if keyword_set(before_and_after) then begin
				atv, [ cube0, *dataset.currframe ],/bl; , names=['Input image','Output Image', 'Bad Pix Mask']
				stop
			endif
		end
		"NEW": begin
			img = *dataset.currframe
			;find badpixs
			sz = size(img)
			badcube = MAKE_ARRAY(sz[1], sz[2], sz[3], /INTEGER, VALUE = 0)
			
			for n=0,sz[3]-1 do begin
				slice = img[*,*,n]
				lowfrq = median(slice,3)
				tst = abs(slice-lowfrq)
				ids = where(tst gt threshold*lowfrq)
				bad = MAKE_ARRAY(sz[1], sz[2], /INTEGER, VALUE = 0)
				bad[ids] = 1
				badcube[*,*,n] = bad 
			endfor
			print,"Number of bad pixels: ",n_elements(ids)
			;median neighbors
			ids = where_xyz(badcube,xind=xind,yind=yind,zind=zind)
			for i=0,n_elements(ids)-1 do begin
				xl = xind[i]-1
				xh = xind[i]+1
				;boundary conditions check
				if xl lt 0 then xl=0
				if xh ge sz[1] then xh=sz[1]-1
				yl = yind[i]-1
				yh = yind[i]+1
				if yl lt 0 then yl=0
				if yh ge sz[2] then yh=sz[2]-1
				zl = zind[i]-1
				zh = zind[i]+1
				if zl lt 0 then zl=0
				if zh ge sz[3] then zh=sz[3]-1
				img[xind[i],yind[i],zind[i]] = median(img[xl:xh,yl:yh,zl:zh])
				ii=strcompress(string(i,f='(F4)'),/rem) 
  				print,f='(%"\33[1M %s \33[1A")',ii				
			endfor
			*dataset.currframe = img
		end
		ELSE: print,"Parameter Failed"
	ENDCASE

	; update the DQ extension if it is present

	if ptr_valid( dataset.currDQ) then begin
		; we should still leave those pixels flagged to indicate
		; that they were repaired. This is used in some subsequent steps of
		; processing (for instance the 2D wavecal)
		; Bit 5 set = 'flagged as bad'
		; Bit 0 set = 'is OK to use'  therefore 32 means flagged and corrected
		; The following bitwise incantation sets bit 5 and clears bit one
		;(*(dataset.currDQ))[wbad] =  ((*(dataset.currDQ))[wbad] OR 32) and (128+64+32+16+8+4+2)
		;backbone->set_keyword,'HISTORY',functionname+": Updated DQ extension to indicate bad pixels were repaired.", ext_num=0
	endif

  if fix(Modules[thisModuleIndex].save) eq 1 then suffix='-bpfix'


@__end_primitive
end

