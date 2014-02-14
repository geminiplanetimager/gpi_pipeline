pro obridgekill,oBridge

sproc=size(oBridge)
nbproc=sproc[1]

for i=0,nbproc-1 do begin
 obj_destroy,oBridge[i]
endfor

end
