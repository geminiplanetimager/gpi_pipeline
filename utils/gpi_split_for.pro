;+
; NAME: gpi_split_for
;
;  This is a modified-for-GPI version of split_for.pro by
;  Rob Silva at UCSC. See GPI section at end of this doc header.
;
;
;PURPOSE
;	to split a for loop into N object parallel processes
;SYNTAX
;	split_for, start, finish[, varnames=varnames, nsplit=nsplit, $
;               outvar=outvar, commands=commands, $
;               ctvariable_name=ctvariable_name, struct2pass1=struct2pass1,$
;               struct2pass2=struct2pass2, struct2pass3=struct2pass3,$
;               struct2pass4=struct2pass4, struct2pass5=struct2pass5, $
;               silent=silent, waittime=waittime,$
;                struct2out1=struct2out1,$
;               struct2out2=struct2out2, struct2out3=struct2out3,$
;               struct2out4=struct2out4, struct2out5=struct2out5]
;		test=test
;INPUTS
;	start: begining index for the for loop, note only loops increasing by
;		1 are allowed
;	finish: ending index for the for loop
;	commands: string array of commands. DO NOT INCLUDE COMMENTS with ';'
;	ctvariable_name: a string scalar set to the name of the for loop index
;		[default to 'i']
;	varnames: a string array of variable names you want passed 
;		to the child prcocess note that you have to 
;		pass tructures with the struct2pass keywords
;	struct2pass[1...5]: structure to pass to child process
;	outvar: string array of names of output variables
;		this will be output to a variable with this name followed by
;		a number denoted which string it came from. if you want to
;		pull out a structure you must use the struct2out keywords
;	waittime: time between tests to see if threads are complete [1]
;	silent: set to suppress output	
;	struct2out[1...5]: structure to pull out of child 
;		process... [currently not implemented]
;	debug: set to the number of the thread you want to debug
;	/halt: set to place a STOP command before and after you run
;		the batch script if debug is set
;	levoff: how many levels up do you want to grab your variable names from
;	wait_interval: time between each split
;EXAMPLE
;	kk=10
;  	split_for, 0, 10, commands=[$
;        'print, i', 'kk++', 'mmm=kk*i'], varnames='kk', $
;        outvar='mmm'
;
;	print, mmm0, mmm1
;	
;TO DO
;	pass structures out
;	maybe allow users to define an expression to 
;		combine the variables output from the strings
;		but is that really any easier than them just doing it?
;	notes... for simplicity, this code only accepts for loops
;		which increase the ctvariable by 1
;
;Written by R. da Silva, UCSC, 9-17-10
;Updated by R. da Silva, UCSC, 3-14-11 == fixed some bugs
;
;
;GPI:
;
; 2013-12-10 by M. Perrin:
; Some customizations for GPI data pipeline:
;	 1) Ability to have arbitrary numbers of threads including
;	    more than the number of hardware cores (this is useful
;	    in the case that chunks of work are not of equal size.)
;	 2) Sets i_start and i_end variables in the worker threads so
;	    each can know what range of work it's going to do. 
;	 3) WORK IN PROGRESS/TO DO: Set up shared memory between sessions
;	    to hand back current status in each for progress bar updates.
;-

pro gpi_split_for, start, finish, varnames=varnames, nsplit=nsplit, $
               outvar=outvar, commands=commands, $
               ctvariable_name=ctvariable_name, struct2pass1=struct2pass1,$
               struct2pass2=struct2pass2, struct2pass3=struct2pass3,$
               struct2pass4=struct2pass4, struct2pass5=struct2pass5, $
               silent=silent, waittime=waittime,$
               struct2out1=struct2out1,$
               struct2out2=struct2out2, struct2out3=struct2out3,$
               struct2out4=struct2out4, struct2out5=struct2out5, test=test, $
               after_loop_commands=after_loop_commands, debug=debug, $
	       levoff=levoff, halt=halt, wait_interval=wait_interval
;if ~keyword_set(levoff) then if scope_level() EQ 2 then levoff=2

fluff='x123123'
basename=fluff+'batch.pro'
if n_elements(debug) NE 0 AND x_chkfil('simple_batch_451451', /silent) EQ 0 then begin
    splog, 'simple batch file not written, writing and calling self recursively'
    openw, lun2, 'simple_batch_451451', /get_lun
    printf, lun2, '@p'+rstring(debug)+basename
    close, lun2
    free_lun, lun2
    if keyword_set(levoff) then l1=levoff-1 else l1=-1
    split_for, start, finish, varnames=varnames, nsplit=nsplit, $
      outvar=outvar, commands=commands, $
      ctvariable_name=ctvariable_name, struct2pass1=struct2pass1,$
      struct2pass2=struct2pass2, struct2pass3=struct2pass3,$
      struct2pass4=struct2pass4, struct2pass5=struct2pass5, $
      silent=silent, waittime=waittime,$
      struct2out1=struct2out1,$
      struct2out2=struct2out2, struct2out3=struct2out3,$
      struct2out4=struct2out4, struct2out5=struct2out5, test=test, $
      after_loop_commands=after_loop_commands, debug=debug, levoff=l1, halt=halt
endif else begin

    if keyword_set(levoff) EQ 0 then levoff=0
    if keyword_set(silent) then verbose = 0 else verbose =1
    if not keyword_set(waittime) then waittime =1
    if not keyword_set(ctvariable_name) then ctvariable_name='i'
;first you need to make your IDL bridges
    if not keyword_set(nsplit) then nsplit=2
    ;nsplit = nsplit < !CPU.HW_NCPU ; user can make this whatever they want!


    nsplit=nsplit < (finish-start+1) ;don't want to duplicated jobs with too many threads
    if nsplit > 32:
        if keyword_set(verbose) then splog, 'Requested NSPLIT', nsplit, ' is greater than the recommended maximum around 32 threads.'
        nsplit = 32
    
    step=ceil((finish-start+1.)/nsplit)
    fin_arr=start+step*(findgen(nsplit)+1)
    min_fin_arr=min(where(fin_arr GE finish))
    nsplit=min_fin_arr+1
    if keyword_set(verbose) then splog, 'Splitting job into ', nsplit, ' threads'


	; Set up some shared memory to pass status variables back to the main IDL
	; session 

;now we need to write the batch files that tell the child processes what to do

    for i=0, nsplit-1 do begin
        openw,lun, 'p'+rstring(i)+basename, /get_lun



        if i NE nsplit-1 then  begin
			ctvariable_start = start+i*step
			ctvariable_stop  = start+(i+1)*step-1
		endif else begin 
			ctvariable_start = start+i*step
			ctvariable_stop  = finish
		endelse 
		printf,lun, ctvariable_name+'_start='+rstring(ctvariable_start)
		printf,lun, ctvariable_name+'_stop=' +rstring(ctvariable_stop)
		printf,lun, 'for '+ctvariable_name+'='+$
          rstring(ctvariable_Start)+','+rstring(ctvariable_stop)+' do begin &$' 

        for j=0, n_elements(commands)-1 do printf, lun, commands[j]+' &$'
        printf, lun, 'endfor'
        if n_elements(after_loop_commands) NE 0 then $
          for j=0, n_elements(after_loop_commands)-1 do printf, lun, $
          after_loop_commands[j]
        printf, lun, 'splog, "*-*-*-*-*-*-*-*-*-*"'
        printf, lun, 'splog, "completed bridge '+rstring(i)+'"'
        printf, lun, 'splog, "*-*-*-*-*-*-*-*-*-*"'
        close, lun
        free_lun, lun
    endfor
    if keyword_set(test) then begin
        splog, 'batch files have been written'
        splog, '/test has been set so you can examine them'
        STOP
    endif


    if n_elements(debug) EQ 0 then begin
        obridge=obj_new("IDL_IDLBridge", output='')

        if nsplit GT 1 then begin
            for i=1, nsplit-1 do begin
                obridge=[obridge, obj_new("IDL_IDLBridge", output='')]
            endfor
        endif

				cd,current=pwd
        fluffx123123pwd=pwd
;now we pass variables and run the batch files
        for i=0, n_elements(obridge)-1 do begin
                                ;need to pass variables...
                                ;structures are complicated so I have to kludge this....
            if keyword_set(struct2pass1) then $
              struct_pass, struct2pass1, obridge[i], lev=-2+levoff
            if keyword_set(struct2pass2) then $
              struct_pass, struct2pass2, obridge[i], lev=-2+levoff
            if keyword_set(struct2pass3) then $
              struct_pass, struct2pass3, obridge[i], lev=-2+levoff
            if keyword_set(struct2pass4) then $
              struct_pass, struct2pass4, obridge[i], lev=-2+levoff
            if keyword_set(struct2pass5) then $
              struct_pass, struct2pass5, obridge[i], lev=-2+levoff
            if n_elements(varnames) NE 0 then $
              for j=0, n_elements(varnames)-1 do $
              obridge[i]->setvar, varnames[j], scope_varfetch(varnames[j],level=-1+levoff)
                                ;move to the right directory
            obridge[i]->setvar, 'which_bridge', i
            obridge[i]->setvar, 'fluffx123123pwd', fluffx123123pwd
if keyword_set(wait_interval) then wait, wait_interval
            obridge[i]->execute, "cd, fluffx123123pwd"
                                ;run the batch files
            obridge[i]->execute, '@'+'p'+rstring(i)+basename, /nowait
        endfor
        if keyword_set(verbose) then splog, 'Commands have been sent to threads'
;----------------------------------------------------
;now we wait until the bridges are all done
        alldone=0
        while alldone EQ 0 do begin
            fins=0
            for i=0, nsplit-1 do begin
                fins+=(obridge[i]->status() NE 1)
                                ;print, i, (obridge[i]->status() EQ 2)
            endfor
            wait, waittime
            if fins EQ nsplit then alldone=1
        endwhile
        if keyword_set(verbose) then splog, 'All threads complete'
;----------------------------------------------------
;now we get our outputs out
        if n_elements(outvar) NE 0 then begin
            for j=0, n_elements(outvar)-1 do begin
                for i=0, nsplit-1 do begin
                                ;use scopevarfetch with level=0 to make variables with the string names... with
                    (scope_varfetch(outvar[j]+rstring(i),$
				 level=-1+levoff,/enter))=$
						obridge[i]->getvar(outvar[j])
                endfor
            endfor
        endif

;----------------------------------------------------
;now we delete our temp batch files
        for i=0, nsplit-1 do begin
            openw,lun, 'p'+rstring(i)+basename, /delete
            close, lun
	    free_lun, lun
        endfor

; you have to burn your idl bridges
        for i=0, nsplit-1 do begin
            obj_destroy, obridge[nsplit-1-i]
        endfor
    endif else begin            ;debug mode
        splog, 'Entering Debug Mode testing thread ', debug
;pass variables to here
        if keyword_set(struct2pass1) then $
          (scope_varfetch(scope_varname(struct2pass1, level=-1+levoff), level=0, /enter))=struct2pass1
        if keyword_set(struct2pass2) then $
          (scope_varfetch(scope_varname(struct2pass2, level=-1+levoff), level=0, /enter))=struct2pass2
        if keyword_set(struct2pass3) then $
          (scope_varfetch(scope_varname(struct2pass3, level=-1+levoff), level=0, /enter))=struct2pass3
        if keyword_set(struct2pass4) then $
          (scope_varfetch(scope_varname(struct2pass4, level=-1+levoff), level=0, /enter))=struct2pass4
        if keyword_set(struct2pass5) then $
          (scope_varfetch(scope_varname(struct2pass5, level=-1+levoff), level=0, /enter))=struct2pass5
        if n_elements(varnames) NE 0 then $
          for j=0, n_elements(varnames)-1 do $
          (scope_varfetch(varnames[j], level=0, /enter))=scope_varfetch(varnames[j], level=-1+levoff)
;run one of the batch files... stupid IDL execute can't handle batch files so I have to make
;a batch file which calls the batch file... ugh...
        which_bridge=debug
        splog, 'all variables have been passed'

;I could avoid duplicated memory by replcaing all references to these variables
;to be (scope_varfetch(varname, level=-1)) but that seems annoying


    if keyword_set(halt) then STOP
        splog, $
          'running batch file all lines in error message for'
	splog, '   SPLIT_FOR refer to lines of the batch file'
	@simple_batch_451451
	splog, 'if the batch file did not run then simply type @simple_batch_451451 to the command line now'
    if keyword_set(halt) then STOP
    endelse
    splog, 'clean up'
    if x_chkfil('simple_batch_451451',/silent) then begin
        openw, lun3, 'simple_batch_451451', /get_lun, /delete
        close, lun3
        free_lun, lun3
    endif
endelse
end
