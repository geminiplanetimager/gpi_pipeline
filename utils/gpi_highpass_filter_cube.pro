;+
; NAME:  gpi_highpass_filter_cube
;
;	highpass filter a cube, parallelized if that's allowed
; when at_gemini parallelization is skipped because finding the new IDL
; license takes a long time. Only when using a local license should 
; parallelization be invoked
;
; INPUTS:
;	datacube		a datacube
; KEYWORDS:
;	boxsize			size of box to use. Default is 15
;	/verbose		Be more talkative while working.
;	/force_skip		Skip parallelizing - this useful when it takes a long time to open new IDL sessions.
; OUTPUTS:
;
; HISTORY:
;	Began 014-11-11 22:13:37 by Marshall Perrin 
;-


function gpi_highpass_filter_cube, datacube, boxsize=boxsize, verbose=verbose, force_skip=force_skip

	sz = size(datacube)
	return_array = fltarr(sz[1],sz[2],sz[3])

	;--- Avoid disallowed parallelization for Runtime IDL
	; Also the summit computer is really slow to start IDL sessions
	; since it has to hit a license server somewhere far away, so 
	; don't parallelize there either.

	;;fix: if at_gemini not defined in settings file, then pipeline thinks you're at Gemini
  Gemtest=gpi_get_setting('at_gemini')
	if Gemtest eq 'ERROR' then Gemtest=0 
	if lmgr(/runtime) or keyword_set(force_skip) or (Gemtest eq 1) then begin
		if keyword_set(verbose) then message,/info,"Can't start parallel IDL processes for IDL runtime"
		if keyword_set(force_skip) then message,/info,"Forcing non-parallelized high-pass filtering"
		if keyword_set(verbose) then message,/info," Just going to run regular high pass in this process."
		for s=0,sz[3]-1 do return_array[*,*,s]=datacube[*,*,s]-filter_image(datacube[*,*,s],median=boxsize)
		return, return_array
	endif
	;--- end Avoid disallowed parallelization



	if ~(keyword_set(boxsize)) then boxsize=15
	t00 = Systime(/Seconds)
	;print, "a", t00

    ; Setting up the shared memory
    shmmap, 'datacube_to_filter', /float, sz[1],sz[2],sz[3]
    datacube_to_filter=shmvar('datacube_to_filter')

	datacube_to_filter[*] = datacube

	; There's a nontrivial overhead to starting more threads here, a substantial
	; fraction of a second. Empirically 
	nbparallel = !CPU.TPOOL_NTHREADS < 4 < sz[3]
	if keyword_set(verbose) then print, "Starting "+strc(nbparallel)+" parallel processes"

	startstop = intarr(2, nbparallel)
	;print, "b", Systime(/Seconds)-t00

	; Split up the number of slices of the cube so that each process has about
	; the same number of slices to work on.
	last = -1
	for ipar=0,nbparallel-1 do begin &$
		startstop[0, ipar] = last+1  &$
		startstop[1, ipar] = ( startstop[0, ipar] + round(sz[3]/nbparallel) )<(sz[3]-1)  &$
		last = startstop[1, ipar] &$
	endfor
	;print, "c", Systime(/Seconds)-t00

	t0=Systime(/Seconds)
	bridges = ptrarr(nbparallel)
	for ipar=0L,nbparallel-1 do begin
		; create new IDL session and initialize the necessary variables
		; there.
		bridges[ipar] = ptr_new(obj_new('IDL_IDLBridge'))
		(*bridges[ipar])->SetVar, 'istart', startstop[0, ipar]
		(*bridges[ipar])->SetVar, 'istop', startstop[1, ipar]
		(*bridges[ipar])->SetVar, 'medboxsize', boxsize
		cmd1 = "SHMMap, 'datacube_to_filter', /float, "+string(sz[1])+","+string(sz[2])+","+string(sz[3])
		cmd2 = "datacube=shmvar('datacube_to_filter')"
		cmd3 = "for s=istart,istop do datacube[*,*,s]-=filter_image(datacube[*,*,s],median=medboxsize)"
		(*bridges[ipar])->Execute,/nowait , cmd1+" & " +cmd2 +" & " + cmd3
		if keyword_set(verbose) then message,/info, "Spawned parallelized highpass filter #"+strc(ipar+1)
	end 
	if keyword_set(verbose) then message,/info, 'Spawned processes in '+strc(Systime(/Seconds)-t00)+ " s"
	
	; now keep looping and wait for them all to finish
	going = 1
	stats =intarr(nbparallel)
	while (going) do begin
		for ipar=0L,nbparallel-1 do stats[ipar] = (*bridges[ipar])->Status()
		if total(stats) eq 0 then going=0
		if keyword_set(verbose) then message,/info,"Waiting for parallelized highpass filter: "+aprint(stats)
		wait, 0.05
	endwhile
	;message,/info, "Parallel computation done!"
	;print, "e", Systime(/Seconds)-t00

	; turn it back from shared memory to a regular array
	return_array[*] = datacube_to_filter
	;print, "f", Systime(/Seconds)-t00
	
	if keyword_set(verbose) then message,/info, "Cleaning up"
	for ipar=0L,nbparallel-1 do obj_destroy, *bridges[ipar]
	shmunmap, 'datacube_to_filter'
	if keyword_set(verbose) then message,/info, "Done"
	if keyword_set(verbose) then message,/info, 'Parallelized highpass complete in '+strc(Systime(/Seconds)-t00)+ " s"
	
	return, return_array
end
