; Set up environment variables for GPI IFS Software
; HISTORY:
;  2010-07-07 Created J. Maire
;  2011-07-29 MP: Validation of directory write permissions fixed up a bit. 
;  2012-01-26 MP: Modified to use for loops. 
;  2012-08-07 MP: Partial cleanup and simplification. Removed GPI_IFS_DIR as
;  					redundant. GPI_DRP_OUTPUT_DIR
;  					-> GPI_REDUCED_DATA_DIR
;  2012-08-10 DS: Changed dirs marked as optional in setup doc to
;                 actually be optional
;
;  FIXME: should try to clean up / reorganize this code? 

function gpi_is_setenv, first=first
  
  ;;these are the things we care about
  ;;name=name, writeable=0|1, isidr=0|1, me=0|1 (must exist)
  env =       {name:'GPI_DRP_QUEUE_DIR',     writeable:1, isidr:1, me:1}
  env = [env, {name:'GPI_RAW_DATA_DIR',      writeable:0, isidr:1, me:1}]
  env = [env, {name:'GPI_REDUCED_DATA_DIR',  writeable:1, isidr:1, me:1}]
  env = [env, {name:'GPI_DRP_DIR',           writeable:0, isidr:1, me:0}]
  env = [env, {name:'GPI_DRP_CONFIG_DIR',    writeable:0, isidr:1, me:0}]
  env = [env, {name:'GPI_DRP_TEMPLATES_DIR', writeable:0, isidr:1, me:0}]
  env = [env, {name:'GPI_CALIBRATIONS_DIR',  writeable:1, isidr:1, me:0}]
  env = [env, {name:'GPI_DRP_LOG_DIR',       writeable:1, isidr:1, me:0}]

  ;;if this is a first incarnation, check for proper idl version and
  ;;try to fill in as many missing env vars with defaults
  if keyword_set(first) then begin 
     runfromvm = LMGR(/VM)
     if (runfromvm eq 0) && (float(!version.release) lt 6.3) then begin
        void = dialog_message('The DRP can not run with IDL version below v6.3.'+$
                              'Please use IDL v6.3 or higher, or run DRP from executables.')
        return,-1
     endif
  endif

  if (!D.NAME eq 'WIN') then newline = string([13B, 10B]) else newline = string(10B)
  retval = 1
  for j = 0,n_elements(env)-1 do begin
     ;;gpi_get_directory always looks for env vars first and takes
     ;;care of default values, so we rely on it completely
     dir = gpi_get_directory(env[j].name,method=method)
     res = file_test(dir, dir = env[j].isidr, write = env[j].writeable )
     if not res then begin
        retval = 0
        message,env[j].name+' value of '+newline+dir+newline+' derived from a(n) '+method+' is not valid.',/info
     endif
  endfor

  return, retval
end   
