;+
; NAME: gpi_obridgestartup.pro
; 
; The following are code dependencies for gpi_obridgestartup
;
; INPUTS: nbproc =  # of processors to initialize
; 	
; KEYWORDS: none
; 	
; OUTPUTS: none
; 	
;	
; HISTORY:
;    Began 2014-01-13 by Christian Marois
;-  

function gpi_obridgestartup,nbproc=nbproc

pathwork=gpi_get_directory('DRP_LOG')
pathcode=getenv('IDL_PATH')

if not keyword_set(nbproc) then nbproc=round(!cpu.TPOOL_NTHREADS) ;Opening all possible thread
oBridgeinit = ptr_new(obj_new('IDL_IDLBridge'))
oBridge=replicate(oBridgeinit,nbproc)
for i=0,nbproc-1 do begin
 	oBridge[i]= ptr_new(obj_new('IDL_IDLBridge',output = strcompress(pathwork+'/GPI_DRP_child_output-'+string(i+1)+'.txt',/remove_all)))
 	(*oBridge[i])->Execute,"!path=!path+':'+EXPAND_PATH('+"+pathcode+"')"
endfor
(*oBridgeinit)->abort
obj_destroy,(*oBridgeinit)

return,oBridge

end
