pro gpitv_obsnotes,fname,mark,msg

  ;;who is doing this?
  spawn,'echo "`whoami`@`hostname`"',res,err

  if err[0] eq '' and res[0] ne '' then username = res[0] else username = 'unknown'

  dbdir = getenv('GPI_DROPBOX_DIR')
  if dbdir eq '' then begin
     message,/cont,'Dropbox dir environment variable not set.'
     return
  endif

  notesfile = dbdir+path_sep()+'GPIDATA-Calibrations'+path_sep()+'obsnotes.txt'
  if file_test(notesfile) then $
     openu,lun,notesfile,/get_lun,/append else $
        openw,lun,notesfile,/get_lun
  printf,lun,fname,username,mark,msg,format='(A,5X,"|",5X,A,5X,"|",5X,I,5X,"|",5X,A)'
  free_lun,lun
  
end
