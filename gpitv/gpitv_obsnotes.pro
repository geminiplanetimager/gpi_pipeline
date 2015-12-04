pro gpitv_obsnotes,fname,mark,msg,errout=errout,curlpath=curlpath
;+
; NAME:  gpitv_obsnotes
; 	Write to observation notes database table
;
; INPUTS:
; 	fname - Full path on local disk to image file
;       mark - Binary (0|1) indicating good|bad
;       msg - Text string note (optional)
; KEYWORDS:
;       curlpath - Full path to curl executable (optional)
;       errout - Returns 1 on error, otherwise 0
;
; OUTPUTS:
;       None
;
; HISTORY:
; 	Written at some point
;       12/4/2015 - Changing over to html POST method - ds
;-
  errout = 0
  
  ;;who is doing this?
  if strmatch(!VERSION.OS_FAMILY , 'Windows',/fold) then $
     username = getenv('USERNAME')+'@'+getenv('COMPUTERNAME') $
  else begin
     spawn,'echo "`whoami`@`hostname`"',res,err
     if err[0] eq '' and res[0] ne '' then username = res[0] else username = 'unknown'
  endelse 

  ;;check for curl
  if keyword_set(curlpath) then begin
     if file_test(curlpath,/dir) or ~file_test(curlpath,/executable) then begin
        message,/cont,'Provided cURL path is not executable.'
        errout = 1
        return
     endif
  endif else begin
     spawn,'which curl',res,err
     if (err[0] ne '') or (res[0] eq '') then begin
        message,/cont,'Cannot find cURL in your path.'
        errout = 1
        return
     endif
  endelse 

  ;;assemble data string
  datastring = '"pass=ax243xm3ws96129szl2918sl258zl23&markedby='+username+'&mark='+strtrim(mark,2)+'&fname='+fname
  if msg ne '' then datastring = datastring+'&note='+msg
  datastring = datastring+'"'

  ;;assemble the command and send
  if keyword_set(curlpath) then comm = curlpath else comm = 'curl'
  comm = comm+' -k --data '+datastring+' https://atuin.coecis.cornell.edu/notestaging'
  spawn,comm,res,err

  if res ne 'ack' then begin
     errout = 1
     message,/cont,'Unable to POST.'
     return
  endif 
  
  ;;this is the old way of doing it via a textfile  preserving for
  ;;historical purposes
  ;dbdir = getenv('GPI_DROPBOX_DIR')
  ;if dbdir eq '' then begin
  ;   message,/cont,'Dropbox dir environment variable not set.'
  ;   return
  ;endif

  ;notesfile = dbdir+path_sep()+'GPIDATA-Calibrations'+path_sep()+'obsnotes.txt'
  ;if file_test(notesfile) then $
  ;   openu,lun,notesfile,/get_lun,/append else $
  ;      openw,lun,notesfile,/get_lun
  ;printf,lun,fname,username,mark,msg,format='(A,5X,"|",5X,A,5X,"|",5X,I,5X,"|",5X,A)'
  ;free_lun,lun

   ;IDL only method (doesn't work on the summit machines)
   ;oUrl = OBJ_NEW('IDLnetUrl')
   ;oUrl->SetProperty, URL_SCHEME = 'https'
   ;oUrl->SetProperty, URL_HOST = 'atuin.coecis.cornell.edu'
   ;oUrl->SetProperty, URL_PATH = 'notestaging'
   ;oUrl->SetProperty, SSL_VERIFY_HOST = 0
   ;oUrl->SetProperty, SSL_VERIFY_PEER = 0
   ;result = oUrl->Put(datastring, /BUFFER, /POST)

  
end
