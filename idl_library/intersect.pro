;+
; NAME:
;	INTERSECT
;
; PURPOSE:
;	Return the an array that is the intersection of the two input arrays.
;
; CATEGORY:
;	Array manipulation.
;
; CALLING SEQUENCE:
;	x = INTERSECT(array1, array2, count)
;
; INPUTS:
;  Arrays    The arrays to be scanned.  The type and number of dimensions
;            of the array are not important.  
;
; OPTIONAL INPUTS:
;   nodata:  This is the value returned if no value in the both of the
;            arrays.  The default is -1.
;
;   xor_flag if this keyword is set, only values are returned that belong
;            to one array or the other, but not both,
;            i.e., the complement of the set of intersection.
;            
;
; OUTPUTS:
;	     result = An array of the values
;        count = # of elements in intersection
;
; EXAMPLE:
;
;     x = [0,2,3,4,6,7,9]
;     y = [3,6,10,12,20]
;
;; print intersection of x and y
;
;     print,intersect(x,y)
;          3        6
;
;; print xor elements
;
;     print,intersect(x,y,/xor_flag)
;          0       2       4       7       9      10      12      20
;
;; print values in x that are not in y        
;
;     xyu=intersect(x,y,/xor_flag) & print,intersect(x,xyu)
;          0       2       4       7       9     
;
;
; COMMON BLOCKS:
;	None.
; 
; AUTHOR and DATE:
;     Jeff Hicke     12/16/92
;
; MODIFICATION HISTORY:
;
;-
;

function intersect, array1, array2, count, nodata=nodata,xor_flag=xor_flag

if (keyword_set(nodata) eq 0) then nodata = -1

array = [reform([array1],n_elements(array1)), reform([array2],n_elements(array2))]
array = array[sort(array)]

if keyword_set(xor_flag) then begin
  samp1=intarr(n_elements(array))
  samp2=samp1
  i1=where(array ne shift(array, -1),count)
  if count gt 0 then samp1(i1)=1
  i2=where(array ne shift(array,  1),count)
  if count gt 0 then samp2(i2)=1
  indices=where(samp1 eq samp2 , count)
  
endif else begin
  indices = where(array eq intshift(array, -1,missing=-1), count)
endelse

if (count GT 0) then return, array[indices] else return, nodata

end
