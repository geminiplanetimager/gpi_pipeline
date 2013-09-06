pro callback_searchnewfits, status, error, $
   oBridge, userdata

common filestateF, stateF

;;check if fidget still exist
if stateF.kill eq 1 then return
;stop
;;change the list if new files detected
change = oBridge->GetVar("chang")
if change eq 1 then begin
print, 'new file detected'
listfile = oBridge->GetVar("listfile")
widget_control, stateF.listfile_id, SET_VALUE= listfile ;display the list
;;start commande if desired:
exec = oBridge->GetVar("exec")
commande = oBridge->GetVar("commande")
if exec eq 1 then CALL_PROCEDURE, commande,listfile[0] ;call_proc not absolutely necessary
endif

;check if user ended the detection
widget_control,stateF.button_id,GET_VALUE=val
if where(strcmp(val,'Search most-recent fits files')) eq -1 then begin
	;check if no user change in directories
	ii=0
	while stateF.listcontent[ii] ne '' do ii+=1
	oBridge->SetVar,"dir",stateF.listcontent[0:ii-1]

	;go for new detection
	comm2="chang=detectnewfits(dir,listfile,list_id,button_value)"
	oBridge->Execute, comm2, /NOWAIT

endif else begin
OBJ_DESTROY, oBridge
print, 'end bridge'

   ;iStatus =oBridge->Status(ERROR=estr)
   ;print, estr
endelse


end
