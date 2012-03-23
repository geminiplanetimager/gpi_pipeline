pro which,proname, output=out, quiet=quiet
;+
; NAME:
; 	which
;
;
; CATGEORY: General utility
;
; PURPOSE:
;Prints full filenames in IDL !path search order for a particular routine.
; NOTES:
; proname (input string) procedure name (.pro will be appended) to find
;24-Aug-92 JAV	Create.
;10-Mar-93 JAV	Fixed bug; last directory in !path ignored; pad with ': '
;-

if n_params() lt 1 then begin
  print,'syntax: which,proname(.pro assumed)'
  retall
endif


if n_elements(proname) eq 0 then begin

   ; some magic to allow you to pass unquoted function names.
    ; based on code from Craig Markwardt's dxhelp.pro
          ;; First, extract the parameter name using ROUTINE_NAMES magic
          name = ''
    	  thislev = routine_names(/level)
          cmd = 'name = routine_names(proname,arg_name=thislev-1)'
          if execute(cmd) NE 1 then return
          if n_elements(name) LT 1 then return
          name0 = name(0)
          name = name0
          if name0 EQ '' then begin
              ;; The value might be a quoted string... see if it is!
              cmd = 'val = proname'
              if execute(cmd) NE 1 then return

              sz = size(val)
              if sz(sz(0)+1) EQ 7 then begin
                  ;; It was a string!
                  name0 = val
                    name=val
                  goto, GET_VAL
              endif
              name = '<Expression>'
              val = 0
          endif else begin
    GET_VAL:
              ;; Retrieve the value, again guarding against undefined values
              sz = size(routine_names(name0, fetch=level))
              val = 0
              dummy = temporary(val)
              if sz(sz(0)+1) NE 0 then val = routine_names(name0, fetch=level)
          endelse
	proname=name
endif

	proname=strlowcase(proname)


  pathlist = '.:' + !path + ': '		;build IDL path list
  fcount = 0					;reset file counter
  il = strlen(pathlist) - 1			;length of path string
  ib = 0					;begining substring index
  ie = strpos(pathlist,':',ib)			;ending substring index
  repeat begin					;true: found path separator
    path = strmid(pathlist,ib,ie-ib)		;extract path element
    fullname = path + '/' + proname + '.pro'	;build full filename
    openr,unit,fullname,error=eno,/get_lun	;try to open file
    if eno eq 0 then begin			;true: found file
      fcount = fcount + 1			;increment file counter
      if path eq '.' then begin			;true: in current directory
		spawn,'pwd',dot				;get current working directory
		dot = dot(0)				;convert to scalar
		if ~(keyword_set(quiet)) then print,fullname + ' (. = ' + dot + ')'	;print filename + current dir
	  endif else begin				;else: not in current directory
		if ~(keyword_set(quiet)) then print,fullname				;print full name
		out=fullname 				; return the caller
      endelse
      free_lun,unit				;close file
    endif
    ib = ie + 1					;point beyond separator
    ie = strpos(pathlist,':',ib)		;ending substring index
    if ie eq -1 then ie = il			;point at end of path string
  endrep until ie eq il				;until end of path reached


  if fcount eq 0 then begin			;true: routine not found
    if ~(keyword_set(quiet)) then print,'which: ' + proname + '.pro not found on IDL !path.'
	out=''
  endif

end
