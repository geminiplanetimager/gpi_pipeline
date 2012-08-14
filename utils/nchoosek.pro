function combs,v,m

  n = (size(v,/dim))[0]
  if n eq m then return, v
  if m eq 1 then return, transpose(v)

  P = []                        
  if (m gt n) or (m lt 1) then return, P

  for k = 0,n-m do begin
     Q = combs(v[k+1:n-1],m-1)    
     P = [[P], [v[k,intarr(max(size(Q,/dim)))], Q]]
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
  

  if (n eq k) or (k eq 1) then return, v

  if (k eq 0) then return, !null

  if (n eq k+1) then begin
     tmp = transpose(v)
     c  = tmp[intarr(n)+1,*]
     c[lindgen(n) * (n+1)] = !VALUES.F_NAN
     c = transpose(reform(c[where(c eq c)],n,n-1))
     return, c
  endif


  c = []                        
  for idx = 0,n-k do begin
     Q = combs(v[idx+1:n-1],k-1)  
     c = [[c], [v[idx,intarr(max(size(Q,/dim)))], Q]]
  endfor

  return, c
end


