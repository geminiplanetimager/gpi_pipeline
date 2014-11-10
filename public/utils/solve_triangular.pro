pro solve_triangular, a,indx, zz, nsetp
; this program is called from inside nnls.pro/

for l = 1,nsetp do begin
  ip = nsetp+1-l
  if (l  NE  1) then zz(1:ip) = zz(1:ip) - a(jj,1:ip)*zz(ip+1)
  jj = indx(ip)
  zz(ip) = zz(ip) / a(jj,ip)
endfor

end


