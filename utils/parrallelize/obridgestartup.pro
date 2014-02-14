function obridgestartup,nbproc=nbproc

pathwork=gpi_get_directory('DRP_LOG')
pathcode=getenv('IDL_PATH')

if not keyword_set(nbproc) then nbproc=round(!cpu.TPOOL_NTHREADS) ;Opening all possible thread

oBridgeinit = obj_new('IDL_IDLBridge')
obridge=replicate(oBridgeinit,nbproc)
print,pathwork
print,pathcode
for i=0,nbproc-1 do begin
 obridge[i]=obj_new('IDL_IDLBridge',output = strcompress(pathwork+'/GPI_DRP_child_output-'+string(i+1)+'.txt',/remove_all))
 oBridge[i]->Execute,"!path=!path+':'+EXPAND_PATH('+"+pathcode+"')"
endfor
obj_destroy,oBridgeinit

return,oBridge

end
