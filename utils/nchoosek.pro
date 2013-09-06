;+
; NAME:
;       nchoosek
; PURPOSE:
;       Generate all of the combinations of a vector.
;
; EXPLANATION:
;       Port of MATLAB nchoosek function. For a vector v of n
;       elements, taken k at a time, produces a matrix of N!/K!/(N-K)!
;       rows and k columns, so that res[j,*] is a k element
;       combination of the elements of v.
; 
; Calling SEQUENCE:
;       res = nchoosek(v,k)
;
; INPUT/OUTPUT:
;       v - n x 1 or 1 x n vector of values
;       k - size of combintations
;
;       res -  n!/k!/(n-l)! x k matrix of combinations
;      
; OPTIONAL OUTPUT:
;       None.
;
; EXAMPLE:
;
;
; DEPENDENCIES:
;
;
; NOTES: 
;      Will probably fail for n > ~15
;             
; REVISION HISTORY
;       MATLAB copyright The Mathworks, Inc.
;       IDL port Written  08/15/2012. - ds
;-

function combs,v,m
  ;;flatten v to row vector and check inputs
  v = (transpose(v[*]))
  if n_elements(v) eq 1 then n = 1 else n = (size(v,/dim))[1]
  if (m gt n) or (m lt 1) then return, !values.d_nan
  if n eq m then return, v
  if m eq 1 then return, transpose(v)
                    
  for k = 0,n-m do begin
     Q = combs(v[k+1:n-1],m-1)    
     if n_elements(P) eq 0 then P = [[v[lonarr((size(Q,/dim))[0]),k]], [Q]] else $
        P = [P, [[v[lonarr((size(Q,/dim))[0]),k]], [Q]]]
  endfor

  return, P
end 

function nchoosek, v, k

  v = (transpose(v))[*] ;;flatten v
  n = size(v,/dim)
  if n_elements(n) gt 1 then begin
     message,'v must be a column or row vector.',/continue
     return,-1
  endif
  n = n[0]
  if k gt n then begin 
     message,'k cannot be greater than the number of elements in v.',/continue
     return,-1
  endif 

  case k of 
     0: return, !values.d_nan
     1: return, v
     n:  return, transpose(v)
     n-1: begin
        otype = size(v,/type)
        c = transpose(v # (dblarr(1,n)+1))
        inds = findgen(floor(n*n/(n+1))+1)*(n+1)
        c[inds] = !values.d_nan
        c = c[where(finite(c))]
        ;;cast back to orig type
        out = make_array(n,n-1,type=otype)
        out[*] = c[*]
        return, out
     end 
     else: begin

        if n lt 17 && (k gt 3 || n-k lt 4) then begin
           rows = 2d^(n)
           ncycles = rows             
           
           x = lonarr(rows,n)
           for j = n-1,0,-1 do begin
              settings = [[1],[0]]                  
              ncycles = ncycles/2d                   
              nreps = rows/(2d*ncycles)               
              settings = settings[(lonarr(1,nreps)+1),*]
              settings = settings[*] 
              settings = settings[*,(lonarr(1,ncycles)+1)]
              x[*,j] = settings[*] 
           end
           
           idx = x[where(total(x,2) eq k),*]
           nrows = (size(idx,/dim))[0]
           rows = array_indices(transpose(idx),where(transpose(idx) eq 1))
           rows = rows[0,*]
           c = transpose(reform(v(rows),k,nrows))
        endif else c = combs(v,k)

        return, c
     end 
  endcase 
end


