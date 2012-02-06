pro autom


  x = OBJ_NEW('automaticproc2')

  if obj_valid(x) then begin ; it will be invalid if the user cancels or there is some startup error
	  x->run
	  obj_destroy, x
  endif
  
  
end  










