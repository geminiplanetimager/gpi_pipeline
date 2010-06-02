;-----------------------------------------
; gpidrfgui.pro 
;
; select file to process, define modules & parameters to be executed and create DRF
;
;
;
; author : 2009-09-14 J.Maire created
; 		   2010-04-19 M.Perrin: All functionality moved into drfgui object
;
;--------------------------------------------------------------------------------


pro gpidrfgui, drfname=drfname ,groupleader,multidrfgui=multidrfgui,no_block=no_block, session=session ;,group,proj

	common DRFGUI_COMM, objvars, nobj_max

	if ~(keyword_set(nobj_max)) then begin
		nobj_max = 20
		objvars = objarr(nobj_max)
	endif

	if ~(keyword_set(session)) then session=0


	if ~obj_valid(objvars[session]) then objvars[session] = obj_new('drfgui',  groupleader,multidrfgui=multidrfgui,no_block=no_block, session=session )

	if obj_valid(objvars[session]) and keyword_set(drfname) then objvars[session]->loaddrf, drfname,/log

end

